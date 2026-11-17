local config = localmodule 'config.shared'

local GetEntityCoords = GetEntityCoords
local SetEntityCoords = SetEntityCoords
local SetEntityHeading = SetEntityHeading
local DrawMarker = DrawMarker
local IsControlJustPressed = IsControlJustPressed
local GetInvokingResource = GetInvokingResource

local spots = config.spots
local startPoint = config.start
local startCoords = startPoint.xyz
local leashDistance = config.leashDistance

local broomModel = `prop_tool_broom`
local sweepDict = 'anim@amb@drug_field_workers@rake@male_a@base'

local active = false
local session = 0
local busy = false
local remaining = 0
local textShown = false
local point, broom, blip

---@param message string
---@param nType string?
local function notify(message, nType)
    lib.notify({ title = 'Piket', description = message, type = nType or 'info' })
end

local function updateInfo()
    infoUI.show({
        id = 'sm_piket',
        title = 'Piket',
        icon = 'fa-solid fa-broom',
        description = ('Sisa piket: [kbd]%d[/kbd] kali'):format(remaining),
    })
end

---@return boolean
local function isDead()
    local meta = QBPlayerData.metadata
    return meta and (meta.isdead or meta.inlaststand) or false
end

local function hideText()
    if not textShown then return end
    textShown = false
    lib.hideTextUI()
end

local function clearPoint()
    if point then
        point:remove()
        point = nil
    end
    if blip then
        RemoveBlip(blip)
        blip = nil
    end
    hideText()
end

---@param coords vector3
local function createBlip(coords)
    local blipConfig = config.blip
    blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, blipConfig.sprite)
    SetBlipDisplay(blip, 2)
    SetBlipScale(blip, blipConfig.scale)
    SetBlipColour(blip, blipConfig.color)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(blipConfig.label)
    EndTextCommandSetBlipName(blip)
end

---@param state boolean
local function sweepEmote(state)
    local ped = cache.ped

    if state then
        lib.requestAnimDict(sweepDict, 2000)
        lib.requestModel(broomModel, 2000)
        broom = CreateObject(broomModel, 0.0, 0.0, 0.0, true, true, false)
        AttachEntityToEntity(broom, ped, GetPedBoneIndex(ped, 28422), -0.01, 0.04, -0.03, 0.0, 0.0, 0.0, true, false, false, false, 2, true)
        TaskPlayAnim(ped, sweepDict, 'base', 3.0, 3.0, -1, 1, 0, false, false, false)
        SetModelAsNoLongerNeeded(broomModel)
        RemoveAnimDict(sweepDict)
        return
    end

    ClearPedTasks(ped)
    if broom and DoesEntityExist(broom) then
        DetachEntity(broom, true, false)
        DeleteEntity(broom)
    end
    broom = nil
end

local setSpot

---@param index number
local function doSweep(index)
    busy = true
    hideText()

    local spot = spots[index]
    SetEntityHeading(cache.ped, spot.w)
    sweepEmote(true)

    local done = lib.progressCircle({
        duration = config.sweepDuration,
        position = 'bottom',
        label = 'Menyapu..',
        useWhileDead = false,
        canCancel = false,
        disable = { move = true, car = true, combat = true },
    })

    sweepEmote(false)

    if not done or not active then
        busy = false
        return
    end

    local left, nextIndex = lib.callback.await('sm_piket:server:complete', false)
    busy = false

    if not left then
        return notify('Gagal, coba sapu lagi di titik yang ditandai.', 'error')
    end

    if left > 0 and nextIndex then
        remaining = left
        updateInfo()
        setSpot(nextIndex)
    end
end

---@param index number
function setSpot(index)
    clearPoint()

    local spot = spots[index]
    createBlip(spot.xyz)
    point = lib.points.new({
        coords = spot.xyz,
        distance = 60,
        nearby = function(self)
            if point ~= self or not active then return end

            local coords = self.coords
            DrawMarker(21, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 140, 12, 199, 190, false, true, 2, true, nil, nil, false)

            if busy then return end

            if self.currentDistance <= 1.5 then
                if not textShown then
                    textShown = true
                    lib.showTextUI('[E] - Menyapu', { icon = 'broom', position = 'left-center' })
                end
                if IsControlJustPressed(0, 38) then
                    busy = true
                    CreateThread(function() doSweep(index) end)
                end
            else
                hideText()
            end
        end,
    })
