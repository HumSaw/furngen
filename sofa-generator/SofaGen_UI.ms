/*
    SofaGen_UI.ms  (FurnGen v2)
    ---------------------------
    Панель генератора мебели: категория -> тип -> стиль -> материал.
    Generate / Randomize / ROOM SET / Delete / пресеты (INI).
*/

global SofaGenUI_Floater
global SofaGen_LastGroup

-- Категории и типы внутри каждой категории
global FurnGen_Categories = #(#sofa, #bed, #chair, #table, #storage, #decor)
global FurnGen_CatLabels  = #("Диваны", "Кровати", "Стулья", "Столы", "Хранение", "Декор")

global FurnGen_TypeKeys = #(
    #(#straight, #corner, #modular, #loveseat, #chaise, #armchair),
    #(#bedSingle, #bedDouble, #bedKing, #bedCanopy),
    #(#chairDining, #chairBar, #chairLounge, #stool),
    #(#tableDining, #tableCoffee, #tableSide, #tableDesk, #tableNightstand),
    #(#wardrobe, #dresser),
    #(#pouf, #rug, #floorLamp, #bookshelf, #tvConsole, #plant, #mirror)
)
global FurnGen_TypeLabels = #(
    #("Прямой", "Угловой", "Модульный", "Loveseat", "Chaise lounge", "Кресло"),
    #("Односпальная", "Двуспальная", "King-size", "С балдахином"),
    #("Обеденный стул", "Барный стул", "Лаунж-кресло", "Табурет"),
    #("Обеденный", "Кофейный", "Приставной", "Письменный", "Тумбочка"),
    #("Шкаф", "Комод"),
    #("Пуф", "Ковёр", "Торшер", "Книжный шкаф", "ТВ-тумба", "Растение", "Зеркало")
)

global SofaGen_StyleKeys  = #(#modern, #minimal, #scandinavian, #japandi, #luxury, #classic, #brutalism, #midcentury)
global SofaGen_FabricKeys = #(#boucle, #velvet, #linen, #cotton, #leather)

