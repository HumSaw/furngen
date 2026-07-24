/*
    SofaGen_Assembly.ms
    -------------------
    Сборка дивана из частей. Система координат:
        X — ширина (центр в 0), Y — глубина (перед = -Y, спинка = +Y),
        Z — высота (пол = 0). Все размеры в см.

    Расширение системы: для нового предмета мебели (кресло, кровать,
    стол) создаётся новый Assembly-модуль, переиспользующий
    Core / Geometry / Materials / QA.
*/

-------------------------------------------------------------------
-- Один "прогон" сидений: база + спинка + подушки + кант
-- origin — точка центра прогона на полу, rotZ — поворот секции.
-------------------------------------------------------------------
fn sgBuildRun cfg runWidth runDepth origin rotZ parts prefix withLeftArm withRightArm fabricMtl pipingMtl =
(
    local innerW = runWidth - (if withLeftArm then cfg.armWidth else 0.0) \
                            - (if withRightArm then cfg.armWidth else 0.0)
    local innerXOff = ((if withLeftArm then cfg.armWidth else 0.0) \
                     - (if withRightArm then cfg.armWidth else 0.0)) / 2.0

    local backD = 18.0
    local cushH = cfg.cushionHeight
    local baseTop = cfg.seatHeight - cushH * 0.55   -- подушка утоплена в базу
    local baseH = baseTop - cfg.legHeight
    local seatD = runDepth - backD - 4.0
    local seatCount = (amax 1 (ceil (innerW / 70.0))) as integer
    if cfg.sofaType != #corner and prefix == "Main" then seatCount = cfg.seats
    local sectionParts = #()

    -- БАЗА
    local base = sgSoftBlock innerW runDepth baseH (baseH * 0.18) cfg (prefix + "_Base") softness:0.2
    base.pos = [innerXOff, 0, cfg.legHeight]
    base.material = fabricMtl
    append sectionParts base

    -- СПИНКА (с лёгким наклоном назад)
    local backH = cfg.height - baseTop
    local backPanel = sgSoftBlock innerW backD backH (backD * 0.35) cfg (prefix + "_Back") softness:0.4
    backPanel.pos = [innerXOff, runDepth / 2.0 - backD / 2.0, baseTop]
    rotate backPanel (eulerangles -5.0 0 0)
    backPanel.material = fabricMtl
    append sectionParts backPanel

    -- ПОДЛОКОТНИКИ
    if withLeftArm then
    (
        local armL = sgArm cfg -1 (prefix + "_Arm_L")
        armL.pos = [-runWidth / 2.0 + cfg.armWidth / 2.0, 0, cfg.legHeight]
        armL.material = fabricMtl
        append sectionParts armL
    )
    if withRightArm then
    (
        local armR = sgArm cfg 1 (prefix + "_Arm_R")
        armR.pos = [runWidth / 2.0 - cfg.armWidth / 2.0, 0, cfg.legHeight]
        armR.material = fabricMtl
        append sectionParts armR
    )

    -- ПОДУШКИ СИДЕНЬЯ + КАНТ
    local gap = 1.5
    local cushW = (innerW - gap * (seatCount - 1)) / seatCount
    local seatY = -backD / 2.0 - 2.0
    for i = 1 to seatCount do
    (
        local cx = innerXOff - innerW / 2.0 + cushW / 2.0 + (i - 1) * (cushW + gap)
        local sc = sgCushion (cushW - 1.0) seatD cushH cfg (prefix + "_SeatCushion_" + i as string)
        sc.pos = [sgJitter cx 0.4, sgJitter seatY 0.5, baseTop]
        sc.material = fabricMtl
        append sectionParts sc

        if cfg.piping then
        (
            local pp = sgPiping (cushW - 1.0) seatD (cushH * 0.3) 0.7 (prefix + "_Piping_Seat_" + i as string)
            pp.pos = [sc.pos.x, sc.pos.y, baseTop + cushH * 0.62]
            pp.material = pipingMtl
            append sectionParts pp
        )

        -- ПОДУШКИ СПИНКИ (опираются на спинку с наклоном)
        if cfg.backCushions then
        (
            local bcH = backH * 0.85
            local bc = sgCushion (cushW - 1.0) 12.0 bcH cfg (prefix + "_BackCushion_" + i as string) isBack:true
            -- ставим вертикально, прислоняя к спинке
            rotate bc (eulerangles (sgJitter -78.0 2.0) 0 0)
            bc.pos = [sgJitter cx 0.4, runDepth / 2.0 - backD - 5.0, baseTop + cushH * 0.5]
            bc.material = fabricMtl
            append sectionParts bc
        )
    )

    -- НОЖКИ
    if cfg.legStyle != #none then
    (
        local inset = 8.0
        local legPos = #(
            [-runWidth / 2.0 + inset, -runDepth / 2.0 + inset, 0],
            [ runWidth / 2.0 - inset, -runDepth / 2.0 + inset, 0],
            [-runWidth / 2.0 + inset,  runDepth / 2.0 - inset, 0],
            [ runWidth / 2.0 - inset,  runDepth / 2.0 - inset, 0]
        )
        if runWidth > 200 then
        (
            append legPos [0, -runDepth / 2.0 + inset, 0]
            append legPos [0,  runDepth / 2.0 - inset, 0]
        )
        for i = 1 to legPos.count do
        (
            local lg = sgLeg cfg (prefix + "_Leg_" + i as string)
            lg.pos = legPos[i]
            append sectionParts lg
        )
    )

    -- трансформация секции целиком: поворот вокруг ЛОКАЛЬНОГО начала секции
    -- (умножение transform на rotateZMatrix вращает и ориентацию, И позицию
    -- вокруг мирового 0, где секция была собрана), затем перенос в origin
    for p in sectionParts do
    (
        if rotZ != 0.0 then p.transform = p.transform * (rotateZMatrix rotZ)
        p.pos = p.pos + origin
        append parts p
    )
    sectionParts
)

