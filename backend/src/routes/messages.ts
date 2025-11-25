import { Router } from "express";
import axios from "axios";
import { sendBrevoMail } from "../services/mailer";
import {
  addAttachment,
  createMessage,
  getMessageById,
  getThreadMessages,
  listAttachments,
  listMessages,
  updateMessage,
} from "../repositories/messages";
import { getEmailByAddress } from "../repositories/emails";

export const messagesRouter: Router = Router();

messagesRouter.get("/", async (req, res, next) => {
  try {
    const inboxId = req.query.inboxId as string | undefined;
    const folder = req.query.folder as string | undefined;
    const isStarred = req.query.isStarred === 'true' ? true : req.query.isStarred === 'false' ? false : undefined;
    const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 25;
    const records = await listMessages(req.userId!, inboxId || undefined, folder, isStarred, limit);
    return res.json(records);
  } catch (error) {
    next(error);
  }
});

// Get messages for a specific inbox
messagesRouter.get("/inbox/:inboxId", async (req, res, next) => {
  try {
    const { inboxId } = req.params;
    const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 25;
    const folder = req.query.folder as string | undefined;
    const isStarred = req.query.isStarred === 'true' ? true : req.query.isStarred === 'false' ? false : undefined;
    const records = await listMessages(req.userId!, inboxId, folder, isStarred, limit);
    return res.json(records);
  } catch (error) {
    next(error);
  }
});

messagesRouter.get("/thread/:threadId", async (req, res, next) => {
  try {
    const { threadId } = req.params;
    const records = await getThreadMessages(req.userId!, threadId);
    const withAttachments = await Promise.all(
      records.map(async (record) => {
        const attachments = await listAttachments(record.id);
        return { ...record, attachments };
      })
    );
    return res.json(withAttachments);
  } catch (error) {
    next(error);
  }
});

messagesRouter.get("/:id", async (req, res, next) => {
  try {
    const record = await getMessageById(req.userId!, req.params.id);
    if (!record) {
      return res.status(404).json({ error: "message not found" });
    }
    const attachments = await listAttachments(record.id);
    return res.json({ ...record, attachments });
  } catch (error) {
    next(error);
  }
});

messagesRouter.patch("/:id", async (req, res, next) => {
  try {
    const { is_read, folder, is_starred } = req.body;
    const updates: { is_read?: boolean; folder?: any; is_starred?: boolean } = {};

    if (typeof is_read === "boolean") {
      updates.is_read = is_read;
    }
    if (folder) {
      updates.folder = folder;
    }
    if (typeof is_starred === "boolean") {
      updates.is_starred = is_starred;
    }

    const record = await updateMessage(req.userId!, req.params.id, updates);
    if (!record) {
      return res.status(404).json({ error: "message not found" });
    }
    return res.json(record);
  } catch (error) {
    next(error);
  }
});

interface AttachmentPayload {
  filename: string;
  url: string; // Catbox URL (required for frontend uploads)
  contentType?: string;
}

messagesRouter.post("/", async (req, res, next) => {
  try {
    const { from, to, cc, bcc, subject, html, text, threadId, attachments = [] }: { from?: string; to: string[]; cc?: string[]; bcc?: string[]; subject: string; html?: string; text?: string; threadId?: string | null; attachments?: AttachmentPayload[] } = req.body;

    if (!Array.isArray(to) || to.length === 0) {
      return res.status(400).json({ error: "at least one recipient required" });
    }

    if (!from || !from.trim()) {
      return res.status(400).json({ error: "from address is required" });
    }

    // All attachments should have URLs (uploaded to Catbox from frontend)
    const resolvedAttachments = await Promise.all(
      attachments.map(async (item) => {
        if (!item.url) {
          throw new Error(`Attachment ${item.filename} missing URL`);
        }

        // Download file from Catbox URL
        const response = await axios.get<ArrayBuffer>(item.url, { responseType: "arraybuffer" });
        return {
          filename: item.filename,
          content: Buffer.from(response.data as ArrayBuffer),
          contentType: item.contentType ?? undefined,
        };
      })
    );

    await sendBrevoMail({
      from: from.trim(),
      to,
      cc,
      bcc,
      subject,
      html,
      text,
      attachments: resolvedAttachments,
    });

    // Get inbox_id from the "from" email address if provided
    let inboxId: string | null = null;
    if (from) {
      const emailRecord = await getEmailByAddress(from.trim());
      if (emailRecord && emailRecord.user_id === req.userId!) {
        inboxId = emailRecord.inbox_id;
      }
    }

    const record = await createMessage({
      userId: req.userId!,
      inboxId,
      direction: "outbound",
      subject,
      senderEmail: from.trim(),
      recipientEmails: [...to, ...(cc || []), ...(bcc || [])],
      threadId: threadId || null,
      previewText: text?.slice(0, 120) ?? html?.replace(/<[^>]+>/g, "").slice(0, 120) ?? "",
      bodyPlain: text ?? null,
      bodyHtml: html ?? null,
      status: "sent",
    });

    await Promise.all(
      resolvedAttachments.map((att) => {
        const attachmentPayload = attachments.find((a) => a.filename === att.filename);
        return addAttachment({
          messageId: record.id,
          filename: att.filename,
          mimetype: att.contentType ?? "application/octet-stream",
          size: att.content.length,
          url: attachmentPayload?.url ?? "", // Use the Catbox URL from the payload
        });
      })
    );

    return res.status(202).json(record);
  } catch (error) {
    next(error);
  }
});

