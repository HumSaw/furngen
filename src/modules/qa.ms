/*
    qa.ms -- automatic post-generation validation
    --------------------------------------------
    Every generated item is checked before it reaches the artist: missing
    materials, empty meshes, default node names, implausible dimensions and
    wrong system units are reported to the panel and the MAXScript Listener.

    Depends on: core.ms
*/

-- Recursively collect every geometry node of a group, including child nodes
-- (for example the bolster parented to a #pillow armrest) and nested groups.
fn fgCollectParts node arr =
(
    for c in node.children do
    (
        if not (isGroupHead c) then append arr c
        fgCollectParts c arr
    )
    arr
)

/*
    Validate a generated group.
    Returns an array of report lines; the LAST line is always the summary,
    which is what the UI shows in its status label.
*/
fn fgValidateItem grp =
(
    local report = #()
    local warnings = 0

    if grp == undefined or not isValidNode grp then
        return #("FAIL: nothing was created")

    -- 1. System units: all geometry is authored in centimeters
    if units.SystemType != #Centimeters then
    (
        append report ("WARN: system units are " + units.SystemType as string + \
            ", Centimeters recommended")
        warnings += 1
    )

    -- 2. Bounding box sanity check. The range spans the whole catalogue,
    -- from a small side table up to a canopy bed or a full room set.
    local bb = grp.max - grp.min
    if bb.x < 20 or bb.x > 650 then
    (
        append report ("WARN: implausible width: " + bb.x as string + " cm")
        warnings += 1
    )
    if bb.z < 1 or bb.z > 260 then
    (
        append report ("WARN: implausible height: " + bb.z as string + " cm")
        warnings += 1
    )

    -- 3. Per-part checks across the whole hierarchy
    local allParts = fgCollectParts grp #()
    local partCount = 0
    local faceCount = 0

    for obj in allParts do
    (
        partCount += 1

        if obj.material == undefined then
        (
            append report ("FAIL: missing material: " + obj.name)
            warnings += 1
        )

        if superclassof obj == GeometryClass then
        (
            local tm = snapshotAsMesh obj
            if tm.numverts == 0 or tm.numfaces == 0 then
            (
                append report ("FAIL: empty geometry: " + obj.name)
                warnings += 1
            )
            faceCount += tm.numfaces
            delete tm
        )

        if matchPattern obj.name pattern:"Box*" or \
           matchPattern obj.name pattern:"ChamferBox0*" or \
           matchPattern obj.name pattern:"Object*" then
        (
            append report ("WARN: default node name: " + obj.name)
            warnings += 1
        )
    )

    if partCount == 0 then
    (
        append report "FAIL: the group contains no objects"
        warnings += 1
    )

    -- 4. Summary always goes last so the UI can read report[report.count]
    local stats = partCount as string + " parts / " + faceCount as string + " tris"
    if warnings == 0 then
        append report ("OK: " + stats + ", render ready")
    else
        append report ("CHECKED: " + stats + ", " + warnings as string + " issue(s) - see Listener")

    for line in report do format "FurnGen QA: %\n" line
    report
)
