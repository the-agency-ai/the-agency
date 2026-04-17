// What Problem: The detail pane needs to display a section's content with
// its heading, metadata (version hash), associated comments and flags, AND
// allow the user to act: flag/unflag the section, add a new comment, and
// resolve an open comment. Phase 1A iteration: interaction, not just read.
//
// How & Why: Vertical ScrollView with the section heading, content body,
// flag banner (if flagged), and comment thread. A toolbar surfaces the two
// primary actions — flag toggle and add-comment — backed by sheets that
// call DocumentModel mutation methods. Each unresolved comment carries a
// "Resolve" button that pushes to the resolve sheet. The view still has a
// convenience init without a DocumentModel so test / preview usage stays
// simple; when no model is passed, interaction controls are hidden.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold
// Updated: 2026-04-06 Phase 1A model alignment (CLI JSON spec dispatch #23)
// Updated: 2026-04-15 Phase 1A iteration — interaction (flag/comment/resolve)
// Updated: 2026-04-15 Phase 1A.4 — inline edit flow (TextEditor + version-hash conflict)
// Updated: 2026-04-15 Phase 1A.5 — Add-Comment context picker (clipboard-backed prefill)

import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

/// Detail view showing a section's content and review state.
public struct SectionReaderView: View {
    let section: Section
    let comments: [Comment]
    let flag: Flag?
    let document: DocumentModel?
    let currentAuthor: String
    /// Clipboard-read seam for "Comment on Selection" (1A.5). Defaults to
    /// `.system` (NSPasteboard on macOS); tests pass a fake. 1B.6
    /// refactored this from a global mutable static.
    let clipboard: ClipboardReader

    // Sheet presentation state
    @State private var showingAddComment = false
    @State private var showingFlagEditor = false
    @State private var resolvingComment: Comment?

    /// Context to prefill into the next AddCommentSheet presentation.
    /// Set by "Comment on Selection" toolbar action before opening the sheet.
    @State private var commentPrefillContext: String?

    // Edit mode state (1A.4)
    /// Non-nil when the user is actively editing; holds the working copy.
    @State private var editDraft: String?
    /// Hash captured at the moment edit began — used for optimistic concurrency.
    @State private var editBaseHash: String = ""
    /// True while a save is in flight.
    @State private var saving: Bool = false
    /// Carries a version-conflict error for a distinct alert UI.
    @State private var conflict: EditConflict?

    /// Distinct state for a version-conflict so the UI can offer Overwrite vs Reload.
    struct EditConflict: Identifiable {
        let id = UUID()
        let slug: String
        let currentHash: String
        let draft: String
    }

    /// Read-only init (tests / previews without a DocumentModel).
    public init(
        section: Section, comments: [Comment], flag: Flag?,
        clipboard: ClipboardReader = .system
    ) {
        self.section = section
        self.comments = comments
        self.flag = flag
        self.document = nil
        self.currentAuthor = "you"
        self.clipboard = clipboard
    }

