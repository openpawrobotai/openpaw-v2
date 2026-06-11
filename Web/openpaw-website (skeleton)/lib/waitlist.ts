// Provider-agnostic waitlist persistence.
// Set WAITLIST_WEBHOOK_URL to any endpoint (Loops/ConvertKit/Zapier/Make/
// Google Apps Script/Firebase function). Works the moment a URL is set —
// no code change needed to switch providers.
// License: MIT (c) 2026 aeropriest

export type Lead = { email: string; source?: string; ts: string };

export async function saveLead(lead: Lead): Promise<void> {
  const webhook = process.env.WAITLIST_WEBHOOK_URL;
  if (webhook) {
    await fetch(webhook, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(lead),
    });
    return;
  }
  // Local/dev fallback until a provider URL is configured.
  console.log("[waitlist] WAITLIST_WEBHOOK_URL not set — lead:", lead);
}
