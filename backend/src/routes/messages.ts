import { Router } from "express";
import axios from "axios";
import { sendBrevoMail } from "../services/mailer";
import { addAttachment, createMessage, getMessageById, listAttachments, listMessages } from "../repositories/messages";

export const messagesRouter = Router();

messagesRouter.get("/", async (req, res, next) => {
  try {
    const records = await listMessages(req.userId!);
    return res.json(records);
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

interface AttachmentPayload {
  filename: string;
  contentBase64?: string;
  url?: string;
  contentType?: string;
}

messagesRouter.post("/", async (req, res, next) => {
  try {
    const { to, cc, bcc, subject, html, text, attachments = [] }: { to: string[]; cc?: string[]; bcc?: string[]; subject: string; html?: string; text?: string; attachments?: AttachmentPayload[] } = req.body;

    if (!Array.isArray(to) || to.length === 0) {
      return res.status(400).json({ error: "at least one recipient required" });
    }

    const resolvedAttachments = await Promise.all(
      attachments.map(async (item) => {
        if (item.contentBase64) {
          return {
            filename: item.filename,
            content: Buffer.from(item.contentBase64, "base64"),
            contentType: item.contentType ?? undefined,
          };
        }
        if (item.url) {
          const response = await axios.get<ArrayBuffer>(item.url, { responseType: "arraybuffer" });
          return {
            filename: item.filename,
            content: Buffer.from(response.data as ArrayBuffer),
            contentType: item.contentType ?? undefined,
          };
        }
        throw new Error("Attachment missing content");
      })
    );

    await sendBrevoMail({
      to,
      cc,
      bcc,
      subject,
      html,
      text,
      attachments: resolvedAttachments,
    });

    const record = await createMessage({
      userId: req.userId!,
      direction: "outbound",
      subject,
      previewText: text?.slice(0, 120) ?? html?.replace(/<[^>]+>/g, "").slice(0, 120) ?? "",
      bodyPlain: text ?? null,
      bodyHtml: html ?? null,
      status: "sent",
    });

    await Promise.all(
      resolvedAttachments.map((att) =>
        addAttachment({
          messageId: record.id,
          filename: att.filename,
          mimetype: att.contentType ?? "application/octet-stream",
          size: att.content.length,
          url: attachments.find((a) => a.filename === att.filename)?.url ?? "",
        })
      )
    );

    return res.status(202).json(record);
  } catch (error) {
    next(error);
  }
});

