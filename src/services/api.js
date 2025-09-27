import { supabase } from '../supabaseClient';
import { getStatusUpdateEmail, getNowOutEmail, getReturnedEmail } from './mailTemplates';
import * as XLSX from 'xlsx';

// No longer need API_BASE_URL as we're using Supabase directly

/**
 * Helper function to handle errors
 * @param {Error} error - The error object
 * @returns {Error} - Formatted error
 */
const handleError = (error) => {
  return new Error(error.message || 'An error occurred with the Supabase request');
};

// Best-effort: set per-request user context so RLS works without JWT
async function ensureUserContext() {
  try {
    if (typeof window === 'undefined') {
      return;
    }
    
    // Check if warden is logged in
    const wardenLoggedIn = sessionStorage.getItem('wardenLoggedIn') === 'true';
    
    if (wardenLoggedIn) {
      const username = sessionStorage.getItem('wardenUsername');
      if (username) {
        try {
          console.log('Setting context for warden:', username);
          const { data, error } = await supabase.rpc('set_user_context', { user_name: username });
          if (error) {
            console.error('Error setting context:', error);
            // If context setting fails, we'll use application-level filtering instead
            console.log('Context setting failed, will use application-level filtering');
          } else {
            console.log('Context set successfully:', data);
          }
        } catch (err) {
          console.error('Failed to set context:', err);
          // If context setting fails, we'll use application-level filtering instead
          console.log('Context setting failed, will use application-level filtering');
        }
      }
      return;
    }
    
    // Check if super admin is logged in via Supabase Auth
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (user?.email) {
        const adminInfo = await fetchAdminInfoByEmail(user.email);
        if (adminInfo?.role === 'superadmin') {
          return;
        }
      }
    } catch (err) {
      // Continue if auth check fails
    }
  } catch (e) {
    // ignore
  }
}

/**
 * Book a lab slot
 * @param {Object} bookingData - The booking data
 * @returns {Promise<Object>} - Booking confirmation
 */
export const bookSlot = async (bookingData) => {
  try {
    // Validate required fields
    if (!bookingData.name || !bookingData.email || !bookingData.hostelName || !bookingData.roomNumber || !bookingData.outDate || !bookingData.outTime || !bookingData.inDate || !bookingData.inTime || !bookingData.reason) {
      throw new Error('Missing required fields: name, email, hostel, room number, out date/time, in date/time, reason are required.');
    }

    // Insert the outing request into the database
    const { data, error } = await supabase
      .from('outing_requests')
      .insert([
        {
          name: bookingData.name,
          email: bookingData.email,
          hostel_name: bookingData.hostelName,
          room_number: bookingData.roomNumber,
          out_date: bookingData.outDate,
          out_time: bookingData.outTime,
          in_date: bookingData.inDate,
          in_time: bookingData.inTime,
          parent_email: bookingData.parentEmail,
          parent_phone: bookingData.parentPhone, // NEW: include parent_phone
          reason: bookingData.reason,
          status: 'waiting'
        }
      ])
      .select();

    if (error) throw error;

    return {
      success: true,
      message: 'Outing request submitted successfully!',
      booking: data[0]
    };
  } catch (error) {
    throw handleError(error);
  }
};

/**
 * Fetch booked slots for a user
 * @param {string} email - The user's email
 * @returns {Promise<Array>} - Array of booked slots with counts
 */
export const fetchBookedSlots = async (email) => {
  try {
    const { data, error } = await supabase
      .from('outing_requests')
      .select('*')
      .eq('email', email);
    
    if (error) throw error;
    
    // Calculate counts for each status
    const waiting = data.filter(booking => booking.status === 'waiting').length;
    const confirmed = data.filter(booking => booking.status === 'confirmed').length;
    const rejected = data.filter(booking => booking.status === 'rejected').length;
    
    data.counts = { waiting, confirmed, rejected };
    
    return data;
  } catch (error) {
    throw handleError(error);
  }
};

