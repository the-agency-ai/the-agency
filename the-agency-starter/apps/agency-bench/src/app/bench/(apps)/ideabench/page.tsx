'use client';

import { useState, useEffect } from 'react';

interface Idea {
  id: number;
  ideaId: string;
  title: string;
  description: string | null;
  status: 'captured' | 'exploring' | 'promoted' | 'parked' | 'discarded';
  sourceType: string;
  sourceName: string;
  tags: string[];
  promotedTo: string | null;
  createdAt: string;
  updatedAt: string;
}

interface IdeaListResponse {
  ideas: Idea[];
  total: number;
}

const STATUS_COLORS: Record<string, string> = {
  'captured': 'bg-blue-100 text-blue-700',
  'exploring': 'bg-purple-100 text-purple-700',
  'promoted': 'bg-green-100 text-green-700',
  'parked': 'bg-yellow-100 text-yellow-700',
  'discarded': 'bg-gray-100 text-gray-500',
};

const STATUS_LABELS: Record<string, string> = {
  'captured': 'Captured',
  'exploring': 'Exploring',
  'promoted': 'Promoted',
  'parked': 'Parked',
  'discarded': 'Discarded',
};

export default function IdeaBenchPage() {
  const [ideas, setIdeas] = useState<Idea[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedIdea, setSelectedIdea] = useState<Idea | null>(null);
  const [filter, setFilter] = useState<'all' | 'captured' | 'exploring' | 'parked'>('all');
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  // Form state
  const [newIdea, setNewIdea] = useState({
    title: '',
    description: '',
    sourceType: 'principal',
    sourceName: '',
    tags: '',
  });

  const API_BASE = process.env.NEXT_PUBLIC_API_URL?.replace('/bug', '/idea') || 'http://localhost:3456/api/idea';

  useEffect(() => {
    loadIdeas();
  }, []);

  async function loadIdeas() {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE}/list?limit=100`);
      if (!response.ok) throw new Error('Failed to load ideas');
      const data: IdeaListResponse = await response.json();
      setIdeas(data.ideas);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load ideas');
    } finally {
      setLoading(false);
    }
  }

  async function createIdea() {
    if (!newIdea.title.trim() || !newIdea.sourceName.trim()) {
      setActionError('Title and source name are required');
      return;
    }

    setSubmitting(true);
    setActionError(null);

    try {
      const response = await fetch(`${API_BASE}/create`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...newIdea,
          tags: newIdea.tags.split(',').map(t => t.trim()).filter(Boolean),
        }),
      });

      if (!response.ok) throw new Error('Failed to create idea');

      setShowCreateForm(false);
      setNewIdea({
        title: '',
        description: '',
        sourceType: 'principal',
        sourceName: '',
        tags: '',
      });
      loadIdeas();
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Failed to create idea');
    } finally {
      setSubmitting(false);
    }
  }

  async function updateStatus(ideaId: string, action: string) {
    setSubmitting(true);
    setActionError(null);

    try {
      const response = await fetch(`${API_BASE}/${action}/${ideaId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      });

      if (!response.ok) throw new Error(`Failed to ${action} idea`);
      loadIdeas();
      const updated = await response.json();
      if (selectedIdea?.ideaId === ideaId) {
        setSelectedIdea(updated);
      }
    } catch (err) {
      setActionError(err instanceof Error ? err.message : `Failed to ${action} idea`);
    } finally {
      setSubmitting(false);
    }
  }

  // Filter ideas
  const filteredIdeas = ideas.filter((i) => {
    if (filter === 'all') return i.status !== 'discarded';
    return i.status === filter;
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
          <p className="font-medium">Error loading ideas</p>
          <p className="text-sm mt-1">{error}</p>
          <p className="text-sm mt-2">Make sure agency-service is running on port 3456</p>
          <button
            onClick={loadIdeas}
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
      {/* Idea List */}
      <div className="w-96 bg-white rounded-xl border border-gray-200 flex flex-col">
        {/* Header with Create button */}
        <div className="p-3 border-b border-gray-200 flex justify-between items-center">
          <div className="flex gap-2">
            {(['all', 'captured', 'exploring', 'parked'] as const).map((f) => (
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
            + Capture
          </button>
        </div>

        {/* Idea List */}
        <div className="flex-1 overflow-y-auto">
          {loading ? (
            <div className="text-center py-8 text-gray-400">Loading...</div>
          ) : filteredIdeas.length === 0 ? (
            <div className="text-center py-8 text-gray-400">No ideas found</div>
          ) : (
            filteredIdeas.map((idea) => {
              const isSelected = selectedIdea?.id === idea.id;

              return (
                <button
                  key={idea.id}
                  onClick={() => setSelectedIdea(idea)}
                  className={`w-full text-left p-3 border-b border-gray-100 hover:bg-gray-50 ${
                    isSelected ? 'bg-agency-50' : ''
                  }`}
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs text-gray-500">{idea.ideaId}</span>
                        <span className={`text-xs px-1.5 py-0.5 rounded ${STATUS_COLORS[idea.status]}`}>
                          {STATUS_LABELS[idea.status]}
                        </span>
                      </div>
                      <div className="text-sm text-gray-900 truncate mt-1">
                        {idea.title}
                      </div>
                      {idea.tags.length > 0 && (
                        <div className="flex gap-1 mt-1">
                          {idea.tags.slice(0, 3).map((tag) => (
                            <span key={tag} className="text-xs px-1.5 py-0.5 bg-gray-100 text-gray-600 rounded">
                              {tag}
                            </span>
                          ))}
                        </div>
                      )}
                    </div>
                    <div className="text-xs text-gray-400">
                      {formatTime(idea.createdAt)}
                    </div>
                  </div>
                </button>
              );
            })
          )}
        </div>

        {/* Stats */}
        <div className="p-3 border-t border-gray-200 text-xs text-gray-500">
          {ideas.filter(i => i.status !== 'discarded').length} ideas &middot;{' '}
          {ideas.filter(i => i.status === 'captured').length} new
        </div>
      </div>

      {/* Idea Detail or Create Form */}
      <div className="flex-1 bg-white rounded-xl border border-gray-200 flex flex-col">
        {showCreateForm ? (
          <div className="p-4">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-medium">Capture New Idea</h2>
              <button
                onClick={() => setShowCreateForm(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                Cancel
              </button>
            </div>

            {actionError && (
              <div className="mb-4 p-3 bg-red-50 text-red-700 text-sm rounded-lg">
                {actionError}
              </div>
            )}

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Title *</label>
                <input
                  type="text"
                  value={newIdea.title}
                  onChange={(e) => setNewIdea({ ...newIdea, title: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-agency-500 focus:border-agency-500"
                  placeholder="What's the idea?"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                <textarea
                  value={newIdea.description}
                  onChange={(e) => setNewIdea({ ...newIdea, description: e.target.value })}
                  rows={4}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-agency-500 focus:border-agency-500"
                  placeholder="Elaborate on the idea..."
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Your Name *</label>
                  <input
                    type="text"
                    value={newIdea.sourceName}
                    onChange={(e) => setNewIdea({ ...newIdea, sourceName: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-agency-500 focus:border-agency-500"
                    placeholder="Who had this idea?"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Tags</label>
                  <input
                    type="text"
                    value={newIdea.tags}
                    onChange={(e) => setNewIdea({ ...newIdea, tags: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-agency-500 focus:border-agency-500"
                    placeholder="ui, tooling, api (comma-separated)"
                  />
                </div>
              </div>

              <button
                onClick={createIdea}
                disabled={submitting}
                className="w-full py-2 bg-agency-600 text-white rounded-lg hover:bg-agency-700 disabled:opacity-50"
              >
                {submitting ? 'Capturing...' : 'Capture Idea'}
              </button>
            </div>
          </div>
        ) : selectedIdea ? (
          <>
            <div className="p-4 border-b border-gray-200">
              <div className="flex items-start justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-mono text-sm text-gray-500">{selectedIdea.ideaId}</span>
                    <span className={`text-xs px-1.5 py-0.5 rounded ${STATUS_COLORS[selectedIdea.status]}`}>
                      {STATUS_LABELS[selectedIdea.status]}
                    </span>
                    {selectedIdea.promotedTo && (
                      <span className="text-xs px-1.5 py-0.5 bg-green-50 text-green-700 rounded">
                        → {selectedIdea.promotedTo}
                      </span>
                    )}
                  </div>
                  <h2 className="text-lg font-medium text-gray-900 mt-1">
                    {selectedIdea.title}
                  </h2>
                </div>
              </div>

              <div className="flex gap-4 mt-3 text-sm text-gray-500">
                <div>
                  From: <span className="text-gray-700">{selectedIdea.sourceType}:{selectedIdea.sourceName}</span>
                </div>
              </div>

              {selectedIdea.tags.length > 0 && (
                <div className="flex gap-1 mt-3">
                  {selectedIdea.tags.map((tag) => (
                    <span key={tag} className="text-xs px-2 py-1 bg-gray-100 text-gray-600 rounded">
                      {tag}
                    </span>
                  ))}
                </div>
              )}
            </div>

            <div className="flex-1 p-4 overflow-y-auto">
              {selectedIdea.description ? (
                <div className="prose prose-sm max-w-none whitespace-pre-wrap">
                  {selectedIdea.description}
                </div>
              ) : (
                <div className="text-gray-400 italic">No description provided</div>
              )}
            </div>

            {/* Actions */}
            {selectedIdea.status !== 'promoted' && selectedIdea.status !== 'discarded' && (
              <div className="p-4 border-t border-gray-200 bg-gray-50">
                <div className="flex gap-2">
                  {selectedIdea.status === 'captured' && (
                    <button
                      onClick={() => updateStatus(selectedIdea.ideaId, 'explore')}
                      disabled={submitting}
                      className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 disabled:opacity-50"
                    >
                      Start Exploring
                    </button>
                  )}
                  <button
                    onClick={() => updateStatus(selectedIdea.ideaId, 'park')}
                    disabled={submitting}
                    className="px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 disabled:opacity-50"
                  >
                    Park for Later
                  </button>
                  <button
                    onClick={() => updateStatus(selectedIdea.ideaId, 'discard')}
                    disabled={submitting}
                    className="px-4 py-2 bg-gray-400 text-white rounded-lg hover:bg-gray-500 disabled:opacity-50"
                  >
                    Discard
                  </button>
                </div>
              </div>
            )}

            <div className="p-4 border-t border-gray-200 text-xs text-gray-500">
              Created: {formatTime(selectedIdea.createdAt)} &middot; Updated: {formatTime(selectedIdea.updatedAt)}
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-400">
            Select an idea to view details or click + Capture to add one
          </div>
        )}
      </div>
    </div>
  );
}
