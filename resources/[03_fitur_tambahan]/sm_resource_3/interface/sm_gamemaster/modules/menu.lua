local config = localmodule 'config'
local state = localmodule 'modules.state'
local selection = localmodule 'modules.selection'
local orders = localmodule 'modules.orders'
local control = localmodule 'modules.control'
local camera = localmodule 'modules.camera'
local elements = localmodule 'modules.elements'
local nui = localmodule 'modules.nui'

local pairs = pairs
local tsort = table.sort
local CreateThread = CreateThread
local DoesEntityExist = DoesEntityExist
local NetworkHasControlOfEntity = NetworkHasControlOfEntity
local IsPedHuman = IsPedHuman
local IsPedAPlayer = IsPedAPlayer
local IsPedDeadOrDying = IsPedDeadOrDying
local IsPedInAnyVehicle = IsPedInAnyVehicle
local IsPedInVehicle = IsPedInVehicle
local GetEntityCoords = GetEntityCoords
local DoesScenarioExistInArea = DoesScenarioExistInArea

local menu = {}

---@type table<string, { fn: fun(data: any), data: any }>
local handlers = {}
local seq = 0
---@type table<string, { label: string, icon: string, run: fun(peds: integer[], entities: integer[]) }>
local radialActions = {}

---@type { impersonate: fun(ped: integer), delete: fun(), modify: fun(entity: integer) }
local hooks = {
    impersonate = function() end,
    delete = function() end,
    modify = function() end,
}

---@param label string
---@param icon string
---@param fn fun(data: any)
---@param data any
---@param danger? boolean
---@return table
local function item(label, icon, fn, data, danger)
    seq += 1

    local id = 'm' .. seq

    handlers[id] = { fn = fn, data = data }

    return { id = id, label = label, icon = icon, danger = danger or nil }
end

---@param label string
---@param icon string
---@param children table[]
---@return table?
local function group(label, icon, children)
    if #children == 0 then return nil end

    seq += 1

    return { id = 'm' .. seq, label = label, icon = icon, children = children }
end

