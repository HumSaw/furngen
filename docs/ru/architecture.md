# Архитектура

Устройство FurnGen: слои, порядок загрузки, конвейеры геометрии и материалов.

---

## Слои

MAXScript не имеет системы модулей, поэтому зависимости выстроены как
линейная цепочка: каждый файл использует только то, что загружено раньше.

```
FurnGen.ms                 точка входа: разрешение путей, загрузка, запуск UI
   │
   ├── modules/core.ms         конфиг, seeded RNG, утилиты, стили
   ├── modules/geometry.ms     мягкие блоки, подушки, подлокотники, ножки, кант
   ├── modules/materials.ms    фабрика PBR-материалов с тремя уровнями отката
   ├── modules/sofa.ms         сборка диванов
   ├── modules/furniture.ms    кровати, стулья, столы, хранение, декор, комнаты
   ├── modules/qa.ms           автопроверка результата
   └── modules/ui.ms           панель
```

Порядок загрузки объявлен в `FurnGen.ms` и является обязательным.

| Модуль | Зависит от |
| --- | --- |
| `core.ms` | — |
| `geometry.ms` | core |
| `materials.ms` | core |
| `sofa.ms` | core, geometry, materials |
| `furniture.ms` | core, geometry, materials |
| `qa.ms` | core |
| `ui.ms` | все предыдущие |

---

## Соглашения об именах

| Префикс | Значение |
| --- | --- |
| `fg…` | Функция (`fgCushion`, `fgMakePBR`, `fgBuildItem`) |
| `FurnGen_…` | Глобальная переменная (`FurnGen_Version`, `FurnGen_LastGroup`) |
| `FurnGenConfig` | Структура конфигурации |

---

## Система координат

```
        +Z  высота (пол = 0)
         │
         │
         └───── +X  ширина (центр = 0)
        ╱
      -Y  фронт предмета     (+Y = спинка)
```

Все размеры — в сантиметрах. Каждый предмет собирается вокруг мирового нуля,
и только затем перемещается на итоговую позицию: это упрощает вращение
секций и повторное использование сборок в комплектах комнат.

---

## Конфигурация

`FurnGenConfig` — единственный объект, который передаётся между слоями.
UI собирает его из состояния панели, стиль изменяет, сборщики читают.

```maxscript
struct FurnGenConfig
(
    sofaType = #straight,      -- #straight #corner #modular #loveseat #chaise #armchair
    seats = 3,

    style = #modern,           -- один из восьми стилей
    fabric = #boucle,          -- #boucle #velvet #linen #cotton #leather

    -- Габариты (см)
    width = 240.0,
    depth = 100.0,
    height = 82.0,
    seatHeight = 42.0,

    -- Подлокотники
    armStyle = #rounded,       -- #rounded #square #pillow
    armWidth = 22.0,
    armHeight = 60.0,

    -- Ножки
    legStyle = #cylinder,      -- #cylinder #cone #block #none
    legHeight = 12.0,

    -- Подушки
    cushionSoftness = 0.5,     -- 0..1
    cushionHeight = 16.0,
    backCushions = true,
    piping = true,
    sofaDecor = true,          -- плед и акцентные подушки

    quality = 2,               -- 1 Draft, 2 Production, 3 Close-up 4K
    seed = 12345,

    -- Палитра, заполняется стилевым пресетом
    fabricColor = color 200 190 175,
    legColor = color 60 45 35
)
```

Обратите внимание на имена `armStyle` и `legStyle` — не `armType` / `legType`.
`sofaType` относится к типу дивана целиком.

---

## Детерминированность

Уникальность моделей строится на управляемой случайности, а не на
непредсказуемой: `fgSetSeed` вызывается **до** применения стиля, поэтому
выбор оттенка из палитры тоже детерминирован.

```maxscript
fn fgSetSeed s = ( seed s )
fn fgRandF a b = ( random (a as float) (b as float) )
fn fgRandI a b = ( random (a as integer) (b as integer) )
fn fgJitter v amt = ( v + (random (-amt) amt) )   -- органическая асимметрия
fn fgPick arr = ( arr[random 1 arr.count] )
```

MAXScript использует один глобальный поток случайных чисел, поэтому все пять
помощников читают из него — и порядок вызовов имеет значение.

Следствие: одинаковый `Seed` при одинаковых параметрах всегда даёт
идентичную модель — вплоть до seed каждого модификатора Noise.

