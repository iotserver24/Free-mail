import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import * as emailsRepo from "../repositories/emails";
import * as inboxesRepo from "../repositories/inboxes";
import * as domainsRepo from "../repositories/domains";

export const emailsRouter: Router = Router();

emailsRouter.use(requireAuth);

// List all email addresses for the authenticated user
emailsRouter.get("/", async (req, res, next) => {
  try {
    const emails = await emailsRepo.listEmails(req.userId!);
    return res.json(emails);
  } catch (error) {
    next(error);
  }
});

// Create a new email address
emailsRouter.post("/", async (req, res, next) => {
  try {
    const user = (req as any).user;
    if (user.role !== "admin") {
      return res.status(403).json({ error: "forbidden: admin only" });
    }

    const { email, domain, inboxName } = req.body;

    if (!email || typeof email !== "string" || !email.trim()) {
      return res.status(400).json({ error: "email is required" });
    }

    if (!domain || typeof domain !== "string" || !domain.trim()) {
      return res.status(400).json({ error: "domain is required" });
    }

    // Verify domain belongs to user
    const domainRecord = await domainsRepo.getDomainByDomain(domain);
    if (!domainRecord || domainRecord.user_id !== req.userId!) {
      return res.status(403).json({ error: "domain not found or access denied" });
    }

    // Create inbox first with a temporary email_id (we'll update it after email creation)
    // We need to modify createInbox to allow empty email_id, or create email first
    // Let's create email first, then inbox, then update email with inbox_id

    // Step 1: Create email with temporary inbox_id
    const tempInboxId = require("uuid").v4();
    const emailRecord = await emailsRepo.createEmail({
      email: email.trim(),
      domain: domain.trim(),
      userId: req.userId!,
      inboxId: tempInboxId,
    });

    // Step 2: Create inbox with email_id
    const inbox = await inboxesRepo.createInbox({
      emailId: emailRecord.id,
      userId: req.userId!,
      name: inboxName || email.trim(),
    });

    // Step 3: Update email with correct inbox_id
    const db = await require("../db").getDb();
    await db.collection("email_addresses").updateOne(
      { id: emailRecord.id },
      { $set: { inbox_id: inbox.id } }
    );

    // Return updated email record
    const updatedEmail = await emailsRepo.getEmailById(req.userId!, emailRecord.id);
    return res.status(201).json(updatedEmail);
  } catch (error) {
    if (error instanceof Error) {
      if (error.message.includes("already exists") || error.message.includes("Invalid")) {
        return res.status(400).json({ error: error.message });
      }
    }
    next(error);
  }
});

// Get a specific email address
emailsRouter.get("/:emailId", async (req, res, next) => {
  try {
    const { emailId } = req.params;
    const email = await emailsRepo.getEmailById(req.userId!, emailId);

    if (!email) {
      return res.status(404).json({ error: "email not found" });
    }

    return res.json(email);
  } catch (error) {
    next(error);
  }
});

// Delete an email address
emailsRouter.delete("/:emailId", async (req, res, next) => {
  try {
    const user = (req as any).user;
    if (user.role !== "admin") {
      return res.status(403).json({ error: "forbidden: admin only" });
    }

    const { emailId } = req.params;

    // Get email to find inbox_id
    const email = await emailsRepo.getEmailById(req.userId!, emailId);
    if (!email) {
      return res.status(404).json({ error: "email not found" });
    }

    // Delete inbox associated with this email
    await inboxesRepo.deleteInbox(req.userId!, email.inbox_id);

    // Delete email
    // Admin can delete any email, so we use deleteEmailAny or we need to pass userId if we want to check ownership (but we are admin)
    // Since we verified admin above, we can just delete by ID.
    // However, the original code used deleteEmail(req.userId!, emailId) which implies ownership.
    // We should probably use deleteEmailAny here since the route is now admin-only.
    const deleted = await emailsRepo.deleteEmailAny(emailId);

    if (!deleted) {
      return res.status(404).json({ error: "email not found" });
    }

    return res.status(204).send();
  } catch (error) {
    next(error);
  }
});


// Admin: List emails for a specific user
emailsRouter.get("/admin/:userId", async (req, res, next) => {
  try {
    const user = (req as any).user;
    if (user.role !== "admin") {
      return res.status(403).json({ error: "forbidden: admin only" });
    }

    const { userId } = req.params;
    const emails = await emailsRepo.listEmails(userId);
    return res.json(emails);
  } catch (error) {
    next(error);
  }
});

// Admin: Create a new email address for a specific user
emailsRouter.post("/admin", async (req, res, next) => {
  try {
    const user = (req as any).user;
    if (user.role !== "admin") {
      return res.status(403).json({ error: "forbidden: admin only" });
    }

    const { userId, email, domain, inboxName } = req.body;

    if (!userId) {
      return res.status(400).json({ error: "userId is required" });
    }

    if (!email || typeof email !== "string" || !email.trim()) {
      return res.status(400).json({ error: "email is required" });
    }

    if (!domain || typeof domain !== "string" || !domain.trim()) {
      return res.status(400).json({ error: "domain is required" });
    }

    // Verify domain exists (Admin can assign any domain, but it must exist in DB)
    const domainRecord = await domainsRepo.getDomainByDomain(domain);
    if (!domainRecord) {
      return res.status(400).json({ error: "domain not found" });
    }

    // Create inbox first with a temporary email_id
    const tempInboxId = require("uuid").v4();
    const emailRecord = await emailsRepo.createEmail({
      email: email.trim(),
      domain: domain.trim(),
      userId: userId,
      inboxId: tempInboxId,
    });

    // Create inbox with email_id
    const inbox = await inboxesRepo.createInbox({
      emailId: emailRecord.id,
      userId: userId,
      name: inboxName || email.trim(),
    });

    // Update email with correct inbox_id
    const db = await require("../db").getDb();
    await db.collection("email_addresses").updateOne(
      { id: emailRecord.id },
      { $set: { inbox_id: inbox.id } }
    );

    const updatedEmail = await emailsRepo.getEmailById(userId, emailRecord.id);
    return res.status(201).json(updatedEmail);
  } catch (error) {
    if (error instanceof Error) {
      if (error.message.includes("already exists") || error.message.includes("Invalid")) {
        return res.status(400).json({ error: error.message });
      }
    }
    next(error);
  }
});
