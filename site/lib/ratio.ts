/**
 * The same arithmetic and formatting the macOS app uses (Sources/Model/Ratio.swift,
 * Format.swift). Kept in sync by hand; the numbers on this page have to match the
 * numbers in the product, including the rounding.
 */

export type Category = "create" | "consume";

export interface Row {
  key: string;
  name: string;
  seconds: number;
  category: Category | null;
}

export interface Summary {
  hasData: boolean;
  createPercent: number;
  consumePercent: number;
  createText: string;
  consumeText: string;
  ratioText: string;
}

export function summarize(rows: Row[]): Summary {
  const create = rows.reduce((t, r) => (r.category === "create" ? t + r.seconds : t), 0);
  const consume = rows.reduce((t, r) => (r.category === "consume" ? t + r.seconds : t), 0);
  const total = create + consume;

  if (total === 0) {
    return {
      hasData: false,
      createPercent: 0,
      consumePercent: 100,
      createText: "—",
      consumeText: "—",
      ratioText: "—/—",
    };
  }

  const basisPoints = Math.round((create / total) * 10_000);
  const createPercent = Math.round((create / total) * 100);

  return {
    hasData: true,
    createPercent,
    consumePercent: 100 - createPercent,
    createText: `${(basisPoints / 100).toFixed(2)}%`,
    consumeText: `${((10_000 - basisPoints) / 100).toFixed(2)}%`,
    ratioText: `${createPercent}/${100 - createPercent}`,
  };
}

/** "0:54", "41:20", "5:23:55". Seconds floor, matching the app. */
export function duration(seconds: number): string {
  const s = Math.max(0, Math.floor(seconds));
  const pad = (n: number) => String(n).padStart(2, "0");
  if (s >= 3600) return `${Math.floor(s / 3600)}:${pad(Math.floor(s / 60) % 60)}:${pad(s % 60)}`;
  return `${Math.floor(s / 60)}:${pad(s % 60)}`;
}
