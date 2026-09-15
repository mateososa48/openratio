"use client";

import { ArrowLeft, History, Moon, Pause, Play, Sun } from "lucide-react";
import { AnimatePresence, motion, useReducedMotion } from "motion/react";
import { useMemo } from "react";
import { PAST_DAYS } from "@/lib/demo";
import { duration as fmt, summarize } from "@/lib/ratio";
import { currentKey, usePanel } from "@/lib/store";
import { PercentDigits } from "./ratio-digits";

/* The app's panel is 360 x 352 on a 44pt row. Everything here is that grid. */
const ROW = 44;

/**
 * Clicking a control inside the scrolling list made the browser scroll it into
 * view, which yanked the list out from under the pointer. Focus it manually
 * instead; keyboard tabbing still scrolls normally because that path is untouched.
 */
function keepPlace(e: React.PointerEvent<HTMLButtonElement>) {
  e.preventDefault();
  e.currentTarget.focus({ preventScroll: true });
}

/* ------------------------------------------------------------------ shell */

export function Panel({ caretX = 262 }: { caretX?: number }) {
  const light = usePanel((s) => s.light);

  return (
    <div className="relative" style={{ width: 360, paddingTop: 9 }}>
      {/* Caret. A rotated square sharing the panel's fill and two of its borders,
          which is how the popover tip reads in the real app. */}
      <span
        aria-hidden
        className="absolute z-10"
        style={{
          top: 3,
          left: caretX - 7,
          width: 14,
          height: 14,
          transform: "rotate(45deg)",
          borderRadius: "3px 0 0 0",
          background: light ? "var(--color-panelite)" : "var(--color-panel)",
          borderTop: `1px solid ${light ? "var(--color-panelite-rule)" : "var(--color-panel-rule)"}`,
          borderLeft: `1px solid ${light ? "var(--color-panelite-rule)" : "var(--color-panel-rule)"}`,
        }}
      />
      <div
        className="relative z-20 flex flex-col overflow-hidden rounded-[8px] shadow-[0_24px_70px_rgba(0,0,0,0.55)]"
        style={{
          height: 352,
          background: light ? "var(--color-panelite)" : "var(--color-panel)",
          color: light ? "var(--color-panelite-fg)" : "var(--color-panel-fg)",
          border: `1px solid ${light ? "var(--color-panelite-rule)" : "var(--color-panel-rule)"}`,
        }}
        aria-label="OpenRatio activity tracker, interactive demo"
      >
        <SummaryRow />
        <TrackingRow />
        <ListArea />
        <Footer />
      </div>
    </div>
  );
}

function usePanelRule() {
  const light = usePanel((s) => s.light);
  return light ? "var(--color-panelite-rule)" : "var(--color-panel-rule)";
}

/* ---------------------------------------------------------------- summary */

function SummaryRow() {
  const rows = usePanel((s) => s.rows);
  const s = useMemo(() => summarize(rows), [rows]);
  const reduce = useReducedMotion();

  return (
    <div className="relative flex shrink-0" style={{ height: ROW }}>
      <Half>
        <span className="text-[var(--color-create)]">
          ↑ <PercentDigits value={Number(s.createText.replace("%", "")) || 0} hasData={s.hasData} />
        </span>
        &nbsp;CREATING
      </Half>
      <Half>
        <span className="text-[var(--color-consume)]">
          ↓ <PercentDigits value={Number(s.consumeText.replace("%", "")) || 0} hasData={s.hasData} />
        </span>
        &nbsp;CONSUMING
      </Half>
      {/* The rule under the summary is the ratio bar: red track, green fill. */}
      <div className="absolute inset-x-0 bottom-0 h-px overflow-hidden bg-[var(--color-consume)]">
        <motion.div
          className="h-full bg-[var(--color-create)]"
          initial={false}
          animate={{ width: `${s.hasData ? s.createPercent : 0}%` }}
          transition={reduce ? { duration: 0 } : { duration: 0.42, ease: [0.16, 1, 0.3, 1] }}
        />
      </div>
    </div>
  );
}

function Half({ children }: { children: React.ReactNode }) {
  return (
    <span className="flex flex-1 items-center overflow-hidden px-4 whitespace-nowrap">{children}</span>
  );
}

/* --------------------------------------------------------------- tracking */

