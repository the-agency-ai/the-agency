'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

interface DevApp {
  id: string;
  name: string;
  href: string;
  description: string;
  icon: string;
}

const devApps: DevApp[] = [
  {
    id: 'markdown-browser',
    name: 'Markdown Browser',
    href: '/bench/markdown-browser',
    description: 'Browse and preview markdown files',
    icon: '📄',
  },
  {
    id: 'knowledge-indexer',
    name: 'Knowledge Indexer',
    href: '/bench/knowledge-indexer',
    description: 'Search and index knowledge files',
    icon: '🔍',
  },
];

const futureApps: DevApp[] = [
  {
    id: 'agent-monitor',
    name: 'Agent Monitor',
    href: '/bench/agent-monitor',
    description: 'Monitor running agents',
    icon: '👁️',
  },
  {
    id: 'collaboration-inbox',
    name: 'Collaboration Inbox',
    href: '/bench/collaboration-inbox',
    description: 'Manage collaboration requests',
    icon: '📬',
  },
];

export function AppSidebar() {
  const pathname = usePathname();

  const isActive = (href: string) => pathname.startsWith(href);

  return (
    <aside className="w-56 bg-gray-900 text-white min-h-screen flex flex-col">
      {/* Branding */}
      <Link
        href="/bench"
        className="block p-6 border-b border-gray-800 hover:bg-gray-800/50 transition-colors"
      >
        <div className="text-2xl mb-2">🏢</div>
        <div className="text-sm">
          <div className="font-semibold text-white">The Agency</div>
          <div className="text-gray-400">AgencyBench</div>
        </div>
      </Link>

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
      <div className="p-4 border-t border-gray-800 space-y-1">
        <div className="text-xs text-gray-500">The Agency v0.2.0</div>
        <div className="text-xs text-gray-600">AgencyBench v0.1.0</div>
      </div>
    </aside>
  );
}
