export function SectionHeading({
  eyebrow,
  title,
  description,
}: {
  eyebrow: string
  title: string
  description?: string
}) {
  return (
    <div className="flex max-w-2xl flex-col gap-4">
      <p className="font-mono text-xs tracking-tight text-primary">{eyebrow}</p>
      <h2 className="text-3xl font-medium tracking-tight text-balance sm:text-4xl">{title}</h2>
      {description ? (
        <p className="text-lg leading-relaxed text-muted-foreground text-pretty">{description}</p>
      ) : null}
    </div>
  )
}
