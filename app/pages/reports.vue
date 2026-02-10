<template>
  <div class="reports-layout">
    <div class="reports-header">
      <p class="section-kicker in">Analytics</p>
      <h1 class="page-title">Reports</h1>
      <p class="page-subtitle">Generate quick operational snapshots from live workspace data.</p>
      <p v-if="!isAuthenticated" class="reports-auth-hint">Sign in to generate reports.</p>
    </div>

    <div v-if="errorMsg" class="reports-error">{{ errorMsg }}</div>

    <section class="card-surface reports-panel">
      <div class="reports-panel-head">
        <div>
          <p class="reports-panel-eyebrow">Workspace Intelligence</p>
          <h2 class="reports-panel-title">Report Builder</h2>
          <p class="reports-panel-subtitle">Run a report, review the output, then export as CSV.</p>
        </div>
        <div class="reports-panel-actions">
          <button
            class="btn-ghost reports-export"
            type="button"
            :disabled="loading || !isAuthenticated || !activeReport"
            @click="exportCsv"
          >
            Export CSV
          </button>
        </div>
      </div>

      <div class="reports-tabs">
        <button
          class="reports-tab"
          :class="{ 'is-active': activeReport === 'tasks' }"
          type="button"
          :disabled="loading || !isAuthenticated"
          @click="generateTasksReport"
        >
          Task Report
        </button>
        <button
          class="reports-tab"
          :class="{ 'is-active': activeReport === 'projects' }"
          type="button"
          :disabled="loading || !isAuthenticated"
          @click="generateProjectsReport"
        >
          Project Report
        </button>
        <button
          class="reports-tab"
          :class="{ 'is-active': activeReport === 'users' }"
          type="button"
          :disabled="loading || !isAuthenticated"
          @click="generateUsersReport"
        >
          User Report
        </button>
      </div>

      <div class="reports-stats">
        <div class="reports-stat">
          <p class="reports-stat-label">Tasks</p>
          <p class="reports-stat-value">{{ tasks.length }}</p>
        </div>
        <div class="reports-stat">
          <p class="reports-stat-label">Projects</p>
          <p class="reports-stat-value">{{ projects.length }}</p>
        </div>
        <div class="reports-stat">
          <p class="reports-stat-label">Users Tracked</p>
          <p class="reports-stat-value">{{ trackedUsers }}</p>
        </div>
        <div class="reports-stat">
          <p class="reports-stat-label">Comments</p>
          <p class="reports-stat-value">{{ comments.length }}</p>
        </div>
      </div>

      <div class="reports-output-card">
        <div class="reports-output-head">
          <p class="reports-output-title">
            {{ activeReport ? `${activeReportLabel} Output` : 'Report Output' }}
          </p>
          <p class="reports-generated-at">
            {{ lastGeneratedAt ? `Updated ${formatDateTime(lastGeneratedAt)}` : 'Not generated yet' }}
          </p>
        </div>
        <textarea
          v-model="reportOutput"
          class="reports-output"
          readonly
          spellcheck="false"
          aria-label="Generated report output"
        ></textarea>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import type { Database } from '~/types/database.types'

// Database row types used by report generators
type Task = Database['public']['Tables']['tasks']['Row']
type Project = Database['public']['Tables']['projects']['Row']
type Profile = Database['public']['Tables']['profiles']['Row']
type Comment = Database['public']['Tables']['comments']['Row']
type ReportType = 'tasks' | 'projects' | 'users'

// Supabase client + auth state
const client = useSupabaseClient<Database>()
const user = useSupabaseUser()
const isAuthenticated = computed(() => !!user.value)

// UI/report state
const loading = ref(false)
const errorMsg = ref('')
const reportOutput = ref('Choose a report type to generate an analytics snapshot.')
const activeReport = ref<ReportType | null>(null)
const lastGeneratedAt = ref<string | null>(null)
const csvHeaders = ref<string[]>([])
const csvRows = ref<string[][]>([])

// Data collections used for analytics
const tasks = ref<Task[]>([])
const projects = ref<Project[]>([])
const profiles = ref<Profile[]>([])
const comments = ref<Comment[]>([])

// Label for the selected report type
const activeReportLabel = computed(() => {
  switch (activeReport.value) {
    case 'tasks':
      return 'Task Report'
    case 'projects':
      return 'Project Report'
    case 'users':
      return 'User Report'
    default:
      return 'Report'
  }
})

// Count users referenced anywhere in workspace data
const trackedUsers = computed(() => {
  const ids = new Set<string>()
  for (const profile of profiles.value) ids.add(profile.id)
  for (const task of tasks.value) {
    if (task.user_id) ids.add(task.user_id)
    if (task.assignee) ids.add(task.assignee)
  }
  for (const project of projects.value) {
    if (project.user_id) ids.add(project.user_id)
  }
  for (const comment of comments.value) {
    if (comment.user_id) ids.add(comment.user_id)
  }
  return ids.size
})

