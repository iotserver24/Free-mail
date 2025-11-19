import type { Request, Response, NextFunction } from "express";

declare global {
  namespace Express {
    interface Request {
      userId?: string;
    }
  }
}

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const userId = (req.session as { userId?: string }).userId;
  if (!userId) {
    return res.status(401).json({ error: "authentication required" });
  }
  req.userId = userId;
  next();
}

export function attachUser(req: Request, _res: Response, next: NextFunction) {
  const userId = (req.session as { userId?: string }).userId;
  req.userId = userId;
  next();
}

