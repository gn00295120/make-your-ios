@preconcurrency import AVFoundation
@preconcurrency import CoreLocation
@preconcurrency import CoreMotion
import Foundation

enum CameraAuthorization {
    static func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            true
        case .notDetermined:
            await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            false
        @unknown default:
            false
        }
    }
}

final class CurrentLocationCapture: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: ((Result<CLLocation, DeviceCaptureError>) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func capture(completion: @escaping (Result<CLLocation, DeviceCaptureError>) -> Void) {
        self.completion = completion
        guard CLLocationManager.locationServicesEnabled() else {
            finish(.failure(.locationUnavailable))
            return
        }
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            finish(.failure(.denied))
        @unknown default:
            finish(.failure(.locationUnavailable))
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard completion != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            finish(.failure(.denied))
        case .notDetermined:
            break
        @unknown default:
            finish(.failure(.locationUnavailable))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            finish(.failure(.locationUnavailable))
            return
        }
        finish(.success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(.failure(.locationUnavailable))
    }

    private func finish(_ result: Result<CLLocation, DeviceCaptureError>) {
        let callback = completion
        completion = nil
        callback?(result)
    }
}

@MainActor
final class PedometerReader {
    private let pedometer = CMPedometer()

    func todaySteps(now: Date = .now, calendar: Calendar = .current) async throws -> Int {
        guard CMPedometer.isStepCountingAvailable() else {
            throw DeviceCaptureError.pedometerUnavailable
        }
        let start = calendar.startOfDay(for: now)
        return try await withCheckedThrowingContinuation { continuation in
            pedometer.queryPedometerData(from: start, to: now) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data {
                    continuation.resume(returning: data.numberOfSteps.intValue)
                } else {
                    continuation.resume(throwing: DeviceCaptureError.pedometerUnavailable)
                }
            }
        }
    }
}

enum DeviceCaptureError: LocalizedError {
    case denied
    case locationUnavailable
    case pedometerUnavailable
    case documentTooLarge
    case unreadableDocument

    var errorDescription: String? {
        switch self {
        case .denied:
            "Permission is turned off."
        case .locationUnavailable:
            "A current location is not available on this device."
        case .pedometerUnavailable:
            "Step counting is not available on this device."
        case .documentTooLarge:
            "Choose a text file smaller than 256 KB."
        case .unreadableDocument:
            "The selected document is not readable UTF-8 text."
        }
    }
}
