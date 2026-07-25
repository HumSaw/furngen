/*
    ui.ms -- generator panel
    -----------------------
    Category -> type -> style -> fabric, plus generation controls,
    one-click room sets and INI-backed presets.

    Depends on: core.ms, geometry.ms, materials.ms, sofa.ms, furniture.ms, qa.ms
*/

global FurnGenUI_Floater
global FurnGen_LastGroup

global FurnGen_DocsUrl = "https://github.com/OWNER/furngen#readme"

-- Categories and the item types available inside each one.
-- Index i of every *Keys / *Labels array refers to the same category.
global FurnGen_Categories = #(#sofa, #bed, #chair, #table, #storage, #decor)
global FurnGen_CatLabels  = #("Sofas", "Beds", "Chairs", "Tables", "Storage", "Decor")

global FurnGen_TypeKeys = #(
    #(#straight, #corner, #modular, #loveseat, #chaise, #armchair),
    #(#bedSingle, #bedDouble, #bedKing, #bedCanopy),
    #(#chairDining, #chairBar, #chairLounge, #stool),
    #(#tableDining, #tableCoffee, #tableSide, #tableDesk, #tableNightstand),
    #(#wardrobe, #dresser),
    #(#pouf, #rug, #floorLamp, #bookshelf, #tvConsole, #plant, #mirror)
)
global FurnGen_TypeLabels = #(
    #("Straight", "Corner / L-shape", "Modular", "Loveseat", "Chaise lounge", "Armchair"),
    #("Single", "Double", "King size", "Canopy"),
    #("Dining chair", "Bar stool", "Lounge chair", "Stool"),
    #("Dining table", "Coffee table", "Side table", "Desk", "Nightstand"),
    #("Wardrobe", "Dresser"),
    #("Pouf", "Rug", "Floor lamp", "Bookshelf", "TV console", "Plant", "Mirror")
)

global FurnGen_StyleKeys  = #(#modern, #minimal, #scandinavian, #japandi, #luxury, #classic, #brutalism, #midcentury)
global FurnGen_FabricKeys = #(#boucle, #velvet, #linen, #cotton, #leather)

