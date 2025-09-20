// lib/questions/select.ts
import type { Question } from "../types";
import { canonicalId } from "../dedupe";

export type SelectionOpts = {
  rating?: number;
  locale?: "en" | "he";
  excludeIds?: Set<string>;
};

function pickDifficulty(rating?: number): Question["difficulty"] {
  if (!rating) return "medium";
  if (rating <= 950) return "easy";
  if (rating <= 1350) return "medium";
  return "hard";
}

export function selectOne(
  bank: Question[],
  opts: SelectionOpts
): Question | null {
  const { rating, locale = "en", excludeIds } = opts;
  const diff = pickDifficulty(rating);

  const filtered = bank.filter(q =>
    q.locale === locale &&
    (q.difficulty === diff || diff === "medium") // allow medium as buffer
  );

  const pool = filtered.filter(q => !excludeIds?.has(q.id));

  const finalPool = pool.length ? pool : filtered; // fallback if exhausted
  if (!finalPool.length) return null;

  const idx = Math.floor(Math.random() * finalPool.length);
  const chosen = finalPool[idx];

  // Recompute canonical id in case bank lacked it
  const id = chosen.id || canonicalId(chosen.question, chosen.answer, chosen.category);
  return { ...chosen, id };
}

export function selectBatch(
  bank: Question[],
  count: number,
  opts: SelectionOpts
): Question[] {
  const out: Question[] = [];
  const excluded = new Set<string>(opts.excludeIds ?? []);
  for (let i = 0; i < count; i++) {
    const q = selectOne(bank, { ...opts, excludeIds: excluded });
    if (!q) break;
    out.push(q);
    excluded.add(q.id);
  }
  return out;
}
