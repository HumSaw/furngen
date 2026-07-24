/*
    SofaGen_Core.ms
    ---------------
    Ядро системы: конфигурация, RNG, утилиты, стилевые пресеты.
    Часть системы SofaGen — расширяемого генератора процедурной мебели
    для 3ds Max + Corona Renderer.

    Единицы: сантиметры (рекомендуется System Units = cm).
*/

global SofaGen_Version = "1.0.0"

-------------------------------------------------------------------
-- УТИЛИТЫ
-------------------------------------------------------------------

-- Безопасная установка свойства (разные версии Max/Corona имеют разные имена свойств)
fn sgTrySet obj propName val =
(
    local ok = false
    try ( setProperty obj propName val; ok = true ) catch ( ok = false )
    ok
)

-- Установка первого подходящего свойства из списка кандидатов
fn sgSetFirst obj propNames val =
(
    for p in propNames do ( if (sgTrySet obj p val) then return true )
    false
)

-- Сидированный рандом
fn sgSetSeed s = ( seed s )
fn sgRandF a b = ( random (a as float) (b as float) )
fn sgRandI a b = ( random (a as integer) (b as integer) )
fn sgJitter v amt = ( v + (random (-amt) amt) )   -- органическая асимметрия
fn sgPick arr = ( arr[random 1 arr.count] )

-- Слой сцены для аккуратной структуры
fn sgGetLayer layerName =
(
    local l = LayerManager.getLayerFromName layerName
    if l == undefined then l = LayerManager.newLayerFromName layerName
    l
)

-------------------------------------------------------------------
-- КОНФИГУРАЦИЯ ГЕНЕРАТОРА
-------------------------------------------------------------------

struct SofaConfig
(
    -- Тип: #straight #corner #modular #loveseat #chaise #armchair
    sofaType = #straight,
    seats = 3,

    -- Стиль: #modern #minimal #scandinavian #japandi #luxury #classic #brutalism #midcentury
    style = #modern,

    -- Ткань: #boucle #velvet #linen #cotton #leather
    fabric = #boucle,

    -- Габариты (см)
    width = 240.0,
    depth = 100.0,
    height = 82.0,
    seatHeight = 42.0,

    -- Подлокотники: #rounded #square #pillow
    armStyle = #rounded,
    armWidth = 22.0,
    armHeight = 60.0,

    -- Ножки: #cylinder #cone #block #none
    legStyle = #cylinder,
    legHeight = 12.0,

    -- Подушки
    cushionSoftness = 0.5,   -- 0..1 : степень "надутости" и складок
    cushionHeight = 16.0,
    backCushions = true,
    piping = true,

    -- Качество: 1 = Draft, 2 = Production, 3 = Close-up 4K
    quality = 2,

    seed = 12345,

    -- Цветовая палитра (заполняется стилем)
    fabricColor = color 200 190 175,
    legColor = color 60 45 35
)

-------------------------------------------------------------------
-- СТИЛЕВЫЕ ПРЕСЕТЫ
-- Каждый стиль задаёт пропорции, форму подлокотников, ножки и палитру.
-------------------------------------------------------------------

fn sgApplyStyle cfg styleName =
(
    cfg.style = styleName
    case styleName of
    (
        #modern:
        (
            cfg.armStyle = #square; cfg.legStyle = #block
            cfg.legHeight = 8.0; cfg.armWidth = 20.0; cfg.armHeight = 58.0
            cfg.fabricColor = sgPick #(color 82 86 92, color 168 160 148, color 60 62 66)
            cfg.legColor = color 30 30 30
        )
        #minimal:
        (
            cfg.armStyle = #square; cfg.legStyle = #none
            cfg.legHeight = 4.0; cfg.armWidth = 14.0; cfg.armHeight = 52.0
            cfg.piping = false
            cfg.fabricColor = sgPick #(color 235 232 226, color 210 205 196, color 190 188 184)
            cfg.legColor = color 40 40 40
        )
        #scandinavian:
        (
            cfg.armStyle = #rounded; cfg.legStyle = #cone
            cfg.legHeight = 16.0; cfg.armWidth = 18.0; cfg.armHeight = 56.0
            cfg.fabricColor = sgPick #(color 214 208 196, color 158 170 160, color 226 220 208)
            cfg.legColor = color 172 132 88   -- светлый дуб
        )
        #japandi:
        (
            cfg.armStyle = #square; cfg.legStyle = #block
            cfg.legHeight = 10.0; cfg.armWidth = 16.0; cfg.armHeight = 50.0
            cfg.height = 74.0
            cfg.fabricColor = sgPick #(color 196 186 168, color 150 140 124, color 120 116 108)
            cfg.legColor = color 70 52 38
        )
        #luxury:
        (
            cfg.armStyle = #rounded; cfg.legStyle = #cylinder
            cfg.legHeight = 10.0; cfg.armWidth = 26.0; cfg.armHeight = 62.0
            cfg.fabric = #velvet; cfg.piping = true
            cfg.fabricColor = sgPick #(color 34 60 54, color 94 66 44, color 44 48 74)
            cfg.legColor = color 190 160 100  -- латунь
        )
        #classic:
        (
            cfg.armStyle = #rounded; cfg.legStyle = #cone
            cfg.legHeight = 12.0; cfg.armWidth = 28.0; cfg.armHeight = 64.0
            cfg.piping = true
            cfg.fabricColor = sgPick #(color 120 96 72, color 96 104 92, color 140 120 96)
            cfg.legColor = color 56 38 26
        )
        #brutalism:
        (
            cfg.armStyle = #square; cfg.legStyle = #none
            cfg.legHeight = 2.0; cfg.armWidth = 30.0; cfg.armHeight = 55.0
            cfg.piping = false; cfg.cushionSoftness = 0.35
            cfg.fabricColor = sgPick #(color 110 110 108, color 88 84 80, color 130 126 120)
            cfg.legColor = color 90 90 90
        )
        #midcentury:
        (
            cfg.armStyle = #pillow; cfg.legStyle = #cone
            cfg.legHeight = 18.0; cfg.armWidth = 18.0; cfg.armHeight = 54.0
            cfg.fabricColor = sgPick #(color 190 120 60, color 96 118 108, color 180 150 100)
            cfg.legColor = color 110 74 46    -- орех
        )
    )
    cfg
)

-- Применение типа дивана к габаритам
fn sgApplyType cfg typeName =
(
    cfg.sofaType = typeName
    case typeName of
    (
        #straight:  ( if cfg.seats < 2 then cfg.seats = 3 )
        #loveseat:  ( cfg.seats = 2; cfg.width = 170.0 )
        #armchair:  ( cfg.seats = 1; cfg.width = 100.0 )
        #chaise:    ( if cfg.seats < 3 then cfg.seats = 3 )
        #corner:    ( if cfg.seats < 3 then cfg.seats = 3 )
        #modular:   ( if cfg.seats < 3 then cfg.seats = 4 )
    )
    -- ширина от количества мест (если пользователь не задал явно)
    if typeName != #loveseat and typeName != #armchair then
        cfg.width = amax cfg.width (cfg.seats * 65.0 + cfg.armWidth * 2)
    cfg
)

format "SofaGen Core % loaded\n" SofaGen_Version
