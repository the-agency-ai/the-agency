// What Problem: Iteration 2.1 ships `mdpal version`. The wire format
// must be stable: JSON with `tool` and `version` fields by default,
// plain version string with --format text. mdpal-app integration tests
// will assert against this shape.
//
// How & Why: Run the binary, capture output, assert shape and exit
// code. No fixture needed for `version`.
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.1)

import Testing
import Foundation

@Test func versionJSONShape() throws {
    let result = try CLISupport.runCLI(["version"])
    #expect(result.exitCode == 0)
    let json = try TestJSON.parse(result.stdout)
    #expect(json["tool"] as? String == "mdpal")
    #expect((json["version"] as? String)?.isEmpty == false)
}

@Test func versionTextFormat() throws {
    let result = try CLISupport.runCLI(["version", "--format", "text"])
    #expect(result.exitCode == 0)
    #expect(!result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    // Text mode should NOT be JSON.
    #expect(!result.stdout.contains("{"))
}

@Test func versionDefaultFormatIsJSON() throws {
    let result = try CLISupport.runCLI(["version"])
    #expect(result.exitCode == 0)
    #expect(result.stdout.contains("{"))
}

@Test func rootHelpListsSubcommands() throws {
    let result = try CLISupport.runCLI(["--help"])
    #expect(result.exitCode == 0)
    #expect(result.stdout.contains("version"))
    #expect(result.stdout.contains("sections"))
    #expect(result.stdout.contains("read"))
}
