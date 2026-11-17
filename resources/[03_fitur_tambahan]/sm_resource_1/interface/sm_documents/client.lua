local Config = localmodule 'config'

local QBCore = exports['qb-core']:GetCoreObject()

local Locale = Config.Locale
local PaperProp = Config.PaperProp
local PaperHash = joaat(PaperProp.name)

local GetEntityCoords = GetEntityCoords
local DisableControlAction = DisableControlAction
local IsControlJustReleased = IsControlJustReleased
local GetPlayerServerId = GetPlayerServerId
local DoesEntityExist = DoesEntityExist
local getClosestPlayer = lib.getClosestPlayer
local Wait = Wait

local INFO_ID = 'sm_documents:selector'

local prop = nil
local selectingPlayer = false

local markerTop = lib.marker.new({
    type = 'ChevronUpx1',
    coords = vec3(0, 0, 0),
    width = 0.4,
    height = -0.4,
    direction = vec3(0, 0, 0),
    color = { r = 26, g = 161, b = 149, a = 120 }
})

local markerGround = lib.marker.new({
    type = 'HorizontalCircleSkinny',
    coords = vec3(0, 0, 0),
    width = 1.0,
    height = 1.0,
    color = { r = 26, g = 161, b = 149, a = 120 }
})

interface.init(false)

local frameMounted = false
local frameReady = false
local pendingSender = nil

local function openSurface(sender)
    pendingSender = sender

    if not frameMounted then
        frameReady = false
        frameMounted = true
        interface.show()
    elseif frameReady then
        pendingSender = nil
        sender()
    end
end

local function closeSurface()
    pendingSender = nil
    if not frameMounted then return end

    interface.hide()
    frameMounted = false
    frameReady = false
end

local function detachPaper()
    if not prop then return end

    if DoesEntityExist(prop) then DeleteEntity(prop) end
    prop = nil
end

local function attachPaper()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)

    if not pcall(lib.requestModel, PaperHash, 2000) then return end

    prop = CreateObject(PaperHash, coords.x, coords.y, coords.z + 0.2, true, true, true)
    SetEntityCompletelyDisableCollision(prop, false, false)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 36029), 0.16, 0.08, 0.1,
        PaperProp.xRot, PaperProp.yRot, PaperProp.zRot, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(PaperHash)
end

local function holdDocument(shouldHold)
    detachPaper()

    if shouldHold then
        lib.playAnim(cache.ped, 'missfam4', 'base', 2.0, 2.0, -1, 51)
        attachPaper()
    else
        ClearPedTasks(cache.ped)
    end
end

local function openDocuments()
    openSurface(function()
        interface.send({ action = 'setVisible', data = true })
        interface.focus(true, true)
    end)

    holdDocument(true)
end

local function showDocumentFrom(document)
    openSurface(function()
        interface.send({ action = 'setDocument', data = document })
        interface.focus(true, true)
    end)

    holdDocument(true)
end

local function closeDocuments(keepHolding)
    interface.focus(false, false)
    closeSurface()

    if not keepHolding then holdDocument(false) end
end

interface.callback('documentsReady', function(_, cb)
    cb('ok')
    frameReady = true

    local sender = pendingSender
    pendingSender = nil
    if sender then sender() end
end)

interface.callback('getConfig', function(_, cb)
    cb({
        texts = Config.Texts,
        availableJobs = Config.AvailableJobs,
        citizenTemplates = Config.CitizenTemplates
    })
end)

interface.callback('hideFrame', function(_, cb)
    closeDocuments(false)
    cb('ok')
end)

interface.callback('hideDocument', function(_, cb)
    closeDocuments(false)
    cb('ok')
end)

interface.callback('getPlayerJob', function(_, cb)
    local job = QBCore.Functions.GetPlayerData().job

    if not job then return cb({}) end

    local grade = job.grade

    cb({
        name = job.name,
        label = job.label,
        grade = grade and grade.level or 0,
        grade_label = grade and grade.name or '',
        grade_name = grade and grade.name or '',
        grade_salary = job.payment,
        isBoss = job.isboss or false
    })
end)

interface.callback('getPlayerData', function(_, cb)
    local charinfo = QBCore.Functions.GetPlayerData().charinfo

    if not charinfo then return cb({}) end

    cb({
        firstname = charinfo.firstname,
        lastname = charinfo.lastname,
        dateofbirth = charinfo.birthdate
    })
end)

local serverCallbacks = {
    getPlayerCopies = 'sm_documents:getPlayerCopies',
    getIssuedDocuments = 'sm_documents:getPlayerDocuments',
    getMyTemplates = 'sm_documents:getDocumentTemplates',
    createDocument = 'sm_documents:createDocument',
    createTemplate = 'sm_documents:createTemplate',
    editTemplate = 'sm_documents:editTemplate',
    deleteTemplate = 'sm_documents:deleteTemplate',
    deleteDocument = 'sm_documents:deleteDocument'
}

