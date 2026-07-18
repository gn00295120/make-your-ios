import XCTest
@testable import MakeYourIOS

final class TinyGameProgramTests: XCTestCase {
    func testProgramRoundTripsWithoutLosingDeclarativeRules() throws {
        let source = TinyGameTestFixtures.catcherProgram()
        let encoded = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(TinyGameProgram.self, from: encoded)

        XCTAssertEqual(decoded, source)
        XCTAssertEqual(decoded.version, 2)
        XCTAssertEqual(decoded.rules.map(\.trigger.kind), [
            .start, .collision, .collision, .leaveWorld, .leaveWorld, .tickInterval
        ])
        XCTAssertEqual(decoded.controls.map(\.kind), [.horizontal, .actionButton])
    }

    func testV3ProgramRoundTripsPhysicsAndControlActions() throws {
        let source = TinyGameTestFixtures.platformerProgram()
        let encoded = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(TinyGameProgram.self, from: encoded)

        XCTAssertEqual(decoded, source)
        XCTAssertEqual(decoded.version, TinyGameProgram.currentVersion)
        XCTAssertEqual(decoded.templates[0].physics?.collisionMode, .solid)
        XCTAssertEqual(decoded.controls[1].action?.kind, .jump)
        XCTAssertEqual(decoded.controls[2].action?.kind, .projectile)
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
        for value in TinyGameCollisionMode.allCases {
            XCTAssertEqual(try decoder.decode(
                TinyGameCollisionMode.self,
                from: encoder.encode(value)
            ), value)
        }
        for value in TinyGameControlActionKind.allCases {
            XCTAssertEqual(try decoder.decode(
                TinyGameControlActionKind.self,
                from: encoder.encode(value)
            ), value)
        }
    }

    func testStoredV2ProgramWithoutPhysicsOrActionsStillDecodesAndCompiles() throws {
        var source = TinyGameTestFixtures.catcherProgram(includesTimer: false)
        source.version = 2
        let encoded = try JSONEncoder().encode(source)
        let encodedText = try XCTUnwrap(String(data: encoded, encoding: .utf8))

        XCTAssertFalse(encodedText.contains("\"physics\":"))
        XCTAssertFalse(encodedText.contains("\"action\":"))

        let decoded = try JSONDecoder().decode(TinyGameProgram.self, from: encoded)
        XCTAssertEqual(decoded.version, 2)
        XCTAssertTrue(decoded.templates.allSatisfy { $0.physics == nil })
        XCTAssertTrue(decoded.controls.allSatisfy { $0.action == nil })
        XCTAssertNoThrow(try TinyGameCompiler().compile(decoded))
    }
}
