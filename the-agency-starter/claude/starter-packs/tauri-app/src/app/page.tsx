'use client';

import { useState } from 'react';

export default function Home() {
  const [greeting, setGreeting] = useState('');
  const [name, setName] = useState('');

  const handleGreet = async () => {
    // Check if running in Tauri
    if (typeof window !== 'undefined' && (window as any).__TAURI__) {
      const { invoke } = await import('@tauri-apps/api/core');
      const result = await invoke('greet', { name: name || 'World' });
      setGreeting(result as string);
    } else {
      setGreeting(`Hello, ${name || 'World'}! (Running in browser mode)`);
    }
  };

  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-8 bg-gradient-to-br from-gray-50 to-gray-100">
      <div className="max-w-md w-full bg-white rounded-xl shadow-lg p-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">My Tauri App</h1>
        <p className="text-gray-500 mb-6">Built with Tauri + Next.js</p>

        <div className="space-y-4">
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Enter your name"
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          <button
            onClick={handleGreet}
            className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            Greet
          </button>
        </div>

        {greeting && (
          <div className="mt-6 p-4 bg-blue-50 rounded-lg">
            <p className="text-blue-800">{greeting}</p>
          </div>
        )}

        <div className="mt-8 pt-6 border-t border-gray-200">
          <h2 className="text-sm font-medium text-gray-700 mb-2">Next Steps:</h2>
          <ul className="text-sm text-gray-500 space-y-1">
            <li>• Edit <code className="bg-gray-100 px-1 rounded">src/app/page.tsx</code></li>
            <li>• Add Tauri commands in <code className="bg-gray-100 px-1 rounded">src-tauri/src/main.rs</code></li>
            <li>• Build with <code className="bg-gray-100 px-1 rounded">npm run tauri:build</code></li>
          </ul>
        </div>
      </div>
    </main>
  );
}
