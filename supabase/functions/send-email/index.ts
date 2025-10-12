// Access Deno runtime safely via globalThis so TypeScript doesn't error in non-Deno environments
const denoRuntime: any = (globalThis as any).Deno;
const _envGet: ((k: string) => string | undefined) | undefined = denoRuntime?.env?.get?.bind(denoRuntime?.env);
const BREVO_API_KEY = _envGet ? _envGet('BREVO_API_KEY') : undefined;
const BREVO_SENDER_EMAIL = _envGet ? _envGet('BREVO_SENDER_EMAIL') : undefined;

// Email template functions (inline, matching src/services/mailTemplates.js)
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

function getStatusUpdateEmail(booking: Booking, statusMsg = 'updated') {
  return {
    subject: `Outing Request ${statusMsg}`,
    html: `
      <p>Dear Parent,</p>
      <p>
        This is to inform you that your child <b>${booking.name}</b> (<a href="mailto:${booking.email}">${booking.email}</a>) from <b>${booking.hostel_name}</b> has had their outing request <b>${statusMsg}</b> by the hostel administration.
      </p>
      <ul>
        <li><b>Out Date:</b> ${booking.out_date}</li>
        <li><b>Out Time:</b> ${booking.out_time}</li>
        <li><b>In Date:</b> ${booking.in_date}</li>
        <li><b>In Time:</b> ${booking.in_time}</li>
        <li><b>Reason:</b> ${booking.reason}</li>
      </ul>
      <p>
        If you have any questions, please contact your ward's respective hostel administration. <br>
        Contact details are available at: <a href="https://www.srmist.edu.in/srm-hostels/">https://www.srmist.edu.in/srm-hostels/</a> <br>
        <b><i>This is an automated message. Please do not reply.</i></b>
      </p>
    `
  };
}

function getStillOutAlertEmail(booking: Booking) {
  return {
    subject: 'Alert: Your ward is still out',
    html: `
      <p>Dear Parent,</p>
      <p>Your ward <b>${booking.name}</b> (${booking.email}) from <b>${booking.hostel_name}</b> has not returned by the expected time.</p>
      <p>Please contact the hostel administration for more information.</p>
      <p>
        If you have any questions, please contact your ward's respective hostel administration. <br>
        Contact details are available at: <a href="https://www.srmist.edu.in/srm-hostels/">https://www.srmist.edu.in/srm-hostels/</a> <br>
        <b><i>This is an automated message. Please do not reply.</i></b>
      </p>
    `
  };
}

function getNowOutEmail(booking: Booking, wardenEmail?: string) {
  return {
    subject: 'Outing Update: Student is now out',
    html: `
      <p>Dear Parent,</p>
      <p>Your child <b>${booking.name}</b> (<a href="mailto:${booking.email}">${booking.email}</a>) from <b>${booking.hostel_name}</b> has been <b>let out</b> for an outing by the hostel warden.</p>
      <ul>
        <li><b>Out Date:</b> ${booking.out_date}</li>
        <li><b>Out Time:</b> ${booking.out_time}</li>
        <li><b>In Date:</b> ${booking.in_date}</li>
        <li><b>In Time:</b> ${booking.in_time}</li>
        <li><b>Reason:</b> ${booking.reason}</li>
      </ul>
      <p>
        <b>Warden:</b> ${wardenEmail || 'Hostel Warden'}<br>
        If you have any questions, please contact your ward's respective hostel administration. <br>
        Contact details are available at: <a href="https://www.srmist.edu.in/srm-hostels/">https://www.srmist.edu.in/srm-hostels/</a> <br>
        <b><i>This is an automated message. Please do not reply.</i></b>
      </p>
    `
  };
}

function getReturnedEmail(booking: Booking) {
  return {
    subject: 'Outing Update: Student has returned',
    html: `
      <p>Dear Parent,</p>
      <p>Your child <b>${booking.name}</b> (<a href="mailto:${booking.email}">${booking.email}</a>) from <b>${booking.hostel_name}</b> has <b>returned</b> to the hostel after their outing.</p>
      <ul>
        <li><b>Out Date:</b> ${booking.out_date}</li>
        <li><b>Out Time:</b> ${booking.out_time}</li>
        <li><b>In Date:</b> ${booking.in_date}</li>
        <li><b>In Time:</b> ${booking.in_time}</li>
        <li><b>Reason:</b> ${booking.reason}</li>
      </ul>
      <p>
        If you have any questions, please contact your ward's respective hostel administration. <br>
        Contact details are available at: <a href="https://www.srmist.edu.in/srm-hostels/">https://www.srmist.edu.in/srm-hostels/</a> <br>
        <b><i>This is an automated message. Please do not reply.</i></b>
      </p>
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