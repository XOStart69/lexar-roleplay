local config = localmodule 'config.shared'
local Growth = localmodule 'modules.growth'
local Placer = localmodule 'modules.placer'
local Render = localmodule 'modules.render'
local Scene = localmodule 'modules.scene'

local TICK_MS = 250
local ANIMATE_EVERY = 4

---@type table<integer, DrugClientObject>
local objects = {}
---@type table<DrugClientObject, true>
local pending = {}
local busy = false

---@param description string
---@param kind? NotificationType
local function notify(description, kind)
    lib.notify({ description = description, type = kind or 'info' })
end

---@param obj DrugClientObject
local function schedule(obj)
    pending[obj] = true
end

---@param fn fun()
---@return fun()
local function async(fn)
    return function()
        CreateThread(fn)
    end
end

---@param obj DrugClientObject
---@return boolean
local function isReady(obj)
    return obj.state.progress ~= nil and Render.progress(obj) >= 1
end

---@param id integer
local function remove(id)
    local obj = objects[id]

    if not obj then return end

    objects[id] = nil
    obj.point:remove()
    obj.removed = true
    obj.visible = false
    schedule(obj)
end

---@param obj DrugClientObject
---@param amount integer
---@param cleanup? fun()
---@return boolean
local function cook(obj, amount, cleanup)
    local cooking = config.cooking

    obj.locked = false
    Render.sync(obj)

    if cleanup then
        cleanup()
    end

    return lib.progressBar({
        duration = cooking.batchMs * amount,
        label = ('%s x%d'):format(cooking.label, amount),
        canCancel = true,
        disable = { move = true, sprint = true, car = true, combat = true },
    }) == true
end

---@param obj DrugClientObject
---@param action string
---@param option? any
---@param amount? integer
local function runAction(obj, action, option, amount)
    if busy then return end

    busy = true

    local ok, message, granted, minimum = lib.callback.await('sm_drugsystem:start', false, obj.id, action, option, amount)

    if not ok then
        busy = false
        return notify(message or 'Tidak bisa sekarang', 'error')
    end

    if not obj.parts then
        TriggerServerEvent('sm_drugsystem:server:cancel', obj.id)
        busy = false
        return
    end

    obj.locked = true

    local completed, cleanup, failed = true, nil, false
    local data

    if Scene.supported(action, obj) then
        completed, cleanup, failed = Scene.play(action, obj, option, granted, action == 'cook' and config.cooking.sceneMs or minimum)
    end

    if completed and action == 'cook' then
        completed = cook(obj, granted, cleanup)
    end

    if completed then
        ok, message, data = lib.callback.await('sm_drugsystem:finish', false, obj.id)
    else
        TriggerServerEvent('sm_drugsystem:server:cancel', obj.id)
        ok, message = false, failed and 'Terjadi kesalahan, cek console F8' or 'Dibatalkan'
    end

    if ok and data then
        obj.state = data.state
        obj.receivedAt = GetGameTimer()
    elseif ok then
        remove(obj.id)
    end

    obj.locked = false
    Render.sync(obj)

    if cleanup then
        cleanup()
    end

    busy = false

    if message then
        notify(message, ok and 'success' or 'error')
    end
end

---@param obj DrugClientObject
---@param callback string
local function request(obj, callback)
    if busy then return end

    busy = true

    local ok, message = lib.callback.await(callback, false, obj.id)

    busy = false

    if message then
        notify(message, ok and 'success' or 'error')
    end
end

---@param name string
---@return string
local function itemLabel(name)
    return ox_inventory:Items(name)?.label or name
end

---@alias DrugRecipe { input: table<string, integer>, output: string, amount: { min: integer, max: integer } }

---@param recipe DrugRecipe
---@param limit integer
---@return integer
local function craftable(recipe, limit)
    local batches = limit

    for item, count in pairs(recipe.input) do
        batches = math.min(batches, math.floor(ox_inventory:GetItemCount(item) / count))
    end

    return batches
