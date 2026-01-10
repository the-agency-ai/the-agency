import Link from 'next/link';

const apps = [
  {
    id: 'docbench',
    name: 'DocBench',
    description: 'Browse, create, and manage documentation files.',
    href: '/bench/docbench',
    icon: '📄',
    status: 'ready',
  },
  {
    id: 'bugbench',
    name: 'BugBench',
    description: 'Report and track bugs across your project.',
    href: '/bench/bugbench',
    icon: '🐛',
    status: 'ready',
  },
  {
    id: 'knowledge-indexer',
    name: 'Knowledge Indexer',
    description: 'Search and index KNOWLEDGE.md files across your project.',
    href: '/bench/knowledge-indexer',
    icon: '🔍',
    status: 'ready',
  },
  {
    id: 'agent-monitor',
    name: 'Agent Monitor',
    description: 'Monitor running Claude Code agents and their status.',
    href: '/bench/agent-monitor',
    icon: '👁️',
    status: 'coming-soon',
  },
  {
    id: 'collaboration-inbox',
    name: 'Collaboration Inbox',
    description: 'View and respond to inter-agent collaboration requests.',
    href: '/bench/collaboration-inbox',
    icon: '📬',
    status: 'coming-soon',
  },
];

export default function DashboardPage() {
  return (
    <div className="space-y-6">
      {/* Welcome */}
      <div className="bg-gradient-to-r from-agency-600 to-agency-700 rounded-xl p-6 text-white">
        <h2 className="text-2xl font-bold mb-2">Welcome to AgencyBench</h2>
        <p className="text-agency-100">
          Your developer workbench for The Agency. Browse docs, search knowledge,
          and monitor your multi-agent development workflow.
        </p>
      </div>

      {/* Apps Grid */}
      <div>
        <h3 className="text-lg font-semibold text-gray-900 mb-4">DevApps</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {apps.map((app) => (
            <div
              key={app.id}
              className={`bg-white rounded-xl border border-gray-200 p-5 ${
                app.status === 'ready'
                  ? 'hover:border-agency-300 hover:shadow-md transition-all cursor-pointer'
                  : 'opacity-60'
              }`}
            >
              {app.status === 'ready' ? (
                <Link href={app.href} className="block">
                  <div className="text-3xl mb-3">{app.icon}</div>
                  <h4 className="font-semibold text-gray-900 mb-1">{app.name}</h4>
                  <p className="text-sm text-gray-500">{app.description}</p>
                </Link>
              ) : (
                <div>
                  <div className="text-3xl mb-3 grayscale">{app.icon}</div>
                  <h4 className="font-semibold text-gray-900 mb-1">
                    {app.name}
                    <span className="ml-2 text-xs font-normal text-gray-400 bg-gray-100 px-2 py-0.5 rounded">
                      Coming Soon
                    </span>
                  </h4>
                  <p className="text-sm text-gray-500">{app.description}</p>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white rounded-xl border border-gray-200 p-5">
          <div className="text-sm text-gray-500 mb-1">Project</div>
          <div className="font-semibold text-gray-900">The Agency</div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-5">
          <div className="text-sm text-gray-500 mb-1">Version</div>
          <div className="font-semibold text-gray-900">1.0.0-20260110</div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-5">
          <div className="text-sm text-gray-500 mb-1">AgencyBench</div>
          <div className="font-semibold text-gray-900">1.0.0-20260110</div>
        </div>
      </div>
    </div>
  );
}
