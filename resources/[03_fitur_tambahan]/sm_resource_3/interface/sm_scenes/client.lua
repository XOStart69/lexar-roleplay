local config = localmodule 'config'
local scene = localmodule 'modules.scene'
local infoui = exports.rhd_infoui
local hasFrame = interface.init(false)

local Wait = Wait
local tonumber = tonumber
local pairs = pairs
local sgsub = string.gsub
local ssub = string.sub
local rad = math.rad
local sin = math.sin
local cos = math.cos
local abs = math.abs
local GetEntityCoords = GetEntityCoords
local GetScreenCoordFromWorldCoord = GetScreenCoordFromWorldCoord
local GetFinalRenderedCamCoord = GetFinalRenderedCamCoord
local GetGameplayCamFov = GetGameplayCamFov
local GetGameplayCamRot = GetGameplayCamRot
local GetGameplayCamCoord = GetGameplayCamCoord
local SetTextScale = SetTextScale
local SetTextFont = SetTextFont
local SetTextColour = SetTextColour
local SetTextProportional = SetTextProportional
local SetTextWrap = SetTextWrap
local SetTextCentre = SetTextCentre
local SetTextDropshadow = SetTextDropshadow
local SetTextOutline = SetTextOutline
local BeginTextCommandGetWidth = BeginTextCommandGetWidth
local EndTextCommandGetWidth = EndTextCommandGetWidth
local BeginTextCommandDisplayText = BeginTextCommandDisplayText
local EndTextCommandDisplayText = EndTextCommandDisplayText
local AddTextComponentSubstringPlayerName = AddTextComponentSubstringPlayerName
local GetRenderedCharacterHeight = GetRenderedCharacterHeight
local DrawSprite = DrawSprite
local DrawLine = DrawLine
local DrawMarker = DrawMarker
local StartExpensiveSynchronousShapeTestLosProbe = StartExpensiveSynchronousShapeTestLosProbe
local GetShapeTestResult = GetShapeTestResult
local IsControlJustReleased = IsControlJustReleased
local DisableControlAction = DisableControlAction
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity

local MAX_DISTANCE = config.maxDistance
local WRITE_MS = config.writeMs
local INFO_ID = 'sm_scenes:place'
local TXD = 'scenes'
local KEY_CONFIRM = 38
local KEY_CANCEL = 177
local LASER = { r = 38, g = 187, b = 183, a = 220 }

---@type table<string, integer>
local fontIds = {}
for i = 1, #config.fonts do
    local font = config.fonts[i]

    if font.file then
        RegisterFontFile(font.file)
        fontIds[font.key] = RegisterFontId(font.name)
    else
        fontIds[font.key] = font.id
    end
end

local DEFAULT_FONT = fontIds[config.defaults.font] or 4

---@class PreparedScene
---@field id? integer
---@field coords vector3
---@field text string
---@field font integer
---@field size number
---@field r integer
---@field g integer
---@field b integer
---@field shadow boolean
---@field outline boolean
---@field sprite? string
---@field br integer
---@field bg integer
---@field bb integer
---@field ba integer
---@field bx number
---@field by number
---@field bw number
---@field bh number

---@type table<integer, CPoint>
local points = {}
---@type PreparedScene?
local preview = nil
local placing = false
local editing = false
local mounted = false
local ready = false
local submitting = false
local editorContext = nil

---@param hex string
---@return integer, integer, integer
local function rgb(hex)
    return tonumber(ssub(hex, 2, 3), 16) or 255, tonumber(ssub(hex, 4, 5), 16) or 255, tonumber(ssub(hex, 6, 7), 16) or 255
end

---@param data SceneStyle
---@param coords vector3
---@param id? integer
---@return PreparedScene
local function prepare(data, coords, id)
    local r, g, b = rgb(data.colour)
    local br, bg, bb = rgb(data.backgroundColour)
    local text = data.text ~= '' and sgsub(data.text, '\n', '~n~') or 'Tulis sesuatu...'

    return {
        id = id,
        coords = coords,
        text = text,
        font = fontIds[data.font] or DEFAULT_FONT,
        size = data.fontSize,
        r = r,
        g = g,
        b = b,
        shadow = data.shadow,
        outline = data.outline,
        sprite = data.background ~= 'none' and data.background or nil,
        br = br,
        bg = bg,
        bb = bb,
        ba = data.backgroundAlpha,
        bx = data.backgroundX,
        by = data.backgroundY,
        bw = data.backgroundWidth,
        bh = data.backgroundHeight,
    }
