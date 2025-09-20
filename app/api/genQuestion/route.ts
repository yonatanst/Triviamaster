// app/api/genQuestion/route.ts
import { NextRequest, NextResponse } from "next/server";
import { getStorage } from "@/lib/storage";
import { loadByCategory } from "@/lib/questions/loaders";
import { selectOne } from "@/lib/questions/select";
import type { GenRequest, Question } from "@/lib/types";

export const runtime = "nodejs"; // not 'edge' because we read filesystem

function pickCategory(categories?: GenRequest["categories"]): string {
  const c = categories && categories.length ? categories : ["geography"];
  return c[Math.floor(Math.random() * c.length)];
}

export async function POST(req: NextRequest) {
  try {
    const body = (await req.json()) as GenRequest;
    const { uid, rating = 1200, categories, seen = [], locale = "en" } = body;

    if (!uid) {
      return NextResponse.json({ error: "Missing uid" }, { status: 400 });
    }

    const category = pickCategory(categories);
    const bank = loadByCategory(category);
    if (!bank.length) {
      return NextResponse.json({ error: `No question bank for category '${category}'. Run the seed script or add data.` }, { status: 500 });
    }

    const storage = getStorage();
    const persistedSeen = await storage.getSeen({ uid, category });
    // Union client 'seen' with persisted
    const exclude = new Set<string>([...persistedSeen, ...seen]);

    const q = selectOne(bank, { rating, locale, excludeIds: exclude });
    if (!q) {
      return NextResponse.json({ error: "No questions available after filtering. Try clearing seen or seeding more data." }, { status: 500 });
    }

    // Persist this question as seen
    await storage.addSeen({ uid, category }, [q.id]);
    // keep last ~2000 seen to avoid unbounded growth
    if (storage.trimSeen) await storage.trimSeen({ uid, category }, 2000);

    const payload: Question = q;
    return NextResponse.json(payload);
  } catch (err: any) {
    console.error(err);
    return NextResponse.json({ error: "Server error", detail: String(err?.message ?? err) }, { status: 500 });
  }
}
