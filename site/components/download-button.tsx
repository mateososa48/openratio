"use client";

import { ArrowDown } from "lucide-react";

const DMG = "/OpenRatio.dmg";

export function DownloadButton({ size = "lg" }: { size?: "lg" | "sm" }) {
  const big = size === "lg";
  return (
    <a
      href={DMG}
      download
      className={`group inline-flex items-center gap-3 bg-[var(--color-create)] font-semibold text-[#041208] transition-[background-color,transform] hover:bg-[#32d74b] active:translate-y-px ${
        big ? "px-5 py-3 text-[13px]" : "px-4 py-2"
      }`}
    >
      <ArrowDown size={big ? 15 : 13} className="shrink-0" aria-hidden />
      DOWNLOAD FOR MAC
    </a>
  );
}
