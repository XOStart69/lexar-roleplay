local config = localmodule 'config'
local infoui = exports.rhd_infoui
local hasFrame = interface.init(false)

local Wait = Wait
local GetGameTimer = GetGameTimer
local GetCloudTimeAsInt = GetCloudTimeAsInt
local GetEntityCoords = GetEntityCoords
local GetEntityRotation = GetEntityRotation
local GetEntityType = GetEntityType
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local NetworkDoesNetworkIdExist = NetworkDoesNetworkIdExist
local NetworkGetEntityFromNetworkId = NetworkGetEntityFromNetworkId
local NetworkGetEntityIsNetworked = NetworkGetEntityIsNetworked
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local StartExpensiveSynchronousShapeTestLosProbe = StartExpensiveSynchronousShapeTestLosProbe
local GetShapeTestResult = GetShapeTestResult
local GetOffsetFromEntityGivenWorldCoords = GetOffsetFromEntityGivenWorldCoords
local GetHeadingFromVector_2d = GetHeadingFromVector_2d
local SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
local SetEntityRotation = SetEntityRotation
local SetEntityAlpha = SetEntityAlpha
local DisableControlAction = DisableControlAction
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local IsEntityDead = IsEntityDead
local SendDuiMessage = SendDuiMessage
local pairs, type = pairs, type
local mrad, mdeg, msin, mcos, matan, mabs = math.rad, math.deg, math.sin, math.cos, math.atan, math.abs
local jencode = json.encode

local BOMBS = config.bombs
local DETONATOR = config.detonator
local DEFUSE = config.defuse
local PLACE_DISTANCE = config.placeDistance
local ROTATE_STEP = config.rotateStep
local PREVIEW_ALPHA = config.previewAlpha
local DEFUSE_BREAK = DEFUSE.distance + 3.0
local SCREEN = config.screen
local SCREEN_DISTANCE = SCREEN.distance
local SCREEN_URL = ('https://cfx-nui-%s/interface/sm_bomb/web/build/dui.html'):format(cache.resource)
local RAY_FLAGS = 1 | 2 | 16
local INFO_PLACE = 'sm_bomb:place'
local INFO_DETONATOR = 'sm_bomb:detonator'
local DEFUSE_ANIM_DICT, DEFUSE_ANIM_CLIP = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer'

local CONTROL_PLACE, CONTROL_CANCEL, CONTROL_BACK = 38, 73, 177
local CONTROL_SCROLL_UP, CONTROL_SCROLL_DOWN = 241, 242
local CONTROL_ATTACK, CONTROL_AIM = 24, 25
local DETONATOR_CONTROLS = { 24, 25, 140, 141, 142, 257, 263 }

local TIMER_HASHES = {}
for _, data in pairs(BOMBS) do
    if data.timer then
        TIMER_HASHES[joaat(data.model)] = true
    end
end

---@type table<string, { net: integer, kind: string, ends?: integer }>
local known = {}
local knownCount = 0
local placing = false
local armed = false
local heldProp, detonatorProp

local defuseId
local frameMounted = false
local frameReady = false
local pending

local function noop() end

---@param description string
---@param kind? string
local function notify(description, kind)
    lib.notify({ title = 'Bom', description = description, type = kind or 'error' })
end

---@param dict string
---@return boolean
local function loadDict(dict)
    return pcall(lib.requestAnimDict, dict, 3000)
end

---@param model string|integer
---@return integer?
local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if pcall(lib.requestModel, hash, 5000) then
        return hash
    end
end

---@param entity? integer
local function deleteLocal(entity)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

---@param net integer
---@return integer
local function entityFromNet(net)
    if not NetworkDoesNetworkIdExist(net) then return 0 end
    local entity = NetworkGetEntityFromNetworkId(net)
    if entity ~= 0 and DoesEntityExist(entity) then return entity end
    return 0
end

local function flush()
    if not pending then return end
    interface.send(pending)
    pending = nil
    interface.focus(true, true)
end

local function closeFrame()
    defuseId = nil
    pending = nil
    interface.focus(false, false)
    StopAnimTask(cache.ped, DEFUSE_ANIM_DICT, DEFUSE_ANIM_CLIP, 1.0)

    SetTimeout(50, function()
        if defuseId or not frameMounted then return end
        frameMounted = false
        frameReady = false
        interface.hide()
    end)
end

