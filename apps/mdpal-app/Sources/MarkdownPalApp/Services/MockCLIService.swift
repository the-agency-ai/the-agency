// What Problem: Phase 1 development needs realistic mock data to build
// and test the UI against while the real CLI is being built by mdpal-cli.
// The mock must return data shaped exactly like the CLI will — same types,
// same relationships (comments anchored to sections, flags on sections).
//
// How & Why: Implements CLIServiceProtocol with canned data. The mock
// document is a realistic design doc with multiple sections, nested headings,
// comments, flags, and resolved/unresolved comment states. This exercises
// the full UI surface. Phase 1A alignment: mock sections are a proper tree
// (authentication with nested children), service flattens before returning.
// BundlePath params accepted. New method stubs for addComment, resolveComment,
// flagSection, clearFlag. Stateless — no mutable state.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold
// Updated: 2026-04-06 Phase 1A model alignment (CLI JSON spec dispatch #23)

import Foundation

/// Mock CLI service for Phase 1 development.
/// Returns realistic canned data matching expected CLI JSON output shapes.
public final class MockCLIService: CLIServiceProtocol, @unchecked Sendable {

    // MARK: - Mock Data

    /// Section tree — authentication has nested children.
    public static let mockSectionTree: [SectionTreeNode] = [
        SectionTreeNode(slug: "overview", heading: "Overview", level: 1,
                        versionHash: "a3f2b1"),
        SectionTreeNode(slug: "authentication", heading: "Authentication", level: 1,
                        versionHash: "c7d4e9", children: [
                            SectionTreeNode(slug: "authentication/oauth", heading: "OAuth Flow",
                                            level: 2, versionHash: "f1a2b3"),
                            SectionTreeNode(slug: "authentication/tokens", heading: "Token Management",
                                            level: 2, versionHash: "b5c6d7"),
                        ]),
        SectionTreeNode(slug: "data-model", heading: "Data Model", level: 1,
                        versionHash: "e8f9a0", children: [
                            SectionTreeNode(slug: "data-model/entities", heading: "Entities",
                                            level: 2, versionHash: "d2e3f4"),
                        ]),
        SectionTreeNode(slug: "api-design", heading: "API Design", level: 1,
                        versionHash: "91b2c3"),
        SectionTreeNode(slug: "open-questions", heading: "Open Questions", level: 1,
                        versionHash: "h4i5j6"),
    ]

    /// Mock SectionsResponse — wraps tree with count and versionId.
    public static let mockSectionsResponse = SectionsResponse(
        sections: mockSectionTree,
        count: 8,
        versionId: "v1-20260406"
    )

    /// Flattened sections for service return.
    public static var mockSectionsFlat: [SectionTreeNode] {
        mockSectionsResponse.flattened()
    }

