/*
    SofaGen_Materials.ms  (v2.1.1 — пуленепробиваемые материалы)
    -------------------------------------------------------------
    Трёхступенчатая система, гарантирующая видимый материал ВСЕГДА:

      1. CoronaPhysicalMtl / CoronaMtl — только если Corona установлена
         И является АКТИВНЫМ рендером (иначе Corona-материалы серые/чёрные).
      2. PhysicalMaterial — для Scanline/Arnold/ART.
      3. StandardMaterial (diffuse) — если цвет не удалось записать
         ни в одно свойство: diffuse работает в любом Max с 1998 года.

    После установки цвета выполняется ВЕРИФИКАЦИЯ (чтение обратно).
    Если цвет не записался — материал заменяется на Standard, а в
    Listener пишется предупреждение "FurnGen MTL WARN".
*/

-------------------------------------------------------------------
-- Определение доступного рендер-стека
-------------------------------------------------------------------
fn sgCoronaAvailable = ( (classof CoronaPhysicalMtl == material) or (classof CoronaMtl == material) )

fn sgRendererIsCorona =
(
    matchPattern ((classof renderers.current) as string) pattern:"*Corona*"
)

-- Использовать Corona-материалы только когда Corona реально рендерит сцену
fn sgUseCorona = ( sgCoronaAvailable() and sgRendererIsCorona() )

-------------------------------------------------------------------
-- Верифицированная установка цвета: пишем и ЧИТАЕМ ОБРАТНО
-------------------------------------------------------------------
fn sgVerifiedSetColor m propNames col =
(
    for p in propNames do
    (
        if (sgTrySet m p col) then
        (
            local back = undefined
            try ( back = getProperty m p ) catch()
            if back != undefined then return true
        )
    )
    false
)

-------------------------------------------------------------------
-- ЕДИНАЯ ФАБРИКА PBR-материала (все материалы системы идут через неё)
-------------------------------------------------------------------
fn sgMakePBR col rough mtlName metalAmt:0.0 sheenAmt:0.0 bumpTex:undefined bumpAmt:0.0 =
(
    local m = undefined
    local colorOK = false

    if sgUseCorona() then
    (
        m = CoronaPhysicalMtl()
        m.name = mtlName
        colorOK = sgVerifiedSetColor m #(#baseColor, #colorBase, #baseColour, #diffuse) col
        sgSetFirst m #(#baseRoughness, #roughness, #roughnessMode) rough
        if metalAmt > 0.0 then sgSetFirst m #(#metalnessMode, #metalness, #metalnessAmount) 1
        if sheenAmt > 0.0 then
        (
            sgSetFirst m #(#sheenAmount, #sheen) sheenAmt
            sgSetFirst m #(#sheenRoughness) 0.5
        )
        if bumpTex != undefined then
        (
            sgSetFirst m #(#baseBumpTexmap, #texmapBump, #bumpTexmap) bumpTex
            sgSetFirst m #(#baseBumpMapAmount, #bumpAmount, #bumpMapAmount) bumpAmt
        )
    )
    else
    (
        m = PhysicalMaterial()
        m.name = mtlName
        colorOK = sgVerifiedSetColor m #(#base_color, #baseColor, #Base_Color) col
        sgSetFirst m #(#roughness) rough
        if metalAmt > 0.0 then sgSetFirst m #(#metalness) metalAmt
        if bumpTex != undefined then
        (
            sgSetFirst m #(#bump_map, #bumpMap) bumpTex
            sgSetFirst m #(#bump_map_amt, #bumpMapAmount) bumpAmt
        )
    )

    -- СТРАХОВКА: цвет не записался вообще -> StandardMaterial.
    -- diffuse гарантированно работает и виден в любом вьюпорте/рендере.
    if not colorOK then
    (
        format "FurnGen MTL WARN: у '%' нет доступного свойства цвета, использую Standard\n" mtlName
        m = StandardMaterial name:(mtlName + "_Std") diffuse:col
        m.specularLevel = (1.0 - rough) * 60.0
        m.glossiness = (1.0 - rough) * 50.0
        if bumpTex != undefined then
        (
            m.bumpMap = bumpTex
            m.bumpMapAmount = (bumpAmt * 100.0) as integer
        )
    )

    -- показывать материал в затенённом вьюпорте
    try ( showTextureMap m true ) catch()
    m
)