---

## Конвейер геометрии

Мягкость достигается последовательностью модификаторов, а не готовыми
моделями:

```
ChamferBox        базовая форма с крупным fillet
     ↓
Push              надувание вдоль нормалей — эффект наполнителя
     ↓
Noise (крупный)   естественное провисание ткани
     ↓
Noise (мелкий)    микроморщины (качество Production и Close-up)
     ↓
TurboSmooth       сглаживание силуэта
```

### Защита fillet

`ChamferBox` даёт вывернутую самопересекающуюся геометрию, если fillet
превышает половину наименьшего измерения. Ограничение стоит в самих
примитивах `fgSoftBlock` и `fgCushion`, поэтому защищены **все** предметы
системы сразу, а не каждый вызов по отдельности:

```maxscript
local maxFillet = (amin (amin w d) h) * 0.45
if fillet > maxFillet then fillet = maxFillet
```

### Сегментация по качеству

`fgQualitySegs` возвращает `#(segs, filletSegs, heightSegs, turboIterations)`.
Свойства сегментов `ChamferBox` переименовывались между версиями Max,
поэтому `fgSetChamferSegs` перебирает варианты имён, пока одно не примется.

---

## Конвейер материалов

Три уровня, гарантирующие видимый материал в любой конфигурации:

```
Corona установлена И активна?
        │да                     │нет
CoronaPhysicalMtl         PhysicalMaterial
        └───────────┬───────────┘
                    ↓
        Верификация: записать цвет и прочитать обратно
                    │
         записался? │ нет → StandardMaterial (diffuse)
                    │        + предупреждение в Listener
                    ↓
              готовый материал
```

Ключевая деталь: проверяется не наличие плагина Corona, а **активный
рендер**. Corona-материалы под чужим движком выглядят серыми, поэтому
одного `isKindOf` недостаточно.

Все материалы системы создаются единственной функцией `fgMakePBR`, а
специализированные обёртки лишь подбирают параметры:

| Функция | Назначение |
| --- | --- |
| `fgMakeFabricMtl` | Обивка по выбранной ткани |
| `fgMakeWoodMtl` | Дерево с картой волокна |
| `fgMakeMetalMtl` | Металл и латунь |
| `fgMakeBeddingMtl` | Постельное бельё |
| `fgMakeFlatMtl` | Матовый цвет: книги, абажуры, декор |
| `fgMakePipingMtl` | Кант — та же ткань темнее |

Дополнительно `wirecolor` каждой ноды берётся из цвета материала, поэтому
модель читается даже в режиме вьюпорта Object Color.

---

## Диспетчер

`fgBuildItem cfg category itemType` — единственная точка входа для UI.
Панель не знает, какой модуль отвечает за какую категорию.

```maxscript
case category of
(
    #sofa:    ( cfg = fgApplyType cfg itemType; result = fgBuildSofa cfg )
    #bed:     ( result = fgBuildBed cfg itemType )
    #chair:   ( result = fgBuildChair cfg itemType )
    #table:   ( result = fgBuildTable cfg itemType )
    #storage: ( result = fgBuildStorage cfg itemType )
    #decor:   ( result = fgBuildDecor cfg itemType )
)
```

---

## Автопроверка

`fgValidateItem` обходит иерархию группы рекурсивно (`fgCollectParts`),
включая дочерние ноды вроде валика подлокотника, и проверяет:

- системные единицы сцены равны сантиметрам
- габариты попадают в разумный диапазон: 20–650 см по ширине и 1–260 см
  по высоте — от приставного столика до кровати с балдахином или комнаты
- у каждой детали есть материал
- меш не пустой (ненулевое число вершин и полигонов)
- не осталось служебных имён вида `Box001` или `ChamferBox001`

Результат — **массив строк**, и сводка всегда стоит последней. Именно поэтому
панель читает `report[report.count]` для строки состояния, а весь массив
печатается в Listener:

```
OK: 34 parts / 118240 tris, render ready
CHECKED: 34 parts / 118240 tris, 2 issue(s) - see Listener
```

Проверка никогда не отменяет генерацию — она только сообщает, на что взглянуть.

---

## Обработка ошибок

Генерация обёрнута в `try … catch`. При сбое вызывается `max undo`,
частично созданная геометрия откатывается, а текст исключения выводится
и в панель, и в Listener. Сцена никогда не остаётся с полусобранным
предметом без материалов.
