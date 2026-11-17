local config = localmodule 'config'

local Wait = Wait
local GetGameTimer = GetGameTimer
local GetFinalRenderedCamCoord = GetFinalRenderedCamCoord
local GetFinalRenderedCamFov = GetFinalRenderedCamFov
local World3dToScreen2d = World3dToScreen2d
local DrawSprite = DrawSprite
local GetAspectRatio = GetAspectRatio
local min, max = math.min, math.max
local sgsub, sformat, sbyte = string.gsub, string.format, string.byte

local WIDTH, HEIGHT = 512, 160
local DUI_ASPECT = WIDTH / HEIGHT
local SIZE_FACTOR = 2.3
local MIN_WIDTH, MAX_WIDTH = 0.04, 0.35
local READY_DELAY = 300
local LIFT = vec3(0.0, 0.0, 0.3)
local RENDER_DISTANCE = config.renderDistance
local DURATION = config.duration
local MAX_CARDS = config.maxCards
local PAGE = ('nui://%s/interface/sm_exiting/build/index.html'):format(cache.resource)

---@type { dui: number, txd: string, tex: string, coords: vector3, readyAt: number, expires: number }[]
local slots = {}
local drawing = false

---@param char string
---@return string
local function escapeChar(char)
    return sformat('%%%02X', sbyte(char))
end

---@param value any
---@return string
local function encode(value)
    return (sgsub(tostring(value or ''), '[^%w%-_%.~]', escapeChar))
end

---@param data table
---@return string
local function buildUrl(data)
    return ('%s?name=%s&meta=%s&reason=%s&type=%s&status=LEFT'):format(
        PAGE, encode(data.name), encode(data.meta), encode(data.reason), encode(data.type)
    )
end

---@param url string
---@return table
local function acquireSlot(url)
    local now = GetGameTimer()
    local oldest

    for i = 1, #slots do
        local slot = slots[i]
        if slot.expires <= now then
            SetDuiUrl(slot.dui, url)
            return slot
        end
        if not oldest or slot.expires < oldest.expires then oldest = slot end
    end

    if #slots >= MAX_CARDS then
        SetDuiUrl(oldest.dui, url)
        return oldest
    end

    local index = #slots + 1
    local dui = CreateDui(url, WIDTH, HEIGHT)
    local slot = {
        dui = dui,
        txd = 'sm_exiting_txd_' .. index,
        tex = 'sm_exiting_tex_' .. index,
        expires = 0,
        readyAt = 0,
    }
    CreateRuntimeTextureFromDuiHandle(CreateRuntimeTxd(slot.txd), slot.tex, GetDuiHandle(dui))
    slots[index] = slot
    return slot
end

local function drawLoop()
    if drawing then return end
    drawing = true

    CreateThread(function()
        while true do
            local now = GetGameTimer()
            local alive, drawn = false, false
            local cam = GetFinalRenderedCamCoord()
            local fovFactor = 100 / GetFinalRenderedCamFov()
            local screenAspect = GetAspectRatio(false)

            for i = 1, #slots do
                local slot = slots[i]
                if slot.expires > now then
                    alive = true
                    local coords = slot.coords
                    local dist = #(cam - coords)

                    if now >= slot.readyAt and dist <= RENDER_DISTANCE and IsDuiAvailable(slot.dui) then
                        local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
                        if onScreen then
                            local w = min(MAX_WIDTH, max(MIN_WIDTH, SIZE_FACTOR / (max(dist, 1.0) * fovFactor)))
                            DrawSprite(slot.txd, slot.tex, x, y, w, w * screenAspect / DUI_ASPECT, 0.0, 255, 255, 255, 255)
                            drawn = true
                        end
                    end
                elseif slot.expires > 0 then
                    slot.expires = 0
                    SetDuiUrl(slot.dui, 'about:blank')
                end
            end

            if not alive then break end
            Wait(drawn and 0 or 250)
        end

        drawing = false
    end)
end

RegisterNetEvent('sm_exiting:client:show', function(data)
    if source == '' or type(data) ~= 'table' or not data.coords then return end

    local slot = acquireSlot(buildUrl(data))
    local now = GetGameTimer()

    slot.coords = vector3(data.coords.x, data.coords.y, data.coords.z) + LIFT
    slot.readyAt = now + READY_DELAY
    slot.expires = now + DURATION

    drawLoop()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    for i = 1, #slots do
        DestroyDui(slots[i].dui)
    end
end)
