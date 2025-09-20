// app/api/genBatch/route.ts
import { NextRequest, NextResponse } from "next/server";
import { getStorage } from "@/lib/storage";
import { loadByCategory } from "@/lib/questions/loaders";
import { selectBatch } from "@/lib/questions/select";
import type { GenBatchRequest, Question } from "@/lib/types";

export const runtime = "nodejs";

export async function POST(req: NextRequest) {
  try {
    const body = (await req.json()) as GenBatchRequest;
    const {
      uid,
      rating = 1200,
      categories = ["geography"],
      seen = [],
      locale = "en",
      count,
      perCategory
    } = body;

    if (!uid) return NextResponse.json({ error: "Missing uid" }, { status: 400 });
    if (!count || count < 1) return NextResponse.json({ error: "Missing or invalid count" }, { status: 400 });

    const storage = getStorage();
    const perCat = perCategory ?? Math.max(1, Math.floor(count / categories.length));
    const results: Question[] = [];

    for (const category of categories) {
      const bank = loadByCategory(category);
      if (!bank.length) continue;

      const persistedSeen = await storage.getSeen({ uid, category });
      const exclude = new Set<string>([...persistedSeen, ...seen, ...results.map(r => r.id)]);

      const batch = selectBatch(bank, perCat, { rating, locale, excludeIds: exclude });
      results.push(...batch);

      // Persist newly selected as seen
      await storage.addSeen({ uid, category }, batch.map(b => b.id));
      if (storage.trimSeen) await storage.trimSeen({ uid, category }, 5000);
    }

    // If count not met (odd splits), try to top-up from first category:
    if (results.length < count && categories.length) {
      const category = categories[0];
      const bank = loadByCategory(category);
      const persistedSeen = await storage.getSeen({ uid, category });
      const exclude = new Set<string>([
        ...persistedSeen,
        ...seen,
        ...results.map(r => r.id),
      ]);
      const topup = selectBatch(bank, count - results.length, { rating, locale, excludeIds: exclude });
      results.push(...topup);
      await storage.addSeen({ uid, category }, topup.map(t => t.id));
      if (storage.trimSeen) await storage.trimSeen({ uid, category }, 5000);
    }

    if (!results.length) {
      return NextResponse.json({ error: "No questions available. Seed more data." }, { status: 500 });
    }

    return NextResponse.json({ items: results });
  } catch (err: any) {
    console.error(err);
    return NextResponse.json({ error: "Server error", detail: String(err?.message ?? err) }, { status: 500 });
  }
}