end

local function leashLoop()
    local id = session
    CreateThread(function()
        while active and id == session do
            local ped = cache.ped
            if not isDead() and #(GetEntityCoords(ped) - startCoords) > leashDistance then
                SetEntityCoords(ped, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
                notify(('Kamu masih punya %d piket lagi.'):format(remaining), 'error')
            end
            Wait(2000)
        end
    end)
end

local function reset()
    active = false
    busy = false
    remaining = 0
    clearPoint()
    sweepEmote(false)
    infoUI.remove('sm_piket')
end

---@param targetId number
---@param count number
local function assign(targetId, count)
    local ok, message = lib.callback.await('sm_piket:server:assign', false, targetId, count)
    notify(message or 'Gagal.', ok and 'success' or 'error')
end

---@param targetId number
local function openCountMenu(targetId)
    local options, size = {}, 0
    local counts = config.counts

    for i = 1, #counts do
        local count = counts[i]
        size += 1
        options[size] = {
            title = ('%d kali'):format(count),
            icon = 'broom',
            onSelect = function() assign(targetId, count) end,
        }
    end

    size += 1
    options[size] = {
        title = 'Jumlah lain',
        icon = 'pen',
        onSelect = function()
            local input = lib.inputDialog('Jumlah Piket', {
                { type = 'number', label = 'Berapa kali', required = true, min = 1, max = config.maxCount },
            })
            local count = input and tonumber(input[1])
            if count then assign(targetId, count) end
        end,
    }

    lib.registerContext({
        id = 'sm_piket_count',
        title = ('Piket - ID %d'):format(targetId),
        menu = 'sm_piket_players',
        options = options,
    })
    lib.showContext('sm_piket_count')
end

local function openMenu()
    local list = lib.callback.await('sm_piket:server:nearby', false)
    if not list then return end

    local selfId = cache.serverId
    local options, size = {
        {
            title = ('Diri Sendiri (ID: %d)'):format(selfId),
            description = active and 'Sedang piket' or nil,
            icon = 'user-check',
            disabled = active,
            onSelect = function() openCountMenu(selfId) end,
        },
    }, 1

    for i = 1, #list do
        local entry = list[i]
        local id = entry.id
        size += 1
        options[size] = {
            title = ('ID: %d'):format(id),
            description = entry.busy and 'Sedang piket' or ('Jarak: %.1fm'):format(entry.distance),
            icon = entry.busy and 'user-clock' or 'user',
            disabled = entry.busy,
            onSelect = function() openCountMenu(id) end,
        }
    end

    if size == 1 then
        options[2] = { title = 'Tidak ada player terdekat', icon = 'user-xmark', disabled = true }
    end

    lib.registerContext({
        id = 'sm_piket_players',
        title = 'Pilih Player Piket',
        options = options,
    })
    lib.showContext('sm_piket_players')
end

RegisterNetEvent('sm_piket:client:openMenu', function()
    if GetInvokingResource() then return end
    openMenu()
end)

RegisterNetEvent('sm_piket:client:begin', function(left, spotIndex, isNew)
    if GetInvokingResource() then return end

    reset()
    active = true
    session += 1
    remaining = left

    local ped = cache.ped
    SetEntityCoords(ped, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityHeading(ped, startPoint.w)

    notify(isNew and ('Kamu dihukum piket %d kali.'):format(left) or ('Kamu masih punya %d piket lagi.'):format(left), 'error')

    updateInfo()
    setSpot(spotIndex)
    leashLoop()
end)

RegisterNetEvent('sm_piket:client:finish', function()
    if GetInvokingResource() then return end
    reset()
    notify('Piket selesai.', 'success')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', reset)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    reset()
end)
