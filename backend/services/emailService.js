import dotenv from "dotenv";
import nodemailer from "nodemailer";

dotenv.config();

// Create transporter using Brevo SMTP
const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST || "smtp-relay.brevo.com",
  port: process.env.EMAIL_PORT || 587,
  secure: false,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// Send camp credentials email to camp manager
export const sendCampCredentials = async (campData) => {
  const {
    recipientEmail,
    campName,
    campId,
    managerName,
    password,
    location,
  } = campData;

  const emailContent = `
    <html>
      <body style="font-family: Arial, sans-serif; color: #333;">
        <div style="max-width: 600px; margin: 0 auto;">
          <h2 style="color: #d9534f;">Sahaya - Camp Manager Credentials</h2>
          
          <p>Hi <strong>${managerName}</strong>,</p>
          
          <p>Your camp has been successfully registered in the Sahaya Disaster Management System. Here are your login credentials:</p>
          
          <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
            <tr style="background-color: #f5f5f5;">
              <td style="padding: 10px; border: 1px solid #ddd;"><strong>Camp Name</strong></td>
              <td style="padding: 10px; border: 1px solid #ddd;">${campName}</td>
            </tr>
            <tr>
              <td style="padding: 10px; border: 1px solid #ddd;"><strong>Camp ID</strong></td>
              <td style="padding: 10px; border: 1px solid #ddd;"><code>${campId}</code></td>
            </tr>
            <tr style="background-color: #f5f5f5;">
              <td style="padding: 10px; border: 1px solid #ddd;"><strong>Email</strong></td>
              <td style="padding: 10px; border: 1px solid #ddd;">${recipientEmail}</td>
            </tr>
            <tr>
              <td style="padding: 10px; border: 1px solid #ddd;"><strong>Password</strong></td>
              <td style="padding: 10px; border: 1px solid #ddd;"><code>${password}</code></td>
            </tr>
            <tr style="background-color: #f5f5f5;">
              <td style="padding: 10px; border: 1px solid #ddd;"><strong>Location</strong></td>
              <td style="padding: 10px; border: 1px solid #ddd;">${location}</td>
            </tr>
          </table>
          
          <p style="color: #d9534f;"><strong>Important:</strong> Please change your password after your first login for security purposes.</p>
          
          <p>If you have any questions or need assistance, please contact the Sahaya support team.</p>
          
          <p style="margin-top: 30px; color: #666; font-size: 12px;">
            This is an automated email. Please do not reply to this address.
          </p>
        </div>
      </body>
    </html>
  `;

  try {
    const mailOptions = {
      from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
      to: recipientEmail,
      subject: `Sahaya Account Created - Camp Manager Credentials [${campId}]`,
      html: emailContent,
      text: `
Camp Manager Credentials
========================

Camp Name: ${campName}
Camp ID: ${campId}
Email: ${recipientEmail}
Password: ${password}
Location: ${location}

Important: Please change your password after your first login.
      `,
    };

    const result = await transporter.sendMail(mailOptions);
    console.log(`✅ Email sent successfully to ${recipientEmail}:`, result.messageId);
    return result;
  } catch (error) {
    console.error(`❌ Email send failed for ${recipientEmail}:`, error);
    throw error;
  }
};

// Send verification OTP email
export const sendVerificationEmail = async (email, otp) => {
  const emailContent = `
    <html>
      <body style="font-family: Arial, sans-serif; color: #333;">
        <div style="max-width: 600px; margin: 0 auto;">
          <h2 style="color: #d9534f;">Sahaya - Email Verification</h2>
          
          <p>Your email verification OTP is:</p>
          
          <h1 style="text-align: center; color: #d9534f; letter-spacing: 5px; font-size: 32px;">${otp}</h1>
          
          <p style="margin-top: 20px;">This OTP will expire in 10 minutes.</p>
          
          <p style="color: #666; font-size: 12px;">
            If you didn't request this, please ignore this email.
          </p>
        </div>
      </body>
    </html>
  `;

  try {
    const mailOptions = {
      from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
      to: email,
      subject: "Sahaya - Email Verification OTP",
      html: emailContent,
      text: `Your email verification OTP is: ${otp}\n\nThis OTP will expire in 10 minutes.`,
    };

    const result = await transporter.sendMail(mailOptions);
    console.log(`✅ Verification email sent to ${email}`);
    return result;
  } catch (error) {
    console.error(`❌ Verification email send failed for ${email}:`, error);
    throw error;
  }
};

// Send disaster alert notification email
export const sendDisasterAlert = async (email, disasterData) => {
  const { disasterName, location, disasterType, severity, description } = disasterData;

  const emailContent = `
    <html>
      <body style="font-family: Arial, sans-serif; color: #333;">
        <div style="max-width: 600px; margin: 0 auto;">
          <h2 style="color: #d9534f;">🚨 SAHAYA - DISASTER ALERT</h2>
          
          <p><strong>A new disaster has been registered in the system:</strong></p>
          
          <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
            <tr style="background-color: #f5f5f5;">
              <td style="padding: 10px; border: 1px solid #ddd;"><strong>Disaster Name</strong></td>
              <td style="padding: 10px; border: 1px solid #ddd;">${disasterName}</td>
            </tr>
            <tr>
              <td style="padding: 10px; border: 1px solid #ddd;"><strong>Type</strong></td>
              <td style="padding: 10px; border: 1px solid #ddd;">${disasterType}</td>
            </tr>
            <tr style="background-color: #f5f5f5;">
              <td style="padding: 10px; border: 1px solid #ddd;"><strong>Severity</strong></td>
              <td style="padding: 10px; border: 1px solid #ddd;"><span style="background-color: #d9534f; color: white; padding: 5px; border-radius: 3px;">${severity}</span></td>
            </tr>
            <tr>
              <td style="padding: 10px; border: 1px solid #ddd;"><strong>Location</strong></td>
              <td style="padding: 10px; border: 1px solid #ddd;">${location}</td>
            </tr>
            <tr style="background-color: #f5f5f5;">
              <td style="padding: 10px; border: 1px solid #ddd;"><strong>Description</strong></td>
              <td style="padding: 10px; border: 1px solid #ddd;">${description}</td>
            </tr>
          </table>
          
          <p>Please log in to your Sahaya account to view more details and take appropriate actions.</p>
          
          <p style="color: #666; font-size: 12px;">
            This is an automated alert from the Sahaya Disaster Management System.
          </p>
        </div>
      </body>
    </html>
  `;

  try {
    const mailOptions = {
      from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
      to: email,
      subject: `🚨 SAHAYA ALERT - ${disasterType} in ${location}`,
      html: emailContent,
      text: `Disaster Alert: ${disasterName}\nType: ${disasterType}\nSeverity: ${severity}\nLocation: ${location}`,
    };

    const result = await transporter.sendMail(mailOptions);
    console.log(`✅ Disaster alert email sent to ${email}`);
    return result;
  } catch (error) {
    console.error(`❌ Disaster alert email send failed for ${email}:`, error);
    throw error;
  }
};

export default transporter;