// Display name helpers
const formatProfileName = (profile: Profile) => {
  const fullName = `${profile.first_name || ''} ${profile.last_name || ''}`.trim()
  return fullName || profile.email || 'User'
}

const profileLookup = computed(() => {
  return new Map(profiles.value.map((profile) => [profile.id, formatProfileName(profile)]))
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

// Lookups for names and labels
const profileName = (userId: string | null) => {
  if (!userId) return 'Unassigned'
  const knownName = profileLookup.value.get(userId)
  if (knownName) return knownName
  if (user.value?.id === userId) return currentUserDisplayName.value
  return 'User'
}

const projectLookup = computed(() => {
  return new Map(projects.value.map((project) => [project.id, project]))
})

const projectName = (projectId: number) => {
  return projectLookup.value.get(projectId)?.name ?? `Project #${projectId}`
}

const statusLabel = (status: string | null) => {
  switch ((status || '').toLowerCase()) {
    case 'in_progress':
      return 'In progress'
    case 'done':
      return 'Done'
    case 'todo':
      return 'Not started'
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

// Date helpers
const parseDate = (value: string | null) => {
  if (!value) return null
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? null : date
}

const formatDate = (value: string | null) => {
  const date = parseDate(value)
  if (!date) return '-'
  return date.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })
}

const formatDateTime = (value: string | null) => {
  const date = parseDate(value)
  if (!date) return '-'
  return date.toLocaleString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  })
}

// Comment counts per task
const commentsCountByTask = computed(() => {
  const map = new Map<number, number>()
  for (const comment of comments.value) {
    map.set(comment.task_id, (map.get(comment.task_id) ?? 0) + 1)
  }
  return map
})

// Text table helpers for report output
const truncate = (value: string, max: number) => {
  if (value.length <= max) return value
  if (max <= 1) return value.slice(0, max)
  return `${value.slice(0, max - 1)}~`
}

const buildTable = (headers: string[], rows: string[][]) => {
  if (!headers.length) return []
  const widths = headers.map((header, index) => {
    const widestCell = rows.reduce((acc, row) => Math.max(acc, (row[index] || '').length), header.length)
    return Math.min(36, widestCell)
  })
  const renderRow = (cells: string[]) =>
    widths
      .map((width, index) => truncate(cells[index] || '', width).padEnd(width, ' '))
      .join(' | ')

  return [
    renderRow(headers),
    widths.map((size) => '-'.repeat(size)).join('-|-'),
    ...rows.map((row) => renderRow(row)),
  ]
}

// Update UI after generating a report
const setGeneratedReport = (type: ReportType, output: string[], headers: string[], rows: string[][]) => {
  activeReport.value = type
  reportOutput.value = output.join('\n')
  csvHeaders.value = headers
  csvRows.value = rows
  lastGeneratedAt.value = new Date().toISOString()
}

// Load tasks/projects/profiles/comments in parallel
const fetchWorkspaceData = async () => {
  if (!user.value) return false
  loading.value = true
  errorMsg.value = ''
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
  loading.value = false

  const error = tasksRes.error || projectsRes.error || profilesRes.error || commentsRes.error
  if (error) {
    errorMsg.value = error.message
    return false
  }

  tasks.value = tasksRes.data ?? []
  projects.value = projectsRes.data ?? []
  profiles.value = profilesRes.data ?? []
  comments.value = commentsRes.data ?? []
  return true
}

