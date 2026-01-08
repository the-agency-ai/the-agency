'use client';

import { AppSidebar } from './AppSidebar';
import { Header } from './Header';

interface BenchLayoutProps {
  children: React.ReactNode;
}

export function BenchLayout({ children }: BenchLayoutProps) {
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
