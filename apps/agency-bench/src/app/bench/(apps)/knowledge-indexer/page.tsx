'use client';

import { useState } from 'react';

interface SearchResult {
  file: string;
  matches: {
    line: number;
    content: string;
    context: string;
  }[];
}

// Sample data for demo
const sampleResults: SearchResult[] = [
  {
    file: 'claude/agents/housekeeping/KNOWLEDGE.md',
    matches: [
      {
        line: 15,
        content: 'Pattern: Always read KNOWLEDGE.md before starting work',
        context: '## Session Patterns',
      },
      {
        line: 42,
        content: 'Knowledge is accumulated wisdom from past sessions',
        context: '## What is Knowledge',
      },
    ],
  },
  {
    file: 'claude/workstreams/housekeeping/KNOWLEDGE.md',
    matches: [
      {
        line: 8,
        content: 'Shared knowledge across all agents in this workstream',
        context: '## Overview',
      },
    ],
  },
];

export default function KnowledgeIndexerPage() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<SearchResult[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [stats, setStats] = useState({
    filesIndexed: 12,
    totalLines: 2450,
    lastIndexed: '2 minutes ago',
  });

  const handleSearch = () => {
    if (!query.trim()) return;

    setIsSearching(true);
    // Simulate search delay
    setTimeout(() => {
      setResults(sampleResults);
      setIsSearching(false);
    }, 300);
  };

  const handleReindex = () => {
    setStats((s) => ({ ...s, lastIndexed: 'Just now' }));
  };

  return (
    <div className="space-y-6">
      {/* Search Bar */}
      <div className="bg-white rounded-xl border border-gray-200 p-4">
        <div className="flex gap-4">
          <div className="flex-1 relative">
            <input
              type="text"
              placeholder="Search knowledge files... (e.g., 'session patterns', 'collaboration')"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-agency-500 focus:border-transparent"
            />
          </div>
          <button
            onClick={handleSearch}
            disabled={isSearching}
            className="px-6 py-3 bg-agency-600 text-white rounded-lg font-medium hover:bg-agency-700 transition-colors disabled:opacity-50"
          >
            {isSearching ? 'Searching...' : 'Search'}
          </button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="text-sm text-gray-500">Files Indexed</div>
          <div className="text-2xl font-semibold text-gray-900">{stats.filesIndexed}</div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="text-sm text-gray-500">Total Lines</div>
          <div className="text-2xl font-semibold text-gray-900">{stats.totalLines.toLocaleString()}</div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="text-sm text-gray-500">Last Indexed</div>
          <div className="text-2xl font-semibold text-gray-900">{stats.lastIndexed}</div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4 flex items-center justify-center">
          <button
            onClick={handleReindex}
            className="px-4 py-2 text-sm text-agency-600 hover:bg-agency-50 rounded-lg transition-colors"
          >
            🔄 Re-index Now
          </button>
        </div>
      </div>

      {/* Results */}
      {results.length > 0 && (
        <div className="bg-white rounded-xl border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="font-medium text-gray-900">
              Found {results.reduce((acc, r) => acc + r.matches.length, 0)} matches in {results.length} files
            </h3>
          </div>
          <div className="divide-y divide-gray-100">
            {results.map((result) => (
              <div key={result.file} className="p-4">
                <div className="flex items-center gap-2 mb-3">
                  <span className="text-lg">📄</span>
                  <span className="font-medium text-gray-900">{result.file}</span>
                  <span className="text-sm text-gray-400">({result.matches.length} matches)</span>
                </div>
                <div className="space-y-2 ml-7">
                  {result.matches.map((match, i) => (
                    <div
                      key={i}
                      className="bg-gray-50 rounded-lg p-3 text-sm hover:bg-gray-100 cursor-pointer transition-colors"
                    >
                      <div className="text-gray-400 text-xs mb-1">
                        Line {match.line} • {match.context}
                      </div>
                      <div className="text-gray-700">{match.content}</div>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Empty State */}
      {query && results.length === 0 && !isSearching && (
        <div className="bg-white rounded-xl border border-gray-200 p-12 text-center">
          <div className="text-4xl mb-4">🔍</div>
          <p className="text-gray-500">No results found for "{query}"</p>
          <p className="text-gray-400 text-sm mt-2">Try different keywords or check file filters</p>
        </div>
      )}

      {/* Initial State */}
      {!query && results.length === 0 && (
        <div className="bg-white rounded-xl border border-gray-200 p-12 text-center">
          <div className="text-4xl mb-4">📚</div>
          <p className="text-gray-500">Search across all KNOWLEDGE.md files</p>
          <p className="text-gray-400 text-sm mt-2">
            Find patterns, decisions, and accumulated wisdom from your agents
          </p>
        </div>
      )}
    </div>
  );
}
