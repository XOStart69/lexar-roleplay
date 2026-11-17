local ped = require "core.ped"
local settings = require "core.settings"
local editor = require "core.editor"
local clothing = require "features.clothing"
local menus = require "config.menu"

local HAT = "hat"
local RELAY_INTERVAL = 100
local SUBMIT_TIMEOUT = 20000

---@class BarberMenuOptions
---@field target number?
---@field relay boolean?
---@field appearance table?
---@field hairBlacklist HairBlacklist?
---@field hatWorn boolean?
---@field title string?
---@field subtitle string?
---@field prices table<string, number>?
---@field bundles table<string, string>?
---@field action 'pay'|'bill'|'view'?
---@field methods string[]?
---@field onChange fun(values: table)?
---@field onHat fun(hidden: boolean)?
---@field onSubmit fun(values: table<string, number>, method: string?)?
---@field onCancel fun()?

---@class BarberSession
---@field target number
---@field relay boolean
---@field viewer boolean
---@field original PedAppearance
---@field options BarberMenuOptions
---@field blacklist HairBlacklist?
---@field hat { hidden: boolean, available: boolean }
---@field sent table<string, table>?
---@field queued table?
---@field pending fun(result: table)?
---@field silent boolean?

---@type BarberSession?
local session

local barber = {}

---@param base PedAppearance
---@param fields table?
---@return PedAppearance
local function withFields(base, fields)
    if type(fields) ~= "table" then return base end

    local merged = table.clone(base)

    if type(fields.hair) == "table" then merged.hair = fields.hair end

    if type(fields.headOverlays) == "table" then
        local overlays = table.clone(base.headOverlays)

        for name, overlay in pairs(fields.headOverlays) do
            overlays[name] = overlay
        end

        merged.headOverlays = overlays
    end

    if type(fields.eyeColor) == "number" then merged.eyeColor = fields.eyeColor end

    return merged
end

---@param entity number
---@param fields table
local function applyFields(entity, fields)
    if type(fields.headOverlays) == "table" then ped.setHeadOverlays(entity, fields.headOverlays) end
    if type(fields.eyeColor) == "number" then ped.setEyeColor(entity, fields.eyeColor) end
    if type(fields.hair) == "table" then ped.setHair(entity, fields.hair) end
end

---@param a table?
---@param b table?
---@return boolean
local function sameOverlay(a, b)
    return a ~= nil and b ~= nil
        and a.style == b.style
        and a.opacity == b.opacity
        and a.color == b.color
        and a.secondColor == b.secondColor
end

---@param current BarberSession
---@param fields table
local function queue(current, fields)
    local pending = current.queued or {}

    if fields.hair then pending.hair = fields.hair end
    if fields.eyeColor then pending.eyeColor = fields.eyeColor end

    if fields.headOverlays then
        pending.headOverlays = pending.headOverlays or {}

        for name, overlay in pairs(fields.headOverlays) do
            pending.headOverlays[name] = overlay
        end
    end

    current.queued = pending
end

---@param current BarberSession
local function flush(current)
    local values = current.queued

    if not values then return end

    current.queued = nil

    if current.options.onChange then
        pcall(current.options.onChange, values)
    end
end

---@param current BarberSession
---@param result PedAppearance|boolean?
local function finish(current, result)
    if session == current then session = nil end

    local pending = current.pending

    if pending then
        current.pending = nil
        pending({ success = false })
    end

    if result == true then return end

    if not current.relay and not current.viewer then
        applyFields(cache.ped, current.original)
    end

    if not current.silent and current.options.onCancel then
        pcall(current.options.onCancel)
    end
end

function barber.pushHat()
    local current = session

    if not current or not current.relay then return end

    SendNuiMessage(json.encode({
        action = "clothing_status",
        data = { [HAT] = { hidden = current.hat.hidden, swap = false, available = current.hat.available } }
    }))
end

---@return boolean
function barber.active()
    return session ~= nil
end

---@return boolean
function barber.busy()
    return session ~= nil and session.pending ~= nil
end

---@param options BarberMenuOptions
---@return boolean
function barber.open(options)
    if session or editor.active() or type(options) ~= "table" then return false end

    local viewer = options.action == "view"
    local target = not viewer and options.target or cache.ped
    local relay = not viewer and options.relay == true and target ~= cache.ped

    if not DoesEntityExist(target) then return false end
    if relay and type(options.appearance) ~= "table" then return false end

    ---@type PedAppearance
    local original

    if relay then
        original = options.appearance --[[@as PedAppearance]]
    else
        original = withFields(ped.get(cache.ped), options.appearance)

        if options.appearance then
            applyFields(cache.ped, original)
        end
    end

    local menu = lib.table.deepclone(menus.default)

    menu.headOverlays = true
    menu.barber = {
        title = options.title or "",
        subtitle = options.subtitle or "",
        prices = options.prices or {},
        bundles = options.bundles or {},
        action = (options.action == "bill" or viewer) and options.action or "pay",
        methods = options.methods or {}
    }

    ---@type BarberSession
    local current = {
        target = target,
        relay = relay,
        viewer = viewer,
        original = original,
        options = options,
        blacklist = relay and options.hairBlacklist or nil,
        hat = { hidden = false, available = options.hatWorn == true },
        sent = relay and table.clone(original.headOverlays or {}) or nil
    }

    session = current

    CreateThread(function()
        local opened = editor.open(menu, function(result)
            finish(current, result)
        end, { target = target, original = original })

        if not opened then
            if session == current then session = nil end

            if current.options.onCancel then pcall(current.options.onCancel) end

            return
        end

        if not relay then return end

        barber.pushHat()

        while session == current do
            Wait(RELAY_INTERVAL)

            if session == current then flush(current) end
        end
    end)

    return true
