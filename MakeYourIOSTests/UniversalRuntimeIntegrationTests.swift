import XCTest
@testable import MakeYourIOS

final class UniversalRuntimeIntegrationTests: XCTestCase {
    func testUniversalShowcasesValidateAndRoundTrip() throws {
        XCTAssertNoThrow(try AppDocumentValidator().validate(SampleDocuments.waterline))
        XCTAssertNoThrow(try AppDocumentValidator().validate(SampleDocuments.starGarden))

        let data = try JSONEncoder().encode(SampleDocuments.starGarden)
        let decoded = try JSONDecoder().decode(AppDocument.self, from: data)
        XCTAssertEqual(decoded.pages.first?.nodes.first?.game?.kind, .custom)
        XCTAssertEqual(
            decoded.pages.first?.nodes.first?.game?.program,
            SampleDocuments.starGardenProgram
        )
        XCTAssertNoThrow(try AppDocumentValidator().validate(decoded))
    }

    func testStarGardenHasAReachableDeterministicWinPath() throws {
        let compiled = try TinyGameCompiler().compile(SampleDocuments.starGardenProgram)
        var engine = TinyGameEngine(program: compiled)
        engine.start()

        advance(&engine, horizontal: 0, vertical: -1, ticks: 35)
        advance(&engine, horizontal: 1, vertical: 0, ticks: 22)
        XCTAssertEqual(engine.variables["score"], 1)

        advance(&engine, horizontal: -1, vertical: 0, ticks: 43)
        advance(&engine, horizontal: 0, vertical: -1, ticks: 10)
        XCTAssertEqual(engine.variables["score"], 2)

        advance(&engine, horizontal: 0, vertical: -1, ticks: 39)
        advance(&engine, horizontal: -1, vertical: 0, ticks: 8)
        XCTAssertEqual(engine.variables["score"], 3)

        advance(&engine, horizontal: 1, vertical: 0, ticks: 30)
        advance(&engine, horizontal: 0, vertical: 1, ticks: 1)
        XCTAssertEqual(engine.variables["score"], 4)

        advance(&engine, horizontal: 1, vertical: 0, ticks: 29)
        XCTAssertEqual(engine.variables["score"], 5)
        XCTAssertEqual(engine.phase, .won)
    }

    private func advance(
        _ engine: inout TinyGameEngine,
        horizontal: Int,
        vertical: Int,
        ticks: Int
    ) {
        engine.setDirectionalInput(
            x: horizontal,
            y: vertical,
            controlID: "move-glider"
        )
        for _ in 0..<ticks where engine.phase == .playing {
            engine.step()
        }
    }
}
