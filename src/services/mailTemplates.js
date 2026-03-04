// Email templates for parent notifications

// Shared components
const getBookingDetailsHTML = (booking) => `
  <ul>
    <li><b>Out Date:</b> ${booking.out_date}</li>
    <li><b>Out Time:</b> ${booking.out_time}</li>
    <li><b>In Date:</b> ${booking.in_date}</li>
    <li><b>In Time:</b> ${booking.in_time}</li>
    <li><b>Reason:</b> ${booking.reason}</li>
  </ul>
`;

const getEmailFooter = () => `
  <p>
    If you have any questions, please contact your ward's respective hostel administration. <br>
    Contact details are available at: <a href="https://www.srmist.edu.in/srm-hostels/">https://www.srmist.edu.in/srm-hostels/</a> <br>
    <b><i>This is an automated message. Please do not reply.</i></b>
  </p>
`;

export function getStatusUpdateEmail(booking, statusMsg) {
  return {
    subject: `Outing Request ${statusMsg}`,
    html: `
      <p>Dear Parent,</p>
      <p>
        This is to inform you that your child <b>${booking.name}</b> (<a href="mailto:${booking.email}">${booking.email}</a>) from <b>${booking.hostel_name}</b> has had their outing request <b>${statusMsg}</b> by the hostel administration.
      </p>
      ${getBookingDetailsHTML(booking)}
      ${getEmailFooter()}
    `
  };
}

export function getStillOutAlertEmail(booking) {
  // Format dates for display
  const formatDate = (dateStr) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-IN', { 
      day: 'numeric', 
      month: 'long', 
      year: 'numeric' 
    });
  };
  
  const formatTime = (timeStr) => {
    return timeStr;
  };
  
  return {
    subject: 'Important Alert: Your ward has not returned from outing',
    html: `
      <p>Dear Parent,</p>
      <p>
        This is an <b>important alert</b> to inform you that your child <b>${booking.name}</b> (<a href="mailto:${booking.email}">${booking.email}</a>) from <b>${booking.hostel_name}</b> has not yet closed their outing request and is still marked as being out of campus.
      </p>
      <p><b>Outing Details:</b></p>
      <ul>
        <li><b>Student Left On:</b> ${formatDate(booking.out_date)} at ${formatTime(booking.out_time)}</li>
        <li><b>Expected Return:</b> ${formatDate(booking.in_date)} at ${formatTime(booking.in_time)}</li>
        <li><b>Reason for Outing:</b> ${booking.reason}</li>
        <li><b>Current Status:</b> Still Out (Not Returned)</li>
      </ul>
      <p>
        <b>Action Required:</b> We request you to please verify your ward's whereabouts and ensure their safety. If your ward has already returned to the hostel, kindly remind them to close their outing request through the portal immediately to update their status.
      </p>
      <p>
        For the safety and security of all students, it is crucial that we maintain accurate records of student movements. If your ward has not yet returned or if there are any concerns, please contact the hostel administration immediately at the earliest.
      </p>
      <p>
        <b>Note:</b> Students must close their outing requests promptly upon returning to campus to ensure proper tracking and compliance with hostel safety protocols.
      </p>
      ${getEmailFooter()}
    `
  };
}

export function getNowOutEmail(booking, wardenEmail) {
  // Format dates for display
  const formatDate = (dateStr) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-IN', { 
      day: 'numeric', 
      month: 'long', 
      year: 'numeric' 
    });
  };
  
  const formatTime = (timeStr) => {
    return timeStr;
  };
  
  return {
    subject: 'Outing Approved: Your ward has left the campus',
    html: `
      <p>Dear Parent,</p>
      <p>
        This is to inform you that your child <b>${booking.name}</b> (<a href="mailto:${booking.email}">${booking.email}</a>) from <b>${booking.hostel_name}</b> has been <b>granted permission to leave the campus</b> and has exited the hostel premises.
      </p>
      <p><b>Outing Details:</b></p>
      <ul>
        <li><b>Out Date:</b> ${formatDate(booking.out_date)} at ${formatTime(booking.out_time)}</li>
        <li><b>Expected Return:</b> ${formatDate(booking.in_date)} at ${formatTime(booking.in_time)}</li>
        <li><b>Reason for Outing:</b> ${booking.reason}</li>
        <li><b>Approved By:</b> Hostel Warden${wardenEmail ? ` (<a href="mailto:${wardenEmail}">${wardenEmail}</a>)` : ''}</li>
      </ul>
      <p>
        <b>Important Reminders:</b>
      </p>
      <ul>
        <li>Please ensure your ward returns to the hostel by the expected return date and time mentioned above.</li>
        <li>Your ward must close the outing request through the portal immediately upon returning to campus for safety tracking purposes.</li>
        <li>In case of any delay or change in plans, please inform the hostel administration promptly.</li>
      </ul>
      <p>
        This notification is sent to keep you informed about your ward's movements for safety and security purposes. We appreciate your cooperation in ensuring your ward follows all hostel protocols.
      </p>
      ${getEmailFooter()}
    `
  };
}

export function getReturnedEmail(booking, closingDate = null) {
  // Parse dates for comparison
  const outDate = new Date(booking.out_date).toDateString();
  const returnDate = closingDate ? new Date(closingDate).toDateString() : new Date().toDateString();
  
  // Check if returned on the same day
  const isSameDay = outDate === returnDate;
  
  // Format dates for display
  const formatDate = (dateStr) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-IN', { 
      day: 'numeric', 
      month: 'long', 
      year: 'numeric' 
    });
  };
  
  const returnMessage = isSameDay 
    ? `<p>Your child <b>${booking.name}</b> (<a href="mailto:${booking.email}">${booking.email}</a>) from <b>${booking.hostel_name}</b> has <b>returned</b> to the hostel after their outing.</p>
       <p>We are pleased to inform you that your ward has followed the proper procedure by closing the outing request on the same day of return to the college. This adherence to safety protocols is appreciated.</p>`
    : `<p>Your child <b>${booking.name}</b> (<a href="mailto:${booking.email}">${booking.email}</a>) from <b>${booking.hostel_name}</b> has <b>closed</b> their outing request on <b>${formatDate(returnDate)}</b>.</p>
       <p><b>Please note:</b> The outing was scheduled with an out date of <b>${formatDate(booking.out_date)}</b>, but the request is being closed on <b>${formatDate(returnDate)}</b>.</p>
       <p>For safety and security reasons, we strongly request that you guide your ward to close outing requests on the same day they return to the college. This helps us maintain accurate records of student whereabouts and ensures campus security protocols are followed effectively.</p>
       <p>We appreciate your cooperation in helping your ward adhere to this procedure in the future.</p>`;
  
  return {
    subject: 'Outing Update: Student has returned',
    html: `
      <p>Dear Parent,</p>
      ${returnMessage}
      ${getBookingDetailsHTML(booking)}
      ${getEmailFooter()}
    `
  };
} 
