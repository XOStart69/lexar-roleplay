local config = localmodule 'config'
local geo = localmodule 'modules.geo'
local interact = exports.rhd_interact
local hasFrame = interface.init(false)

local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity

local NPC = config.npc
local NPC_COORDS = NPC.coords
local DEBUG_JOB = config.debug and config.debug.enabled and config.debug.job

SmAnimalFarm = {
    config = config,
    inPen = false,
    penOwner = nil,
    riding = false,
    boarded = false,
}

local farm = SmAnimalFarm

local open = false
local mounted = false
local ready = false
local pending
local hud
local npcPed
local npcNearby = false
local blip

local ACTIONS = {
    buyPlot = 'sm_animalfarm:buyPlot',
    buyAnimal = 'sm_animalfarm:buyAnimal',
    buyStock = 'sm_animalfarm:buyStock',
    buyLasso = 'sm_animalfarm:buyLasso',
    bury = 'sm_animalfarm:bury',
    revive = 'sm_animalfarm:revive',
    rename = 'sm_animalfarm:rename',
    enterPen = 'sm_animalfarm:enterPen',
    exitPen = 'sm_animalfarm:exitPen',
    invitables = 'sm_animalfarm:invitables',
    invite = 'sm_animalfarm:invite',
    release = 'sm_animalfarm:release',
}

---@return table
local function catalog()
    local species = {}
    local order = config.speciesOrder

    for i = 1, #order do
        local key = order[i]
        local entry = config.species[key]

        species[i] = {
            id = key,
            label = entry.label,
            price = entry.price,
            revivePrice = entry.revivePrice,
            image = entry.image,
            description = entry.description,
            care = entry.care,
            growHours = entry.growHours,
            milk = entry.milk and true or false,
            job = entry.job,
            noCare = entry.noCare == true,
        }
    end

    local plots = {}

    for i = 1, #config.plots do
        plots[i] = { label = config.plots[i].label, price = config.plots[i].price }
    end

    local stock = {}

    for key, entry in pairs(config.stock) do
        stock[#stock + 1] = {
            id = key,
            label = entry.label,
            description = entry.description,
            price = entry.price,
            max = entry.max,
            image = entry.image,
        }
    end

    table.sort(stock, function(a, b) return a.id < b.id end)

    return {
        species = species,
        plots = plots,
        stock = stock,
        maxAnimals = config.maxAnimals,
        nameMaxLength = config.nameMaxLength,
        takeOutMinHealth = config.takeOutMinHealth,
        lasso = { price = config.lasso.price },
        trough = { capacity = config.trough.capacity, fillAmount = config.trough.fillAmount },
    }
end

local CATALOG = catalog()

---@return table
local function catalogForJob()
    local job = QBPlayerData and QBPlayerData.job and QBPlayerData.job.name
    local species = {}

    for i = 1, #CATALOG.species do
        local entry = CATALOG.species[i]

        local copy = {}

        for key, value in pairs(entry) do
            copy[key] = value
        end

        copy.available = geo.jobAllowed(entry.job, job)
        species[i] = copy
    end

    local copy = {}

    for key, value in pairs(CATALOG) do
        copy[key] = value
    end

    copy.species = species

    return copy
end

---@param action string
---@param data? any
local function send(action, data)
    if ready then
        interface.send({ action = action, data = data })
    end
end

local function unmountLater()
    SetTimeout(100, function()
        if open or hud or not mounted then return end

        mounted = false
        ready = false
        interface.hide()
    end)
end

local function close()
    if not open then return end

    open = false
    pending = nil
    send('close')
    interface.focus(false, false)
    unmountLater()
end

---@return boolean
function farm.isKid()
    return geo.isKidModel(GetEntityModel(cache.ped))
end

---@param data table|nil
function farm.setHud(data)
    if not hasFrame then return end

    hud = data

    if data then
        if ready then
            send('hud', data)
        elseif not mounted then
            mounted = true
            interface.show()
        end

        return
    end

    send('hud', false)
    unmountLater()
end

farm.closeUI = close

local function openUI()
    if not hasFrame or open then return end
    if farm.riding or farm.boarded then return end

    local result = lib.callback.await('sm_animalfarm:init', false)

    if not result or not result.ok then
        return lib.notify({ title = 'Peternakan', description = result and result.message or 'Data belum siap, coba lagi.', type = 'error' })
    end

    open = true
    pending = { catalog = catalogForJob(), farm = result.data }

    if ready then
        send('open', pending)
        pending = nil
        interface.focus(true, true)
    elseif not mounted then
        mounted = true
        interface.show()
    end
end

---@param name string
---@param ... any
---@return table
local function request(name, ...)
    local result = lib.callback.await(name, false, ...)

    if type(result) ~= 'table' then
        return { ok = false, message = 'Server did not respond, try again.' }
    end

    return result
end

