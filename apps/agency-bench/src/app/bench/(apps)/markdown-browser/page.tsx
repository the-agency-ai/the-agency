'use client';

import { useState, useEffect } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';

// Sample files for demo - in production, these come from Tauri FS
const sampleFiles = [
  { path: 'CLAUDE.md', name: 'CLAUDE.md' },
  { path: 'README.md', name: 'README.md' },
  { path: 'CHANGELOG.md', name: 'CHANGELOG.md' },
  { path: 'claude/agents/housekeeping/agent.md', name: 'housekeeping/agent.md' },
  { path: 'claude/agents/housekeeping/KNOWLEDGE.md', name: 'housekeeping/KNOWLEDGE.md' },
];

const sampleContent: Record<string, string> = {
  'CLAUDE.md': `# The Agency

A multi-agent development framework for Claude Code.

## What is The Agency?

The Agency is a convention-over-configuration system for running multiple Claude Code agents that collaborate on a shared codebase.

## Quick Start

\`\`\`bash
./tools/myclaude housekeeping housekeeping
\`\`\`

## Core Concepts

- **Workstreams** - Organized areas of work
- **Agents** - Specialized Claude Code instances
- **Principals** - Human stakeholders
- **Collaboration** - Inter-agent communication
`,
  'README.md': `# The Agency

A multi-agent development framework for Claude Code.

## Overview

Built for developers who want to scale their AI-assisted development workflows.

## Getting Started

\`\`\`bash
curl -fsSL https://raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh | bash
\`\`\`
`,
};

export default function MarkdownBrowserPage() {
  const [selectedFile, setSelectedFile] = useState<string | null>(null);
  const [content, setContent] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    if (selectedFile && sampleContent[selectedFile]) {
      setContent(sampleContent[selectedFile]);
    } else if (selectedFile) {
      setContent(`# ${selectedFile}\n\nContent loading...\n\n*In production, this will load from the file system via Tauri.*`);
    }
  }, [selectedFile]);

  const filteredFiles = sampleFiles.filter((f) =>
    f.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="flex h-[calc(100vh-8rem)] gap-4">
      {/* File List */}
      <div className="w-72 bg-white rounded-xl border border-gray-200 flex flex-col">
        <div className="p-4 border-b border-gray-200">
          <input
            type="text"
            placeholder="Search files..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-agency-500 focus:border-transparent"
          />
        </div>
        <div className="flex-1 overflow-y-auto p-2">
          {filteredFiles.map((file) => (
            <button
              key={file.path}
              onClick={() => setSelectedFile(file.path)}
              className={`w-full text-left px-3 py-2 rounded-lg text-sm transition-colors ${
                selectedFile === file.path
                  ? 'bg-agency-100 text-agency-700'
                  : 'text-gray-700 hover:bg-gray-100'
              }`}
            >
              <span className="mr-2">📄</span>
              {file.name}
            </button>
          ))}
        </div>
      </div>

      {/* Content Viewer */}
      <div className="flex-1 bg-white rounded-xl border border-gray-200 flex flex-col">
        {selectedFile ? (
          <>
            <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
              <h2 className="font-medium text-gray-900">{selectedFile}</h2>
              <div className="flex gap-2">
                <button className="px-3 py-1 text-sm text-gray-600 hover:bg-gray-100 rounded">
                  Copy
                </button>
                <button className="px-3 py-1 text-sm text-gray-600 hover:bg-gray-100 rounded">
                  Open in Editor
                </button>
              </div>
            </div>
            <div className="flex-1 overflow-y-auto p-6">
              <article className="prose prose-slate max-w-none">
                <ReactMarkdown remarkPlugins={[remarkGfm]}>{content}</ReactMarkdown>
              </article>
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-400">
            <div className="text-center">
              <div className="text-4xl mb-4">📄</div>
              <p>Select a file to preview</p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
