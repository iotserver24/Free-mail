import { Router } from "express";
import { config } from "../config";
import { getUserByEmail, createUser } from "../repositories/users";

export const authRouter: Router = Router();

authRouter.post("/login", async (req, res, next) => {
  try {
    const { email, password } = req.body as { email?: string; password?: string };

    if (!email || !password) {
      return res.status(400).json({ error: "email and password are required" });
    }

    let user;

    // 1. Check if it's the super admin from environment
    if (email === config.admin.email) {
      if (password !== config.admin.password) {
        return res.status(401).json({ error: "invalid credentials" });
      }

      // Ensure admin user exists in database
      user = await getUserByEmail(config.admin.email);
      if (!user) {
        // Create admin user if it doesn't exist
        await createUser({
          email: config.admin.email,
          username: "admin",
          password: config.admin.password, // This will be hashed
          displayName: "Admin",
          role: "admin",
        });
        user = await getUserByEmail(config.admin.email);
      } else if (user.role !== "admin") {
        // Ensure role is admin
        const { updateUser } = await import("../repositories/users");
        await updateUser(user.id, { role: "admin" });
        user.role = "admin";
      }
    } else {
      // 2. Regular user login
      user = await getUserByEmail(email);

      if (!user || !user.password_hash) {
        return res.status(401).json({ error: "invalid credentials" });
      }

      const { verifyPassword } = await import("../repositories/users");
      const isValid = await verifyPassword(password, user.password_hash);

      if (!isValid) {
        return res.status(401).json({ error: "invalid credentials" });
      }
    }

    if (!user) {
      return res.status(500).json({ error: "login failed" });
    }

    // Set session
    (req.session as { userId?: string; email?: string }).userId = user.id;
    (req.session as { userId?: string; email?: string }).email = user.email;

    return res.json({
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        displayName: user.display_name ?? "User",
        role: user.role,
        avatarUrl: user.avatar_url,
        personalEmail: user.personal_email,
      },
    });
  } catch (error) {
    next(error);
  }
});

authRouter.post("/logout", async (req, res, next) => {
  try {
    req.session.destroy((err) => {
      if (err) {
        return next(err);
      }
      return res.status(204).send();
    });
  } catch (error) {
    next(error);
  }
});

authRouter.get("/me", async (req, res, next) => {
  try {
    const userId = (req.session as { userId?: string; email?: string }).userId;
    const email = (req.session as { userId?: string; email?: string }).email;

    if (!userId || !email) {
      return res.status(401).json({ error: "not authenticated" });
    }

    // Verify user still exists
    const { getUserById } = await import("../repositories/users");
    const user = await getUserById(userId);
    if (!user) {
      return res.status(404).json({ error: "user not found" });
    }

    return res.json({
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        displayName: user.display_name ?? "User",
        role: user.role,
        avatarUrl: user.avatar_url,
        personalEmail: user.personal_email,
      },
    });
  } catch (error) {
    next(error);
  }
});

