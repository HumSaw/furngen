/*
    SofaGen_Materials.ms
    --------------------
    Автоматическое создание материалов для Corona Renderer
    с fallback на PhysicalMaterial, если Corona не установлена.

    Все свойства ставятся защищённо (sgSetFirst), т.к. имена
    параметров CoronaPhysicalMtl отличаются между версиями Corona.
*/

fn sgCoronaAvailable = ( CoronaPhysicalMtl != undefined )

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
    local m

    if sgCoronaAvailable() then
    (
        m = CoronaPhysicalMtl()
        m.name = mtlName
        sgSetFirst m #(#baseColor, #colorBase, #baseColour) cfg.fabricColor
        sgSetFirst m #(#baseRoughness, #roughness) prm[1]
        -- velvet/ткань: sheen даёт характерный светлый ворс на гранях
        sgSetFirst m #(#sheenAmount, #sheen) prm[2]
        sgSetFirst m #(#sheenRoughness) 0.5
        sgSetFirst m #(#baseBumpTexmap, #texmapBump, #bumpTexmap) bumpTex
        sgSetFirst m #(#baseBumpMapAmount, #bumpAmount) prm[4]
        -- лёгкая транслюцентность для тонких тканей
        if cfg.fabric != #leather then
            sgSetFirst m #(#translucencyFraction, #translucencyAmount) 0.03
    )
    else
    (
        m = PhysicalMaterial()
        m.name = mtlName + "_Fallback"
        sgSetFirst m #(#base_color, #baseColor) cfg.fabricColor
        sgSetFirst m #(#roughness) prm[1]
        sgSetFirst m #(#bump_map, #bumpMap) bumpTex
        sgSetFirst m #(#bump_map_amt, #bumpMapAmount) prm[4]
    )
    m
)

-------------------------------------------------------------------
-- Материал ножек (дерево / металл / латунь по цвету из стиля)
-------------------------------------------------------------------
fn sgMakeLegMtl cfg =
(
    local isMetal = (cfg.style == #luxury or cfg.style == #modern or cfg.style == #brutalism)
    local m
    if sgCoronaAvailable() then
    (
        m = CoronaPhysicalMtl()
        m.name = "SofaGen_Legs"
        sgSetFirst m #(#baseColor, #colorBase) cfg.legColor
        if isMetal then
        (
            sgSetFirst m #(#metalnessMode, #metalness) 1
            sgSetFirst m #(#baseRoughness, #roughness) 0.25
        )
        else
        (
            sgSetFirst m #(#baseRoughness, #roughness) 0.45
            local woodTex = Noise type:2 size:8.0 high:0.7 low:0.4 name:"SofaGen_WoodGrain"
            sgSetFirst m #(#baseBumpTexmap, #texmapBump) woodTex
            sgSetFirst m #(#baseBumpMapAmount, #bumpAmount) 0.15
        )
    )
    else
    (
        m = PhysicalMaterial()
        m.name = "SofaGen_Legs_Fallback"
        sgSetFirst m #(#base_color) cfg.legColor
        sgSetFirst m #(#roughness) (if isMetal then 0.25 else 0.45)
        if isMetal then sgSetFirst m #(#metalness) 1.0
    )
    m
)

-------------------------------------------------------------------
-- Материал канта — та же ткань, чуть темнее (визуально читается шов)
-------------------------------------------------------------------
fn sgMakePipingMtl cfg fabricMtl =
(
    local m = copy fabricMtl
    m.name = "SofaGen_Piping"
    local darker = color (cfg.fabricColor.r * 0.75) (cfg.fabricColor.g * 0.75) (cfg.fabricColor.b * 0.75)
    sgSetFirst m #(#baseColor, #colorBase, #base_color) darker
    m
)
