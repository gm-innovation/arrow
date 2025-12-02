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
        ]
      }
      clients: {
        Row: {
          address: string | null
          cnpj: string | null
          company_id: string
          contact_person: string | null
          created_at: string
          email: string | null
          id: string
          name: string
          phone: string | null
          updated_at: string
        }
        Insert: {
          address?: string | null
          cnpj?: string | null
          company_id: string
          contact_person?: string | null
          created_at?: string
          email?: string | null
          id?: string
          name: string
          phone?: string | null
          updated_at?: string
        }
        Update: {
          address?: string | null
          cnpj?: string | null
          company_id?: string
          contact_person?: string | null
          created_at?: string
          email?: string | null
          id?: string
          name?: string
          phone?: string | null
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
        ]
      }
      companies: {
        Row: {
          address: string | null
          cep: string | null
          cnpj: string | null
          created_at: string
          email: string | null
          id: string
          logo_url: string | null
          name: string
          payment_status: Database["public"]["Enums"]["payment_status"] | null
          phone: string | null
          subscription_plan:
            | Database["public"]["Enums"]["subscription_plan"]
            | null
          updated_at: string
        }
        Insert: {
          address?: string | null
          cep?: string | null
          cnpj?: string | null
          created_at?: string
          email?: string | null
          id?: string
          logo_url?: string | null
          name: string
          payment_status?: Database["public"]["Enums"]["payment_status"] | null
          phone?: string | null
          subscription_plan?:
            | Database["public"]["Enums"]["subscription_plan"]
            | null
          updated_at?: string
        }
        Update: {
          address?: string | null
          cep?: string | null
          cnpj?: string | null
          created_at?: string
          email?: string | null
          id?: string
          logo_url?: string | null
          name?: string
          payment_status?: Database["public"]["Enums"]["payment_status"] | null
          phone?: string | null
          subscription_plan?:
            | Database["public"]["Enums"]["subscription_plan"]
            | null
          updated_at?: string
        }
        Relationships: []
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
            foreignKeyName: "conversations_service_order_id_fkey"
            columns: ["service_order_id"]
            isOneToOne: false
            referencedRelation: "service_orders"
            referencedColumns: ["id"]
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
            foreignKeyName: "forecast_history_coordinator_id_fkey"
            columns: ["coordinator_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
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
        ]
      }
      measurement_materials: {
        Row: {
          created_at: string | null
          id: string
          markup_percentage: number | null
          measurement_id: string
          name: string
          quantity: number
          stock_item_id: string | null
          total_value: number
          unit_value: number
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          markup_percentage?: number | null
          measurement_id: string
          name: string
          quantity: number
          stock_item_id?: string | null
          total_value: number
          unit_value: number
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          markup_percentage?: number | null
          measurement_id?: string
          name?: string
          quantity?: number
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
          technician_id: string
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
          technician_id: string
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
          technician_id?: string
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
            foreignKeyName: "productivity_snapshots_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          company_id: string | null
          created_at: string
          email: string
          full_name: string
          id: string
          phone: string | null
          updated_at: string
        }
        Insert: {
          avatar_url?: string | null
          company_id?: string | null
          created_at?: string
          email: string
          full_name: string
          id: string
          phone?: string | null
          updated_at?: string
        }
        Update: {
          avatar_url?: string | null
          company_id?: string | null
          created_at?: string
          email?: string
          full_name?: string
          id?: string
          phone?: string | null
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
          client_id: string | null
          company_id: string
          completed_date: string | null
          created_at: string
          created_by: string
          description: string | null
          id: string
          location: string | null
          order_number: string
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
          client_id?: string | null
          company_id: string
          completed_date?: string | null
          created_at?: string
          created_by: string
          description?: string | null
          id?: string
          location?: string | null
          order_number: string
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
          client_id?: string | null
          company_id?: string
          completed_date?: string | null
          created_at?: string
          created_by?: string
          description?: string | null
          id?: string
          location?: string | null
          order_number?: string
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
            foreignKeyName: "service_orders_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
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
            referencedRelation: "profiles"
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
            foreignKeyName: "service_visits_service_order_id_fkey"
            columns: ["service_order_id"]
            isOneToOne: false
            referencedRelation: "service_orders"
            referencedColumns: ["id"]
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
          status?: string
          task_id?: string
          task_uuid?: string | null
          updated_at?: string
          visit_id?: string | null
        }
        Relationships: [
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
      task_types: {
        Row: {
          category: string | null
          company_id: string
          created_at: string
          description: string | null
          id: string
          name: string
          photo_labels: string[] | null
          steps: string[] | null
          tools: string[] | null
          updated_at: string
        }
        Insert: {
          category?: string | null
          company_id: string
          created_at?: string
          description?: string | null
          id?: string
          name: string
          photo_labels?: string[] | null
          steps?: string[] | null
          tools?: string[] | null
          updated_at?: string
        }
        Update: {
          category?: string | null
          company_id?: string
          created_at?: string
          description?: string | null
          id?: string
          name?: string
          photo_labels?: string[] | null
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
        ]
      }
      tasks: {
        Row: {
          assigned_to: string | null
          completed_at: string | null
          created_at: string
          description: string | null
          due_date: string | null
          id: string
          priority: number | null
          service_order_id: string
          status: Database["public"]["Enums"]["task_status"] | null
          task_type_id: string | null
          title: string
          updated_at: string
        }
        Insert: {
          assigned_to?: string | null
          completed_at?: string | null
          created_at?: string
          description?: string | null
          due_date?: string | null
          id?: string
          priority?: number | null
          service_order_id: string
          status?: Database["public"]["Enums"]["task_status"] | null
          task_type_id?: string | null
          title: string
          updated_at?: string
        }
        Update: {
          assigned_to?: string | null
          completed_at?: string | null
          created_at?: string
          description?: string | null
          due_date?: string | null
          id?: string
          priority?: number | null
          service_order_id?: string
          status?: Database["public"]["Enums"]["task_status"] | null
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
            foreignKeyName: "technicians_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      time_entries: {
        Row: {
          created_at: string
          end_time: string
          entry_date: string
          entry_type: Database["public"]["Enums"]["time_entry_type"]
          id: string
          start_time: string
          task_id: string
          technician_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          end_time: string
          entry_date: string
          entry_type: Database["public"]["Enums"]["time_entry_type"]
          id?: string
          start_time: string
          task_id: string
          technician_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          end_time?: string
          entry_date?: string
          entry_type?: Database["public"]["Enums"]["time_entry_type"]
          id?: string
          start_time?: string
          task_id?: string
          technician_id?: string
          updated_at?: string
        }
        Relationships: [
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
      vessels: {
        Row: {
          client_id: string
          created_at: string
          flag: string | null
          id: string
          imo_number: string | null
          name: string
          updated_at: string
          vessel_type: string | null
          year_built: number | null
        }
        Insert: {
          client_id: string
          created_at?: string
          flag?: string | null
          id?: string
          imo_number?: string | null
          name: string
          updated_at?: string
          vessel_type?: string | null
          year_built?: number | null
        }
        Update: {
          client_id?: string
          created_at?: string
          flag?: string | null
          id?: string
          imo_number?: string | null
          name?: string
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
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "visit_technicians_technician_id_fkey"
            columns: ["technician_id"]
            isOneToOne: false
            referencedRelation: "technicians"
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
    }
    Views: {
      [_ in never]: never
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
      can_view_profile: {
        Args: { _profile_id: string; _viewer_id: string }
        Returns: boolean
      }
      get_city_distance: {
        Args: { _company_id: string; _from_city: string; _to_city: string }
        Returns: number
      }
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      is_assigned_to_visit: {
        Args: { _user_id: string; _visit_id: string }
        Returns: boolean
      }
      is_conversation_participant: {
        Args: { _conversation_id: string; _user_id: string }
        Returns: boolean
      }
      mark_messages_as_read: {
        Args: { _conversation_id: string }
        Returns: undefined
      }
      update_forecast_actuals: { Args: never; Returns: undefined }
      user_company_id: { Args: { _user_id: string }; Returns: string }
      visit_belongs_to_user_company: {
        Args: { _user_id: string; _visit_id: string }
        Returns: boolean
      }
    }
    Enums: {
      app_role: "super_admin" | "admin" | "technician" | "manager"
      expense_type: "hospedagem" | "alimentacao"
      measurement_category: "CATIVO" | "LABORATORIO" | "EXTERNO"
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
      payment_status: "paid" | "pending" | "overdue"
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
      app_role: ["super_admin", "admin", "technician", "manager"],
      expense_type: ["hospedagem", "alimentacao"],
      measurement_category: ["CATIVO", "LABORATORIO", "EXTERNO"],
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
      ],
      payment_status: ["paid", "pending", "overdue"],
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
