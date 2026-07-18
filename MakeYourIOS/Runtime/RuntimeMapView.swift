import MapKit
import SwiftUI

struct RuntimeMapView: View {
    private struct Place: Identifiable, Equatable {
        let id: String
        let name: String
        let address: String
        let coordinate: CLLocationCoordinate2D

        static func == (lhs: Place, rhs: Place) -> Bool {
            lhs.id == rhs.id
        }
    }

    let node: ComponentNode

    @Environment(\.runtimeDesign) private var design
    @State private var cameraPosition: MapCameraPosition
    @State private var searchText: String
    @State private var places: [Place] = []
    @State private var selectedPlaceID: String?
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var activeSearch: MKLocalSearch?
    @State private var activeSearchID = UUID()

    private var spec: RuntimeMapSpec {
        node.map ?? RuntimeMapSpec(
            mode: .coordinate,
            query: "",
            latitude: 25.033,
            longitude: 121.5654,
            spanMeters: 2_000,
            allowsSearch: false,
            allowsDirections: false
        )
    }

    init(node: ComponentNode) {
        self.node = node
        let spec = node.map ?? RuntimeMapSpec(
            mode: .coordinate,
            query: "",
            latitude: 25.033,
            longitude: 121.5654,
            spanMeters: 2_000,
            allowsSearch: false,
            allowsDirections: false
        )
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: spec.latitude, longitude: spec.longitude),
            latitudinalMeters: spec.spanMeters,
            longitudinalMeters: spec.spanMeters
        )
        _cameraPosition = State(initialValue: .region(region))
        _searchText = State(initialValue: spec.query)
    }

    private var selectedPlace: Place? {
        places.first(where: { $0.id == selectedPlaceID }) ?? places.first ?? configuredPlace
    }

    private var configuredPlace: Place {
        Place(
            id: "configured-location",
            name: node.title.isEmpty ? "Location" : node.title,
            address: String(format: "%.5f, %.5f", spec.latitude, spec.longitude),
            coordinate: CLLocationCoordinate2D(
                latitude: spec.latitude,
                longitude: spec.longitude
            )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if spec.allowsSearch {
                searchBar
            }
            map
            status
            if spec.allowsDirections, let selectedPlace {
                directionsButton(for: selectedPlace)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: spec.mode == .placeSearch ? spec.query : "") {
            guard spec.mode == .placeSearch, !spec.query.isEmpty else { return }
            await search(for: spec.query)
        }
        .onDisappear {
            activeSearch?.cancel()
            activeSearch = nil
        }
        .accessibilityIdentifier("runtime.node.\(node.id)")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(node.title, systemImage: node.symbol.isEmpty ? "map.fill" : node.symbol)
                .font(design.bodyFont.weight(.semibold))
            if !node.subtitle.isEmpty {
                Text(node.subtitle)
                    .font(design.captionFont)
                    .foregroundStyle(design.secondaryForeground)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            TextField("Search Apple Maps", text: $searchText)
                .textInputAutocapitalization(.words)
                .submitLabel(.search)
                .onSubmit { beginSearch() }
                .accessibilityIdentifier("runtime.map.\(node.id).query")
            Button {
                beginSearch()
            } label: {
                if isSearching {
                    ProgressView()
                } else {
                    Image(systemName: "magnifyingglass")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSearching || searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Search places")
            .accessibilityIdentifier("runtime.map.\(node.id).search")
        }
    }

    private var map: some View {
        Map(position: $cameraPosition, selection: $selectedPlaceID) {
            if places.isEmpty {
                Marker(configuredPlace.name, coordinate: configuredPlace.coordinate)
                    .tag(configuredPlace.id)
            } else {
                ForEach(places) { place in
                    Marker(place.name, coordinate: place.coordinate)
                        .tag(place.id)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: design.controlCornerRadius, style: .continuous))
        .accessibilityLabel("Map for \(node.title)")
    }

    @ViewBuilder
    private var status: some View {
        if let errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.triangle")
                .font(design.captionFont)
                .foregroundStyle(design.secondaryForeground)
        } else if let selectedPlace {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedPlace.name)
                    .font(design.bodyFont.weight(.semibold))
                if !selectedPlace.address.isEmpty {
                    Text(selectedPlace.address)
                        .font(design.captionFont)
                        .foregroundStyle(design.secondaryForeground)
                }
            }
        }
    }

    private func directionsButton(for place: Place) -> some View {
        Button {
            let item = MKMapItem(placemark: MKPlacemark(coordinate: place.coordinate))
            item.name = place.name
            item.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault
            ])
        } label: {
            Label("Open directions in Maps", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .frame(minHeight: 44)
        .accessibilityIdentifier("runtime.map.\(node.id).directions")
    }

    private func beginSearch() {
        Task { await search(for: searchText) }
    }

    @MainActor
    private func search(for value: String) async {
        let query = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, query.count <= 120 else { return }
        activeSearch?.cancel()
        let searchID = UUID()
        activeSearchID = searchID
        isSearching = true
        errorMessage = nil
        defer {
            if activeSearchID == searchID {
                isSearching = false
                activeSearch = nil
            }
        }

        do {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            let search = MKLocalSearch(request: request)
            activeSearch = search
            let response = try await search.start()
            guard activeSearchID == searchID, !Task.isCancelled else { return }
            let results = response.mapItems.prefix(8).enumerated().map { index, item in
                let coordinate = item.placemark.coordinate
                return Place(
                    id: "\(index)-\(coordinate.latitude),\(coordinate.longitude)",
                    name: item.name ?? "Place",
                    address: item.placemark.title ?? "",
                    coordinate: coordinate
                )
            }
            guard !results.isEmpty else {
                places = []
                selectedPlaceID = nil
                errorMessage = "No places found."
                return
            }
            places = results
            selectedPlaceID = results[0].id
            cameraPosition = .region(MKCoordinateRegion(
                center: results[0].coordinate,
                latitudinalMeters: spec.spanMeters,
                longitudinalMeters: spec.spanMeters
            ))
        } catch {
            guard activeSearchID == searchID, !Task.isCancelled else { return }
            errorMessage = "Apple Maps search is unavailable right now."
        }
    }
}
