'use client';

import { useState, useEffect, useCallback } from 'react';

// ─────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────

type LogLevel = 'trace' | 'debug' | 'info' | 'warn' | 'error' | 'fatal';

interface LogEntry {
  id: number;
  timestamp: string;
  service: string;
  level: LogLevel;
  message: string;
  runId?: string;
  requestId?: string;
  userId?: string;
  userType?: 'agent' | 'principal' | 'system';
  data?: Record<string, unknown>;
  error?: {
    name: string;
    message: string;
    stack?: string;
  };
}

interface LogListResponse {
  logs: LogEntry[];
  total: number;
  limit: number;
  offset: number;
}

interface LogStats {
  total: number;
  byLevel: Record<LogLevel, number>;
  byService: Record<string, number>;
  errorsLastHour: number;
}

// ─────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3456/api/log';

const LEVEL_COLORS: Record<LogLevel, { bg: string; text: string; dot: string }> = {
  trace: { bg: 'bg-gray-100', text: 'text-gray-600', dot: 'bg-gray-400' },
  debug: { bg: 'bg-gray-100', text: 'text-gray-600', dot: 'bg-gray-400' },
  info: { bg: 'bg-blue-100', text: 'text-blue-700', dot: 'bg-blue-500' },
  warn: { bg: 'bg-yellow-100', text: 'text-yellow-700', dot: 'bg-yellow-500' },
  error: { bg: 'bg-red-100', text: 'text-red-700', dot: 'bg-red-500' },
  fatal: { bg: 'bg-red-200', text: 'text-red-900', dot: 'bg-red-700' },
};

const LEVEL_ORDER: LogLevel[] = ['fatal', 'error', 'warn', 'info', 'debug', 'trace'];

const TIME_RANGES = [
  { label: '15m', value: '15m' },
  { label: '1h', value: '1h' },
  { label: '6h', value: '6h' },
  { label: '24h', value: '24h' },
  { label: '7d', value: '7d' },
];

// ─────────────────────────────────────────────────────────────
// Components
// ─────────────────────────────────────────────────────────────

