import { Router } from "express";
import multer from "multer";
import type { Request } from "express";
import { uploadBufferToCatbox } from "../services/catbox";
import { addAttachment } from "../repositories/messages";

const upload = multer();
export const attachmentsRouter: Router = Router();

interface MulterRequest extends Request {
  file?: Express.Multer.File;
}

attachmentsRouter.post("/", upload.single("file"), async (req, res, next) => {
  try {
    const file = (req as MulterRequest).file;
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

