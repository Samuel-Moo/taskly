<template>
  <div class="auth-stack">
    <div class="welcome-card">
      <h1 class="welcome-title">
        Welcome to <span class="welcome-highlight">Taskly</span>
      </h1>
    </div>
    <h1 class="auth-title">Sign in</h1>
    <form @submit.prevent="login">
      <ErrorAlert :error-msg="authError" @clearError="clearError" />
      <div class="auth-group">
        <label class="form-field">
          <div class="form-field-inner">
            <input class="form-input" type="text" placeholder="Email address" v-model="email" />
          </div>
        </label>
        <label class="form-field">
          <div class="form-field-inner">
            <input class="form-input" type="password" placeholder="Password" v-model="password" />
          </div>
        </label>
      </div>
      <div class="auth-group">
        <button class="btn-primary" type="submit" :disabled="loading">
          <div class="btn-label" :class="{ loading: loading }">Sign in</div>
          <svg viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg" class="btn-spinner" :class="{ loading: loading }">
            <g fill="none" stroke-width="1.5" stroke-linecap="round" class="spinner-rotate" style="stroke: var(--icon-color)">
              <circle stroke-opacity=".2" cx="8" cy="8" r="6"></circle>
              <circle cx="8" cy="8" r="6" class="spinner-arc"></circle>
            </g>
          </svg>
        </button>
        <NuxtLink to="/forgot-password" class="link-muted">Forgot your password?</NuxtLink>
      </div>
    </form>
   
    <div class="auth-group">
      <p class="auth-subtitle">Do you need and account?</p>
      <NuxtLink to="/register">
        <button class="btn-secondary">
          <div class="btn-label">Create new account</div>
        </button>
      </NuxtLink>
    </div>
 
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: 'auth',
});
useHead({
  title: 'Login | supaAuth',
});
const user = useSupabaseUser();
const loading = ref(false);
const authError = ref('');
const email = ref('');
const password = ref('');
const client = useSupabaseClient();

watchEffect(async () => {
  if (user.value) {
    await navigateTo('/');
  }
});

const login = async () => {
  loading.value = true;
  const { error } = await client.auth.signInWithPassword({
    email: email.value,
    password: password.value,
  });
  if (error) {
    loading.value = false;
    authError.value = error.message;
    setTimeout(() => {
      authError.value = '';
    }, 5000);
  }
};

const clearError = () => {
  authError.value = '';
};
</script>
