// What Problem: CLI consumers (humans, agents, mdpal-app) need a stable
// contract for what each exit code means. ArgumentParser's default exit
// codes are 0 / 1 / 64 — too coarse for our error taxonomy.
//
// How & Why: Five canonical exit codes per A&D §3.5. Mapped from
// EngineError cases at the boundary in each command. Documented in the
// root command's `discussion` so `mdpal --help` surfaces them.
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.1)

import Foundation
import ArgumentParser

/// Deterministic exit codes for the mdpal CLI, per A&D §3.5.
///
/// Consumers (mdpal-app's RealCLIService, agent scripts) match on these
/// values to decide error-handling behavior. Adding a new value is a
/// backward-incompatible wire-format change.
///
/// Named MdpalExitCode (not ExitCode) to avoid collision with
/// ArgumentParser's `ExitCode` type — which IS the throwable used by
/// `ParsableCommand.run()` to set the process exit code. Use the
/// `argumentParserCode` helper to convert.
enum MdpalExitCode: Int32 {
    /// Operation succeeded.
    case success = 0
    /// General error — parse failure, invalid arguments, I/O.
    case generalError = 1
    /// Optimistic-concurrency rejection (edit, revision create with stale base).
    case versionConflict = 2
    /// Slug, comment id, file, or bundle path not found.
    case notFound = 3
    /// Bundle invariant violated (revision collision, concurrent writer detected).
    case bundleConflict = 4

    /// Convert to ArgumentParser's `ExitCode` (which conforms to `Error`
    /// and is the throwable that ParsableCommand uses to set the
    /// process exit status).
    var argumentParserCode: ExitCode {
        ExitCode(rawValue)
    }
}