    /// Interactive init (production use from ContentView).
    public init(
        section: Section, comments: [Comment], flag: Flag?,
        document: DocumentModel, currentAuthor: String = "you",
        clipboard: ClipboardReader = .system
    ) {
        self.section = section
        self.comments = comments
        self.flag = flag
        self.document = document
        self.currentAuthor = currentAuthor
        self.clipboard = clipboard
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader
                if let flag = flag { flagBanner(flag) }
                Divider()
                if let draft = editDraft {
                    TextEditor(text: Binding(
                        get: { draft },
                        set: { editDraft = $0 }
                    ))
                    .font(.body)
                    .frame(minHeight: 240)
                    .border(.quaternary)
                    .disabled(saving)
                } else {
                    Text(section.content)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if !comments.isEmpty {
                    Divider()
                    commentsSection
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(section.heading)
        .toolbar { if document != nil { toolbarContent } }
        .sheet(isPresented: $showingAddComment, onDismiss: { commentPrefillContext = nil }) {
            AddCommentSheet(
                slug: section.slug,
                author: currentAuthor,
                prefillContext: commentPrefillContext
            ) { type, text, context, priority in
                // No document means we cannot perform the mutation — keep the
                // sheet open so the user's draft is preserved (return false).
                guard let document else { return false }
                do {
                    try await document.addComment(
                        slug: section.slug, type: type, author: currentAuthor,
                        text: text, context: context, priority: priority
                    )
                    return true
                } catch {
                    document.lastError = "Failed to add comment: \(error.localizedDescription)"
                    return false
                }
            }
        }
        .sheet(isPresented: $showingFlagEditor) {
            FlagEditorSheet(slug: section.slug, currentlyFlagged: flag != nil) { note in
                // No document means we cannot perform the mutation — keep the
                // sheet open so the user's draft is preserved (return false).
                guard let document else { return false }
                do {
                    try await document.toggleFlag(
                        slug: section.slug, author: currentAuthor, note: note
                    )
                    return true
                } catch {
                    document.lastError = "Failed to update flag: \(error.localizedDescription)"
                    return false
                }
            }
        }
        .alert(
            "Section changed on disk",
            isPresented: Binding(
                get: { conflict != nil },
                set: { shown in if !shown { conflict = nil } }
            ),
            presenting: conflict
        ) { c in
            Button("Overwrite") {
                editBaseHash = c.currentHash
                Task { await commitEdit() }
            }
            Button("Discard my edits", role: .destructive) {
                editDraft = nil
                editBaseHash = ""
                conflict = nil
                if let document {
                    Task { await document.selectSection(slug: c.slug) }
                }
            }
            Button("Keep editing", role: .cancel) {
                conflict = nil
            }
        } message: { c in
            Text("Another writer updated this section (current hash: \(c.currentHash)). Overwrite with your edits, discard yours to reload, or keep editing to merge by hand.")
        }
        .sheet(item: $resolvingComment) { comment in
            ResolveCommentSheet(comment: comment, by: currentAuthor) { response in
                // No document means we cannot perform the mutation — keep the
                // sheet open so the user's draft is preserved (return false).
                guard let document else { return false }
                do {
                    try await document.resolveComment(
                        commentId: comment.commentId, response: response, by: currentAuthor
                    )
                    return true
                } catch {
                    document.lastError = "Failed to resolve comment: \(error.localizedDescription)"
                    return false
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if editDraft == nil {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editDraft = section.content
                    editBaseHash = section.versionHash
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .help("Edit this section's content")
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        commentPrefillContext = nil
                        showingAddComment = true
                    } label: {
                        Label("Add Comment", systemImage: "plus.bubble")
                    }
                    Button {
                        commentPrefillContext = selectionContextFromClipboard()
                        showingAddComment = true
                    } label: {
                        Label("Comment on Selection", systemImage: "text.quote")
                    }
                    .disabled(selectionContextFromClipboard() == nil)
                } label: {
                    Label("Add Comment", systemImage: "plus.bubble")
                }
                .help("Add a comment — use 'Comment on Selection' to prefill context from your copied selection")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingFlagEditor = true
                } label: {
                    Label(flag == nil ? "Flag" : "Clear Flag",
                          systemImage: flag == nil ? "flag" : "flag.slash")
                }
                .help(flag == nil ? "Flag this section for discussion" : "Clear the flag")
            }
        } else {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    editDraft = nil
                    editBaseHash = ""
                }
                .disabled(saving)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(saving ? "Saving…" : "Save") {
                    Task { await commitEdit() }
                }
                .disabled(saving || (editDraft ?? "").isEmpty)
            }
        }
    }

    // MARK: - Selection context (1A.5)

    /// Produce a prefill context from the system clipboard, if the clipboard
    /// text looks like a quote from the current section. Returns nil if the
    /// clipboard is empty, not text, or doesn't appear in `section.content`.
    /// Extracted for testability — see `SelectionContext.extract` below.
    private func selectionContextFromClipboard() -> String? {
        SelectionContext.extract(
            from: clipboard.readString(),
            within: section.content
        )
    }

    // MARK: - Edit commit

    /// Save the draft through DocumentModel.editSection, routing version
    /// conflicts to a dedicated UI and other errors to document.lastError.
    private func commitEdit() async {
        guard let document, let draft = editDraft else { return }
        saving = true
        defer { saving = false }
        do {
            try await document.editSection(
                slug: section.slug, newContent: draft, versionHash: editBaseHash
            )
            editDraft = nil
            editBaseHash = ""
        } catch let CLIServiceError.versionConflict(slug, _, currentHash) {
            conflict = EditConflict(slug: slug, currentHash: currentHash, draft: draft)
        } catch {
            document.lastError = "Failed to save section: \(error.localizedDescription)"
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(section.heading).font(.largeTitle.bold())
            HStack(spacing: 12) {
                Label(section.slug, systemImage: "link")
                    .font(.caption).foregroundStyle(.secondary)
                Label("v: \(section.versionHash)", systemImage: "number")
                    .font(.caption).foregroundStyle(.secondary)
                Label("H\(section.level)",
                      systemImage: "text.header.level.\(min(section.level, 3))")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Flag Banner

    private func flagBanner(_ flag: Flag) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "flag.fill").foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Flagged for discussion").font(.subheadline.bold())
                if let note = flag.note {
                    Text(note).font(.caption).foregroundStyle(.secondary)
                }
                Text("by \(flag.author) \(flag.timestamp.formatted(.relative(presentation: .named)))")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.orange.opacity(0.1))
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Comments Section

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Comments").font(.headline)
                let unresolvedCount = comments.filter { !$0.isResolved }.count
                if unresolvedCount > 0 {
                    Text("\(unresolvedCount) unresolved")
                        .font(.caption).foregroundStyle(.blue)
                }
            }
            ForEach(comments) { comment in
                CommentView(comment: comment, canResolve: document != nil) {
                    resolvingComment = comment
                }
            }
        }
    }
}

