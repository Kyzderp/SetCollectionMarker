SetCollectionMarker = SetCollectionMarker or {}
local SCM = SetCollectionMarker
SCM.Trade = SCM.Trade or {}

---------------------------------------------------------------------
--[[
When a player whispers us with item links, store the item links for
some amount of time. When we initiate a trade with the player, either
automatically add the items or show a button that will add those
items to the trade window.
Once the item is traded, remove it from the list, in case they trade
again. We also need to deal with not putting duplicate items, and
checking that player's list for duplicate items.

TODO: Maybe add a button to mailing too?
TODO: Tradeable and not locked
]]

---------------------------------------------------------------------
-- Common
---------------------------------------------------------------------
-- Currently trading recipient
local otherCharacterName = ""
local otherDisplayName = ""

-- Correct "key" for trading recipient. Should usually be the display name, but could be character?
local currentlyTradingName = ""

---------------------------------------------------------------------
-- Item Searching
---------------------------------------------------------------------
-- Returns: {[id] = trait}
--          nil if none
local function GetTraderWantedItems()
    local wantedItems = SCM.Whisper.GetWantedItems()

    -- Check both the display name and the character name
    local data = wantedItems[otherDisplayName]
    currentlyTradingName = otherDisplayName
    if (not data) then
        data = wantedItems[otherCharacterName]
        currentlyTradingName = otherCharacterName
    end
    if (not data) then return end

    -- Clean struct if over an hour ago
    local age = GetGameTimeSeconds() - data.timeWhispered
    if (age > 360) then
        wantedItems[currentlyTradingName] = nil
        return
    end

    return data.items
end

-- Returns: {slotIndex, slotIndex,}
--          {} if none
local function GetMatchingItems()
    local wanted = GetTraderWantedItems()
    if (not wanted) then
        -- None of us are wanted
        return {}
    end

    -- Go through bag to find matching items
    local matches = {}
    local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(BAG_BACKPACK)
    for _, item in pairs(bagCache) do
        if (IsItemBound(item.bagId, item.slotIndex)) then
            -- Bound already
        elseif (IsItemPlayerLocked(item.bagId, item.slotIndex)) then
            -- Locked
            -- TODO: show in tooltip that it's locked, instead of not adding to list at all
        elseif (IsItemBoPAndTradeable(item.bagId, item.slotIndex) and not IsDisplayNameInItemBoPAccountTable(item.bagId, item.slotIndex, string.gsub(otherDisplayName, "@", ""))) then
            -- BoP Tradeable but not tradeable with this person
        else
            -- TODO: maybe match trait too?
            -- TODO: this might add doubles?
            local itemLink = GetItemLink(item.bagId, item.slotIndex, LINK_STYLE_BRACKETS)
            local itemId = GetItemLinkItemId(itemLink)
            if (wanted[itemId]) then
                table.insert(matches, item.slotIndex)
            end
        end
    end

    return matches
end

---------------------------------------------------------------------
-- Trade Inventory Button
---------------------------------------------------------------------
local matches = {}

local function UpdateTradeButton()
    matches = GetMatchingItems()
end
SCM.Trade.UpdateTradeButton = UpdateTradeButton

local function AddItemsToTrade()
    -- * TradeAddItem(*[Bag|#Bag]* _bagId_, *integer* _slotIndex_, *luaindex:nilable* _tradeIndex_)
    for tradeIndex = 1, 5 do
        local bagId = GetTradeItemBagAndSlot(TRADE_ME, tradeIndex)
        if (not bagId and #matches > 0) then
            local slotIndex = table.remove(matches, 1) -- TODO: maybe don't remove until it's traded away
            local itemLink = GetItemLink(BAG_BACKPACK, slotIndex, LINK_STYLE_BRACKETS)
            local itemId = GetItemLinkItemId(itemLink)
            SCM.Whisper.GetWantedItems()[currentlyTradingName].items[itemId] = nil -- Also remove it from the original

            d(string.format("Adding %s to slot %d", itemLink, tradeIndex))
            TradeAddItem(BAG_BACKPACK, slotIndex, tradeIndex)
        end
    end
end
SCM.Trade.AddItemsToTrade = AddItemsToTrade

local function GetTradeButtonTooltip()
    local resultItems = ""
    for _, slotIndex in pairs(matches) do
        local itemLink = GetItemLink(BAG_BACKPACK, slotIndex, LINK_STYLE_BRACKETS)
        resultItems = string.format("%s\n%s", resultItems, itemLink)
    end

    return string.format("%s wants:%s", currentlyTradingName, resultItems)
end
SCM.Trade.GetTradeButtonTooltip = GetTradeButtonTooltip

---------------------------------------------------------------------
-- Trading
---------------------------------------------------------------------
local function OnTrade()
    d(string.format("Trading with %s / %s", otherCharacterName, otherDisplayName))
    SCM_TradeButton:SetParent(ZO_TradeMyControls)
    SCM_TradeButton:ClearAnchors()
    SCM_TradeButton:SetAnchor(RIGHT, ZO_TradeMyControlsMoney, LEFT, -10, 0)

    UpdateTradeButton(otherDisplayName, otherCharacterName)
end

-- Either being invited or inviting someone else, doesn't matter
local function OnTradeInvite(_, characterName, displayName)
    otherCharacterName = zo_strformat("<<1>>", characterName)
    otherDisplayName = displayName
end

---------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------
function SCM.Trade.Initialize()
    -- It would be easier if these events just provided the names with the confirm event...
    EVENT_MANAGER:RegisterForEvent(SCM.name .. "TradeConsidering", EVENT_TRADE_INVITE_CONSIDERING, OnTradeInvite)
    EVENT_MANAGER:RegisterForEvent(SCM.name .. "TradeWaiting", EVENT_TRADE_INVITE_WAITING, OnTradeInvite)
    EVENT_MANAGER:RegisterForEvent(SCM.name .. "TradeAccepted", EVENT_TRADE_INVITE_ACCEPTED, OnTrade)
end

