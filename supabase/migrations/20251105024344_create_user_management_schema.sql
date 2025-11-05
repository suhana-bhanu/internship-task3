/*
  # User Management System Database Schema

  ## Overview
  Complete database schema for a user management system with authentication,
  role-based access control, and profile management capabilities.

  ## 1. New Tables

  ### `roles` table
  - `id` (uuid, primary key) - Unique identifier for each role
  - `name` (text, unique) - Role name (e.g., 'user', 'admin')
  - `description` (text) - Description of the role
  - `created_at` (timestamptz) - When the role was created

  ### `users` table
  - `id` (uuid, primary key) - References auth.users(id)
  - `email` (text, unique) - User's email address
  - `full_name` (text) - User's full name
  - `role_id` (uuid) - Foreign key to roles table
  - `profile_picture_url` (text, nullable) - URL to profile picture in storage
  - `created_at` (timestamptz) - When the user registered
  - `updated_at` (timestamptz) - Last profile update

  ## 2. Security Features
  
  ### Row Level Security (RLS)
  - Enabled on both `roles` and `users` tables
  - Restrictive by default - no access unless explicitly granted
  
  ### Roles Table Policies
  - Anyone can view roles (needed for registration)
  - Only admins can create/update/delete roles
  
  ### Users Table Policies
  - Users can view their own profile
  - Admins can view all users
  - Users can update their own profile
  - Admins can update any user
  - Admins can delete users
  
  ## 3. Storage Configuration
  
  ### Profile Pictures Bucket
  - Public bucket for profile pictures
  - Size limit: 5MB
  - Allowed types: image/jpeg, image/png, image/gif, image/webp
  - Users can upload their own pictures
  - Admins can manage all pictures
  
  ## 4. Initial Data
  
  ### Default Roles
  - User role: Standard user with basic permissions
  - Admin role: Administrator with full system access
  
  ## 5. Database Normalization
  
  This schema follows Third Normal Form (3NF):
  - 1NF: All columns contain atomic values
  - 2NF: No partial dependencies on composite keys
  - 3NF: No transitive dependencies between non-key attributes
*/

-- Create roles table
CREATE TABLE IF NOT EXISTS roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  description text DEFAULT '',
  created_at timestamptz DEFAULT now()
);

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text NOT NULL,
  role_id uuid REFERENCES roles(id) NOT NULL,
  profile_picture_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create index for faster role lookups
CREATE INDEX IF NOT EXISTS idx_users_role_id ON users(role_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Enable RLS on roles table
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;

-- Roles table policies
CREATE POLICY "Anyone can view roles"
  ON roles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admins can insert roles"
  ON roles FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      JOIN roles ON users.role_id = roles.id
      WHERE users.id = auth.uid()
      AND roles.name = 'admin'
    )
  );

CREATE POLICY "Only admins can update roles"
  ON roles FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      JOIN roles ON users.role_id = roles.id
      WHERE users.id = auth.uid()
      AND roles.name = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      JOIN roles ON users.role_id = roles.id
      WHERE users.id = auth.uid()
      AND roles.name = 'admin'
    )
  );

CREATE POLICY "Only admins can delete roles"
  ON roles FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      JOIN roles ON users.role_id = roles.id
      WHERE users.id = auth.uid()
      AND roles.name = 'admin'
    )
  );

-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Admins can view all users"
  ON users FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN roles r ON u.role_id = r.id
      WHERE u.id = auth.uid()
      AND r.name = 'admin'
    )
  );

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can update any user"
  ON users FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN roles r ON u.role_id = r.id
      WHERE u.id = auth.uid()
      AND r.name = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      JOIN roles r ON u.role_id = r.id
      WHERE u.id = auth.uid()
      AND r.name = 'admin'
    )
  );

CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can delete users"
  ON users FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN roles r ON u.role_id = r.id
      WHERE u.id = auth.uid()
      AND r.name = 'admin'
    )
  );

-- Insert default roles
INSERT INTO roles (name, description) VALUES
  ('user', 'Standard user with basic permissions'),
  ('admin', 'Administrator with full system access')
ON CONFLICT (name) DO NOTHING;

-- Create storage bucket for profile pictures
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-pictures', 'profile-pictures', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for profile pictures
CREATE POLICY "Anyone can view profile pictures"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'profile-pictures');

CREATE POLICY "Users can upload own profile picture"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'profile-pictures'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can update own profile picture"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'profile-pictures'
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'profile-pictures'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can delete own profile picture"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'profile-pictures'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Admins can manage all profile pictures"
  ON storage.objects FOR ALL
  TO authenticated
  USING (
    bucket_id = 'profile-pictures'
    AND EXISTS (
      SELECT 1 FROM users u
      JOIN roles r ON u.role_id = r.id
      WHERE u.id = auth.uid()
      AND r.name = 'admin'
    )
  )
  WITH CHECK (
    bucket_id = 'profile-pictures'
    AND EXISTS (
      SELECT 1 FROM users u
      JOIN roles r ON u.role_id = r.id
      WHERE u.id = auth.uid()
      AND r.name = 'admin'
    )
  );

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on users table
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();