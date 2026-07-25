import { styles } from '@/lib/furngen-data'
import { SectionHeading } from './section-heading'

export function StylesGrid() {
  return (
    <section id="styles" className="border-b border-border">
      <div className="mx-auto w-full max-w-6xl px-6 py-16 lg:py-24">
        <SectionHeading
          eyebrow="Styles"
          title="Eight coherent design languages"
          description="A style is not a colour swap. It sets the armrest silhouette, the leg profile and height, the seat proportions and the palette — and it will deliberately override choices that contradict it."
        />

        <ul className="mt-12 grid gap-px overflow-hidden rounded-lg border border-border bg-border sm:grid-cols-2 lg:grid-cols-4">
          {styles.map((style) => (
            <li key={style.name} className="flex flex-col gap-4 bg-card p-5">
              <div className="flex items-center gap-1.5" aria-hidden="true">
                {style.swatches.map((swatch) => (
                  <span
                    key={swatch}
                    className="size-6 rounded-sm border border-border/40"
                    style={{ backgroundColor: swatch }}
                  />
                ))}
                <span
                  className="ml-auto size-6 rounded-full border border-border/40"
                  style={{ backgroundColor: style.legSwatch }}
                />
              </div>

              <div className="flex flex-col gap-1">
                <h3 className="font-medium tracking-tight">{style.name}</h3>
                <p className="font-mono text-[11px] text-muted-foreground">
                  {style.arm} arms · {style.leg} legs
                </p>
              </div>

              <p className="mt-auto text-xs leading-relaxed text-muted-foreground">
                {style.note ?? 'no parameter overrides'}
              </p>
            </li>
          ))}
        </ul>

        <p className="mt-6 max-w-2xl text-sm leading-relaxed text-muted-foreground">
          Squares are the fabric colours the style picks from; the circle is its leg colour. Luxury
          forces velvet, Minimal and Brutalism switch piping off — so changing the style can visibly
          override a choice you made further down the panel. That is intentional.
        </p>
      </div>
    </section>
  )
}
