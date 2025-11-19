import { Router } from "express";
import multer from "multer";
import { uploadBufferToCatbox } from "../services/catbox";
import { addAttachment } from "../repositories/messages";

const upload = multer();
export const attachmentsRouter = Router();

attachmentsRouter.post("/", upload.single("file"), async (req, res, next) => {
  try {
    const file = req.file as Express.Multer.File | undefined;
    if (!file) {
      return res.status(400).json({ error: "file is required" });
    }
    const { messageId } = req.body;
    if (!messageId) {
      return res.status(400).json({ error: "messageId is required" });
    }

    const url = await uploadBufferToCatbox(file.originalname, file.buffer);
    const attachment = await addAttachment({
      messageId,
      filename: file.originalname,
      mimetype: file.mimetype,
      size: file.size,
      url,
    });

    return res.status(201).json(attachment);
  } catch (error) {
    next(error);
  }
});

