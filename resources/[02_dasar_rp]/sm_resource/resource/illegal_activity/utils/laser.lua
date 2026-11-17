local ShapeTestRay = StartShapeTestRay or StartExpensiveSynchronousShapeTestLosProbe

local function RayCast(origin, destination, flags)
    ---@diagnostic disable-next-line: param-type-mismatch
    local ray = ShapeTestRay(origin.x, origin.y, origin.z, destination.x, destination.y, destination.z, flags, nil, 0)
        return GetShapeTestResult(ray)
    end

    local function randomFloat(lower, greater)
    return lower + math.random()  * (greater - lower);
    end

    local function drawLaser(origin, destination, r, g, b, a)
    DrawLine(origin.x, origin.y, origin.z, destination.x, destination.y, destination.z, r, g, b, a)
end

local function calculateCurrentPoint(fromPoint, toPoint, deltaTime, travelTimeBetweenTargets)
    local desiredDirection = toPoint - fromPoint
    local desiredDirectionDist = #desiredDirection
    local percentOfTravelTime = deltaTime / (travelTimeBetweenTargets * 1000)
    local distance = math.min(desiredDirectionDist * percentOfTravelTime, desiredDirectionDist)
    return fromPoint + (norm(desiredDirection) * distance)
end

local function getNextToIndex(fromIndex, targetPointCount, randomTargetSelection)
    local toIndex = fromIndex

    if randomTargetSelection then
        while toIndex == fromIndex do
            toIndex = math.random(1, targetPointCount)
        end
    else
        toIndex = (fromIndex % targetPointCount) + 1
    end

    return toIndex
end

---@diagnostic disable-next-line: undefined-doc-class
---@class Laser: OxClass
local Laser = lib.class('Laser')

