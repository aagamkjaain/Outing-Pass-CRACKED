// Mock API - No Supabase connection, all data stored locally
import { normalizeHostels as normalizeHostelsList } from '../utils/wardenHostels';
import * as XLSX from 'xlsx';

const STORAGE_KEYS = {
  BOOKINGS: 'mock_bookings',
  STUDENTS: 'mock_students',
  ADMINS: 'mock_admins',
  WARDENS: 'mock_wardens'
};

// Initialize mock data if empty
const initializeMockData = () => {
  if (!localStorage.getItem(STORAGE_KEYS.BOOKINGS)) {
    const mockBookings = [
      {
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        hostel_name: 'Hostel A',
        room_number: '101',
        out_date: new Date().toISOString().split('T')[0],
        out_time: '09:00',
        in_date: new Date(Date.now() + 86400000).toISOString().split('T')[0],
        in_time: '18:00',
        parent_email: 'parent@example.com',
        parent_phone: '9876543210',
        reason: 'Home visit',
        status: 'waiting',
        created_at: new Date().toISOString()
      }
    ];
    localStorage.setItem(STORAGE_KEYS.BOOKINGS, JSON.stringify(mockBookings));
  }

  if (!localStorage.getItem(STORAGE_KEYS.STUDENTS)) {
    const mockStudents = [
      {
        id: 1,
        student_email: 'demo@srmist.edu.in',
        hostel_name: 'Hostel A',
        parent_email: 'parent@example.com',
        parent_phone: '9876543210'
      }
    ];
    localStorage.setItem(STORAGE_KEYS.STUDENTS, JSON.stringify(mockStudents));
  }

  if (!localStorage.getItem(STORAGE_KEYS.ADMINS)) {
    localStorage.setItem(STORAGE_KEYS.ADMINS, JSON.stringify([]));
  }

  if (!localStorage.getItem(STORAGE_KEYS.WARDENS)) {
    localStorage.setItem(STORAGE_KEYS.WARDENS, JSON.stringify([]));
  }
};

initializeMockData();

const getBookings = () => JSON.parse(localStorage.getItem(STORAGE_KEYS.BOOKINGS) || '[]');
const saveBookings = (data) => localStorage.setItem(STORAGE_KEYS.BOOKINGS, JSON.stringify(data));

const getStudents = () => JSON.parse(localStorage.getItem(STORAGE_KEYS.STUDENTS) || '[]');
const saveStudents = (data) => localStorage.setItem(STORAGE_KEYS.STUDENTS, JSON.stringify(data));

const getAdmins = () => JSON.parse(localStorage.getItem(STORAGE_KEYS.ADMINS) || '[]');
const getWardens = () => JSON.parse(localStorage.getItem(STORAGE_KEYS.WARDENS) || '[]');

// ===== API Functions =====

export const bookSlot = async (bookingData) => {
  try {
    if (!bookingData.name || !bookingData.email || !bookingData.hostelName || !bookingData.roomNumber) {
      throw new Error('Missing required fields');
    }

    const bookings = getBookings();
    const newBooking = {
      id: Math.max(...bookings.map(b => b.id || 0), 0) + 1,
      name: bookingData.name,
      email: bookingData.email,
      hostel_name: bookingData.hostelName,
      room_number: bookingData.roomNumber,
      out_date: bookingData.outDate,
      out_time: bookingData.outTime,
      in_date: bookingData.inDate,
      in_time: bookingData.inTime,
      parent_email: bookingData.parentEmail,
      parent_phone: bookingData.parentPhone,
      reason: bookingData.reason,
      status: 'still_out',
      handled_by: 'auto-approved',
      handled_at: new Date().toISOString(),
      created_at: new Date().toISOString()
    };

    bookings.push(newBooking);
    saveBookings(bookings);

    return {
      success: true,
      message: 'Outing request submitted successfully!',
      booking: newBooking
    };
  } catch (error) {
    throw new Error(error.message || 'Failed to book slot');
  }
};

