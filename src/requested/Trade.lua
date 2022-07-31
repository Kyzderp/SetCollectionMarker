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
-- The data could be saved with either @name or character name, maybe
---------------------------------------------------------------------
local function UpdateTraderDataName()
    local wantedItems = SCM.Whisper.GetWantedItems()

    -- Check both the display name and the character name
    if (wantedItems[otherDisplayName]) then
        currentlyTradingName = otherDisplayName
    else
        currentlyTradingName = otherCharacterName
    end
end

---------------------------------------------------------------------
-- Trade Inventory Button
---------------------------------------------------------------------
local matches = {}
local itemsString = ""

local function UpdateTradeButton()
    UpdateTraderDataName()
    matches, itemsString = SCM.Whisper.GetMatchingItems(currentlyTradingName, true)
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

            -- If the item is already in the window we get an alert back, but it should be ok
            d(string.format("Adding %s to slot %d", itemLink, tradeIndex))
            TradeAddItem(BAG_BACKPACK, slotIndex, tradeIndex)
        end
    end
    SCM.Mail.UpdateMailUI()
end
SCM.Trade.AddItemsToTrade = AddItemsToTrade

local function GetTradeButtonTooltip()
    return string.format("%s wants:%s", currentlyTradingName, itemsString)
end
SCM.Trade.GetTradeButtonTooltip = GetTradeButtonTooltip

---------------------------------------------------------------------
-- Trading
---------------------------------------------------------------------
local function OnTrade()
    -- d(string.format("Trading with %s / %s", otherCharacterName, otherDisplayName))
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

    SCM_TradeButtonAddItems:SetHidden(not SCM.savedOptions.showTradeButton)
end