/**
 * Delete a booked slot
 * @param {number} slotId - The slot ID to delete
 * @returns {Promise<Object>} - Deletion confirmation
 */
export const deleteBookedSlot = async (slotId) => {
  try {
    const { error } = await supabase
      .from('outing_requests')
      .delete()
      .eq('id', slotId)
      .select();
    
    if (error) throw error;
    
    return { success: true, message: 'Booking deleted successfully' };
  } catch (error) {
    throw handleError(error);
  }
};

/**
 * Fetch all bookings (admin/warden)
 * Optionally restrict by allowed hostels (for wardens)
 * @param {string} adminEmail - The admin's email (for audit/compat)
 * @param {string[]} allowedHostels - Optional list of hostel names the user is allowed to see; if ['all'] or empty/undefined => no restriction
 * @returns {Promise<Array>} - Array of bookings
 */
export const fetchPendingBookings = async (adminEmail, allowedHostels) => {
  try {
    await ensureUserContext();
    
    console.log('fetchPendingBookings called with:', { adminEmail, allowedHostels });
    
    // Check if warden is logged in - if so, use application-level filtering
    const wardenLoggedIn = typeof window !== 'undefined' && sessionStorage.getItem('wardenLoggedIn') === 'true';
    
    if (wardenLoggedIn) {
      console.log('Warden logged in, using RPC function for data fetching');
      const username = sessionStorage.getItem('wardenUsername');
      
      if (!username) {
        throw new Error('Warden username not found in session');
      }
      
      console.log('Fetching data for warden:', username);
      const { data: allData, error: allError } = await supabase
        .rpc('get_warden_outing_requests', { warden_username: username });
      
      if (allError) {
        console.error('Error fetching warden outing requests:', allError);
        throw new Error(`Failed to fetch outing requests: ${allError.message}`);
      }
      
      console.log('Fetched warden data:', allData?.length || 0, 'records');
      console.log('Sample data:', allData?.slice(0, 2));
      
      // RPC function already handles filtering by warden's assigned hostels
      // No additional application-level filtering needed
      return allData || [];
    }
    
    // For super admins, use normal query with RLS
    const query = supabase
      .from('outing_requests')
      .select('*')
      .order('out_date', { ascending: false })
      .order('created_at', { ascending: false });

    // Apply server-side hostel restriction when provided and not 'all'
    if (Array.isArray(allowedHostels) && allowedHostels.length > 0 && !allowedHostels.map(h => h.toLowerCase()).includes('all')) {
      console.log('Applying hostel filter:', allowedHostels);
      // Supabase supports in() for filtering
      query.in('hostel_name', allowedHostels);
    }

    console.log('Executing query...');
    const { data, error } = await query;
    
    if (error) {
      console.error('Supabase query error:', error);
      throw new Error(`Failed to fetch outing requests: ${error.message}`);
    }
    
    console.log('Query successful, returned', data?.length || 0, 'records');
    
    if (!data) {
      throw new Error('No outing request data available');
    }
    
    return data;
  } catch (error) {
    console.error('fetchPendingBookings error:', error);
    throw handleError(error);
  }
};



function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * Handle booking action (confirm/reject)
 * @param {number} bookingId - The booking ID to update
 * @param {string} action - The action to perform ('confirm' or 'reject')
 * @param {string} adminEmail - The admin's email
 * @returns {Promise<Object>} - Action confirmation
 */
