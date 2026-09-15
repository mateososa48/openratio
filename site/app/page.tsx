import Image from "next/image";
import { CopyCommand } from "@/components/copy-command";
import { DownloadButton } from "@/components/download-button";
import { Mark, Nav } from "@/components/nav";
import { Panel } from "@/components/panel";
import { Reveal } from "@/components/reveal";

const SOURCE = "https://github.com/mateososa48/openratio";

export default function Home() {
  return (
    <>
      <Nav />
      <main id="top" className="pt-[34px]">
        <Hero />
        <HowItWorks />
        <Privacy />
        <States />
        <Install />
        <Questions />
      </main>
      <Footer />
    </>
  );
}

/* ------------------------------------------------------------------- hero */

function Hero() {
  return (
    <section className="mx-auto flex min-h-[calc(100dvh-34px)] max-w-[1240px] flex-col justify-center px-4 py-16 sm:px-6 lg:py-20">
      <div className="grid grid-cols-[minmax(0,1fr)] items-center gap-14 lg:grid-cols-[minmax(0,1fr)_360px] lg:gap-20">
        <div>
          <h1 className="text-[clamp(38px,7.4vw,74px)] leading-[0.98] font-bold tracking-[-0.045em]">
            CREATE MORE.
            <br />
            CONSUME LESS.
          </h1>
          <p className="mt-7 max-w-[46ch] text-[14px] leading-[1.75] text-[var(--color-chalk-dim)]">
            A free menu bar app that splits your Mac screen time into what you made and what you
            watched.
          </p>
          <div className="mt-9 flex flex-wrap items-center gap-3">
            <DownloadButton />
            <a
              href={SOURCE}
              className="px-4 py-3 text-[13px] text-[var(--color-chalk-dim)] transition-colors hover:text-[var(--color-chalk)]"
            >
              VIEW SOURCE
            </a>
          </div>
        </div>

        <div className="flex justify-center lg:justify-end">
          <div className="w-[360px] max-w-full">
            <div className="origin-top scale-[0.86] sm:scale-100">
              <Panel />
            </div>
            <p className="mt-6 text-center text-[11px] leading-relaxed text-[var(--color-chalk-faint)] lg:text-right">
              The real panel. Press an arrow and watch the menu bar above change.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ----------------------------------------------------------- how it works */

const BEHAVIOUR = [
  {
    title: "IT WATCHES THE FRONT WINDOW",
    body: "Every second goes to the app you are actually in. In Safari, Chrome, Arc, Brave, Edge, Vivaldi and Dia it follows the active tab instead, so x.com and github.com get their own lines rather than hiding inside one browser.",
  },
  {
    title: "YOU ANSWER ONCE PER APP",
    body: "Press the up arrow for create or the down arrow for consume. The answer sticks for every day after that. Anything still unanswered stays orange and gets counted in the badge.",
  },
  {
    title: "AWAY TIME IS NOT YOUR TIME",
    body: "A locked screen, a sleeping Mac, the screensaver, or sixty seconds without a keystroke all stop the clock. Nothing is attributed to an app you walked away from.",
  },
];

const MENUBAR_STATES = [
  { glyph: "↑", tone: "text-[var(--color-create)]", meaning: "in something you call create" },
  { glyph: "↓", tone: "text-[var(--color-consume)]", meaning: "in something you call consume" },
  { glyph: "?", tone: "text-[var(--color-pending)]", meaning: "in something you never answered" },
  { glyph: "Ⅱ", tone: "text-[var(--color-chalk-faint)]", meaning: "away, asleep, or paused" },
];

function HowItWorks() {
  return (
    <section className="rule-t bg-[var(--color-ink-raised)]">
      <div className="mx-auto max-w-[1240px] px-4 py-20 sm:px-6 lg:py-28">
        <h2 className="text-[clamp(24px,3.6vw,38px)] leading-[1.06] font-bold tracking-[-0.03em]">
          ONE QUESTION PER APP.
          <br />
          THAT IS THE WHOLE INTERFACE.
        </h2>

        <div className="mt-14 grid grid-cols-[minmax(0,1fr)] gap-14 lg:grid-cols-[minmax(0,1fr)_400px] lg:gap-20">
          <ul>
            {BEHAVIOUR.map((item, i) => (
              <Reveal key={item.title} delay={i * 0.05}>
                <li className="rule-b py-7 first:pt-0">
                  <h3 className="font-semibold tracking-label">{item.title}</h3>
                  <p className="mt-3 max-w-[62ch] leading-[1.7] text-[var(--color-chalk-dim)]">
                    {item.body}
                  </p>
                </li>
              </Reveal>
            ))}
          </ul>

          <Reveal delay={0.1}>
            <div className="rule-t rule-b lg:sticky lg:top-[74px]">
              <p className="rule-b py-4 font-semibold tracking-label">THE MENU BAR KEEPS SCORE</p>
              <dl>
                {MENUBAR_STATES.map((s) => (
                  <div key={s.glyph} className="rule-b flex items-center gap-4 py-0 last:border-b-0" style={{ height: 44 }}>
                    <dt className={`w-[74px] shrink-0 tabular-nums ${s.tone}`}>
                      {s.glyph} 67/33
                    </dt>
                    <dd className="text-[var(--color-chalk-dim)]">{s.meaning}</dd>
                  </div>
                ))}
              </dl>
              <p className="py-5 leading-[1.7] text-[var(--color-chalk-faint)]">
                The number is the whole day so far. The glyph is whatever you are doing this
                second, so one glance gives you both.
              </p>
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  );
}

/* ---------------------------------------------------------------- privacy */

function Privacy() {
  return (
    <section className="rule-t">
      <div className="mx-auto max-w-[1240px] px-4 py-20 sm:px-6 lg:py-28">
        <div className="grid grid-cols-[minmax(0,1fr)] gap-12 lg:grid-cols-2 lg:gap-20">
          <Reveal>
            <h2 className="text-[clamp(24px,3.6vw,38px)] leading-[1.06] font-bold tracking-[-0.03em]">
              NOTHING LEAVES
              <br />
              YOUR MAC.
            </h2>
            <p className="mt-6 max-w-[48ch] leading-[1.7] text-[var(--color-chalk-dim)]">
              No account, no server, no analytics, no network calls of any kind. Your whole history
              is one readable file. Open it, edit it, back it up, or delete it and start over.
            </p>
            <p className="mt-6 leading-[1.7] text-[var(--color-chalk-faint)]">
              Reading the active tab needs macOS Automation permission, which your Mac asks you for
              the first time you open a browser. Say no and the browser is tracked as one app.
            </p>
          </Reveal>

          <Reveal delay={0.08}>
            <figure className="rule-t rule-b overflow-hidden">
              <figcaption className="rule-b flex h-11 items-center justify-between gap-4 text-[11px] text-[var(--color-chalk-faint)]">
                <span className="truncate">~/Library/Application Support/OpenRatio/data.json</span>
              </figcaption>
              <pre className="overflow-x-auto py-5 text-[11px] leading-[1.9] text-[var(--color-chalk-dim)]">
                <code>{`{
  "categories": {
    "com.figma.Desktop": "create",
    "web:youtube.com": "consume"
  },
  "days": {
    "2026-09-15": {
      "activities": {
        "web:youtube.com": {
          "name": "youtube.com",
          "seconds": 2900
        }
      }
    }
  }
}`}</code>
              </pre>
            </figure>
          </Reveal>
        </div>
      </div>
    </section>
  );
}

/* ----------------------------------------------------------------- states */

const SHOTS = [
  { src: "/shots/activity.png", alt: "The OpenRatio panel listing today's apps with create and consume arrows.", caption: "The day so far" },
  { src: "/shots/pending.png", alt: "The panel filtered down to two apps that have not been categorized.", caption: "Filtered to what you skipped" },
  { src: "/shots/history.png", alt: "The panel showing five days of create to consume ratios as green and red bars.", caption: "Five days of history" },
  { src: "/shots/light.png", alt: "The same panel rendered in light mode.", caption: "Light mode" },
];

function States() {
  return (
    <section className="rule-t bg-[var(--color-ink-raised)]">
      <div className="mx-auto max-w-[1240px] px-4 py-20 sm:px-6 lg:py-28">
        <h2 className="text-[clamp(24px,3.6vw,38px)] leading-[1.06] font-bold tracking-[-0.03em]">
          EVERY STATE, ACTUAL SIZE.
        </h2>
        {/* 360 points wide, which is what the panel measures on your Mac. Four of them
            do not fit, so the strip scrolls rather than shrinking the product. */}
        <Reveal className="mt-12">
          <div className="strip panel-scroll -mx-4 snap-x snap-mandatory overflow-x-auto px-4 pb-5 sm:-mx-6 sm:px-6">
            <ul className="flex w-max gap-6">
              {SHOTS.map((shot) => (
                <li key={shot.src} className="w-[360px] shrink-0 snap-start">
                  <Image
                    src={shot.src}
                    alt={shot.alt}
                    width={360}
                    height={362}
                    className="w-[360px]"
                    sizes="360px"
                  />
                  <p className="mt-4 text-[11px] text-[var(--color-chalk-faint)]">{shot.caption}</p>
                </li>
              ))}
            </ul>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

/* ---------------------------------------------------------------- install */

const STEPS = [
  {
    n: "1",
    title: "OPEN THE DISK IMAGE, DRAG OPENRATIO ACROSS",
    body: "The window shows you exactly where it goes. No installer, nothing to configure.",
  },
  {
    n: "2",
    title: "CLEAR THE FIRST LAUNCH BLOCK",
    body: "OpenRatio is not notarized, so macOS refuses to open it the first time. Open System Settings, go to Privacy and Security, scroll to the bottom, and click Open Anyway. You only do this once.",
  },
  {
    n: "3",
    title: "ANSWER YOUR FIRST FEW APPS",
    body: "The panel opens itself on first launch. Give your three or four most-used apps an arrow and the menu bar starts keeping score.",
  },
];

const BREW_INSTALL = "brew install --cask mateososa48/openratio/openratio";
const BREW_UNBLOCK = "xattr -dr com.apple.quarantine /Applications/OpenRatio.app";

function Install() {
  return (
    <section id="install" className="rule-t scroll-mt-[34px]">
      <div className="mx-auto max-w-[1240px] px-4 py-20 sm:px-6 lg:py-28">
        <div className="grid grid-cols-[minmax(0,1fr)] gap-14 lg:grid-cols-[minmax(0,420px)_minmax(0,1fr)] lg:gap-20">
          <div className="lg:sticky lg:top-[74px] lg:self-start">
            <h2 className="text-[clamp(24px,3.6vw,38px)] leading-[1.06] font-bold tracking-[-0.03em]">
              FREE, AND IT STAYS FREE.
            </h2>
            <p className="mt-6 max-w-[42ch] leading-[1.7] text-[var(--color-chalk-dim)]">
              MIT licensed. No trial, no upgrade, no account. Build it yourself from source if you
              would rather not trust a download.
            </p>
            <div className="mt-8">
              <DownloadButton />
            </div>
            <dl className="rule-t mt-10">
              {[
                ["REQUIRES", "macOS 13 Ventura or later"],
                ["ARCHITECTURE", "Apple silicon and Intel"],
                ["DOWNLOAD", "519 KB disk image"],
                ["LICENSE", "MIT"],
              ].map(([k, v]) => (
                <div key={k} className="rule-b flex items-center justify-between gap-6" style={{ height: 44 }}>
                  <dt className="tracking-label text-[var(--color-chalk-faint)]">{k}</dt>
                  <dd className="text-right text-[var(--color-chalk-dim)]">{v}</dd>
                </div>
              ))}
            </dl>
          </div>

          <div>
            <ol>
              {STEPS.map((step, i) => (
                <Reveal key={step.n} delay={i * 0.05}>
                  <li className="rule-b grid grid-cols-[38px_minmax(0,1fr)] gap-5 py-7 first:pt-0">
                    <span className="text-[var(--color-chalk-faint)] tabular-nums">{step.n}</span>
                    <div>
                      <h3 className="font-semibold tracking-label">{step.title}</h3>
                      <p className="mt-3 max-w-[58ch] leading-[1.7] text-[var(--color-chalk-dim)]">
                        {step.body}
                      </p>
                    </div>
                  </li>
                </Reveal>
              ))}
            </ol>

            <Reveal delay={0.1}>
              <div className="mt-12">
                <h3 className="font-semibold tracking-label">OR USE HOMEBREW</h3>
                <p className="mt-3 mb-5 max-w-[58ch] leading-[1.7] text-[var(--color-chalk-dim)]">
                  You still have to clear the block, but the second command does it without
                  a trip through System Settings.
                </p>
                <CopyCommand command={BREW_INSTALL} />
                <div className="mt-3">
                  <CopyCommand command={BREW_UNBLOCK} />
                </div>
              </div>
            </Reveal>
          </div>
        </div>
      </div>
    </section>
  );
}

/* -------------------------------------------------------------- questions */

const QA = [
  {
    q: "Why does macOS say it cannot check the app for malware?",
    a: "Because it is not notarized. Notarizing needs a paid Apple Developer account, which this project does not have yet. Homebrew used to be able to skip the block, but that option was removed in Homebrew 6, so every install route hits it once. The source and the workflow that builds the app are both public, so you can compile it yourself and skip the warning entirely.",
  },
  {
    q: "What exactly gets recorded?",
    a: "The bundle identifier of the frontmost app, or the host name of the active browser tab, plus how many seconds each one had the front window. No page titles, no full addresses, no keystrokes, no screenshots.",
  },
  {
    q: "Does it work with Firefox?",
    a: "Firefox has no scripting interface for its active tab, so it is tracked as a single app rather than by site. Safari, Chrome, Arc, Brave, Edge, Vivaldi, Opera and Dia are all tracked by site.",
  },
  {
    q: "Can I change my mind about an app?",
    a: "Yes. Press the other arrow at any time. Categories are global, so the change applies to every day in your history, not just today.",
  },
  {
    q: "Is this the same as Ratio by Visualize Value?",
    a: "No. Ratio is a paid app by Visualize Value and is the reason this exists. OpenRatio is an independent, free reimplementation of the same idea, not affiliated with or endorsed by them. If you want the original, buy theirs.",
  },
];

function Questions() {
  return (
    <section className="rule-t bg-[var(--color-ink-raised)]">
      <div className="mx-auto max-w-[1240px] px-4 py-20 sm:px-6 lg:py-28">
        <h2 className="text-[clamp(24px,3.6vw,38px)] leading-[1.06] font-bold tracking-[-0.03em]">
          QUESTIONS.
        </h2>
        {/* Native disclosure: keyboard and screen reader behaviour for free, and it
            matches the page's flat, ruled surface better than a themed accordion. */}
        <div className="rule-t mt-12 max-w-[760px]">
          {QA.map((item) => (
            <details key={item.q} className="rule-b group">
              <summary className="flex cursor-pointer list-none items-center gap-5 py-6 text-[13px] font-semibold transition-colors hover:text-[var(--color-create)] [&::-webkit-details-marker]:hidden">
                <span className="flex-1">{item.q}</span>
                <span
                  aria-hidden
                  className="shrink-0 text-[var(--color-chalk-faint)] transition-transform duration-200 group-open:rotate-45"
                >
                  +
                </span>
              </summary>
              <p className="max-w-[70ch] pb-7 leading-[1.8] text-[var(--color-chalk-dim)]">{item.a}</p>
            </details>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ----------------------------------------------------------------- footer */

function Footer() {
  return (
    <footer className="rule-t">
      <div className="mx-auto flex max-w-[1240px] flex-col gap-6 px-4 py-10 sm:flex-row sm:items-center sm:px-6">
        <p className="flex items-center gap-2 font-semibold tracking-label">
          <Mark />
          OPENRATIO
        </p>
        <nav className="-my-3 flex flex-wrap gap-x-6 text-[var(--color-chalk-dim)] sm:ml-auto">
          <a href={SOURCE} className="inline-flex min-h-[44px] items-center transition-colors hover:text-[var(--color-chalk)]">
            SOURCE
          </a>
          <a href={`${SOURCE}/issues`} className="inline-flex min-h-[44px] items-center transition-colors hover:text-[var(--color-chalk)]">
            REPORT A BUG
          </a>
          <a href={`${SOURCE}/blob/main/LICENSE`} className="inline-flex min-h-[44px] items-center transition-colors hover:text-[var(--color-chalk)]">
            MIT LICENSE
          </a>
        </nav>
      </div>
      <p className="mx-auto max-w-[1240px] px-4 pb-10 text-[11px] leading-[1.8] text-[var(--color-chalk-faint)] sm:px-6">
        Inspired by Ratio from Visualize Value. Independent, unaffiliated, and free.
      </p>
    </footer>
  );
}
