<template>
  <div class="auth-stack">
    <h1 class="auth-title">Forgot password</h1>
    <form @submit.prevent="resetPassword">
      <ErrorAlert :error-msg="authError" @clearError="clearError" />
      <SuccessAlert :success-msg="authSuccess" @clearSuccess="clearSuccess" />
      <div class="auth-group">
        <label class="form-field">
          <div class="form-field-inner">
            <input class="form-input" type="text" placeholder="Email address" v-model="email" />
          </div>
        </label>
      </div>
      <button class="btn-primary" type="submit" :disabled="loading">
        <div class="btn-label" :class="{ loading: loading }">Request</div>
        <svg viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg" class="btn-spinner" :class="{ loading: loading }">
          <g fill="none" stroke-width="1.5" stroke-linecap="round" class="spinner-rotate" style="stroke: var(--icon-color)">
            <circle stroke-opacity=".2" cx="8" cy="8" r="6"></circle>
            <circle cx="8" cy="8" r="6" class="spinner-arc"></circle>
          </g>
        </svg>
      </button>
    </form>
  </div>
</template>

<script setup lang="ts">
// Page metadata for auth layout
definePageMeta({
  layout: 'auth',
});
// SEO title
useHead({
  title: 'Forgot Password | supaAuth',
});
// Form state + Supabase client
const email = ref('');
const client = useSupabaseClient();
const loading = ref(false);
const authSuccess = ref('');
const authError = ref('');

// Request a password reset email
const resetPassword = async () => {
  loading.value = true;
  const { error } = await client.auth.resetPasswordForEmail(email.value, {
    redirectTo: `${window.location.origin}/new-password`,
  });
  if (error) {
    loading.value = false;
    authError.value = error.message;
    setTimeout(() => {
      authError.value = '';
    }, 5000);
  } else {
    loading.value = false;
    authSuccess.value = `We've sent your an email.`;
    setTimeout(() => {
      authSuccess.value = '';
    }, 5000);
  }
};

// Clear alert helpers
const clearError = () => {
  authError.value = '';
};

const clearSuccess = () => {
  authSuccess.value = '';
};
</script>
