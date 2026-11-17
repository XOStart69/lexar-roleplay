if not require 'config.client'.debug then return end

local phone = require 'client.phone'
local select = require 'client.select'
local camera = require 'modules.client.camera'
local nui = require 'modules.client.nui'

local MOCK_LOCATIONS <const> = {
    { id = 'debug_last', label = 'Lokasi Terakhir', type = 'last' },
    { id = 'debug_default', label = 'Pelabuhan', type = 'default' },
    { id = 'debug_vip', label = 'Garasi Kota', type = 'vip' },
    { id = 'debug_house', label = 'Mirror Park No. 12', type = 'house' },
    { id = 'debug_motel', label = 'Avenue Royal Motel - Room 7', type = 'motel' },
}

local freecam = false

local function closePhone()
    phone.close()
    camera.destroy(500)
    FreezeEntityPosition(cache.ped, false)
end

RegisterCommand('smchar_phone', function(_, args)
    CreateThread(function()
        if phone.isOpen() then
            closePhone()
            return
        end

        FreezeEntityPosition(cache.ped, true)

        phone.open(MOCK_LOCATIONS, { name = 'Mode Debug' }, function(id)
            lib.notify({ description = ('phonePick: %s'):format(id), type = 'inform' })
            closePhone()
        end, { child = args[1] == 'bocil' })
    end)
end, false)

RegisterCommand('smchar_phonecal', function()
    if not phone.calibrate() then
        return lib.notify({ description = 'Buka handphone dulu (/smchar_phone atau saat pilih lokasi spawn).', type = 'error' })
    end

    lib.notify({ description = 'Klik tengah target 1, lalu target 2 di layar handphone.', type = 'inform' })
end, false)

---@param origin vector3
---@param heading number
---@param point vector3
---@return vector3
local function toLocal(origin, heading, point)
    local rad = math.rad(heading)
    local dx, dy = point.x - origin.x, point.y - origin.y

    return vec3(dx * math.cos(rad) + dy * math.sin(rad), -dx * math.sin(rad) + dy * math.cos(rad), point.z - origin.z)
end

---@param value vector3
---@return string
local function vec(value)
    return ('vec3(%.2f, %.2f, %.2f)'):format(value.x, value.y, value.z)
end

---@param view { config: table, anchor: vector3, heading: number, label: string }
---@param position vector3
---@param focus vector3
---@param fov number
local function save(view, position, focus, fov)
    local localPosition = toLocal(view.anchor, view.heading, position)
    local localFocus = toLocal(view.anchor, view.heading, focus)
    local line = ('%s = { position = %s, focus = %s, fov = %.1f },'):format(view.label, vec(localPosition), vec(localFocus), fov)

    view.config.position = localPosition
    view.config.focus = localFocus
    view.config.fov = fov

    lib.setClipboard(line)
    print(('[sm_characters] kamera: %s'):format(line))
    lib.notify({ description = 'Nilai kamera disalin ke clipboard dan F8, dipakai sampai resource restart.', type = 'success' })
end

RegisterCommand('smchar_cam', function()
    if freecam then
        freecam = false
        return
    end

    local view = select.view()
    local base = camera.handle()

    if not view or not base then
        return lib.notify({ description = 'Buka layar pilih karakter dulu.', type = 'error' })
    end

    freecam = true

    local position = GetCamCoord(base)
    local rotation = GetCamRot(base, 2)
    local fov = GetCamFov(base)
    local pitch, yaw = rotation.x, rotation.z
    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', position.x, position.y, position.z, pitch, 0.0, yaw, fov, true, 2)

    nui.focus(false)
    RenderScriptCams(true, false, 0, true, false)
    lib.notify({
        description = 'Free-cam: mouse untuk melihat, WASD/Q/E gerak, Shift cepat, scroll FOV, Enter simpan, Backspace keluar.',
        type = 'inform',
        duration = 8000,
    })

    CreateThread(function()
        while freecam do
            DisableAllControlActions(0)

            yaw -= GetDisabledControlNormal(0, 1) * 6.0
            pitch = math.max(-89.0, math.min(89.0, pitch - GetDisabledControlNormal(0, 2) * 6.0))

            local rx, rz = math.rad(pitch), math.rad(yaw)
            local forward = vec3(-math.sin(rz) * math.cos(rx), math.cos(rz) * math.cos(rx), math.sin(rx))
            local right = vec3(math.cos(rz), math.sin(rz), 0.0)
            local speed = (IsDisabledControlPressed(0, 21) and 3.0 or 0.75) * GetFrameTime()

            if IsDisabledControlPressed(0, 32) then position += forward * speed end
            if IsDisabledControlPressed(0, 33) then position -= forward * speed end
            if IsDisabledControlPressed(0, 35) then position += right * speed end
            if IsDisabledControlPressed(0, 34) then position -= right * speed end
            if IsDisabledControlPressed(0, 38) then position += vec3(0.0, 0.0, speed) end
            if IsDisabledControlPressed(0, 44) then position -= vec3(0.0, 0.0, speed) end
            if IsDisabledControlJustPressed(0, 241) then fov = math.max(10.0, fov - 2.0) end
            if IsDisabledControlJustPressed(0, 242) then fov = math.min(90.0, fov + 2.0) end

            SetCamCoord(cam, position.x, position.y, position.z)
            SetCamRot(cam, pitch, 0.0, yaw, 2)
            SetCamFov(cam, fov)

            if IsDisabledControlJustPressed(0, 191) then
                save(view, position, position + forward * 2.0, fov)
            end

            if IsDisabledControlJustPressed(0, 194) then
                freecam = false
            end

            Wait(0)
        end

        SetCamActive(cam, false)
        DestroyCam(cam, false)

        if DoesCamExist(base) then
            SetCamActive(base, true)
        end

        RenderScriptCams(true, false, 0, true, false)

        if select.isActive() then
            nui.focus(true)
        end
    end)
end, false)
