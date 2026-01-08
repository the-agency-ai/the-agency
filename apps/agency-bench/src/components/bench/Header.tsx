'use client';

import { usePathname } from 'next/navigation';

const titles: Record<string, string> = {
  '/bench': 'Dashboard',
  '/bench/markdown-browser': 'Markdown Browser',
  '/bench/knowledge-indexer': 'Knowledge Indexer',
  '/bench/agent-monitor': 'Agent Monitor',
  '/bench/collaboration-inbox': 'Collaboration Inbox',
};

export function Header() {
  const pathname = usePathname();

  // Find the best matching title
  const title = Object.entries(titles).reduce((acc, [path, t]) => {
    if (pathname.startsWith(path) && path.length > acc.pathLen) {
      return { title: t, pathLen: path.length };
    }
    return acc;
  }, { title: 'AgencyBench', pathLen: 0 }).title;

  return (
    <header className="bg-white border-b border-gray-200 px-6 py-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-semibold text-gray-900">{title}</h1>
        <div className="flex items-center gap-4">
          <span className="text-sm text-gray-500">
            {new Date().toLocaleDateString('en-US', {
              weekday: 'short',
              month: 'short',
              day: 'numeric',
            })}
          </span>
        </div>
      </div>
    </header>
  );
}
