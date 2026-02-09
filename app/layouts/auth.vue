<template>
  <div class="auth-root">
    <div class="auth-scroll">
      <div class="auth-shell">
        <AppBackToLogin />
        <div class="auth-content">
          <div class="auth-panel">
            <slot />
          </div>
        </div>
        <p class="auth-footer">
          This site is authenticate by supabase.com and the Supabase
          <a target="_blank" href="https://supabase.com/privacy" rel="noreferrer">Privacy Policy</a>
          and
          <a target="_blank" href="https://supabase.com/terms" rel="noreferrer">Terms of Service</a>
          apply.
        </p>
      </div>
    </div>
  </div>
</template>
