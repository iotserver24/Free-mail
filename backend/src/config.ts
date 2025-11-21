import dotenv from "dotenv";

dotenv.config();

const isServerless = process.env.VERCEL === "1" || process.env.NODE_ENV === "production";

function getRequiredEnv(key: string, fallback?: string) {
  const value = process.env[key] ?? fallback;
  if (!value && isServerless) {
    throw new Error(
      `Missing required environment variable "${key}". ` +
      `Serverless deployments (Vercel/production) must set this variable to avoid runtime failures.`
    );
  }
  return value ?? "";
}

const databaseUrl =
  process.env.MONGODB_URL ??
  (!isServerless ? "mongodb://localhost:27017/freemail" : undefined);

if (!databaseUrl) {
  throw new Error(
    'MONGODB_URL is not set. Provide a remote MongoDB connection string via environment variable (see `VERCEL_DEPLOY.md`).'
  );
}

const defaultFrontendUrl = "http://localhost:3000";
const defaultCorsOrigins = ["http://localhost:5173", defaultFrontendUrl].join(",");

export const config = {
  port: parseInt(process.env.PORT ?? "4000", 10),
  frontendUrl: process.env.FRONTEND_URL ?? defaultFrontendUrl,
  corsOrigins: process.env.CORS_ORIGINS ?? defaultCorsOrigins,
  brevo: {
    host: process.env.BREVO_SMTP_HOST ?? "smtp-relay.brevo.com",
    port: parseInt(process.env.BREVO_SMTP_PORT ?? "587", 10),
    user: process.env.BREVO_SMTP_USER ?? "",
    pass: process.env.BREVO_SMTP_PASS ?? "",
    sender: process.env.BREVO_SENDER ?? "", // Optional fallback (users should provide their own 'from' address)
  },
  database: {
    url: databaseUrl,
  },
  security: {
    webhookSecret: getRequiredEnv("CF_WEBHOOK_SECRET"),
  },
  catbox: {
    apiUrl: process.env.CATBOX_API_URL ?? "https://catbox.moe/user/api.php",
  },
  admin: {
    email: getRequiredEnv("ADMIN_EMAIL", "admin@example.com"),
    password: getRequiredEnv("ADMIN_PASSWORD", "admin123"),
  },
};

