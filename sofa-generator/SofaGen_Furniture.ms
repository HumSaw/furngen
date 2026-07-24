/*
    SofaGen_Furniture.ms  (FurnGen v2.0.1)
    --------------------------------------
    Кровати, стулья, столы, декор и Room Set.
    Переиспользует Core (конфиг, стили, RNG), Geometry (мягкие блоки,
    подушки), Materials (ткань, дерево, металл, постель).

    ВАЖНО (исправления v2.0.1):
    - каждый предмет использует СВОИ габариты, cfg.width больше
      не раздувает кровати/столы/декор
    - одна декларация local на строку, многострочные case —
      надёжный парсинг MAXScript
    - материал назначается КАЖДОЙ детали в момент создания
    - все fillet защищены от превышения размеров (см. Geometry)

    Система координат едина с диванами:
        X — ширина, Y — глубина (перед = -Y), Z — высота (пол = 0), см.
*/

-------------------------------------------------------------------
-- Финализация: материалы-страховка + слой + группа
-------------------------------------------------------------------
fn sgFinalizeItem parts grpName defaultMtl =
(
    local lay = sgGetLayer "SofaGen_Furniture"
    for p in parts do
    (
        if p.material == undefined then p.material = defaultMtl
        -- wirecolor от материала: цвет виден даже в режиме "Object Color"
        p.wirecolor = sgMtlColor p.material (color 150 150 150)
        lay.addNode p
        for ch in p.children do
        (
            if ch.material == undefined then ch.material = p.material
            ch.wirecolor = sgMtlColor ch.material (color 150 150 150)
            lay.addNode ch
        )
    )
    local grp = group parts name:(uniquename grpName)
    lay.addNode grp
    format "FurnGen: built '%' (% parts)\n" grp.name parts.count
    grp
)

-------------------------------------------------------------------
-- Ножка мебели (конус / цилиндр / брус)
-------------------------------------------------------------------
fn sgFurnLeg legStyle h partName r1:2.4 r2:1.4 =
(
    local lg
    case legStyle of
    (
        #cone:     ( lg = Cone radius1:r1 radius2:r2 height:h sides:18 name:partName )
        #cylinder: ( lg = Cylinder radius:(r1 * 0.8) height:h sides:18 name:partName )
        #block:    ( lg = Box width:(r1 * 2.2) length:(r1 * 2.2) height:h name:partName )
        default:   ( lg = Cone radius1:r1 radius2:r2 height:h sides:18 name:partName )
    )
    lg
)

-------------------------------------------------------------------
-- 4 ножки по углам (mtl назначается сразу)
-------------------------------------------------------------------
fn sgFourLegs parts w d h legMtl prefix inset:6.0 splay:0.0 =
(
    for i = 1 to 4 do
    (
        local sx = if (mod i 2 == 1) then -1 else 1
        local sy = if i <= 2 then -1 else 1
        local lg = sgFurnLeg #cone h (prefix + "_Leg_" + i as string) r1:2.8 r2:1.8
        lg.pos = [sx * (w / 2.0 - inset), sy * (d / 2.0 - inset), 0]
        if splay != 0.0 then rotate lg (eulerangles (sy * -splay) (sx * splay) 0)
        lg.material = legMtl
        append parts lg
    )
)

-------------------------------------------------------------------
-- Столешница: прямоугольная или круглая, с фаской
-------------------------------------------------------------------
fn sgTableTop isRound w d thick partName =
(
    local t
    if isRound then
        t = ChamferCyl radius:(w / 2.0) height:thick fillet:(thick * 0.3) sides:48 filletsegs:3 name:partName
    else
    (
        t = ChamferBox width:w length:d height:thick fillet:(thick * 0.28) name:partName
        sgSetChamferSegs t 4 3 2
    )
    t
)

