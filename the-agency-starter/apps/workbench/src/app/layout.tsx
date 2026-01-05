import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Agency Workbench',
  description: 'Manage your Agency-powered project',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
