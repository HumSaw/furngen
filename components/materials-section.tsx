import Image from 'next/image'
import { fabrics, qualityLevels } from '@/lib/furngen-data'
import { SectionHeading } from './section-heading'

export function MaterialsSection() {
  return (
    <section id="materials" className="border-b border-border">
      <div className="mx-auto w-full max-w-6xl px-6 py-16 lg:py-24">
        <SectionHeading
          eyebrow="Materials"
          title="Corona when you have it, Physical when you don't"
          description="FurnGen detects Corona at load time and only builds Corona materials when the plugin is both installed and the active renderer. Otherwise it falls back to PhysicalMaterial, so the same file still renders in Scanline or Arnold."
        />

        <div className="mt-12 grid gap-8 lg:grid-cols-[1fr_1.1fr] lg:gap-12">
          <div className="overflow-hidden rounded-lg border border-border bg-card">
            <Image
              src="/images/fabric-detail.png"
              alt="Macro render of bouclé upholstery meeting a contrast piping seam, showing the procedural weave and surface fuzz"
              width={1024}
              height={1024}
              className="h-full w-full object-cover"
            />
          </div>

          {/* min-w-0 lets the quality table scroll in its wrapper instead of widening the page. */}
          <div className="flex min-w-0 flex-col gap-10">
            <div className="flex min-w-0 flex-col gap-4">
              <h3 className="font-mono text-xs tracking-tight text-primary">Fabrics</h3>
              <ul className="flex flex-col divide-y divide-border rounded-lg border border-border bg-card">
                {fabrics.map((fabric) => (
                  <li key={fabric.name} className="flex items-baseline justify-between gap-4 px-4 py-3">
                    <span className="font-medium tracking-tight">{fabric.name}</span>
                    <span className="text-right font-mono text-[11px] text-muted-foreground">
                      {fabric.detail}
                    </span>
                  </li>
                ))}
              </ul>
              <p className="text-sm leading-relaxed text-muted-foreground text-pretty">
                Every bump map is procedural — fractal noise sized per fabric, or a cellular map for
                leather pores. There are no bitmap dependencies, so moving the folder never breaks a
                material.
              </p>
            </div>

            <div className="flex min-w-0 flex-col gap-4">
              <h3 className="font-mono text-xs tracking-tight text-primary">Quality levels</h3>
              <div className="min-w-0 overflow-x-auto rounded-lg border border-border bg-card">
                <table className="w-full text-sm">
                  <caption className="sr-only">
                    Segment counts, fillet segments, TurboSmooth iterations and fine wrinkle pass per
                    quality level
                  </caption>
                  <thead>
                    <tr className="border-b border-border text-left font-mono text-[11px] text-muted-foreground">
                      <th scope="col" className="px-4 py-2.5 font-normal">
                        Level
                      </th>
                      <th scope="col" className="px-4 py-2.5 font-normal">
                        Segs
                      </th>
                      <th scope="col" className="px-4 py-2.5 font-normal">
                        Fillet
                      </th>
                      <th scope="col" className="px-4 py-2.5 font-normal">
                        Smooth
                      </th>
                      <th scope="col" className="px-4 py-2.5 font-normal">
                        Wrinkles
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {qualityLevels.map((level) => (
                      <tr key={level.name}>
                        <th scope="row" className="px-4 py-3 text-left font-medium tracking-tight">
                          {level.name}
                        </th>
                        <td className="px-4 py-3 font-mono text-muted-foreground">
                          {level.segments}
                        </td>
                        <td className="px-4 py-3 font-mono text-muted-foreground">{level.fillet}</td>
                        <td className="px-4 py-3 font-mono text-muted-foreground">
                          {level.turboSmooth}
                        </td>
                        <td className="px-4 py-3 font-mono text-muted-foreground">
                          {level.wrinkles ? 'yes' : 'no'}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              <p className="text-sm leading-relaxed text-muted-foreground text-pretty">
                Draft is the only level that skips the fine wrinkle pass, which is what makes it fast
                enough to explore with. Close-up 4K adds no new effect over Production — it raises
                density everywhere.
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
