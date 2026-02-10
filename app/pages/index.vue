<template>
  <div class="dashboard-layout">
    <div v-if="loading" class="dashboard-loading" aria-live="polite" aria-busy="true">
      <div class="dashboard-loading-card">
        <span class="dashboard-loading-dot"></span>
        Updating dashboard...
      </div>
    </div>

    <section class="card-surface dashboard-hero">
      <div class="dashboard-hero-head">
        <div>
          <p class="section-kicker in">
            {{ user?.user_metadata?.first_name ? `Hi ${user.user_metadata.first_name}` : 'Workspace overview' }}
          </p>
          <h1 class="dashboard-title">
            {{ user?.user_metadata?.first_name ? 'Welcome back' : 'Taskly Dashboard' }}
          </h1>

        </div>
        <div class="dashboard-quick-actions">
          <NuxtLink to="/tasks" class="btn-primary-solid">
            <span class="btn-inline">Open Tasks</span>
          </NuxtLink>
          <NuxtLink to="/projects" class="btn-ghost">
            <span class="btn-inline">Projects</span>
          </NuxtLink>
          <NuxtLink to="/reports" class="btn-ghost">
            <span class="btn-inline">Reports</span>
          </NuxtLink>
        </div>
      </div>

      <div class="dashboard-search">
        <label class="dashboard-search-label" for="dashboard-search">Search workspace</label>
        <form class="dashboard-search-controls" @submit.prevent="applySearch">
          <label class="form-field dashboard-search-field">
            <div class="form-field-inner">
              <input
                id="dashboard-search"
                v-model="searchQuery"
                class="form-input"
                type="text"
                placeholder="Search tasks, projects, comments, assignees..."
              />
            </div>
          </label>
          <div class="dashboard-search-actions">
            <button class="btn-ghost dashboard-search-btn" type="submit">Search</button>
            <button class="btn-ghost dashboard-search-btn" type="button" @click="clearSearch">Clear</button>
          </div>
        </form>
        <p class="dashboard-search-meta">
          {{ searchSummary }}
        </p>
      </div>
    </section>

    <div v-if="errorMsg" class="dashboard-error">{{ errorMsg }}</div>

    <section class="dashboard-metrics">
      <article class="card-surface dashboard-metric">
        <p class="dashboard-metric-label">Projects</p>
        <p class="dashboard-metric-value">{{ metrics.projects }}</p>
        <p class="dashboard-metric-meta">{{ metrics.activeProjects }} active</p>
      </article>
      <article class="card-surface dashboard-metric">
        <p class="dashboard-metric-label">Tasks</p>
        <p class="dashboard-metric-value">{{ metrics.tasks }}</p>
        <p class="dashboard-metric-meta">{{ metrics.openTasks }} open</p>
      </article>
      <article class="card-surface dashboard-metric">
        <p class="dashboard-metric-label">Completion</p>
        <p class="dashboard-metric-value">{{ metrics.completionRate }}%</p>
        <p class="dashboard-metric-meta">{{ metrics.doneTasks }} completed</p>
      </article>
      <article class="card-surface dashboard-metric">
        <p class="dashboard-metric-label">Comments</p>
        <p class="dashboard-metric-value">{{ metrics.comments }}</p>
        <p class="dashboard-metric-meta">{{ metrics.overdueTasks }} overdue tasks</p>
      </article>
    </section>

    <section class="dashboard-grid">
      <article class="card-surface dashboard-card">
        <div class="dashboard-card-head">
          <h2 class="dashboard-card-title">Task Pipeline</h2>
          <NuxtLink to="/tasks" class="dashboard-card-link">View all</NuxtLink>
        </div>

        <div class="dashboard-statuses">
          <div v-for="status in statusStats" :key="status.key" class="dashboard-status-row">
            <div class="dashboard-status-top">
              <span>{{ status.label }}</span>
              <span>{{ status.count }}</span>
            </div>
            <div class="dashboard-status-track">
              <div class="dashboard-status-fill" :style="{ width: `${status.percent}%` }"></div>
            </div>
          </div>
        </div>

        <div class="dashboard-list">
          <p v-if="recentTasks.length === 0" class="dashboard-empty">No matching tasks.</p>
          <div v-for="task in recentTasks" :key="task.id" class="dashboard-list-item">
            <div>
              <p class="dashboard-item-title">{{ task.title }}</p>
              <p class="dashboard-item-meta">
                {{ projectName(task.project_id) }} · {{ statusLabel(task.status) }}
              </p>
            </div>
            <p class="dashboard-item-right">{{ formatDate(task.due_date) }}</p>
          </div>
        </div>
      </article>

      <article class="card-surface dashboard-card">
        <div class="dashboard-card-head">
          <h2 class="dashboard-card-title">Project Health</h2>
          <NuxtLink to="/projects" class="dashboard-card-link">Manage</NuxtLink>
        </div>

        <div class="dashboard-list">
          <p v-if="projectHealth.length === 0" class="dashboard-empty">No matching projects.</p>
          <div v-for="project in projectHealth" :key="project.id" class="dashboard-project-item">
            <div class="dashboard-project-top">
              <p class="dashboard-item-title">{{ project.name }}</p>
              <p class="dashboard-item-right">{{ project.completion }}%</p>
            </div>
            <p class="dashboard-item-meta">
              {{ statusLabel(project.status) }} · {{ project.total }} tasks · {{ project.comments }} comments
            </p>
            <div class="dashboard-status-track">
              <div class="dashboard-status-fill" :style="{ width: `${project.completion}%` }"></div>
            </div>
          </div>
        </div>
      </article>
    </section>

    <section class="card-surface dashboard-card">
      <div class="dashboard-card-head">
        <h2 class="dashboard-card-title">Recent Comments</h2>
        <NuxtLink to="/comments" class="dashboard-card-link">Open comments</NuxtLink>
      </div>
      <div class="dashboard-list">
        <p v-if="recentComments.length === 0" class="dashboard-empty">No matching comments.</p>
        <div v-for="comment in recentComments" :key="comment.id" class="dashboard-comment-item">
          <p class="dashboard-item-title">{{ comment.body }}</p>
          <p class="dashboard-item-meta">
            {{ profileName(comment.user_id) }} · {{ commentTaskTitle(comment.task_id) }} · {{ formatDateTime(comment.created_at) }}
          </p>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import type { Database } from '~/types/database.types'

