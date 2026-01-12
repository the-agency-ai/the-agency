'use client';

import { useState, useEffect, useCallback } from 'react';

// Types for all work item resources
type WorkItemType = 'request' | 'bug' | 'idea' | 'observation';

interface BaseItem {
  id: number;
  createdAt: string;
  updatedAt: string;
}

interface Request extends BaseItem {
  requestId: string;
  title: string;
  summary: string;
  status: string;
  priority: string;
  principalName: string;
  workstream: string | null;
  assigneeName: string | null;
}

interface Bug extends BaseItem {
  bugId: string;
  summary: string;
  description: string | null;
  status: string;
  workstream: string;
  reporterName: string;
  assigneeName: string | null;
  tags: string[];
}

interface Idea extends BaseItem {
  ideaId: string;
  title: string;
  description: string | null;
  status: string;
  sourceName: string;
  tags: string[];
  promotedTo: string | null;
}

interface Observation extends BaseItem {
  observationId: string;
  title: string;
  summary: string;
  status: string;
  category: string;
  reporterName: string;
  workstream: string | null;
  tags: string[];
}

type WorkItem = Request | Bug | Idea | Observation;

// Status color mappings
const STATUS_COLORS: Record<string, string> = {
  // Request statuses
  'Open': 'bg-blue-100 text-blue-700',
  'In Progress': 'bg-yellow-100 text-yellow-700',
  'Review': 'bg-purple-100 text-purple-700',
  'Testing': 'bg-indigo-100 text-indigo-700',
  'Complete': 'bg-green-100 text-green-700',
  'On Hold': 'bg-gray-100 text-gray-700',
  'Cancelled': 'bg-red-100 text-red-700',
  // Bug statuses
  'Fixed': 'bg-green-100 text-green-700',
  "Won't Fix": 'bg-gray-100 text-gray-700',
  // Idea statuses
  'captured': 'bg-blue-100 text-blue-700',
  'exploring': 'bg-yellow-100 text-yellow-700',
  'promoted': 'bg-green-100 text-green-700',
  'parked': 'bg-gray-100 text-gray-700',
  'discarded': 'bg-red-100 text-red-700',
  // Observation statuses
  'Acknowledged': 'bg-yellow-100 text-yellow-700',
  'Noted': 'bg-green-100 text-green-700',
  'Archived': 'bg-gray-100 text-gray-700',
};

const PRIORITY_COLORS: Record<string, string> = {
  'Low': 'bg-gray-100 text-gray-600',
  'Medium': 'bg-yellow-100 text-yellow-700',
  'High': 'bg-orange-100 text-orange-700',
  'Critical': 'bg-red-100 text-red-700',
};

const TAB_CONFIG: { id: WorkItemType; label: string; icon: string }[] = [
  { id: 'request', label: 'Requests', icon: '📋' },
  { id: 'bug', label: 'Bugs', icon: '🐛' },
  { id: 'idea', label: 'Ideas', icon: '💡' },
  { id: 'observation', label: 'Observations', icon: '👁️' },
];

