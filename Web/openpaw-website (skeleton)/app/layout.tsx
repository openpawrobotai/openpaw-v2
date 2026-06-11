// OpenPaw website root layout. MIT (c) 2026 aeropriest
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "OpenPaw — keep an eye on the ones who can't tell you",
  description:
    "An open-source robot companion for pets, and the world's first pet-health AI.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
