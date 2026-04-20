# REQUEST-jordan-0031-housekeeping-build-pipeline-for-the-agency-starter

**Status:** Complete
**Priority:** High
**Requested By:** agent:housekeeping (on behalf of jordan)
**Assigned To:** housekeeping
**Created:** 2026-01-11
**Updated:** 2026-01-11

## Summary

Build pipeline for the-agency-starter

## Details

Define and implement a solid build process for the-agency-starter, including AgencyBench DMG builds. Need deep dive like REQUEST-jordan-0030. Covers: version sync, build tools, release pipeline, CI/CD.

## Acceptance Criteria

### Core Build Pipeline (Complete)
- [x] Starter release tools (`starter-release`, `starter-test`, `starter-verify`, `starter-compare`, `starter-cleanup`)
- [x] Release process documentation (`STARTER-RELEASE-PROCESS.md`)
- [x] Version management (`version-bump`, `version-next`, VERSION file)
- [x] AgencyBench build tool (`bench-build` - creates .app and .dmg)
- [x] Secrets scanning during release
- [x] File sync between repos

### CI/CD (Complete)
- [x] GitHub Actions workflow for PR testing (test.yml)
- [x] GitHub Actions workflow for release automation (starter-release.yml, starter-verify.yml)
- [x] Automated version tagging on release (--push --github flags)

### Documentation (Complete)
- [x] CI/CD workflow documentation (inline in workflow files)
- [x] Release automation guide (--help updated)

## Notes

The core build pipeline and release tools are functional. Main gap is CI/CD automation via GitHub Actions.

Related: REQUEST-jordan-0030 covered onboarding and setup-agency tooling.

---

## Activity Log

### 2026-01-20 - Request Complete
- Code review cycle (3 reviewers): Fixed CRITICAL sed compatibility, HIGH var shadowing
- Test review cycle (2 reviewers): Created starter-release.bats with 23 tests
- All stages tagged and pushed:
  - REQUEST-jordan-0031-impl
  - REQUEST-jordan-0031-review
  - REQUEST-jordan-0031-tests
  - REQUEST-jordan-0031-complete

### 2026-01-20 - Implementation
- Added CI/CD workflows: test.yml, starter-release.yml, starter-verify.yml
- Enhanced starter-release with --push and --github flags
- Workflows synced to starter during release (renamed without starter- prefix)
- All acceptance criteria met

### 2026-01-20 - Status Review
- Reviewed current implementation status
- Core build pipeline is complete
- CI/CD workflows identified as main remaining work
- Updated acceptance criteria to reflect actual state

### 2026-01-11 - Created
- Request created by agent:housekeeping (on behalf of jordan)
