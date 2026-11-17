local peds = localmodule 'data.peds'
local exportWrapper = require 'export_wrapper'
local interact = exports.rhd_interact

local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded

local MALE_FREEMODE = `mp_m_freemode_01`
local FEMALE_FREEMODE = `mp_f_freemode_01`
local DEFAULT_BONE = 28422
local DEFAULT_RENDER_DISTANCE = 30.0
local PRELOAD_TIMEOUT <const> = 5000
local currentResource = cache.resource

---@type table<string, table[]>
local entriesByResource = {}

---@param model string|number
---@return number
local function toHash(model)
    return type(model) == 'string' and joaat(model) or model
end

---@param ped number
---@param face table
local function applyFace(ped, face)
    SetPedHeadBlendData(ped,
        face.father or 0, face.mother or 0, 0,
        face.skinFather or face.father or 0,
        face.skinMother or face.mother or 0,
        0,
        face.shapeMix or 0.5,
        face.skinMix or 0.5,
        0.0, false
    )

    local hair = face.hair
    if hair then
        SetPedComponentVariation(ped, 2, hair.model or 0, 0, 0)
        SetPedHairColor(ped, hair.color or 0, hair.highlight or 0)
    end

    local brows = face.eyebrows
    if brows then
        SetPedHeadOverlay(ped, 2, brows.model or 0, brows.opacity or 1.0)
        if brows.color then
            SetPedHeadOverlayColor(ped, 2, 1, brows.color, brows.colorSecond or brows.color)
        end
    end

    local features = face.features
    if features then
        for i = 0, 19 do
            if features[i] then
                SetPedFaceFeature(ped, i, features[i])
            end
        end
    end

    if face.overlays then
        for overlayId, overlay in pairs(face.overlays) do
            SetPedHeadOverlay(ped, overlayId, overlay.model or 0, overlay.opacity or 1.0)
            if overlay.color then
                SetPedHeadOverlayColor(ped, overlayId, overlay.colorType or 1, overlay.color, overlay.secondColor or overlay.color)
            end
        end
    end

    if face.eyeColor then
        SetPedEyeColor(ped, face.eyeColor)
    end
end

---@param ped number
---@param outfit table[]
local function preloadOutfit(ped, outfit)
    for i = 1, #outfit do
        local part = outfit[i]

        if part.component then
            SetPedPreloadVariationData(ped, part.component, part.drawable or 0, part.texture or 0)
        end
    end

    local deadline = GetGameTimer() + PRELOAD_TIMEOUT

    while DoesEntityExist(ped) and not HasPedPreloadVariationDataFinished(ped) and GetGameTimer() < deadline do
        Wait(0)
    end
end

---@param ped number
---@param outfit table[]
local function applyOutfit(ped, outfit)
    for i = 1, #outfit do
        local part = outfit[i]

        if part.component then
            SetPedComponentVariation(ped, part.component, part.drawable or 0, part.texture or 0, 0)
        end
    end

    ReleasePedPreloadVariationData(ped)
end

---@param ped number
---@param prop table
---@return number?
local function attachProp(ped, prop)
    local model = toHash(prop.propModel)
    if not pcall(lib.requestModel, model, 5000) then return end

    local entity = CreateObject(model, 0.0, 0.0, 0.0, false, false, false)
    SetModelAsNoLongerNeeded(model)
    if entity == 0 then return end

    local bone = prop.bone
    local boneIndex = type(bone) == 'string' and GetEntityBoneIndexByName(ped, bone) or GetPedBoneIndex(ped, bone or DEFAULT_BONE)
    local pos = prop.pos or prop.offset
    local rot = prop.rot or prop.rotation

    AttachEntityToEntity(entity, ped, boneIndex,
        pos and pos.x or 0.0, pos and pos.y or 0.0, pos and pos.z or 0.0,
        rot and rot.x or 0.0, rot and rot.y or 0.0, rot and rot.z or 0.0,
        true, true, false, true, 0, true
    )

    return entity
end

