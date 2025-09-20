import { NextRequest, NextResponse } from "next/server";
import { getStorage } from "../../../lib/storage";
import { loadByCategory } from "../../../lib/questions/loaders";
import { selectOne } from "../../../lib/questions/select";
import type { GenRequest, Question } from "../../../lib/types";

export const runtime = "nodejs";

function pickCategory(categories?: GenRequest["categories"]): string {
  const c = categories && categories.length ? categories : ["geography"];
  return c[Math.floor(Math.random() * c.length)];
}

export async function POST(req: NextRequest) {
  try {
    const body = (await req.json()) as GenRequest;
    const { uid, rating = 1200, categories, seen = [], locale = "en" } = body;

    if (!uid) return NextResponse.json({ error: "Missing uid" }, { status: 400 });

    const category = pickCategory(categories);
    const bank = loadByCategory(category);
    if (!bank.length) {
      return NextResponse.json({ error: `No question bank for '${category}'. Seed data.` }, { status: 500 });
    }

    const storage = getStorage();
    const persistedSeen = await storage.getSeen({ uid, category });
    const exclude = new Set<string>([...persistedSeen, ...seen]);

    const q = selectOne(bank, { rating, locale, excludeIds: exclude });
    if (!q) return NextResponse.json({ error: "No questions available after filtering." }, { status: 500 });

    await storage.addSeen({ uid, category }, [q.id]);
    if (storage.trimSeen) await storage.trimSeen({ uid, category }, 2000);

    const payload: Question = q;
    return NextResponse.json(payload);
  } catch (err: any) {
    console.error("genQuestion error:", err);
    return NextResponse.json({ error: "Server error", detail: String(err?.message ?? err) }, { status: 500 });
  }
}