export const handleBookingAction = async (bookingId, action, adminEmail, rejectionReason) => {
  try {
    await ensureUserContext();
    // Validate handled_by (adminEmail used here as handler name) must be non-empty
    if (!adminEmail || !String(adminEmail).trim()) {
      throw new Error('Approver name is required');
    }
    
    // Check if warden is logged in - if so, use RPC function
    const wardenLoggedIn = typeof window !== 'undefined' && sessionStorage.getItem('wardenLoggedIn') === 'true';
    
    if (wardenLoggedIn) {
      const wardenUsername = sessionStorage.getItem('wardenUsername');
      if (!wardenUsername) {
        throw new Error('Warden username not found in session');
      }
      
      // action is now the new status: 'still_out', 'confirmed', 'rejected'
      let newStatus = action;
      if (action === 'reject') newStatus = 'rejected';
      
      console.log('Using RPC function for warden update:', { bookingId, newStatus, wardenUsername });
      
      const { data, error } = await supabase
        .rpc('warden_update_outing_request', {
          request_id: bookingId,
          new_status: newStatus,
          handled_by: wardenUsername,
          rejection_reason: rejectionReason || null
        });
      
      if (error) {
        console.error('RPC update error:', error);
        throw new Error(`Failed to update request: ${error.message}`);
      }
      
      // RPC returns array, get first element
      const updatedBooking = data && data.length > 0 ? data[0] : null;
      if (!updatedBooking) {
        throw new Error('No data returned from update');
      }
      
      // Set data for email processing
      const data = [updatedBooking];
    } else {
      // For super admins, use normal update
      let newStatus = action;
      if (action === 'reject') newStatus = 'rejected';
      const updateObj = {
        status: newStatus,
        handled_by: adminEmail,
        handled_at: new Date().toISOString(),
      };
      if (newStatus === 'rejected') {
        updateObj.rejection_reason = rejectionReason || null;
      }
      const { data, error } = await supabase
        .from('outing_requests')
        .update(updateObj)
        .eq('id', bookingId)
        .select();
      if (error) {
        throw new Error(`Supabase error: ${error.message || error}`);
      }
    }

    let emailResult = { sent: false, error: null };
    // --- AUTOMATED EMAIL TO PARENT ---
    if (data && data[0] && data[0].parent_email) {
      const booking = data[0];
      let emailTemplate;
      if (newStatus === 'still_out') {
        emailTemplate = getNowOutEmail(booking, adminEmail);
      } else if (newStatus === 'confirmed') {
        emailTemplate = getReturnedEmail(booking);
      } else if (newStatus === 'rejected') {
        emailTemplate = getStatusUpdateEmail(booking, 'rejected');
      }
      if (emailTemplate) {
      const functionUrl = 'https://fwnknmqlhlyxdeyfcrad.supabase.co/functions/v1/send-email';
      try {
        const emailRes = await fetch(functionUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
              to: booking.parent_email,
              subject: emailTemplate.subject,
              html: emailTemplate.html
          })
        });
        const emailData = await emailRes.json();
        if (emailRes.ok && !emailData.error) {
          emailResult.sent = true;
        } else {
          emailResult.error = emailData.error || 'Unknown error';
        }
      } catch (err) {
        emailResult.error = err.message || 'Failed to send email';
        }
      }
    }
    // --- END EMAIL ---

    return { 
      success: true, 
      message: `Booking ${newStatus} successfully`, 
      booking: data[0],
      emailResult
    };
  } catch (error) {
    throw handleError(error);
  }
};

/**
 * Generate OTP for a booking only on the out date and only once
 * @param {number} bookingId - The booking ID
 * @returns {Promise<{otp: string}>}
 */
export const generateOtpForBooking = async (bookingId) => {
  try {
    await ensureUserContext();
    const today = new Date().toISOString().split('T')[0];
    const { data: booking, error: fetchErr } = await supabase
      .from('outing_requests')
      .select('id, out_date, status, otp, otp_used')
      .eq('id', bookingId)
      .single();
    if (fetchErr) throw fetchErr;
    if (!booking) throw new Error('Booking not found');
    if (booking.out_date !== today) throw new Error('OTP will be available on your out date only');
    // Ensure the student has been let out (approved)
    if ((booking.status || '').toLowerCase() !== 'still_out') {
      throw new Error('OTP can be generated after you are marked as Out by the warden');
    }
    // If an unused OTP already exists, reuse it
    if (booking.otp && booking.otp_used === false) {
      return { otp: booking.otp };
    }
    // Generate a unique OTP
    let otp = null;
    let unique = false;
    while (!unique) {
      otp = generateOTP();
      const { data: exists } = await supabase
        .from('outing_requests')
        .select('id')
        .eq('otp', otp);
      if (!exists || exists.length === 0) unique = true;
    }
    const { data: updated, error: updErr } = await supabase
      .from('outing_requests')
      .update({ otp, otp_used: false })
      .eq('id', bookingId)
      .select();
    if (updErr) throw updErr;
    return { otp: updated?.[0]?.otp || otp };
  } catch (error) {
    throw handleError(error);
  }
};

