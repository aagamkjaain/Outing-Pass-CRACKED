// Access Deno runtime safely via globalThis so TypeScript doesn't error in non-Deno environments
const denoRuntime: any = (globalThis as any).Deno;
const _envGet: ((k: string) => string | undefined) | undefined = denoRuntime?.env?.get?.bind(denoRuntime?.env);
const BREVO_API_KEY = _envGet ? _envGet('BREVO_API_KEY') : undefined;
const BREVO_SENDER_EMAIL = _envGet ? _envGet('BREVO_SENDER_EMAIL') : undefined;

// Types
type Booking = {
  name?: string;
  email?: string;
  hostel_name?: string;
  out_date?: string;
  out_time?: string;
  in_date?: string;
  in_time?: string;
  reason?: string;
};

// Shared utility functions
const formatDate = (dateStr: string): string => {
  const date = new Date(dateStr);
  return date.toLocaleDateString('en-IN', { 
    day: 'numeric', 
    month: 'long', 
    year: 'numeric' 
  });
};

const getEmailFooter = (): string => `
  <p>
    If you have any questions, please contact your ward's respective hostel administration. <br>
    Contact details are available at: <a href="https://www.srmist.edu.in/srm-hostels/">https://www.srmist.edu.in/srm-hostels/</a> <br>
    <b><i>This is an automated message. Please do not reply.</i></b>
  </p>
`;

// Email template functions
function getStatusUpdateEmail(booking: Booking, statusMsg = 'rejected') {
  return {
    subject: `Outing Request Rejected`,
    html: `
      <p>Dear Parent,</p>
      <p>
        This is to inform you that your child <b>${booking.name}</b> (<a href="mailto:${booking.email}">${booking.email}</a>) from <b>${booking.hostel_name}</b> has had their outing request <b>rejected</b> by the hostel administration.
      </p>
      <p><b>Request Details:</b></p>
      <ul>
        <li><b>Requested Out Date:</b> ${booking.out_date}</li>
        <li><b>Requested Out Time:</b> ${booking.out_time}</li>
        <li><b>Requested In Date:</b> ${booking.in_date}</li>
        <li><b>Requested In Time:</b> ${booking.in_time}</li>
        <li><b>Reason Provided:</b> ${booking.reason}</li>
      </ul>
      <p>
        If you have any questions regarding this decision, please contact your ward's hostel administration for more information.
      </p>
      ${getEmailFooter()}
    `
  };
}

