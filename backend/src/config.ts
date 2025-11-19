import dotenv from "dotenv";

dotenv.config();

export const config = {
  port: parseInt(process.env.PORT ?? "4000", 10),
  brevo: {
    host: process.env.BREVO_SMTP_HOST ?? "smtp-relay.brevo.com",
    port: parseInt(process.env.BREVO_SMTP_PORT ?? "587", 10),
    user: process.env.BREVO_SMTP_USER ?? "",
    pass: process.env.BREVO_SMTP_PASS ?? "",
    sender: process.env.BREVO_SENDER ?? "", // Optional fallback (users should provide their own 'from' address)
  },
  database: {
    url: process.env.MONGODB_URL ?? "mongodb://localhost:27017/freemail",
  },
  security: {
    webhookSecret: process.env.CF_WEBHOOK_SECRET ?? "",
  },
  catbox: {
    apiUrl: process.env.CATBOX_API_URL ?? "https://catbox.moe/user/api.php",
  },
  admin: {
    email: process.env.ADMIN_EMAIL ?? "admin@example.com",
    password: process.env.ADMIN_PASSWORD ?? "admin123",
  },
};

