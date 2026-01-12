'use client';

import { useState, useEffect } from 'react';
import { isTauri, readFile, getProjectRoot } from '@/lib/tauri';

interface Agent {
  name: string;
  path: string;
  description: string;
  hasKnowledge: boolean;
  hasWorklog: boolean;
}

export default function AgentMonitorPage() {
  const [agents, setAgents] = useState<Agent[]>([]);
  const [selectedAgent, setSelectedAgent] = useState<Agent | null>(null);
  const [agentContent, setAgentContent] = useState<string>('');
  const [loading, setLoading] = useState(true);
  const [projectRoot, setProjectRoot] = useState('');

  useEffect(() => {
    async function loadAgents() {
      try {
        const root = await getProjectRoot();
        setProjectRoot(root);

        if (isTauri) {
          const { invoke } = await import('@tauri-apps/api/core');
          const mdFiles: string[] = await invoke('list_markdown_files', { root });

          // Find agent.md files
          const agentFiles = mdFiles.filter((f) => f.includes('/agents/') && f.endsWith('/agent.md'));

          const agentList = await Promise.all(
            agentFiles.map(async (agentPath) => {
              const agentDir = agentPath.replace('/agent.md', '');
              const name = agentDir.split('/').pop() || 'unknown';

              // Read agent.md to get description
              let description = 'No description';
              try {
                const content = await readFile(agentPath);
                const match = content.match(/^#[^\n]*\n+([^\n]+)/);
                if (match) {
                  description = match[1].replace(/^[-*]\s*/, '').trim();
                }
              } catch {
                // Ignore read errors
              }

              // Check for KNOWLEDGE.md and WORKLOG.md
              const hasKnowledge = mdFiles.some((f) => f === `${agentDir}/KNOWLEDGE.md`);
              const hasWorklog = mdFiles.some((f) => f === `${agentDir}/WORKLOG.md`);

              return {
                name,
                path: agentPath,
                description,
                hasKnowledge,
                hasWorklog,
              };
            })
          );

          setAgents(agentList.sort((a, b) => a.name.localeCompare(b.name)));
        } else {
          // Browser fallback
          setAgents([
            {
              name: 'housekeeping',
              path: `${root}/claude/agents/housekeeping/agent.md`,
              description: 'Your guide to The Agency framework',
              hasKnowledge: true,
              hasWorklog: true,
            },
          ]);
        }
      } catch (err) {
        console.error('Failed to load agents:', err);
      } finally {
        setLoading(false);
      }
    }

    loadAgents();
  }, []);

  useEffect(() => {
    async function loadAgentContent() {
      if (!selectedAgent) {
        setAgentContent('');
        return;
      }

      try {
        const content = await readFile(selectedAgent.path);
        setAgentContent(content);
      } catch (err) {
        console.error('Failed to read agent:', err);
        setAgentContent(`# Error\n\nFailed to read: ${selectedAgent.path}`);
      }
    }

    loadAgentContent();
  }, [selectedAgent]);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <h1 className="text-xl font-semibold text-gray-900 mb-2">Agent Monitor</h1>
        <p className="text-gray-500 text-sm">
          View and monitor all agents in your project.
          {isTauri ? ' Reading from real file system.' : ' Start with tauri:dev for real data.'}
        </p>
        <div className="mt-4 flex gap-4 text-sm">
          <div className="px-3 py-1 bg-gray-100 rounded-lg">
            <span className="text-gray-500">Total agents:</span>{' '}
            <span className="font-medium">{agents.length}</span>
          </div>
          <div className="px-3 py-1 bg-green-100 rounded-lg text-green-700">
            {isTauri ? 'Tauri mode' : 'Browser mode'}
          </div>
        </div>
      </div>

      {/* Agent Grid */}
      {loading ? (
        <div className="bg-white rounded-xl border border-gray-200 p-12 text-center">
          <div className="text-4xl mb-4">🔄</div>
          <p className="text-gray-500">Loading agents...</p>
        </div>
      ) : agents.length === 0 ? (
        <div className="bg-white rounded-xl border border-gray-200 p-12 text-center">
          <div className="text-4xl mb-4">🤖</div>
          <p className="text-gray-500">No agents found</p>
          <p className="text-gray-400 text-sm mt-2">
            Create agents with ./tools/create-agent
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {agents.map((agent) => (
            <button
              key={agent.name}
              onClick={() => setSelectedAgent(agent)}
              className={`text-left bg-white rounded-xl border border-gray-200 p-4 hover:border-agency-300 hover:shadow-sm transition-all ${
                selectedAgent?.name === agent.name ? 'ring-2 ring-agency-500 border-agency-500' : ''
              }`}
            >
              <div className="flex items-start gap-3">
                <div className="text-2xl">🤖</div>
                <div className="flex-1 min-w-0">
                  <div className="font-medium text-gray-900">{agent.name}</div>
                  <div className="text-sm text-gray-500 truncate mt-1">{agent.description}</div>
                  <div className="flex gap-2 mt-3">
                    {agent.hasKnowledge && (
                      <span className="text-xs px-2 py-0.5 bg-blue-100 text-blue-700 rounded">
                        KNOWLEDGE
                      </span>
                    )}
                    {agent.hasWorklog && (
                      <span className="text-xs px-2 py-0.5 bg-green-100 text-green-700 rounded">
                        WORKLOG
                      </span>
                    )}
                  </div>
                </div>
              </div>
            </button>
          ))}
        </div>
      )}

      {/* Selected Agent Details */}
      {selectedAgent && (
        <div className="bg-white rounded-xl border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
            <div>
              <h2 className="font-medium text-gray-900">{selectedAgent.name}</h2>
              <div className="text-xs text-gray-400 mt-1">
                {selectedAgent.path.replace(projectRoot + '/', '')}
              </div>
            </div>
            <button
              onClick={() => setSelectedAgent(null)}
              className="px-3 py-1 text-sm text-gray-600 hover:bg-gray-100 rounded"
            >
              Close
            </button>
          </div>
          <div className="p-6 max-h-96 overflow-y-auto">
            <pre className="text-sm text-gray-700 whitespace-pre-wrap font-mono bg-gray-50 p-4 rounded-lg">
              {agentContent}
            </pre>
          </div>
        </div>
      )}
    </div>
  );
}
