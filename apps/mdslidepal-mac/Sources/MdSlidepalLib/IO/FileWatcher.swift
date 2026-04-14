// What Problem: Watch a markdown source file for changes and trigger a
// re-parse when the file is modified. Editors save files in different ways
// (atomic write = rename, direct write, temp+rename) — the watcher must
// handle all patterns with a debounce to avoid re-parsing mid-save.
//
// How & Why: Uses DispatchSource.makeFileSystemObjectSource to watch for
// .write and .rename events on the file descriptor. On event, debounces
// 100ms then fires the onChange callback. On .rename (atomic save), re-opens
// the file descriptor to continue watching the new inode. This covers Zed,
// VS Code, Sublime, BBEdit, and vim save patterns.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 2.3

import Foundation

/// Watches a file for changes and calls a handler on modification.
@MainActor
public final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var debounceWork: DispatchWorkItem?
    private let debounceInterval: TimeInterval

    /// The URL being watched.
    public private(set) var watchedURL: URL?

    /// Called on the main thread when the file changes.
    public var onChange: (() -> Void)?

    /// Whether the watcher is currently paused (e.g., during presentation mode).
    public var isPaused: Bool = false

    public init(debounceInterval: TimeInterval = 0.1) {
        self.debounceInterval = debounceInterval
    }

    /// Start watching a file URL for changes.
    public func watch(url: URL) {
        stop()
        watchedURL = url
        startWatching(url: url)
    }

    /// Stop watching the current file.
    public func stop() {
        debounceWork?.cancel()
        debounceWork = nil
        source?.cancel()
        source = nil
        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
        watchedURL = nil
    }

    /// Pause watching (e.g., during presentation mode).
    public func pause() {
        isPaused = true
    }

    /// Resume watching after a pause. Re-parses immediately to catch
    /// any changes made while paused.
    public func resume() {
        isPaused = false
        // Fire immediately to catch changes during pause
        fireOnChange()
    }

    deinit {
        // Clean up — note: deinit can't be @MainActor but we just clean up resources
        debounceWork?.cancel()
        source?.cancel()
        if fileDescriptor >= 0 {
            close(fileDescriptor)
        }
    }

    // MARK: - Private

    private func startWatching(url: URL) {
        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            guard let self = self, !self.isPaused else { return }

            let flags = source.data
            if flags.contains(.rename) || flags.contains(.delete) {
                // File was replaced (atomic save) or deleted — re-open
                self.source?.cancel()
                if self.fileDescriptor >= 0 {
                    close(self.fileDescriptor)
                    self.fileDescriptor = -1
                }
                // Small delay then re-watch (the new file may not exist yet)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    guard let self = self, let url = self.watchedURL else { return }
                    if FileManager.default.fileExists(atPath: url.path) {
                        self.startWatching(url: url)
                        self.debouncedOnChange()
                    }
                }
            } else {
                self.debouncedOnChange()
            }
        }

        source.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
                self?.fileDescriptor = -1
            }
        }

        self.source = source
        source.resume()
    }

    private func debouncedOnChange() {
        debounceWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.fireOnChange()
        }
        debounceWork = work
        DispatchQueue.main.asyncAfter(
            deadline: .now() + debounceInterval,
            execute: work
        )
    }

    private func fireOnChange() {
        onChange?()
    }
}
