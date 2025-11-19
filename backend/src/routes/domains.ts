import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import * as domainsRepo from "../repositories/domains";

export const domainsRouter = Router();

domainsRouter.use(requireAuth);

// List all domains for the authenticated user
domainsRouter.get("/", async (req, res, next) => {
  try {
    const domains = await domainsRepo.listDomains(req.userId!);
    return res.json(domains);
  } catch (error) {
    next(error);
  }
});

// Create a new domain
domainsRouter.post("/", async (req, res, next) => {
  try {
    const { domain } = req.body;
    
    if (!domain || typeof domain !== "string" || !domain.trim()) {
      return res.status(400).json({ error: "domain is required" });
    }

    const domainRecord = await domainsRepo.createDomain({
      domain: domain.trim(),
      userId: req.userId!,
    });

    return res.status(201).json(domainRecord);
  } catch (error) {
    if (error instanceof Error) {
      if (error.message.includes("already exists") || error.message.includes("Invalid domain")) {
        return res.status(400).json({ error: error.message });
      }
    }
    next(error);
  }
});

// Get a specific domain
domainsRouter.get("/:domainId", async (req, res, next) => {
  try {
    const { domainId } = req.params;
    const domain = await domainsRepo.getDomainById(req.userId!, domainId);
    
    if (!domain) {
      return res.status(404).json({ error: "domain not found" });
    }

    return res.json(domain);
  } catch (error) {
    next(error);
  }
});

// Delete a domain
domainsRouter.delete("/:domainId", async (req, res, next) => {
  try {
    const { domainId } = req.params;
    const deleted = await domainsRepo.deleteDomain(req.userId!, domainId);
    
    if (!deleted) {
      return res.status(404).json({ error: "domain not found" });
    }

    return res.status(204).send();
  } catch (error) {
    next(error);
  }
});

