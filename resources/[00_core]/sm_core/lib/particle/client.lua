local functions = {}

---@deprecated use ParticleFx natives directly
functions.StartParticleAtCoord = function(dict, ptName, looped, coords, rot, scale, alpha, color, duration) -- luacheck: ignore
    coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords or GetEntityCoords(cache.ped)

    lib.requestNamedPtfxAsset(dict)
    UseParticleFxAssetNextCall(dict)
    SetPtfxAssetNextCall(dict)
    local particleHandle
    if looped then
        particleHandle = StartParticleFxLoopedAtCoord(ptName, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, scale or 1.0, false, false, false, false)
        if color then
            SetParticleFxLoopedColour(particleHandle, color.r, color.g, color.b, false)
        end
        SetParticleFxLoopedAlpha(particleHandle, alpha or 10.0)
        if duration then
            Wait(duration)
            StopParticleFxLooped(particleHandle, false)
        end
    else
        SetParticleFxNonLoopedAlpha(alpha or 1.0)
        if color then
            SetParticleFxNonLoopedColour(color.r, color.g, color.b)
        end
        StartParticleFxNonLoopedAtCoord(ptName, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, scale or 1.0, false, false, false)
    end
    return particleHandle
end

---@deprecated use ParticleFx natives directly
functions.StartParticleOnEntity = function(dict, ptName, looped, entity, bone, offset, rot, scale, alpha, color, evolution, duration) -- luacheck: ignore
    lib.requestNamedPtfxAsset(dict)
    UseParticleFxAssetNextCall(dict)
    local particleHandle = nil
    ---@cast bone number
    local pedBoneIndex = bone and GetPedBoneIndex(entity, bone) or 0
    ---@cast bone string
    local nameBoneIndex = bone and GetEntityBoneIndexByName(entity, bone) or 0
    local entityType = GetEntityType(entity)
    local boneID = entityType == 1 and (pedBoneIndex ~= 0 and pedBoneIndex) or (looped and nameBoneIndex ~= 0 and nameBoneIndex)
    if looped then
        if boneID then
            particleHandle = StartParticleFxLoopedOnEntityBone(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, boneID, scale or 1.0, false, false, false)
        else
            particleHandle = StartParticleFxLoopedOnEntity(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, scale or 1.0, false, false, false)
        end
        if evolution then
            SetParticleFxLoopedEvolution(particleHandle, evolution.name, evolution.amount, false)
        end
        if color then
            SetParticleFxLoopedColour(particleHandle, color.r, color.g, color.b, false)
        end
        SetParticleFxLoopedAlpha(particleHandle, alpha or 1.0)
        if duration then
            Wait(duration)
            StopParticleFxLooped(particleHandle, false)
        end
    else
        SetParticleFxNonLoopedAlpha(alpha or 1.0)
        if color then
            SetParticleFxNonLoopedColour(color.r, color.g, color.b)
        end
        if boneID then
            StartParticleFxNonLoopedOnPedBone(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, boneID, scale or 1.0, false, false, false)
        else
            StartParticleFxNonLoopedOnEntity(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, scale or 1.0, false, false, false)
        end
    end
    return particleHandle
end

return functions