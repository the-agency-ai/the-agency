'use client';

import { useState, useEffect } from 'react';
import { isTauri, readFile, getProjectRoot } from '@/lib/tauri';

interface Collaboration {
  id: string;
  filename: string;
  path: string;
  from: string;
  to: string;
  status: 'pending' | 'completed';
  title: string;
  preview: string;
}

export default function CollaborationInboxPage() {
  const [collaborations, setCollaborations] = useState<Collaboration[]>([]);
  const [selectedCollab, setSelectedCollab] = useState<Collaboration | null>(null);
  const [collabContent, setCollabContent] = useState<string>('');
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'pending' | 'completed'>('all');
  const [projectRoot, setProjectRoot] = useState('');

  useEffect(() => {
    async function loadCollaborations() {
      try {
        const root = await getProjectRoot();
        setProjectRoot(root);

        if (isTauri) {
          const { invoke } = await import('@tauri-apps/api/core');
          const mdFiles: string[] = await invoke('list_markdown_files', { root });

          // Find collaboration files
          const collabFiles = mdFiles.filter(
            (f) => f.includes('/collaboration/') && f.endsWith('.md')
          );

          const collabList = await Promise.all(
            collabFiles.map(async (path) => {
              const filename = path.split('/').pop() || '';
              let from = 'unknown';
              let to = 'unknown';
              let status: 'pending' | 'completed' = 'pending';
              let title = filename.replace('.md', '');
              let preview = '';

              // Try to parse the file
              try {
                const content = await readFile(path);

                // Parse COLLAB-XXX-from-to-title format
                const match = filename.match(/^COLLAB-(\d+)-([^-]+)-([^-]+)-(.+)\.md$/);
                if (match) {
                  from = match[2];
                  to = match[3];
                  title = match[4].replace(/-/g, ' ');
                }

                // Check for status in content
                if (content.toLowerCase().includes('status: completed')) {
                  status = 'completed';
                }

                // Get first non-empty line as preview
                const lines = content.split('\n').filter((l) => l.trim() && !l.startsWith('#'));
                preview = lines[0]?.substring(0, 100) || 'No preview available';
              } catch {
                // Ignore read errors
              }

              return {
                id: filename,
                filename,
                path,
                from,
                to,
                status,
                title,
                preview,
              };
            })
          );

          setCollaborations(collabList.sort((a, b) => b.filename.localeCompare(a.filename)));
        } else {
          // Browser fallback
          setCollaborations([
            {
              id: 'demo-1',
              filename: 'COLLAB-0001-housekeeping-web-setup-help.md',
              path: `${root}/claude/agents/collaboration/COLLAB-0001-housekeeping-web-setup-help.md`,
              from: 'housekeeping',
              to: 'web',
              status: 'pending',
              title: 'setup help',
              preview: 'Need help setting up the web frontend...',
            },
          ]);
        }
      } catch (err) {
        console.error('Failed to load collaborations:', err);
      } finally {
        setLoading(false);
      }
    }

    loadCollaborations();
  }, []);

  useEffect(() => {
    async function loadContent() {
      if (!selectedCollab) {
        setCollabContent('');
        return;
      }

      try {
        const content = await readFile(selectedCollab.path);
        setCollabContent(content);
      } catch (err) {
        console.error('Failed to read collaboration:', err);
        setCollabContent(`# Error\n\nFailed to read: ${selectedCollab.path}`);
      }
    }

    loadContent();
  }, [selectedCollab]);

  const filteredCollabs = collaborations.filter((c) => {
    if (filter === 'all') return true;
    return c.status === filter;
  });

  const pendingCount = collaborations.filter((c) => c.status === 'pending').length;
  const completedCount = collaborations.filter((c) => c.status === 'completed').length;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <h1 className="text-xl font-semibold text-gray-900 mb-2">Collaboration Inbox</h1>
        <p className="text-gray-500 text-sm">
          View and manage collaboration requests between agents.
          {isTauri ? ' Reading from real file system.' : ' Start with tauri:dev for real data.'}
        </p>
        <div className="mt-4 flex gap-4 text-sm">
          <div className="px-3 py-1 bg-yellow-100 rounded-lg text-yellow-700">
            <span className="font-medium">{pendingCount}</span> pending
          </div>
          <div className="px-3 py-1 bg-green-100 rounded-lg text-green-700">
            <span className="font-medium">{completedCount}</span> completed
          </div>
          <div className="px-3 py-1 bg-gray-100 rounded-lg">
            <span className="text-gray-500">Total:</span>{' '}
            <span className="font-medium">{collaborations.length}</span>
          </div>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex gap-2">
        {(['all', 'pending', 'completed'] as const).map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              filter === f
                ? 'bg-agency-600 text-white'
                : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
            }`}
          >
            {f.charAt(0).toUpperCase() + f.slice(1)}
          </button>
        ))}
      </div>

      {/* Collaboration List */}
      {loading ? (
        <div className="bg-white rounded-xl border border-gray-200 p-12 text-center">
          <div className="text-4xl mb-4">🔄</div>
          <p className="text-gray-500">Loading collaborations...</p>
        </div>
      ) : filteredCollabs.length === 0 ? (
        <div className="bg-white rounded-xl border border-gray-200 p-12 text-center">
          <div className="text-4xl mb-4">📬</div>
          <p className="text-gray-500">
            {filter === 'all'
              ? 'No collaborations found'
              : `No ${filter} collaborations`}
          </p>
          <p className="text-gray-400 text-sm mt-2">
            Create collaborations with ./tools/collaborate
          </p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 divide-y divide-gray-100">
          {filteredCollabs.map((collab) => (
            <button
              key={collab.id}
              onClick={() => setSelectedCollab(collab)}
              className={`w-full text-left p-4 hover:bg-gray-50 transition-colors ${
                selectedCollab?.id === collab.id ? 'bg-agency-50' : ''
              }`}
            >
              <div className="flex items-start gap-3">
                <div className="text-xl mt-1">
                  {collab.status === 'pending' ? '📨' : '✅'}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="font-medium text-gray-900">{collab.title}</span>
                    <span
                      className={`text-xs px-2 py-0.5 rounded ${
                        collab.status === 'pending'
                          ? 'bg-yellow-100 text-yellow-700'
                          : 'bg-green-100 text-green-700'
                      }`}
                    >
                      {collab.status}
                    </span>
                  </div>
                  <div className="text-sm text-gray-500 mt-1">
                    <span className="font-medium">{collab.from}</span>
                    <span className="mx-2">→</span>
                    <span className="font-medium">{collab.to}</span>
                  </div>
                  <div className="text-sm text-gray-400 mt-2 truncate">{collab.preview}</div>
                </div>
              </div>
            </button>
          ))}
        </div>
      )}

      {/* Selected Collaboration Details */}
      {selectedCollab && (
        <div className="bg-white rounded-xl border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
            <div>
              <h2 className="font-medium text-gray-900">{selectedCollab.title}</h2>
              <div className="text-sm text-gray-500 mt-1">
                {selectedCollab.from} → {selectedCollab.to}
              </div>
            </div>
            <button
              onClick={() => setSelectedCollab(null)}
              className="px-3 py-1 text-sm text-gray-600 hover:bg-gray-100 rounded"
            >
              Close
            </button>
          </div>
          <div className="p-6 max-h-96 overflow-y-auto">
            <pre className="text-sm text-gray-700 whitespace-pre-wrap font-mono bg-gray-50 p-4 rounded-lg">
              {collabContent}
            </pre>
          </div>
        </div>
      )}
    </div>
  );
}
