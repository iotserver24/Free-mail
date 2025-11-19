import { getDb } from "../db";
import { v4 as uuid } from "uuid";

export interface DomainRecord {
  id: string;
  domain: string;
  user_id: string;
  created_at: string;
}

export interface CreateDomainInput {
  domain: string;
  userId: string;
}

export async function createDomain(input: CreateDomainInput): Promise<DomainRecord> {
  const db = await getDb();
  const collection = db.collection("domains");

  // Validate domain format (basic check)
  const domainRegex = /^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$/i;
  if (!domainRegex.test(input.domain)) {
    throw new Error("Invalid domain format");
  }

  // Check if domain already exists for this user
  const existing = await collection.findOne({ domain: input.domain, user_id: input.userId });
  if (existing) {
    throw new Error("Domain already exists for this user");
  }

  const domain = {
    id: uuid(),
    domain: input.domain.toLowerCase(),
    user_id: input.userId,
    created_at: new Date().toISOString(),
  };

  await collection.insertOne(domain);

  return {
    id: domain.id,
    domain: domain.domain,
    user_id: domain.user_id,
    created_at: domain.created_at,
  };
}

export async function listDomains(userId: string): Promise<DomainRecord[]> {
  const db = await getDb();
  const collection = db.collection("domains");

  const domains = await collection
    .find<{
      id: string;
      domain: string;
      user_id: string;
      created_at: string;
    }>({ user_id: userId })
    .sort({ created_at: -1 })
    .toArray();

  return domains.map((d) => ({
    id: d.id,
    domain: d.domain,
    user_id: d.user_id,
    created_at: d.created_at,
  }));
}

export async function getDomainById(userId: string, domainId: string): Promise<DomainRecord | null> {
  const db = await getDb();
  const collection = db.collection("domains");

  const domain = await collection.findOne<{
    id: string;
    domain: string;
    user_id: string;
    created_at: string;
  }>({ id: domainId, user_id: userId });

  if (!domain) {
    return null;
  }

  return {
    id: domain.id,
    domain: domain.domain,
    user_id: domain.user_id,
    created_at: domain.created_at,
  };
}

export async function getDomainByDomain(domain: string): Promise<DomainRecord | null> {
  const db = await getDb();
  const collection = db.collection("domains");

  const domainRecord = await collection.findOne<{
    id: string;
    domain: string;
    user_id: string;
    created_at: string;
  }>({ domain: domain.toLowerCase() });

  if (!domainRecord) {
    return null;
  }

  return {
    id: domainRecord.id,
    domain: domainRecord.domain,
    user_id: domainRecord.user_id,
    created_at: domainRecord.created_at,
  };
}

export async function deleteDomain(userId: string, domainId: string): Promise<boolean> {
  const db = await getDb();
  const collection = db.collection("domains");

  const result = await collection.deleteOne({ id: domainId, user_id: userId });
  return result.deletedCount > 0;
}