// Database row types for the dashboard
type Task = Database['public']['Tables']['tasks']['Row']
type Project = Database['public']['Tables']['projects']['Row']
type Profile = Database['public']['Tables']['profiles']['Row']
type Comment = Database['public']['Tables']['comments']['Row']

// Supabase client + authenticated user
const client = useSupabaseClient<Database>()
const user = useSupabaseUser()

// UI state
const loading = ref(false)
const errorMsg = ref('')
const searchQuery = ref('')
const appliedSearchQuery = ref('')

// Data collections
const tasks = ref<Task[]>([])
const projects = ref<Project[]>([])
const profiles = ref<Profile[]>([])
const comments = ref<Comment[]>([])

// Search helpers
const appliedNormalizedQuery = computed(() => appliedSearchQuery.value.trim().toLowerCase())
const pendingSearch = computed(() => searchQuery.value.trim() !== appliedSearchQuery.value.trim())

const contains = (value: string | null | undefined, query: string) => {
  if (!query) return true
  return (value || '').toLowerCase().includes(query)
}

// Display name helpers for profiles and current user
const formatProfileName = (profile: Profile) => {
  const fullName = `${profile.first_name || ''} ${profile.last_name || ''}`.trim()
  return fullName || profile.email || 'User'
}

const profileLookup = computed(() => {
  return new Map(profiles.value.map((profile: Profile) => [profile.id, formatProfileName(profile)]))
})

const readString = (value: unknown) => {
  return typeof value === 'string' && value.trim().length > 0 ? value.trim() : ''
}

const currentUserDisplayName = computed(() => {
  const metadata = (user.value?.user_metadata ?? {}) as Record<string, unknown>
  const firstName = readString(metadata.first_name)
  const lastName = readString(metadata.last_name)
  const fullName = `${firstName} ${lastName}`.trim()
  if (fullName) return fullName

  const profileName = readString(metadata.full_name)
  if (profileName) return profileName

  const email = readString(user.value?.email)
  if (email) return email

  return 'User'
})

// Lookup maps for quick name/title resolution
const projectLookup = computed(() => {
  return new Map(projects.value.map((project: Project) => [project.id, project]))
})

const taskLookup = computed(() => {
  return new Map(tasks.value.map((task: Task) => [task.id, task]))
})

const profileName = (userId: string | null) => {
  if (!userId) return 'Unassigned'
  const knownName = profileLookup.value.get(userId)
  if (knownName) return knownName
  if (user.value?.id === userId) return currentUserDisplayName.value
  return 'User'
}

const projectName = (projectId: number) => {
  return projectLookup.value.get(projectId)?.name ?? `Project #${projectId}`
}

const commentTaskTitle = (taskId: number) => {
  return taskLookup.value.get(taskId)?.title ?? `Task #${taskId}`
}

// Date parsing/formatting helpers
const parseDate = (value: string | null) => {
  if (!value) return null
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? null : date
}

const formatDate = (value: string | null) => {
  const date = parseDate(value)
  if (!date) return 'No date'
  return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
}

