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
          technician_id: string
          template_id: string
          updated_at: string
        }
        Insert: {
          completed_at?: string | null
          created_at?: string
          id?: string
          task_id: string
          technician_id: string
          template_id: string
          updated_at?: string
        }
        Update: {
          completed_at?: string | null
          created_at?: string
          id?: string
          task_id?: string
          technician_id?: string
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
        ]
      }
      client_contacts: {
        Row: {
          client_id: string
          created_at: string
          email: string | null
          id: string
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
            foreignKeyName: "company_holidays_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
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
          technician_id: string
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
          technician_id: string
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
          technician_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "hr_time_adjustments_adjusted_by_fkey"
            columns: ["adjusted_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "hr_time_adjustments_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
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
          company_id: string
          completed_date: string | null
          created_at: string
          created_by: string
          description: string | null
          expected_context: string | null
          id: string
          location: string | null
          order_number: string
          planned_location: string | null
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
          company_id: string
          completed_date?: string | null
          created_at?: string
          created_by: string
          description?: string | null
          expected_context?: string | null
          id?: string
          location?: string | null
          order_number: string
          planned_location?: string | null
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
          company_id?: string
          completed_date?: string | null
          created_at?: string
          created_by?: string
          description?: string | null
          expected_context?: string | null
          id?: string
          location?: string | null
          order_number?: string
          planned_location?: string | null
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
          due_date?: string | null
          id?: string
          priority?: number | null
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
          due_date?: string | null
          id?: string
          priority?: number | null
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
          technician_id: string
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
          technician_id: string
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
          technician_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "technician_absences_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "technician_absences_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
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
          technician_id: string
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
          technician_id: string
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
          technician_id?: string
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
            foreignKeyName: "technician_on_call_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
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
          technician_id: string
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
          technician_id: string
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
          technician_id?: string
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
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
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
            foreignKeyName: "technicians_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
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
      get_technician_availability: {
        Args: { _check_date: string; _technician_id: string }
        Returns: {
          is_available: boolean
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
      is_tech_assigned_to_order: {
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
      update_forecast_actuals: { Args: never; Returns: undefined }
      user_company_id: { Args: { _user_id: string }; Returns: string }
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
      app_role: "super_admin" | "admin" | "technician" | "manager" | "hr"
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
      absence_status: ["scheduled", "in_progress", "completed", "cancelled"],
      absence_type: [
        "vacation",
        "day_off",
        "medical_exam",
        "training",
        "sick_leave",
        "other",
      ],
      app_role: ["super_admin", "admin", "technician", "manager", "hr"],
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
