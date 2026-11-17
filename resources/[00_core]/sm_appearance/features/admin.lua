local settings = require "core.settings"

local EMPTY = { allowed = false }

---@type table?
local data

local admin = {}

---@param payload table?
local function publish(payload)
    SendNuiMessage(json.encode({ action = "admin_data", data = payload or EMPTY }))
end

RegisterNetEvent("rhd_appearance:admin:data", function(payload)
    if source == '' then return end

    data = payload

    settings.reset()
    publish(data)
end)

function admin.reset()
    if not data then return end

    data = nil

    publish(nil)
end

local ACTIONS = {
    admin_save_entry = "rhd_appearance:admin:blacklist:save",
    admin_delete_entry = "rhd_appearance:admin:blacklist:delete",
    admin_sync_blacklist = "rhd_appearance:admin:blacklist:sync",
    admin_register_half_ped = "rhd_appearance:admin:halfped:register",
    admin_remove_half_ped = "rhd_appearance:admin:halfped:remove",
    admin_grant_half_ped = "rhd_appearance:admin:halfped:grant",
    admin_revoke_half_ped = "rhd_appearance:admin:halfped:revoke",
    admin_save_ped_rule = "rhd_appearance:admin:peds:save",
    admin_delete_ped_rule = "rhd_appearance:admin:peds:delete",
    admin_sync_peds = "rhd_appearance:admin:peds:sync",
    admin_save_ped_catalogue = "rhd_appearance:admin:catalogue:save"
}

for callback, target in pairs(ACTIONS) do
    RegisterNUICallback(callback, function(payload, cb)
        local result = lib.callback.await(target, false, payload)

        if not result then
            lib.notify({ description = locale("notify.adminFailed"), type = "error" })
        end

        cb(result)
    end)
end

return admin