function getStillOutAlertEmail(booking: Booking) {
  return {
    subject: 'Important Alert: Your ward has not returned from outing',
    html: `
      <p>Dear Parent,</p>
      <p>
        This is an <b>important alert</b> to inform you that your child <b>${booking.name}</b> (<a href="mailto:${booking.email}">${booking.email}</a>) from <b>${booking.hostel_name}</b> has not yet closed their outing request and is still marked as being out of campus.
      </p>
      <p><b>Outing Details:</b></p>
      <ul>
        <li><b>Student Left On:</b> ${formatDate(booking.out_date || '')} at ${booking.out_time || ''}</li>
        <li><b>Expected Return:</b> ${formatDate(booking.in_date || '')} at ${booking.in_time || ''}</li>
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

function getNowOutEmail(booking: Booking, wardenEmail?: string) {
  return {
    subject: 'Outing Approved: Your ward has left the campus',
    html: `
      <p>Dear Parent,</p>
      <p>
        This is to inform you that your child <b>${booking.name}</b> (<a href="mailto:${booking.email}">${booking.email}</a>) from <b>${booking.hostel_name}</b> has been <b>granted permission to leave the campus</b> and has exited the hostel premises.
      </p>
      <p><b>Outing Details:</b></p>
      <ul>
        <li><b>Out Date:</b> ${formatDate(booking.out_date || '')} at ${booking.out_time || ''}</li>
        <li><b>Expected Return:</b> ${formatDate(booking.in_date || '')} at ${booking.in_time || ''}</li>
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

function getReturnedEmail(booking: Booking, closingDate: string | null = null) {
  const outDate = new Date(booking.out_date || '').toDateString();
  const returnDate = closingDate ? new Date(closingDate).toDateString() : new Date().toDateString();
  const isSameDay = outDate === returnDate;
  
  const additionalNote = isSameDay 
    ? `<p>We are pleased to inform you that your ward has followed the proper procedure by closing the outing request on the same day of return to the college. This adherence to safety protocols is appreciated.</p>`
    : `<p><b>Please note:</b> Your ward has closed this outing request on <b>${formatDate(returnDate)}</b>, but the outing was scheduled with an out date of <b>${formatDate(booking.in_date || '')}</b>.</p>
       <p>For safety and security reasons, we strongly request that you guide your ward to close outing requests on the same day they return to the college. This helps us maintain accurate records of student whereabouts and ensures campus security protocols are followed effectively.</p>
       <p>We appreciate your cooperation in helping your ward adhere to this procedure in the future.</p>`;
  
  return {
    subject: 'Outing Update: Student has returned',
    html: `
      <p>Dear Parent,</p>
      <p>Your child <b>${booking.name}</b> (<a href="mailto:${booking.email}">${booking.email}</a>) from <b>${booking.hostel_name}</b> has <b>returned</b> to the hostel after their outing.</p>
      <p><b>Outing Details:</b></p>
      <ul>
        <li><b>Out Date:</b> ${booking.out_date}</li>
        <li><b>Out Time:</b> ${booking.out_time}</li>
        <li><b>In Date:</b> ${booking.in_date}</li>
        <li><b>In Time:</b> ${booking.in_time}</li>
        <li><b>Reason:</b> ${booking.reason}</li>
      </ul>
      ${additionalNote}
      ${getEmailFooter()}
    `
  };
}

export const handler = async (request: Request): Promise<Response> => {
  const urlPath = new URL(request.url).pathname;
  if (urlPath.endsWith("/health")) {
    return new Response(JSON.stringify({ status: "ok" }), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  }

  // Handle preflight OPTIONS request
  if (request.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
      },
    });
  }

  let to, subject, html, template, booking, statusMsg, wardenEmail;
  try {
    const body = await request.json();
    to = body.to;
    subject = body.subject;
    html = body.html;
    template = body.template;
    booking = body.booking;
    statusMsg = body.statusMsg;
    wardenEmail = body.wardenEmail;
    // If using a template, generate subject/html
    if (template && booking) {
      let tpl;
      switch (template) {
        case 'now_out':
          tpl = getNowOutEmail(booking, wardenEmail);
          break;
        case 'returned':
          tpl = getReturnedEmail(booking);
          break;
        case 'status_update':
          tpl = getStatusUpdateEmail(booking, statusMsg || 'updated');
          break;
        case 'still_out':
          tpl = getStillOutAlertEmail(booking);
          break;
        default:
          return new Response(JSON.stringify({ error: "Unknown template" }), {
            status: 400,
            headers: { "Access-Control-Allow-Origin": "*" },
          });
      }
      subject = tpl.subject;
      html = tpl.html;
    }
    if (!to || !subject || !html) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        status: 400,
        headers: { "Access-Control-Allow-Origin": "*" },
      });
    }
  } catch (e) {
    return new Response(JSON.stringify({ error: "Invalid or missing JSON body" }), {
      status: 400,
      headers: { "Access-Control-Allow-Origin": "*" },
    });
  }

  // Debug logging for env vars
  console.log('BREVO_API_KEY defined:', !!BREVO_API_KEY);
  console.log('BREVO_SENDER_EMAIL:', BREVO_SENDER_EMAIL);

  // Brevo API endpoint
  const url = "https://api.brevo.com/v3/smtp/email";

  const payload = {
    sender: { email: BREVO_SENDER_EMAIL },
    to: [{ email: to }],
    subject,
    htmlContent: html,
  };

  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        "api-key": BREVO_API_KEY!,
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify(payload),
    });

    const text = await res.text();
    console.log('Brevo API status:', res.status);
    console.log('Brevo API response:', text);
    let data;
    try {
      data = JSON.parse(text);
    } catch (e) {
      data = { raw: text };
    }

    if (!res.ok) {
      return new Response(JSON.stringify({ error: data.message || "Failed to send email", details: data }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          "Access-Control-Allow-Origin": "*",
        },
      });
    }

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(JSON.stringify({ error: message || "Unknown error" }), {
      status: 500,
      headers: { "Access-Control-Allow-Origin": "*" },
    });
  }
};

// If running under Deno (Supabase Edge), start the server. Otherwise export the handler for compatibility/tests.
if (denoRuntime && typeof denoRuntime.serve === 'function') {
  denoRuntime.serve(handler);
}
