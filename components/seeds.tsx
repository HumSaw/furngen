import Image from 'next/image'
import { CheckCircle2, Dices, Layers, ShieldCheck } from 'lucide-react'
import { fabrics, qualityLevels } from '@/lib/furngen-data'
import { SectionHeading } from './section-heading'

const pillars = [
  {
    icon: Dices,
    title: 'Deterministic seeds',
    body: 'The seed drives every random decision — cushion jitter, palette pick, wrinkle placement. Same seed and same settings, same geometry, on any machine.',
  },
  {
    icon: Layers,
    title: 'Procedural materials',
    body: 'Corona materials when Corona is installed and active, Physical Material otherwise. Bump maps are Noise and Cellular, so nothing depends on a bitmap path.',
  },
  {
    icon: ShieldCheck,
    title: 'A QA pass on every build',
    body: 'Units, plausible dimensions, missing materials, empty meshes and leftover Box001 names are all checked. The panel reports a one-line summary.',
  },
  {
    icon: CheckCircle2,
    title: 'Safe to cancel',
    body: 'Generation runs inside an undo block. If a build throws, the partial geometry is rolled back and your scene is left clean.',
  },
]

export function Seeds() {
  return (
    <section id="seeds" className="border-b border-border">
      <div className="mx-auto w-full max-w-6xl px-6 py-16 lg:py-24">
        <SectionHeading
          eyebrow="Reproducibility"
          title="A seed you can put in a shot note"
          description="Randomised furniture is only useful if you can get the good one back. FurnGen treats the seed as the identity of the model, not as a throwaway."
        />

        <div className="mt-12 grid gap-px overflow-hidden rounded-lg border border-border bg-border sm:grid-cols-2">
          {pillars.map((pillar) => (
            <article key={pillar.title} className="flex flex-col gap-3 bg-card p-6">
              <pillar.icon className="size-5 text-primary" aria-hidden="true" />
              <h3 className="font-medium tracking-tight">{pillar.title}</h3>
              <p className="text-sm leading-relaxed text-muted-foreground text-pretty">
                {pillar.body}
              </p>
            </article>
          ))}
        </div>

        {/* Fabrics and quality, side by side with the fabric macro shot. */}
        <div className="mt-12 grid gap-8 lg:grid-cols-[1fr_1.1fr] lg:items-start">
          <div className="overflow-hidden rounded-lg border border-border bg-card">
            <Image
              src="/images/fabric-detail.png"
              alt="Close-up of generated upholstery showing procedural weave texture and cushion wrinkles"
              width={1024}
              height={1024}
              className="h-auto w-full"
            />
          </div>

          <div className="flex flex-col gap-8">
            <div className="flex flex-col gap-4">
              <h3 className="font-mono text-xs tracking-tight text-primary">Fabrics</h3>
              <ul className="flex flex-col gap-px overflow-hidden rounded-lg border border-border bg-border">
                {fabrics.map((fabric) => (
                  <li
                    key={fabric.name}
                    className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 bg-card px-4 py-3"
                  >
                    <span className="text-sm font-medium tracking-tight">{fabric.name}</span>
                    <span className="font-mono text-[11px] text-muted-foreground">
                      {fabric.detail}
                    </span>
                  </li>
                ))}
              </ul>
            </div>

            <div className="flex flex-col gap-4">
              <h3 className="font-mono text-xs tracking-tight text-primary">Quality</h3>
              <div className="overflow-hidden rounded-lg border border-border">
                <table className="w-full border-collapse text-sm">
                  <caption className="sr-only">
                    Segment counts, TurboSmooth iterations and wrinkle pass per quality level
                  </caption>
                  <thead>
                    <tr className="bg-secondary text-secondary-foreground">
                      <th scope="col" className="px-4 py-2.5 text-left font-medium">
                        Level
                      </th>
                      <th scope="col" className="px-3 py-2.5 text-right font-medium">
                        Segs
                      </th>
                      <th scope="col" className="px-3 py-2.5 text-right font-medium">
                        Smooth
                      </th>
                      <th scope="col" className="px-4 py-2.5 text-right font-medium">
                        Wrinkles
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {qualityLevels.map((level) => (
                      <tr key={level.name} className="border-t border-border bg-card">
                        <th scope="row" className="px-4 py-2.5 text-left font-normal">
                          {level.name}
                        </th>
                        <td className="px-3 py-2.5 text-right font-mono text-xs text-muted-foreground">
                          {level.segments}
                        </td>
                        <td className="px-3 py-2.5 text-right font-mono text-xs text-muted-foreground">
                          {level.turboSmooth}
                        </td>
                        <td className="px-4 py-2.5 text-right font-mono text-xs text-muted-foreground">
                          {level.wrinkles ? 'yes' : 'no'}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              <p className="text-sm leading-relaxed text-muted-foreground text-pretty">
                Draft is the only level that skips the fine wrinkle pass, which is what makes it
                fast enough to hold down Randomize against.
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
