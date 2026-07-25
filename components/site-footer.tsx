import { REPO_URL, VERSION } from '@/lib/furngen-data'
import { FurnGenMark } from './furngen-mark'

const columns = [
  {
    heading: 'Project',
    links: [
      { label: 'Repository', href: REPO_URL },
      { label: 'Releases', href: `${REPO_URL}/releases` },
      { label: 'Changelog', href: `${REPO_URL}/blob/main/CHANGELOG.md` },
      { label: 'License (MIT)', href: `${REPO_URL}/blob/main/LICENSE` },
    ],
  },
  {
    heading: 'Contribute',
    links: [
      { label: 'Contributing guide', href: `${REPO_URL}/blob/main/CONTRIBUTING.md` },
      { label: 'Report a bug', href: `${REPO_URL}/issues/new/choose` },
      { label: 'Security policy', href: `${REPO_URL}/blob/main/SECURITY.md` },
    ],
  },
  {
    heading: 'Documentation',
    links: [
      { label: 'English', href: `${REPO_URL}/blob/main/docs/en/README.md` },
      { label: 'Русский', href: `${REPO_URL}/blob/main/docs/ru/README.md` },
    ],
  },
]

export function SiteFooter() {
  return (
    <footer className="mx-auto w-full max-w-6xl px-6 py-14">
      <div className="flex flex-col gap-12 lg:flex-row lg:justify-between">
        <div className="flex max-w-sm flex-col gap-4">
          <div className="flex items-center gap-2.5">
            <FurnGenMark className="size-6 text-primary" />
            <span className="font-mono text-sm font-medium tracking-tight">FurnGen</span>
          </div>
          <p className="text-sm leading-relaxed text-muted-foreground text-pretty">
            A procedural furniture generator for Autodesk 3ds Max, written in plain MAXScript and
            released under the MIT license.
          </p>
        </div>

        <div className="grid gap-10 sm:grid-cols-3 sm:gap-14">
          {columns.map((column) => (
            <nav key={column.heading} aria-label={column.heading} className="flex flex-col gap-3">
              <h2 className="font-mono text-xs tracking-tight text-foreground">{column.heading}</h2>
              <ul className="flex flex-col gap-2.5">
                {column.links.map((link) => (
                  <li key={link.label}>
                    <a
                      href={link.href}
                      target="_blank"
                      rel="noreferrer"
                      className="text-sm text-muted-foreground transition-colors hover:text-foreground"
                    >
                      {link.label}
                    </a>
                  </li>
                ))}
              </ul>
            </nav>
          ))}
        </div>
      </div>

      <div className="mt-12 flex flex-col gap-2 border-t border-border pt-6 font-mono text-xs text-muted-foreground sm:flex-row sm:items-center sm:justify-between">
        <p>FurnGen v{VERSION} — requires 3ds Max 2020 or newer</p>
        <p>Renders on this page were produced for illustration.</p>
      </div>
    </footer>
  )
}
