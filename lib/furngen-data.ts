/**
 * Content for the FurnGen landing page.
 *
 * Every value here mirrors the MAXScript source so the page cannot drift from
 * the tool. Style swatches are the literal `color r g b` values from
 * `fgApplyStyle` in src/modules/core.ms.
 */

export const VERSION = '1.0.0'
export const REPO_URL = 'https://github.com/OWNER/furngen'

export type Category = {
  name: string
  count: number
  types: string[]
}

export const categories: Category[] = [
  {
    name: 'Sofas',
    count: 6,
    types: ['Straight', 'Corner', 'Modular', 'Loveseat', 'Chaise lounge', 'Armchair'],
  },
  {
    name: 'Beds',
    count: 4,
    types: ['Single', 'Double', 'King size', 'Canopy'],
  },
  {
    name: 'Chairs',
    count: 4,
    types: ['Dining chair', 'Bar stool', 'Lounge chair', 'Stool'],
  },
  {
    name: 'Tables',
    count: 5,
    types: ['Dining', 'Coffee', 'Side', 'Desk', 'Nightstand'],
  },
  {
    name: 'Storage',
    count: 2,
    types: ['Two-door wardrobe', 'Three-drawer dresser'],
  },
  {
    name: 'Decor',
    count: 7,
    types: ['Ottoman', 'Rug', 'Floor lamp', 'Bookshelf', 'TV unit', 'Plant', 'Mirror'],
  },
]

export type Style = {
  name: string
  arm: string
  leg: string
  /** Literal fabric colours the style picks from, as CSS rgb(). */
  swatches: string[]
  legSwatch: string
  note?: string
}

export const styles: Style[] = [
  {
    name: 'Modern',
    arm: 'square',
    leg: 'block',
    swatches: ['rgb(82 86 92)', 'rgb(168 160 148)', 'rgb(60 62 66)'],
    legSwatch: 'rgb(30 30 30)',
  },
  {
    name: 'Minimal',
    arm: 'square',
    leg: 'none',
    swatches: ['rgb(235 232 226)', 'rgb(210 205 196)', 'rgb(190 188 184)'],
    legSwatch: 'rgb(40 40 40)',
    note: 'forces piping off',
  },
  {
    name: 'Scandinavian',
    arm: 'rounded',
    leg: 'cone',
    swatches: ['rgb(214 208 196)', 'rgb(158 170 160)', 'rgb(226 220 208)'],
    legSwatch: 'rgb(172 132 88)',
    note: 'light oak legs',
  },
  {
    name: 'Japandi',
    arm: 'square',
    leg: 'block',
    swatches: ['rgb(196 186 168)', 'rgb(150 140 124)', 'rgb(120 116 108)'],
    legSwatch: 'rgb(70 52 38)',
    note: 'drops height to 74 cm',
  },
  {
    name: 'Luxury',
    arm: 'rounded',
    leg: 'cylinder',
    swatches: ['rgb(34 60 54)', 'rgb(94 66 44)', 'rgb(44 48 74)'],
    legSwatch: 'rgb(190 160 100)',
    note: 'forces velvet, brass legs',
  },
  {
    name: 'Classic',
    arm: 'rounded',
    leg: 'cone',
    swatches: ['rgb(120 96 72)', 'rgb(96 104 92)', 'rgb(140 120 96)'],
    legSwatch: 'rgb(56 38 26)',
    note: 'forces piping on',
  },
  {
    name: 'Brutalism',
    arm: 'square',
    leg: 'none',
    swatches: ['rgb(110 110 108)', 'rgb(88 84 80)', 'rgb(130 126 120)'],
    legSwatch: 'rgb(90 90 90)',
    note: 'softness clamped to 0.35',
  },
  {
    name: 'Mid-century',
    arm: 'pillow',
    leg: 'cone',
    swatches: ['rgb(190 120 60)', 'rgb(96 118 108)', 'rgb(180 150 100)'],
    legSwatch: 'rgb(110 74 46)',
    note: 'walnut legs',
  },
]

export const fabrics = [
  { name: 'Bouclé', detail: 'coarse fractal noise, low sheen' },
  { name: 'Velvet', detail: 'fine noise, high sheen' },
  { name: 'Linen', detail: 'medium weave, matte' },
  { name: 'Cotton', detail: 'fine weave, matte' },
  { name: 'Leather', detail: 'cellular pores, soft sheen' },
]

export type QualityLevel = {
  name: string
  segments: number
  fillet: number
  turboSmooth: number
  wrinkles: boolean
}

export const qualityLevels: QualityLevel[] = [
  { name: 'Draft', segments: 3, fillet: 2, turboSmooth: 1, wrinkles: false },
  { name: 'Production', segments: 5, fillet: 3, turboSmooth: 2, wrinkles: true },
  { name: 'Close-up 4K', segments: 8, fillet: 4, turboSmooth: 3, wrinkles: true },
]

export const docs = [
  {
    title: 'Getting started',
    titleRu: 'Быстрый старт',
    description: 'Install, set your system units, and generate the first sofa.',
    en: `${REPO_URL}/blob/main/docs/en/getting-started.md`,
    ru: `${REPO_URL}/blob/main/docs/ru/getting-started.md`,
  },
  {
    title: 'User guide',
    titleRu: 'Руководство пользователя',
    description: 'Every panel control, all categories, styles, fabrics and presets.',
    en: `${REPO_URL}/blob/main/docs/en/user-guide.md`,
    ru: `${REPO_URL}/blob/main/docs/ru/user-guide.md`,
  },
  {
    title: 'Architecture',
    titleRu: 'Архитектура',
    description: 'Module layout, load order, geometry and material pipelines.',
    en: `${REPO_URL}/blob/main/docs/en/architecture.md`,
    ru: `${REPO_URL}/blob/main/docs/ru/architecture.md`,
  },
  {
    title: 'Extending',
    titleRu: 'Расширение системы',
    description: 'Add your own furniture type, style or upholstery fabric.',
    en: `${REPO_URL}/blob/main/docs/en/extending.md`,
    ru: `${REPO_URL}/blob/main/docs/ru/extending.md`,
  },
  {
    title: 'Troubleshooting',
    titleRu: 'Решение проблем',
    description: 'Grey materials, load failures, torn geometry, reading the Listener.',
    en: `${REPO_URL}/blob/main/docs/en/troubleshooting.md`,
    ru: `${REPO_URL}/blob/main/docs/ru/troubleshooting.md`,
  },
]
