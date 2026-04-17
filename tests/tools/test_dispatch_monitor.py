"""
Tests for dispatch-monitor (Python rewrite).

Tests the core functions: ID extraction, seen-ID dedup, eviction.
Does NOT test subprocess calls (those depend on the dispatch tool + DB).

Written: 2026-04-17 D44 — dispatch-monitor Python rewrite
"""

import importlib.util
import sys
from pathlib import Path

# Load dispatch-monitor as a module despite no .py extension.
# Use SourceFileLoader directly — spec_from_file_location returns None
# for files without .py extension.
from importlib.machinery import SourceFileLoader

_tool_path = str(Path(__file__).resolve().parent.parent.parent / "claude" / "tools" / "dispatch-monitor")
_loader = SourceFileLoader("dispatch_monitor", _tool_path)
_mod = _loader.load_module()

extract_id = _mod.extract_id
evict_oldest = _mod.evict_oldest
ID_PATTERN = _mod.ID_PATTERN


class TestExtractId:
    def test_valid_id_line(self):
        assert extract_id("519  commit   normal   resolved   ...") == 519

    def test_valid_id_with_leading_spaces(self):
        assert extract_id("  42  dispatch  normal  unread  ...") == 42

    def test_header_line(self):
        assert extract_id("ID   TYPE   PRI   STATUS   SUBJECT") is None

    def test_separator_line(self):
        assert extract_id("──────────────────────") is None

    def test_empty_line(self):
        assert extract_id("") is None

    def test_no_dispatches_message(self):
        assert extract_id("No dispatches found.") is None

    def test_large_id(self):
        assert extract_id("99999  commit  normal  unread  test") == 99999


class TestEvictOldest:
    def test_no_eviction_under_limit(self):
        seen = {1, 2, 3}
        evict_oldest(seen, 10)
        assert seen == {1, 2, 3}

    def test_eviction_at_limit(self):
        seen = set(range(100))
        evict_oldest(seen, 50)
        # Should have evicted ~half (the lower IDs)
        assert len(seen) <= 50
        # Higher IDs should survive
        assert 99 in seen
        assert 98 in seen

    def test_eviction_keeps_newer(self):
        seen = {1, 2, 3, 100, 200, 300}
        evict_oldest(seen, 3)
        # Should keep the higher IDs
        assert 300 in seen
        assert 200 in seen
        assert 100 in seen

    def test_empty_set(self):
        seen: set = set()
        evict_oldest(seen, 10)
        assert len(seen) == 0


class TestDedup:
    """Test the dedup logic that would happen in check_dispatches."""

    def test_new_id_added(self):
        seen = set()
        line = "519  commit   normal   unread   test"
        dispatch_id = extract_id(line)
        assert dispatch_id == 519
        assert dispatch_id not in seen
        seen.add(dispatch_id)
        assert dispatch_id in seen

    def test_duplicate_rejected(self):
        seen = {519}
        line = "519  commit   normal   unread   test"
        dispatch_id = extract_id(line)
        assert dispatch_id in seen  # Should be filtered

    def test_different_ids_both_accepted(self):
        seen = set()
        for line in [
            "519  commit   normal   unread   test1",
            "520  commit   normal   unread   test2",
        ]:
            dispatch_id = extract_id(line)
            assert dispatch_id not in seen
            seen.add(dispatch_id)
        assert seen == {519, 520}


if __name__ == "__main__":
    # Simple test runner — no pytest dependency needed
    import traceback

    passed = 0
    failed = 0
    errors = []

    for cls_name, cls in [
        ("TestExtractId", TestExtractId),
        ("TestEvictOldest", TestEvictOldest),
        ("TestDedup", TestDedup),
    ]:
        for method_name in sorted(dir(cls)):
            if not method_name.startswith("test_"):
                continue
            test_name = f"{cls_name}.{method_name}"
            try:
                getattr(cls(), method_name)()
                passed += 1
            except Exception:
                failed += 1
                errors.append((test_name, traceback.format_exc()))

    for test_name, tb in errors:
        print(f"FAIL: {test_name}")
        print(tb)

    print(f"\n{passed} passed, {failed} failed")
    sys.exit(1 if failed else 0)
