SetCollectionMarkerChat = {}

---------------------------------------------------------------------
-- Should be called from settings whenever the style is updated
function SetCollectionMarkerChat.UpdateIconString()
    SetCollectionMarkerChat.iconString = string.format("|c%02x%02x%02x|t%d:%d:%s:inheritcolor|t|r",
        SetCollectionMarker.savedOptions.chatIconColor[1] * 255,
        SetCollectionMarker.savedOptions.chatIconColor[2] * 255,
        SetCollectionMarker.savedOptions.chatIconColor[3] * 255,
        SetCollectionMarker.savedOptions.chatIconSize,
        SetCollectionMarker.savedOptions.chatIconSize,
        SetCollectionMarker.iconTexture)
end

---------------------------------------------------------------------
-- Add the icon(s) to the message
function SetCollectionMarkerChat.ParseItemLinks(message, location)
    -- Use a table to make sure the links are unique, for gsub later
    local found = {}
    local count = 0

    -- Non-greedy matches. normally it would just be numbers... but Group Loot Notifier inserts :by:<name> at the end for some reason...
    for itemLink in string.gmatch(message, "(|H%d:item:.-|h|h)") do
        if (SetCollectionMarker.ShouldShowIcon(itemLink)) then
            -- things to be subbed for
            if (location == SetCollectionMarker.LOCATION_BEFORE) then
                found[itemLink] = SetCollectionMarkerChat.iconString .. itemLink
            elseif (location == SetCollectionMarker.LOCATION_AFTER) then
                found[itemLink] = itemLink .. SetCollectionMarkerChat.iconString
            end
            count = count + 1
        end
    end

    -- No item links
    if (count == 0) then
        return message
    end

    -- For the single-icon options, just put it in the Location
    if (location == SetCollectionMarker.LOCATION_BEGINNING) then
        return SetCollectionMarkerChat.iconString .. message
    elseif (location == SetCollectionMarker.LOCATION_END) then
        return message .. SetCollectionMarkerChat.iconString
    end

    -- For each-icon option, substitute in the strings
    for link, withIcon in pairs(found) do
        message = string.gsub(message, link, withIcon)
    end
    return message
end

---------------------------------------------------------------------
-- After player is activated, do some chat things
function SetCollectionMarkerChat.OnPlayerActivated()
    -----------------------------
    -- Set up system message hook
    local function AddIconToSystem(origMessage)
        return SetCollectionMarkerChat.ParseItemLinks(origMessage, SetCollectionMarker.savedOptions.chatSystemLocation)
    end
    local previousFormatter = CHAT_ROUTER:GetRegisteredMessageFormatters()["AddSystemMessage"]
    if (previousFormatter) then
        CHAT_ROUTER:RegisterMessageFormatter("AddSystemMessage", function(...)
            return AddIconToSystem(previousFormatter(...))
        end)
    else
        CHAT_ROUTER:RegisterMessageFormatter("AddSystemMessage", AddIconToSystem)
    end

    --------------------------
    -- Set up normal chat hook
    local function AddIconToMessage(messageType, fromName, text, isFromCustomerService, fromDisplayName)
        local formattedText = SetCollectionMarkerChat.ParseItemLinks(text, SetCollectionMarker.savedOptions.chatMessageLocation)

        local channelInfo = ZO_ChatSystem_GetChannelInfo()[messageType]
        if (not channelInfo or not channelInfo.format) then
            return
        end

        return formattedText, channelInfo.saveTarget
    end
    local oldFormatter = CHAT_ROUTER:GetRegisteredMessageFormatters()[EVENT_CHAT_MESSAGE_CHANNEL]
    if (oldFormatter) then
        CHAT_ROUTER:RegisterMessageFormatter(EVENT_CHAT_MESSAGE_CHANNEL, function(messageType, fromName, text, isFromCustomerService, fromDisplayName)
            local oldText = oldFormatter(messageType, fromName, text, isFromCustomerService, fromDisplayName)
            return AddIconToMessage(messageType, fromName, oldText, isFromCustomerService, fromDisplayName)
        end)
    else
        CHAT_ROUTER:RegisterMessageFormatter(EVENT_CHAT_MESSAGE_CHANNEL, AddIconToMessage)
    end

    -- No longer need this
    EVENT_MANAGER:UnregisterForEvent(SetCollectionMarker.name .. "Activated", EVENT_PLAYER_ACTIVATED)
end
