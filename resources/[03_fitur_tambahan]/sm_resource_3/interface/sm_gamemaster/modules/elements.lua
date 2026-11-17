local config = localmodule 'config'
local nui = localmodule 'modules.nui'

local type = type
local pairs = pairs
local StartScriptFire = StartScriptFire
local RemoveScriptFire = RemoveScriptFire
local StopFireInRange = StopFireInRange
local AddExplosion = AddExplosion
local ForceLightningFlash = ForceLightningFlash

local LIGHTNING_TYPE = config.lightningExplosion
local FIRE_MS = 30000

local elements = {}

---@type table<integer, true>
local fires = {}

---@param coords vector3
function elements.fire(coords)
    local id = StartScriptFire(coords.x, coords.y, coords.z, 25, false)

    if not id or id == 0 then return end

    fires[id] = true

    SetTimeout(FIRE_MS, function()
        if fires[id] then
            fires[id] = nil
            RemoveScriptFire(id)
        end
    end)
end

---@param coords vector3
function elements.extinguish(coords)
    StopFireInRange(coords.x, coords.y, coords.z, 10.0)
end

---@param result any
---@return boolean
local function accepted(result)
    if type(result) == 'table' and result.ok then return true end

    nui.log('error', type(result) == 'table' and result.reason or 'Server tidak merespons')

    return false
end

---@param coords vector3
function elements.lightning(coords)
    local result = lib.callback.await('sm_gamemaster:server:lightning', false, coords)

    if not accepted(result) then return end

    AddExplosion(coords.x, coords.y, coords.z, LIGHTNING_TYPE, 0.3, true, false, 0.0)
end

---@param explosionType integer
---@param coords vector3
function elements.explode(explosionType, coords)
    local result = lib.callback.await('sm_gamemaster:server:explosion', false, explosionType, coords)

    if not accepted(result) then return end

    AddExplosion(coords.x, coords.y, coords.z, explosionType, 1.0, true, false, 0.5)
end

function elements.flash()
    ForceLightningFlash()
end

function elements.clear()
    for id in pairs(fires) do
        RemoveScriptFire(id)
    end

    fires = {}
end

return elements