/**
 * Update only the in_time field for a booking (admin only)
 * @param {number} bookingId - The booking ID to update
 * @param {string} newInTime - The new in_time value
 * @returns {Promise<Object>} - Update confirmation
 */
export const updateBookingInTime = async (bookingId, newInTime) => {
  try {
    await ensureUserContext();
    const { data, error } = await supabase
      .from('outing_requests')
      .update({ in_time: newInTime })
      .eq('id', bookingId)
      .select();
    if (error) throw error;
    return {
      success: true,
      message: 'In Time updated successfully',
      booking: data[0]
    };
  } catch (error) {
    throw handleError(error);
  }
};

/**
 * Add or update student info (upsert by student_email)
 * @param {Object} info - student info object
 * @returns {Promise<Object>} - inserted/updated row
 */
export async function addOrUpdateStudentInfo(info, adminEmail = null) {
  // Application-level security: Check if user is authorized
  const isWardenLoggedIn = typeof window !== 'undefined' && sessionStorage.getItem('wardenLoggedIn') === 'true';
  let adminRole = '';
  
  // Check if user is super admin via Supabase Auth
  if (!isWardenLoggedIn) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (user?.email) {
        const adminInfo = await fetchAdminInfoByEmail(user.email);
        adminRole = adminInfo?.role || '';
      }
    } catch (err) {
      // Continue if auth check fails
    }
  }

  // Only allow superadmin to add/update student info (wardens can only view)
  if (!isWardenLoggedIn && adminRole !== 'superadmin') {
    throw new Error('Unauthorized: Only super admins can manage student info.');
  }

  // Convert all string fields to lowercase
  const lowerInfo = Object.fromEntries(
    Object.entries(info).map(([k, v]) => [k, typeof v === 'string' ? v.toLowerCase() : v])
  );
  const { data, error } = await supabase
    .from('student_info')
    .upsert([lowerInfo], { onConflict: ['student_email'] });
  if (error) throw error;
  return data;
}

/**
 * Fetch all student info (admin only)
 * @returns {Promise<Array>} - Array of student info
 */
export const fetchAllStudentInfo = async () => {
  try {
    await ensureUserContext();
    
    // Check if warden is logged in - if so, use application-level filtering
    const wardenLoggedIn = typeof window !== 'undefined' && sessionStorage.getItem('wardenLoggedIn') === 'true';
    
    if (wardenLoggedIn) {
      console.log('Warden logged in, using RPC function for student info');
      const username = sessionStorage.getItem('wardenUsername');
      
      if (!username) {
        throw new Error('Warden username not found in session');
      }
      
      console.log('Fetching student info for warden:', username);
      const { data: allData, error: allError } = await supabase
        .rpc('get_warden_student_info', { warden_username: username });
      
      if (allError) {
        console.error('Error fetching warden student info:', allError);
        throw new Error(`Failed to fetch student info: ${allError.message}`);
      }
      
      console.log('Fetched warden student data:', allData?.length || 0, 'records');
      console.log('Sample student data:', allData?.slice(0, 2));
      
      // RPC function already handles filtering by warden's assigned hostels
      // No additional application-level filtering needed
      return allData || [];
    }
    
    // For super admins, use normal query with RLS
    const { data, error } = await supabase
      .from('student_info')
      .select('*')
      .order('student_email', { ascending: true });
    
    if (error) {
      console.error('Supabase query error:', error);
      throw error;
    }
    
    return data;
  } catch (error) {
    throw handleError(error);
  }
};

