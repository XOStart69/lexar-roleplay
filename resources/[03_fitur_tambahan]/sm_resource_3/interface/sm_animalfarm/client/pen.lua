local config = localmodule 'config'
local geo = localmodule 'modules.geo'
local interact = exports.rhd_interact

local Wait = Wait
local GetGameTimer = GetGameTimer
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local CreatePed = CreatePed
local CreateObject = CreateObject
local GetEntityCoords = GetEntityCoords
local SetEntityMatrix = SetEntityMatrix
local SetEntityHealth = SetEntityHealth
local FreezeEntityPosition = FreezeEntityPosition
local SetEntityInvincible = SetEntityInvincible
local SetBlockingOfNonTemporaryEvents = SetBlockingOfNonTemporaryEvents
local SetPedFleeAttributes = SetPedFleeAttributes
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local PlaceObjectOnGroundProperly = PlaceObjectOnGroundProperly
local RequestCollisionAtCoord = RequestCollisionAtCoord
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
local IsModelInCdimage = IsModelInCdimage
local rad, sin, cos, ceil = math.rad, math.sin, math.cos, math.ceil
local pairs = pairs

local farm = SmAnimalFarm
local SPECIES = config.species
local PLOTS = config.plots
local TROUGH = config.trough
local CAPACITY = TROUGH.capacity
local PER_PROP = TROUGH.fillAmount
local MILK_ANIM = config.milkAnim
local GRAZE = config.graze
local TaskPlayAnim = TaskPlayAnim
local StopAnimTask = StopAnimTask
local DoesAnimDictExist = DoesAnimDictExist
local random = math.random
local SLAUGHTER = config.slaughter

---@class PenRecord
---@field id integer
---@field data table
---@field ped integer|nil
---@field ground number
---@field lift number
---@field matrix number[]|nil
---@field props table<string, integer[]>
---@field levels table<string, integer>
---@field gen integer
---@field grazeAt integer|nil

---@type table<integer, PenRecord>
local records = {}
local list = {}
local generation = 0
local warned = {}
local loopRunning = false
local grazeRunning = false
---@type table<string, table|false>
local grazeAnims = {}

---@param model string
---@return boolean
local function validModel(model)
    if IsModelInCdimage(joaat(model)) then return true end

    if not warned[model] then
        warned[model] = true
        lib.print.warn(('sm_animalfarm: model %s not found'):format(model))
    end

    return false
end

---@param x number
---@param y number
---@param z number
---@return number
local function groundAt(x, y, z)
    RequestCollisionAtCoord(x, y, z)

    for _ = 1, 20 do
        local found, ground = GetGroundZFor_3dCoord(x, y, z + 2.0, false)

        if found then return ground end

        Wait(50)
    end

    return z - 1.0
end

---@param record PenRecord
local function rebuildMatrix(record)
    local data = record.data

    if not record.ped or data.dead then
        record.matrix = nil
        return
    end

    local coords = PLOTS[data.plot].coords
    local s = geo.scale(data.growth, data.weight)
    local h = rad(coords.w)
    local sh, ch = sin(h), cos(h)

    record.matrix = {
        -sh * s, ch * s, 0.0,
        ch * s, sh * s, 0.0,
        0.0, 0.0, s,
        coords.x, coords.y, record.ground + record.lift * s,
    }
end

---@param record PenRecord
---@param kind 'food'|'water'
local function clearProps(record, kind)
    local props = record.props[kind]

    for i = 1, #props do
        if DoesEntityExist(props[i]) then
            DeleteEntity(props[i])
        end

        props[i] = nil
    end
end

---@param record PenRecord
---@param kind 'food'|'water'
local function syncProps(record, kind)
    local data = record.data
    local level = data.dead and 0 or ceil((data[kind] or 0) / PER_PROP)

    if level > 3 then level = 3 end
    if record.levels[kind] == level then return end

    record.levels[kind] = level
    clearProps(record, kind)

    local trough = TROUGH[kind]

    if level == 0 or not validModel(trough.model) then return end
    if not lib.requestModel(trough.model, 5000) then return end

    local coords = PLOTS[data.plot].coords
    local props = record.props[kind]

    for i = 1, level do
        local x, y = geo.offset(coords, trough.offset.x + (i - 2) * trough.spacing, trough.offset.y)
        local object = CreateObject(trough.model, x, y, record.ground, false, false, false)

        PlaceObjectOnGroundProperly(object)
        FreezeEntityPosition(object, true)
        props[i] = object
    end

    SetModelAsNoLongerNeeded(trough.model)
