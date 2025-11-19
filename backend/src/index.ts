import express from "express";
import morgan from "morgan";
import session from "express-session";
import { config } from "./config";
import { ensureConnection, closeConnection } from "./db";
import { attachUser, requireAuth } from "./middleware/auth";
import { authRouter } from "./routes/auth";
import { messagesRouter } from "./routes/messages";
import { attachmentsRouter } from "./routes/attachments";
import { webhooksRouter } from "./routes/webhooks";

const app = express();

// Basic error handling for app initialization
try {
  // CORS removed - not needed for mobile apps (React Native, Flutter, etc.)
  // Mobile apps make direct HTTP requests, not browser requests
  app.use(express.json({ limit: "2mb" }));
  app.use(morgan("dev"));
  
  const sessionSecret = process.env.SESSION_SECRET;
  if (!sessionSecret && process.env.VERCEL) {
    console.warn("WARNING: SESSION_SECRET not set in Vercel environment variables!");
  }
  
  app.use(
    session({
      secret: sessionSecret ?? "change-me-in-production",
      resave: false,
      saveUninitialized: false,
      cookie: {
        secure: process.env.NODE_ENV === "production",
        httpOnly: true,
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

// Initialize database on first request (for serverless) - non-blocking
app.use(async (_req, _res, next) => {
  // Don't await - let it initialize in background
  initializeDatabase().catch((error) => {
    console.error("Background database initialization error:", error);
  });
  next();
});

app.use("/api/auth", authRouter);
app.use("/api/messages", requireAuth, messagesRouter);
app.use("/api/attachments", requireAuth, attachmentsRouter);
// Webhooks - handle both JSON and raw email bodies
app.use("/api/webhooks/cloudflare", express.raw({ type: ["application/json", "text/plain", "message/rfc822"], limit: "10mb" }), webhooksRouter);
app.use("/api/webhooks", express.json({ limit: "10mb" }), webhooksRouter);

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
  const port = process.env.PORT || config.port;
  app.listen(port, () => {
    console.log(`API listening on port ${port}`);
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

