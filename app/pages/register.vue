<template>
  <div class="auth-stack">
    <h1 class="auth-title">Create an account</h1>
    <form @submit.prevent="signUp">
      <ErrorAlert :error-msg="authError" @clearError="clearError" />
      <div class="auth-group">
        <label class="form-field">
          <div class="form-field-inner">
            <input class="form-input" type="text" placeholder="First name" v-model="name" />
          </div>
        </label>
        <label class="form-field">
          <div class="form-field-inner">
            <input class="form-input" type="text" placeholder="Last name" v-model="lastname" />
          </div>
        </label>
        <label class="form-field">
          <div class="form-field-inner">
            <input class="form-input" type="text" placeholder="Company (Optional)" v-model="company" />
          </div>
        </label>
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
          <div class="btn-label" :class="{ loading: loading }">Sign up</div>
          <svg viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg" class="btn-spinner" :class="{ loading: loading }">
            <g fill="none" stroke-width="1.5" stroke-linecap="round" class="spinner-rotate" style="stroke: var(--icon-color)">
              <circle stroke-opacity=".2" cx="8" cy="8" r="6"></circle>
              <circle cx="8" cy="8" r="6" class="spinner-arc"></circle>
            </g>
          </svg>
        </button>
        <div class="legal-text">
          By signing up you agree to our
          <a href="https://policies.google.com/terms" target="_blank" rel="noopener noreferrer" class="legal-link">
            <span>API Terms of Service</span>
          </a>
          and
          <a href="https://policies.google.com/privacy" target="_blank" rel="noopener noreferrer" class="legal-link">
            <span>Privacy Policy</span>
          </a>
          .
        </div>
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
  title: 'Register | supaAuth',
});
// Form inputs + Supabase client/state
const email = ref('');
const password = ref('');
const name = ref('');
const lastname = ref('');
const company = ref('');
const client = useSupabaseClient();
const user = useSupabaseUser();
const loading = ref(false);
const authError = ref('');

// Redirect authenticated users away from register
watchEffect(async () => {
  if (user.value) {
    await navigateTo('/');
  }
});

// Create a new user account and store profile metadata
const signUp = async () => {
  if (!name.value) return (authError.value = 'First name required');
  if (!lastname.value) return (authError.value = 'Last name required');
  loading.value = true;
  const { error } = await client.auth.signUp({
    email: email.value,
    password: password.value,
    options: {
      data: {
        first_name: name.value,
        last_name: lastname.value,
        company: company.value,
      },
    },
  });
  if (error) {
    loading.value = false;
    authError.value = 'Failed to fetch';
  }
};

// Clear the inline error message
const clearError = () => {
  authError.value = '';
};
</script>
