export default defineNuxtRouteMiddleware(async (to) => {
  const publicRoutes = ['/login', '/register', '/forgot-password', '/new-password']

  if (publicRoutes.includes(to.path)) return

  const user = useSupabaseUser()
  if (user.value) return

  const client = useSupabaseClient()
  const { data } = await client.auth.getSession()

  if (!data.session) {
    return navigateTo('/login')
  }
})
