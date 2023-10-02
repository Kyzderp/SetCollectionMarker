-- Thanks Friday-The13-rus!
SetCollectionMarker = SetCollectionMarker or {}
local SCM = SetCollectionMarker
SCM.Gamepad = SCM.Gamepad or {}

local function AddUncollectedGamepadIndicator(control, itemLink, show)
    local statusIndicator = control.statusIndicator
    if statusIndicator then
        if (show and SCM.ShouldShowIcon(itemLink)) then
            statusIndicator:Hide()
            statusIndicator:AddIcon(SCM.iconTexture)
            statusIndicator:Show()
        end
    end
end

function SCM.Gamepad.SetupGamepadBagHooks()
    local inventories = {
        bag = {
            init = { object = ZO_GamepadInventory, functionName = "InitializeItemList" },
            list = function() return GAMEPAD_INVENTORY.itemList end,
            templateName = "ZO_GamepadItemSubEntryTemplate",
            showKey = "bag"
        },
        storeSell = {
            list = function() return STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_SELL].list end,
            templateName = "ZO_GamepadPricedVendorItemEntryTemplate",
            showKey = "bag"
        },
        storeBuyBack = {
            list = function() return STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_BUY_BACK].list end,
            templateName = "ZO_GamepadPricedVendorItemEntryTemplate",
            showKey = "bag"
        },
        deconstruction = {
            list = function () return SMITHING_GAMEPAD.deconstructionPanel.inventory.list end,
            templateName = "ZO_GamepadItemSubEntryTemplate",
            showKey = "crafting",
        },
        improvement = {
            list = function () return SMITHING_GAMEPAD.improvementPanel.inventory.list end,
            templateName = "ZO_GamepadItemSubEntryTemplate",
            showKey = "crafting",
        },
        bankWithdraw = {
            init = { object = ZO_GamepadBanking, functionName = "OnDeferredInitialize" },
            list = function() return GAMEPAD_BANKING.withdrawList.list end,
            templateName = "ZO_GamepadItemSubEntryTemplate",
            showKey = "bank"
        },
        bankDeposit = {
            init = { object = ZO_GamepadBanking, functionName = "OnDeferredInitialize" },
            list = function() return GAMEPAD_BANKING.depositList.list end,
            templateName = "ZO_GamepadItemSubEntryTemplate",
            showKey = "bank"
        },
        guildBankWithdraw = {
            init = { object = ZO_GuildBank_Gamepad, functionName = "OnDeferredInitialization" },
            list = function() return GAMEPAD_GUILD_BANK.withdrawList.list end,
            templateName = "ZO_GamepadItemSubEntryTemplate",
            showKey = "guild"
        },
        guildBankDeposit = {
            init = { object = ZO_GuildBank_Gamepad, functionName = "OnDeferredInitialization" },
            list = function() return GAMEPAD_GUILD_BANK.depositList.list end,
            templateName = "ZO_GamepadItemSubEntryTemplate",
            showKey = "guild"
        },
        transmute = {
            list = function() return ZO_RETRAIT_STATION_RETRAIT_GAMEPAD.inventory.list end,
            templateName = "ZO_GamepadItemSubEntryTemplate",
            showKey = "transmute"
        }
    }

    local function SetupHook(inventory)
        for _, templateName in ipairs({ inventory.templateName, inventory.templateName .. "WithHeader" }) do
            SecurePostHook(ZO_ScrollList_GetDataTypeTable(inventory.list(), templateName), "setupFunction", function(control, data)
                local show = SCM.savedOptions.show[inventory.showKey]
                local itemLink = GetItemLink(data.bagId, data.slotIndex, LINK_STYLE_BRACKETS)
                AddUncollectedGamepadIndicator(control, itemLink, show)
            end)
        end
    end

    for _, inventory in pairs(inventories) do
        if inventory.init then
            -- Some gamepad item lists are not loaded after loading ui or activating gamepad. Need hook another function for initialize
            SecurePostHook(inventory.init.object, inventory.init.functionName, function ()
                SetupHook(inventory)
            end)
        else
            SetupHook(inventory)
        end
    end
end