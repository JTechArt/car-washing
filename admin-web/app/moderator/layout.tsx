import Sidebar from '@/components/Sidebar'

const NAV = [
  { href: '/moderator', label: 'Bay Status', icon: '🔴' },
]

export default function ModeratorLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen">
      <Sidebar title="Lva Moderator" items={NAV} />
      <main className="flex-1 p-8 overflow-y-auto">{children}</main>
    </div>
  )
}
