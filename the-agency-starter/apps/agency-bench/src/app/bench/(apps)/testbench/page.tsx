'use client';

import { useState, useEffect } from 'react';

interface TestRun {
  id: number;
  runId: string;
  suite: string;
  status: 'running' | 'passed' | 'failed' | 'error';
  total: number;
  passed: number;
  failed: number;
  skipped: number;
  duration: number | null;
  output: string | null;
  startedAt: string;
  completedAt: string | null;
}

interface TestRunListResponse {
  runs: TestRun[];
  total: number;
}

const STATUS_COLORS: Record<string, string> = {
  'running': 'bg-blue-100 text-blue-700',
  'passed': 'bg-green-100 text-green-700',
  'failed': 'bg-red-100 text-red-700',
  'error': 'bg-red-100 text-red-700',
};

export default function TestBenchPage() {
  const [runs, setRuns] = useState<TestRun[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedRun, setSelectedRun] = useState<TestRun | null>(null);
  const [filter, setFilter] = useState<'all' | 'passed' | 'failed'>('all');
  const [running, setRunning] = useState(false);

  const API_BASE = process.env.NEXT_PUBLIC_API_URL?.replace('/bug', '/test') || 'http://localhost:3456/api/test';

  useEffect(() => {
    loadRuns();
  }, []);

  async function loadRuns() {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE}/runs/list?limit=50`);
      if (!response.ok) throw new Error('Failed to load test runs');
      const data: TestRunListResponse = await response.json();
      setRuns(data.runs);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load test runs');
    } finally {
      setLoading(false);
    }
  }

  async function runTests(suite: string) {
    setRunning(true);
    try {
      const response = await fetch(`${API_BASE}/runs/start`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ suite }),
      });
      if (!response.ok) throw new Error('Failed to start test run');
      loadRuns();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to start tests');
    } finally {
      setRunning(false);
    }
  }

  const formatTime = (ts: string) => {
    const date = new Date(ts);
    return date.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const formatDuration = (ms: number | null) => {
    if (!ms) return '-';
    if (ms < 1000) return `${ms}ms`;
    return `${(ms / 1000).toFixed(1)}s`;
  };

  const filteredRuns = runs.filter((r) => {
    if (filter === 'all') return true;
    return r.status === filter;
  });

  if (error) {
    return (
      <div className="p-8">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
          <p className="font-medium">Error loading test runs</p>
          <p className="text-sm mt-1">{error}</p>
          <button onClick={loadRuns} className="mt-3 px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700">
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-[calc(100vh-8rem)] gap-4">
      {/* Run List */}
      <div className="w-96 bg-white rounded-xl border border-gray-200 flex flex-col">
        <div className="p-3 border-b border-gray-200 space-y-2">
          <div className="flex gap-2">
            {(['all', 'passed', 'failed'] as const).map((f) => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`px-3 py-1 text-sm rounded-full capitalize ${
                  filter === f ? 'bg-agency-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {f}
              </button>
            ))}
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => runTests('all')}
              disabled={running}
              className="flex-1 px-3 py-1.5 text-sm bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
            >
              {running ? 'Running...' : 'Run All Tests'}
            </button>
            <button
              onClick={() => runTests('unit')}
              disabled={running}
              className="px-3 py-1.5 text-sm bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 disabled:opacity-50"
            >
              Unit
            </button>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto">
          {loading ? (
            <div className="text-center py-8 text-gray-400">Loading...</div>
          ) : filteredRuns.length === 0 ? (
            <div className="text-center py-8 text-gray-400">No test runs found</div>
          ) : (
            filteredRuns.map((run) => (
              <button
                key={run.id}
                onClick={() => setSelectedRun(run)}
                className={`w-full text-left p-3 border-b border-gray-100 hover:bg-gray-50 ${
                  selectedRun?.id === run.id ? 'bg-agency-50' : ''
                }`}
              >
                <div className="flex items-center gap-2">
                  <span className={`text-xs px-1.5 py-0.5 rounded uppercase ${STATUS_COLORS[run.status]}`}>
                    {run.status}
                  </span>
                  <span className="font-mono text-xs text-gray-500">{run.suite}</span>
                  <span className="text-xs text-gray-400 ml-auto">{formatDuration(run.duration)}</span>
                </div>
                <div className="mt-1 text-sm">
                  <span className="text-green-600">{run.passed} passed</span>
                  {run.failed > 0 && <span className="text-red-600 ml-2">{run.failed} failed</span>}
                  {run.skipped > 0 && <span className="text-gray-400 ml-2">{run.skipped} skipped</span>}
                </div>
                <div className="text-xs text-gray-400 mt-1">{formatTime(run.startedAt)}</div>
              </button>
            ))
          )}
        </div>

        <div className="p-3 border-t border-gray-200 text-xs text-gray-500">
          {runs.length} runs &middot; {runs.filter(r => r.status === 'passed').length} passed
        </div>
      </div>

      {/* Run Detail */}
      <div className="flex-1 bg-white rounded-xl border border-gray-200 flex flex-col">
        {selectedRun ? (
          <>
            <div className="p-4 border-b border-gray-200">
              <div className="flex items-center gap-2">
                <span className={`text-sm px-2 py-1 rounded uppercase ${STATUS_COLORS[selectedRun.status]}`}>
                  {selectedRun.status}
                </span>
                <span className="font-mono text-gray-600">{selectedRun.suite}</span>
                <span className="text-sm text-gray-400 ml-auto">{formatDuration(selectedRun.duration)}</span>
              </div>
              <div className="mt-3 grid grid-cols-4 gap-4 text-center">
                <div className="bg-gray-50 p-2 rounded">
                  <div className="text-lg font-medium">{selectedRun.total}</div>
                  <div className="text-xs text-gray-500">Total</div>
                </div>
                <div className="bg-green-50 p-2 rounded">
                  <div className="text-lg font-medium text-green-700">{selectedRun.passed}</div>
                  <div className="text-xs text-green-600">Passed</div>
                </div>
                <div className="bg-red-50 p-2 rounded">
                  <div className="text-lg font-medium text-red-700">{selectedRun.failed}</div>
                  <div className="text-xs text-red-600">Failed</div>
                </div>
                <div className="bg-gray-50 p-2 rounded">
                  <div className="text-lg font-medium text-gray-500">{selectedRun.skipped}</div>
                  <div className="text-xs text-gray-500">Skipped</div>
                </div>
              </div>
            </div>
            <div className="flex-1 p-4 overflow-y-auto">
              {selectedRun.output ? (
                <pre className="text-xs font-mono bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto whitespace-pre-wrap">
                  {selectedRun.output}
                </pre>
              ) : (
                <div className="text-gray-400 italic">No output available</div>
              )}
            </div>
            <div className="p-4 border-t border-gray-200 text-xs text-gray-500">
              Started: {formatTime(selectedRun.startedAt)}
              {selectedRun.completedAt && ` · Completed: ${formatTime(selectedRun.completedAt)}`}
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-400">
            Select a test run to view details
          </div>
        )}
      </div>
    </div>
  );
}
