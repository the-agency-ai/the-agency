/**
 * AgencyBench Version Constants
 *
 * These values are updated by the build tool:
 *   ./tools/build-bench
 *
 * Format: MAJOR.MINOR.PATCH-YYYYMMDD-BUILDNUMBER
 *
 * - MAJOR: Breaking changes
 * - MINOR: New features
 * - PATCH: Bug fixes
 * - YYYYMMDD: Build date
 * - BUILDNUMBER: Sequential build number for the day (000001, 000002, etc.)
 */

// Agency project version (from VERSION file)
export const AGENCY_VERSION = '1.0.3';

// AgencyBench app version
export const AGENCYBENCH_VERSION = '1.0.0';

// Build metadata
export const BUILD_DATE = '20260111';
export const BUILD_NUMBER = '000012';

// Full version strings
export const AGENCY_FULL_VERSION = `${AGENCY_VERSION}-${BUILD_DATE}-${BUILD_NUMBER}`;
export const AGENCYBENCH_FULL_VERSION = `${AGENCYBENCH_VERSION}-${BUILD_DATE}-${BUILD_NUMBER}`;

// DevApp versions (all 1.x now)
export const DEVAPP_VERSIONS = {
  workitems: `1.0.0-${BUILD_DATE}-${BUILD_NUMBER}`,
  docbench: `1.0.0-${BUILD_DATE}-${BUILD_NUMBER}`,
  bugbench: `1.0.0-${BUILD_DATE}-${BUILD_NUMBER}`,
  'knowledge-indexer': `1.0.0-${BUILD_DATE}-${BUILD_NUMBER}`,
  'agent-monitor': `1.0.0-${BUILD_DATE}-${BUILD_NUMBER}`,
  'collaboration-inbox': `1.0.0-${BUILD_DATE}-${BUILD_NUMBER}`,
  messages: `1.0.0-${BUILD_DATE}-${BUILD_NUMBER}`,
  secrets: `1.0.0-${BUILD_DATE}-${BUILD_NUMBER}`,
} as const;