fn sgPresetFile = ( (getDir #userScripts) + "\\SofaGen_Presets.ini" )

rollout SofaGenRollout "FurnGen — Procedural Furniture Generator" width:300
(
    group "Что генерируем"
    (
        dropdownlist ddCategory "Категория:" items:FurnGen_CatLabels selection:1
        dropdownlist ddType "Тип:" items:FurnGen_TypeLabels[1] selection:1
        dropdownlist ddStyle "Стиль:" items:#("Modern", "Minimal", "Scandinavian", "Japandi", "Luxury", "Classic", "Brutalism", "Mid-century") selection:1
        dropdownlist ddFabric "Ткань:" items:#("Boucle", "Velvet", "Linen", "Cotton", "Leather") selection:1
    )
    group "Параметры"
    (
        spinner spSeats "Мест (диваны):" range:[1, 6, 3] type:#integer fieldwidth:50
        spinner spWidth "Ширина (см):" range:[40, 500, 240] fieldwidth:60
        spinner spDepth "Глубина (см):" range:[30, 220, 100] fieldwidth:60
        spinner spHeight "Высота (см):" range:[30, 250, 82] fieldwidth:60
        spinner spSoft "Мягкость:" range:[0.0, 1.0, 0.5] scale:0.05 fieldwidth:60
        checkbox cbPiping "Кант (piping)" checked:true
        checkbox cbBackCush "Подушки спинки" checked:true
        checkbox cbDecor "Декор дивана (плед + подушки)" checked:true
    )
    group "Генерация"
    (
        dropdownlist ddQuality "Качество:" items:#("Draft", "Production", "Close-up 4K") selection:2
        spinner spSeed "Seed:" range:[1, 999999, 12345] type:#integer fieldwidth:70
        button btnGenerate "GENERATE" width:270 height:34
        button btnRandom "Randomize" width:132 height:26 across:2
        button btnRandomAll "Random ALL" width:132 height:26
        button btnRoomSet "BUILD LIVING ROOM (гостиная)" width:270 height:30
        button btnBedroom "BUILD BEDROOM (спальня)" width:270 height:30
        button btnDelete "Delete last" width:270 height:22
    )
    group "Пресеты"
    (
        edittext etPreset "Имя:" text:"MyFurniture"
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
        cfg.fabric = SofaGen_FabricKeys[ddFabric.selection]
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

    -- Общая процедура генерации (с перехватом ошибок: при сбое
    -- никакой «полусобранной» серой геометрии в сцене не остаётся)
    fn doGenerate =
    (
        lblStatus.text = "Генерация..."
        local cfg = buildConfig()
        local category = FurnGen_Categories[ddCategory.selection]
        local itemType = FurnGen_TypeKeys[ddCategory.selection][ddType.selection]
        -- у диванов ширина от количества мест (как раньше)
        if category == #sofa then cfg.width = amax cfg.width 80.0
        local grp = undefined
        try
        (
            undo "FurnGen Generate" on ( grp = sgBuildItem cfg category itemType )
        )
        catch
        (
            max undo   -- откатить частично созданную геометрию
            lblStatus.text = "ОШИБКА: " + (getCurrentException())
            format "FurnGen ERROR: %\n" (getCurrentException())
            return()
        )
        SofaGen_LastGroup = grp
        local report = sgValidateSofa grp
        lblStatus.text = report[report.count]
        if grp != undefined then ( select grp; max zoomext sel )
    )

    on ddCategory selected idx do
    (
        ddType.items = FurnGen_TypeLabels[idx]
        ddType.selection = 1
    )

    on btnGenerate pressed do doGenerate()

    -- Общий обработчик сборки комнат (гостиная / спальня)
    fn doBuildSet setKind =
    (
        local cfg = buildConfig()
        local grp = undefined
        try
        (
            undo "FurnGen Set" on
            (
                if setKind == #living then grp = sgBuildRoomSet cfg
                else grp = sgBuildBedroomSet cfg
            )
        )
        catch
        (
            max undo
            lblStatus.text = "ОШИБКА: " + (getCurrentException())
            format "FurnGen ERROR: %\n" (getCurrentException())
        )
        if grp != undefined then
        (
            SofaGen_LastGroup = grp
            lblStatus.text = "Готово: " + grp.name
            select grp
            max zoomext sel
        )
    )

    on btnRoomSet pressed do
    (
        lblStatus.text = "Сборка гостиной..."
        doBuildSet #living
    )

    on btnBedroom pressed do
    (
        lblStatus.text = "Сборка спальни..."
        doBuildSet #bedroom
    )

    on btnDelete pressed do
    (
        if SofaGen_LastGroup != undefined and isValidNode SofaGen_LastGroup then
        (
            undo "FurnGen Delete" on ( delete SofaGen_LastGroup )
            SofaGen_LastGroup = undefined
            lblStatus.text = "Последний объект удалён"
        )
        else lblStatus.text = "Нечего удалять"
    )

    -- Random в пределах текущей категории
    on btnRandom pressed do
    (
        ddType.selection = random 1 FurnGen_TypeKeys[ddCategory.selection].count
        ddStyle.selection = random 1 8
        ddFabric.selection = random 1 5
        spSeats.value = random 2 4
        spWidth.value = random 160.0 300.0
        spSoft.value = random 0.3 0.8
        spSeed.value = random 1 999999
        doGenerate()
    )

    -- Random вообще всего, включая категорию
    on btnRandomAll pressed do
    (
        ddCategory.selection = random 1 FurnGen_Categories.count
        ddType.items = FurnGen_TypeLabels[ddCategory.selection]
        ddType.selection = random 1 FurnGen_TypeKeys[ddCategory.selection].count
        ddStyle.selection = random 1 8
        ddFabric.selection = random 1 5
        spSeats.value = random 2 4
        spWidth.value = random 160.0 300.0
        spSoft.value = random 0.3 0.8
        spSeed.value = random 1 999999
        doGenerate()
    )

    on btnSave pressed do
    (
        local f = sgPresetFile()
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
            lblStatus.text = "Пресет '" + p + "' загружен"
        )
    )
)

fn sgOpenUI =
(
    if SofaGenUI_Floater != undefined then ( try (closeRolloutFloater SofaGenUI_Floater) catch() )
    SofaGenUI_Floater = newRolloutFloater ("FurnGen v" + SofaGen_Version) 320 820
    addRollout SofaGenRollout SofaGenUI_Floater
)
