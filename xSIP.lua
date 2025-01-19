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
    "codex", -- Added codices.
}

local xSipItems = jarray({})

if xsb then
    sb.logInfo("[xSIP] xClient v" .. xsb.version() .. " detected.")
else
    sb.logInfo("[xSIP] OpenStarbound or similar detected.")
end

for _, ext in ipairs(itemExtensions) do
    local itemPaths = assets.byExtension(ext)
    sb.logInfo("[xSIP] Processing item assets with extension '.%s'...", ext)
    for _, path in ipairs(itemPaths) do
        local status, itemJsonOrError = pcall(assets.json, path)
        local itemJson = jobject{}
        if not status then
            local errorMessage = itemJsonOrError
            sb.logError("[xSIP] Could not process item at path '%s' due to error, skipping.\n  Error: %s",
                path, errorMessage)
            goto continue
        else
            itemJson = itemJsonOrError
        end
        if -- Ignore virtual «items» from Betabound that get converted to actual items when spawned.
            itemJson.builder == "/items/buildscripts/starbound/convert.lua"
            or itemJson.builder == "/items/buildscripts/starbound/convert3.lua"
        then
            goto continue
        end
        itemJson.itemConfig = type(itemJson.itemConfig) == "table" and itemJson.itemConfig or jobject({})
        local directory, fileName = splitPath(path)
        local isCodex = ext == "codex"
        local nameKey = ext == "object" and "objectName" or "itemName"
        local icon = type(itemJson.inventoryIcon) == "string" and itemJson.inventoryIcon
            or (
                type(itemJson.inventoryIcon) == "table"
                    and itemJson.inventoryIcon[1]
                    and itemJson.inventoryIcon[1].image
                or (itemJson.icon or nil)
            )
        local category = isCodex and itemJson.itemConfig.category or itemJson.category
        local itemConfig = jobject({
            path = directory,
            fileName = fileName,
            name = isCodex and (itemJson.id .. "-codex") or itemJson[nameKey] or "perfectlygenericitem",
            rarity = checkRarity(isCodex and itemJson.itemConfig.rarity or itemJson.rarity),
            shortdescription = (itemJson.shortDescription or itemJson.shortdescription or itemJson.title) or "",
            icon = (icon or "/assetmissing.png"):gsub("<directives>", ""),
            race = itemJson.race or itemJson.species or "generic",
            category = (((not icon) and not category) and "other" or category) or (isCodex and "codex" or ext),
        })
        if ext == "head" or ext == "chest" or ext == "legs" or ext == "back" then
            itemConfig.directives = parseColourOptions(itemJson.colorOptions, path)
        end
        table.insert(xSipItems, itemConfig)
        ::continue::
    end
end

table.sort(xSipItems, function(a, b)
    a = a.shortdescription:gsub("(%^.-%;)", ""):gsub(" ", "")
    a = a == "" and a.name or a
    b = b.shortdescription:gsub("(%^.-%;)", ""):gsub(" ", "")
    b = b == "" and b.name or b
    return a < b
end)

sb.logInfo("[xSIP] Adding all items...", ext)

assets.erase("/sipItemDump.json")
assets.add("/sipItemDump.json", xSipItems)
