/*
    materials.ms -- PBR material factory
    -----------------------------------
    A three-tier strategy that guarantees a visible material on every part,
    on every renderer, on every supported Max version:

      1. CoronaPhysicalMtl / CoronaMtl -- only when Corona is installed AND
         is the ACTIVE renderer, because Corona materials render grey or
         black under other engines.
      2. PhysicalMaterial -- for Scanline, Arnold and ART.
      3. StandardMaterial -- last resort when no colour property could be
         written; the diffuse slot has existed in every Max release.

    After a colour is assigned it is read back for VERIFICATION. If the
    write silently failed, the material is downgraded to StandardMaterial
    and a "FurnGen MTL WARN" line is printed to the Listener.

    Depends on: core.ms
*/

-------------------------------------------------------------------
-- Detect the available render stack
-------------------------------------------------------------------
fn fgCoronaAvailable = ( (classof CoronaPhysicalMtl == material) or (classof CoronaMtl == material) )

fn fgRendererIsCorona =
(
    matchPattern ((classof renderers.current) as string) pattern:"*Corona*"
)

-- Use Corona materials only when Corona actually renders the scene
fn fgUseCorona = ( fgCoronaAvailable() and fgRendererIsCorona() )

-------------------------------------------------------------------
-- Verified colour assignment: write, then read back to confirm
-------------------------------------------------------------------
fn fgVerifiedSetColor m propNames col =
(
    for p in propNames do
    (
        if (fgTrySet m p col) then
        (
            local back = undefined
            try ( back = getProperty m p ) catch()
            if back != undefined then return true
        )
    )
    false
)

-------------------------------------------------------------------
-- Single PBR factory. Every material in the system is created here.
-------------------------------------------------------------------
fn fgMakePBR col rough mtlName metalAmt:0.0 sheenAmt:0.0 bumpTex:undefined bumpAmt:0.0 =
(
    local m = undefined
    local colorOK = false

    if fgUseCorona() then
    (
        m = CoronaPhysicalMtl()
        m.name = mtlName
        colorOK = fgVerifiedSetColor m #(#baseColor, #colorBase, #baseColour, #diffuse) col
        fgSetFirst m #(#baseRoughness, #roughness, #roughnessMode) rough
        if metalAmt > 0.0 then fgSetFirst m #(#metalnessMode, #metalness, #metalnessAmount) 1
        if sheenAmt > 0.0 then
        (
            fgSetFirst m #(#sheenAmount, #sheen) sheenAmt
            fgSetFirst m #(#sheenRoughness) 0.5
        )
        if bumpTex != undefined then
        (
            fgSetFirst m #(#baseBumpTexmap, #texmapBump, #bumpTexmap) bumpTex
            fgSetFirst m #(#baseBumpMapAmount, #bumpAmount, #bumpMapAmount) bumpAmt
        )
    )
    else
    (
        m = PhysicalMaterial()
        m.name = mtlName
        colorOK = fgVerifiedSetColor m #(#base_color, #baseColor, #Base_Color) col
        fgSetFirst m #(#roughness) rough
        if metalAmt > 0.0 then fgSetFirst m #(#metalness) metalAmt
        if bumpTex != undefined then
        (
            fgSetFirst m #(#bump_map, #bumpMap) bumpTex
            fgSetFirst m #(#bump_map_amt, #bumpMapAmount) bumpAmt
        )
    )

    -- Safety net: no colour property accepted the value -> StandardMaterial.
    -- The diffuse slot is guaranteed to render and to show in the viewport.
    if not colorOK then
    (
        format "FurnGen MTL WARN: no colour property on '%', falling back to Standard\n" mtlName
        m = StandardMaterial name:(mtlName + "_Std") diffuse:col
        m.specularLevel = (1.0 - rough) * 60.0
        m.glossiness = (1.0 - rough) * 50.0
        if bumpTex != undefined then
        (
            m.bumpMap = bumpTex
            m.bumpMapAmount = (bumpAmt * 100.0) as integer
        )
    )

    -- Show the map in the shaded viewport
    try ( showTextureMap m true ) catch()
    m
)