function LevelBadge({ level }: { level: LogLevel }) {
  const colors = LEVEL_COLORS[level];
  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${colors.bg} ${colors.text}`}>
      {level.toUpperCase()}
    </span>
  );
}

function StatCard({ label, value, sublabel, variant = 'default' }: {
  label: string;
  value: number | string;
  sublabel?: string;
  variant?: 'default' | 'error' | 'warning';
}) {
  const variants = {
    default: 'bg-white border-gray-200',
    error: 'bg-red-50 border-red-200',
    warning: 'bg-yellow-50 border-yellow-200',
  };

  return (
    <div className={`rounded-lg border p-4 ${variants[variant]}`}>
      <div className="text-sm text-gray-500">{label}</div>
      <div className="text-2xl font-semibold mt-1">{value}</div>
      {sublabel && <div className="text-xs text-gray-400 mt-1">{sublabel}</div>}
    </div>
  );
}

function LogDetailPanel({ log, onClose }: { log: LogEntry; onClose: () => void }) {
  const [copied, setCopied] = useState(false);

  const copyToClipboard = async () => {
    const text = JSON.stringify(log, null, 2);
    await navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const formatTimestamp = (ts: string) => {
    const date = new Date(ts);
    return date.toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      fractionalSecondDigits: 3,
    });
  };

  return (
    <div className="bg-white rounded-xl border border-gray-200 flex flex-col h-full">
      {/* Header */}
      <div className="p-4 border-b border-gray-200 flex items-start justify-between">
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <LevelBadge level={log.level} />
            <span className="text-sm font-medium text-gray-700">{log.service}</span>
          </div>
          <div className="text-xs text-gray-500 mt-1">{formatTimestamp(log.timestamp)}</div>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={copyToClipboard}
            className="px-3 py-1 text-sm bg-gray-100 text-gray-700 rounded hover:bg-gray-200 transition-colors"
          >
            {copied ? 'Copied!' : 'Copy JSON'}
          </button>
          <button
            onClick={onClose}
            className="p-1 text-gray-400 hover:text-gray-600 transition-colors"
            title="Close"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {/* Message */}
        <div>
          <div className="text-xs font-medium text-gray-500 uppercase mb-1">Message</div>
          <div className="text-sm text-gray-900 bg-gray-50 rounded-lg p-3 font-mono whitespace-pre-wrap break-words">
            {log.message}
          </div>
        </div>

        {/* Context */}
        <div className="grid grid-cols-2 gap-4">
          {log.runId && (
            <div>
              <div className="text-xs font-medium text-gray-500 uppercase mb-1">Run ID</div>
              <div className="text-sm text-gray-700 font-mono">{log.runId}</div>
            </div>
          )}
          {log.requestId && (
            <div>
              <div className="text-xs font-medium text-gray-500 uppercase mb-1">Request ID</div>
              <div className="text-sm text-gray-700 font-mono">{log.requestId}</div>
            </div>
          )}
          {log.userId && (
            <div>
              <div className="text-xs font-medium text-gray-500 uppercase mb-1">User</div>
              <div className="text-sm text-gray-700">
                {log.userType && <span className="text-gray-500">{log.userType}:</span>}
                {log.userId}
              </div>
            </div>
          )}
        </div>

        {/* Error Details */}
        {log.error && (
          <div>
            <div className="text-xs font-medium text-red-500 uppercase mb-1">Error</div>
            <div className="bg-red-50 rounded-lg p-3 border border-red-200">
              <div className="text-sm font-medium text-red-700">{log.error.name}: {log.error.message}</div>
              {log.error.stack && (
                <pre className="mt-2 text-xs text-red-600 overflow-x-auto whitespace-pre-wrap font-mono">
                  {log.error.stack}
                </pre>
              )}
            </div>
          </div>
        )}

        {/* Data */}
        {log.data && Object.keys(log.data).length > 0 && (
          <div>
            <div className="text-xs font-medium text-gray-500 uppercase mb-1">Data</div>
            <pre className="text-xs text-gray-700 bg-gray-50 rounded-lg p-3 overflow-x-auto font-mono">
              {JSON.stringify(log.data, null, 2)}
            </pre>
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="p-3 border-t border-gray-200 bg-gray-50 text-xs text-gray-500">
        Log ID: {log.id}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Main Page
// ─────────────────────────────────────────────────────────────

export default function LogsPage() {
  // State
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [stats, setStats] = useState<LogStats | null>(null);
  const [services, setServices] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedLog, setSelectedLog] = useState<LogEntry | null>(null);

  // Filters
  const [levelFilter, setLevelFilter] = useState<LogLevel | 'all'>('all');
  const [serviceFilter, setServiceFilter] = useState<string>('all');
  const [timeRange, setTimeRange] = useState<string>('1h');
  const [searchText, setSearchText] = useState<string>('');
  const [searchInput, setSearchInput] = useState<string>('');

  // Polling
  const [newLogsAvailable, setNewLogsAvailable] = useState(false);
  const [lastFetchTime, setLastFetchTime] = useState<Date | null>(null);
  const [autoRefresh, setAutoRefresh] = useState(true);

  // ─────────────────────────────────────────────────────────────
  // Data Fetching
  // ─────────────────────────────────────────────────────────────

  const fetchLogs = useCallback(async (showLoading = true) => {
    try {
      if (showLoading) setLoading(true);
      setError(null);

      const params = new URLSearchParams({
        limit: '200',
        since: timeRange,
      });

      if (levelFilter !== 'all') {
        params.set('level', levelFilter);
      }
      if (serviceFilter !== 'all') {
        params.set('service', serviceFilter);
      }
      if (searchText) {
        params.set('search', searchText);
      }

      const response = await fetch(`${API_BASE}/query?${params}`);
      if (!response.ok) throw new Error('Failed to fetch logs');

      const data: LogListResponse = await response.json();
      setLogs(data.logs);
      setLastFetchTime(new Date());
      setNewLogsAvailable(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load logs');
    } finally {
      setLoading(false);
    }
  }, [levelFilter, serviceFilter, timeRange, searchText]);

  const fetchStats = useCallback(async () => {
    try {
      const response = await fetch(`${API_BASE}/stats`);
      if (!response.ok) throw new Error('Failed to fetch stats');
      const data: LogStats = await response.json();
      setStats(data);
    } catch (err) {
      console.error('Failed to fetch stats:', err);
    }
  }, []);

  const fetchServices = useCallback(async () => {
    try {
      const response = await fetch(`${API_BASE}/services`);
      if (!response.ok) throw new Error('Failed to fetch services');
      const data = await response.json();
      setServices(data.services || []);
    } catch (err) {
      console.error('Failed to fetch services:', err);
    }
  }, []);

  const checkForNewLogs = useCallback(async () => {
    if (!lastFetchTime || !autoRefresh) return;

    try {
      const params = new URLSearchParams({
        limit: '1',
        since: '1m',
      });

      const response = await fetch(`${API_BASE}/query?${params}`);
      if (!response.ok) return;

      const data: LogListResponse = await response.json();
      if (data.logs.length > 0) {
        const newestLog = new Date(data.logs[0].timestamp);
        if (newestLog > lastFetchTime) {
          setNewLogsAvailable(true);
        }
      }
    } catch {
      // Silently fail for background checks
    }
  }, [lastFetchTime, autoRefresh]);

  // ─────────────────────────────────────────────────────────────
  // Effects
  // ─────────────────────────────────────────────────────────────

  // Initial load
  useEffect(() => {
    fetchLogs();
    fetchStats();
    fetchServices();
  }, [fetchLogs, fetchStats, fetchServices]);

  // Polling for new logs
  useEffect(() => {
    if (!autoRefresh) return;

    const interval = setInterval(() => {
      checkForNewLogs();
      fetchStats(); // Also refresh stats
    }, 5000);

    return () => clearInterval(interval);
  }, [autoRefresh, checkForNewLogs, fetchStats]);

  // ─────────────────────────────────────────────────────────────
  // Handlers
  // ─────────────────────────────────────────────────────────────

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setSearchText(searchInput);
  };

  const handleRefresh = () => {
    fetchLogs();
    fetchStats();
  };

  const handleLoadNewLogs = () => {
    fetchLogs();
  };

  const formatTime = (ts: string) => {
    const date = new Date(ts);
    return date.toLocaleString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      fractionalSecondDigits: 3,
    });
  };

  const formatDate = (ts: string) => {
    const date = new Date(ts);
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
    });
  };

  // ─────────────────────────────────────────────────────────────
  // Render
  // ─────────────────────────────────────────────────────────────

  if (error) {
    return (
      <div className="p-8">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
          <p className="font-medium">Error loading logs</p>
          <p className="text-sm mt-1">{error}</p>
          <p className="text-sm mt-2">Make sure agency-service is running on port 3456</p>
          <button
            onClick={() => fetchLogs()}
            className="mt-3 px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-[calc(100vh-8rem)] gap-4">
      {/* Stats Panel */}
      <div className="grid grid-cols-4 gap-4">
        <StatCard
          label="Total Logs"
          value={stats?.total.toLocaleString() ?? '-'}
          sublabel={timeRange === '24h' ? 'Last 24 hours' : `Last ${timeRange}`}
        />
        <StatCard
          label="Errors (1hr)"
          value={stats?.errorsLastHour ?? 0}
          variant={stats?.errorsLastHour && stats.errorsLastHour > 0 ? 'error' : 'default'}
        />
        <StatCard
          label="Warnings"
          value={stats?.byLevel.warn ?? 0}
          variant={stats?.byLevel.warn && stats.byLevel.warn > 10 ? 'warning' : 'default'}
        />
        <StatCard
          label="Services"
          value={services.length}
          sublabel="Active sources"
        />
      </div>

      {/* Filters Bar */}
      <div className="bg-white rounded-xl border border-gray-200 p-4">
        <div className="flex flex-wrap items-center gap-4">
          {/* Level Filter */}
          <div className="flex items-center gap-2">
            <label className="text-sm text-gray-600">Level:</label>
            <select
              value={levelFilter}
              onChange={(e) => setLevelFilter(e.target.value as LogLevel | 'all')}
              className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm focus:ring-agency-500 focus:border-agency-500"
            >
              <option value="all">All</option>
              {LEVEL_ORDER.map((level) => (
                <option key={level} value={level}>
                  {level.toUpperCase()}
                </option>
              ))}
            </select>
          </div>

          {/* Service Filter */}
          <div className="flex items-center gap-2">
            <label className="text-sm text-gray-600">Service:</label>
            <select
              value={serviceFilter}
              onChange={(e) => setServiceFilter(e.target.value)}
              className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm focus:ring-agency-500 focus:border-agency-500"
            >
              <option value="all">All</option>
              {services.map((service) => (
                <option key={service} value={service}>
                  {service}
                </option>
              ))}
            </select>
          </div>

          {/* Time Range */}
          <div className="flex items-center gap-2">
            <label className="text-sm text-gray-600">Time:</label>
            <div className="flex rounded-lg border border-gray-300 overflow-hidden">
              {TIME_RANGES.map((range) => (
                <button
                  key={range.value}
                  onClick={() => setTimeRange(range.value)}
                  className={`px-3 py-1.5 text-sm border-r border-gray-300 last:border-r-0 transition-colors ${
                    timeRange === range.value
                      ? 'bg-agency-600 text-white'
                      : 'bg-white text-gray-600 hover:bg-gray-50'
                  }`}
                >
                  {range.label}
                </button>
              ))}
            </div>
          </div>

          {/* Search */}
          <form onSubmit={handleSearch} className="flex-1 min-w-[200px]">
            <div className="relative">
              <input
                type="text"
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
                placeholder="Search logs..."
                className="w-full px-3 py-1.5 pr-20 border border-gray-300 rounded-lg text-sm focus:ring-agency-500 focus:border-agency-500"
              />
              <button
                type="submit"
                className="absolute right-1 top-1 px-3 py-0.5 bg-agency-600 text-white text-sm rounded hover:bg-agency-700"
              >
                Search
              </button>
            </div>
          </form>

          {/* Actions */}
          <div className="flex items-center gap-2">
            <button
              onClick={() => setAutoRefresh(!autoRefresh)}
              className={`px-3 py-1.5 text-sm rounded-lg border transition-colors ${
                autoRefresh
                  ? 'bg-green-100 text-green-700 border-green-300'
                  : 'bg-gray-100 text-gray-600 border-gray-300'
              }`}
              title={autoRefresh ? 'Auto-refresh enabled' : 'Auto-refresh disabled'}
            >
              {autoRefresh ? 'Live' : 'Paused'}
            </button>
            <button
              onClick={handleRefresh}
              className="p-1.5 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
              title="Refresh"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
            </button>
          </div>
        </div>

        {/* Active filters display */}
        {(searchText || levelFilter !== 'all' || serviceFilter !== 'all') && (
          <div className="flex items-center gap-2 mt-3 pt-3 border-t border-gray-100">
            <span className="text-xs text-gray-500">Active filters:</span>
            {levelFilter !== 'all' && (
              <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-gray-100 rounded text-xs">
                Level: {levelFilter.toUpperCase()}
                <button onClick={() => setLevelFilter('all')} className="text-gray-400 hover:text-gray-600">
                  <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </span>
            )}
            {serviceFilter !== 'all' && (
              <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-gray-100 rounded text-xs">
                Service: {serviceFilter}
                <button onClick={() => setServiceFilter('all')} className="text-gray-400 hover:text-gray-600">
                  <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </span>
            )}
            {searchText && (
              <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-gray-100 rounded text-xs">
                Search: &quot;{searchText}&quot;
                <button onClick={() => { setSearchText(''); setSearchInput(''); }} className="text-gray-400 hover:text-gray-600">
                  <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </span>
            )}
            <button
              onClick={() => {
                setLevelFilter('all');
                setServiceFilter('all');
                setSearchText('');
                setSearchInput('');
              }}
              className="text-xs text-agency-600 hover:text-agency-700"
            >
              Clear all
            </button>
          </div>
        )}
      </div>

      {/* New logs indicator */}
      {newLogsAvailable && (
        <button
          onClick={handleLoadNewLogs}
          className="bg-agency-100 text-agency-700 border border-agency-200 rounded-lg p-2 text-center text-sm hover:bg-agency-200 transition-colors"
        >
          New logs available - Click to refresh
        </button>
      )}

      {/* Main Content */}
      <div className="flex-1 flex gap-4 min-h-0">
        {/* Log List */}
        <div className={`bg-white rounded-xl border border-gray-200 flex flex-col ${selectedLog ? 'w-1/2' : 'flex-1'}`}>
          {/* Table Header */}
          <div className="grid grid-cols-[100px_70px_120px_1fr] gap-2 px-4 py-2 bg-gray-50 border-b border-gray-200 text-xs font-medium text-gray-500 uppercase">
            <div>Time</div>
            <div>Level</div>
            <div>Service</div>
            <div>Message</div>
          </div>

          {/* Log Rows */}
          <div className="flex-1 overflow-y-auto">
            {loading ? (
              <div className="flex items-center justify-center h-32 text-gray-400">
                <svg className="animate-spin h-6 w-6 mr-2" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                Loading logs...
              </div>
            ) : logs.length === 0 ? (
              <div className="flex flex-col items-center justify-center h-32 text-gray-400">
                <svg className="w-12 h-12 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                <span>No logs found</span>
                <span className="text-xs mt-1">Try adjusting your filters</span>
              </div>
            ) : (
              logs.map((log) => {
                const colors = LEVEL_COLORS[log.level];
                const isSelected = selectedLog?.id === log.id;
                const hasError = !!log.error;

                return (
                  <button
                    key={log.id}
                    onClick={() => setSelectedLog(log)}
                    className={`w-full text-left grid grid-cols-[100px_70px_120px_1fr] gap-2 px-4 py-2 border-b border-gray-100 hover:bg-gray-50 transition-colors ${
                      isSelected ? 'bg-agency-50' : ''
                    }`}
                  >
                    {/* Time */}
                    <div className="text-xs text-gray-500 font-mono">
                      <div>{formatTime(log.timestamp)}</div>
                      <div className="text-gray-400">{formatDate(log.timestamp)}</div>
                    </div>

                    {/* Level */}
                    <div>
                      <span className={`inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-xs font-medium ${colors.bg} ${colors.text}`}>
                        <span className={`w-1.5 h-1.5 rounded-full ${colors.dot}`} />
                        {log.level.toUpperCase()}
                      </span>
                    </div>

                    {/* Service */}
                    <div className="text-xs text-gray-600 font-medium truncate" title={log.service}>
                      {log.service}
                    </div>

                    {/* Message */}
                    <div className="min-w-0">
                      <div className="text-sm text-gray-900 truncate" title={log.message}>
                        {log.message}
                      </div>
                      <div className="flex items-center gap-2 mt-0.5">
                        {hasError && (
                          <span className="text-xs text-red-600 bg-red-50 px-1 rounded">
                            {log.error?.name}
                          </span>
                        )}
                        {log.runId && (
                          <span className="text-xs text-gray-400 font-mono truncate" title={log.runId}>
                            run:{log.runId.slice(0, 8)}
                          </span>
                        )}
                      </div>
                    </div>
                  </button>
                );
              })
            )}
          </div>

          {/* Footer */}
          <div className="px-4 py-2 border-t border-gray-200 bg-gray-50 text-xs text-gray-500 flex justify-between items-center">
            <span>Showing {logs.length} logs</span>
            {lastFetchTime && (
              <span>Last updated: {lastFetchTime.toLocaleTimeString()}</span>
            )}
          </div>
        </div>

        {/* Detail Panel */}
        {selectedLog && (
          <div className="w-1/2">
            <LogDetailPanel log={selectedLog} onClose={() => setSelectedLog(null)} />
          </div>
        )}
      </div>
    </div>
  );
}