---@param list table[]
---@param entry table?
local function push(list, entry)
    if entry then
        list[#list + 1] = entry
    end
end

---@param peds integer[]
---@param fn fun(ped: integer)
local function eachPed(peds, fn)
    control.ensure(peds)

    local failed = 0

    for i = 1, #peds do
        local ped = peds[i]

        if DoesEntityExist(ped) then
            if NetworkHasControlOfEntity(ped) then
                fn(ped)
            else
                failed += 1
            end
        end
    end

    if failed > 0 then
        nui.log('warn', ('%d NPC gagal dikontrol (dipegang client lain), coba lagi'):format(failed))
    end
end

---@param peds integer[]
---@param predicate fun(ped: integer): boolean
---@return boolean
local function any(peds, predicate)
    for i = 1, #peds do
        if DoesEntityExist(peds[i]) and predicate(peds[i]) then return true end
    end

    return false
end

---@param peds integer[]
---@param predicate fun(ped: integer): boolean
---@return boolean
local function all(peds, predicate)
    if #peds == 0 then return false end

    for i = 1, #peds do
        if not DoesEntityExist(peds[i]) or not predicate(peds[i]) then return false end
    end

    return true
end

---@param ped integer
---@return boolean
local function inVehicle(ped)
    return IsPedInAnyVehicle(ped, false)
end

---@param ped integer
---@return boolean
local function isDead(ped)
    return IsPedDeadOrDying(ped, true)
end

---@param ped integer
---@return boolean
local function isAlive(ped)
    return not IsPedDeadOrDying(ped, true)
end

local SEAT_LABELS = {
    [-1] = 'Sopir',
    [0] = 'Penumpang Depan',
    [1] = 'Belakang Kiri',
    [2] = 'Belakang Kanan',
}

---@param ctx { ped?: integer, vehicle?: integer, ground?: vector3 }
---@return integer[]
local function commandPeds(ctx)
    local selected = selection.peds()

    if #selected > 0 then
        local focus = false

        if ctx.ped and selection.has(ctx.ped) then
            focus = true
        elseif ctx.vehicle then
            for i = 1, #selected do
                if IsPedInVehicle(selected[i], ctx.vehicle, false) then
                    focus = true
                    break
                end
            end
        end

        return focus and selected or {}
    end

    if ctx.ped and selection.isPed(ctx.ped) then return { ctx.ped } end

    return {}
end

---@param peds integer[]
---@return table?
local function animationMenu(peds)
    local categories = {}
    local names = {}
    local count = 0

    for i = 1, #config.animations do
        local anim = config.animations[i]
        local list = categories[anim.category]

        if not list then
            list = {}
            categories[anim.category] = list
            count += 1
            names[count] = anim.category
        end

        list[#list + 1] = item(anim.label, 'motion', function(data)
            eachPed(data.peds, function(ped)
                orders.playAnim(ped, data.anim)
            end)
        end, { peds = peds, anim = anim })
    end

    tsort(names)

    local children = {}

    for i = 1, count do
        push(children, group(names[i], 'folder', categories[names[i]]))
    end

    return group('Animasi', 'motion', children)
end

---@param peds integer[]
---@param items table[]
local function pedMenu(peds, items)
    local single = #peds == 1 and peds[1] or nil

    push(items, item('Diam di Tempat', 'hand-stop', function(data)
        eachPed(data, orders.stand)
    end, peds))

    push(items, item('Perilaku NPC Biasa', 'walk', function(data)
        eachPed(data, orders.ambient)
    end, peds))

    if single then
        if state.follow and state.follow.entity == single then
            push(items, item('Berhenti Mengikuti', 'eye-off', function()
                camera.stopFollow()
            end))
        else
            push(items, item('Ikuti dengan Kamera', 'eye', function(ped)
                camera.follow(ped, 12.0)
            end, single))
        end

        if IsPedHuman(single) and not IsPedDeadOrDying(single, true) then
            push(items, item('Menyamar Jadi NPC Ini', 'mask', function(ped)
                hooks.impersonate(ped)
            end, single))
        end
    end

    if any(peds, IsPedHuman) then
        local weapons = {}

        for i = 1, #config.weapons do
            local weapon = config.weapons[i]

            weapons[i] = item(weapon.label, 'sword', function(data)
                eachPed(data.peds, function(ped)
                    orders.giveWeapon(ped, data.weapon)
                end)
            end, { peds = peds, weapon = weapon.weapon })
        end

        push(items, group('Beri Senjata', 'sword', weapons))
    end

    if any(peds, orders.isArmed) then
        push(items, item('Lepas Senjata', 'sword-off', function(data)
            eachPed(data, orders.removeWeapons)
        end, peds))
    end

    if #peds > 1 and any(peds, inVehicle) then
        push(items, item('Turun dari Kendaraan', 'door-exit', function(data)
            eachPed(data, orders.dismount)
        end, peds))
    end

    local actions = {}

    if any(peds, isDead) then
        push(actions, item('Hidupkan', 'heart-plus', function(data)
            eachPed(data, function(ped)
                if IsPedDeadOrDying(ped, true) then
                    orders.revive(ped)
                end
            end)
        end, peds))
    end

    push(actions, item('Pulihkan Darah', 'first-aid', function(data)
        eachPed(data, orders.heal)
    end, peds))

    if any(peds, isAlive) then
        push(actions, item('Bunuh', 'skull', function(data)
            eachPed(data, orders.kill)
        end, peds, true))
    end

    local allGod = all(peds, orders.isGod)
    local allFrozen = all(peds, orders.isFrozen)

    push(actions, item(allGod and 'Matikan Kebal' or 'Aktifkan Kebal', 'shield', function(data)
        eachPed(data.peds, function(ped)
            if orders.isGod(ped) == data.current then
                orders.toggleGod(ped)
            end
        end)
    end, { peds = peds, current = allGod }))

    push(actions, item(allFrozen and 'Lepas Bekuan' or 'Bekukan', 'snowflake', function(data)
        eachPed(data.peds, function(ped)
            if orders.isFrozen(ped) == data.current then
                orders.toggleFreeze(ped)
            end
        end)
    end, { peds = peds, current = allFrozen }))

    push(actions, item('Batalkan Tugas', 'ban', function(data)
        eachPed(data, function(ped)
            orders.clear(ped, false)
        end)
    end, peds))

    push(actions, item('Hentikan Paksa', 'player-stop', function(data)
        eachPed(data, function(ped)
            orders.clear(ped, true)
        end)
    end, peds))

    push(items, group('Aksi NPC', 'user-cog', actions))

    if any(peds, IsPedHuman) then
        push(items, animationMenu(peds))
    end
end

---@param ctx { ped?: integer, vehicle?: integer, ground?: vector3, object?: integer }
---@return table[]
local function build(ctx)
    local items = {}
    local actors = selection.actors()
    local ground = ctx.ground

    if #actors > 0 and ground then
        push(items, group('Pergi ke Sini', 'route', {
            item('Langsung', 'arrow-up-right', function(coords)
                orders.goTo(coords, 'direct')
            end, ground),
            item('Ikuti Jalan', 'route', function(coords)
                orders.goTo(coords, 'path')
            end, ground),
            item('Pergi lalu Diam', 'map-pin', function(coords)
                orders.goTo(coords, 'stand')
            end, ground),
        }))

        local attack = {}

        if ctx.ped and not selection.has(ctx.ped) and (selection.isPed(ctx.ped) or IsPedAPlayer(ctx.ped)) then
            push(attack, item('Serang Target', 'target', function(target)
                orders.attack(target)
            end, ctx.ped, true))
        end

        push(attack, item('Serang Area', 'radar', function(coords)
            orders.attackArea(coords)
        end, ground, true))

        push(items, group('Serang', 'swords', attack))
    end

    local selectedPeds = selection.peds()

    if #selectedPeds == 1 and ground and IsPedHuman(selectedPeds[1]) and DoesScenarioExistInArea(ground.x, ground.y, ground.z, 6.0, true) then
        push(items, group('Skenario', 'armchair', {
            item('Jalan ke Skenario Terdekat', 'walk', function(data)
                eachPed({ data.ped }, function(ped)
                    orders.scenario(ped, data.coords, false)
                end)
            end, { ped = selectedPeds[1], coords = ground }),
            item('Teleport ke Skenario Terdekat', 'bolt', function(data)
                eachPed({ data.ped }, function(ped)
                    orders.scenario(ped, data.coords, true)
                end)
            end, { ped = selectedPeds[1], coords = ground }),
        }))
    end

    local peds = commandPeds(ctx)

    if #peds > 0 then
        pedMenu(peds, items)
    end

    if #selectedPeds == 1 and not ctx.vehicle and IsPedInAnyVehicle(selectedPeds[1], false) and #peds == 0 then
        push(items, item('Turun dari Kendaraan', 'door-exit', function(ped)
            eachPed({ ped }, orders.dismount)
        end, selectedPeds[1]))
    end

    local selectedVehicles = selection.vehicles()

    if #state.selection == 1 and #selectedVehicles == 1 then
        local vehicle = selectedVehicles[1]

        push(items, item('Turunkan Semua Penumpang', 'users-minus', function(target)
            orders.unmountAll(target)
        end, vehicle))

        push(items, item('Lumpuhkan Kendaraan', 'car-crash', function(target)
            orders.disable(target)
        end, vehicle, true))
    end

    local vehicle = ctx.vehicle

    if vehicle and selection.isVehicle(vehicle) then
        if #selectedPeds == 1 and IsPedHuman(selectedPeds[1]) and not IsPedInAnyVehicle(selectedPeds[1], false) then
            local seats = {}

            for seat = -1, orders.lastSeat(vehicle) do
                local free = orders.seatFree(vehicle, seat)
                local label = ('%s · %s'):format(SEAT_LABELS[seat] or ('Kursi ' .. (seat + 2)), free and 'Kosong' or 'Terisi')

                seats[#seats + 1] = item(label, 'armchair', function(data)
                    orders.enter(data.ped, data.vehicle, data.seat)
                end, { ped = selectedPeds[1], vehicle = vehicle, seat = seat })
            end

            push(items, group('Masuk Kendaraan', 'car', seats))
        elseif #selectedPeds > 1 then
            push(items, item('Semua Masuk Kendaraan', 'car', function(target)
                orders.enterAll(target)
            end, vehicle))
        end

        local carrying = false

        for i = 1, #selectedPeds do
            if IsPedInVehicle(selectedPeds[i], vehicle, false) then
                carrying = true
                break
            end
        end

        if carrying then
            push(items, item('Turun dari Kendaraan Ini', 'door-exit', function(data)
                local inside = {}

                for i = 1, #data.peds do
                    if IsPedInVehicle(data.peds[i], data.vehicle, false) then
                        inside[#inside + 1] = data.peds[i]
                    end
                end

                eachPed(inside, orders.dismount)
            end, { peds = selectedPeds, vehicle = vehicle }))
        end

        if orders.isFlyingHeli(vehicle) then
            push(items, item('Daratkan Helikopter', 'helicopter-landing', function(data)
                orders.land(data.vehicle, data.coords)
            end, { vehicle = vehicle, coords = ground }))
        end
    end

    if ctx.object and #state.selection == 1 and state.selection[1] == ctx.object then
        push(items, item('Ubah Posisi Objek', 'arrows-move', function(entity)
            hooks.modify(entity)
        end, ctx.object))
    end

    local point = ground

    if ctx.ped and DoesEntityExist(ctx.ped) then
        point = GetEntityCoords(ctx.ped)
    elseif vehicle and DoesEntityExist(vehicle) then
        point = GetEntityCoords(vehicle)
    end

    if point then
        local explosions = {}

        for i = 1, #config.explosions do
            local entry = config.explosions[i]

            explosions[i] = item(entry.label, 'bomb', function(data)
                elements.explode(data.type, data.coords)
            end, { type = entry.type, coords = point }, true)
        end

        push(items, group('Elemen', 'flame', {
            item('Buat Api', 'flame', function(coords)
                elements.fire(coords)
            end, point),
            item('Padamkan Api', 'droplet', function(coords)
                elements.extinguish(coords)
            end, point),
            item('Sambaran Petir', 'bolt', function(coords)
                elements.lightning(coords)
            end, point, true),
            group('Ledakan', 'bomb', explosions),
        }))
    end

    if #state.selection > 0 then
        push(items, item(('Hapus Terpilih (%d)'):format(#state.selection), 'trash', function()
            hooks.delete()
        end, nil, true))
    end

    return items
end

---@param fns table
function menu.setHooks(fns)
    for key, fn in pairs(fns) do
        hooks[key] = fn
    end
end

---@param ctx table
---@return boolean
function menu.open(ctx)
    handlers = {}
    seq = 0

    local items = build(ctx)

    if #items == 0 then return false end

    state.menuOpen = true

    nui.send('menu', {
        x = state.cursorX,
        y = state.cursorY,
        items = items,
    })

    return true
end

---@param id string
function menu.select(id)
    local entry = handlers[id]

    handlers = {}
    state.menuOpen = false

    if not entry then return end

    CreateThread(function()
        entry.fn(entry.data)
    end)
end

function menu.close()
    handlers = {}
    state.menuOpen = false
end

---@param id string
---@param label string
---@param icon string
---@param run fun(peds: integer[], entities: integer[])
local function radial(id, label, icon, run)
    radialActions[id] = { label = label, icon = icon, run = run }
end

radial('clear_now', 'Hentikan Paksa', 'player-stop', function(peds)
    eachPed(peds, function(ped)
        orders.clear(ped, true)
    end)
end)

radial('clear', 'Batalkan Tugas', 'ban', function(peds)
    eachPed(peds, function(ped)
        orders.clear(ped, false)
    end)
end)

radial('ambient', 'NPC Biasa', 'walk', function(peds)
    eachPed(peds, orders.ambient)
end)

radial('stand', 'Diam', 'hand-stop', function(peds)
    eachPed(peds, orders.stand)
end)

radial('flee', 'Kabur', 'run', function(peds)
    eachPed(peds, orders.flee)
end)

radial('heal', 'Pulihkan', 'first-aid', function(peds)
    eachPed(peds, orders.heal)
end)

radial('god', 'Kebal', 'shield', function(peds)
    eachPed(peds, orders.toggleGod)
end)

radial('freeze', 'Bekukan', 'snowflake', function(peds)
    eachPed(peds, orders.toggleFreeze)
end)

radial('disarm', 'Lepas Senjata', 'sword-off', function(peds)
    eachPed(peds, orders.removeWeapons)
end)

radial('delete', 'Hapus', 'trash', function()
    hooks.delete()
end)

---@return { id: string, label: string, icon: string }[]
function menu.radialCatalog()
    local list = {}
    local count = 0

    for id, action in pairs(radialActions) do
        count += 1
        list[count] = { id = id, label = action.label, icon = action.icon }
    end

    tsort(list, function(a, b)
        return a.label < b.label
    end)

    return list
end

---@param id string
---@return boolean
function menu.radialValid(id)
    return radialActions[id] ~= nil
end

---@param id string
function menu.radialRun(id)
    local action = radialActions[id]

    if not action then return end

    CreateThread(function()
        action.run(selection.peds(), state.selection)
    end)
end

return menu
