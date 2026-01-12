'use client';

import { useState, useEffect } from 'react';

interface Bug {
  id: number;
  bugId: string;
  workstream: string;
  summary: string;
  description: string | null;
  status: 'Open' | 'In Progress' | 'Fixed' | "Won't Fix";
  reporterType: string;
  reporterName: string;
  assigneeType: string | null;
  assigneeName: string | null;
  createdAt: string;
  updatedAt: string;
}

interface BugListResponse {
  bugs: Bug[];
  total: number;
}

const STATUS_COLORS: Record<string, string> = {
  'Open': 'bg-red-100 text-red-700',
  'In Progress': 'bg-yellow-100 text-yellow-700',
  'Fixed': 'bg-green-100 text-green-700',
  "Won't Fix": 'bg-gray-100 text-gray-700',
};

export default function BugBenchPage() {
  const [bugs, setBugs] = useState<Bug[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedBug, setSelectedBug] = useState<Bug | null>(null);
  const [filter, setFilter] = useState<'all' | 'Open' | 'In Progress' | 'Fixed'>('all');
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  // Form state
  const [newBug, setNewBug] = useState({
    workstream: 'BENCH',
    summary: '',
    description: '',
    reporterType: 'principal',
    reporterName: '',
  });

  const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3456/api/bug';

  useEffect(() => {
    loadBugs();
  }, []);

  async function loadBugs() {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE}/list?limit=100`);
      if (!response.ok) throw new Error('Failed to load bugs');
      const data: BugListResponse = await response.json();
      setBugs(data.bugs);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load bugs');
    } finally {
      setLoading(false);
    }
  }

  async function createBug() {
    if (!newBug.summary.trim() || !newBug.reporterName.trim()) {
      setActionError('Summary and reporter name are required');
      return;
    }

    setSubmitting(true);
    setActionError(null);

    try {
      const response = await fetch(`${API_BASE}/create`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newBug),
      });

      if (!response.ok) throw new Error('Failed to create bug');

      setShowCreateForm(false);
      setNewBug({
        workstream: 'BENCH',
        summary: '',
        description: '',
        reporterType: 'principal',
        reporterName: '',
      });
      loadBugs();
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Failed to create bug');
    } finally {
      setSubmitting(false);
    }
  }

  async function updateStatus(bugId: string, status: string) {
    setSubmitting(true);
    setActionError(null);

    try {
      const response = await fetch(`${API_BASE}/status/${bugId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status }),
      });

      if (!response.ok) throw new Error('Failed to update status');
      loadBugs();
      if (selectedBug?.bugId === bugId) {
        setSelectedBug({ ...selectedBug, status: status as Bug['status'] });
      }
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Failed to update status');
    } finally {
      setSubmitting(false);
    }
  }

  // Filter bugs
  const filteredBugs = bugs.filter((b) => {
    if (filter === 'all') return true;
    return b.status === filter;
  });

  // Format timestamp
  const formatTime = (ts: string) => {
    const date = new Date(ts);
    return date.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  if (error) {
    return (
      <div className="p-8">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
          <p className="font-medium">Error loading bugs</p>
          <p className="text-sm mt-1">{error}</p>
          <p className="text-sm mt-2">Make sure agency-service is running on port 3456</p>
          <button
            onClick={loadBugs}
            className="mt-3 px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-[calc(100vh-8rem)] gap-4">
      {/* Bug List */}
      <div className="w-96 bg-white rounded-xl border border-gray-200 flex flex-col">
        {/* Header with Create button */}
        <div className="p-3 border-b border-gray-200 flex justify-between items-center">
          <div className="flex gap-2">
            {(['all', 'Open', 'In Progress', 'Fixed'] as const).map((f) => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`px-3 py-1 text-sm rounded-full capitalize ${
                  filter === f
                    ? 'bg-agency-600 text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {f}
              </button>
            ))}
          </div>
          <button
            onClick={() => setShowCreateForm(true)}
            className="px-3 py-1 text-sm bg-agency-600 text-white rounded-full hover:bg-agency-700"
          >
            + New
          </button>
        </div>

        {/* Bug List */}
        <div className="flex-1 overflow-y-auto">
          {loading ? (
            <div className="text-center py-8 text-gray-400">Loading...</div>
          ) : filteredBugs.length === 0 ? (
            <div className="text-center py-8 text-gray-400">No bugs found</div>
          ) : (
            filteredBugs.map((bug) => {
              const isSelected = selectedBug?.id === bug.id;

              return (
                <button
                  key={bug.id}
                  onClick={() => setSelectedBug(bug)}
                  className={`w-full text-left p-3 border-b border-gray-100 hover:bg-gray-50 ${
                    isSelected ? 'bg-agency-50' : ''
                  }`}
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs text-gray-500">{bug.bugId}</span>
                        <span className={`text-xs px-1.5 py-0.5 rounded ${STATUS_COLORS[bug.status]}`}>
                          {bug.status}
                        </span>
                      </div>
                      <div className="text-sm text-gray-900 truncate mt-1">
                        {bug.summary}
                      </div>
                      <div className="text-xs text-gray-500 mt-0.5">
                        {bug.reporterType}:{bug.reporterName}
                      </div>
                    </div>
                    <div className="text-xs text-gray-400">
                      {formatTime(bug.createdAt)}
                    </div>
                  </div>
                </button>
              );
            })
          )}
        </div>

        {/* Stats */}
        <div className="p-3 border-t border-gray-200 text-xs text-gray-500">
          {bugs.length} bugs total &middot; {bugs.filter(b => b.status === 'Open').length} open
        </div>
      </div>

      {/* Bug Detail or Create Form */}
      <div className="flex-1 bg-white rounded-xl border border-gray-200 flex flex-col">
        {showCreateForm ? (
          <div className="p-4">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-medium">Report New Bug</h2>
              <button
                onClick={() => setShowCreateForm(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                Cancel
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Summary *</label>
                <input
                  type="text"
                  value={newBug.summary}
                  onChange={(e) => setNewBug({ ...newBug, summary: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-agency-500 focus:border-agency-500"
                  placeholder="Brief description of the bug"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                <textarea
                  value={newBug.description}
                  onChange={(e) => setNewBug({ ...newBug, description: e.target.value })}
                  rows={4}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-agency-500 focus:border-agency-500"
                  placeholder="Detailed description, steps to reproduce, etc."
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Workstream</label>
                  <input
                    type="text"
                    value={newBug.workstream}
                    onChange={(e) => setNewBug({ ...newBug, workstream: e.target.value.toUpperCase() })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-agency-500 focus:border-agency-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Reporter Name *</label>
                  <input
                    type="text"
                    value={newBug.reporterName}
                    onChange={(e) => setNewBug({ ...newBug, reporterName: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-agency-500 focus:border-agency-500"
                    placeholder="Your name"
                  />
                </div>
              </div>

              <button
                onClick={createBug}
                className="w-full py-2 bg-agency-600 text-white rounded-lg hover:bg-agency-700"
              >
                Create Bug
              </button>
            </div>
          </div>
        ) : selectedBug ? (
          <>
            <div className="p-4 border-b border-gray-200">
              <div className="flex items-start justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-mono text-sm text-gray-500">{selectedBug.bugId}</span>
                    <span className="text-xs px-1.5 py-0.5 rounded bg-gray-100 text-gray-600">
                      {selectedBug.workstream}
                    </span>
                  </div>
                  <h2 className="text-lg font-medium text-gray-900 mt-1">
                    {selectedBug.summary}
                  </h2>
                </div>
                <select
                  value={selectedBug.status}
                  onChange={(e) => updateStatus(selectedBug.bugId, e.target.value)}
                  className={`px-3 py-1 rounded-lg border-0 text-sm font-medium ${STATUS_COLORS[selectedBug.status]}`}
                >
                  <option value="Open">Open</option>
                  <option value="In Progress">In Progress</option>
                  <option value="Fixed">Fixed</option>
                  <option value="Won't Fix">Won&apos;t Fix</option>
                </select>
              </div>

              <div className="flex gap-4 mt-3 text-sm text-gray-500">
                <div>
                  Reporter: <span className="text-gray-700">{selectedBug.reporterType}:{selectedBug.reporterName}</span>
                </div>
                {selectedBug.assigneeName && (
                  <div>
                    Assignee: <span className="text-gray-700">{selectedBug.assigneeType}:{selectedBug.assigneeName}</span>
                  </div>
                )}
              </div>
            </div>

            <div className="flex-1 p-4 overflow-y-auto">
              {selectedBug.description ? (
                <div className="prose prose-sm max-w-none whitespace-pre-wrap">
                  {selectedBug.description}
                </div>
              ) : (
                <div className="text-gray-400 italic">No description provided</div>
              )}
            </div>

            <div className="p-4 border-t border-gray-200 bg-gray-50 text-xs text-gray-500">
              Created: {formatTime(selectedBug.createdAt)} &middot; Updated: {formatTime(selectedBug.updatedAt)}
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-400">
            Select a bug to view details or click + New to report one
          </div>
        )}
      </div>
    </div>
  );
}
