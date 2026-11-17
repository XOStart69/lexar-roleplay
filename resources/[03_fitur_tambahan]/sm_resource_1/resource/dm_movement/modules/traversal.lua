local config = localmodule 'config.shared'
local Util = localmodule 'modules.util'
local Anim = localmodule 'modules.anim'
local State = localmodule 'modules.state'

local Traversal = {
    frozen = false
}

local mathMax, mathMin, mathAbs, mathHuge, mathFloor = math.max, math.min, math.abs, math.huge, math.floor
local strformat = string.format
local tablesort = table.sort

local activeTraversal = nil
local nextScanTime = 0
local prospectHeights = { 1.2, 1.8, 2.4 }
local prospectHeightCount = #prospectHeights
local prospectAngles = { 0.0, -45.0, 45.0 }
local prospectAngleCount = #prospectAngles
local landingCache = {}
local landingCacheTtl = 500
local nextCacheWipe = 0
local blockedControls = { 21, 22, 24, 25, 30, 31, 37, 44, 75, 140, 141, 142, 257 }
local blockedCount = #blockedControls

---@param edge vector3
---@param forward vector3
---@param ped number
---@param groundZ number
---@param rootHeight number
---@return vector3?
local function findSmartVaultLanding(edge, forward, ped, groundZ, rootHeight)
    local cfg = config.traversal
    local smartVault = cfg.smartVault

    if not smartVault or not smartVault.enabled then
        return nil
    end

    local scanStep = mathMax(0.08, smartVault.scanStep)
    local right = vec3(forward.y, -forward.x, 0.0)
    local radius = mathMax(cfg.landingSpread, cfg.bodyRadius)
    local maxSearchZ = (edge.z - groundZ) + mathMax(0.0, smartVault.maxDrop)
    local prevDist = 0.0
    local foundDepth = nil

    for depth = scanStep, smartVault.maxDepth + scanStep, scanStep do
        local hit, hitPos, normal, hitEntity = Util.Surface(edge + forward * depth, 0.2, maxSearchZ + 0.05, ped)

        if not hit then
            return nil
        end

        if hitEntity ~= 0 and (IsEntityAVehicle(hitEntity) or IsEntityAPed(hitEntity) or GetEntitySpeed(hitEntity) > 0.1) then
            return nil
        end

        if normal.z < cfg.minSurfaceNormal then
            return nil
        end

        if hitPos.z < edge.z - cfg.minHeight then
            local low = prevDist
            local high = depth

            for _ = 1, 4 do
                local mid = (low + high) * 0.5
                local bHit, bPos = Util.Surface(edge + forward * mid, 0.2, maxSearchZ + 0.05, ped)

                if not bHit then
                    return nil
                end

                if bPos.z < edge.z - cfg.minHeight then
                    high = mid
                else
                    low = mid
                end
            end

            if high > smartVault.maxDepth then
                return nil
            end

            foundDepth = high
            break
        end

        if mathAbs(hitPos.z - edge.z) > 0.1 then
            return nil
        end

        prevDist = depth
    end

    if not foundDepth then
        return nil
    end

    local landingPos = edge + forward * (foundDepth + mathMax(smartVault.landingGap, radius + 0.1))
    local sampleOffsets = {
        vec3(0.0, 0.0, 0.0),
        right * radius,
        right * -radius,
        forward * radius,
        forward * -radius,
        (right + forward) * radius,
        (right - forward) * radius,
        (forward - right) * radius,
        (right + forward) * -radius
    }

    local maxLandingZ = -mathHuge
    local minLandingZ = mathHuge

    for i = 1, 9 do
        local hit, hitPos, normal, hitEntity = Util.Surface(landingPos + sampleOffsets[i], 0.2, maxSearchZ + 0.05, ped)

        if not hit or normal.z < cfg.minSurfaceNormal then
            return nil
        end

        if hitEntity ~= 0 and (IsEntityAVehicle(hitEntity) or IsEntityAPed(hitEntity) or GetEntitySpeed(hitEntity) > 0.1) then
            return nil
        end

        if hitPos.z < groundZ - smartVault.maxDrop or hitPos.z > edge.z - cfg.minHeight then
            return nil
        end

        if hitPos.z > maxLandingZ then maxLandingZ = hitPos.z end
        if hitPos.z < minLandingZ then minLandingZ = hitPos.z end
    end

    if (maxLandingZ - minLandingZ) > cfg.maxLandingSlope then
        return nil
    end

    local finalLandingPos = vec3(landingPos.x, landingPos.y, maxLandingZ)

    if not Util.BodyClear(finalLandingPos + vec3(0.0, 0.0, rootHeight + 0.025), ped, rootHeight) then
        return nil
    end

    return finalLandingPos
