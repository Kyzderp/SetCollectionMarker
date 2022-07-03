SetCollectionMarker = SetCollectionMarker or {}
local SCM = SetCollectionMarker

local function GetDescriptionString()
    return string.format("Displays an icon |c%02x%02x%02x|t36:36:%s:inheritcolor|t|r next to items not in your set collection.",
        SCM.savedOptions.iconColor[1] * 255,
        SCM.savedOptions.iconColor[2] * 255,
        SCM.savedOptions.iconColor[3] * 255,
        SCM.iconTexture)
end

local function GetChatDescriptionString()
    return string.format("Displays an inline icon on chat messages that contain items not in your set collection. Examples with location:\n\n" ..
        "Beginning:\n" ..
        "  %s|cfd7a1a[Group][@Kyzeragon]: anyone want |cFFDD00[Ring of the Advancing Yokeda]|cfd7a1a?|r\n" ..
        "End:\n" ..
        "  |cfd7a1a[Group][@Kyzeragon]: anyone want |cFFDD00[Ring of the Advancing Yokeda]|cfd7a1a?|r%s\n" ..
        "Before:\n" ..
        "  |cfd7a1a[Group][@Kyzeragon]: anyone want %s|cFFDD00[Ring of the Advancing Yokeda]|cfd7a1a?|r\n" ..
        "After:\n" ..
        "  |cfd7a1a[Group][@Kyzeragon]: anyone want |cFFDD00[Ring of the Advancing Yokeda]%s|cfd7a1a?|r",
        SCM.Chat.iconString,
        SCM.Chat.iconString,
        SCM.Chat.iconString,
        SCM.Chat.iconString)
end

local function UpdateSettingsDesc()
    WINDOW_MANAGER:GetControlByName("SetCollectionMarker#Description").data.text = GetDescriptionString()
    WINDOW_MANAGER:GetControlByName("SetCollectionMarker#Description"):UpdateValue()
end

local function UpdateSettingsChatDesc()
    WINDOW_MANAGER:GetControlByName("SetCollectionMarker#ChatDescription").data.text = GetChatDescriptionString()
    WINDOW_MANAGER:GetControlByName("SetCollectionMarker#ChatDescription"):UpdateValue()
end

