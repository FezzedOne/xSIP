--- xSIP item post-processor ---

local function contains(array, item)
    for _, v in ipairs(array) do
        if item == v then return true end
    end
    return false
end

local function splitPath(path)
    local lastSlash = path:match("^.*()/")

    if lastSlash then
        local directory = path:sub(1, lastSlash)
        local filename = path:sub(lastSlash + 1)
        return directory, filename
    else
        return "", path
    end
end

local function checkRarity(rawRarity)
    local validRarities = {
        "common",
        "Common",
        "uncommon",
        "Uncommon",
        "rare",
        "Rare",
        "legendary",
        "Legendary",
        "essential",
        "Essential",
    }
    local isValid = false
    for _, vr in ipairs(validRarities) do
        if rawRarity == vr then
            isValid = true
            break
        end
    end
    return isValid and rawRarity or "essential"
end

local function parseColourOptions(colourOptions, path)
    colourOptions = type(colourOptions) == "table" and colourOptions or jarray({})
    local firstEntry = colourOptions[1]
    if firstEntry then
        local directives = "?replace"
        local isEmpty = true
        if type(firstEntry) == "string" then
            isEmpty = false
            directives = firstEntry
        elseif type(firstEntry) == "table" then
            for a, b in pairs(firstEntry) do
                isEmpty = false
                directives = directives .. ";" .. tostring(a) .. "=" .. tostring(b)
            end
        end
        return isEmpty and "" or directives
    else
        return nil
    end
end

local itemExtensions = {
    "object",
    "item",
    "liqitem",
    "matitem",
    "miningtool",
    "flashlight",
    "wiretool",
    "beamaxe",
    "tillingtool",
    "painttool",
    "harvestingtool",
    "head",
    "chest",
    "legs",
    "back",
    "currency",
    "consumable",
    "blueprint",
    "inspectiontool",
    "instrument",
    "thrownitem",
    "unlock",
    "activeitem",
    "augment",
}

local xSipItems = jarray({})

if xsb then
    sb.logInfo("[xSIP] xSB-2 v" .. xsb.version() .. " detected.")
else
    sb.logInfo("[xSIP] OpenStarbound or similar detected.")
end

for _, ext in ipairs(itemExtensions) do
    local itemPaths = assets.byExtension(ext)
    sb.logInfo("[xSIP] Processing item assets with extension '.%s'...", ext)
    for _, path in ipairs(itemPaths) do
        local itemJson = assets.json(path)
        if -- Ignore virtual «items» from Betabound that get converted to actual items when spawned.
            itemJson.builder == "/items/buildscripts/starbound/convert.lua"
            or itemJson.builder == "/items/buildscripts/starbound/convert3.lua"
        then
            goto continue
        end
        local directory, fileName = splitPath(path)
        local nameKey = ext == "object" and "objectName" or "itemName"
        local itemConfig = jobject{
            path = directory,
            fileName = fileName,
            name = itemJson[nameKey] or "perfectlygenericitem",
            rarity = checkRarity(itemJson.rarity),
            shortdescription = (itemJson.shortDescription or itemJson.shortdescription) or "",
            icon = type(itemJson.inventoryIcon) == "string" and itemJson.inventoryIcon or "/assetmissing.png",
            race = itemJson.race or "generic",
            category = itemJson.category or "junk",
        }
        if ext == "head" or ext == "chest" or ext == "legs" or ext == "back" then
            itemConfig.directives = parseColourOptions(itemJson.colorOptions, path)
        end
        table.insert(xSipItems, itemConfig)
        ::continue::
    end
end

sb.logInfo("[xSIP] Adding all items...", ext)

assets.erase("/sipItemDump.json")
assets.add("/sipItemDump.json", xSipItems)
