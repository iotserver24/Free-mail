import { Router } from "express";
import { v4 as uuid } from "uuid";
import { config } from "../config";
import { createUser, getUserByEmail, getUserByInviteToken, updateUser } from "../repositories/users";
import { sendBrevoMail } from "../services/mailer";
import { requireAuth } from "../middleware/auth";

export const usersRouter: Router = Router();

// Create new user (Admin only)
usersRouter.post("/", requireAuth, async (req, res, next) => {
    try {
        const user = (req as any).user;
        if (user.role !== "admin") {
            return res.status(403).json({ error: "forbidden: admin only" });
        }

        const {
            username,
            email, // Full email with domain
            permanent_domain,
            details, // Not stored in DB currently, maybe add to display_name or new field?
            password,
            send_invite,
            personal_email,
        } = req.body;

        if (!username || !email || !permanent_domain) {
            return res.status(400).json({ error: "missing required fields" });
        }

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

        const newUser = await createUser({
            username,
            email,
            password: password || undefined,
            displayName: details,
            personalEmail: personal_email,
            permanentDomain: permanent_domain,
            ...(inviteToken ? { inviteToken } : {}),
            ...(inviteTokenExpires ? { inviteTokenExpires } : {}),
            role: "user",
        });

        if (send_invite && inviteToken) {
            const inviteUrl = `${config.frontendUrl}/set-password?token=${inviteToken}`;

            // Extract domain from the new user's email
            const emailDomain = email.split('@')[1];
            const senderEmail = `noreply@${emailDomain}`;

            try {
                await sendBrevoMail({
                    from: senderEmail,
                    to: [personal_email],
                    subject: "Welcome to Free-mail - Set your password",
                    html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2>Welcome to Free-mail!</h2>
              <p>An account has been created for you.</p>
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
                // Don't fail the request, but warn
            }
        }

        return res.status(201).json({ user: newUser });
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
