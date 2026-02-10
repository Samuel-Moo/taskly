<template>
  <main class="layout-root">
    <div class="layout-bg">
      <div class="background-gradient">
        <div class="background-gradient-pattern"></div>
      </div>
    </div>
    <div class="layout-shell">
      <aside v-if="user" class="sidebar">
        <div class="sidebar-header">
          <div class="sidebar-logo">Taskly</div>
          <button
            type="button"
            class="theme-toggle"
            :aria-pressed="isDark"
            :aria-label="isDark ? 'Switch to light mode' : 'Switch to dark mode'"
            @click="toggleTheme"
          >
            <span class="theme-toggle-icon">{{ isDark ? '🌙' : '☀️' }}</span>
            <span class="theme-toggle-label">{{ isDark ? 'Dark' : 'Light' }}</span>
          </button>
        </div>
        <div class="sidebar-user">
          <p class="sidebar-user-label">Logged in as</p>
          <p class="sidebar-user-name">
            {{
              user?.user_metadata?.first_name || user?.user_metadata?.last_name
                ? `${user?.user_metadata?.first_name ?? ''} ${user?.user_metadata?.last_name ?? ''}`.trim()
                : user?.user_metadata?.full_name || user?.email || 'User'
            }}
          </p>
        </div>
        <nav class="sidebar-nav">
          <NuxtLink to="/" class="sidebar-link">
            <span class="sidebar-emoji">🗠</span>
            Dashboard
          </NuxtLink>
          <NuxtLink to="/projects" class="sidebar-link">
            <span class="sidebar-emoji">📁</span>
            Projects
          </NuxtLink>
          <NuxtLink to="/tasks" class="sidebar-link">
            <span class="sidebar-emoji">✅</span>
            Tasks
          </NuxtLink>
          <NuxtLink to="/comments" class="sidebar-link">
            <span class="sidebar-emoji">💬</span>
            Comments
          </NuxtLink>
          <NuxtLink to="/notifications" class="sidebar-link">
            <span class="sidebar-emoji">🔔</span>
            Notifications
          </NuxtLink>
          <NuxtLink to="/reports" class="sidebar-link">
            <span class="sidebar-emoji">📊</span>
            Reports
          </NuxtLink>
        </nav>
        <div class="sidebar-logout">
          <button @click="logout" class="btn-ghost w-full justify-center gap-2 sidebar-logout-button" :disabled="loading">
            <span class="btn-inline" :class="{ loading: loading }">Log out</span>
            <svg viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg" class="btn-spinner" :class="{ loading: loading }">
              <g fill="none" stroke-width="1.5" stroke-linecap="round" class="spinner-rotate" style="stroke: var(--icon-color)">
                <circle stroke-opacity=".2" cx="8" cy="8" r="6"></circle>
                <circle cx="8" cy="8" r="6" class="spinner-arc"></circle>
              </g>
            </svg>
          </button>
        </div>
      </aside>
      <section class="layout-content">
        <div class="layout-content-inner">
          <slot />
        </div>
      </section>
    </div>
  </main>
</template>

<script setup lang="ts">
// Supabase session + UI theme state
const client = useSupabaseClient()
const user = useSupabaseUser()
const loading = ref(false)
const theme = useCookie<'light' | 'dark'>('taskly-theme', { default: () => 'dark' })
const isDark = computed(() => theme.value !== 'light')

// Keep the root HTML class aligned with the current theme
useHead({
  htmlAttrs: {
    class: computed(() => (isDark.value ? 'theme-dark' : 'theme-light')),
  },
})

// Theme toggle handler
const toggleTheme = () => {
  theme.value = isDark.value ? 'light' : 'dark'
}

// Sign out and return to the login screen
const logout = async () => {
  loading.value = true
  try {
    const { error } = await client.auth.signOut()
    if (error) {
      alert('Something went wrong !')
      return
    }
    await navigateTo('/login')
  } finally {
    loading.value = false
  }
}
</script>
