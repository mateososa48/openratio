"use client";

import { RollingNumber } from "@kitlangton/rolling-number/react";

/**
 * The menu bar reads "67/33". When a visitor classifies a row, both halves have to
 * move at once, so each half is its own reel and the slash stays put.
 * Rolling Number (kitlangton.dev) handles interruption, so fast repeated clicks
 * retarget mid-flight instead of queueing.
 */
export function RatioDigits({
  create,
  consume,
  hasData,
  duration = 420,
  className = "",
}: {
  create: number;
  consume: number;
  hasData: boolean;
  duration?: number;
  className?: string;
}) {
  if (!hasData) return <span className={className}>—/—</span>;
  return (
    <span className={`ratio-reel ${className}`} aria-label={`${create} percent create, ${consume} percent consume`}>
      <RollingNumber value={create} duration={duration} aria-hidden />
      <span aria-hidden>/</span>
      <RollingNumber value={consume} duration={duration} aria-hidden />
    </span>
  );
}

/** "66.93%" in the panel summary. Two decimals, same as the app. */
export function PercentDigits({
  value,
  hasData,
  className = "",
}: {
  value: number;
  hasData: boolean;
  className?: string;
}) {
  if (!hasData) return <span className={className}>—</span>;
  return (
    <span className={`ratio-reel ${className}`}>
      <RollingNumber
        value={value / 100}
        duration={420}
        format={{ style: "percent", minimumFractionDigits: 2, maximumFractionDigits: 2 }}
        locales="en-US"
      />
    </span>
  );
}
