# Расширение системы

[English](../en/extending.md) &middot; Русский

Добавление своего предмета мебели, стиля или ткани.

---

## Правила модуля

Эти соглашения появились из реальных ошибок парсинга и рендера — их стоит
соблюдать, иначе сбой проявится не сразу.

1. **Одно объявление `local` на строку.** Многострочные списки `local a = …, b = …`
   с вызовами функций MAXScript разбирает ненадёжно.
2. **Материал назначается сразу при создании детали.** Не откладывайте это
   на финализацию: если сборка упадёт в середине, деталь останется серой.
3. **Габариты берутся из типа предмета,** а не из `cfg.width`. Иначе спиннер
   ширины дивана раздует кровать или тумбочку.
4. **Fillet всегда через `fgSoftBlock` / `fgCushion`** — там стоит защита от
   вывернутой геометрии.
5. **Один `case` — одна строка на ветку не обязателен, но блоки в скобках обязательны.**

---

## Новый тип внутри существующей категории

Пример: добавим кофейный столик с эпоксидной вставкой.

### 1. Ветка в сборщике

`src/modules/furniture.ms`, функция `fgBuildTable`:

```maxscript
#tableRiver:
(
    local w = 120.0
    local d = 60.0
    local h = 42.0
    local topMtl = fgMakeWoodMtl cfg.legColor
    local resinMtl = fgMakeFlatMtl (color 40 70 90) 0.05 mtlName:"FurnGen_Resin"

    fgFourLegs parts w d (h - 4.0) topMtl "River" inset:8.0

    local top = fgTableTop cfg w d 4.0 (h - 4.0) topMtl round:false
    append parts top

    local vein = ChamferBox width:(w * 0.15) length:d height:4.2 fillet:0.4 name:"River_Resin"
    vein.pos = [fgJitter 0.0 8.0, 0, h - 4.0]
    vein.material = resinMtl
    append parts vein
)
```

### 2. Регистрация в UI

`src/modules/ui.ms` — добавьте ключ и подпись в **соответствующие позиции**
массивов (индекс категории `Tables` — четвёртый):

```maxscript
global FurnGen_TypeKeys = #(
    ...
    #(#tableDining, #tableCoffee, #tableSide, #tableDesk, #tableNightstand, #tableRiver),
    ...
)
global FurnGen_TypeLabels = #(
    ...
    #("Dining table", "Coffee table", "Side table", "Desk", "Nightstand", "River table"),
    ...
)
```

Порядок ключей и подписей должен совпадать — линтер проверяет длину массивов.

### 3. Проверка

```bash
pnpm lint
```

---

## Новая категория

Пример: светильники.

### 1. Сборщик

Создайте `src/modules/lighting.ms`:

```maxscript
/*
    lighting.ms -- pendant and wall lamps
    ------------------------------------
    Depends on: core.ms, geometry.ms, materials.ms
*/

fn fgBuildLighting cfg itemType =
(
    fgSetSeed cfg.seed
    local parts = #()
    local metalMtl = fgMakeMetalMtl (color 190 160 100) 0.25 mtlName:"FurnGen_LampMetal"

    case itemType of
    (
        #pendant:
        (
            local shade = Cone radius1:18.0 radius2:6.0 height:20.0 sides:32 name:"Pendant_Shade"
            shade.material = metalMtl
            append parts shade
        )
    )

    fgFinalizeItem parts ("Lighting_" + (cfg.style as string) + "_" + (itemType as string)) metalMtl
)
```

### 2. Порядок загрузки

`src/FurnGen.ms` — после `materials.ms`, до `ui.ms`:

```maxscript
local modules = #(
    "core.ms",
    "geometry.ms",
    "materials.ms",
    "sofa.ms",
    "furniture.ms",
    "lighting.ms",
    "qa.ms",
    "ui.ms"
)
```

### 3. Диспетчер

`fgBuildItem` в `furniture.ms`:

```maxscript
#lighting: ( result = fgBuildLighting cfg itemType )
```

### 4. UI

Добавьте элемент в **три** массива, сохраняя порядок:

```maxscript
global FurnGen_Categories = #(#sofa, #bed, #chair, #table, #storage, #decor, #lighting)
global FurnGen_CatLabels  = #("Sofas", ..., "Decor", "Lighting")
-- и соответствующие записи в FurnGen_TypeKeys / FurnGen_TypeLabels
```

При необходимости обновите `syncEnabled`, чтобы неприменимые параметры
обивки блокировались для новой категории.

---

## Новый стиль

`src/modules/core.ms`, функция `fgApplyStyle`:

```maxscript
#industrial:
(
    cfg.armStyle = #square
    cfg.legStyle = #block
    cfg.seatHeight = 42.0
    cfg.cushionSoftness = 0.35
    cfg.fabricColor = fgPick #(color 78 74 70, color 96 90 84)
    cfg.legColor = color 60 58 56
)
```

Затем зарегистрируйте ключ и подпись в `ui.ms`:

```maxscript
global FurnGen_StyleKeys = #(..., #midcentury, #industrial)
-- и в dropdownlist ddStyle
```

---

## Новая ткань

`src/modules/materials.ms`, функция `fgFabricParams` возвращает
`#(roughness, sheenAmount, bumpSize, bumpStrength, useCellular)`:

```maxscript
#tweed: #(0.85, 0.05, 1.6, 0.5, false)
```

Добавьте ключ в `FurnGen_FabricKeys` и подпись в `ddFabric` внутри `ui.ms`.

---

## Перед отправкой изменений

```bash
pnpm lint       # структура MAXScript и разрешение зависимостей
pnpm package    # сборка релизного архива
```

Проверьте в 3ds Max:

- новый предмет строится во всех трёх уровнях качества
- автопроверка не выдаёт предупреждений
- материалы видны без Corona (переключите рендер на Scanline)
- один и тот же `Seed` даёт идентичный результат
