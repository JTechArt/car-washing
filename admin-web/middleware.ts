import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const token = request.cookies.get('lva_token')?.value
  const { pathname } = request.nextUrl

  const protectedPaths = ['/owner', '/superadmin', '/moderator']
  const isProtected = protectedPaths.some(p => pathname.startsWith(p))

  if (isProtected && !token) {
    return NextResponse.redirect(new URL('/login', request.url))
  }
  return NextResponse.next()
}

export const config = {
  matcher: ['/owner/:path*', '/superadmin/:path*', '/moderator/:path*'],
}