---@param result table
local function afterAction(name, result)
    if not result.ok then return end

    if name == 'enterPen' then
        close()
    elseif name == 'release' and result.spawn then
        close()
        farm.spawnReleased(result.spawn)
    end
end

if hasFrame then
    interface.callback('ready', function(_, cb)
        ready = true
        cb({})

        if hud then
            send('hud', hud)
        end

        if open and pending then
            send('open', pending)
            pending = nil
            interface.focus(true, true)
        end
    end)

    interface.callback('close', function(_, cb)
        cb({})
        close()
    end)

    interface.callback('request', function(data, cb)
        local key = type(data) == 'table' and data.name
        local name = key and ACTIONS[key]

        if not name or not open then
            return cb({ ok = false, message = 'Invalid request.' })
        end

        local args = type(data.args) == 'table' and data.args or {}
        local result = request(name, args[1], args[2], args[3])

        cb({ ok = result.ok == true, message = result.message, data = result.data })
        afterAction(key, result)
    end)
end

RegisterNetEvent('sm_animalfarm:client:refresh', function(snapshot)
    if source == '' or not open then return end

    send('farm', snapshot)
end)

AddEventHandler('sm_animalfarm:client:forceClose', function()
    close()
end)

RegisterNetEvent('sm_animalfarm:client:invite', function(ownerSrc, ownerName)
    if source == '' then return end

    CreateThread(function()
        local answer = lib.alertDialog({
            header = 'Undangan Peternakan',
            content = ('%s mengundang kamu melihat kandang hewannya.'):format(ownerName),
            centered = true,
            cancel = true,
            labels = { confirm = 'Masuk', cancel = 'Tolak' },
        })

        if answer ~= 'confirm' then return end

        local result = request('sm_animalfarm:acceptInvite', ownerSrc)

        if not result.ok then
            lib.notify({ title = 'Peternakan', description = result.message, type = 'error' })
        end
    end)
end)

local function exitPen()
    local result = request('sm_animalfarm:exitPen')

    if not result.ok then
        lib.notify({ title = 'Peternakan', description = result.message, type = 'error' })
    end
end

farm.exitPen = exitPen

local function removeNpc()
    local ped = npcPed

    npcPed = nil

    if ped and DoesEntityExist(ped) then
        interact:removeLocalEntity(ped)
        DeleteEntity(ped)
    end
end

local function spawnNpc()
    if npcPed or not lib.requestModel(NPC.model, 10000) then return end
    if not npcNearby or npcPed then return end

    local ped = CreatePed(0, NPC.model, NPC_COORDS.x, NPC_COORDS.y, NPC_COORDS.z - 1.0, NPC_COORDS.w, false, true)

    SetModelAsNoLongerNeeded(NPC.model)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    npcPed = ped

    interact:addLocalEntity(ped, {
        {
            name = 'sm_animalfarm:open',
            label = 'Peternakan',
            icon = 'fa-solid fa-cow',
            distance = NPC.interactDistance,
            canInteract = function()
                if DEBUG_JOB then
                    local job = QBPlayerData and QBPlayerData.job

                    if not geo.jobAllowed(DEBUG_JOB, job and job.name) then return false end
                end

                return not farm.riding and not farm.boarded
            end,
            onSelect = openUI,
        },
        {
            name = 'sm_animalfarm:exit',
            label = 'Keluar Kandang',
            icon = 'fa-solid fa-door-open',
            distance = NPC.interactDistance,
            canInteract = function()
                return farm.inPen
            end,
            onSelect = exitPen,
        },
        {
            name = 'sm_animalfarm:store',
            label = 'Kembalikan Hewan ke Kandang',
            icon = 'fa-solid fa-house',
            distance = NPC.interactDistance,
            canInteract = function()
                return farm.hasReleased and farm.hasReleased() and not farm.riding
            end,
            onSelect = function()
                farm.storeReleased()
            end,
        },
    })
end

lib.points.new({
    coords = NPC_COORDS.xyz,
    distance = NPC.renderDistance,
    onEnter = function()
        npcNearby = true
        spawnNpc()
    end,
    onExit = function()
        npcNearby = false
        removeNpc()
    end,
})

lib.points.new({
    coords = NPC_COORDS.xyz,
    distance = config.penLeaveDistance,
    onExit = function()
        if farm.inPen then
            exitPen()
        end
    end,
})

if config.blip.enabled then
    blip = AddBlipForCoord(NPC_COORDS.x, NPC_COORDS.y, NPC_COORDS.z)
    SetBlipSprite(blip, config.blip.sprite)
    SetBlipColour(blip, config.blip.color)
    SetBlipScale(blip, config.blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(config.blip.label)
    EndTextCommandSetBlipName(blip)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    removeNpc()

    if blip then
        RemoveBlip(blip)
    end

    if open then
        SetNuiFocus(false, false)
    end
end)
