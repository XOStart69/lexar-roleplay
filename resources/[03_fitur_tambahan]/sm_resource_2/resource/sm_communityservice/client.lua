local config = localmodule 'config'
local infoui = exports.rhd_infoui

local Wait = Wait
local GetEntityCoords = GetEntityCoords
local IsControlJustPressed = IsControlJustPressed
local DrawMarker = DrawMarker

local INFO_ID = 'sm_cs:sweep'
local BROOM_MODEL = `prop_tool_broom`
local SWEEP_DICT = 'anim@amb@drug_field_workers@rake@male_a@base'

local tasksRemaining = 0
local inService = false
local spotPoint
local broom
local sweeping = false
local hintShown = false

---@param text string
---@param kind? string
local function notify(text, kind)
    lib.notify({ title = 'Pelayanan Masyarakat', description = text, type = kind or 'inform' })
end

local function setHint(show)
    if show == hintShown then return end
    hintShown = show
    if show then
        infoui:show({ id = INFO_ID, title = 'Pelayanan Masyarakat', icon = 'fa-solid fa-broom', description = '[kbd]E[/kbd] Menyapu' })
    else
        infoui:remove(INFO_ID)
    end
end

local function clearSpot()
    if spotPoint then
        spotPoint:remove()
        spotPoint = nil
    end
    setHint(false)
end

local function holdBroom(state)
    local ped = cache.ped
    if state then
        lib.requestAnimDict(SWEEP_DICT, 2000)
        lib.requestModel(BROOM_MODEL, 2000)
        broom = CreateObject(BROOM_MODEL, 0.0, 0.0, 0.0, true, true, false)
        AttachEntityToEntity(broom, ped, GetPedBoneIndex(ped, 28422), -0.01, 0.04, -0.03, 0.0, 0.0, 0.0, true, false, false, false, 2, true)
        TaskPlayAnim(ped, SWEEP_DICT, 'base', 3.0, 3.0, -1, 1, 0, false, false, false)
        SetModelAsNoLongerNeeded(BROOM_MODEL)
    else
        ClearPedTasks(ped)
        if broom and DoesEntityExist(broom) then
            DetachEntity(broom, true, false)
            DeleteEntity(broom)
        end
        broom = nil
        RemoveAnimDict(SWEEP_DICT)
    end
end

local showSpot

local function sweep()
    if sweeping then return end
    sweeping = true
    setHint(false)
    holdBroom(true)

    local done = lib.progressCircle({
        duration = config.sweepDuration,
        position = 'bottom',
        label = 'Menyapu..',
        useWhileDead = false,
        canCancel = false,
        disable = { move = true, car = true, combat = true },
    })
    holdBroom(false)
    sweeping = false
    if not done then return end

    local remaining, nextSpot = lib.callback.await('sm_cs:server:complete', false)
    if not remaining then return end

    tasksRemaining = remaining
    if remaining > 0 and nextSpot then
        notify(('Sisa pekerjaan: %s'):format(remaining))
        showSpot(nextSpot)
    end
end

---@param index number
showSpot = function(index)
    clearSpot()
    local coords = config.spots[index]
    if not coords then return end

    spotPoint = lib.points.new({ coords = coords, distance = 60.0 })

    function spotPoint:nearby()
        DrawMarker(21, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 0, 204, 201, 190, false, true, 2, true, nil, nil, false)
        local close = self.currentDistance <= 1.5 and not sweeping
        setHint(close)
        if close and IsControlJustPressed(0, 38) then
            sweep()
        end
    end

    function spotPoint:onExit()
        setHint(false)
    end
end

local function leash()
    CreateThread(function()
        local origin, radius, interval = config.start, config.leashRadius, config.leashInterval
        while inService do
            local ped = cache.ped
            local meta = QBPlayerData.metadata or {}
            if #(GetEntityCoords(ped) - origin) > radius and not IsEntityDead(ped) and not meta.inlaststand and not meta.isdead then
                SetEntityCoords(ped, origin.x, origin.y, origin.z, false, false, false, false)
                notify(('Kamu masih ada %s pekerjaan lagi.'):format(tasksRemaining))
            end
            Wait(interval)
        end
    end)
end

