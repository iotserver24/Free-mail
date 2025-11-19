import { Router } from "express";
import { config } from "../config";
import { getUserByEmail, createUser } from "../repositories/users";

export const authRouter = Router();

authRouter.post("/login", async (req, res, next) => {
  try {
    const { email, password } = req.body as { email?: string; password?: string };

    if (!email || !password) {
      return res.status(400).json({ error: "email and password are required" });
    }

    // Check against admin credentials from environment
    if (email !== config.admin.email || password !== config.admin.password) {
      return res.status(401).json({ error: "invalid credentials" });
    }

    // Ensure admin user exists in database (for foreign key constraints)
    let adminUser = await getUserByEmail(config.admin.email);
    if (!adminUser) {
      // Create admin user if it doesn't exist
      await createUser({
        email: config.admin.email,
        password: config.admin.password,
        displayName: "Admin",
      });
      // Fetch the created user with password_hash for consistency
      adminUser = await getUserByEmail(config.admin.email);
      if (!adminUser) {
        return res.status(500).json({ error: "failed to create admin user" });
      }
    }

    // Set session with admin user ID
    (req.session as { userId?: string; email?: string }).userId = adminUser.id;
    (req.session as { userId?: string; email?: string }).email = config.admin.email;

    return res.json({
      user: {
        id: adminUser.id,
        email: config.admin.email,
        displayName: "Admin",
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
        displayName: user.display_name ?? "Admin",
      },
    });
  } catch (error) {
    next(error);
  }
});

