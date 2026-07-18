import XCTest
@testable import MakeYourIOS

final class TinyGameProgramTests: XCTestCase {
    func testProgramRoundTripsWithoutLosingDeclarativeRules() throws {
        let source = TinyGameTestFixtures.catcherProgram()
        let encoded = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(TinyGameProgram.self, from: encoded)

        XCTAssertEqual(decoded, source)
        XCTAssertEqual(decoded.version, TinyGameProgram.currentVersion)
        XCTAssertEqual(decoded.rules.map(\.trigger.kind), [
            .start, .collision, .collision, .leaveWorld, .leaveWorld, .tickInterval
        ])
        XCTAssertEqual(decoded.controls.map(\.kind), [.horizontal, .actionButton])
    }

    func testEveryProgramEnumHasStableRawValueRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for value in TinyGameTriggerKind.allCases {
            XCTAssertEqual(try decoder.decode(
                TinyGameTriggerKind.self,
                from: encoder.encode(value)
            ), value)
        }
        for value in TinyGameEffectKind.allCases {
            XCTAssertEqual(try decoder.decode(
                TinyGameEffectKind.self,
                from: encoder.encode(value)
            ), value)
        }
        for value in TinyGameMovementKind.allCases {
            XCTAssertEqual(try decoder.decode(
                TinyGameMovementKind.self,
                from: encoder.encode(value)
            ), value)
        }
    }
}