function TrackingRow() {
  const { rows, view, pendingOnly, paused, togglePendingOnly } = usePanel();
  const rule = usePanelRule();
  const pending = rows.filter((r) => r.category === null).length;
  const total = rows.reduce((t, r) => t + r.seconds, 0);

  const label = view === "history" ? "HISTORY" : pendingOnly ? "TO CATEGORIZE" : paused ? "PAUSED" : "TRACKING";

  return (
    <div
      className="flex shrink-0 items-center"
      style={{ height: ROW, borderBottom: `1px solid ${rule}` }}
    >
      <span className="flex-1 truncate pl-4 text-[var(--color-chalk-dim)]">{label}</span>
      {view === "history" ? (
        <span className="w-[176px] pr-4 text-right tabular-nums text-[var(--color-chalk-dim)]">
          {PAST_DAYS.length + 1} DAYS
        </span>
      ) : (
        <>
          <span className="w-[92px] pr-2 text-right tabular-nums text-[var(--color-chalk-dim)]">
            {fmt(total)}
          </span>
          <button
            type="button"
            onClick={togglePendingOnly}
            onPointerDown={keepPlace}
            aria-pressed={pendingOnly}
            aria-label={pendingOnly ? "Show all activity" : `Review ${pending} uncategorized apps`}
            title={pending > 0 ? `${pending} ${pending === 1 ? "app needs" : "apps need"} categorizing` : "All apps categorized"}
            className="flex h-full w-[88px] items-center justify-center transition-colors"
            style={{ borderLeft: `1px solid ${rule}` }}
          >
            {pending > 0 ? (
              <span className="inline-flex h-[19px] min-w-[19px] items-center justify-center rounded-full bg-[var(--color-pending)] px-[5px] font-bold tabular-nums text-[#222]">
                {pending}
              </span>
            ) : (
              <span className="text-[var(--color-create)]">✓</span>
            )}
          </button>
        </>
      )}
    </div>
  );
}

/* ------------------------------------------------------------------ lists */

function ListArea() {
  const view = usePanel((s) => s.view);
  return (
    <div style={{ height: 220 }} className="panel-scroll overflow-y-auto overflow-x-hidden">
      {view === "history" ? <HistoryList /> : <ActivityList />}
    </div>
  );
}

function ActivityList() {
  const { rows, pendingOnly } = usePanel();
  const visible = pendingOnly ? rows.filter((r) => r.category === null) : rows;

  if (visible.length === 0) {
    return <p className="px-4 py-[13px] text-[var(--color-chalk-dim)]">All caught up.</p>;
  }
  return (
    <ul aria-label={pendingOnly ? "Uncategorized activity" : "Today's activity"}>
      {visible.map((r) => (
        <ActivityRow key={r.key} row={r} />
      ))}
    </ul>
  );
}

function ActivityRow({ row }: { row: { key: string; name: string; seconds: number; category: "create" | "consume" | null } }) {
  const { classify, paused, light } = usePanel();
  const rule = usePanelRule();
  const isCurrent = row.key === currentKey;

  return (
    <li
      className="flex items-center"
      style={{
        height: ROW,
        borderBottom: `1px solid ${rule}`,
        background: isCurrent
          ? light
            ? "var(--color-panelite-current)"
            : "var(--color-panel-current)"
          : "transparent",
      }}
    >
      <span
        className="flex-1 truncate pl-4"
        style={{
          fontWeight: isCurrent ? 600 : 400,
          color: row.category === null ? "var(--color-pending)" : "inherit",
        }}
      >
        {row.name}
      </span>
      <span className="flex w-[92px] items-center justify-end gap-2 pr-2 tabular-nums">
        {isCurrent && !paused && (
          <span className="size-1 shrink-0 rounded-full bg-[var(--color-create)]" aria-label="Currently tracking" />
        )}
        {fmt(row.seconds)}
      </span>
      <Arrow
        glyph="↑"
        tone="create"
        selected={row.category === "create"}
        dimmed={row.category === "consume"}
        onClick={() => classify(row.key, "create")}
        label={`Categorize ${row.name} as create`}
      />
      <Arrow
        glyph="↓"
        tone="consume"
        selected={row.category === "consume"}
        dimmed={row.category === "create"}
        onClick={() => classify(row.key, "consume")}
        label={`Categorize ${row.name} as consume`}
      />
    </li>
  );
}

function Arrow({
  glyph,
  tone,
  selected,
  dimmed,
  onClick,
  label,
}: {
  glyph: string;
  tone: "create" | "consume";
  selected: boolean;
  dimmed: boolean;
  onClick: () => void;
  label: string;
}) {
  const light = usePanel((s) => s.light);
  const rule = usePanelRule();
  return (
    <button
      type="button"
      onClick={onClick}
      onPointerDown={keepPlace}
      aria-label={label}
      aria-pressed={selected}
      title={tone === "create" ? "Create" : "Consume"}
      className="group/arrow flex shrink-0 items-center justify-center transition-colors"
      style={{
        width: ROW,
        height: ROW,
        borderLeft: `1px solid ${rule}`,
        background: selected
          ? light
            ? "var(--color-panelite-armed)"
            : "var(--color-panel-armed)"
          : "transparent",
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.background = light ? "var(--color-panelite-hover)" : "var(--color-panel-hover)";
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.background = selected
          ? light
            ? "var(--color-panelite-armed)"
            : "var(--color-panel-armed)"
          : "transparent";
      }}
    >
      <span
        style={{
          fontWeight: selected ? 700 : 400,
          color: dimmed
            ? "var(--color-chalk-faint)"
            : tone === "create"
              ? "var(--color-create)"
              : "var(--color-consume)",
        }}
      >
        {glyph}
      </span>
    </button>
  );
}

