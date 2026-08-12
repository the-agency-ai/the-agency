// What Problem: Markdown image sources come from untrusted .md files. A deck
// can reference `../../../secret.png`, a symlink pointing outside the deck, or
// a sibling directory whose name merely shares a prefix with the deck folder.
// Contract §11 says such references must be refused, not rendered. The check
// previously lived inside ImageBlockView as a private method, which made it
// both untestable and wrong (a bare string hasPrefix).
//
// How & Why: Pulled out as a pure, public function so the containment rule can
// be unit-tested without instantiating a SwiftUI view. Containment is decided
// on path *components*, not string prefixes — `/deck` must not be considered a
// parent of `/deck-private`. Both sides are symlink-resolved first, so a
// symlink inside the deck cannot smuggle in a file from elsewhere.
//
// Written: 2026-08-07 during mdslidepal-mac PR-prep QG — extracted from
// ImageBlockView to fix the sibling-prefix escape and give contract §11 a test.
// Updated: 2026-08-12 PR-prep QG wave 4 — `resolve()` returned a bare `nil` for
//   three unrelated failures (empty source, no base, containment refusal), so a
//   security refusal was indistinguishable from a typo and neither could be
//   reported as the distinct §11 diagnostic the contract asks for. The reason is
//   now carried by `ImageResolution`; `resolve()` is the URL-only convenience.

import Foundation

/// Resolves markdown image sources to URLs, enforcing contract §11 containment.
public enum ImagePathResolver {

    /// The outcome of resolving one markdown image source.
    ///
    /// Failure cases are distinct because contract §11 treats them as distinct
    /// error classes: a path escaping the deck (line 300) is refused for
    /// security, a missing file (line 295) is a typo in the deck. Both warn, but
    /// they must not read the same to the author.
    public enum ImageResolution: Equatable {
        /// A file path inside the deck directory. The file may or may not exist.
        case local(URL)
        /// An `http`/`https` URL — containment does not apply.
        case remote(URL)
        /// `![alt]()` — nothing to resolve.
        case emptySource
        /// A relative path with no deck directory to resolve it against, i.e. a
        /// document that has never been saved.
        case noBaseDirectory
        /// Contract §11 line 300 — the path leaves the deck directory.
        case outsideDeck(resolvedPath: String)
    }

    /// Resolve an image `source` relative to the markdown file at `sourceURL`,
    /// reporting *why* when it does not resolve.
    public static func resolution(
        for source: String?, relativeTo sourceURL: URL?
    ) -> ImageResolution {
        guard let source, !source.isEmpty else { return .emptySource }

        // Remote URL — no containment rule applies. Schemes are case-insensitive
        // per RFC 3986, so compare the parsed scheme rather than a literal
        // prefix; `HTTP://host/x.png` otherwise fell into the local-path branch
        // and was refused by the containment check.
        if let url = URL(string: source),
           let scheme = url.scheme?.lowercased(),
           scheme == "http" || scheme == "https" {
            return .remote(url)
        }

        // Local path — resolve relative to the source .md file. With no base
        // there is nothing to contain the path against, so refuse rather than
        // fall back to an unvalidated location.
        guard let baseURL = sourceURL?.deletingLastPathComponent() else {
            return .noBaseDirectory
        }

        let base = baseURL.standardized.resolvingSymlinksInPath()
        let resolved = baseURL.appendingPathComponent(source)
            .standardized
            .resolvingSymlinksInPath()

        guard isContained(resolved, in: base) else {
            return .outsideDeck(resolvedPath: resolved.path)
        }
        return .local(resolved)
    }

    /// Resolve an image `source` to a URL, discarding the reason it failed.
    ///
    /// Returns `nil` when the source is empty, when a local path is given but
    /// no base is known, or when the resolved path escapes the base directory.
    /// Remote `http`/`https` sources are returned as-is. Callers that need to
    /// tell those apart — anything that reports to the author — must use
    /// `resolution(for:relativeTo:)`.
    public static func resolve(source: String?, relativeTo sourceURL: URL?) -> URL? {
        switch resolution(for: source, relativeTo: sourceURL) {
        case .local(let url), .remote(let url):
            return url
        case .emptySource, .noBaseDirectory, .outsideDeck:
            return nil
        }
    }

    // MARK: - Reading, with containment re-established on the open file