const formatDateTime = (value: string | null) => {
  const date = parseDate(value)
  if (!date) return 'Unknown date'
  return date.toLocaleString(undefined, { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' })
}

// Normalize status strings for display
const statusLabel = (status: string | null) => {
  switch ((status || '').toLowerCase()) {
    case 'in_progress':
      return 'In progress'
    case 'done':
      return 'Done'
    case 'todo':
      return 'To do'
    case 'active':
      return 'Active'
    case 'paused':
      return 'Paused'
    case 'archived':
      return 'Archived'
    default:
      return status || 'Unknown'
  }
}

// Filtered collections driven by the applied search
const filteredTasks = computed(() => {
  const query = appliedNormalizedQuery.value
  return tasks.value.filter((task: Task) => {
    return (
      contains(task.title, query) ||
      contains(task.description, query) ||
      contains(projectName(task.project_id), query) ||
      contains(profileName(task.assignee), query) ||
      contains(task.status, query) ||
      contains(task.priority, query)
    )
  })
})

const filteredProjects = computed(() => {
  const query = appliedNormalizedQuery.value
  return projects.value.filter((project: Project) => {
    return contains(project.name, query) || contains(project.description, query) || contains(project.status, query)
  })
})

const filteredComments = computed(() => {
  const query = appliedNormalizedQuery.value
  return comments.value.filter((comment: Comment) => {
    return (
      contains(comment.body, query) ||
      contains(commentTaskTitle(comment.task_id), query) ||
      contains(profileName(comment.user_id), query)
    )
  })
})

// KPI blocks for the dashboard summary
const metrics = computed(() => {
  const doneTasks = tasks.value.filter((task: Task) => task.status === 'done').length
  const tasksCount = tasks.value.length
  const openTasks = tasksCount - doneTasks
  const completionRate = tasksCount ? Math.round((doneTasks / tasksCount) * 100) : 0
  const overdueTasks = tasks.value.filter((task: Task) => {
    const due = parseDate(task.due_date)
    if (!due || task.status === 'done') return false
    return due.getTime() < Date.now()
  }).length

  return {
    projects: projects.value.length,
    activeProjects: projects.value.filter((project: Project) => (project.status || '').toLowerCase() === 'active').length,
    tasks: tasksCount,
    doneTasks,
    openTasks,
    completionRate,
    comments: comments.value.length,
    overdueTasks,
  }
})

// Status breakdown chart
const statusStats = computed(() => {
  const total = tasks.value.length || 1
  const todo = tasks.value.filter((task: Task) => task.status === 'todo').length
  const progress = tasks.value.filter((task: Task) => task.status === 'in_progress').length
  const done = tasks.value.filter((task: Task) => task.status === 'done').length
  return [
    { key: 'todo', label: 'To do', count: todo, percent: Math.round((todo / total) * 100) },
    { key: 'in_progress', label: 'In progress', count: progress, percent: Math.round((progress / total) * 100) },
    { key: 'done', label: 'Done', count: done, percent: Math.round((done / total) * 100) },
  ]
})

// Shortlists for dashboard cards
const recentTasks = computed(() => {
  return [...filteredTasks.value]
    .sort((a, b) => {
      const aDue = parseDate(a.due_date)?.getTime() ?? Number.MAX_SAFE_INTEGER
      const bDue = parseDate(b.due_date)?.getTime() ?? Number.MAX_SAFE_INTEGER
      if (aDue !== bDue) return aDue - bDue
      const aCreated = parseDate(a.created_at)?.getTime() ?? 0
      const bCreated = parseDate(b.created_at)?.getTime() ?? 0
      return bCreated - aCreated
    })
    .slice(0, 6)
})

const commentsByProject = computed(() => {
  const map = new Map<number, number>()
  for (const comment of comments.value) {
    const task = taskLookup.value.get(comment.task_id)
    if (!task) continue
    map.set(task.project_id, (map.get(task.project_id) ?? 0) + 1)
  }
  return map
})

const projectHealth = computed(() => {
  return [...filteredProjects.value]
    .map((project: Project) => {
      const projectTasks = tasks.value.filter((task: Task) => task.project_id === project.id)
      const done = projectTasks.filter((task: Task) => task.status === 'done').length
      const total = projectTasks.length
      const completion = total ? Math.round((done / total) * 100) : 0
      return {
        id: project.id,
        name: project.name,
        status: project.status,
        total,
        completion,
        comments: commentsByProject.value.get(project.id) ?? 0,
      }
    })
    .sort((a, b) => b.total - a.total)
})

const recentComments = computed(() => {
  return [...filteredComments.value]
    .sort((a, b) => {
      const aTime = parseDate(a.created_at)?.getTime() ?? 0
      const bTime = parseDate(b.created_at)?.getTime() ?? 0
      return bTime - aTime
    })
    .slice(0, 8)
})

// Search UI summary string
const searchSummary = computed(() => {
  if (!appliedNormalizedQuery.value) {
    if (pendingSearch.value && searchQuery.value.trim()) {
      return 'Press Search to apply your query.'
    }
    return `Browsing all data: ${tasks.value.length} tasks, ${projects.value.length} projects, ${comments.value.length} comments`
  }
  return `Matches: ${filteredTasks.value.length} tasks, ${filteredProjects.value.length} projects, ${filteredComments.value.length} comments`
})

// Search actions
const applySearch = () => {
  appliedSearchQuery.value = searchQuery.value.trim()
}

const clearSearch = () => {
  searchQuery.value = ''
  appliedSearchQuery.value = ''
}

const hasDashboardData = () => {
  return tasks.value.length > 0 || projects.value.length > 0 || comments.value.length > 0
}

// Delay helper for retries
const wait = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms))

