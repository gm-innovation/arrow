-- Create enums
CREATE TYPE public.app_role AS ENUM ('super_admin', 'admin', 'technician');
CREATE TYPE public.task_status AS ENUM ('pending', 'in_progress', 'completed', 'cancelled');
CREATE TYPE public.service_order_status AS ENUM ('pending', 'in_progress', 'completed', 'cancelled');
CREATE TYPE public.notification_type AS ENUM ('task_assignment', 'task_update', 'report_submitted', 'service_order_created', 'service_order_updated');
CREATE TYPE public.time_entry_type AS ENUM ('work_normal', 'work_extra', 'work_night', 'standby');
CREATE TYPE public.payment_status AS ENUM ('paid', 'pending', 'overdue');
CREATE TYPE public.subscription_plan AS ENUM ('basic', 'professional', 'enterprise');

-- Create companies table
CREATE TABLE public.companies (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  address TEXT,
  subscription_plan public.subscription_plan DEFAULT 'basic',
  payment_status public.payment_status DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create profiles table
CREATE TABLE public.profiles (
  id UUID NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  avatar_url TEXT,
  company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create user_roles table
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role public.app_role NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

-- Create clients table
CREATE TABLE public.clients (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  address TEXT,
  contact_person TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create vessels table
CREATE TABLE public.vessels (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  client_id UUID REFERENCES public.clients(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  vessel_type TEXT,
  imo_number TEXT,
  flag TEXT,
  year_built INTEGER,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create technicians table
CREATE TABLE public.technicians (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  specialty TEXT,
  certifications TEXT[],
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create task_types table
CREATE TABLE public.task_types (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  category TEXT,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create service_orders table
CREATE TABLE public.service_orders (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  order_number TEXT NOT NULL UNIQUE,
  vessel_id UUID REFERENCES public.vessels(id) ON DELETE SET NULL,
  client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
  supervisor_id UUID REFERENCES public.technicians(id) ON DELETE SET NULL,
  status public.service_order_status DEFAULT 'pending',
  description TEXT,
  scheduled_date DATE,
  completed_date DATE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create tasks table
CREATE TABLE public.tasks (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  service_order_id UUID REFERENCES public.service_orders(id) ON DELETE CASCADE NOT NULL,
  task_type_id UUID REFERENCES public.task_types(id) ON DELETE SET NULL,
  assigned_to UUID REFERENCES public.technicians(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  status public.task_status DEFAULT 'pending',
  priority INTEGER DEFAULT 0,
  due_date DATE,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create time_entries table
CREATE TABLE public.time_entries (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE NOT NULL,
  technician_id UUID REFERENCES public.technicians(id) ON DELETE CASCADE NOT NULL,
  entry_type public.time_entry_type NOT NULL,
  entry_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create notifications table
CREATE TABLE public.notifications (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  notification_type public.notification_type NOT NULL,
  title TEXT NOT NULL,
  message TEXT,
  reference_id UUID,
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create service_history table
CREATE TABLE public.service_history (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  service_order_id UUID REFERENCES public.service_orders(id) ON DELETE CASCADE NOT NULL,
  vessel_id UUID REFERENCES public.vessels(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  description TEXT,
  performed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Update task_reports to reference tasks
ALTER TABLE public.task_reports 
  ADD COLUMN IF NOT EXISTS task_uuid UUID REFERENCES public.tasks(id) ON DELETE CASCADE;

-- Create security definer function for role checking
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role public.app_role)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id
      AND role = _role
  )
$$;

-- Create function to check if user belongs to company
CREATE OR REPLACE FUNCTION public.user_company_id(_user_id UUID)
RETURNS UUID
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT company_id FROM public.profiles WHERE id = _user_id
$$;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Function to handle new user profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    NEW.email
  );
  RETURN NEW;
END;
$$;

-- Create trigger for new user profile
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create triggers for updated_at
CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON public.companies FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_vessels_updated_at BEFORE UPDATE ON public.vessels FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_technicians_updated_at BEFORE UPDATE ON public.technicians FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_task_types_updated_at BEFORE UPDATE ON public.task_types FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_service_orders_updated_at BEFORE UPDATE ON public.service_orders FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER update_time_entries_updated_at BEFORE UPDATE ON public.time_entries FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Enable RLS on all tables
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vessels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technicians ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.time_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies for companies
CREATE POLICY "Super admins can view all companies" ON public.companies FOR SELECT USING (public.has_role(auth.uid(), 'super_admin'));
CREATE POLICY "Users can view their own company" ON public.companies FOR SELECT USING (id = public.user_company_id(auth.uid()));
CREATE POLICY "Super admins can manage companies" ON public.companies FOR ALL USING (public.has_role(auth.uid(), 'super_admin'));

-- RLS Policies for profiles
CREATE POLICY "Users can view profiles in their company" ON public.profiles FOR SELECT USING (company_id = public.user_company_id(auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (id = auth.uid());
CREATE POLICY "Admins can manage profiles in their company" ON public.profiles FOR ALL USING (public.has_role(auth.uid(), 'admin') AND company_id = public.user_company_id(auth.uid()));
CREATE POLICY "Super admins can manage all profiles" ON public.profiles FOR ALL USING (public.has_role(auth.uid(), 'super_admin'));

-- RLS Policies for user_roles
CREATE POLICY "Users can view their own roles" ON public.user_roles FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Super admins can manage all roles" ON public.user_roles FOR ALL USING (public.has_role(auth.uid(), 'super_admin'));
CREATE POLICY "Admins can manage roles in their company" ON public.user_roles FOR ALL USING (public.has_role(auth.uid(), 'admin'));

-- RLS Policies for clients
CREATE POLICY "Users can view clients in their company" ON public.clients FOR SELECT USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY "Admins can manage clients in their company" ON public.clients FOR ALL USING (public.has_role(auth.uid(), 'admin') AND company_id = public.user_company_id(auth.uid()));

-- RLS Policies for vessels
CREATE POLICY "Users can view vessels in their company" ON public.vessels FOR SELECT USING (EXISTS (SELECT 1 FROM public.clients WHERE id = vessels.client_id AND company_id = public.user_company_id(auth.uid())));
CREATE POLICY "Admins can manage vessels in their company" ON public.vessels FOR ALL USING (EXISTS (SELECT 1 FROM public.clients WHERE id = vessels.client_id AND company_id = public.user_company_id(auth.uid())) AND public.has_role(auth.uid(), 'admin'));

-- RLS Policies for technicians
CREATE POLICY "Users can view technicians in their company" ON public.technicians FOR SELECT USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY "Technicians can view their own data" ON public.technicians FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Admins can manage technicians in their company" ON public.technicians FOR ALL USING (public.has_role(auth.uid(), 'admin') AND company_id = public.user_company_id(auth.uid()));

-- RLS Policies for task_types
CREATE POLICY "Users can view task types in their company" ON public.task_types FOR SELECT USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY "Admins can manage task types in their company" ON public.task_types FOR ALL USING (public.has_role(auth.uid(), 'admin') AND company_id = public.user_company_id(auth.uid()));

-- RLS Policies for service_orders
CREATE POLICY "Users can view service orders in their company" ON public.service_orders FOR SELECT USING (company_id = public.user_company_id(auth.uid()));
CREATE POLICY "Admins can manage service orders in their company" ON public.service_orders FOR ALL USING (public.has_role(auth.uid(), 'admin') AND company_id = public.user_company_id(auth.uid()));

-- RLS Policies for tasks
CREATE POLICY "Users can view tasks in their company" ON public.tasks FOR SELECT USING (EXISTS (SELECT 1 FROM public.service_orders WHERE id = tasks.service_order_id AND company_id = public.user_company_id(auth.uid())));
CREATE POLICY "Technicians can view their assigned tasks" ON public.tasks FOR SELECT USING (EXISTS (SELECT 1 FROM public.technicians WHERE id = tasks.assigned_to AND user_id = auth.uid()));
CREATE POLICY "Admins can manage tasks in their company" ON public.tasks FOR ALL USING (EXISTS (SELECT 1 FROM public.service_orders WHERE id = tasks.service_order_id AND company_id = public.user_company_id(auth.uid())) AND public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Technicians can update their assigned tasks" ON public.tasks FOR UPDATE USING (EXISTS (SELECT 1 FROM public.technicians WHERE id = tasks.assigned_to AND user_id = auth.uid()));

-- RLS Policies for time_entries
CREATE POLICY "Users can view time entries in their company" ON public.time_entries FOR SELECT USING (EXISTS (SELECT 1 FROM public.tasks JOIN public.service_orders ON tasks.service_order_id = service_orders.id WHERE tasks.id = time_entries.task_id AND service_orders.company_id = public.user_company_id(auth.uid())));
CREATE POLICY "Technicians can manage their own time entries" ON public.time_entries FOR ALL USING (EXISTS (SELECT 1 FROM public.technicians WHERE id = time_entries.technician_id AND user_id = auth.uid()));
CREATE POLICY "Admins can manage time entries in their company" ON public.time_entries FOR ALL USING (EXISTS (SELECT 1 FROM public.tasks JOIN public.service_orders ON tasks.service_order_id = service_orders.id WHERE tasks.id = time_entries.task_id AND service_orders.company_id = public.user_company_id(auth.uid())) AND public.has_role(auth.uid(), 'admin'));

-- RLS Policies for notifications
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can update their own notifications" ON public.notifications FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "System can create notifications" ON public.notifications FOR INSERT WITH CHECK (true);

-- RLS Policies for service_history
CREATE POLICY "Users can view service history in their company" ON public.service_history FOR SELECT USING (EXISTS (SELECT 1 FROM public.service_orders WHERE id = service_history.service_order_id AND company_id = public.user_company_id(auth.uid())));
CREATE POLICY "System can create service history" ON public.service_history FOR INSERT WITH CHECK (true);

-- Update task_reports RLS policies to be more specific
DROP POLICY IF EXISTS "Users can view their own task reports" ON public.task_reports;
DROP POLICY IF EXISTS "Users can create their own task reports" ON public.task_reports;
DROP POLICY IF EXISTS "Users can update their own task reports" ON public.task_reports;
DROP POLICY IF EXISTS "Users can delete their own task reports" ON public.task_reports;

CREATE POLICY "Users can view task reports in their company" ON public.task_reports FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.tasks 
    JOIN public.service_orders ON tasks.service_order_id = service_orders.id 
    WHERE tasks.id::text = task_reports.task_id 
    AND service_orders.company_id = public.user_company_id(auth.uid())
  )
);

CREATE POLICY "Technicians can create reports for their tasks" ON public.task_reports FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.tasks 
    JOIN public.technicians ON tasks.assigned_to = technicians.id
    WHERE tasks.id::text = task_reports.task_id 
    AND technicians.user_id = auth.uid()
  )
);

CREATE POLICY "Technicians can update their own reports" ON public.task_reports FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.tasks 
    JOIN public.technicians ON tasks.assigned_to = technicians.id
    WHERE tasks.id::text = task_reports.task_id 
    AND technicians.user_id = auth.uid()
  )
);

CREATE POLICY "Admins can manage reports in their company" ON public.task_reports FOR ALL USING (
  public.has_role(auth.uid(), 'admin') AND
  EXISTS (
    SELECT 1 FROM public.tasks 
    JOIN public.service_orders ON tasks.service_order_id = service_orders.id 
    WHERE tasks.id::text = task_reports.task_id 
    AND service_orders.company_id = public.user_company_id(auth.uid())
  )
);