end

---@param notify boolean?
function barber.close(notify)
    local current = session

    if not current then return end

    current.silent = notify ~= true

    editor.close()
end

---@return table?
function barber.settings()
    local current = session

    if not current then return end

    local all = settings.all(current.target)

    if current.relay then
        all.hair = settings.hair(current.target, current.original.hair and current.original.hair.style, current.blacklist)
    end

    return all
end

---@param hair PedHair
---@return table
function barber.changeHair(hair)
    local current = session

    if not current or current.viewer or type(hair) ~= "table" then return settings.hair(cache.ped) end

    if current.relay then
        queue(current, { hair = hair })

        return settings.hair(current.target, hair.style, current.blacklist)
    end

    ped.setHair(cache.ped, hair)

    return settings.hair(cache.ped)
end

---@param overlays PedHeadOverlays
function barber.changeOverlays(overlays)
    local current = session

    if not current or current.viewer or type(overlays) ~= "table" then return end

    if not current.relay then
        ped.setHeadOverlays(cache.ped, overlays)

        return
    end

    local changed, any = {}, false

    for name, overlay in pairs(overlays) do
        if type(overlay) == "table" and not sameOverlay(current.sent[name], overlay) then
            changed[name] = overlay
            current.sent[name] = overlay
            any = true
        end
    end

    if any then queue(current, { headOverlays = changed }) end
end

---@param value number
---@return number
function barber.changeEyeColor(value)
    local current = session

    if not current or current.viewer or type(value) ~= "number" then return ped.getEyeColor(cache.ped) end

    if current.relay then
        queue(current, { eyeColor = value })

        return value
    end

    ped.setEyeColor(cache.ped, value)

    return ped.getEyeColor(cache.ped)
end

---@param items string[]
---@return boolean
function barber.toggleHat(items)
    local current = session

    if not current or current.viewer or type(items) ~= "table" or #items ~= 1 or items[1] ~= HAT then return false end

    if not current.relay then
        return clothing.toggleGroup({ HAT })
    end

    if not current.hat.available then return false end

    current.hat.hidden = not current.hat.hidden

    if current.options.onHat then
        pcall(current.options.onHat, current.hat.hidden)
    end

    barber.pushHat()

    return true
end

---@param data { values: table<string, number>?, method: string? }?
---@param cb fun(result: table)
function barber.submit(data, cb)
    local current = session

    if not current or current.pending or not current.options.onSubmit then
        return cb({ success = false })
    end

    if current.relay then flush(current) end

    current.pending = cb

    local values = type(data) == "table" and type(data.values) == "table" and data.values or {}
    local method = type(data) == "table" and type(data.method) == "string" and data.method or nil

    if not pcall(current.options.onSubmit, values, method) then
        current.pending = nil

        return cb({ success = false, message = locale("barber.failed") })
    end

    SetTimeout(SUBMIT_TIMEOUT, function()
        if current.pending ~= cb then return end

        current.pending = nil
        cb({ success = false, message = locale("barber.timeout") })
    end)
end

---@param result { success: boolean, message: string? }?
---@return boolean
function barber.resolve(result)
    local current = session

    if not current or not current.pending then return false end

    local cb = current.pending --[[@as fun(result: table)]]
    local success = type(result) == "table" and result.success == true

    current.pending = nil
    cb({ success = success, message = type(result) == "table" and result.message or nil })

    if success then
        CreateThread(function()
            if session == current then editor.close(true) end
        end)
    end

    return true
end

---@return { appearance: PedAppearance, hairBlacklist: HairBlacklist, hatWorn: boolean }
function barber.snapshot()
    local hat = clothing.status()[HAT]

    return {
        appearance = ped.get(cache.ped),
        hairBlacklist = settings.hairBlacklist(cache.ped),
        hatWorn = hat ~= nil and hat.available == true
    }
end

---@param fields table
---@return boolean
function barber.apply(fields)
    if type(fields) ~= "table" then return false end

    applyFields(cache.ped, fields)

    if session and session.viewer then
        SendNuiMessage(json.encode({
            action = "barber_sync",
            data = {
                hair = ped.getHair(cache.ped),
                headOverlays = ped.getHeadOverlays(cache.ped),
                eyeColor = ped.getEyeColor(cache.ped),
                hairSettings = settings.hair(cache.ped)
            }
        }))
    end

    return true
end

---@param hidden boolean
---@return boolean
function barber.setHat(hidden)
    if clothing.hidden(HAT) == (hidden == true) then return true end

    return clothing.toggleGroup({ HAT })
end

return barber
