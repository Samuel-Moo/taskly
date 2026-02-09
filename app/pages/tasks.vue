<template>
  <div>
    <div class="tasks-layout">
    <div class="tasks-header">
      <p class="section-kicker in">Task Management</p>
      <h1 class="page-title">Tasks</h1>
      <p class="page-subtitle">Plan, prioritize, and move work across your board.</p>
      <div class="tasks-header-actions">
        <button class="btn-primary" type="button" :disabled="!isAuthenticated" @click="openCreateModal">
          Add task
        </button>
        <p v-if="!isAuthenticated" class="tasks-auth-hint">Sign in to create tasks.</p>
      </div>
    </div>

    <div v-if="errorMsg" class="tasks-error">{{ errorMsg }}</div>

    <div class="tasks-filter">
      <div class="tasks-field tasks-filter-field">
        <label class="tasks-label">Filter by project</label>
        <label class="form-field">
          <div class="form-field-inner">
            <select v-model="projectFilter" class="form-select">
              <option value="all">All projects</option>
              <option v-for="project in projects" :key="project.id" :value="String(project.id)">
                {{ project.name }}
              </option>
            </select>
          </div>
        </label>
      </div>
      <div class="tasks-stats card-surface">
        <div class="tasks-stat">
          <span>Total</span>
          <span class="tasks-stat-value">{{ stats.total }}</span>
        </div>
        <div class="tasks-stat">
          <span>Done</span>
          <span class="tasks-stat-value">{{ stats.done }}</span>
        </div>
        <div class="tasks-stat">
          <span>Pending</span>
          <span class="tasks-stat-value">{{ stats.pending }}</span>
        </div>
        <div class="tasks-stat">
          <span>High priority</span>
          <span class="tasks-stat-value">{{ stats.high }}</span>
        </div>
        <div class="tasks-stat">
          <span>Overdue</span>
          <span class="tasks-stat-value">{{ stats.overdue }}</span>
        </div>
      </div>
    </div>

    <div class="tasks-board">
      <div
        v-for="column in statusOptions"
        :key="column.value"
        class="task-column"
        :class="{ 'is-over': dragOverStatus === column.value }"
        @dragover.prevent="onDragOver(column.value)"
        @dragleave="onDragLeave"
        @drop="onDrop(column.value)"
      >
        <div class="task-column-header">
          <div>
            <p class="task-column-title">{{ column.label }}</p>
            <p class="task-column-count">{{ columnTasks(column.value).length }} tasks</p>
          </div>
        </div>
        <div class="task-list">
          <button
            v-for="task in columnTasks(column.value)"
            :key="task.id"
            class="card-surface task-card"
            :class="{ 'is-dragging': draggingId === task.id }"
            type="button"
            draggable="true"
            @dragstart="onDragStart(task)"
            @dragend="onDragEnd"
            @click="handleCardClick(task)"
          >
            <div class="task-card-top">
              <span class="task-project">{{ projectName(task.project_id) }}</span>
              <span class="task-priority" :class="priorityClass(task.priority)">
                {{ task.priority }}
              </span>
            </div>
            <h3 class="task-card-title">{{ task.title }}</h3>
            <p v-if="task.description" class="task-card-desc">{{ task.description }}</p>
            <div class="task-card-meta">
              <span v-if="task.assignee">Assigned to {{ displayAssignee(task.assignee) }}</span>
              <span v-if="task.due_date">Due {{ formatDate(task.due_date) }}</span>
            </div>
          </button>
          <p v-if="columnTasks(column.value).length === 0" class="task-empty">
            Drag tasks here
          </p>
        </div>
      </div>
    </div>

    </div>

    <div v-if="isCreateOpen" class="modal-overlay" @click.self="closeCreateModal">
    <div class="modal-card">
      <div class="modal-header">
        <div>
          <p class="section-kicker">New task</p>
          <h2 class="modal-title">Create a task</h2>
        </div>
        <button class="modal-close" type="button" @click="closeCreateModal">Close</button>
      </div>

      <form class="tasks-form" @submit.prevent="createTask">
        <div class="tasks-field">
          <label class="tasks-label">Title</label>
          <label class="form-field">
            <div class="form-field-inner">
              <input v-model="draft.title" class="form-input" type="text" placeholder="Design kickoff notes" />
            </div>
          </label>
        </div>
        <div class="tasks-field">
          <label class="tasks-label">Description</label>
          <label class="form-field">
            <div class="form-field-inner">
              <textarea v-model="draft.description" class="form-textarea" placeholder="Add a short summary..."></textarea>
            </div>
          </label>
        </div>
        <div class="tasks-grid">
          <div class="tasks-field">
            <label class="tasks-label">Status</label>
            <label class="form-field">
              <div class="form-field-inner">
                <select v-model="draft.status" class="form-select">
                  <option v-for="status in statusOptions" :key="status.value" :value="status.value">
                    {{ status.label }}
                  </option>
                </select>
              </div>
            </label>
          </div>
          <div class="tasks-field">
            <label class="tasks-label">Priority</label>
            <label class="form-field">
              <div class="form-field-inner">
                <select v-model="draft.priority" class="form-select">
                  <option v-for="priority in priorityOptions" :key="priority" :value="priority">
                    {{ priority }}
                  </option>
                </select>
              </div>
            </label>
          </div>
          <div class="tasks-field">
            <label class="tasks-label">Project</label>
            <label class="form-field">
              <div class="form-field-inner">
                <select v-model="draft.project_id" class="form-select">
                  <option disabled value="">Select a project</option>
                  <option v-for="project in projects" :key="project.id" :value="project.id">
                    {{ project.name }}
                  </option>
                </select>
              </div>
            </label>
          </div>
          <div class="tasks-field">
            <label class="tasks-label">Assigned to</label>
            <label class="form-field">
              <div class="form-field-inner">
                <select v-model="draft.assignee" class="form-select">
                  <option value="">Unassigned</option>
                  <option v-for="profile in assignees" :key="profile.id" :value="profile.id">
                    {{ formatProfileName(profile) }}
                  </option>
                </select>
              </div>
            </label>
          </div>
          <div class="tasks-field">
            <label class="tasks-label">Due date</label>
            <label class="form-field">
              <div class="form-field-inner">
                <input v-model="draft.due_date" class="form-input" type="date" />
              </div>
            </label>
          </div>
          <div class="tasks-field">
            <label class="tasks-label">Estimated hours</label>
            <label class="form-field">
              <div class="form-field-inner">
                <input v-model="draft.estimated_hours" class="form-input" type="number" min="0" step="0.5" />
              </div>
            </label>
          </div>
        </div>
        <div class="tasks-actions">
          <button class="btn-primary" type="submit" :disabled="loading || !isAuthenticated">Add task</button>
          <button class="btn-ghost" type="button" :disabled="loading" @click="closeCreateModal">Cancel</button>
        </div>
      </form>
    </div>
    </div>

    <div v-if="isModalOpen" class="modal-overlay" @click.self="closeModal">
    <div class="modal-card">
      <div class="modal-header">
        <div>
          <p class="section-kicker">Task details</p>
          <h2 class="modal-title">{{ modalDraft.title || 'Untitled task' }}</h2>
        </div>
        <button class="modal-close" type="button" @click="closeModal">Close</button>
      </div>

      <form class="tasks-form" @submit.prevent="saveModal">
        <div class="tasks-field">
          <label class="tasks-label">Title</label>
          <label class="form-field">
            <div class="form-field-inner">
              <input v-model="modalDraft.title" class="form-input" type="text" placeholder="Design kickoff notes" />
            </div>
          </label>
        </div>
        <div class="tasks-field">
          <label class="tasks-label">Description</label>
          <label class="form-field">
            <div class="form-field-inner">
              <textarea v-model="modalDraft.description" class="form-textarea" placeholder="Add a short summary..."></textarea>
            </div>
          </label>
        </div>
        <div class="tasks-grid">
          <div class="tasks-field">
            <label class="tasks-label">Status</label>
            <label class="form-field">
              <div class="form-field-inner">
                <select v-model="modalDraft.status" class="form-select">
                  <option v-for="status in statusOptions" :key="status.value" :value="status.value">
                    {{ status.label }}
                  </option>
                </select>
              </div>
            </label>
          </div>
          <div class="tasks-field">
            <label class="tasks-label">Priority</label>
            <label class="form-field">
              <div class="form-field-inner">
                <select v-model="modalDraft.priority" class="form-select">
                  <option v-for="priority in priorityOptions" :key="priority" :value="priority">
                    {{ priority }}
                  </option>
                </select>
              </div>
            </label>
          </div>
          <div class="tasks-field">
            <label class="tasks-label">Project</label>
            <label class="form-field">
              <div class="form-field-inner">
                <select v-model="modalDraft.project_id" class="form-select">
                  <option disabled value="">Select a project</option>
                  <option v-for="project in projects" :key="project.id" :value="project.id">
                    {{ project.name }}
                  </option>
                </select>
              </div>
            </label>
          </div>
          <div class="tasks-field">
            <label class="tasks-label">Assigned to</label>
            <label class="form-field">
              <div class="form-field-inner">
                <select v-model="modalDraft.assignee" class="form-select">
                  <option value="">Unassigned</option>
                  <option
                    v-if="modalDraft.assignee && !assigneeLookup.has(modalDraft.assignee)"
                    :value="modalDraft.assignee"
                  >
                    Current: {{ modalDraft.assignee }}
                  </option>
                  <option v-for="profile in assignees" :key="profile.id" :value="profile.id">
                    {{ formatProfileName(profile) }}
                  </option>
                </select>
              </div>
            </label>
          </div>
          <div class="tasks-field">
            <label class="tasks-label">Due date</label>
            <label class="form-field">
              <div class="form-field-inner">
                <input v-model="modalDraft.due_date" class="form-input" type="date" />
              </div>
            </label>
          </div>
          <div class="tasks-field">
            <label class="tasks-label">Estimated hours</label>
            <label class="form-field">
              <div class="form-field-inner">
                <input v-model="modalDraft.estimated_hours" class="form-input" type="number" min="0" step="0.5" />
              </div>
            </label>
          </div>
        </div>
        <div v-if="errorMsg" class="tasks-error">{{ errorMsg }}</div>
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
          <h2 class="modal-title">Delete this task?</h2>
        </div>
        <button class="modal-close" type="button" @click="confirmDelete = false">Close</button>
      </div>
      <p class="modal-body">
        This action cannot be undone. The task will be permanently removed.
      </p>
      <div class="modal-actions">
        <button class="btn-ghost" type="button" :disabled="loading" @click="confirmDelete = false">Cancel</button>
        <button class="btn-ghost" type="button" :disabled="loading" @click="deleteModal">Delete</button>
      </div>
    </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Database } from '~/types/database.types'