export default function WorkItemsPage() {
  const [activeTab, setActiveTab] = useState<WorkItemType>('request');
  const [items, setItems] = useState<WorkItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedItem, setSelectedItem] = useState<WorkItem | null>(null);
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');

  const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3141/api';

  const loadItems = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      let url = `${API_BASE}/${activeTab}/list?limit=100`;
      if (searchQuery) {
        url += `&search=${encodeURIComponent(searchQuery)}`;
      }
      if (statusFilter !== 'all') {
        url += `&status=${encodeURIComponent(statusFilter)}`;
      }

      const response = await fetch(url);
      if (!response.ok) throw new Error(`Failed to load ${activeTab}s`);

      const data = await response.json();
      // Handle different response structures
      const itemList = data.requests || data.bugs || data.ideas || data.observations || [];
      setItems(itemList);
    } catch (err) {
      setError(err instanceof Error ? err.message : `Failed to load ${activeTab}s`);
    } finally {
      setLoading(false);
    }
  }, [activeTab, statusFilter, searchQuery, API_BASE]);

  useEffect(() => {
    loadItems();
    setSelectedItem(null);
  }, [loadItems]);

  // Get ID field based on type
  const getItemId = (item: WorkItem): string => {
    if ('requestId' in item) return item.requestId;
    if ('bugId' in item) return item.bugId;
    if ('ideaId' in item) return item.ideaId;
    if ('observationId' in item) return item.observationId;
    return String((item as BaseItem).id);
  };

  // Get title field based on type
  const getItemTitle = (item: WorkItem): string => {
    const anyItem = item as Request | Bug | Idea | Observation;
    if ('title' in anyItem && anyItem.title) return anyItem.title;
    if ('summary' in anyItem && anyItem.summary) return anyItem.summary;
    return 'Untitled';
  };

  // Get status options based on type
  const getStatusOptions = (): string[] => {
    switch (activeTab) {
      case 'request':
        return ['Open', 'In Progress', 'Review', 'Testing', 'Complete', 'On Hold', 'Cancelled'];
      case 'bug':
        return ['Open', 'In Progress', 'Fixed', "Won't Fix"];
      case 'idea':
        return ['captured', 'exploring', 'promoted', 'parked', 'discarded'];
      case 'observation':
        return ['Open', 'Acknowledged', 'Noted', 'Archived'];
      default:
        return [];
    }
  };

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

  // Update item status
  const updateStatus = async (itemId: string, newStatus: string) => {
    try {
      const response = await fetch(`${API_BASE}/${activeTab}/update/${itemId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: newStatus }),
      });

      if (!response.ok) throw new Error('Failed to update status');
      loadItems();
    } catch (err) {
      console.error('Failed to update status:', err);
    }
  };

  // Render item details
  const renderDetails = (item: WorkItem) => {
    const itemId = getItemId(item);

    return (
      <>
        <div className="p-4 border-b border-gray-200">
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <div className="flex items-center gap-2 flex-wrap">
                <span className="font-mono text-sm text-gray-500">{itemId}</span>
                {'priority' in item && (
                  <span className={`text-xs px-2 py-0.5 rounded ${PRIORITY_COLORS[item.priority] || 'bg-gray-100'}`}>
                    {item.priority}
                  </span>
                )}
                {'category' in item && (
                  <span className="text-xs px-2 py-0.5 rounded bg-purple-100 text-purple-700">
                    {item.category}
                  </span>
                )}
                {'workstream' in item && item.workstream && (
                  <span className="text-xs px-2 py-0.5 rounded bg-gray-100 text-gray-600">
                    {item.workstream}
                  </span>
                )}
              </div>
              <h2 className="text-lg font-medium text-gray-900 mt-2">
                {getItemTitle(item)}
              </h2>
            </div>
            <select
              value={item.status}
              onChange={(e) => updateStatus(itemId, e.target.value)}
              className={`px-3 py-1 rounded-lg border-0 text-sm font-medium ${STATUS_COLORS[item.status] || 'bg-gray-100'}`}
            >
              {getStatusOptions().map((s) => (
                <option key={s} value={s}>{s}</option>
              ))}
            </select>
          </div>

          <div className="flex gap-4 mt-3 text-sm text-gray-500 flex-wrap">
            {'principalName' in item && (
              <div>Principal: <span className="text-gray-700">{item.principalName}</span></div>
            )}
            {'reporterName' in item && (
              <div>Reporter: <span className="text-gray-700">{item.reporterName}</span></div>
            )}
            {'sourceName' in item && (
              <div>Source: <span className="text-gray-700">{item.sourceName}</span></div>
            )}
            {'assigneeName' in item && item.assigneeName && (
              <div>Assignee: <span className="text-gray-700">{item.assigneeName}</span></div>
            )}
            {'promotedTo' in item && item.promotedTo && (
              <div>Promoted to: <span className="text-gray-700">{item.promotedTo}</span></div>
            )}
          </div>

          {'tags' in item && item.tags.length > 0 && (
            <div className="flex gap-1 mt-3">
              {item.tags.map((tag) => (
                <span key={tag} className="text-xs px-2 py-0.5 rounded bg-blue-100 text-blue-700">
                  {tag}
                </span>
              ))}
            </div>
          )}
        </div>

        <div className="flex-1 p-4 overflow-y-auto">
          {'description' in item && item.description ? (
            <div className="prose prose-sm max-w-none whitespace-pre-wrap">
              {item.description}
            </div>
          ) : 'summary' in item && 'title' in item ? (
            <div className="prose prose-sm max-w-none whitespace-pre-wrap">
              {item.summary}
            </div>
          ) : (
            <div className="text-gray-400 italic">No description provided</div>
          )}
        </div>

        <div className="p-4 border-t border-gray-200 bg-gray-50 text-xs text-gray-500">
          Created: {formatTime(item.createdAt)} &middot; Updated: {formatTime(item.updatedAt)}
        </div>
      </>
    );
  };

  if (error) {
    return (
      <div className="p-8">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
          <p className="font-medium">Error loading {activeTab}s</p>
          <p className="text-sm mt-1">{error}</p>
          <p className="text-sm mt-2">Make sure agency-service is running on port 3141</p>
          <button
            onClick={loadItems}
            className="mt-3 px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-[calc(100vh-8rem)]">
      {/* Tabs */}
      <div className="flex gap-2 mb-4">
        {TAB_CONFIG.map((tab) => (
          <button
            key={tab.id}
            onClick={() => {
              setActiveTab(tab.id);
              setStatusFilter('all');
              setSearchQuery('');
            }}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              activeTab === tab.id
                ? 'bg-agency-600 text-white'
                : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
            }`}
          >
            <span>{tab.icon}</span>
            <span>{tab.label}</span>
          </button>
        ))}
      </div>

      <div className="flex flex-1 gap-4 min-h-0">
        {/* Item List */}
        <div className="w-96 bg-white rounded-xl border border-gray-200 flex flex-col">
          {/* Filters */}
          <div className="p-3 border-b border-gray-200 space-y-2">
            <input
              type="text"
              placeholder="Search..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full px-3 py-1.5 text-sm border border-gray-200 rounded-lg focus:ring-agency-500 focus:border-agency-500"
            />
            <div className="flex gap-1 flex-wrap">
              <button
                onClick={() => setStatusFilter('all')}
                className={`px-2 py-1 text-xs rounded-full ${
                  statusFilter === 'all'
                    ? 'bg-agency-600 text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                All
              </button>
              {getStatusOptions().slice(0, 4).map((s) => (
                <button
                  key={s}
                  onClick={() => setStatusFilter(s)}
                  className={`px-2 py-1 text-xs rounded-full ${
                    statusFilter === s
                      ? 'bg-agency-600 text-white'
                      : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                >
                  {s}
                </button>
              ))}
            </div>
          </div>

          {/* List */}
          <div className="flex-1 overflow-y-auto">
            {loading ? (
              <div className="text-center py-8 text-gray-400">Loading...</div>
            ) : items.length === 0 ? (
              <div className="text-center py-8 text-gray-400">No {activeTab}s found</div>
            ) : (
              items.map((item) => {
                const itemId = getItemId(item);
                const isSelected = selectedItem && getItemId(selectedItem) === itemId;

                return (
                  <button
                    key={item.id}
                    onClick={() => setSelectedItem(item)}
                    className={`w-full text-left p-3 border-b border-gray-100 hover:bg-gray-50 ${
                      isSelected ? 'bg-agency-50' : ''
                    }`}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <span className="font-mono text-xs text-gray-500">{itemId}</span>
                          <span className={`text-xs px-1.5 py-0.5 rounded ${STATUS_COLORS[item.status] || 'bg-gray-100'}`}>
                            {item.status}
                          </span>
                        </div>
                        <div className="text-sm text-gray-900 truncate mt-1">
                          {getItemTitle(item)}
                        </div>
                      </div>
                      <div className="text-xs text-gray-400 whitespace-nowrap">
                        {formatTime(item.createdAt)}
                      </div>
                    </div>
                  </button>
                );
              })
            )}
          </div>

          {/* Stats */}
          <div className="p-3 border-t border-gray-200 text-xs text-gray-500">
            {items.length} {activeTab}s
          </div>
        </div>

        {/* Detail Panel */}
        <div className="flex-1 bg-white rounded-xl border border-gray-200 flex flex-col">
          {selectedItem ? (
            renderDetails(selectedItem)
          ) : (
            <div className="flex-1 flex items-center justify-center text-gray-400">
              Select a {activeTab} to view details
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
