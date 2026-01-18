'use client';

import { useEffect, useState, useCallback } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { AppSidebar } from './AppSidebar';
import { Header } from './Header';
import { getPendingOpen, type PendingOpen } from '@/lib/tauri';

interface BenchLayoutProps {
  children: React.ReactNode;
}

// Map app names to routes
const APP_ROUTES: Record<string, string> = {
  docbench: '/bench/docbench',
  bugbench: '/bench/bugbench',
  'knowledge-indexer': '/bench/knowledge-indexer',
  'agent-monitor': '/bench/agent-monitor',
  'collaboration-inbox': '/bench/collaboration-inbox',
  messages: '/bench/messages',
  secrets: '/bench/secrets',
  workitems: '/bench/workitems',
};

// Polling interval for hot-reload (in ms)
const PENDING_CHECK_INTERVAL = 2000;

export function BenchLayout({ children }: BenchLayoutProps) {
  const router = useRouter();
  const pathname = usePathname();
  const [pendingFile, setPendingFile] = useState<string | null>(null);

  // Check for pending open files
  const checkPendingOpen = useCallback(async () => {
    try {
      const pending = await getPendingOpen();
      if (!pending) return;

      console.log('[BenchLayout] Pending open:', pending);

      // If there's a file, navigate to docbench
      if (pending.file) {
        setPendingFile(pending.file);
        if (!pathname.includes('/docbench')) {
          console.log('[BenchLayout] Navigating to docbench for file:', pending.file);
          router.push('/bench/docbench');
        }
        return;
      }

      // If there's an app specified, navigate to it
      if (pending.app) {
        const route = APP_ROUTES[pending.app];
        if (route && !pathname.includes(route)) {
          console.log('[BenchLayout] Navigating to app:', pending.app);
          router.push(route);
        }
      }
    } catch (err) {
      console.error('[BenchLayout] Error checking pending open:', err);
    }
  }, [router, pathname]);

  // Check on mount
  useEffect(() => {
    checkPendingOpen();
  }, [checkPendingOpen]);

  // Hot-reload: check when window regains focus
  useEffect(() => {
    const handleFocus = () => {
      console.log('[BenchLayout] Window focused, checking for pending files');
      checkPendingOpen();
    };

    window.addEventListener('focus', handleFocus);
    return () => window.removeEventListener('focus', handleFocus);
  }, [checkPendingOpen]);

  // Hot-reload: periodic polling for pending files
  useEffect(() => {
    const interval = setInterval(() => {
      checkPendingOpen();
    }, PENDING_CHECK_INTERVAL);

    return () => clearInterval(interval);
  }, [checkPendingOpen]);

  // Store pending file for docbench to pick up
  useEffect(() => {
    if (pendingFile) {
      // Store in sessionStorage so docbench can access it
      sessionStorage.setItem('pendingOpenFile', pendingFile);
      setPendingFile(null);
    }
  }, [pendingFile]);

  return (
    <div className="flex h-screen bg-gray-50 overflow-hidden">
      <AppSidebar />
      <div className="flex-1 flex flex-col min-w-0">
        <Header />
        <main className="flex-1 p-6 overflow-y-auto">{children}</main>
      </div>
    </div>
  );
}
