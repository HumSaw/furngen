import { REPO_URL, VERSION } from '@/lib/furngen-data'
import { FurnGenMark } from './furngen-mark'

/** lucide-react v1 no longer ships brand marks, so the glyph lives here. */
function GithubMark({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 16 16" fill="currentColor" className={className} aria-hidden="true">
      <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-2.91-.88-2.91-2.82 0-.62.22-1.13.58-1.53-.05-.14-.25-.73.06-1.51 0 0 .6-.19 1.97.73a5.4 5.4 0 0 1 1.35-.18c.46 0 .92.06 1.35.18 1.37-.93 1.97-.73 1.97-.73.31.78.11 1.37.06 1.51.36.4.58.91.58 1.53 0 1.95-1.13 2.62-2.92 2.82.29.25.55.74.55 1.5 0 1.07-.01 1.94-.01 2.21 0 .21.15.46.55.38A7.99 7.99 0 0 0 16 8c0-4.42-3.58-8-8-8Z" />
    </svg>
  )
}

const links = [
  { label: 'Catalogue', href: '#catalogue' },
  { label: 'Styles', href: '#styles' },
  { label: 'Seeds', href: '#seeds' },
  { label: 'Install', href: '#install' },
  { label: 'Docs', href: '#docs' },
]

export function SiteNav() {
  return (
    <header className="sticky top-0 z-50 border-b border-border/60 bg-background/85 backdrop-blur-md">
      <div className="mx-auto flex h-16 w-full max-w-6xl items-center gap-6 px-6">
        <a href="#top" className="flex items-center gap-2.5">
          <FurnGenMark className="size-6 text-primary" />
          <span className="font-mono text-sm font-medium tracking-tight">FurnGen</span>
          <span className="hidden font-mono text-xs text-muted-foreground sm:inline">
            v{VERSION}
          </span>
        </a>

        <nav aria-label="Sections" className="ml-auto hidden items-center gap-7 md:flex">
          {links.map((link) => (
            <a
              key={link.href}
              href={link.href}
              className="text-sm text-muted-foreground transition-colors hover:text-foreground"
            >
              {link.label}
            </a>
          ))}
        </nav>

        <a
          href={REPO_URL}
          target="_blank"
          rel="noreferrer"
          className="ml-auto flex items-center gap-2 rounded-md border border-border px-3 py-1.5 text-sm transition-colors hover:bg-secondary md:ml-0"
        >
          <GithubMark className="size-4" />
          <span className="hidden sm:inline">GitHub</span>
        </a>
      </div>
    </header>
  )
}
