function GetDescriptionString()
    local whereDisplay = "items not in your set collection"

    -- TODO: remove when Markarth drops
    if (GetAPIVersion() < 100033) then
        whereDisplay = "all set item pieces that are not bound. "
            .. "When ESO updates to the Markarth DLC, it will automatically start displaying the icon "
            .. "next to ONLY items that are not in your set collection"
    end
    return string.format("Displays an icon |c%02x%02x%02x|t36:36:%s:inheritcolor|t|r next to %s.",
        SetCollectionMarker.savedOptions.iconColor[1] * 255,
        SetCollectionMarker.savedOptions.iconColor[2] * 255,
        SetCollectionMarker.savedOptions.iconColor[3] * 255,
        SetCollectionMarker.iconTexture,
        whereDisplay)
end

local function UpdateSettingsDesc()
    WINDOW_MANAGER:GetControlByName("SetCollectionMarker#Description").data.text = GetDescriptionString()
    WINDOW_MANAGER:GetControlByName("SetCollectionMarker#Description"):UpdateValue()
end

function SetCollectionMarker:CreateSettingsMenu()
    local LAM = LibAddonMenu2
    -- Register the Options panel with LAM
    local panelData = 
    {
        type = "panel",
        name = "|c08BD1DSet Collection Marker|r",
        author = "Kyzeragon",
        version = SetCollectionMarker.version,
        registerForRefresh = true,
        registerForDefaults = true,
    }

    -- Set the actual panel data
    local optionsData = {
        {
            type = "description",
            title = nil,
            text = GetDescriptionString(),
            width = "full",
            reference = "SetCollectionMarker#Description",
        },
        {
            type = "header",
            name = "|c08BD1DWhich Icons|r",
            width = "full",
        },
        {
            type = "checkbox",
            name = "Bag",
            tooltip = "Show icon in your character's inventory",
            default = true,
            getFunc = function() return SetCollectionMarker.savedOptions.show.bag end,
            setFunc = function(value)
                SetCollectionMarker.savedOptions.show.bag = value
                SetCollectionMarker.OnSetCollectionUpdated()
            end,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Bank",
            tooltip = "Show icon in your personal bank",
            default = true,
            getFunc = function() return SetCollectionMarker.savedOptions.show.bank end,
            setFunc = function(value)
                SetCollectionMarker.savedOptions.show.bank = value
                SetCollectionMarker.OnSetCollectionUpdated()
            end,
            width = "full",
        },
        {
            type = "checkbox",
            name = "House Storage",
            tooltip = "Show icon in house storage coffers",
            default = true,
            getFunc = function() return SetCollectionMarker.savedOptions.show.housebank end,
            setFunc = function(value)
                SetCollectionMarker.savedOptions.show.housebank = value
                SetCollectionMarker.OnSetCollectionUpdated()
            end,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Guild Bank",
            tooltip = "Show icon in guild bank",
            default = true,
            getFunc = function() return SetCollectionMarker.savedOptions.show.guild end,
            setFunc = function(value)
                SetCollectionMarker.savedOptions.show.guild = value
                SetCollectionMarker.OnSetCollectionUpdated()
            end,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Crafting Station",
            tooltip = "Show icon at crafting stations",
            default = true,
            getFunc = function() return SetCollectionMarker.savedOptions.show.crafting end,
            setFunc = function(value)
                SetCollectionMarker.savedOptions.show.crafting = value
                SetCollectionMarker.OnSetCollectionUpdated()
            end,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Transmute Station",
            tooltip = "Show icon at transmute stations when retraiting",
            default = true,
            getFunc = function() return SetCollectionMarker.savedOptions.show.transmute end,
            setFunc = function(value)
                SetCollectionMarker.savedOptions.show.transmute = value
                SetCollectionMarker.OnSetCollectionUpdated()
            end,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Guild Store",
            tooltip = "Show icon in guild store search list and personal listings",
            default = true,
            getFunc = function() return SetCollectionMarker.savedOptions.show.guildstore end,
            setFunc = function(value)
                SetCollectionMarker.savedOptions.show.guildstore = value
                SetCollectionMarker.OnSetCollectionUpdated()
            end,
            width = "full",
        },
        {
            type = "header",
            name = "|c08BD1DIcon Appearance|r",
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
            getFunc = function() return SetCollectionMarker.savedOptions.iconSize end,
            setFunc = function(value)
                SetCollectionMarker.savedOptions.iconSize = value
                SetCollectionMarker.OnSetCollectionUpdated()
            end,
        },
        {
            type = "colorpicker",
            name = "Color",
            getFunc = function() return unpack(SetCollectionMarker.savedOptions.iconColor) end,
            setFunc = function(r, g, b)
                SetCollectionMarker.savedOptions.iconColor = {r, g, b}
                SetCollectionMarker.OnSetCollectionUpdated()
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
            getFunc = function() return SetCollectionMarker.savedOptions.iconOffset end,
            setFunc = function(value)
                SetCollectionMarker.savedOptions.iconOffset = value
                SetCollectionMarker.OnSetCollectionUpdated()
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
            getFunc = function() return SetCollectionMarker.savedOptions.iconStoreOffset end,
            setFunc = function(value)
                SetCollectionMarker.savedOptions.iconStoreOffset = value
                SetCollectionMarker.OnSetCollectionUpdated()
            end,
        },
    }

    SetCollectionMarker.addonPanel = LAM:RegisterAddonPanel("SetCollectionMarkerOptions", panelData)
    LAM:RegisterOptionControls("SetCollectionMarkerOptions", optionsData)
end