---@param reason? string
local function forceCloseDefuse(reason)
    if not defuseId then return end
    if frameReady then
        interface.send({ action = 'close' })
    end
    closeFrame()
    if reason == 'exploded' then
        notify('Bom meledak!')
    elseif reason == 'removed' then
        notify('Bom sudah tidak ada.', 'inform')
    elseif reason == 'far' then
        notify('Kamu terlalu jauh dari bom.')
    elseif reason == 'idle' then
        notify('Sesi penjinakan berakhir.')
    end
end

---@param id string
local function openDefuse(id)
    if not hasFrame or defuseId or placing or armed then return end

    local ok, data = lib.callback.await('sm_bomb:open', false, id)
    if not ok then return notify(data or 'Gagal membuka defuse kit.') end

    defuseId = id
    pending = { action = 'open', data = data }

    if loadDict(DEFUSE_ANIM_DICT) then
        TaskPlayAnim(cache.ped, DEFUSE_ANIM_DICT, DEFUSE_ANIM_CLIP, 3.0, 3.0, -1, 1, 0, false, false, false)
    end

    if frameReady then
        flush()
    elseif not frameMounted then
        frameMounted = true
        interface.show()
    end

    CreateThread(function()
        while defuseId == id do
            local bomb = known[id]
            local entity = bomb and entityFromNet(bomb.net) or 0
            if entity == 0 or #(GetEntityCoords(cache.ped) - GetEntityCoords(entity)) > DEFUSE_BREAK or IsEntityDead(cache.ped) then
                lib.callback('sm_bomb:close', false, noop, id)
                forceCloseDefuse(entity == 0 and 'removed' or 'far')
                break
            end
            Wait(500)
        end
    end)
end

---@type table<integer, string>
local netToId = {}

---@param entity integer
---@return string?
local function bombIdOf(entity)
    if not entity or entity == 0 or not NetworkGetEntityIsNetworked(entity) then return end
    return netToId[NetworkGetNetworkIdFromEntity(entity)]
end

