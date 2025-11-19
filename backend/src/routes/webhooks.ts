import { Router } from "express";
import { simpleParser, type Attachment } from "mailparser";
import { config } from "../config";
import { createMessage, addAttachment } from "../repositories/messages";
import { uploadBufferToCatbox } from "../services/catbox";
import { getUserByEmail } from "../repositories/users";

export const webhooksRouter = Router();

webhooksRouter.post("/cloudflare", async (req, res, next) => {
  try {
    const secretHeader = req.header("x-webhook-secret");
    if (config.security.webhookSecret && secretHeader !== config.security.webhookSecret) {
      return res.status(403).json({ error: "invalid webhook secret" });
    }

    // Cloudflare Email Routing can send emails in different formats
    // Try to handle multiple formats:
    let rawEmail: string;
    
    // Get admin user ID from database
    const adminUser = await getUserByEmail(config.admin.email);
    if (!adminUser) {
      return res.status(500).json({ error: "admin user not found" });
    }
    const userId = adminUser.id;

    const contentType = req.header("content-type") || "";

    // Format 1: JSON with rawEmail field (base64 encoded)
    if (contentType.includes("application/json") && req.body && typeof req.body === "object" && !Buffer.isBuffer(req.body)) {
      if ("rawEmail" in req.body) {
        const body = req.body as { rawEmail: string };
        rawEmail = Buffer.from(body.rawEmail, "base64").toString("utf-8");
      } else if ("email" in req.body) {
        const body = req.body as { email: string };
        rawEmail = typeof body.email === "string" ? body.email : JSON.stringify(body.email);
      } else {
        // Try to parse as JSON string
        try {
          const parsed = JSON.parse(req.body.toString());
          if (parsed.rawEmail) {
            rawEmail = Buffer.from(parsed.rawEmail, "base64").toString("utf-8");
          } else {
            rawEmail = req.body.toString();
          }
        } catch {
          rawEmail = req.body.toString();
        }
      }
    }
    // Format 2: Raw email in request body (Buffer from express.raw)
    else if (Buffer.isBuffer(req.body)) {
      // Check if it's JSON
      try {
        const jsonBody = JSON.parse(req.body.toString());
        if (jsonBody.rawEmail) {
          rawEmail = Buffer.from(jsonBody.rawEmail, "base64").toString("utf-8");
        } else {
          rawEmail = req.body.toString("utf-8");
        }
      } catch {
        // Not JSON, treat as raw email
        rawEmail = req.body.toString("utf-8");
      }
    }
    // Format 3: Raw email in request body (plain text string)
    else if (typeof req.body === "string") {
      rawEmail = req.body;
    }
    // Format 4: Try to get from raw body
    else {
      rawEmail = req.body?.toString() || "";
    }

    if (!rawEmail || rawEmail.trim().length === 0) {
      console.error("Webhook received invalid payload. Content-Type:", contentType);
      console.error("Body type:", typeof req.body, "Is Buffer:", Buffer.isBuffer(req.body));
      return res.status(400).json({ error: "rawEmail is required" });
    }

    const parsed = await simpleParser(rawEmail);
    const htmlBody = typeof parsed.html === "string" ? parsed.html : null;
    const textBody = parsed.text ?? null;

    const record = await createMessage({
      userId,
      direction: "inbound",
      subject: parsed.subject ?? "(no subject)",
      previewText: textBody?.slice(0, 120) ?? htmlBody?.replace(/<[^>]+>/g, "").slice(0, 120) ?? "",
      bodyPlain: textBody,
      bodyHtml: htmlBody,
      status: "received",
    });

    const attachments = parsed.attachments as Attachment[] | undefined;
    if (attachments?.length) {
      await Promise.all(
        attachments.map(async (att) => {
          const url = await uploadBufferToCatbox(att.filename ?? "attachment.bin", att.content);
          await addAttachment({
            messageId: record.id,
            filename: att.filename ?? "attachment.bin",
            mimetype: att.contentType ?? "application/octet-stream",
            size: att.size ?? att.content.length,
            url,
          });
          return url;
        })
      );
    }

    return res.status(204).send();
  } catch (error) {
    next(error);
  }
});

