/*
    SofaGen_Furniture.ms
    --------------------
    FurnGen v2: кровати, стулья, столы, декор и генератор Room Set.
    Переиспользует Core (конфиг, стили, RNG), Geometry (мягкие блоки,
    подушки, ножки), Materials (ткань, дерево, металл, постель).

    Система координат едина с диванами:
        X — ширина, Y — глубина (перед = -Y), Z — высота (пол = 0), см.
*/

-------------------------------------------------------------------
-- Финализация: слой + группа + лог (общая для всех предметов)
-------------------------------------------------------------------
fn sgFinalizeItem parts grpName defaultMtl =
(
    local lay = sgGetLayer "SofaGen_Furniture"
    for p in parts do
    (
        if p.material == undefined then p.material = defaultMtl
        lay.addNode p
        for ch in p.children do
        (
            if ch.material == undefined then ch.material = p.material
            lay.addNode ch
        )
    )
    local grp = group parts name:(uniquename grpName)
    lay.addNode grp
    format "FurnGen: built '%' (% parts)\n" grp.name parts.count
    grp
)

-------------------------------------------------------------------
-- Деревянная ножка произвольной высоты (конус/цилиндр/брус)
-------------------------------------------------------------------
fn sgFurnLeg legStyle h partName r1:2.4 r2:1.4 =
(
    case legStyle of
    (
        #cone:     ( Cone radius1:r1 radius2:r2 height:h sides:18 name:partName )
        #cylinder: ( Cylinder radius:(r1 * 0.8) height:h sides:18 name:partName )
        #block:    ( Box width:(r1 * 2.2) length:(r1 * 2.2) height:h name:partName )
        default:   ( Cone radius1:r1 radius2:r2 height:h sides:18 name:partName )
    )
)

-------------------------------------------------------------------
-- Столешница: прямоугольная или круглая, с фаской
-------------------------------------------------------------------
fn sgTableTop isRound w d thick partName =
(
    if isRound then
        ChamferCyl radius:(w / 2.0) height:thick fillet:(thick * 0.3) sides:48 filletsegs:3 name:partName
    else
    (
        local t = ChamferBox width:w length:d height:thick fillet:(thick * 0.28) name:partName
        sgSetChamferSegs t 4 3 2
        t
    )
)