const hadVisibleData = ref(false)
let ensureLoadPromise: Promise<void> | null = null

// Fetch all dashboard data in parallel
const fetchDashboardData = async (options: { clearError?: boolean; showLoading?: boolean } = {}) => {
  if (!user.value) return { ok: false, hasData: false }
  const { clearError = true, showLoading = true } = options
  if (showLoading) {
    loading.value = true
  }
  if (clearError) errorMsg.value = ''
  const [tasksRes, projectsRes, profilesRes, commentsRes] = await Promise.all([
    client
      .from('tasks')
      .select('id,user_id,project_id,title,description,status,priority,assignee,due_date,estimated_hours,position,created_at')
      .order('created_at', { ascending: false }),
    client
      .from('projects')
      .select('id,user_id,name,description,status,created_at')
      .order('created_at', { ascending: false }),
    client
      .from('profiles')
      .select('id,first_name,last_name,email,created_at')
      .order('first_name', { ascending: true }),
    client
      .from('comments')
      .select('id,task_id,user_id,body,created_at')
      .order('created_at', { ascending: false }),
  ])
  if (showLoading) {
    loading.value = false
  }

  const error = tasksRes.error || projectsRes.error || profilesRes.error || commentsRes.error
  if (error) {
    errorMsg.value = error.message
    return { ok: false, hasData: hasDashboardData() }
  }

  tasks.value = tasksRes.data ?? []
  projects.value = projectsRes.data ?? []
  profiles.value = profilesRes.data ?? []
  comments.value = commentsRes.data ?? []
  const hasData = hasDashboardData()
  if (hasData) hadVisibleData.value = true
  return { ok: true, hasData }
}

// Ensure data is loaded, with short retries if needed
const ensureDashboardDataLoaded = async (options: { showLoading?: boolean } = {}) => {
  if (!user.value) return
  if (ensureLoadPromise) {
    await ensureLoadPromise
    return
  }

  ensureLoadPromise = (async () => {
    const { showLoading = true } = options
    const extraRetries = hadVisibleData.value ? 2 : 1
    for (let attempt = 0; attempt <= extraRetries; attempt += 1) {
      const result = await fetchDashboardData({ clearError: attempt === 0, showLoading })
      if (!result.ok || result.hasData) return
      if (attempt < extraRetries) {
        await wait(700 * (attempt + 1))
      }
    }
  })()

  try {
    await ensureLoadPromise
  } finally {
    ensureLoadPromise = null
  }
}

// Refresh data when the window regains focus
const handleWindowFocus = async () => {
  if (!user.value) return
  await ensureDashboardDataLoaded({ showLoading: false })
}

let refreshTimer: ReturnType<typeof setInterval> | null = null

// Polling-based refresh loop (every 5 seconds)
const startAutoRefresh = () => {
  if (refreshTimer) clearInterval(refreshTimer)
  refreshTimer = setInterval(() => {
    if (!user.value || loading.value) return
    ensureDashboardDataLoaded({ showLoading: false })
  }, 5_000)
}

const stopAutoRefresh = () => {
  if (!refreshTimer) return
  clearInterval(refreshTimer)
  refreshTimer = null
}

// React to auth changes and page lifecycle
watch(
  () => user.value?.id,
  async (id: string | null) => {
    if (!id) return
    await ensureDashboardDataLoaded()
  },
  { immediate: true },
)

onMounted(() => {
  startAutoRefresh()
  window.addEventListener('focus', handleWindowFocus)
  if (user.value?.id) {
    ensureDashboardDataLoaded()
  }
})

onBeforeUnmount(() => {
  stopAutoRefresh()
  window.removeEventListener('focus', handleWindowFocus)
})
</script>
