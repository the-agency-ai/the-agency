import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'My Tauri App',
  description: 'A desktop app built with Tauri + Next.js',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
