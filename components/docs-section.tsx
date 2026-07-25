import { docs } from '@/lib/furngen-data'
import { SectionHeading } from './section-heading'

export function DocsSection() {
  return (
    <section id="docs" className="border-b border-border">
      <div className="mx-auto w-full max-w-6xl px-6 py-16 lg:py-24">
        <SectionHeading
          eyebrow="Documentation"
          title="Documented in English and Russian"
          description="Five guides, both languages, kept in the repository next to the code they describe."
        />

        <ul className="mt-12 grid gap-px overflow-hidden rounded-lg border border-border bg-border sm:grid-cols-2 lg:grid-cols-3">
          {docs.map((doc) => (
            <li key={doc.title} className="flex flex-col gap-3 bg-card p-6">
              <h3 className="text-lg font-medium tracking-tight">{doc.title}</h3>
              <p className="text-sm leading-relaxed text-muted-foreground text-pretty">
                {doc.description}
              </p>
              <div className="mt-auto flex items-center gap-2 pt-2 font-mono text-xs">
                <a
                  href={doc.en}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-sm bg-secondary px-2 py-1 text-secondary-foreground transition-colors hover:bg-primary hover:text-primary-foreground"
                >
                  English
                </a>
                <a
                  href={doc.ru}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-sm bg-secondary px-2 py-1 text-secondary-foreground transition-colors hover:bg-primary hover:text-primary-foreground"
                >
                  Русский
                </a>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </section>
  )
}