end

---@param s PreparedScene
---@param scale number
local function applyTextStyle(s, scale)
    SetTextScale(0.0, scale)
    SetTextFont(s.font)
    SetTextColour(s.r, s.g, s.b, 255)
    SetTextProportional(true)
    SetTextWrap(0.0, 1.0)
    SetTextCentre(true)

    if s.shadow then
        SetTextDropshadow(1, 0, 0, 0, 255)
    end

    if s.outline then
        SetTextOutline()
    end
end

---@param s PreparedScene
local function drawScene(s)
    local c = s.coords
    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(c.x, c.y, c.z)

    if not onScreen then return end

    local distance = #(c - GetFinalRenderedCamCoord())

    if distance < 0.5 then distance = 0.5 end

    local scale = 4.0 / distance * (75.0 / GetGameplayCamFov()) * s.size

    if s.sprite then
        applyTextStyle(s, scale)
        BeginTextCommandGetWidth('STRING')
        AddTextComponentSubstringPlayerName(s.text)

        local width = EndTextCommandGetWidth(s.font) + 0.005
        local height = GetRenderedCharacterHeight(scale, s.font) + 0.003

        DrawSprite(TXD, s.sprite, sx + s.bx * scale, sy + s.by * scale, width + s.bw * scale, height + s.bh * scale, 0.0, s.br, s.bg, s.bb, s.ba)
    end

    applyTextStyle(s, scale)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(s.text)
    EndTextCommandDisplayText(sx, sy)
end

---@param id integer
local function removePoint(id)
    local point = points[id]

    if not point then return end

    point:remove()
    points[id] = nil
end

---@param data table
local function addPoint(data)
    local coords = scene.coords(data.coords)
    local id = tonumber(data.id)

    if not coords or not id then return end

    removePoint(id)

    local style = scene.style(data)
    local prepared = prepare(style, coords, id)
    local point = lib.points.new({
        coords = coords,
        distance = style.viewDistance,
    })

    function point:nearby()
        drawScene(prepared)
    end

    points[id] = point
end

local function clearPoints()
    for id in pairs(points) do
        removePoint(id)
    end
end

---@return boolean, vector3
local function cameraRay()
    local rot = GetGameplayCamRot(2)
    local origin = GetGameplayCamCoord()
    local rx, rz = rad(rot.x), rad(rot.z)
    local pitch = abs(cos(rx))
    local tx = origin.x - sin(rz) * pitch * MAX_DISTANCE
    local ty = origin.y + cos(rz) * pitch * MAX_DISTANCE
    local tz = origin.z + sin(rx) * MAX_DISTANCE
    local handle = StartExpensiveSynchronousShapeTestLosProbe(origin.x, origin.y, origin.z, tx, ty, tz, 1 | 16, cache.ped, 4)
    local _, hit, coords = GetShapeTestResult(handle)

    return hit == true or hit == 1, coords
end

---@param dict string
---@param anim string
---@param props { model: string, bone: integer, offset: number[] }[]
---@return fun()
local function playTool(dict, anim, props)
    lib.requestAnimDict(dict)

    local ped = cache.ped
    local spawned = {}

    for i = 1, #props do
        local prop = props[i]
        local model = lib.requestModel(prop.model)
        local o = prop.offset
        local entity = CreateObject(model, 0.0, 0.0, 0.0, false, false, false)

        AttachEntityToEntity(entity, ped, GetPedBoneIndex(ped, prop.bone), o[1], o[2], o[3], o[4], o[5], o[6], true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded(model)
        spawned[i] = entity
    end

    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 51, 0, false, false, false)
    RemoveAnimDict(dict)

    return function()
        StopAnimTask(ped, dict, anim, 8.0)

        for i = 1, #spawned do
            local entity = spawned[i]

            if DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
        end
    end
