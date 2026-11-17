local QUIET <const> = 1500
local WATCH <const> = 1000
local RANGE <const> = 100.0
local SHARE_DELAY <const> = 150

---@class SwapClient
local swap = {}

---@type table<string, string>
local stored = {}
---@type table<string, true>?
local fresh = {}
---@type table<number, string | false>
local held = {}
---@type table<integer, { sound: string | false, shop: string }>
local previews = {}
---@type table<number, { sound: string | false, driver: number }>
local applied = {}
local sharing = false

---@param vehicle number
---@return string
local function plateOf(vehicle)
    return GetVehicleNumberPlateText(vehicle):match('^%s*(.-)%s*$')
end

---@param vehicle number
---@param sound string | false
local function apply(vehicle, sound)
    local radio = IsVehicleRadioOn(vehicle)

    ForceUseAudioGameObject(vehicle, sound or GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    applied[vehicle] = { sound = sound, driver = GetPedInVehicleSeat(vehicle, -1) }

    if radio then return end

    CreateThread(function()
        local deadline = GetGameTimer() + QUIET

        while GetGameTimer() < deadline and DoesEntityExist(vehicle) do
            if IsVehicleRadioOn(vehicle) then SetVehRadioStation(vehicle, 'OFF') end

            Wait(0)
        end
    end)
end

---@param vehicle number
---@return string | false
local function wanted(vehicle)
    local sound = held[vehicle]
    if sound ~= nil then return sound end

    local entry = next(previews) and NetworkGetEntityIsNetworked(vehicle) and previews[NetworkGetNetworkIdFromEntity(vehicle)]
    if entry then return entry.sound end

    return swap.current(vehicle)
end

local function sync()
    if not next(stored) and not next(held) and not next(previews) and not next(applied) then return end

    local origin = GetEntityCoords(cache.ped)
    local seen = {}

    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if #(GetEntityCoords(vehicle) - origin) <= RANGE then
            local sound, last = wanted(vehicle), applied[vehicle]

            seen[vehicle] = true

            if sound and (not last or last.sound ~= sound or last.driver ~= GetPedInVehicleSeat(vehicle, -1)) then
                apply(vehicle, sound)
            elseif not sound and last and last.sound then
                apply(vehicle, false)
            end
        end
    end

    for vehicle in pairs(applied) do
        if not seen[vehicle] then applied[vehicle] = nil end
    end

    for vehicle in pairs(held) do
        if not DoesEntityExist(vehicle) then held[vehicle] = nil end
    end
end

---@param vehicle number
---@return string | false
function swap.current(vehicle)
    return stored[plateOf(vehicle)] or false
end

---@param vehicle number
---@param sound string | false
function swap.hold(vehicle, sound)
    held[vehicle] = sound
    apply(vehicle, sound)

    if sharing then return end

    sharing = true

    SetTimeout(SHARE_DELAY, function()
        sharing = false

        local current = held[vehicle]

        if current ~= nil then modules.net.emitLatentServer('sm_custom:server:swapPreview', current) end
    end)
end

---@param vehicle number
function swap.release(vehicle)
    held[vehicle] = nil

    if DoesEntityExist(vehicle) then apply(vehicle, wanted(vehicle)) end
end

RegisterNetEvent('sm_custom:client:swaps', function(saved, unowned)
    if source == '' then return end

    local skip = fresh or {}

    fresh = nil

    for _, list in ipairs({ saved, unowned }) do
        if type(list) == 'table' then
            for plate, sound in pairs(list) do
                if type(plate) == 'string' and type(sound) == 'string' and not skip[plate] then
                    stored[plate] = sound
                end
            end
        end
    end

    sync()
end)

RegisterNetEvent('sm_custom:client:swap', function(plate, sound)
    if source == '' or type(plate) ~= 'string' then return end

    if fresh then fresh[plate] = true end

    stored[plate] = type(sound) == 'string' and sound or nil

    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if plateOf(vehicle) == plate then apply(vehicle, wanted(vehicle)) end
    end
end)

RegisterNetEvent('sm_custom:client:swapPreview', function(id, shop, sound)
    if source == '' or math.type(id) ~= 'integer' or type(shop) ~= 'string' then return end

    local valid = sound == false or type(sound) == 'string'

    previews[id] = valid and modules.areas.inside(shop) and { sound = sound, shop = shop } or nil

    sync()
end)

modules.areas.watch(function(key, inside)
    if inside then return end

    for id, entry in pairs(previews) do
        if entry.shop == key then previews[id] = nil end
    end

    sync()
end)

SetInterval(sync, WATCH)
TriggerServerEvent('sm_custom:server:swaps')

return swap