export const fetchBookedSlots = async (email, opts = { limit: 50, minimal: true }) => {
  try {
    const bookings = getBookings();
    const userBookings = bookings
      .filter(b => b.email === email)
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
      .slice(0, opts.limit || 50);

    const waiting = userBookings.filter(b => b.status === 'waiting').length;
    const confirmed = userBookings.filter(b => b.status === 'confirmed').length;
    const rejected = userBookings.filter(b => b.status === 'rejected').length;

    userBookings.counts = { waiting, confirmed, rejected };
    return userBookings;
  } catch (error) {
    throw new Error(error.message || 'Failed to fetch bookings');
  }
};

export const deleteBookedSlot = async (slotId) => {
  try {
    const bookings = getBookings();
    const filtered = bookings.filter(b => b.id !== slotId);
    saveBookings(filtered);
    return { success: true, message: 'Booking deleted successfully' };
  } catch (error) {
    throw new Error(error.message || 'Failed to delete booking');
  }
};

export const fetchPendingBookings = async (adminEmail, allowedHostels) => {
  try {
    let bookings = getBookings();
    
    const normalizedHostels = normalizeHostelsList(allowedHostels);
    const hasAll = normalizedHostels.map(h => h.toLowerCase()).includes('all');
    
    if (Array.isArray(normalizedHostels) && normalizedHostels.length > 0 && !hasAll) {
      bookings = bookings.filter(b => normalizedHostels.includes(b.hostel_name));
    }

    return bookings.sort((a, b) => new Date(b.out_date) - new Date(a.out_date));
  } catch (error) {
    throw new Error(error.message || 'Failed to fetch pending bookings');
  }
};

export const fetchBookingsFiltered = async (opts = {}) => {
  try {
    const { status, startDate, endDate, allowedHostels, searchRoom, page = 1, pageSize = 50, minimal = true } = opts;

    let bookings = getBookings();

    if (status) {
      bookings = bookings.filter(b => b.status === status);
    }

    if (startDate) {
      bookings = bookings.filter(b => b.out_date >= startDate);
    }

    if (endDate) {
      bookings = bookings.filter(b => b.out_date <= endDate);
    }

    const normalizedHostels = normalizeHostelsList(allowedHostels);
    const hasAll = normalizedHostels.map(h => h.toLowerCase()).includes('all');
    if (Array.isArray(normalizedHostels) && normalizedHostels.length > 0 && !hasAll) {
      bookings = bookings.filter(b => normalizedHostels.includes(b.hostel_name));
    }

    if (searchRoom && searchRoom.trim()) {
      bookings = bookings.filter(b => String(b.room_number).includes(searchRoom.trim()));
    }

    const from = (page - 1) * pageSize;
    const to = from + pageSize;
    const paginatedBookings = bookings.slice(from, to);

    return { rows: paginatedBookings, count: bookings.length, page, pageSize };
  } catch (error) {
    throw new Error(error.message || 'Failed to fetch filtered bookings');
  }
};

export const handleBookingAction = async (bookingId, action, adminEmail, rejectionReason) => {
  try {
    const bookings = getBookings();
    const booking = bookings.find(b => b.id === bookingId);

    if (!booking) {
      throw new Error('Booking not found');
    }

    const newStatus = action === 'reject' ? 'rejected' : action;
    booking.status = newStatus;
    booking.handled_by = adminEmail;
    booking.handled_at = new Date().toISOString();

    if (newStatus === 'rejected') {
      booking.rejection_reason = rejectionReason || null;
    }

    saveBookings(bookings);

    return {
      success: true,
      message: `Booking ${newStatus} successfully`,
      booking: booking,
      emailResult: { sent: false }
    };
  } catch (error) {
    throw new Error(error.message || 'Failed to handle booking action');
  }
};

function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

