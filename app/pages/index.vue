<template>
  <div class="relative z-10 max-w-screen-sm">
    <div class="welcome-card">
      <p v-if="user?.user_metadata?.first_name" class="section-kicker in">Hi {{ user.user_metadata.first_name }}</p>
      <p v-else class="section-kicker">Workspace overview</p>
      <h1 class="welcome-title">
        <span v-if="user?.user_metadata?.first_name">Welcome back</span>
        <span v-else>
          Welcome to <span class="welcome-highlight">Taskly</span>
        </span>
      </h1>
      <p class="welcome-subtitle">
        <span v-if="user">Here is your dashboard. Pick up where you left off.</span>
        <span v-else>Organize projects, track tasks, and keep every update in one place.</span>
      </p>
    </div>
    <div class="action-row" v-if="!user">
      <NuxtLink class="btn-primary-solid" to="/login">
        <span class="btn-inline">
          Login
          <svg viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg" class="btn-arrow">
            <path class="chevron" d="M8 13L13 8L8 3" stroke-width="1.5" stroke-linecap="square" stroke-linejoin="round"></path>
            <path class="stem" d="M12 8L2 8" stroke-width="1.5"></path>
          </svg>
        </span>
      </NuxtLink>
      <NuxtLink to="/register">
        <button class="btn-ghost">
          <span class="btn-inline">Sign up</span>
        </button>
      </NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
const user = useSupabaseUser();

useHead({
  title: 'supaAuth',
  meta: [
    {
      name: 'description',
      content: 'Authentication template with email and password, using Supabase. If you want to a quick start to your next Nuxt3 app, please feel free to use this template.',
    },
  ],
});
</script>
