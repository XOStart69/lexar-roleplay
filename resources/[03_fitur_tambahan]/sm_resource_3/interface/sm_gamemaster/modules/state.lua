---@class GmItem
---@field kind 'ped'|'vehicle'|'object'
---@field model string

---@class GmFollow
---@field entity integer
---@field distance number
---@field target number
---@field velocity number
---@field azimuth number
---@field pitch number
---@field height number

---@class GmOptions
---@field ambient boolean
---@field persist boolean
---@field run boolean
---@field path boolean
---@field pickPeds boolean
---@field pickVehicles boolean
---@field pickObjects boolean
---@field preview boolean
---@field cameraToggle boolean

---@class GmMarker
---@field x number
---@field y number
---@field z number
---@field r integer
---@field g integer
---@field b integer
---@field heading number
---@field startAt integer
---@field expiresAt integer

---@class GmState
---@field enabled boolean
---@field cam? integer
---@field camPos vector3
---@field heading number
---@field pitch number
---@field fov number
---@field mode 'select'|'spawn'
---@field selection integer[]
---@field selected table<integer, true>
---@field selectionDirty boolean
---@field cursorX number
---@field cursorY number
---@field screenW number
---@field screenH number
---@field overUi boolean
---@field typing boolean
---@field menuOpen boolean
---@field item? GmItem
---@field options GmOptions
---@field follow? GmFollow
---@field markers GmMarker[]
---@field rmbDragging boolean
---@field placing boolean
---@field impersonating boolean
---@field entryCoords? vector3
---@field entryHeading? number
local state = {
    enabled = false,
    cam = nil,
    camPos = vector3(0.0, 0.0, 0.0),
    heading = 0.0,
    pitch = -30.0,
    fov = 50.0,
    mode = 'select',
    selection = {},
    selected = {},
    selectionDirty = false,
    cursorX = 0.5,
    cursorY = 0.5,
    screenW = 1920,
    screenH = 1080,
    overUi = false,
    typing = false,
    menuOpen = false,
    item = nil,
    options = {
        ambient = false,
        persist = false,
        run = false,
        path = false,
        pickPeds = true,
        pickVehicles = true,
        pickObjects = false,
        preview = true,
        cameraToggle = false,
    },
    follow = nil,
    markers = {},
    rmbDragging = false,
    placing = false,
    impersonating = false,
    entryCoords = nil,
    entryHeading = nil,
}

return state