export const generateOtpForBooking = async (bookingId) => {
  try {
    const bookings = getBookings();
    const booking = bookings.find(b => b.id === bookingId);

    if (!booking) {
      throw new Error('Booking not found');
    }

    const today = new Date().toISOString().split('T')[0];
    if (booking.out_date !== today) {
      throw new Error(`OTP will be available on your out date only (Today: ${today}, Out Date: ${booking.out_date})`);
    }

    if ((booking.status || '').toLowerCase() !== 'still_out') {
      throw new Error('OTP can be generated after you are marked as Out by the warden');
    }

    if (booking.otp && !booking.otp_used) {
      return { otp: booking.otp };
    }

    const otp = generateOTP();
    booking.otp = otp;
    booking.otp_used = false;

    saveBookings(bookings);

    return { otp };
  } catch (error) {
    throw new Error(error.message || 'Failed to generate OTP');
  }
};

export const updateBookingInTime = async (bookingId, newInTime) => {
  try {
    const bookings = getBookings();
    const booking = bookings.find(b => b.id === bookingId);

    if (!booking) {
      throw new Error('Booking not found');
    }

    booking.in_time = newInTime;
    saveBookings(bookings);

    return {
      success: true,
      message: 'In Time updated successfully',
      booking: booking
    };
  } catch (error) {
    throw new Error(error.message || 'Failed to update booking');
  }
};

export async function addOrUpdateStudentInfo(info) {
  try {
    const students = getStudents();
    const existingIndex = students.findIndex(s => s.student_email === info.student_email.toLowerCase());

    const normalizedInfo = {
      id: existingIndex >= 0 ? students[existingIndex].id : Math.max(...students.map(s => s.id || 0), 0) + 1,
      student_email: (info.student_email || '').toLowerCase(),
      hostel_name: info.hostel_name,
      parent_email: (info.parent_email || '').toLowerCase(),
      parent_phone: info.parent_phone
    };

    if (existingIndex >= 0) {
      students[existingIndex] = normalizedInfo;
    } else {
      students.push(normalizedInfo);
    }

    saveStudents(students);
    return normalizedInfo;
  } catch (error) {
    throw new Error(error.message || 'Failed to add/update student info');
  }
}

export const fetchAllStudentInfo = async (allowedHostels) => {
  try {
    let students = getStudents();

    const normalizedHostels = normalizeHostelsList(allowedHostels);
    const hasAll = normalizedHostels.map(h => h.toLowerCase()).includes('all');
    if (Array.isArray(normalizedHostels) && normalizedHostels.length > 0 && !hasAll) {
      students = students.filter(s => normalizedHostels.includes(s.hostel_name));
    }

    return students.sort((a, b) => a.student_email.localeCompare(b.student_email));
  } catch (error) {
    throw new Error(error.message || 'Failed to fetch student info');
  }
};

export const searchStudentInfoWithHostels = async (searchQuery, allowedHostels, options = {}) => {
  try {
    const { page = 1, pageSize = 25, minimal = true, includeCount = false } = options;

    let students = getStudents();

    if (searchQuery && searchQuery.trim()) {
      const term = searchQuery.trim().toLowerCase();
      students = students.filter(s => s.student_email.includes(term));
    }

    const normalizedHostels = normalizeHostelsList(allowedHostels);
    const hasAll = normalizedHostels.map(h => h.toLowerCase()).includes('all');
    if (Array.isArray(normalizedHostels) && normalizedHostels.length > 0 && !hasAll) {
      students = students.filter(s => normalizedHostels.includes(s.hostel_name));
    }

    const from = (page - 1) * pageSize;
    const to = from + pageSize;

    return { rows: students.slice(from, to), count: students.length, page, pageSize };
  } catch (error) {
    throw new Error(error.message || 'Failed to search student info');
  }
};

export const downloadStudentInfoTemplate = async () => {
  try {
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
      }
    ];

    const workbook = XLSX.utils.book_new();
    const worksheet = XLSX.utils.json_to_sheet(templateData);
    worksheet['!cols'] = [{ wch: 25 }, { wch: 15 }, { wch: 25 }, { wch: 20 }];

    XLSX.utils.book_append_sheet(workbook, worksheet, 'Student Info Template');

    const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
    const blob = new Blob([excelBuffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    const url = window.URL.createObjectURL(blob);

    const link = document.createElement('a');
    link.href = url;
    link.download = 'student_info_template.xlsx';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);
  } catch (error) {
    throw new Error(`Failed to generate template: ${error.message}`);
  }
};

