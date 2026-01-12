'use client';

import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { useState, useEffect } from 'react';

interface DevApp {
  id: string;
  name: string;
  href: string;
  description: string;
  icon: string;
}

const devApps: DevApp[] = [
  {
    id: 'workitems',
    name: 'Work Items',
    href: '/bench/workitems',
    description: 'Unified work item tracker (requests, bugs, ideas, observations)',
    icon: '📊',
  },
  {
    id: 'docbench',
    name: 'DocBench',
    href: '/bench/docbench',
    description: 'Browse, create, and manage documents',
    icon: '📄',
  },
  {
    id: 'bugbench',
    name: 'BugBench',
    href: '/bench/bugbench',
    description: 'Report and track bugs',
    icon: '🐛',
  },
  {
    id: 'knowledge-indexer',
    name: 'Knowledge Indexer',
    href: '/bench/knowledge-indexer',
    description: 'Search and index knowledge files',
    icon: '🔍',
  },
  {
    id: 'agent-monitor',
    name: 'Agent Monitor',
    href: '/bench/agent-monitor',
    description: 'View all agents in your project',
    icon: '🤖',
  },
  {
    id: 'collaboration-inbox',
    name: 'Collaboration Inbox',
    href: '/bench/collaboration-inbox',
    description: 'Manage collaboration requests',
    icon: '🤝',
  },
  {
    id: 'messages',
    name: 'Messages',
    href: '/bench/messages',
    description: 'View message queue and delivery status',
    icon: '📬',
  },
  {
    id: 'secrets',
    name: 'Secrets',
    href: '/bench/secrets',
    description: 'Manage secrets and credentials',
    icon: '🔐',
  },
];

const futureApps: DevApp[] = [
  {
    id: 'news-feed',
    name: 'News Feed',
    href: '/bench/news-feed',
    description: 'Agent broadcasts and updates',
    icon: '📰',
  },
  {
    id: 'session-browser',
    name: 'Session Browser',
    href: '/bench/session-browser',
    description: 'Browse archived sessions',
    icon: '📁',
  },
];

export function AppSidebar() {
  const pathname = usePathname();
  const [collapsed, setCollapsed] = useState(false);

  // Load collapsed state from localStorage
  useEffect(() => {
    const stored = localStorage.getItem('agencybench-sidebar-collapsed');
    if (stored === 'true') {
      setCollapsed(true);
    }
  }, []);

  // Save collapsed state to localStorage
  useEffect(() => {
    localStorage.setItem('agencybench-sidebar-collapsed', collapsed.toString());
  }, [collapsed]);

  const isActive = (href: string) => pathname.startsWith(href);

  // Collapsed view - icons only
  if (collapsed) {
    return (
      <aside className="w-14 bg-gray-900 text-white min-h-screen flex flex-col">
        {/* Branding - collapsed */}
        <Link
          href="/bench"
          className="flex items-center justify-center p-3 border-b border-gray-800 hover:bg-gray-800/50 transition-colors"
          title="TheAgency"
        >
          <Image src="/logo.svg" alt="TheAgency" width={32} height={32} />
        </Link>

        {/* DevApps - icons only */}
        <div className="flex-1 py-4">
          <nav className="space-y-1 px-2">
            {devApps.map((app) => (
              <Link
                key={app.id}
                href={app.href}
                className={`flex items-center justify-center p-2 rounded-lg transition-colors ${
                  isActive(app.href)
                    ? 'bg-agency-600 text-white'
                    : 'text-gray-300 hover:bg-gray-800 hover:text-white'
                }`}
                title={app.name}
              >
                <span className="text-lg">{app.icon}</span>
              </Link>
            ))}
          </nav>

          {/* Divider */}
          <div className="border-t border-gray-800 my-4 mx-2" />

          {/* Coming Soon - icons only */}
          <nav className="space-y-1 px-2">
            {futureApps.map((app) => (
              <span
                key={app.id}
                className="flex items-center justify-center p-2 rounded-lg text-gray-600 cursor-not-allowed"
                title={`${app.name} (Coming Soon)`}
              >
                <span className="text-lg">{app.icon}</span>
              </span>
            ))}
          </nav>
        </div>

        {/* Expand button */}
        <button
          onClick={() => setCollapsed(false)}
          className="p-3 border-t border-gray-800 text-gray-400 hover:text-white hover:bg-gray-800/50 transition-colors"
          title="Expand sidebar"
        >
          <svg className="w-5 h-5 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 5l7 7-7 7M5 5l7 7-7 7" />
          </svg>
        </button>

        {/* Version indicator */}
        <div
          className="p-2 text-center text-[10px] text-gray-600"
          title={`AgencyBench v${process.env.NEXT_PUBLIC_APP_VERSION || '0.0.0'}`}
        >
          v{process.env.NEXT_PUBLIC_APP_VERSION || '0.0.0'}
        </div>
      </aside>
    );
  }

  // Expanded view
  return (
    <aside className="w-56 bg-gray-900 text-white min-h-screen flex flex-col">
      {/* Branding */}
      <div className="flex items-center border-b border-gray-800">
        <Link
          href="/bench"
          className="flex-1 p-4 hover:bg-gray-800/50 transition-colors"
        >
          <div className="flex items-center gap-3">
            <Image src="/logo.svg" alt="TheAgency" width={40} height={40} />
            <div className="text-sm">
              <div className="font-semibold text-white">TheAgency</div>
              <div className="text-gray-400">AgencyBench</div>
            </div>
          </div>
        </Link>
        <button
          onClick={() => setCollapsed(true)}
          className="p-3 mr-2 text-gray-500 hover:text-white hover:bg-gray-800 rounded transition-colors"
          title="Collapse sidebar"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 19l-7-7 7-7m8 14l-7-7 7-7" />
          </svg>
        </button>
      </div>

      {/* DevApps */}
      <div className="flex-1 p-4">
        <div className="text-xs font-medium text-gray-500 uppercase tracking-wider mb-3">
          DevApps
        </div>
        <nav className="space-y-1">
          {devApps.map((app) => (
            <Link
              key={app.id}
              href={app.href}
              className={`flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                isActive(app.href)
                  ? 'bg-agency-600 text-white'
                  : 'text-gray-300 hover:bg-gray-800 hover:text-white'
              }`}
            >
              <span>{app.icon}</span>
              <span>{app.name}</span>
            </Link>
          ))}
        </nav>

        {/* Coming Soon */}
        <div className="text-xs font-medium text-gray-500 uppercase tracking-wider mb-3 mt-6">
          Coming Soon
        </div>
        <nav className="space-y-1">
          {futureApps.map((app) => (
            <span
              key={app.id}
              className="flex items-center gap-2 px-3 py-2 rounded-lg text-sm text-gray-600 cursor-not-allowed"
            >
              <span>{app.icon}</span>
              <span>{app.name}</span>
            </span>
          ))}
        </nav>
      </div>

      {/* Footer */}
      <div className="p-4 border-t border-gray-800">
        <div className="text-xs text-gray-500">
          AgencyBench v{process.env.NEXT_PUBLIC_APP_VERSION || '0.0.0'}
        </div>
      </div>
    </aside>
  );
}