end

---@param recipe DrugRecipe
---@return string
local function describeRecipe(recipe)
    local inputs = {}

    for item, count in pairs(recipe.input) do
        inputs[#inputs + 1] = ('%dx %s'):format(count, itemLabel(item))
    end

    return ('%s → %d-%dx %s'):format(table.concat(inputs, ' + '), recipe.amount.min, recipe.amount.max, itemLabel(recipe.output))
end

---@param obj DrugClientObject
local function inspect(obj)
    local state = obj.state
    local equipment = config.equipment[obj.kind]
    local station = config.stations[equipment.group]

    if equipment.group == 'table' then
        local cooking = config.cooking

        return notify(('Per kelipatan (%d detik): %s. Bisa dimasak: x%d'):format(cooking.batchMs // 1000, describeRecipe(cooking), craftable(cooking, cooking.maxBatches)))
    end

    if station then
        local left = Render.timeLeft(obj)

        if not left then
            return notify(('%s siap dipakai'):format(equipment.label))
        end

        if left > 0 then
            return notify(('%s sedang diproses, %d detik lagi'):format(itemLabel(station.output), math.ceil(left)))
        end

        return notify(('%s siap diambil'):format(itemLabel(station.output)), 'success')
    end

    if not state.soil then
        return notify('Pot masih kosong, isi tanah dulu')
    end

    local plant = config.plants[state.seed]

    if not plant then
        return notify(state.watered and 'Tanah sudah disiram, tinggal tanam benih' or 'Tanah siap, tanam benih')
    end

    if not state.watered then
        return notify(('%s belum disiram'):format(plant.label), 'warning')
    end

    local progress = Render.progress(obj)

    if progress >= 1 then
        return notify(('%s siap dipanen'):format(plant.label), 'success')
    end

    local left = math.ceil((1 - progress) / Growth.rate(state.lamp))
    local lamp = state.lamp and ', UV Lamp aktif' or ''

    notify(('%s tumbuh %d%%, siap dalam %d detik%s'):format(plant.label, math.floor(progress * 100), left, lamp))
end

---@param obj DrugClientObject
---@param index integer
---@param recipe DrugRecipe
---@param batches integer
local function startPacking(obj, index, recipe, batches)
    local amount = 1

    if batches > 1 then
        local input = lib.inputDialog(itemLabel(recipe.output), {
            {
                type = 'slider',
                label = 'Kelipatan',
                min = 1,
                max = batches,
                step = 1,
                default = 1,
            },
        })

        if not input then return end

        amount = math.floor(input[1])
    end

    runAction(obj, 'pack', index, amount)
end

---@param obj DrugClientObject
local function openPacking(obj)
    local equipment = config.equipment[obj.kind]
    local options = {}

    for index, recipe in ipairs(config.packing.recipes[equipment.group]) do
        local batches = craftable(recipe, config.packing.maxBatches)

        options[index] = {
            title = itemLabel(recipe.output),
            description = describeRecipe(recipe),
            icon = 'fa-solid fa-box',
            disabled = batches == 0,
            metadata = { ('Bisa diproses: x%d'):format(batches) },
            onSelect = async(function()
                startPacking(obj, index, recipe, batches)
            end),
        }
    end

    lib.registerContext({
        id = 'sm_drugsystem:packing',
        title = equipment.label,
        options = options,
    })
    lib.showContext('sm_drugsystem:packing')
end

---@alias DrugBatchRecipe { label: string, icon: string, start: string, maxBatches: integer, input: table<string, integer>, output: string, amount: { min: integer, max: integer } }

---@param obj DrugClientObject
---@param action string
---@param recipe DrugBatchRecipe
---@param seconds integer
local function startBatch(obj, action, recipe, seconds)
    local input = lib.inputDialog(recipe.label, {
        {
            type = 'slider',
            label = ('Kelipatan (%d detik per kelipatan)'):format(seconds),
            description = ('Per kelipatan: %s'):format(describeRecipe(recipe)),
            min = 1,
            max = recipe.maxBatches,
            step = 1,
            default = 1,
        },
    })

    if not input then return end

    runAction(obj, action, nil, math.floor(input[1]))
end

---@param obj DrugClientObject
---@param action string
---@param recipe DrugBatchRecipe
---@param seconds integer
local function openBatch(obj, action, recipe, seconds)
    local options = {}

    for item, count in pairs(recipe.input) do
        local owned = ox_inventory:GetItemCount(item)
        local enough = owned >= count

        options[#options + 1] = {
            title = itemLabel(item),
            description = ('Butuh %dx per kelipatan, kamu punya %d'):format(count, owned),
            icon = enough and 'fa-solid fa-check' or 'fa-solid fa-xmark',
            iconColor = enough and '#40c057' or '#fa5252',
            readOnly = true,
        }
    end

    options[#options + 1] = {
        title = recipe.start,
        description = describeRecipe(recipe),
        icon = recipe.icon,
        metadata = {
            ('Bisa diproses: x%d'):format(craftable(recipe, recipe.maxBatches)),
            ('Durasi: %d detik per kelipatan'):format(seconds),
        },
        onSelect = async(function()
            startBatch(obj, action, recipe, seconds)
        end),
    }

    lib.registerContext({
        id = 'sm_drugsystem:batch',
        title = recipe.label,
        options = options,
    })
    lib.showContext('sm_drugsystem:batch')
end

---@param obj DrugClientObject
---@return table[]
local function optionsFor(obj)
    local equipment = config.equipment[obj.kind]
    local station = config.stations[equipment.group]
    local distance = config.targetDistance
    local options = {}

    if equipment.group == 'pot' then
        options[#options + 1] = {
            name = 'sm_drugsystem:soil',
            label = 'Isi Tanah',
            icon = 'fa-solid fa-trowel',
            distance = distance,
            items = config.grow.soilItem,
            canInteract = function()
                return not obj.state.soil
            end,
            onSelect = async(function()
                runAction(obj, 'soil')
            end),
        }

        for name, plant in pairs(config.plants) do
            options[#options + 1] = {
                name = ('sm_drugsystem:seed_%s'):format(name),
                label = ('Tanam Benih %s'):format(plant.label),
                icon = 'fa-solid fa-seedling',
                distance = distance,
                items = plant.seed,
                canInteract = function()
                    return obj.state.soil and not obj.state.seed
                end,
                onSelect = async(function()
                    runAction(obj, 'seed', name)
                end),
            }
        end

        options[#options + 1] = {
            name = 'sm_drugsystem:water',
            label = 'Siram',
            icon = 'fa-solid fa-droplet',
            distance = distance,
            items = config.grow.waterItem,
            canInteract = function()
                return obj.state.soil and not isReady(obj)
            end,
            onSelect = async(function()
                runAction(obj, 'water')
            end),
        }

        options[#options + 1] = {
            name = 'sm_drugsystem:harvest',
            label = 'Panen',
            icon = 'fa-solid fa-scissors',
            distance = distance,
            items = config.grow.harvestTool,
            canInteract = function()
                return isReady(obj)
            end,
            onSelect = async(function()
                runAction(obj, 'harvest')
            end),
        }
    elseif equipment.group == 'table' then
        options[#options + 1] = {
            name = 'sm_drugsystem:cook',
            label = config.cooking.label,
            icon = config.cooking.icon,
            distance = distance,
            onSelect = function()
                openBatch(obj, 'cook', config.cooking, config.cooking.batchMs // 1000)
            end,
        }
    elseif station then
        options[#options + 1] = {
            name = 'sm_drugsystem:process',
            label = station.label,
            icon = station.icon,
            distance = distance,
            items = not station.maxBatches and station.input or nil,
            canInteract = function()
                return obj.state.remaining == nil
            end,
            onSelect = station.maxBatches and function()
                openBatch(obj, 'process', station, station.seconds)
            end or async(function()
                runAction(obj, 'process')
            end),
        }

        options[#options + 1] = {
            name = 'sm_drugsystem:collect',
            label = 'Ambil Hasil',
            icon = 'fa-solid fa-hand-holding',
            distance = distance,
            canInteract = function()
                return Render.timeLeft(obj) == 0
            end,
            onSelect = async(function()
                runAction(obj, 'collect')
            end),
        }
    elseif config.packing.recipes[equipment.group] then
        options[#options + 1] = {
            name = 'sm_drugsystem:pack',
            label = 'Packing',
            icon = 'fa-solid fa-box',
            distance = distance,
            onSelect = function()
                openPacking(obj)
            end,
        }
    end

    if equipment.group == 'pot' or equipment.group == 'table' or station then
        options[#options + 1] = {
            name = 'sm_drugsystem:inspect',
            label = 'Periksa',
            icon = 'fa-solid fa-magnifying-glass',
            distance = distance,
            onSelect = function()
                inspect(obj)
            end,
        }
    end

    options[#options + 1] = {
        name = 'sm_drugsystem:remove',
        label = ('Ambil %s'):format(equipment.label),
        icon = 'fa-solid fa-hand',
        distance = distance,
        onSelect = async(function()
            request(obj, 'sm_drugsystem:remove')
        end),
    }

    return options
end

---@param obj DrugClientObject
local function add(obj)
    obj.receivedAt = GetGameTimer()
    obj.options = optionsFor(obj)
    obj.optionNames = {}

    for i = 1, #obj.options do
        obj.optionNames[i] = obj.options[i].name
    end

    obj.point = lib.points.new({
        coords = obj.coords,
        distance = config.renderDistance,
        onEnter = function()
            obj.visible = true
            schedule(obj)
        end,
        onExit = function()
            obj.visible = false
            schedule(obj)
        end,
    })

    objects[obj.id] = obj
end

RegisterNetEvent('sm_drugsystem:client:snapshot', function(list)
    for id in pairs(objects) do
        remove(id)
    end

    for i = 1, #list do
        add(list[i])
    end
end)

RegisterNetEvent('sm_drugsystem:client:upsert', function(data)
    local obj = objects[data.id]

    if not obj then
        return add(data)
    end

    obj.state = data.state
    obj.receivedAt = GetGameTimer()
    schedule(obj)
end)

RegisterNetEvent('sm_drugsystem:client:remove', remove)

RegisterNetEvent('sm_drugsystem:client:place', function(kind, slot)
    local equipment = config.equipment[kind]

    if busy or not equipment then return end

    if cache.vehicle then
        return notify('Turun dari kendaraan dulu', 'error')
    end

    busy = true

    local coords, heading = Placer.start(equipment.model)

    if coords then
        local ok, message = lib.callback.await('sm_drugsystem:place', false, kind, coords, heading, slot)

        if not ok then
            notify(message or 'Gagal memasang', 'error')
        end
    end

    busy = false
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    Scene.abort()

    for _, obj in pairs(objects) do
        Render.clear(obj)
    end
end)

CreateThread(function()
    local tick = 0

    while true do
        local batch = pending

        pending = {}

        for obj in pairs(batch) do
            Render.sync(obj)
        end

        tick += 1

        if tick >= ANIMATE_EVERY then
            local animated = {}

            tick = 0

            for _, obj in pairs(objects) do
                if Render.animated(obj) then
                    animated[#animated + 1] = obj
                end
            end

            for i = 1, #animated do
                Render.sync(animated[i])
            end
        end

        Wait(TICK_MS)
    end
end)

TriggerServerEvent('sm_drugsystem:server:requestSnapshot')
