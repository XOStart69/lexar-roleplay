local blipExist = {}

---@class BlipHandle: OxClass
---@field id string
---@field blip number
---@field data Modules_BlipData
local blip = lib.class('BlipHandle')

local function generateId()
    local id
    repeat
        ---@diagnostic disable-next-line: undefined-field
        id = string.random('...-...-..')
    until not blipExist[id]

    return id
end

---@param data Modules_BlipData
function blip:constructor(data)
    if not (data.coords or data.entity) then
        error('Blip requires either coords or entity')
        return
    end

    self.visible = true
    self.id = data.id or generateId()

    if blipExist[self.id] then
        warn(('Blip with id "%s" already exists, removing old one'):format(self.id))
        blipExist[self.id]:remove()
    end

    if data.coords then
        self.blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    elseif data.entity then
        self.blip = AddBlipForEntity(data.entity)
    end

    if not DoesBlipExist(self.blip) then
        error('Failed to create blip')
        return
    end

    self.data = data
    SetBlipSprite(self.blip, data.sprite or 1)
    SetBlipColour(self.blip, data.color or 0)
    SetBlipScale(self.blip, data.scale or 0.6)
    SetBlipDisplay(self.blip, data.display or 4)

    if data.label then
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(data.label)
        EndTextCommandSetBlipName(self.blip)
    end

    if data.shortRange ~= nil then
        SetBlipAsShortRange(self.blip, data.shortRange)
    end

    if data.category then
        SetBlipCategory(self.blip, data.category)
    end

    if data.alpha then
        SetBlipAlpha(self.blip, data.alpha)
    end

    if data.rotation then
        SetBlipRotation(self.blip, data.rotation)
    end

    if data.route then
        SetBlipRoute(self.blip, true)
        SetBlipRouteColour(self.blip, (data.routeColor or data.color or 1))
    end

    blipExist[self.id] = self
end

---@param coords vector3
function blip:setCoords(coords)
    if DoesBlipExist(self.blip) then
        SetBlipCoords(self.blip, coords.x, coords.y, coords.z)
        self.data.coords = coords
    end
end

---@param sprite number
function blip:setSprite(sprite)
    if DoesBlipExist(self.blip) then
        SetBlipSprite(self.blip, sprite)
        self.data.sprite = sprite
    end
end

---@param color number
function blip:setColor(color)
    if DoesBlipExist(self.blip) then
        SetBlipColour(self.blip, color)
        self.data.color = color
    end
end

---@param scale number
function blip:setScale(scale)
    if DoesBlipExist(self.blip) then
        SetBlipScale(self.blip, scale)
        self.data.scale = scale
    end
end

---@param label string
function blip:setLabel(label)
    if DoesBlipExist(self.blip) then
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(label)
        EndTextCommandSetBlipName(self.blip)
        self.data.label = label
    end
end

---@param alpha number
function blip:setAlpha(alpha)
    if DoesBlipExist(self.blip) then
        SetBlipAlpha(self.blip, alpha)
        self.data.alpha = alpha
    end
end

---@param rotation number
function blip:setRotation(rotation)
    if DoesBlipExist(self.blip) then
        SetBlipRotation(self.blip, rotation)
        self.data.rotation = rotation
    end
end

---@param enabled boolean
---@param color? number Route color
function blip:setRoute(enabled, color)
    if DoesBlipExist(self.blip) then
        SetBlipRoute(self.blip, enabled)
        if enabled and color then
            SetBlipRouteColour(self.blip, color)
            self.data.routeColor = color
        end
        self.data.route = enabled
    end
end

---@param duration? number Flash duration in ms (default: infinite)
function blip:flash(duration)
    if DoesBlipExist(self.blip) then
        SetBlipFlashes(self.blip, true)
        
        if duration then
            SetTimeout(duration, function()
                if DoesBlipExist(self.blip) then
                    SetBlipFlashes(self.blip, false)
                end
            end)
        end
    end
end

function blip:stopFlash()
    if DoesBlipExist(self.blip) then
        SetBlipFlashes(self.blip, false)
    end
end

function blip:pulse()
    if DoesBlipExist(self.blip) then
        PulseBlip(self.blip)
    end
end

---@param visible boolean
function blip:setVisible(visible)
    self.visible = visible
    if DoesBlipExist(self.blip) then
        SetBlipHiddenOnLegend(self.blip, not self.visible)
    end
end

---@return boolean
function blip:exists()
    return DoesBlipExist(self.blip)
end

---@return number
function blip:getHandle()
    return self.blip
end

function blip:remove()
    if DoesBlipExist(self.blip) then
        RemoveBlip(self.blip)
    end
    blipExist[self.id] = nil
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for id, blipHandle in pairs(blipExist) do
            blipHandle:remove()
        end
    end
end)

return blip