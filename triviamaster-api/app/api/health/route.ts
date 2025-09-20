import fs from "fs";
import path from "path";
import { NextResponse } from "next/server";

export const runtime = "nodejs";

export async function GET() {
  const p = path.join(process.cwd(), "data", "generated", "geography.json");
  const exists = fs.existsSync(p);
  return NextResponse.json({
    ok: true,
    router: "app",
    geographyJsonExists: exists,
    geographyJsonPath: p
  });
}
