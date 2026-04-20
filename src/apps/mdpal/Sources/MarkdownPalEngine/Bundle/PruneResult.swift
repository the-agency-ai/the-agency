// What Problem: Callers of bundle.prune need to know what happened — which
// revisions were deleted, how many comments were merged forward, and how
// many revisions remain.
//
// How & Why: Plain value struct returned from DocumentBundle.prune.
// Equatable for tests.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.4)

import Foundation

/// Result of a bundle prune operation.
public struct PruneResult: Equatable, Sendable {

    /// Version IDs of the revisions that were deleted.
    public let prunedRevisions: [String]

    /// Number of resolved comments merged forward into the latest revision.
    public let mergedComments: Int

    /// Number of revisions remaining after the prune.
    public let remainingRevisions: Int

    public init(
        prunedRevisions: [String],
        mergedComments: Int,
        remainingRevisions: Int
    ) {
        self.prunedRevisions = prunedRevisions
        self.mergedComments = mergedComments
        self.remainingRevisions = remainingRevisions
    }
}
