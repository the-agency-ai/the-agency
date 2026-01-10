'use client';

import { useState, useEffect } from 'react';

interface LogEntry {
  id: number;
  level: 'debug' | 'info' | 'warn' | 'error';
  service: string;
  message: string;
  data: Record<string, unknown> | null;
  timestamp: string;
}

interface LogListResponse {
  logs: LogEntry[];
  total: number;
}

const LEVEL_COLORS: Record<string, string> = {
  'debug': 'bg-gray-100 text-gray-600',
  'info': 'bg-blue-100 text-blue-700',
  'warn': 'bg-yellow-100 text-yellow-700',
  'error': 'bg-red-100 text-red-700',
};

export default function LogBenchPage() {
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedLog, setSelectedLog] = useState<LogEntry | null>(null);
  const [filter, setFilter] = useState<'all' | 'info' | 'warn' | 'error'>('all');
  const [serviceFilter, setServiceFilter] = useState<string>('');

  const API_BASE = process.env.NEXT_PUBLIC_API_URL?.replace('/bug', '/log') || 'http://localhost:3456/api/log';

  useEffect(() => {
    loadLogs();
  }, [filter, serviceFilter]);

  async function loadLogs() {
    try {
      setLoading(true);
      const params = new URLSearchParams({ limit: '200' });
      if (filter !== 'all') params.set('level', filter);
      if (serviceFilter) params.set('service', serviceFilter);

      const response = await fetch(`${API_BASE}/list?${params}`);
      if (!response.ok) throw new Error('Failed to load logs');
      const data: LogListResponse = await response.json();
      setLogs(data.logs);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load logs');
    } finally {
      setLoading(false);
    }
  }

  const formatTime = (ts: string) => {
    const date = new Date(ts);
    return date.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
  };

  // Get unique services
  const services = [...new Set(logs.map(l => l.service))].sort();

  if (error) {
    return (
      <div className="p-8">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
          <p className="font-medium">Error loading logs</p>
          <p className="text-sm mt-1">{error}</p>
          <button onClick={loadLogs} className="mt-3 px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700">
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-[calc(100vh-8rem)] gap-4">
      {/* Log List */}
      <div className="w-[500px] bg-white rounded-xl border border-gray-200 flex flex-col">
        <div className="p-3 border-b border-gray-200 space-y-2">
          <div className="flex gap-2">
            {(['all', 'info', 'warn', 'error'] as const).map((f) => (
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
            <button onClick={loadLogs} className="ml-auto px-3 py-1 text-sm bg-gray-100 text-gray-600 rounded-full hover:bg-gray-200">
              Refresh
            </button>
          </div>
          <select
            value={serviceFilter}
            onChange={(e) => setServiceFilter(e.target.value)}
            className="w-full px-3 py-1.5 text-sm border border-gray-200 rounded-lg"
          >
            <option value="">All services</option>
            {services.map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
        </div>

        <div className="flex-1 overflow-y-auto font-mono text-xs">
          {loading ? (
            <div className="text-center py-8 text-gray-400">Loading...</div>
          ) : logs.length === 0 ? (
            <div className="text-center py-8 text-gray-400">No logs found</div>
          ) : (
            logs.map((log) => (
              <button
                key={log.id}
                onClick={() => setSelectedLog(log)}
                className={`w-full text-left p-2 border-b border-gray-100 hover:bg-gray-50 ${
                  selectedLog?.id === log.id ? 'bg-agency-50' : ''
                }`}
              >
                <div className="flex items-start gap-2">
                  <span className={`px-1.5 py-0.5 rounded text-[10px] uppercase ${LEVEL_COLORS[log.level]}`}>
                    {log.level}
                  </span>
                  <span className="text-gray-500">{log.service}</span>
                  <span className="flex-1 truncate text-gray-700">{log.message}</span>
                  <span className="text-gray-400 whitespace-nowrap">{formatTime(log.timestamp)}</span>
                </div>
              </button>
            ))
          )}
        </div>

        <div className="p-3 border-t border-gray-200 text-xs text-gray-500">
          {logs.length} entries
        </div>
      </div>

      {/* Log Detail */}
      <div className="flex-1 bg-white rounded-xl border border-gray-200 flex flex-col">
        {selectedLog ? (
          <>
            <div className="p-4 border-b border-gray-200">
              <div className="flex items-center gap-2">
                <span className={`px-2 py-1 rounded text-xs uppercase ${LEVEL_COLORS[selectedLog.level]}`}>
                  {selectedLog.level}
                </span>
                <span className="font-mono text-sm text-gray-600">{selectedLog.service}</span>
                <span className="text-xs text-gray-400">{formatTime(selectedLog.timestamp)}</span>
              </div>
              <p className="mt-2 text-gray-900">{selectedLog.message}</p>
            </div>
            <div className="flex-1 p-4 overflow-y-auto">
              {selectedLog.data ? (
                <pre className="text-xs font-mono bg-gray-50 p-4 rounded-lg overflow-x-auto">
                  {JSON.stringify(selectedLog.data, null, 2)}
                </pre>
              ) : (
                <div className="text-gray-400 italic">No additional data</div>
              )}
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-400">
            Select a log entry to view details
          </div>
        )}
      </div>
    </div>
  );
}