type Task = Database['public']['Tables']['tasks']['Row']
type Project = Database['public']['Tables']['projects']['Row']
type Profile = Database['public']['Tables']['profiles']['Row']

const client = useSupabaseClient<Database>()
const user = useSupabaseUser()
const loading = ref(false)
const errorMsg = ref('')
const projectFilter = ref('all')
const dragOverStatus = ref<string | null>(null)
const draggingId = ref<number | null>(null)
const isDragging = ref(false)
const isModalOpen = ref(false)
const isCreateOpen = ref(false)
const confirmDelete = ref(false)
const modalId = ref<number | null>(null)

const statusOptions = [
  { value: 'todo', label: 'Not started yet' },
  { value: 'in_progress', label: 'In progress' },
  { value: 'done', label: 'Done' },
]

const priorityOptions = ['Low', 'Medium', 'High']
const isAuthenticated = computed(() => !!user.value)

const draft = reactive({
  title: '',
  description: '',
  status: 'todo',
  priority: 'Medium',
  project_id: '' as number | string,
  assignee: '',
  due_date: '',
  estimated_hours: '' as number | string,
})

const modalDraft = reactive({
  title: '',
  description: '',
  status: 'todo',
  priority: 'Medium',
  project_id: '' as number | string,
  assignee: '',
  due_date: '',
  estimated_hours: '' as number | string,
})

