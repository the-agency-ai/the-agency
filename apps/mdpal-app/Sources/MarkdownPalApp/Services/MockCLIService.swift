// What Problem: Phase 1 development needs realistic mock data to build
// and test the UI against while the real CLI is being built by mdpal-cli.
// The mock must return data shaped exactly like the CLI will — same types,
// same relationships (comments anchored to sections, flags on sections).
//
// How & Why: Implements CLIServiceProtocol with canned data. The mock
// document is a realistic Markdown Pal design doc with multiple sections,
// nested headings, comments from both humans and agents, flags, and
// resolved/unresolved comment states. This exercises the full UI surface.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold

import Foundation

/// Mock CLI service for Phase 1 development.
/// Returns realistic canned data matching expected CLI JSON output shapes.
public final class MockCLIService: CLIServiceProtocol, @unchecked Sendable {

    // MARK: - Mock Data

    public static let mockSections: [SectionInfo] = [
        SectionInfo(slug: "overview", heading: "Overview", level: 1,
                    versionHash: "a3f2b1", childCount: 0),
        SectionInfo(slug: "authentication", heading: "Authentication", level: 1,
                    versionHash: "c7d4e9", childCount: 2),
        SectionInfo(slug: "authentication/oauth", heading: "OAuth Flow", level: 2,
                    versionHash: "f1a2b3", childCount: 0),
        SectionInfo(slug: "authentication/tokens", heading: "Token Management", level: 2,
                    versionHash: "b5c6d7", childCount: 0),
        SectionInfo(slug: "data-model", heading: "Data Model", level: 1,
                    versionHash: "e8f9a0", childCount: 1),
        SectionInfo(slug: "data-model/entities", heading: "Entities", level: 2,
                    versionHash: "d2e3f4", childCount: 0),
        SectionInfo(slug: "api-design", heading: "API Design", level: 1,
                    versionHash: "91b2c3", childCount: 0),
        SectionInfo(slug: "open-questions", heading: "Open Questions", level: 1,
                    versionHash: "h4i5j6", childCount: 0),
    ]

    public static let mockSectionContents: [String: Section] = [
        "overview": Section(
            slug: "overview",
            heading: "Overview",
            level: 1,
            content: """
            This document describes the architecture for the Acme Project,
            a cloud-native service for managing widget lifecycles. The system
            handles authentication, data persistence, and a RESTful API layer.

            The primary goal is to support both human operators and automated
            agents operating on the same data with section-level granularity.
            """,
            versionHash: "a3f2b1",
            children: []
        ),
        "authentication": Section(
            slug: "authentication",
            heading: "Authentication",
            level: 1,
            content: """
            The user authenticates via OAuth2 and receives a bearer token
            that expires after 24 hours. Token refresh is handled automatically
            by the client SDK.

            Agent authentication uses API keys with scoped permissions. Each
            agent key is tied to a principal and has an explicit capability set.
            """,
            versionHash: "c7d4e9",
            children: [
                SectionInfo(slug: "authentication/oauth", heading: "OAuth Flow", level: 2,
                            versionHash: "f1a2b3", childCount: 0),
                SectionInfo(slug: "authentication/tokens", heading: "Token Management", level: 2,
                            versionHash: "b5c6d7", childCount: 0),
            ]
        ),
        "authentication/oauth": Section(
            slug: "authentication/oauth",
            heading: "OAuth Flow",
            level: 2,
            content: """
            Standard OAuth2 authorization code flow with PKCE:

            1. Client redirects to `/authorize` with code challenge
            2. User authenticates with identity provider
            3. Callback receives authorization code
            4. Client exchanges code + verifier for access token
            5. Access token used for all subsequent API calls

            The identity provider is configurable — supports Auth0, Okta,
            and Azure AD out of the box.
            """,
            versionHash: "f1a2b3",
            children: []
        ),
        "authentication/tokens": Section(
            slug: "authentication/tokens",
            heading: "Token Management",
            level: 2,
            content: """
            Access tokens expire after 24 hours. Refresh tokens expire after
            30 days of inactivity. The client SDK handles refresh transparently.

            Token storage:
            - macOS: Keychain Services
            - Linux: libsecret / encrypted file fallback
            - CLI: Environment variable or config file (agent use case)
            """,
            versionHash: "b5c6d7",
            children: []
        ),
        "data-model": Section(
            slug: "data-model",
            heading: "Data Model",
            level: 1,
            content: """
            The data model uses a document-oriented approach. Each widget is
            a versioned document with section-level metadata. Changes are tracked
            at the section granularity — not line-level diffs.

            Storage backend is PostgreSQL with JSONB columns for flexible
            metadata. Revision history is append-only.
            """,
            versionHash: "e8f9a0",
            children: [
                SectionInfo(slug: "data-model/entities", heading: "Entities", level: 2,
                            versionHash: "d2e3f4", childCount: 0),
            ]
        ),
        "data-model/entities": Section(
            slug: "data-model/entities",
            heading: "Entities",
            level: 2,
            content: """
            Core entities:

            - **Widget** — the primary document. Has sections, metadata, revision history.
            - **Section** — a named chunk of content within a widget. Addressable by slug.
            - **Revision** — an immutable snapshot of a widget at a point in time.
            - **Comment** — anchored to a section + version hash. Supports threading.
            - **Flag** — marks a section for discussion. One per section.
            """,
            versionHash: "d2e3f4",
            children: []
        ),
        "api-design": Section(
            slug: "api-design",
            heading: "API Design",
            level: 1,
            content: """
            RESTful API with JSON responses. Section-oriented endpoints:

            ```
            GET  /widgets/:id/sections           — list sections
            GET  /widgets/:id/sections/:slug      — read section
            PUT  /widgets/:id/sections/:slug      — edit section (version hash required)
            POST /widgets/:id/sections/:slug/comments — add comment
            GET  /widgets/:id/comments            — list all comments
            ```

            All mutation endpoints require the section's version hash for
            optimistic concurrency. On conflict, returns HTTP 409 with the
            current content and hash.
            """,
            versionHash: "91b2c3",
            children: []
        ),
        "open-questions": Section(
            slug: "open-questions",
            heading: "Open Questions",
            level: 1,
            content: """
            1. Should we support real-time collaboration (WebSocket) in V1,
               or is polling sufficient?
            2. What's the maximum document size we need to handle gracefully?
            3. Do we need an audit log separate from revision history?
            4. Should agent API keys support time-bounded access?
            """,
            versionHash: "h4i5j6",
            children: []
        ),
    ]

