import express, { Express } from "express";
import cors from "cors";
import morgan from "morgan";
import session from "express-session";
import MongoStore from "connect-mongo";
import { config } from "./config";
import { ensureConnection, closeConnection } from "./db";
import { attachUser, requireAuth } from "./middleware/auth";
import { authRouter } from "./routes/auth";
import { messagesRouter } from "./routes/messages";
import { attachmentsRouter } from "./routes/attachments";
import { webhooksRouter } from "./routes/webhooks";
import { domainsRouter } from "./routes/domains";
import { emailsRouter } from "./routes/emails";
import { inboxesRouter } from "./routes/inboxes";
import { docsRouter } from "./routes/docs";
import { uploadsRouter } from "./routes/uploads";
import aiRouter from "./routes/ai.routes";

const app: Express = express();

// Required so Express marks cookies as secure when behind a proxy (Vercel, Render, etc.)
const trustProxyHops = parseInt(process.env.TRUST_PROXY_HOPS ?? "1", 10);
app.set("trust proxy", trustProxyHops);

// Basic error handling for app initialization
try {
  const allowedOrigins = (config.corsOrigins?.split(",") || [config.frontendUrl]).map((origin) =>
    origin.trim()
  );

  const corsOptions: cors.CorsOptions = {
    origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
      if (!origin) {
        return callback(null, true); // Allow server-to-server or curl
      }

      if (allowedOrigins.includes(origin)) {
        return callback(null, true);
      }

      return callback(new Error(`Origin ${origin} not allowed by CORS policy`));
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  };

  app.use(cors(corsOptions));

  // Register uploads route BEFORE express.json() to prevent JSON parsing of multipart data
  // MOVED: to after session middleware to ensure auth works
  // app.use("/api/uploads", requireAuth, uploadsRouter);

  app.use(express.json({ limit: "25mb" })); // Increased for attachment URLs
  app.use(morgan("dev"));

  const sessionSecret = process.env.SESSION_SECRET;
  if (!sessionSecret && process.env.VERCEL) {
    console.warn("WARNING: SESSION_SECRET not set in Vercel environment variables!");
  }

  // ...

  app.use(
    session({
      secret: sessionSecret ?? "change-me-in-production",
      resave: false,
      saveUninitialized: false,
      store: MongoStore.create({
        mongoUrl: config.database.url,
        ttl: 14 * 24 * 60 * 60, // 14 days
      }),
      cookie: {
        secure: process.env.NODE_ENV === "production",
        httpOnly: true,
        sameSite: process.env.NODE_ENV === "production" ? "none" : "lax",
        maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
      },
    })
  );
} catch (error) {
  console.error("Failed to initialize Express middleware:", error);
  // Don't throw - let the app continue so we can return error responses
}
app.use(attachUser);

// Root endpoint for testing
app.get("/", (_req, res) => {
  res.json({
    message: "Free-mail API",
    status: "running",
    endpoints: {
      health: "/health",
      auth: "/api/auth",
      messages: "/api/messages",
      webhooks: "/api/webhooks"
    }
  });
});

// Health endpoint - should work even if DB is down
app.get("/health", async (_req, res) => {
  try {
    await ensureConnection();
    res.json({ status: "ok", database: "connected", timestamp: new Date().toISOString() });
  } catch (error) {
    // Health endpoint should still return 200 even if DB is down
    // This allows monitoring to detect if the function itself is working
    res.status(200).json({
      status: "ok",
      database: "disconnected",
      error: error instanceof Error ? error.message : "unknown error",
      timestamp: new Date().toISOString()
    });
  }
});

app.get("/api/status", (_req, res) => {
  res.json({
    status: "ok",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    env: process.env.NODE_ENV ?? "development",
  });
});

// Initialize database on first request (for serverless) - non-blocking
app.use(async (_req, _res, next) => {
  // Don't await - let it initialize in background
  initializeDatabase().catch((error) => {
    console.error("Background database initialization error:", error);
  });
  next();
});

import { usersRouter } from "./routes/users";

app.use("/api/auth", authRouter);
app.use("/api/users", usersRouter);
app.use("/api/domains", requireAuth, domainsRouter);
app.use("/api/emails", requireAuth, emailsRouter);
app.use("/api/inboxes", requireAuth, inboxesRouter);
app.use("/api/messages", requireAuth, messagesRouter);
app.use("/api/attachments", requireAuth, attachmentsRouter);
app.use("/api/uploads", requireAuth, uploadsRouter);
app.use("/api/ai", requireAuth, aiRouter);
// Webhooks - Cloudflare Worker sends JSON, so use express.json() for that route
// Other webhook routes can use raw for direct email forwarding
app.use("/api/webhooks/cloudflare", express.json({ limit: "25mb" }), webhooksRouter);
app.use("/api/webhooks", express.raw({ type: ["text/plain", "message/rfc822"], limit: "25mb" }), webhooksRouter);
app.use("/docs", docsRouter);

// Error handler - must be last
app.use((err: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error("Error handler:", err);
  const errorMessage = err instanceof Error ? err.message : "internal server error";
  const errorStack = err instanceof Error ? err.stack : undefined;

  // Log full error in serverless environment
  if (process.env.VERCEL) {
    console.error("Full error:", errorStack || errorMessage);
  }

  res.status(500).json({
    error: "internal server error",
    message: process.env.NODE_ENV === "development" ? errorMessage : undefined
  });
});

// Initialize database connection on app start (for serverless, this runs on first request)
let dbInitialized = false;
async function initializeDatabase() {
  if (!dbInitialized) {
    try {
      await ensureConnection();
      dbInitialized = true;
    } catch (error) {
      console.error("Database connection error:", error);
      // Don't throw - let individual requests handle connection retries
    }
  }
}

async function bootstrap() {
  await ensureConnection();
  const port = Number(process.env.PORT || config.port);
  app.listen(port, "0.0.0.0", () => {
    const os = require("os");
    const networks = os.networkInterfaces();
    let ipAddress = "localhost";

    // Find the first non-internal IPv4 address
    for (const name of Object.keys(networks)) {
      for (const net of networks[name] || []) {
        if (net.family === "IPv4" && !net.internal) {
          ipAddress = net.address;
          break;
        }
      }
      if (ipAddress !== "localhost") break;
    }

    console.log(`API listening on port ${port}`);
    console.log(`Local Network URL: http://${ipAddress}:${port}`);
  });
}

// Graceful shutdown
process.on("SIGINT", async () => {
  console.log("Shutting down...");
  await closeConnection();
  process.exit(0);
});

process.on("SIGTERM", async () => {
  console.log("Shutting down...");
  await closeConnection();
  process.exit(0);
});

// Only start server if not in Vercel (serverless)
if (process.env.VERCEL !== "1") {
  bootstrap().catch((error) => {
    console.error("Failed to start server", error);
    process.exit(1);
  });
}

// Export for Vercel serverless
export default app;

