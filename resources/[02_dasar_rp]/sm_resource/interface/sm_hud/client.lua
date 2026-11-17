if not interface.init() then return end

local KVP_SETTINGS   = 'sm_hud:settings'
local KVP_POSITIONS  = 'sm_hud:positions'
local KVP_VISIBILITY = 'sm_hud:visibility'

local default = localmodule 'data.default'

local DEFAULT_SETTINGS = default.DEFAULT_SETTINGS
local DEFAULT_POSITIONS = default.DEFAULT_POSITIONS
local DEFAULT_VISIBILITY = default.DEFAULT_VISIBILITY

SM_HUD = {
    maxPlayers = GetConvarInt('sv_maxclients', 64),
    serverPlayers = 0,
    blackBarsActive = false,
    settings = {},
    weaponAmmo = default.WEAPON_AMMO_BY_HASH,
    minimapPosition = DEFAULT_SETTINGS.minimapPosition,
    visible = false
}

---@param key string
---@return table|nil
local function kvpGet(key)
    local raw = GetResourceKvpString(key)
    if not raw or raw == '' then return nil end
    local ok, val = pcall(json.decode, raw)
    return ok and val or nil
end

---@param key  string
---@param data table
local function kvpSet(key, data)
    local ok, encoded = pcall(json.encode, data)
    if ok then SetResourceKvp(key, encoded) end
end

---@param saved table|nil
---@param defaults table
---@return table
local function withDefaults(saved, defaults)
    if not saved then return defaults end

    for key, value in pairs(defaults) do
        if saved[key] == nil then
            saved[key] = value
        end
    end

    return saved
end

local function loadSettings()
    local settings = withDefaults(kvpGet(KVP_SETTINGS), DEFAULT_SETTINGS)
    local positions = withDefaults(kvpGet(KVP_POSITIONS), DEFAULT_POSITIONS)
    local visibility = withDefaults(kvpGet(KVP_VISIBILITY), DEFAULT_VISIBILITY)

    settings.navigator = withDefaults(settings.navigator, DEFAULT_SETTINGS.navigator)

    SM_HUD.mapState = settings.mapState or DEFAULT_SETTINGS.mapState
    SM_HUD.minimapPosition = settings.minimapPosition or DEFAULT_SETTINGS.minimapPosition
    SM_HUD.blackBarsActive = settings.cinematicMode == true
    SM_HUD.settings = settings

    interface.send({
        action = 'loadSettings',
        data = {
            settings = settings,
            positions = positions,
            visibility = visibility,
        }
    })
end

local function resetDefault()
    SM_HUD.mapState = DEFAULT_SETTINGS.mapState
    SM_HUD.minimapPosition = DEFAULT_SETTINGS.minimapPosition
    SM_HUD.blackBarsActive = DEFAULT_SETTINGS.cinematicMode == true
    SM_HUD.settings = DEFAULT_SETTINGS

    kvpSet(KVP_SETTINGS, DEFAULT_SETTINGS)
    kvpSet(KVP_POSITIONS, DEFAULT_POSITIONS)
    kvpSet(KVP_VISIBILITY, DEFAULT_VISIBILITY)

    interface.send({
        action = 'loadSettings',
        data = {
            settings = DEFAULT_SETTINGS,
            positions = DEFAULT_POSITIONS,
            visibility = DEFAULT_VISIBILITY,
        }
    })
end

local function initHUD()
    loadSettings()
    SM_HUD.setVisible(true)
end

function SM_HUD.setVisible(state)
    SM_HUD.visible = state
    interface.send({ action = 'setVisible', data = { visible = state } })
end

---@alias HUD_Component
---| 'ammo'
---| 'compass'
---| 'information'
---| 'healthArmor'
---| 'voice'
---| 'status'
---| 'speedometer'
---| 'aviation'
---| 'navigation'

---@param key HUD_Component
---@param visibility boolean
function SM_HUD.setComponentVisible(key, visibility)
    interface.send({
        action = 'setComponentVisible',
        data = {
            component = key,
            visible = visibility
        }
    })
end

require 'interface.sm_hud.modules.compas'
require 'interface.sm_hud.modules.information'
require 'interface.sm_hud.modules.minimap'
require 'interface.sm_hud.modules.line_navigator.navigator'
require 'interface.sm_hud.modules.status'
require 'interface.sm_hud.modules.sprint'
require 'interface.sm_hud.modules.vehicle'
require 'interface.sm_hud.modules.voice'
require 'interface.sm_hud.modules.weapon'
require 'interface.sm_hud.modules.seatbelt'
require 'interface.sm_hud.modules.stress'
require 'interface.sm_hud.modules.media'

interface.callback('exit', function(_, cb)
    interface.focus(false, false)
    cb('ok')
end)

interface.callback('saveSettings', function(data, cb)
    if data then
        SM_HUD.mapState = data.mapState or SM_HUD.mapState
        SM_HUD.minimapPosition = data.minimapPosition or SM_HUD.minimapPosition
        SM_HUD.blackBarsActive = data.cinematicMode == true
        SM_HUD.settings = data
        kvpSet(KVP_SETTINGS, data)
    end
    cb('ok')
end)

interface.callback('savePositions', function(data, cb)
    if data then
        if data.positions then kvpSet(KVP_POSITIONS,  data.positions)  end
        if data.visibility then kvpSet(KVP_VISIBILITY, data.visibility) end
    end
    cb('ok')
end)

interface.callback('saveVisibility', function(data, cb)
    if data then
        kvpSet(KVP_VISIBILITY, data)
    end
    cb('ok')
end)

interface.callback('resetSettings', function(data, cb)
    local toDefault = data?.default

    cb('ok')

    if toDefault then
        resetDefault()
        return
    end

    loadSettings()
end)

interface.callback('resetMinimap', function(_, cb)
    SM_HUD.minimapPosition = DEFAULT_SETTINGS.minimapPosition
    cb(DEFAULT_SETTINGS.minimapPosition)
end)

CreateThread(function ()
    ---@CUSTOM_WARNA_HUD_GTA
    ReplaceHudColourWithRgba(142, 42, 166, 185, 255) -- Waypoint

    if not playerState.isLoggedIn then
        return
    end

    Wait(1500)
    initHUD()
end)

AddEventHandler('rhd_spawn:client:onSpawn', function (isNew)
    initHUD()
end)

AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    SM_HUD.setVisible(false)
end)

RegisterNetEvent('sm_hud:client:setVisible', function(state)
    SM_HUD.setVisible(state)
end)

RegisterNetEvent('sm_hud:client:openSettings', function()
    interface.focus(true, true)
    interface.send({ action = 'openSettings', data = {} })
end)

local exportHandler = require 'export_wrapper'

exportHandler('sm_hud', 'setVisible', SM_HUD.setVisible)
exportHandler('sm_hud', 'setComponentVisible', SM_HUD.setComponentVisible)

exportHandler('sm_hud', 'openSettings', function()
    interface.focus(true, true)
    interface.send({ action = 'openSettings', data = {} })
end)

lib.addKeybind({
    name = 'hudsetting',
    description = 'Open HUD settings',
    defaultKey = 'F9',
    onPressed = function(self)
        interface.focus(true, true)
        interface.send({ action = 'openSettings', data = {} })
    end
})