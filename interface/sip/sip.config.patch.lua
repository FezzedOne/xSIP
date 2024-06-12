function patch(config, _)
    local redHueshift = "?hueshift=-120"
    local redReplace = "?replace;01f23c=f20000;00f23c=f20000;00ae2c=ae0000;009926=990000;04941e=940000;025410=540000"
    local featureButtonReplace = "?replace;00bc2c=009926;006317=009926;00821e=009926"

    local function splitDirectives(path)
        local firstSplitter = path:match("^.-()%?")

        if firstSplitter == 1 then
            return "", path
        elseif firstSplitter then
            local parsedPath = path:sub(1, firstSplitter - 1)
            local directives = path:sub(firstSplitter)
            return parsedPath, directives
        else
            return path, ""
        end
    end

    local background = config.gui.background
    background.fileHeader = background.fileHeader .. redHueshift
    background.fileBody = background.fileBody .. redHueshift
    background.fileFooter = background.fileFooter .. redHueshift

    local detectedClient = (function()
        if xsb then
            return "(xSB-2 v" .. xsb.version() .. ")"
        else
            return "(OpenStarbound)"
        end
    end)()
    config.gui.windowtitle.title = config.gui.windowtitle.title .. " " .. detectedClient

    local printButton = config.gui.sipButtonPrint
    local _, printButtonHoverDirectives = splitDirectives(printButton.hover)
    printButton.base = printButton.base .. redReplace
    printButton.hover = printButton.base .. redReplace .. printButtonHoverDirectives

    local printAmount = config.gui.sipImagePrintAmount
    printAmount.file = printAmount.file .. redReplace

    local lessButton = config.gui.sipButtonPrintAmountLess
    local _, lessButtonHoverDirectives = splitDirectives(lessButton.hover)
    lessButton.base = lessButton.base .. redReplace
    lessButton.hover = lessButton.base .. redReplace .. lessButtonHoverDirectives

    local moreButton = config.gui.sipButtonPrintAmountMore
    local _, moreButtonHoverDirectives = splitDirectives(lessButton.hover)
    moreButton.base = moreButton.base .. redReplace
    moreButton.hover = moreButton.base .. redReplace .. moreButtonHoverDirectives

    local rarityBackground = config.gui.paneRarity.children.background
    rarityBackground.file = rarityBackground.file .. redReplace

    local blueprintButton = config.gui.buttonPrintBlueprint
    local _, blueprintHoverDirectives = splitDirectives(blueprintButton.hover)
    blueprintButton.base = blueprintButton.base .. redReplace
    blueprintButton.hover = blueprintButton.base .. redReplace .. blueprintHoverDirectives

    local upgradeButton = config.gui.buttonPrintUpgrade
    local _, upgradeHoverDirectives = splitDirectives(blueprintButton.hover)
    upgradeButton.base = upgradeButton.base .. redReplace
    upgradeButton.hover = upgradeButton.base .. redReplace .. upgradeHoverDirectives

    for _, v in ipairs{"sipButtonChangeCategory", "sipButtonShowItems", "sipButtonShowObjects"} do
        local _, hoverDirectives = splitDirectives(config.gui[v].hover)
        config.gui[v].base = config.gui[v].base .. featureButtonReplace .. redReplace
        config.gui[v].hover = config.gui[v].base .. featureButtonReplace .. redReplace .. hoverDirectives
    end

    local levelLessButton = config.gui.paneWeapon.children.buttonWeaponLevelLess
    local _, levelLessButtonHoverDirectives = splitDirectives(levelLessButton.hover)
    levelLessButton.base = levelLessButton.base .. redReplace
    levelLessButton.hover = levelLessButton.base .. redReplace .. levelLessButtonHoverDirectives

    local levelMoreButton = config.gui.paneWeapon.children.buttonWeaponLevelMore
    local _, levelMoreButtonHoverDirectives = splitDirectives(levelMoreButton.hover)
    levelMoreButton.base = levelMoreButton.base .. redReplace
    levelMoreButton.hover = levelMoreButton.base .. redReplace .. levelMoreButtonHoverDirectives

    local levelAmount = config.gui.paneWeapon.children.imageWeaponLevel
    levelAmount.file = levelAmount.file .. redReplace

    return config
end