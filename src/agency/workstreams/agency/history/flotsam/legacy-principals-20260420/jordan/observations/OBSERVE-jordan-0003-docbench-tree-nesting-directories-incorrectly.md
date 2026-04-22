# OBSERVE-jordan-0003-docbench-tree-nesting-directories-incorrectly

**Status:** Open
**Observed By:** agent:housekeeping (on behalf of jordan)
**Created:** 2026-01-09
**Updated:** 2026-01-09

## Summary

DocBench tree nesting directories incorrectly

## Observation

In DocBench, agency-browser-extension/ appears nested inside agency-bench/ but they are actually sibling directories under apps/. The tree-building logic from flat file paths has a bug in directory hierarchy construction.

## Context

<!-- Where did you observe this? What were you doing? -->

## Potential Impact

<!-- Why might this matter? What could happen if not addressed? -->

## Related

<!-- Links to related files, requests, or observations -->

---

## Notes

### 2026-01-09 - Created
- Observation recorded by agent:housekeeping (on behalf of jordan)
