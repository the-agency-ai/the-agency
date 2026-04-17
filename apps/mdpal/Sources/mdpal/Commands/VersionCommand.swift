// What Problem: mdpal-app and agent scripts need a stable way to ask
// "what version of mdpal is installed?" without parsing --help output.
//
// How & Why: `mdpal version` returns a JSON object with `tool` and
// `version` fields. Plain text mode returns the raw version string
// (compatible with shell command-substitution).
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.1)

import ArgumentParser

struct VersionCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Print the mdpal CLI version."
    )

    @Option(name: .long, help: "Output format: json (default) or text.")
    var format: OutputFormat = .json

    func run() throws {
        let payload = VersionPayload(tool: "mdpal", version: Mdpal.configuration.version)

        switch format {
        case .json:
            try JSONOutput.print(payload)
        case .text:
            print(payload.version)
        }
    }
}

/// Wire shape for `mdpal version` JSON output.
struct VersionPayload: Encodable {
    let tool: String
    let version: String
}