const projects = ref<Project[]>([])
const assignees = ref<Profile[]>([])
const tasks = ref<Task[]>([])

const formatProfileName = (profile: Profile) => {
  const fullName = `${profile.first_name || ''} ${profile.last_name || ''}`.trim()
  return fullName || profile.email || 'User'
}

const assigneeLookup = computed(() => {
  return new Map(assignees.value.map((profile) => [profile.id, formatProfileName(profile)]))
})

const displayAssignee = (value: string | null) => {
  if (!value) return 'Unassigned'
  return assigneeLookup.value.get(value) ?? value
}

const projectName = (projectId: number) => {
  const project = projects.value.find((item) => item.id === projectId)
  return project?.name || 'Unassigned'
}

const formatDate = (value: string) => {
  if (!value) return ''
  const date = new Date(value)
  return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
}

const priorityClass = (priority: string) => {
  switch ((priority || '').toLowerCase()) {
    case 'high':
      return 'task-priority task-priority--high'
    case 'low':
      return 'task-priority task-priority--low'
    case 'medium':
    default:
      return 'task-priority task-priority--medium'
  }
}

const visibleTasks = computed(() => {
  if (projectFilter.value === 'all') return tasks.value
  const projectId = Number(projectFilter.value)
  return tasks.value.filter((task) => task.project_id === projectId)
})