end

---@param id integer
---@param speciesKey? string
function farm.milk(id, speciesKey)
    local data = records[id] and records[id].data
    local species = SPECIES[speciesKey or (data and data.species) or '']
    local milk = species and species.milk

    if not milk then return end

    local done = lib.progressBar({
        duration = milk.duration,
        label = 'Memerah susu...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = MILK_ANIM.dict, clip = MILK_ANIM.clip },
    })

    if not done then return end

    local result = lib.callback.await('sm_animalfarm:milk', false, id)

    if type(result) ~= 'table' then return end

    lib.notify({ title = 'Peternakan', description = result.message, type = result.ok and 'success' or 'error' })
end

---@param data table
---@return string
local function conditionText(data)
    local stageLabel = data.stage == 'adult' and 'Dewasa' or data.stage == 'young' and 'Remaja' or 'Anak'

    if data.dead then
        return ('%s sudah mati. Hidupkan kembali lewat menu peternak.'):format(data.name)
    end

    return ('%s (%s)\nTumbuh: %.0f%%  Kesehatan: %.0f%%\nJerami: %d/%d  Air: %d/%d'):format(
        data.name,
        stageLabel,
        data.growth,
        data.weight,
        data.food,
        CAPACITY,
        data.water,
        CAPACITY
    )
end

---@param id integer
local function release(id)
    local result = lib.callback.await('sm_animalfarm:release', false, id)

    if type(result) ~= 'table' then return end

    lib.notify({ title = 'Peternakan', description = result.message, type = result.ok and 'success' or 'error' })

    if result.ok and result.spawn then
        farm.spawnReleased(result.spawn)
    end
end

---@param id integer
local function slaughter(id)
    local record = records[id]

    if not record then return end

    local answer = lib.alertDialog({
        header = 'Potong Hewan',
        content = ('Potong %s? Hewan ini hilang permanen dan lahannya kosong lagi.'):format(record.data.name),
        centered = true,
        cancel = true,
        labels = { confirm = 'Potong', cancel = 'Batal' },
    })

    if answer ~= 'confirm' then return end

    local done = lib.progressBar({
        duration = SLAUGHTER.duration,
        label = 'Memotong hewan...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = SLAUGHTER.anim.dict, clip = SLAUGHTER.anim.clip },
    })

    if not done then return end

    local result = lib.callback.await('sm_animalfarm:slaughter', false, id)

    if type(result) ~= 'table' then return end

    lib.notify({ title = 'Peternakan', description = result.message, type = result.ok and 'success' or 'error' })
end

---@param record PenRecord
local function addPedOptions(record)
    local id = record.id
    local isOwner = farm.penOwner == cache.serverId

    local options = {
        {
            name = 'sm_animalfarm:condition',
            label = 'Cek Kondisi',
            icon = 'fa-solid fa-heart-pulse',
            distance = 2.5,
            onSelect = function()
                local current = records[id]

                if not current then return end

                lib.notify({ title = 'Peternakan', description = conditionText(current.data), type = 'inform', duration = 7000 })
            end,
        },
    }

    if isOwner then
        options[#options + 1] = {
            name = 'sm_animalfarm:milk',
            label = 'Perah Susu',
            icon = 'fa-solid fa-bottle-droplet',
            distance = 2.5,
            canInteract = function()
                local current = records[id]
                local data = current and current.data

                return data and not data.dead and data.stage == 'adult' and SPECIES[data.species].milk and true or false
            end,
            onSelect = function()
                farm.milk(id)
            end,
        }

        options[#options + 1] = {
            name = 'sm_animalfarm:release',
            label = 'Take Out',
            icon = 'fa-solid fa-person-walking',
            distance = 2.5,
            canInteract = function()
                local current = records[id]
                local data = current and current.data

                if not data or data.dead then return false end
                if data.stage ~= 'adult' and not farm.isKid() then return false end

                return data.weight >= config.takeOutMinHealth
            end,
            onSelect = function()
                release(id)
            end,
        }

        options[#options + 1] = {
            name = 'sm_animalfarm:slaughter',
            label = 'Potong',
            icon = 'fa-solid fa-drumstick-bite',
            distance = 2.5,
            canInteract = function()
                local current = records[id]
                local data = current and current.data

                return data and not data.dead and data.stage == 'adult' and SPECIES[data.species].meat and true or false
            end,
            onSelect = function()
                slaughter(id)
            end,
        }
    end

    interact:addLocalEntity(record.ped, options)
