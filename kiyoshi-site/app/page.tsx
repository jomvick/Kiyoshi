import {
  FileText,
  Kanban,
  Calendar,
  Blocks,
  BarChart3,
  Moon,
  Github,
  ArrowDown,
} from "lucide-react";
import { BotanicalLogo } from "@/components/BotanicalLogo";
import { ScreenshotFrame } from "@/components/ScreenshotFrame";

const features = [
  {
    icon: FileText,
    title: "Notes",
    body: "Fleeting thoughts captured in a single gesture, without ever forcing a project.",
  },
  {
    icon: Kanban,
    title: "Tasks & Kanban",
    body: "A list view to move fast, a board to see the big picture.",
  },
  {
    icon: Calendar,
    title: "Calendar",
    body: "Every deadline in its place, every day with open space.",
  },
  {
    icon: Blocks,
    title: "Canvas blocks",
    body: "Text, code, links, files — nine block types for free-form composition.",
  },
  {
    icon: BarChart3,
    title: "Analytics",
    body: "A calm read of your progress, without an anxiety-inducing dashboard.",
  },
  {
    icon: Moon,
    title: "Dark mode",
    body: "Warm charcoal, not cold black — designed for long sessions.",
  },
];

export default function Home() {
  return (
    <div className="relative overflow-hidden">
      {/* Ambient blobs, echoing AmbientZenBackground from the app */}
      <div className="pointer-events-none absolute -left-40 -top-40 h-[32rem] w-[32rem] rounded-full bg-mint/60 blur-3xl" />
      <div className="pointer-events-none absolute -right-32 top-96 h-[28rem] w-[28rem] rounded-full bg-sage-light/25 blur-3xl" />

      <header className="relative mx-auto flex max-w-6xl items-center justify-between px-6 py-8">
        <div className="flex items-center gap-2.5">
          <BotanicalLogo size={26} className="text-sage" />
          <span className="font-display text-lg font-semibold tracking-tight text-ink">
            Kiyoshi
          </span>
        </div>
        <nav className="flex items-center gap-8">
          <a
            href="#features"
            className="font-mono text-[11px] tracking-[0.15em] text-ink-muted transition hover:text-ink"
          >
            FEATURES
          </a>
          <a
            href="https://github.com/jomvick/Kiyoshi"
            className="flex items-center gap-1.5 font-mono text-[11px] tracking-[0.15em] text-ink-muted transition hover:text-ink"
          >
            <Github size={13} />
            GITHUB
          </a>
        </nav>
      </header>

      <main>
        {/* Hero */}
        <section className="relative mx-auto grid max-w-6xl gap-16 px-6 pb-28 pt-12 lg:grid-cols-[1fr_1.1fr] lg:items-center">
          <div>
            <p className="font-mono text-[11px] tracking-[0.3em] text-sage">
              DESKTOP WORKSPACE
            </p>
            <h1 className="font-display mt-4 text-5xl font-light leading-[1.08] tracking-tight text-ink sm:text-6xl">
              A quiet desktop
              <br />
              for your work.
            </h1>
            <p className="mt-6 max-w-md text-[15px] leading-relaxed text-ink-muted">
              Notes, tasks, projects, and a calendar — together in a single
              frosted-glass space, with no nagging notifications, no page that
              overwhelms.
            </p>
            <div className="mt-9 flex flex-wrap items-center gap-4">
              <a
                href="https://github.com/jomvick/Kiyoshi/releases"
                className="prismatic-ring flex items-center gap-2 rounded-2xl bg-sage px-6 py-3.5 text-[13px] font-semibold text-accent-ink shadow-[0_10px_30px_-10px_rgba(0,0,0,0.5)] transition hover:bg-sage-dim"
              >
                <ArrowDown size={15} />
                Download for Linux
              </a>
              <a
                href="https://github.com/jomvick/Kiyoshi"
                className="font-mono text-[11px] tracking-[0.15em] text-ink-muted transition hover:text-ink"
              >
                SOURCE CODE →
              </a>
            </div>
            <p className="mt-5 font-mono text-[10px] tracking-[0.1em] text-ink-faint">
              FREE · OPEN SOURCE · LINUX · MACOS · WINDOWS
            </p>
          </div>

          <div className="flex justify-center lg:justify-end">
            <ScreenshotFrame
              src="/screenshots/dashboard.png"
              alt="Kiyoshi dashboard in dark mode, showing the workspace overview and studio metrics"
              priority
              className="w-full max-w-xl"
            />
          </div>
        </section>

        {/* Features */}
        <section id="features" className="relative mx-auto max-w-6xl px-6 pb-28">
          <p className="font-mono text-[11px] tracking-[0.3em] text-sage">
            FEATURES
          </p>
          <h2 className="font-display mt-3 max-w-lg text-3xl font-light text-ink">
            Everything you need, nothing more.
          </h2>

          <div className="mt-12 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {features.map(({ icon: Icon, title, body }) => (
              <div key={title} className="glass rounded-2xl p-6">
                <div className="mb-4 inline-flex rounded-xl bg-sage/10 p-2.5">
                  <Icon size={18} className="text-sage" strokeWidth={2} />
                </div>
                <h3 className="font-display text-[15px] font-semibold text-ink">
                  {title}
                </h3>
                <p className="mt-2 text-[13px] leading-relaxed text-ink-muted">
                  {body}
                </p>
              </div>
            ))}
          </div>
        </section>

        {/* Showcase — real screenshots, replacing the coded mockup */}
        <section className="relative mx-auto max-w-6xl px-6 pb-28">
          <p className="font-mono text-[11px] tracking-[0.3em] text-sage">
            IN ACTION
          </p>
          <h2 className="font-display mt-3 max-w-lg text-3xl font-light text-ink">
            The same calm, on every page.
          </h2>

          <div className="mt-12 grid gap-6 md:grid-cols-2">
            <ScreenshotFrame
              src="/screenshots/projects.png"
              alt="Kiyoshi Projects screen, listing workspaces as glass cards"
            />
            <ScreenshotFrame
              src="/screenshots/tasks.png"
              alt="Kiyoshi Tasks screen in kanban board view, with To do, In progress, and Done columns"
            />
            <ScreenshotFrame
              src="/screenshots/notes.png"
              alt="Kiyoshi Notes screen, with quick capture and a note shown as a card"
              className="md:col-span-2"
            />
          </div>
        </section>

        {/* Closing */}
        <section className="relative mx-auto max-w-6xl px-6 pb-28">
          <div className="glass rounded-3xl px-10 py-16 text-center">
            <BotanicalLogo size={32} className="mx-auto text-sage" />
            <h2 className="font-display mx-auto mt-6 max-w-md text-3xl font-light text-ink">
              An empty space is waiting for you.
            </h2>
            <p className="mx-auto mt-3 max-w-sm text-[14px] text-ink-muted">
              Install Kiyoshi and start with a single thought.
            </p>
            <a
              href="https://github.com/jomvick/Kiyoshi/releases"
              className="prismatic-ring mt-8 inline-flex items-center gap-2 rounded-2xl bg-sage px-6 py-3.5 text-[13px] font-semibold text-accent-ink transition hover:bg-sage-dim"
            >
              <ArrowDown size={15} />
              Download Kiyoshi
            </a>
          </div>
        </section>
      </main>

      <footer className="relative mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 border-t border-outline px-6 py-8 sm:flex-row">
        <div className="flex items-center gap-2 text-ink-faint">
          <BotanicalLogo size={16} />
          <span className="font-mono text-[10px] tracking-[0.15em]">
            KIYOSHI — ZEN STUDIO
          </span>
        </div>
        <p className="font-mono text-[10px] tracking-[0.1em] text-ink-faint">
          BUILT WITH FLUTTER
        </p>
      </footer>
    </div>
  );
}
