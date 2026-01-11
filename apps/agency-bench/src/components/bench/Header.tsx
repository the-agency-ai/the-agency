'use client';

import { usePathname } from 'next/navigation';
import { useState, useEffect } from 'react';
import { DEVAPP_VERSIONS } from '@/lib/version';

const apps: Record<string, { title: string; version?: string }> = {
  '/bench': { title: 'Dashboard' },
  '/bench/workitems': { title: 'Work Items', version: DEVAPP_VERSIONS.workitems },
  '/bench/docbench': { title: 'DocBench', version: DEVAPP_VERSIONS.docbench },
  '/bench/bugbench': { title: 'BugBench', version: DEVAPP_VERSIONS.bugbench },
  '/bench/knowledge-indexer': { title: 'Knowledge Indexer', version: DEVAPP_VERSIONS['knowledge-indexer'] },
  '/bench/agent-monitor': { title: 'Agent Monitor', version: DEVAPP_VERSIONS['agent-monitor'] },
  '/bench/collaboration-inbox': { title: 'Collaboration Inbox', version: DEVAPP_VERSIONS['collaboration-inbox'] },
  '/bench/messages': { title: 'Messages', version: DEVAPP_VERSIONS.messages },
  '/bench/secrets': { title: 'Secrets', version: DEVAPP_VERSIONS.secrets },
};

export function Header() {
  const pathname = usePathname();
  const [principalName, setPrincipalName] = useState<string>('');
  const [showPrincipalInput, setShowPrincipalInput] = useState(false);
  const [inputValue, setInputValue] = useState('');

  // Load principal name from localStorage
  useEffect(() => {
    const stored = localStorage.getItem('agencybench-principal');
    if (stored) {
      setPrincipalName(stored);
    }

    // Listen for storage changes (in case principal is set in another tab/component)
    const handleStorage = (e: StorageEvent) => {
      if (e.key === 'agencybench-principal' && e.newValue) {
        setPrincipalName(e.newValue);
      }
    };
    window.addEventListener('storage', handleStorage);
    return () => window.removeEventListener('storage', handleStorage);
  }, []);

  const handleSetPrincipal = () => {
    if (inputValue.trim()) {
      // Normalize to lowercase for consistent matching
      const normalizedPrincipal = inputValue.trim().toLowerCase();
      localStorage.setItem('agencybench-principal', normalizedPrincipal);
      setPrincipalName(normalizedPrincipal);
      setShowPrincipalInput(false);
      setInputValue('');
      // Reload to apply the new principal
      window.location.reload();
    }
  };

  const handleClearPrincipal = () => {
    localStorage.removeItem('agencybench-principal');
    setPrincipalName('');
    setShowPrincipalInput(false);
    window.location.reload();
  };

  // Find the best matching app info
  const appInfo = Object.entries(apps).reduce<{ title: string; pathLen: number; version?: string }>((acc, [path, info]) => {
    if (pathname.startsWith(path) && path.length > acc.pathLen) {
      return { title: info.title, version: info.version, pathLen: path.length };
    }
    return acc;
  }, { title: 'AgencyBench', pathLen: 0, version: undefined });

  return (
    <header className="bg-white border-b border-gray-200 px-6 py-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold text-gray-900">{appInfo.title}</h1>
          {appInfo.version && (
            <span className="text-xs text-gray-400">v{appInfo.version}</span>
          )}
        </div>
        <div className="flex items-center gap-4 relative">
          {showPrincipalInput ? (
            <div className="flex items-center gap-2">
              <input
                type="text"
                value={inputValue}
                onChange={(e) => setInputValue(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleSetPrincipal()}
                placeholder="Enter principal name"
                className="px-2 py-1 text-sm border border-gray-300 rounded focus:ring-agency-500 focus:border-agency-500"
                autoFocus
                autoComplete="off"
                autoCorrect="off"
                autoCapitalize="off"
                spellCheck={false}
              />
              <button
                onClick={handleSetPrincipal}
                className="px-2 py-1 text-sm bg-agency-600 text-white rounded hover:bg-agency-700"
              >
                Set
              </button>
              <button
                onClick={() => setShowPrincipalInput(false)}
                className="px-2 py-1 text-sm text-gray-500 hover:text-gray-700"
              >
                Cancel
              </button>
            </div>
          ) : principalName ? (
            <button
              onClick={() => {
                setInputValue(principalName);
                setShowPrincipalInput(true);
              }}
              className="text-sm font-medium text-gray-700 hover:text-agency-600 flex items-center gap-1"
              title="Click to change principal"
            >
              {principalName}
              <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
              </svg>
            </button>
          ) : (
            <button
              onClick={() => setShowPrincipalInput(true)}
              className="text-sm text-red-500 hover:text-red-700 italic"
            >
              No principal set (click to set)
            </button>
          )}
        </div>
      </div>
    </header>
  );
}