export const fetchStudentInfoByEmail = async (email) => {
  try {
    const students = getStudents();
    return students.find(s => s.student_email === email.toLowerCase()) || null;
  } catch (error) {
    return null;
  }
};

export const fetchAdminInfoByEmail = async (email) => {
  try {
    // Demo: accept demo user as admin
    if (email === 'demo@srmist.edu.in') {
      return { id: 1, email: 'demo@srmist.edu.in', role: 'superadmin', hostels: ['all'] };
    }
    return null;
  } catch (error) {
    return null;
  }
};

export const fetchWardenInfoByEmail = async (email) => {
  try {
    const wardens = getWardens();
    return wardens.find(w => w.email === email.toLowerCase()) || null;
  } catch (error) {
    return null;
  }
};

export const deleteStudentInfo = async (student_email) => {
  try {
    const students = getStudents();
    const filtered = students.filter(s => s.student_email !== student_email.toLowerCase());
    saveStudents(filtered);
    return { success: true };
  } catch (error) {
    throw new Error(error.message || 'Failed to delete student info');
  }
};

export const authenticateWarden = async (email, password) => {
  try {
    // Demo: simple auth
    const wardens = getWardens();
    const warden = wardens.find(w => w.email === email.toLowerCase() && w.password === password);
    return warden ? { ...warden, role: 'warden' } : null;
  } catch (error) {
    return null;
  }
};

export const checkArchGateStatus = async (email) => {
  try {
    // Demo: no arch gate by default
    return null;
  } catch (error) {
    return null;
  }
};

export const checkApiHealth = async () => {
  try {
    // Always healthy for local mock
    return true;
  } catch (error) {
    return false;
  }
};

export const fetchOutingDetailsByOTP = async (otp) => {
  try {
    const bookings = getBookings();
    const booking = bookings.find(b => b.otp === otp && !b.otp_used && b.status === 'still_out');
    return booking || null;
  } catch (error) {
    throw new Error(error.message || 'Failed to fetch outing details');
  }
};

export const markOTPAsUsed = async (otp) => {
  try {
    const bookings = getBookings();
    const booking = bookings.find(b => b.otp === otp);

    if (!booking) {
      throw new Error('OTP not found');
    }

    booking.otp_used = true;
    booking.otp_verified_by = 'arch_gate';
    booking.otp_verified_at = new Date().toISOString();
    booking.status = 'confirmed';

    saveBookings(bookings);
    return booking;
  } catch (error) {
    throw new Error(`Failed to mark OTP as used: ${error.message}`);
  }
};

export const banStudent = async (banData) => {
  try {
    if (!banData.student_email || !banData.from_date || !banData.till_date) {
      throw new Error('Missing required ban data');
    }
    return { success: true, message: 'Student banned successfully' };
  } catch (error) {
    throw new Error(error.message || 'Failed to ban student');
  }
};

export const checkAndAutoUnban = async (email) => {
  // Mock: no bans
  return null;
};

export const fetchAllBans = async () => {
  // Mock: return empty bans
  return [];
};

export const deleteBan = async (banId) => {
  // Mock: ban deleted successfully
  return { success: true };
};

export const fetchOutingRequestsByRoom = async (roomNumber, startDate, endDate, allowedHostels) => {
  try {
    let bookings = getBookings();

    bookings = bookings.filter(b => String(b.room_number).includes(roomNumber));

    if (startDate) {
      bookings = bookings.filter(b => b.out_date >= startDate);
    }

    if (endDate) {
      bookings = bookings.filter(b => b.out_date <= endDate);
    }

    const normalizedHostels = normalizeHostelsList(allowedHostels);
    const hasAll = normalizedHostels.map(h => h.toLowerCase()).includes('all');
    if (Array.isArray(normalizedHostels) && normalizedHostels.length > 0 && !hasAll) {
      bookings = bookings.filter(b => normalizedHostels.includes(b.hostel_name));
    }

    return bookings;
  } catch (error) {
    throw new Error(error.message || 'Failed to fetch outing requests');
  }
};
