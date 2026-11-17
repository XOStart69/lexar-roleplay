local config = localmodule 'config'

local PED_MODEL = config.pedModel
local DISTANCE = config.interactDistance
local PED_ANIM = { dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@idle_a', anim = 'idle_a', flag = 49 }
local PED_PROP = { propModel = 'prop_cs_tablet', bone = 28422, rotation = vec3(0.0, 0.0, 0.03), offset = vec3(0.0, 0.0, 0.03) }
local PERFORMANCE_MODS = { 11, 12, 13, 15, 16 }
local PERFORMANCE_TOGGLES = { 18, 20, 22 }

---@param description string
---@param kind? string
local function notify(description, kind)
    lib.notify({ description = description, type = kind or 'error' })
end

local rentVehicle

---@param key string
---@param vehicle table
---@param point table
---@return table
local function rentOption(key, vehicle, point)
    local title, description, disabled = vehicle.label, nil, false
    local rule = vehicle.jobs and QBPlayerData.job and vehicle.jobs[QBPlayerData.job.name]
    local items = rule and rule.items

    if items then
        local counts = ox_inventory:Search('count', items)
        local total = 0
        for i = 1, #items do
            total = total + (counts[items[i]] or 0)
        end
        local item = ox_inventory:Items(items[1])
        description = 'Butuh: ' .. (item and item.label or items[1])
        if total <= 0 then
            disabled = true
            title = title .. ' - LACKING ITEM'
        end
    end

    return {
        title = title,
        description = description,
        icon = 'car',
        disabled = disabled,
        onSelect = function() rentVehicle(key, vehicle) end,
    }
end

---@param veh number
---@param custom table
local function applyCustom(veh, custom)
    if custom.mods then
        for i = 1, #custom.mods do
            local mod = custom.mods[i]
            SetVehicleMod(veh, mod[1], mod[2], false)
        end
    end
    if custom.toggles then
        for i = 1, #custom.toggles do
            ToggleVehicleMod(veh, custom.toggles[i], true)
        end
    end
    if custom.colours then SetVehicleColours(veh, custom.colours[1], custom.colours[2]) end
    if custom.primary then
        local _, secondary = GetVehicleColours(veh)
        SetVehicleColours(veh, custom.primary, secondary)
    end
    if custom.extra then SetVehicleExtraColours(veh, custom.extra[1], custom.extra[2]) end
    if custom.dashboard then SetVehicleDashboardColour(veh, custom.dashboard) end
    if custom.interior then SetVehicleInteriorColour(veh, custom.interior) end
    if custom.xenon then SetVehicleXenonLightsColour(veh, custom.xenon) end
    if custom.tint then SetVehicleWindowTint(veh, custom.tint) end
end

---@param veh number
local function applyPerformance(veh)
    local model = GetEntityModel(veh)
    if IsThisModelABoat(model) or IsThisModelAHeli(model) or IsThisModelAPlane(model) then return end

    for i = 1, #PERFORMANCE_MODS do
        local slot = PERFORMANCE_MODS[i]
        SetVehicleMod(veh, slot, GetNumVehicleMods(veh, slot) - 1, false)
    end
    for i = 1, #PERFORMANCE_TOGGLES do
        ToggleVehicleMod(veh, PERFORMANCE_TOGGLES[i], true)
    end
end

---@param veh number
---@param livery number
local function applyLivery(veh, livery)
    SetVehicleLivery(veh, livery)
    if GetNumVehicleMods(veh, 48) > 0 then
        SetVehicleMod(veh, 48, livery, false)
    end
end

---@param key string
---@param vehicle table
rentVehicle = function(key, vehicle)
    local ok, data = lib.callback.await('sm_jobrental:rent', false, key, vehicle.model)
    if not ok or type(data) ~= 'table' then
        return notify(type(data) == 'string' and data or 'Kendaraan ini tidak tersedia atau kamu tidak punya izin.')
    end

    local hash = joaat(vehicle.model)
    if not lib.requestModel(hash, 10000) then
        return notify('Model kendaraan gagal dimuat.')
    end

    local veh = CreateVehicle(hash, data.x, data.y, data.z, data.w, true, false)
    SetModelAsNoLongerNeeded(hash)
    if veh == 0 then return notify('Gagal memunculkan kendaraan.') end

    SetVehicleNumberPlateText(veh, data.plate)
    SetVehicleOnGroundProperly(veh)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehicleModKit(veh, 0)
    if vehicle.livery and vehicle.livery >= 0 then
        applyLivery(veh, vehicle.livery)
    end
    applyPerformance(veh)
    if vehicle.custom then
        applyCustom(veh, vehicle.custom)
    end
    pcall(function() exports.LegacyFuel:SetFuel(veh, 100.0) end)
    TaskWarpPedIntoVehicle(cache.ped, veh, -1)

    local networked = pcall(lib.waitFor, function()
        if NetworkGetEntityIsNetworked(veh) then return true end
    end, 'kendaraan tidak tersinkron', 5000)

    if not networked or not lib.callback.await('sm_jobrental:register', false, VehToNet(veh)) then
        if DoesEntityExist(veh) then DeleteEntity(veh) end
        return notify('Gagal mendaftarkan kendaraan sewa.')
    end

    notify('Kendaraan berhasil disewa.', 'success')
end

---@param key string
---@param menuId string
local function openReturnMenu(key, menuId)
    local list = lib.callback.await('sm_jobrental:list', false, key) or {}
    local options = {}

    for i = 1, #list do
        local rental = list[i]
        options[i] = {
            title = 'Kembalikan ' .. rental.label,
            icon = 'trash',
            onSelect = function()
                local returned = lib.callback.await('sm_jobrental:return', false, rental.netId)
                notify(returned and 'Kendaraan telah dikembalikan.' or 'Kendaraan sudah tidak ada.', returned and 'success' or 'error')
                openReturnMenu(key, menuId)
            end,
        }
    end

    if #options == 0 then
        options[1] = { title = 'Tidak ada kendaraan disewa.', icon = 'ban', disabled = true }
    end

    lib.registerContext({ id = menuId .. ':return', title = 'Kendaraan Disewa', menu = menuId, options = options })
    lib.showContext(menuId .. ':return')
end

---@param key string
---@param point table
---@param title string
---@param vehicles table[]
---@param menuId string
local function openMenu(key, point, title, vehicles, menuId)
    lib.registerContext({
        id = menuId,
        title = title,
        options = {
            {
                title = 'Sewa Kendaraan',
                icon = 'car',
                onSelect = function()
                    local options = {}
                    for i = 1, #vehicles do
                        options[i] = rentOption(key, vehicles[i], point)
                    end
                    lib.registerContext({ id = menuId .. ':rent', title = 'Pilih Kendaraan', menu = menuId, options = options })
                    lib.showContext(menuId .. ':rent')
                end,
            },
            {
                title = 'Kendaraan Disewa',
                icon = 'list',
                onSelect = function() openReturnMenu(key, menuId) end,
            },
        },
    })
    lib.showContext(menuId)
end

CreateThread(function()
    local addPed = exports[cache.resource]

    for key, point in pairs(config.points) do
        if point.zone then
            local zone = point.zone
            local menuId = 'sm_jobrental:' .. key
            ox_target:addBoxZone({
                coords = zone.coords,
                size = zone.size,
                rotation = zone.rotation,
                options = {
                    {
                        name = 'sm_jobrental_' .. key,
                        icon = 'fas fa-car',
                        label = zone.label,
                        onSelect = function() openMenu(key, point, point.label, point.vehicles, menuId) end,
                    },
                },
            })
        end

        if point.peds then
            for i = 1, #point.peds do
                local ped = point.peds[i]
                local menuId = ('sm_jobrental:%s:%d'):format(key, i)
                local label = point.cid and ('Sewa ' .. point.label) or ped.label or 'Sewa Kendaraan'

                addPed:addPed({
                    model = PED_MODEL,
                    coords = { ped.coords },
                    renderDistance = 30.0,
                    animation = PED_ANIM,
                    prop = PED_PROP,
                    interactOptions = {
                        {
                            label = label,
                            icon = 'car',
                            distance = DISTANCE,
                            onSelect = function() openMenu(key, point, ped.label or point.label, ped.vehicles, menuId) end,
                        },
                    },
                })
            end
        end
    end
end)
