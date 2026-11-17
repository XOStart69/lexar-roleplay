if lib.context == 'server' then return end

local cacheProps = {}
local localProps = {}

local function clearProps(serverId)
    if not serverId then
        for k, v in pairs(cacheProps) do
            if v and type(v) == 'table' then
                for i = 1, #v do
                    local entity = v[i]
                    if DoesEntityExist(entity) then
                        DetachEntity(entity, true, true)
                        Wait(0)
                        pcall(DeleteEntity, entity)
                    end
                end
            end
        end
        cacheProps = {}
        return
    end

    local props = cacheProps[serverId]
    
    if not props then
        return
    end

    for i=1, #props do
        local entity = props[i]
        if DoesEntityExist(entity) then
            DetachEntity(entity, true, true)
            Wait(0)
            pcall(DeleteEntity, entity)
        end
    end
    cacheProps[serverId] = nil
end

local function clearLocal()
    if #localProps < 1 then
        return
    end

    for i=1, #localProps do
        local entity = localProps[i]
        if DoesEntityExist(entity) then
            DetachEntity(entity, true, true)
            Wait(0)
            pcall(DeleteEntity, entity)
        end
    end

    localProps = {}
end

local function clearPropsFromPed(ped)
    if not DoesEntityExist(ped) then return end
    
    local deletedEntities = {}
    
    for k, v in pairs(cacheProps) do
        if v and type(v) == 'table' then
            for i = #v, 1, -1 do
                local entity = v[i]
                if DoesEntityExist(entity) and not deletedEntities[entity] then
                    local attachedTo = GetEntityAttachedTo(entity)
                    if attachedTo == ped then
                        DetachEntity(entity, true, true)
                        Wait(0)
                        pcall(DeleteEntity, entity)
                        deletedEntities[entity] = true
                        table.remove(v, i)
                    end
                end
            end
            if #v == 0 then
                cacheProps[k] = nil
            end
        end
    end
    
    for i = #localProps, 1, -1 do
        local entity = localProps[i]
        if DoesEntityExist(entity) and not deletedEntities[entity] then
            local attachedTo = GetEntityAttachedTo(entity)
            if attachedTo == ped then
                DetachEntity(entity, true, true)
                Wait(0)
                pcall(DeleteEntity, entity)
                deletedEntities[entity] = true
                table.remove(localProps, i)
            end
        end
    end
end

---@param data table
---@return integer?
local function addProp(ped, data)
    local prop, bone, offset, rotation, texture, nocoll = data.prop, data.bone, data.offset, data.rotation, data.texture, data.nocoll

    assert(prop, 'No prop passed')
    assert(bone, 'No bone passed')
    assert(nocoll == nil or type(nocoll) == "boolean", 'noCollision must be a boolean')

    if not DoesEntityExist(ped) then
        return nil
    end

    local coords = GetEntityCoords(ped)
    local x, y, z = table.unpack(coords)

    if not IsModelValid(prop) then
        lib.print.warn(prop .. " is not a valid model!")
        return
    end

    local model = lib.requestModel(prop, 15000)

    if not model then
        return
    end

    local props = CreateObject(model, x, y, z + 0.2, false, true, false)
    SetEntityAsMissionEntity(props, true, true)

    if texture ~= nil then
        SetObjectTextureVariation(props, texture)
    end

    if nocoll then
        SetEntityCollision(props, false, false)
    end

    AttachEntityToEntity(
        props,
        ped,
        GetPedBoneIndex(ped, bone),
        offset.x, offset.y, offset.z,
        rotation.x, rotation.y, rotation.z,
        true, true, false, true, 1, true
    )

    SetModelAsNoLongerNeeded(prop)

    return props
end