const columnTasks = (status: string) =>
  visibleTasks.value
    .filter((task) => task.status === status)
    .sort((a, b) => (a.position ?? 0) - (b.position ?? 0))

const stats = computed(() => {
  const list = visibleTasks.value
  const total = list.length
  const done = list.filter((task) => task.status === 'done').length
  const pending = total - done
  const high = list.filter((task) => (task.priority || '').toLowerCase() === 'high').length
  const today = new Date()
  const overdue = list.filter((task) => task.due_date && new Date(task.due_date) < today).length
  return { total, done, pending, high, overdue }
})

const fetchProjects = async () => {
  if (!user.value) return
  const { data, error } = await client
    .from('projects')
    .select('id,user_id,name,description,status,created_at')
    .order('created_at', { ascending: false })
  if (error) {
    errorMsg.value = error.message
    return
  }
  projects.value = data ?? []
}

const fetchAssignees = async () => {
  if (!user.value) return
  const { data, error } = await client
    .from('profiles')
    .select('id,first_name,last_name,email,created_at')
    .order('first_name', { ascending: true })
  if (error) {
    errorMsg.value = error.message
    return
  }
  assignees.value = data ?? []
}

const fetchTasks = async () => {
  if (!user.value) return
  loading.value = true
  errorMsg.value = ''
  const { data, error } = await client
    .from('tasks')
    .select('id,user_id,project_id,title,description,status,priority,assignee,due_date,estimated_hours,position,created_at')
    .order('status', { ascending: true })
    .order('position', { ascending: true })
  loading.value = false

  if (error) {
    errorMsg.value = error.message
    return
  }
  tasks.value = data ?? []
}

const resetDraft = () => {
  draft.title = ''
  draft.description = ''
  draft.status = 'todo'
  draft.priority = 'Medium'
  draft.project_id = ''
  draft.assignee = ''
  draft.due_date = ''
  draft.estimated_hours = ''
}

const nextPosition = (status: string) => {
  const column = tasks.value.filter((task) => task.status === status)
  const max = column.reduce((acc, task) => Math.max(acc, task.position ?? 0), 0)
  return max + 1
}

