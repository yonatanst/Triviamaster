// scripts/seed-geography.ts
// Generate thousands of geography questions from countries.csv
import fs from "fs";
import path from "path";
import { canonicalId } from "../lib/dedupe";
import type { Question } from "../lib/types";

type Row = { Country: string; Capital: string; Continent: string };

function readCSV(fp: string): Row[] {
  const raw = fs.readFileSync(fp, "utf-8").trim();
  const [header, ...lines] = raw.split(/\r?\n/);
  const cols = header.split(",").map(s => s.trim());
  return lines.map(line => {
    const parts = line.split(",").map(s => s.trim());
    const obj: any = {};
    cols.forEach((c, i) => (obj[c] = parts[i]));
    return obj as Row;
  });
}

function shuffle<T>(arr: T[]): T[] {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor((Math.random() * (i + 1)));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

function sampleOther<T>(arr: T[], n: number, bad: (x: T) => boolean) {
  const pool = arr.filter(x => !bad(x));
  return shuffle(pool).slice(0, n);
}

function uniqBy<T>(arr: T[], key: (x: T) => string) {
  const seen = new Set<string>();
  const out: T[] = [];
  for (const x of arr) {
    const k = key(x);
    if (!seen.has(k)) {
      seen.add(k);
      out.push(x);
    }
  }
  return out;
}

function makeQuestions(rows: Row[]): Question[] {
  const qs: Question[] = [];

  // 1) "What is the capital of X?"
  for (const r of rows) {
    const distractors = sampleOther(rows, 3, rr => rr.Country === r.Country)
      .map(rr => rr.Capital);
    const choices = shuffle([r.Capital, ...distractors]);
    const q = `What is the capital of ${r.Country}?`;
    qs.push({
      id: "", // fill later
      category: "geography",
      locale: "en",
      difficulty: "easy",
      question: q,
      choices,
      answer: r.Capital,
      meta: { type: "capital_of", country: r.Country, continent: r.Continent }
    });
  }

  // 2) "Which country's capital is X?"
  for (const r of rows) {
    const distractors = sampleOther(rows, 3, rr => rr.Capital === r.Capital)
      .map(rr => rr.Country);
    const choices = shuffle([r.Country, ...distractors]);
    const q = `Which country's capital is ${r.Capital}?`;
    qs.push({
      id: "",
      category: "geography",
      locale: "en",
      difficulty: "medium",
      question: q,
      choices,
      answer: r.Country,
      meta: { type: "which_has_capital", capital: r.Capital, continent: r.Continent }
    });
  }

  // 3) "On which continent is X located?"
  for (const r of rows) {
    const allContinents = Array.from(new Set(rows.map(x => x.Continent)));
    const distractors = sampleOther(
      allContinents,
      3,
      c => c === r.Continent
    );
    const choices = shuffle([r.Continent, ...distractors]);
    const q = `On which continent is ${r.Country} located?`;
    qs.push({
      id: "",
      category: "geography",
      locale: "en",
      difficulty: "easy",
      question: q,
      choices,
      answer: r.Continent,
      meta: { type: "continent_of", country: r.Country }
    });
  }

  // Fill canonical IDs & de-dup near-identicals
  const withIds = qs.map(q => ({
    ...q,
    id: canonicalId(q.question, q.answer, q.category)
  }));

  return uniqBy(withIds, q => q.id);
}

function main() {
  const csv = path.join(process.cwd(), "data", "geography", "countries.csv");
  if (!fs.existsSync(csv)) {
    throw new Error(`CSV not found at ${csv}`);
  }
  const rows = readCSV(csv);
  const questions = makeQuestions(rows);

  const outDir = path.join(process.cwd(), "data", "generated");
  fs.mkdirSync(outDir, { recursive: true });
  const outFile = path.join(outDir, "geography.json");
  fs.writeFileSync(outFile, JSON.stringify(questions, null, 2), "utf-8");
  console.log(`Wrote ${questions.length} geography questions to ${outFile}`);
}

main();
