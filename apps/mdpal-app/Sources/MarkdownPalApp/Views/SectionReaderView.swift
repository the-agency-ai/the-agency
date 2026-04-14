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

import SwiftUI

/// Detail view showing a section's content and review state.
public struct SectionReaderView: View {
    let section: Section
    let comments: [Comment]
    let flag: Flag?
    let document: DocumentModel?
    let currentAuthor: String

    // Sheet presentation state
    @State private var showingAddComment = false
    @State private var showingFlagEditor = false
    @State private var resolvingComment: Comment?

    /// Read-only init (tests / previews without a DocumentModel).
    public init(section: Section, comments: [Comment], flag: Flag?) {
        self.section = section
        self.comments = comments
        self.flag = flag
        self.document = nil
        self.currentAuthor = "you"
    }

    /// Interactive init (production use from ContentView).
    public init(section: Section, comments: [Comment], flag: Flag?,
                document: DocumentModel, currentAuthor: String = "you") {
        self.section = section
        self.comments = comments
        self.flag = flag
        self.document = document
        self.currentAuthor = currentAuthor
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader
                if let flag = flag { flagBanner(flag) }
                Divider()
                Text(section.content)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        .sheet(isPresented: $showingAddComment) {
            AddCommentSheet(slug: section.slug, author: currentAuthor) { type, text, context, priority in
                guard let document else { return true }
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
                guard let document else { return true }
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
        .sheet(item: $resolvingComment) { comment in
            ResolveCommentSheet(comment: comment, by: currentAuthor) { response in
                guard let document else { return true }
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
        ToolbarItem(placement: .primaryAction) {
            Button {
                showingAddComment = true
            } label: {
                Label("Add Comment", systemImage: "plus.bubble")
            }
            .help("Add a comment to this section")
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

// MARK: - Add Comment Sheet

struct AddCommentSheet: View {
    let slug: String
    let author: String
    /// Returns true on success; false signals failure — sheet stays open.
    let onSubmit: (CommentType, String, String?, Priority) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var type: CommentType = .question
    @State private var text: String = ""
    @State private var context: String = ""
    @State private var priority: Priority = .normal
    @State private var submitting = false

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
                Text("Context (optional)").font(.caption).foregroundStyle(.secondary)
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
