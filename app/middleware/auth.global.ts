export default defineNuxtRouteMiddleware(async (to) => {
  const publicRoutes = ['/login', '/register', '/forgot-password', '/new-password']

  if (publicRoutes.includes(to.path)) return

  const user = useSupabaseUser()
  if (user.value) return

  const client = useSupabaseClient()
  try {
    const { data, error } = await client.auth.getSession()

    if (error || !data.session) {
      return navigateTo('/login')
    }
  } catch {
    return navigateTo('/login')
  }
})