/**
 * Fetch limited student info for initial load (performance optimization)
 * @param {number} limit - Number of records to fetch (default: 20)
 * @returns {Promise<Array>} - Array of limited student info
 */
export const fetchLimitedStudentInfo = async (limit = 20) => {
  try {
    await ensureUserContext();
    const { data, error } = await supabase
      .from('student_info')
      .select('*')
      .order('student_email', { ascending: true })
      .limit(limit);
    if (error) throw error;
    return data;
  } catch (error) {
    throw handleError(error);
  }
};

/**
 * Search student info by email or name
 * @param {string} searchQuery - Search term
 * @param {number} limit - Maximum results to return (default: 50)
 * @returns {Promise<Array>} - Array of matching student info
 */
export const searchStudentInfo = async (searchQuery, limit = 50) => {
  try {
    await ensureUserContext();
    if (!searchQuery || searchQuery.trim().length < 2) {
      return [];
    }
    
    const query = searchQuery.trim().toLowerCase();
    const { data, error } = await supabase
      .from('student_info')
      .select('*')
      .or(`student_email.ilike.%${query}%,hostel_name.ilike.%${query}%`)
      .order('student_email', { ascending: true })
      .limit(limit);
    
    if (error) {
      console.error('Supabase query error:', error);
      // If RLS fails, try to fetch all data and filter at application level
      if (error.message && error.message.includes('permission denied')) {
        console.log('RLS permission denied, trying to fetch all student data for application-level filtering');
        const { data: allData, error: allError } = await supabase
          .from('student_info')
          .select('*')
          .order('student_email', { ascending: true });
        
        if (allError) {
          throw new Error(`Failed to search student info: ${allError.message}`);
        }
        
        // Apply application-level filtering
        const wardenLoggedIn = typeof window !== 'undefined' && sessionStorage.getItem('wardenLoggedIn') === 'true';
        let filteredData = allData || [];
        
        if (wardenLoggedIn) {
          const wardenHostels = JSON.parse(sessionStorage.getItem('wardenHostels') || '[]');
          if (wardenHostels.length > 0) {
            filteredData = filteredData.filter(student => 
              wardenHostels.some(hostel => 
                student.hostel_name && student.hostel_name.toLowerCase().includes(hostel.toLowerCase())
              )
            );
          }
        }
        
        // Apply search filter
        filteredData = filteredData.filter(student => 
          (student.student_email && student.student_email.toLowerCase().includes(query)) ||
          (student.hostel_name && student.hostel_name.toLowerCase().includes(query))
        );
        
        return filteredData.slice(0, limit);
      }
      throw error;
    }
    
    return data;
  } catch (error) {
    throw handleError(error);
  }
};



/**
 * Generate and download Excel template for student info upload
 * @returns {Promise<void>}
 */
