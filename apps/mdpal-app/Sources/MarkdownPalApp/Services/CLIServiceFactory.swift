// What Problem: The app needs to pick between RealCLIService (production,
// shells out to a real `mdpal` binary) and MockCLIService (previews,
// tests, and graceful fallback when no CLI is installed). Hardcoding
// either everywhere would prevent previews from running on a machine
// without mdpal, and would make CI runs depend on an installed binary.
//
// How & Why: One factory, one resolution policy. Looks at `MDPAL_MOCK`
// env var first (explicit opt-in to Mock for tests/previews), then tries
// RealCLIService. If the real service can't be constructed (cliNotFound —
// no binary on MDPAL_BIN, PATH, or fallbacks), logs a diagnostic marker
// to stderr and falls back to Mock so the app is still usable — the user
// sees a banner ("running without CLI") rather than a crash.
//
// The factory is a static free function rather than a service registry
// so it has no state to leak between tests. Tests can still exercise
// the decision logic by calling `CLIServiceFactory.make(...)` with an
// explicit environment.
//
// Written: 2026-04-17 during Phase 1B.6 (service selection + housekeeping)

import Foundation

/// Resolves which `CLIServiceProtocol` implementation the app should use.
public enum CLIServiceFactory {
    /// Names the resolution outcome so callers (e.g., a UI banner or
    /// diagnostic log) can show which service is active and why.
    public enum Resolution: Equatable, Sendable {
        /// Production path: real CLI resolved and in use.
        case real(executablePath: String)
        /// Explicitly requested Mock via `MDPAL_MOCK=1` (or similar truthy).
        case mockRequested
        /// Real CLI couldn't be found; fell back to Mock so the app still runs.
        case mockFallback(reason: String)
    }

    /// Construct a service and report the resolution. Callers that care
    /// about the outcome (e.g., to show a "running in mock mode" banner)
    /// inspect the `.resolution` on the returned pair.
    public static func make(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) -> (service: CLIServiceProtocol, resolution: Resolution) {
        // Explicit mock opt-in via env. Accept any non-empty truthy value
        // (1, true, yes) — restrictive-match would surprise users who set
        // MDPAL_MOCK=TRUE or similar.
        if let raw = environment["MDPAL_MOCK"],
           Self.isTruthy(raw) {
            return (MockCLIService(), .mockRequested)
        }

        do {
            let real = try RealCLIService(
                environment: environment,
                fileManager: fileManager,
                runner: DefaultProcessRunner()
            )
            return (real, .real(executablePath: real.executablePath))
        } catch CLIServiceError.cliNotFound {
            return (MockCLIService(),
                    .mockFallback(reason: "no `mdpal` binary found on MDPAL_BIN, PATH, or fallbacks"))
        } catch {
            // Any other init failure is unexpected but shouldn't crash the app.
            return (MockCLIService(),
                    .mockFallback(reason: "RealCLIService init failed: \(error.localizedDescription)"))
        }
    }

    /// Conservative truthy check for an env-var string. Empty → false so
    /// `MDPAL_MOCK=""` (inherited empty) doesn't silently force Mock.
    private static func isTruthy(_ raw: String) -> Bool {
        switch raw.lowercased() {
        case "1", "true", "yes", "y", "on":
            return true
        default:
            return false
        }
    }
}
