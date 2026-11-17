local config = localmodule 'config'

local ITEM = config.item
local TARGET_DISTANCE = config.targetDistance
local DURATION = config.duration
local SKILL_DIFFICULTY = config.skillCheck.difficulty
local SKILL_INPUTS = config.skillCheck.inputs
local ANIM_DICT = config.anim.dict
local ANIM_CLIP = config.anim.clip

local NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local GetPlayerServerId = GetPlayerServerId

local busy = false

---@param entity number
---@return number?
local function serverIdFromPed(entity)
    local player = NetworkGetPlayerIndexFromPed(entity)
    if player == -1 then return end

    return GetPlayerServerId(player)
end

local function stopAnim()
    ClearPedTasks(cache.ped)
    RemoveAnimDict(ANIM_DICT)
end

---@param target number
local function destroyGps(target)
    if busy then return end
    busy = true

    if not lib.callback.await('sm_gpsjammer:server:start', false, target) then
        busy = false
        return
    end

    lib.requestAnimDict(ANIM_DICT, 2000)
    TaskPlayAnim(cache.ped, ANIM_DICT, ANIM_CLIP, 8.0, -8.0, -1, 1, 0, false, false, false)

    local success = lib.skillCheck(SKILL_DIFFICULTY, SKILL_INPUTS) and lib.progressBar({
        duration = DURATION,
        label = 'Menghancurkan GPS...',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    })

    stopAnim()

    if success then
        TriggerTokenEvent('sm_gpsjammer:server:finish')
    else
        TriggerTokenEvent('sm_gpsjammer:server:cancel')
        lib.notify({ title = 'GPS Jammer', description = 'Gagal menghancurkan GPS', type = 'error' })
    end

    busy = false
end

ox_target:addGlobalPlayer({
    {
        name = 'sm_gpsjammer:destroy',
        icon = 'fa-solid fa-satellite-dish',
        label = 'Hancurkan GPS',
        distance = TARGET_DISTANCE,
        canInteract = function(_, distance)
            return not busy and distance <= TARGET_DISTANCE and ox_inventory:Search('count', ITEM) > 0
        end,
        onSelect = function(data)
            local target = serverIdFromPed(data.entity)
            if target then
                destroyGps(target)
            end
        end
    }
})
