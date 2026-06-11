// Waitlist signup endpoint. MIT (c) 2026 aeropriest
import { NextResponse } from "next/server";
import { saveLead } from "@/lib/waitlist";

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function POST(req: Request) {
  try {
    const { email, hp } = await req.json();

    // Honeypot: bots fill hidden field -> pretend success, store nothing.
    if (hp) return NextResponse.json({ ok: true });

    if (typeof email !== "string" || !EMAIL.test(email)) {
      return NextResponse.json(
        { ok: false, error: "Please enter a valid email." },
        { status: 400 },
      );
    }

    await saveLead({
      email: email.toLowerCase().trim(),
      source: "website",
      ts: new Date().toISOString(),
    });

    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json({ ok: false, error: "Bad request" }, { status: 400 });
  }
}