    /// Why a contained read was refused.
    public enum ContainedReadFailure: Error, Equatable {
        /// The file could not be opened at all — missing, or permission denied.
        case cannotOpen(errno: Int32)
        /// The opened file's real path is not inside the deck. This is the
        /// symlink-swap case: the path passed the check, the file did not.
        case escapedContainment(realPath: String)
        /// The file has more than one name on disk. A hardlink inside the deck
        /// can point at a file anywhere on the same volume, and no path test can
        /// see it, so a deck asset with several names is refused outright.
        case multiplyLinked(linkCount: Int)
        /// Opened and contained, but the bytes could not be read.
        case readFailed
    }

    /// Read `url`'s bytes, re-establishing containment against the file that was
    /// actually opened rather than against the path it was opened by.
    ///
    /// `resolve()` decides containment at time of check and returns a path the
    /// caller opens at some later time of use. Between those two moments the deck
    /// directory is a directory anyone can write to: the entry can be replaced by
    /// a symlink pointing outside, and a hardlink placed there in the first place
    /// never had to point inside at all. So the order here is: open once, ask the
    /// descriptor where it actually landed (`F_GETPATH`) and how many names it has
    /// (`st_nlink`), and read through that same descriptor — never re-opening by
    /// name, which is what would reintroduce the race.
    ///
    /// Symlinks are followed deliberately (no `O_NOFOLLOW`): a symlink inside the
    /// deck pointing at another in-deck file is legitimate, and the containment
    /// test on the resolved descriptor is what makes following one safe.
    ///
    /// Passing `nil` for `base` reads without any containment claim — for callers
    /// that are not resolving untrusted deck content.
    public static func readContained(
        at url: URL, in base: URL?
    ) -> Result<Data, ContainedReadFailure> {
        let descriptor = open(url.path, O_RDONLY | O_CLOEXEC)
        guard descriptor >= 0 else { return .failure(.cannotOpen(errno: errno)) }
        defer { close(descriptor) }

        if let base {
            var info = stat()
            guard fstat(descriptor, &info) == 0 else {
                return .failure(.cannotOpen(errno: errno))
            }
            if info.st_nlink > 1 {
                return .failure(.multiplyLinked(linkCount: Int(info.st_nlink)))
            }
            guard let openedPath = realPath(ofDescriptor: descriptor) else {
                return .failure(.readFailed)
            }
            // Both sides must be normalized the same way. URL's
            // resolvingSymlinksInPath strips a leading `/private` (a documented
            // Foundation quirk), while F_GETPATH keeps it — comparing one against
            // the other refuses every image in a temp directory. realpath(3) is
            // the same normalization the kernel path gives us.
            let resolvedBase = realPath(ofPath: base.path)
                ?? base.standardized.resolvingSymlinksInPath().path
            guard isContained(
                URL(fileURLWithPath: openedPath), in: URL(fileURLWithPath: resolvedBase)
            ) else {
                return .failure(.escapedContainment(realPath: openedPath))
            }
        }

        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: false)
        guard let data = try? handle.readToEnd() else { return .failure(.readFailed) }
        return .success(data ?? Data())
    }

    /// The path the descriptor's file currently occupies, per `F_GETPATH`. For a
    /// descriptor obtained by following a symlink this is the *target's* path,
    /// which is exactly the point.
    /// `realpath(3)` — the fully symlink-resolved form of a path that exists.
    private static func realPath(ofPath path: String) -> String? {
        guard let resolved = realpath(path, nil) else { return nil }
        defer { free(resolved) }
        return String(cString: resolved)
    }

    private static func realPath(ofDescriptor descriptor: Int32) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        guard fcntl(descriptor, F_GETPATH, &buffer) != -1 else { return nil }
        return String(cString: buffer)
    }

    /// True when `url` is the base directory itself or sits beneath it.
    ///
    /// Compares path components so that `/decks` is not treated as a parent of
    /// `/decks-private` — the failure mode of a plain string prefix test.
    public static func isContained(_ url: URL, in base: URL) -> Bool {
        let baseComponents = base.pathComponents
        let urlComponents = url.pathComponents
        guard urlComponents.count >= baseComponents.count else { return false }
        return Array(urlComponents.prefix(baseComponents.count)) == baseComponents
    }
}
