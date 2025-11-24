import type { Request, Response, NextFunction } from "express";
import type { UserRecord } from "../types";

declare global {
  namespace Express {
    interface Request {
      userId?: string;
      user?: UserRecord;
    }
  }
}

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  if (!req.userId || !req.user) {
    return res.status(401).json({ error: "authentication required" });
  }
  next();
}

export async function attachUser(req: Request, _res: Response, next: NextFunction) {
  const userId = (req.session as { userId?: string }).userId;

  if (userId) {
    req.userId = userId;
    try {
      const { getUserById } = await import("../repositories/users");
      const user = await getUserById(userId);
      if (user) {
        req.user = user;
      }
    } catch (error) {
      console.error("Failed to attach user:", error);
    }
  }

  next();
}