const createTask = async () => {
  if (!user.value || !draft.title.trim() || !draft.project_id) return
  loading.value = true
  errorMsg.value = ''
  const payload = {
    user_id: user.value.id,
    project_id: Number(draft.project_id),
    title: draft.title.trim(),
    description: draft.description?.trim() || null,
    status: draft.status,
    priority: draft.priority,
    assignee: draft.assignee || null,
    due_date: draft.due_date || null,
    estimated_hours: draft.estimated_hours ? Number(draft.estimated_hours) : null,
    position: nextPosition(draft.status),
  }
  const { data, error } = await client
    .from('tasks')
    .insert(payload)
    .select('id,user_id,project_id,title,description,status,priority,assignee,due_date,estimated_hours,position,created_at')
    .single()
  loading.value = false

  if (error) {
    errorMsg.value = error.message
    return
  }
  if (data) {
    tasks.value = [data, ...tasks.value]
  }
  resetDraft()
  closeCreateModal()
}

const openModal = (task: Task) => {
  modalId.value = task.id
  modalDraft.title = task.title
  modalDraft.description = task.description || ''
  modalDraft.status = task.status
  modalDraft.priority = task.priority
  modalDraft.project_id = task.project_id
  modalDraft.assignee = task.assignee || ''
  modalDraft.due_date = task.due_date || ''
  modalDraft.estimated_hours = task.estimated_hours ?? ''
  errorMsg.value = ''
  confirmDelete.value = false
  isModalOpen.value = true
}

const closeModal = () => {
  isModalOpen.value = false
  modalId.value = null
  confirmDelete.value = false
}

const openCreateModal = () => {
  if (!isAuthenticated.value) return
  resetDraft()
  errorMsg.value = ''
  isCreateOpen.value = true
}

const closeCreateModal = () => {
  isCreateOpen.value = false
}

const saveModal = async () => {
  if (!modalId.value || !modalDraft.title.trim() || !modalDraft.project_id) return
  loading.value = true
  errorMsg.value = ''
  const payload = {
    project_id: Number(modalDraft.project_id),
    title: modalDraft.title.trim(),
    description: modalDraft.description?.trim() || null,
    status: modalDraft.status,
    priority: modalDraft.priority,
    assignee: modalDraft.assignee || null,
    due_date: modalDraft.due_date || null,
    estimated_hours: modalDraft.estimated_hours ? Number(modalDraft.estimated_hours) : null,
  }
  const { data, error } = await client
    .from('tasks')
    .update(payload)
    .eq('id', modalId.value)
    .select('id,user_id,project_id,title,description,status,priority,assignee,due_date,estimated_hours,position,created_at')
    .single()
  loading.value = false

  if (error) {
    errorMsg.value = error.message
    return
  }
  if (data) {
    tasks.value = tasks.value.map((task) => (task.id === data.id ? data : task))
  }
  closeModal()
}

const deleteModal = async () => {
  if (!modalId.value) return
  loading.value = true
  errorMsg.value = ''
  const { error } = await client.from('tasks').delete().eq('id', modalId.value)
  loading.value = false

  if (error) {
    errorMsg.value = error.message
    return
  }
  tasks.value = tasks.value.filter((task) => task.id !== modalId.value)
  confirmDelete.value = false
  closeModal()
}

const onDragStart = (task: Task) => {
  draggingId.value = task.id
  isDragging.value = true
}

const onDragEnd = () => {
  setTimeout(() => {
    isDragging.value = false
    draggingId.value = null
    dragOverStatus.value = null
  }, 0)
}

const onDragOver = (status: string) => {
  dragOverStatus.value = status
}

const onDragLeave = () => {
  dragOverStatus.value = null
}

const onDrop = async (status: string) => {
  if (!draggingId.value) return
  const task = tasks.value.find((item) => item.id === draggingId.value)
  dragOverStatus.value = null
  if (!task || task.status === status) {
    draggingId.value = null
    return
  }

  const updated = {
    status,
    position: nextPosition(status),
  }

  tasks.value = tasks.value.map((item) => (item.id === task.id ? { ...item, ...updated } : item))

  const { error } = await client.from('tasks').update(updated).eq('id', task.id)
  if (error) {
    errorMsg.value = error.message
  }
  draggingId.value = null
}

const handleCardClick = (task: Task) => {
  if (isDragging.value) return
  openModal(task)
}

watchEffect(() => {
  if (user.value) {
    fetchProjects()
    fetchAssignees()
    fetchTasks()
  }
})
</script>
