import type { Metadata, Viewport } from "next";
import { Fira_Code, Inter_Tight, Instrument_Serif } from "next/font/google";
import "./globals.css";

const sans = Inter_Tight({ subsets: ["latin"], weight: ["300", "400", "500", "600"], variable: "--font-sans", display: "swap" });
const serif = Instrument_Serif({ subsets: ["latin"], weight: "400", style: "italic", variable: "--font-serif", display: "swap" });
const mono = Fira_Code({ subsets: ["latin"], weight: "400", variable: "--font-mono", display: "swap" });

export const metadata: Metadata = {
  title: "DevPilot: learn real engineering tools",
  description: "Tell DevPilot what you want to learn. It builds the path, finds the videos, writes the labs and checks your work, on your own computer.",
};

export const viewport: Viewport = { width: "device-width", initialScale: 1, themeColor: "#0d0830" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    // "anim" keeps the hero entrance elements hidden until the entrance script starts (it removes the class).
    <html lang="en" className={`anim ${sans.variable} ${serif.variable} ${mono.variable}`} suppressHydrationWarning>
      <body>{children}</body>
    </html>
  );
}