// Task report builder
const generateTasksReport = async () => {
  const ok = await fetchWorkspaceData()
  if (!ok) return

  const today = new Date()
  today.setHours(0, 0, 0, 0)

  const total = tasks.value.length
  const done = tasks.value.filter((task) => task.status === 'done').length
  const inProgress = tasks.value.filter((task) => task.status === 'in_progress').length
  const todo = tasks.value.filter((task) => task.status === 'todo').length
  const overdue = tasks.value.filter((task) => {
    const due = parseDate(task.due_date)
    return !!due && due < today && task.status !== 'done'
  }).length
  const totalComments = comments.value.length

  const ordered = [...tasks.value].sort((a, b) => {
    const aDue = parseDate(a.due_date)?.getTime() ?? Number.MAX_SAFE_INTEGER
    const bDue = parseDate(b.due_date)?.getTime() ?? Number.MAX_SAFE_INTEGER
    if (aDue !== bDue) return aDue - bDue
    return a.id - b.id
  })

  const tableRows = ordered.map((task) => [
    String(task.id),
    task.title,
    projectName(task.project_id),
    statusLabel(task.status),
    task.priority || 'Medium',
    profileName(task.assignee),
    String(commentsCountByTask.value.get(task.id) ?? 0),
    formatDate(task.due_date),
  ])

  const csvHeader = [
    'task_id',
    'title',
    'project',
    'status',
    'priority',
    'assignee',
    'comments',
    'due_date',
    'estimated_hours',
    'created_at',
  ]
  const csvData = ordered.map((task) => [
    String(task.id),
    task.title,
    projectName(task.project_id),
    statusLabel(task.status),
    task.priority || 'Medium',
    profileName(task.assignee),
    String(commentsCountByTask.value.get(task.id) ?? 0),
    task.due_date || '',
    task.estimated_hours == null ? '' : String(task.estimated_hours),
    task.created_at || '',
  ])

  const output = [
    'TASK REPORT',
    `Generated: ${formatDateTime(new Date().toISOString())}`,
    '',
    `Total tasks: ${total}`,
    `Completed: ${done}`,
    `In progress: ${inProgress}`,
    `Not started: ${todo}`,
    `Overdue: ${overdue}`,
    `Total comments: ${totalComments}`,
    '',
    ...buildTable(['ID', 'Title', 'Project', 'Status', 'Priority', 'Assignee', 'Comments', 'Due'], tableRows),
  ]

  setGeneratedReport('tasks', output, csvHeader, csvData)
}

// Project report builder
const generateProjectsReport = async () => {
  const ok = await fetchWorkspaceData()
  if (!ok) return

  const taskByProject = new Map<number, Task[]>()
  for (const task of tasks.value) {
    const list = taskByProject.get(task.project_id) ?? []
    list.push(task)
    taskByProject.set(task.project_id, list)
  }

  const commentsByProject = new Map<number, number>()
  for (const comment of comments.value) {
    const task = tasks.value.find((item) => item.id === comment.task_id)
    if (!task) continue
    commentsByProject.set(task.project_id, (commentsByProject.get(task.project_id) ?? 0) + 1)
  }

  const ordered = [...projects.value].sort((a, b) => a.name.localeCompare(b.name))
  const tableRows = ordered.map((project) => {
    const list = taskByProject.get(project.id) ?? []
    const done = list.filter((task) => task.status === 'done').length
    const progress = list.filter((task) => task.status === 'in_progress').length
    const todo = list.filter((task) => task.status === 'todo').length
    const completion = list.length ? `${Math.round((done / list.length) * 100)}%` : '0%'
    return [
      String(project.id),
      project.name,
      statusLabel(project.status),
      String(list.length),
      String(done),
      String(progress),
      String(todo),
      String(commentsByProject.get(project.id) ?? 0),
      completion,
    ]
  })

  const csvHeader = [
    'project_id',
    'project_name',
    'status',
    'tasks_total',
    'tasks_done',
    'tasks_in_progress',
    'tasks_todo',
    'comments',
    'completion_percent',
    'created_at',
  ]
  const csvData = ordered.map((project) => {
    const list = taskByProject.get(project.id) ?? []
    const done = list.filter((task) => task.status === 'done').length
    const progress = list.filter((task) => task.status === 'in_progress').length
    const todo = list.filter((task) => task.status === 'todo').length
    const completion = list.length ? String(Math.round((done / list.length) * 100)) : '0'
    return [
      String(project.id),
      project.name,
      statusLabel(project.status),
      String(list.length),
      String(done),
      String(progress),
      String(todo),
      String(commentsByProject.get(project.id) ?? 0),
      completion,
      project.created_at || '',
    ]
  })

  const activeCount = projects.value.filter((project) => (project.status || '').toLowerCase() === 'active').length
  const pausedCount = projects.value.filter((project) => (project.status || '').toLowerCase() === 'paused').length
  const archivedCount = projects.value.filter((project) => (project.status || '').toLowerCase() === 'archived').length

  const output = [
    'PROJECT REPORT',
    `Generated: ${formatDateTime(new Date().toISOString())}`,
    '',
    `Total projects: ${projects.value.length}`,
    `Active: ${activeCount}`,
    `Paused: ${pausedCount}`,
    `Archived: ${archivedCount}`,
    `Total tasks: ${tasks.value.length}`,
    '',
    ...buildTable(
      ['ID', 'Project', 'Status', 'Tasks', 'Done', 'In Progress', 'To Do', 'Comments', 'Completion'],
      tableRows,
    ),
  ]

  setGeneratedReport('projects', output, csvHeader, csvData)
}

