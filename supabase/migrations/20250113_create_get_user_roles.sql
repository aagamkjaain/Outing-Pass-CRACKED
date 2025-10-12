-- Create get_user_roles function for JWT-based role detection
-- Returns all role information for a user in a single RPC call

CREATE OR REPLACE FUNCTION get_user_roles(user_email text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result jsonb := '{}';
  admin_record record;
  warden_record record;
  arch_gate_record record;
BEGIN
  -- Check admin role
  SELECT id, email, role, hostels INTO admin_record
  FROM admins
  WHERE email = lower(user_email)
  LIMIT 1;

  IF FOUND THEN
    result := jsonb_set(result, '{admin}', jsonb_build_object(
      'id', admin_record.id,
      'email', admin_record.email,
      'role', admin_record.role,
      'hostels', COALESCE(admin_record.hostels, ARRAY[]::text[])
    ));
  END IF;

  -- Check warden role
  SELECT id, email, hostels INTO warden_record
  FROM wardens
  WHERE email = lower(user_email)
  LIMIT 1;

  IF FOUND THEN
    result := jsonb_set(result, '{warden}', jsonb_build_object(
      'id', warden_record.id,
      'email', warden_record.email,
      'hostels', COALESCE(warden_record.hostels, ARRAY[]::text[])
    ));
  END IF;

  -- Check arch_gate role
  SELECT id, email INTO arch_gate_record
  FROM arch_gate
  WHERE email = lower(user_email)
  LIMIT 1;

  IF FOUND THEN
    result := jsonb_set(result, '{arch_gate}', jsonb_build_object(
      'id', arch_gate_record.id,
      'email', arch_gate_record.email
    ));
  END IF;

  RETURN result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_user_roles(text) TO authenticated;
