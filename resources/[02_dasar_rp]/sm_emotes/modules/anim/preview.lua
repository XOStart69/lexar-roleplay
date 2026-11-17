local preview = {}

preview.ped = nil
preview.props = {}
preview.id = 0
preview.active = false
preview.isZoom = false

local PREVIEW_SCREEN_X = 0.65
local PREVIEW_SCREEN_Y = 0.60
local PREVIEW_DISTANCE = 6.0

local ZOOM_SCREEN_X = 0.6
local ZOOM_SCREEN_Y = 1.5
local ZOOM_DISTANCE = 2.0

function preview.finish()
    if not preview.active then return end

    for i = 1, #preview.props do
        local entity = preview.props[i]

        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end

    preview.props = {}

    if preview.ped and DoesEntityExist(preview.ped) then
        DeleteEntity(preview.ped)
    end

    preview.ped = nil
    preview.active = false
    preview.isZoom = false
end

---@return number? ped
function preview.createPreviewPed()
    local ped = ClonePed(cache.ped, false, false, true)

    if not DoesEntityExist(ped) then
        return nil
    end

    SetEntityCollision(ped, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    local buffers = {}
    CreateThread(function()
        while DoesEntityExist(ped) and preview.active do
            Wait(0)

            local screenX = preview.isZoom and ZOOM_SCREEN_X or PREVIEW_SCREEN_X
            local screenY = preview.isZoom and ZOOM_SCREEN_Y or PREVIEW_SCREEN_Y
            local distance = preview.isZoom and ZOOM_DISTANCE or PREVIEW_DISTANCE

            local worldVector, normalVector = GetWorldCoordFromScreenCoord(screenX, screenY)
            local buffer = worldVector + normalVector * distance
            local camRot = GetGameplayCamRot(2)

            buffers[#buffers + 1] = buffer

            if #buffers > 5 then
                table.remove(buffers, 1)
            end

            local previewCoords = vec3(0.0, 0.0, 0.0)

            for i = 1, #buffers do
                previewCoords = previewCoords + buffers[i]
            end

            previewCoords = previewCoords / #buffers

            local heading = camRot.z + 180.0

            SetEntityCoords(ped, previewCoords.x, previewCoords.y, previewCoords.z, false, false, false, false)
            SetEntityHeading(ped, heading)
            SetEntityRotation(ped, camRot.x * (-1), 0.0, camRot.z + 170.0, 2, false)
        end
    end)

    return ped
end

---@param ped number
---@param emote_data CacheEmote
---@param texture? number
local function addPreviewProps(ped, emote_data, texture)
    local AnimationOptions = emote_data.AnimationOptions

    if not AnimationOptions or not AnimationOptions.Prop then
        return
    end

    local x, y, z, rx, ry, rz = table.unpack(AnimationOptions.PropPlacement)
    local propHash = AnimationOptions.Prop

    if not IsModelValid(propHash) then
        return
    end

    lib.requestModel(propHash, 15000)

    local previewCoords = GetEntityCoords(ped)
    local object = CreateObject(propHash, previewCoords.x, previewCoords.y, previewCoords.z, false, false, false)

    if texture then
        SetObjectTextureVariation(object, texture)
    end

    SetEntityCollision(object, false, false)
    AttachEntityToEntity(
        object, ped,
        GetPedBoneIndex(ped, AnimationOptions.PropBone),
        x or 0.0, y or 0.0, z or 0.0,
        rx or 0.0, ry or 0.0, rz or 0.0,
        true, true, false, true, 1, true
    )

    SetModelAsNoLongerNeeded(propHash)
    preview.props[#preview.props + 1] = object

    if AnimationOptions.SecondProp then
        local sx, sy, sz, srx, sry, srz = table.unpack(AnimationOptions.SecondPropPlacement)
        local secondPropHash = AnimationOptions.SecondProp

        if IsModelValid(secondPropHash) then
            lib.requestModel(secondPropHash, 15000)

            local secondObject = CreateObject(secondPropHash, previewCoords.x, previewCoords.y, previewCoords.z, false, false, false)

            if texture then
                SetObjectTextureVariation(secondObject, texture)
            end

            SetEntityCollision(secondObject, false, false)
            AttachEntityToEntity(
                secondObject,
                ped,
                GetPedBoneIndex(ped, AnimationOptions.SecondPropBone),
                sx or 0.0, sy or 0.0, sz or 0.0,
                srx or 0.0, sry or 0.0, srz or 0.0,
                true, true, false, true, 1, true
            )
            SetModelAsNoLongerNeeded(secondPropHash)

            preview.props[#preview.props + 1] = secondObject
        end
    end
end

---@param ped number
---@param emote_data CacheEmote
local function previewWalks(ped, emote_data)
    local clipset = emote_data.anim

    lib.requestAnimSet(clipset)
    SetPedMovementClipset(ped, clipset, 0.2)
    TaskWanderStandard(ped, 10.0, 10)
    local camRot = GetGameplayCamRot(2)
    local hading = camRot.z + 180.0
    local targetCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 0.0)
    
    TaskGoStraightToCoord(ped,
    targetCoords.x, targetCoords.y + 0.5, targetCoords.z,
        0.5, -1, hading, 0.1
    )
end

---@param ped number
local function hideBodyComponents(ped)
    -- local componentsToHide = {3, 4, 5, 6, 7, 8, 9, 10, 11}

    -- for _, componentId in ipairs(componentsToHide) do
    --     SetPedComponentVariation(ped, componentId, 0, 0, 0)
    -- end

    -- SetPedComponentVariation(ped, 3, -1, 0, 0)  -- Torso
    -- SetPedComponentVariation(ped, 4, -1, 0, 0)  -- Legs
    -- SetPedComponentVariation(ped, 5, -1, 0, 0)  -- Hands
    -- SetPedComponentVariation(ped, 6, -1, 0, 0)  -- Feet
    -- SetPedComponentVariation(ped, 8, -1, 0, 0)  -- Accessories
    -- SetPedComponentVariation(ped, 11, -1, 0, 0) -- Torso2
end

---@param ped number
---@param emote_data CacheEmote
local function previewExpressions(ped, emote_data)
    preview.isZoom = true
    hideBodyComponents(ped)
    lib.playAnim(ped, "mp_sleep", "bind_pose_180", 8.0, 1, -1, 1, 0, false, false, false)
    Wait(100)
    SetFacialIdleAnimOverride(ped, emote_data.anim, 0)
end

---@param ped number
---@param emote_data CacheEmote
local function previewScenario(ped, emote_data)
    local scenario = emote_data.scenario
    local scenarioType = emote_data.scenarioType

    if scenarioType == ScenarioType.OBJECT then
        local pedCoords = GetEntityCoords(ped)
        local behindPed = GetOffsetFromEntityInWorldCoords(ped, 0.0, -0.5, -0.5)
        TaskStartScenarioAtPosition(ped, scenario, behindPed.x, behindPed.y, behindPed.z, GetEntityHeading(ped), 0, true, false)
    else
        TaskStartScenarioInPlace(ped, scenario, 0, true)
    end
end

---@param command string
---@param texture? number
function preview.show(command, texture)
    if not command then return end

    if preview.active then
        preview.finish()
    end

    local emote_data = utils.getEmote(command)

    if not emote_data then
        return
    end

    local category = emote_data.category


    preview.id = preview.id + 1
    local previewId = preview.id

    preview.active = true
    preview.ped = preview.createPreviewPed()

    if not preview.ped then
        preview.active = false
        return
    end

    preview.props = {}

    if category == 'walks' then
        previewWalks(preview.ped, emote_data)
    elseif category == 'expressions' then
        previewExpressions(preview.ped, emote_data)
    elseif category == 'scenario' or emote_data.scenario then
        previewScenario(preview.ped, emote_data)
    else
        local dict = emote_data.dict
        local anim = emote_data.anim
        local AnimationOptions = emote_data.AnimationOptions

        if not lib.requestAnimDict(dict) then
            preview.finish()
            return
        end

        local duration = -1
        local movementFlag = 0

        if AnimationOptions then
            if AnimationOptions.EmoteDuration then
                duration = AnimationOptions.EmoteDuration
            end

            if AnimationOptions.Flag then
                movementFlag = AnimationOptions.Flag
            elseif AnimationOptions.onFootFlag then
                movementFlag = AnimationOptions.onFootFlag
            end

            if AnimationOptions.Prop then
                addPreviewProps(preview.ped, emote_data, texture)
            end
        end

        TaskPlayAnim(preview.ped, dict, anim, 2.0, 2.0, duration, movementFlag, 0, false, false, false)
        RemoveAnimDict(dict)
    end

    SetTimeout(5000, function()
        if previewId == preview.id and preview.active then
            preview.finish()
        end
    end)
end

_ENV.preview = preview
