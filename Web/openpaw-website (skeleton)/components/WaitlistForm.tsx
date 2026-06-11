// Email-capture form for the OpenPaw crowdfunding waitlist.
// MIT (c) 2026 aeropriest
"use client";

import { useState } from "react";

type State = "idle" | "loading" | "done" | "error";

export default function WaitlistForm() {
  const [email, setEmail] = useState("");
  const [hp, setHp] = useState(""); // honeypot
  const [state, setState] = useState<State>("idle");
  const [error, setError] = useState("");

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setState("loading");
    setError("");
    try {
      const res = await fetch("/api/waitlist", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, hp }),
      });
      const data = await res.json();
      if (!res.ok || !data.ok) throw new Error(data.error ?? "Something went wrong");
      setState("done");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong");
      setState("error");
    }
  }

  if (state === "done") {
    return <p>🎉 You&apos;re on the list — we&apos;ll email you at launch.</p>;
  }

  return (
    <form onSubmit={submit} style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
      <input
        type="email"
        required
        placeholder="you@email.com"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        style={{ padding: "0.6rem 0.8rem", borderRadius: 8, border: "1px solid #ccc", minWidth: 240 }}
      />
      {/* honeypot — hidden from humans */}
      <input
        type="text"
        tabIndex={-1}
        autoComplete="off"
        value={hp}
        onChange={(e) => setHp(e.target.value)}
        style={{ position: "absolute", left: "-9999px" }}
        aria-hidden="true"
      />
      <button
        type="submit"
        disabled={state === "loading"}
        style={{ padding: "0.6rem 1.2rem", borderRadius: 8, border: "none", background: "#0d9488", color: "#fff", cursor: "pointer" }}
      >
        {state === "loading" ? "…" : "Notify me at launch"}
      </button>
      {state === "error" && <p style={{ color: "#dc2626", width: "100%" }}>{error}</p>}
    </form>
  );
}