/// A single comment in the thread.
struct CommentView: View {
    let comment: Comment
    let canResolve: Bool
    let onResolve: () -> Void

    init(comment: Comment, canResolve: Bool = false, onResolve: @escaping () -> Void = {}) {
        self.comment = comment
        self.canResolve = canResolve
        self.onResolve = onResolve
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                commentTypeIcon.foregroundStyle(commentTypeColor)
                Text(comment.type.rawValue.capitalized)
                    .font(.caption.bold()).foregroundStyle(commentTypeColor)
                Text("by \(comment.author)")
                    .font(.caption).foregroundStyle(.secondary)
                if comment.priority == .high {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2).foregroundStyle(.red)
                        .help("High priority")
                }
                Spacer()
                Text(comment.timestamp.formatted(.relative(presentation: .named)))
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            Text(comment.text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let context = comment.context, !context.isEmpty {
                Text(context)
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.quaternary.opacity(0.5))
                    )
            }
            if let resolution = comment.resolution {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green).font(.caption)
                    Text("Resolved by \(resolution.by):")
                        .font(.caption.bold()).foregroundStyle(.green)
                }
                Text(resolution.response)
                    .font(.caption).foregroundStyle(.secondary)
            } else if canResolve {
                HStack {
                    Spacer()
                    Button("Resolve", action: onResolve)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(comment.isResolved ? .green.opacity(0.05) : .blue.opacity(0.05))
                .stroke(comment.isResolved ? .green.opacity(0.2) : .blue.opacity(0.2), lineWidth: 1)
        )
    }

    private var commentTypeIcon: some View {
        Image(systemName: iconName).font(.caption)
    }

    private var iconName: String {
        switch comment.type {
        case .question: return "questionmark.circle"
        case .suggestion: return "lightbulb"
        case .note: return "note.text"
        case .issue: return "exclamationmark.circle"
        case .todo: return "checklist"
        }
    }

    private var commentTypeColor: Color {
        switch comment.type {
        case .question: return .purple
        case .suggestion: return .blue
        case .note: return .gray
        case .issue: return .orange
        case .todo: return .green
        }
    }
}

// MARK: - Selection Context Helper (1A.5)

/// Pure logic for deciding whether a clipboard string should pre-fill the
/// "context" field of a new comment. Separated for testability — no SwiftUI,
/// no AppKit, no Foundation platform deps.
public enum SelectionContext {
    /// Extract a usable context prefill from `clipboard` given the section's
    /// content. Returns nil if:
    /// - clipboard is nil or empty/whitespace
    /// - clipboard text does not appear as a substring of `sectionContent`
    ///   (trimmed comparison so a stray trailing newline from a copy doesn't
    ///   defeat the check)
    ///
    /// The Phase 1A workflow: user selects text in the reader, hits Cmd-C,
    /// then opens "Comment on Selection" — this function gatekeeps so
    /// unrelated clipboard contents (URLs from elsewhere, passwords, etc.)
    /// don't accidentally leak into a comment.
    public static func extract(from clipboard: String?, within sectionContent: String) -> String? {
        guard let raw = clipboard else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard sectionContent.contains(trimmed) else { return nil }
        return trimmed
    }
}

/// Thin indirection over NSPasteboard so views can read the clipboard and
/// tests can swap in a fake. 1A.5.
///
/// 1B.6 refactor: dropped the global mutable `static var current` in
/// favor of env-injection. Views now take a `ClipboardReader` (default
/// `.system`) as an init parameter; tests pass their own reader rather
/// than mutating shared state.
public struct ClipboardReader: Sendable {
    public let readString: @Sendable () -> String?

    public init(readString: @escaping @Sendable () -> String?) {
        self.readString = readString
    }

    #if canImport(AppKit)
    public static let system = ClipboardReader {
        NSPasteboard.general.string(forType: .string)
    }
    #else
    public static let system = ClipboardReader { nil }
    #endif
}

