import { AlertTriangle } from 'lucide-react'
import { REPO_URL } from '@/lib/furngen-data'
import { SectionHeading } from './section-heading'

const steps = [
  {
    title: 'Download and unzip',
    body: 'Grab the latest archive from Releases and unzip it anywhere you like. Keep FurnGen.ms and the modules folder together — the loader finds its modules relative to itself.',
    code: 'FurnGen/\n├── FurnGen.ms\n└── modules/*.ms',
  },
  {
    title: 'Set system units to centimetres',
    body: 'Customize → Units Setup → System Unit Setup. FurnGen works in centimetres because modifier amounts in 3ds Max are absolute, not relative.',
    code: '1 Unit = 1.0 Centimeters',
  },
  {
    title: 'Run the script',
    body: 'Scripting → Run Script… and pick FurnGen.ms. The panel opens on the right, and a FurnGen macro is registered so you can drag a button onto any toolbar.',
    code: 'Scripting → Run Script… → FurnGen.ms',
  },
  {
    title: 'Generate',
    body: 'Pick a category, a style and a fabric, then press GENERATE. The status line reports the part count, the triangle count and the QA result.',
    code: 'OK: 34 parts / 118240 tris, render ready',
  },
]

export function Install() {
  return (
    <section id="install" className="border-b border-border">
      <div className="mx-auto w-full max-w-6xl px-6 py-16 lg:py-24">
        <SectionHeading
          eyebrow="Install"
          title="Four steps, no dependencies"
          description="FurnGen is plain MAXScript. There is nothing to compile, no plugin to register and no Python environment to manage."
        />

        <ol className="mt-12 grid gap-px overflow-hidden rounded-lg border border-border bg-border sm:grid-cols-2">
          {steps.map((step, index) => (
            <li key={step.title} className="flex flex-col gap-3 bg-card p-6">
              <div className="flex items-center gap-3">
                <span
                  aria-hidden="true"
                  className="flex size-6 shrink-0 items-center justify-center rounded-sm bg-primary font-mono text-xs text-primary-foreground"
                >
                  {index + 1}
                </span>
                <h3 className="font-medium tracking-tight">{step.title}</h3>
              </div>
              <p className="text-sm leading-relaxed text-muted-foreground text-pretty">
                {step.body}
              </p>
              <pre className="mt-auto overflow-x-auto rounded-sm bg-secondary p-3 font-mono text-[11px] leading-relaxed text-secondary-foreground">
                <code>{step.code}</code>
              </pre>
            </li>
          ))}
        </ol>

        <div className="mt-8 flex flex-col gap-6 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-start gap-3 rounded-lg border border-border bg-card p-4">
            <AlertTriangle className="mt-0.5 size-4 shrink-0 text-primary" aria-hidden="true" />
            <p className="text-sm leading-relaxed text-muted-foreground text-pretty">
              Corona Renderer is optional. Without it, materials are built on Physical Material and
              render correctly in Scanline and Arnold.
            </p>
          </div>

          <a
            href={`${REPO_URL}/releases/latest`}
            target="_blank"
            rel="noreferrer"
            className="inline-flex shrink-0 items-center justify-center gap-2 rounded-md bg-primary px-5 py-2.5 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90"
          >
            Download FurnGen
          </a>
        </div>
      </div>
    </section>
  )
}