export const downloadStudentInfoTemplate = async () => {
  try {
    // Create template data with headers and example rows
    const templateData = [
      {
        'Student Email': 'student1@example.com',
        'Hostel Name': 'Hostel A',
        'Parent Email': 'parent1@example.com',
        'Parent Phone': '+91-9876543210'
      },
      {
        'Student Email': 'student2@example.com',
        'Hostel Name': 'Hostel B',
        'Parent Email': 'parent2@example.com',
        'Parent Phone': '+91-9876543211'
      },
      {
        'Student Email': 'student3@example.com',
        'Hostel Name': 'Hostel C',
        'Parent Email': 'parent3@example.com',
        'Parent Phone': '+91-9876543212'
      }
    ];

    // Create workbook and worksheet
    const workbook = XLSX.utils.book_new();
    const worksheet = XLSX.utils.json_to_sheet(templateData);

    // Set column widths for better readability
    const columnWidths = [
      { wch: 25 }, // Student Email
      { wch: 15 }, // Hostel Name
      { wch: 25 }, // Parent Email
      { wch: 20 }  // Parent Phone
    ];
    worksheet['!cols'] = columnWidths;

    // Add the worksheet to the workbook
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Student Info Template');

    // Generate the Excel file
    const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
    
    // Create blob and download
    const blob = new Blob([excelBuffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    const url = window.URL.createObjectURL(blob);
    
    // Create download link
    const link = document.createElement('a');
    link.href = url;
    link.download = 'student_info_template.xlsx';
    document.body.appendChild(link);
    link.click();
    
    // Cleanup
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);
  } catch (error) {
    throw new Error(`Failed to generate template: ${error.message}`);
  }
};



/**
 * Fetch student info by email
 * @param {string} email - Student email
 * @returns {Promise<Object>} - Student info
 */
export const fetchStudentInfoByEmail = async (email) => {
  try {
    await ensureUserContext();
    const { data, error } = await supabase
      .from('student_info')
      .select('*')
      .eq('student_email', email.toLowerCase())
      .single();
    if (error && error.code === 'PGRST116') return null; // No row found is not an error
    if (error) throw error;
    return data;
  } catch (error) {
    return null;
  }
};

/**
 * Fetch admin info by email
 * @param {string} email
 * @returns {Promise<Object|null>} - Admin info or null if not found
 */
export const fetchAdminInfoByEmail = async (email) => {
  try {
    const { data, error } = await supabase
      .from('admins')
      .select('*')
      .eq('email', email.toLowerCase())
      .single();
    if (error && error.code !== 'PGRST116') throw error;
    return data || null;
  } catch (error) {
    return null;
  }
};

/**
 * Delete student info by email (superadmin only)
 * @param {string} student_email - The student's email
 * @returns {Promise<Object>} - Deletion confirmation
 */
export const deleteStudentInfo = async (student_email) => {
  try {
    // Application-level security: Check if user is authorized
    const isWardenLoggedIn = typeof window !== 'undefined' && sessionStorage.getItem('wardenLoggedIn') === 'true';
    let adminRole = '';
    
    // Check if user is super admin via Supabase Auth
    if (!isWardenLoggedIn) {
      try {
        const { data: { user } } = await supabase.auth.getUser();
        if (user?.email) {
          const adminInfo = await fetchAdminInfoByEmail(user.email);
          adminRole = adminInfo?.role || '';
        }
      } catch (err) {
        // Continue if auth check fails
      }
    }

    // Only allow superadmin to delete student info (wardens can only view)
    if (!isWardenLoggedIn && adminRole !== 'superadmin') {
      throw new Error('Unauthorized: Only super admins can delete student info.');
    }

    const { error } = await supabase
      .from('student_info')
      .delete()
      .eq('student_email', student_email.toLowerCase());
    if (error) throw error;
    return { success: true };
  } catch (error) {
    throw handleError(error);
  }
};

/**
 * Authenticate warden by username and password
 * @param {string} username
 * @param {string} password
 * @returns {Promise<Object|null>} - Warden info or null if not found/invalid
 */
export const authenticateWarden = async (username, password) => {
  try {
    const { data, error } = await supabase
      .from('admins')
      .select('*')
      .eq('username', username)
      .eq('role', 'warden') // Re-enabled role validation for security
      .maybeSingle();
    if (error && error.code !== 'PGRST116') throw error;
    if (!data) return null;
    if (data.password !== password) return null;
    return data;
  } catch (error) {
    return null;
  }
};

/**
 * Authenticate system user by username and password
 * @param {string} username - The user's username
 * @param {string} password - The user's password
 * @returns {Promise<Object|null>} - User info or null if not found/invalid
 */
export const authenticateSystemUser = async (username, password) => {
  try {
    // Use RPC function for secure authentication
    const { data, error } = await supabase
      .rpc('authenticate_warden', { 
        warden_username: username, 
        warden_password: password 
      });
    
    if (error) {
      console.error('Warden authentication RPC error:', error);
      return null;
    }
    
    // Return the first (and should be only) result
    return data && data.length > 0 ? data[0] : null;
  } catch (error) {
    console.error('Warden authentication error:', error);
    return null;
  }
};

/**
 * Helper function to maintain user context for warden operations
 * @param {string} username - The warden's username
 * @returns {Promise<void>}
 */
export const maintainWardenContext = async (username) => {
  try {
    console.log('Setting user context for warden:', username);
    const { data, error } = await supabase.rpc('set_user_context', { user_name: username });
    if (error) {
      console.error('Error setting user context:', error);
      throw error; // Re-throw to stop execution
    } else {
      console.log('User context set successfully:', data);
    }
  } catch (error) {
    console.error('Failed to set user context:', error);
    throw error; // Re-throw to stop execution
  }
};

// Health check function checks if we can connect to Supabase
export const checkApiHealth = async () => {
  try {
    // First try to fetch a public table that should exist
    try {
      const { error } = await supabase.from('health_check').select('count').limit(1);
      if (!error) return true;
    } catch (e) {
  
    }
    
    // If that fails, try a simple auth ping which should always work
    const { error } = await supabase.auth.getSession();
    return !error;
  } catch (error) {
    // console.error('Supabase connection error:', error);
    return false;
  }
};

export const fetchOutingDetailsByOTP = async (otp) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const { data, error } = await supabase
      .from('outing_requests')
      .select('*')
      .eq('otp', otp)
      .eq('otp_used', false)
      .eq('status', 'still_out')
      .gte('in_date', today)
      .single();
    if (error) throw error;
    return data;
  } catch (error) {
    throw handleError(error);
  }
};