// User report builder
const generateUsersReport = async () => {
  const ok = await fetchWorkspaceData()
  if (!ok) return

  const userIds = new Set<string>()
  for (const profile of profiles.value) userIds.add(profile.id)
  for (const task of tasks.value) {
    if (task.user_id) userIds.add(task.user_id)
    if (task.assignee) userIds.add(task.assignee)
  }
  for (const project of projects.value) {
    if (project.user_id) userIds.add(project.user_id)
  }
  for (const comment of comments.value) {
    if (comment.user_id) userIds.add(comment.user_id)
  }

  const summaries = [...userIds].map((userId) => {
    const createdTasks = tasks.value.filter((task) => task.user_id === userId)
    const assignedTasks = tasks.value.filter((task) => task.assignee === userId)
    const completedAssigned = assignedTasks.filter((task) => task.status === 'done')
    const createdProjects = projects.value.filter((project) => project.user_id === userId)
    const writtenComments = comments.value.filter((comment) => comment.user_id === userId)

    const dateCandidates: number[] = []
    for (const task of createdTasks) {
      const parsed = parseDate(task.created_at)
      if (parsed) dateCandidates.push(parsed.getTime())
    }
    for (const task of assignedTasks) {
      const parsed = parseDate(task.created_at)
      if (parsed) dateCandidates.push(parsed.getTime())
    }
    for (const project of createdProjects) {
      const parsed = parseDate(project.created_at)
      if (parsed) dateCandidates.push(parsed.getTime())
    }
    for (const comment of writtenComments) {
      const parsed = parseDate(comment.created_at)
      if (parsed) dateCandidates.push(parsed.getTime())
    }

    return {
      userId,
      name: profileName(userId),
      email: profiles.value.find((profile) => profile.id === userId)?.email || '',
      createdProjects: createdProjects.length,
      createdTasks: createdTasks.length,
      assignedTasks: assignedTasks.length,
      completedAssigned: completedAssigned.length,
      commentsWritten: writtenComments.length,
      lastActivity: dateCandidates.length ? new Date(Math.max(...dateCandidates)).toISOString() : '',
    }
  })

  summaries.sort((a, b) => {
    const scoreA = a.createdTasks + a.assignedTasks + a.commentsWritten
    const scoreB = b.createdTasks + b.assignedTasks + b.commentsWritten
    if (scoreA !== scoreB) return scoreB - scoreA
    return a.name.localeCompare(b.name)
  })

  const tableRows = summaries.map((summary) => [
    summary.name,
    summary.email || '-',
    String(summary.createdProjects),
    String(summary.createdTasks),
    String(summary.assignedTasks),
    String(summary.completedAssigned),
    String(summary.commentsWritten),
    formatDate(summary.lastActivity || null),
  ])

  const csvHeader = [
    'user_id',
    'name',
    'email',
    'created_projects',
    'created_tasks',
    'assigned_tasks',
    'completed_assigned_tasks',
    'comments_written',
    'last_activity',
  ]
  const csvData = summaries.map((summary) => [
    summary.userId,
    summary.name,
    summary.email,
    String(summary.createdProjects),
    String(summary.createdTasks),
    String(summary.assignedTasks),
    String(summary.completedAssigned),
    String(summary.commentsWritten),
    summary.lastActivity,
  ])

  const output = [
    'USER REPORT',
    `Generated: ${formatDateTime(new Date().toISOString())}`,
    '',
    `Users detected: ${summaries.length}`,
    `Assigned tasks: ${tasks.value.filter((task) => !!task.assignee).length}`,
    `Comments logged: ${comments.value.length}`,
    '',
    ...buildTable(
      ['User', 'Email', 'Projects', 'Tasks Created', 'Tasks Assigned', 'Done', 'Comments', 'Last Activity'],
      tableRows,
    ),
  ]

  setGeneratedReport('users', output, csvHeader, csvData)
}

// CSV export helpers
const escapeCsvCell = (value: string) => {
  if (value.includes('"') || value.includes(',') || value.includes('\n')) {
    return `"${value.replaceAll('"', '""')}"`
  }
  return value
}

const exportCsv = () => {
  if (!activeReport.value || !csvHeaders.value.length) {
    errorMsg.value = 'Generate a report before exporting to CSV.'
    return
  }
  if (process.server) return

  const content = [csvHeaders.value, ...csvRows.value]
    .map((row) => row.map((cell) => escapeCsvCell(cell || '')).join(','))
    .join('\n')

  const blob = new Blob([content], { type: 'text/csv;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  const stamp = new Date().toISOString().replace(/[:.]/g, '-')
  link.href = url
  link.download = `taskly-${activeReport.value}-report-${stamp}.csv`
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(url)
}

// Refresh data when the auth user changes
watch(
  () => user.value?.id,
  async (id) => {
    if (!id) {
      tasks.value = []
      projects.value = []
      profiles.value = []
      comments.value = []
      return
    }
    await fetchWorkspaceData()
  },
  { immediate: true },
)
</script>
