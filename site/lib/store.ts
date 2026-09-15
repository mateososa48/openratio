"use client";

import { create } from "zustand";
import { CURRENT_KEY, INITIAL_ROWS } from "./demo";
import { summarize, type Category, type Row, type Summary } from "./ratio";

type View = "activity" | "history";

interface PanelState {
  rows: Row[];
  view: View;
  pendingOnly: boolean;
  paused: boolean;
  light: boolean;
  touched: boolean;
  classify: (key: string, category: Category) => void;
  setView: (view: View) => void;
  togglePendingOnly: () => void;
  togglePaused: () => void;
  toggleLight: () => void;
  reset: () => void;
}

export const usePanel = create<PanelState>((set) => ({
  rows: INITIAL_ROWS,
  view: "activity",
  pendingOnly: false,
  paused: false,
  light: false,
  touched: false,

  classify: (key, category) =>
    set((s) => {
      const rows = s.rows.map((r) => (r.key === key ? { ...r, category } : r));
      const stillPending = rows.some((r) => r.category === null);
      return { rows, touched: true, pendingOnly: stillPending && s.pendingOnly };
    }),

  setView: (view) => set({ view }),
  togglePendingOnly: () => set((s) => ({ pendingOnly: !s.pendingOnly })),
  togglePaused: () => set((s) => ({ paused: !s.paused })),
  toggleLight: () => set((s) => ({ light: !s.light })),
  reset: () => set({ rows: INITIAL_ROWS, pendingOnly: false, paused: false, touched: false }),
}));

export const currentKey = CURRENT_KEY;

export function useSummary(): Summary {
  return summarize(usePanel((s) => s.rows));
}

export function usePendingCount(): number {
  return usePanel((s) => s.rows.filter((r) => r.category === null).length);
}

/** Live means: not paused, and the visitor is looking at a tracked app. */
export function useIsLive(): boolean {
  return usePanel((s) => !s.paused);
}
