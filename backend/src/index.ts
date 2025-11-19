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

// CORS removed - not needed for mobile apps (React Native, Flutter, etc.)
// Mobile apps make direct HTTP requests, not browser requests
app.use(express.json({ limit: "2mb" }));
app.use(morgan("dev"));
app.use(
  session({
    secret: process.env.SESSION_SECRET ?? "change-me-in-production",
    resave: false,
    saveUninitialized: false,
    cookie: {
      secure: process.env.NODE_ENV === "production",
      httpOnly: true,
      maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
    },
  })
);
// Initialize database on first request (for serverless)
app.use(async (_req, _res, next) => {
  await initializeDatabase();
  next();
});

app.use(attachUser);

app.get("/health", async (_req, res) => {
  try {
    await ensureConnection();
    res.json({ status: "ok", database: "connected" });
  } catch (error) {
    res.status(503).json({ status: "error", database: "disconnected" });
  }
});

app.use("/api/auth", authRouter);
app.use("/api/messages", requireAuth, messagesRouter);
app.use("/api/attachments", requireAuth, attachmentsRouter);
// Webhooks - handle both JSON and raw email bodies
app.use("/api/webhooks/cloudflare", express.raw({ type: ["application/json", "text/plain", "message/rfc822"], limit: "10mb" }), webhooksRouter);
app.use("/api/webhooks", express.json({ limit: "10mb" }), webhooksRouter);

app.use((err: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err);
  res.status(500).json({ error: "internal server error" });
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