-------------------------------------------------------------------
-- Параметры тканей: roughness, sheen, размер/сила bump-шума
-------------------------------------------------------------------
fn sgFabricParams fabricType =
(
    -- #(roughness, sheenAmount, bumpSize, bumpStrength, useCellular)
    case fabricType of
    (
        #velvet:  #(0.85, 1.0, 0.25, 0.15, false)
        #linen:   #(0.75, 0.25, 0.60, 0.35, false)
        #boucle:  #(0.80, 0.15, 1.40, 0.70, false)
        #cotton:  #(0.70, 0.20, 0.45, 0.25, false)
        #leather: #(0.35, 0.00, 0.50, 0.30, true)
        default:  #(0.75, 0.20, 0.60, 0.35, false)
    )
)

-------------------------------------------------------------------
-- Bump-карта ткани
-------------------------------------------------------------------
fn sgFabricBumpMap fabricType prm =
(
    if prm[5] then
        Cellular size:prm[3] spread:0.4 fractal:true name:"SofaGen_LeatherGrain"
    else
        Noise type:2 size:prm[3] high:0.72 low:0.28 levels:6.0 name:"SofaGen_FabricWeave"
)

-------------------------------------------------------------------
-- Материал ткани
-------------------------------------------------------------------
fn sgMakeFabricMtl cfg =
(
    local prm = sgFabricParams cfg.fabric
    local bumpTex = sgFabricBumpMap cfg.fabric prm
    local mtlName = "SofaGen_" + (cfg.fabric as string) + "_Fabric"
    sgMakePBR cfg.fabricColor prm[1] mtlName sheenAmt:prm[2] bumpTex:bumpTex bumpAmt:prm[4]
)

-------------------------------------------------------------------
-- Материал ножек (дерево / металл по стилю)
-------------------------------------------------------------------
fn sgMakeLegMtl cfg =
(
    local isMetal = (cfg.style == #luxury or cfg.style == #modern or cfg.style == #brutalism)
    if isMetal then
        sgMakePBR cfg.legColor 0.25 "SofaGen_Legs" metalAmt:1.0
    else
    (
        local woodTex = Noise type:2 size:8.0 high:0.7 low:0.4 name:"SofaGen_WoodGrain"
        sgMakePBR cfg.legColor 0.45 "SofaGen_Legs" bumpTex:woodTex bumpAmt:0.15
    )
)

-------------------------------------------------------------------
-- Материал канта — та же ткань, чуть темнее (читается как шов)
-------------------------------------------------------------------
fn sgMakePipingMtl cfg fabricMtl =
(
    local prm = sgFabricParams cfg.fabric
    local darker = color (cfg.fabricColor.r * 0.75) (cfg.fabricColor.g * 0.75) (cfg.fabricColor.b * 0.75)
    sgMakePBR darker prm[1] "SofaGen_Piping" sheenAmt:prm[2]
)

-------------------------------------------------------------------
-- Дерево (столешницы, каркасы, полки)
-------------------------------------------------------------------
fn sgMakeWoodMtl woodColor mtlName:"FurnGen_Wood" =
(
    local grainTex = Noise type:2 size:14.0 high:0.68 low:0.38 name:"FurnGen_WoodGrain"
    sgMakePBR woodColor 0.38 mtlName bumpTex:grainTex bumpAmt:0.12
)

-------------------------------------------------------------------
-- Металл (каркасы, ножки, лампы, латунь)
-------------------------------------------------------------------
fn sgMakeMetalMtl mColor rough mtlName:"FurnGen_Metal" =
(
    sgMakePBR mColor rough mtlName metalAmt:1.0
)

-------------------------------------------------------------------
-- Постельное бельё (матрас / одеяло / наволочки) — мягкий хлопок
-------------------------------------------------------------------
fn sgMakeBeddingMtl beddingColor mtlName:"FurnGen_Bedding" =
(
    local weaveTex = Noise type:2 size:0.5 high:0.7 low:0.3 levels:6.0 name:"FurnGen_CottonWeave"
    sgMakePBR beddingColor 0.78 mtlName sheenAmt:0.25 bumpTex:weaveTex bumpAmt:0.22
)

-------------------------------------------------------------------
-- Простой цветной матовый материал (книги, абажуры, декор)
-------------------------------------------------------------------
fn sgMakeFlatMtl flatColor rough mtlName:"FurnGen_Flat" =
(
    sgMakePBR flatColor rough mtlName
)

-------------------------------------------------------------------
-- Чтение видимого цвета материала (для wirecolor нод)
-------------------------------------------------------------------
fn sgMtlColor m fallbackCol =
(
    local names = #(#baseColor, #colorBase, #base_color, #diffuse)
    for p in names do
    (
        local v = undefined
        try ( v = getProperty m p ) catch()
        if v != undefined and classof v == color then return v
    )
    fallbackCol
)

format "SofaGen Materials loaded (Corona available: %, Corona active: %)\n" (sgCoronaAvailable()) (sgRendererIsCorona())
