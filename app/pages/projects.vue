<template>
  <div class="projects-layout">
    <div class="projects-header">
      <p class="section-kicker in">Project Management</p>
      <h1 class="page-title">Projects</h1>
    </div>

    <div class="card-surface projects-panel">
      <form class="projects-form" @submit.prevent="createProject">
        <div class="projects-field">
          <label class="projects-label">Name</label>
          <label class="form-field">
            <div class="form-field-inner">
              <input v-model="draft.name" class="form-input" type="text" placeholder="Project Alpha" />
            </div>
          </label>
        </div>
        <div class="projects-field">
          <label class="projects-label">Description</label>
          <label class="form-field">
            <div class="form-field-inner">
              <textarea v-model="draft.description" class="form-textarea" placeholder="Describe the project..."></textarea>
            </div>
          </label>
        </div>
        <div class="projects-field">
          <label class="projects-label">Status</label>
          <label class="form-field">
            <div class="form-field-inner">
              <select v-model="draft.status" class="form-select">
                <option value="Active">Active</option>
                <option value="Paused">Paused</option>
                <option value="Archived">Archived</option>
              </select>
            </div>
          </label>
        </div>
        <div class="projects-actions">
          <button class="btn-primary" type="submit" :disabled="loading">Add</button>
        </div>
      </form>
    </div>

    <div v-if="errorMsg && !isModalOpen" class="projects-error">{{ errorMsg }}</div>

    <div class="projects-grid">
      <button
        v-for="project in projects"
        :key="project.id"
        class="card-surface projects-card"
        type="button"
        @click="openModal(project)"
      >
        <div class="projects-card-top">
          <span
            class="projects-card-pill"
            :class="statusClass(project.status)"
          >
            {{ project.status || 'Active' }}
          </span>
        </div>
        <h3 class="projects-card-title">{{ project.name }}</h3>
        <p class="projects-card-desc">{{ project.description || 'No description provided.' }}</p>
      </button>
    </div>

    <p v-if="!loading && projects.length === 0" class="projects-empty">
      No projects yet. Create your first one above.
    </p>
  </div>

  <div v-if="isModalOpen" class="modal-overlay" @click.self="closeModal">
    <div class="modal-card">
      <div class="modal-header">
        <div>
          <p class="section-kicker">Project Details</p>
          <h2 class="modal-title">{{ modalDraft.name || 'Untitled project' }}</h2>
        </div>
        <button class="modal-close" type="button" @click="closeModal">Close</button>
      </div>

      <form class="projects-form" @submit.prevent="saveModal">
        <div class="projects-field">
          <label class="projects-label">Name</label>
          <label class="form-field">
            <div class="form-field-inner">
              <input v-model="modalDraft.name" class="form-input" type="text" placeholder="Project Alpha" />
            </div>
          </label>
        </div>
        <div class="projects-field">
          <label class="projects-label">Description</label>
          <label class="form-field">
            <div class="form-field-inner">
              <textarea v-model="modalDraft.description" class="form-textarea" placeholder="Describe the project..."></textarea>
            </div>
          </label>
        </div>
        <div class="projects-field">
          <label class="projects-label">Status</label>
          <label class="form-field">
            <div class="form-field-inner">
              <select v-model="modalDraft.status" class="form-select">
                <option value="Active">Active</option>
                <option value="Paused">Paused</option>
                <option value="Archived">Archived</option>
              </select>
            </div>
          </label>
        </div>
        <div v-if="errorMsg" class="projects-error">{{ errorMsg }}</div>
        <div class="modal-actions">
          <button class="btn-ghost" type="button" :disabled="loading" @click="closeModal">Cancel</button>
          <button class="btn-ghost" type="button" :disabled="loading" @click="confirmDelete = true">Delete</button>
          <button class="btn-primary" type="submit" :disabled="loading">Save changes</button>
        </div>
      </form>
    </div>
  </div>

  <div v-if="confirmDelete" class="modal-overlay" @click.self="confirmDelete = false">
    <div class="modal-card modal-card--compact">
      <div class="modal-header">
        <div>
          <p class="section-kicker">Confirm delete</p>
          <h2 class="modal-title">Delete this project?</h2>
        </div>
        <button class="modal-close" type="button" @click="confirmDelete = false">Close</button>
      </div>
      <p class="modal-body">
        This action cannot be undone. The project will be permanently removed.
      </p>
      <div class="modal-actions">
        <button class="btn-ghost" type="button" :disabled="loading" @click="confirmDelete = false">Cancel</button>
        <button class="btn-ghost" type="button" :disabled="loading" @click="deleteModal">Delete</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Database } from '~/types/database.types'

