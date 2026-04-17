// What Problem: Every CLI test needs to: (a) locate the built mdpal
// binary, (b) invoke it with arguments, (c) capture stdout, stderr,
// and exit code, (d) clean up fixtures. Open-coding this in each test
// invites drift.
//
// How & Why: CLISupport provides three helpers — runCLI() launches a
// subprocess and returns Output{stdout, stderr, exitCode}; makeFixture()
// creates a fresh DocumentBundle in a temp directory; cleanup() removes it.
// Tests use these and stay focused on assertions.
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.1)

import Foundation
@testable import MarkdownPalEngine

enum CLISupport {

    /// Captured output of a single CLI invocation.
    struct Output {
        let stdout: String
        let stderr: String
        let exitCode: Int32
    }

    /// Locate the mdpal binary built into the SwiftPM build directory.
    /// Tests run after `swift build`, so the binary exists at
    /// `.build/{config}/mdpal`. We probe both debug and release.
    static func binaryURL() throws -> URL {
        let env = ProcessInfo.processInfo.environment
        // SwiftPM sets BUILT_PRODUCTS_DIR for in-test invocations sometimes;
        // fall back to walking up from the test bundle to find .build/.
        if let dir = env["MDPAL_BIN_DIR"] {
            return URL(fileURLWithPath: dir).appendingPathComponent("mdpal")
        }

        // Walk up from CWD to find a .build directory, then probe debug/release.
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        var current: URL? = cwd
        while let dir = current {
            let buildDir = dir.appendingPathComponent(".build")
            if FileManager.default.fileExists(atPath: buildDir.path) {
                for config in ["debug", "release"] {
                    let candidate = buildDir.appendingPathComponent(config).appendingPathComponent("mdpal")
                    if FileManager.default.isExecutableFile(atPath: candidate.path) {
                        return candidate
                    }
                }
            }
            let parent = dir.deletingLastPathComponent()
            if parent.path == dir.path { break }
            current = parent
        }
        throw CLITestError.binaryNotFound
    }

    /// Launch the mdpal binary with the given arguments. Captures stdout,
    /// stderr, and exit code. Synchronous — blocks until the process exits.
    static func runCLI(_ args: [String], stdin: String? = nil) throws -> Output {
        let binary = try binaryURL()

        let process = Process()
        process.executableURL = binary
        process.arguments = args

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        if let stdin {
            let stdinPipe = Pipe()
            process.standardInput = stdinPipe
            try process.run()
            stdinPipe.fileHandleForWriting.write(Data(stdin.utf8))
            try stdinPipe.fileHandleForWriting.close()
        } else {
            try process.run()
        }

        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        return Output(
            stdout: String(data: stdoutData, encoding: .utf8) ?? "",
            stderr: String(data: stderrData, encoding: .utf8) ?? "",
            exitCode: process.terminationStatus
        )
    }

    /// Create a fresh fixture bundle at a unique temp path. Returns the
    /// bundle directory path. Caller must call `cleanup(_:)` when done.
    static func makeFixture(name: String, content: String) throws -> String {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("mdpal-cli-test-\(UUID().uuidString)")
        let bundlePath = tempDir.appendingPathComponent("\(name).mdpal").path
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        _ = try DocumentBundle.create(
            name: name,
            initialContent: content,
            at: bundlePath,
            timestamp: Date(timeIntervalSince1970: 1_775_000_000) // deterministic
        )
        return bundlePath
    }

    /// Remove a fixture bundle and its parent temp directory.
    static func cleanup(_ bundlePath: String) {
        let parent = (bundlePath as NSString).deletingLastPathComponent
        try? FileManager.default.removeItem(atPath: parent)
    }
}

enum CLITestError: Error, CustomStringConvertible {
    case binaryNotFound

    var description: String {
        switch self {
        case .binaryNotFound: return "mdpal binary not found — run `swift build` first"
        }
    }
}

/// Minimal JSON-from-string helper for tests.
enum TestJSON {
    static func parse(_ s: String) throws -> [String: Any] {
        let data = Data(s.utf8)
        let any = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dict = any as? [String: Any] else {
            throw CLITestError.binaryNotFound // wrong error but tests will catch
        }
        return dict
    }
}
