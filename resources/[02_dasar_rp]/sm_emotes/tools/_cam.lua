---@class CamHandler: OxClass
CamHandler = lib.class('CamHandler')

local function TransformVectoTable(vector)
    return {
        x = vector.x,
        y = vector.y,
        z = vector.z,
        w = vector.w
    }
end

function CamHandler:constructor(coords)
    self.cam = nil
    self.baseCoords = TransformVectoTable(coords)
    self.coords = table.clone(self.baseCoords)
end

function CamHandler:setup(offset)
    if self.cam then
        self:destroy()
    end

    self.coords = table.clone(self.baseCoords)

    if offset then
        if offset.x then self.coords.x = self.coords.x + offset.x end
        if offset.y then self.coords.y = self.coords.y + offset.y end
        if offset.z then self.coords.z = self.coords.z + offset.z end
        if offset.w then self.coords.w = self.coords.w + offset.w end
    end

    self.cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    
    local heading = math.rad(self.coords.w or 0.0)
    local distance = 2.5
    
    local camX = self.coords.x - (math.sin(heading) * distance)
    local camY = self.coords.y - (math.cos(heading) * distance)
    local camZ = self.coords.z + 0.5

    SetCamCoord(self.cam, camX, camY, camZ)
    PointCamAtCoord(self.cam, self.coords.x, self.coords.y, self.coords.z + 0.5)
    SetCamFov(self.cam, 50.0)
    
    SetCamActive(self.cam, true)
    RenderScriptCams(true, true, 500, true, true)
end

function CamHandler:changecoords(pos, xOffset, yOffset, zOffset)
    if not self.cam then return end
    
    xOffset = xOffset or 0.0
    yOffset = yOffset or 0.0
    zOffset = zOffset or 0.0
    
    local newPos = TransformVectoTable(pos)
    newPos.x = newPos.x + xOffset
    newPos.y = newPos.y + yOffset
    newPos.z = newPos.z + zOffset
    
    SetCamCoord(self.cam, newPos.x, newPos.y, newPos.z)
end

function CamHandler:destroy()
    if not self.cam then
        return
    end

    RenderScriptCams(false, true, 500, true, true)
    DestroyCam(self.cam, false)
    self.cam = nil
end

function CamHandler:updatePos(coords, xOffset, yOffset, zOffset)
    if not self.cam then return end
    
    xOffset = xOffset or 0.0
    yOffset = yOffset or 0.0
    zOffset = zOffset or 0.0
    
    self.coords = TransformVectoTable(coords)
    self.coords.x = self.coords.x + xOffset
    self.coords.y = self.coords.y + yOffset
    self.coords.z = self.coords.z + zOffset

    SetCamCoord(self.cam, self.coords.x, self.coords.y, self.coords.z)
end

function CamHandler:pointatentity(entity)
    if not self.cam or not DoesEntityExist(entity) then return end
    PointCamAtEntity(self.cam, entity, 0.0, 0.0, 0.0, true)
end

function CamHandler:pointatcoords(coords)
    if not self.cam then return end
    PointCamAtCoord(self.cam, coords.x, coords.y, coords.z)
end

function CamHandler:setfov(fov)
    if not self.cam then return end
    SetCamFov(self.cam, fov)
end
