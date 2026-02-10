<template>
  <div class="comments-layout">
    <div class="comments-header">
      <p class="section-kicker in">Collaboration</p>
      <h1 class="page-title">Comments</h1>
      <p v-if="!isAuthenticated" class="comments-auth-hint">Sign in to add comments.</p>
    </div>

    <div v-if="errorMsg" class="comments-error">{{ errorMsg }}</div>

    <div class="comments-grid">
      <article v-for="task in forumTasks" :key="task.id" class="card-surface comments-thread">
        <header class="comments-thread-head">
          <div class="comments-thread-main">
            <p class="comments-thread-project">{{ projectName(task.project_id) }}</p>
            <h3 class="comments-thread-title">{{ task.title }}</h3>
          </div>
          <div class="comments-thread-badges">
            <span class="comments-thread-pill comments-thread-pill--status">{{ statusLabel(task.status) }}</span>
            <span class="comments-thread-pill">{{ taskComments(task.id).length }} replies</span>
          </div>
        </header>

        <p v-if="task.description" class="comments-thread-desc">{{ task.description }}</p>

        <div class="comments-replies">
          <p v-if="taskComments(task.id).length === 0" class="comments-empty">No comments yet.</p>
          <div v-for="comment in previewComments(task.id)" :key="comment.id" class="comments-reply">
            <div class="comments-avatar">{{ initials(profileName(comment.user_id)) }}</div>
            <div class="comments-reply-content">
              <p class="comments-reply-meta">
                <span class="comments-reply-author">{{ profileName(comment.user_id) }}</span>
                <span>{{ formatDateTime(comment.created_at) }}</span>
              </p>
              <p class="comments-reply-body">{{ comment.body }}</p>
            </div>
          </div>
          <p v-if="extraReplies(task.id) > 0" class="comments-more">+{{ extraReplies(task.id) }} older replies</p>
        </div>

        <form class="comments-compose" @submit.prevent="submitComment(task.id)">
          <label class="comments-label" :for="`comment-input-${task.id}`">Quick reply</label>
          <label class="form-field comments-compose-field">
            <div class="form-field-inner">
              <textarea
                :id="`comment-input-${task.id}`"
                v-model="drafts[task.id]"
                class="form-textarea comments-compose-textarea"
                placeholder="Write a reply..."
              ></textarea>
            </div>
          </label>
          <div class="comments-actions">
            <button class="btn-ghost comments-submit" type="submit" :disabled="loading || !isAuthenticated">
              Reply
            </button>
          </div>
        </form>
      </article>
    </div>

    <p v-if="!fetching && forumTasks.length === 0" class="comments-empty">
      No tasks yet. Create one from the Tasks page.
    </p>
  </div>
</template>

<script setup lang="ts">
import type { Database } from '~/types/database.types'

// Database row types for the forum view
type Task = Database['public']['Tables']['tasks']['Row']
type Project = Database['public']['Tables']['projects']['Row']
type Profile = Database['public']['Tables']['profiles']['Row']
type Comment = Database['public']['Tables']['comments']['Row']

// Supabase client + auth state
const client = useSupabaseClient<Database>()
const user = useSupabaseUser()
const isAuthenticated = computed(() => !!user.value)
const loading = ref(false)
const fetching = ref(false)
const errorMsg = ref('')

// Data collections + draft comment text per task
const tasks = ref<Task[]>([])
const projects = ref<Project[]>([])
const profiles = ref<Profile[]>([])
const comments = ref<Comment[]>([])
const drafts = reactive<Record<number, string>>({})

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

// Safe label resolution for authors
const profileName = (userId: string | null) => {
  if (!userId) return 'User'
  const knownName = profileLookup.value.get(userId)
  if (knownName) return knownName
  if (user.value?.id === userId) return currentUserDisplayName.value
  return 'User'
}

// Fallback to fetch auth user id if reactive user is missing
const resolveCommentUserId = async () => {
  const reactiveUserId = readString(user.value?.id)
  if (reactiveUserId) return reactiveUserId

  const { data, error } = await client.auth.getUser()
  if (error) return ''
  return readString(data.user?.id)
}

