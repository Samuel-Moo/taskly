<template>
  <div class="auth-stack">
    <h1 class="auth-title">New password</h1>
    <form @submit.prevent="updatepassword">
      <ErrorAlert :error-msg="authError" @clearError="clearError" />
      <SuccessAlert :success-msg="authSuccess" @clearSuccess="clearSuccess" />
      <div class="auth-group">
        <label class="form-field">
          <div class="form-field-inner">
            <input class="form-input" type="password" placeholder="Password" v-model="password" />
          </div>
        </label>
        <label class="form-field">
          <div class="form-field-inner">
            <input class="form-input" type="password" placeholder="Repeat" v-model="passwordConfirm" />
          </div>
        </label>
      </div>
      <div class="auth-group">
        <button class="btn-primary" type="submit" :disabled="loading">
          <div class="btn-label" :class="{ loading: loading }">Save</div>
          <svg viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg" class="btn-spinner" :class="{ loading: loading }">
            <g fill="none" stroke-width="1.5" stroke-linecap="round" class="spinner-rotate" style="stroke: var(--icon-color)">
              <circle stroke-opacity=".2" cx="8" cy="8" r="6"></circle>
              <circle cx="8" cy="8" r="6" class="spinner-arc"></circle>
            </g>
          </svg>
        </button>
      </div>
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
  title: 'New Password | supaAuth',
});
// Form inputs + Supabase client/state
const password = ref('');
const passwordConfirm = ref('');
const client = useSupabaseClient();
const loading = ref(false);
const authSuccess = ref('');
const authError = ref('');

// Update the user's password using the reset token session
const updatepassword = async () => {
  if (password.value !== passwordConfirm.value) return (authError.value = 'Password mismatch!');
  loading.value = true;
  const { error } = await client.auth.updateUser({
    password: password.value,
  });
  await client.auth.signOut();
  if (error) {
    loading.value = false;
    authError.value = error.message;
    setTimeout(() => {
      authError.value = '';
    }, 5000);
  } else {
    loading.value = false;
    authSuccess.value = `Password changed`;
    setTimeout(() => {
      authSuccess.value = '';
      navigateTo('/login');
    }, 5000);
  }
};

// Clear alert helpers
const clearError = () => {
  authError.value = '';
};

const clearSuccess = () => {
  authSuccess.value = '';
  navigateTo('/login');
};
</script>
