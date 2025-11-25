import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import * as inboxesRepo from "../repositories/inboxes";
import * as emailsRepo from "../repositories/emails";

export const inboxesRouter: Router = Router();

inboxesRouter.use(requireAuth);

// List all inboxes for the authenticated user
inboxesRouter.get("/", async (req, res, next) => {
  try {
    const inboxes = await inboxesRepo.listInboxes(req.userId!);

    // Enrich with email information
    const enrichedInboxes = await Promise.all(
      inboxes.map(async (inbox) => {
        const email = await emailsRepo.getEmailById(req.userId!, inbox.email_id);
        return {
          ...inbox,
          email: email?.email || null,
        };
      })
    );

    return res.json(enrichedInboxes);
  } catch (error) {
    next(error);
  }
});

// Create a new inbox (for an existing email)
inboxesRouter.post("/", async (req, res, next) => {
  try {
    const user = (req as any).user;
    if (user.role !== "admin") {
      return res.status(403).json({ error: "forbidden: admin only" });
    }

    const { emailId, name } = req.body;

    if (!emailId || typeof emailId !== "string" || !emailId.trim()) {
      return res.status(400).json({ error: "emailId is required" });
    }

    if (!name || typeof name !== "string" || !name.trim()) {
      return res.status(400).json({ error: "name is required" });
    }

    // Verify email belongs to user
    const email = await emailsRepo.getEmailById(req.userId!, emailId);
    if (!email) {
      return res.status(404).json({ error: "email not found" });
    }

    const inbox = await inboxesRepo.createInbox({
      emailId: emailId.trim(),
      userId: req.userId!,
      name: name.trim(),
    });

    return res.status(201).json(inbox);
  } catch (error) {
    next(error);
  }
});

// Get a specific inbox
inboxesRouter.get("/:inboxId", async (req, res, next) => {
  try {
    const { inboxId } = req.params;
    const inbox = await inboxesRepo.getInboxById(req.userId!, inboxId);

    if (!inbox) {
      return res.status(404).json({ error: "inbox not found" });
    }

    // Enrich with email information
    const email = await emailsRepo.getEmailById(req.userId!, inbox.email_id);
    return res.json({
      ...inbox,
      email: email?.email || null,
    });
  } catch (error) {
    next(error);
  }
});

// Delete an inbox
inboxesRouter.delete("/:inboxId", async (req, res, next) => {
  try {
    const user = (req as any).user;
    if (user.role !== "admin") {
      return res.status(403).json({ error: "forbidden: admin only" });
    }

    const { inboxId } = req.params;
    const deleted = await inboxesRepo.deleteInboxAny(inboxId);

    if (!deleted) {
      return res.status(404).json({ error: "inbox not found" });
    }

    return res.status(204).send();
  } catch (error) {
    next(error);
  }
});