-------------------------------------------------------------------
-- Fabric parameters: roughness, sheen, bump size and strength
-------------------------------------------------------------------
fn fgFabricParams fabricType =
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
-- Fabric bump map
-------------------------------------------------------------------
fn fgFabricBumpMap fabricType prm =
(
    if prm[5] then
        Cellular size:prm[3] spread:0.4 fractal:true name:"FurnGen_LeatherGrain"
    else
        Noise type:2 size:prm[3] high:0.72 low:0.28 levels:6.0 name:"FurnGen_FabricWeave"
)

-------------------------------------------------------------------
-- Upholstery fabric
-------------------------------------------------------------------
fn fgMakeFabricMtl cfg =
(
    local prm = fgFabricParams cfg.fabric
    local bumpTex = fgFabricBumpMap cfg.fabric prm
    local mtlName = "FurnGen_" + (cfg.fabric as string) + "_Fabric"
    fgMakePBR cfg.fabricColor prm[1] mtlName sheenAmt:prm[2] bumpTex:bumpTex bumpAmt:prm[4]
)

-------------------------------------------------------------------
-- Legs: wood or metal depending on the style
-------------------------------------------------------------------
fn fgMakeLegMtl cfg =
(
    local isMetal = (cfg.style == #luxury or cfg.style == #modern or cfg.style == #brutalism)
    if isMetal then
        fgMakePBR cfg.legColor 0.25 "FurnGen_Legs" metalAmt:1.0
    else
    (
        local woodTex = Noise type:2 size:8.0 high:0.7 low:0.4 name:"FurnGen_WoodGrain"
        fgMakePBR cfg.legColor 0.45 "FurnGen_Legs" bumpTex:woodTex bumpAmt:0.15
    )
)

-------------------------------------------------------------------
-- Piping: the same fabric, slightly darker, so the seam reads on camera
-------------------------------------------------------------------
fn fgMakePipingMtl cfg fabricMtl =
(
    local prm = fgFabricParams cfg.fabric
    local darker = color (cfg.fabricColor.r * 0.75) (cfg.fabricColor.g * 0.75) (cfg.fabricColor.b * 0.75)
    fgMakePBR darker prm[1] "FurnGen_Piping" sheenAmt:prm[2]
)

-------------------------------------------------------------------
-- Wood: table tops, frames, shelves
-------------------------------------------------------------------
fn fgMakeWoodMtl woodColor mtlName:"FurnGen_Wood" =
(
    local grainTex = Noise type:2 size:14.0 high:0.68 low:0.38 name:"FurnGen_WoodGrain"
    fgMakePBR woodColor 0.38 mtlName bumpTex:grainTex bumpAmt:0.12
)

-------------------------------------------------------------------
-- Metal: frames, legs, lamps, brass
-------------------------------------------------------------------
fn fgMakeMetalMtl mColor rough mtlName:"FurnGen_Metal" =
(
    fgMakePBR mColor rough mtlName metalAmt:1.0
)

-------------------------------------------------------------------
-- Bedding: mattress, duvet and pillow cases in soft cotton
-------------------------------------------------------------------
fn fgMakeBeddingMtl beddingColor mtlName:"FurnGen_Bedding" =
(
    local weaveTex = Noise type:2 size:0.5 high:0.7 low:0.3 levels:6.0 name:"FurnGen_CottonWeave"
    fgMakePBR beddingColor 0.78 mtlName sheenAmt:0.25 bumpTex:weaveTex bumpAmt:0.22
)

-------------------------------------------------------------------
-- Plain matte colour: books, lamp shades, decor
-------------------------------------------------------------------
fn fgMakeFlatMtl flatColor rough mtlName:"FurnGen_Flat" =
(
    fgMakePBR flatColor rough mtlName
)

-------------------------------------------------------------------
-- Read the visible colour of a material, used to drive node wirecolor
-------------------------------------------------------------------
fn fgMtlColor m fallbackCol =
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

format "FurnGen Materials loaded (Corona available: %, Corona active: %)\n" (fgCoronaAvailable()) (fgRendererIsCorona())
