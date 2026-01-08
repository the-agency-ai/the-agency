'use client';

import { useState, useEffect } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { isTauri, readFile, getProjectRoot } from '@/lib/tauri';

interface FileItem {
  path: string;
  name: string;
}

export default function MarkdownBrowserPage() {
  const [files, setFiles] = useState<FileItem[]>([]);
  const [selectedFile, setSelectedFile] = useState<string | null>(null);
  const [content, setContent] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [projectRoot, setProjectRoot] = useState<string>('');

  // Load files on mount
  useEffect(() => {
    async function loadFiles() {
      try {
        const root = await getProjectRoot();
        setProjectRoot(root);

        if (isTauri) {
          const { invoke } = await import('@tauri-apps/api/core');
          const mdFiles: string[] = await invoke('list_markdown_files', { root });
          setFiles(
            mdFiles.map((f) => ({
              path: f,
              name: f.replace(root + '/', ''),
            }))
          );
        } else {
          // Browser fallback
          setFiles([
            { path: `${root}/CLAUDE.md`, name: 'CLAUDE.md' },
            { path: `${root}/README.md`, name: 'README.md' },
            { path: `${root}/CHANGELOG.md`, name: 'CHANGELOG.md' },
            { path: `${root}/claude/agents/housekeeping/agent.md`, name: 'claude/agents/housekeeping/agent.md' },
            { path: `${root}/claude/agents/housekeeping/KNOWLEDGE.md`, name: 'claude/agents/housekeeping/KNOWLEDGE.md' },
          ]);
        }
      } catch (err) {
        console.error('Failed to load files:', err);
      } finally {
        setLoading(false);
      }
    }

    loadFiles();
  }, []);

  // Load file content when selected
  useEffect(() => {
    async function loadContent() {
      if (!selectedFile) {
        setContent('');
        return;
      }

      try {
        const fileContent = await readFile(selectedFile);
        setContent(fileContent);
      } catch (err) {
        console.error('Failed to read file:', err);
        setContent(`# Error\n\nFailed to read file: ${selectedFile}\n\n${err}`);
      }
    }

    loadContent();
  }, [selectedFile]);

  const filteredFiles = files.filter((f) =>
    f.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // Group files by directory
  const groupedFiles = filteredFiles.reduce((acc, file) => {
    const parts = file.name.split('/');
    const dir = parts.length > 1 ? parts.slice(0, -1).join('/') : '(root)';
    if (!acc[dir]) acc[dir] = [];
    acc[dir].push(file);
    return acc;
  }, {} as Record<string, FileItem[]>);

  return (
    <div className="flex h-[calc(100vh-8rem)] gap-4">
      {/* File List */}
      <div className="w-80 bg-white rounded-xl border border-gray-200 flex flex-col">
        <div className="p-4 border-b border-gray-200">
          <input
            type="text"
            placeholder="Search files..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-agency-500 focus:border-transparent"
          />
          <div className="mt-2 text-xs text-gray-400">
            {isTauri ? '🟢 Tauri mode' : '🟡 Browser mode'} • {files.length} files
          </div>
        </div>

        <div className="flex-1 overflow-y-auto p-2">
          {loading ? (
            <div className="text-center py-4 text-gray-400">Loading files...</div>
          ) : (
            Object.entries(groupedFiles).map(([dir, dirFiles]) => (
              <div key={dir} className="mb-4">
                <div className="px-3 py-1 text-xs font-medium text-gray-500 uppercase">
                  {dir}
                </div>
                {dirFiles.map((file) => (
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
                    {file.name.split('/').pop()}
                  </button>
                ))}
              </div>
            ))
          )}
        </div>
      </div>

      {/* Content Viewer */}
      <div className="flex-1 bg-white rounded-xl border border-gray-200 flex flex-col">
        {selectedFile ? (
          <>
            <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
              <div>
                <h2 className="font-medium text-gray-900">
                  {selectedFile.replace(projectRoot + '/', '')}
                </h2>
                <div className="text-xs text-gray-400">{selectedFile}</div>
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => navigator.clipboard.writeText(content)}
                  className="px-3 py-1 text-sm text-gray-600 hover:bg-gray-100 rounded"
                >
                  Copy
                </button>
              </div>
            </div>
            <div className="flex-1 overflow-y-auto p-6">
              <article className="prose prose-slate max-w-none prose-headings:font-semibold prose-code:text-sm prose-pre:bg-gray-900">
                <ReactMarkdown remarkPlugins={[remarkGfm]}>{content}</ReactMarkdown>
              </article>
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-400">
            <div className="text-center">
              <div className="text-4xl mb-4">📄</div>
              <p>Select a file to preview</p>
              <p className="text-sm mt-2">
                {isTauri
                  ? 'Real files from your project'
                  : 'Start with tauri:dev for real file access'}
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