end

---@param record PenRecord
local function destroyRecord(record)
    record.gen = -1
    clearProps(record, 'food')
    clearProps(record, 'water')

    local ped = record.ped

    record.ped = nil
    record.matrix = nil

    if ped and DoesEntityExist(ped) then
        interact:removeLocalEntity(ped)
        DeleteEntity(ped)
    end
end

local function rebuildList()
    local count = 0

    for _, record in pairs(records) do
        count += 1
        list[count] = record
    end

    for i = count + 1, #list do
        list[i] = nil
    end
end

---@param speciesKey string
---@return table|nil
local function grazeAnim(speciesKey)
    local cached = grazeAnims[speciesKey]

    if cached ~= nil then return cached or nil end

    local wanted = SPECIES[speciesKey].graze
    local anim = wanted and DoesAnimDictExist(wanted.dict) and wanted or GRAZE.fallback

    if not pcall(lib.requestAnimDict, anim.dict, 3000) then
        grazeAnims[speciesKey] = false
        return nil
    end

    grazeAnims[speciesKey] = anim

    return anim
end

local function startGraze()
    if grazeRunning then return end

    grazeRunning = true

    CreateThread(function()
        while farm.inPen do
            local now = GetGameTimer()

            for i = 1, #list do
                local record = list[i]
                local ped = record.ped
                local data = record.data

                if ped and not data.dead and now >= (record.grazeAt or 0) then
                    local anim = ((data.food or 0) > 0 or SPECIES[data.species].noCare) and grazeAnim(data.species)

                    if anim then
                        local duration = random(GRAZE.duration[1], GRAZE.duration[2])

                        TaskPlayAnim(ped, anim.dict, anim.clip, 2.0, -2.0, duration, 1, 0.0, false, false, false)
                        record.grazeAt = now + duration + random(GRAZE.rest[1], GRAZE.rest[2])
                    else
                        record.grazeAt = now + 5000
                    end
                end
            end

            Wait(1000)
        end

        grazeRunning = false
    end)
end

local function startLoop()
    if loopRunning then return end

    loopRunning = true

    CreateThread(function()
        while farm.inPen do
            for i = 1, #list do
                local record = list[i]
                local matrix = record.matrix
                local ped = record.ped

                if matrix and ped then
                    SetEntityMatrix(
                        ped,
                        matrix[1], matrix[2], matrix[3],
                        matrix[4], matrix[5], matrix[6],
                        matrix[7], matrix[8], matrix[9],
                        matrix[10], matrix[11], matrix[12]
                    )
                end
            end

            Wait(0)
        end

        loopRunning = false
    end)
end