end

local stopToolAnim = nil

local function stopTool()
    if not stopToolAnim then return end

    stopToolAnim()
    stopToolAnim = nil
end

local WRITE_PROPS = {
    { model = 'prop_notepad_01', bone = 18905, offset = { 0.1, 0.02, 0.05, 10.0, 0.0, 0.0 } },
    { model = 'prop_pencil_01', bone = 58866, offset = { 0.11, -0.02, 0.001, -120.0, 0.0, 0.0 } },
}

local ERASE_PROPS = {
    { model = 'prop_sponge_01', bone = 28422, offset = { 0.0, 0.0, -0.01, 90.0, 0.0, 0.0 } },
}

---@param action string
---@param data? any
local function send(action, data)
    if ready then
        interface.send({ action = action, data = data })
    end
end

local function unmountLater()
    SetTimeout(150, function()
        if editing or not mounted then return end

        mounted = false
        ready = false
        interface.hide()
    end)
end

local function closeEditor()
    if not editing then return end

    editing = false
    preview = nil
    editorContext = nil
    send('close')
    interface.focus(false, false)
    unmountLater()
end

local function previewLoop()
    while editing do
        if preview then
            drawScene(preview)
        end

        Wait(0)
    end
end

---@param coords vector3
local function openEditor(coords)
    if not hasFrame then return end

    local context = lib.callback.await('sm_scenes:server:context', false)

    if type(context) ~= 'table' then return end

    editing = true
    preview = prepare(scene.style(config.defaults), coords)
    editorContext = {
        coords = coords,
        payload = {
            fonts = config.fonts,
            backgrounds = config.backgrounds,
            defaults = config.defaults,
            maxDistance = MAX_DISTANCE,
            maxDuration = config.maxDuration,
            maxText = config.maxText,
            admin = context.admin == true,
            used = tonumber(context.used) or 0,
            max = tonumber(context.max) or config.maxScenes,
        },
    }

    CreateThread(previewLoop)

    if ready then
        send('open', editorContext.payload)
        interface.focus(true, true)
    elseif not mounted then
        mounted = true
        interface.show()
    end
end

local function stopPlacing()
    if not placing then return end

    placing = false
    infoui:remove(INFO_ID)
end

local function placeLoop()
    infoui:show({
        id = INFO_ID,
        title = 'Pasang Scene',
        icon = 'fa-solid fa-pen-nib',
        description = 'Arahkan ke dinding atau lantai\n[kbd]E[/kbd] Pilih lokasi   [kbd]Backspace[/kbd] Batal',
    })

    while placing do
        local hit, coords = cameraRay()

        if hit then
            local origin = GetEntityCoords(cache.ped)

            DrawLine(origin.x, origin.y, origin.z, coords.x, coords.y, coords.z, LASER.r, LASER.g, LASER.b, LASER.a)
            DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.08, 0.08, 0.08, LASER.r, LASER.g, LASER.b, LASER.a, false, true, 2, false, nil, nil, false)
        end

        DisableControlAction(0, 200, true)

        if IsControlJustReleased(0, KEY_CANCEL) then
            stopPlacing()
        elseif IsControlJustReleased(0, KEY_CONFIRM) then
            if hit then
                stopPlacing()
                openEditor(coords)
            else
                lib.notify({ title = 'Scene', description = 'Arahkan ke permukaan yang lebih dekat.', type = 'error' })
            end
        end

        Wait(0)
    end
end

RegisterNetEvent('sm_scenes:client:place', function()
    if source == '' or placing or editing then return end

    placing = true
    CreateThread(placeLoop)
end)

RegisterNetEvent('sm_scenes:client:all', function(list)
    if source == '' or type(list) ~= 'table' then return end

    clearPoints()

    for i = 1, #list do
        addPoint(list[i])
    end
end)

RegisterNetEvent('sm_scenes:client:add', function(data)
    if source == '' or type(data) ~= 'table' then return end

    addPoint(data)
end)

