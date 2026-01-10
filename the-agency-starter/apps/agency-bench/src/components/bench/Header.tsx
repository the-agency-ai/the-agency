'use client';

import { usePathname } from 'next/navigation';
import { useState, useEffect } from 'react';

// Build version - based on date
const BUILD_DATE = new Date().toISOString().slice(0, 10).replace(/-/g, '');

const apps: Record<string, { title: string; version?: string }> = {
  '/bench': { title: 'Dashboard' },
  '/bench/docbench': { title: 'DocBench', version: `0.1.0-${BUILD_DATE}` },
  '/bench/bugbench': { title: 'BugBench', version: `0.1.0-${BUILD_DATE}` },
  '/bench/knowledge-indexer': { title: 'Knowledge Indexer', version: `0.1.0-${BUILD_DATE}` },
  '/bench/agent-monitor': { title: 'Agent Monitor', version: `0.1.0-${BUILD_DATE}` },
  '/bench/collaboration-inbox': { title: 'Collaboration Inbox', version: `0.1.0-${BUILD_DATE}` },
  '/bench/messages': { title: 'Messages', version: `0.1.0-${BUILD_DATE}` },
};

export function Header() {
  const pathname = usePathname();
  const [principalName, setPrincipalName] = useState<string>('');

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
        <div className="flex items-center gap-4">
          {principalName ? (
            <span className="text-sm font-medium text-gray-700">
              {principalName}
            </span>
          ) : (
            <span className="text-sm text-gray-400 italic">
              No principal set
            </span>
          )}
        </div>
      </div>
    </header>
  );
}
