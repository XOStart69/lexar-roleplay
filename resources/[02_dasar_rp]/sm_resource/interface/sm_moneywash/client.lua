local Config = localmodule 'config.shared'

interface.init(false)

local CreateThread = CreateThread
local SetTimeout = SetTimeout
local Wait = Wait
local GetGameTimer = GetGameTimer
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local IsEntityDead = IsEntityDead
local HasAnimEventFired = HasAnimEventFired
local SetEntityVisible = SetEntityVisible
local NetworkCreateSynchronisedScene = NetworkCreateSynchronisedScene
local NetworkAddPedToSynchronisedScene = NetworkAddPedToSynchronisedScene
local NetworkAddEntityToSynchronisedScene = NetworkAddEntityToSynchronisedScene
local NetworkStartSynchronisedScene = NetworkStartSynchronisedScene
local sformat = string.format
local ssub = string.sub
local mfloor = math.floor

local IMAGE_BASE = 'nui://ox_inventory/web/images/%s.png'
local GRAB_DICT = 'anim@heists@ornate_bank@grab_cash'
local BAG_MODEL = `hei_p_m_bag_var22_arm_s`
local CASH_MODEL = `hei_prop_heist_cash_pile`
local CASH_APPEAR = `CASH_APPEAR`
local CASH_DESTROY = `RELEASE_CASH_DESTROY`
local INTRO_TIME = 1750
local EXIT_TIME = 2000
local FINISH_BUFFER = 250
local locations = Config.Locations

local uiOpen = false
local washing = false
local cancelRequested = false
local activeIndex = nil
local pendingPayload = nil
local bagEntity = 0
local cashEntity = 0
local zones = {}
local itemInfo = {}

---@param description string
---@param notifyType? string
local function notify(description, notifyType)
    lib.notify({ title = 'Cuci Uang', description = description, type = notifyType or 'inform' })
end

---@param location MoneyWashLocation
---@return boolean
local function hasAccess(location)
    if location.isPublic then return true end

    local job = QBPlayerData.job
    if not job then return false end

    local jobName, level = job.name, job.grade.level
    local jobs = location.jobs
    if jobs then
        for i = 1, #jobs do
            local entry = jobs[i]
            if jobName == entry.name and level >= entry.minGrade then return true end
        end
        return false
    end

    return jobName == location.job and level >= (location.minGrade or 0)
end

---@param name string
---@return table
local function getItemInfo(name)
    local info = itemInfo[name]
    if info then return info end

    local data = ox_items and ox_items[name]
    local image = data and data.client and data.client.image
    if image then
        local prefix = ssub(image, 1, 4)
        if prefix ~= 'http' and prefix ~= 'nui:' then
            image = sformat('nui://ox_inventory/web/images/%s', image)
        end
    else
        image = sformat(IMAGE_BASE, name)
    end

    info = { name = name, label = data and data.label or name, image = image }
    itemInfo[name] = info
    return info
end

---@param payload table
---@return table
local function decoratePayload(payload)
    local list = payload.exchanges
    for i = 1, #list do
        local exchange = list[i]
        exchange.from = getItemInfo(exchange.fromItem)
        exchange.to = getItemInfo(exchange.toItem)
    end
    return payload
end

local function closeUI()
    if not uiOpen then return end
    uiOpen = false
    pendingPayload = nil

    interface.focus(false, false)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    SetTimeout(50, function()
        if not uiOpen then interface.hide() end
    end)
end

---@param index number
local function openUI(index)
    if uiOpen or washing then return end

    local ok, payload = lib.callback.await('sm_moneywash:open', false, index)
    if not ok then
        notify(payload or 'Tidak bisa membuka menu cuci uang.', 'error')
        return
    end

    activeIndex = index
    pendingPayload = decoratePayload(payload)
    uiOpen = true

    if not interface.show() then
        uiOpen = false
        pendingPayload = nil
        return
    end

    interface.focus(true, true)
end

local function deleteWashProps()
    if bagEntity ~= 0 and DoesEntityExist(bagEntity) then DeleteEntity(bagEntity) end
    if cashEntity ~= 0 and DoesEntityExist(cashEntity) then DeleteEntity(cashEntity) end
    bagEntity = 0
    cashEntity = 0
end