-------------------------------------------------------------------
-- КРОВАТЬ: #bedSingle #bedDouble #bedKing #bedCanopy
-------------------------------------------------------------------
fn sgBuildBed cfg itemType =
(
    sgSetSeed cfg.seed
    local parts = #()

    -- габариты матраса по типу (ширину можно переопределить конфигом)
    local mattW = case itemType of ( #bedSingle: 90.0; #bedDouble: 160.0; #bedKing: 200.0; #bedCanopy: 180.0; default: 160.0 )
    mattW = amax mattW (amin cfg.width 220.0)
    local mattL = 200.0
    local legH = 12.0
    local frameH = 20.0
    local mattH = 22.0
    local frameTop = legH + frameH

    local woodMtl = sgMakeWoodMtl cfg.legColor
    local fabricMtl = sgMakeFabricMtl cfg
    local beddingCol = sgPick #(color 240 238 232, color 226 222 212, color 210 214 218)
    local beddingMtl = sgMakeBeddingMtl beddingCol
    local blanketMtl = sgMakeBeddingMtl cfg.fabricColor mtlName:"FurnGen_Blanket"

    -- КАРКАС (мягкий, обитый тканью)
    local frame = sgSoftBlock (mattW + 14.0) (mattL + 12.0) frameH 4.0 cfg "Bed_Frame" softness:0.25
    frame.pos = [0, 0, legH]; frame.material = fabricMtl
    append parts frame

    -- МАТРАС (белый, мягкий)
    local matt = sgSoftBlock mattW mattL mattH 6.0 cfg "Bed_Mattress" softness:0.55
    matt.pos = [0, 0, frameTop]; matt.material = beddingMtl
    append parts matt

    -- ИЗГОЛОВЬЕ (мягкое, у +Y)
    local hbH = if itemType == #bedCanopy then 90.0 else 65.0
    local hb = sgSoftBlock (mattW + 14.0) 12.0 hbH 5.0 cfg "Bed_Headboard" softness:0.45
    hb.pos = [0, mattL / 2.0 + 8.0, legH]; hb.material = fabricMtl
    append parts hb

    -- ОДЕЯЛО: накрывает нижние 2/3, свисает по бокам, сильный Noise = драпировка
    local blW = mattW + 22.0
    local blL = mattL * 0.62
    local bl = ChamferBox width:blW length:blL height:5.0 fillet:2.2 name:"Bed_Blanket"
    sgSetChamferSegs bl 10 3 2
    addModifier bl (Noisemodifier scale:28.0 fractal:true strength:[2.5, 3.5, 4.5] seed:(sgRandI 1 99999))
    addModifier bl (Noisemodifier scale:7.0 fractal:true strength:[0.8, 0.8, 1.4] seed:(sgRandI 1 99999))
    addModifier bl (TurboSmooth iterations:2)
    addModifier bl (Uvwmap maptype:4 width:60 length:60 height:60)
    bl.pos = [0, -mattL / 2.0 + blL / 2.0 - 3.0, frameTop + mattH - 2.0]
    bl.material = blanketMtl
    append parts bl

    -- ПОДУШКИ у изголовья (2 ряда для широких кроватей)
    local pilCount = if mattW >= 140.0 then 2 else 1
    local pilW = (mattW - 12.0) / pilCount
    for i = 1 to pilCount do
    (
        local px = -mattW / 2.0 + 6.0 + pilW / 2.0 + (i - 1) * pilW
        local pil = sgCushion (pilW - 6.0) 42.0 15.0 cfg ("Bed_Pillow_" + i as string)
        rotate pil (eulerangles (sgJitter -18.0 5.0) 0 (sgJitter 0.0 3.0))
        pil.pos = [sgJitter px 1.5, mattL / 2.0 - 26.0, frameTop + mattH + 4.0]
        pil.material = beddingMtl
        append parts pil
        -- декоративная малая подушка спереди
        if pilCount == 2 and i == 1 then
        (
            local dp = sgCushion 40.0 30.0 12.0 cfg "Bed_DecoPillow"
            rotate dp (eulerangles (sgJitter -25.0 6.0) 0 (sgJitter 0.0 8.0))
            dp.pos = [sgJitter 0.0 10.0, mattL / 2.0 - 52.0, frameTop + mattH + 3.0]
            dp.material = fabricMtl
            append parts dp
        )
    )

    -- НОЖКИ
    for i = 1 to 4 do
    (
        local sx = if (mod i 2 == 1) then -1 else 1
        local sy = if i <= 2 then -1 else 1
        local lg = sgFurnLeg #cone legH ("Bed_Leg_" + i as string) r1:3.2 r2:2.0
        lg.pos = [sx * (mattW / 2.0), sy * (mattL / 2.0), 0]
        lg.material = woodMtl
        append parts lg
    )

    -- БАЛДАХИН (canopy): 4 стойки + верхняя рама
    if itemType == #bedCanopy then
    (
        local postH = 210.0
        for i = 1 to 4 do
        (
            local sx = if (mod i 2 == 1) then -1 else 1
            local sy = if i <= 2 then -1 else 1
            local post = Cylinder radius:2.4 height:postH sides:16 name:("Bed_Post_" + i as string)
            post.pos = [sx * (mattW / 2.0 + 5.0), sy * (mattL / 2.0 + 4.0), 0]
            post.material = woodMtl
            append parts post
        )
        local railX = Box width:(mattW + 14.0) length:4.0 height:4.0 name:"Bed_CanopyRail_F"
        railX.pos = [0, -(mattL / 2.0 + 4.0), postH]; railX.material = woodMtl
        append parts railX
        local railX2 = copy railX; railX2.name = "Bed_CanopyRail_B"
        railX2.pos = [0, mattL / 2.0 + 4.0, postH]
        append parts railX2
        local railY = Box width:4.0 length:(mattL + 12.0) height:4.0 name:"Bed_CanopyRail_L"
        railY.pos = [-(mattW / 2.0 + 5.0), 0, postH]; railY.material = woodMtl
        append parts railY
        local railY2 = copy railY; railY2.name = "Bed_CanopyRail_R"
        railY2.pos = [mattW / 2.0 + 5.0, 0, postH]
        append parts railY2
    )

    sgFinalizeItem parts ("Bed_" + (cfg.style as string) + "_" + (itemType as string)) fabricMtl
)

-------------------------------------------------------------------
-- СТУЛ / ТАБУРЕТ: #chairDining #chairBar #chairLounge #stool
-------------------------------------------------------------------
fn sgBuildChair cfg itemType =
(
    sgSetSeed cfg.seed
    local parts = #()
    local woodMtl = sgMakeWoodMtl cfg.legColor
    local fabricMtl = sgMakeFabricMtl cfg

    case itemType of
    (
        #chairDining:
        (
            local seatH = 45.0, seatW = 45.0, seatD = 45.0
            -- ножки: задние выше (переходят в спинку)
            for i = 1 to 4 do
            (
                local sx = if (mod i 2 == 1) then -1 else 1
                local isBack = i > 2
                local h = if isBack then 88.0 else seatH
                local lg = sgFurnLeg #cone h ("Chair_Leg_" + i as string) r1:2.2 r2:1.5
                lg.pos = [sx * (seatW / 2.0 - 3.0), (if isBack then 1 else -1) * (seatD / 2.0 - 3.0), 0]
                if isBack then rotate lg (eulerangles 4.0 0 0)   -- лёгкий наклон спинки
                lg.material = woodMtl
                append parts lg
            )
            -- сиденье: деревянная основа + мягкая подушка
            local sBase = sgTableTop false seatW seatD 4.0 "Chair_SeatBase"
            sBase.pos = [0, 0, seatH]; sBase.material = woodMtl
            append parts sBase
            local sCush = sgCushion (seatW - 4.0) (seatD - 4.0) 6.5 cfg "Chair_SeatCushion"
            sCush.pos = [0, 0, seatH + 4.0]; sCush.material = fabricMtl
            append parts sCush
            -- спинка: мягкая панель между задними ножками
            local back = sgSoftBlock (seatW - 6.0) 5.0 30.0 2.5 cfg "Chair_Back" softness:0.4
            back.pos = [0, seatD / 2.0 + 1.0, 56.0]
            rotate back (eulerangles 4.0 0 0)
            back.material = fabricMtl
            append parts back
        )
        #chairBar:
        (
            local seatH = 75.0
            for i = 1 to 4 do
            (
                local sx = if (mod i 2 == 1) then -1 else 1
                local sy = if i <= 2 then -1 else 1
                local lg = sgFurnLeg #cone seatH ("Stool_Leg_" + i as string) r1:2.0 r2:1.3
                lg.pos = [sx * 14.0, sy * 14.0, 0]
                rotate lg (eulerangles (sy * -4.0) (sx * 4.0) 0)   -- расставленные ножки
                lg.material = woodMtl
                append parts lg
            )
            -- подножка-кольцо
            local ring = Torus radius1:16.0 radius2:0.9 segs:32 name:"Stool_FootRing"
            ring.pos = [0, 0, 24.0]
            ring.material = sgMakeMetalMtl (color 40 40 40) 0.3
            append parts ring
            -- круглое мягкое сиденье
            local seat = ChamferCyl radius:17.0 height:9.0 fillet:4.0 sides:32 filletsegs:3 name:"Stool_Seat"
            addModifier seat (Push Push_Value:0.6)
            addModifier seat (Noisemodifier scale:10.0 fractal:true strength:[0.3, 0.3, 0.7] seed:(sgRandI 1 99999))
            addModifier seat (TurboSmooth iterations:2)
            addModifier seat (Uvwmap maptype:4 width:50 length:50 height:50)
            seat.pos = [0, 0, seatH]; seat.material = fabricMtl
            append parts seat
        )
        #chairLounge:
        (
            -- низкое широкое кресло-лаунж: деревянный каркас + 2 толстые подушки
            local seatH = 38.0, w = 65.0, d = 75.0
            for i = 1 to 4 do
            (
                local sx = if (mod i 2 == 1) then -1 else 1
                local sy = if i <= 2 then -1 else 1
                local lg = sgFurnLeg #cone seatH ("Lounge_Leg_" + i as string) r1:2.6 r2:1.6
                lg.pos = [sx * (w / 2.0 - 5.0), sy * (d / 2.0 - 5.0), 0]
                lg.material = woodMtl
                append parts lg
            )
            local sFrame = sgTableTop false w d 5.0 "Lounge_Frame"
            sFrame.pos = [0, 0, seatH]; sFrame.material = woodMtl
            append parts sFrame
            local sCush = sgCushion (w - 6.0) (d - 8.0) 14.0 cfg "Lounge_SeatCushion"
            sCush.pos = [0, -2.0, seatH + 4.0]; sCush.material = fabricMtl
            append parts sCush
            local bCush = sgCushion (w - 6.0) 12.0 (d * 0.75) cfg "Lounge_BackCushion" isBack:true
            rotate bCush (eulerangles (sgJitter -70.0 2.0) 0 0)
            bCush.pos = [0, d / 2.0 - 4.0, seatH + 12.0]
            bCush.material = fabricMtl
            append parts bCush
        )
        #stool:
        (
            local seatH = 45.0
            for i = 1 to 4 do
            (
                local sx = if (mod i 2 == 1) then -1 else 1
                local sy = if i <= 2 then -1 else 1
                local lg = sgFurnLeg #cone seatH ("Stool_Leg_" + i as string) r1:2.2 r2:1.4
                lg.pos = [sx * 13.0, sy * 13.0, 0]
                rotate lg (eulerangles (sy * -5.0) (sx * 5.0) 0)
                lg.material = woodMtl
                append parts lg
            )
            local top = ChamferCyl radius:16.0 height:4.0 fillet:1.2 sides:32 filletsegs:3 name:"Stool_Top"
            top.pos = [0, 0, seatH]; top.material = woodMtl
            append parts top
        )
    )

    sgFinalizeItem parts ("Chair_" + (cfg.style as string) + "_" + (itemType as string)) fabricMtl
)

-------------------------------------------------------------------
-- СТОЛ: #tableDining #tableCoffee #tableSide #tableDesk #tableNightstand
-------------------------------------------------------------------
fn sgBuildTable cfg itemType =
(
    sgSetSeed cfg.seed
    local parts = #()
    local woodMtl = sgMakeWoodMtl cfg.legColor
    local topMtl = sgMakeWoodMtl (color (cfg.legColor.r * 1.15) (cfg.legColor.g * 1.15) (cfg.legColor.b * 1.1)) mtlName:"FurnGen_TableTop"

    fn addFourLegs parts w d h woodMtl prefix inset:6.0 =
    (
        for i = 1 to 4 do
        (
            local sx = if (mod i 2 == 1) then -1 else 1
            local sy = if i <= 2 then -1 else 1
            local lg = sgFurnLeg #cone h (prefix + "_Leg_" + i as string) r1:2.8 r2:1.8
            lg.pos = [sx * (w / 2.0 - inset), sy * (d / 2.0 - inset), 0]
            lg.material = woodMtl
            append parts lg
        )
    )

    case itemType of
    (
        #tableDining:
        (
            local w = amax cfg.width 160.0, d = 90.0, h = 73.0
            addFourLegs parts w d (h - 4.0) woodMtl "Dining" inset:10.0
            local top = sgTableTop false w d 4.5 "Dining_Top"
            top.pos = [0, 0, h - 4.0]; top.material = topMtl
            append parts top
            -- царга (подстолье) для жёсткости и реализма
            local apron = Box width:(w - 24.0) length:(d - 24.0) height:8.0 name:"Dining_Apron"
            apron.pos = [0, 0, h - 13.0]; apron.material = woodMtl
            append parts apron
        )
        #tableCoffee:
        (
            -- круглый кофейный столик
            local r = 50.0, h = 40.0
            addFourLegs parts (r * 1.35) (r * 1.35) (h - 3.5) woodMtl "Coffee" inset:4.0
            local top = sgTableTop true (r * 2) (r * 2) 3.5 "Coffee_Top"
            top.pos = [0, 0, h - 3.5]; top.material = topMtl
            append parts top
        )
        #tableSide:
        (
            -- приставной столик: диск-база + стойка + круглый верх
            local r = 22.0, h = 55.0
            local baseDisc = ChamferCyl radius:16.0 height:2.5 fillet:0.8 sides:36 filletsegs:2 name:"Side_Base"
            baseDisc.material = woodMtl
            append parts baseDisc
            local pole = Cylinder radius:2.2 height:(h - 5.0) sides:18 name:"Side_Pole"
            pole.pos = [0, 0, 2.5]; pole.material = woodMtl
            append parts pole
            local top = sgTableTop true (r * 2) (r * 2) 2.5 "Side_Top"
            top.pos = [0, 0, h - 2.5]; top.material = topMtl
            append parts top
        )
        #tableDesk:
        (
            local w = 130.0, d = 60.0, h = 74.0
            addFourLegs parts w d (h - 4.0) woodMtl "Desk" inset:7.0
            local top = sgTableTop false w d 4.0 "Desk_Top"
            top.pos = [0, 0, h - 4.0]; top.material = topMtl
            append parts top
            -- тумба с ящиками справа
            local drwW = 38.0, drwH = 45.0
            local drawerBox = ChamferBox width:drwW length:(d - 8.0) height:drwH fillet:1.0 name:"Desk_DrawerUnit"
            drawerBox.pos = [w / 2.0 - drwW / 2.0 - 6.0, 0, h - 4.0 - drwH]
            drawerBox.material = woodMtl
            append parts drawerBox
            for j = 1 to 2 do
            (
                local front = ChamferBox width:(drwW - 4.0) length:1.5 height:(drwH / 2.0 - 4.0) fillet:0.5 name:("Desk_DrawerFront_" + j as string)
                front.pos = [drawerBox.pos.x, -(d - 8.0) / 2.0 - 0.8, drawerBox.pos.z + 2.0 + (j - 1) * (drwH / 2.0)]
                front.material = topMtl
                append parts front
                local knob = Sphere radius:1.1 segs:16 name:("Desk_Knob_" + j as string)
                knob.pos = [front.pos.x, front.pos.y - 1.2, front.pos.z + (drwH / 2.0 - 4.0) / 2.0]
                knob.material = sgMakeMetalMtl (color 190 160 100) 0.25
                append parts knob
            )
        )
        #tableNightstand:
        (
            local w = 45.0, d = 40.0, h = 50.0, legH = 12.0
            addFourLegs parts w d legH woodMtl "Night" inset:5.0
            local body = ChamferBox width:w length:d height:(h - legH) fillet:1.2 name:"Night_Body"
            sgSetChamferSegs body 3 2 2
            body.pos = [0, 0, legH]; body.material = woodMtl
            append parts body
            local front = ChamferBox width:(w - 6.0) length:1.5 height:((h - legH) / 2.0 - 5.0) fillet:0.5 name:"Night_DrawerFront"
            front.pos = [0, -d / 2.0 - 0.8, legH + (h - legH) / 2.0]
            front.material = topMtl
            append parts front
            local knob = Sphere radius:1.2 segs:16 name:"Night_Knob"
            knob.pos = [0, front.pos.y - 1.3, front.pos.z + ((h - legH) / 2.0 - 5.0) / 2.0]
            knob.material = sgMakeMetalMtl (color 190 160 100) 0.25
            append parts knob
        )
    )

    sgFinalizeItem parts ("Table_" + (cfg.style as string) + "_" + (itemType as string)) woodMtl
)

-------------------------------------------------------------------
-- ДЕКОР: #pouf #rug #floorLamp #bookshelf #tvConsole
-------------------------------------------------------------------
fn sgBuildDecor cfg itemType =
(
    sgSetSeed cfg.seed
    local parts = #()
    local woodMtl = sgMakeWoodMtl cfg.legColor
    local fabricMtl = sgMakeFabricMtl cfg

    case itemType of
    (
        #pouf:
        (
            local r = 26.0, h = 36.0
            local p = ChamferCyl radius:r height:h fillet:(h * 0.28) sides:36 filletsegs:4 name:"Pouf_Body"
            addModifier p (Push Push_Value:(h * 0.05 * cfg.cushionSoftness + 0.5))
            addModifier p (Noisemodifier scale:(h * 0.9) fractal:true \
                strength:[r * 0.05 * cfg.cushionSoftness, r * 0.05 * cfg.cushionSoftness, h * 0.06 * cfg.cushionSoftness] \
                seed:(sgRandI 1 99999))
            addModifier p (TurboSmooth iterations:2)
            addModifier p (Uvwmap maptype:4 width:50 length:50 height:50)
            p.material = fabricMtl
            append parts p
            if cfg.piping then
            (
                local ring = Torus radius1:(r * 0.96) radius2:0.7 segs:40 name:"Pouf_Piping"
                ring.pos = [0, 0, h * 0.55]
                ring.material = sgMakePipingMtl cfg fabricMtl
                append parts ring
            )
        )
        #rug:
        (
            local w = amax cfg.width 200.0, d = 140.0
            local r = ChamferBox width:w length:d height:1.4 fillet:0.5 name:"Rug"
            sgSetChamferSegs r 12 2 1
            addModifier r (Noisemodifier scale:35.0 fractal:true strength:[0, 0, 0.5] seed:(sgRandI 1 99999))
            addModifier r (TurboSmooth iterations:1)
            addModifier r (Uvwmap maptype:4 width:80 length:80 height:80)
            r.material = fabricMtl
            append parts r
        )
        #floorLamp:
        (
            local metalMtl = sgMakeMetalMtl (color 45 45 45) 0.3
            local base = ChamferCyl radius:15.0 height:2.5 fillet:0.8 sides:36 filletsegs:2 name:"Lamp_Base"
            base.material = metalMtl
            append parts base
            local pole = Cylinder radius:1.1 height:145.0 sides:16 name:"Lamp_Pole"
            pole.pos = [0, 0, 2.5]; pole.material = metalMtl
            append parts pole
            local shade = Cone radius1:22.0 radius2:15.0 height:30.0 sides:36 name:"Lamp_Shade"
            shade.pos = [0, 0, 140.0]
            shade.material = sgMakeFlatMtl (sgPick #(color 235 230 220, cfg.fabricColor)) 0.7 mtlName:"FurnGen_Shade"
            append parts shade
        )
        #bookshelf:
        (
            local w = 90.0, d = 30.0, h = 180.0, boardT = 3.0
            local shelfCount = 5
            -- боковины, верх, низ, задник
            local sideL = Box width:boardT length:d height:h name:"Shelf_Side_L"
            sideL.pos = [-(w / 2.0 - boardT / 2.0), 0, 0]; sideL.material = woodMtl
            append parts sideL
            local sideR = copy sideL; sideR.name = "Shelf_Side_R"
            sideR.pos = [w / 2.0 - boardT / 2.0, 0, 0]
            append parts sideR
            local backP = Box width:w length:1.2 height:h name:"Shelf_Back"
            backP.pos = [0, d / 2.0 - 0.6, 0]; backP.material = woodMtl
            append parts backP
            -- полки + СЛУЧАЙНЫЕ КНИГИ
            local bookPalette = #(color 140 60 50, color 60 90 120, color 90 110 80, color 190 170 140, color 50 50 55, color 170 120 60)
            local bookMtls = for c in bookPalette collect sgMakeFlatMtl c 0.6 mtlName:("FurnGen_Book_" + ((random 1 9999) as string))
            local shelfGap = h / shelfCount
            for s = 0 to shelfCount do
            (
                local sh = Box width:(w - boardT * 2) length:d height:boardT name:("Shelf_Board_" + s as string)
                sh.pos = [0, 0, s * shelfGap - (if s == shelfCount then boardT else 0)]
                sh.material = woodMtl
                append parts sh
                -- книги на полке (кроме самой верхней доски)
                if s < shelfCount then
                (
                    local bx = -(w / 2.0) + boardT + 2.0
                    local shelfTop = s * shelfGap + boardT
                    while bx < (w / 2.0 - boardT - 8.0) and (random 1.0 10.0) > 1.5 do
                    (
                        local bw = sgRandF 2.0 4.5
                        local bh = sgRandF (shelfGap * 0.45) (shelfGap * 0.8)
                        local bd = sgRandF (d * 0.55) (d * 0.8)
                        local book = Box width:bw length:bd height:bh name:(uniquename "Shelf_Book")
                        book.pos = [bx + bw / 2.0, sgJitter 0.0 1.5, shelfTop]
                        rotate book (eulerangles 0 0 (sgJitter 0.0 2.0))
                        book.material = sgPick bookMtls
                        append parts book
                        bx += bw + (sgRandF 0.1 1.2)
                        -- иногда пропуск (стопка или пустое место)
                        if (random 1 10) > 8 then bx += sgRandF 6.0 14.0
                    )
                )
            )
        )
        #tvConsole:
        (
            local w = 160.0, d = 40.0, h = 45.0, legH = 11.0
            for i = 1 to 4 do
            (
                local sx = if (mod i 2 == 1) then -1 else 1
                local sy = if i <= 2 then -1 else 1
                local lg = sgFurnLeg #cone legH ("TV_Leg_" + i as string) r1:2.6 r2:1.6
                lg.pos = [sx * (w / 2.0 - 8.0), sy * (d / 2.0 - 6.0), 0]
                lg.material = woodMtl
                append parts lg
            )
            local body = ChamferBox width:w length:d height:(h - legH) fillet:1.5 name:"TV_Body"
            sgSetChamferSegs body 4 2 2
            body.pos = [0, 0, legH]; body.material = woodMtl
            append parts body
            -- 2 дверцы-фасада
            for j = 1 to 2 do
            (
                local front = ChamferBox width:(w / 2.0 - 5.0) length:1.5 height:(h - legH - 6.0) fillet:0.6 name:("TV_Door_" + j as string)
                front.pos = [(if j == 1 then -1 else 1) * (w / 4.0), -d / 2.0 - 0.8, legH + (h - legH) / 2.0]
                front.material = sgMakeWoodMtl (color (cfg.legColor.r * 1.2) (cfg.legColor.g * 1.2) (cfg.legColor.b * 1.15)) mtlName:"FurnGen_TVDoor"
                append parts front
            )
        )
    )

    sgFinalizeItem parts ("Decor_" + (cfg.style as string) + "_" + (itemType as string)) fabricMtl
)

-------------------------------------------------------------------
-- ROOM SET: целая гостиная одной кнопкой
-- Диван + ковёр + кофейный столик + лаунж-кресло + торшер +
-- приставной столик + книжный шкаф. Все в одном стиле и палитре.
-------------------------------------------------------------------
fn sgBuildRoomSet cfg =
(
    local items = #()
    local baseSeed = cfg.seed

    -- диван (лицом к -Y)
    cfg.sofaType = #straight
    cfg.seed = baseSeed
    local sofa = sgBuildSofa cfg
    sofa.pos = [0, 90, 0]
    append items sofa

    -- ковёр перед диваном
    cfg.seed = baseSeed + 1
    local rug = sgBuildDecor cfg #rug
    rug.pos = [0, -35, 0]
    append items rug

    -- кофейный столик на ковре
    cfg.seed = baseSeed + 2
    local coffee = sgBuildTable cfg #tableCoffee
    coffee.pos = [0, -35, 0]
    append items coffee

    -- лаунж-кресло сбоку, повёрнуто к столику
    cfg.seed = baseSeed + 3
    local lounge = sgBuildChair cfg #chairLounge
    lounge.pos = [-150, -50, 0]
    rotate lounge (eulerangles 0 0 -55)
    append items lounge

    -- пуф с другой стороны
    cfg.seed = baseSeed + 4
    local pouf = sgBuildDecor cfg #pouf
    pouf.pos = [130, -70, 0]
    append items pouf

    -- торшер за креслом
    cfg.seed = baseSeed + 5
    local lamp = sgBuildDecor cfg #floorLamp
    lamp.pos = [-185, 40, 0]
    append items lamp

    -- приставной столик у дивана
    cfg.seed = baseSeed + 6
    local side = sgBuildTable cfg #tableSide
    side.pos = [135, 75, 0]
    append items side

    -- книжный шкаф у "стены" (за диваном, сбоку)
    cfg.seed = baseSeed + 7
    local shelf = sgBuildDecor cfg #bookshelf
    shelf.pos = [190, 140, 0]
    append items shelf

    cfg.seed = baseSeed
    local grp = group items name:(uniquename ("RoomSet_" + (cfg.style as string)))
    (sgGetLayer "SofaGen_Furniture").addNode grp
    format "FurnGen: built room set '%' (% items)\n" grp.name items.count
    grp
)

-------------------------------------------------------------------
-- ДИСПЕТЧЕР: единая точка входа для UI
-------------------------------------------------------------------
fn sgBuildItem cfg category itemType =
(
    case category of
    (
        #sofa:    ( cfg = sgApplyType cfg itemType; sgBuildSofa cfg )
        #bed:     ( sgBuildBed cfg itemType )
        #chair:   ( sgBuildChair cfg itemType )
        #table:   ( sgBuildTable cfg itemType )
        #decor:   ( sgBuildDecor cfg itemType )
        #roomset: ( sgBuildRoomSet cfg )
        default:  ( cfg = sgApplyType cfg itemType; sgBuildSofa cfg )
    )
)

format "FurnGen Furniture module loaded (beds / chairs / tables / decor / room set)\n"