    public static let mockSectionContents: [String: Section] = [
        "overview": Section(
            slug: "overview", heading: "Overview", level: 1,
            content: """
            This document describes the architecture for the Acme Project,
            a cloud-native service for managing widget lifecycles. The system
            handles authentication, data persistence, and a RESTful API layer.

            The primary goal is to support both human operators and automated
            agents operating on the same data with section-level granularity.
            """,
            versionHash: "a3f2b1", versionId: "v1-20260406"
        ),
        "authentication": Section(
            slug: "authentication", heading: "Authentication", level: 1,
            content: """
            The user authenticates via OAuth2 and receives a bearer token
            that expires after 24 hours. Token refresh is handled automatically
            by the client SDK.

            Agent authentication uses API keys with scoped permissions. Each
            agent key is tied to a principal and has an explicit capability set.
            """,
            versionHash: "c7d4e9", versionId: "v1-20260406"
        ),
        "authentication/oauth": Section(
            slug: "authentication/oauth", heading: "OAuth Flow", level: 2,
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
            versionHash: "f1a2b3", versionId: "v1-20260406"
        ),
        "authentication/tokens": Section(
            slug: "authentication/tokens", heading: "Token Management", level: 2,
            content: """
            Access tokens expire after 24 hours. Refresh tokens expire after
            30 days of inactivity. The client SDK handles refresh transparently.

            Token storage:
            - macOS: Keychain Services
            - Linux: libsecret / encrypted file fallback
            - CLI: Environment variable or config file (agent use case)
            """,
            versionHash: "b5c6d7", versionId: "v1-20260406"
        ),
        "data-model": Section(
            slug: "data-model", heading: "Data Model", level: 1,
            content: """
            The data model uses a document-oriented approach. Each widget is
            a versioned document with section-level metadata. Changes are tracked
            at the section granularity — not line-level diffs.

            Storage backend is PostgreSQL with JSONB columns for flexible
            metadata. Revision history is append-only.
            """,
            versionHash: "e8f9a0", versionId: "v1-20260406"
        ),
        "data-model/entities": Section(
            slug: "data-model/entities", heading: "Entities", level: 2,
            content: """
            Core entities:

            - **Widget** — the primary document. Has sections, metadata, revision history.
            - **Section** — a named chunk of content within a widget. Addressable by slug.
            - **Revision** — an immutable snapshot of a widget at a point in time.
            - **Comment** — anchored to a section + version hash. Supports threading.
            - **Flag** — marks a section for discussion. One per section.
            """,
            versionHash: "d2e3f4", versionId: "v1-20260406"
        ),
        "api-design": Section(
            slug: "api-design", heading: "API Design", level: 1,
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
            versionHash: "91b2c3", versionId: "v1-20260406"
        ),
        "open-questions": Section(
            slug: "open-questions", heading: "Open Questions", level: 1,
            content: """
            1. Should we support real-time collaboration (WebSocket) in V1,
               or is polling sufficient?
            2. What's the maximum document size we need to handle gracefully?
            3. Do we need an audit log separate from revision history?
            4. Should agent API keys support time-bounded access?
            """,
            versionHash: "h4i5j6", versionId: "v1-20260406"
        ),
    ]

    private static let isoFormatter = ISO8601DateFormatter()

    public static let mockComments: [Comment] = [
        Comment(
            commentId: "c001", type: .question, author: "claude",
            slug: "authentication",
            timestamp: isoFormatter.date(from: "2026-03-10T14:00:00Z")!,
            context: "The user authenticates via OAuth2 and receives a bearer token that expires after 24 hours.",
            text: "Does this handle token refresh for long-running agent sessions that exceed 24 hours?",
            resolved: false,
            priority: .high
        ),
        Comment(
            commentId: "c002", type: .suggestion, author: "jordan",
            slug: "data-model",
            timestamp: isoFormatter.date(from: "2026-03-09T10:30:00Z")!,
            context: "Storage backend is PostgreSQL with JSONB columns for flexible metadata.",
            text: "Consider SQLite for the local/single-user case. PostgreSQL feels heavy for a desktop tool.",
            resolved: true,
            resolution: Resolution(
                response: "Agreed. SQLite for local, PostgreSQL for hosted. Engine abstracts the storage layer.",
                by: "jordan",
                timestamp: isoFormatter.date(from: "2026-03-10T09:00:00Z")!
            ),
            priority: .normal
        ),
        Comment(
            commentId: "c003", type: .issue, author: "jordan",
            slug: "api-design",
            timestamp: isoFormatter.date(from: "2026-03-11T16:00:00Z")!,
            context: "All mutation endpoints require the section's version hash for optimistic concurrency.",
            text: "Add rate limiting for agent API keys. We need to prevent runaway agents from flooding the API.",
            resolved: false,
            priority: .high
        ),
        Comment(
            commentId: "c004", type: .note, author: "claude",
            slug: "open-questions",
            timestamp: isoFormatter.date(from: "2026-03-11T17:00:00Z")!,
            context: "Should we support real-time collaboration (WebSocket) in V1?",
            text: "Polling with ETag/If-None-Match is simpler and sufficient for V1. WebSocket adds complexity without clear V1 demand.",
            resolved: false,
            priority: .low
        ),
    ]