function HistoryList() {
  const rows = usePanel((s) => s.rows);
  const today = summarize(rows);
  const rule = usePanelRule();

  const days = [
    { label: "TODAY", create: today.hasData ? today.createPercent : 0, hasData: today.hasData },
    ...PAST_DAYS.map((d) => ({ ...d, hasData: true })),
  ];

  return (
    <ul aria-label="Daily ratio history">
      {days.map((d) => (
        <li
          key={d.label}
          className="flex items-center gap-[10px] px-4"
          style={{ height: ROW, borderBottom: `1px solid ${rule}` }}
        >
          <span className="w-16 shrink-0 truncate text-[var(--color-chalk-dim)]">{d.label}</span>
          <span className="relative block h-[2px] flex-1 bg-[var(--color-consume)]">
            <span
              className="absolute inset-y-0 left-0 bg-[var(--color-create)] transition-[width] duration-[420ms]"
              style={{ width: `${d.create}%` }}
            />
          </span>
          <span
            className="w-[62px] shrink-0 text-right tabular-nums"
            style={{
              color:
                !d.hasData
                  ? "var(--color-chalk-dim)"
                  : d.create > 50
                    ? "var(--color-create)"
                    : d.create < 50
                      ? "var(--color-consume)"
                      : "inherit",
            }}
          >
            {d.hasData ? `${d.create}/${100 - d.create}` : "—/—"}
          </span>
        </li>
      ))}
    </ul>
  );
}

/* ----------------------------------------------------------------- footer */

function Footer() {
  const { view, setView, paused, togglePaused, light, toggleLight, reset, touched } = usePanel();
  const rule = usePanelRule();

  return (
    <div
      className="mt-auto grid shrink-0"
      style={{ height: ROW, gridTemplateColumns: "44px 44px 1fr 1fr 44px", borderTop: `1px solid ${rule}` }}
    >
      <FooterButton
        onClick={togglePaused}
        label={paused ? "Resume tracking" : "Pause tracking"}
        first
      >
        {paused ? <Play size={14} /> : <Pause size={14} />}
      </FooterButton>

      <FooterButton
        onClick={() => setView(view === "history" ? "activity" : "history")}
        label={view === "history" ? "Back to activity" : "Show history"}
        selected={view === "history"}
      >
        {view === "history" ? <ArrowLeft size={14} /> : <History size={14} />}
      </FooterButton>

      <FooterButton onClick={reset} label={touched ? "Reset the demo" : "Reset"} quiet>
        RESET
      </FooterButton>

      <FooterButton onClick={() => {}} label="Quit, disabled in this demo" disabled>
        QUIT
      </FooterButton>

      <FooterButton
        onClick={toggleLight}
        label={light ? "Switch panel to dark mode" : "Switch panel to light mode"}
      >
        {light ? <Moon size={14} /> : <Sun size={14} />}
      </FooterButton>
    </div>
  );
}

function FooterButton({
  children,
  onClick,
  label,
  selected = false,
  quiet = false,
  disabled = false,
  first = false,
}: {
  children: React.ReactNode;
  onClick: () => void;
  label: string;
  selected?: boolean;
  quiet?: boolean;
  disabled?: boolean;
  first?: boolean;
}) {
  const light = usePanel((s) => s.light);
  const rule = usePanelRule();
  const hoverBg = light ? "#111111" : "#ffffff";
  const hoverFg = light ? "#ffffff" : "#000000";
  const selectedBg = light ? "var(--color-panelite-armed)" : "var(--color-panel-footer-on)";

  return (
    <button
      type="button"
      onClick={onClick}
      onPointerDown={keepPlace}
      aria-label={label}
      title={label}
      disabled={disabled}
      className="flex items-center justify-center transition-colors disabled:cursor-not-allowed disabled:opacity-40"
      style={{
        borderLeft: first ? undefined : `1px solid ${rule}`,
        background: selected ? selectedBg : "transparent",
      }}
      onMouseEnter={(e) => {
        if (disabled || quiet) return;
        e.currentTarget.style.background = hoverBg;
        e.currentTarget.style.color = hoverFg;
      }}
      onMouseLeave={(e) => {
        if (disabled || quiet) return;
        e.currentTarget.style.background = selected ? selectedBg : "transparent";
        e.currentTarget.style.color = "inherit";
      }}
    >
      {children}
    </button>
  );
}
