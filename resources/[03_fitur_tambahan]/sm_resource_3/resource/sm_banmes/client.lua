local config = localmodule 'config'

local peds = {}
local nearby = {}

---@param index number
local function register(index)
    local job = QBPlayerData.job

    if job and job.name == config.job then
        return lib.notify({ description = 'Kamu sudah dalam job Banmes.', type = 'error' })
    end

    lib.progressBar({
        duration = 3000,
        label = 'Mendaftarkan...',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
    })

    ClearPedTasks(cache.ped)
    TriggerTokenEvent('sm_banmes:server:register', index)
end

---@param index number
local function removePed(index)
    local ped = peds[index]
    peds[index] = nil

    if ped and DoesEntityExist(ped) then
        DeleteEntity(ped)
    end
end

---@param index number
---@param location vector4
local function spawnPed(index, location)
    local model = config.pedModel
    if peds[index] or not lib.requestModel(model, 10000) then return end
    if not nearby[index] or peds[index] then return end

    local ped = CreatePed(0, model, location.x, location.y, location.z - 1.0, location.w, false, true)
    SetModelAsNoLongerNeeded(model)

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    peds[index] = ped
end

for i = 1, #config.locations do
    local location = config.locations[i]

    lib.points.new({
        coords = location.xyz,
        distance = config.pedDistance,
        onEnter = function()
            nearby[i] = true
            spawnPed(i, location)
        end,
        onExit = function()
            nearby[i] = nil
            removePed(i)
        end,
    })

    ox_target:addBoxZone({
        coords = location.xyz,
        size = vec3(1, 1, 2),
        rotation = 45,
        options = {
            {
                name = ('sm_banmes:%d'):format(i),
                icon = 'fa-solid fa-id-card',
                label = 'Daftar Banmes',
                onSelect = function()
                    register(i)
                end
            }
        }
    })
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for i = 1, #config.locations do
        removePed(i)
    end
end)