---@param entry table
local function despawn(entry)
    local ped = entry.ped
    entry.ped = nil

    if entry.propEntity then
        DeleteEntity(entry.propEntity)
        entry.propEntity = nil
    end

    if not ped then return end

    if entry.data.onDespawn then
        pcall(entry.data.onDespawn, ped)
    end

    if DoesEntityExist(ped) then
        if entry.data.targetOptions then
            ox_target:removeLocalEntity(ped)
        end
        if entry.data.interactOptions then
            interact:removeLocalEntity(ped)
        end
        DeleteEntity(ped)
    end
end

---@param entry table
local function spawn(entry)
    if entry.ped or entry.loading then return end

    local data = entry.data
    local model = toHash(data.model)

    entry.loading = true
    local ok = pcall(lib.requestModel, model, 10000)
    entry.loading = false

    if not ok or not entry.inside or entry.removed then
        SetModelAsNoLongerNeeded(model)
        return
    end

    local coords = entry.coords
    local ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    SetModelAsNoLongerNeeded(model)
    if ped == 0 then return end

    entry.ped = ped

    SetEntityAsMissionEntity(ped, true, true)
    SetPedDefaultComponentVariation(ped)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, true)
    SetPedKeepTask(ped, true)

    if data.outfit then
        preloadOutfit(ped, data.outfit)
    else
        Wait(100)
    end

    if entry.ped ~= ped or not DoesEntityExist(ped) then return end

    if data.faceData and (model == MALE_FREEMODE or model == FEMALE_FREEMODE) then
        applyFace(ped, data.faceData)
    end

    if data.outfit then
        applyOutfit(ped, data.outfit)
    end

    if data.targetOptions then
        ox_target:addLocalEntity(ped, data.targetOptions)
    end

    if data.interactOptions then
        interact:addLocalEntity(ped, data.interactOptions)
    end

    local anim = data.animation

    if anim and pcall(lib.requestAnimDict, anim.dict, 5000) then
        if entry.ped ~= ped then
            RemoveAnimDict(anim.dict)
            return
        end

        TaskPlayAnim(ped, anim.dict, anim.anim, 3.0, -8.0, -1, anim.flag or 1, 0, false, false, false)
        RemoveAnimDict(anim.dict)
    end

    if data.scenario then
        TaskStartScenarioInPlace(ped, data.scenario, 0, false)
    end

    if data.prop then
        local prop = attachProp(ped, data.prop)

        if entry.ped ~= ped then
            if prop then
                DeleteEntity(prop)
            end

            return
        end

        entry.propEntity = prop
    end

    if data.onSpawn then
        pcall(data.onSpawn, ped)
    end

    if not entry.inside or entry.removed then
        despawn(entry)
    end
end

---@param data table
local function addPed(data)
    local resource = GetInvokingResource() or currentResource
    local coordsType = type(data.coords)
    assert(coordsType == 'vector4' or coordsType == 'table', ('pedmanager expected vector4 or vector4[], got %s'):format(coordsType))

    local list = coordsType == 'vector4' and { data.coords } or data.coords
    local entries = entriesByResource[resource]
    if not entries then
        entries = {}
        entriesByResource[resource] = entries
    end

    for i = 1, #list do
        local coords = list[i]
        assert(type(coords) == 'vector4', ('pedmanager expected vector4, got %s'):format(type(coords)))

        local entry = { data = data, coords = coords }
        local point = lib.points.new({
            coords = coords.xyz,
            distance = data.renderDistance or DEFAULT_RENDER_DISTANCE,
        })

        function point:onEnter()
            entry.inside = true
            spawn(entry)
        end

        function point:onExit()
            entry.inside = false
            despawn(entry)
        end

        entry.point = point
        entries[#entries + 1] = entry
    end
end

---@param resource string
local function clearResource(resource)
    local entries = entriesByResource[resource]
    if not entries then return end
    entriesByResource[resource] = nil

    for i = 1, #entries do
        local entry = entries[i]
        entry.removed = true
        entry.inside = false
        entry.point:remove()
        despawn(entry)
    end
end

AddEventHandler('onClientResourceStop', function(resource)
    if resource == currentResource then
        for name in pairs(entriesByResource) do
            clearResource(name)
        end
        return
    end
    clearResource(resource)
end)

exports('addPed', addPed)
exportWrapper('sm_utilized', 'addPed', addPed)

CreateThread(function()
    for i = 1, #peds do
        addPed(peds[i])
    end
end)
