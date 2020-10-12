-----------------------------------------------------------
-- SetCollectionMarker
-- @author Kyzeragon
-----------------------------------------------------------

SetCollectionMarker = {}
SetCollectionMarker.name = "SetCollectionMarker"
SetCollectionMarker.version = "0.9.1"

-- Defaults
local defaultOptions = {
    iconSize = 36,
    iconOffset = 0,
    iconStoreOffset = 0,
    iconColor = {0.4, 1, 0.5},
    show = {
        bag = true,
        bank = true,
        housebank = true,
        guild = true,
        guildstore = true,
        crafting = true,
    },
}

---------------------------------------------------------------------
-- Display icon to the right of item
local function AddUncollectedIndicator(control, bagID, slotIndex, itemLink, show, offset)
    local uncollectedControl = control:GetNamedChild("UncollectedControl")
    local itemType = GetItemLinkItemType(itemLink)
    
    -- Use the item set collections tab icon
    local function CreateUncollectedControl(parent)
        local control = WINDOW_MANAGER:CreateControl(parent:GetName() .. "UncollectedControl", parent, CT_TEXTURE)
        control:SetDrawTier(DT_HIGH)
        control:SetTexture("/" .. SetCollectionMarker.iconTexture)
        return control
    end

    -- Create control if doesn't exist
    if (not uncollectedControl) then
        uncollectedControl = CreateUncollectedControl(control)
    end
    uncollectedControl:SetHidden(true)

    -- Icon should remain hidden if specified in settings
    if (not show) then
        return
    end

    -- Check that this is a gear item
    if (itemType ~= ITEMTYPE_ARMOR and itemType ~= ITEMTYPE_WEAPON) then
        return
    end

    -- Check that this is a set item
    local hasSet = GetItemLinkSetInfo(itemLink)
    if (not hasSet) then
        return
    end

    -- If it's already unlocked (collected), then skip
    -- TODO: remove nil check when Markarth drops
    if (IsItemSetCollectionPieceUnlocked and IsItemSetCollectionPieceUnlocked(GetItemLinkItemId(itemLink))) then
        return
    end

    -- TODO: remove bound check when Markarth drops
    if (GetAPIVersion() < 100033 and IsItemLinkBound(itemLink)) then
        return
    end

    -- Show the icon
    local controlName = WINDOW_MANAGER:GetControlByName(control:GetName() .. 'Name')
    uncollectedControl:SetAnchor(LEFT, controlName, RIGHT, offset)
    uncollectedControl:SetDimensions(SetCollectionMarker.savedOptions.iconSize, SetCollectionMarker.savedOptions.iconSize)
    uncollectedControl:SetColor(unpack(SetCollectionMarker.savedOptions.iconColor))
    uncollectedControl:SetHidden(false)
end


---------------------------------------------------------------------
-- Set up hooks to display icons in bags, thanks TraitBuddy
local function SetupBagHooks()
    for _, inventory in pairs(SetCollectionMarker.inventories) do
        SecurePostHook(ZO_ScrollList_GetDataTypeTable(inventory.list, 1), "setupCallback", function(control, dataEntryData)
            local show = SetCollectionMarker.savedOptions.show[inventory.showKey]
            local itemLink = GetItemLink(control.dataEntry.data.bagId, control.dataEntry.data.slotIndex, LINK_STYLE_BRACKETS)
            AddUncollectedIndicator(control, control.dataEntry.data.bagId, control.dataEntry.data.slotIndex,
                itemLink, show, SetCollectionMarker.savedOptions.iconOffset)
        end)
    end
end

