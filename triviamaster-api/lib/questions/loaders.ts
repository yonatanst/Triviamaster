// lib/questions/loaders.ts
import fs from "fs";
import path from "path";
import type { Question } from "../types";

let geographyCache: Question[] | null = null;

export function loadGeography(): Question[] {
  if (geographyCache) return geographyCache;
  const genPath = path.join(process.cwd(), "data", "generated", "geography.json");
  if (fs.existsSync(genPath)) {
    geographyCache = JSON.parse(fs.readFileSync(genPath, "utf-8")) as Question[];
    return geographyCache!;
  }
  // Fallback: no generated file yet.
  return [];
}

export function loadByCategory(category: string): Question[] {
  if (category === "geography") return loadGeography();
  // TODO: add more categories loaders here.
  return [];
}