    public static let mockFlags: [Flag] = [
        Flag(
            slug: "authentication/oauth",
            note: "Discuss OAuth flow choice — PKCE vs client credentials for agents",
            author: "jordan",
            timestamp: isoFormatter.date(from: "2026-03-10T14:00:00Z")!
        ),
        Flag(
            slug: "open-questions",
            note: nil,
            author: "claude",
            timestamp: isoFormatter.date(from: "2026-03-11T17:30:00Z")!
        ),
    ]

    // MARK: - CLIServiceProtocol

    public init() {}

    public func listSections(bundle: BundlePath) async throws -> [SectionTreeNode] {
        try await Task.sleep(for: .milliseconds(50))
        // Service flattens the tree — callers get a flat list in document order.
        return Self.mockSectionsResponse.flattened()
    }

    public func readSection(slug: String, bundle: BundlePath) async throws -> Section {
        try await Task.sleep(for: .milliseconds(30))
        guard let section = Self.mockSectionContents[slug] else {
            throw CLIServiceError.sectionNotFound(
                slug: slug,
                availableSlugs: Self.mockSectionsFlat.map(\.slug)
            )
        }
        return section
    }

    public func editSection(slug: String, content: String,
                            versionHash: String, bundle: BundlePath) async throws -> EditResult {
        try await Task.sleep(for: .milliseconds(50))
        guard let existing = Self.mockSectionContents[slug] else {
            throw CLIServiceError.sectionNotFound(
                slug: slug,
                availableSlugs: Self.mockSectionsFlat.map(\.slug)
            )
        }
        guard existing.versionHash == versionHash else {
            throw CLIServiceError.versionConflict(
                slug: slug,
                expectedHash: versionHash,
                currentHash: existing.versionHash
            )
        }
        // Return EditResult — no content field (MAR finding: caller must re-read)
        let newHash = String(content.hashValue.magnitude % 0xFFFFFF, radix: 16)
        return EditResult(
            slug: slug,
            versionHash: newHash,
            versionId: "v2-20260406",
            bytesWritten: content.utf8.count
        )
    }

    public func listComments(bundle: BundlePath) async throws -> [Comment] {
        try await Task.sleep(for: .milliseconds(30))
        return Self.mockComments
    }

    public func listFlags(bundle: BundlePath) async throws -> [Flag] {
        try await Task.sleep(for: .milliseconds(20))
        return Self.mockFlags
    }

    public func addComment(slug: String, bundle: BundlePath, type: CommentType,
                           author: String, text: String, context: String?,
                           priority: Priority, tags: [String]) async throws -> Comment {
        try await Task.sleep(for: .milliseconds(30))
        return Comment(
            commentId: "c\(Int.random(in: 100...999))",
            type: type, author: author, slug: slug,
            timestamp: Date(), context: context, text: text,
            resolved: false, priority: priority, tags: tags
        )
    }

    public func resolveComment(commentId: String, bundle: BundlePath,
                               response: String, by: String) async throws -> ResolveResult {
        try await Task.sleep(for: .milliseconds(30))
        return ResolveResult(
            commentId: commentId,
            resolved: true,
            resolution: Resolution(response: response, by: by, timestamp: Date())
        )
    }

    public func flagSection(slug: String, bundle: BundlePath,
                            author: String, note: String?) async throws -> FlagResult {
        try await Task.sleep(for: .milliseconds(20))
        return FlagResult(
            slug: slug, flagged: true, author: author,
            note: note, timestamp: Date()
        )
    }

    public func clearFlag(slug: String, bundle: BundlePath) async throws -> ClearFlagResult {
        try await Task.sleep(for: .milliseconds(20))
        return ClearFlagResult(slug: slug, flagged: false)
    }
}
