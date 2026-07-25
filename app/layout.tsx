import { Analytics } from '@vercel/analytics/next'
import type { Metadata, Viewport } from 'next'
import { Geist, Geist_Mono } from 'next/font/google'
import './globals.css'

const geistSans = Geist({
  subsets: ['latin'],
  variable: '--font-geist-sans',
})

const geistMono = Geist_Mono({
  subsets: ['latin'],
  variable: '--font-geist-mono',
})

// Relative Open Graph paths need an absolute base, so resolve it from the
// deployment rather than hardcoding a domain that may not exist.
const siteUrl = process.env.VERCEL_PROJECT_PRODUCTION_URL
  ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
  : 'http://localhost:3000'

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: 'FurnGen — Procedural furniture for 3ds Max',
  description:
    'An open-source MAXScript tool that generates production-ready furniture in 3ds Max. 28 item types, 8 design styles, 5 upholstery fabrics, and deterministic seeds that rebuild identical geometry every time.',
  keywords: [
    '3ds Max',
    'MAXScript',
    'procedural furniture',
    'archviz',
    'Corona Renderer',
    'furniture generator',
  ],
  openGraph: {
    title: 'FurnGen — Procedural furniture for 3ds Max',
    description:
      'Generate production-ready furniture in 3ds Max. 8 styles, 5 fabrics, deterministic seeds.',
    type: 'website',
    images: ['/images/hero-sofa.png'],
  },
  generator: 'v0.app',
  icons: {
    icon: [
      {
        url: '/icon-light-32x32.png',
        media: '(prefers-color-scheme: light)',
      },
      {
        url: '/icon-dark-32x32.png',
        media: '(prefers-color-scheme: dark)',
      },
      {
        url: '/icon.svg',
        type: 'image/svg+xml',
      },
    ],
    apple: '/apple-icon.png',
  },
}

export const viewport: Viewport = {
  colorScheme: 'light dark',
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: 'oklch(0.976 0.006 85)' },
    { media: '(prefers-color-scheme: dark)', color: 'oklch(0.163 0.008 62)' },
  ],
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html
      lang="en"
      className={`bg-background ${geistSans.variable} ${geistMono.variable}`}
    >
      <body className="font-sans antialiased">
        {children}
        {process.env.NODE_ENV === 'production' && <Analytics />}
      </body>
    </html>
  )
}
