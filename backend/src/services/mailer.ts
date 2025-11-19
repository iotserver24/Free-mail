import nodemailer from "nodemailer";
import { config } from "../config";

export const brevoTransport = nodemailer.createTransport({
  host: config.brevo.host,
  port: config.brevo.port,
  secure: config.brevo.port === 465,
  auth: {
    user: config.brevo.user,
    pass: config.brevo.pass,
  },
});

export interface SendMailInput {
  from: string; // User's email address to send from
  to: string[];
  cc?: string[] | undefined;
  bcc?: string[] | undefined;
  subject: string;
  html?: string | undefined;
  text?: string | undefined;
  attachments?: {
    filename: string;
    content: Buffer;
    contentType?: string | undefined;
  }[];
}

export async function sendBrevoMail(payload: SendMailInput) {
  // Users must provide their own 'from' address
  return brevoTransport.sendMail({
    from: payload.from,
    ...payload,
  });
}