    public static let mockComments: [Comment] = [
        Comment(
            id: "c001",
            type: .question,
            author: "claude",
            sectionSlug: "authentication",
            versionHash: "c7d4e9",
            timestamp: ISO8601DateFormatter().date(from: "2026-03-10T14:00:00Z")!,
            context: "The user authenticates via OAuth2 and receives a bearer token that expires after 24 hours.",
            text: "Does this handle token refresh for long-running agent sessions that exceed 24 hours?",
            resolution: nil,
            priority: .high
        ),
        Comment(
            id: "c002",
            type: .suggestion,
            author: "jordan",
            sectionSlug: "data-model",
            versionHash: "e8f9a0",
            timestamp: ISO8601DateFormatter().date(from: "2026-03-09T10:30:00Z")!,
            context: "Storage backend is PostgreSQL with JSONB columns for flexible metadata.",
            text: "Consider SQLite for the local/single-user case. PostgreSQL feels heavy for a desktop tool.",
            resolution: Resolution(
                response: "Agreed. SQLite for local, PostgreSQL for hosted. Engine abstracts the storage layer.",
                resolvedDate: ISO8601DateFormatter().date(from: "2026-03-10T09:00:00Z")!,
                resolvedBy: "jordan"
            ),
            priority: .normal
        ),
        Comment(
            id: "c003",
            type: .directive,
            author: "jordan",
            sectionSlug: "api-design",
            versionHash: "91b2c3",
            timestamp: ISO8601DateFormatter().date(from: "2026-03-11T16:00:00Z")!,
            context: "All mutation endpoints require the section's version hash for optimistic concurrency.",
            text: "Add rate limiting for agent API keys. We need to prevent runaway agents from flooding the API.",
            resolution: nil,
            priority: .high
        ),
        Comment(
            id: "c004",
            type: .note,
            author: "claude",
            sectionSlug: "open-questions",
            versionHash: "h4i5j6",
            timestamp: ISO8601DateFormatter().date(from: "2026-03-11T17:00:00Z")!,
            context: "Should we support real-time collaboration (WebSocket) in V1?",
            text: "Polling with ETag/If-None-Match is simpler and sufficient for V1. WebSocket adds complexity without clear V1 demand.",
            resolution: nil,
            priority: .low
        ),
    ]

    public static let mockFlags: [Flag] = [
        Flag(
            sectionSlug: "authentication/oauth",
            note: "Discuss OAuth flow choice — PKCE vs client credentials for agents",
            author: "jordan",
            timestamp: ISO8601DateFormatter().date(from: "2026-03-10T14:00:00Z")!
        ),
        Flag(
            sectionSlug: "open-questions",
            note: nil,
            author: "claude",
            timestamp: ISO8601DateFormatter().date(from: "2026-03-11T17:30:00Z")!
        ),
    ]

    // MARK: - CLIServiceProtocol

    public init() {}

    public func listSections(content: String) async throws -> [SectionInfo] {
        // Simulate CLI latency
        try await Task.sleep(for: .milliseconds(50))
        return Self.mockSections
    }

    public func readSection(slug: String, content: String) async throws -> Section {
        try await Task.sleep(for: .milliseconds(30))
        guard let section = Self.mockSectionContents[slug] else {
            throw CLIServiceError.sectionNotFound(
                slug: slug,
                availableSlugs: Self.mockSections.map(\.slug)
            )
        }
        return section
    }

    public func editSection(slug: String, newContent: String,
                            versionHash: String, documentContent: String) async throws -> Section {
        try await Task.sleep(for: .milliseconds(50))
        guard let existing = Self.mockSectionContents[slug] else {
            throw CLIServiceError.sectionNotFound(
                slug: slug,
                availableSlugs: Self.mockSections.map(\.slug)
            )
        }
        guard existing.versionHash == versionHash else {
            throw CLIServiceError.versionConflict(
                slug: slug,
                expectedHash: versionHash,
                currentHash: existing.versionHash
            )
        }
        // Return updated section with new content and a new hash
        return Section(
            slug: slug,
            heading: existing.heading,
            level: existing.level,
            content: newContent,
            versionHash: String(newContent.hashValue.magnitude % 0xFFFFFF, radix: 16),
            children: existing.children
        )
    }

    public func listComments(content: String) async throws -> [Comment] {
        try await Task.sleep(for: .milliseconds(30))
        return Self.mockComments
    }

    public func listFlags(content: String) async throws -> [Flag] {
        try await Task.sleep(for: .milliseconds(20))
        return Self.mockFlags
    }
}