RegisterNetEvent('sm_cs:client:start', function(tasks, spot, fresh)
    tasksRemaining = tasks
    local start = config.start
    SetEntityCoords(cache.ped, start.x, start.y, start.z, false, false, false, false)
    notify(fresh and ('Anda dijatuhi hukuman pelayanan masyarakat untuk %s tugas.'):format(tasks)
        or ('Anda masih memiliki %s tugas pelayanan masyarakat.'):format(tasks))
    showSpot(spot)
    if not inService then
        inService = true
        leash()
    end
end)

RegisterNetEvent('sm_cs:client:finish', function()
    inService = false
    tasksRemaining = 0
    clearSpot()
    local finish = config.finish
    SetEntityCoords(cache.ped, finish.x, finish.y, finish.z, false, false, false, false)
    notify('Pelayanan masyarakat Anda sudah berakhir.', 'success')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    inService = false
    tasksRemaining = 0
    clearSpot()
end)

---@param target table
---@param tasks number
---@param reason string
local function confirm(target, tasks, reason)
    lib.registerContext({
        id = 'sm_cs_confirm',
        title = 'Konfirmasi Sanksi',
        options = {
            { title = 'Target: ' .. target.name, description = 'ID: ' .. target.serverId, icon = 'user', disabled = true },
            { title = 'Jumlah Tugas: ' .. tasks, icon = 'list-check', disabled = true },
            { title = 'Alasan: ' .. reason, icon = 'file-lines', disabled = true },
            {
                title = 'Konfirmasi Sanksi',
                icon = 'check',
                onSelect = function()
                    local result = lib.callback.await('sm_cs:server:assign', false, { targetId = target.serverId, tasks = tasks, reason = reason })
                    notify(result.message, result.success and 'success' or 'error')
                end,
            },
            { title = 'Batal', icon = 'xmark' },
        },
    })
    lib.showContext('sm_cs_confirm')
end

---@param target table
local function askDetails(target)
    local input = lib.inputDialog('Sanksi Pelayanan Masyarakat', {
        { type = 'number', label = 'Jumlah Tugas', description = ('1-%s'):format(config.maxTasks), required = true, min = 1, max = config.maxTasks },
        { type = 'input', label = 'Alasan', description = ('%s-%s karakter'):format(config.reason.min, config.reason.max), required = true, placeholder = 'Contoh: Melanggar rambu lalu lintas' },
    })
    if not input then return end

    local tasks = tonumber(input[1])
    local reason = tostring(input[2] or ''):match('^%s*(.-)%s*$')
    if not tasks or tasks < 1 or tasks > config.maxTasks then
        return notify(('Jumlah tugas harus antara 1-%s'):format(config.maxTasks), 'error')
    end
    if #reason < config.reason.min or #reason > config.reason.max then
        return notify(('Alasan harus %s-%s karakter'):format(config.reason.min, config.reason.max), 'error')
    end

    confirm(target, tasks, reason)
end

RegisterNetEvent('sm_cs:client:openMenu', function()
    local nearby = lib.callback.await('sm_cs:server:nearby', false) or {}
    local options = {
        {
            title = 'Diri Sendiri',
            description = 'Berikan sanksi ke diri sendiri',
            icon = 'flask',
            disabled = inService,
            onSelect = function()
                askDetails({ serverId = cache.serverId, name = 'Diri Sendiri' })
            end,
        },
    }

    if #nearby == 0 then
        options[#options + 1] = { title = 'Tidak ada player terdekat', description = ('Jangkauan %sm'):format(config.assignRadius), icon = 'user-xmark', disabled = true }
    end

    for i = 1, #nearby do
        local player = nearby[i]
        options[#options + 1] = {
            title = ('%s (ID: %s)%s'):format(player.name, player.serverId, player.inService and ' (Sedang CS)' or ''),
            description = ('Jarak: %.2fm'):format(player.distance),
            icon = player.inService and 'user-xmark' or 'user',
            disabled = player.inService,
            onSelect = function()
                askDetails(player)
            end,
        }
    end

    lib.registerContext({ id = 'sm_cs_players', title = 'Pilih Target Pelayanan Masyarakat', options = options })
    lib.showContext('sm_cs_players')
end)

AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= cache.resource then return end
    clearSpot()
    if broom and DoesEntityExist(broom) then
        DeleteEntity(broom)
    end
end)