local BOMB_MODELS = {}
for _, data in pairs(BOMBS) do
    BOMB_MODELS[#BOMB_MODELS + 1] = data.model
end

ox_target:addModel(BOMB_MODELS, {
    {
        name = 'sm_bomb:defuse',
        label = 'Jinakkan Bom',
        icon = 'fa-solid fa-scissors',
        distance = DEFUSE.distance,
        canInteract = function(entity)
            return bombIdOf(entity) ~= nil
        end,
        onSelect = function(data)
            local id = bombIdOf(data.entity)
            if id then openDefuse(id) end
        end,
    },
})

---@param list any
local function syncBombs(list)
    if type(list) ~= 'table' then list = {} end

    local seen = {}
    for i = 1, #list do
        local entry = list[i]
        local id = entry.id
        seen[id] = true
        local current = known[id]
        if not current then
            known[id] = { net = entry.net, kind = entry.kind, ends = entry.ends }
            knownCount = knownCount + 1
            netToId[entry.net] = id
        else
            current.ends = entry.ends
        end
    end

    for id, bomb in pairs(known) do
        if not seen[id] then
            known[id] = nil
            knownCount = knownCount - 1
            if netToId[bomb.net] == id then
                netToId[bomb.net] = nil
            end
            if defuseId == id then
                forceCloseDefuse('removed')
            end
        end
    end

    local current = defuseId and known[defuseId]
    if current and frameReady then
        interface.send({ action = 'update', data = { ends = current.ends } })
    end
end

AddStateBagChangeHandler('smBombs', 'global', function(_, _, value)
    syncBombs(value)
end)

CreateThread(function()
    syncBombs(GlobalState.smBombs)
end)

---@param bombCfg table
local function startHold(bombCfg)
    local hash = loadModel(bombCfg.model)
    if not hash then return end

    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    heldProp = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityCollision(heldProp, false, false)
    local h = bombCfg.hold
    AttachEntityToEntity(heldProp, ped, GetPedBoneIndex(ped, 28422), h.x, h.y, h.z, h.rx, h.ry, h.rz, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(hash)

    local anim = config.holdAnim
    if loadDict(anim.dict) then
        TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, -1, 50, 0, false, false, false)
    end
end

local function stopHold()
    deleteLocal(heldProp)
    heldProp = nil
    local anim = config.holdAnim
    StopAnimTask(cache.ped, anim.dict, anim.clip, 1.0)
end

---@param bombCfg table
---@return integer?, string?
local function askSettings(bombCfg)
    local fields = {}
    if bombCfg.timer then
        fields[1] = {
            type = 'number',
            label = 'Durasi (detik)',
            description = ('Minimal %d detik, maksimal %d detik (%d menit)'):format(config.timer.min, config.timer.max, config.timer.max // 60),
            default = config.timer.default,
            min = config.timer.min,
            max = config.timer.max,
            required = true,
        }
    end
    fields[#fields + 1] = {
        type = 'input',
        label = ('PIN (%d digit)'):format(config.pinLength),
        password = true,
        required = true,
    }

    local input = lib.inputDialog(bombCfg.label, fields)
    if not input then return end

    local timer = bombCfg.timer and tonumber(input[1]) or 0
    local pin = tostring(input[#fields] or '')
    if #pin ~= config.pinLength or not pin:match('^%d+$') then
        notify(('PIN harus %d digit angka.'):format(config.pinLength))
        return
    end

    return timer, pin
end

local camRay = { valid = false }

---@param heading number
---@return table
local function trace(heading)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local rx, rz = mrad(camRot.x), mrad(camRot.z)
    local cx = mabs(mcos(rx))
    local reach = PLACE_DISTANCE + 3.0
    local tx = camCoords.x - msin(rz) * cx * reach
    local ty = camCoords.y + mcos(rz) * cx * reach
    local tz = camCoords.z + msin(rx) * reach

    local ped = cache.ped
    local ray = StartExpensiveSynchronousShapeTestLosProbe(camCoords.x, camCoords.y, camCoords.z, tx, ty, tz, RAY_FLAGS, ped, 7)
    local _, hit, coords, normal, entity = GetShapeTestResult(ray)

    local result = camRay
    result.valid = false
    result.vehicle = nil

    if not (hit == 1 or hit == true) then
        return result
    end

    local pedCoords = GetEntityCoords(ped)
    if #(pedCoords - coords) > PLACE_DISTANCE then
        result.coords = coords
        return result
    end

    local face = GetHeadingFromVector_2d(pedCoords.x - coords.x, pedCoords.y - coords.y) + 180.0 + heading
    local pitch = -mdeg(matan(normal.y, normal.z))
    local roll = mdeg(matan(normal.x, normal.z))

    result.coords = coords + normal * 0.02
    result.rot = vector3(pitch, roll, face)
    result.valid = true

    if entity and entity ~= 0 and DoesEntityExist(entity) and GetEntityType(entity) == 2 then
        if not NetworkGetEntityIsNetworked(entity) then
            result.valid = false
            return result
        end
        result.vehicle = entity
    end

    return result
end

---@param bombCfg table
---@param result table
---@param timer integer
---@param pin string
---@return table
local function buildPayload(bombCfg, result, timer, pin)
    local rot = result.rot
    local payload = { timer = timer, pin = pin }
    local vehicle = result.vehicle

    if vehicle and bombCfg.vehicle then
        local offset = GetOffsetFromEntityGivenWorldCoords(vehicle, result.coords.x, result.coords.y, result.coords.z)
        local vrot = GetEntityRotation(vehicle, 2)
        payload.vehicle = NetworkGetNetworkIdFromEntity(vehicle)
        payload.offset = { x = offset.x, y = offset.y, z = offset.z }
        payload.rot = { x = rot.x - vrot.x, y = rot.y - vrot.y, z = rot.z - vrot.z }
    else
        payload.coords = { x = result.coords.x, y = result.coords.y, z = result.coords.z }
        payload.rot = { x = rot.x, y = rot.y, z = rot.z }
    end

    return payload
end

---@param bombCfg table
---@param result table
---@return boolean
local function plant(bombCfg, result)
    local ped = cache.ped
    local low = result.coords.z < GetEntityCoords(ped).z - 0.5
    local anim = low and config.crouchAnim or config.plantAnim

    return lib.progressBar({
        duration = config.plantDuration,
        label = ('Memasang %s...'):format(bombCfg.label),
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = anim.dict, clip = anim.clip, flag = 1 },
    }) == true
end

---@param slot integer
---@param kind string
local function placeBomb(slot, kind)
    local bombCfg = BOMBS[kind]
    local timer, pin = askSettings(bombCfg)
    if not timer then return end

    local hash = loadModel(bombCfg.model)
    if not hash then return end

    local preview = CreateObject(hash, 0.0, 0.0, 0.0, false, false, false)
    SetEntityCollision(preview, false, false)
    SetEntityAlpha(preview, 0, false)
    FreezeEntityPosition(preview, true)
    startHold(bombCfg)

    infoui:show({
        id = INFO_PLACE,
        title = bombCfg.label,
        icon = 'fa-solid fa-bomb',
        description = '[kbd]E[/kbd] Pasang  [kbd]Scroll[/kbd] Putar  [kbd]X[/kbd] Batal',
    })

    local heading = 0.0
    local nextTrace = 0
    local result = camRay
    local confirmed = false

    while placing do
        DisableControlAction(0, CONTROL_SCROLL_UP, true)
        DisableControlAction(0, CONTROL_SCROLL_DOWN, true)
        DisableControlAction(0, CONTROL_ATTACK, true)
        DisableControlAction(0, CONTROL_AIM, true)
        DisableControlAction(0, CONTROL_BACK, true)

        if IsDisabledControlJustPressed(0, CONTROL_SCROLL_UP) then
            heading = heading + ROTATE_STEP
        elseif IsDisabledControlJustPressed(0, CONTROL_SCROLL_DOWN) then
            heading = heading - ROTATE_STEP
        end

        local now = GetGameTimer()
        if now >= nextTrace then
            nextTrace = now + 30
            result = trace(heading)
            if result.coords then
                SetEntityCoordsNoOffset(preview, result.coords.x, result.coords.y, result.coords.z, false, false, false)
                if result.rot then
                    SetEntityRotation(preview, result.rot.x, result.rot.y, result.rot.z, 2, true)
                end
                SetEntityAlpha(preview, result.valid and PREVIEW_ALPHA or 60, false)
            else
                SetEntityAlpha(preview, 0, false)
            end
        end

        if IsControlJustPressed(0, CONTROL_PLACE) then
            if result.valid and (not result.vehicle or bombCfg.vehicle) then
                confirmed = true
                break
            end
            notify(result.vehicle and 'Bom ini tidak bisa dipasang di kendaraan.' or 'Tidak bisa dipasang di sini.')
        elseif IsControlJustPressed(0, CONTROL_CANCEL) or IsDisabledControlJustPressed(0, CONTROL_BACK) or IsEntityDead(cache.ped) then
            break
        end

        Wait(0)
    end

    infoui:remove(INFO_PLACE)
    deleteLocal(preview)
    SetModelAsNoLongerNeeded(hash)

    if not confirmed then
        stopHold()
        return
    end

    local payload = buildPayload(bombCfg, result, timer, pin)
    local done = plant(bombCfg, result)
    stopHold()
    if not done then return notify('Pemasangan dibatalkan.', 'inform') end

    local ok, reason = lib.callback.await('sm_bomb:place', false, slot, kind, payload)
    if not ok then return notify(reason or 'Gagal memasang bom.') end

    notify(bombCfg.timer and ('%s aktif, meledak dalam %d detik.'):format(bombCfg.label, timer) or ('%s terpasang. Gunakan detonator untuk meledakkan.'):format(bombCfg.label), 'success')
end

RegisterNetEvent('sm_bomb:client:place', function(slot, kind)
    if source == '' or placing or armed or defuseId or not BOMBS[kind] then return end
    if cache.vehicle then return notify('Tidak bisa memasang bom dari dalam kendaraan.') end

    placing = true
    local ok, err = pcall(placeBomb, slot, kind)
    placing = false
    if not ok then
        infoui:remove(INFO_PLACE)
        stopHold()
        lib.print.error(err)
    end
end)

RegisterNetEvent('sm_bomb:client:attach', function(net, vehNet, offset, rot)
    if source == '' then return end

    local entity, vehicle = 0, 0
    for _ = 1, 60 do
        entity, vehicle = entityFromNet(net), entityFromNet(vehNet)
        if entity ~= 0 and vehicle ~= 0 then break end
        Wait(50)
    end
    if entity == 0 or vehicle == 0 then return end

    for _ = 1, 20 do
        if NetworkHasControlOfEntity(entity) then break end
        NetworkRequestControlOfEntity(entity)
        Wait(50)
    end

    FreezeEntityPosition(entity, false)
    AttachEntityToEntity(entity, vehicle, 0, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, false, false, false, false, 2, true)
end)

local function disarm()
    armed = false
    infoui:remove(INFO_DETONATOR)
    deleteLocal(detonatorProp)
    detonatorProp = nil
    StopAnimTask(cache.ped, DETONATOR.anim.dict, DETONATOR.anim.clip, 1.0)
end

RegisterNetEvent('sm_bomb:client:detonator', function(slot)
    if source == '' or armed or placing or defuseId then return end
    armed = true

    local ped = cache.ped
    local hash = loadModel(DETONATOR.model)
    if hash then
        local coords = GetEntityCoords(ped)
        local o = DETONATOR.offset
        detonatorProp = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
        SetEntityCollision(detonatorProp, false, false)
        AttachEntityToEntity(detonatorProp, ped, GetPedBoneIndex(ped, DETONATOR.bone), o.x, o.y, o.z, o.rx, o.ry, o.rz, true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded(hash)
    end

    local anim = DETONATOR.anim
    if loadDict(anim.dict) then
        TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, -1, 50, 0, false, false, false)
    end

    infoui:show({
        id = INFO_DETONATOR,
        title = 'Detonator',
        icon = 'fa-solid fa-tower-broadcast',
        description = '[kbd]Klik Kiri[/kbd] Ledakkan  [kbd]Klik Kanan[/kbd] Simpan',
    })

    local count = #DETONATOR_CONTROLS
    while armed do
        for i = 1, count do
            DisableControlAction(0, DETONATOR_CONTROLS[i], true)
        end

        if IsDisabledControlJustPressed(0, CONTROL_ATTACK) then
            disarm()
            local ok, reason = lib.callback.await('sm_bomb:detonate', false, slot)
            if not ok then notify(reason or 'Detonator gagal.') end
            break
        elseif IsDisabledControlJustPressed(0, CONTROL_AIM) or IsEntityDead(cache.ped) then
            disarm()
            break
        end

        Wait(0)
    end
end)

RegisterNetEvent('sm_bomb:client:explode', function(data)
    if source == '' or type(data) ~= 'table' then return end

    local bombCfg = BOMBS[data.kind]
    if not bombCfg then return end

    local coords = data.coords
    local entity = entityFromNet(data.net)
    if entity ~= 0 then
        coords = GetEntityCoords(entity)
    end

    local ownerPlayer = data.owner and GetPlayerFromServerId(data.owner) or -1
    local ownerPed = ownerPlayer ~= -1 and GetPlayerPed(ownerPlayer) or 0
    local explosion = bombCfg.explosion
    local types = explosion.types

    for i = 1, #types do
        if ownerPed ~= 0 and DoesEntityExist(ownerPed) then
            AddOwnedExplosion(ownerPed, coords.x, coords.y, coords.z, types[i], explosion.damageScale, true, false, explosion.shake)
        else
            AddExplosion(coords.x, coords.y, coords.z, types[i], explosion.damageScale, true, false, explosion.shake)
        end
    end
end)

RegisterNetEvent('sm_bomb:client:fx', function(coords, scale)
    if source == '' or type(coords) ~= 'vector3' then return end
    scale = tonumber(scale) or 1.0

    if not pcall(lib.requestNamedPtfxAsset, 'core', 3000) then return end

    UseParticleFxAssetNextCall('core')
    StartParticleFxNonLoopedAtCoord('exp_grd_grenade_lod', coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, scale * 1.5, false, false, false)

    UseParticleFxAssetNextCall('core')
    local smoke = StartParticleFxLoopedAtCoord('exp_grd_grenade_smoke', coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, scale * 0.8, false, false, false, false)

    SetTimeout(5000, function()
        StopParticleFxLooped(smoke, false)
    end)
end)

RegisterNetEvent('sm_bomb:client:closeDefuse', function(reason)
    if source == '' then return end
    forceCloseDefuse(reason)
end)

local screen = { dui = nil, txdReady = false, replaced = false, bombId = nil, ends = nil, volume = -1, idleSince = 0 }

---@param message table
local function duiSend(message)
    if screen.dui then
        SendDuiMessage(screen.dui, jencode(message))
    end
end

---@return boolean
local function ensureScreen()
    if not screen.dui then
        local dui = CreateDui(SCREEN_URL, SCREEN.width, SCREEN.height)
        local waited = 0
        while not IsDuiAvailable(dui) do
            Wait(100)
            waited = waited + 100
            if waited >= 5000 then
                DestroyDui(dui)
                return false
            end
        end
        screen.dui = dui
        if not screen.txdReady then
            CreateRuntimeTextureFromDuiHandle(CreateRuntimeTxd('sm_bomb_screen'), 'sm_bomb_screen', GetDuiHandle(dui))
            screen.txdReady = true
        end
    end

    if not screen.replaced then
        AddReplaceTexture(SCREEN.txd, SCREEN.texture, 'sm_bomb_screen', 'sm_bomb_screen')
        screen.replaced = true
    end
    return true
end

local function releaseScreen()
    if screen.replaced then
        RemoveReplaceTexture(SCREEN.txd, SCREEN.texture)
        screen.replaced = false
    end
    if screen.bombId then
        duiSend({ action = 'stop' })
        screen.bombId = nil
        screen.ends = nil
        screen.volume = -1
    end
end

local function destroyScreen()
    releaseScreen()
    if screen.dui then
        DestroyDui(screen.dui)
        screen.dui = nil
        screen.txdReady = false
    end
end

CreateThread(function()
    while true do
        local sleep = 1000

        if knownCount > 0 then
            sleep = 250
            local camCoords = GetGameplayCamCoord()
            local bestId, bestDist, bestBomb

            for id, bomb in pairs(known) do
                if bomb.ends then
                    local entity = entityFromNet(bomb.net)
                    if entity ~= 0 and TIMER_HASHES[GetEntityModel(entity)] then
                        local dist = #(camCoords - GetEntityCoords(entity))
                        if dist <= SCREEN_DISTANCE and (not bestDist or dist < bestDist) then
                            bestId, bestDist, bestBomb = id, dist, bomb
                        end
                    end
                end
            end

            if bestId and ensureScreen() then
                screen.idleSince = 0
                if screen.bombId ~= bestId or screen.ends ~= bestBomb.ends then
                    screen.bombId = bestId
                    screen.ends = bestBomb.ends
                    duiSend({ action = 'state', ends = bestBomb.ends, now = GetCloudTimeAsInt() })
                end

                local falloff = 1.0 - bestDist / SCREEN_DISTANCE
                local volume = SCREEN.volume * falloff * falloff
                if mabs(volume - screen.volume) > 0.02 then
                    screen.volume = volume
                    duiSend({ action = 'volume', value = volume })
                end
            else
                releaseScreen()
            end
        else
            releaseScreen()
        end

        if screen.dui and not screen.bombId then
            local now = GetGameTimer()
            if screen.idleSince == 0 then
                screen.idleSince = now
            elseif now - screen.idleSince > 30000 then
                destroyScreen()
                screen.idleSince = 0
            end
        end

        Wait(sleep)
    end
end)

if hasFrame then
    interface.callback('ready', function(_, cb)
        frameReady = true
        flush()
        cb({})
    end)

    interface.callback('decryptStart', function(_, cb)
        local id = defuseId
        if not id then return cb({ ok = false }) end
        local ok, result, wait = lib.callback.await('sm_bomb:decryptStart', false, id)
        cb({ ok = ok == true, cells = ok and result or nil, reason = not ok and result or nil, wait = wait })
    end)

    interface.callback('decryptSubmit', function(data, cb)
        local id = defuseId
        if not id or type(data) ~= 'table' then return cb({ ok = false }) end
        local ok, result, extra = lib.callback.await('sm_bomb:decryptSubmit', false, id, data.cells)
        cb({ ok = ok == true, revealed = ok and result or nil, reason = not ok and result or nil, extra = extra })
    end)

    interface.callback('pin', function(data, cb)
        local id = defuseId
        if not id or type(data) ~= 'table' then return cb({ ok = false }) end
        local ok, reason, extra = lib.callback.await('sm_bomb:pin', false, id, data.pin)
        cb({ ok = ok == true, reason = reason, extra = extra })
        if ok then
            SetTimeout(900, function()
                if defuseId == id then
                    closeFrame()
                    notify('Bom berhasil dijinakkan.', 'success')
                end
            end)
        end
    end)

    interface.callback('close', function(_, cb)
        cb({})
        local id = defuseId
        if not id then return end
        closeFrame()
        lib.callback('sm_bomb:close', false, noop, id)
    end)
end

AddEventHandler('sm_bomb:client:forceClose', function()
    if armed then disarm() end
    if defuseId then
        local id = defuseId
        forceCloseDefuse()
        lib.callback('sm_bomb:close', false, noop, id)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    infoui:remove(INFO_PLACE)
    infoui:remove(INFO_DETONATOR)
    deleteLocal(heldProp)
    deleteLocal(detonatorProp)
    destroyScreen()
    ox_target:removeModel(BOMB_MODELS, 'sm_bomb:defuse')
end)
