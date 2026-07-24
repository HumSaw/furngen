/*
    SofaGenerator.ms — ГЛАВНЫЙ ФАЙЛ ЗАПУСКА
    ========================================
    Процедурный генератор премиальных диванов
    для 3ds Max + Corona Renderer.

    ЗАПУСК:
        1. Положите все файлы SofaGen_*.ms в одну папку с этим файлом.
        2. В 3ds Max: Scripting > Run Script > SofaGenerator.ms
        3. Откроется панель генератора.

    Работает и без Corona (fallback на Physical Material).
*/

(
    local dir = getFilenamePath (getThisScriptFilename())

    local modules = #(
        "SofaGen_Core.ms",
        "SofaGen_Geometry.ms",
        "SofaGen_Materials.ms",
        "SofaGen_Assembly.ms",
        "SofaGen_QA.ms",
        "SofaGen_UI.ms"
    )

    local ok = true
    for m in modules do
    (
        local f = dir + m
        if doesFileExist f then
            fileIn f
        else
        (
            format "SofaGen ERROR: module not found: %\n" f
            ok = false
        )
    )

    if ok then
    (
        sgOpenUI()
        format "SofaGen % ready. Units: cm recommended.\n" SofaGen_Version
    )
    else
        messageBox "SofaGen: не найдены модули. Все файлы SofaGen_*.ms должны лежать рядом с SofaGenerator.ms" title:"SofaGen"
)
