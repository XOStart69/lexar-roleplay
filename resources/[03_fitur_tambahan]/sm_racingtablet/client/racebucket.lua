local cfg = Config.RaceBucket

if not cfg or not cfg.enabled then return end

local currentBucket -- key of the location we're currently bucketed into, nil if none
local peds = {}     -- [key] = ped handle

local function spawnNpc(location)
    local ped = peds[location.key]
    if ped and DoesEntityExist(ped) then return end

    local model = lib.requestModel(location.npc.model, 10000)
    if not model then return end

    ped = CreatePed(0, model, location.npc.coords.x, location.npc.coords.y, location.npc.coords.z - 1.0,
        location.npc.coords.w, false, false)
    SetModelAsNoLongerNeeded(model)

    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityAsMissionEntity(ped, true, true)

    peds[location.key] = ped

    exports.rhd_interact:addLocalEntity(ped, {
        {
            label = cfg.enterLabel,
            icon = cfg.icon,
            distance = location.npc.interactDistance,
            canInteract = function()
                return not currentBucket
            end,
            onSelect = function()
                TriggerTokenEvent('sm_racingtablet:server:enterRaceBucket', location.key)
            end,
        },
        {
            label = cfg.leaveLabel,
            icon = cfg.icon,
            distance = location.npc.interactDistance,
            canInteract = function()
                return currentBucket == location.key
            end,
            onSelect = function()
                TriggerTokenEvent('sm_racingtablet:server:leaveRaceBucket')
            end,
        },
    })
end

local function despawnNpc(key)
    local ped = peds[key]
    if ped and DoesEntityExist(ped) then
        DeleteEntity(ped)
    end
    peds[key] = nil
end

CreateThread(function()
    for _, location in ipairs(cfg.locations) do
        local point = lib.points.new({
            coords = location.npc.coords.xyz,
            distance = location.npc.renderDistance,
        })

        function point:onEnter()
            spawnNpc(location)
        end

        function point:onExit()
            despawnNpc(location.key)
        end

        if location.blip.enabled then
            local blip = AddBlipForCoord(location.npc.coords.x, location.npc.coords.y, location.npc.coords.z)
            SetBlipSprite(blip, location.blip.sprite)
            SetBlipColour(blip, location.blip.color)
            SetBlipScale(blip, location.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(location.blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

RegisterNetEvent('sm_racingtablet:client:raceBucketDenied', function()
    lib.notify({
        title = 'Race Bucket',
        description = Lang('race_bucket_no_item'),
        type = 'error',
    })
end)

RegisterNetEvent('sm_racingtablet:client:raceBucketChanged', function(key)
    currentBucket = key
    lib.notify({
        title = 'Race Bucket',
        description = key and Lang('race_bucket_entered') or Lang('race_bucket_left'),
        type = key and 'success' or 'inform',
    })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for key in pairs(peds) do
            despawnNpc(key)
        end
    end
end)
