local functions = {}

---@class BlipOptions
---@field coords vector3|vector4 World coordinates for the blip
---@field sprite? integer Blip sprite ID (default: 1)
---@field color? integer Blip color ID (default: 0)
---@field scale? number Blip scale (default: 0.8)
---@field label? string Blip name shown on map (default: 'Blip')
---@field alpha? integer Blip opacity 0-255 (default: 255)
---@field shortRange? boolean Only show when nearby (default: false)
---@field display? integer Blip display type (default: 4)
---@field category? integer Blip category (default: 0)
---@field priority? integer Blip priority (default: 0)
---@field flashes? boolean Whether blip flashes (default: false)
---@field flashTimer? number Duration in ms before flash stops (0 = infinite)

---@class RadiusBlipOptions
---@field coords vector3|vector4 World coordinates for the radius blip center
---@field radius number Radius in units
---@field color? integer Blip color ID (default: 2)
---@field alpha? integer Blip opacity 0-255 (default: 80)
---@field label? string Blip name shown on map

---@class BlipEntry
---@field handle integer Native blip handle
---@field type 'coords'|'radius'
---@field id string Unique identifier

local blips = {}
local idCounter = 0

local function generateId()
    idCounter += 1
    return ('blip_%d_%d'):format(GetGameTimer(), idCounter)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Internal helpers
-- ─────────────────────────────────────────────────────────────────────────────

local function applyBlipOptions(handle, opts)
    SetBlipSprite(handle, opts.sprite or 1)
    SetBlipColour(handle, opts.color or 0)
    SetBlipScale(handle, opts.scale or 0.8)
    SetBlipAlpha(handle, opts.alpha or 255)
    SetBlipDisplay(handle, opts.display or 4)
    SetBlipCategory(handle, opts.category or 0)
    SetBlipPriority(handle, opts.priority or 0)
    SetBlipAsShortRange(handle, opts.shortRange or false)

    local label = opts.label or 'Blip'
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(handle)

    if opts.flashes then
        SetBlipFlashes(handle, true)
        if opts.flashTimer and opts.flashTimer > 0 then
            SetBlipFlashTimer(handle, opts.flashTimer)
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────────────────────────

---Create a blip at specific world coordinates.
---@param opts BlipOptions
---@return string id  Unique blip ID for later reference
function functions.Add(opts)
    assert(opts and opts.coords, '[sm_core:blip] opts.coords is required')

    local coords = opts.coords
    local handle = AddBlipForCoord(coords.x, coords.y, coords.z)
    applyBlipOptions(handle, opts)

    local id = generateId()
    blips[id] = { handle = handle, type = 'coords', id = id }
    return id
end

---Create a radius (circle) blip at specific world coordinates.
---@param opts RadiusBlipOptions
---@return string id  Unique blip ID for later reference
function functions.AddRadius(opts)
    assert(opts and opts.coords, '[sm_core:blip] opts.coords is required')
    assert(opts.radius and opts.radius > 0, '[sm_core:blip] opts.radius must be > 0')

    local coords = opts.coords
    local handle = AddBlipForRadius(coords.x, coords.y, coords.z, opts.radius)

    SetBlipColour(handle, opts.color or 2)
    SetBlipAlpha(handle, opts.alpha or 80)

    if opts.label then
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(opts.label)
        EndTextCommandSetBlipName(handle)
    end

    local id = generateId()
    blips[id] = { handle = handle, type = 'radius', id = id }
    return id
end

---Create a blip attached to an entity (vehicle, ped, object).
---@param entity integer Entity handle
---@param opts BlipOptions
---@return string id
function functions.AddForEntity(entity, opts)
    assert(entity and DoesEntityExist(entity), '[sm_core:blip] entity does not exist')

    local handle = AddBlipForEntity(entity)
    applyBlipOptions(handle, opts or {})

    local id = generateId()
    blips[id] = { handle = handle, type = 'entity', id = id }
    return id
end

---Remove a blip by its ID.
---@param id string
function functions.Remove(id)
    local entry = blips[id]
    if not entry then return end

    if DoesBlipExist(entry.handle) then
        RemoveBlip(entry.handle)
    end

    blips[id] = nil
end

---Remove all blips managed by this module.
function functions.RemoveAll()
    for id, entry in pairs(blips) do
        if DoesBlipExist(entry.handle) then
            RemoveBlip(entry.handle)
        end
        blips[id] = nil
    end
end

---Update the coords of an existing coord blip.
---@param id string
---@param coords vector3|vector4
function functions.SetCoords(id, coords)
    local entry = blips[id]
    if not entry or not DoesBlipExist(entry.handle) then return end
    SetBlipCoords(entry.handle, coords.x, coords.y, coords.z)
end

---Update the sprite of an existing blip.
---@param id string
---@param sprite integer
function functions.SetSprite(id, sprite)
    local entry = blips[id]
    if not entry or not DoesBlipExist(entry.handle) then return end
    SetBlipSprite(entry.handle, sprite)
end

---Update the color of an existing blip.
---@param id string
---@param color integer
function functions.SetColor(id, color)
    local entry = blips[id]
    if not entry or not DoesBlipExist(entry.handle) then return end
    SetBlipColour(entry.handle, color)
end

---Update the scale of an existing blip.
---@param id string
---@param scale number
function functions.SetScale(id, scale)
    local entry = blips[id]
    if not entry or not DoesBlipExist(entry.handle) then return end
    SetBlipScale(entry.handle, scale)
end

---Update the alpha (opacity) of an existing blip.
---@param id string
---@param alpha integer 0–255
function functions.SetAlpha(id, alpha)
    local entry = blips[id]
    if not entry or not DoesBlipExist(entry.handle) then return end
    SetBlipAlpha(entry.handle, alpha)
end

---Set blip label text.
---@param id string
---@param label string
function functions.SetLabel(id, label)
    local entry = blips[id]
    if not entry or not DoesBlipExist(entry.handle) then return end
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(entry.handle)
end

---Toggle blip flash on/off.
---@param id string
---@param state boolean
---@param timer? number ms before flash stops (0 or nil = infinite)
function functions.SetFlash(id, state, timer)
    local entry = blips[id]
    if not entry or not DoesBlipExist(entry.handle) then return end
    SetBlipFlashes(entry.handle, state)
    if state and timer and timer > 0 then
        SetBlipFlashTimer(entry.handle, timer)
    end
end

---Toggle short range on an existing blip.
---@param id string
---@param state boolean
function functions.SetShortRange(id, state)
    local entry = blips[id]
    if not entry or not DoesBlipExist(entry.handle) then return end
    SetBlipAsShortRange(entry.handle, state)
end

---Check if a managed blip still exists.
---@param id string
---@return boolean
function functions.Exists(id)
    local entry = blips[id]
    return entry ~= nil and DoesBlipExist(entry.handle)
end

---Get the raw native handle for a managed blip.
---@param id string
---@return integer|nil
function functions.GetHandle(id)
    local entry = blips[id]
    if not entry then return nil end
    return entry.handle
end

---Get all managed blip IDs.
---@return string[]
function functions.GetAll()
    local ids = {}
    for id in pairs(blips) do
        ids[#ids + 1] = id
    end
    return ids
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Cleanup on resource stop
-- ─────────────────────────────────────────────────────────────────────────────

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    functions.RemoveAll()
end)

return functions
