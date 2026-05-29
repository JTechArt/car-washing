export default function SuperAdminPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-2">Tenant Management</h1>
      <p className="text-gray-500 mb-8">Manage white-label car wash operators.</p>

      <div className="bg-white rounded-2xl shadow-sm p-8 text-center text-gray-400">
        <div className="text-5xl mb-4">🏢</div>
        <p className="text-lg font-semibold mb-2">Tenant API endpoints coming in Phase 2</p>
        <p className="text-sm max-w-md mx-auto">
          White-label tenant CRUD requires the super admin endpoints to be implemented
          in the backend. This page will list, create, and configure tenants.
        </p>
      </div>
    </div>
  )
}
