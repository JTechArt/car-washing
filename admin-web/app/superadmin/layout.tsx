import Sidebar from '@/components/Sidebar'

const NAV = [
  { href: '/superadmin', label: 'Tenants', icon: '🏢' },
]

export default function SuperAdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen">
      <Sidebar title="Lva Super" items={NAV} />
      <main className="flex-1 p-8 overflow-y-auto">{children}</main>
    </div>
  )
}