function SCM.CreateSettingsMenu()
    local LAM = LibAddonMenu2
    local panelData = {
        type = "panel",
        name = "|c08BD1DSet Collection Marker|r",
        author = "Kyzeragon",
        version = SCM.version,
        registerForRefresh = true,
        registerForDefaults = true,
    }

    local optionsData = {
        {
            type = "submenu",
            name = "Inventory Icon",
            controls = {
                {
                    type = "description",
                    title = nil,
                    text = GetDescriptionString(),
                    width = "full",
                    reference = "SetCollectionMarker#Description",
                },
                {
                    type = "header",
                    name = "|c08BD1DWhere to Show|r",
                    width = "full",
                },
                {
                    type = "checkbox",
                    name = "Bag",
                    tooltip = "Show icon in your character's inventory",
                    default = true,
                    getFunc = function() return SCM.savedOptions.show.bag end,
                    setFunc = function(value)
                        SCM.savedOptions.show.bag = value
                        SCM.OnSetCollectionUpdated()
                    end,
                    width = "full",
                },
                {
                    type = "checkbox",
                    name = "Trade",
                    tooltip = "Show icon when trading with other players",
                    default = true,
                    getFunc = function() return SCM.savedOptions.show.trading end,
                    setFunc = function(value)
                        SCM.savedOptions.show.trading = value
                        SCM.OnSetCollectionUpdated()
                    end,
                    width = "full",
                },
                {
                    type = "checkbox",
                    name = "Bank",
                    tooltip = "Show icon in your personal bank",
                    default = true,
                    getFunc = function() return SCM.savedOptions.show.bank end,
                    setFunc = function(value)
                        SCM.savedOptions.show.bank = value
                        SCM.OnSetCollectionUpdated()
                    end,
                    width = "full",
                },
                {
                    type = "checkbox",
                    name = "House Storage",
                    tooltip = "Show icon in house storage coffers",
                    default = true,
                    getFunc = function() return SCM.savedOptions.show.housebank end,
                    setFunc = function(value)
                        SCM.savedOptions.show.housebank = value
                        SCM.OnSetCollectionUpdated()
                    end,
                    width = "full",
                },
                {
                    type = "checkbox",
                    name = "Guild Bank",
                    tooltip = "Show icon in guild bank",
                    default = true,
                    getFunc = function() return SCM.savedOptions.show.guild end,
                    setFunc = function(value)
                        SCM.savedOptions.show.guild = value
                        SCM.OnSetCollectionUpdated()
                    end,
                    width = "full",
                },
                {
                    type = "checkbox",
                    name = "Crafting Station",
                    tooltip = "Show icon at crafting stations, including the deconstruction assistant",
                    default = true,
                    getFunc = function() return SCM.savedOptions.show.crafting end,
                    setFunc = function(value)
                        SCM.savedOptions.show.crafting = value
                        SCM.OnSetCollectionUpdated()
                    end,
                    width = "full",
                },
                {
                    type = "checkbox",
                    name = "Transmute Station",
                    tooltip = "Show icon at transmute stations when retraiting",
                    default = true,
                    getFunc = function() return SCM.savedOptions.show.transmute end,
                    setFunc = function(value)
                        SCM.savedOptions.show.transmute = value
                        SCM.OnSetCollectionUpdated()
                    end,
                    width = "full",
                },
                {
                    type = "checkbox",
                    name = "Guild Store",
                    tooltip = "Show icon in guild store search list and personal listings",
                    default = true,
                    getFunc = function() return SCM.savedOptions.show.guildstore end,
                    setFunc = function(value)
                        SCM.savedOptions.show.guildstore = value
                        SCM.OnSetCollectionUpdated()
                    end,
                    width = "full",
                },
        ---------------------------------------------------------------------
        -- Inventory Icon Appearance
                {
                    type = "header",
                    name = "|c08BD1DInventory Icon Appearance|r",
                    width = "full",
                },
                {
                    type = "slider",
                    name = "Size",
                    min = 12,
                    max = 60,
                    step = 2,
                    default = 36,
                    width = full,
                    getFunc = function() return SCM.savedOptions.iconSize end,
                    setFunc = function(value)
                        SCM.savedOptions.iconSize = value
                        SCM.OnSetCollectionUpdated()
                    end,
                },
                {
                    type = "colorpicker",
                    name = "Color",
                    default = {r = 0.4, g = 1, b = 0.5, a = 1},
                    getFunc = function() return unpack(SCM.savedOptions.iconColor) end,
                    setFunc = function(r, g, b)
                        SCM.savedOptions.iconColor = {r, g, b}
                        SCM.OnSetCollectionUpdated()
                        UpdateSettingsDesc()
                    end,
                },
                {
                    type = "slider",
                    name = "Bag Offset",
                    tooltip = "Horizontal offset for the icon in all places except guild store",
                    min = -390,
                    max = 150,
                    step = 10,
                    default = 0,
                    width = full,
                    getFunc = function() return SCM.savedOptions.iconOffset end,
                    setFunc = function(value)
                        SCM.savedOptions.iconOffset = value
                        SCM.OnSetCollectionUpdated()
                    end,
                },
                {
                    type = "slider",
                    name = "Guild Store Offset",
                    tooltip = "Horizontal offset for the icon in guild store",
                    min = -270,
                    max = 330,
                    step = 10,
                    default = 0,
                    width = full,
                    getFunc = function() return SCM.savedOptions.iconStoreOffset end,
                    setFunc = function(value)
                        SCM.savedOptions.iconStoreOffset = value
                        SCM.OnSetCollectionUpdated()
                    end,
                },
            },
        },
---------------------------------------------------------------------
-- Chat Icon Appearance
        {
            type = "submenu",
            name = "Chat Icon",
            controls = {
                {
                    type = "description",
                    title = nil,
                    text = GetChatDescriptionString(),
                    width = "full",
                    reference = "SetCollectionMarker#ChatDescription",
                },
                {
                    type = "header",
                    name = "|c08BD1DWhere to Show|r",
                    width = "full",
                },
                {
                    type = "checkbox",
                    name = "System Messages",
                    tooltip = "Show an icon when a system message contains an item that is not in your set collection",
                    default = true,
                    getFunc = function() return SCM.savedOptions.chatSystemShow end,
                    setFunc = function(value)
                        SCM.savedOptions.chatSystemShow = value
                    end,
                    width = "half",
                },
                {
                    type = "dropdown",
                    name = "System Icon Location",
                    tooltip = "Where to show the icon for system messages",
                    default = "Beginning",
                    choices = {"Beginning", "End", "Before", "After"},
                    getFunc = function() return SCM.locationString[SCM.savedOptions.chatSystemLocation] end,
                    setFunc = function(value)
                        SCM.savedOptions.chatSystemLocation = SCM.stringLocation[value]
                    end,
                    width = "half",
                    disabled = function() return not SCM.savedOptions.chatSystemShow end,
                },
                {
                    type = "checkbox",
                    name = "Chat Messages",
                    tooltip = "Show an icon when a player chat message contains an item that is not in your set collection",
                    default = true,
                    getFunc = function() return SCM.savedOptions.chatMessageShow end,
                    setFunc = function(value)
                        SCM.savedOptions.chatMessageShow = value
                    end,
                    width = "half",
                },
                {
                    type = "dropdown",
                    name = "Chat Icon Location",
                    tooltip = "Where to show the icon for player chat messages",
                    default = "Before",
                    choices = {"Beginning", "End", "Before", "After"},
                    getFunc = function() return SCM.locationString[SCM.savedOptions.chatMessageLocation] end,
                    setFunc = function(value)
                        SCM.savedOptions.chatMessageLocation = SCM.stringLocation[value]
                    end,
                    width = "half",
                    disabled = function() return not SCM.savedOptions.chatMessageShow end,
                },
                {
                    type = "header",
                    name = "|c08BD1DChat Icon Appearance|r",
                    width = "full",
                },
                {
                    type = "slider",
                    name = "Size",
                    min = 8,
                    max = 36,
                    step = 2,
                    default = 18,
                    width = full,
                    getFunc = function() return SCM.savedOptions.chatIconSize end,
                    setFunc = function(value)
                        SCM.savedOptions.chatIconSize = value
                        SCM.Chat.UpdateIconString()
                        UpdateSettingsChatDesc()
                    end,
                },
                {
                    type = "colorpicker",
                    name = "Color",
                    default = {r = 0.4, g = 1, b = 0.5, a = 1},
                    getFunc = function() return unpack(SCM.savedOptions.chatIconColor) end,
                    setFunc = function(r, g, b)
                        SCM.savedOptions.chatIconColor = {r, g, b}
                        SCM.Chat.UpdateIconString()
                        UpdateSettingsChatDesc()
                    end,
                },
            }
        }
    }

    SCM.addonPanel = LAM:RegisterAddonPanel("SetCollectionMarkerOptions", panelData)
    LAM:RegisterOptionControls("SetCollectionMarkerOptions", optionsData)
end