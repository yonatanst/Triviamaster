// lib/dedupe.ts
import crypto from "crypto";

/** Normalize a string so "What's the capital of France?" ~ "what is the capital of france" */
export function normalizeQuestion(q: string): string {
  return q
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[’'`]/g, "")         // strip curly/straight apostrophes
    .replace(/[^a-z0-9\s]/g, " ")  // drop punctuation
    .replace(/\s+/g, " ")          // collapse whitespace
    .trim();
}

/** Deterministic ID from normalized question (plus correct answer & category to reduce collisions) */
export function canonicalId(question: string, answer: string, category: string): string {
  const base = `${normalizeQuestion(question)}|${normalizeQuestion(answer)}|${normalizeQuestion(category)}`;
  return crypto.createHash("sha1").update(base).digest("hex");
}
