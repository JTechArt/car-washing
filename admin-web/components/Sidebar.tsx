'use client'

import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { clearAuth } from '@/lib/auth'

interface NavItem {
  href: string
  label: string
  icon: string
}

interface SidebarProps {
  title: string
  items: NavItem[]
}

export default function Sidebar({ title, items }: SidebarProps) {
  const pathname = usePathname()
  const router = useRouter()

  function handleLogout() {
    clearAuth()
    router.push('/login')
  }

  return (
    <aside className="w-56 min-h-screen bg-navy-600 flex flex-col flex-shrink-0">
      <div className="flex items-center gap-2.5 px-5 py-6 border-b border-white/10">
        <div className="w-8 h-8 bg-white/15 rounded-lg flex items-center justify-center text-white font-bold text-sm">
          Լ
        </div>
        <span className="text-white font-bold">{title}</span>
      </div>

      <nav className="flex-1 py-4">
        {items.map(item => {
          const active = pathname === item.href || pathname.startsWith(item.href + '/')
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-2.5 px-5 py-2.5 text-sm transition ${
                active
                  ? 'bg-white/15 text-white font-semibold'
                  : 'text-white/70 hover:text-white'
              }`}
            >
              <span>{item.icon}</span>
              <span>{item.label}</span>
            </Link>
          )
        })}
      </nav>

      <button
        onClick={handleLogout}
        className="flex items-center gap-2.5 px-5 py-4 text-white/60 hover:text-white text-sm border-t border-white/10 transition"
      >
        <span>↩</span>
        <span>Sign out</span>
      </button>
    </aside>
  )
}