-------------------------------------------------------------------
-- КРОВАТЬ: #bedSingle #bedDouble #bedKing #bedCanopy
-- Габариты фиксированы типом — cfg.width НЕ влияет.
-------------------------------------------------------------------
fn sgBuildBed cfg itemType =
(
    sgSetSeed cfg.seed
    local parts = #()

    local mattW = 160.0
    case itemType of
    (
        #bedSingle: ( mattW = 90.0 )
        #bedDouble: ( mattW = 160.0 )
        #bedKing:   ( mattW = 200.0 )
        #bedCanopy: ( mattW = 180.0 )
    )
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
    frame.pos = [0, 0, legH]
    frame.material = fabricMtl
    append parts frame

    -- МАТРАС (белый, мягкий)
    local matt = sgSoftBlock mattW mattL mattH 6.0 cfg "Bed_Mattress" softness:0.55
    matt.pos = [0, 0, frameTop]
    matt.material = beddingMtl
    append parts matt

    -- ИЗГОЛОВЬЕ (мягкое, у +Y)
    local hbH = 65.0
    if itemType == #bedCanopy then hbH = 90.0
    local hb = sgSoftBlock (mattW + 14.0) 12.0 hbH 4.5 cfg "Bed_Headboard" softness:0.45
    hb.pos = [0, mattL / 2.0 + 8.0, legH]
    hb.material = fabricMtl
    append parts hb

    -- ОДЕЯЛО: нижние 2/3 кровати, драпировка двойным Noise
    local blW = mattW + 22.0
    local blL = mattL * 0.62
    local bl = ChamferBox width:blW length:blL height:5.0 fillet:2.0 name:"Bed_Blanket"
    sgSetChamferSegs bl 12 3 2
    addModifier bl (Noisemodifier scale:28.0 fractal:true strength:[2.0, 2.5, 3.5] seed:(sgRandI 1 99999))
    addModifier bl (Noisemodifier scale:7.0 fractal:true strength:[0.6, 0.6, 1.2] seed:(sgRandI 1 99999))
    addModifier bl (TurboSmooth iterations:2)
    addModifier bl (Uvwmap maptype:4 width:60 length:60 height:60)
    bl.pos = [0, -mattL / 2.0 + blL / 2.0 - 3.0, frameTop + mattH - 2.0]
    bl.material = blanketMtl
    append parts bl

    -- ПОДУШКИ у изголовья
    local pilCount = 1
    if mattW >= 140.0 then pilCount = 2
    local pilW = (mattW - 12.0) / pilCount
    for i = 1 to pilCount do
    (
        local px = -mattW / 2.0 + 6.0 + pilW / 2.0 + (i - 1) * pilW
        local pil = sgCushion (pilW - 6.0) 42.0 15.0 cfg ("Bed_Pillow_" + i as string)
        rotate pil (eulerangles (sgJitter -18.0 5.0) 0 (sgJitter 0.0 3.0))
        pil.pos = [sgJitter px 1.5, mattL / 2.0 - 26.0, frameTop + mattH + 4.0]
        pil.material = beddingMtl
        append parts pil
    )
    -- декоративная малая подушка спереди (широкие кровати)
    if pilCount == 2 then
    (
        local dp = sgCushion 40.0 30.0 12.0 cfg "Bed_DecoPillow"
        rotate dp (eulerangles (sgJitter -25.0 6.0) 0 (sgJitter 0.0 8.0))
        dp.pos = [sgJitter 0.0 10.0, mattL / 2.0 - 52.0, frameTop + mattH + 3.0]
        dp.material = fabricMtl
        append parts dp
    )

    -- НОЖКИ
    sgFourLegs parts (mattW + 8.0) (mattL + 6.0) legH woodMtl "Bed" inset:4.0

    -- БАЛДАХИН: 4 стойки + верхняя рама
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
        local railF = Box width:(mattW + 14.0) length:4.0 height:4.0 name:"Bed_CanopyRail_F"
        railF.pos = [0, -(mattL / 2.0 + 4.0), postH]
        railF.material = woodMtl
        append parts railF
        local railB = Box width:(mattW + 14.0) length:4.0 height:4.0 name:"Bed_CanopyRail_B"
        railB.pos = [0, mattL / 2.0 + 4.0, postH]
        railB.material = woodMtl
        append parts railB
        local railL = Box width:4.0 length:(mattL + 12.0) height:4.0 name:"Bed_CanopyRail_L"
        railL.pos = [-(mattW / 2.0 + 5.0), 0, postH]
        railL.material = woodMtl
        append parts railL
        local railR = Box width:4.0 length:(mattL + 12.0) height:4.0 name:"Bed_CanopyRail_R"
        railR.pos = [mattW / 2.0 + 5.0, 0, postH]
        railR.material = woodMtl
        append parts railR
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
            local seatH = 45.0
            local seatW = 45.0
            local seatD = 45.0
            -- ножки: задние выше, переходят в спинку
            for i = 1 to 4 do
            (
                local sx = if (mod i 2 == 1) then -1 else 1
                local isBack = (i > 2)
                local h = seatH
                if isBack then h = 88.0
                local sy = -1
                if isBack then sy = 1
                local lg = sgFurnLeg #cone h ("Chair_Leg_" + i as string) r1:2.2 r2:1.5
                lg.pos = [sx * (seatW / 2.0 - 3.0), sy * (seatD / 2.0 - 3.0), 0]
                if isBack then rotate lg (eulerangles 4.0 0 0)
                lg.material = woodMtl
                append parts lg
            )
            -- сиденье: деревянная основа + мягкая подушка
            local sBase = sgTableTop false seatW seatD 4.0 "Chair_SeatBase"
            sBase.pos = [0, 0, seatH]
            sBase.material = woodMtl
            append parts sBase
            local sCush = sgCushion (seatW - 4.0) (seatD - 4.0) 6.5 cfg "Chair_SeatCushion"
            sCush.pos = [0, 0, seatH + 4.0]
            sCush.material = fabricMtl
            append parts sCush
            -- спинка: мягкая панель между задними ножками
            local back = sgSoftBlock (seatW - 6.0) 5.0 30.0 2.2 cfg "Chair_Back" softness:0.4
            back.pos = [0, seatD / 2.0 + 1.0, 56.0]
            rotate back (eulerangles 4.0 0 0)
            back.material = fabricMtl
            append parts back
        )
        #chairBar:
        (
            local seatH = 75.0
            sgFourLegs parts 32.0 32.0 seatH woodMtl "BarStool" inset:2.0 splay:4.0
            -- подножка-кольцо
            local ring = Torus radius1:16.5 radius2:0.9 segs:32 name:"BarStool_FootRing"
            ring.pos = [0, 0, 24.0]
            ring.material = sgMakeMetalMtl (color 40 40 40) 0.3
            append parts ring
            -- круглое мягкое сиденье
            local seat = ChamferCyl radius:17.0 height:9.0 fillet:3.6 sides:32 filletsegs:3 name:"BarStool_Seat"
            addModifier seat (Push Push_Value:0.6)
            addModifier seat (Noisemodifier scale:10.0 fractal:true strength:[0.3, 0.3, 0.7] seed:(sgRandI 1 99999))
            addModifier seat (TurboSmooth iterations:2)
            addModifier seat (Uvwmap maptype:4 width:50 length:50 height:50)
            seat.pos = [0, 0, seatH]
            seat.material = fabricMtl
            append parts seat
        )
        #chairLounge:
        (
            -- низкое широкое лаунж-кресло
            local seatH = 38.0
            local w = 65.0
            local d = 75.0
            sgFourLegs parts w d seatH woodMtl "Lounge" inset:5.0
            local sFrame = sgTableTop false w d 5.0 "Lounge_Frame"
            sFrame.pos = [0, 0, seatH]
            sFrame.material = woodMtl
            append parts sFrame
            local sCush = sgCushion (w - 6.0) (d - 8.0) 14.0 cfg "Lounge_SeatCushion"
            sCush.pos = [0, -2.0, seatH + 4.0]
            sCush.material = fabricMtl
            append parts sCush
            -- спинка: подушка строится ЛЁЖА (w x длина x толщина),
            -- затем откидывается назад до почти вертикали
            local bCush = sgCushion (w - 6.0) (d * 0.72) 12.0 cfg "Lounge_BackCushion" isBack:true
            rotate bCush (eulerangles (sgJitter 72.0 2.0) 0 0)
            bCush.pos = [0, d / 2.0 - 6.0, seatH + 12.0]
            bCush.material = fabricMtl
            append parts bCush
        )
        #stool:
        (
            local seatH = 45.0
            sgFourLegs parts 30.0 30.0 seatH woodMtl "Stool" inset:2.0 splay:5.0
            local top = ChamferCyl radius:16.0 height:4.0 fillet:1.2 sides:32 filletsegs:3 name:"Stool_Top"
            top.pos = [0, 0, seatH]
            top.material = woodMtl
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
    local topCol = color (amin (cfg.legColor.r * 1.15) 255.0) (amin (cfg.legColor.g * 1.15) 255.0) (amin (cfg.legColor.b * 1.1) 255.0)
    local topMtl = sgMakeWoodMtl topCol mtlName:"FurnGen_TableTop"
    local brassMtl = sgMakeMetalMtl (color 190 160 100) 0.25 mtlName:"FurnGen_Brass"

    case itemType of
    (
        #tableDining:
        (
            local w = 180.0
            local d = 90.0
            local h = 73.0
            sgFourLegs parts w d (h - 4.0) woodMtl "Dining" inset:10.0
            local top = sgTableTop false w d 4.5 "Dining_Top"
            top.pos = [0, 0, h - 4.0]
            top.material = topMtl
            append parts top
            -- царга (подстолье)
            local apron = Box width:(w - 26.0) length:(d - 26.0) height:8.0 name:"Dining_Apron"
            apron.pos = [0, 0, h - 13.0]
            apron.material = woodMtl
            append parts apron
        )
        #tableCoffee:
        (
            local r = 50.0
            local h = 40.0
            sgFourLegs parts (r * 1.35) (r * 1.35) (h - 3.5) woodMtl "Coffee" inset:4.0
            local top = sgTableTop true (r * 2) (r * 2) 3.5 "Coffee_Top"
            top.pos = [0, 0, h - 3.5]
            top.material = topMtl
            append parts top
        )
        #tableSide:
        (
            local r = 22.0
            local h = 55.0
            local baseDisc = ChamferCyl radius:16.0 height:2.5 fillet:0.8 sides:36 filletsegs:2 name:"Side_Base"
            baseDisc.material = woodMtl
            append parts baseDisc
            local pole = Cylinder radius:2.2 height:(h - 5.0) sides:18 name:"Side_Pole"
            pole.pos = [0, 0, 2.5]
            pole.material = woodMtl
            append parts pole
            local top = sgTableTop true (r * 2) (r * 2) 2.5 "Side_Top"
            top.pos = [0, 0, h - 2.5]
            top.material = topMtl
            append parts top
        )
        #tableDesk:
        (
            local w = 130.0
            local d = 60.0
            local h = 74.0
            sgFourLegs parts w d (h - 4.0) woodMtl "Desk" inset:7.0
            local top = sgTableTop false w d 4.0 "Desk_Top"
            top.pos = [0, 0, h - 4.0]
            top.material = topMtl
            append parts top
            -- тумба с ящиками справа
            local drwW = 38.0
            local drwH = 45.0
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
                knob.material = brassMtl
                append parts knob
            )
        )
        #tableNightstand:
        (
            local w = 45.0
            local d = 40.0
            local h = 50.0
            local legH = 12.0
            sgFourLegs parts w d legH woodMtl "Night" inset:5.0
            local body = ChamferBox width:w length:d height:(h - legH) fillet:1.2 name:"Night_Body"
            sgSetChamferSegs body 3 2 2
            body.pos = [0, 0, legH]
            body.material = woodMtl
            append parts body
            local front = ChamferBox width:(w - 6.0) length:1.5 height:((h - legH) / 2.0 - 5.0) fillet:0.5 name:"Night_DrawerFront"
            front.pos = [0, -d / 2.0 - 0.8, legH + (h - legH) / 2.0]
            front.material = topMtl
            append parts front
            local knob = Sphere radius:1.2 segs:16 name:"Night_Knob"
            knob.pos = [0, front.pos.y - 1.3, front.pos.z + ((h - legH) / 2.0 - 5.0) / 2.0]
            knob.material = brassMtl
            append parts knob
        )
    )

    sgFinalizeItem parts ("Table_" + (cfg.style as string) + "_" + (itemType as string)) woodMtl
)