---@param origin vector3
---@param heading number
---@param pedClip string
---@param bagClip string
local function playScene(origin, heading, pedClip, bagClip)
    local scene = NetworkCreateSynchronisedScene(origin.x, origin.y, origin.z, 0.0, 0.0, heading, 2, true, false, 1065353216, 0, 1.3)
    NetworkAddPedToSynchronisedScene(cache.ped, scene, GRAB_DICT, pedClip, 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(bagEntity, scene, GRAB_DICT, bagClip, 4.0, -8.0, 1)
    NetworkStartSynchronisedScene(scene)
end

---@param index number
---@return vector3? origin
---@return number? heading
local function prepareScene(index)
    local loaded = pcall(lib.requestAnimDict, GRAB_DICT, 5000)
        and pcall(lib.requestModel, BAG_MODEL, 5000)
        and pcall(lib.requestModel, CASH_MODEL, 5000)
    if not loaded then return end

    local ped = cache.ped
    local pedCoords = GetEntityCoords(ped)
    local target = locations[index].coords
    local dx, dy = target.x - pedCoords.x, target.y - pedCoords.y
    local pedHeading = (dx * dx + dy * dy > 0.09) and GetHeadingFromVector_2d(dx, dy) or GetEntityHeading(ped)

    local baseRotation = GetAnimInitialOffsetRotation(GRAB_DICT, 'intro', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 2)
    local sceneHeading = pedHeading - baseRotation.z
    local offset = GetAnimInitialOffsetPosition(GRAB_DICT, 'intro', 0.0, 0.0, 0.0, 0.0, 0.0, sceneHeading, 0, 2)
    local origin = pedCoords - offset

    bagEntity = CreateObject(BAG_MODEL, pedCoords.x, pedCoords.y, pedCoords.z, true, true, false)
    cashEntity = CreateObject(CASH_MODEL, pedCoords.x, pedCoords.y, pedCoords.z, true, false, false)
    SetModelAsNoLongerNeeded(BAG_MODEL)
    SetModelAsNoLongerNeeded(CASH_MODEL)

    SetEntityVisible(cashEntity, false, false)
    SetEntityCollision(cashEntity, false, false)
    SetEntityInvincible(cashEntity, true)
    AttachEntityToEntity(cashEntity, ped, GetPedBoneIndex(ped, 60309), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true)

    return origin, sceneHeading
end

---@param duration number
---@param index number
local function runWash(duration, index)
    washing = true
    cancelRequested = false

    local ped = cache.ped
    FreezeEntityPosition(ped, true)
    ox_target:disableTargeting(true)

    local origin, sceneHeading = prepareScene(index)
    local animated = origin ~= nil
    local grabLength = animated and mfloor(GetAnimDuration(GRAB_DICT, 'grab') * 1000) or 0
    if grabLength < 1000 then grabLength = 30000 end

    if animated then
        playScene(origin, sceneHeading, 'intro', 'bag_intro')
    end

    local startedAt = GetGameTimer()
    local deadline = startedAt + duration + FINISH_BUFFER
    local grabbing = false
    local stageAt = startedAt
    local cashVisible = false
    local completed = false

    while true do
        local now = GetGameTimer()
        if now >= deadline then
            completed = true
            break
        end
        if cancelRequested or IsEntityDead(ped) then break end

        if animated then
            if (not grabbing and now - stageAt >= INTRO_TIME) or (grabbing and now - stageAt >= grabLength) then
                playScene(origin, sceneHeading, 'grab', 'bag_grab')
                grabbing = true
                stageAt = now
            end

            if not cashVisible and HasAnimEventFired(ped, CASH_APPEAR) then
                SetEntityVisible(cashEntity, true, false)
                cashVisible = true
            elseif cashVisible and HasAnimEventFired(ped, CASH_DESTROY) then
                SetEntityVisible(cashEntity, false, false)
                cashVisible = false
            end
        end

        Wait(0)
    end

    closeUI()

    if completed then
        local ok, message = lib.callback.await('sm_moneywash:finish', false)
        notify(message or (ok and 'Berhasil.' or 'Penukaran gagal.'), ok and 'success' or 'error')
    else
        TriggerTokenEvent('sm_moneywash:cancel')
        notify('Penukaran uang dibatalkan!', 'error')
    end

    if animated then
        if cashEntity ~= 0 then SetEntityVisible(cashEntity, false, false) end
        if completed and not IsEntityDead(ped) then
            playScene(origin, sceneHeading, 'exit', 'bag_exit')
            Wait(EXIT_TIME)
        end
        deleteWashProps()
        if not IsEntityDead(ped) then ClearPedTasks(ped) end
        RemoveAnimDict(GRAB_DICT)
    end

    FreezeEntityPosition(ped, false)
    ox_target:disableTargeting(false)
    washing = false
end

interface.callback('ready', function(_, cb)
    cb(pendingPayload or {})
end)

interface.callback('start', function(data, cb)
    CreateThread(function()
        if washing or type(data) ~= 'table' then
            cb({ ok = false, message = 'Tidak bisa memulai pencucian.' })
            return
        end

        local ok, result = lib.callback.await('sm_moneywash:start', false, activeIndex, data.exchange, tonumber(data.amount))
        if not ok then
            cb({ ok = false, message = result or 'Tidak bisa memulai pencucian.' })
            return
        end

        cb({ ok = true, duration = result })
        runWash(result, activeIndex)
    end)
end)

interface.callback('cancel', function(_, cb)
    cb({})
    if washing then cancelRequested = true end
end)

interface.callback('close', function(_, cb)
    cb({})
    if washing then return end
    closeUI()
end)

for index = 1, #locations do
    local location = locations[index]
    zones[index] = ox_target:addSphereZone({
        coords = location.coords,
        radius = location.radius,
        debug = false,
        options = {
            {
                name = sformat('sm_moneywash_%d', index),
                icon = 'fas fa-money-bill-wave',
                label = 'Cuci Uang',
                distance = location.distance or 2.0,
                canInteract = function()
                    return not washing and hasAccess(location)
                end,
                onSelect = function()
                    CreateThread(function() openUI(index) end)
                end,
            },
        },
    })
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    if uiOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    if washing then
        deleteWashProps()
        FreezeEntityPosition(cache.ped, false)
        ClearPedTasks(cache.ped)
        ox_target:disableTargeting(false)
    end

    for i = 1, #zones do
        ox_target:removeZone(zones[i])
    end
end)
