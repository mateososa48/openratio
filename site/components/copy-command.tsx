"use client";

import { Check, Copy } from "lucide-react";
import { useRef, useState } from "react";

type State = "idle" | "copied" | "failed";

/**
 * A terminal command you can read or take.
 * The scroll container has to be a block element: `overflow-x-auto` on the inline
 * <code> itself does nothing and the long command pushes the whole page wide.
 * If the clipboard is refused, the text gets selected so it can still be copied
 * by hand rather than the button vanishing.
 */
export function CopyCommand({ command }: { command: string }) {
  const [state, setState] = useState<State>("idle");
  const codeRef = useRef<HTMLElement>(null);

  async function copy() {
    try {
      await navigator.clipboard.writeText(command);
      setState("copied");
    } catch {
      setState("failed");
      const node = codeRef.current;
      if (node) {
        const range = document.createRange();
        range.selectNodeContents(node);
        const sel = window.getSelection();
        sel?.removeAllRanges();
        sel?.addRange(range);
      }
    }
    setTimeout(() => setState("idle"), 2000);
  }

  return (
    <div className="rule-t rule-b flex items-center gap-2">
      <div className="min-w-0 flex-1 overflow-x-auto py-3">
        <code ref={codeRef} className="whitespace-nowrap text-[var(--color-chalk-dim)]">
          <span className="mr-2 text-[var(--color-chalk-faint)] select-none">$</span>
          {command}
        </code>
      </div>
      <button
        type="button"
        onClick={copy}
        aria-label={`Copy: ${command}`}
        className="flex size-11 shrink-0 items-center justify-center text-[var(--color-chalk-faint)] transition-colors hover:text-[var(--color-chalk)]"
      >
        {state === "copied" ? (
          <Check size={14} className="text-[var(--color-create)]" aria-hidden />
        ) : (
          <Copy size={14} aria-hidden />
        )}
      </button>
      <span aria-live="polite" className="sr-only">
        {state === "copied" ? "Copied to clipboard" : state === "failed" ? "Copy blocked, command selected instead" : ""}
      </span>
    </div>
  );
}