-------------------------------------------------------------------
-- ХРАНЕНИЕ: #wardrobe #dresser
-------------------------------------------------------------------
fn sgBuildStorage cfg itemType =
(
    sgSetSeed cfg.seed
    local parts = #()
    local woodMtl = sgMakeWoodMtl cfg.legColor
    local doorCol = color (amin (cfg.legColor.r * 1.2) 255.0) (amin (cfg.legColor.g * 1.2) 255.0) (amin (cfg.legColor.b * 1.15) 255.0)
    local doorMtl = sgMakeWoodMtl doorCol mtlName:"FurnGen_StorageDoor"
    local brassMtl = sgMakeMetalMtl (color 190 160 100) 0.25 mtlName:"FurnGen_Brass"

    case itemType of
    (
        #wardrobe:
        (
            local w = 110.0
            local d = 60.0
            local h = 200.0
            local legH = 6.0
            sgFourLegs parts w d legH woodMtl "Wardrobe" inset:5.0
            local body = ChamferBox width:w length:d height:(h - legH) fillet:1.2 name:"Wardrobe_Body"
            sgSetChamferSegs body 4 2 2
            body.pos = [0, 0, legH]
            body.material = woodMtl
            append parts body
            for j = 1 to 2 do
            (
                local jx = -1
                if j == 2 then jx = 1
                local door = ChamferBox width:(w / 2.0 - 3.0) length:1.6 height:(h - legH - 6.0) fillet:0.6 name:("Wardrobe_Door_" + j as string)
                door.pos = [jx * (w / 4.0), -d / 2.0 - 0.9, legH + 3.0]
                door.material = doorMtl
                append parts door
                -- вертикальная ручка-рейлинг у центрального стыка дверей
                local handle = Cylinder radius:0.8 height:16.0 sides:14 name:("Wardrobe_Handle_" + j as string)
                handle.pos = [jx * 6.0, -d / 2.0 - 2.8, h * 0.5]
                handle.material = brassMtl
                append parts handle
            )
        )
        #dresser:
        (
            local w = 100.0
            local d = 45.0
            local h = 80.0
            local legH = 10.0
            sgFourLegs parts w d legH woodMtl "Dresser" inset:6.0
            local body = ChamferBox width:w length:d height:(h - legH) fillet:1.2 name:"Dresser_Body"
            sgSetChamferSegs body 4 2 2
            body.pos = [0, 0, legH]
            body.material = woodMtl
            append parts body
            local drawerH = (h - legH - 8.0) / 3.0
            for j = 1 to 3 do
            (
                local front = ChamferBox width:(w - 8.0) length:1.5 height:(drawerH - 3.0) fillet:0.5 name:("Dresser_Front_" + j as string)
                front.pos = [0, -d / 2.0 - 0.8, legH + 4.0 + (j - 1) * drawerH]
                front.material = doorMtl
                append parts front
                for k = 1 to 2 do
                (
                    local kx = -1
                    if k == 2 then kx = 1
                    local knob = Sphere radius:1.1 segs:16 name:(uniquename "Dresser_Knob")
                    knob.pos = [kx * (w / 4.0), -d / 2.0 - 2.2, front.pos.z + (drawerH - 3.0) / 2.0]
                    knob.material = brassMtl
                    append parts knob
                )
            )
        )
    )

    sgFinalizeItem parts ("Storage_" + (cfg.style as string) + "_" + (itemType as string)) woodMtl
)