RegisterNetEvent('sm_scenes:client:remove', function(ids)
    if source == '' or type(ids) ~= 'table' then return end

    for i = 1, #ids do
        removePoint(ids[i])
    end
end)

RegisterNetEvent('sm_scenes:client:erase', function(duration)
    if source == '' or stopToolAnim then return end

    stopToolAnim = playTool('amb@world_human_maid_clean@', 'base', ERASE_PROPS)

    local finished = lib.progressBar({
        duration = tonumber(duration) or config.eraseMs,
        label = 'Menghapus scene...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    })

    stopTool()
    TriggerServerEvent('sm_scenes:server:erase', finished == true)
end)

RegisterNetEvent('sm_scenes:client:confirmBulk', function(texts, radius)
    if source == '' or type(texts) ~= 'table' then return end

    local lines = {}
    local shown = #texts < 10 and #texts or 10

    for i = 1, shown do
        lines[i] = ('- %s'):format(texts[i] ~= '' and texts[i] or 'Tanpa teks')
    end

    if #texts > shown then
        lines[#lines + 1] = ('- dan %d lainnya'):format(#texts - shown)
    end

    local answer = lib.alertDialog({
        header = 'Hapus Scene',
        content = ('Ditemukan **%d scene** dalam radius **%d meter**:\n\n%s\n\nHapus semuanya?'):format(#texts, tonumber(radius) or 0, table.concat(lines, '\n')),
        centered = true,
        cancel = true,
        labels = { confirm = 'Hapus', cancel = 'Batal' },
    })

    if answer == 'confirm' then
        TriggerServerEvent('sm_scenes:server:confirmBulk')
    end
end)

AddEventHandler('sm_scenes:client:forceClose', function()
    stopPlacing()
    closeEditor()
    stopTool()
end)

if hasFrame then
    interface.callback('ready', function(_, cb)
        ready = true
        cb({})

        if editing and editorContext then
            send('open', editorContext.payload)
            interface.focus(true, true)
        end
    end)

    interface.callback('close', function(_, cb)
        cb({})

        if not submitting then
            closeEditor()
        end
    end)

    interface.callback('preview', function(data, cb)
        cb({})

        if not editing or not editorContext then return end

        preview = prepare(scene.style(data), editorContext.coords)
    end)

    interface.callback('submit', function(data, cb)
        if not editing or not editorContext or submitting or type(data) ~= 'table' then
            return cb({ ok = false, message = 'Editor tidak aktif.' })
        end

        local style = scene.style(data.style)

        if style.text == '' then
            return cb({ ok = false, message = 'Teks scene tidak boleh kosong.' })
        end

        submitting = true
        stopToolAnim = playTool('missheistdockssetup1clipboard@base', 'base', WRITE_PROPS)

        local finished = lib.progressBar({
            duration = WRITE_MS,
            label = 'Menulis scene...',
            useWhileDead = false,
            canCancel = false,
            disable = { move = true, car = true, combat = true },
        })

        stopTool()

        if not finished or not editing then
            submitting = false
            return cb({ ok = false, message = 'Penulisan dibatalkan.' })
        end

        local result = lib.callback.await('sm_scenes:server:create', false, editorContext.coords, style, data.duration, data.neverExpire == true)

        submitting = false

        if type(result) ~= 'table' or not result.ok then
            return cb({ ok = false, message = type(result) == 'table' and result.message or 'Server tidak merespons, coba lagi.' })
        end

        cb({ ok = true })
        closeEditor()
        lib.notify({ title = 'Scene', description = 'Scene berhasil dipasang.', type = 'success' })
    end)
end

CreateThread(function()
    if not pcall(lib.requestStreamedTextureDict, TXD) then
        lib.print.error('texture dict "scenes" tidak termuat, latar scene tidak akan tampil')
    end

    for _ = 1, 240 do
        if NetworkIsPlayerActive(cache.playerId) then break end

        Wait(500)
    end

    TriggerServerEvent('sm_scenes:server:sync')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    stopTool()

    if placing then
        infoui:remove(INFO_ID)
    end

    if editing then
        SetNuiFocus(false, false)
    end
end)
