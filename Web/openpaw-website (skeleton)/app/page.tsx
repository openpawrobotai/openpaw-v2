// OpenPaw landing page + crowdfunding waitlist. MIT (c) 2026 aeropriest
import WaitlistForm from "@/components/WaitlistForm";

export default function Home() {
  return (
    <main style={{ fontFamily: "system-ui", padding: "4rem 1.5rem", maxWidth: 720, margin: "0 auto" }}>
      <h1 style={{ fontSize: "2.5rem", marginBottom: "0.5rem" }}>🐾 OpenPaw</h1>
      <p style={{ fontSize: "1.25rem", color: "#374151" }}>
        An open-source robot companion that watches over your pet — and the
        world&apos;s first pet-health AI built from real-world data.
      </p>

      <section style={{ margin: "2.5rem 0" }}>
        <h2 style={{ fontSize: "1.1rem" }}>Be first in line</h2>
        <p style={{ color: "#6b7280", marginBottom: "1rem" }}>
          We&apos;re launching on crowdfunding soon. Join the waitlist for early-bird pricing.
        </p>
        <WaitlistForm />
      </section>

      <p style={{ color: "#9ca3af", fontSize: "0.9rem" }}>
        Built in public by Ayva Labs · MIT licensed ·{" "}
        <a href="https://github.com/ayvalabs">GitHub</a>
      </p>
    </main>
  );
}
