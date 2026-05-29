import Sidebar from '@/components/Sidebar'

const NAV = [
  { href: '/owner', label: 'Dashboard', icon: '📊' },
  { href: '/owner/pricing', label: 'Pricing', icon: '💰' },
]

export default function OwnerLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen">
      <Sidebar title="Lva" items={NAV} />
      <main className="flex-1 p-8 overflow-y-auto">{children}</main>
    </div>
  )
}
