// Example API route. MIT (c) 2026 aeropriest
import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({ status: "ok", service: "openpaw-website" });
}
