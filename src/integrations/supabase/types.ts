export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "13.0.5"
  }
  public: {
    Tables: {
      access_points: {
        Row: {
          company_id: string
          created_at: string | null
          id: string
          instructions: string | null
          is_mainland: boolean | null
          latitude: number | null
          location: string | null
          longitude: number | null
          name: string
          point_type: string | null
          updated_at: string | null
        }
        Insert: {
          company_id: string
          created_at?: string | null
          id?: string
          instructions?: string | null
          is_mainland?: boolean | null
          latitude?: number | null
          location?: string | null
          longitude?: number | null
          name: string
          point_type?: string | null
          updated_at?: string | null
        }
        Update: {
          company_id?: string
          created_at?: string | null
          id?: string
          instructions?: string | null
          is_mainland?: boolean | null
          latitude?: number | null
          location?: string | null
          longitude?: number | null
          name?: string
          point_type?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "access_points_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "access_points_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "access_points_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      ai_agents: {
        Row: {
          appearance: Json
          behavior: Json
          company_id: string | null
          created_at: string
          created_by: string | null
          description: string | null
          enabled: boolean
          guardrails: Json
          id: string
          identity: Json
          is_default: boolean
          name: string
          scope: Json
          slug: string
          tools_model: Json
          updated_at: string
        }
        Insert: {
          appearance?: Json
          behavior?: Json
          company_id?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          enabled?: boolean
          guardrails?: Json
          id?: string
          identity?: Json
          is_default?: boolean
          name: string
          scope?: Json
          slug: string
          tools_model?: Json
          updated_at?: string
        }
        Update: {
          appearance?: Json
          behavior?: Json
          company_id?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          enabled?: boolean
          guardrails?: Json
          id?: string
          identity?: Json
          is_default?: boolean
          name?: string
          scope?: Json
          slug?: string
          tools_model?: Json
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "ai_agents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_agents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "ai_agents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      ai_channel_bindings: {
        Row: {
          agent_id: string
          channel: string
          company_id: string | null
          config: Json
          created_at: string
          created_by: string | null
          enabled: boolean
          id: string
          updated_at: string
        }
        Insert: {
          agent_id: string
          channel: string
          company_id?: string | null
          config?: Json
          created_at?: string
          created_by?: string | null
          enabled?: boolean
          id?: string
          updated_at?: string
        }
        Update: {
          agent_id?: string
          channel?: string
          company_id?: string | null
          config?: Json
          created_at?: string
          created_by?: string | null
          enabled?: boolean
          id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "ai_channel_bindings_agent_id_fkey"
            columns: ["agent_id"]
            isOneToOne: false
            referencedRelation: "ai_agents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_channel_bindings_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_channel_bindings_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "ai_channel_bindings_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      ai_conversations: {
        Row: {
          company_id: string | null
          context: Json | null
          created_at: string | null
          id: string
          title: string | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          company_id?: string | null
          context?: Json | null
          created_at?: string | null
          id?: string
          title?: string | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          company_id?: string | null
          context?: Json | null
          created_at?: string | null
          id?: string
          title?: string | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "ai_conversations_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_conversations_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "ai_conversations_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      ai_email_activity: {
        Row: {
          action: string
          agent_id: string | null
          company_id: string | null
          created_at: string
          error_message: string | null
          external_message_id: string | null
          from_address: string | null
          id: string
          metadata: Json
          response_preview: string | null
          subject: string | null
        }
        Insert: {
          action: string
          agent_id?: string | null
          company_id?: string | null
          created_at?: string
          error_message?: string | null
          external_message_id?: string | null
          from_address?: string | null
          id?: string
          metadata?: Json
          response_preview?: string | null
          subject?: string | null
        }
        Update: {
          action?: string
          agent_id?: string | null
          company_id?: string | null
          created_at?: string
          error_message?: string | null
          external_message_id?: string | null
          from_address?: string | null
          id?: string
          metadata?: Json
          response_preview?: string | null
          subject?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "ai_email_activity_agent_id_fkey"
            columns: ["agent_id"]
            isOneToOne: false
            referencedRelation: "ai_agents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_email_activity_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_email_activity_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "ai_email_activity_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      ai_failure_patterns: {
        Row: {
          client_id: string | null
          company_id: string
          confidence_score: number | null
          created_at: string
          description: string
          id: string
          last_occurrence: string | null
          occurrences: number | null
          pattern_type: string
          suggested_action: string | null
          updated_at: string
          vessel_id: string | null
        }
        Insert: {
          client_id?: string | null
          company_id: string
          confidence_score?: number | null
          created_at?: string
          description: string
          id?: string
          last_occurrence?: string | null
          occurrences?: number | null
          pattern_type: string
          suggested_action?: string | null
          updated_at?: string
          vessel_id?: string | null
        }
        Update: {
          client_id?: string | null
          company_id?: string
          confidence_score?: number | null
          created_at?: string
          description?: string
          id?: string
          last_occurrence?: string | null
          occurrences?: number | null
          pattern_type?: string
          suggested_action?: string | null
          updated_at?: string
          vessel_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "ai_failure_patterns_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_failure_patterns_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_failure_patterns_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "ai_failure_patterns_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "ai_failure_patterns_vessel_id_fkey"
            columns: ["vessel_id"]
            isOneToOne: false
            referencedRelation: "vessels"
            referencedColumns: ["id"]
          },
        ]
      }
      ai_feedback: {
        Row: {
          comment: string | null
          created_at: string | null
          id: string
          message_id: string
          rating: string | null
          user_id: string
        }
        Insert: {
          comment?: string | null
          created_at?: string | null
          id?: string
          message_id: string
          rating?: string | null
          user_id: string
        }
        Update: {
          comment?: string | null
          created_at?: string | null
          id?: string
          message_id?: string
          rating?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "ai_feedback_message_id_fkey"
            columns: ["message_id"]
            isOneToOne: false
            referencedRelation: "ai_messages"
            referencedColumns: ["id"]
          },
        ]
      }
      ai_fine_tune_jobs: {
        Row: {
          agent_id: string | null
          base_model: string
          company_id: string | null
          cost_estimate: number | null
          created_at: string
          created_by: string | null
          dataset_storage_path: string | null
          error_message: string | null
          example_count: number
          external_job_id: string | null
          fine_tuned_model: string | null
          id: string
          metadata: Json
          provider: string
          status: string
          updated_at: string
        }
        Insert: {
          agent_id?: string | null
          base_model: string
          company_id?: string | null
          cost_estimate?: number | null
          created_at?: string
          created_by?: string | null
          dataset_storage_path?: string | null
          error_message?: string | null
          example_count?: number
          external_job_id?: string | null
          fine_tuned_model?: string | null
          id?: string
          metadata?: Json
          provider?: string
          status?: string
          updated_at?: string
        }
        Update: {
          agent_id?: string | null
          base_model?: string
          company_id?: string | null
          cost_estimate?: number | null
          created_at?: string
          created_by?: string | null
          dataset_storage_path?: string | null
          error_message?: string | null
          example_count?: number
          external_job_id?: string | null
          fine_tuned_model?: string | null
          id?: string
          metadata?: Json
          provider?: string
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "ai_fine_tune_jobs_agent_id_fkey"
            columns: ["agent_id"]
            isOneToOne: false
            referencedRelation: "ai_agents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_fine_tune_jobs_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_fine_tune_jobs_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "ai_fine_tune_jobs_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      ai_knowledge_chunks: {
        Row: {
          agent_id: string | null
          chunk_index: number
          company_id: string | null
          content: string
          created_at: string
          embedding: string | null
          id: string
          source_id: string
          token_count: number | null
        }
        Insert: {
          agent_id?: string | null
          chunk_index: number
          company_id?: string | null
          content: string
          created_at?: string
          embedding?: string | null
          id?: string
          source_id: string
          token_count?: number | null
        }
        Update: {
          agent_id?: string | null
          chunk_index?: number
          company_id?: string | null
          content?: string
          created_at?: string
          embedding?: string | null
          id?: string
          source_id?: string
          token_count?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "ai_knowledge_chunks_agent_id_fkey"
            columns: ["agent_id"]
            isOneToOne: false
            referencedRelation: "ai_agents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_knowledge_chunks_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_knowledge_chunks_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "ai_knowledge_chunks_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "ai_knowledge_chunks_source_id_fkey"
            columns: ["source_id"]
            isOneToOne: false
            referencedRelation: "ai_knowledge_sources"
            referencedColumns: ["id"]
          },
        ]
      }
      ai_knowledge_sources: {
        Row: {
          agent_id: string | null
          chunk_count: number
          company_id: string | null
          created_at: string
          created_by: string | null
          error_message: string | null
          id: string
          raw_text: string | null
          scope: Json
          source_type: string
          status: string
          storage_path: string | null
          tags: string[]
          title: string
          updated_at: string
          url: string | null
        }
        Insert: {
          agent_id?: string | null
          chunk_count?: number
          company_id?: string | null
          created_at?: string
          created_by?: string | null
          error_message?: string | null
          id?: string
          raw_text?: string | null
          scope?: Json
          source_type: string
          status?: string
          storage_path?: string | null
          tags?: string[]
          title: string
          updated_at?: string
          url?: string | null
        }
        Update: {
          agent_id?: string | null
          chunk_count?: number
          company_id?: string | null
          created_at?: string
          created_by?: string | null
          error_message?: string | null
          id?: string
          raw_text?: string | null
          scope?: Json
          source_type?: string
          status?: string
          storage_path?: string | null
          tags?: string[]
          title?: string
          updated_at?: string
          url?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "ai_knowledge_sources_agent_id_fkey"
            columns: ["agent_id"]
            isOneToOne: false
            referencedRelation: "ai_agents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_knowledge_sources_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_knowledge_sources_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "ai_knowledge_sources_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      ai_messages: {
        Row: {
          content: string
          conversation_id: string
          created_at: string | null
          id: string
          metadata: Json | null
          role: string
        }
        Insert: {
          content: string
          conversation_id: string
          created_at?: string | null
          id?: string
          metadata?: Json | null
          role: string
        }
        Update: {
          content?: string
          conversation_id?: string
          created_at?: string | null
          id?: string
          metadata?: Json | null
          role?: string
        }
        Relationships: [
          {
            foreignKeyName: "ai_messages_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "ai_conversations"
            referencedColumns: ["id"]
          },
        ]
      }
      ai_proactive_alerts: {
        Row: {
          alert_type: string
          company_id: string | null
          created_at: string | null
          id: string
          message: string
          read: boolean | null
          reference_data: Json | null
          title: string
          user_id: string
        }
        Insert: {
          alert_type: string
          company_id?: string | null
          created_at?: string | null
          id?: string
          message: string
          read?: boolean | null
          reference_data?: Json | null
          title: string
          user_id: string
        }
        Update: {
          alert_type?: string
          company_id?: string | null
          created_at?: string | null
          id?: string
          message?: string
          read?: boolean | null
          reference_data?: Json | null
          title?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "ai_proactive_alerts_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_proactive_alerts_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "ai_proactive_alerts_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      ai_training_examples: {
        Row: {
          active: boolean
          agent_id: string | null
          company_id: string | null
          created_at: string
          created_by: string | null
          id: string
          ideal_answer: string
          question: string
          source: string | null
          source_message_id: string | null
          tags: string[]
          updated_at: string
        }
        Insert: {
          active?: boolean
          agent_id?: string | null
          company_id?: string | null
          created_at?: string
          created_by?: string | null
          id?: string
          ideal_answer: string
          question: string
          source?: string | null
          source_message_id?: string | null
          tags?: string[]
          updated_at?: string
        }
        Update: {
          active?: boolean
          agent_id?: string | null
          company_id?: string | null
          created_at?: string
          created_by?: string | null
          id?: string
          ideal_answer?: string
          question?: string
          source?: string | null
          source_message_id?: string | null
          tags?: string[]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "ai_training_examples_agent_id_fkey"
            columns: ["agent_id"]
            isOneToOne: false
            referencedRelation: "ai_agents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_training_examples_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ai_training_examples_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "ai_training_examples_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      api_idempotency_keys: {
        Row: {
          created_at: string
          integration_id: string
          key: string
          response_body: Json
          response_status: number
        }
        Insert: {
          created_at?: string
          integration_id: string
          key: string
          response_body: Json
          response_status: number
        }
        Update: {
          created_at?: string
          integration_id?: string
          key?: string
          response_body?: Json
          response_status?: number
        }
        Relationships: [
          {
            foreignKeyName: "api_idempotency_keys_integration_id_fkey"
            columns: ["integration_id"]
            isOneToOne: false
            referencedRelation: "api_integrations"
            referencedColumns: ["id"]
          },
        ]
      }
      api_integrations: {
        Row: {
          company_id: string
          created_at: string
          created_by: string | null
          description: string | null
          id: string
          key_hash: string
          key_prefix: string
          last_used_at: string | null
          name: string
          scopes: string[]
          status: string
          updated_at: string
        }
        Insert: {
          company_id: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          key_hash: string
          key_prefix: string
          last_used_at?: string | null
          name: string
          scopes?: string[]
          status?: string
          updated_at?: string
        }
        Update: {
          company_id?: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          key_hash?: string
          key_prefix?: string
          last_used_at?: string | null
          name?: string
          scopes?: string[]
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "api_integrations_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "api_integrations_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "api_integrations_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "api_integrations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "api_integrations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "api_integrations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "api_integrations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      api_request_logs: {
        Row: {
          company_id: string | null
          created_at: string
          error_message: string | null
          id: string
          integration_id: string | null
          ip: string | null
          latency_ms: number | null
          method: string
          path: string
          status: number
          user_agent: string | null
        }
        Insert: {
          company_id?: string | null
          created_at?: string
          error_message?: string | null
          id?: string
          integration_id?: string | null
          ip?: string | null
          latency_ms?: number | null
          method: string
          path: string
          status: number
          user_agent?: string | null
        }
        Update: {
          company_id?: string | null
          created_at?: string
          error_message?: string | null
          id?: string
          integration_id?: string | null
          ip?: string | null
          latency_ms?: number | null
          method?: string
          path?: string
          status?: number
          user_agent?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "api_request_logs_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "api_request_logs_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "api_request_logs_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "api_request_logs_integration_id_fkey"
            columns: ["integration_id"]
            isOneToOne: false
            referencedRelation: "api_integrations"
            referencedColumns: ["id"]
          },
        ]
      }
      checklist_item_responses: {
        Row: {
          answered_at: string | null
          id: string
          item_id: string
          response_id: string
          value_boolean: boolean | null
          value_number: number | null
          value_photo_path: string | null
          value_text: string | null
        }
        Insert: {
          answered_at?: string | null
          id?: string
          item_id: string
          response_id: string
          value_boolean?: boolean | null
          value_number?: number | null
          value_photo_path?: string | null
          value_text?: string | null
        }
        Update: {
          answered_at?: string | null
          id?: string
          item_id?: string
          response_id?: string
          value_boolean?: boolean | null
          value_number?: number | null
          value_photo_path?: string | null
          value_text?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "checklist_item_responses_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "checklist_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_item_responses_response_id_fkey"
            columns: ["response_id"]
            isOneToOne: false
            referencedRelation: "checklist_responses"
            referencedColumns: ["id"]
          },
        ]
      }
      checklist_items: {
        Row: {
          created_at: string
          description: string
          id: string
          is_required: boolean | null
          item_order: number
          item_type: string
          template_id: string
        }
        Insert: {
          created_at?: string
          description: string
          id?: string
          is_required?: boolean | null
          item_order?: number
          item_type?: string
          template_id: string
        }
        Update: {
          created_at?: string
          description?: string
          id?: string
          is_required?: boolean | null
          item_order?: number
          item_type?: string
          template_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "checklist_items_template_id_fkey"
            columns: ["template_id"]
            isOneToOne: false
            referencedRelation: "checklist_templates"
            referencedColumns: ["id"]
          },
        ]
      }
      checklist_responses: {
        Row: {
          completed_at: string | null
          created_at: string
          id: string
          task_id: string
          technician_id: string | null
          template_id: string
          updated_at: string
        }
        Insert: {
          completed_at?: string | null
          created_at?: string
          id?: string
          task_id: string
          technician_id?: string | null
          template_id: string
          updated_at?: string
        }
        Update: {
          completed_at?: string | null
          created_at?: string
          id?: string
          task_id?: string
          technician_id?: string | null
          template_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "checklist_responses_task_id_fkey"
            columns: ["task_id"]
            isOneToOne: false
            referencedRelation: "tasks"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_responses_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_responses_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_responses_template_id_fkey"
            columns: ["template_id"]
            isOneToOne: false
            referencedRelation: "checklist_templates"
            referencedColumns: ["id"]
          },
        ]
      }
      checklist_templates: {
        Row: {
          company_id: string
          created_at: string
          description: string | null
          id: string
          is_mandatory: boolean | null
          name: string
          task_type_id: string | null
          updated_at: string
        }
        Insert: {
          company_id: string
          created_at?: string
          description?: string | null
          id?: string
          is_mandatory?: boolean | null
          name: string
          task_type_id?: string | null
          updated_at?: string
        }
        Update: {
          company_id?: string
          created_at?: string
          description?: string | null
          id?: string
          is_mandatory?: boolean | null
          name?: string
          task_type_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "checklist_templates_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_templates_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "checklist_templates_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "checklist_templates_task_type_id_fkey"
            columns: ["task_type_id"]
            isOneToOne: false
            referencedRelation: "task_types"
            referencedColumns: ["id"]
          },
        ]
      }
      city_distances: {
        Row: {
          company_id: string
          created_at: string | null
          distance_km: number
          from_city: string
          id: string
          to_city: string
          updated_at: string | null
        }
        Insert: {
          company_id: string
          created_at?: string | null
          distance_km: number
          from_city: string
          id?: string
          to_city: string
          updated_at?: string | null
        }
        Update: {
          company_id?: string
          created_at?: string | null
          distance_km?: number
          from_city?: string
          id?: string
          to_city?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "city_distances_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "city_distances_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "city_distances_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      client_addresses: {
        Row: {
          cep: string | null
          city: string | null
          client_id: string
          complement: string | null
          created_at: string | null
          id: string
          is_primary: boolean | null
          label: string | null
          state: string | null
          street: string | null
          street_number: string | null
          updated_at: string | null
        }
        Insert: {
          cep?: string | null
          city?: string | null
          client_id: string
          complement?: string | null
          created_at?: string | null
          id?: string
          is_primary?: boolean | null
          label?: string | null
          state?: string | null
          street?: string | null
          street_number?: string | null
          updated_at?: string | null
        }
        Update: {
          cep?: string | null
          city?: string | null
          client_id?: string
          complement?: string | null
          created_at?: string | null
          id?: string
          is_primary?: boolean | null
          label?: string | null
          state?: string | null
          street?: string | null
          street_number?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "client_addresses_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
        ]
      }
      client_contacts: {
        Row: {
          client_id: string
          created_at: string
          email: string | null
          id: string
          is_general: boolean | null
          is_primary: boolean | null
          name: string
          phone: string | null
          role: string | null
          updated_at: string
          whatsapp: string | null
        }
        Insert: {
          client_id: string
          created_at?: string
          email?: string | null
          id?: string
          is_general?: boolean | null
          is_primary?: boolean | null
          name: string
          phone?: string | null
          role?: string | null
          updated_at?: string
          whatsapp?: string | null
        }
        Update: {
          client_id?: string
          created_at?: string
          email?: string | null
          id?: string
          is_general?: boolean | null
          is_primary?: boolean | null
          name?: string
          phone?: string | null
          role?: string | null
          updated_at?: string
          whatsapp?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "client_contacts_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
        ]
      }
      client_legal_entities: {
        Row: {
          client_id: string
          cnpj: string | null
          created_at: string | null
          id: string
          is_primary: boolean | null
          legal_name: string
          updated_at: string | null
        }
        Insert: {
          client_id: string
          cnpj?: string | null
          created_at?: string | null
          id?: string
          is_primary?: boolean | null
          legal_name: string
          updated_at?: string | null
        }
        Update: {
          client_id?: string
          cnpj?: string | null
          created_at?: string | null
          id?: string
          is_primary?: boolean | null
          legal_name?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "client_legal_entities_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
        ]
      }
      clients: {
        Row: {
          address: string | null
          annual_revenue: number | null
          cep: string | null
          city: string | null
          cnpj: string | null
          commercial_status: string | null
          company_id: string
          contact_person: string | null
          created_at: string
          email: string | null
          id: string
          ignore_omie_sync: boolean
          last_contact_date: string | null
          name: string
          notes: string | null
          omie_client_id: number | null
          parent_client_id: string | null
          phone: string | null
          segment: string | null
          source: string | null
          state: string | null
          street: string | null
          street_number: string | null
          updated_at: string
        }
        Insert: {
          address?: string | null
          annual_revenue?: number | null
          cep?: string | null
          city?: string | null
          cnpj?: string | null
          commercial_status?: string | null
          company_id: string
          contact_person?: string | null
          created_at?: string
          email?: string | null
          id?: string
          ignore_omie_sync?: boolean
          last_contact_date?: string | null
          name: string
          notes?: string | null
          omie_client_id?: number | null
          parent_client_id?: string | null
          phone?: string | null
          segment?: string | null
          source?: string | null
          state?: string | null
          street?: string | null
          street_number?: string | null
          updated_at?: string
        }
        Update: {
          address?: string | null
          annual_revenue?: number | null
          cep?: string | null
          city?: string | null
          cnpj?: string | null
          commercial_status?: string | null
          company_id?: string
          contact_person?: string | null
          created_at?: string
          email?: string | null
          id?: string
          ignore_omie_sync?: boolean
          last_contact_date?: string | null
          name?: string
          notes?: string | null
          omie_client_id?: number | null
          parent_client_id?: string | null
          phone?: string | null
          segment?: string | null
          source?: string | null
          state?: string | null
          street?: string | null
          street_number?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "clients_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "clients_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "clients_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "clients_parent_client_id_fkey"
            columns: ["parent_client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
        ]
      }
      companies: {
        Row: {
          address: string | null
          careers_about_text: string | null
          careers_about_title: string | null
          careers_mission: string | null
          careers_values: string[] | null
          cep: string | null
          cnpj: string | null
          created_at: string
          email: string | null
          id: string
          logo_url: string | null
          name: string
          omie_app_key: string | null
          omie_app_secret: string | null
          omie_sync_enabled: boolean | null
          payment_status: Database["public"]["Enums"]["payment_status"] | null
          phone: string | null
          public_intake_enabled: boolean
          public_site_base_url: string | null
          public_site_slug: string | null
          subscription_plan:
            | Database["public"]["Enums"]["subscription_plan"]
            | null
          updated_at: string
        }
        Insert: {
          address?: string | null
          careers_about_text?: string | null
          careers_about_title?: string | null
          careers_mission?: string | null
          careers_values?: string[] | null
          cep?: string | null
          cnpj?: string | null
          created_at?: string
          email?: string | null
          id?: string
          logo_url?: string | null
          name: string
          omie_app_key?: string | null
          omie_app_secret?: string | null
          omie_sync_enabled?: boolean | null
          payment_status?: Database["public"]["Enums"]["payment_status"] | null
          phone?: string | null
          public_intake_enabled?: boolean
          public_site_base_url?: string | null
          public_site_slug?: string | null
          subscription_plan?:
            | Database["public"]["Enums"]["subscription_plan"]
            | null
          updated_at?: string
        }
        Update: {
          address?: string | null
          careers_about_text?: string | null
          careers_about_title?: string | null
          careers_mission?: string | null
          careers_values?: string[] | null
          cep?: string | null
          cnpj?: string | null
          created_at?: string
          email?: string | null
          id?: string
          logo_url?: string | null
          name?: string
          omie_app_key?: string | null
          omie_app_secret?: string | null
          omie_sync_enabled?: boolean | null
          payment_status?: Database["public"]["Enums"]["payment_status"] | null
          phone?: string | null
          public_intake_enabled?: boolean
          public_site_base_url?: string | null
          public_site_slug?: string | null
          subscription_plan?:
            | Database["public"]["Enums"]["subscription_plan"]
            | null
          updated_at?: string
        }
        Relationships: []
      }
      company_benefits: {
        Row: {
          company_id: string
          created_at: string
          description: string | null
          display_order: number
          icon: string | null
          id: string
          is_active: boolean
          title: string
          updated_at: string
        }
        Insert: {
          company_id: string
          created_at?: string
          description?: string | null
          display_order?: number
          icon?: string | null
          id?: string
          is_active?: boolean
          title: string
          updated_at?: string
        }
        Update: {
          company_id?: string
          created_at?: string
          description?: string | null
          display_order?: number
          icon?: string | null
          id?: string
          is_active?: boolean
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "company_benefits_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "company_benefits_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "company_benefits_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      company_holidays: {
        Row: {
          company_id: string
          created_at: string | null
          created_by: string | null
          holiday_date: string
          id: string
          is_recurring: boolean | null
          name: string
          updated_at: string | null
        }
        Insert: {
          company_id: string
          created_at?: string | null
          created_by?: string | null
          holiday_date: string
          id?: string
          is_recurring?: boolean | null
          name: string
          updated_at?: string | null
        }
        Update: {
          company_id?: string
          created_at?: string | null
          created_by?: string | null
          holiday_date?: string
          id?: string
          is_recurring?: boolean | null
          name?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "company_holidays_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "company_holidays_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "company_holidays_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "company_holidays_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "company_holidays_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "company_holidays_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "company_holidays_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      contact_vessel_links: {
        Row: {
          contact_id: string
          id: string
          vessel_id: string
        }
        Insert: {
          contact_id: string
          id?: string
          vessel_id: string
        }
        Update: {
          contact_id?: string
          id?: string
          vessel_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "contact_vessel_links_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "client_contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "contact_vessel_links_vessel_id_fkey"
            columns: ["vessel_id"]
            isOneToOne: false
            referencedRelation: "vessels"
            referencedColumns: ["id"]
          },
        ]
      }
      conversation_participants: {
        Row: {
          conversation_id: string
          id: string
          joined_at: string | null
          last_read_at: string | null
          user_id: string
        }
        Insert: {
          conversation_id: string
          id?: string
          joined_at?: string | null
          last_read_at?: string | null
          user_id: string
        }
        Update: {
          conversation_id?: string
          id?: string
          joined_at?: string | null
          last_read_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "conversation_participants_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
        ]
      }
      conversations: {
        Row: {
          company_id: string
          conversation_type: string | null
          created_at: string | null
          created_by: string | null
          id: string
          service_order_id: string | null
          title: string | null
          updated_at: string | null
        }
        Insert: {
          company_id: string
          conversation_type?: string | null
          created_at?: string | null
          created_by?: string | null
          id?: string
          service_order_id?: string | null
          title?: string | null
          updated_at?: string | null
        }
        Update: {
          company_id?: string
          conversation_type?: string | null
          created_at?: string | null
          created_by?: string | null
          id?: string
          service_order_id?: string | null
          title?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "conversations_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conversations_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "conversations_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "conversations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conversations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conversations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conversations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "conversations_service_order_id_fkey"
            columns: ["service_order_id"]
            isOneToOne: false
            referencedRelation: "service_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      corp_audit_log: {
        Row: {
          action: string
          company_id: string
          created_at: string
          details: Json | null
          entity_id: string | null
          entity_type: string | null
          id: string
          user_id: string | null
        }
        Insert: {
          action: string
          company_id: string
          created_at?: string
          details?: Json | null
          entity_id?: string | null
          entity_type?: string | null
          id?: string
          user_id?: string | null
        }
        Update: {
          action?: string
          company_id?: string
          created_at?: string
          details?: Json | null
          entity_id?: string | null
          entity_type?: string | null
          id?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "corp_audit_log_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_audit_log_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "corp_audit_log_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "corp_audit_log_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_audit_log_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_audit_log_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_audit_log_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      corp_badges: {
        Row: {
          awarded_at: string
          awarded_by: string | null
          badge_type: string
          category: string | null
          company_id: string
          description: string | null
          icon: string | null
          id: string
          title: string
          user_id: string
          xp_value: number | null
        }
        Insert: {
          awarded_at?: string
          awarded_by?: string | null
          badge_type: string
          category?: string | null
          company_id: string
          description?: string | null
          icon?: string | null
          id?: string
          title: string
          user_id: string
          xp_value?: number | null
        }
        Update: {
          awarded_at?: string
          awarded_by?: string | null
          badge_type?: string
          category?: string | null
          company_id?: string
          description?: string | null
          icon?: string | null
          id?: string
          title?: string
          user_id?: string
          xp_value?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "corp_badges_awarded_by_fkey"
            columns: ["awarded_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_badges_awarded_by_fkey"
            columns: ["awarded_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_badges_awarded_by_fkey"
            columns: ["awarded_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_badges_awarded_by_fkey"
            columns: ["awarded_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "corp_badges_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_badges_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "corp_badges_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "corp_badges_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_badges_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_badges_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_badges_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      corp_documents: {
        Row: {
          company_id: string
          created_at: string
          department_id: string | null
          document_type: string
          file_name: string
          file_url: string
          id: string
          owner_user_id: string
          related_request_id: string | null
          title: string
          uploaded_by: string
          visibility_level: string
        }
        Insert: {
          company_id: string
          created_at?: string
          department_id?: string | null
          document_type: string
          file_name: string
          file_url: string
          id?: string
          owner_user_id: string
          related_request_id?: string | null
          title: string
          uploaded_by: string
          visibility_level?: string
        }
        Update: {
          company_id?: string
          created_at?: string
          department_id?: string | null
          document_type?: string
          file_name?: string
          file_url?: string
          id?: string
          owner_user_id?: string
          related_request_id?: string | null
          title?: string
          uploaded_by?: string
          visibility_level?: string
        }
        Relationships: [
          {
            foreignKeyName: "corp_documents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_documents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "corp_documents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "corp_documents_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_documents_owner_user_id_fkey"
            columns: ["owner_user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_documents_owner_user_id_fkey"
            columns: ["owner_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_documents_owner_user_id_fkey"
            columns: ["owner_user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_documents_owner_user_id_fkey"
            columns: ["owner_user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "corp_documents_related_request_id_fkey"
            columns: ["related_request_id"]
            isOneToOne: false
            referencedRelation: "corp_requests"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_documents_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_documents_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_documents_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_documents_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      corp_feed_attachments: {
        Row: {
          created_at: string
          file_name: string
          file_size: number | null
          file_type: string
          file_url: string
          id: string
          mime_type: string | null
          post_id: string
        }
        Insert: {
          created_at?: string
          file_name: string
          file_size?: number | null
          file_type?: string
          file_url: string
          id?: string
          mime_type?: string | null
          post_id: string
        }
        Update: {
          created_at?: string
          file_name?: string
          file_size?: number | null
          file_type?: string
          file_url?: string
          id?: string
          mime_type?: string | null
          post_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "corp_feed_attachments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "corp_feed_posts"
            referencedColumns: ["id"]
          },
        ]
      }
      corp_feed_comments: {
        Row: {
          author_id: string
          content: string
          created_at: string
          id: string
          post_id: string
          updated_at: string
        }
        Insert: {
          author_id: string
          content: string
          created_at?: string
          id?: string
          post_id: string
          updated_at?: string
        }
        Update: {
          author_id?: string
          content?: string
          created_at?: string
          id?: string
          post_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "corp_feed_comments_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_comments_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_comments_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_comments_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "corp_feed_comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "corp_feed_posts"
            referencedColumns: ["id"]
          },
        ]
      }
      corp_feed_discussion_replies: {
        Row: {
          author_id: string
          content: string
          created_at: string
          discussion_id: string
          id: string
        }
        Insert: {
          author_id: string
          content: string
          created_at?: string
          discussion_id: string
          id?: string
        }
        Update: {
          author_id?: string
          content?: string
          created_at?: string
          discussion_id?: string
          id?: string
        }
        Relationships: [
          {
            foreignKeyName: "corp_feed_discussion_replies_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_discussion_replies_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_discussion_replies_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_discussion_replies_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "corp_feed_discussion_replies_discussion_id_fkey"
            columns: ["discussion_id"]
            isOneToOne: false
            referencedRelation: "corp_feed_discussions"
            referencedColumns: ["id"]
          },
        ]
      }
      corp_feed_discussions: {
        Row: {
          author_id: string
          company_id: string
          content: string | null
          created_at: string
          id: string
          pinned: boolean
          title: string
          updated_at: string
        }
        Insert: {
          author_id: string
          company_id: string
          content?: string | null
          created_at?: string
          id?: string
          pinned?: boolean
          title: string
          updated_at?: string
        }
        Update: {
          author_id?: string
          company_id?: string
          content?: string | null
          created_at?: string
          id?: string
          pinned?: boolean
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "corp_feed_discussions_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_discussions_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_discussions_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_discussions_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "corp_feed_discussions_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_discussions_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "corp_feed_discussions_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      corp_feed_likes: {
        Row: {
          created_at: string
          id: string
          post_id: string
          reaction_type: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          post_id: string
          reaction_type?: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          post_id?: string
          reaction_type?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "corp_feed_likes_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "corp_feed_posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_likes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_likes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_likes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_likes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      corp_feed_mentions: {
        Row: {
          created_at: string
          display_name: string
          id: string
          mention_type: string
          mention_value: string
          post_id: string
        }
        Insert: {
          created_at?: string
          display_name: string
          id?: string
          mention_type: string
          mention_value: string
          post_id: string
        }
        Update: {
          created_at?: string
          display_name?: string
          id?: string
          mention_type?: string
          mention_value?: string
          post_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "corp_feed_mentions_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "corp_feed_posts"
            referencedColumns: ["id"]
          },
        ]
      }
      corp_feed_poll_options: {
        Row: {
          id: string
          option_text: string
          poll_id: string
          position: number
        }
        Insert: {
          id?: string
          option_text: string
          poll_id: string
          position?: number
        }
        Update: {
          id?: string
          option_text?: string
          poll_id?: string
          position?: number
        }
        Relationships: [
          {
            foreignKeyName: "corp_feed_poll_options_poll_id_fkey"
            columns: ["poll_id"]
            isOneToOne: false
            referencedRelation: "corp_feed_polls"
            referencedColumns: ["id"]
          },
        ]
      }
      corp_feed_poll_votes: {
        Row: {
          created_at: string
          id: string
          option_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          option_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          option_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "corp_feed_poll_votes_option_id_fkey"
            columns: ["option_id"]
            isOneToOne: false
            referencedRelation: "corp_feed_poll_options"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_poll_votes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_poll_votes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_poll_votes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_poll_votes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      corp_feed_polls: {
        Row: {
          allow_multiple: boolean
          closed_at: string | null
          created_at: string
          ends_at: string | null
          group_id: string | null
          id: string
          post_id: string
          question: string
          status: string
        }
        Insert: {
          allow_multiple?: boolean
          closed_at?: string | null
          created_at?: string
          ends_at?: string | null
          group_id?: string | null
          id?: string
          post_id: string
          question: string
          status?: string
        }
        Update: {
          allow_multiple?: boolean
          closed_at?: string | null
          created_at?: string
          ends_at?: string | null
          group_id?: string | null
          id?: string
          post_id?: string
          question?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "corp_feed_polls_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "corp_groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_polls_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "corp_feed_posts"
            referencedColumns: ["id"]
          },
        ]
      }
      corp_feed_posts: {
        Row: {
          author_id: string
          company_id: string
          content: string
          created_at: string
          id: string
          pinned: boolean
          post_type: string
          quality_document_id: string | null
          sgq_tag: boolean
          title: string | null
          updated_at: string
        }
        Insert: {
          author_id: string
          company_id: string
          content: string
          created_at?: string
          id?: string
          pinned?: boolean
          post_type?: string
          quality_document_id?: string | null
          sgq_tag?: boolean
          title?: string | null
          updated_at?: string
        }
        Update: {
          author_id?: string
          company_id?: string
          content?: string
          created_at?: string
          id?: string
          pinned?: boolean
          post_type?: string
          quality_document_id?: string | null
          sgq_tag?: boolean
          title?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "corp_feed_posts_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_posts_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_posts_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_posts_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "corp_feed_posts_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_feed_posts_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "corp_feed_posts_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "corp_feed_posts_quality_document_id_fkey"
            columns: ["quality_document_id"]
            isOneToOne: false
            referencedRelation: "quality_documents"
            referencedColumns: ["id"]
          },
        ]
      }
      corp_group_discussion_posts: {
        Row: {
          author_id: string
          content: string
          created_at: string
          discussion_id: string
          id: string
        }
        Insert: {
          author_id: string
          content: string
          created_at?: string
          discussion_id: string
          id?: string
        }
        Update: {
          author_id?: string
          content?: string
          created_at?: string
          discussion_id?: string
          id?: string
        }
        Relationships: [
          {
            foreignKeyName: "corp_group_discussion_posts_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_group_discussion_posts_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_group_discussion_posts_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_group_discussion_posts_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "corp_group_discussion_posts_discussion_id_fkey"
            columns: ["discussion_id"]
            isOneToOne: false
            referencedRelation: "corp_group_discussions"
            referencedColumns: ["id"]
          },
        ]
      }
      corp_group_discussions: {
        Row: {
          author_id: string
          content: string | null
          created_at: string
          group_id: string
          id: string
          pinned: boolean
          title: string
          updated_at: string
        }
        Insert: {
          author_id: string
          content?: string | null
          created_at?: string
          group_id: string
          id?: string
          pinned?: boolean
          title: string
          updated_at?: string
        }
        Update: {
          author_id?: string
          content?: string | null
          created_at?: string
          group_id?: string
          id?: string
          pinned?: boolean
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "corp_group_discussions_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_group_discussions_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_group_discussions_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_group_discussions_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "corp_group_discussions_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "corp_groups"
            referencedColumns: ["id"]
          },
        ]
      }
      corp_group_join_requests: {
        Row: {
          group_id: string
          id: string
          requested_at: string
          reviewed_at: string | null
          reviewed_by: string | null
          status: string
          user_id: string
        }
        Insert: {
          group_id: string
          id?: string
          requested_at?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          user_id: string
        }
        Update: {
          group_id?: string
          id?: string
          requested_at?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "corp_group_join_requests_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "corp_groups"
            referencedColumns: ["id"]
          },
        ]
      }
      corp_group_members: {
        Row: {
          group_id: string
          id: string
          joined_at: string
          user_id: string
        }
        Insert: {
          group_id: string
          id?: string
          joined_at?: string
          user_id: string
        }
        Update: {
          group_id?: string
          id?: string
          joined_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "corp_group_members_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "corp_groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_group_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_group_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_group_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_group_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      corp_groups: {
        Row: {
          admin_user_id: string | null
          avatar_url: string | null
          company_id: string
          created_at: string
          created_by: string | null
          description: string | null
          group_type: string
          id: string
          name: string
          role_slug: string | null
        }
        Insert: {
          admin_user_id?: string | null
          avatar_url?: string | null
          company_id: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          group_type?: string
          id?: string
          name: string
          role_slug?: string | null
        }
        Update: {
          admin_user_id?: string | null
          avatar_url?: string | null
          company_id?: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          group_type?: string
          id?: string
          name?: string
          role_slug?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "corp_groups_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_groups_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "corp_groups_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "corp_groups_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_groups_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_groups_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_groups_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      corp_kudos: {
        Row: {
          category: string
          company_id: string
          created_at: string
          from_user_id: string
          id: string
          message: string | null
          to_user_id: string
        }
        Insert: {
          category?: string
          company_id: string
          created_at?: string
          from_user_id: string
          id?: string
          message?: string | null
          to_user_id: string
        }
        Update: {
          category?: string
          company_id?: string
          created_at?: string
          from_user_id?: string
          id?: string
          message?: string | null
          to_user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "corp_kudos_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_kudos_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "corp_kudos_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "corp_kudos_from_user_id_fkey"
            columns: ["from_user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_kudos_from_user_id_fkey"
            columns: ["from_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_kudos_from_user_id_fkey"
            columns: ["from_user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_kudos_from_user_id_fkey"
            columns: ["from_user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "corp_kudos_to_user_id_fkey"
            columns: ["to_user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_kudos_to_user_id_fkey"
            columns: ["to_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_kudos_to_user_id_fkey"
            columns: ["to_user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_kudos_to_user_id_fkey"
            columns: ["to_user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      corp_request_attachments: {
        Row: {
          created_at: string
          file_name: string
          file_size: number | null
          file_url: string
          id: string
          request_id: string
          uploaded_by: string | null
        }
        Insert: {
          created_at?: string
          file_name: string
          file_size?: number | null
          file_url: string
          id?: string
          request_id: string
          uploaded_by?: string | null
        }
        Update: {
          created_at?: string
          file_name?: string
          file_size?: number | null
          file_url?: string
          id?: string
          request_id?: string
          uploaded_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "corp_request_attachments_request_id_fkey"
            columns: ["request_id"]
            isOneToOne: false
            referencedRelation: "corp_requests"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_request_attachments_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_request_attachments_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_request_attachments_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_request_attachments_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      corp_request_types: {
        Row: {
          active: boolean
          category: string
          company_id: string
          created_at: string
          department_id: string | null
          director_threshold_value: number | null
          dynamic_fields: Json | null
          id: string
          name: string
          requires_approval: boolean
          requires_director_approval: boolean
          updated_at: string
        }
        Insert: {
          active?: boolean
          category?: string
          company_id: string
          created_at?: string
          department_id?: string | null
          director_threshold_value?: number | null
          dynamic_fields?: Json | null
          id?: string
          name: string
          requires_approval?: boolean
          requires_director_approval?: boolean
          updated_at?: string
        }
        Update: {
          active?: boolean
          category?: string
          company_id?: string
          created_at?: string
          department_id?: string | null
          director_threshold_value?: number | null
          dynamic_fields?: Json | null
          id?: string
          name?: string
          requires_approval?: boolean
          requires_director_approval?: boolean
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "corp_request_types_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_request_types_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "corp_request_types_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "corp_request_types_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
        ]
      }
      corp_requests: {
        Row: {
          amount: number | null
          approved_amount: number | null
          company_id: string
          created_at: string
          department_id: string | null
          description: string | null
          director_approved_at: string | null
          director_approver_id: string | null
          dynamic_data: Json | null
          id: string
          manager_approved_at: string | null
          manager_approver_id: string | null
          priority: string
          rejection_reason: string | null
          requester_id: string
          status: string
          target_user_id: string | null
          title: string
          type_id: string | null
          updated_at: string
        }
        Insert: {
          amount?: number | null
          approved_amount?: number | null
          company_id: string
          created_at?: string
          department_id?: string | null
          description?: string | null
          director_approved_at?: string | null
          director_approver_id?: string | null
          dynamic_data?: Json | null
          id?: string
          manager_approved_at?: string | null
          manager_approver_id?: string | null
          priority?: string
          rejection_reason?: string | null
          requester_id: string
          status?: string
          target_user_id?: string | null
          title: string
          type_id?: string | null
          updated_at?: string
        }
        Update: {
          amount?: number | null
          approved_amount?: number | null
          company_id?: string
          created_at?: string
          department_id?: string | null
          description?: string | null
          director_approved_at?: string | null
          director_approver_id?: string | null
          dynamic_data?: Json | null
          id?: string
          manager_approved_at?: string | null
          manager_approver_id?: string | null
          priority?: string
          rejection_reason?: string | null
          requester_id?: string
          status?: string
          target_user_id?: string | null
          title?: string
          type_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "corp_requests_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_requests_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "corp_requests_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "corp_requests_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_requests_director_approver_id_fkey"
            columns: ["director_approver_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_requests_director_approver_id_fkey"
            columns: ["director_approver_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_requests_director_approver_id_fkey"
            columns: ["director_approver_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_requests_director_approver_id_fkey"
            columns: ["director_approver_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "corp_requests_manager_approver_id_fkey"
            columns: ["manager_approver_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_requests_manager_approver_id_fkey"
            columns: ["manager_approver_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_requests_manager_approver_id_fkey"
            columns: ["manager_approver_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_requests_manager_approver_id_fkey"
            columns: ["manager_approver_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "corp_requests_requester_id_fkey"
            columns: ["requester_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_requests_requester_id_fkey"
            columns: ["requester_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_requests_requester_id_fkey"
            columns: ["requester_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_requests_requester_id_fkey"
            columns: ["requester_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "corp_requests_target_user_id_fkey"
            columns: ["target_user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_requests_target_user_id_fkey"
            columns: ["target_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_requests_target_user_id_fkey"
            columns: ["target_user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "corp_requests_target_user_id_fkey"
            columns: ["target_user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "corp_requests_type_id_fkey"
            columns: ["type_id"]
            isOneToOne: false
            referencedRelation: "corp_request_types"
            referencedColumns: ["id"]
          },
        ]
      }
      crm_buyers: {
        Row: {
          client_id: string
          company_id: string
          created_at: string
          email: string | null
          id: string
          influence_level: string | null
          is_active: boolean | null
          is_primary: boolean | null
          name: string
          notes: string | null
          phone: string | null
          role: string | null
          updated_at: string
        }
        Insert: {
          client_id: string
          company_id: string
          created_at?: string
          email?: string | null
          id?: string
          influence_level?: string | null
          is_active?: boolean | null
          is_primary?: boolean | null
          name: string
          notes?: string | null
          phone?: string | null
          role?: string | null
          updated_at?: string
        }
        Update: {
          client_id?: string
          company_id?: string
          created_at?: string
          email?: string | null
          id?: string
          influence_level?: string | null
          is_active?: boolean | null
          is_primary?: boolean | null
          name?: string
          notes?: string | null
          phone?: string | null
          role?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "crm_buyers_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_buyers_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_buyers_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_buyers_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      crm_client_recurrences: {
        Row: {
          advance_notice_days: number | null
          assigned_to: string | null
          client_id: string
          company_id: string
          created_at: string
          estimated_value: number | null
          id: string
          last_executed_date: string | null
          next_date: string
          notes: string | null
          periodicity: string
          product_id: string | null
          recurrence_type: string | null
          status: string
          template_id: string | null
          updated_at: string
        }
        Insert: {
          advance_notice_days?: number | null
          assigned_to?: string | null
          client_id: string
          company_id: string
          created_at?: string
          estimated_value?: number | null
          id?: string
          last_executed_date?: string | null
          next_date: string
          notes?: string | null
          periodicity?: string
          product_id?: string | null
          recurrence_type?: string | null
          status?: string
          template_id?: string | null
          updated_at?: string
        }
        Update: {
          advance_notice_days?: number | null
          assigned_to?: string | null
          client_id?: string
          company_id?: string
          created_at?: string
          estimated_value?: number | null
          id?: string
          last_executed_date?: string | null
          next_date?: string
          notes?: string | null
          periodicity?: string
          product_id?: string | null
          recurrence_type?: string | null
          status?: string
          template_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "crm_client_recurrences_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_client_recurrences_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_client_recurrences_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_client_recurrences_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "crm_client_recurrences_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_client_recurrences_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_client_recurrences_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_client_recurrences_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_client_recurrences_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "crm_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_client_recurrences_template_id_fkey"
            columns: ["template_id"]
            isOneToOne: false
            referencedRelation: "crm_recurrence_templates"
            referencedColumns: ["id"]
          },
        ]
      }
      crm_integration_logs: {
        Row: {
          action: string
          company_id: string
          created_at: string
          details: Json | null
          entity_id: string | null
          entity_type: string | null
          error_message: string | null
          id: string
          status: string
          user_id: string | null
        }
        Insert: {
          action: string
          company_id: string
          created_at?: string
          details?: Json | null
          entity_id?: string | null
          entity_type?: string | null
          error_message?: string | null
          id?: string
          status?: string
          user_id?: string | null
        }
        Update: {
          action?: string
          company_id?: string
          created_at?: string
          details?: Json | null
          entity_id?: string | null
          entity_type?: string | null
          error_message?: string | null
          id?: string
          status?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "crm_integration_logs_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_integration_logs_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_integration_logs_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_integration_logs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_integration_logs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_integration_logs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_integration_logs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      crm_knowledge_base: {
        Row: {
          author_id: string | null
          category: string | null
          company_id: string
          content: string
          created_at: string
          id: string
          notes: string | null
          priority: string | null
          product_id: string | null
          published: boolean | null
          tags: string[] | null
          target_segment: string | null
          title: string
          updated_at: string
          version: string | null
        }
        Insert: {
          author_id?: string | null
          category?: string | null
          company_id: string
          content: string
          created_at?: string
          id?: string
          notes?: string | null
          priority?: string | null
          product_id?: string | null
          published?: boolean | null
          tags?: string[] | null
          target_segment?: string | null
          title: string
          updated_at?: string
          version?: string | null
        }
        Update: {
          author_id?: string | null
          category?: string | null
          company_id?: string
          content?: string
          created_at?: string
          id?: string
          notes?: string | null
          priority?: string | null
          product_id?: string | null
          published?: boolean | null
          tags?: string[] | null
          target_segment?: string | null
          title?: string
          updated_at?: string
          version?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "crm_knowledge_base_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_knowledge_base_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_knowledge_base_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_knowledge_base_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "crm_knowledge_base_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_knowledge_base_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_knowledge_base_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_knowledge_base_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "crm_products"
            referencedColumns: ["id"]
          },
        ]
      }
      crm_opportunities: {
        Row: {
          assigned_to: string | null
          buyer_id: string | null
          client_id: string
          closed_at: string | null
          company_id: string
          created_at: string
          created_by: string | null
          description: string | null
          estimated_value: number | null
          expected_close_date: string | null
          id: string
          loss_reason: string | null
          notes: string | null
          opportunity_type: string | null
          priority: string | null
          probability: number | null
          segment: string
          service_order_id: string | null
          stage: string
          title: string
          updated_at: string
        }
        Insert: {
          assigned_to?: string | null
          buyer_id?: string | null
          client_id: string
          closed_at?: string | null
          company_id: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          estimated_value?: number | null
          expected_close_date?: string | null
          id?: string
          loss_reason?: string | null
          notes?: string | null
          opportunity_type?: string | null
          priority?: string | null
          probability?: number | null
          segment?: string
          service_order_id?: string | null
          stage?: string
          title: string
          updated_at?: string
        }
        Update: {
          assigned_to?: string | null
          buyer_id?: string | null
          client_id?: string
          closed_at?: string | null
          company_id?: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          estimated_value?: number | null
          expected_close_date?: string | null
          id?: string
          loss_reason?: string | null
          notes?: string | null
          opportunity_type?: string | null
          priority?: string | null
          probability?: number | null
          segment?: string
          service_order_id?: string | null
          stage?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "crm_opportunities_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunities_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunities_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunities_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "crm_opportunities_buyer_id_fkey"
            columns: ["buyer_id"]
            isOneToOne: false
            referencedRelation: "crm_buyers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunities_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunities_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunities_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_opportunities_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_opportunities_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunities_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunities_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunities_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "crm_opportunities_service_order_id_fkey"
            columns: ["service_order_id"]
            isOneToOne: false
            referencedRelation: "service_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      crm_opportunity_activities: {
        Row: {
          activity_date: string
          activity_type: string
          created_at: string
          description: string | null
          id: string
          opportunity_id: string
          user_id: string | null
        }
        Insert: {
          activity_date?: string
          activity_type: string
          created_at?: string
          description?: string | null
          id?: string
          opportunity_id: string
          user_id?: string | null
        }
        Update: {
          activity_date?: string
          activity_type?: string
          created_at?: string
          description?: string | null
          id?: string
          opportunity_id?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "crm_opportunity_activities_opportunity_id_fkey"
            columns: ["opportunity_id"]
            isOneToOne: false
            referencedRelation: "crm_opportunities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunity_activities_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunity_activities_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunity_activities_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunity_activities_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      crm_opportunity_products: {
        Row: {
          created_at: string
          id: string
          opportunity_id: string
          product_id: string
          quantity: number
          total_value: number | null
          unit_value: number | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          opportunity_id: string
          product_id: string
          quantity?: number
          total_value?: number | null
          unit_value?: number | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          opportunity_id?: string
          product_id?: string
          quantity?: number
          total_value?: number | null
          unit_value?: number | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "crm_opportunity_products_opportunity_id_fkey"
            columns: ["opportunity_id"]
            isOneToOne: false
            referencedRelation: "crm_opportunities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunity_products_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "crm_products"
            referencedColumns: ["id"]
          },
        ]
      }
      crm_opportunity_transfers: {
        Row: {
          company_id: string
          created_at: string
          decided_at: string | null
          decided_by: string | null
          decision_note: string | null
          from_user_id: string
          id: string
          opportunity_id: string
          reason: string | null
          status: string
          to_user_id: string
          updated_at: string
        }
        Insert: {
          company_id: string
          created_at?: string
          decided_at?: string | null
          decided_by?: string | null
          decision_note?: string | null
          from_user_id: string
          id?: string
          opportunity_id: string
          reason?: string | null
          status?: string
          to_user_id: string
          updated_at?: string
        }
        Update: {
          company_id?: string
          created_at?: string
          decided_at?: string | null
          decided_by?: string | null
          decision_note?: string | null
          from_user_id?: string
          id?: string
          opportunity_id?: string
          reason?: string | null
          status?: string
          to_user_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "crm_opportunity_transfers_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunity_transfers_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_opportunity_transfers_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_opportunity_transfers_decided_by_fkey"
            columns: ["decided_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunity_transfers_decided_by_fkey"
            columns: ["decided_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunity_transfers_decided_by_fkey"
            columns: ["decided_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunity_transfers_decided_by_fkey"
            columns: ["decided_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "crm_opportunity_transfers_from_user_id_fkey"
            columns: ["from_user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunity_transfers_from_user_id_fkey"
            columns: ["from_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunity_transfers_from_user_id_fkey"
            columns: ["from_user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunity_transfers_from_user_id_fkey"
            columns: ["from_user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "crm_opportunity_transfers_opportunity_id_fkey"
            columns: ["opportunity_id"]
            isOneToOne: false
            referencedRelation: "crm_opportunities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunity_transfers_to_user_id_fkey"
            columns: ["to_user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunity_transfers_to_user_id_fkey"
            columns: ["to_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunity_transfers_to_user_id_fkey"
            columns: ["to_user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_opportunity_transfers_to_user_id_fkey"
            columns: ["to_user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      crm_products: {
        Row: {
          active: boolean | null
          category: string | null
          company_id: string
          created_at: string
          description: string | null
          id: string
          is_recurring: boolean | null
          lead_time_days: number | null
          name: string
          reference_value: number | null
          type: string
          updated_at: string
        }
        Insert: {
          active?: boolean | null
          category?: string | null
          company_id: string
          created_at?: string
          description?: string | null
          id?: string
          is_recurring?: boolean | null
          lead_time_days?: number | null
          name: string
          reference_value?: number | null
          type?: string
          updated_at?: string
        }
        Update: {
          active?: boolean | null
          category?: string | null
          company_id?: string
          created_at?: string
          description?: string | null
          id?: string
          is_recurring?: boolean | null
          lead_time_days?: number | null
          name?: string
          reference_value?: number | null
          type?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "crm_products_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_products_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_products_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      crm_recurrence_templates: {
        Row: {
          active: boolean | null
          company_id: string
          created_at: string
          description: string | null
          id: string
          name: string
          notification_days_before: number | null
          period_type: string
          period_value: number
          product_id: string | null
          updated_at: string
        }
        Insert: {
          active?: boolean | null
          company_id: string
          created_at?: string
          description?: string | null
          id?: string
          name: string
          notification_days_before?: number | null
          period_type?: string
          period_value?: number
          product_id?: string | null
          updated_at?: string
        }
        Update: {
          active?: boolean | null
          company_id?: string
          created_at?: string
          description?: string | null
          id?: string
          name?: string
          notification_days_before?: number | null
          period_type?: string
          period_value?: number
          product_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "crm_recurrence_templates_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_recurrence_templates_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_recurrence_templates_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_recurrence_templates_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "crm_products"
            referencedColumns: ["id"]
          },
        ]
      }
      crm_reference_documents: {
        Row: {
          category: string | null
          company_id: string
          created_at: string
          file_name: string
          file_type: string | null
          file_url: string
          id: string
          knowledge_base_id: string | null
          updated_at: string
        }
        Insert: {
          category?: string | null
          company_id: string
          created_at?: string
          file_name: string
          file_type?: string | null
          file_url: string
          id?: string
          knowledge_base_id?: string | null
          updated_at?: string
        }
        Update: {
          category?: string | null
          company_id?: string
          created_at?: string
          file_name?: string
          file_type?: string | null
          file_url?: string
          id?: string
          knowledge_base_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "crm_reference_documents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_reference_documents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_reference_documents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_reference_documents_knowledge_base_id_fkey"
            columns: ["knowledge_base_id"]
            isOneToOne: false
            referencedRelation: "crm_knowledge_base"
            referencedColumns: ["id"]
          },
        ]
      }
      crm_sale_items: {
        Row: {
          created_at: string | null
          id: string
          markup_percentage: number | null
          name: string
          quantity: number
          sale_id: string
          stock_product_id: string | null
          total_value: number | null
          unit_value: number | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          markup_percentage?: number | null
          name: string
          quantity?: number
          sale_id: string
          stock_product_id?: string | null
          total_value?: number | null
          unit_value?: number | null
        }
        Update: {
          created_at?: string | null
          id?: string
          markup_percentage?: number | null
          name?: string
          quantity?: number
          sale_id?: string
          stock_product_id?: string | null
          total_value?: number | null
          unit_value?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "crm_sale_items_sale_id_fkey"
            columns: ["sale_id"]
            isOneToOne: false
            referencedRelation: "crm_sales"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_sale_items_stock_product_id_fkey"
            columns: ["stock_product_id"]
            isOneToOne: false
            referencedRelation: "stock_products"
            referencedColumns: ["id"]
          },
        ]
      }
      crm_sales: {
        Row: {
          client_id: string | null
          company_id: string
          created_at: string | null
          created_by: string | null
          id: string
          notes: string | null
          opportunity_id: string | null
          sale_number: string | null
          status: string | null
          total_amount: number | null
          updated_at: string | null
        }
        Insert: {
          client_id?: string | null
          company_id: string
          created_at?: string | null
          created_by?: string | null
          id?: string
          notes?: string | null
          opportunity_id?: string | null
          sale_number?: string | null
          status?: string | null
          total_amount?: number | null
          updated_at?: string | null
        }
        Update: {
          client_id?: string | null
          company_id?: string
          created_at?: string | null
          created_by?: string | null
          id?: string
          notes?: string | null
          opportunity_id?: string | null
          sale_number?: string | null
          status?: string | null
          total_amount?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "crm_sales_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_sales_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_sales_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_sales_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_sales_opportunity_id_fkey"
            columns: ["opportunity_id"]
            isOneToOne: false
            referencedRelation: "crm_opportunities"
            referencedColumns: ["id"]
          },
        ]
      }
      crm_tasks: {
        Row: {
          assigned_to: string | null
          client_id: string | null
          company_id: string
          created_at: string
          created_by: string | null
          description: string | null
          due_date: string | null
          id: string
          opportunity_id: string | null
          priority: string
          status: string
          title: string
          updated_at: string
        }
        Insert: {
          assigned_to?: string | null
          client_id?: string | null
          company_id: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          due_date?: string | null
          id?: string
          opportunity_id?: string | null
          priority?: string
          status?: string
          title: string
          updated_at?: string
        }
        Update: {
          assigned_to?: string | null
          client_id?: string | null
          company_id?: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          due_date?: string | null
          id?: string
          opportunity_id?: string | null
          priority?: string
          status?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "crm_tasks_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_tasks_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_tasks_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_tasks_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "crm_tasks_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_tasks_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_tasks_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_tasks_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "crm_tasks_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_tasks_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_tasks_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "crm_tasks_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "crm_tasks_opportunity_id_fkey"
            columns: ["opportunity_id"]
            isOneToOne: false
            referencedRelation: "crm_opportunities"
            referencedColumns: ["id"]
          },
        ]
      }
      department_members: {
        Row: {
          created_at: string
          department_id: string
          id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          department_id: string
          id?: string
          user_id: string
        }
        Update: {
          created_at?: string
          department_id?: string
          id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "department_members_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "department_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "department_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "department_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "department_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      departments: {
        Row: {
          active: boolean
          company_id: string
          created_at: string
          description: string | null
          id: string
          manager_id: string | null
          name: string
        }
        Insert: {
          active?: boolean
          company_id: string
          created_at?: string
          description?: string | null
          id?: string
          manager_id?: string | null
          name: string
        }
        Update: {
          active?: boolean
          company_id?: string
          created_at?: string
          description?: string | null
          id?: string
          manager_id?: string | null
          name?: string
        }
        Relationships: [
          {
            foreignKeyName: "departments_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "departments_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "departments_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "departments_manager_id_fkey"
            columns: ["manager_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "departments_manager_id_fkey"
            columns: ["manager_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "departments_manager_id_fkey"
            columns: ["manager_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "departments_manager_id_fkey"
            columns: ["manager_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      employee_notes: {
        Row: {
          author_id: string
          company_id: string
          content: string
          created_at: string | null
          employee_user_id: string
          id: string
          is_confidential: boolean | null
          note_type: string
          title: string
          updated_at: string | null
        }
        Insert: {
          author_id: string
          company_id: string
          content: string
          created_at?: string | null
          employee_user_id: string
          id?: string
          is_confidential?: boolean | null
          note_type?: string
          title: string
          updated_at?: string | null
        }
        Update: {
          author_id?: string
          company_id?: string
          content?: string
          created_at?: string | null
          employee_user_id?: string
          id?: string
          is_confidential?: boolean | null
          note_type?: string
          title?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "employee_notes_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "employee_notes_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "employee_notes_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      employee_onboarding: {
        Row: {
          access_token: string
          candidate_email: string | null
          candidate_name: string | null
          company_id: string
          completed_at: string | null
          created_at: string | null
          created_by: string
          id: string
          job_application_id: string | null
          notes: string | null
          position_tag: string | null
          started_at: string | null
          status: string
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          access_token?: string
          candidate_email?: string | null
          candidate_name?: string | null
          company_id: string
          completed_at?: string | null
          created_at?: string | null
          created_by: string
          id?: string
          job_application_id?: string | null
          notes?: string | null
          position_tag?: string | null
          started_at?: string | null
          status?: string
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          access_token?: string
          candidate_email?: string | null
          candidate_name?: string | null
          company_id?: string
          completed_at?: string | null
          created_at?: string | null
          created_by?: string
          id?: string
          job_application_id?: string | null
          notes?: string | null
          position_tag?: string | null
          started_at?: string | null
          status?: string
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "employee_onboarding_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "employee_onboarding_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "employee_onboarding_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "employee_onboarding_job_application_id_fkey"
            columns: ["job_application_id"]
            isOneToOne: false
            referencedRelation: "job_applications"
            referencedColumns: ["id"]
          },
        ]
      }
      epi_deliveries: {
        Row: {
          company_id: string
          created_at: string
          created_by: string | null
          delivered_at: string
          epi_item_id: string
          expires_at: string | null
          id: string
          notes: string | null
          quantity: number
          recipient_profile_id: string
          signature_url: string | null
          updated_at: string
        }
        Insert: {
          company_id: string
          created_at?: string
          created_by?: string | null
          delivered_at?: string
          epi_item_id: string
          expires_at?: string | null
          id?: string
          notes?: string | null
          quantity?: number
          recipient_profile_id: string
          signature_url?: string | null
          updated_at?: string
        }
        Update: {
          company_id?: string
          created_at?: string
          created_by?: string | null
          delivered_at?: string
          epi_item_id?: string
          expires_at?: string | null
          id?: string
          notes?: string | null
          quantity?: number
          recipient_profile_id?: string
          signature_url?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "epi_deliveries_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "epi_deliveries_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "epi_deliveries_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "epi_deliveries_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "epi_deliveries_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "epi_deliveries_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "epi_deliveries_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "epi_deliveries_epi_item_id_fkey"
            columns: ["epi_item_id"]
            isOneToOne: false
            referencedRelation: "epi_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "epi_deliveries_recipient_profile_id_fkey"
            columns: ["recipient_profile_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "epi_deliveries_recipient_profile_id_fkey"
            columns: ["recipient_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "epi_deliveries_recipient_profile_id_fkey"
            columns: ["recipient_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "epi_deliveries_recipient_profile_id_fkey"
            columns: ["recipient_profile_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      epi_items: {
        Row: {
          company_id: string
          created_at: string
          created_by: string | null
          current_stock: number
          description: string | null
          id: string
          is_active: boolean
          min_stock: number
          name: string
          size: string | null
          updated_at: string
        }
        Insert: {
          company_id: string
          created_at?: string
          created_by?: string | null
          current_stock?: number
          description?: string | null
          id?: string
          is_active?: boolean
          min_stock?: number
          name: string
          size?: string | null
          updated_at?: string
        }
        Update: {
          company_id?: string
          created_at?: string
          created_by?: string | null
          current_stock?: number
          description?: string | null
          id?: string
          is_active?: boolean
          min_stock?: number
          name?: string
          size?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "epi_items_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "epi_items_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "epi_items_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "epi_items_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "epi_items_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "epi_items_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "epi_items_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      epi_stock_movements: {
        Row: {
          company_id: string
          created_at: string
          created_by: string | null
          epi_item_id: string
          id: string
          movement_type: string
          notes: string | null
          quantity: number
        }
        Insert: {
          company_id: string
          created_at?: string
          created_by?: string | null
          epi_item_id: string
          id?: string
          movement_type: string
          notes?: string | null
          quantity: number
        }
        Update: {
          company_id?: string
          created_at?: string
          created_by?: string | null
          epi_item_id?: string
          id?: string
          movement_type?: string
          notes?: string | null
          quantity?: number
        }
        Relationships: [
          {
            foreignKeyName: "epi_stock_movements_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "epi_stock_movements_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "epi_stock_movements_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "epi_stock_movements_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "epi_stock_movements_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "epi_stock_movements_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "epi_stock_movements_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "epi_stock_movements_epi_item_id_fkey"
            columns: ["epi_item_id"]
            isOneToOne: false
            referencedRelation: "epi_items"
            referencedColumns: ["id"]
          },
        ]
      }
      finance_categories: {
        Row: {
          category_type: string
          company_id: string
          created_at: string
          id: string
          is_active: boolean | null
          name: string
          updated_at: string
        }
        Insert: {
          category_type: string
          company_id: string
          created_at?: string
          id?: string
          is_active?: boolean | null
          name: string
          updated_at?: string
        }
        Update: {
          category_type?: string
          company_id?: string
          created_at?: string
          id?: string
          is_active?: boolean | null
          name?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "finance_categories_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_categories_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "finance_categories_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      finance_payables: {
        Row: {
          amount: number
          approved_at: string | null
          approved_by: string | null
          category_id: string | null
          company_id: string
          created_at: string
          created_by: string | null
          description: string | null
          due_date: string
          id: string
          invoice_number: string | null
          notes: string | null
          paid_amount: number | null
          payment_date: string | null
          purchase_request_id: string | null
          status: string
          supplier_name: string
          updated_at: string
        }
        Insert: {
          amount: number
          approved_at?: string | null
          approved_by?: string | null
          category_id?: string | null
          company_id: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          due_date: string
          id?: string
          invoice_number?: string | null
          notes?: string | null
          paid_amount?: number | null
          payment_date?: string | null
          purchase_request_id?: string | null
          status?: string
          supplier_name: string
          updated_at?: string
        }
        Update: {
          amount?: number
          approved_at?: string | null
          approved_by?: string | null
          category_id?: string | null
          company_id?: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          due_date?: string
          id?: string
          invoice_number?: string | null
          notes?: string | null
          paid_amount?: number | null
          payment_date?: string | null
          purchase_request_id?: string | null
          status?: string
          supplier_name?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "finance_payables_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_payables_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_payables_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_payables_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "finance_payables_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "finance_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_payables_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_payables_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "finance_payables_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "finance_payables_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_payables_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_payables_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_payables_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "finance_payables_purchase_request_id_fkey"
            columns: ["purchase_request_id"]
            isOneToOne: false
            referencedRelation: "purchase_requests"
            referencedColumns: ["id"]
          },
        ]
      }
      finance_receivables: {
        Row: {
          amount: number
          category_id: string | null
          client_id: string | null
          client_name: string
          company_id: string
          created_at: string
          created_by: string | null
          description: string | null
          due_date: string
          id: string
          invoice_number: string | null
          measurement_id: string | null
          notes: string | null
          received_amount: number | null
          received_date: string | null
          status: string
          updated_at: string
        }
        Insert: {
          amount: number
          category_id?: string | null
          client_id?: string | null
          client_name: string
          company_id: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          due_date: string
          id?: string
          invoice_number?: string | null
          measurement_id?: string | null
          notes?: string | null
          received_amount?: number | null
          received_date?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          amount?: number
          category_id?: string | null
          client_id?: string | null
          client_name?: string
          company_id?: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          due_date?: string
          id?: string
          invoice_number?: string | null
          measurement_id?: string | null
          notes?: string | null
          received_amount?: number | null
          received_date?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "finance_receivables_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "finance_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_receivables_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_receivables_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_receivables_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "finance_receivables_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "finance_receivables_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_receivables_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_receivables_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_receivables_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      finance_reimbursement_attachments: {
        Row: {
          created_at: string
          file_name: string
          file_size: number | null
          file_url: string
          id: string
          reimbursement_id: string
          uploaded_by: string | null
        }
        Insert: {
          created_at?: string
          file_name: string
          file_size?: number | null
          file_url: string
          id?: string
          reimbursement_id: string
          uploaded_by?: string | null
        }
        Update: {
          created_at?: string
          file_name?: string
          file_size?: number | null
          file_url?: string
          id?: string
          reimbursement_id?: string
          uploaded_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "finance_reimbursement_attachments_reimbursement_id_fkey"
            columns: ["reimbursement_id"]
            isOneToOne: false
            referencedRelation: "finance_reimbursements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_reimbursement_attachments_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_reimbursement_attachments_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_reimbursement_attachments_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_reimbursement_attachments_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      finance_reimbursements: {
        Row: {
          amount: number
          approved_at: string | null
          approved_by: string | null
          category_id: string | null
          company_id: string
          created_at: string
          description: string
          expense_date: string
          id: string
          notes: string | null
          paid_at: string | null
          rejection_reason: string | null
          requester_id: string
          status: string
          updated_at: string
        }
        Insert: {
          amount: number
          approved_at?: string | null
          approved_by?: string | null
          category_id?: string | null
          company_id: string
          created_at?: string
          description: string
          expense_date: string
          id?: string
          notes?: string | null
          paid_at?: string | null
          rejection_reason?: string | null
          requester_id: string
          status?: string
          updated_at?: string
        }
        Update: {
          amount?: number
          approved_at?: string | null
          approved_by?: string | null
          category_id?: string | null
          company_id?: string
          created_at?: string
          description?: string
          expense_date?: string
          id?: string
          notes?: string | null
          paid_at?: string | null
          rejection_reason?: string | null
          requester_id?: string
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "finance_reimbursements_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_reimbursements_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_reimbursements_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_reimbursements_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "finance_reimbursements_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "finance_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_reimbursements_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_reimbursements_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "finance_reimbursements_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "finance_reimbursements_requester_id_fkey"
            columns: ["requester_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_reimbursements_requester_id_fkey"
            columns: ["requester_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_reimbursements_requester_id_fkey"
            columns: ["requester_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_reimbursements_requester_id_fkey"
            columns: ["requester_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      finance_transactions: {
        Row: {
          amount: number
          category_id: string | null
          company_id: string
          created_at: string
          created_by: string | null
          description: string
          id: string
          notes: string | null
          reference_id: string | null
          reference_type: string | null
          transaction_date: string
          transaction_type: string
          updated_at: string
        }
        Insert: {
          amount: number
          category_id?: string | null
          company_id: string
          created_at?: string
          created_by?: string | null
          description: string
          id?: string
          notes?: string | null
          reference_id?: string | null
          reference_type?: string | null
          transaction_date: string
          transaction_type: string
          updated_at?: string
        }
        Update: {
          amount?: number
          category_id?: string | null
          company_id?: string
          created_at?: string
          created_by?: string | null
          description?: string
          id?: string
          notes?: string | null
          reference_id?: string | null
          reference_type?: string | null
          transaction_date?: string
          transaction_type?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "finance_transactions_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "finance_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_transactions_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_transactions_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "finance_transactions_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "finance_transactions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_transactions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_transactions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_transactions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      forecast_history: {
        Row: {
          actual_completed: number | null
          actual_orders: number | null
          client_id: string | null
          company_id: string
          confidence: string
          coordinator_id: string | null
          created_at: string
          created_by: string
          forecast_month: string
          id: string
          metadata: Json | null
          predicted_completed: number
          predicted_orders: number
        }
        Insert: {
          actual_completed?: number | null
          actual_orders?: number | null
          client_id?: string | null
          company_id: string
          confidence: string
          coordinator_id?: string | null
          created_at?: string
          created_by: string
          forecast_month: string
          id?: string
          metadata?: Json | null
          predicted_completed: number
          predicted_orders: number
        }
        Update: {
          actual_completed?: number | null
          actual_orders?: number | null
          client_id?: string | null
          company_id?: string
          confidence?: string
          coordinator_id?: string | null
          created_at?: string
          created_by?: string
          forecast_month?: string
          id?: string
          metadata?: Json | null
          predicted_completed?: number
          predicted_orders?: number
        }
        Relationships: [
          {
            foreignKeyName: "forecast_history_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "forecast_history_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "forecast_history_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "forecast_history_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "forecast_history_coordinator_id_fkey"
            columns: ["coordinator_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "forecast_history_coordinator_id_fkey"
            columns: ["coordinator_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "forecast_history_coordinator_id_fkey"
            columns: ["coordinator_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "forecast_history_coordinator_id_fkey"
            columns: ["coordinator_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "forecast_history_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "forecast_history_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "forecast_history_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "forecast_history_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      home_office_schedules: {
        Row: {
          company_id: string
          created_at: string
          created_by: string | null
          end_date: string
          id: string
          notes: string | null
          start_date: string
          technician_id: string
          updated_at: string
        }
        Insert: {
          company_id: string
          created_at?: string
          created_by?: string | null
          end_date: string
          id?: string
          notes?: string | null
          start_date: string
          technician_id: string
          updated_at?: string
        }
        Update: {
          company_id?: string
          created_at?: string
          created_by?: string | null
          end_date?: string
          id?: string
          notes?: string | null
          start_date?: string
          technician_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "home_office_schedules_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "home_office_schedules_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians_public"
            referencedColumns: ["id"]
          },
        ]
      }
      hr_partnerships: {
        Row: {
          benefit: string | null
          category: string | null
          company_id: string
          contact: string | null
          created_at: string
          created_by: string | null
          description: string | null
          id: string
          is_active: boolean
          link: string | null
          logo_url: string | null
          name: string
          updated_at: string
          valid_from: string | null
          valid_until: string | null
        }
        Insert: {
          benefit?: string | null
          category?: string | null
          company_id: string
          contact?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          is_active?: boolean
          link?: string | null
          logo_url?: string | null
          name: string
          updated_at?: string
          valid_from?: string | null
          valid_until?: string | null
        }
        Update: {
          benefit?: string | null
          category?: string | null
          company_id?: string
          contact?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          is_active?: boolean
          link?: string | null
          logo_url?: string | null
          name?: string
          updated_at?: string
          valid_from?: string | null
          valid_until?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "hr_partnerships_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hr_partnerships_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "hr_partnerships_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "hr_partnerships_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hr_partnerships_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hr_partnerships_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hr_partnerships_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      hr_time_adjustments: {
        Row: {
          adjusted_by: string | null
          adjusted_check_in: string | null
          adjusted_check_out: string | null
          adjustment_date: string
          adjustment_reason: string
          company_id: string
          created_at: string | null
          id: string
          original_check_in: string | null
          original_check_out: string | null
          technician_id: string | null
        }
        Insert: {
          adjusted_by?: string | null
          adjusted_check_in?: string | null
          adjusted_check_out?: string | null
          adjustment_date: string
          adjustment_reason: string
          company_id: string
          created_at?: string | null
          id?: string
          original_check_in?: string | null
          original_check_out?: string | null
          technician_id?: string | null
        }
        Update: {
          adjusted_by?: string | null
          adjusted_check_in?: string | null
          adjusted_check_out?: string | null
          adjustment_date?: string
          adjustment_reason?: string
          company_id?: string
          created_at?: string | null
          id?: string
          original_check_in?: string | null
          original_check_out?: string | null
          technician_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "hr_time_adjustments_adjusted_by_fkey"
            columns: ["adjusted_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hr_time_adjustments_adjusted_by_fkey"
            columns: ["adjusted_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hr_time_adjustments_adjusted_by_fkey"
            columns: ["adjusted_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hr_time_adjustments_adjusted_by_fkey"
            columns: ["adjusted_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "hr_time_adjustments_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hr_time_adjustments_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "hr_time_adjustments_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "hr_time_adjustments_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hr_time_adjustments_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians_public"
            referencedColumns: ["id"]
          },
        ]
      }
      job_application_notes: {
        Row: {
          application_id: string
          author_id: string
          created_at: string
          id: string
          note: string
        }
        Insert: {
          application_id: string
          author_id: string
          created_at?: string
          id?: string
          note: string
        }
        Update: {
          application_id?: string
          author_id?: string
          created_at?: string
          id?: string
          note?: string
        }
        Relationships: [
          {
            foreignKeyName: "job_application_notes_application_id_fkey"
            columns: ["application_id"]
            isOneToOne: false
            referencedRelation: "job_applications"
            referencedColumns: ["id"]
          },
        ]
      }
      job_application_tag_assignments: {
        Row: {
          application_id: string
          assigned_at: string
          assigned_by: string | null
          id: string
          tag_id: string
        }
        Insert: {
          application_id: string
          assigned_at?: string
          assigned_by?: string | null
          id?: string
          tag_id: string
        }
        Update: {
          application_id?: string
          assigned_at?: string
          assigned_by?: string | null
          id?: string
          tag_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "job_application_tag_assignments_application_id_fkey"
            columns: ["application_id"]
            isOneToOne: false
            referencedRelation: "job_applications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "job_application_tag_assignments_tag_id_fkey"
            columns: ["tag_id"]
            isOneToOne: false
            referencedRelation: "job_application_tags"
            referencedColumns: ["id"]
          },
        ]
      }
      job_application_tags: {
        Row: {
          color: string
          company_id: string
          created_at: string
          created_by: string | null
          id: string
          name: string
        }
        Insert: {
          color?: string
          company_id: string
          created_at?: string
          created_by?: string | null
          id?: string
          name: string
        }
        Update: {
          color?: string
          company_id?: string
          created_at?: string
          created_by?: string | null
          id?: string
          name?: string
        }
        Relationships: []
      }
      job_applications: {
        Row: {
          area_of_interest: string | null
          availability: string | null
          city: string | null
          company_id: string
          cover_letter: string | null
          created_at: string
          cv_extracted_data: Json | null
          cv_file_name: string | null
          cv_file_url: string | null
          email: string
          full_name: string
          id: string
          ip: string | null
          job_opening_id: string | null
          linkedin_url: string | null
          phone: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          salary_expectation: number | null
          source: string
          state: string | null
          status: string
          updated_at: string
          user_agent: string | null
        }
        Insert: {
          area_of_interest?: string | null
          availability?: string | null
          city?: string | null
          company_id: string
          cover_letter?: string | null
          created_at?: string
          cv_extracted_data?: Json | null
          cv_file_name?: string | null
          cv_file_url?: string | null
          email: string
          full_name: string
          id?: string
          ip?: string | null
          job_opening_id?: string | null
          linkedin_url?: string | null
          phone?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          salary_expectation?: number | null
          source?: string
          state?: string | null
          status?: string
          updated_at?: string
          user_agent?: string | null
        }
        Update: {
          area_of_interest?: string | null
          availability?: string | null
          city?: string | null
          company_id?: string
          cover_letter?: string | null
          created_at?: string
          cv_extracted_data?: Json | null
          cv_file_name?: string | null
          cv_file_url?: string | null
          email?: string
          full_name?: string
          id?: string
          ip?: string | null
          job_opening_id?: string | null
          linkedin_url?: string | null
          phone?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          salary_expectation?: number | null
          source?: string
          state?: string | null
          status?: string
          updated_at?: string
          user_agent?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "job_applications_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "job_applications_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "job_applications_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "job_applications_job_opening_id_fkey"
            columns: ["job_opening_id"]
            isOneToOne: false
            referencedRelation: "job_openings"
            referencedColumns: ["id"]
          },
        ]
      }
      job_openings: {
        Row: {
          area: string | null
          company_id: string
          created_at: string
          created_by: string | null
          description: string | null
          employment_type: string | null
          id: string
          is_active: boolean
          location: string | null
          title: string
          updated_at: string
        }
        Insert: {
          area?: string | null
          company_id: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          employment_type?: string | null
          id?: string
          is_active?: boolean
          location?: string | null
          title: string
          updated_at?: string
        }
        Update: {
          area?: string | null
          company_id?: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          employment_type?: string | null
          id?: string
          is_active?: boolean
          location?: string | null
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "job_openings_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "job_openings_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "job_openings_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      measurement_expenses: {
        Row: {
          admin_fee_amount: number
          admin_fee_percentage: number | null
          base_value: number
          created_at: string | null
          description: string | null
          expense_type: Database["public"]["Enums"]["expense_type"]
          id: string
          measurement_id: string
          total_value: number
          updated_at: string | null
        }
        Insert: {
          admin_fee_amount: number
          admin_fee_percentage?: number | null
          base_value: number
          created_at?: string | null
          description?: string | null
          expense_type: Database["public"]["Enums"]["expense_type"]
          id?: string
          measurement_id: string
          total_value: number
          updated_at?: string | null
        }
        Update: {
          admin_fee_amount?: number
          admin_fee_percentage?: number | null
          base_value?: number
          created_at?: string | null
          description?: string | null
          expense_type?: Database["public"]["Enums"]["expense_type"]
          id?: string
          measurement_id?: string
          total_value?: number
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "measurement_expenses_measurement_id_fkey"
            columns: ["measurement_id"]
            isOneToOne: false
            referencedRelation: "measurements"
            referencedColumns: ["id"]
          },
        ]
      }
      measurement_man_hours: {
        Row: {
          created_at: string | null
          end_time: string
          entry_date: string
          hour_type: Database["public"]["Enums"]["time_entry_type"]
          hourly_rate: number
          id: string
          measurement_id: string
          start_time: string
          technician_id: string | null
          technician_name: string
          technician_role: Database["public"]["Enums"]["technician_role"]
          total_hours: number
          total_value: number
          updated_at: string | null
          work_type: Database["public"]["Enums"]["work_type"]
        }
        Insert: {
          created_at?: string | null
          end_time: string
          entry_date: string
          hour_type: Database["public"]["Enums"]["time_entry_type"]
          hourly_rate: number
          id?: string
          measurement_id: string
          start_time: string
          technician_id?: string | null
          technician_name: string
          technician_role: Database["public"]["Enums"]["technician_role"]
          total_hours: number
          total_value: number
          updated_at?: string | null
          work_type: Database["public"]["Enums"]["work_type"]
        }
        Update: {
          created_at?: string | null
          end_time?: string
          entry_date?: string
          hour_type?: Database["public"]["Enums"]["time_entry_type"]
          hourly_rate?: number
          id?: string
          measurement_id?: string
          start_time?: string
          technician_id?: string | null
          technician_name?: string
          technician_role?: Database["public"]["Enums"]["technician_role"]
          total_hours?: number
          total_value?: number
          updated_at?: string | null
          work_type?: Database["public"]["Enums"]["work_type"]
        }
        Relationships: [
          {
            foreignKeyName: "measurement_man_hours_measurement_id_fkey"
            columns: ["measurement_id"]
            isOneToOne: false
            referencedRelation: "measurements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "measurement_man_hours_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "measurement_man_hours_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians_public"
            referencedColumns: ["id"]
          },
        ]
      }
      measurement_materials: {
        Row: {
          created_at: string | null
          external_product_code: string | null
          external_product_id: number | null
          id: string
          markup_percentage: number | null
          measurement_id: string
          name: string
          quantity: number
          source: string | null
          stock_item_id: string | null
          total_value: number
          unit_value: number
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          external_product_code?: string | null
          external_product_id?: number | null
          id?: string
          markup_percentage?: number | null
          measurement_id: string
          name: string
          quantity: number
          source?: string | null
          stock_item_id?: string | null
          total_value: number
          unit_value: number
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          external_product_code?: string | null
          external_product_id?: number | null
          id?: string
          markup_percentage?: number | null
          measurement_id?: string
          name?: string
          quantity?: number
          source?: string | null
          stock_item_id?: string | null
          total_value?: number
          unit_value?: number
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "measurement_materials_measurement_id_fkey"
            columns: ["measurement_id"]
            isOneToOne: false
            referencedRelation: "measurements"
            referencedColumns: ["id"]
          },
        ]
      }
      measurement_services: {
        Row: {
          created_at: string | null
          description: string | null
          id: string
          measurement_id: string
          name: string
          updated_at: string | null
          value: number
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          id?: string
          measurement_id: string
          name: string
          updated_at?: string | null
          value: number
        }
        Update: {
          created_at?: string | null
          description?: string | null
          id?: string
          measurement_id?: string
          name?: string
          updated_at?: string | null
          value?: number
        }
        Relationships: [
          {
            foreignKeyName: "measurement_services_measurement_id_fkey"
            columns: ["measurement_id"]
            isOneToOne: false
            referencedRelation: "measurements"
            referencedColumns: ["id"]
          },
        ]
      }
      measurement_settings: {
        Row: {
          company_id: string
          created_at: string | null
          default_material_markup: number | null
          expense_admin_fee: number | null
          id: string
          km_rate: number | null
          tax_cativo: number | null
          tax_externo: number | null
          tax_isento: number | null
          tax_laboratorio: number | null
          updated_at: string | null
        }
        Insert: {
          company_id: string
          created_at?: string | null
          default_material_markup?: number | null
          expense_admin_fee?: number | null
          id?: string
          km_rate?: number | null
          tax_cativo?: number | null
          tax_externo?: number | null
          tax_isento?: number | null
          tax_laboratorio?: number | null
          updated_at?: string | null
        }
        Update: {
          company_id?: string
          created_at?: string | null
          default_material_markup?: number | null
          expense_admin_fee?: number | null
          id?: string
          km_rate?: number | null
          tax_cativo?: number | null
          tax_externo?: number | null
          tax_isento?: number | null
          tax_laboratorio?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "measurement_settings_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: true
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "measurement_settings_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: true
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "measurement_settings_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: true
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      measurement_travels: {
        Row: {
          created_at: string | null
          description: string | null
          distance_km: number | null
          fixed_value: number | null
          from_city: string
          id: string
          km_rate: number | null
          measurement_id: string
          to_city: string
          total_value: number
          travel_type: Database["public"]["Enums"]["travel_type"]
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          distance_km?: number | null
          fixed_value?: number | null
          from_city: string
          id?: string
          km_rate?: number | null
          measurement_id: string
          to_city: string
          total_value: number
          travel_type: Database["public"]["Enums"]["travel_type"]
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          description?: string | null
          distance_km?: number | null
          fixed_value?: number | null
          from_city?: string
          id?: string
          km_rate?: number | null
          measurement_id?: string
          to_city?: string
          total_value?: number
          travel_type?: Database["public"]["Enums"]["travel_type"]
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "measurement_travels_measurement_id_fkey"
            columns: ["measurement_id"]
            isOneToOne: false
            referencedRelation: "measurements"
            referencedColumns: ["id"]
          },
        ]
      }
      measurements: {
        Row: {
          category: Database["public"]["Enums"]["measurement_category"]
          created_at: string | null
          created_by: string | null
          finalized_at: string | null
          finalized_by: string | null
          id: string
          pdf_path: string | null
          service_order_id: string
          status: Database["public"]["Enums"]["measurement_status"]
          subtotal: number | null
          subtotal_expenses: number | null
          subtotal_man_hours: number | null
          subtotal_materials: number | null
          subtotal_services: number | null
          subtotal_travels: number | null
          tax_amount: number | null
          tax_percentage: number | null
          total_amount: number | null
          updated_at: string | null
        }
        Insert: {
          category?: Database["public"]["Enums"]["measurement_category"]
          created_at?: string | null
          created_by?: string | null
          finalized_at?: string | null
          finalized_by?: string | null
          id?: string
          pdf_path?: string | null
          service_order_id: string
          status?: Database["public"]["Enums"]["measurement_status"]
          subtotal?: number | null
          subtotal_expenses?: number | null
          subtotal_man_hours?: number | null
          subtotal_materials?: number | null
          subtotal_services?: number | null
          subtotal_travels?: number | null
          tax_amount?: number | null
          tax_percentage?: number | null
          total_amount?: number | null
          updated_at?: string | null
        }
        Update: {
          category?: Database["public"]["Enums"]["measurement_category"]
          created_at?: string | null
          created_by?: string | null
          finalized_at?: string | null
          finalized_by?: string | null
          id?: string
          pdf_path?: string | null
          service_order_id?: string
          status?: Database["public"]["Enums"]["measurement_status"]
          subtotal?: number | null
          subtotal_expenses?: number | null
          subtotal_man_hours?: number | null
          subtotal_materials?: number | null
          subtotal_services?: number | null
          subtotal_travels?: number | null
          tax_amount?: number | null
          tax_percentage?: number | null
          total_amount?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "measurements_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "measurements_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "measurements_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "measurements_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "measurements_finalized_by_fkey"
            columns: ["finalized_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "measurements_finalized_by_fkey"
            columns: ["finalized_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "measurements_finalized_by_fkey"
            columns: ["finalized_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "measurements_finalized_by_fkey"
            columns: ["finalized_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "measurements_service_order_id_fkey"
            columns: ["service_order_id"]
            isOneToOne: true
            referencedRelation: "service_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      messages: {
        Row: {
          attachment_url: string | null
          content: string
          conversation_id: string
          created_at: string | null
          edited_at: string | null
          id: string
          message_type: string | null
          sender_id: string
        }
        Insert: {
          attachment_url?: string | null
          content: string
          conversation_id: string
          created_at?: string | null
          edited_at?: string | null
          id?: string
          message_type?: string | null
          sender_id: string
        }
        Update: {
          attachment_url?: string | null
          content?: string
          conversation_id?: string
          created_at?: string | null
          edited_at?: string | null
          id?: string
          message_type?: string | null
          sender_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "messages_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          created_at: string
          id: string
          message: string | null
          notification_type: Database["public"]["Enums"]["notification_type"]
          read: boolean | null
          reference_id: string | null
          title: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          message?: string | null
          notification_type: Database["public"]["Enums"]["notification_type"]
          read?: boolean | null
          reference_id?: string | null
          title: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          message?: string | null
          notification_type?: Database["public"]["Enums"]["notification_type"]
          read?: boolean | null
          reference_id?: string | null
          title?: string
          user_id?: string
        }
        Relationships: []
      }
      omie_sync_blocklist: {
        Row: {
          blocked_at: string
          blocked_by: string | null
          cnpj: string | null
          company_id: string
          id: string
          omie_client_id: string | null
          reason: string | null
        }
        Insert: {
          blocked_at?: string
          blocked_by?: string | null
          cnpj?: string | null
          company_id: string
          id?: string
          omie_client_id?: string | null
          reason?: string | null
        }
        Update: {
          blocked_at?: string
          blocked_by?: string | null
          cnpj?: string | null
          company_id?: string
          id?: string
          omie_client_id?: string | null
          reason?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "omie_sync_blocklist_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "omie_sync_blocklist_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "omie_sync_blocklist_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      onboarding_document_types: {
        Row: {
          company_id: string
          created_at: string | null
          description: string | null
          id: string
          is_required: boolean | null
          name: string
          position_tag: string | null
          sort_order: number | null
        }
        Insert: {
          company_id: string
          created_at?: string | null
          description?: string | null
          id?: string
          is_required?: boolean | null
          name: string
          position_tag?: string | null
          sort_order?: number | null
        }
        Update: {
          company_id?: string
          created_at?: string | null
          description?: string | null
          id?: string
          is_required?: boolean | null
          name?: string
          position_tag?: string | null
          sort_order?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "onboarding_document_types_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "onboarding_document_types_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "onboarding_document_types_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      onboarding_documents: {
        Row: {
          document_type_id: string
          file_name: string
          file_url: string
          id: string
          onboarding_id: string
          rejection_reason: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: string | null
          uploaded_at: string | null
          uploaded_by: string | null
        }
        Insert: {
          document_type_id: string
          file_name: string
          file_url: string
          id?: string
          onboarding_id: string
          rejection_reason?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string | null
          uploaded_at?: string | null
          uploaded_by?: string | null
        }
        Update: {
          document_type_id?: string
          file_name?: string
          file_url?: string
          id?: string
          onboarding_id?: string
          rejection_reason?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string | null
          uploaded_at?: string | null
          uploaded_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "onboarding_documents_document_type_id_fkey"
            columns: ["document_type_id"]
            isOneToOne: false
            referencedRelation: "onboarding_document_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "onboarding_documents_onboarding_id_fkey"
            columns: ["onboarding_id"]
            isOneToOne: false
            referencedRelation: "employee_onboarding"
            referencedColumns: ["id"]
          },
        ]
      }
      os_materials: {
        Row: {
          created_at: string | null
          external_product_code: string | null
          external_product_id: number | null
          id: string
          name: string
          quantity: number | null
          service_order_id: string
          source: string | null
          synced_at: string | null
          unit_value: number
          updated_at: string | null
          used: boolean | null
        }
        Insert: {
          created_at?: string | null
          external_product_code?: string | null
          external_product_id?: number | null
          id?: string
          name: string
          quantity?: number | null
          service_order_id: string
          source?: string | null
          synced_at?: string | null
          unit_value: number
          updated_at?: string | null
          used?: boolean | null
        }
        Update: {
          created_at?: string | null
          external_product_code?: string | null
          external_product_id?: number | null
          id?: string
          name?: string
          quantity?: number | null
          service_order_id?: string
          source?: string | null
          synced_at?: string | null
          unit_value?: number
          updated_at?: string | null
          used?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "os_materials_service_order_id_fkey"
            columns: ["service_order_id"]
            isOneToOne: false
            referencedRelation: "service_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      productivity_snapshots: {
        Row: {
          average_task_duration: number | null
          company_id: string
          created_at: string | null
          hours_worked: number | null
          id: string
          satisfaction_avg: number | null
          snapshot_date: string
          tasks_assigned: number | null
          tasks_completed: number | null
          technician_id: string | null
        }
        Insert: {
          average_task_duration?: number | null
          company_id: string
          created_at?: string | null
          hours_worked?: number | null
          id?: string
          satisfaction_avg?: number | null
          snapshot_date: string
          tasks_assigned?: number | null
          tasks_completed?: number | null
          technician_id?: string | null
        }
        Update: {
          average_task_duration?: number | null
          company_id?: string
          created_at?: string | null
          hours_worked?: number | null
          id?: string
          satisfaction_avg?: number | null
          snapshot_date?: string
          tasks_assigned?: number | null
          tasks_completed?: number | null
          technician_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "productivity_snapshots_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "productivity_snapshots_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "productivity_snapshots_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "productivity_snapshots_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "productivity_snapshots_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians_public"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          bio: string | null
          birth_date: string | null
          company_id: string | null
          cover_url: string | null
          cpf: string | null
          created_at: string
          email: string
          emergency_contact_name: string | null
          emergency_contact_phone: string | null
          full_name: string
          gender: string | null
          height: number | null
          hire_date: string | null
          id: string
          nationality: string | null
          phone: string | null
          rg: string | null
          status: string
          updated_at: string
        }
        Insert: {
          avatar_url?: string | null
          bio?: string | null
          birth_date?: string | null
          company_id?: string | null
          cover_url?: string | null
          cpf?: string | null
          created_at?: string
          email: string
          emergency_contact_name?: string | null
          emergency_contact_phone?: string | null
          full_name: string
          gender?: string | null
          height?: number | null
          hire_date?: string | null
          id: string
          nationality?: string | null
          phone?: string | null
          rg?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          avatar_url?: string | null
          bio?: string | null
          birth_date?: string | null
          company_id?: string | null
          cover_url?: string | null
          cpf?: string | null
          created_at?: string
          email?: string
          emergency_contact_name?: string | null
          emergency_contact_phone?: string | null
          full_name?: string
          gender?: string | null
          height?: number | null
          hire_date?: string | null
          id?: string
          nationality?: string | null
          phone?: string | null
          rg?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "profiles_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "profiles_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      public_lead_rate_limit: {
        Row: {
          count: number
          ip: string
          window_start: string
        }
        Insert: {
          count?: number
          ip: string
          window_start: string
        }
        Update: {
          count?: number
          ip?: string
          window_start?: string
        }
        Relationships: []
      }
      public_site_leads: {
        Row: {
          assigned_to: string | null
          company_id: string
          company_name: string | null
          converted_at: string | null
          converted_opportunity_id: string | null
          created_at: string
          email: string
          id: string
          ip: string | null
          items: Json
          message: string | null
          name: string
          opportunity_id: string | null
          phone: string | null
          segment: string
          source: string
          status: string
          type: string
          updated_at: string
          user_agent: string | null
        }
        Insert: {
          assigned_to?: string | null
          company_id: string
          company_name?: string | null
          converted_at?: string | null
          converted_opportunity_id?: string | null
          created_at?: string
          email: string
          id?: string
          ip?: string | null
          items?: Json
          message?: string | null
          name: string
          opportunity_id?: string | null
          phone?: string | null
          segment?: string
          source?: string
          status?: string
          type: string
          updated_at?: string
          user_agent?: string | null
        }
        Update: {
          assigned_to?: string | null
          company_id?: string
          company_name?: string | null
          converted_at?: string | null
          converted_opportunity_id?: string | null
          created_at?: string
          email?: string
          id?: string
          ip?: string | null
          items?: Json
          message?: string | null
          name?: string
          opportunity_id?: string | null
          phone?: string | null
          segment?: string
          source?: string
          status?: string
          type?: string
          updated_at?: string
          user_agent?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "public_site_leads_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "public_site_leads_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "public_site_leads_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "public_site_leads_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "public_site_leads_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "public_site_leads_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "public_site_leads_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "public_site_leads_opportunity_id_fkey"
            columns: ["opportunity_id"]
            isOneToOne: false
            referencedRelation: "crm_opportunities"
            referencedColumns: ["id"]
          },
        ]
      }
      purchase_request_items: {
        Row: {
          created_at: string
          description: string
          estimated_unit_price: number | null
          id: string
          notes: string | null
          quantity: number
          request_id: string
          unit: string
        }
        Insert: {
          created_at?: string
          description: string
          estimated_unit_price?: number | null
          id?: string
          notes?: string | null
          quantity?: number
          request_id: string
          unit?: string
        }
        Update: {
          created_at?: string
          description?: string
          estimated_unit_price?: number | null
          id?: string
          notes?: string | null
          quantity?: number
          request_id?: string
          unit?: string
        }
        Relationships: [
          {
            foreignKeyName: "purchase_request_items_request_id_fkey"
            columns: ["request_id"]
            isOneToOne: false
            referencedRelation: "purchase_requests"
            referencedColumns: ["id"]
          },
        ]
      }
      purchase_requests: {
        Row: {
          category: string
          company_id: string
          created_at: string
          description: string | null
          director_approved_at: string | null
          director_approver_id: string | null
          estimated_total: number | null
          id: string
          justification: string | null
          manager_approved_at: string | null
          manager_approver_id: string | null
          priority: string
          rejection_reason: string | null
          requester_id: string
          status: string
          supplier_id: string | null
          title: string
          updated_at: string
        }
        Insert: {
          category?: string
          company_id: string
          created_at?: string
          description?: string | null
          director_approved_at?: string | null
          director_approver_id?: string | null
          estimated_total?: number | null
          id?: string
          justification?: string | null
          manager_approved_at?: string | null
          manager_approver_id?: string | null
          priority?: string
          rejection_reason?: string | null
          requester_id: string
          status?: string
          supplier_id?: string | null
          title: string
          updated_at?: string
        }
        Update: {
          category?: string
          company_id?: string
          created_at?: string
          description?: string | null
          director_approved_at?: string | null
          director_approver_id?: string | null
          estimated_total?: number | null
          id?: string
          justification?: string | null
          manager_approved_at?: string | null
          manager_approver_id?: string | null
          priority?: string
          rejection_reason?: string | null
          requester_id?: string
          status?: string
          supplier_id?: string | null
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "purchase_requests_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchase_requests_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "purchase_requests_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "purchase_requests_director_approver_id_fkey"
            columns: ["director_approver_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchase_requests_director_approver_id_fkey"
            columns: ["director_approver_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchase_requests_director_approver_id_fkey"
            columns: ["director_approver_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchase_requests_director_approver_id_fkey"
            columns: ["director_approver_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "purchase_requests_manager_approver_id_fkey"
            columns: ["manager_approver_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchase_requests_manager_approver_id_fkey"
            columns: ["manager_approver_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchase_requests_manager_approver_id_fkey"
            columns: ["manager_approver_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchase_requests_manager_approver_id_fkey"
            columns: ["manager_approver_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "purchase_requests_requester_id_fkey"
            columns: ["requester_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchase_requests_requester_id_fkey"
            columns: ["requester_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchase_requests_requester_id_fkey"
            columns: ["requester_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchase_requests_requester_id_fkey"
            columns: ["requester_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "purchase_requests_supplier_id_fkey"
            columns: ["supplier_id"]
            isOneToOne: false
            referencedRelation: "quality_suppliers"
            referencedColumns: ["id"]
          },
        ]
      }
      push_subscriptions: {
        Row: {
          auth: string
          created_at: string | null
          endpoint: string
          id: string
          p256dh: string
          user_id: string
        }
        Insert: {
          auth: string
          created_at?: string | null
          endpoint: string
          id?: string
          p256dh: string
          user_id: string
        }
        Update: {
          auth?: string
          created_at?: string | null
          endpoint?: string
          id?: string
          p256dh?: string
          user_id?: string
        }
        Relationships: []
      }
      quality_action_items: {
        Row: {
          action_plan_id: string
          completed_at: string | null
          created_at: string
          how: string | null
          how_much: number | null
          id: string
          item_order: number | null
          notes: string | null
          status: string
          updated_at: string
          what: string
          when_date: string | null
          where_location: string | null
          who: string | null
          why: string | null
        }
        Insert: {
          action_plan_id: string
          completed_at?: string | null
          created_at?: string
          how?: string | null
          how_much?: number | null
          id?: string
          item_order?: number | null
          notes?: string | null
          status?: string
          updated_at?: string
          what: string
          when_date?: string | null
          where_location?: string | null
          who?: string | null
          why?: string | null
        }
        Update: {
          action_plan_id?: string
          completed_at?: string | null
          created_at?: string
          how?: string | null
          how_much?: number | null
          id?: string
          item_order?: number | null
          notes?: string | null
          status?: string
          updated_at?: string
          what?: string
          when_date?: string | null
          where_location?: string | null
          who?: string | null
          why?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quality_action_items_action_plan_id_fkey"
            columns: ["action_plan_id"]
            isOneToOne: false
            referencedRelation: "quality_action_plans"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_action_items_who_fkey"
            columns: ["who"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_action_items_who_fkey"
            columns: ["who"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_action_items_who_fkey"
            columns: ["who"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_action_items_who_fkey"
            columns: ["who"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      quality_action_plans: {
        Row: {
          company_id: string
          completed_date: string | null
          created_at: string
          created_by: string | null
          description: string | null
          effectiveness_notes: string | null
          effectiveness_verified: boolean | null
          id: string
          ncr_id: string | null
          plan_type: string
          responsible_id: string | null
          source: string | null
          source_id: string | null
          start_date: string | null
          status: string
          target_date: string | null
          title: string
          updated_at: string
          verified_at: string | null
          verified_by: string | null
        }
        Insert: {
          company_id: string
          completed_date?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          effectiveness_notes?: string | null
          effectiveness_verified?: boolean | null
          id?: string
          ncr_id?: string | null
          plan_type?: string
          responsible_id?: string | null
          source?: string | null
          source_id?: string | null
          start_date?: string | null
          status?: string
          target_date?: string | null
          title: string
          updated_at?: string
          verified_at?: string | null
          verified_by?: string | null
        }
        Update: {
          company_id?: string
          completed_date?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          effectiveness_notes?: string | null
          effectiveness_verified?: boolean | null
          id?: string
          ncr_id?: string | null
          plan_type?: string
          responsible_id?: string | null
          source?: string | null
          source_id?: string | null
          start_date?: string | null
          status?: string
          target_date?: string | null
          title?: string
          updated_at?: string
          verified_at?: string | null
          verified_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quality_action_plans_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_action_plans_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_action_plans_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_action_plans_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_action_plans_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_action_plans_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_action_plans_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "quality_action_plans_ncr_id_fkey"
            columns: ["ncr_id"]
            isOneToOne: false
            referencedRelation: "quality_ncrs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_action_plans_responsible_id_fkey"
            columns: ["responsible_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_action_plans_responsible_id_fkey"
            columns: ["responsible_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_action_plans_responsible_id_fkey"
            columns: ["responsible_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_action_plans_responsible_id_fkey"
            columns: ["responsible_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "quality_action_plans_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_action_plans_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_action_plans_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_action_plans_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      quality_alert_history: {
        Row: {
          company_id: string
          entity_id: string
          id: string
          notification_id: string | null
          notified_at: string
          source: string
          status: string
        }
        Insert: {
          company_id: string
          entity_id: string
          id?: string
          notification_id?: string | null
          notified_at?: string
          source: string
          status: string
        }
        Update: {
          company_id?: string
          entity_id?: string
          id?: string
          notification_id?: string | null
          notified_at?: string
          source?: string
          status?: string
        }
        Relationships: []
      }
      quality_audit_checklist_items: {
        Row: {
          audit_id: string
          clause_reference: string | null
          created_at: string
          id: string
          item_order: number | null
          notes: string | null
          requirement: string
          result: string | null
        }
        Insert: {
          audit_id: string
          clause_reference?: string | null
          created_at?: string
          id?: string
          item_order?: number | null
          notes?: string | null
          requirement: string
          result?: string | null
        }
        Update: {
          audit_id?: string
          clause_reference?: string | null
          created_at?: string
          id?: string
          item_order?: number | null
          notes?: string | null
          requirement?: string
          result?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quality_audit_checklist_items_audit_id_fkey"
            columns: ["audit_id"]
            isOneToOne: false
            referencedRelation: "quality_audits"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_audit_findings: {
        Row: {
          action_plan_id: string | null
          audit_id: string
          clause_reference: string | null
          corrective_action_required: boolean | null
          created_at: string
          deadline: string | null
          description: string
          evidence: string | null
          finding_type: string
          id: string
          responsible_id: string | null
          status: string
          updated_at: string
        }
        Insert: {
          action_plan_id?: string | null
          audit_id: string
          clause_reference?: string | null
          corrective_action_required?: boolean | null
          created_at?: string
          deadline?: string | null
          description: string
          evidence?: string | null
          finding_type?: string
          id?: string
          responsible_id?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          action_plan_id?: string | null
          audit_id?: string
          clause_reference?: string | null
          corrective_action_required?: boolean | null
          created_at?: string
          deadline?: string | null
          description?: string
          evidence?: string | null
          finding_type?: string
          id?: string
          responsible_id?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_audit_findings_action_plan_id_fkey"
            columns: ["action_plan_id"]
            isOneToOne: false
            referencedRelation: "quality_action_plans"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_audit_findings_audit_id_fkey"
            columns: ["audit_id"]
            isOneToOne: false
            referencedRelation: "quality_audits"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_audit_findings_responsible_id_fkey"
            columns: ["responsible_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_audit_findings_responsible_id_fkey"
            columns: ["responsible_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_audit_findings_responsible_id_fkey"
            columns: ["responsible_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_audit_findings_responsible_id_fkey"
            columns: ["responsible_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      quality_audits: {
        Row: {
          actual_date: string | null
          audit_number: number
          audit_type: string
          company_id: string
          conclusion: string | null
          created_at: string
          created_by: string | null
          department: string | null
          id: string
          lead_auditor_id: string | null
          planned_date: string
          scope: string | null
          standard_reference: string | null
          status: string
          summary: string | null
          title: string
          updated_at: string
        }
        Insert: {
          actual_date?: string | null
          audit_number?: number
          audit_type?: string
          company_id: string
          conclusion?: string | null
          created_at?: string
          created_by?: string | null
          department?: string | null
          id?: string
          lead_auditor_id?: string | null
          planned_date: string
          scope?: string | null
          standard_reference?: string | null
          status?: string
          summary?: string | null
          title: string
          updated_at?: string
        }
        Update: {
          actual_date?: string | null
          audit_number?: number
          audit_type?: string
          company_id?: string
          conclusion?: string | null
          created_at?: string
          created_by?: string | null
          department?: string | null
          id?: string
          lead_auditor_id?: string | null
          planned_date?: string
          scope?: string | null
          standard_reference?: string | null
          status?: string
          summary?: string | null
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_audits_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_audits_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_audits_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_audits_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_audits_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_audits_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_audits_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "quality_audits_lead_auditor_id_fkey"
            columns: ["lead_auditor_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_audits_lead_auditor_id_fkey"
            columns: ["lead_auditor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_audits_lead_auditor_id_fkey"
            columns: ["lead_auditor_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_audits_lead_auditor_id_fkey"
            columns: ["lead_auditor_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      quality_calibration_checkpoints: {
        Row: {
          calibration_id: string
          created_at: string
          error: number | null
          id: string
          measured_value: number | null
          nominal_value: number | null
          notes: string | null
          pass: boolean | null
          tolerance: number | null
        }
        Insert: {
          calibration_id: string
          created_at?: string
          error?: number | null
          id?: string
          measured_value?: number | null
          nominal_value?: number | null
          notes?: string | null
          pass?: boolean | null
          tolerance?: number | null
        }
        Update: {
          calibration_id?: string
          created_at?: string
          error?: number | null
          id?: string
          measured_value?: number | null
          nominal_value?: number | null
          notes?: string | null
          pass?: boolean | null
          tolerance?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "quality_calibration_checkpoints_calibration_id_fkey"
            columns: ["calibration_id"]
            isOneToOne: false
            referencedRelation: "quality_calibrations"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_calibrations: {
        Row: {
          calibration_date: string
          certificate_file_name: string | null
          certificate_file_url: string | null
          certificate_number: string | null
          company_id: string
          cost: number | null
          created_at: string
          created_by: string | null
          device_id: string
          id: string
          kind: Database["public"]["Enums"]["quality_calibration_kind"]
          measurement_uncertainty: string | null
          next_due_at: string | null
          notes: string | null
          performed_by_user_id: string | null
          provider_supplier_id: string | null
          restrictions: string | null
          result: Database["public"]["Enums"]["quality_calibration_result"]
          traceability: string | null
          updated_at: string
          valid_until: string | null
        }
        Insert: {
          calibration_date: string
          certificate_file_name?: string | null
          certificate_file_url?: string | null
          certificate_number?: string | null
          company_id: string
          cost?: number | null
          created_at?: string
          created_by?: string | null
          device_id: string
          id?: string
          kind?: Database["public"]["Enums"]["quality_calibration_kind"]
          measurement_uncertainty?: string | null
          next_due_at?: string | null
          notes?: string | null
          performed_by_user_id?: string | null
          provider_supplier_id?: string | null
          restrictions?: string | null
          result?: Database["public"]["Enums"]["quality_calibration_result"]
          traceability?: string | null
          updated_at?: string
          valid_until?: string | null
        }
        Update: {
          calibration_date?: string
          certificate_file_name?: string | null
          certificate_file_url?: string | null
          certificate_number?: string | null
          company_id?: string
          cost?: number | null
          created_at?: string
          created_by?: string | null
          device_id?: string
          id?: string
          kind?: Database["public"]["Enums"]["quality_calibration_kind"]
          measurement_uncertainty?: string | null
          next_due_at?: string | null
          notes?: string | null
          performed_by_user_id?: string | null
          provider_supplier_id?: string | null
          restrictions?: string | null
          result?: Database["public"]["Enums"]["quality_calibration_result"]
          traceability?: string | null
          updated_at?: string
          valid_until?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quality_calibrations_device_id_fkey"
            columns: ["device_id"]
            isOneToOne: false
            referencedRelation: "quality_measuring_devices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_calibrations_provider_supplier_id_fkey"
            columns: ["provider_supplier_id"]
            isOneToOne: false
            referencedRelation: "quality_suppliers"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_competencies: {
        Row: {
          active: boolean
          category: Database["public"]["Enums"]["quality_competency_category"]
          company_id: string
          created_at: string
          description: string | null
          id: string
          name: string
          updated_at: string
        }
        Insert: {
          active?: boolean
          category?: Database["public"]["Enums"]["quality_competency_category"]
          company_id: string
          created_at?: string
          description?: string | null
          id?: string
          name: string
          updated_at?: string
        }
        Update: {
          active?: boolean
          category?: Database["public"]["Enums"]["quality_competency_category"]
          company_id?: string
          created_at?: string
          description?: string | null
          id?: string
          name?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_competencies_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_competencies_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_competencies_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      quality_competency_evidences: {
        Row: {
          company_id: string
          created_at: string
          evidence_date: string
          evidence_type: Database["public"]["Enums"]["quality_evidence_type"]
          id: string
          level_contribution: Database["public"]["Enums"]["quality_competency_level"]
          source_id: string | null
          source_label: string | null
          user_competency_id: string
        }
        Insert: {
          company_id: string
          created_at?: string
          evidence_date?: string
          evidence_type: Database["public"]["Enums"]["quality_evidence_type"]
          id?: string
          level_contribution?: Database["public"]["Enums"]["quality_competency_level"]
          source_id?: string | null
          source_label?: string | null
          user_competency_id: string
        }
        Update: {
          company_id?: string
          created_at?: string
          evidence_date?: string
          evidence_type?: Database["public"]["Enums"]["quality_evidence_type"]
          id?: string
          level_contribution?: Database["public"]["Enums"]["quality_competency_level"]
          source_id?: string | null
          source_label?: string | null
          user_competency_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_competency_evidences_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_competency_evidences_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_competency_evidences_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_competency_evidences_user_competency_id_fkey"
            columns: ["user_competency_id"]
            isOneToOne: false
            referencedRelation: "quality_user_competencies"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_competency_mappings: {
        Row: {
          company_id: string
          competency_id: string
          created_at: string
          evidence_type: Database["public"]["Enums"]["quality_evidence_type"]
          grants_level: Database["public"]["Enums"]["quality_competency_level"]
          id: string
          source_id: string | null
          source_label: string | null
          updated_at: string
        }
        Insert: {
          company_id: string
          competency_id: string
          created_at?: string
          evidence_type: Database["public"]["Enums"]["quality_evidence_type"]
          grants_level?: Database["public"]["Enums"]["quality_competency_level"]
          id?: string
          source_id?: string | null
          source_label?: string | null
          updated_at?: string
        }
        Update: {
          company_id?: string
          competency_id?: string
          created_at?: string
          evidence_type?: Database["public"]["Enums"]["quality_evidence_type"]
          grants_level?: Database["public"]["Enums"]["quality_competency_level"]
          id?: string
          source_id?: string | null
          source_label?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_competency_mappings_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_competency_mappings_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_competency_mappings_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_competency_mappings_competency_id_fkey"
            columns: ["competency_id"]
            isOneToOne: false
            referencedRelation: "quality_competencies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_competency_mappings_competency_id_fkey"
            columns: ["competency_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["competency_id"]
          },
        ]
      }
      quality_complaints: {
        Row: {
          acknowledged_at: string | null
          client_id: string | null
          company_id: string
          complaint_number: number
          created_at: string
          created_by: string | null
          description: string
          id: string
          is_anonymous: boolean
          kind: Database["public"]["Enums"]["complaint_kind"]
          linked_ncr_id: string | null
          linked_response_id: string | null
          received_at: string
          resolution_notes: string | null
          resolved_at: string | null
          responder_email: string | null
          responder_name: string | null
          responsible_id: string | null
          source: Database["public"]["Enums"]["complaint_source"]
          status: Database["public"]["Enums"]["complaint_status"]
          title: string
          updated_at: string
        }
        Insert: {
          acknowledged_at?: string | null
          client_id?: string | null
          company_id: string
          complaint_number?: number
          created_at?: string
          created_by?: string | null
          description: string
          id?: string
          is_anonymous?: boolean
          kind?: Database["public"]["Enums"]["complaint_kind"]
          linked_ncr_id?: string | null
          linked_response_id?: string | null
          received_at?: string
          resolution_notes?: string | null
          resolved_at?: string | null
          responder_email?: string | null
          responder_name?: string | null
          responsible_id?: string | null
          source?: Database["public"]["Enums"]["complaint_source"]
          status?: Database["public"]["Enums"]["complaint_status"]
          title: string
          updated_at?: string
        }
        Update: {
          acknowledged_at?: string | null
          client_id?: string | null
          company_id?: string
          complaint_number?: number
          created_at?: string
          created_by?: string | null
          description?: string
          id?: string
          is_anonymous?: boolean
          kind?: Database["public"]["Enums"]["complaint_kind"]
          linked_ncr_id?: string | null
          linked_response_id?: string | null
          received_at?: string
          resolution_notes?: string | null
          resolved_at?: string | null
          responder_email?: string | null
          responder_name?: string | null
          responsible_id?: string | null
          source?: Database["public"]["Enums"]["complaint_source"]
          status?: Database["public"]["Enums"]["complaint_status"]
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_complaints_linked_response_id_fkey"
            columns: ["linked_response_id"]
            isOneToOne: false
            referencedRelation: "quality_satisfaction_responses"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_controlled_copies: {
        Row: {
          copy_number: number
          created_at: string
          destroyed_at: string | null
          document_id: string
          id: string
          issued_at: string
          issued_by: string | null
          notes: string | null
          recipient_location: string | null
          recipient_name: string | null
          recipient_user_id: string | null
          returned_at: string | null
          status: Database["public"]["Enums"]["quality_controlled_copy_status"]
          updated_at: string
          version_id: string
        }
        Insert: {
          copy_number: number
          created_at?: string
          destroyed_at?: string | null
          document_id: string
          id?: string
          issued_at?: string
          issued_by?: string | null
          notes?: string | null
          recipient_location?: string | null
          recipient_name?: string | null
          recipient_user_id?: string | null
          returned_at?: string | null
          status?: Database["public"]["Enums"]["quality_controlled_copy_status"]
          updated_at?: string
          version_id: string
        }
        Update: {
          copy_number?: number
          created_at?: string
          destroyed_at?: string | null
          document_id?: string
          id?: string
          issued_at?: string
          issued_by?: string | null
          notes?: string | null
          recipient_location?: string | null
          recipient_name?: string | null
          recipient_user_id?: string | null
          returned_at?: string | null
          status?: Database["public"]["Enums"]["quality_controlled_copy_status"]
          updated_at?: string
          version_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_controlled_copies_document_id_fkey"
            columns: ["document_id"]
            isOneToOne: false
            referencedRelation: "quality_documents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_controlled_copies_version_id_fkey"
            columns: ["version_id"]
            isOneToOne: false
            referencedRelation: "quality_document_versions"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_device_usage_log: {
        Row: {
          company_id: string
          device_id: string
          id: string
          notes: string | null
          service_order_id: string | null
          used_at: string
          used_by: string | null
        }
        Insert: {
          company_id: string
          device_id: string
          id?: string
          notes?: string | null
          service_order_id?: string | null
          used_at?: string
          used_by?: string | null
        }
        Update: {
          company_id?: string
          device_id?: string
          id?: string
          notes?: string | null
          service_order_id?: string | null
          used_at?: string
          used_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quality_device_usage_log_device_id_fkey"
            columns: ["device_id"]
            isOneToOne: false
            referencedRelation: "quality_measuring_devices"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_document_access_log: {
        Row: {
          action: Database["public"]["Enums"]["quality_access_action"]
          created_at: string
          document_id: string
          id: string
          ip_address: string | null
          user_agent: string | null
          user_id: string | null
          version_id: string | null
        }
        Insert: {
          action: Database["public"]["Enums"]["quality_access_action"]
          created_at?: string
          document_id: string
          id?: string
          ip_address?: string | null
          user_agent?: string | null
          user_id?: string | null
          version_id?: string | null
        }
        Update: {
          action?: Database["public"]["Enums"]["quality_access_action"]
          created_at?: string
          document_id?: string
          id?: string
          ip_address?: string | null
          user_agent?: string | null
          user_id?: string | null
          version_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quality_document_access_log_document_id_fkey"
            columns: ["document_id"]
            isOneToOne: false
            referencedRelation: "quality_documents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_document_access_log_version_id_fkey"
            columns: ["version_id"]
            isOneToOne: false
            referencedRelation: "quality_document_versions"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_document_acknowledgement_assignments: {
        Row: {
          acknowledged_at: string | null
          assigned_at: string
          assigned_by: string | null
          created_at: string
          document_id: string
          due_date: string | null
          id: string
          signature_event_id: string | null
          status: string
          updated_at: string
          user_id: string
          version_id: string
        }
        Insert: {
          acknowledged_at?: string | null
          assigned_at?: string
          assigned_by?: string | null
          created_at?: string
          document_id: string
          due_date?: string | null
          id?: string
          signature_event_id?: string | null
          status?: string
          updated_at?: string
          user_id: string
          version_id: string
        }
        Update: {
          acknowledged_at?: string | null
          assigned_at?: string
          assigned_by?: string | null
          created_at?: string
          document_id?: string
          due_date?: string | null
          id?: string
          signature_event_id?: string | null
          status?: string
          updated_at?: string
          user_id?: string
          version_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_document_acknowledgement_assign_signature_event_id_fkey"
            columns: ["signature_event_id"]
            isOneToOne: false
            referencedRelation: "quality_signature_events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_document_acknowledgement_assignments_document_id_fkey"
            columns: ["document_id"]
            isOneToOne: false
            referencedRelation: "quality_documents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_document_acknowledgement_assignments_version_id_fkey"
            columns: ["version_id"]
            isOneToOne: false
            referencedRelation: "quality_document_versions"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_document_approvals: {
        Row: {
          approver_role: string | null
          approver_user_id: string
          comments: string | null
          created_at: string
          decided_at: string
          decision: string
          id: string
          signature_event_id: string | null
          version_id: string
        }
        Insert: {
          approver_role?: string | null
          approver_user_id: string
          comments?: string | null
          created_at?: string
          decided_at?: string
          decision: string
          id?: string
          signature_event_id?: string | null
          version_id: string
        }
        Update: {
          approver_role?: string | null
          approver_user_id?: string
          comments?: string | null
          created_at?: string
          decided_at?: string
          decision?: string
          id?: string
          signature_event_id?: string | null
          version_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "qd_approvals_sigev_fk"
            columns: ["signature_event_id"]
            isOneToOne: false
            referencedRelation: "quality_signature_events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_document_approvals_version_id_fkey"
            columns: ["version_id"]
            isOneToOne: false
            referencedRelation: "quality_document_versions"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_document_permissions: {
        Row: {
          can_download: boolean
          can_print: boolean
          can_view: boolean
          created_at: string
          document_id: string
          granted_by: string | null
          id: string
          receives_controlled_copy: boolean
          updated_at: string
          user_id: string
        }
        Insert: {
          can_download?: boolean
          can_print?: boolean
          can_view?: boolean
          created_at?: string
          document_id: string
          granted_by?: string | null
          id?: string
          receives_controlled_copy?: boolean
          updated_at?: string
          user_id: string
        }
        Update: {
          can_download?: boolean
          can_print?: boolean
          can_view?: boolean
          created_at?: string
          document_id?: string
          granted_by?: string | null
          id?: string
          receives_controlled_copy?: boolean
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_document_permissions_document_id_fkey"
            columns: ["document_id"]
            isOneToOne: false
            referencedRelation: "quality_documents"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_document_required_courses: {
        Row: {
          company_id: string
          course_id: string | null
          created_at: string
          created_by: string | null
          document_id: string
          id: string
          is_mandatory: boolean
          notes: string | null
          trail_id: string | null
        }
        Insert: {
          company_id: string
          course_id?: string | null
          created_at?: string
          created_by?: string | null
          document_id: string
          id?: string
          is_mandatory?: boolean
          notes?: string | null
          trail_id?: string | null
        }
        Update: {
          company_id?: string
          course_id?: string | null
          created_at?: string
          created_by?: string | null
          document_id?: string
          id?: string
          is_mandatory?: boolean
          notes?: string | null
          trail_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quality_document_required_courses_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_document_required_courses_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_document_required_courses_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_document_required_courses_course_id_fkey"
            columns: ["course_id"]
            isOneToOne: false
            referencedRelation: "university_courses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_document_required_courses_document_id_fkey"
            columns: ["document_id"]
            isOneToOne: false
            referencedRelation: "quality_documents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_document_required_courses_trail_id_fkey"
            columns: ["trail_id"]
            isOneToOne: false
            referencedRelation: "university_trails"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_document_types: {
        Row: {
          code_prefix: string
          company_id: string
          created_at: string
          default_classification: string | null
          default_review_interval_months: number | null
          description: string | null
          id: string
          is_active: boolean
          name: string
          updated_at: string
        }
        Insert: {
          code_prefix: string
          company_id: string
          created_at?: string
          default_classification?: string | null
          default_review_interval_months?: number | null
          description?: string | null
          id?: string
          is_active?: boolean
          name: string
          updated_at?: string
        }
        Update: {
          code_prefix?: string
          company_id?: string
          created_at?: string
          default_classification?: string | null
          default_review_interval_months?: number | null
          description?: string | null
          id?: string
          is_active?: boolean
          name?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_document_types_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_document_types_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_document_types_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      quality_document_versions: {
        Row: {
          approved_at: string | null
          approved_by: string | null
          change_summary: string | null
          content_kind: Database["public"]["Enums"]["quality_document_content_kind"]
          created_at: string
          document_id: string
          file_mime: string | null
          file_name: string | null
          file_path: string | null
          file_size: number | null
          id: string
          issued_at: string | null
          prepared_by: string | null
          revision_label: string
          revision_number: number
          rich_content: Json | null
          status: Database["public"]["Enums"]["quality_document_status"]
          updated_at: string
        }
        Insert: {
          approved_at?: string | null
          approved_by?: string | null
          change_summary?: string | null
          content_kind?: Database["public"]["Enums"]["quality_document_content_kind"]
          created_at?: string
          document_id: string
          file_mime?: string | null
          file_name?: string | null
          file_path?: string | null
          file_size?: number | null
          id?: string
          issued_at?: string | null
          prepared_by?: string | null
          revision_label: string
          revision_number: number
          rich_content?: Json | null
          status?: Database["public"]["Enums"]["quality_document_status"]
          updated_at?: string
        }
        Update: {
          approved_at?: string | null
          approved_by?: string | null
          change_summary?: string | null
          content_kind?: Database["public"]["Enums"]["quality_document_content_kind"]
          created_at?: string
          document_id?: string
          file_mime?: string | null
          file_name?: string | null
          file_path?: string | null
          file_size?: number | null
          id?: string
          issued_at?: string | null
          prepared_by?: string | null
          revision_label?: string
          revision_number?: number
          rich_content?: Json | null
          status?: Database["public"]["Enums"]["quality_document_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_document_versions_document_id_fkey"
            columns: ["document_id"]
            isOneToOne: false
            referencedRelation: "quality_documents"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_documents: {
        Row: {
          auto_renewal: boolean
          classification: string | null
          code: string
          company_id: string
          created_at: string
          created_by: string | null
          current_version_id: string | null
          document_control_mode: Database["public"]["Enums"]["quality_document_control_mode"]
          document_type_id: string | null
          expires_at: string | null
          external_source: string | null
          id: string
          next_review_date: string | null
          normative_reference: string | null
          notify_on_publish: boolean
          obsolete_at: string | null
          origin: Database["public"]["Enums"]["quality_origin"]
          published_at: string | null
          requires_strong_acknowledgement: boolean
          status: Database["public"]["Enums"]["quality_document_status"]
          title: string
          updated_at: string
          validity_end: string | null
          validity_start: string | null
          widely_visible: boolean
        }
        Insert: {
          auto_renewal?: boolean
          classification?: string | null
          code: string
          company_id: string
          created_at?: string
          created_by?: string | null
          current_version_id?: string | null
          document_control_mode?: Database["public"]["Enums"]["quality_document_control_mode"]
          document_type_id?: string | null
          expires_at?: string | null
          external_source?: string | null
          id?: string
          next_review_date?: string | null
          normative_reference?: string | null
          notify_on_publish?: boolean
          obsolete_at?: string | null
          origin?: Database["public"]["Enums"]["quality_origin"]
          published_at?: string | null
          requires_strong_acknowledgement?: boolean
          status?: Database["public"]["Enums"]["quality_document_status"]
          title: string
          updated_at?: string
          validity_end?: string | null
          validity_start?: string | null
          widely_visible?: boolean
        }
        Update: {
          auto_renewal?: boolean
          classification?: string | null
          code?: string
          company_id?: string
          created_at?: string
          created_by?: string | null
          current_version_id?: string | null
          document_control_mode?: Database["public"]["Enums"]["quality_document_control_mode"]
          document_type_id?: string | null
          expires_at?: string | null
          external_source?: string | null
          id?: string
          next_review_date?: string | null
          normative_reference?: string | null
          notify_on_publish?: boolean
          obsolete_at?: string | null
          origin?: Database["public"]["Enums"]["quality_origin"]
          published_at?: string | null
          requires_strong_acknowledgement?: boolean
          status?: Database["public"]["Enums"]["quality_document_status"]
          title?: string
          updated_at?: string
          validity_end?: string | null
          validity_start?: string | null
          widely_visible?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "quality_documents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_documents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_documents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_documents_current_version_fk"
            columns: ["current_version_id"]
            isOneToOne: false
            referencedRelation: "quality_document_versions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_documents_document_type_id_fkey"
            columns: ["document_type_id"]
            isOneToOne: false
            referencedRelation: "quality_document_types"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_improvements_manual: {
        Row: {
          action_plan_id: string | null
          category: string | null
          company_id: string
          created_at: string
          description: string | null
          due_date: string | null
          id: string
          priority: string
          responsible_id: string | null
          status: string
          submitted_by: string
          title: string
          updated_at: string
        }
        Insert: {
          action_plan_id?: string | null
          category?: string | null
          company_id: string
          created_at?: string
          description?: string | null
          due_date?: string | null
          id?: string
          priority?: string
          responsible_id?: string | null
          status?: string
          submitted_by: string
          title: string
          updated_at?: string
        }
        Update: {
          action_plan_id?: string | null
          category?: string | null
          company_id?: string
          created_at?: string
          description?: string | null
          due_date?: string | null
          id?: string
          priority?: string
          responsible_id?: string | null
          status?: string
          submitted_by?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_improvements_manual_action_plan_id_fkey"
            columns: ["action_plan_id"]
            isOneToOne: false
            referencedRelation: "quality_action_plans"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_interested_parties: {
        Row: {
          category: string
          company_id: string
          created_at: string
          created_by: string | null
          id: string
          last_review_notes: string | null
          last_reviewed_at: string | null
          last_reviewed_by: string | null
          monitoring_method: string | null
          name: string
          needs_expectations: string | null
          next_review_due_at: string | null
          owner_user_id: string | null
          relevance: string
          review_frequency_months: number | null
          status: string
          updated_at: string
        }
        Insert: {
          category: string
          company_id: string
          created_at?: string
          created_by?: string | null
          id?: string
          last_review_notes?: string | null
          last_reviewed_at?: string | null
          last_reviewed_by?: string | null
          monitoring_method?: string | null
          name: string
          needs_expectations?: string | null
          next_review_due_at?: string | null
          owner_user_id?: string | null
          relevance?: string
          review_frequency_months?: number | null
          status?: string
          updated_at?: string
        }
        Update: {
          category?: string
          company_id?: string
          created_at?: string
          created_by?: string | null
          id?: string
          last_review_notes?: string | null
          last_reviewed_at?: string | null
          last_reviewed_by?: string | null
          monitoring_method?: string | null
          name?: string
          needs_expectations?: string | null
          next_review_due_at?: string | null
          owner_user_id?: string | null
          relevance?: string
          review_frequency_months?: number | null
          status?: string
          updated_at?: string
        }
        Relationships: []
      }
      quality_interested_party_evidences: {
        Row: {
          created_at: string
          description: string | null
          document_id: string | null
          evidence_date: string | null
          evidence_type: string
          external_file_path: string | null
          id: string
          party_id: string
          title: string
          updated_at: string
          uploaded_by: string | null
          valid_until: string | null
        }
        Insert: {
          created_at?: string
          description?: string | null
          document_id?: string | null
          evidence_date?: string | null
          evidence_type?: string
          external_file_path?: string | null
          id?: string
          party_id: string
          title: string
          updated_at?: string
          uploaded_by?: string | null
          valid_until?: string | null
        }
        Update: {
          created_at?: string
          description?: string | null
          document_id?: string | null
          evidence_date?: string | null
          evidence_type?: string
          external_file_path?: string | null
          id?: string
          party_id?: string
          title?: string
          updated_at?: string
          uploaded_by?: string | null
          valid_until?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quality_interested_party_evidences_document_id_fkey"
            columns: ["document_id"]
            isOneToOne: false
            referencedRelation: "quality_documents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_interested_party_evidences_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "quality_interested_parties"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_management_review_inputs: {
        Row: {
          content: Json
          created_at: string
          id: string
          input_type: Database["public"]["Enums"]["quality_review_input_type"]
          is_snapshot: boolean
          notes: string | null
          review_id: string
          snapshot_at: string | null
          updated_at: string
        }
        Insert: {
          content?: Json
          created_at?: string
          id?: string
          input_type: Database["public"]["Enums"]["quality_review_input_type"]
          is_snapshot?: boolean
          notes?: string | null
          review_id: string
          snapshot_at?: string | null
          updated_at?: string
        }
        Update: {
          content?: Json
          created_at?: string
          id?: string
          input_type?: Database["public"]["Enums"]["quality_review_input_type"]
          is_snapshot?: boolean
          notes?: string | null
          review_id?: string
          snapshot_at?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_management_review_inputs_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: false
            referencedRelation: "quality_management_reviews"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_management_review_outputs: {
        Row: {
          created_at: string
          description: string
          due_date: string | null
          id: string
          linked_action_plan_id: string | null
          output_type: Database["public"]["Enums"]["quality_review_output_type"]
          responsible_user_id: string | null
          review_id: string
          status: Database["public"]["Enums"]["quality_review_output_status"]
          updated_at: string
        }
        Insert: {
          created_at?: string
          description: string
          due_date?: string | null
          id?: string
          linked_action_plan_id?: string | null
          output_type: Database["public"]["Enums"]["quality_review_output_type"]
          responsible_user_id?: string | null
          review_id: string
          status?: Database["public"]["Enums"]["quality_review_output_status"]
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string
          due_date?: string | null
          id?: string
          linked_action_plan_id?: string | null
          output_type?: Database["public"]["Enums"]["quality_review_output_type"]
          responsible_user_id?: string | null
          review_id?: string
          status?: Database["public"]["Enums"]["quality_review_output_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_management_review_outputs_linked_action_plan_id_fkey"
            columns: ["linked_action_plan_id"]
            isOneToOne: true
            referencedRelation: "quality_action_plans"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_review_outputs_responsible_user_id_fkey"
            columns: ["responsible_user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_review_outputs_responsible_user_id_fkey"
            columns: ["responsible_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_review_outputs_responsible_user_id_fkey"
            columns: ["responsible_user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_review_outputs_responsible_user_id_fkey"
            columns: ["responsible_user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "quality_management_review_outputs_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: false
            referencedRelation: "quality_management_reviews"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_management_review_participants: {
        Row: {
          attended: boolean
          confirmed_at: string | null
          created_at: string
          id: string
          review_id: string
          role_in_meeting: Database["public"]["Enums"]["quality_review_participant_role"]
          signature_event_id: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          attended?: boolean
          confirmed_at?: string | null
          created_at?: string
          id?: string
          review_id: string
          role_in_meeting?: Database["public"]["Enums"]["quality_review_participant_role"]
          signature_event_id?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          attended?: boolean
          confirmed_at?: string | null
          created_at?: string
          id?: string
          review_id?: string
          role_in_meeting?: Database["public"]["Enums"]["quality_review_participant_role"]
          signature_event_id?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_management_review_participants_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: false
            referencedRelation: "quality_management_reviews"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_review_participants_signature_event_id_fkey"
            columns: ["signature_event_id"]
            isOneToOne: false
            referencedRelation: "quality_signature_events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_review_participants_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_review_participants_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_review_participants_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_review_participants_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      quality_management_reviews: {
        Row: {
          chair_user_id: string | null
          closed_at: string | null
          closed_by: string | null
          company_id: string
          created_at: string
          created_by: string | null
          id: string
          minutes_document_id: string | null
          next_due_date: string | null
          period_end: string
          period_start: string
          review_date: string
          signed_event_id: string | null
          status: Database["public"]["Enums"]["quality_review_status"]
          summary: string | null
          updated_at: string
        }
        Insert: {
          chair_user_id?: string | null
          closed_at?: string | null
          closed_by?: string | null
          company_id: string
          created_at?: string
          created_by?: string | null
          id?: string
          minutes_document_id?: string | null
          next_due_date?: string | null
          period_end: string
          period_start: string
          review_date: string
          signed_event_id?: string | null
          status?: Database["public"]["Enums"]["quality_review_status"]
          summary?: string | null
          updated_at?: string
        }
        Update: {
          chair_user_id?: string | null
          closed_at?: string | null
          closed_by?: string | null
          company_id?: string
          created_at?: string
          created_by?: string | null
          id?: string
          minutes_document_id?: string | null
          next_due_date?: string | null
          period_end?: string
          period_start?: string
          review_date?: string
          signed_event_id?: string | null
          status?: Database["public"]["Enums"]["quality_review_status"]
          summary?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_management_reviews_chair_user_id_fkey"
            columns: ["chair_user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_reviews_chair_user_id_fkey"
            columns: ["chair_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_reviews_chair_user_id_fkey"
            columns: ["chair_user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_reviews_chair_user_id_fkey"
            columns: ["chair_user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "quality_management_reviews_closed_by_fkey"
            columns: ["closed_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_reviews_closed_by_fkey"
            columns: ["closed_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_reviews_closed_by_fkey"
            columns: ["closed_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_reviews_closed_by_fkey"
            columns: ["closed_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "quality_management_reviews_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_reviews_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_management_reviews_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_management_reviews_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_reviews_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_reviews_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_reviews_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "quality_management_reviews_minutes_document_id_fkey"
            columns: ["minutes_document_id"]
            isOneToOne: false
            referencedRelation: "quality_documents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_management_reviews_signed_event_id_fkey"
            columns: ["signed_event_id"]
            isOneToOne: false
            referencedRelation: "quality_signature_events"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_measuring_devices: {
        Row: {
          accuracy: string | null
          acquired_at: string | null
          calibration_frequency_months: number
          code: string
          company_id: string
          created_at: string
          created_by: string | null
          criticality: string
          description: string | null
          id: string
          last_calibration_at: string | null
          location: string | null
          manufacturer: string | null
          measurement_range: string | null
          model: string | null
          name: string
          next_calibration_due: string | null
          notes: string | null
          resolution: string | null
          responsible_user_id: string | null
          retired_at: string | null
          serial_number: string | null
          status: Database["public"]["Enums"]["quality_device_status"]
          unit: string | null
          updated_at: string
        }
        Insert: {
          accuracy?: string | null
          acquired_at?: string | null
          calibration_frequency_months?: number
          code: string
          company_id: string
          created_at?: string
          created_by?: string | null
          criticality?: string
          description?: string | null
          id?: string
          last_calibration_at?: string | null
          location?: string | null
          manufacturer?: string | null
          measurement_range?: string | null
          model?: string | null
          name: string
          next_calibration_due?: string | null
          notes?: string | null
          resolution?: string | null
          responsible_user_id?: string | null
          retired_at?: string | null
          serial_number?: string | null
          status?: Database["public"]["Enums"]["quality_device_status"]
          unit?: string | null
          updated_at?: string
        }
        Update: {
          accuracy?: string | null
          acquired_at?: string | null
          calibration_frequency_months?: number
          code?: string
          company_id?: string
          created_at?: string
          created_by?: string | null
          criticality?: string
          description?: string | null
          id?: string
          last_calibration_at?: string | null
          location?: string | null
          manufacturer?: string | null
          measurement_range?: string | null
          model?: string | null
          name?: string
          next_calibration_due?: string | null
          notes?: string | null
          resolution?: string | null
          responsible_user_id?: string | null
          retired_at?: string | null
          serial_number?: string | null
          status?: Database["public"]["Enums"]["quality_device_status"]
          unit?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      quality_ncr_attachments: {
        Row: {
          created_at: string
          file_name: string
          file_size: number | null
          file_url: string
          id: string
          ncr_id: string
          uploaded_by: string | null
        }
        Insert: {
          created_at?: string
          file_name: string
          file_size?: number | null
          file_url: string
          id?: string
          ncr_id: string
          uploaded_by?: string | null
        }
        Update: {
          created_at?: string
          file_name?: string
          file_size?: number | null
          file_url?: string
          id?: string
          ncr_id?: string
          uploaded_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quality_ncr_attachments_ncr_id_fkey"
            columns: ["ncr_id"]
            isOneToOne: false
            referencedRelation: "quality_ncrs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_ncr_attachments_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_ncr_attachments_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_ncr_attachments_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_ncr_attachments_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      quality_ncrs: {
        Row: {
          affected_area: string | null
          closed_at: string | null
          closed_by: string | null
          company_id: string
          created_at: string
          created_by: string | null
          deadline: string | null
          description: string | null
          detected_at: string | null
          detected_by: string | null
          id: string
          immediate_action: string | null
          ncr_number: number
          ncr_type: string
          responsible_id: string | null
          root_cause: string | null
          severity: string
          source: string | null
          status: string
          title: string
          updated_at: string
          verification_notes: string | null
        }
        Insert: {
          affected_area?: string | null
          closed_at?: string | null
          closed_by?: string | null
          company_id: string
          created_at?: string
          created_by?: string | null
          deadline?: string | null
          description?: string | null
          detected_at?: string | null
          detected_by?: string | null
          id?: string
          immediate_action?: string | null
          ncr_number?: number
          ncr_type?: string
          responsible_id?: string | null
          root_cause?: string | null
          severity?: string
          source?: string | null
          status?: string
          title: string
          updated_at?: string
          verification_notes?: string | null
        }
        Update: {
          affected_area?: string | null
          closed_at?: string | null
          closed_by?: string | null
          company_id?: string
          created_at?: string
          created_by?: string | null
          deadline?: string | null
          description?: string | null
          detected_at?: string | null
          detected_by?: string | null
          id?: string
          immediate_action?: string | null
          ncr_number?: number
          ncr_type?: string
          responsible_id?: string | null
          root_cause?: string | null
          severity?: string
          source?: string | null
          status?: string
          title?: string
          updated_at?: string
          verification_notes?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quality_ncrs_closed_by_fkey"
            columns: ["closed_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_ncrs_closed_by_fkey"
            columns: ["closed_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_ncrs_closed_by_fkey"
            columns: ["closed_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_ncrs_closed_by_fkey"
            columns: ["closed_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "quality_ncrs_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_ncrs_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_ncrs_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_ncrs_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_ncrs_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_ncrs_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_ncrs_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "quality_ncrs_detected_by_fkey"
            columns: ["detected_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_ncrs_detected_by_fkey"
            columns: ["detected_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_ncrs_detected_by_fkey"
            columns: ["detected_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_ncrs_detected_by_fkey"
            columns: ["detected_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "quality_ncrs_responsible_id_fkey"
            columns: ["responsible_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_ncrs_responsible_id_fkey"
            columns: ["responsible_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_ncrs_responsible_id_fkey"
            columns: ["responsible_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_ncrs_responsible_id_fkey"
            columns: ["responsible_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      quality_org_context: {
        Row: {
          applicable_scope: string | null
          company_id: string
          created_at: string
          external_issues: string | null
          id: string
          internal_issues: string | null
          last_review_notes: string | null
          last_reviewed_at: string | null
          last_reviewed_by: string | null
          next_review_due_at: string | null
          review_frequency_months: number | null
          updated_at: string
        }
        Insert: {
          applicable_scope?: string | null
          company_id: string
          created_at?: string
          external_issues?: string | null
          id?: string
          internal_issues?: string | null
          last_review_notes?: string | null
          last_reviewed_at?: string | null
          last_reviewed_by?: string | null
          next_review_due_at?: string | null
          review_frequency_months?: number | null
          updated_at?: string
        }
        Update: {
          applicable_scope?: string | null
          company_id?: string
          created_at?: string
          external_issues?: string | null
          id?: string
          internal_issues?: string | null
          last_review_notes?: string | null
          last_reviewed_at?: string | null
          last_reviewed_by?: string | null
          next_review_due_at?: string | null
          review_frequency_months?: number | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_org_context_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: true
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_org_context_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: true
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_org_context_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: true
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      quality_reference_norms: {
        Row: {
          code: string
          company_id: string
          created_at: string
          created_by: string | null
          document_id: string | null
          id: string
          is_active: boolean
          issuer: string | null
          notes: string | null
          title: string
          updated_at: string
          valid_from: string | null
          valid_until: string | null
        }
        Insert: {
          code: string
          company_id: string
          created_at?: string
          created_by?: string | null
          document_id?: string | null
          id?: string
          is_active?: boolean
          issuer?: string | null
          notes?: string | null
          title: string
          updated_at?: string
          valid_from?: string | null
          valid_until?: string | null
        }
        Update: {
          code?: string
          company_id?: string
          created_at?: string
          created_by?: string | null
          document_id?: string | null
          id?: string
          is_active?: boolean
          issuer?: string | null
          notes?: string | null
          title?: string
          updated_at?: string
          valid_from?: string | null
          valid_until?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quality_reference_norms_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_reference_norms_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_reference_norms_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_reference_norms_document_id_fkey"
            columns: ["document_id"]
            isOneToOne: false
            referencedRelation: "quality_documents"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_risk_actions: {
        Row: {
          company_id: string
          completed_at: string | null
          created_at: string
          created_by: string | null
          description: string
          due_date: string | null
          evidence_url: string | null
          id: string
          notes: string | null
          responsible_id: string | null
          risk_id: string
          status: Database["public"]["Enums"]["quality_risk_action_status"]
          updated_at: string
        }
        Insert: {
          company_id: string
          completed_at?: string | null
          created_at?: string
          created_by?: string | null
          description: string
          due_date?: string | null
          evidence_url?: string | null
          id?: string
          notes?: string | null
          responsible_id?: string | null
          risk_id: string
          status?: Database["public"]["Enums"]["quality_risk_action_status"]
          updated_at?: string
        }
        Update: {
          company_id?: string
          completed_at?: string | null
          created_at?: string
          created_by?: string | null
          description?: string
          due_date?: string | null
          evidence_url?: string | null
          id?: string
          notes?: string | null
          responsible_id?: string | null
          risk_id?: string
          status?: Database["public"]["Enums"]["quality_risk_action_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_risk_actions_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_risk_actions_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_risk_actions_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_risk_actions_risk_id_fkey"
            columns: ["risk_id"]
            isOneToOne: false
            referencedRelation: "quality_risks"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_risk_events: {
        Row: {
          at: string
          by_user_id: string | null
          company_id: string
          event_type: string
          id: string
          new_value: Json | null
          old_value: Json | null
          risk_id: string
        }
        Insert: {
          at?: string
          by_user_id?: string | null
          company_id: string
          event_type: string
          id?: string
          new_value?: Json | null
          old_value?: Json | null
          risk_id: string
        }
        Update: {
          at?: string
          by_user_id?: string | null
          company_id?: string
          event_type?: string
          id?: string
          new_value?: Json | null
          old_value?: Json | null
          risk_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_risk_events_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_risk_events_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_risk_events_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_risk_events_risk_id_fkey"
            columns: ["risk_id"]
            isOneToOne: false
            referencedRelation: "quality_risks"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_risks: {
        Row: {
          category: string | null
          closed_at: string | null
          closure_notes: string | null
          code: string | null
          company_id: string
          created_at: string
          created_by: string | null
          description: string | null
          id: string
          impact: number
          kind: Database["public"]["Enums"]["quality_risk_kind"]
          last_reviewed_at: string | null
          next_review_due_at: string | null
          owner_user_id: string | null
          probability: number
          residual_impact: number | null
          residual_probability: number | null
          residual_score: number | null
          residual_severity: string | null
          review_frequency_months: number
          reviewed_by: string | null
          score: number | null
          severity: string | null
          source: Database["public"]["Enums"]["quality_risk_source"]
          source_ref_id: string | null
          status: Database["public"]["Enums"]["quality_risk_status"]
          status_changed_at: string
          title: string
          treatment:
            | Database["public"]["Enums"]["quality_risk_treatment"]
            | null
          treatment_due_date: string | null
          treatment_plan: string | null
          updated_at: string
        }
        Insert: {
          category?: string | null
          closed_at?: string | null
          closure_notes?: string | null
          code?: string | null
          company_id: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          impact: number
          kind?: Database["public"]["Enums"]["quality_risk_kind"]
          last_reviewed_at?: string | null
          next_review_due_at?: string | null
          owner_user_id?: string | null
          probability: number
          residual_impact?: number | null
          residual_probability?: number | null
          residual_score?: number | null
          residual_severity?: string | null
          review_frequency_months?: number
          reviewed_by?: string | null
          score?: number | null
          severity?: string | null
          source?: Database["public"]["Enums"]["quality_risk_source"]
          source_ref_id?: string | null
          status?: Database["public"]["Enums"]["quality_risk_status"]
          status_changed_at?: string
          title: string
          treatment?:
            | Database["public"]["Enums"]["quality_risk_treatment"]
            | null
          treatment_due_date?: string | null
          treatment_plan?: string | null
          updated_at?: string
        }
        Update: {
          category?: string | null
          closed_at?: string | null
          closure_notes?: string | null
          code?: string | null
          company_id?: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          impact?: number
          kind?: Database["public"]["Enums"]["quality_risk_kind"]
          last_reviewed_at?: string | null
          next_review_due_at?: string | null
          owner_user_id?: string | null
          probability?: number
          residual_impact?: number | null
          residual_probability?: number | null
          residual_score?: number | null
          residual_severity?: string | null
          review_frequency_months?: number
          reviewed_by?: string | null
          score?: number | null
          severity?: string | null
          source?: Database["public"]["Enums"]["quality_risk_source"]
          source_ref_id?: string | null
          status?: Database["public"]["Enums"]["quality_risk_status"]
          status_changed_at?: string
          title?: string
          treatment?:
            | Database["public"]["Enums"]["quality_risk_treatment"]
            | null
          treatment_due_date?: string | null
          treatment_plan?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_risks_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_risks_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_risks_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      quality_role_requirements: {
        Row: {
          company_id: string
          competency_id: string
          created_at: string
          id: string
          is_mandatory: boolean
          notes: string | null
          required_level: Database["public"]["Enums"]["quality_competency_level"]
          role: Database["public"]["Enums"]["app_role"]
          updated_at: string
        }
        Insert: {
          company_id: string
          competency_id: string
          created_at?: string
          id?: string
          is_mandatory?: boolean
          notes?: string | null
          required_level?: Database["public"]["Enums"]["quality_competency_level"]
          role: Database["public"]["Enums"]["app_role"]
          updated_at?: string
        }
        Update: {
          company_id?: string
          competency_id?: string
          created_at?: string
          id?: string
          is_mandatory?: boolean
          notes?: string | null
          required_level?: Database["public"]["Enums"]["quality_competency_level"]
          role?: Database["public"]["Enums"]["app_role"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_role_requirements_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_role_requirements_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_role_requirements_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_role_requirements_competency_id_fkey"
            columns: ["competency_id"]
            isOneToOne: false
            referencedRelation: "quality_competencies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_role_requirements_competency_id_fkey"
            columns: ["competency_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["competency_id"]
          },
        ]
      }
      quality_satisfaction_campaigns: {
        Row: {
          company_id: string
          created_at: string
          created_by: string | null
          description: string | null
          ends_at: string
          id: string
          name: string
          starts_at: string
          status: Database["public"]["Enums"]["satisfaction_campaign_status"]
          target_client_ids: string[]
          target_kind: Database["public"]["Enums"]["satisfaction_target_kind"]
          updated_at: string
        }
        Insert: {
          company_id: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          ends_at: string
          id?: string
          name: string
          starts_at: string
          status?: Database["public"]["Enums"]["satisfaction_campaign_status"]
          target_client_ids?: string[]
          target_kind?: Database["public"]["Enums"]["satisfaction_target_kind"]
          updated_at?: string
        }
        Update: {
          company_id?: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          ends_at?: string
          id?: string
          name?: string
          starts_at?: string
          status?: Database["public"]["Enums"]["satisfaction_campaign_status"]
          target_client_ids?: string[]
          target_kind?: Database["public"]["Enums"]["satisfaction_target_kind"]
          updated_at?: string
        }
        Relationships: []
      }
      quality_satisfaction_invites: {
        Row: {
          campaign_id: string
          client_id: string | null
          created_at: string
          id: string
          responded_at: string | null
          sent_at: string | null
          service_order_id: string | null
          token: string
        }
        Insert: {
          campaign_id: string
          client_id?: string | null
          created_at?: string
          id?: string
          responded_at?: string | null
          sent_at?: string | null
          service_order_id?: string | null
          token?: string
        }
        Update: {
          campaign_id?: string
          client_id?: string | null
          created_at?: string
          id?: string
          responded_at?: string | null
          sent_at?: string | null
          service_order_id?: string | null
          token?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_satisfaction_invites_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "quality_satisfaction_campaigns"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_satisfaction_responses: {
        Row: {
          campaign_id: string | null
          client_id: string | null
          comment: string | null
          company_id: string
          created_at: string
          csat_score: number
          derived_csat: string | null
          derived_nps: string | null
          id: string
          invite_id: string | null
          nps_score: number
          responded_at: string
          responder_email: string | null
          responder_ip: string | null
          responder_name: string | null
          service_order_id: string | null
          suggested_ncr_id: string | null
        }
        Insert: {
          campaign_id?: string | null
          client_id?: string | null
          comment?: string | null
          company_id: string
          created_at?: string
          csat_score: number
          derived_csat?: string | null
          derived_nps?: string | null
          id?: string
          invite_id?: string | null
          nps_score: number
          responded_at?: string
          responder_email?: string | null
          responder_ip?: string | null
          responder_name?: string | null
          service_order_id?: string | null
          suggested_ncr_id?: string | null
        }
        Update: {
          campaign_id?: string | null
          client_id?: string | null
          comment?: string | null
          company_id?: string
          created_at?: string
          csat_score?: number
          derived_csat?: string | null
          derived_nps?: string | null
          id?: string
          invite_id?: string | null
          nps_score?: number
          responded_at?: string
          responder_email?: string | null
          responder_ip?: string | null
          responder_name?: string | null
          service_order_id?: string | null
          suggested_ncr_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quality_satisfaction_responses_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "quality_satisfaction_campaigns"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_satisfaction_responses_invite_id_fkey"
            columns: ["invite_id"]
            isOneToOne: true
            referencedRelation: "quality_satisfaction_invites"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_settings: {
        Row: {
          company_id: string
          created_at: string
          critical_review_required_topics: Json
          id: string
          review_cycles: Json
          updated_at: string
        }
        Insert: {
          company_id: string
          created_at?: string
          critical_review_required_topics?: Json
          id?: string
          review_cycles?: Json
          updated_at?: string
        }
        Update: {
          company_id?: string
          created_at?: string
          critical_review_required_topics?: Json
          id?: string
          review_cycles?: Json
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_settings_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: true
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_settings_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: true
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_settings_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: true
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      quality_signature_events: {
        Row: {
          action: Database["public"]["Enums"]["quality_signature_action"]
          created_at: string
          document_id: string | null
          full_name_snapshot: string | null
          id: string
          ip_address: string | null
          notes: string | null
          role_snapshot: string | null
          signature_image_path: string
          signed_at: string
          user_agent: string | null
          user_id: string
          version_id: string | null
        }
        Insert: {
          action: Database["public"]["Enums"]["quality_signature_action"]
          created_at?: string
          document_id?: string | null
          full_name_snapshot?: string | null
          id?: string
          ip_address?: string | null
          notes?: string | null
          role_snapshot?: string | null
          signature_image_path: string
          signed_at?: string
          user_agent?: string | null
          user_id: string
          version_id?: string | null
        }
        Update: {
          action?: Database["public"]["Enums"]["quality_signature_action"]
          created_at?: string
          document_id?: string | null
          full_name_snapshot?: string | null
          id?: string
          ip_address?: string | null
          notes?: string | null
          role_snapshot?: string | null
          signature_image_path?: string
          signed_at?: string
          user_agent?: string | null
          user_id?: string
          version_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quality_signature_events_document_id_fkey"
            columns: ["document_id"]
            isOneToOne: false
            referencedRelation: "quality_documents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_signature_events_version_id_fkey"
            columns: ["version_id"]
            isOneToOne: false
            referencedRelation: "quality_document_versions"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_signatures: {
        Row: {
          company_id: string
          created_at: string
          full_name_snapshot: string | null
          id: string
          is_active: boolean
          signature_image_path: string
          updated_at: string
          user_id: string
        }
        Insert: {
          company_id: string
          created_at?: string
          full_name_snapshot?: string | null
          id?: string
          is_active?: boolean
          signature_image_path: string
          updated_at?: string
          user_id: string
        }
        Update: {
          company_id?: string
          created_at?: string
          full_name_snapshot?: string | null
          id?: string
          is_active?: boolean
          signature_image_path?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_signatures_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_signatures_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_signatures_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      quality_supplier_documents: {
        Row: {
          company_id: string
          created_at: string
          document_type: string
          file_name: string
          file_url: string
          id: string
          supplier_id: string
          uploaded_by: string | null
          valid_until: string | null
        }
        Insert: {
          company_id: string
          created_at?: string
          document_type: string
          file_name: string
          file_url: string
          id?: string
          supplier_id: string
          uploaded_by?: string | null
          valid_until?: string | null
        }
        Update: {
          company_id?: string
          created_at?: string
          document_type?: string
          file_name?: string
          file_url?: string
          id?: string
          supplier_id?: string
          uploaded_by?: string | null
          valid_until?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quality_supplier_documents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_supplier_documents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_supplier_documents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_supplier_documents_supplier_id_fkey"
            columns: ["supplier_id"]
            isOneToOne: false
            referencedRelation: "quality_suppliers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_supplier_documents_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_supplier_documents_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_supplier_documents_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_supplier_documents_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      quality_supplier_evaluation_criteria: {
        Row: {
          company_id: string
          created_at: string
          criterion_code: string
          evaluation_id: string
          id: string
          notes: string | null
          score: number
          weight: number
        }
        Insert: {
          company_id: string
          created_at?: string
          criterion_code: string
          evaluation_id: string
          id?: string
          notes?: string | null
          score?: number
          weight?: number
        }
        Update: {
          company_id?: string
          created_at?: string
          criterion_code?: string
          evaluation_id?: string
          id?: string
          notes?: string | null
          score?: number
          weight?: number
        }
        Relationships: [
          {
            foreignKeyName: "quality_supplier_evaluation_criteria_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_supplier_evaluation_criteria_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_supplier_evaluation_criteria_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_supplier_evaluation_criteria_evaluation_id_fkey"
            columns: ["evaluation_id"]
            isOneToOne: false
            referencedRelation: "quality_supplier_evaluations"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_supplier_evaluations: {
        Row: {
          company_id: string
          created_at: string
          evaluation_date: string
          evaluator_id: string | null
          grade: string | null
          id: string
          kind: Database["public"]["Enums"]["quality_supplier_evaluation_kind"]
          next_due_at: string | null
          period_end: string | null
          period_start: string | null
          recommendations: string | null
          score: number | null
          status_after:
            | Database["public"]["Enums"]["quality_supplier_status"]
            | null
          summary: string | null
          supplier_id: string
          updated_at: string
        }
        Insert: {
          company_id: string
          created_at?: string
          evaluation_date?: string
          evaluator_id?: string | null
          grade?: string | null
          id?: string
          kind?: Database["public"]["Enums"]["quality_supplier_evaluation_kind"]
          next_due_at?: string | null
          period_end?: string | null
          period_start?: string | null
          recommendations?: string | null
          score?: number | null
          status_after?:
            | Database["public"]["Enums"]["quality_supplier_status"]
            | null
          summary?: string | null
          supplier_id: string
          updated_at?: string
        }
        Update: {
          company_id?: string
          created_at?: string
          evaluation_date?: string
          evaluator_id?: string | null
          grade?: string | null
          id?: string
          kind?: Database["public"]["Enums"]["quality_supplier_evaluation_kind"]
          next_due_at?: string | null
          period_end?: string | null
          period_start?: string | null
          recommendations?: string | null
          score?: number | null
          status_after?:
            | Database["public"]["Enums"]["quality_supplier_status"]
            | null
          summary?: string | null
          supplier_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_supplier_evaluations_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_supplier_evaluations_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_supplier_evaluations_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_supplier_evaluations_evaluator_id_fkey"
            columns: ["evaluator_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_supplier_evaluations_evaluator_id_fkey"
            columns: ["evaluator_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_supplier_evaluations_evaluator_id_fkey"
            columns: ["evaluator_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_supplier_evaluations_evaluator_id_fkey"
            columns: ["evaluator_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "quality_supplier_evaluations_supplier_id_fkey"
            columns: ["supplier_id"]
            isOneToOne: false
            referencedRelation: "quality_suppliers"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_supplier_incidents: {
        Row: {
          company_id: string
          created_at: string
          description: string
          id: string
          incident_date: string
          linked_ncr_id: string | null
          reported_by: string | null
          resolved_at: string | null
          resolved_by: string | null
          severity: string
          supplier_id: string
        }
        Insert: {
          company_id: string
          created_at?: string
          description: string
          id?: string
          incident_date?: string
          linked_ncr_id?: string | null
          reported_by?: string | null
          resolved_at?: string | null
          resolved_by?: string | null
          severity?: string
          supplier_id: string
        }
        Update: {
          company_id?: string
          created_at?: string
          description?: string
          id?: string
          incident_date?: string
          linked_ncr_id?: string | null
          reported_by?: string | null
          resolved_at?: string | null
          resolved_by?: string | null
          severity?: string
          supplier_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_supplier_incidents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_supplier_incidents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_supplier_incidents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_supplier_incidents_linked_ncr_id_fkey"
            columns: ["linked_ncr_id"]
            isOneToOne: false
            referencedRelation: "quality_ncrs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_supplier_incidents_reported_by_fkey"
            columns: ["reported_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_supplier_incidents_reported_by_fkey"
            columns: ["reported_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_supplier_incidents_reported_by_fkey"
            columns: ["reported_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_supplier_incidents_reported_by_fkey"
            columns: ["reported_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "quality_supplier_incidents_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_supplier_incidents_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_supplier_incidents_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_supplier_incidents_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "quality_supplier_incidents_supplier_id_fkey"
            columns: ["supplier_id"]
            isOneToOne: false
            referencedRelation: "quality_suppliers"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_suppliers: {
        Row: {
          category: Database["public"]["Enums"]["quality_supplier_category"]
          company_id: string
          contact_email: string | null
          contact_name: string | null
          contact_phone: string | null
          created_at: string
          created_by: string | null
          criticality: Database["public"]["Enums"]["quality_supplier_criticality"]
          current_grade: string | null
          current_score: number | null
          id: string
          last_evaluation_at: string | null
          name: string
          next_evaluation_due: string | null
          notes: string | null
          owner_user_id: string | null
          requalification_frequency_months: number
          scope_description: string | null
          status: Database["public"]["Enums"]["quality_supplier_status"]
          tax_id: string | null
          updated_at: string
        }
        Insert: {
          category?: Database["public"]["Enums"]["quality_supplier_category"]
          company_id: string
          contact_email?: string | null
          contact_name?: string | null
          contact_phone?: string | null
          created_at?: string
          created_by?: string | null
          criticality?: Database["public"]["Enums"]["quality_supplier_criticality"]
          current_grade?: string | null
          current_score?: number | null
          id?: string
          last_evaluation_at?: string | null
          name: string
          next_evaluation_due?: string | null
          notes?: string | null
          owner_user_id?: string | null
          requalification_frequency_months?: number
          scope_description?: string | null
          status?: Database["public"]["Enums"]["quality_supplier_status"]
          tax_id?: string | null
          updated_at?: string
        }
        Update: {
          category?: Database["public"]["Enums"]["quality_supplier_category"]
          company_id?: string
          contact_email?: string | null
          contact_name?: string | null
          contact_phone?: string | null
          created_at?: string
          created_by?: string | null
          criticality?: Database["public"]["Enums"]["quality_supplier_criticality"]
          current_grade?: string | null
          current_score?: number | null
          id?: string
          last_evaluation_at?: string | null
          name?: string
          next_evaluation_due?: string | null
          notes?: string | null
          owner_user_id?: string | null
          requalification_frequency_months?: number
          scope_description?: string | null
          status?: Database["public"]["Enums"]["quality_supplier_status"]
          tax_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_suppliers_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_suppliers_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_suppliers_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_suppliers_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_suppliers_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_suppliers_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_suppliers_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "quality_suppliers_owner_user_id_fkey"
            columns: ["owner_user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_suppliers_owner_user_id_fkey"
            columns: ["owner_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_suppliers_owner_user_id_fkey"
            columns: ["owner_user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_suppliers_owner_user_id_fkey"
            columns: ["owner_user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      quality_terms: {
        Row: {
          company_id: string
          created_at: string
          created_by: string | null
          definition: string
          id: string
          source_norm_id: string | null
          term: string
          updated_at: string
        }
        Insert: {
          company_id: string
          created_at?: string
          created_by?: string | null
          definition: string
          id?: string
          source_norm_id?: string | null
          term: string
          updated_at?: string
        }
        Update: {
          company_id?: string
          created_at?: string
          created_by?: string | null
          definition?: string
          id?: string
          source_norm_id?: string | null
          term?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_terms_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_terms_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_terms_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_terms_source_norm_id_fkey"
            columns: ["source_norm_id"]
            isOneToOne: false
            referencedRelation: "quality_reference_norms"
            referencedColumns: ["id"]
          },
        ]
      }
      quality_training_plans: {
        Row: {
          auto_generated: boolean
          company_id: string
          competency_id: string
          completed_at: string | null
          completed_evidence_id: string | null
          created_at: string
          current_level: Database["public"]["Enums"]["quality_competency_level"]
          due_date: string | null
          generated_at: string
          id: string
          linked_course_id: string | null
          linked_trail_id: string | null
          notes: string | null
          required_level: Database["public"]["Enums"]["quality_competency_level"]
          responsible_id: string | null
          status: Database["public"]["Enums"]["quality_training_plan_status"]
          target_level: Database["public"]["Enums"]["quality_competency_level"]
          updated_at: string
          user_id: string
        }
        Insert: {
          auto_generated?: boolean
          company_id: string
          competency_id: string
          completed_at?: string | null
          completed_evidence_id?: string | null
          created_at?: string
          current_level: Database["public"]["Enums"]["quality_competency_level"]
          due_date?: string | null
          generated_at?: string
          id?: string
          linked_course_id?: string | null
          linked_trail_id?: string | null
          notes?: string | null
          required_level: Database["public"]["Enums"]["quality_competency_level"]
          responsible_id?: string | null
          status?: Database["public"]["Enums"]["quality_training_plan_status"]
          target_level: Database["public"]["Enums"]["quality_competency_level"]
          updated_at?: string
          user_id: string
        }
        Update: {
          auto_generated?: boolean
          company_id?: string
          competency_id?: string
          completed_at?: string | null
          completed_evidence_id?: string | null
          created_at?: string
          current_level?: Database["public"]["Enums"]["quality_competency_level"]
          due_date?: string | null
          generated_at?: string
          id?: string
          linked_course_id?: string | null
          linked_trail_id?: string | null
          notes?: string | null
          required_level?: Database["public"]["Enums"]["quality_competency_level"]
          responsible_id?: string | null
          status?: Database["public"]["Enums"]["quality_training_plan_status"]
          target_level?: Database["public"]["Enums"]["quality_competency_level"]
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_training_plans_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_training_plans_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_training_plans_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_training_plans_competency_id_fkey"
            columns: ["competency_id"]
            isOneToOne: false
            referencedRelation: "quality_competencies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_training_plans_competency_id_fkey"
            columns: ["competency_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["competency_id"]
          },
        ]
      }
      quality_user_competencies: {
        Row: {
          assessed_by: string | null
          assessment_notes: string | null
          auto_suggested_level: Database["public"]["Enums"]["quality_competency_level"]
          auto_suggestion_reason: string | null
          company_id: string
          competency_id: string
          created_at: string
          current_level: Database["public"]["Enums"]["quality_competency_level"]
          id: string
          last_assessed_at: string | null
          manual_override: boolean
          updated_at: string
          user_id: string
        }
        Insert: {
          assessed_by?: string | null
          assessment_notes?: string | null
          auto_suggested_level?: Database["public"]["Enums"]["quality_competency_level"]
          auto_suggestion_reason?: string | null
          company_id: string
          competency_id: string
          created_at?: string
          current_level?: Database["public"]["Enums"]["quality_competency_level"]
          id?: string
          last_assessed_at?: string | null
          manual_override?: boolean
          updated_at?: string
          user_id: string
        }
        Update: {
          assessed_by?: string | null
          assessment_notes?: string | null
          auto_suggested_level?: Database["public"]["Enums"]["quality_competency_level"]
          auto_suggestion_reason?: string | null
          company_id?: string
          competency_id?: string
          created_at?: string
          current_level?: Database["public"]["Enums"]["quality_competency_level"]
          id?: string
          last_assessed_at?: string | null
          manual_override?: boolean
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "quality_user_competencies_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_user_competencies_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_user_competencies_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_user_competencies_competency_id_fkey"
            columns: ["competency_id"]
            isOneToOne: false
            referencedRelation: "quality_competencies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_user_competencies_competency_id_fkey"
            columns: ["competency_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["competency_id"]
          },
        ]
      }
      report_embeddings: {
        Row: {
          content_hash: string | null
          content_text: string | null
          created_at: string | null
          embedding: string | null
          id: string
          task_report_id: string
          updated_at: string | null
        }
        Insert: {
          content_hash?: string | null
          content_text?: string | null
          created_at?: string | null
          embedding?: string | null
          id?: string
          task_report_id: string
          updated_at?: string | null
        }
        Update: {
          content_hash?: string | null
          content_text?: string | null
          created_at?: string | null
          embedding?: string | null
          id?: string
          task_report_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "report_embeddings_task_report_id_fkey"
            columns: ["task_report_id"]
            isOneToOne: true
            referencedRelation: "task_reports"
            referencedColumns: ["id"]
          },
        ]
      }
      service_history: {
        Row: {
          action: string
          change_type: string
          created_at: string
          description: string | null
          id: string
          ip_address: string | null
          new_values: Json | null
          old_values: Json | null
          performed_by: string | null
          service_order_id: string
          user_agent: string | null
          vessel_id: string | null
        }
        Insert: {
          action: string
          change_type?: string
          created_at?: string
          description?: string | null
          id?: string
          ip_address?: string | null
          new_values?: Json | null
          old_values?: Json | null
          performed_by?: string | null
          service_order_id: string
          user_agent?: string | null
          vessel_id?: string | null
        }
        Update: {
          action?: string
          change_type?: string
          created_at?: string
          description?: string | null
          id?: string
          ip_address?: string | null
          new_values?: Json | null
          old_values?: Json | null
          performed_by?: string | null
          service_order_id?: string
          user_agent?: string | null
          vessel_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "service_history_performed_by_fkey"
            columns: ["performed_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_history_performed_by_fkey"
            columns: ["performed_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_history_performed_by_fkey"
            columns: ["performed_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_history_performed_by_fkey"
            columns: ["performed_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "service_history_service_order_id_fkey"
            columns: ["service_order_id"]
            isOneToOne: false
            referencedRelation: "service_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_history_vessel_id_fkey"
            columns: ["vessel_id"]
            isOneToOne: false
            referencedRelation: "vessels"
            referencedColumns: ["id"]
          },
        ]
      }
      service_orders: {
        Row: {
          access: string | null
          access_instructions: string | null
          access_point_id: string | null
          boarding_method: string | null
          client_id: string | null
          client_reference: string | null
          company_id: string
          completed_date: string | null
          coordinator_id: string | null
          created_at: string
          created_by: string | null
          description: string | null
          expected_context: string | null
          id: string
          is_docking: boolean | null
          location: string | null
          omie_os_id: number | null
          omie_os_integration_code: string | null
          order_number: string
          parent_docking_id: string | null
          planned_location: string | null
          requester_contact_id: string | null
          scheduled_date: string | null
          service_date_time: string | null
          single_report: boolean | null
          status: Database["public"]["Enums"]["service_order_status"] | null
          supervisor_id: string | null
          updated_at: string
          vessel_id: string | null
        }
        Insert: {
          access?: string | null
          access_instructions?: string | null
          access_point_id?: string | null
          boarding_method?: string | null
          client_id?: string | null
          client_reference?: string | null
          company_id: string
          completed_date?: string | null
          coordinator_id?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          expected_context?: string | null
          id?: string
          is_docking?: boolean | null
          location?: string | null
          omie_os_id?: number | null
          omie_os_integration_code?: string | null
          order_number: string
          parent_docking_id?: string | null
          planned_location?: string | null
          requester_contact_id?: string | null
          scheduled_date?: string | null
          service_date_time?: string | null
          single_report?: boolean | null
          status?: Database["public"]["Enums"]["service_order_status"] | null
          supervisor_id?: string | null
          updated_at?: string
          vessel_id?: string | null
        }
        Update: {
          access?: string | null
          access_instructions?: string | null
          access_point_id?: string | null
          boarding_method?: string | null
          client_id?: string | null
          client_reference?: string | null
          company_id?: string
          completed_date?: string | null
          coordinator_id?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          expected_context?: string | null
          id?: string
          is_docking?: boolean | null
          location?: string | null
          omie_os_id?: number | null
          omie_os_integration_code?: string | null
          order_number?: string
          parent_docking_id?: string | null
          planned_location?: string | null
          requester_contact_id?: string | null
          scheduled_date?: string | null
          service_date_time?: string | null
          single_report?: boolean | null
          status?: Database["public"]["Enums"]["service_order_status"] | null
          supervisor_id?: string | null
          updated_at?: string
          vessel_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "service_orders_access_point_id_fkey"
            columns: ["access_point_id"]
            isOneToOne: false
            referencedRelation: "access_points"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_orders_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_orders_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_orders_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "service_orders_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "service_orders_coordinator_id_fkey"
            columns: ["coordinator_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_orders_coordinator_id_fkey"
            columns: ["coordinator_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_orders_coordinator_id_fkey"
            columns: ["coordinator_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_orders_coordinator_id_fkey"
            columns: ["coordinator_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "service_orders_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_orders_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_orders_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_orders_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "service_orders_parent_docking_id_fkey"
            columns: ["parent_docking_id"]
            isOneToOne: false
            referencedRelation: "service_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_orders_requester_contact_id_fkey"
            columns: ["requester_contact_id"]
            isOneToOne: false
            referencedRelation: "client_contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_orders_supervisor_id_fkey"
            columns: ["supervisor_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_orders_supervisor_id_fkey"
            columns: ["supervisor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_orders_supervisor_id_fkey"
            columns: ["supervisor_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_orders_supervisor_id_fkey"
            columns: ["supervisor_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "service_orders_vessel_id_fkey"
            columns: ["vessel_id"]
            isOneToOne: false
            referencedRelation: "vessels"
            referencedColumns: ["id"]
          },
        ]
      }
      service_rates: {
        Row: {
          company_id: string
          created_at: string | null
          hour_type: Database["public"]["Enums"]["time_entry_type"]
          id: string
          rate_value: number
          role_type: Database["public"]["Enums"]["technician_role"]
          updated_at: string | null
          work_type: Database["public"]["Enums"]["work_type"]
        }
        Insert: {
          company_id: string
          created_at?: string | null
          hour_type: Database["public"]["Enums"]["time_entry_type"]
          id?: string
          rate_value: number
          role_type: Database["public"]["Enums"]["technician_role"]
          updated_at?: string | null
          work_type: Database["public"]["Enums"]["work_type"]
        }
        Update: {
          company_id?: string
          created_at?: string | null
          hour_type?: Database["public"]["Enums"]["time_entry_type"]
          id?: string
          rate_value?: number
          role_type?: Database["public"]["Enums"]["technician_role"]
          updated_at?: string | null
          work_type?: Database["public"]["Enums"]["work_type"]
        }
        Relationships: [
          {
            foreignKeyName: "service_rates_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_rates_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "service_rates_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      service_visits: {
        Row: {
          created_at: string
          created_by: string | null
          id: string
          return_reason: string | null
          scheduled_by: string | null
          service_order_id: string
          status: Database["public"]["Enums"]["service_order_status"] | null
          updated_at: string
          visit_date: string
          visit_number: number
          visit_type: Database["public"]["Enums"]["visit_type"]
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          id?: string
          return_reason?: string | null
          scheduled_by?: string | null
          service_order_id: string
          status?: Database["public"]["Enums"]["service_order_status"] | null
          updated_at?: string
          visit_date: string
          visit_number: number
          visit_type?: Database["public"]["Enums"]["visit_type"]
        }
        Update: {
          created_at?: string
          created_by?: string | null
          id?: string
          return_reason?: string | null
          scheduled_by?: string | null
          service_order_id?: string
          status?: Database["public"]["Enums"]["service_order_status"] | null
          updated_at?: string
          visit_date?: string
          visit_number?: number
          visit_type?: Database["public"]["Enums"]["visit_type"]
        }
        Relationships: [
          {
            foreignKeyName: "service_visits_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_visits_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_visits_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_visits_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "service_visits_scheduled_by_fkey"
            columns: ["scheduled_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_visits_scheduled_by_fkey"
            columns: ["scheduled_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_visits_scheduled_by_fkey"
            columns: ["scheduled_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_visits_scheduled_by_fkey"
            columns: ["scheduled_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "service_visits_service_order_id_fkey"
            columns: ["service_order_id"]
            isOneToOne: false
            referencedRelation: "service_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      stock_products: {
        Row: {
          category: string | null
          company_id: string
          created_at: string | null
          current_quantity: number | null
          external_product_code: string | null
          external_product_id: number | null
          id: string
          is_active: boolean | null
          last_synced_at: string | null
          min_quantity: number | null
          name: string
          sell_price: number | null
          unit: string | null
          unit_cost: number | null
          updated_at: string | null
        }
        Insert: {
          category?: string | null
          company_id: string
          created_at?: string | null
          current_quantity?: number | null
          external_product_code?: string | null
          external_product_id?: number | null
          id?: string
          is_active?: boolean | null
          last_synced_at?: string | null
          min_quantity?: number | null
          name: string
          sell_price?: number | null
          unit?: string | null
          unit_cost?: number | null
          updated_at?: string | null
        }
        Update: {
          category?: string | null
          company_id?: string
          created_at?: string | null
          current_quantity?: number | null
          external_product_code?: string | null
          external_product_id?: number | null
          id?: string
          is_active?: boolean | null
          last_synced_at?: string | null
          min_quantity?: number | null
          name?: string
          sell_price?: number | null
          unit?: string | null
          unit_cost?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "stock_products_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "stock_products_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "stock_products_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      system_settings: {
        Row: {
          created_at: string
          id: string
          key: string
          updated_at: string
          value: Json
        }
        Insert: {
          created_at?: string
          id?: string
          key: string
          updated_at?: string
          value: Json
        }
        Update: {
          created_at?: string
          id?: string
          key?: string
          updated_at?: string
          value?: Json
        }
        Relationships: []
      }
      task_categories: {
        Row: {
          company_id: string
          created_at: string
          id: string
          name: string
          updated_at: string
        }
        Insert: {
          company_id: string
          created_at?: string
          id?: string
          name: string
          updated_at?: string
        }
        Update: {
          company_id?: string
          created_at?: string
          id?: string
          name?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "task_categories_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "task_categories_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "task_categories_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      task_report_history: {
        Row: {
          action: string
          changes: Json | null
          created_at: string
          edited_by: string
          id: string
          previous_data: Json | null
          report_id: string
        }
        Insert: {
          action: string
          changes?: Json | null
          created_at?: string
          edited_by: string
          id?: string
          previous_data?: Json | null
          report_id: string
        }
        Update: {
          action?: string
          changes?: Json | null
          created_at?: string
          edited_by?: string
          id?: string
          previous_data?: Json | null
          report_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "task_report_history_report_id_fkey"
            columns: ["report_id"]
            isOneToOne: false
            referencedRelation: "task_reports"
            referencedColumns: ["id"]
          },
        ]
      }
      task_reports: {
        Row: {
          approved_at: string | null
          approved_by: string | null
          created_at: string
          id: string
          pdf_path: string | null
          rejection_reason: string | null
          report_data: Json
          signed_pdf_path: string | null
          status: string
          task_id: string
          task_uuid: string | null
          updated_at: string
          visit_id: string | null
        }
        Insert: {
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          id?: string
          pdf_path?: string | null
          rejection_reason?: string | null
          report_data: Json
          signed_pdf_path?: string | null
          status: string
          task_id: string
          task_uuid?: string | null
          updated_at?: string
          visit_id?: string | null
        }
        Update: {
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          id?: string
          pdf_path?: string | null
          rejection_reason?: string | null
          report_data?: Json
          signed_pdf_path?: string | null
          status?: string
          task_id?: string
          task_uuid?: string | null
          updated_at?: string
          visit_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "task_reports_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "task_reports_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "task_reports_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "task_reports_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "task_reports_task_uuid_fkey"
            columns: ["task_uuid"]
            isOneToOne: true
            referencedRelation: "tasks"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "task_reports_visit_id_fkey"
            columns: ["visit_id"]
            isOneToOne: false
            referencedRelation: "service_visits"
            referencedColumns: ["id"]
          },
        ]
      }
      task_time_estimates: {
        Row: {
          average_duration_minutes: number | null
          company_id: string
          id: string
          last_updated: string
          max_duration_minutes: number | null
          min_duration_minutes: number | null
          sample_count: number | null
          task_type_id: string | null
          vessel_type: string | null
        }
        Insert: {
          average_duration_minutes?: number | null
          company_id: string
          id?: string
          last_updated?: string
          max_duration_minutes?: number | null
          min_duration_minutes?: number | null
          sample_count?: number | null
          task_type_id?: string | null
          vessel_type?: string | null
        }
        Update: {
          average_duration_minutes?: number | null
          company_id?: string
          id?: string
          last_updated?: string
          max_duration_minutes?: number | null
          min_duration_minutes?: number | null
          sample_count?: number | null
          task_type_id?: string | null
          vessel_type?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "task_time_estimates_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "task_time_estimates_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "task_time_estimates_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "task_time_estimates_task_type_id_fkey"
            columns: ["task_type_id"]
            isOneToOne: false
            referencedRelation: "task_types"
            referencedColumns: ["id"]
          },
        ]
      }
      task_types: {
        Row: {
          category: string | null
          company_id: string
          created_at: string
          default_estimated_value: number | null
          default_periodicity: number | null
          description: string | null
          id: string
          is_recurrent: boolean
          name: string
          photo_labels: string[] | null
          pricing_type: string | null
          recurrence_type: string | null
          steps: string[] | null
          tools: string[] | null
          updated_at: string
        }
        Insert: {
          category?: string | null
          company_id: string
          created_at?: string
          default_estimated_value?: number | null
          default_periodicity?: number | null
          description?: string | null
          id?: string
          is_recurrent?: boolean
          name: string
          photo_labels?: string[] | null
          pricing_type?: string | null
          recurrence_type?: string | null
          steps?: string[] | null
          tools?: string[] | null
          updated_at?: string
        }
        Update: {
          category?: string | null
          company_id?: string
          created_at?: string
          default_estimated_value?: number | null
          default_periodicity?: number | null
          description?: string | null
          id?: string
          is_recurrent?: boolean
          name?: string
          photo_labels?: string[] | null
          pricing_type?: string | null
          recurrence_type?: string | null
          steps?: string[] | null
          tools?: string[] | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "task_types_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "task_types_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "task_types_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      tasks: {
        Row: {
          assigned_to: string | null
          completed_at: string | null
          created_at: string
          description: string | null
          docking_activity_group: string | null
          due_date: string | null
          id: string
          priority: number | null
          scheduled_date: string | null
          scheduled_time: string | null
          service_order_id: string
          status: Database["public"]["Enums"]["task_status"] | null
          task_order_number: string | null
          task_type_id: string | null
          title: string
          updated_at: string
        }
        Insert: {
          assigned_to?: string | null
          completed_at?: string | null
          created_at?: string
          description?: string | null
          docking_activity_group?: string | null
          due_date?: string | null
          id?: string
          priority?: number | null
          scheduled_date?: string | null
          scheduled_time?: string | null
          service_order_id: string
          status?: Database["public"]["Enums"]["task_status"] | null
          task_order_number?: string | null
          task_type_id?: string | null
          title: string
          updated_at?: string
        }
        Update: {
          assigned_to?: string | null
          completed_at?: string | null
          created_at?: string
          description?: string | null
          docking_activity_group?: string | null
          due_date?: string | null
          id?: string
          priority?: number | null
          scheduled_date?: string | null
          scheduled_time?: string | null
          service_order_id?: string
          status?: Database["public"]["Enums"]["task_status"] | null
          task_order_number?: string | null
          task_type_id?: string | null
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "tasks_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "technicians"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tasks_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "technicians_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tasks_service_order_id_fkey"
            columns: ["service_order_id"]
            isOneToOne: false
            referencedRelation: "service_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tasks_task_type_id_fkey"
            columns: ["task_type_id"]
            isOneToOne: false
            referencedRelation: "task_types"
            referencedColumns: ["id"]
          },
        ]
      }
      technician_absences: {
        Row: {
          absence_type: Database["public"]["Enums"]["absence_type"]
          approved_at: string | null
          approved_by: string | null
          company_id: string
          created_at: string | null
          created_by: string | null
          end_date: string
          end_time: string | null
          id: string
          notes: string | null
          reason: string | null
          start_date: string
          start_time: string | null
          status: Database["public"]["Enums"]["absence_status"] | null
          technician_id: string | null
          updated_at: string | null
        }
        Insert: {
          absence_type: Database["public"]["Enums"]["absence_type"]
          approved_at?: string | null
          approved_by?: string | null
          company_id: string
          created_at?: string | null
          created_by?: string | null
          end_date: string
          end_time?: string | null
          id?: string
          notes?: string | null
          reason?: string | null
          start_date: string
          start_time?: string | null
          status?: Database["public"]["Enums"]["absence_status"] | null
          technician_id?: string | null
          updated_at?: string | null
        }
        Update: {
          absence_type?: Database["public"]["Enums"]["absence_type"]
          approved_at?: string | null
          approved_by?: string | null
          company_id?: string
          created_at?: string | null
          created_by?: string | null
          end_date?: string
          end_time?: string | null
          id?: string
          notes?: string | null
          reason?: string | null
          start_date?: string
          start_time?: string | null
          status?: Database["public"]["Enums"]["absence_status"] | null
          technician_id?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "technician_absences_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_absences_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_absences_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_absences_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "technician_absences_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_absences_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "technician_absences_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "technician_absences_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_absences_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_absences_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_absences_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "technician_absences_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_absences_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians_public"
            referencedColumns: ["id"]
          },
        ]
      }
      technician_documents: {
        Row: {
          certificate_name: string | null
          created_at: string
          document_type: string
          expiry_date: string | null
          file_name: string
          file_path: string
          id: string
          issue_date: string | null
          metadata: Json | null
          technician_id: string
          uploaded_at: string
          valid_until: string | null
        }
        Insert: {
          certificate_name?: string | null
          created_at?: string
          document_type: string
          expiry_date?: string | null
          file_name: string
          file_path: string
          id?: string
          issue_date?: string | null
          metadata?: Json | null
          technician_id: string
          uploaded_at?: string
          valid_until?: string | null
        }
        Update: {
          certificate_name?: string | null
          created_at?: string
          document_type?: string
          expiry_date?: string | null
          file_name?: string
          file_path?: string
          id?: string
          issue_date?: string | null
          metadata?: Json | null
          technician_id?: string
          uploaded_at?: string
          valid_until?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "technician_documents_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_documents_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians_public"
            referencedColumns: ["id"]
          },
        ]
      }
      technician_locations: {
        Row: {
          accuracy: number | null
          address: string | null
          check_in_forced: boolean | null
          force_reason: string | null
          id: string
          latitude: number
          location_matches_planned: boolean | null
          location_type: string
          longitude: number
          recorded_at: string
          task_id: string | null
          technician_id: string
          vessel_distance_meters: number | null
          vessel_position_snapshot: Json | null
          visit_id: string | null
        }
        Insert: {
          accuracy?: number | null
          address?: string | null
          check_in_forced?: boolean | null
          force_reason?: string | null
          id?: string
          latitude: number
          location_matches_planned?: boolean | null
          location_type?: string
          longitude: number
          recorded_at?: string
          task_id?: string | null
          technician_id: string
          vessel_distance_meters?: number | null
          vessel_position_snapshot?: Json | null
          visit_id?: string | null
        }
        Update: {
          accuracy?: number | null
          address?: string | null
          check_in_forced?: boolean | null
          force_reason?: string | null
          id?: string
          latitude?: number
          location_matches_planned?: boolean | null
          location_type?: string
          longitude?: number
          recorded_at?: string
          task_id?: string | null
          technician_id?: string
          vessel_distance_meters?: number | null
          vessel_position_snapshot?: Json | null
          visit_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "technician_locations_task_id_fkey"
            columns: ["task_id"]
            isOneToOne: false
            referencedRelation: "tasks"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_locations_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_locations_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_locations_visit_id_fkey"
            columns: ["visit_id"]
            isOneToOne: false
            referencedRelation: "service_visits"
            referencedColumns: ["id"]
          },
        ]
      }
      technician_on_call: {
        Row: {
          company_id: string
          created_at: string | null
          created_by: string | null
          end_time: string | null
          id: string
          is_holiday: boolean | null
          is_weekend: boolean | null
          notes: string | null
          on_call_date: string
          start_time: string | null
          technician_id: string | null
          updated_at: string | null
        }
        Insert: {
          company_id: string
          created_at?: string | null
          created_by?: string | null
          end_time?: string | null
          id?: string
          is_holiday?: boolean | null
          is_weekend?: boolean | null
          notes?: string | null
          on_call_date: string
          start_time?: string | null
          technician_id?: string | null
          updated_at?: string | null
        }
        Update: {
          company_id?: string
          created_at?: string | null
          created_by?: string | null
          end_time?: string | null
          id?: string
          is_holiday?: boolean | null
          is_weekend?: boolean | null
          notes?: string | null
          on_call_date?: string
          start_time?: string | null
          technician_id?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "technician_on_call_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_on_call_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "technician_on_call_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "technician_on_call_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_on_call_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_on_call_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_on_call_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "technician_on_call_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_on_call_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians_public"
            referencedColumns: ["id"]
          },
        ]
      }
      technician_reservations: {
        Row: {
          client_id: string | null
          company_id: string
          created_at: string | null
          end_date: string
          end_time: string | null
          id: string
          includes_overnight: boolean | null
          includes_travel: boolean | null
          notes: string | null
          reason: string | null
          reserved_by: string | null
          service_order_id: string | null
          start_date: string
          start_time: string | null
          status: string
          technician_id: string
          updated_at: string | null
          vessel_id: string | null
        }
        Insert: {
          client_id?: string | null
          company_id: string
          created_at?: string | null
          end_date: string
          end_time?: string | null
          id?: string
          includes_overnight?: boolean | null
          includes_travel?: boolean | null
          notes?: string | null
          reason?: string | null
          reserved_by?: string | null
          service_order_id?: string | null
          start_date: string
          start_time?: string | null
          status?: string
          technician_id: string
          updated_at?: string | null
          vessel_id?: string | null
        }
        Update: {
          client_id?: string | null
          company_id?: string
          created_at?: string | null
          end_date?: string
          end_time?: string | null
          id?: string
          includes_overnight?: boolean | null
          includes_travel?: boolean | null
          notes?: string | null
          reason?: string | null
          reserved_by?: string | null
          service_order_id?: string | null
          start_date?: string
          start_time?: string | null
          status?: string
          technician_id?: string
          updated_at?: string | null
          vessel_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "technician_reservations_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_reservations_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_reservations_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "technician_reservations_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "technician_reservations_reserved_by_fkey"
            columns: ["reserved_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_reservations_reserved_by_fkey"
            columns: ["reserved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_reservations_reserved_by_fkey"
            columns: ["reserved_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_reservations_reserved_by_fkey"
            columns: ["reserved_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "technician_reservations_service_order_id_fkey"
            columns: ["service_order_id"]
            isOneToOne: false
            referencedRelation: "service_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_reservations_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_reservations_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_reservations_vessel_id_fkey"
            columns: ["vessel_id"]
            isOneToOne: false
            referencedRelation: "vessels"
            referencedColumns: ["id"]
          },
        ]
      }
      technicians: {
        Row: {
          active: boolean | null
          aso_valid_until: string | null
          birth_date: string | null
          blood_rh_factor: string | null
          blood_type: string | null
          certifications: string[] | null
          company_id: string
          cpf: string | null
          created_at: string
          gender: string | null
          height: number | null
          id: string
          medical_status: string | null
          nationality: string | null
          rg: string | null
          specialty: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          active?: boolean | null
          aso_valid_until?: string | null
          birth_date?: string | null
          blood_rh_factor?: string | null
          blood_type?: string | null
          certifications?: string[] | null
          company_id: string
          cpf?: string | null
          created_at?: string
          gender?: string | null
          height?: number | null
          id?: string
          medical_status?: string | null
          nationality?: string | null
          rg?: string | null
          specialty?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          active?: boolean | null
          aso_valid_until?: string | null
          birth_date?: string | null
          blood_rh_factor?: string | null
          blood_type?: string | null
          certifications?: string[] | null
          company_id?: string
          cpf?: string | null
          created_at?: string
          gender?: string | null
          height?: number | null
          id?: string
          medical_status?: string | null
          nationality?: string | null
          rg?: string | null
          specialty?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "technicians_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technicians_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "technicians_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "technicians_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technicians_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technicians_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technicians_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      time_entries: {
        Row: {
          check_in_at: string | null
          check_out_at: string | null
          coordinator_name: string | null
          created_at: string
          end_time: string
          entry_date: string
          entry_type: Database["public"]["Enums"]["time_entry_type"]
          hours_extra: number | null
          hours_night: number | null
          hours_normal: number | null
          hours_standby: number | null
          id: string
          is_onboard: boolean | null
          is_overnight: boolean | null
          is_standby: boolean | null
          is_travel: boolean | null
          notes: string | null
          service_order_id: string | null
          start_time: string
          task_id: string | null
          technician_id: string | null
          updated_at: string
          vessel_name: string | null
        }
        Insert: {
          check_in_at?: string | null
          check_out_at?: string | null
          coordinator_name?: string | null
          created_at?: string
          end_time: string
          entry_date: string
          entry_type: Database["public"]["Enums"]["time_entry_type"]
          hours_extra?: number | null
          hours_night?: number | null
          hours_normal?: number | null
          hours_standby?: number | null
          id?: string
          is_onboard?: boolean | null
          is_overnight?: boolean | null
          is_standby?: boolean | null
          is_travel?: boolean | null
          notes?: string | null
          service_order_id?: string | null
          start_time: string
          task_id?: string | null
          technician_id?: string | null
          updated_at?: string
          vessel_name?: string | null
        }
        Update: {
          check_in_at?: string | null
          check_out_at?: string | null
          coordinator_name?: string | null
          created_at?: string
          end_time?: string
          entry_date?: string
          entry_type?: Database["public"]["Enums"]["time_entry_type"]
          hours_extra?: number | null
          hours_night?: number | null
          hours_normal?: number | null
          hours_standby?: number | null
          id?: string
          is_onboard?: boolean | null
          is_overnight?: boolean | null
          is_standby?: boolean | null
          is_travel?: boolean | null
          notes?: string | null
          service_order_id?: string | null
          start_time?: string
          task_id?: string | null
          technician_id?: string | null
          updated_at?: string
          vessel_name?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "time_entries_service_order_id_fkey"
            columns: ["service_order_id"]
            isOneToOne: false
            referencedRelation: "service_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "time_entries_task_id_fkey"
            columns: ["task_id"]
            isOneToOne: false
            referencedRelation: "tasks"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "time_entries_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "time_entries_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians_public"
            referencedColumns: ["id"]
          },
        ]
      }
      university_certificates: {
        Row: {
          certificate_code: string
          course_id: string
          enrollment_id: string
          id: string
          issued_at: string | null
          user_id: string
        }
        Insert: {
          certificate_code?: string
          course_id: string
          enrollment_id: string
          id?: string
          issued_at?: string | null
          user_id: string
        }
        Update: {
          certificate_code?: string
          course_id?: string
          enrollment_id?: string
          id?: string
          issued_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "university_certificates_course_id_fkey"
            columns: ["course_id"]
            isOneToOne: false
            referencedRelation: "university_courses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_certificates_enrollment_id_fkey"
            columns: ["enrollment_id"]
            isOneToOne: false
            referencedRelation: "university_enrollments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_certificates_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_certificates_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_certificates_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_certificates_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      university_courses: {
        Row: {
          category: string | null
          company_id: string
          created_at: string | null
          created_by: string | null
          description: string | null
          duration_minutes: number | null
          id: string
          is_published: boolean | null
          thumbnail_url: string | null
          title: string
          updated_at: string | null
        }
        Insert: {
          category?: string | null
          company_id: string
          created_at?: string | null
          created_by?: string | null
          description?: string | null
          duration_minutes?: number | null
          id?: string
          is_published?: boolean | null
          thumbnail_url?: string | null
          title: string
          updated_at?: string | null
        }
        Update: {
          category?: string | null
          company_id?: string
          created_at?: string | null
          created_by?: string | null
          description?: string | null
          duration_minutes?: number | null
          id?: string
          is_published?: boolean | null
          thumbnail_url?: string | null
          title?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "university_courses_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_courses_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "university_courses_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "university_courses_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_courses_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_courses_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_courses_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      university_enrollments: {
        Row: {
          assigned_by: string | null
          company_id: string
          completed_at: string | null
          course_id: string
          created_at: string | null
          id: string
          is_mandatory: boolean | null
          started_at: string | null
          status: string | null
          user_id: string
        }
        Insert: {
          assigned_by?: string | null
          company_id: string
          completed_at?: string | null
          course_id: string
          created_at?: string | null
          id?: string
          is_mandatory?: boolean | null
          started_at?: string | null
          status?: string | null
          user_id: string
        }
        Update: {
          assigned_by?: string | null
          company_id?: string
          completed_at?: string | null
          course_id?: string
          created_at?: string | null
          id?: string
          is_mandatory?: boolean | null
          started_at?: string | null
          status?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "university_enrollments_assigned_by_fkey"
            columns: ["assigned_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_enrollments_assigned_by_fkey"
            columns: ["assigned_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_enrollments_assigned_by_fkey"
            columns: ["assigned_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_enrollments_assigned_by_fkey"
            columns: ["assigned_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "university_enrollments_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_enrollments_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "university_enrollments_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "university_enrollments_course_id_fkey"
            columns: ["course_id"]
            isOneToOne: false
            referencedRelation: "university_courses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_enrollments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_enrollments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_enrollments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_enrollments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      university_modules: {
        Row: {
          content_type: string
          content_url: string | null
          course_id: string
          created_at: string | null
          description: string | null
          duration_minutes: number | null
          id: string
          sort_order: number | null
          title: string
        }
        Insert: {
          content_type?: string
          content_url?: string | null
          course_id: string
          created_at?: string | null
          description?: string | null
          duration_minutes?: number | null
          id?: string
          sort_order?: number | null
          title: string
        }
        Update: {
          content_type?: string
          content_url?: string | null
          course_id?: string
          created_at?: string | null
          description?: string | null
          duration_minutes?: number | null
          id?: string
          sort_order?: number | null
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "university_modules_course_id_fkey"
            columns: ["course_id"]
            isOneToOne: false
            referencedRelation: "university_courses"
            referencedColumns: ["id"]
          },
        ]
      }
      university_progress: {
        Row: {
          completed: boolean | null
          completed_at: string | null
          enrollment_id: string
          id: string
          module_id: string
        }
        Insert: {
          completed?: boolean | null
          completed_at?: string | null
          enrollment_id: string
          id?: string
          module_id: string
        }
        Update: {
          completed?: boolean | null
          completed_at?: string | null
          enrollment_id?: string
          id?: string
          module_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "university_progress_enrollment_id_fkey"
            columns: ["enrollment_id"]
            isOneToOne: false
            referencedRelation: "university_enrollments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_progress_module_id_fkey"
            columns: ["module_id"]
            isOneToOne: false
            referencedRelation: "university_modules"
            referencedColumns: ["id"]
          },
        ]
      }
      university_reward_settings: {
        Row: {
          badge_title_template: string
          company_id: string
          created_at: string | null
          icon: string
          id: string
          post_to_feed: boolean
          reward_type: string
          updated_at: string | null
          xp_value: number
        }
        Insert: {
          badge_title_template?: string
          company_id: string
          created_at?: string | null
          icon?: string
          id?: string
          post_to_feed?: boolean
          reward_type: string
          updated_at?: string | null
          xp_value?: number
        }
        Update: {
          badge_title_template?: string
          company_id?: string
          created_at?: string | null
          icon?: string
          id?: string
          post_to_feed?: boolean
          reward_type?: string
          updated_at?: string | null
          xp_value?: number
        }
        Relationships: [
          {
            foreignKeyName: "university_reward_settings_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_reward_settings_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "university_reward_settings_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      university_trail_courses: {
        Row: {
          course_id: string
          id: string
          sort_order: number | null
          trail_id: string
        }
        Insert: {
          course_id: string
          id?: string
          sort_order?: number | null
          trail_id: string
        }
        Update: {
          course_id?: string
          id?: string
          sort_order?: number | null
          trail_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "university_trail_courses_course_id_fkey"
            columns: ["course_id"]
            isOneToOne: false
            referencedRelation: "university_courses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_trail_courses_trail_id_fkey"
            columns: ["trail_id"]
            isOneToOne: false
            referencedRelation: "university_trails"
            referencedColumns: ["id"]
          },
        ]
      }
      university_trails: {
        Row: {
          company_id: string
          created_at: string | null
          created_by: string | null
          description: string | null
          id: string
          is_published: boolean | null
          title: string
        }
        Insert: {
          company_id: string
          created_at?: string | null
          created_by?: string | null
          description?: string | null
          id?: string
          is_published?: boolean | null
          title: string
        }
        Update: {
          company_id?: string
          created_at?: string | null
          created_by?: string | null
          description?: string | null
          id?: string
          is_published?: boolean | null
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "university_trails_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_trails_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "university_trails_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "university_trails_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_trails_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_trails_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "university_trails_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
      user_roles: {
        Row: {
          created_at: string
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
      vessel_positions: {
        Row: {
          course_over_ground: number | null
          created_at: string | null
          destination: string | null
          eta: string | null
          heading: number | null
          id: string
          latitude: number
          location_context: string | null
          longitude: number
          navigation_status: number | null
          recorded_at: string | null
          speed_over_ground: number | null
          vessel_id: string
        }
        Insert: {
          course_over_ground?: number | null
          created_at?: string | null
          destination?: string | null
          eta?: string | null
          heading?: number | null
          id?: string
          latitude: number
          location_context?: string | null
          longitude: number
          navigation_status?: number | null
          recorded_at?: string | null
          speed_over_ground?: number | null
          vessel_id: string
        }
        Update: {
          course_over_ground?: number | null
          created_at?: string | null
          destination?: string | null
          eta?: string | null
          heading?: number | null
          id?: string
          latitude?: number
          location_context?: string | null
          longitude?: number
          navigation_status?: number | null
          recorded_at?: string | null
          speed_over_ground?: number | null
          vessel_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "vessel_positions_vessel_id_fkey"
            columns: ["vessel_id"]
            isOneToOne: false
            referencedRelation: "vessels"
            referencedColumns: ["id"]
          },
        ]
      }
      vessels: {
        Row: {
          ais_source: string | null
          beam: number | null
          call_sign: string | null
          client_id: string
          created_at: string
          flag: string | null
          gross_tonnage: number | null
          id: string
          imo_number: string | null
          length_overall: number | null
          mmsi: string | null
          name: string
          ship_type: number | null
          updated_at: string
          vessel_type: string | null
          year_built: number | null
        }
        Insert: {
          ais_source?: string | null
          beam?: number | null
          call_sign?: string | null
          client_id: string
          created_at?: string
          flag?: string | null
          gross_tonnage?: number | null
          id?: string
          imo_number?: string | null
          length_overall?: number | null
          mmsi?: string | null
          name: string
          ship_type?: number | null
          updated_at?: string
          vessel_type?: string | null
          year_built?: number | null
        }
        Update: {
          ais_source?: string | null
          beam?: number | null
          call_sign?: string | null
          client_id?: string
          created_at?: string
          flag?: string | null
          gross_tonnage?: number | null
          id?: string
          imo_number?: string | null
          length_overall?: number | null
          mmsi?: string | null
          name?: string
          ship_type?: number | null
          updated_at?: string
          vessel_type?: string | null
          year_built?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "vessels_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
        ]
      }
      visit_technicians: {
        Row: {
          assigned_at: string
          assigned_by: string | null
          id: string
          is_lead: boolean | null
          technician_id: string
          visit_id: string
        }
        Insert: {
          assigned_at?: string
          assigned_by?: string | null
          id?: string
          is_lead?: boolean | null
          technician_id: string
          visit_id: string
        }
        Update: {
          assigned_at?: string
          assigned_by?: string | null
          id?: string
          is_lead?: boolean | null
          technician_id?: string
          visit_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "visit_technicians_assigned_by_fkey"
            columns: ["assigned_by"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "visit_technicians_assigned_by_fkey"
            columns: ["assigned_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "visit_technicians_assigned_by_fkey"
            columns: ["assigned_by"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "visit_technicians_assigned_by_fkey"
            columns: ["assigned_by"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "visit_technicians_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "visit_technicians_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "visit_technicians_visit_id_fkey"
            columns: ["visit_id"]
            isOneToOne: false
            referencedRelation: "service_visits"
            referencedColumns: ["id"]
          },
        ]
      }
      whatsapp_conversations: {
        Row: {
          ai_context: Json | null
          created_at: string | null
          direction: string
          id: string
          message: string
          message_sid: string | null
          phone_number: string
          user_id: string | null
        }
        Insert: {
          ai_context?: Json | null
          created_at?: string | null
          direction: string
          id?: string
          message: string
          message_sid?: string | null
          phone_number: string
          user_id?: string | null
        }
        Update: {
          ai_context?: Json | null
          created_at?: string | null
          direction?: string
          id?: string
          message?: string
          message_sid?: string | null
          phone_number?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "whatsapp_conversations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "whatsapp_conversations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "whatsapp_conversations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "whatsapp_conversations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
    }
    Views: {
      employee_celebrations_public: {
        Row: {
          avatar_url: string | null
          birth_day: number | null
          birth_month: number | null
          company_id: string | null
          full_name: string | null
          hire_day: number | null
          hire_month: number | null
          hire_year: number | null
          id: string | null
        }
        Insert: {
          avatar_url?: string | null
          birth_day?: never
          birth_month?: never
          company_id?: string | null
          full_name?: string | null
          hire_day?: never
          hire_month?: never
          hire_year?: never
          id?: string | null
        }
        Update: {
          avatar_url?: string | null
          birth_day?: never
          birth_month?: never
          company_id?: string | null
          full_name?: string | null
          hire_day?: never
          hire_month?: never
          hire_year?: never
          id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "profiles_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "profiles_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      profiles_public: {
        Row: {
          avatar_url: string | null
          company_id: string | null
          full_name: string | null
          id: string | null
        }
        Insert: {
          avatar_url?: string | null
          company_id?: string | null
          full_name?: string | null
          id?: string | null
        }
        Update: {
          avatar_url?: string | null
          company_id?: string | null
          full_name?: string | null
          id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "profiles_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "profiles_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      quality_acknowledgements_v: {
        Row: {
          acknowledged_at: string | null
          assigned_at: string | null
          assigned_by: string | null
          assignment_id: string | null
          company_id: string | null
          document_code: string | null
          document_id: string | null
          document_title: string | null
          due_date: string | null
          requires_strong_acknowledgement: boolean | null
          revision_label: string | null
          signature_event_id: string | null
          status: string | null
          user_id: string | null
          version_id: string | null
          version_status:
            | Database["public"]["Enums"]["quality_document_status"]
            | null
        }
        Relationships: [
          {
            foreignKeyName: "quality_document_acknowledgement_assign_signature_event_id_fkey"
            columns: ["signature_event_id"]
            isOneToOne: false
            referencedRelation: "quality_signature_events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_document_acknowledgement_assignments_document_id_fkey"
            columns: ["document_id"]
            isOneToOne: false
            referencedRelation: "quality_documents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_document_acknowledgement_assignments_version_id_fkey"
            columns: ["version_id"]
            isOneToOne: false
            referencedRelation: "quality_document_versions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_documents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_documents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_documents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      quality_alerts_v: {
        Row: {
          category: string | null
          company_id: string | null
          days_remaining: number | null
          due_date: string | null
          entity_id: string | null
          source: string | null
          status: string | null
          title: string | null
        }
        Relationships: []
      }
      quality_competency_matrix_v: {
        Row: {
          auto_suggested_level:
            | Database["public"]["Enums"]["quality_competency_level"]
            | null
          category:
            | Database["public"]["Enums"]["quality_competency_category"]
            | null
          company_id: string | null
          competency_id: string | null
          competency_name: string | null
          current_level:
            | Database["public"]["Enums"]["quality_competency_level"]
            | null
          full_name: string | null
          gap: number | null
          is_mandatory: boolean | null
          manual_override: boolean | null
          required_level:
            | Database["public"]["Enums"]["quality_competency_level"]
            | null
          role: Database["public"]["Enums"]["app_role"] | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "profiles_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "profiles_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      quality_improvements_v: {
        Row: {
          action_plan_id: string | null
          company_id: string | null
          description: string | null
          due_date: string | null
          id: string | null
          opened_at: string | null
          owner_user_id: string | null
          priority: string | null
          source: string | null
          source_label: string | null
          source_url: string | null
          status: string | null
          title: string | null
        }
        Relationships: []
      }
      quality_kpi_recurrence_v: {
        Row: {
          company_id: string | null
          occurrences: number | null
          root_cause_key: string | null
          root_cause_sample: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quality_ncrs_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quality_ncrs_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "quality_ncrs_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
        ]
      }
      quality_kpi_snapshot_v: {
        Row: {
          avg_approval_days: number | null
          avg_ncr_resolution_days: number | null
          company_id: string | null
          documents_expiring_30d: number | null
          documents_pending_approval: number | null
          documents_published: number | null
          findings_major_12m: number | null
          findings_minor_12m: number | null
          findings_observation_12m: number | null
          findings_opportunity_12m: number | null
          ncrs_open: number | null
          ncrs_overdue: number | null
          plans_effective: number | null
          plans_evaluated: number | null
          plans_overdue: number | null
          review_outputs_open: number | null
          reviews_closed_12m: number | null
        }
        Insert: {
          avg_approval_days?: never
          avg_ncr_resolution_days?: never
          company_id?: string | null
          documents_expiring_30d?: never
          documents_pending_approval?: never
          documents_published?: never
          findings_major_12m?: never
          findings_minor_12m?: never
          findings_observation_12m?: never
          findings_opportunity_12m?: never
          ncrs_open?: never
          ncrs_overdue?: never
          plans_effective?: never
          plans_evaluated?: never
          plans_overdue?: never
          review_outputs_open?: never
          reviews_closed_12m?: never
        }
        Update: {
          avg_approval_days?: never
          avg_ncr_resolution_days?: never
          company_id?: string | null
          documents_expiring_30d?: never
          documents_pending_approval?: never
          documents_published?: never
          findings_major_12m?: never
          findings_minor_12m?: never
          findings_observation_12m?: never
          findings_opportunity_12m?: never
          ncrs_open?: never
          ncrs_overdue?: never
          plans_effective?: never
          plans_evaluated?: never
          plans_overdue?: never
          review_outputs_open?: never
          reviews_closed_12m?: never
        }
        Relationships: []
      }
      quality_kpi_timeseries_v: {
        Row: {
          audits_executed: number | null
          audits_planned: number | null
          company_id: string | null
          documents_published: number | null
          month: string | null
          ncrs_closed: number | null
          ncrs_opened: number | null
          plans_effective: number | null
          plans_ineffective: number | null
        }
        Relationships: []
      }
      quality_review_status_v: {
        Row: {
          company_id: string | null
          computed_status: string | null
          entity_id: string | null
          entity_label: string | null
          entity_type: string | null
          next_review_due_at: string | null
        }
        Relationships: []
      }
      technicians_public: {
        Row: {
          active: boolean | null
          avatar_url: string | null
          certifications: string[] | null
          company_id: string | null
          created_at: string | null
          full_name: string | null
          id: string | null
          specialty: string | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "technicians_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technicians_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_snapshot_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "technicians_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "quality_kpi_timeseries_v"
            referencedColumns: ["company_id"]
          },
          {
            foreignKeyName: "technicians_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "employee_celebrations_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technicians_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technicians_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technicians_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "quality_competency_matrix_v"
            referencedColumns: ["user_id"]
          },
        ]
      }
    }
    Functions: {
      calculate_man_hour_value: {
        Args: {
          _company_id: string
          _hour_type: Database["public"]["Enums"]["time_entry_type"]
          _role_type: Database["public"]["Enums"]["technician_role"]
          _total_hours: number
          _work_type: Database["public"]["Enums"]["work_type"]
        }
        Returns: number
      }
      can_admin_manage_report: { Args: { _task_id: string }; Returns: boolean }
      can_manager_view_role: {
        Args: { _manager_id: string; _target_user_id: string }
        Returns: boolean
      }
      can_tech_view_supervisor: {
        Args: { _supervisor_id: string; _user_id: string }
        Returns: boolean
      }
      can_view_profile: {
        Args: { _profile_id: string; _viewer_id: string }
        Returns: boolean
      }
      cleanup_old_vessel_positions: { Args: never; Returns: undefined }
      generate_time_entries_for_completed_orders: {
        Args: never
        Returns: number
      }
      get_city_distance: {
        Args: { _company_id: string; _from_city: string; _to_city: string }
        Returns: number
      }
      get_company_public_logo: {
        Args: { _company_id: string }
        Returns: {
          id: string
          logo_url: string
          name: string
        }[]
      }
      get_employee_hr_profile: {
        Args: { _user_id: string }
        Returns: {
          company_id: string
          full_name: string
          hire_date: string
          id: string
          status: string
        }[]
      }
      get_employee_pii: {
        Args: { _user_id: string }
        Returns: {
          avatar_url: string
          bio: string
          birth_date: string
          company_id: string
          cover_url: string
          cpf: string
          email: string
          emergency_contact_name: string
          emergency_contact_phone: string
          full_name: string
          gender: string
          height: number
          id: string
          nationality: string
          phone: string
          rg: string
        }[]
      }
      get_onboarding_by_token: {
        Args: { _token: string }
        Returns: {
          access_token: string
          candidate_email: string | null
          candidate_name: string | null
          company_id: string
          completed_at: string | null
          created_at: string | null
          created_by: string
          id: string
          job_application_id: string | null
          notes: string | null
          position_tag: string | null
          started_at: string | null
          status: string
          updated_at: string | null
          user_id: string | null
        }[]
        SetofOptions: {
          from: "*"
          to: "employee_onboarding"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      get_onboarding_doc_types_by_token: {
        Args: { _token: string }
        Returns: {
          company_id: string
          created_at: string | null
          description: string | null
          id: string
          is_required: boolean | null
          name: string
          position_tag: string | null
          sort_order: number | null
        }[]
        SetofOptions: {
          from: "*"
          to: "onboarding_document_types"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      get_technician_availability: {
        Args: { _check_date: string; _technician_id: string }
        Returns: {
          is_available: boolean
          status_description: string
          status_type: string
        }[]
      }
      get_technician_availability_v2: {
        Args: { _check_date: string; _technician_id: string }
        Returns: {
          blocked_by: string
          is_available: boolean
          reservation_id: string
          status_description: string
          status_type: string
        }[]
      }
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      import_historical_time_entries: { Args: never; Returns: number }
      is_assigned_to_visit: {
        Args: { _user_id: string; _visit_id: string }
        Returns: boolean
      }
      is_conversation_participant: {
        Args: { _conversation_id: string; _user_id: string }
        Returns: boolean
      }
      is_department_manager: {
        Args: { _department_id: string; _user_id: string }
        Returns: boolean
      }
      is_hr_in_company: { Args: { _user_id: string }; Returns: boolean }
      is_hr_or_director_in_company: {
        Args: { _company_id: string; _user_id: string }
        Returns: boolean
      }
      is_operational_role: { Args: { _user_id: string }; Returns: boolean }
      is_tech_assigned_to_order: {
        Args: { _service_order_id: string; _user_id: string }
        Returns: boolean
      }
      is_technician_assigned_to_service_order: {
        Args: { _service_order_id: string; _user_id: string }
        Returns: boolean
      }
      is_technician_available: {
        Args: { _check_date: string; _technician_id: string }
        Returns: boolean
      }
      mark_messages_as_read: {
        Args: { _conversation_id: string }
        Returns: undefined
      }
      match_ai_knowledge: {
        Args: {
          match_count?: number
          match_threshold?: number
          p_agent_id?: string
          p_company_id?: string
          query_embedding: string
        }
        Returns: {
          content: string
          id: string
          similarity: number
          source_id: string
        }[]
      }
      quality_accept_auto_suggestion: {
        Args: { p_competency_id: string; p_user_id: string }
        Returns: undefined
      }
      quality_build_review_inputs: {
        Args: { p_review_id: string }
        Returns: undefined
      }
      quality_complaint_to_ncr: {
        Args: { p_complaint_id: string }
        Returns: string
      }
      quality_compute_risk_severity: {
        Args: { p_score: number }
        Returns: string
      }
      quality_device_block_usage: {
        Args: { p_device_id: string }
        Returns: boolean
      }
      quality_device_status_refresh: { Args: never; Returns: undefined }
      quality_generate_alert_notifications: { Args: never; Returns: number }
      quality_generate_training_plans: {
        Args: { p_user_id: string }
        Returns: number
      }
      quality_get_invite_public: {
        Args: { p_token: string }
        Returns: {
          already_responded: boolean
          campaign_id: string
          campaign_name: string
          campaign_status: string
          invite_id: string
        }[]
      }
      quality_int_to_level: {
        Args: { p_int: number }
        Returns: Database["public"]["Enums"]["quality_competency_level"]
      }
      quality_is_master: { Args: { _user_id: string }; Returns: boolean }
      quality_kpi_get_overview: {
        Args: { p_company_id: string }
        Returns: Json
      }
      quality_level_to_int: {
        Args: {
          p_level: Database["public"]["Enums"]["quality_competency_level"]
        }
        Returns: number
      }
      quality_recompute_user_competencies_all: {
        Args: { p_user_id: string }
        Returns: undefined
      }
      quality_recompute_user_competency: {
        Args: { p_competency_id: string; p_user_id: string }
        Returns: undefined
      }
      quality_register_acknowledgement: {
        Args: { p_assignment_id: string; p_ip?: string; p_user_agent?: string }
        Returns: string
      }
      quality_risk_next_code: {
        Args: {
          p_company_id: string
          p_kind: Database["public"]["Enums"]["quality_risk_kind"]
        }
        Returns: string
      }
      quality_seed_safety_document_types: {
        Args: { p_company_id: string }
        Returns: undefined
      }
      quality_set_manual_level: {
        Args: {
          p_competency_id: string
          p_level: Database["public"]["Enums"]["quality_competency_level"]
          p_notes?: string
          p_user_id: string
        }
        Returns: undefined
      }
      quality_submit_satisfaction_response: {
        Args: {
          p_comment: string
          p_csat: number
          p_nps: number
          p_responder_email: string
          p_responder_name: string
          p_token: string
        }
        Returns: string
      }
      quality_supplier_compute_score: {
        Args: { p_evaluation_id: string }
        Returns: undefined
      }
      quality_supplier_next_status: {
        Args: { p_open_critical_incidents: number; p_score: number }
        Returns: Database["public"]["Enums"]["quality_supplier_status"]
      }
      quality_user_has_completed_prerequisites: {
        Args: { p_document_id: string; p_user_id: string }
        Returns: boolean
      }
      quality_user_missing_prerequisites: {
        Args: { p_document_id: string; p_user_id: string }
        Returns: {
          kind: string
          label: string
          ref_id: string
          required_id: string
        }[]
      }
      recalculate_measurement: {
        Args: { p_measurement_id: string }
        Returns: undefined
      }
      search_similar_reports: {
        Args: {
          match_count?: number
          match_threshold?: number
          p_company_id?: string
          query_embedding: string
        }
        Returns: {
          content_text: string
          report_data: Json
          similarity: number
          task_report_id: string
        }[]
      }
      service_order_in_user_company: {
        Args: { p_service_order_id: string; p_user_id: string }
        Returns: boolean
      }
      task_in_user_company: {
        Args: { _task_id: string; _user_id: string }
        Returns: boolean
      }
      update_company_careers_page: {
        Args: {
          _about_text: string
          _about_title: string
          _company_id: string
          _mission: string
          _values: string[]
        }
        Returns: {
          careers_about_text: string
          careers_about_title: string
          careers_mission: string
          careers_values: string[]
        }[]
      }
      update_forecast_actuals: { Args: never; Returns: undefined }
      user_company_id: { Args: { _user_id: string }; Returns: string }
      user_has_corp_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      verify_api_key: {
        Args: { _key: string }
        Returns: {
          company_id: string
          integration_id: string
          scopes: string[]
        }[]
      }
      visit_belongs_to_user_company: {
        Args: { _user_id: string; _visit_id: string }
        Returns: boolean
      }
    }
    Enums: {
      absence_status: "scheduled" | "in_progress" | "completed" | "cancelled"
      absence_type:
        | "vacation"
        | "day_off"
        | "medical_exam"
        | "training"
        | "sick_leave"
        | "other"
        | "home_office"
      app_role:
        | "super_admin"
        | "admin"
        | "technician"
        | "manager"
        | "hr"
        | "commercial"
        | "director"
        | "compras"
        | "qualidade"
        | "financeiro"
        | "coordinator"
        | "marketing"
      complaint_kind: "complaint" | "suggestion"
      complaint_source:
        | "survey"
        | "email"
        | "phone"
        | "in_person"
        | "system"
        | "other"
      complaint_status:
        | "new"
        | "acknowledged"
        | "under_analysis"
        | "resolved"
        | "rejected"
      expense_type: "hospedagem" | "alimentacao"
      measurement_category: "CATIVO" | "LABORATORIO" | "EXTERNO" | "ISENTO"
      measurement_status: "draft" | "finalized"
      notification_type:
        | "task_assignment"
        | "task_update"
        | "report_submitted"
        | "service_order_created"
        | "service_order_updated"
        | "schedule_change"
        | "service_order"
        | "payment_overdue"
        | "new_company"
        | "request_created"
        | "request_approved"
        | "request_rejected"
        | "document_received"
        | "approval_pending"
        | "quality_alert"
      payment_status: "paid" | "pending" | "overdue"
      quality_access_action: "view" | "print" | "download"
      quality_calibration_kind:
        | "internal"
        | "external_lab"
        | "manufacturer"
        | "self_check"
      quality_calibration_result:
        | "approved"
        | "approved_with_restriction"
        | "reproved"
      quality_competency_category:
        | "technical"
        | "behavioral"
        | "regulatory"
        | "safety"
        | "management"
      quality_competency_level:
        | "none"
        | "basic"
        | "intermediate"
        | "advanced"
        | "expert"
      quality_controlled_copy_status:
        | "issued"
        | "returned"
        | "destroyed"
        | "lost"
        | "superseded"
      quality_device_status:
        | "active"
        | "in_calibration"
        | "out_of_service"
        | "retired"
        | "overdue"
      quality_document_content_kind: "rich_text" | "file"
      quality_document_control_mode: "full_control" | "received_only"
      quality_document_status:
        | "draft"
        | "pending_approval"
        | "published"
        | "obsolete"
        | "archived"
      quality_evidence_type:
        | "university_course"
        | "university_trail"
        | "hr_certificate"
        | "acknowledgement"
        | "manual"
      quality_origin:
        | "internal"
        | "client"
        | "external_norm"
        | "external_law"
        | "external_certificate"
        | "safety"
      quality_review_input_type:
        | "previous_actions_status"
        | "external_internal_changes"
        | "qms_performance"
        | "resources_adequacy"
        | "stakeholder_feedback"
        | "improvement_opportunities"
        | "risks_opportunities"
      quality_review_output_status: "open" | "in_progress" | "done"
      quality_review_output_type:
        | "improvement_opportunity"
        | "qms_change"
        | "resource_need"
        | "decision"
      quality_review_participant_role: "chair" | "member" | "guest"
      quality_review_status: "draft" | "in_progress" | "closed"
      quality_risk_action_status: "open" | "in_progress" | "done" | "cancelled"
      quality_risk_kind: "risk" | "opportunity"
      quality_risk_source:
        | "context"
        | "interested_party"
        | "process"
        | "audit"
        | "ncr"
        | "management_review"
        | "manual"
      quality_risk_status:
        | "identified"
        | "analyzing"
        | "treating"
        | "monitoring"
        | "accepted"
        | "closed"
      quality_risk_treatment:
        | "avoid"
        | "mitigate"
        | "transfer"
        | "accept"
        | "exploit"
        | "enhance"
        | "share"
        | "ignore"
      quality_signature_action:
        | "approval"
        | "acknowledgment"
        | "review"
        | "closure"
        | "issuance"
        | "other"
      quality_supplier_category:
        | "material"
        | "service"
        | "calibration"
        | "training"
        | "software"
        | "logistics"
        | "other"
      quality_supplier_criticality: "low" | "medium" | "high" | "critical"
      quality_supplier_evaluation_kind:
        | "initial"
        | "periodic"
        | "incident"
        | "requalification"
      quality_supplier_status:
        | "pending"
        | "approved"
        | "conditional"
        | "suspended"
        | "disqualified"
      quality_training_plan_status:
        | "proposed"
        | "in_progress"
        | "completed"
        | "cancelled"
      satisfaction_campaign_status: "draft" | "active" | "closed"
      satisfaction_target_kind: "all_clients" | "selected"
      service_order_status:
        | "pending"
        | "in_progress"
        | "completed"
        | "cancelled"
      subscription_plan: "basic" | "professional" | "enterprise"
      task_status: "pending" | "in_progress" | "completed" | "cancelled"
      technician_role: "tecnico" | "auxiliar" | "engenheiro" | "supervisor"
      time_entry_type: "work_normal" | "work_extra" | "work_night" | "standby"
      travel_type: "carro_proprio" | "carro_alugado" | "passagem_aerea"
      visit_type: "initial" | "continuation" | "return"
      work_type: "trabalho" | "espera_deslocamento" | "laboratorio"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      absence_status: ["scheduled", "in_progress", "completed", "cancelled"],
      absence_type: [
        "vacation",
        "day_off",
        "medical_exam",
        "training",
        "sick_leave",
        "other",
        "home_office",
      ],
      app_role: [
        "super_admin",
        "admin",
        "technician",
        "manager",
        "hr",
        "commercial",
        "director",
        "compras",
        "qualidade",
        "financeiro",
        "coordinator",
        "marketing",
      ],
      complaint_kind: ["complaint", "suggestion"],
      complaint_source: [
        "survey",
        "email",
        "phone",
        "in_person",
        "system",
        "other",
      ],
      complaint_status: [
        "new",
        "acknowledged",
        "under_analysis",
        "resolved",
        "rejected",
      ],
      expense_type: ["hospedagem", "alimentacao"],
      measurement_category: ["CATIVO", "LABORATORIO", "EXTERNO", "ISENTO"],
      measurement_status: ["draft", "finalized"],
      notification_type: [
        "task_assignment",
        "task_update",
        "report_submitted",
        "service_order_created",
        "service_order_updated",
        "schedule_change",
        "service_order",
        "payment_overdue",
        "new_company",
        "request_created",
        "request_approved",
        "request_rejected",
        "document_received",
        "approval_pending",
        "quality_alert",
      ],
      payment_status: ["paid", "pending", "overdue"],
      quality_access_action: ["view", "print", "download"],
      quality_calibration_kind: [
        "internal",
        "external_lab",
        "manufacturer",
        "self_check",
      ],
      quality_calibration_result: [
        "approved",
        "approved_with_restriction",
        "reproved",
      ],
      quality_competency_category: [
        "technical",
        "behavioral",
        "regulatory",
        "safety",
        "management",
      ],
      quality_competency_level: [
        "none",
        "basic",
        "intermediate",
        "advanced",
        "expert",
      ],
      quality_controlled_copy_status: [
        "issued",
        "returned",
        "destroyed",
        "lost",
        "superseded",
      ],
      quality_device_status: [
        "active",
        "in_calibration",
        "out_of_service",
        "retired",
        "overdue",
      ],
      quality_document_content_kind: ["rich_text", "file"],
      quality_document_control_mode: ["full_control", "received_only"],
      quality_document_status: [
        "draft",
        "pending_approval",
        "published",
        "obsolete",
        "archived",
      ],
      quality_evidence_type: [
        "university_course",
        "university_trail",
        "hr_certificate",
        "acknowledgement",
        "manual",
      ],
      quality_origin: [
        "internal",
        "client",
        "external_norm",
        "external_law",
        "external_certificate",
        "safety",
      ],
      quality_review_input_type: [
        "previous_actions_status",
        "external_internal_changes",
        "qms_performance",
        "resources_adequacy",
        "stakeholder_feedback",
        "improvement_opportunities",
        "risks_opportunities",
      ],
      quality_review_output_status: ["open", "in_progress", "done"],
      quality_review_output_type: [
        "improvement_opportunity",
        "qms_change",
        "resource_need",
        "decision",
      ],
      quality_review_participant_role: ["chair", "member", "guest"],
      quality_review_status: ["draft", "in_progress", "closed"],
      quality_risk_action_status: ["open", "in_progress", "done", "cancelled"],
      quality_risk_kind: ["risk", "opportunity"],
      quality_risk_source: [
        "context",
        "interested_party",
        "process",
        "audit",
        "ncr",
        "management_review",
        "manual",
      ],
      quality_risk_status: [
        "identified",
        "analyzing",
        "treating",
        "monitoring",
        "accepted",
        "closed",
      ],
      quality_risk_treatment: [
        "avoid",
        "mitigate",
        "transfer",
        "accept",
        "exploit",
        "enhance",
        "share",
        "ignore",
      ],
      quality_signature_action: [
        "approval",
        "acknowledgment",
        "review",
        "closure",
        "issuance",
        "other",
      ],
      quality_supplier_category: [
        "material",
        "service",
        "calibration",
        "training",
        "software",
        "logistics",
        "other",
      ],
      quality_supplier_criticality: ["low", "medium", "high", "critical"],
      quality_supplier_evaluation_kind: [
        "initial",
        "periodic",
        "incident",
        "requalification",
      ],
      quality_supplier_status: [
        "pending",
        "approved",
        "conditional",
        "suspended",
        "disqualified",
      ],
      quality_training_plan_status: [
        "proposed",
        "in_progress",
        "completed",
        "cancelled",
      ],
      satisfaction_campaign_status: ["draft", "active", "closed"],
      satisfaction_target_kind: ["all_clients", "selected"],
      service_order_status: [
        "pending",
        "in_progress",
        "completed",
        "cancelled",
      ],
      subscription_plan: ["basic", "professional", "enterprise"],
      task_status: ["pending", "in_progress", "completed", "cancelled"],
      technician_role: ["tecnico", "auxiliar", "engenheiro", "supervisor"],
      time_entry_type: ["work_normal", "work_extra", "work_night", "standby"],
      travel_type: ["carro_proprio", "carro_alugado", "passagem_aerea"],
      visit_type: ["initial", "continuation", "return"],
      work_type: ["trabalho", "espera_deslocamento", "laboratorio"],
    },
  },
} as const