export const markOTPAsUsed = async (otp) => {
  try {
    const { data, error } = await supabase
      .from('outing_requests')
      .update({ otp_used: true })
      .eq('otp', otp)
      .select();

    if (error) throw error;
    return data[0];
  } catch (error) {
    throw handleError(error);
  }
};

/**
 * Ban a student
 * @param {Object} banData - The ban data (student_email, from_date, till_date, reason, banned_by)
 * @returns {Promise<Object>} - Ban confirmation
 */
export const banStudent = async (banData) => {
  try {
    // Validate required fields
    if (!banData.student_email || !banData.from_date || !banData.till_date || !banData.banned_by) {
      throw new Error('Missing required fields: student_email, from_date, till_date, and banned_by are required.');
    }

    // Application-level security: Check if user is authorized to ban
    const isWardenLoggedIn = typeof window !== 'undefined' && sessionStorage.getItem('wardenLoggedIn') === 'true';
    
    // Get admin info - check both sessionStorage and Supabase auth
    let adminRole = '';
    let adminEmail = '';
    
    if (isWardenLoggedIn) {
      // Warden is logged in via sessionStorage
      adminEmail = sessionStorage.getItem('wardenEmail') || '';
      adminRole = sessionStorage.getItem('wardenRole') || 'warden';
    } else {
      // Check if user is authenticated via Supabase Auth (super admin)
      try {
        const { data: { user } } = await supabase.auth.getUser();
        if (user?.email) {
          adminEmail = user.email;
          const adminInfo = await fetchAdminInfoByEmail(user.email);
          adminRole = adminInfo?.role || '';
        }
      } catch (err) {
        // Continue if auth check fails
      }
    }

    // Only allow superadmin or warden to ban
    if (!isWardenLoggedIn && adminRole !== 'superadmin') {
      throw new Error('Unauthorized: Only super admins and wardens can ban students.');
    }

    // Check if student is already banned for overlapping dates
    const { data: existingBans, error: checkError } = await supabase
      .from('ban_students')
      .select('*')
      .eq('student_email', banData.student_email)
      .eq('is_active', true)
      .or(`from_date.lte.${banData.till_date},till_date.gte.${banData.from_date}`);

    if (checkError) throw checkError;

    if (existingBans && existingBans.length > 0) {
      throw new Error('Student is already banned for overlapping dates.');
    }

    // Insert the ban record, always set is_active: true
    const { data, error } = await supabase
      .from('ban_students')
      .insert([{
        student_email: banData.student_email,
        from_date: banData.from_date,
        till_date: banData.till_date,
        reason: banData.reason || null,
        banned_by: banData.banned_by,
        is_active: true
      }])
      .select();

    if (error) throw error;

    return {
      success: true,
      message: 'Student banned successfully!',
      ban: data[0]
    };
  } catch (error) {
    throw handleError(error);
  }
};



