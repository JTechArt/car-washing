import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Lva Admin',
  description: 'Lva car wash operations portal',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
