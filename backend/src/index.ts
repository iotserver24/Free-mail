import express from "express";
import cors from "cors";
import morgan from "morgan";
import session from "express-session";
import { config } from "./config";
import { ensureConnection } from "./db";
import { attachUser, requireAuth } from "./middleware/auth";
import { authRouter } from "./routes/auth";
import { messagesRouter } from "./routes/messages";
import { attachmentsRouter } from "./routes/attachments";
import { webhooksRouter } from "./routes/webhooks";

const app = express();

app.use(
  cors({
    origin: process.env.FRONTEND_URL ?? "http://localhost:5173",
    credentials: true,
  })
);
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
app.use(attachUser);

app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
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

async function bootstrap() {
  await ensureConnection();
  app.listen(config.port, () => {
    console.log(`API listening on port ${config.port}`);
  });
}

bootstrap().catch((error) => {
  console.error("Failed to start server", error);
  process.exit(1);
});

