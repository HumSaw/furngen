/*
    SofaGen_UI.ms
    -------------
    Панель генератора: Generate / Randomize / стиль / материал /
    качество / seed / сохранение пресетов (INI-файл в userScripts).
*/

global SofaGenUI_Floater

global SofaGen_TypeKeys   = #(#straight, #corner, #modular, #loveseat, #chaise, #armchair)
global SofaGen_StyleKeys  = #(#modern, #minimal, #scandinavian, #japandi, #luxury, #classic, #brutalism, #midcentury)
global SofaGen_FabricKeys = #(#boucle, #velvet, #linen, #cotton, #leather)
global SofaGen_LastGroup

fn sgPresetFile = ( (getDir #userScripts) + "\\SofaGen_Presets.ini" )

rollout SofaGenRollout "SofaGen — Procedural Sofa Generator" width:300
(
    group "Конфигурация"
    (
        dropdownlist ddType "Тип дивана:" items:#("Прямой", "Угловой", "Модульный", "Loveseat", "Chaise lounge", "Кресло") selection:1
        spinner spSeats "Количество мест:" range:[1, 6, 3] type:#integer fieldwidth:50
        dropdownlist ddStyle "Стиль:" items:#("Modern", "Minimal", "Scandinavian", "Japandi", "Luxury", "Classic", "Brutalism", "Mid-century") selection:1
        dropdownlist ddFabric "Материал:" items:#("Boucle", "Velvet", "Linen", "Cotton", "Leather") selection:1
    )
    group "Габариты (см)"
    (
        spinner spWidth "Ширина:" range:[80, 500, 240] fieldwidth:60
        spinner spDepth "Глубина:" range:[70, 180, 100] fieldwidth:60
        spinner spHeight "Высота:" range:[55, 130, 82] fieldwidth:60
        spinner spSoft "Мягкость:" range:[0.0, 1.0, 0.5] scale:0.05 fieldwidth:60
        checkbox cbPiping "Кант (piping)" checked:true
        checkbox cbBackCush "Подушки спинки" checked:true
    )
    group "Генерация"
    (
        dropdownlist ddQuality "Качество:" items:#("Draft", "Production", "Close-up 4K") selection:2
        spinner spSeed "Seed:" range:[1, 999999, 12345] type:#integer fieldwidth:70
        button btnGenerate "GENERATE SOFA" width:270 height:34
        button btnRandom "Randomize" width:270 height:26
        button btnDelete "Delete last" width:270 height:22
    )
    group "Пресеты"
    (
        edittext etPreset "Имя:" text:"MySofa"
        button btnSave "Save preset" width:130 across:2
        button btnLoad "Load preset" width:130
    )
    label lblStatus "Готов к генерации" align:#left

    -- Собрать конфиг из UI
    fn buildConfig =
    (
        local cfg = SofaConfig()
        cfg.seed = spSeed.value
        sgSetSeed cfg.seed   -- seed ДО выбора палитры стиля: полный детерминизм
        cfg = sgApplyStyle cfg SofaGen_StyleKeys[ddStyle.selection]
        cfg.seats = spSeats.value
        cfg = sgApplyType cfg SofaGen_TypeKeys[ddType.selection]
        cfg.fabric = SofaGen_FabricKeys[ddFabric.selection]
        cfg.width = amax spWidth.value cfg.width
        cfg.depth = spDepth.value
        cfg.height = spHeight.value
        cfg.cushionSoftness = spSoft.value
        cfg.piping = cbPiping.checked and cfg.piping
        cfg.backCushions = cbBackCush.checked
        cfg.quality = ddQuality.selection
        cfg
    )

    -- Общая процедура генерации (вызывается из Generate и Randomize)
    fn doGenerate =
    (
        lblStatus.text = "Генерация..."
        local cfg = buildConfig()
        local grp
        undo "SofaGen Generate" on ( grp = sgBuildSofa cfg )
        SofaGen_LastGroup = grp
        local report = sgValidateSofa grp
        lblStatus.text = report[report.count]
        if grp != undefined then ( select grp; max zoomext sel )
    )

    on btnGenerate pressed do doGenerate()

    on btnDelete pressed do
    (
        if SofaGen_LastGroup != undefined and isValidNode SofaGen_LastGroup then
        (
            undo "SofaGen Delete" on ( delete SofaGen_LastGroup )
            SofaGen_LastGroup = undefined
            lblStatus.text = "Последний диван удалён"
        )
        else lblStatus.text = "Нечего удалять"
    )

    on btnRandom pressed do
    (
        ddType.selection = random 1 6
        ddStyle.selection = random 1 8
        ddFabric.selection = random 1 5
        spSeats.value = random 2 4
        spWidth.value = random 180.0 320.0
        spDepth.value = random 90.0 115.0
        spSoft.value = random 0.3 0.8
        spSeed.value = random 1 999999
        doGenerate()
    )

    on btnSave pressed do
    (
        local f = sgPresetFile()
        local p = etPreset.text
        if p == "" then p = "Default"
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
        lblStatus.text = "Пресет '" + p + "' сохранён"
    )

    on btnLoad pressed do
    (
        local f = sgPresetFile()
        local p = etPreset.text
        if (getINISetting f p "type") == "" then
            lblStatus.text = "Пресет '" + p + "' не найден"
        else
        (
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
            lblStatus.text = "Пресет '" + p + "' загружен"
        )
    )
)

fn sgOpenUI =
(
    if SofaGenUI_Floater != undefined then ( try (closeRolloutFloater SofaGenUI_Floater) catch() )
    SofaGenUI_Floater = newRolloutFloater ("SofaGen v" + SofaGen_Version) 320 680
    addRollout SofaGenRollout SofaGenUI_Floater
)
