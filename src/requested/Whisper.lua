SetCollectionMarker = SetCollectionMarker or {}
local SCM = SetCollectionMarker
SCM.Whisper = SCM.Whisper or {}

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

function SCM.Whisper.GetWantedItems()
    return wantedItems
end

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
    SCM.Trade.UpdateTradeButton()
    SCM.Mail.UpdateMailUI()
end

---------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------
function SCM.Whisper.Initialize()
    EVENT_MANAGER:RegisterForEvent(SCM.name .. "Whisper", EVENT_CHAT_MESSAGE_CHANNEL, OnWhisper)

    SCM.Trade.Initialize()
    SCM.Mail.Initialize()
end

