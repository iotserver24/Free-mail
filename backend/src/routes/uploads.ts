import { Router } from "express";
import multer from "multer";
import type { Request, Response, NextFunction } from "express";
import { uploadBufferToCatbox } from "../services/catbox";

const MAX_FILE_SIZE = 20 * 1024 * 1024; // 20MB
const upload = multer({
  limits: {
    fileSize: MAX_FILE_SIZE,
  },
});

export const uploadsRouter: Router = Router();

interface MulterRequest extends Request {
  file?: Express.Multer.File;
}

uploadsRouter.post("/catbox", upload.single("file"), async (req, res, next) => {
  try {
    const file = (req as MulterRequest).file;
    if (!file) {
      return res.status(400).json({ error: "file is required" });
    }

    const catboxUrl = await uploadBufferToCatbox(file.originalname, file.buffer);

    return res.status(201).json({
      url: catboxUrl,
      filename: file.originalname,
      mimetype: file.mimetype,
      size_bytes: file.size,
    });
  } catch (error) {
    next(error);
  }
});

uploadsRouter.use(
  (err: unknown, _req: Request, res: Response, next: NextFunction) => {
    if (err instanceof multer.MulterError && err.code === "LIMIT_FILE_SIZE") {
      return res.status(413).json({
        error: "file too large",
        limit_bytes: MAX_FILE_SIZE,
      });
    }
    return next(err);
  }
);


