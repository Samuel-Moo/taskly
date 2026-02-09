export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          first_name: string | null
          last_name: string | null
          email: string | null
          created_at: string | null
        }
        Insert: {
          id: string
          first_name?: string | null
          last_name?: string | null
          email?: string | null
          created_at?: string | null
        }
        Update: {
          id?: string
          first_name?: string | null
          last_name?: string | null
          email?: string | null
          created_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: 'profiles_id_fkey'
            columns: ['id']
            referencedRelation: 'users'
            referencedColumns: ['id']
          }
        ]
      }
      projects: {
        Row: {
          id: number
          user_id: string
          name: string
          description: string | null
          status: string | null
          created_at: string | null
        }
        Insert: {
          id?: number
          user_id?: string
          name: string
          description?: string | null
          status?: string | null
          created_at?: string | null
        }
        Update: {
          id?: number
          user_id?: string
          name?: string
          description?: string | null
          status?: string | null
          created_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: 'projects_user_id_fkey'
            columns: ['user_id']
            referencedRelation: 'users'
            referencedColumns: ['id']
          }
        ]
      }
      tasks: {
        Row: {
          id: number
          user_id: string
          project_id: number
          title: string
          description: string | null
          status: string
          priority: string
          assignee: string | null
          due_date: string | null
          estimated_hours: number | null
          position: number | null
          created_at: string | null
        }
        Insert: {
          id?: number
          user_id?: string
          project_id: number
          title: string
          description?: string | null
          status?: string
          priority?: string
          assignee?: string | null
          due_date?: string | null
          estimated_hours?: number | null
          position?: number | null
          created_at?: string | null
        }
        Update: {
          id?: number
          user_id?: string
          project_id?: number
          title?: string
          description?: string | null
          status?: string
          priority?: string
          assignee?: string | null
          due_date?: string | null
          estimated_hours?: number | null
          position?: number | null
          created_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: 'tasks_project_id_fkey'
            columns: ['project_id']
            referencedRelation: 'projects'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'tasks_user_id_fkey'
            columns: ['user_id']
            referencedRelation: 'users'
            referencedColumns: ['id']
          }
        ]
      }
      comments: {
        Row: {
          id: number
          task_id: number
          user_id: string
          body: string
          created_at: string | null
        }
        Insert: {
          id?: number
          task_id: number
          user_id?: string
          body: string
          created_at?: string | null
        }
        Update: {
          id?: number
          task_id?: number
          user_id?: string
          body?: string
          created_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: 'comments_task_id_fkey'
            columns: ['task_id']
            referencedRelation: 'tasks'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'comments_user_id_fkey'
            columns: ['user_id']
            referencedRelation: 'users'
            referencedColumns: ['id']
          }
        ]
      }
    }
    Views: Record<string, never>
    Functions: Record<string, never>
    Enums: Record<string, never>
    CompositeTypes: Record<string, never>
  }
}