// Database row type for projects
type Project = Database['public']['Tables']['projects']['Row']

// Supabase client + auth state
const client = useSupabaseClient<Database>()
const user = useSupabaseUser()
const loading = ref(false)
const errorMsg = ref('')
const isModalOpen = ref(false)
const modalId = ref<number | null>(null)
const confirmDelete = ref(false)

// Create/edit form drafts
const draft = reactive({
  name: '',
  description: '',
  status: 'Active',
})

const modalDraft = reactive({
  name: '',
  description: '',
  status: 'Active',
})

// Loaded project list
const projects = ref<Project[]>([])

// Fetch existing projects for the current user
const fetchProjects = async () => {
  if (!user.value) return
  loading.value = true
  errorMsg.value = ''
  const { data, error } = await client
    .from('projects')
    .select('id,user_id,name,description,status,created_at')
    .order('created_at', { ascending: false })
  loading.value = false

  if (error) {
    errorMsg.value = error.message
    return
  }
  projects.value = data ?? []
}

// Reset the create form
const resetDraft = () => {
  draft.name = ''
  draft.description = ''
  draft.status = 'Active'
}

// Create a new project
const createProject = async () => {
  if (!user.value || !draft.name.trim()) return
  loading.value = true
  errorMsg.value = ''
  const { data, error } = await client
    .from('projects')
    .insert({
      user_id: user.value.id,
      name: draft.name.trim(),
      description: draft.description?.trim() || null,
      status: draft.status,
    })
    .select('id,user_id,name,description,status,created_at')
    .single()
  loading.value = false

  if (error) {
    errorMsg.value = error.message
    return
  }
  if (data) {
    projects.value = [data, ...projects.value]
  }
  resetDraft()
}

// Status pill helper
const statusClass = (status: string | null) => {
  switch ((status || '').toLowerCase()) {
    case 'paused':
      return 'status-pill status-pill--paused'
    case 'archived':
      return 'status-pill status-pill--archived'
    case 'active':
    default:
      return 'status-pill status-pill--active'
  }
}

// Open edit modal and seed draft values
const openModal = (project: Project) => {
  modalId.value = project.id
  modalDraft.name = project.name
  modalDraft.description = project.description || ''
  modalDraft.status = project.status || 'Active'
  errorMsg.value = ''
  confirmDelete.value = false
  isModalOpen.value = true
}

// Close edit modal
const closeModal = () => {
  isModalOpen.value = false
  modalId.value = null
  confirmDelete.value = false
}

// Persist modal edits
const saveModal = async () => {
  if (!modalId.value || !modalDraft.name.trim()) return
  loading.value = true
  errorMsg.value = ''
  const { data, error } = await client
    .from('projects')
    .update({
      name: modalDraft.name.trim(),
      description: modalDraft.description?.trim() || null,
      status: modalDraft.status,
    })
    .eq('id', modalId.value)
    .select('id,user_id,name,description,status,created_at')
    .single()
  loading.value = false

  if (error) {
    errorMsg.value = error.message
    return
  }
  if (data) {
    projects.value = projects.value.map((project) => (project.id === data.id ? data : project))
  }
  closeModal()
}

// Delete the selected project
const deleteModal = async () => {
  if (!modalId.value) return
  loading.value = true
  errorMsg.value = ''
  const { error } = await client.from('projects').delete().eq('id', modalId.value)
  loading.value = false

  if (error) {
    errorMsg.value = error.message
    return
  }
  projects.value = projects.value.filter((project) => project.id !== modalId.value)
  confirmDelete.value = false
  closeModal()
}

// Load projects after login
watchEffect(() => {
  if (user.value) {
    fetchProjects()
  }
})
</script>