end

---@param edge vector3
---@param forward vector3
---@param ped number
---@return vector3?
local function findStandardLanding(edge, forward, ped)
    local cfg = config.traversal
    local sampleCenter = edge + forward * mathMax(cfg.landingSpread, cfg.landingDepth - cfg.landingSpread)
    local right = vec3(forward.y, -forward.x, 0.0) * cfg.landingSpread
    local sampleOffsets = {
        right,
        right * -1.0,
        forward * cfg.landingSpread
    }

    local maxSlope = cfg.maxLandingSlope + 0.3
    local hit, hitPos, normal, hitEntity = Util.Surface(sampleCenter, 0.8, maxSlope, ped)

    if not hit then
        return nil
    end

    if hitEntity ~= 0 and (IsEntityAVehicle(hitEntity) or IsEntityAPed(hitEntity)) then
        return nil
    end

    if normal.z < cfg.minSurfaceNormal then
        return nil
    end

    local maxZ = hitPos.z
    local minZ = hitPos.z

    for i = 1, 3 do
        local sHit, sPos = Util.Surface(sampleCenter + sampleOffsets[i], 0.8, maxSlope, ped)

        if not sHit then
            return nil
        end

        if sPos.z > maxZ then maxZ = sPos.z end
        if sPos.z < minZ then minZ = sPos.z end
    end

    if (maxZ - minZ) > cfg.maxLandingSlope then
        return nil
    end

    return vec3(sampleCenter.x, sampleCenter.y, maxZ)
end

