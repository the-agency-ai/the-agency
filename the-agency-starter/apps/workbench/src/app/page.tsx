export default function Home() {
  return (
    <main className="min-h-screen p-8">
      <h1 className="text-3xl font-bold mb-4">Agency Workbench</h1>
      <p className="text-gray-600 mb-8">
        Manage your Agency-powered project from here.
      </p>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <a href="/staff" className="block p-6 border rounded-lg hover:border-blue-500">
          <h2 className="text-xl font-semibold mb-2">Staff Manager</h2>
          <p className="text-gray-500">Team authentication and permissions</p>
        </a>

        <a href="/agents" className="block p-6 border rounded-lg hover:border-blue-500">
          <h2 className="text-xl font-semibold mb-2">Agent Manager</h2>
          <p className="text-gray-500">Configure and monitor Claude agents</p>
        </a>

        <a href="/content" className="block p-6 border rounded-lg hover:border-blue-500">
          <h2 className="text-xl font-semibold mb-2">Content Manager</h2>
          <p className="text-gray-500">Manage prompts and templates</p>
        </a>

        <a href="/pulse" className="block p-6 border rounded-lg hover:border-blue-500">
          <h2 className="text-xl font-semibold mb-2">Pulse Beat</h2>
          <p className="text-gray-500">Real-time metrics dashboard</p>
        </a>

        <a href="/catalog" className="block p-6 border rounded-lg hover:border-blue-500">
          <h2 className="text-xl font-semibold mb-2">Catalog</h2>
          <p className="text-gray-500">Browse available agents</p>
        </a>
      </div>
    </main>
  );
}