for nuiName, eventName in pairs(serverCallbacks) do
    interface.callback(nuiName, function(data, cb)
        lib.callback(eventName, false, function(result)
            cb(result)
        end, data)
    end)
end

---@param confirmText string
---@return number targetId -1 kalau dibatalkan
local function playerSelector(confirmText)
    closeDocuments(true)
    selectingPlayer = true

    infoUI.show({
        id = INFO_ID,
        title = confirmText,
        icon = 'fa-solid fa-file-signature',
        description = ('%s - [kbd]E[/kbd]\n%s - [kbd]BACKSPACE[/kbd]'):format(confirmText, Locale.cancel)
    })

    local targetId = -1

    while selectingPlayer do
        local ped = cache.ped
        local coords = GetEntityCoords(ped)
        local playerId, _, playerCoords = getClosestPlayer(coords, 2.0, false)

        DisableControlAction(2, 200, true)

        if IsControlJustReleased(0, 202) then
            break
        end

        if playerId then
            markerTop.coords = vec3(playerCoords.x, playerCoords.y, playerCoords.z + 1.2)
            markerGround.coords = vec3(playerCoords.x, playerCoords.y, playerCoords.z - 0.95)
            markerTop:draw()
            markerGround:draw()

            if IsControlJustReleased(0, 38) then
                targetId = GetPlayerServerId(playerId)
                break
            end
        elseif IsControlJustReleased(0, 38) then
            lib.notify({ description = Locale.noPlayersAround, type = 'error' })
        end

        Wait(0)
    end

    selectingPlayer = false
    infoUI.remove(INFO_ID)

    return targetId
end

interface.callback('giveCopy', function(data, cb)
    cb('ok')

    CreateThread(function()
        local targetId = playerSelector(Locale.giveCopy)

        if targetId == -1 then
            holdDocument(false)
        else
            TriggerServerEvent('sm_documents:giveCopy', data, targetId)
        end
    end)
end)

interface.callback('giveOriginal', function(data, cb)
    cb('ok')

    CreateThread(function()
        local targetId = playerSelector(Locale.giveOriginal)

        if targetId == -1 then
            holdDocument(false)
        else
            TriggerServerEvent('sm_documents:giveOriginal', data, targetId)
        end
    end)
end)

interface.callback('showDocument', function(data, cb)
    cb('ok')

    CreateThread(function()
        local targetId = playerSelector(Locale.showDocument)

        holdDocument(false)

        if targetId ~= -1 then
            lib.playAnim(cache.ped, 'mp_common', 'givetake1_a', 2.0, 2.0, 1500, 51)
            TriggerServerEvent('sm_documents:receiveDocument', data, targetId)
        end
    end)
end)

RegisterNetEvent('sm_documents:copyGave', function(name)
    holdDocument(false)
    lib.playAnim(cache.ped, 'mp_common', 'givetake1_a', 2.0, 2.0, 1500, 51)
    lib.notify({ description = Locale.giveNotification .. name, type = 'success' })
end)

RegisterNetEvent('sm_documents:copyReceived', function(name)
    lib.notify({ description = Locale.receiveNotification .. name, type = 'success' })
    interface.send({ action = 'refreshDocuments' })
end)

RegisterNetEvent('sm_documents:originalGave', function(name)
    holdDocument(false)
    lib.playAnim(cache.ped, 'mp_common', 'givetake1_a', 2.0, 2.0, 1500, 51)
    lib.notify({ description = Locale.giveOriginalNotification .. name, type = 'success' })
    interface.send({ action = 'refreshDocuments' })
end)

RegisterNetEvent('sm_documents:originalReceived', function(name)
    lib.notify({ description = Locale.receiveOriginalNotification .. name, type = 'success' })
    interface.send({ action = 'refreshDocuments' })
end)

RegisterNetEvent('sm_documents:viewDocument', function(data)
    showDocumentFrom(data)
end)

RegisterNetEvent('sm_documents:useItem', function()
    openDocuments()
end)

if Config.Command then
    RegisterCommand(Config.Command, function()
        openDocuments()
    end, false)

    TriggerEvent('chat:addSuggestion', '/' .. Config.Command, Locale.registerMapDescription)

    if Config.RegisterKey then
        RegisterKeyMapping(Config.Command, Locale.registerMapDescription, 'keyboard', Config.RegisterKey)
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    detachPaper()
    infoUI.remove(INFO_ID)
end)