---@param ped number
---@param candidate table
---@param pedCoords vector3
---@param groundZ number
---@param rootHeight number
---@param handBones table
---@return table?
local function evaluateCandidate(ped, candidate, pedCoords, groundZ, rootHeight, handBones)
    local cfg = config.traversal
    local edge = candidate.edge
    local forward = candidate.forward
    local pedFeetZ = pedCoords.z - rootHeight
    local rise = edge.z - groundZ

    local leftHand, rightHand = handBones[1], handBones[2]
    local closestHand = (#(leftHand - edge) < #(rightHand - edge)) and leftHand or rightHand
    local highestHandZ = mathMax(leftHand.z, rightHand.z)

    if rise < cfg.minHeight then
        return nil
    end

    if edge.z < pedFeetZ + 0.1 then
        return nil
    end

    if (edge.z - pedFeetZ) > cfg.highMax then
        return nil
    end

    if edge.z > highestHandZ + cfg.grabReach then
        return nil
    end

    if #(vec3(edge.x, edge.y, pedCoords.z) - pedCoords) > cfg.forwardReach + 0.2 then
        return nil
    end

    if Util.Ray(closestHand, (edge - forward * 0.08) + vec3(0.0, 0.0, 0.1), ped, cfg.clearanceFlags) then
        return nil
    end

    local now = GetGameTimer()
    local cacheKey = strformat('%s:%d:%d', candidate.key, mathFloor(groundZ * 10.0), mathFloor(rootHeight * 10.0))
    local cached = landingCache[cacheKey]

    if not cached or cached.expires < now then
        local landingPos = nil

        if rise <= cfg.lowMax then
            landingPos = findSmartVaultLanding(edge, forward, ped, groundZ, rootHeight)
        end

        local smart = landingPos ~= nil

        if not landingPos then
            landingPos = findStandardLanding(edge, forward, ped)
        end

        local dest = false

        if landingPos then
            dest = landingPos + vec3(0.0, 0.0, rootHeight + 0.025)

            if not Util.BodyClear(dest, ped, rootHeight) then
                dest = false
            end
        end

        cached = { expires = now + landingCacheTtl, dest = dest, smart = smart }
        landingCache[cacheKey] = cached
    end

    local landingDest = cached.dest

    if not landingDest then
        return nil
    end

    local isSmartVault = cached.smart

    local mode = 'climb'

    if rise <= cfg.lowMax then
        mode = 'vault'
    elseif rise <= cfg.mediumMax then
        mode = 'mantle'
    end

    if mode == 'vault' and cfg.smartVault and cfg.smartVault.enabled and not isSmartVault then
        mode = 'mantle'
    end

    local startPos = pedCoords

    if mode == 'climb' then
        local hangDrop = mathMax(0.3, highestHandZ - pedCoords.z)
        startPos = vec3(edge.x, edge.y, (edge.z - hangDrop) - 0.05) - forward * cfg.hangGap

        if #(startPos - pedCoords) > cfg.maxAssist then
            return nil
        end

        if not Util.BodyPath(pedCoords, startPos, ped, rootHeight) then
            return nil
        end
    end

    local peakZ = mathMax(landingDest.z, edge.z + rootHeight) + 0.12
    local mid1 = vec3(startPos.x, startPos.y, mathMax(startPos.z, peakZ))
    local path = {
        startPos,
        mid1,
        vec3(landingDest.x, landingDest.y, mid1.z),
        landingDest
    }

    for i = 1, 3 do
        if not Util.BodyPath(path[i], path[i + 1], ped, rootHeight) then
            return nil
        end
    end

    return {
        edge = edge,
        forward = forward,
        destination = landingDest,
        path = path,
        mode = mode,
        smartVault = isSmartVault,
        rise = rise,
        rootHeight = rootHeight,
        entity = candidate.entity,
        assist = #(startPos - pedCoords)
    }
end

---@param a table
---@param b table
---@param pedCoords vector3
---@return boolean
local function sortCandidates(a, b)
    if mathAbs(a.edge.z - b.edge.z) > 0.02 then
        return a.edge.z < b.edge.z
    end

    return a.distance < b.distance
end

---@param ped number
---@return boolean
function Traversal.Prospect(ped)
    local cfg = config.traversal
    local pedCoords = GetEntityCoords(ped)
    local feetZ = pedCoords.z - State.rootHeight
    local reach = cfg.forwardReach + cfg.landingSpread
    local heading = GetEntityHeading(ped)

    for i = 1, prospectHeightCount do
        local origin = vec3(pedCoords.x, pedCoords.y, feetZ + prospectHeights[i])

        for j = 1, prospectAngleCount do
            if Util.Ray(origin, origin + Util.Forward(heading + prospectAngles[j]) * reach, ped, cfg.clearanceFlags) then
                return true
            end
        end
    end

    return false
end

---@param ped number
---@return table?
function Traversal.Scan(ped)
    local cfg = config.traversal
    local pedCoords = GetEntityCoords(ped)
    local now = GetGameTimer()

    if now >= nextCacheWipe then
        landingCache = {}
        nextCacheWipe = now + 5000
    end
    local rootHeight = State.rootHeight
    local feetZ = pedCoords.z - rootHeight
    local ground = State.ground

    if ground and (ground.z > feetZ + 0.1 or #(vec3(ground.x, ground.y, pedCoords.z) - pedCoords) > 8.0) then
        ground = nil
    end

    if not ground then
        local hit, hitPos = Util.Ray(pedCoords + vec3(0.0, 0.0, 0.5), pedCoords - vec3(0.0, 0.0, 12.0), ped)

        if hit and hitPos.z <= feetZ + 0.1 then
            ground = hitPos
        else
            ground = vec3(pedCoords.x, pedCoords.y, feetZ)
        end
    end

    local handBones = {
        GetPedBoneCoords(ped, 18905, 0.0, 0.0, 0.0),
        GetPedBoneCoords(ped, 57005, 0.0, 0.0, 0.0)
    }

    local maxScanZ = mathMax(handBones[1].z, handBones[2].z) + cfg.grabReach + 0.15
    local scanStep = mathMax(0.08, cfg.scanStep)
    local scanStartZ = feetZ + mathMax(0.25, cfg.minHeight - scanStep)
    local approachAngles = cfg.approachAngles
    local candidates = {}
    local candidateCount = 0
    local seenCoords = {}
    local pedHeading = GetEntityHeading(ped)

    for i = 1, #approachAngles do
        local forward = Util.Forward(pedHeading + approachAngles[i])

        for scanZ = scanStartZ, maxScanZ, scanStep do
            local rayOrigin = vec3(pedCoords.x, pedCoords.y, scanZ)
            local hit, hitPos, hitNormal, hitEntity = Util.Ray(rayOrigin, rayOrigin + forward * cfg.forwardReach, ped)

            if hit and mathAbs(hitNormal.z) < 0.45 then
                local normal2D = vec3(hitNormal.x, hitNormal.y, 0.0)
                local normalLen = #normal2D

                if normalLen > 0.1 then
                    local surfaceNormal = normal2D * (-1.0) / normalLen
                    local topProbe = hitPos + surfaceNormal * 0.12
                    local topProbeHigh = vec3(topProbe.x, topProbe.y, scanZ + scanStep + 0.06)

                    if not Util.Ray(vec3(pedCoords.x, pedCoords.y, topProbeHigh.z), topProbeHigh, ped) then
                        local downHit, downHitPos, downNormal, downEntity = Util.Ray(topProbeHigh, vec3(topProbe.x, topProbe.y, scanZ - 0.06), ped)

                        if downHit and downNormal.z >= cfg.minSurfaceNormal and downHitPos.z >= feetZ + cfg.minHeight then
                            local coordKey = strformat('%.1f:%.1f:%.1f', downHitPos.x, downHitPos.y, downHitPos.z)

                            if not seenCoords[coordKey] then
                                seenCoords[coordKey] = true

                                local edge = vec3(hitPos.x, hitPos.y, downHitPos.z)
                                candidateCount = candidateCount + 1
                                candidates[candidateCount] = {
                                    key = coordKey,
                                    edge = edge,
                                    forward = surfaceNormal,
                                    entity = (downEntity and downEntity ~= 0) and downEntity or hitEntity,
                                    distance = #(edge - pedCoords)
                                }

                                break
                            end
                        end
                    end
                end
            end
        end
    end

    tablesort(candidates, sortCandidates)

    for i = 1, candidateCount do
        local candidate = candidates[i]
        local ent = candidate.entity
        local isValidEntity = true

        if ent and ent ~= 0 and (IsEntityAVehicle(ent) or IsEntityAPed(ent) or GetEntitySpeed(ent) >= 0.1) then
            isValidEntity = false
        end

        if isValidEntity then
            local result = evaluateCandidate(ped, candidate, pedCoords, ground.z, rootHeight, handBones)

            if result then
                return result
            end
        end
    end

    return nil
end

---@param ped number
function Traversal.Unfreeze(ped)
    if not Traversal.frozen then
        return
    end

    Traversal.frozen = false

    if DoesEntityExist(ped) then
        FreezeEntityPosition(ped, false)
    end
end

function Traversal.Cancel()
    local current = activeTraversal

    if not current then
        return
    end

    activeTraversal = nil
    State.token = State.token + 1
    State.traversing = false
    State.needsGround = true
    State.lastTraversal = GetGameTimer()

    if not DoesEntityExist(current.ped) then
        return
    end

    if current.frozen then
        Traversal.Unfreeze(current.ped)
    end

    if current.native and (IsPedClimbing(current.ped) or IsPedVaulting(current.ped)) then
        ClearPedTasks(current.ped)
    end

    if current.clip then
        Anim.Stop(current.ped, config.traversal.hangAnim)
    end
end

---@param traversalData table
---@return boolean
local function isCurrentTraversal(traversalData)
    return activeTraversal == traversalData
end

---@param traversalData table
---@param targetPos vector3
---@param duration number
---@return boolean
local function lerpToTarget(traversalData, targetPos, duration)
    local ped = traversalData.ped
    local startPos = GetEntityCoords(ped)
    local prevPos = startPos
    local startTime = GetGameTimer()
    local totalDuration = mathMax(1, duration)
    local isSmartVault = traversalData.info.smartVault
    local rootHeight = traversalData.info.rootHeight

    while true do
        if not isCurrentTraversal(traversalData) then
            return false
        end

        local progress = Util.Clamp((GetGameTimer() - startTime) / totalDuration, 0.0, 1.0)
        local currentPos = Util.Lerp(startPos, targetPos, Util.Ease(progress))

        if isSmartVault and not Util.BodyPath(prevPos, currentPos, ped, rootHeight) then
            return false
        end

        SetEntityCoordsNoOffset(ped, currentPos.x, currentPos.y, currentPos.z, true, true, false)
        prevPos = currentPos

        if progress >= 1.0 then
            return true
        end

        Wait(0)
    end
end

---@param ped number
---@param info table
---@return boolean
function Traversal.Perform(ped, info)
    if not info or not State.CanTraverse(ped) then
        return false
    end

    State.token = State.token + 1
    State.traversing = true
    State.needsGround = true

    local traversalData = {
        ped = ped,
        token = State.token,
        info = info,
        deadline = GetGameTimer() + config.traversal.safetyTimeout,
        frozen = false,
        native = false,
        clip = false
    }

    activeTraversal = traversalData

    CreateThread(function()
        pcall(function(data)
            local currentPed = data.ped
            local cfg = config.traversal
            local currentInfo = data.info
            local startCoords = GetEntityCoords(currentPed)

            Traversal.Lean.Reset(currentPed)
            SetEntityHeading(currentPed, GetHeadingFromVector_2d(currentInfo.forward.x, currentInfo.forward.y))

            if cfg.useNativeClamber then
                data.native = true
                TaskClimb(currentPed, true)

                local clamberTimeout = GetGameTimer() + cfg.clamberGrace

                while isCurrentTraversal(data) and clamberTimeout > GetGameTimer() and not IsPedClimbing(currentPed) and not IsPedVaulting(currentPed) do
                    Wait(0)
                end

                if not isCurrentTraversal(data) then
                    return false
                end

                if IsPedClimbing(currentPed) or IsPedVaulting(currentPed) then
                    while isCurrentTraversal(data) do
                        local curCoords = GetEntityCoords(currentPed)
                        local targetZ = currentInfo.smartVault and mathMax(currentInfo.destination.z, currentInfo.edge.z + currentInfo.rootHeight) or currentInfo.destination.z

                        if curCoords.z > targetZ + 0.7 or #(curCoords - startCoords) > 4.0 then
                            return false
                        end

                        if not currentInfo.smartVault and curCoords.z >= currentInfo.destination.z - 0.15 then
                            break
                        end

                        Wait(0)

                        if not IsPedClimbing(currentPed) and not IsPedVaulting(currentPed) then
                            break
                        end
                    end

                    data.native = false

                    if not currentInfo.smartVault then
                        return true
                    end

                    local endCoords = GetEntityCoords(currentPed)
                    local delta2D = vec3(currentInfo.destination.x - endCoords.x, currentInfo.destination.y - endCoords.y, 0.0)

                    if #delta2D <= 0.35 and mathAbs(endCoords.z - currentInfo.destination.z) <= 0.35 then
                        return true
                    end

                    if Util.Dot(delta2D, currentInfo.forward) < 0.0 then
                        return false
                    end
                else
                    ClearPedTasks(currentPed)
                    data.native = false
                end
            end

            local pedCoords = GetEntityCoords(currentPed)

            if currentInfo.smartVault then
                local smartLanding = findSmartVaultLanding(currentInfo.edge, currentInfo.forward, currentPed, currentInfo.edge.z - currentInfo.rise, currentInfo.rootHeight)

                if not smartLanding then
                    return false
                end

                currentInfo.destination = smartLanding + vec3(0.0, 0.0, currentInfo.rootHeight + 0.025)

                local peakZ = mathMax(pedCoords.z, currentInfo.edge.z + currentInfo.rootHeight + 0.12, currentInfo.destination.z + 0.12)
                currentInfo.path = {
                    pedCoords,
                    vec3(pedCoords.x, pedCoords.y, peakZ),
                    vec3(currentInfo.destination.x, currentInfo.destination.y, peakZ),
                    currentInfo.destination
                }

                for i = 1, 3 do
                    if not Util.BodyPath(currentInfo.path[i], currentInfo.path[i + 1], currentPed, currentInfo.rootHeight) then
                        return false
                    end
                end
            end

            if currentInfo.mode == 'climb' and #(currentInfo.path[1] - pedCoords) > cfg.maxAssist then
                return false
            end

            if not Util.BodyPath(pedCoords, currentInfo.path[1], currentPed, currentInfo.rootHeight) then
                return false
            end

            if not isCurrentTraversal(data) then
                return false
            end

            FreezeEntityPosition(currentPed, true)
            data.frozen = true
            Traversal.frozen = true

            data.clip = Anim.Play(currentPed, cfg.hangAnim, 2)

            if not lerpToTarget(data, currentInfo.path[1], (currentInfo.mode == 'climb') and (cfg.reachTime or 1) or 1) then
                return false
            end

            if currentInfo.mode == 'climb' then
                local hangEnd = GetGameTimer() + cfg.hangTime

                while hangEnd > GetGameTimer() do
                    if not isCurrentTraversal(data) then
                        return false
                    end

                    Wait(0)
                end
            end

            local traverseDuration = cfg.climbTime

            if currentInfo.mode == 'vault' then
                traverseDuration = cfg.vaultTime or traverseDuration
            elseif currentInfo.mode == 'mantle' then
                traverseDuration = cfg.mantleTime or traverseDuration
            end

            if not lerpToTarget(data, currentInfo.path[2], traverseDuration * 0.45) then
                return false
            end

            if not lerpToTarget(data, currentInfo.path[3], traverseDuration * 0.4) then
                return false
            end

            if not lerpToTarget(data, currentInfo.path[4], traverseDuration * 0.15) then
                return false
            end

            SetEntityVelocity(currentPed, 0.0, 0.0, 0.0)

            return true
        end, traversalData)

        if activeTraversal == traversalData then
            Traversal.Cancel()
        elseif traversalData.frozen then
            Traversal.Unfreeze(traversalData.ped)
        end
    end)

    return true
end

---@param ped number
function Traversal.Tick(ped)
    if activeTraversal then
        if not isCurrentTraversal(activeTraversal) then
            Traversal.Cancel()
        end

        return
    end

    local cfg = config.traversal

    if not cfg.enabled or State.traversing or IsPauseMenuActive() then
        return
    end
    local isFallingCatch = false

    if cfg.catchWhileFalling and IsPedFalling(ped) then
        isFallingCatch = GetEntityVelocity(ped).z < -cfg.minFallSpeed
    end

    if not IsPedJumping(ped) and not isFallingCatch then
        return
    end

    local now = GetGameTimer()

    if now < nextScanTime then
        return
    end

    nextScanTime = now + mathMax(40, cfg.scanInterval)

    if not Traversal.Prospect(ped) then
        return
    end

    local candidate = Traversal.Scan(ped)

    if candidate then
        Traversal.Perform(ped, candidate)
    end
end

function Traversal.BlockControls()
    if not State.traversing then
        return
    end

    DisablePlayerFiring(PlayerId(), true)

    for i = 1, blockedCount do
        DisableControlAction(0, blockedControls[i], true)
    end
end

return Traversal
