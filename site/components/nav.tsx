"use client";

import { useMemo } from "react";
import { summarize } from "@/lib/ratio";
import { usePanel } from "@/lib/store";
import { RatioDigits } from "./ratio-digits";

/**
 * The site nav, shaped like the thing you are buying. The readout on the right is
 * wired to the demo panel below, so classifying a row up-ends the number here too.
 */
export function Nav() {
  const rows = usePanel((s) => s.rows);
  const paused = usePanel((s) => s.paused);
  const s = useMemo(() => summarize(rows), [rows]);

  const currentCategory = rows.find((r) => r.key === "figma")?.category ?? null;
  const glyph = paused ? "Ⅱ" : currentCategory === "create" ? "↑" : currentCategory === "consume" ? "↓" : "?";
  const tone = paused
    ? "text-[var(--color-chalk-dim)]"
    : currentCategory === "create"
      ? "text-[var(--color-create)]"
      : currentCategory === "consume"
        ? "text-[var(--color-consume)]"
        : "text-[var(--color-pending)]";

  return (
    <header className="fixed inset-x-0 top-0 z-50 h-[34px] border-b border-[var(--color-rule-strong)] bg-[#000]/92 backdrop-blur-sm">
      <div className="mx-auto flex h-full max-w-[1240px] items-center gap-4 px-4 sm:px-6">
        <a href="#top" className="flex h-full items-center gap-2 font-semibold tracking-label whitespace-nowrap">
          <Mark />
          OPENRATIO
        </a>

        <div className="ml-auto flex h-full items-center gap-4 sm:gap-5">
          <span className={`tabular-nums whitespace-nowrap ${tone}`} aria-live="polite">
            <span aria-hidden>{glyph} </span>
            <RatioDigits create={s.createPercent} consume={s.consumePercent} hasData={s.hasData} />
          </span>
          <a
            href="https://github.com/mateososa48/openratio"
            className="hidden h-full items-center text-[var(--color-chalk-dim)] transition-colors hover:text-[var(--color-chalk)] sm:flex"
          >
            SOURCE
          </a>
          <a
            href="#install"
            className="flex h-[26px] items-center bg-[var(--color-create)] px-3 font-semibold whitespace-nowrap text-[#041208] transition-colors hover:bg-[#32d74b]"
          >
            DOWNLOAD
          </a>
        </div>
      </div>
    </header>
  );
}

/** The app icon's mark: a 67/33 split bar. */
export function Mark({ w = 18 }: { w?: number }) {
  return (
    <span aria-hidden className="inline-flex h-[6px] shrink-0 overflow-hidden" style={{ width: w }}>
      <span className="bg-[var(--color-create)]" style={{ width: "67%" }} />
      <span className="bg-[var(--color-consume)]" style={{ width: "33%" }} />
    </span>
  );
}