function Laser:constructor(originPoint, targetPoints, options)
    options = options or {}
    assert(options.color == nil or #options.color == 4, "Laser color must have four values {r, g, b, a}")

    self.name = options.name
    self.originPoint = originPoint
    self.targetPoints = targetPoints
    self.visible = true
    self.moving = true
    self.active = false
    self.r, self.g, self.b, self.a = 255, 0, 0, 255

    if options.color then
        self.r, self.g, self.b, self.a = table.unpack(options.color)
    end

    self.extensionEnabled = true

    if options.extensionEnabled ~= nil then
        self.extensionEnabled = options.extensionEnabled
    end

    self.randomTargetSelection = true

    if options.randomTargetSelection ~= nil then
        self.randomTargetSelection = options.randomTargetSelection
    end

    self.maxDistance = options.maxDistance or 20.0

    local travelTimeBetweenTargets = options.travelTimeBetweenTargets or {}
    self.minTravelTimeBetweenTargets = travelTimeBetweenTargets[1] or 1.0
    self.maxTravelTimeBetweenTargets = travelTimeBetweenTargets[2] or 1.0

    local waitTimeAtTargets = options.waitTimeAtTargets or {}
    self.minWaitTimeAtTargets = waitTimeAtTargets ~= nil and waitTimeAtTargets[1] or 0.0
    self.maxWaitTimeAtTargets = waitTimeAtTargets ~= nil and waitTimeAtTargets[2] or 0.0

    self.onPlayerHitCb = nil
    self.playerBeingHit = false
end

function Laser:getActive()
    return self.active
end

function Laser:setActive(toggle)
    if self.active == toggle then
        return
    end

    self.active = toggle

    if self.active then
        if type(self.originPoint) == "vector3" then
            self:_startLaser()
        elseif type(self.originPoint) == "table" then
            self:_startMultiOriginLaser()
        end
    end
end

function Laser:getVisible()
    return self.visible
end

function Laser:setVisible(toggle)
    if self.visible == toggle then return end
    self.visible = toggle
end

function Laser:getMoving()
    return self.moving
end

function Laser:setMoving(toggle)
    if self.moving == toggle then return end
    self.moving = toggle
end

function Laser:getColor()
    return self.r, self.g, self.b, self.a
end

function Laser:setColor(_r, _g, _b, _a)
    if type(_r) ~= "number" or type(_g) ~= "number" or type(_b) ~= "number" or type(_a) ~= "number" then
        error("(r, g, b, a) must all be integers " .. string.format("{r = %s, g = %s, b = %s, a = %s}", _r, _g, _b, _a))
    end
    self.r, self.g, self.b, self.a = _r, _g, _b, _a
end

function Laser:onPlayerHit(cb)
    self.onPlayerHitCb = cb
    self.playerBeingHit = false
end

function Laser:clearOnPlayerHit()
    self.onPlayerHitCb = nil
    self.playerBeingHit = false
end

function Laser:_onPlayerHitTest(origin, destination)
    local _, hit, hitPos, _, hitEntity = RayCast(origin, destination, 12)
    local newPlayerBeingHit = hit and hitEntity == cache.ped

    if newPlayerBeingHit ~= self.playerBeingHit then
        self.playerBeingHit = newPlayerBeingHit
        self.onPlayerHitCb(self.playerBeingHit, hitPos)
    end
end

function Laser:_startLaser()
    if #self.targetPoints == 1 then
        CreateThread(function()
            local direction = norm(self.targetPoints[1] - self.originPoint)
            local destination = self.originPoint + direction * self.maxDistance

            while self.active do
                if self.visible then
                    drawLaser(self.originPoint, destination, self.r, self.g, self.b, self.a)
                    if self.onPlayerHitCb then
                        self:_onPlayerHitTest(self.originPoint, destination)
                    end
                end
                Wait(0)
            end
        end)
    else
        CreateThread(function()
            local deltaTime = 0
            local fromIndex = 1
            local toIndex = 2

            if self.randomTargetSelection then
                fromIndex = math.random(1, #self.targetPoints)
                toIndex = getNextToIndex(fromIndex, #self.targetPoints, self.randomTargetSelection)
            end

            local waiting = false
            local waitTime = 0
            local currentTravelTime = randomFloat(self.minTravelTimeBetweenTargets, self.maxTravelTimeBetweenTargets)

            while self.active do
                local fromPoint = self.targetPoints[fromIndex]
                local toPoint = self.targetPoints[toIndex]
                local currentPoint = calculateCurrentPoint(fromPoint, toPoint, deltaTime, currentTravelTime)
                local currentDirection = norm(currentPoint - self.originPoint)

                if self.visible then
                    local destination = currentPoint
                    if self.extensionEnabled then
                        destination = self.originPoint + currentDirection * self.maxDistance
                    end
                    drawLaser(self.originPoint, destination, self.r, self.g, self.b, self.a)
                    if self.onPlayerHitCb then
                        self:_onPlayerHitTest(self.originPoint, destination)
                    end
                end

                if self.moving and not waiting then
                    if #(toPoint - currentPoint) < 0.001 then
                        deltaTime = 0
                        fromIndex = toIndex
                        toIndex = getNextToIndex(fromIndex, #self.targetPoints, self.randomTargetSelection)
                        currentTravelTime = randomFloat(self.minTravelTimeBetweenTargets, self.maxTravelTimeBetweenTargets)
                        if self.minWaitTimeAtTargets > 0.0 or self.maxWaitTimeAtTargets > 0.0 then
                            waiting = true
                            waitTime = randomFloat(self.minWaitTimeAtTargets, self.maxWaitTimeAtTargets) * 1000
                        end
                    end
                    deltaTime = deltaTime + (GetFrameTime() * 1000)
                elseif waiting then
                    waitTime = waitTime - (GetFrameTime() * 1000)
                    if waitTime <= 0.0 then waiting = false end
                end

                Wait(0)
            end
        end)
    end
end

function Laser:_startMultiOriginLaser()
    assert(#self.originPoint == #self.targetPoints, "Multi-origin laser must have same number of origin and target points")
    assert(#self.originPoint > 1 and #self.targetPoints > 1, "Multi-origin laser must have more than one origin and target points")

    CreateThread(function()
        local deltaTime = 0
        local fromIndex = 1
        local toIndex = 2
        local step = 1
        local waiting = false
        local waitTime = 0
        local currentTravelTime = randomFloat(self.minTravelTimeBetweenTargets, self.maxTravelTimeBetweenTargets)

        while self.active do
            local fromTargetPoint = self.targetPoints[fromIndex]
            local toTargetPoint = self.targetPoints[toIndex]
            local currentTargetPoint = calculateCurrentPoint(fromTargetPoint, toTargetPoint, deltaTime, currentTravelTime)
            local fromOriginPoint = self.originPoint[fromIndex]
            local toOriginPoint = self.originPoint[toIndex]
            local currentOriginPoint = calculateCurrentPoint(fromOriginPoint, toOriginPoint, deltaTime, currentTravelTime)

            if self.visible then
                drawLaser(currentOriginPoint, currentTargetPoint, self.r, self.g, self.b, self.a)
                if self.onPlayerHitCb then
                    self:_onPlayerHitTest(currentOriginPoint, currentTargetPoint)
                end
            end

            if self.moving and not waiting then
                if #(currentTargetPoint - toTargetPoint) < 0.001 then
                    deltaTime = 0
                    if toIndex == 1 or toIndex == #self.originPoint then
                        step = step * -1
                        fromIndex = toIndex
                        toIndex = fromIndex + step
                    else
                        fromIndex = fromIndex + step
                        toIndex = toIndex + step
                    end
                    currentTravelTime = randomFloat(self.minTravelTimeBetweenTargets, self.maxTravelTimeBetweenTargets)
                    if self.minWaitTimeAtTargets > 0.0 or self.maxWaitTimeAtTargets > 0.0 then
                        waiting = true
                        waitTime = randomFloat(self.minWaitTimeAtTargets, self.maxWaitTimeAtTargets) * 1000
                    end
                end
                deltaTime = deltaTime + (GetFrameTime() * 1000)
            elseif waiting then
                waitTime = waitTime - (GetFrameTime() * 1000)
                if waitTime <= 0.0 then waiting = false end
            end
            Wait(0)
        end
    end)
end

return Laser