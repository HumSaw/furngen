/**
 * FurnGen mark: a sofa reduced to the three volumes the generator actually
 * builds -- back, seat and two arms -- on a pair of tapered legs.
 */
export function FurnGenMark({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.6"
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      aria-hidden="true"
    >
      {/* back */}
      <path d="M4 11V7.5A1.5 1.5 0 0 1 5.5 6h13A1.5 1.5 0 0 1 20 7.5V11" />
      {/* arms */}
      <path d="M4 11h2.5v5H4zM17.5 11H20v5h-2.5z" />
      {/* seat */}
      <path d="M6.5 12.5h11V16h-11z" />
      {/* legs */}
      <path d="M6 16v2.5M18 16v2.5" />
    </svg>
  )
}
