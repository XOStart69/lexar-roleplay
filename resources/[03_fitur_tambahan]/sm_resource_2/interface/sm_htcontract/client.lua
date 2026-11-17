local config = localmodule 'config'
local exportWrapper = require 'export_wrapper'
local hasFrame = interface.init(false)

local ANIM = config.anim
local TARGET_DELAY = config.targetOpenDelay
local COMPLETE_DELAY = config.completeDelay

local uiOpen = false
local inContract = false
local props = {}

ox_inventory:displayMetadata({
    contractId = 'Contract ID',
    initiatorName = 'Initiator',
    initiatorJob = 'Initiator Role',
    targetName = 'Target',
    targetJob = 'Target Role',
})

---@param action string
---@param data? table
local function send(action, data)
    interface.send({ action = action, data = data or {} })
end

---@param prop table
---@return number?
local function attachProp(prop)
    if not pcall(lib.requestModel, prop.model, 5000) then return end

    local ped = cache.ped
    local entity = CreateObject(joaat(prop.model), 0.0, 0.0, 0.0, true, true, false)
    SetModelAsNoLongerNeeded(prop.model)
    AttachEntityToEntity(entity, ped, GetPedBoneIndex(ped, prop.bone), prop.offset.x, prop.offset.y, prop.offset.z, prop.rotation.x, prop.rotation.y, prop.rotation.z, true, true, false, true, 1, true)
    return entity
end

local function startAnim()
    if #props > 0 then return end
    if pcall(lib.requestAnimDict, ANIM.dict, 5000) then
        TaskPlayAnim(cache.ped, ANIM.dict, ANIM.name, 8.0, -8.0, -1, ANIM.flag, 0, false, false, false)
        RemoveAnimDict(ANIM.dict)
    end
    for i = 1, #ANIM.props do
        props[#props + 1] = attachProp(ANIM.props[i])
    end
end

local function stopAnim()
    StopAnimTask(cache.ped, ANIM.dict, ANIM.name, 1.0)
    for i = #props, 1, -1 do
        local entity = props[i]
        if entity and DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
        props[i] = nil
    end
end

local function openUI()
    if not hasFrame then return false end
    if not uiOpen then
        uiOpen = true
        interface.show()
    end
    interface.focus(true, true)
    return true
end

local function closeUI()
    inContract = false
    stopAnim()
    if not uiOpen then return end

    uiOpen = false
    interface.focus(false, false)
    SetTimeout(50, function()
        if not uiOpen then interface.hide() end
    end)
end

---@return boolean
local function authorized()
    local job = QBPlayerData.job
    return job ~= nil and job.name == config.requiredJob and job.grade.level >= config.requiredGrade
end

exportWrapper('sm_htcontract', 'useContract', function()
    if uiOpen then return end
    if not authorized() then
        return lib.notify({ type = 'error', description = 'You are not authorized' })
    end
    if not openUI() then return end
    startAnim()
    send('coinOpen')
end)

exportWrapper('sm_htcontract', 'viewSignedContract', function(_, slot)
    local metadata = slot and slot.metadata
    if uiOpen or not metadata or not metadata.contractId then
        return lib.notify({ type = 'error', description = 'Invalid contract' })
    end
    if not openUI() then return end
    send('viewSigned', { contract = metadata })
end)

if hasFrame then
    interface.callback('requestNearby', function(_, cb)
        cb({})
        local players = lib.callback.await('sm_htcontract:nearby', false)
        send('showNearby', { players = players or {} })
    end)

    interface.callback('selectTarget', function(data, cb)
        cb({})
        if type(data) == 'table' then
            TriggerTokenEvent('sm_htcontract:server:send', data.serverId)
        end
    end)

    interface.callback('sign', function(_, cb)
        cb({})
        if inContract then
            TriggerTokenEvent('sm_htcontract:server:sign')
        end
    end)

    interface.callback('cancel', function(_, cb)
        cb({})
        if inContract then
            TriggerTokenEvent('sm_htcontract:server:cancel')
        end
        closeUI()
    end)

    interface.callback('closeUI', function(_, cb)
        cb({})
        closeUI()
    end)
end

RegisterNetEvent('sm_htcontract:client:open', function(payload, role)
    if source == '' then return end
    inContract = true

    if role == 'target' then
        if not openUI() then return end
        startAnim()
        send('coinOpenTarget')
        Wait(TARGET_DELAY)
        if not inContract then return end
    end

    send('openContract', { contract = payload, role = role })
end)

RegisterNetEvent('sm_htcontract:client:partnerSigned', function(role)
    if source == '' then return end
    send('partnerSigned', { role = role })
end)

RegisterNetEvent('sm_htcontract:client:complete', function()
    if source == '' then return end
    inContract = false
    send('contractComplete')
    lib.notify({ type = 'success', description = 'Blood oath sealed' })
    Wait(COMPLETE_DELAY)
    closeUI()
end)

RegisterNetEvent('sm_htcontract:client:cancelled', function()
    if source == '' then return end
    send('close')
    closeUI()
    lib.notify({ type = 'error', description = 'Contract cancelled' })
end)

AddEventHandler('sm_htcontract:client:forceClose', function()
    if inContract then
        TriggerTokenEvent('sm_htcontract:server:cancel')
    end
    send('close')
    closeUI()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        stopAnim()
    end
end)