// Project/task label helpers
const projectName = (projectId: number) => {
  const project = projects.value.find((item) => item.id === projectId)
  return project?.name || 'Unassigned'
}

const statusLabel = (status: string) => {
  switch (status) {
    case 'in_progress':
      return 'In progress'
    case 'done':
      return 'Done'
    case 'todo':
    default:
      return 'Not started'
  }
}

const formatDateTime = (value: string | null) => {
  if (!value) return 'Just now'
  const date = new Date(value)
  return date.toLocaleString(undefined, { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' })
}

// Group comments by task (sorted newest first)
const commentsByTask = computed(() => {
  const map = new Map<number, Comment[]>()
  const sorted = [...comments.value].sort((a, b) => {
    const aTime = a.created_at ? new Date(a.created_at).getTime() : 0
    const bTime = b.created_at ? new Date(b.created_at).getTime() : 0
    return bTime - aTime
  })
  for (const comment of sorted) {
    const list = map.get(comment.task_id) ?? []
    list.push(comment)
    map.set(comment.task_id, list)
  }
  return map
})

// Convenience selectors for comment previews
const taskComments = (taskId: number) => {
  return commentsByTask.value.get(taskId) ?? []
}

const previewComments = (taskId: number) => {
  return taskComments(taskId).slice(0, 3)
}

const extraReplies = (taskId: number) => {
  return Math.max(taskComments(taskId).length - 3, 0)
}

// Initials for avatar bubbles
const initials = (value: string) => {
  const clean = value.trim()
  if (!clean) return 'U'
  const parts = clean.split(/\s+/).filter(Boolean)
  const [first = '', second = ''] = parts
  if (!second) return first.slice(0, 2).toUpperCase()
  return `${first.charAt(0)}${second.charAt(0)}`.toUpperCase()
}

// Most recent reply timestamp per task
const lastCommentTime = (taskId: number) => {
  const latest = taskComments(taskId)[0]
  return latest?.created_at ? new Date(latest.created_at).getTime() : 0
}

// Sort tasks by latest reply activity
const forumTasks = computed(() => {
  return [...tasks.value].sort((a, b) => {
    const byRecentReply = lastCommentTime(b.id) - lastCommentTime(a.id)
    if (byRecentReply !== 0) return byRecentReply
    const bCreated = b.created_at ? new Date(b.created_at).getTime() : 0
    const aCreated = a.created_at ? new Date(a.created_at).getTime() : 0
    return bCreated - aCreated
  })
})

// Ensure each task has a draft entry
const ensureDrafts = () => {
  for (const task of tasks.value) {
    if (drafts[task.id] === undefined) {
      drafts[task.id] = ''
    }
  }
}

// Load tasks, projects, profiles, and comments together
const loadData = async () => {
  if (!user.value) return
  fetching.value = true
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
  fetching.value = false

  const error = tasksRes.error || projectsRes.error || profilesRes.error || commentsRes.error
  if (error) {
    errorMsg.value = error.message
    return
  }
  tasks.value = tasksRes.data ?? []
  projects.value = projectsRes.data ?? []
  profiles.value = profilesRes.data ?? []
  comments.value = commentsRes.data ?? []
  ensureDrafts()
}

// Submit a new comment for a task
const submitComment = async (taskId: number) => {
  const body = (drafts[taskId] || '').trim()
  if (!user.value || !body) return
  const userId = await resolveCommentUserId()
  if (!userId) {
    errorMsg.value = 'Could not resolve your authenticated user id. Sign out and sign in again.'
    return
  }
  loading.value = true
  errorMsg.value = ''
  const { data, error } = await client
    .from('comments')
    .insert({
      task_id: taskId,
      user_id: userId,
      body,
    })
    .select('id,task_id,user_id,body,created_at')
    .single()
  loading.value = false

  if (error) {
    errorMsg.value = error.message
    return
  }
  if (data) {
    comments.value = [data, ...comments.value]
  }
  drafts[taskId] = ''
}

// Fetch data on auth changes and keep drafts in sync
watchEffect(() => {
  if (user.value) {
    loadData()
  }
})

watch(tasks, () => ensureDrafts(), { deep: true })
</script>
