local IsPedSwimmingUnderWater = IsPedSwimmingUnderWater
local Wait = Wait
local floor = math.floor

local MAX_OXYGEN = 600
local MASK_MODEL = `p_d_scuba_mask_s`
local TANK_MODEL = `p_s_scuba_tank_s`
local ANIM_DICT = 'clothingshirt'

local oxygen = 0
local wearing = false
local busy = false
local gear = { mask = 0, tank = 0 }

local function deleteGear()
    for key, entity in pairs(gear) do
        if entity ~= 0 and DoesEntityExist(entity) then
            DetachEntity(entity, false, true)
            DeleteEntity(entity)
        end

        gear[key] = 0
    end
end

local function playGearAnim()
    if not lib.requestAnimDict(ANIM_DICT, 5000) then return end

    TaskPlayAnim(cache.ped, ANIM_DICT, 'try_shirt_positive_d', 8.0, 1.0, -1, 49, 0, false, false, false)
    RemoveAnimDict(ANIM_DICT)
end

local function takeOff()
    deleteGear()
    wearing = false

    local ped = cache.ped
    SetEnableScuba(ped, false)
    SetPedMaxTimeUnderwater(ped, 1.0)
end

---@param model number
---@param ped number
---@param bone number
---@param offsetX number
---@param offsetY number
---@return number
local function attachProp(model, ped, bone, offsetX, offsetY)
    local prop = CreateObject(model, 1.0, 1.0, 1.0, true, true, false)

    SetEntityCollision(prop, false, false)
    SetEntityCanBeDamaged(prop, false)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, bone), offsetX, offsetY, 0.0, 180.0, 90.0, 0.0, false, true, false, true, 2, true)

    return prop
end

local function oxygenLoop()
    local shown = -1

    while wearing do
        local ped = cache.ped

        if IsPedSwimmingUnderWater(ped) then
            oxygen = oxygen - 1

            if oxygen <= 0 then
                oxygen = 0
                takeOff()
                lib.notify({ description = 'Oksigen habis!', type = 'error' })
                break
            end

            local percent = floor(oxygen / MAX_OXYGEN * 100)

            if percent ~= shown then
                shown = percent
                lib.showTextUI(('%d%% Oxygen'):format(percent), {
                    position = 'right-center',
                    icon = 'lungs',
                })
            end
        elseif shown ~= -1 then
            shown = -1
            lib.hideTextUI()
        end

        Wait(1000)
    end

    if shown ~= -1 then
        lib.hideTextUI()
    end
end

local function putOn()
    if oxygen <= 0 then
        return lib.notify({ description = 'Isi tabung oksigen terlebih dahulu.', type = 'error' })
    end

    playGearAnim()

    local done = lib.progressBar({
        duration = 5000,
        label = 'Memakai perlengkapan selam...',
        canCancel = true,
        disable = { car = true, combat = true },
    })

    ClearPedTasks(cache.ped)

    if not done then return end

    if not lib.requestModel(MASK_MODEL, 10000) or not lib.requestModel(TANK_MODEL, 10000) then
        return lib.notify({ description = 'Gagal memuat perlengkapan selam.', type = 'error' })
    end

    deleteGear()

    local ped = cache.ped
    gear.mask = attachProp(MASK_MODEL, ped, 12844, 0.0, 0.0)
    gear.tank = attachProp(TANK_MODEL, ped, 24818, -0.25, -0.25)

    SetModelAsNoLongerNeeded(MASK_MODEL)
    SetModelAsNoLongerNeeded(TANK_MODEL)
    SetEnableScuba(ped, true)
    SetPedMaxTimeUnderwater(ped, 2000.0)

    wearing = true
    CreateThread(oxygenLoop)
end

local function remove()
    playGearAnim()

    local done = lib.progressBar({
        duration = 5000,
        label = 'Melepas perlengkapan selam...',
        canCancel = true,
        disable = { car = true, combat = true },
    })

    ClearPedTasks(cache.ped)

    if not done then return end

    takeOff()
    lib.notify({ description = 'Perlengkapan selam dilepas.' })
end

RegisterNetEvent('sm_diving:client:useGear', function()
    if busy then return end

    busy = true

    local ok, err = pcall(wearing and remove or putOn)

    busy = false

    if not ok then
        lib.print.error(err)
    end
end)

RegisterNetEvent('sm_diving:client:fill', function()
    oxygen = MAX_OXYGEN
    lib.notify({ description = 'Tabung oksigen terisi penuh silahkan pakai diving gear.', type = 'success' })
end)

lib.callback.register('sm_diving:client:oxygen', function()
    return floor(oxygen / MAX_OXYGEN * 100)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource or not wearing then return end

    lib.hideTextUI()
    takeOff()
end)