// MARK: - Add Comment Sheet

struct AddCommentSheet: View {
    let slug: String
    let author: String
    /// Optional pre-filled context (e.g. user's quoted selection). 1A.5.
    let prefillContext: String?
    /// Returns true on success; false signals failure — sheet stays open.
    let onSubmit: (CommentType, String, String?, Priority) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var type: CommentType = .question
    @State private var text: String = ""
    @State private var context: String = ""
    @State private var priority: Priority = .normal
    @State private var submitting = false

    init(slug: String, author: String, prefillContext: String? = nil,
         onSubmit: @escaping (CommentType, String, String?, Priority) async -> Bool) {
        self.slug = slug
        self.author = author
        self.prefillContext = prefillContext
        self.onSubmit = onSubmit
        // Seed the @State's initial value with the prefill so the sheet
        // renders with it on first appearance.
        self._context = State(initialValue: prefillContext ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Comment").font(.title2.bold())
            Text("Section: \(slug)").font(.caption).foregroundStyle(.secondary)

            Picker("Type", selection: $type) {
                ForEach(CommentType.allCases, id: \.self) { t in
                    Text(t.rawValue.capitalized).tag(t)
                }
            }
            .pickerStyle(.segmented)

            Picker("Priority", selection: $priority) {
                ForEach(Priority.allCases, id: \.self) { p in
                    Text(p.rawValue.capitalized).tag(p)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 4) {
                Text("Comment").font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $text)
                    .frame(minHeight: 80)
                    .font(.body)
                    .border(.quaternary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Context (optional)").font(.caption).foregroundStyle(.secondary)
                    if prefillContext != nil {
                        Text("· prefilled from your selection")
                            .font(.caption).foregroundStyle(.blue)
                    }
                }
                TextEditor(text: $context)
                    .frame(minHeight: 50)
                    .font(.body)
                    .border(.quaternary)
            }

            Spacer()

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button(submitting ? "Adding…" : "Add Comment") {
                    submitting = true
                    Task {
                        let ctx = context.isEmpty ? nil : context
                        let ok = await onSubmit(type, text, ctx, priority)
                        submitting = false
                        if ok { dismiss() }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty || submitting)
            }
        }
        .padding(20)
        .frame(minWidth: 480, minHeight: 420)
    }
}

// MARK: - Resolve Comment Sheet

struct ResolveCommentSheet: View {
    let comment: Comment
    let by: String
    /// Returns true on success; false signals failure — sheet stays open.
    let onSubmit: (String) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var response: String = ""
    @State private var submitting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resolve Comment").font(.title2.bold())

            VStack(alignment: .leading, spacing: 4) {
                Text("Original comment").font(.caption).foregroundStyle(.secondary)
                Text(comment.text).font(.body)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.quaternary.opacity(0.3))
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Your response").font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $response)
                    .frame(minHeight: 100)
                    .font(.body)
                    .border(.quaternary)
            }

            Spacer()

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button(submitting ? "Resolving…" : "Resolve") {
                    submitting = true
                    Task {
                        let ok = await onSubmit(response)
                        submitting = false
                        if ok { dismiss() }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(response.trimmingCharacters(in: .whitespaces).isEmpty || submitting)
            }
        }
        .padding(20)
        .frame(minWidth: 480, minHeight: 360)
    }
}

// MARK: - Flag Editor Sheet

struct FlagEditorSheet: View {
    let slug: String
    let currentlyFlagged: Bool
    /// Returns true on success; false signals failure — sheet stays open.
    let onSubmit: (String?) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var note: String = ""
    @State private var submitting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(currentlyFlagged ? "Clear Flag" : "Flag Section").font(.title2.bold())
            Text("Section: \(slug)").font(.caption).foregroundStyle(.secondary)

            if !currentlyFlagged {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Note (optional)").font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                        .font(.body)
                        .border(.quaternary)
                }
            } else {
                Text("This will remove the flag from the section.")
                    .font(.body).foregroundStyle(.secondary)
            }

            Spacer()

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button(submitting
                       ? (currentlyFlagged ? "Clearing…" : "Flagging…")
                       : (currentlyFlagged ? "Clear Flag" : "Flag")) {
                    submitting = true
                    Task {
                        let n = (currentlyFlagged || note.isEmpty) ? nil : note
                        let ok = await onSubmit(n)
                        submitting = false
                        if ok { dismiss() }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(submitting)
            }
        }
        .padding(20)
        .frame(minWidth: 420, minHeight: currentlyFlagged ? 220 : 340)
    }
}
