local config = require('config.client').install

local GAP <const> = 0.5
local TYRE <const> = 0.6
local REACH <const> = 1.5
local LIFT <const> = 1.0
local RANGE <const> = 45.0
local STEPS <const> = 40
local WALK_TIMEOUT <const> = 3000
local ENTRY <const> = 0.75
local SCROLL_DOWN <const> = 14
local SCROLL_UP <const> = 15
local WEAPON_SCROLL <const> = { 14, 15, 16, 17, 261, 262 }
local WAIT <const> = 1000
local SETTLE <const> = 500
local PELVIS <const> = 11816
local TICK <const> = 500
local LINGER <const> = 10000

local CLAIM_ERRORS <const> = {
    busy = 'install.busy',
    taken = 'install.taken',
    seated = 'install.seated',
    far = 'install.far',
    denied = 'install.denied',
    gone = 'install.gone',
    full = 'install.full',
    empty = 'install.empty',
    idle = 'install.not_helping',
}

local RACK_ICONS <const> = { engine = 'hoist', jackUp = 'jack', paint = 'paint' }
local WORK_ICONS <const> = { engine = 'hoist', jackUp = 'jack', jackDown = 'jack', paint = 'paint', wheels = 'wheel' }
local HELP_SIDES <const> = { { side = 'left' }, { side = 'right' } }

local SIDE_LABELS <const> = {
    front = 'install.side_front',
    rear = 'install.side_rear',
    left = 'install.side_left',
    right = 'install.side_right',
    ['front-left'] = 'install.side_front_left',
    ['front-right'] = 'install.side_front_right',
    ['rear-left'] = 'install.side_rear_left',
    ['rear-right'] = 'install.side_rear_right',
    door = 'install.side_door',
}

local WHEEL_LABELS <const> = {
    wheel_lf = 'install.wheel_lf',
    wheel_rf = 'install.wheel_rf',
    wheel_lr = 'install.wheel_lr',
    wheel_rr = 'install.wheel_rr',
}

local EDGES <const> = {
    front = function(_, max) return 0.0, max.y, 0.0, 1.0 end,
    rear = function(min) return 0.0, min.y, 0.0, -1.0 end,
    left = function(min) return min.x, 0.0, -1.0, 0.0 end,
    right = function(_, max) return max.x, 0.0, 1.0, 0.0 end,
    ['front-left'] = function(min, max) return min.x, max.y * 0.6, -1.0, 0.0 end,
    ['front-right'] = function(_, max) return max.x, max.y * 0.6, 1.0, 0.0 end,
    ['rear-left'] = function(min) return min.x, min.y * 0.6, -1.0, 0.0 end,
    ['rear-right'] = function(min, max) return max.x, min.y * 0.6, 1.0, 0.0 end,
    door = function(min, max) return min.x, max.y * 0.15, -1.0, 0.0 end,
}

---@class InstallPlace
---@field stand vector3
---@field edge vector3
---@field heading number
---@field inward number
---@field label string

---@class InstallTask
---@field order integer
---@field vehicle number
---@field index integer
---@field label string
---@field short string
---@field patch table
---@field keys string[]
---@field kind string
---@field done integer
---@field step integer
---@field entry? vector3

---@class InstallTaskState
---@field label string
---@field short string
---@field kind string
---@field keys string[]
---@field state 'pending' | 'active' | 'done'
---@field carry boolean
---@field steps integer
---@field finished integer
---@field free integer[]
---@field workers string[]
---@field open boolean
---@field takeable boolean

---@class InstallOrder
---@field id integer
---@field netId integer
---@field zone string
---@field shop string
---@field plate string
---@field creator? integer
---@field version integer
---@field tasks InstallTaskState[]

---@class InstallChoice
---@field id? string
---@field action 'take' | 'return' | 'work' | 'help'
---@field order integer
---@field vehicle number
---@field index integer
---@field step? integer
---@field prompt string
---@field icon string

---@class InstallTarget
---@field key string
---@field point vector3
---@field anchor vector3
---@field choices InstallChoice[]

---@class InstallRig
---@field hoist? number
---@field engine? number

---@class InstallCarry
---@field order integer
---@field vehicle number
---@field index integer
---@field short string
---@field keys string[]
---@field kind string
---@field reuse boolean
---@field rig? InstallRig

---@class InstallClient : InstallShared
local install = {}

---@type fun(vehicle: number, props: table)
local apply
---@type table<integer, InstallOrder>
local orders = {}
---@type table<integer, integer>
local tombstones = {}
---@type integer?
local attached
---@type integer?
local helping
---@type InstallTask?
local task
---@type InstallCarry?
local carry
---@type InstallTarget[]
local targets = {}
---@type table<string, string>
local chosen = {}
---@type number[]
local held = {}
---@type number[]
local placed = {}
---@type InstallProp?
local carried
---@type table<number, { handle: integer, zone: string }>
local sprays = {}
---@type table<number, integer>
local versions = {}
local step = ''
local sent = ''
local stopped = false
local claiming = false
local away = 0
---@type { shop: string, label: string, plate: string }?
local staged

---@param kind string
---@param short string
---@param definition InstallDefinition
---@return string
local function thingOf(kind, short, definition)
    if kind == 'engine' then return locale('install.engine') end
    if kind == 'jackUp' then return locale('install.jack') end
    if kind == 'paint' then return locale('install.paint_of', short) end

    return definition.item or short
end

---@param kind string
---@param short string
---@param definition InstallDefinition
---@return string
local function verbOf(kind, short, definition)
    if kind == 'engine' then return locale('install.place_hoist') end
    if kind == 'jackUp' then return locale('install.jack_up') end
    if kind == 'jackDown' then return locale('install.jack_down') end
    if kind == 'paint' then return locale('install.spray', short) end

    return definition.prompt or locale('install.fit', short)
