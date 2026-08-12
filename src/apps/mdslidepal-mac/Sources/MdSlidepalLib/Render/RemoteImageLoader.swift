// What Problem: Contract §5 line 219 requires remote (`http`/`https`) images to
// load, and they do — through SwiftUI's `AsyncImage`, which fetches on the shared
// URLSession with the 60-second default request timeout and no ceiling at all on
// the response body. A deck is opened in front of an audience: one unreachable
// host stalls the slide for a minute behind a spinner, and one hostile or
// mistaken URL streams as many bytes as the server cares to send straight into
// memory. Remote loading is required; unbounded remote loading is not.
//
// How & Why: A dedicated session with an explicit `timeoutIntervalForRequest`
// (and a resource timeout, so a slow-drip response cannot outlive the slide),
// plus a byte ceiling enforced twice — once against the declared Content-Length,
// which rejects before the body is read, and once against the bytes actually
// received, which is the bound a lying or absent header cannot get past. Both
// decisions are pure functions over numbers so they are tested without a network:
// the async `load` is a thin shell around them.
//
// Every failure lands on the same placeholder the local-image path uses. A
// bounded failure and a 404 look identical to the audience by design — the deck
// keeps moving.
//
// Written: 2026-08-12 during mdslidepal-mac PR-prep QG wave 4.

import AppKit
import Foundation

/// Ceilings a remote image fetch runs under.
public struct RemoteImageBounds: Equatable {
    /// Longest any single request may take before it is abandoned.
    public var timeout: TimeInterval
    /// Largest response body, in bytes, that will be accepted.
    public var maxResponseBytes: Int

    public init(timeout: TimeInterval, maxResponseBytes: Int) {
        self.timeout = timeout
        self.maxResponseBytes = maxResponseBytes
    }

    /// 10 seconds, 16 MB.
    ///
    /// Ten seconds is chosen against the presentation, not against the network:
    /// past that the presenter has already moved on and a spinner is worse than
    /// a placeholder. 16 MB is well above any image a 1920x1080 slide can use and
    /// far below a body that would hurt to hold in memory.
    public static let `default` = RemoteImageBounds(
        timeout: 10, maxResponseBytes: 16 * 1024 * 1024
    )
}

/// Why a remote image was not shown. Every case renders the placeholder.
public enum RemoteImageRefusal: Error, Equatable {
    case timedOut
    case httpStatus(Int)
    case tooLarge(bytes: Int, limit: Int)
    case notAnImage
    case transportFailure(String)
}

/// Bounded fetch of a remote image.
public enum RemoteImageLoader {

    // MARK: - The bounds, as pure functions

    /// A session that cannot outwait the slide it is drawing.
    public static func makeSession(bounds: RemoteImageBounds = .default) -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = bounds.timeout
        // Per-request timeout bounds the gaps between bytes; the resource timeout
        // bounds the whole transfer, so a server dripping one byte a second
        // cannot hold the slide open indefinitely.
        configuration.timeoutIntervalForResource = bounds.timeout
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: configuration)
    }

    /// Refuse on the declared Content-Length, before the body is read.
    ///
    /// `nil` and `-1` (URLResponse's "unknown") are not refusals — an unknown
    /// length is normal, and the received-bytes bound covers it.
    public static func refusal(
        forDeclaredLength length: Int64?, bounds: RemoteImageBounds = .default
    ) -> RemoteImageRefusal? {
        guard let length, length >= 0 else { return nil }
        guard length > Int64(bounds.maxResponseBytes) else { return nil }
        return .tooLarge(bytes: Int(length), limit: bounds.maxResponseBytes)
    }

    /// Refuse on the bytes actually received. This is the bound that holds when
    /// the header is absent or false.
    public static func refusal(
        forReceivedByteCount count: Int, bounds: RemoteImageBounds = .default
    ) -> RemoteImageRefusal? {
        count > bounds.maxResponseBytes
            ? .tooLarge(bytes: count, limit: bounds.maxResponseBytes)
            : nil
    }

    /// Refuse on a non-success HTTP status.
    public static func refusal(forStatusCode code: Int) -> RemoteImageRefusal? {
        (200...299).contains(code) ? nil : .httpStatus(code)
    }

    /// Decode a response body, or nil when it is not an image.
    public static func decode(_ data: Data) -> NSImage? {
        guard !data.isEmpty else { return nil }
        return NSImage(data: data)
    }

    // MARK: - The fetch

    /// Fetch and decode `url` under `bounds`.
    ///
    /// The body is streamed rather than fetched whole so the byte ceiling can
    /// stop a response that ignores its own Content-Length partway through,
    /// instead of discovering the size after it is all in memory.
    public static func load(
        _ url: URL,
        bounds: RemoteImageBounds = .default,
        session: URLSession? = nil
    ) async -> Result<NSImage, RemoteImageRefusal> {
        let session = session ?? makeSession(bounds: bounds)
        do {
            let (stream, response) = try await session.bytes(from: url)

            if let http = response as? HTTPURLResponse,
               let refusal = refusal(forStatusCode: http.statusCode) {
                return .failure(refusal)
            }
            if let refusal = refusal(
                forDeclaredLength: response.expectedContentLength, bounds: bounds
            ) {
                return .failure(refusal)
            }

            // Accumulated as [UInt8] rather than Data: the async sequence yields
            // one byte at a time, and Array's amortized append is materially
            // cheaper than Data's over a multi-megabyte image.
            var buffer: [UInt8] = []
            buffer.reserveCapacity(min(bounds.maxResponseBytes, 1 << 20))
            for try await byte in stream {
                buffer.append(byte)
                if let refusal = refusal(forReceivedByteCount: buffer.count, bounds: bounds) {
                    return .failure(refusal)
                }
            }

            guard let image = decode(Data(buffer)) else { return .failure(.notAnImage) }
            return .success(image)
        } catch let error as URLError where error.code == .timedOut {
            return .failure(.timedOut)
        } catch {
            return .failure(.transportFailure(error.localizedDescription))
        }
    }
}