---@param record PenRecord
local function spawnRecord(record)
    local gen = record.gen
    local data = record.data
    local species = SPECIES[data.species]
    local coords = PLOTS[data.plot].coords

    CreateThread(function()
        local ground = groundAt(coords.x, coords.y, coords.z)

        if record.gen ~= gen then return end

        record.ground = ground

        syncProps(record, 'food')
        syncProps(record, 'water')

        if not validModel(species.model) or not lib.requestModel(species.model, 10000) then return end
        if record.gen ~= gen then return end

        local ped = CreatePed(28, species.model, coords.x, coords.y, ground + 0.5, coords.w, false, true)

        SetModelAsNoLongerNeeded(species.model)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedFleeAttributes(ped, 0, false)
        SetPedCanRagdoll(ped, false)

        local started = GetGameTimer()

        while GetGameTimer() - started < 600 and record.gen == gen do
            Wait(50)
        end

        if record.gen ~= gen then
            DeleteEntity(ped)
            return
        end

        if IsPedRagdoll(ped) or IsPedFalling(ped) then
            ClearPedTasksImmediately(ped)
            SetEntityCoords(ped, coords.x, coords.y, ground + 0.5, false, false, false, false)
            Wait(300)
        end

        SetEntityHeading(ped, coords.w)

        record.lift = GetEntityCoords(ped).z - ground

        if record.lift < 0.0 or record.lift > 3.0 then
            record.lift = 0.5
        end

        FreezeEntityPosition(ped, true)
        record.ped = ped
        record.grazeAt = GetGameTimer() + random(1000, 6000)

        if data.dead then
            SetEntityInvincible(ped, false)
            FreezeEntityPosition(ped, false)
            SetEntityHealth(ped, 0)
        end

        addPedOptions(record)
        rebuildMatrix(record)
    end)
end

---@param kind 'food'|'water'
---@param spots table[]
---@return integer
function farm.troughSpots(kind, spots)
    local count = 0

    if farm.inPen and farm.penOwner == cache.serverId then
        local trough = TROUGH[kind]
        local limit = CAPACITY - TROUGH.fillAmount * 0.5

        for i = 1, #list do
            local record = list[i]
            local data = record.data

            if record.ped and not data.dead and not SPECIES[data.species].noCare and (data[kind] or 0) <= limit then
                local level = record.levels[kind] or 0
                local slot = level < 3 and level + 1 or 3
                local coords = PLOTS[data.plot].coords
                local x, y = geo.offset(coords, trough.offset.x + (slot - 2) * trough.spacing, trough.offset.y)

                count += 1

                local spot = spots[count] or {}

                spot.id = record.id
                spot.x = x
                spot.y = y
                spot.z = record.ground
                spot.h = coords.w
                spots[count] = spot
            end
        end
    end

    for i = count + 1, #spots do
        spots[i] = nil
    end

    return count
end

local function clearPen()
    for id, record in pairs(records) do
        destroyRecord(record)
        records[id] = nil
    end

    rebuildList()
end

---@param animals table[]
local function renderPen(animals)
    local seen = {}

    for i = 1, #animals do
        local data = animals[i]

        if not data.released and SPECIES[data.species] and PLOTS[data.plot] then
            seen[data.id] = true

            local record = records[data.id]

            if record and (record.data.species ~= data.species or record.data.dead ~= data.dead or record.data.plot ~= data.plot) then
                destroyRecord(record)
                record = nil
            end

            if record then
                record.data = data
                rebuildMatrix(record)

                syncProps(record, 'food')
                syncProps(record, 'water')
            else
                generation += 1
                record = {
                    id = data.id,
                    data = data,
                    ground = PLOTS[data.plot].coords.z - 1.0,
                    lift = 0.5,
                    props = { food = {}, water = {} },
                    levels = {},
                    gen = generation,
                }
                records[data.id] = record
                spawnRecord(record)
            end
        end
    end

    for id, record in pairs(records) do
        if not seen[id] then
            destroyRecord(record)
            records[id] = nil
        end
    end

    rebuildList()
end

RegisterNetEvent('sm_animalfarm:client:pen', function(payload)
    if source == '' or type(payload) ~= 'table' then return end

    local wasOwner = farm.penOwner

    farm.inPen = true
    farm.penOwner = payload.owner
    farm.penStock = type(payload.stock) == 'table' and payload.stock or nil

    if wasOwner ~= payload.owner then
        clearPen()
    end

    renderPen(type(payload.animals) == 'table' and payload.animals or {})
    startLoop()
    startGraze()
end)

RegisterNetEvent('sm_animalfarm:client:penLeft', function(kicked)
    if source == '' then return end

    farm.inPen = false
    farm.penOwner = nil
    farm.penStock = nil
    clearPen()

    if kicked then
        lib.notify({ title = 'Peternakan', description = 'Pemilik kandang sudah keluar.', type = 'inform' })
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    farm.inPen = false
    clearPen()
end)