-------------------------------------------------------------------
-- ДЕКОР: #pouf #rug #floorLamp #bookshelf #tvConsole #plant #mirror
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
            local r = 26.0
            local h = 36.0
            local p = ChamferCyl radius:r height:h fillet:(h * 0.26) sides:36 filletsegs:4 name:"Pouf_Body"
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
                local ring = Torus radius1:(r * 0.98) radius2:0.7 segs:40 name:"Pouf_Piping"
                ring.pos = [0, 0, h * 0.55]
                ring.material = sgMakePipingMtl cfg fabricMtl
                append parts ring
            )
        )
        #rug:
        (
            local w = 230.0
            local d = 150.0
            local r = ChamferBox width:w length:d height:1.4 fillet:0.5 name:"Rug"
            sgSetChamferSegs r 12 2 1
            addModifier r (Noisemodifier scale:35.0 fractal:true strength:[0, 0, 0.4] seed:(sgRandI 1 99999))
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
            pole.pos = [0, 0, 2.5]
            pole.material = metalMtl
            append parts pole
            local shadeCol = sgPick #(color 235 230 220, cfg.fabricColor)
            local shade = Cone radius1:22.0 radius2:15.0 height:30.0 sides:36 name:"Lamp_Shade"
            shade.pos = [0, 0, 140.0]
            shade.material = sgMakeFlatMtl shadeCol 0.7 mtlName:"FurnGen_Shade"
            append parts shade
        )
        #bookshelf:
        (
            local w = 90.0
            local d = 30.0
            local h = 180.0
            local boardT = 3.0
            local shelfCount = 5
            local sideL = Box width:boardT length:d height:h name:"Shelf_Side_L"
            sideL.pos = [-(w / 2.0 - boardT / 2.0), 0, 0]
            sideL.material = woodMtl
            append parts sideL
            local sideR = Box width:boardT length:d height:h name:"Shelf_Side_R"
            sideR.pos = [w / 2.0 - boardT / 2.0, 0, 0]
            sideR.material = woodMtl
            append parts sideR
            local backP = Box width:w length:1.2 height:h name:"Shelf_Back"
            backP.pos = [0, d / 2.0 - 0.6, 0]
            backP.material = woodMtl
            append parts backP
            -- полки + случайные книги
            local bookPalette = #(color 140 60 50, color 60 90 120, color 90 110 80, color 190 170 140, color 50 50 55, color 170 120 60)
            local bookMtls = #()
            for c in bookPalette do
                append bookMtls (sgMakeFlatMtl c 0.6 mtlName:(uniquename "FurnGen_Book"))
            local shelfGap = h / shelfCount
            for s = 0 to shelfCount do
            (
                local shZ = s * shelfGap
                if s == shelfCount then shZ = h - boardT
                local sh = Box width:(w - boardT * 2) length:d height:boardT name:("Shelf_Board_" + s as string)
                sh.pos = [0, 0, shZ]
                sh.material = woodMtl
                append parts sh
                -- книги (кроме самой верхней доски)
                if s < shelfCount then
                (
                    local bx = -(w / 2.0) + boardT + 2.0
                    local shelfTop = shZ + boardT
                    local keepGoing = true
                    while keepGoing and bx < (w / 2.0 - boardT - 8.0) do
                    (
                        local bw = sgRandF 2.0 4.5
                        local bh = sgRandF (shelfGap * 0.45) (shelfGap * 0.75)
                        local bd = sgRandF (d * 0.55) (d * 0.8)
                        local book = Box width:bw length:bd height:bh name:(uniquename "Shelf_Book")
                        book.pos = [bx + bw / 2.0, sgJitter 0.0 1.5, shelfTop]
                        rotate book (eulerangles 0 0 (sgJitter 0.0 2.0))
                        book.material = sgPick bookMtls
                        append parts book
                        bx += bw + (sgRandF 0.1 1.2)
                        if (sgRandI 1 10) > 8 then bx += sgRandF 6.0 14.0
                        if (sgRandF 0.0 1.0) < 0.06 then keepGoing = false
                    )
                )
            )
        )
        #plant:
        (
            -- растение в кашпо: горшок + земля + стебли-цилиндры с листьями-сферами
            local potMtl = sgMakeFlatMtl (sgPick #(color 200 195 185, color 90 88 84, color 150 110 85)) 0.55 mtlName:"FurnGen_Pot"
            local soilMtl = sgMakeFlatMtl (color 45 35 28) 0.9 mtlName:"FurnGen_Soil"
            local leafMtl = sgMakeFlatMtl (sgPick #(color 60 100 55, color 45 85 50, color 75 110 60)) 0.5 mtlName:"FurnGen_Leaf"
            local pot = Cone radius1:14.0 radius2:17.0 height:32.0 sides:32 name:"Plant_Pot"
            pot.material = potMtl
            append parts pot
            local soil = Cylinder radius:15.5 height:2.0 sides:28 name:"Plant_Soil"
            soil.pos = [0, 0, 29.0]
            soil.material = soilMtl
            append parts soil
            local stemCount = sgRandI 4 6
            for s = 1 to stemCount do
            (
                local ang = sgRandF 0.0 360.0
                local lean = sgRandF 6.0 22.0
                local stemH = sgRandF 45.0 85.0
                local stem = Cylinder radius:0.5 height:stemH sides:10 name:(uniquename "Plant_Stem")
                stem.pos = [sgJitter 0.0 5.0, sgJitter 0.0 5.0, 30.0]
                rotate stem (eulerangles (lean * (cos (degToRad ang))) (lean * (sin (degToRad ang))) 0)
                stem.material = leafMtl
                append parts stem
                -- листва: сплюснутая сфера на конце стебля
                local leaf = Sphere radius:(sgRandF 7.0 12.0) segs:16 name:(uniquename "Plant_Leaf")
                leaf.pos = stem.pos + [(stemH * 0.9) * (sin (degToRad lean)) * (sin (degToRad ang)), \
                                       (stemH * 0.9) * (sin (degToRad lean)) * (cos (degToRad ang)) * -1.0, \
                                       stemH * 0.9]
                addModifier leaf (Noisemodifier scale:8.0 fractal:true strength:[3.0, 3.0, 4.5] seed:(sgRandI 1 99999))
                scale leaf [1.0, 1.0, 0.72]
                leaf.material = leafMtl
                append parts leaf
            )
        )
        #mirror:
        (
            -- напольное зеркало в раме, слегка прислонено к стене
            local frameMtl = sgMakeMetalMtl (color 190 160 100) 0.3 mtlName:"FurnGen_MirrorFrame"
            local glassMtl = sgMakeMetalMtl (color 220 225 230) 0.02 mtlName:"FurnGen_MirrorGlass"
            local mw = 60.0
            local mh = 170.0
            local frame = ChamferBox width:mw length:3.0 height:mh fillet:1.0 name:"Mirror_Frame"
            sgSetChamferSegs frame 3 2 2
            frame.material = frameMtl
            append parts frame
            local glass = Box width:(mw - 6.0) length:0.6 height:(mh - 6.0) name:"Mirror_Glass"
            glass.pos = [0, -1.6, 3.0]
            glass.material = glassMtl
            append parts glass
            -- наклон к "стене" (прислонено)
            for p in parts do
            (
                rotate p (eulerangles -6.0 0 0)
                p.pos.y += 2.0
            )
        )
        #tvConsole:
        (
            local w = 160.0
            local d = 40.0
            local h = 45.0
            local legH = 11.0
            local doorCol = color (amin (cfg.legColor.r * 1.2) 255.0) (amin (cfg.legColor.g * 1.2) 255.0) (amin (cfg.legColor.b * 1.15) 255.0)
            local doorMtl = sgMakeWoodMtl doorCol mtlName:"FurnGen_TVDoor"
            sgFourLegs parts w d legH woodMtl "TV" inset:8.0
            local body = ChamferBox width:w length:d height:(h - legH) fillet:1.5 name:"TV_Body"
            sgSetChamferSegs body 4 2 2
            body.pos = [0, 0, legH]
            body.material = woodMtl
            append parts body
            for j = 1 to 2 do
            (
                local jx = -1
                if j == 2 then jx = 1
                local front = ChamferBox width:(w / 2.0 - 5.0) length:1.5 height:(h - legH - 6.0) fillet:0.6 name:("TV_Door_" + j as string)
                front.pos = [jx * (w / 4.0), -d / 2.0 - 0.8, legH + 3.0]
                front.material = doorMtl
                append parts front
            )
        )
    )

    sgFinalizeItem parts ("Decor_" + (cfg.style as string) + "_" + (itemType as string)) fabricMtl
)

