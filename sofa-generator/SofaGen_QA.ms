/*
    SofaGen_QA.ms
    -------------
    Автоматический контроль качества после генерации:
    геометрия, материалы, масштаб, именование, готовность к рендеру.
*/

-- Рекурсивный сбор всех геометрических нод группы (включая child-ноды
-- вроде валика #pillow-подлокотника и вложенные группы)
fn sgCollectParts node arr =
(
    for c in node.children do
    (
        if not (isGroupHead c) then append arr c
        sgCollectParts c arr
    )
    arr
)

fn sgValidateSofa grp =
(
    local report = #()
    local warnings = 0

    if grp == undefined or not isValidNode grp then
        return #("FAIL: группа не создана")

    -- 0. Системные единицы (вся геометрия рассчитана в см)
    if units.SystemType != #Centimeters then
        ( append report ("WARN: system units = " + units.SystemType as string + ", рекомендуется Centimeters"); warnings += 1 )

    -- 1. Габариты (санити-чек масштаба, см)
    local bb = grp.max - grp.min
    if bb.x < 60 or bb.x > 600 then
        ( append report ("WARN: подозрительная ширина: " + bb.x as string + " cm"); warnings += 1 )
    if bb.z < 40 or bb.z > 150 then
        ( append report ("WARN: подозрительная высота: " + bb.z as string + " cm"); warnings += 1 )

    -- 2. Проверка каждой части (рекурсивно по всей иерархии)
    local allParts = sgCollectParts grp #()
    local partCount = 0
    for obj in allParts do
    (
        partCount += 1

        -- материал
        if obj.material == undefined then
            ( append report ("FAIL: нет материала: " + obj.name); warnings += 1 )

        -- геометрия без ошибок (пустые меши, degenerate)
        if superclassof obj == GeometryClass then
        (
            local tm = snapshotAsMesh obj
            if tm.numverts == 0 or tm.numfaces == 0 then
                ( append report ("FAIL: пустая геометрия: " + obj.name); warnings += 1 )
            delete tm
        )

        -- именование
        if matchPattern obj.name pattern:"Box*" or \
           matchPattern obj.name pattern:"ChamferBox0*" or \
           matchPattern obj.name pattern:"Object*" then
            ( append report ("WARN: дефолтное имя: " + obj.name); warnings += 1 )
    )

    if partCount == 0 then
        ( append report "FAIL: в группе нет объектов"; warnings += 1 )

    -- 3. Итог
    if warnings == 0 then
        append report ("OK: " + partCount as string + " частей, материалы и геометрия валидны, готово к рендеру")
    else
        insertItem ("Проверено частей: " + partCount as string + ", замечаний: " + warnings as string) report 1

    for line in report do format "SofaGen QA: %\n" line
    report
)
