import { TriangleAlert } from 'lucide-react'
import { REPO_URL } from '@/lib/furngen-data'
import { SectionHeading } from './section-heading'

const steps = [
  {
    title: 'Download and unblock',
    body: 'Grab the release archive and extract it anywhere. On Windows, right-click the ZIP first and tick Unblock, or Max will refuse the scripts.',
  },
  {
    title: 'Set system units to centimetres',
    body: 'Customize → Units Setup → System Unit Setup → 1 Unit = 1.0 Centimeters. Modifier amounts are absolute, so this has to be right before you generate.',
  },
  {
    title: 'Run FurnGen.ms',
    body: 'Scripting → Run Script… and pick FurnGen.ms. Keep the modules folder next to it — the loader resolves its seven modules relative to its own path.',
  },
]

export function InstallSteps() {
  return (
    <section id="install" className="border-b border-border">
      <div className="mx-auto w-full max-w-6xl px-6 py-16 lg:py-24">
        <SectionHeading
          eyebrow="Install"
          title="Three steps, no dependencies"
          description="FurnGen is plain MAXScript. There is nothing to compile, no plugin to register and no Python environment to manage."
        />

        <ol className="mt-12 grid gap-px overflow-hidden rounded-lg border border-border bg-border lg:grid-cols-3">
          {steps.map((step, index) => (
            <li key={step.title} className="flex flex-col gap-3 bg-card p-6">
              <span className="font-mono text-xs text-primary">
                {String(index + 1).padStart(2, '0')}
              </span>
              <h3 className="text-lg font-medium tracking-tight text-balance">{step.title}</h3>
              <p className="text-sm leading-relaxed text-muted-foreground text-pretty">
                {step.body}
              </p>
            </li>
          ))}
        </ol>

        <div className="mt-8 flex flex-col gap-6 lg:flex-row lg:items-start lg:justify-between">
          <p className="flex max-w-xl items-start gap-3 text-sm leading-relaxed text-muted-foreground">
            <TriangleAlert className="mt-0.5 size-4 shrink-0 text-primary" aria-hidden="true" />
            <span>
              On a successful load FurnGen registers a macro automatically, so you can drag{' '}
              <span className="font-mono text-foreground">FurnGen</span> from the{' '}
              <span className="font-mono text-foreground">FurnGen</span> category onto any toolbar.
              The button re-runs the loader from its original path, so do not move the folder
              afterwards.
            </span>
          </p>

          <a
            href={`${REPO_URL}#installation`}
            target="_blank"
            rel="noreferrer"
            className="shrink-0 self-start rounded-md border border-border px-5 py-2.5 text-sm font-medium transition-colors hover:bg-secondary"
          >
            Full install guide
          </a>
        </div>
      </div>
    </section>
  )
}
