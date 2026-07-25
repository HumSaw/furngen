import { Dices, Save, ShieldCheck } from 'lucide-react'
import { SectionHeading } from './section-heading'

const points = [
  {
    icon: Dices,
    title: 'Randomize, then keep',
    body: 'Hammer Randomize in Draft quality until a silhouette catches your eye, then note the seed. Every jitter — cushion sag, arm asymmetry, throw placement — replays identically.',
  },
  {
    icon: Save,
    title: 'Presets are just numbers',
    body: 'Saving a preset writes the whole configuration to an INI file in your Max user-scripts folder. Share that file and a colleague gets your exact sofa, not an approximation.',
  },
  {
    icon: ShieldCheck,
    title: 'Failure rolls back',
    body: 'If a build throws, the partial geometry is undone through max undo. You never end up hand-deleting half a wardrobe out of the scene.',
  },
]

export function SeedSection() {
  return (
    <section id="seeds" className="border-b border-border">
      <div className="mx-auto grid w-full max-w-6xl gap-12 px-6 py-16 lg:grid-cols-2 lg:items-start lg:gap-16 lg:py-24">
        <div className="flex flex-col gap-10">
          <SectionHeading
            eyebrow="Reproducibility"
            title="One number rebuilds the exact model"
            description="Randomness in FurnGen is seeded, never ambient. Identical parameters plus an identical seed always produce identical geometry — which is what makes the variation safe to rely on."
          />

          <ul className="flex flex-col gap-7">
            {points.map((point) => (
              <li key={point.title} className="flex gap-4">
                <point.icon
                  className="mt-0.5 size-5 shrink-0 text-primary"
                  aria-hidden="true"
                />
                <div className="flex flex-col gap-1.5">
                  <h3 className="font-medium tracking-tight">{point.title}</h3>
                  <p className="text-sm leading-relaxed text-muted-foreground text-pretty">
                    {point.body}
                  </p>
                </div>
              </li>
            ))}
          </ul>
        </div>

        {/* min-w-0 lets the snippet scroll inside the panel instead of widening the page. */}
        <figure className="min-w-0 overflow-hidden rounded-lg border border-border bg-card">
          <figcaption className="flex items-center gap-2 border-b border-border px-4 py-2.5 font-mono text-xs text-muted-foreground">
            <span className="size-2 rounded-full bg-primary" aria-hidden="true" />
            MAXScript Listener
          </figcaption>
          <pre className="overflow-x-auto p-4 font-mono text-[13px] leading-relaxed">
            <code>{`-- generate the same armchair twice, from anywhere
cfg = FurnGenConfig()
fgApplyStyle cfg #midcentury
cfg.sofaType = #armchair
cfg.fabric   = #leather
cfg.seed     = 48213
cfg.quality  = 2

fgBuildItem cfg #sofa #armchair

FurnGen QA: OK: 11 parts / 24680 tris, render ready`}</code>
          </pre>
        </figure>
      </div>
    </section>
  )
}