end

---@return string
local function hint()
    if task then return step end
    if not carry then return '' end

    local state = orders[carry.order]
    local item = state and state.tasks[carry.index]
    local definition = modules.install.of(carry.keys)

    if item and item.open then return verbOf(carry.kind, carry.short, definition) end

    return locale('install.return_rack', thingOf(carry.kind, carry.short, definition))
end

local function push()
    local state = attached and orders[attached]
    local data

    if state then
        local tasks = {}

        for i, item in ipairs(state.tasks) do
            tasks[i] = {
                label = item.label,
                state = item.state,
                worker = item.workers[1] and table.concat(item.workers, ', ') or nil,
                steps = item.steps,
                finished = item.finished,
            }
        end

        data = { shop = state.shop, plate = state.plate, step = hint(), tasks = tasks }
    elseif staged then
        data = { shop = staged.label, plate = staged.plate, step = locale('install.bring'), tasks = {} }
    end

    if not data then
        if sent ~= '' then
            sent = ''
            SendNUIMessage({ action = 'install', data = false })
        end

        return
    end

    local encoded = json.encode(data)
    if encoded == sent then return end

    sent = encoded
    SendNUIMessage({ action = 'install', data = data })
end

---@param text string
local function stage(text)
    step = text
    push()
end

---@return InstallTask?
---@return InstallOrder?
local function alive()
    local state = task and orders[task.order]
    if stopped or not task or not state then return end
    if #(GetEntityCoords(cache.ped) - GetEntityCoords(task.vehicle)) > config.distance then return end

    return task, state
end

---@param state InstallOrder
---@return number?
local function vehicleOf(state)
    if not NetworkDoesEntityExistWithNetworkId(state.netId) then return end

    local vehicle = NetworkGetEntityFromNetworkId(state.netId)

    return vehicle ~= 0 and DoesEntityExist(vehicle) and vehicle or nil
end

---@param entity number
---@return boolean
local function control(entity)
    local deadline = GetGameTimer() + 1500

    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < deadline do
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    end

    return NetworkHasControlOfEntity(entity)
end

---@param model string
---@param coords vector3
---@param tracked boolean
---@return number?
local function spawn(model, coords, tracked)
    if not IsModelValid(model) then return end

    local hash = lib.requestModel(model)
    local object = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false)

    SetModelAsNoLongerNeeded(hash)
    SetEntityCollision(object, false, false)

    if tracked then
        TriggerServerEvent('sm_custom:server:orderProp', NetworkGetNetworkIdFromEntity(object))
    end

    return object
end

---@param entity number
---@param spec InstallProp
local function attach(entity, spec)
    local ped = cache.ped
    local pos, rot = spec.pos, spec.rot

    AttachEntityToEntity(
        entity,
        ped,
        GetPedBoneIndex(ped, spec.bone),
        pos.x,
        pos.y,
        pos.z,
        rot.x,
        rot.y,
        rot.z,
        true,
        true,
        false,
        spec.ped ~= false,
        spec.order or 1,
        true
    )
end

local function letGo()
    if carried and carried.anim then
        StopAnimTask(cache.ped, carried.anim.dict, carried.anim.clip, 1.0)
    end

    held, carried = {}, nil
end

local function release()
    for i = 1, #held do
        if DoesEntityExist(held[i]) then DeleteEntity(held[i]) end
    end

    letGo()
end

local function clear()
    release()

    for i = 1, #placed do
        if DoesEntityExist(placed[i]) then DeleteEntity(placed[i]) end
    end

    placed = {}
end

