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
TODO: They can also whisper during the trade
TODO: Tradeable and not locked
]]

---------------------------------------------------------------------
-- Common
---------------------------------------------------------------------
-- TODO: is saving the ID sufficient? or do we care about trait?
--       correct trait should probably have higher priority

--[[
wantedItems = {
    ["@Kyzeragon"] = {
        items = {
            [id] = trait?,
        },
        timeWhispered = 1284481,
    }
}

Can also be keyed by character name
]]
local wantedItems = {}
local aliases = {}

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
local function GetWantedItems()
    local data = wantedItems[otherDisplayName]
    currentlyTradingName = otherDisplayName
    if (not data) then
        data = wantedItems[otherCharacterName]
        currentlyTradingName = otherCharacterName
    end
    if (not data) then return end

    local age = GetGameTimeSeconds() - data.timeWhispered
    if (age > 360) then
        -- Ignore if over an hour ago
        wantedItems[currentlyTradingName] = nil
        return
    end

    return data.items
end

-- Returns: {slotIndex, slotIndex,}
--          {} if none
local function GetMatchingItems()
    local wanted = GetWantedItems()
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
        elseif (IsItemBoPAndTradeable(item.bagId, item.slotIndex) and not IsDisplayNameInItemBoPAccountTable(item.bagId, item.slotIndex, string.gsub(otherDisplayName, "@", ""))) then
            -- BoP Tradeable but not tradeable with this person
        else
            -- TODO: maybe match trait too?
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

local function AddItemsToTrade()
    -- * TradeAddItem(*[Bag|#Bag]* _bagId_, *integer* _slotIndex_, *luaindex:nilable* _tradeIndex_)
    for tradeIndex = 1, 5 do
        local bagId = GetTradeItemBagAndSlot(TRADE_ME, tradeIndex)
        if (not bagId and #matches > 0) then
            local slotIndex = table.remove(matches, 1) -- TODO: maybe don't remove until it's traded away
            local itemLink = GetItemLink(BAG_BACKPACK, slotIndex, LINK_STYLE_BRACKETS)
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
-- Chatting
---------------------------------------------------------------------
-- EVENT_CHAT_MESSAGE_CHANNEL (*[ChannelType|#ChannelType]* _channelType_, *string* _fromName_, *string* _text_, *bool* _isCustomerService_, *string* _fromDisplayName_)
local function OnWhisper(_, channelType, fromName, text, _, fromDisplayName)
    if (channelType ~= CHAT_CHANNEL_WHISPER) then return end

    -- It's possible that some data is already saved in character name
    -- Use that if already existing, otherwise use @ name
    local name
    if (fromDisplayName and not wantedItems[fromName]) then
        name = fromDisplayName
    else
        name = fromName
    end

    local data = wantedItems[name] or {}
    local items = data.items or {}

    -- Non-greedy matches. normally it would just be numbers... but Group Loot Notifier inserts :by:<name> at the end for some reason...
    for itemLink in string.gmatch(text, "(|H%d:item:.-|h|h)") do
        -- Senchal Defender's Ring
        -- |H1:item:154836:363:50:0:0:0:0:0:0:0:0:0:0:0:0:95:0:0:0:0:0|h|h
        if (IsItemLinkSetCollectionPiece(itemLink)) then
            local id = GetItemLinkItemId(itemLink)
            local trait = GetItemLinkTraitType(itemLink)
            items[id] = trait
        end
    end

    data.items = items
    data.timeWhispered = GetGameTimeSeconds()
    wantedItems[name] = data
    UpdateTradeButton(fromDisplayName, fromName)
end

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
    EVENT_MANAGER:RegisterForEvent(SCM.name .. "Whisper", EVENT_CHAT_MESSAGE_CHANNEL, OnWhisper)

    -- It would be easier if these events just provided the names with the confirm event...
    EVENT_MANAGER:RegisterForEvent(SCM.name .. "TradeConsidering", EVENT_TRADE_INVITE_CONSIDERING, OnTradeInvite)
    EVENT_MANAGER:RegisterForEvent(SCM.name .. "TradeWaiting", EVENT_TRADE_INVITE_WAITING, OnTradeInvite)
    EVENT_MANAGER:RegisterForEvent(SCM.name .. "TradeAccepted", EVENT_TRADE_INVITE_ACCEPTED, OnTrade)
end