/**
 * Fetch all bans (admin only)
 * @returns {Promise<Array>} - Array of all bans
 */
export const fetchAllBans = async () => {
  try {
    await ensureUserContext();
    const { data, error } = await supabase
      .from('ban_students')
      .select('*')
      .eq('is_active', true);
    if (error) throw error;
    return data;
  } catch (error) {
    throw handleError(error);
  }
};

/**
 * Fetch active bans for a student
 * @param {string} studentEmail - The student's email
 * @returns {Promise<Array>} - Array of active bans for the student
 */
export const fetchStudentBans = async (studentEmail) => {
  try {
    await ensureUserContext();
    const { data, error } = await supabase
      .from('ban_students')
      .select('*')
      .eq('student_email', studentEmail.toLowerCase()) // ensure case-insensitive match
      .eq('is_active', true)
      .order('created_at', { ascending: false });
    if (error) throw error;
    return data;
  } catch (error) {
    throw handleError(error);
  }
};

/**
 * Update a ban
 * @param {string} banId - The ban ID to update
 * @param {Object} updateData - The data to update
 * @returns {Promise<Object>} - Update confirmation
 */
export const updateBan = async (banId, updateData) => {
  try {
    const { data, error } = await supabase
      .from('ban_students')
      .update({
        ...updateData,
        updated_at: new Date().toISOString()
      })
      .eq('id', banId)
      .select();

    if (error) throw error;

    return {
      success: true,
      message: 'Ban updated successfully!',
      ban: data[0]
    };
  } catch (error) {
    throw handleError(error);
  }
};

/**
 * Delete a ban (soft delete by setting is_active to false)
 * @param {string} banId - The ban ID to delete
 * @returns {Promise<Object>} - Deletion confirmation
 */
export const deleteBan = async (banId) => {
  try {
    const { data, error } = await supabase
      .from('ban_students')
      .update({ 
        is_active: false,
        updated_at: new Date().toISOString()
      })
      .eq('id', banId)
      .select();

    if (error) throw error;

    return {
      success: true,
      message: 'Ban removed successfully!',
      ban: data[0]
    };
  } catch (error) {
    throw handleError(error);
  }
};

/**
 * Check if a student is currently banned
 * @param {string} studentEmail - The student's email
 * @returns {Promise<Object|null>} - Active ban if exists, null otherwise
 */
export const checkStudentBanStatus = async (studentEmail) => {
  try {
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD format
    
    const { data, error } = await supabase
      .from('ban_students')
      .select('*')
      .eq('student_email', studentEmail)
      .eq('is_active', true)
      .lte('from_date', today)
      .gte('till_date', today)
      .single();

    if (error && error.code !== 'PGRST116') throw error; // PGRST116 = no rows returned
    
    return data || null;
  } catch (error) {
    throw handleError(error);
  }
};

export const checkAndAutoUnban = async (studentEmail) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const { data: bans, error } = await supabase
      .from('ban_students')
      .select('*')
      .eq('student_email', studentEmail.toLowerCase())
      .eq('is_active', true);
    if (error) throw error;
    let activeBan = null;
    for (const ban of bans) {
      if (ban.till_date && ban.till_date < today) {
        // Auto-unban
        await supabase
          .from('ban_students')
          .update({ is_active: false })
          .eq('id', ban.id);
      } else if (ban.till_date && ban.from_date && ban.from_date <= today && today <= ban.till_date) {
        activeBan = ban;
      }
    }
    return activeBan;
  } catch (error) {
    throw handleError(error);
  }
};