---@param ped number
---@param serverId number
---@param emote string
---@param texture? integer
local function addProps(ped, serverId, emote, texture)
    if not emote or type(emote) ~= 'string' then
        return
    end
    
    local emote_data = utils.getEmote(emote)
    
    if not emote_data then
        return
    end

    local options = emote_data.AnimationOptions
    if not options then return end
    
    if not options.Prop then
        return
    end

    if not options.PropPlacement then
        return
    end
    
    if type(options.PropPlacement) ~= 'table' then
        return
    end
    
    local propLen = 0
    pcall(function()
        propLen = #options.PropPlacement
    end)
    
    if propLen < 5 then
        return
    end

    local x, y, z, rx, ry, rz = table.unpack(options.PropPlacement)

    local waitTime = options and options.EmoteDuration or 0
    if waitTime > 0 then
        Wait(waitTime)
        if not DoesEntityExist(ped) then
            return
        end
    end

    local nt = cacheProps[serverId] or {}

    local added = addProp(ped, {
        prop = options.Prop,
        bone = options.PropBone,
        offset = vec(x or 0.0, y or 0.0, z or 0.0),
        rotation = vec(rx or 0.0, ry or 0.0, rz or 0.0),
        texture = texture,
        nocoll = options.PropNoCollision
    })

    if added then
        nt[#nt+1] = added
        cacheProps[serverId] = nt
    end
    
    if added and options.SecondProp then
        if not DoesEntityExist(ped) then
            clearProps(serverId)
            return
        end
        
        if not options.SecondPropPlacement then
            return added
        end
        
        if type(options.SecondPropPlacement) ~= 'table' then
            return added
        end
        
        local secondPropLen = 0
        pcall(function()
            secondPropLen = #options.SecondPropPlacement
        end)
        
        if secondPropLen < 5 then
            return added
        end

        x, y, z, rx, ry, rz = table.unpack(options.SecondPropPlacement)
        
        local secondAdded = addProp(ped, {
            prop = options.SecondProp,
            bone = options.SecondPropBone,
            offset = vec(x or 0.0, y or 0.0, z or 0.0),
            rotation = vec(rx or 0.0, ry or 0.0, rz or 0.0),
            texture = texture,
            nocoll = options.SecondPropNoCollision
        })
        
        if secondAdded then
            nt[#nt+1] = secondAdded
        end
    end

    if not added then
        clearProps(serverId)
        return
    end

    return added
end


---@param ped number
---@param emote string
---@param texture? integer
local function addPropsLocal(ped, emote, texture)
    if not emote or type(emote) ~= 'string' then
        return
    end
    
    local emote_data = utils.getEmote(emote)
    
    if not emote_data then
        return
    end

    local options = emote_data.AnimationOptions
    if not options then return end
    
    if not options.Prop then
        return
    end

    if not options.PropPlacement then
        return
    end
    
    if type(options.PropPlacement) ~= 'table' then
        return
    end
    
    local propLen = 0
    pcall(function()
        propLen = #options.PropPlacement
    end)
    
    if propLen < 5 then
        return
    end

    local x, y, z, rx, ry, rz = table.unpack(options.PropPlacement)

    local waitTime = options and options.EmoteDuration or 0
    if waitTime > 0 then
        Wait(waitTime)
        if not DoesEntityExist(ped) then
            return
        end
    end

    local added = addProp(ped, {
        prop = options.Prop,
        bone = options.PropBone,
        offset = vec(x or 0.0, y or 0.0, z or 0.0),
        rotation = vec(rx or 0.0, ry or 0.0, rz or 0.0),
        texture = texture,
        nocoll = options.PropNoCollision
    })

    if added then
        localProps[#localProps+1] = added
    end
    
    if added and options.SecondProp then
        if not DoesEntityExist(ped) then
            clearLocal()
            return
        end
        
        if not options.SecondPropPlacement then
            return added
        end
        
        if type(options.SecondPropPlacement) ~= 'table' then
            return added
        end
  
        local secondPropLen = 0
        pcall(function()
            secondPropLen = #options.SecondPropPlacement
        end)
        
        if secondPropLen < 5 then
            return added
        end

        x, y, z, rx, ry, rz = table.unpack(options.SecondPropPlacement)
        
        local secondAdded = addProp(ped, {
            prop = options.SecondProp,
            bone = options.SecondPropBone,
            offset = vec(x or 0.0, y or 0.0, z or 0.0),
            rotation = vec(rx or 0.0, ry or 0.0, rz or 0.0),
            texture = texture,
            nocoll = options.SecondPropNoCollision
        })
        
        if secondAdded then
            localProps[#localProps+1] = secondAdded
        end
    end

    if not added then
        clearLocal()
    end

    return added
end

local function getProps(serverId)
    if not cacheProps[serverId] then
        return
    end
    return cacheProps[serverId][#cacheProps[serverId]]
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    clearProps()
    clearLocal()
end)


_ENV.props = {
    add = addProps,
    clear = clearProps,
    get = getProps,
    addLocal = addPropsLocal,
    clearLocal = clearLocal,
    clearFromPed = clearPropsFromPed
}