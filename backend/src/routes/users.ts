import { Router } from "express";
import { v4 as uuid } from "uuid";
import { config } from "../config";
import { createUser, getUserByEmail, getUserByInviteToken, updateUser, listUsers, getUserById } from "../repositories/users";
import { createInbox } from "../repositories/inboxes";
import { createEmail } from "../repositories/emails";
import { getDomainById } from "../repositories/domains";
import { sendBrevoMail } from "../services/mailer";
import { requireAuth } from "../middleware/auth";

export const usersRouter: Router = Router();

// List all users (Admin only)
usersRouter.get("/", requireAuth, async (req, res, next) => {
    try {
        const user = (req as any).user;
        if (user.role !== "admin") {
            return res.status(403).json({ error: "forbidden: admin only" });
        }
        const users = await listUsers();
        return res.json(users);
    } catch (error) {
        next(error);
    }
});

// Create new user (Admin only)
usersRouter.post("/", requireAuth, async (req, res, next) => {
    try {
        const user = (req as any).user;
        if (user.role !== "admin") {
            return res.status(403).json({ error: "forbidden: admin only" });
        }

        const {
            username,
            domain_id, // ID of the selected domain
            fullname,
            details,
            password,
            send_invite,
            personal_email,
            avatar_url,
        } = req.body;

        if (!username || !domain_id) {
            return res.status(400).json({ error: "username and domain are required" });
        }

        // 1. Fetch domain to construct email
        const domainRecord = await getDomainById(req.userId!, domain_id);
        if (!domainRecord) {
            return res.status(400).json({ error: "invalid domain" });
        }

        const email = `${username}@${domainRecord.domain}`;

        const existingUser = await getUserByEmail(email);
        if (existingUser) {
            return res.status(409).json({ error: "user already exists" });
        }

        let inviteToken = null;
        let inviteTokenExpires = null;

        if (send_invite) {
            if (!personal_email) {
                return res.status(400).json({ error: "personal email required for invite" });
            }
            inviteToken = uuid();
            inviteTokenExpires = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(); // 24 hours
        }

        // 2. Create User
        const newUser = await createUser({
            username,
            email,
            password: password || undefined,
            displayName: fullname || details,
            personalEmail: personal_email,
            permanentDomain: domainRecord.domain,
            ...(inviteToken ? { inviteToken } : {}),
            ...(inviteTokenExpires ? { inviteTokenExpires } : {}),
            avatarUrl: avatar_url,
            role: "user",
        });

        // 3. Auto-create Inbox and Email record
        try {
            const inboxId = uuid();

            const emailRecord = await createEmail({
                email: newUser.email,
                domain: domainRecord.domain,
                userId: newUser.id,
                inboxId: inboxId,
            });

            await createInbox({
                id: inboxId,
                userId: newUser.id,
                name: "Main Inbox",
                emailId: emailRecord.id,
            });
        } catch (err) {
            console.error("Failed to auto-create inbox/email:", err);
            // Don't fail the request, but log it. Admin might need to fix manually.
        }

        if (send_invite && inviteToken) {
            const inviteUrl = `${config.frontendUrl}/set-password?token=${inviteToken}`;
            const senderEmail = `noreply@${domainRecord.domain}`;

            try {
                await sendBrevoMail({
                    from: senderEmail,
                    to: [personal_email],
                    subject: "Welcome to Free-mail - Set your password",
                    html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2>Welcome to Free-mail!</h2>
              <p>An account has been created for you.</p>
              <p><strong>Name:</strong> ${fullname}</p>
              <p><strong>Username:</strong> ${username}</p>
              <p><strong>Email:</strong> ${email}</p>
              <p>Please click the link below to set your password and access your account:</p>
              <p>
                <a href="${inviteUrl}" style="background-color: #4F46E5; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;">
                  Set Password
                </a>
              </p>
              <p>Or copy this link: ${inviteUrl}</p>
              <p>This link will expire in 24 hours.</p>
              <p>After setting your password, close the page for security.</p>
            </div>
          `,
                });
            } catch (emailError) {
                console.error("Failed to send invite email:", emailError);
            }
        }

        return res.status(201).json({ user: newUser });
    } catch (error) {
        next(error);
    }
});

// Update user (Admin or Self)
usersRouter.patch("/:id", requireAuth, async (req, res, next) => {
    try {
        const { id } = req.params;
        const updates = req.body;
        const currentUser = (req as any).user;

        if (!id) {
            return res.status(400).json({ error: "user id required" });
        }

        // Only admin or the user themselves can update
        if (currentUser.role !== "admin" && currentUser.id !== id) {
            return res.status(403).json({ error: "forbidden" });
        }

        // Prevent non-admins from changing role or sensitive fields if needed
        if (currentUser.role !== "admin") {
            delete updates.role;
            delete updates.email; // Usually email shouldn't be changed easily
        }

        const updatedUser = await updateUser(id, updates);
        if (!updatedUser) {
            return res.status(404).json({ error: "user not found" });
        }

        return res.json({ user: updatedUser });
    } catch (error) {
        next(error);
    }
});

// Set password via invite token (Public)
usersRouter.post("/invite/:token", async (req, res, next) => {
    try {
        const { token } = req.params;
        const { password } = req.body;

        if (!password) {
            return res.status(400).json({ error: "password required" });
        }

        const user = await getUserByInviteToken(token);
        if (!user) {
            return res.status(404).json({ error: "invalid or expired token" });
        }

        if (user.invite_token_expires && new Date(user.invite_token_expires) < new Date()) {
            return res.status(400).json({ error: "token expired" });
        }

        await updateUser(user.id, {
            password,
            invite_token: null, // Clear token
            invite_token_expires: null,
        });

        return res.json({ message: "password set successfully" });
    } catch (error) {
        next(error);
    }
});

// Forgot password (Public)
usersRouter.post("/forgot-password", async (req, res, next) => {
    try {
        const { email } = req.body;
        if (!email) {
            return res.status(400).json({ error: "email required" });
        }

        const user = await getUserByEmail(email);
        if (!user || !user.personal_email) {
            // Don't reveal if user exists or has personal email
            return res.json({ message: "if account exists, email sent" });
        }

        const inviteToken = uuid();
        const inviteTokenExpires = new Date(Date.now() + 1 * 60 * 60 * 1000).toISOString(); // 1 hour

        await updateUser(user.id, {
            invite_token: inviteToken,
            invite_token_expires: inviteTokenExpires,
        });

        const inviteUrl = `${config.frontendUrl}/set-password?token=${inviteToken}`;

        try {
            await sendBrevoMail({
                from: config.admin.email,
                to: [user.personal_email],
                subject: "Reset your Free-mail password",
                html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2>Password Reset Request</h2>
            <p>We received a request to reset your password for ${user.email}.</p>
            <p>Click the link below to set a new password:</p>
            <p>
              <a href="${inviteUrl}" style="background-color: #4F46E5; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;">
                Reset Password
              </a>
            </p>
            <p>This link expires in 1 hour.</p>
          </div>
        `,
            });
        } catch (emailError) {
            console.error("Failed to send reset email:", emailError);
        }

        return res.json({ message: "if account exists, email sent" });
    } catch (error) {
        next(error);
    }
});
