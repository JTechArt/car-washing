const TOKEN_COOKIE = 'lva_token'
const ROLE_COOKIE = 'lva_role'

export function getToken(): string | null {
  if (typeof document === 'undefined') return null
  const match = document.cookie.match(new RegExp(`(?:^|; )${TOKEN_COOKIE}=([^;]*)`))
  return match ? decodeURIComponent(match[1]) : null
}

export function getRole(): string | null {
  if (typeof document === 'undefined') return null
  const match = document.cookie.match(new RegExp(`(?:^|; )${ROLE_COOKIE}=([^;]*)`))
  return match ? decodeURIComponent(match[1]) : null
}

export function setAuth(token: string, role: string) {
  const expires = new Date(Date.now() + 86400 * 1000).toUTCString()
  document.cookie = `${TOKEN_COOKIE}=${encodeURIComponent(token)}; path=/; expires=${expires}; SameSite=Strict`
  document.cookie = `${ROLE_COOKIE}=${encodeURIComponent(role)}; path=/; expires=${expires}; SameSite=Strict`
}

export function clearAuth() {
  document.cookie = `${TOKEN_COOKIE}=; path=/; max-age=0`
  document.cookie = `${ROLE_COOKIE}=; path=/; max-age=0`
}
