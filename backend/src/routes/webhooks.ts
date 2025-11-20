import { Router } from "express";
import { simpleParser, type Attachment } from "mailparser";
import { config } from "../config";
import { createMessage, addAttachment } from "../repositories/messages";
import { uploadBufferToCatbox } from "../services/catbox";
import { getUserByEmail } from "../repositories/users";
import { getEmailByAddress } from "../repositories/emails";

export const webhooksRouter = Router();

webhooksRouter.post("/cloudflare", async (req, res, next) => {
  try {
    const secretHeader = req.header("x-webhook-secret");
    console.log("Webhook received - Secret header present:", !!secretHeader);
    
    if (config.security.webhookSecret && secretHeader !== config.security.webhookSecret) {
      console.error("Webhook secret mismatch. Expected:", config.security.webhookSecret?.substring(0, 5) + "...", "Got:", secretHeader?.substring(0, 5) + "...");
      return res.status(403).json({ error: "invalid webhook secret" });
    }

    // Cloudflare Worker sends JSON with rawEmail field (base64 encoded)
    let rawEmail: string;

    const contentType = req.header("content-type") || "";
    console.log("Webhook Content-Type:", contentType);
    console.log("Webhook body type:", typeof req.body, "Is Buffer:", Buffer.isBuffer(req.body));

    // Cloudflare Worker sends JSON with rawEmail field (base64 encoded)
    if (contentType.includes("application/json") && req.body && typeof req.body === "object" && !Buffer.isBuffer(req.body)) {
      if ("rawEmail" in req.body) {
        const body = req.body as { rawEmail: string };
        console.log("Found rawEmail in JSON body, length:", body.rawEmail?.length);
        rawEmail = Buffer.from(body.rawEmail, "base64").toString("utf-8");
        console.log("Decoded email length:", rawEmail.length);
      } else {
        console.error("JSON body missing rawEmail field. Body keys:", Object.keys(req.body));
        return res.status(400).json({ error: "rawEmail field is required in JSON body" });
      }
    }
    // Fallback: Try to parse as Buffer (shouldn't happen with express.json, but just in case)
    else if (Buffer.isBuffer(req.body)) {
      try {
        const jsonBody = JSON.parse(req.body.toString());
        if (jsonBody.rawEmail) {
          rawEmail = Buffer.from(jsonBody.rawEmail, "base64").toString("utf-8");
        } else {
          console.error("Buffer body missing rawEmail field");
          return res.status(400).json({ error: "rawEmail field is required" });
        }
      } catch (parseError) {
        console.error("Failed to parse Buffer as JSON:", parseError);
        return res.status(400).json({ error: "invalid JSON format" });
      }
    }
    // Fallback: String body
    else if (typeof req.body === "string") {
      try {
        const jsonBody = JSON.parse(req.body);
        if (jsonBody.rawEmail) {
          rawEmail = Buffer.from(jsonBody.rawEmail, "base64").toString("utf-8");
        } else {
          return res.status(400).json({ error: "rawEmail field is required" });
        }
      } catch {
        rawEmail = req.body;
      }
    }
    else {
      console.error("Unsupported body type:", typeof req.body);
      return res.status(400).json({ error: "unsupported content type or missing body" });
    }

    if (!rawEmail || rawEmail.trim().length === 0) {
      console.error("Webhook received empty rawEmail. Content-Type:", contentType);
      console.error("Body type:", typeof req.body, "Is Buffer:", Buffer.isBuffer(req.body));
      return res.status(400).json({ error: "rawEmail is required and cannot be empty" });
    }

    console.log("Parsing email with mailparser...");
    const parsed = await simpleParser(rawEmail);
    console.log("Email parsed successfully. Subject:", parsed.subject);
    
    // Extract sender email address
    let senderEmail: string | null = null;
    if (Array.isArray(parsed.from)) {
      const firstFrom = parsed.from[0];
      senderEmail = ((firstFrom as any).address || firstFrom.text?.match(/<([^>]+)>/)?.[1] || firstFrom.text || "").toLowerCase();
    } else if (parsed.from) {
      senderEmail = ((parsed.from as any).address || parsed.from.text?.match(/<([^>]+)>/)?.[1] || parsed.from.text || "").toLowerCase();
    }
    
    // Extract recipient email addresses
    const recipientEmails: string[] = [];
    if (Array.isArray(parsed.to)) {
      parsed.to.forEach(addr => {
        const email = (addr as any).address || addr.text?.match(/<([^>]+)>/)?.[1] || addr.text;
        if (email) recipientEmails.push(email.toLowerCase());
      });
    } else if (parsed.to) {
      const email = (parsed.to as any).address || parsed.to.text?.match(/<([^>]+)>/)?.[1] || parsed.to.text;
      if (email) recipientEmails.push(email.toLowerCase());
    }
    
    console.log("From:", senderEmail, "To:", recipientEmails);
    
    // Validate that at least one recipient email exists in the database
    let validEmailRecord = null;
    for (const recipientEmail of recipientEmails) {
      const emailRecord = await getEmailByAddress(recipientEmail);
      if (emailRecord) {
        validEmailRecord = emailRecord;
        console.log("Found valid email address:", recipientEmail);
        break;
      }
    }
    
    if (!validEmailRecord) {
      console.error("Rejecting email: No valid recipient found. Recipients:", recipientEmails);
      // Return 200 to prevent Cloudflare from retrying, but log the rejection
      return res.status(200).json({ 
        message: "Email rejected - recipient not found",
        rejected: true 
      });
    }
    
    const userId = validEmailRecord.user_id;
    const inboxId = validEmailRecord.inbox_id;
    
    const htmlBody = typeof parsed.html === "string" ? parsed.html : null;
    const textBody = parsed.text ?? null;

    console.log("Creating message record in database for inbox:", inboxId);
    const record = await createMessage({
      userId,
      inboxId,
      direction: "inbound",
      subject: parsed.subject ?? "(no subject)",
      senderEmail,
      recipientEmails,
      previewText: textBody?.slice(0, 120) ?? htmlBody?.replace(/<[^>]+>/g, "").slice(0, 120) ?? "",
      bodyPlain: textBody,
      bodyHtml: htmlBody,
      status: "received",
    });
    console.log("Message created with ID:", record.id);

    const attachments = parsed.attachments as Attachment[] | undefined;
    if (attachments?.length) {
      console.log("Processing", attachments.length, "attachments...");
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
          console.log("Attachment uploaded:", att.filename);
          return url;
        })
      );
    }

    console.log("Webhook processed successfully");
    return res.status(204).send();
  } catch (error) {
    console.error("Error processing webhook:", error);
    if (error instanceof Error) {
      console.error("Error stack:", error.stack);
    }
    next(error);
  }
});

