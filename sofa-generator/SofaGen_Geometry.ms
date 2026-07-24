/*
    SofaGen_Geometry.ms
    -------------------
    Построители частей: мягкие блоки, подушки, подлокотники, ножки, кант.

    Пайплайн реализма:
        ChamferBox (базовая форма с большим fillet)
        -> Push        (надувание вдоль нормалей — "наполнитель")
        -> Noise       (фрактальные складки и неровности ткани)
        -> TurboSmooth (subdivision для мягких краёв)
    Уникальность каждой генерации — сидированный jitter позиций,
    размеров и seed каждого Noise-модификатора.
*/

-------------------------------------------------------------------
-- Настройки качества -> сегментация / subdivision
-------------------------------------------------------------------
fn sgQualitySegs quality =
(
    case quality of
    (
        1: #(3, 2, 2, 1)   -- segs, filletSegs, hSegs, turboIters
        2: #(5, 3, 2, 2)
        3: #(8, 4, 3, 3)
        default: #(5, 3, 2, 2)
    )
)

-------------------------------------------------------------------
-- Универсальная установка сегментов ChamferBox (имена свойств
-- отличаются между версиями Max — ставим защищённо)
-------------------------------------------------------------------
fn sgSetChamferSegs cb segs fsegs hsegs =
(
    sgSetFirst cb #(#lsegs, #Length_Segments, #lengthsegs) segs
    sgSetFirst cb #(#wsegs, #Width_Segments, #widthsegs) segs
    sgSetFirst cb #(#hsegs, #Height_Segments, #heightsegs) hsegs
    sgSetFirst cb #(#fsegs, #Fillet_Segments, #filletsegs) fsegs
)

-------------------------------------------------------------------
-- Мягкий блок (каркас, спинка, база) — скруглённый, слегка сглаженный
-------------------------------------------------------------------
fn sgSoftBlock w d h fillet cfg partName softness:0.25 =
(
    local q = sgQualitySegs cfg.quality
    -- защита: fillet не может превышать ~45% наименьшего измерения,
    -- иначе ChamferBox даёт рваную вывернутую геометрию
    local maxFillet = (amin (amin w d) h) * 0.45
    if fillet > maxFillet then fillet = maxFillet
    local b = ChamferBox width:w length:d height:h fillet:fillet name:partName
    sgSetChamferSegs b q[1] q[2] q[3]

    -- лёгкое надувание + микро-шум, чтобы убрать "пластиковость"
    if softness > 0.01 then
    (
        addModifier b (Push Push_Value:(h * 0.02 * softness))
        addModifier b (Noisemodifier scale:(h * 1.2) fractal:true \
            strength:[w * 0.006 * softness, d * 0.006 * softness, h * 0.012 * softness] \
            seed:(sgRandI 1 99999))
    )
    addModifier b (TurboSmooth iterations:q[4])
    addModifier b (Uvwmap maptype:4 width:60 length:60 height:60)
    b
)

-------------------------------------------------------------------
-- Подушка сиденья / спинки — главная "мягкая" деталь
-------------------------------------------------------------------
fn sgCushion w d h cfg partName isBack:false =
(
    local q = sgQualitySegs cfg.quality
    local soft = cfg.cushionSoftness
    local fillet = h * (0.26 + soft * 0.10)
    -- защита от рваной геометрии: fillet <= 45% наименьшего измерения
    local maxFillet = (amin (amin w d) h) * 0.45
    if fillet > maxFillet then fillet = maxFillet

    local c = ChamferBox width:w length:d height:h fillet:fillet name:partName
    sgSetChamferSegs c (q[1] + 2) q[2] q[3]

    -- 1. Надувание — эффект наполнителя, распирающего чехол
    addModifier c (Push Push_Value:(h * (0.05 + soft * 0.07)))

    -- 2. Крупные складки — естественное провисание ткани
    addModifier c (Noisemodifier scale:(h * 1.4) fractal:true \
        strength:[w * 0.010 * soft, d * 0.014 * soft, h * 0.05 * soft] \
        seed:(sgRandI 1 99999))

    -- 3. Мелкие морщины (только для production/close-up качества)
    if cfg.quality >= 2 then
        addModifier c (Noisemodifier scale:(h * 0.35) fractal:true \
            strength:[h * 0.008 * soft, h * 0.008 * soft, h * 0.015 * soft] \
            seed:(sgRandI 1 99999))

    -- 4. Subdivision
    addModifier c (TurboSmooth iterations:q[4])
    addModifier c (Uvwmap maptype:4 width:50 length:50 height:50)

    -- органическая неидеальность: лёгкий наклон каждой подушки
    rotate c (eulerangles (sgJitter 0.0 0.7) (sgJitter 0.0 0.7) (sgJitter 0.0 1.0))
    c
)

-------------------------------------------------------------------
-- Кант (piping) — renderable-сплайн по периметру подушки
-------------------------------------------------------------------
fn sgPiping w d cornerR pipeR partName =
(
    local r = Rectangle width:(w * 0.985) length:(d * 0.985) cornerRadius:cornerR name:partName
    -- защищённая установка renderable-свойств (имена меняются между версиями)
    sgSetFirst r #(#render_renderable, #renderable) true
    sgSetFirst r #(#render_displayRenderMesh, #displayRenderMesh) true
    sgSetFirst r #(#render_thickness, #thickness) (pipeR * 2)
    sgSetFirst r #(#render_sides, #sides) 12
    r
)

-------------------------------------------------------------------
-- Подлокотник — три формы
-------------------------------------------------------------------
fn sgArm cfg sideSign partName =
(
    -- sideSign: -1 левый, +1 правый
    local w = cfg.armWidth
    local d = cfg.depth
    local h = cfg.armHeight - cfg.legHeight
    local arm

    case cfg.armStyle of
    (
        #rounded:
        (
            arm = sgSoftBlock w d h (w * 0.42) cfg partName softness:0.5
        )
        #square:
        (
            arm = sgSoftBlock w d h (w * 0.14) cfg partName softness:0.2
        )
        #pillow:
        (
            -- низкий каркас + мягкий валик сверху (mid-century)
            arm = sgSoftBlock w d (h * 0.7) (w * 0.15) cfg partName softness:0.25
            local roll = sgCushion (w * 1.1) d (h * 0.42) cfg (partName + "_Roll")
            roll.pos = [0, 0, h * 0.66]
            roll.parent = arm
        )
        default: ( arm = sgSoftBlock w d h (w * 0.3) cfg partName softness:0.3 )
    )
    arm
)

-------------------------------------------------------------------
-- Ножка
-------------------------------------------------------------------
fn sgLeg cfg partName =
(
    local h = cfg.legHeight
    local leg
    case cfg.legStyle of
    (
        #cylinder: ( leg = Cylinder radius:2.2 height:h sides:18 name:partName )
        #cone:     ( leg = Cone radius1:2.8 radius2:1.3 height:h sides:18 name:partName )
        #block:    ( leg = Box width:6 length:6 height:h name:partName )
        #none:     ( leg = Box width:8 length:8 height:(amax h 1.5) name:partName )
        default:   ( leg = Cylinder radius:2.2 height:h sides:18 name:partName )
    )
    leg
)