-------------------------------------------------------------------
-- ROOM SET: целая гостиная одной кнопкой
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
    rotate lounge (eulerangles 0 0 -55)
    lounge.pos = [-150, -50, 0]
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

    -- книжный шкаф у "стены" за диваном
    cfg.seed = baseSeed + 7
    local shelf = sgBuildDecor cfg #bookshelf
    shelf.pos = [190, 140, 0]
    append items shelf

    -- растение у другого края
    cfg.seed = baseSeed + 8
    local plant = sgBuildDecor cfg #plant
    plant.pos = [200, 40, 0]
    append items plant

    cfg.seed = baseSeed
    local grp = group items name:(uniquename ("RoomSet_" + (cfg.style as string)))
    (sgGetLayer "SofaGen_Furniture").addNode grp
    format "FurnGen: built room set '%' (% items)\n" grp.name items.count
    grp
)

-------------------------------------------------------------------
-- BEDROOM SET: спальня одной кнопкой
-------------------------------------------------------------------
fn sgBuildBedroomSet cfg =
(
    local items = #()
    local baseSeed = cfg.seed

    -- кровать (изголовье к +Y — "стене")
    cfg.seed = baseSeed
    local bed = sgBuildBed cfg #bedDouble
    bed.pos = [0, 60, 0]
    append items bed

    -- тумбочки по обе стороны
    cfg.seed = baseSeed + 1
    local ns1 = sgBuildTable cfg #tableNightstand
    ns1.pos = [-120, 130, 0]
    append items ns1
    cfg.seed = baseSeed + 2
    local ns2 = sgBuildTable cfg #tableNightstand
    ns2.pos = [120, 130, 0]
    append items ns2

    -- комод напротив кровати
    cfg.seed = baseSeed + 3
    local dr = sgBuildStorage cfg #dresser
    rotate dr (eulerangles 0 0 180)
    dr.pos = [-30, -160, 0]
    append items dr

    -- шкаф в углу
    cfg.seed = baseSeed + 4
    local wd = sgBuildStorage cfg #wardrobe
    rotate wd (eulerangles 0 0 -90)
    wd.pos = [-200, 40, 0]
    append items wd

    -- ковёр под кроватью (выступает спереди)
    cfg.seed = baseSeed + 5
    local rug = sgBuildDecor cfg #rug
    rug.pos = [0, -20, 0]
    append items rug

    -- табурет-скамья в изножье
    cfg.seed = baseSeed + 6
    local st = sgBuildChair cfg #stool
    st.pos = [0, -70, 0]
    append items st

    -- зеркало у стены + растение
    cfg.seed = baseSeed + 7
    local mir = sgBuildDecor cfg #mirror
    rotate mir (eulerangles 0 0 35)
    mir.pos = [185, 120, 0]
    append items mir
    cfg.seed = baseSeed + 8
    local plant = sgBuildDecor cfg #plant
    plant.pos = [200, -120, 0]
    append items plant

    cfg.seed = baseSeed
    local grp = group items name:(uniquename ("BedroomSet_" + (cfg.style as string)))
    (sgGetLayer "SofaGen_Furniture").addNode grp
    format "FurnGen: built bedroom set '%' (% items)\n" grp.name items.count
    grp
)

-------------------------------------------------------------------
-- ДИСПЕТЧЕР: единая точка входа для UI
-------------------------------------------------------------------
fn sgBuildItem cfg category itemType =
(
    local result = undefined
    case category of
    (
        #sofa:    ( cfg = sgApplyType cfg itemType; result = sgBuildSofa cfg )
        #bed:     ( result = sgBuildBed cfg itemType )
        #chair:   ( result = sgBuildChair cfg itemType )
        #table:   ( result = sgBuildTable cfg itemType )
        #storage: ( result = sgBuildStorage cfg itemType )
        #decor:   ( result = sgBuildDecor cfg itemType )
        #roomset: ( result = sgBuildRoomSet cfg )
        default:  ( cfg = sgApplyType cfg itemType; result = sgBuildSofa cfg )
    )
    result
)

format "FurnGen Furniture module loaded (beds / chairs / tables / decor / room set)\n"
