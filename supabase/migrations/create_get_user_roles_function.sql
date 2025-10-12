-- RPC function to get all roles for a user in a single call
-- This is much more efficient than making 3 separate REST API calls

CREATE OR REPLACE FUNCTION public.get_user_roles(user_email text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result jsonb := '{}';
  admin_rec record;
  warden_rec record;
  arch_gate_rec record;
BEGIN
  -- Check admin table
  SELECT id, email, role, hostels INTO admin_rec
  FROM public.admins
  WHERE LOWER(email) = LOWER(user_email);
  
  IF FOUND THEN
    result := jsonb_set(result, '{admin}', jsonb_build_object(
      'id', admin_rec.id,
      'email', admin_rec.email,
      'role', admin_rec.role,
      'hostels', COALESCE(admin_rec.hostels, '[]'::jsonb)
    ));
  END IF;

  -- Check wardens table
  SELECT id, email, hostels INTO warden_rec
  FROM public.wardens
  WHERE LOWER(email) = LOWER(user_email);
  
  IF FOUND THEN
    result := jsonb_set(result, '{warden}', jsonb_build_object(
      'id', warden_rec.id,
      'email', warden_rec.email,
      'hostels', COALESCE(warden_rec.hostels, '[]'::jsonb)
    ));
  END IF;

  -- Check arch_gate table (columns: id, email, display_name, created_at, updated_at)
  -- Note: arch_gate does NOT have 'role' or 'phone' columns
  SELECT id, email, display_name INTO arch_gate_rec
  FROM public.arch_gate
  WHERE LOWER(email) = LOWER(user_email);
  
  IF FOUND THEN
    result := jsonb_set(result, '{arch_gate}', jsonb_build_object(
      'id', arch_gate_rec.id,
      'email', arch_gate_rec.email,
      'display_name', arch_gate_rec.display_name
    ));
  END IF;

  RETURN result;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_user_roles(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_roles(text) TO anon;

COMMENT ON FUNCTION public.get_user_roles(text) IS 'Get all roles for a user (admin, warden, arch_gate) in a single call';