fn fgPresetFile = ( (getDir #userScripts) + "\\FurnGen_Presets.ini" )

rollout FurnGenRollout "FurnGen - Procedural Furniture Generator" width:300
(
    group "What to build"
    (
        dropdownlist ddCategory "Category:" items:FurnGen_CatLabels selection:1
        dropdownlist ddType "Type:" items:FurnGen_TypeLabels[1] selection:1
        dropdownlist ddStyle "Style:" items:#("Modern", "Minimal", "Scandinavian", "Japandi", \
            "Luxury", "Classic", "Brutalism", "Mid-century") selection:1
        dropdownlist ddFabric "Fabric:" items:#("Boucle", "Velvet", "Linen", "Cotton", "Leather") selection:1
    )
    group "Dimensions (cm)"
    (
        spinner spSeats "Seats:" range:[1, 6, 3] type:#integer fieldwidth:50
        spinner spWidth "Width:" range:[40, 500, 240] fieldwidth:60
        spinner spDepth "Depth:" range:[30, 220, 100] fieldwidth:60
        spinner spHeight "Height:" range:[30, 250, 82] fieldwidth:60
    )
    group "Upholstery"
    (
        spinner spSoft "Softness:" range:[0.0, 1.0, 0.5] scale:0.05 fieldwidth:60
        checkbox cbPiping "Piping seams" checked:true
        checkbox cbBackCush "Back cushions" checked:true
        checkbox cbDecor "Styling (throw blanket + accent pillows)" checked:true
    )
    group "Generate"
    (
        dropdownlist ddQuality "Quality:" items:#("Draft", "Production", "Close-up 4K") selection:2
        spinner spSeed "Seed:" range:[1, 999999, 12345] type:#integer fieldwidth:70
        button btnGenerate "GENERATE" width:270 height:34
        button btnRandom "Randomize" width:132 height:26 across:2
        button btnRandomAll "Surprise me" width:132 height:26
        button btnRoomSet "BUILD LIVING ROOM" width:270 height:30
        button btnBedroom "BUILD BEDROOM" width:270 height:30
        button btnDelete "Delete last" width:270 height:22
    )
    group "Presets"
    (
        edittext etPreset "Name:" text:"MyFurniture"
        button btnSave "Save" width:132 across:2
        button btnLoad "Load" width:132
    )
    label lblStatus "Ready." align:#left
    hyperlink hlDocs "Documentation" address:FurnGen_DocsUrl color:(color 120 160 220) align:#left

    -- Upholstery controls only affect soft furniture; grey them out otherwise
    -- so the panel always communicates what a parameter actually does.
    fn syncEnabled =
    (
        local cat = FurnGen_Categories[ddCategory.selection]
        local soft = (cat == #sofa or cat == #bed or cat == #chair)
        spSeats.enabled = (cat == #sofa)
        spSoft.enabled = soft
        cbPiping.enabled = soft
        cbBackCush.enabled = (cat == #sofa)
        cbDecor.enabled = (cat == #sofa)
        spWidth.enabled = (cat == #sofa)
        spDepth.enabled = (cat == #sofa)
        spHeight.enabled = (cat == #sofa)
    )

    -- Collect a FurnGenConfig from the current panel state
    fn buildConfig =
    (
        local cfg = FurnGenConfig()
        cfg.seed = spSeed.value
        -- Seed before the style pass so palette picks are deterministic too
        fgSetSeed cfg.seed
        cfg = fgApplyStyle cfg FurnGen_StyleKeys[ddStyle.selection]
        cfg.seats = spSeats.value
        cfg.fabric = FurnGen_FabricKeys[ddFabric.selection]
        cfg.width = spWidth.value
        cfg.depth = spDepth.value
        cfg.height = spHeight.value
        cfg.cushionSoftness = spSoft.value
        cfg.piping = cbPiping.checked and cfg.piping
        cfg.backCushions = cbBackCush.checked
        cfg.sofaDecor = cbDecor.checked
        cfg.quality = ddQuality.selection
        cfg
    )

    -- Report a failure without leaving half-built geometry behind
    fn reportFailure =
    (
        max undo
        lblStatus.text = "Error: " + (getCurrentException())
        format "FurnGen ERROR: %\n" (getCurrentException())
    )

    fn doGenerate =
    (
        lblStatus.text = "Generating..."
        local cfg = buildConfig()
        local category = FurnGen_Categories[ddCategory.selection]
        local itemType = FurnGen_TypeKeys[ddCategory.selection][ddType.selection]
        if category == #sofa then cfg.width = amax cfg.width 80.0
        local grp = undefined
        try ( undo "FurnGen Generate" on ( grp = fgBuildItem cfg category itemType ) )
        catch ( reportFailure(); return() )
        FurnGen_LastGroup = grp
        local report = fgValidateItem grp
        lblStatus.text = report[report.count]
        if grp != undefined then ( select grp; max zoomext sel )
    )

    fn doBuildSet setKind =
    (
        local cfg = buildConfig()
        local grp = undefined
        try
        (
            undo "FurnGen Set" on
            (
                if setKind == #living then grp = fgBuildRoomSet cfg
                else grp = fgBuildBedroomSet cfg
            )
        )
        catch ( reportFailure(); return() )
        if grp != undefined then
        (
            FurnGen_LastGroup = grp
            lblStatus.text = "Done: " + grp.name
            select grp
            max zoomext sel
        )
    )

    -- Randomize every control except the category
    fn randomizeParams =
    (
        ddType.selection = random 1 FurnGen_TypeKeys[ddCategory.selection].count
        ddStyle.selection = random 1 FurnGen_StyleKeys.count
        ddFabric.selection = random 1 FurnGen_FabricKeys.count
        spSeats.value = random 2 4
        spWidth.value = random 160.0 300.0
        spDepth.value = random 90.0 115.0
        spSoft.value = random 0.3 0.8
        spSeed.value = random 1 999999
    )

    on FurnGenRollout open do syncEnabled()

    on ddCategory selected idx do
    (
        ddType.items = FurnGen_TypeLabels[idx]
        ddType.selection = 1
        syncEnabled()
    )

    on btnGenerate pressed do doGenerate()

    on btnRandom pressed do
    (
        randomizeParams()
        doGenerate()
    )

    on btnRandomAll pressed do
    (
        ddCategory.selection = random 1 FurnGen_Categories.count
        ddType.items = FurnGen_TypeLabels[ddCategory.selection]
        randomizeParams()
        syncEnabled()
        doGenerate()
    )

    on btnRoomSet pressed do
    (
        lblStatus.text = "Building living room..."
        doBuildSet #living
    )

    on btnBedroom pressed do
    (
        lblStatus.text = "Building bedroom..."
        doBuildSet #bedroom
    )

    on btnDelete pressed do
    (
        if FurnGen_LastGroup != undefined and isValidNode FurnGen_LastGroup then
        (
            undo "FurnGen Delete" on ( delete FurnGen_LastGroup )
            FurnGen_LastGroup = undefined
            lblStatus.text = "Last item deleted."
        )
        else lblStatus.text = "Nothing to delete."
    )

    on btnSave pressed do
    (
        local f = fgPresetFile()
        local p = etPreset.text
        if p == "" then p = "Default"
        setINISetting f p "category" (ddCategory.selection as string)
        setINISetting f p "type" (ddType.selection as string)
        setINISetting f p "style" (ddStyle.selection as string)
        setINISetting f p "fabric" (ddFabric.selection as string)
        setINISetting f p "seats" (spSeats.value as string)
        setINISetting f p "width" (spWidth.value as string)
        setINISetting f p "depth" (spDepth.value as string)
        setINISetting f p "height" (spHeight.value as string)
        setINISetting f p "soft" (spSoft.value as string)
        setINISetting f p "seed" (spSeed.value as string)
        setINISetting f p "quality" (ddQuality.selection as string)
        lblStatus.text = "Preset '" + p + "' saved."
    )

    on btnLoad pressed do
    (
        local f = fgPresetFile()
        local p = etPreset.text
        if (getINISetting f p "type") == "" then
            lblStatus.text = "Preset '" + p + "' not found."
        else
        (
            local catStr = getINISetting f p "category"
            if catStr != "" then
            (
                ddCategory.selection = catStr as integer
                ddType.items = FurnGen_TypeLabels[ddCategory.selection]
            )
            ddType.selection = (getINISetting f p "type") as integer
            ddStyle.selection = (getINISetting f p "style") as integer
            ddFabric.selection = (getINISetting f p "fabric") as integer
            spSeats.value = (getINISetting f p "seats") as integer
            spWidth.value = (getINISetting f p "width") as float
            spDepth.value = (getINISetting f p "depth") as float
            spHeight.value = (getINISetting f p "height") as float
            spSoft.value = (getINISetting f p "soft") as float
            spSeed.value = (getINISetting f p "seed") as integer
            ddQuality.selection = (getINISetting f p "quality") as integer
            syncEnabled()
            lblStatus.text = "Preset '" + p + "' loaded."
        )
    )
)

fn fgOpenUI =
(
    if FurnGenUI_Floater != undefined then ( try (closeRolloutFloater FurnGenUI_Floater) catch() )
    FurnGenUI_Floater = newRolloutFloater ("FurnGen v" + FurnGen_Version) 320 860
    addRollout FurnGenRollout FurnGenUI_Floater
)
