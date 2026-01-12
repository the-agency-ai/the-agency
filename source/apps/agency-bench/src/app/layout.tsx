import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'AgencyBench',
  description: 'Developer workbench for The Agency',
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
