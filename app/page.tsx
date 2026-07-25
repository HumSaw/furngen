import { Catalogue } from '@/components/catalogue'
import { DocsSection } from '@/components/docs-section'
import { Gallery } from '@/components/gallery'
import { Hero } from '@/components/hero'
import { InstallSteps } from '@/components/install-steps'
import { MaterialsSection } from '@/components/materials-section'
import { SeedSection } from '@/components/seed-section'
import { SiteFooter } from '@/components/site-footer'
import { SiteNav } from '@/components/site-nav'
import { StylesGrid } from '@/components/styles-grid'

export default function Page() {
  return (
    <>
      <SiteNav />
      <main>
        <Hero />
        <Catalogue />
        <StylesGrid />
        <Gallery />
        <SeedSection />
        <MaterialsSection />
        <InstallSteps />
        <DocsSection />
      </main>
      <SiteFooter />
    </>
  )
}