---------------------------------------------------------------------
-- Set up hooks to display icons in guild store, thanks Master Recipe List
local function SetupGuildStoreHooks()
    ZO_PreHook(TRADING_HOUSE.searchResultsList.dataTypes[1], "setupCallback", function(...)
        local show = SetCollectionMarker.savedOptions.show.guildstore
        local control, data = ...
        if (control.slotControlType and control.slotControlType == 'listSlot' and data.slotIndex) then
            local itemLink = GetTradingHouseSearchResultItemLink(data.slotIndex, LINK_STYLE_BRACKETS)
            AddUncollectedIndicator(control, nil, nil, itemLink, show, SetCollectionMarker.savedOptions.iconStoreOffset)
        end
    end)
    ZO_PreHook(TRADING_HOUSE.postedItemsList.dataTypes[2], "setupCallback", function(...)
        local show = SetCollectionMarker.savedOptions.show.guildstore
        local control, data = ...
        if (control.slotControlType and control.slotControlType == 'listSlot' and data.slotIndex) then
            local itemLink = GetTradingHouseListingItemLink(data.slotIndex, LINK_STYLE_BRACKETS)
            AddUncollectedIndicator(control, nil, nil, itemLink, show, SetCollectionMarker.savedOptions.iconStoreOffset)
        end
    end)

    -- Refresh immediately, because for some reason it doesn't show upon first opening
    ZO_ScrollList_RefreshVisible(ZO_TradingHouseBrowseItemsRightPaneSearchResults)
end


---------------------------------------------------------------------
-- When the collection updates or settings change, we should refresh the view so the icons immediately update
function SetCollectionMarker.OnSetCollectionUpdated()
    ZO_ScrollList_RefreshVisible(ZO_PlayerInventoryList)
    ZO_ScrollList_RefreshVisible(ZO_PlayerBankBackpack)
    ZO_ScrollList_RefreshVisible(ZO_HouseBankBackpack)
    ZO_ScrollList_RefreshVisible(ZO_GuildBankBackpack)
    ZO_ScrollList_RefreshVisible(ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack)
    ZO_ScrollList_RefreshVisible(ZO_SmithingTopLevelImprovementPanelInventoryBackpack)
end

---------------------------------------------------------------------
-- Initialize 
local function Initialize()
    -- Settings and saved variables
    SetCollectionMarker.savedOptions = ZO_SavedVars:NewAccountWide("SetCollectionMarkerSavedVariables", 1, "Options", defaultOptions)

    -- TODO: remove condition when Markarth drops
    if (GetAPIVersion() >= 100033) then
        EVENT_MANAGER:RegisterForEvent(SetCollectionMarker.name .. "CollectionUpdate", EVENT_ITEM_SET_COLLECTION_UPDATED, SetCollectionMarker.OnSetCollectionUpdated)
    end
    EVENT_MANAGER:RegisterForEvent(SetCollectionMarker.name .. "StoreSearch", EVENT_TRADING_HOUSE_RESPONSE_RECEIVED, SetupGuildStoreHooks)

    -- Inventories to show icons in, thanks TraitBuddy
    SetCollectionMarker.inventories = {
        bag = {
            list = ZO_PlayerInventoryList,
            showKey = "bag",
        },
        bank = {
            list = ZO_PlayerBankBackpack,
            showKey = "bank",
        },
        housebank = {
            list = ZO_HouseBankBackpack,
            showKey = "housebank",
        },
        guild = {
            list = ZO_GuildBankBackpack,
            showKey = "guild",
        },
        deconstruction = {
            list = ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack,
            showKey = "crafting",
        },
        improvement = {
            list = ZO_SmithingTopLevelImprovementPanelInventoryBackpack,
            showKey = "crafting",
        },
    }

    SetCollectionMarker.iconTexture = "esoui/art/collections/collections_tabIcon_itemSets_down.dds"
    -- TODO: remove when Markarth drops
    if (GetAPIVersion() < 100033) then
        SetCollectionMarker.iconTexture = "esoui/art/crafting/smithing_tabicon_armorset_down.dds"
    end

    SetCollectionMarker:CreateSettingsMenu()

    SetupBagHooks()
end


---------------------------------------------------------------------
-- On load
local function OnAddOnLoaded(_, addonName)
    if addonName == SetCollectionMarker.name then
        EVENT_MANAGER:UnregisterForEvent(SetCollectionMarker.name, EVENT_ADD_ON_LOADED)
        Initialize()
    end
end
 
EVENT_MANAGER:RegisterForEvent(SetCollectionMarker.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

