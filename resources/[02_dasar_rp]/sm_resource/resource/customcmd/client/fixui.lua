local SWEEP_COUNT = 10
local SWEEP_INTERVAL = 100

local function try(fn)
    local ok, result = pcall(fn)
    if not ok then
        lib.print.debug(('[fixui] step gagal: %s'):format(result))
        return nil
    end
    return result
end

local function callExport(resource, export)
    if GetResourceState(resource) ~= 'started' then return nil end
    return try(function()
        return exports[resource][export](exports[resource])
    end)
end

local function closeOxLib()
    try(lib.hideContext)
    try(lib.hideMenu)
    try(lib.hideRadial)
    try(lib.hideTextUI)
    try(lib.closeInputDialog)
    try(function() lib.closeAlertDialog('fixui') end)
end

local function closeResourceUI()
    if GetResourceState('mm_radio') == 'started' then
        try(function() TriggerEvent('mm_radio:client:remove') end)
    end

    callExport('ox_inventory', 'closeInventory')

    try(function() TriggerEvent('sm_pets:client:forceClose') end)
    try(function() TriggerEvent('sm_printer:client:forceClose') end)
    try(function() TriggerEvent('sm_notepad:client:forceClose') end)
    try(function() TriggerEvent('sm_lockpick:client:forceClose') end)
    try(function() TriggerEvent('sm_htcontract:client:forceClose') end)
    try(function() TriggerEvent('sm_vehcontrol:client:forceClose') end)
    try(function() TriggerEvent('sm_netfish:client:forceClose') end)
    try(function() TriggerEvent('sm_report:client:forceClose') end)
    try(function() TriggerEvent('sm_ecutuning:client:forceClose') end)
    try(function() TriggerEvent('sm_cache:client:forceClose') end)
    try(function() TriggerEvent('sm_ittego:client:forceClose') end)
    try(function() TriggerEvent('sm_warden:client:forceClose') end)
    try(function() TriggerEvent('sm_roxnav:client:forceClose') end)
    try(function() TriggerEvent('sm_bomb:client:forceClose') end)
    try(function() TriggerEvent('sm_domino:client:forceClose') end)
    try(function() TriggerEvent('sm_animalfarm:client:forceClose') end)
    try(function() TriggerEvent('sm_scenes:client:forceClose') end)
    try(function() TriggerEvent('sm_gamemaster:client:forceClose') end)
    try(function() TriggerEvent('adjudicator:client:forceClose') end)

    if GetResourceState('sm_nui_browser') == 'started' then
        try(function() exports.sm_nui_browser:close(true) end)
    end

    if callExport('lb-phone', 'IsOpen') then
        try(function() exports['lb-phone']:ToggleOpen(false) end)
    end
end

local function releaseFocus()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end

local resetting = false

local function fixStuckUI()
    if resetting then return end
    resetting = true

    releaseFocus()
    closeOxLib()
    closeResourceUI()

    CreateThread(function()
        for _ = 1, SWEEP_COUNT do
            Wait(SWEEP_INTERVAL)
            releaseFocus()
        end

        resetting = false

        lib.notify({
            title = 'Fix UI',
            description = 'UI yang nyangkut udah ditutup.',
            type = 'success'
        })
    end)
end

RegisterCommand('fixui', fixStuckUI, false)

TriggerEvent('chat:addSuggestion', '/fixui', 'Tutup paksa UI yang nyangkut kalau kursor nyala dan ga bisa gerak')

exports('fixStuckUI', fixStuckUI)