---@param spec InstallProp | InstallProp[]
local function hold(spec)
    release()

    local list = spec.model and { spec } or spec
    local coords = GetEntityCoords(cache.ped)

    for i = 1, #list do
        local object = spawn(list[i].model, coords, true)

        if object then
            attach(object, list[i])
            held[#held + 1] = object
        end
    end

    carried = list[1]

    if carried.anim then lib.requestAnimDict(carried.anim.dict) end
end

local function carrying()
    if not carried then return end

    local anim = carried.anim

    if anim and not IsEntityPlayingAnim(cache.ped, anim.dict, anim.clip, 3) then
        TaskPlayAnim(cache.ped, anim.dict, anim.clip, 8.0, -8.0, -1, 49, 0, false, false, false)
    end

    DisableControlAction(0, 23, true)
    DisableControlAction(0, 24, true)
    DisableControlAction(0, 25, true)

    if carried.slow then
        DisableControlAction(0, 21, true)
        DisableControlAction(0, 22, true)
    end
end

---@param point vector3
---@return vector3
local function ground(point)
    local found, z = GetGroundZFor_3dCoord(point.x, point.y, point.z + 1.0, false)

    return found and vec3(point.x, point.y, z) or point
end

---@param points vector3[]
---@param prompt string
---@param icon string
---@return integer?
local function reach(points, prompt, icon)
    local entry = task and task.entry

    if task and entry then
        task.entry = nil

        for i = 1, #points do
            if #(points[i] - entry) < ENTRY then return i end
        end
    end

    local anchors = {}

    for i = 1, #points do
        anchors[i] = ground(points[i]) + vec3(0.0, 0.0, LIFT)
    end

    while alive() do
        carrying()

        local coords = GetEntityCoords(cache.ped)
        local near

        for i = 1, #points do
            local point = points[i]
            local inside = not near and #(coords.xy - point.xy) <= REACH and math.abs(coords.z - point.z) < 2.0

            if inside then near = i end

            modules.interact.draw(anchors[i], icon, #(coords - point), inside and prompt or nil)
        end

        if not near then modules.interact.clear() end

        if near and IsControlJustReleased(0, 38) then
            modules.interact.clear()

            return near
        end

        Wait(0)
    end

    modules.interact.clear()
end

---@param vehicle number
---@return 'front' | 'rear'
local function engineSide(vehicle)
    local bone = GetEntityBoneIndexByName(vehicle, 'engine')
    if bone == -1 then return 'front' end

    local position = GetWorldPositionOfEntityBone(vehicle, bone)

    return GetOffsetFromEntityGivenWorldCoords(vehicle, position.x, position.y, position.z).y < 0.0 and 'rear' or 'front'
end

---@param vehicle number
---@param anchor vector3
---@param out vector3
---@param label string
---@param offset? vector3
---@return InstallPlace
local function measure(vehicle, anchor, out, label, offset)
    if offset then anchor += offset end

    local stand = ground(GetOffsetFromEntityInWorldCoords(vehicle, anchor.x + out.x, anchor.y + out.y, anchor.z))
    local edge = ground(GetOffsetFromEntityInWorldCoords(vehicle, anchor.x, anchor.y, anchor.z))
    local center = GetEntityCoords(vehicle)

    return {
        stand = stand,
        edge = edge,
        heading = GetHeadingFromVector_2d(edge.x - stand.x, edge.y - stand.y),
        inward = GetHeadingFromVector_2d(center.x - edge.x, center.y - edge.y),
        label = label,
    }
end

---@param vehicle number
---@param spot InstallSpot
---@return InstallPlace?
local function locate(vehicle, spot)
    local min, max = GetModelDimensions(GetEntityModel(vehicle))

    if spot.wheel then
        local bone = GetEntityBoneIndexByName(vehicle, spot.wheel)
        if bone == -1 then return locate(vehicle, { side = modules.install.area(spot.wheel), offset = spot.offset }) end

        local position = GetWorldPositionOfEntityBone(vehicle, bone)
        local wheel = GetOffsetFromEntityGivenWorldCoords(vehicle, position.x, position.y, position.z)
        local out = vec3(wheel.x < 0.0 and -TYRE or TYRE, 0.0, 0.0)

        local label = locale(WHEEL_LABELS[spot.wheel] or 'install.wheel')

        return measure(vehicle, vec3(wheel.x, wheel.y, min.z), out, label, spot.offset)
    end

    local side = spot.side == 'engine' and engineSide(vehicle) or spot.side
    local x, y, dx, dy = EDGES[side](min, max)
    local label = locale(spot.side == 'engine' and 'install.engine_bay' or SIDE_LABELS[side])

    return measure(vehicle, vec3(x, y, min.z), vec3(dx * GAP, dy * GAP, 0.0), label, spot.offset)
end

---@param vehicle number
---@param doors? integer[]
---@param open boolean
local function doorsOf(vehicle, doors, open)
    if not doors or not DoesEntityExist(vehicle) or not control(vehicle) then return end

    for _, door in ipairs(doors) do
        if open then SetVehicleDoorOpen(vehicle, door, false, false) else SetVehicleDoorShut(vehicle, door, false) end
    end
end

---@param ped number
---@param target vector3
---@param heading number
local function walk(ped, target, heading)
    TaskGoStraightToCoord(ped, target.x, target.y, target.z, 1.0, WALK_TIMEOUT, heading, 0.1)

    local deadline = GetGameTimer() + WALK_TIMEOUT

    while #(GetEntityCoords(ped).xy - target.xy) > 0.3 and GetGameTimer() < deadline do
        Wait(50)
    end
end

---@param ped number
---@param anim InstallAnim
---@param active fun(): boolean
local function creep(ped, anim, active)
    while active() and not IsEntityPlayingAnim(ped, anim.dict, anim.clip, 3) do
        Wait(0)
    end

    Wait(SETTLE)

    if not active() then return end

    local creeper = spawn(modules.install.creeper, ground(GetPedBoneCoords(ped, PELVIS, 0.0, 0.0, 0.0)), true)
    if not creeper then return end

    SetEntityHeading(creeper, GetEntityHeading(ped))
    PlaceObjectOnGroundProperly(creeper)

    while active() do
        Wait(100)
    end

    DeleteEntity(creeper)
end

---@param ped number
---@param anim InstallAnim
---@param out number
local function play(ped, anim, out)
    TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, out, -1, anim.flag or 1, 0.0, false, false, false)
end

---@param ped number
---@param intro InstallAnim
---@param anim InstallAnim
---@param active fun(): boolean
local function sequence(ped, intro, anim, active)
    lib.requestAnimDict(intro.dict)
    lib.requestAnimDict(anim.dict)

    if active() then play(ped, intro, -8.0) end

    local deadline = GetGameTimer() + (intro.time or 0)

    while active() and GetGameTimer() < deadline do
        Wait(50)
    end

    if active() then play(ped, anim, -2.0) end

    RemoveAnimDict(intro.dict)
    RemoveAnimDict(anim.dict)
end

---@param vehicle number
---@param work InstallWork
---@param place InstallPlace
---@param label string
---@param during? fun(active: fun(): boolean)
---@return boolean
local function perform(vehicle, work, place, label, during)
    local ped = cache.ped
    local anim, intro, grip = work.anim, work.intro, work.grip
    local running = true

    local function active() return running end

    if not work.under then walk(ped, place.stand, place.heading) end

    if not grip then
        release()
    elseif held[1] then
        attach(held[1], grip)
    end

    if work.under then
        SetEntityCoordsNoOffset(ped, place.edge.x, place.edge.y, GetEntityCoords(ped).z, false, false, false)
        SetEntityHeading(ped, place.inward + 180.0)
        CreateThread(function() creep(ped, anim, active) end)
    else
        SetEntityHeading(ped, place.heading)
    end

    doorsOf(vehicle, work.doors, true)

    if during then
        CreateThread(function() during(active) end)
    end

    if intro then
        CreateThread(function() sequence(ped, intro, anim, active) end)
    end

    local done = lib.progressBar({
        duration = work.time + (intro and intro.time or 0),
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = not intro and { dict = anim.dict, clip = anim.clip, flag = anim.flag or 1 } or nil,
        prop = work.tool,
    })

    running = false

    if intro then
        StopAnimTask(ped, intro.dict, intro.clip, 1.0)
        StopAnimTask(ped, anim.dict, anim.clip, 1.0)
    end

    if grip and held[1] and carried then attach(held[1], carried) end

    doorsOf(vehicle, work.doors, false)

    return done == true
end

---@param vehicle number
---@param spot InstallSpot
---@return string
local function areaOf(vehicle, spot)
    if spot.side == 'engine' then return engineSide(vehicle) end

    return modules.install.area(spot.wheel or spot.side --[[@as string]])
end

---@param current InstallTask
---@param area string
---@param stand vector3
---@param label string
---@return boolean?
local function occupy(current, area, stand, label)
    local previous = step

    while alive() do
        local holder = lib.callback.await('sm_custom:server:orderArea', false, current.order, current.index, area)

        if holder == true then
            stage(previous)

            return true
        end

        if type(holder) ~= 'string' then return false end

        stage(locale('install.waiting', holder, label))

        local deadline = GetGameTimer() + WAIT

        while GetGameTimer() < deadline do
            carrying()

            if #(GetEntityCoords(cache.ped).xy - stand.xy) > REACH then return end

            Wait(0)
        end
    end

    return false
end

---@param spot InstallSpot
---@param prompt string
---@param work InstallWork
---@param label string
---@param during? fun(active: fun(): boolean)
---@param icon? string
---@return boolean
local function workAt(spot, prompt, work, label, during, icon)
    local current = alive()
    local place = current and locate(current.vehicle, spot)
    if not current or not place then return false end

    stage(locale('install.at', prompt, place.label))

    if not reach({ place.stand }, prompt, icon or 'work') then return false end
    if not occupy(current, areaOf(current.vehicle, spot), place.stand, place.label) then return false end

    return perform(current.vehicle, work, place, label, during)
end

---@param stands? integer[]
---@return boolean
local function mark(stands)
    local current = alive()
    if not current then return false end

    local ok = lib.callback.await('sm_custom:server:orderStep', false, current.order, current.index, current.done + 1, stands)
    if ok ~= true then return false end

    current.done += 1

    return true
end

---@param vehicle number
---@param patch table
local function show(vehicle, patch)
    if not next(patch) or not DoesEntityExist(vehicle) or not control(vehicle) then return end

    apply(vehicle, patch)
end

---@class InstallTint
---@field target integer[]
---@field custom fun(vehicle: number): boolean
---@field get fun(vehicle: number): integer, integer, integer
---@field set fun(vehicle: number, r: integer, g: integer, b: integer)

---@param patch table
---@return InstallTint?
local function tint(patch)
    if type(patch.color1) == 'table' then
        return {
            target = patch.color1,
            custom = GetIsVehiclePrimaryColourCustom,
            get = GetVehicleCustomPrimaryColour,
            set = SetVehicleCustomPrimaryColour,
        }
    end

    if type(patch.color2) == 'table' then
        return {
            target = patch.color2,
            custom = GetIsVehicleSecondaryColourCustom,
            get = GetVehicleCustomSecondaryColour,
            set = SetVehicleCustomSecondaryColour,
        }
    end
end

---@param current InstallTask
---@param work InstallWork
---@return fun(active: fun(): boolean)
local function spraying(current, work)
    local vehicle = current.vehicle
    local colour = tint(current.patch)

    return function(active)
        local anim = work.anim

        while active() and not IsEntityPlayingAnim(cache.ped, anim.dict, anim.clip, 3) do
            Wait(50)
        end

        if not active() then return end

        local state = orders[current.order]
        local item = state and state.tasks[current.index]
        local remaining = item and #item.free + 1 or 1
        local can = held[1]

        if can and DoesEntityExist(can) then
            local target = colour and colour.target

            TriggerServerEvent(
                'sm_custom:server:spray',
                current.order,
                current.index,
                NetworkGetNetworkIdFromEntity(can),
                target and { math.floor(target[1]), math.floor(target[2]), math.floor(target[3]) } or false
            )
        end

        local from = colour and colour.custom(vehicle) and control(vehicle) and { colour.get(vehicle) }
        local began = GetGameTimer()

        while active() do
            if colour and from and NetworkHasControlOfEntity(vehicle) then
                local target = colour.target
                local t = math.min((GetGameTimer() - began) / work.time, 1.0) / remaining

                colour.set(
                    vehicle,
                    math.floor(from[1] + (target[1] - from[1]) * t + 0.5),
                    math.floor(from[2] + (target[2] - from[2]) * t + 0.5),
                    math.floor(from[3] + (target[3] - from[3]) * t + 0.5)
                )
            end

            Wait(100)
        end

        TriggerServerEvent('sm_custom:server:spray')
    end
end

---@param definition InstallDefinition
---@return boolean
local function piece(definition)
    local current = task --[[@as InstallTask]]
    local spot = (definition.spots or {})[current.step]
    if not spot then return false end

    local short, kind = current.short, current.kind
    local paints = kind == 'paint'
    local progress = definition.progress or locale(paints and 'install.spraying' or 'install.fitting', short)
    local during = paints and spraying(current, definition.work) or nil

    return workAt(spot, verbOf(kind, short, definition), definition.work, progress, during, WORK_ICONS[kind])
end

---@param vehicle number
---@return vector3
---@return number
local function station(vehicle)
    local min, max = GetModelDimensions(GetEntityModel(vehicle))
    local front = engineSide(vehicle) == 'front'
    local offset = modules.install.hoist.offset
    local y = front and max.y + offset.y or min.y - offset.y
    local position = ground(GetOffsetFromEntityInWorldCoords(vehicle, offset.x, y, 0.0))

    return position, GetEntityHeading(vehicle) + (front and 0.0 or 180.0)
end

---@param rig InstallRig
---@return boolean
local function grab(rig)
    hold(modules.install.hoist.carry)
    rig.hoist = held[1]

    return rig.hoist ~= nil
end

---@param rig InstallRig
---@param vehicle number
---@return boolean
local function park(rig, vehicle)
    local current = task --[[@as InstallTask]]
    local position, heading = station(vehicle)

    stage(locale('install.hoist_hint'))

    if not reach({ position }, locale('install.place_hoist'), 'hoist') then return false end
    if not occupy(current, engineSide(vehicle), position, 'ruang mesin') then return false end

    DetachEntity(rig.hoist, false, false)
    FreezeEntityPosition(rig.hoist, true)
    SetEntityCoordsNoOffset(rig.hoist, position.x, position.y, position.z, false, false, false)
    SetEntityHeading(rig.hoist, heading)
    letGo()
    placed[#placed + 1] = rig.hoist

    return true
end

---@param rig InstallRig
local function hang(rig)
    local engine = modules.install.hoist.engine

    AttachEntityToEntity(rig.engine, rig.hoist, 0, engine.pos.x, engine.pos.y, engine.pos.z, engine.rot.x, engine.rot.y, engine.rot.z, true, true, false, false, 1, true)
end

---@param rig InstallRig
local function descend(rig)
    local engine = modules.install.hoist.engine
    local hook = GetOffsetFromEntityInWorldCoords(rig.hoist, engine.pos.x, engine.pos.y, engine.pos.z)
    local drop = modules.install.hoist.drop

    DetachEntity(rig.engine, false, false)
    FreezeEntityPosition(rig.engine, true)
    SetEntityHeading(rig.engine, GetEntityHeading(rig.hoist) - 180.0)

    for i = 0, STEPS do
        SetEntityCoordsNoOffset(rig.engine, hook.x, hook.y, hook.z - drop * i / STEPS, false, false, false)
        Wait(25)
    end
end

---@param rig InstallRig
local function mount(rig)
    rig.engine = spawn(modules.install.hoist.engine.model, GetEntityCoords(rig.hoist), true)

    if rig.engine then placed[#placed + 1] = rig.engine end
end

---@return boolean
local function engine()
    local current = task --[[@as InstallTask]]
    local spec = modules.install.hoist
    local vehicle = current.vehicle
    local bay = { side = engineSide(vehicle) == 'front' and 'front-left' or 'rear-left' }
    local rig = carry and carry.rig

    if not rig or not rig.hoist or not park(rig, vehicle) then return false end

    doorsOf(vehicle, { 4 }, true)

    if rig.engine then descend(rig) end

    if not workAt(bay, locale('install.engine_fit'), spec.work, locale('install.engine_fitting')) then return false end

    clear()

    if not mark() then return false end

    doorsOf(vehicle, { 4 }, false)

    return true
end

---@param vehicle number
---@param height number
---@return integer[]
local function raise(vehicle, height)
    local spec = modules.install.jack
    local stands = {}

    if not control(vehicle) then return stands end

    local origin = GetEntityCoords(vehicle)
    local heading = GetEntityHeading(vehicle)

    for _, offset in ipairs(spec.placements) do
        local position = ground(GetOffsetFromEntityInWorldCoords(vehicle, offset.x, offset.y, offset.z))
        local stand = spawn(spec.stand, position, false)

        if stand then
            FreezeEntityPosition(stand, true)
            SetEntityHeading(stand, heading)
            SetEntityCoordsNoOffset(stand, position.x, position.y, position.z, false, false, false)
            stands[#stands + 1] = NetworkGetNetworkIdFromEntity(stand)
        end
    end

    for i = 1, STEPS do
        SetEntityCoordsNoOffset(vehicle, origin.x, origin.y, origin.z + height * i / STEPS, false, false, false)
        Wait(25)
    end

    return stands
end

---@param vehicle number
---@param height number
local function lower(vehicle, height)
    if not control(vehicle) then return end

    local origin = GetEntityCoords(vehicle)

    for i = 1, STEPS do
        SetEntityCoordsNoOffset(vehicle, origin.x, origin.y, origin.z - height * i / STEPS, false, false, false)
        Wait(25)
    end

    SetVehicleOnGroundProperly(vehicle)
end

---@return boolean
local function jackUp()
    local current = task --[[@as InstallTask]]
    local spec = modules.install.jack

    local done = workAt(spec.spot, locale('install.jack_up'), spec.work, locale('install.jack_raising'), nil, 'jack')
    if not done then return false end

    return mark(raise(current.vehicle, spec.height))
end

---@return boolean
local function jackDown()
    local current = task --[[@as InstallTask]]
    local spec = modules.install.jack

    local done = workAt(spec.spot, locale('install.jack_down'), spec.work, locale('install.jack_lowering'), nil, 'jack')
    if not done then return false end

    lower(current.vehicle, spec.height)

    return mark()
end

local KINDS <const> = {
    part = piece,
    wheels = piece,
    paint = piece,
    engine = engine,
    jackUp = jackUp,
    jackDown = jackDown,
}

---@param vehicle number
local function settle(vehicle)
    if not DoesEntityExist(vehicle) or not control(vehicle) then return end

    SetVehicleDoorsShut(vehicle, false)
    SetVehicleOnGroundProperly(vehicle)
end

local function discard()
    carry = nil
    clear()
    push()
end

local function putBack()
    if not carry then return end

    TriggerServerEvent('sm_custom:server:orderReturn', carry.order, carry.index)
    discard()
end

---@param item InstallCarry
local function equip(item)
    if item.kind ~= 'engine' then
        local spec = modules.install.carry(item.kind, modules.install.of(item.keys))

        if spec then hold(spec) end

        return
    end

    local rig = {}

    if not grab(rig) then return end

    mount(rig)

    if rig.engine then hang(rig) end

    item.rig = rig
end

---@param finished boolean
local function restock(finished)
    if not carry then return end
    if finished and not carry.reuse then return discard() end
    if #held > 0 then return end
    if carry.rig then return putBack() end

    equip(carry)
end

local function run()
    local current = task --[[@as InstallTask]]
    local handler = KINDS[current.kind]

    stopped = false
    push()

    local ok = handler ~= nil and alive() and handler(modules.install.of(current.keys))
    local result = ok and lib.callback.await('sm_custom:server:orderDone', false, current.order, current.index)

    if type(result) ~= 'table' then
        TriggerServerEvent('sm_custom:server:orderRelease', current.order, current.index)
        restock(false)
    else
        if result.complete or result.last then discard() else restock(true) end

        if result.last then show(current.vehicle, current.patch) end

        if result.complete then
            if type(result.leftover) == 'table' then show(current.vehicle, result.leftover) end

            settle(current.vehicle)
            lib.notify({ type = 'success', description = locale('install.done') })
        end
    end

    task = nil
    step = ''
    push()
end

---@param id integer
---@param vehicle number
---@param result table
---@param entry? vector3
local function begin(id, vehicle, result, entry)
    if task then
        return TriggerServerEvent('sm_custom:server:orderRelease', id, result.index)
    end

    attached = id
    task = {
        order = id,
        vehicle = vehicle,
        index = result.index,
        label = result.label,
        short = result.short,
        patch = result.patch,
        keys = result.keys,
        kind = result.kind,
        done = result.done,
        step = result.step,
        entry = entry,
    }

    run()
end

---@param result any
---@param id integer
---@return string?
local function refusal(result, id)
    if type(result) == 'table' and not result.error then return end

    local problem = type(result) == 'table' and result.error or 'denied'

    if problem == 'gone' then orders[id] = nil end

    return problem
end

---@param id integer
---@param vehicle number
---@param index integer
---@param point vector3
---@param step? integer
---@return string?
local function claim(id, vehicle, index, point, step)
    if task or claiming then return end

    claiming = true

    local result = lib.callback.await('sm_custom:server:orderClaim', false, id, index, step)

    claiming = false

    local problem = refusal(result, id)
    if problem then return problem end

    begin(id, vehicle, result, point)
end

---@param choice InstallChoice
---@return string?
local function pickUp(choice)
    if task or carry or claiming then return end

    claiming = true

    local result = lib.callback.await('sm_custom:server:orderTake', false, choice.order, choice.index)

    claiming = false

    local problem = refusal(result, choice.order)
    if problem then return problem end

    carry = {
        order = choice.order,
        vehicle = choice.vehicle,
        index = result.index,
        short = result.short,
        keys = result.keys,
        kind = result.kind,
        reuse = result.reuse == true,
    }
    attached = choice.order

    equip(carry)
    push()
end

---@param choice InstallChoice
---@return string?
local function join(choice)
    if task or claiming then return end

    claiming = true

    local result = lib.callback.await('sm_custom:server:orderHelp', false, choice.order)

    claiming = false

    if result ~= true then
        if result == 'gone' then orders[choice.order] = nil end

        return type(result) == 'string' and result or 'denied'
    end

    if carry then discard() end

    local state = orders[choice.order]

    helping, attached = choice.order, choice.order
    lib.notify({ type = 'success', description = locale('install.helping', state and state.plate or '') })
end

---@param choice InstallChoice
---@param point vector3
local function act(choice, point)
    if choice.action == 'return' then return putBack() end

    local problem

    if choice.action == 'help' then
        problem = join(choice)
    elseif choice.action == 'take' then
        problem = pickUp(choice)
    else
        problem = claim(choice.order, choice.vehicle, choice.index, point, choice.step)
    end

    if problem then
        lib.notify({ type = 'error', description = locale(CLAIM_ERRORS[problem] or CLAIM_ERRORS.denied) })
    end
end

---@param list InstallTarget[]
---@param index table<string, InstallTarget>
---@param point vector3
---@param choice InstallChoice
local function offer(list, index, point, choice)
    local key = ('%.1f:%.1f:%.1f'):format(point.x, point.y, point.z)
    local target = index[key]

    if not target then
        target = {
            key = key,
            point = point,
            anchor = ground(point) + vec3(0.0, 0.0, LIFT),
            choices = {},
        }
        index[key] = target
        list[#list + 1] = target
    end

    choice.id = ('%s:%d:%d:%d'):format(choice.action, choice.order, choice.index, choice.step or 0)
    target.choices[#target.choices + 1] = choice
end

---@param list InstallTarget[]
---@param index table<string, InstallTarget>
---@param zone CustomZone
---@param keys string[]
---@param choice InstallChoice
local function offerRack(list, index, zone, keys, choice)
    for _, point in ipairs(modules.zones.pickups(zone, keys)) do
        offer(list, index, point, choice)
    end
end

---@param vehicle number
---@param item InstallTaskState
---@param step integer
---@return vector3?
local function pointOf(vehicle, item, step)
    if item.kind == 'engine' then return (station(vehicle)) end

    local jack = item.kind == 'jackUp' or item.kind == 'jackDown'
    local spot = jack and modules.install.jack.spot or (modules.install.of(item.keys).spots or {})[step]
    local place = spot and locate(vehicle, spot)

    return place and place.stand
end

---@param list InstallTarget[]
---@param index table<string, InstallTarget>
---@param id integer
---@param vehicle number
---@param i integer
---@param item InstallTaskState
local function offerWork(list, index, id, vehicle, i, item)
    local prompt = verbOf(item.kind, item.short, modules.install.of(item.keys))
    local icon = WORK_ICONS[item.kind] or 'work'

    for _, step in ipairs(item.free) do
        local point = pointOf(vehicle, item, step)

        if point then
            offer(list, index, point, {
                action = 'work',
                order = id,
                vehicle = vehicle,
                index = i,
                step = step,
                prompt = prompt,
                icon = icon,
            })
        end
    end
end

---@param list InstallTarget[]
---@param index table<string, InstallTarget>
---@param id integer
---@param vehicle number
local function offerHelp(list, index, id, vehicle)
    for _, spot in ipairs(HELP_SIDES) do
        local place = locate(vehicle, spot)

        if place then
            offer(list, index, place.stand, {
                action = 'help',
                order = id,
                vehicle = vehicle,
                index = 0,
                prompt = locale('install.help'),
                icon = 'help',
            })
        end
    end
end

local function scan()
    local coords = GetEntityCoords(cache.ped)
    local candidates = {}

    for id, state in pairs(orders) do
        local vehicle = vehicleOf(state)
        local zone = modules.zones.get(state.zone)

        if vehicle and zone then
            local distance = #(GetEntityCoords(vehicle) - coords)

            if distance <= RANGE then
                candidates[#candidates + 1] = {
                    id = id,
                    state = state,
                    vehicle = vehicle,
                    zone = zone,
                    rank = id == attached and -1.0 or distance,
                }
            end
        end
    end

    table.sort(candidates, function(a, b) return a.rank < b.rank end)

    local list, index = {}, {}
    local state = carry and orders[carry.order]
    local zone = state and modules.zones.get(state.zone)

    if carry and zone then
        offerRack(list, index, zone, carry.keys, {
            action = 'return',
            order = carry.order,
            vehicle = carry.vehicle,
            index = carry.index,
            prompt = locale('install.return', thingOf(carry.kind, carry.short, modules.install.of(carry.keys))),
            icon = RACK_ICONS[carry.kind] or 'rack',
        })
    end

    for _, candidate in ipairs(candidates) do
        if candidate.id ~= helping then
            offerHelp(list, index, candidate.id, candidate.vehicle)
        else
            for i, item in ipairs(candidate.state.tasks) do
                local holding = carry ~= nil and carry.order == candidate.id and carry.index == i

                if holding or not (carry or item.carry) then
                    if item.open then offerWork(list, index, candidate.id, candidate.vehicle, i, item) end
                elseif not carry and item.takeable then
                    offerRack(list, index, candidate.zone, item.keys, {
                        action = 'take',
                        order = candidate.id,
                        vehicle = candidate.vehicle,
                        index = i,
                        prompt = locale('install.take', thingOf(item.kind, item.short, modules.install.of(item.keys))),
                        icon = RACK_ICONS[item.kind] or 'rack',
                    })
                end
            end
        end
    end

    targets = list
end

---@return integer?
local function closest()
    local coords = GetEntityCoords(cache.ped)
    local found, best

    for id, state in pairs(orders) do
        local vehicle = vehicleOf(state)
        local distance = vehicle and #(GetEntityCoords(vehicle) - coords)

        if distance and distance <= RANGE and (not best or distance < best) then
            found, best = id, distance
        end
    end

    return found
end

---@return integer?
local function joined()
    local state = helping and orders[helping]
    local vehicle = state and vehicleOf(state)

    if vehicle and #(GetEntityCoords(vehicle) - GetEntityCoords(cache.ped)) <= RANGE then return helping end
end

local function watch()
    if not carry or task then return end

    local state = orders[carry.order]
    local vehicle = state and vehicleOf(state)
    local far = not vehicle or #(GetEntityCoords(vehicle) - GetEntityCoords(cache.ped)) > config.distance

    if not far and not IsEntityDead(cache.ped) then return end

    putBack()
    lib.notify({ type = 'info', description = locale('install.returned') })
end

SetInterval(function()
    local id = joined()

    watch()

    if task then
        attached = task.order
    elseif carry then
        attached = carry.order
    elseif id then
        attached = id
    elseif attached then
        local state = orders[attached]
        local current = state and vehicleOf(state)

        if not current or #(GetEntityCoords(current) - GetEntityCoords(cache.ped)) > RANGE then
            attached = nil
        end
    end

    if task then
        targets = {}
    else
        scan()
    end

    if task or closest() then
        away = 0
        modules.interact.hold('install', true)
    elseif away < LINGER then
        away += TICK
    else
        modules.interact.hold('install', false)
    end

    push()
end, TICK)

---@param target InstallTarget
---@return integer
local function picked(target)
    local id = chosen[target.key]

    for i, choice in ipairs(target.choices) do
        if choice.id == id then return i end
    end

    return 1
end

---@param target InstallTarget
local function cycle(target)
    local total = #target.choices
    if total < 2 then return end

    for i = 1, #WEAPON_SCROLL do
        DisableControlAction(0, WEAPON_SCROLL[i], true)
    end

    local down = IsDisabledControlJustPressed(0, SCROLL_DOWN)
    local up = IsDisabledControlJustPressed(0, SCROLL_UP)
    if down == up then return end

    local shift = down and 1 or -1

    chosen[target.key] = target.choices[(picked(target) - 1 + shift) % total + 1].id
end

CreateThread(function()
    while true do
        if task or cache.vehicle or (#targets == 0 and not carry) then
            Wait(250)
        else
            local coords = GetEntityCoords(cache.ped)
            local near

            if carry then carrying() end

            for _, target in ipairs(targets) do
                local point = target.point
                local inside = not near and #(coords.xy - point.xy) <= REACH and math.abs(coords.z - point.z) < 2.0
                local pick = picked(target)
                local choice = target.choices[pick]
                local total = #target.choices

                if inside then near = target end

                modules.interact.draw(
                    target.anchor,
                    choice.icon,
                    #(coords - point),
                    inside and choice.prompt or nil,
                    inside and total > 1 and ('%d/%d'):format(pick, total) or nil
                )
            end

            if near then cycle(near) else modules.interact.clear() end

            if near and not claiming and IsControlJustReleased(0, 38) then
                local choice, point = near.choices[picked(near)], near.point

                modules.interact.clear()
                CreateThread(function() act(choice, point) end)
            end

            Wait(0)
        end
    end
end)

RegisterNetEvent('sm_custom:client:order', function(data)
    if source == '' or type(data) ~= 'table' then return end

    local id, version = data.id, tonumber(data.version)
    if math.type(id) ~= 'integer' or not version then return end

    local current = orders[id]
    if (current and current.version >= version) or (tombstones[id] or 0) >= version then return end

    if data.removed then
        orders[id] = nil
        tombstones[id] = version

        if helping == id then helping = nil end

        if task and task.order == id then
            stopped = true

            if lib.progressActive() then lib.cancelProgress() end
        end

        if carry and carry.order == id then discard() end
    else
        orders[id] = data
    end

    push()
end)

RegisterNetEvent('sm_custom:client:orders', function(list)
    if source == '' or type(list) ~= 'table' then return end

    local fresh = {}

    for _, data in ipairs(list) do
        if type(data) == 'table' then
            local id, version = data.id, tonumber(data.version)

            if math.type(id) == 'integer' and version and (tombstones[id] or 0) < version then
                local current = orders[id]

                fresh[id] = (current and current.version > version) and current or data
            end
        end
    end

    orders = fresh

    if helping and not orders[helping] then helping = nil end

    if task and not orders[task.order] then
        stopped = true

        if lib.progressActive() then lib.cancelProgress() end
    end

    if carry and not orders[carry.order] then putBack() end

    push()
end)

RegisterNetEvent('sm_custom:client:helping', function(id)
    if source == '' or math.type(id) ~= 'integer' then return end

    helping = id
end)

RegisterNetEvent('sm_custom:client:unload', function(id, index)
    if source == '' or not carry or carry.order ~= id or carry.index ~= index then return end

    discard()
end)

---@param player number
local function unspray(player)
    local entry = sprays[player]
    if not entry then return end

    StopParticleFxLooped(entry.handle, false)
    sprays[player] = nil
end

RegisterNetEvent('sm_custom:client:spray', function(player, zone, netId, colour)
    if source == '' or math.type(player) ~= 'integer' or type(zone) ~= 'string' then return end

    local version = (versions[player] or 0) + 1

    versions[player] = version
    unspray(player)

    if math.type(netId) ~= 'integer' or not modules.areas.inside(zone) then return end
    if not NetworkDoesEntityExistWithNetworkId(netId) then return end

    local can = NetworkGetEntityFromNetworkId(netId)
    local ped = GetPlayerPed(GetPlayerFromServerId(player))
    if not DoesEntityExist(can) or not IsEntityAttachedToEntity(can, ped) then return end

    CreateThread(function()
        local spray = modules.install.spray

        lib.requestNamedPtfxAsset(spray.asset)

        if versions[player] ~= version or not DoesEntityExist(can) then return end

        UseParticleFxAsset(spray.asset)

        local started = StartParticleFxLoopedOnEntity(
            spray.effect,
            can,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            spray.scale,
            false,
            false,
            false
        )

        SetParticleFxLoopedAlpha(started, spray.alpha)

        if type(colour) == 'table' then
            local r, g, b = tonumber(colour[1]) or 255, tonumber(colour[2]) or 255, tonumber(colour[3]) or 255

            SetParticleFxLoopedColour(started, r / 255, g / 255, b / 255, false)
        end

        sprays[player] = { handle = started, zone = zone }
    end)
end)

modules.areas.watch(function(key, inside)
    if inside then return end

    for player, entry in pairs(sprays) do
        if entry.zone == key then
            versions[player] = (versions[player] or 0) + 1
            unspray(player)
        end
    end
end)

RegisterNetEvent('sm_custom:client:forced', function(netId, patch)
    if source == '' or math.type(netId) ~= 'integer' or type(patch) ~= 'table' then return end
    if not NetworkDoesEntityExistWithNetworkId(netId) then return end

    local vehicle = NetToVeh(netId)

    show(vehicle, patch)
    settle(vehicle)
    lib.notify({ type = 'warning', description = locale('install.stopped') })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    clear()

    for _, entry in pairs(sprays) do
        StopParticleFxLooped(entry.handle, false)
    end
end)

---@return boolean
function install.active()
    return task ~= nil or carry ~= nil
end

---@param handler fun(vehicle: number, props: table)
function install.start(handler)
    apply = handler
end

---@param shop string
local function waypoint(shop)
    local origin = GetEntityCoords(cache.ped)
    local target, best

    for _, zone in ipairs(modules.zones.list) do
        if zone.key == shop and zone.install and not zone.booth then
            local distance = #(zone.coords - origin)

            if not best or distance < best then target, best = zone.coords, distance end
        end
    end

    if target then SetNewWaypoint(target.x, target.y) end
end

---@param data? { shop: string, label: string, plate: string }
function install.stage(data)
    staged = data

    if data then waypoint(data.shop) end

    push()
end

---@param vehicle number
---@param patch table
function install.apply(vehicle, patch)
    show(vehicle, patch)
end

return install