-------------------------------------------------------------------
-- ГЛАВНАЯ ФУНКЦИЯ СБОРКИ
-------------------------------------------------------------------
fn sgBuildSofa cfg =
(
    sgSetSeed cfg.seed
    local parts = #()

    local fabricMtl = sgMakeFabricMtl cfg
    local pipingMtl = sgMakePipingMtl cfg fabricMtl
    local legMtl = sgMakeLegMtl cfg

    -- основной прогон
    case cfg.sofaType of
    (
        #modular:
        (
            -- модульные секции с видимым зазором, крайние — с подлокотником;
            -- зазоры учтены в ширине секций, итоговая ширина = cfg.width точно
            local mGap = 2.0
            local secW = (cfg.width - cfg.armWidth * 2 - mGap * (cfg.seats - 1)) / cfg.seats
            for i = 1 to cfg.seats do
            (
                local isFirst = (i == 1)
                local isLast = (i == cfg.seats)
                local w = secW + (if isFirst then cfg.armWidth else 0) + (if isLast then cfg.armWidth else 0)
                local xStart = -cfg.width / 2.0 + (if isFirst then 0.0 else (cfg.armWidth + (secW + mGap) * (i - 1)))
                sgBuildRun cfg w cfg.depth [xStart + w / 2.0, 0, 0] 0.0 parts ("Module_" + i as string) isFirst isLast fabricMtl pipingMtl
            )
        )
        #corner:
        (
            -- основной прогон без левого подлокотника + перпендикулярная секция
            sgBuildRun cfg cfg.width cfg.depth [0, 0, 0] 0.0 parts "Main" false true fabricMtl pipingMtl
            local extLen = cfg.depth * 1.6
            sgBuildRun cfg extLen cfg.depth \
                [-cfg.width / 2.0 + cfg.depth / 2.0, -cfg.depth / 2.0 - extLen / 2.0 + cfg.depth, 0] \
                90.0 parts "Corner" true false fabricMtl pipingMtl
        )
        #chaise:
        (
            sgBuildRun cfg cfg.width cfg.depth [0, 0, 0] 0.0 parts "Main" true true fabricMtl pipingMtl
            -- оттоманка перед левым сиденьем
            local chW = (cfg.width - cfg.armWidth * 2) / cfg.seats
            local chD = cfg.depth * 0.7
            local chX = -cfg.width / 2.0 + cfg.armWidth + chW / 2.0
            local baseTop = cfg.seatHeight - cfg.cushionHeight * 0.55
            local chBase = sgSoftBlock chW chD (baseTop - cfg.legHeight) 4.0 cfg "Chaise_Base" softness:0.2
            chBase.pos = [chX, -cfg.depth / 2.0 - chD / 2.0 + 1.0, cfg.legHeight]
            chBase.material = fabricMtl
            append parts chBase
            local chCush = sgCushion (chW - 1.0) (chD - 2.0) cfg.cushionHeight cfg "Chaise_Cushion"
            chCush.pos = [chX, chBase.pos.y, baseTop]
            chCush.material = fabricMtl
            append parts chCush
            if cfg.legStyle != #none then for i = 1 to 2 do
            (
                local lg = sgLeg cfg ("Chaise_Leg_" + i as string)
                lg.pos = [chX + (if i == 1 then -1 else 1) * (chW / 2.0 - 8.0), chBase.pos.y - chD / 2.0 + 8.0, 0]
                append parts lg
            )
        )
        default:
        (
            -- straight / loveseat / armchair
            sgBuildRun cfg cfg.width cfg.depth [0, 0, 0] 0.0 parts "Main" true true fabricMtl pipingMtl
        )
    )

    -- материалы ножек + слой сцены (включая child-ноды, напр. валик #pillow-подлокотника)
    local sofaLayer = sgGetLayer "SofaGen_Furniture"
    for p in parts do
    (
        if matchPattern p.name pattern:"*_Leg_*" then p.material = legMtl
        if p.material == undefined then p.material = fabricMtl
        sofaLayer.addNode p
        for ch in p.children do
        (
            if ch.material == undefined then ch.material = p.material
            sofaLayer.addNode ch
        )
    )

    -- группа с уникальным именем
    local grpName = uniquename ("Sofa_" + (cfg.style as string) + "_" + (cfg.sofaType as string))
    local grp = group parts name:grpName
    sofaLayer.addNode grp

    format "SofaGen: built '%' (% parts, seed %)\n" grpName parts.count cfg.seed
    grp
)
