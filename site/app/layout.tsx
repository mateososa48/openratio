import type { Metadata, Viewport } from "next";
import { JetBrains_Mono } from "next/font/google";
import "@kitlangton/rolling-number/styles.css";
import "./globals.css";

/**
 * On a Mac, SF Mono resolves first so the page renders in the same face as the app.
 * JetBrains Mono is the fallback everywhere else; the native stack is listed ahead
 * of it in --font-mono (globals.css).
 */
const fallbackMono = JetBrains_Mono({
  subsets: ["latin"],
  weight: ["400", "600", "700"],
  variable: "--font-fallback-mono",
  display: "swap",
});

// Social cards need an absolute origin. Override with NEXT_PUBLIC_SITE_URL if a
// custom domain gets pointed at this project later.
const SITE = process.env.NEXT_PUBLIC_SITE_URL ?? "https://openratio.vercel.app";

export const metadata: Metadata = {
  metadataBase: new URL(SITE),
  title: "OpenRatio - Create more. Consume less.",
  description:
    "A free, open-source macOS menu bar app that splits your screen time into what you made and what you watched.",
  applicationName: "OpenRatio",
  keywords: ["macOS", "menu bar", "screen time", "time tracking", "open source", "productivity"],
  openGraph: {
    title: "OpenRatio - Create more. Consume less.",
    description:
      "A free, open-source macOS menu bar app that splits your screen time into what you made and what you watched.",
    url: SITE,
    siteName: "OpenRatio",
    type: "website",
    images: [{ url: "/og.png", width: 1200, height: 630, alt: "The OpenRatio panel showing a 67/33 create to consume split." }],
  },
  twitter: {
    card: "summary_large_image",
    title: "OpenRatio - Create more. Consume less.",
    description: "A free, open-source macOS menu bar app for your create to consume ratio.",
    images: ["/og.png"],
  },
  icons: { icon: "/icon.png", apple: "/icon.png" },
};

export const viewport: Viewport = {
  themeColor: "#0a0a0a",
  colorScheme: "dark",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={fallbackMono.variable}>
      <body>{children}</body>
    </html>
  );
}
