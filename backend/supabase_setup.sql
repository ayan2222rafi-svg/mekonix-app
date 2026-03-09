-- Create profiles table
CREATE TABLE profiles (
  id uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name text,
  avatar_url text,
  role text CHECK (role IN ('student', 'tutor')) DEFAULT 'student',
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
CREATE POLICY "Public profiles are viewable by everyone." ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile." ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile." ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Create tutors table
CREATE TABLE tutors (
  id uuid REFERENCES profiles(id) ON DELETE CASCADE PRIMARY KEY,
  bio text,
  rate_per_hour numeric,
  location text,
  experience_years int,
  rating numeric DEFAULT 0,
  reviews_count int DEFAULT 0,
  is_featured boolean DEFAULT false,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for tutors
ALTER TABLE tutors ENABLE ROW LEVEL SECURITY;

-- Tutors Policies
CREATE POLICY "All tutors are viewable by everyone." ON tutors
  FOR SELECT USING (true);

CREATE POLICY "Tutors can update own record." ON tutors
  FOR UPDATE USING (auth.uid() = id);

-- Create subjects table
CREATE TABLE subjects (
  id serial PRIMARY KEY,
  name text UNIQUE NOT NULL,
  category text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for subjects
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;

-- Subjects Policies
CREATE POLICY "Subjects are viewable by everyone." ON subjects
  FOR SELECT USING (true);

-- Create tutor_subjects junction table
CREATE TABLE tutor_subjects (
  tutor_id uuid REFERENCES tutors(id) ON DELETE CASCADE NOT NULL,
  subject_id int REFERENCES subjects(id) ON DELETE CASCADE NOT NULL,
  PRIMARY KEY (tutor_id, subject_id)
);

-- Enable RLS for tutor_subjects
ALTER TABLE tutor_subjects ENABLE ROW LEVEL SECURITY;

-- Tutor Subjects Policies
CREATE POLICY "Tutor subjects are viewable by everyone." ON tutor_subjects
  FOR SELECT USING (true);

-- Seed subjects
INSERT INTO subjects (name, category) VALUES
  ('Mathematics', 'Academic'),
  ('Physics', 'Academic'),
  ('Chemistry', 'Academic'),
  ('Biology', 'Academic'),
  ('English Literature', 'Academic'),
  ('Computer Science', 'Technical'),
  ('History', 'Humanities'),
  ('Geography', 'Humanities'),
  ('Spanish Language', 'Languages'),
  ('Music Theory', 'Art & Music'),
  ('Art & Design', 'Art & Music'),
  ('Test Prep', 'Academic')
ON CONFLICT (name) DO NOTHING;

-- Function to handle new user profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call handle_new_user on signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
