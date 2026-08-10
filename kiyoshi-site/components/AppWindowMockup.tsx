import { Folder, Trash2, LayoutGrid, CheckSquare, FileText, Calendar, BarChart3, Settings } from "lucide-react";
import { BotanicalLogo } from "./BotanicalLogo";

const navItems = [
  { icon: LayoutGrid, label: "Dashboard" },
  { icon: Folder, label: "Projects", active: true },
  { icon: CheckSquare, label: "Tasks" },
  { icon: FileText, label: "Notes" },
  { icon: Calendar, label: "Calendar" },
  { icon: BarChart3, label: "Analytics" },
  { icon: Settings, label: "Settings" },
];

const cards = [
  { title: "Site redesign", status: "In Progress", dot: "bg-sage-light", note: "12 blocks · due Aug 14" },
  { title: "Mobile launch", status: "Not Started", dot: "bg-ink-faint", note: "3 blocks" },
];

/**
 * A coded recreation of the app's Projects screen — same sidebar, same glass
 * project cards — rather than a static screenshot, so the hero visual stays
 * crisp at any size and always matches the current palette.
 */
export function AppWindowMockup() {
  return (
    <div className="glass w-full max-w-xl overflow-hidden rounded-3xl">
      {/* Window chrome, matching the app's own title bar */}
      <div className="relative flex items-center justify-center gap-2 bg-[#1c1b1a] px-4 py-2.5">
        <div className="absolute left-4 flex gap-1.5">
          <span className="h-2.5 w-2.5 rounded-full bg-white/20" />
          <span className="h-2.5 w-2.5 rounded-full bg-white/20" />
          <span className="h-2.5 w-2.5 rounded-full bg-white/20" />
        </div>
        <span className="font-mono text-[11px] tracking-wide text-white/60">kiyoshi</span>
      </div>

      <div className="flex">
        {/* Sidebar */}
        <div className="hidden w-40 shrink-0 flex-col gap-1 border-r border-outline bg-white/40 p-4 sm:flex">
          <div className="mb-4 flex items-center gap-2">
            <BotanicalLogo size={22} className="text-sage" />
            <div className="leading-tight">
              <p className="font-display text-[13px] font-semibold text-ink">Kiyoshi</p>
              <p className="font-mono text-[8px] tracking-[0.2em] text-ink-faint">ZEN STUDIO</p>
            </div>
          </div>
          {navItems.map(({ icon: Icon, label, active }) => (
            <div
              key={label}
              className={`flex items-center gap-2 rounded-lg px-2.5 py-1.5 text-[11px] ${
                active ? "bg-sage text-white" : "text-ink-muted"
              }`}
            >
              <Icon size={13} strokeWidth={2} />
              <span>{label}</span>
            </div>
          ))}
        </div>

        {/* Content */}
        <div className="flex-1 p-5">
          <p className="font-mono text-[9px] tracking-[0.25em] text-sage-light">PROJECTS</p>
          <p className="font-display mb-4 text-xl font-light text-ink">Your workspaces</p>

          <div className="flex flex-col gap-3">
            {cards.map((card) => (
              <div key={card.title} className="glass rounded-2xl">
                <div className="flex items-center gap-2 rounded-t-2xl bg-sage/[0.06] px-3.5 py-2.5">
                  <div className="rounded-md bg-sage/10 p-1.5">
                    <Folder size={13} className="text-sage" />
                  </div>
                  <span className="flex-1 text-[12px] font-semibold text-ink">{card.title}</span>
                  <Trash2 size={12} className="text-ink-faint" />
                </div>
                <div className="flex items-center gap-2 px-3.5 py-2.5">
                  <span className={`h-1.5 w-1.5 rounded-full ${card.dot}`} />
                  <span className="text-[10px] font-medium text-ink-muted">{card.status}</span>
                  <span className="ml-auto text-[10px] text-ink-faint">{card.note}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
