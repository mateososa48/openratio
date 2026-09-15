import type { Row } from "./ratio";

/**
 * A plausible afternoon, ordered the way the app orders rows: the app you are in
 * right now first, then most recently used. Two rows are deliberately left
 * uncategorized so the badge has something to do.
 */
export const INITIAL_ROWS: Row[] = [
  { key: "figma", name: "Figma", seconds: 8040, category: "create" },
  { key: "youtube", name: "youtube.com", seconds: 2900, category: "consume" },
  { key: "slack", name: "Slack", seconds: 1810, category: "consume" },
  { key: "terminal", name: "Terminal", seconds: 2480, category: "create" },
  { key: "reddit", name: "reddit.com", seconds: 570, category: null },
  { key: "obsidian", name: "Obsidian", seconds: 1855, category: "create" },
  { key: "hn", name: "news.ycombinator.com", seconds: 1405, category: "consume" },
  { key: "spotify", name: "Spotify", seconds: 375, category: null },
];

export const CURRENT_KEY = "figma";

/** Past days are fixed; today's row is computed from whatever the visitor clicks. */
export const PAST_DAYS = [
  { label: "SEP 14", create: 71 },
  { label: "SEP 13", create: 64 },
  { label: "SEP 12", create: 45 },
  { label: "SEP 11", create: 58 },
];
