local ls
local cacheEntities = {}

local ps = {}
local utils = localmodule 'utils.client'
local propSpawner = localmodule 'utils.propSpawner'
local config = localmodule 'config.shared'
-- local placer = localmodule 'utils.placer'


-- RegisterCommand('placeprop', function (_, args)
--     placer.start('prop_barrel_03a', false, 20)
-- end, false)

local function playPropEffect(entity, prop)
    local particle = prop.particle
    local sound = prop.sound
    local ptfx

    if particle then
        lib.requestNamedPtfxAsset(particle.dict)
        UseParticleFxAsset(particle.dict)

        local coords = GetEntityCoords(entity)
        local rot = particle.rot or vec(0.0, 0.0, 0.0)

        ptfx = StartParticleFxLoopedAtCoord(
            particle.name,
            coords.x, coords.y, coords.z + 0.5,
            rot.x, rot.y, rot.z,
            particle.scale or 1.0,
            false, false, false, false
        )
    end

    if sound then
        PlaySoundFromEntity(GetSoundId(), sound.name, entity, sound.set, true, 0)
    end

    return ptfx
end

local function stopPropEffect(ptfx)
    if ptfx then
        StopParticleFxLooped(ptfx, false)
    end
end

local WALK_SPEED = 1.0
local NAV_BREAKING_CONTROLS = { 74, 21, 22, 23, 75 }

local function blockNavBreakingControls()
    for i = 1, #NAV_BREAKING_CONTROLS do
        DisableControlAction(0, NAV_BREAKING_CONTROLS[i], true)
    end
end

local function execute(key, data, auto, entity, menuIndex)
    local isProp = entity ~= nil
    local menuOpt = menuIndex and data.menu and data.menu[menuIndex]

    if not utils.checkRequired(data.requiredWeapon, menuOpt?.items?.remove or data.items?.remove) then
        ls = false
        ps[key] = nil
        return false
    end

    if isProp and (not entity or not DoesEntityExist(entity)) then
        ls = false
        ps[key] = nil
        return false
    end

    local coords = isProp and GetEntityCoords(entity) or data.coords

    ps[key] = 'check'

    if data.busyCheck then
        local canAction = lib.callback.await('sidejobs:server:c', 1500, key, coords, menuIndex)

        if not canAction then
            ls = false
            ps[key] = nil

            lib.notify({
                description = 'Tidak bisa melakukan ini sekarang.',
                type = 'error'
            })
            return false
        end
    end

    playerState.canEmote = false
    local progress = data.progressbar
    local dict = progress?.anim?.dict
    local name = progress?.anim?.clip

    local success = not progress
    local ptfx = { handle = nil }

    if isProp then
        if data.prop?.effects then
            ptfx.handle = playPropEffect(entity, data.prop?.effects)
        elseif data.prop?.loopedEffects then
            SetTimeout(data.prop.loopedEffects.delay or 0, function ()
                CreateThread(function()
                    while ps[key] == 'check' and DoesEntityExist(entity) do
                        stopPropEffect(ptfx.handle)
                        ptfx.handle = playPropEffect(entity, data.prop.loopedEffects)

                        local delay = data.prop.loopedEffects.tick

                        if delay == 'animduration' then
                            delay = (GetAnimDuration(dict, name) * 1000) - 100
                        end

                        Wait(delay or 1000)
                    end

                    stopPropEffect(ptfx.handle)
                end)
            end)
        end
    end

    local progressProps = data.progressprops
    local beforeProps = {}

    if progressProps?.before then
        beforeProps = propSpawner.spawnProgressProps(progressProps.before)
    end

    if progress then
        success = lib.progressBar({
            label = progress.label or 'Melakukan sesuatu',
            duration = progress.duration or 2500,
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                combat = true,
                move = true
            },
            anim = progress.anim
        })
    end

    propSpawner.deleteProgressProps(beforeProps)

    local afterProps = {}

    if success and progressProps?.after then
        afterProps = propSpawner.spawnProgressProps(progressProps.after)
        Wait(progressProps.afterDuration or 1500)
        propSpawner.deleteProgressProps(afterProps)
    end

    stopPropEffect(ptfx.handle)
    ClearPedTasks(cache.ped)
    playerState.canEmote = true

    ls = auto
    ps[key] = success and 'success' or 'failed'

    local result = lib.callback.await('sidejobs:server:c', 1500, key, coords, menuIndex)

    if isProp and success and result and DoesEntityExist(entity) then
        local id = propSpawner.findIdByEntity(key, entity)

        if id then
            ox_target:removeLocalEntity(entity)
            propSpawner.remove(key, id, true)
        end
    end

    if ls and success and result then
        Wait(500)

        if isProp then
            local nearest, dist = propSpawner.findNearest(key)

            if nearest and dist then
                if dist > 2.0 then
                    local nc = GetEntityCoords(nearest)
                    local lastPos = GetEntityCoords(cache.ped)

                    local stuckTimer = 0
                    local retryCount = 0
                    local maxRetries = 3
                    local taskFailCount = 0
                    local maxTaskFail = 3

                    TaskGoToCoordAnyMeans(cache.ped, nc.x, nc.y, nc.z, WALK_SPEED, 0, false, 786603, 0xbf800000)

                    local walking = true

                    CreateThread(function()
                        while walking do
                            blockNavBreakingControls()
                            Wait(0)
                        end
                    end)

                    local function stopWalking()
                        walking = false
                    end

                    while true do
                        Wait(300)

                        if cache.vehicle or not ls or not propSpawner.isActive(key) then
                            stopWalking()
                            ClearPedTasks(cache.ped)
                            ls = false
                            ps[key] = nil
                            return false
                        end

                        if not DoesEntityExist(nearest) then
                            nearest, dist = propSpawner.findNearest(key)
                            if not nearest then
                                stopWalking()
                                break
                            end
                            nc = GetEntityCoords(nearest)
                            TaskGoToCoordAnyMeans(cache.ped, nc.x, nc.y, nc.z, WALK_SPEED, 0, false, 786603, 0xbf800000)
                            stuckTimer = 0
                            lastPos = GetEntityCoords(cache.ped)
                            taskFailCount = 0
                        end

                        local pc = GetEntityCoords(cache.ped)
                        local currentDist = #(pc - nc)

                        if currentDist <= 1.5 then
                            stopWalking()
                            ClearPedTasks(cache.ped)
                            break
                        end

                        if #(pc - lastPos) < 0.1 then
                            stuckTimer = stuckTimer + 300
                            
                            if stuckTimer > 2000 then
                                retryCount = retryCount + 1
                                
                                if retryCount >= maxRetries then
                                    local heading = GetHeadingFromVector_2d(nc.x - pc.x, nc.y - pc.y)
                                    local offset = vector3(
                                        nc.x - math.sin(math.rad(heading)) * 5.0,
                                        nc.y + math.cos(math.rad(heading)) * 5.0,
                                        nc.z
                                    )
                                    SetEntityCoords(cache.ped, offset.x, offset.y, offset.z, false, false, false, false)
                                    Wait(500)
                                end

                                ClearPedTasks(cache.ped)
                                Wait(100)

                                TaskGoToCoordAnyMeans(cache.ped, nc.x, nc.y, nc.z, WALK_SPEED, 0, false, 786603, 0xbf800000)
                                stuckTimer = 0
                            end
                        else
                            stuckTimer = 0
                            retryCount = 0
                            lastPos = pc
                        end

                        if not GetIsTaskActive(cache.ped, 224) and not GetIsTaskActive(cache.ped, 225) then
                            taskFailCount = taskFailCount + 1
                            
                            if taskFailCount >= maxTaskFail then
                                if currentDist > 2.0 then
                                    lib.notify({
                                        description = 'Auto harvest dibatalkan karena tidak bisa mencapai target',
                                        type = 'warning'
                                    })
                                    stopWalking()
                                    ls = false
                                    ps[key] = nil
                                    return false
                                else
                                    stopWalking()
                                    break
                                end
                            elseif currentDist > 2.0 then
                                TaskGoToCoordAnyMeans(cache.ped, nc.x, nc.y, nc.z, WALK_SPEED, 0, false, 786603, 0xbf800000)
                            end
                        else
                            taskFailCount = 0
                        end
                    end
                end

                if nearest and DoesEntityExist(nearest) then
                    local nc = GetEntityCoords(nearest)
                    TaskTurnPedToFaceCoord(cache.ped, nc.x, nc.y, nc.z, 1000)
                    Wait(1000)
                    return execute(key, data, true, nearest)
                end
            end
        else
            return execute(key, data, true)
        end
    end

    ls = false
    ps[key] = nil

    return success and result
end

local function openCraftMenu(key, data, entity)
    local menu = data.menu
    if not menu then return end

    local options = {}

    for i, opt in ipairs(menu) do
        options[#options + 1] = {
            title = opt.label,
            description = opt.description,
            icon = opt.icon,
            onSelect = function()
                execute(key, data, false, entity, i)
            end
        }
    end

    lib.registerContext({
        id = 'sidejob_craft_' .. key,
        title = data.label or 'Craft Menu',
        options = options
    })

    lib.showContext('sidejob_craft_' .. key)
end

local function setupOptions(key, data, entity)
    local isProp = entity ~= nil
    local menu = data.menu

    if menu then
        return {
            {
                label = data.label or 'Craft',
                icon = data.icon or 'fas fa-hammer',
                distance = data.distance or 2.0,
                onSelect = function(opts)
                    openCraftMenu(key, data, isProp and opts.entity or nil)
                end,
                canInteract = function()
                    return not ls and not IsPedInAnyVehicle(cache.ped, false)
                end
            }
        }
    end

    return {
        {
            label = data.label .. ' (Manual)',
            icon = data.icon or 'fas fa-circle-info',
            distance = data.distance or 2.0,
            onSelect = function(opts)
                execute(key, data, false, isProp and opts.entity or nil)
            end,
            canInteract = function()
                return not ls and not IsPedInAnyVehicle(cache.ped, false)
            end
        },
        {
            label = data.label .. ' (Automatic)',
            icon = data.icon or 'fas fa-circle-info',
            distance = data.distance or 2.0,
            onSelect = function(opts)
                execute(key, data, true, isProp and opts.entity or nil)
            end,
            canInteract = function()
                return not ls and not IsPedInAnyVehicle(cache.ped, false)
            end
        }
    }
end

local function setupProp(key, data)
    local prop = data.prop
    local options = setupOptions(key, data, true)
    local positions = prop.positions

    local pts = lib.points.new(prop.coords.xyz, prop.distance + 50)

    function pts:spawnAll()
        propSpawner.activate(key)

        local maxSpawn = positions and #positions or (prop.max_spawn or 15)

        local spawnData = {
            key = key,
            model = prop.model,
            coords = prop.coords,
            positions = positions,
            maxSpawn = maxSpawn,
            distance = prop.distance or 20,
            minDistance = prop.gap,
            respawnTime = prop.respawn_time or 5,
            indoor = prop.indoor,
            onSpawn = function(_, entity)
                if propSpawner.isActive(key) then
                    ox_target:addLocalEntity(entity, options)
                end
            end
        }

        for i = 1, maxSpawn do
            if not propSpawner.isActive(key) then break end

            local _, ent = propSpawner.spawn(spawnData, positions and i or nil)

            if positions then
                Wait(50)
            else
                if not ent then break end
                Wait(150)
            end
        end
    end

    function pts:onEnter()
        self:spawnAll()
    end

    function pts:onExit()
        ls = false
        ps[key] = nil
        propSpawner.deactivate(key)
    end
end

local function setupPoints(key, data)
    local point = data.point
    local coords = point.coords
    local coordsType = type(coords)
    local coordsList = (coordsType == 'vector3' or coordsType == 'vector4') and { coords } or coords

    for _, c in ipairs(coordsList) do
        local pts = lib.points.new(c.xyz, point.distance or 2.0)
        pts.key = key
        pts.data = data
        pts.label = point.label or data.label or 'Interact'
        pts.showingUI = false

        function pts:onEnter()
            if ls or IsPedInAnyVehicle(cache.ped, false) then return end
            self.showingUI = true
            lib.showTextUI(('[E] %s'):format(self.label), {
                icon = point.icon or 'fas fa-hand'
            })
        end

        function pts:onExit()
            if self.showingUI then
                self.showingUI = false
                lib.hideTextUI()
            end
        end

        function pts:nearby()
            if ls or IsPedInAnyVehicle(cache.ped, false) then
                if self.showingUI then
                    self.showingUI = false
                    lib.hideTextUI()
                end
                return
            end

            if not self.showingUI then
                self.showingUI = true
                lib.showTextUI(('[E] %s'):format(self.label), {
                    icon = point.icon or 'fas fa-hand'
                })
            end

            if IsControlJustPressed(0, point.control or 38) then
                lib.hideTextUI()
                self.showingUI = false

                if data.menu then
                    openCraftMenu(self.key, self.data)
                else
                    execute(self.key, self.data, false)
                end
            end
        end
    end
end

local function setupTarget(key, data)
    local target = data.target
    local typeCoords = type(target.coords)

    if typeCoords == 'vector3' or typeCoords == 'vector4' then
        target.coords = { target.coords }
    end

    if target.model and #target.coords > 0 then
        local coords = target.coords
        
        array.forEach(coords, function (c)
            local iterData = tbl.deepclone(data)
            iterData.coords = c
            local options = setupOptions(key, iterData)

            local pts = lib.points.new(c.xyz, target.renderDistance or (target.distance * 2))

            function pts:clear()
                local currentEntity = cacheEntities[self.coords]
                if not (currentEntity and DoesEntityExist(currentEntity)) then
                    return
                end

                ox_target:removeLocalEntity(currentEntity)
                pcall(DeleteEntity, currentEntity)
                cacheEntities[self.coords] = nil
            end

            function pts:onEnter()
                local model = utils.loadModel(target.model)
                if not model then return end

                self:clear()
                Wait(100)

                local currentEntity = CreateObject(model, c.x, c.y, c.z, false, false, false)

                SetEntityHeading(currentEntity, c.w or 0.0)
                FreezeEntityPosition(currentEntity, true)
                PlaceObjectOnGroundProperly(currentEntity)
                SetEntityProofs(currentEntity, true, true, true, true, true, true, true, true)

                ox_target:addLocalEntity(currentEntity, options)
                cacheEntities[self.coords] = currentEntity
            end

            function pts:onExit()
                ps[key] = nil
                self:clear()
            end
        end)

    elseif #target.coords > 0 then
        array.forEach(target.coords, function (c)
            local iterData = tbl.deepclone(data)
            iterData.coords = c
            local options = setupOptions(key, iterData)

            ox_target:addSphereZone({
                coords = c.xyz,
                radius = target.radius or 1.5,
                options = options
            })
        end)
    end
end

local function setUp(group, id, value)
    local key = ('%s:%s'):format(group, id)

    local target = value.target
    local prop = value.prop
    local point = value.points
    local blip = value.blip
    local items = value.items
    local menu = value.menu
    local progressbar = value.progressbar
    local progressprops = value.progressprops

    local data = {
        label = prop?.label or target?.label or point?.label or 'Interact',
        icon = prop?.icon or target?.icon or point?.icon,
        distance = prop?.interactDistance or target?.distance or point?.distance or 2.0,
        requiredWeapon = prop?.requiredWeapon or target?.requiredWeapon or point?.requiredWeapon,
        busyCheck = prop?.busyCheck or target?.busyCheck or point?.busyCheck,
        coords = target?.coords or point?.coords,
        items = items,
        menu = menu,
        progressbar = progressbar,
        progressprops = progressprops,
        target = target,
        prop = prop,
        point = point
    }

    if blip then
        utils.createBlip(blip, group)
    end

    if prop then
        setupProp(key, data)
    elseif target then
        setupTarget(key, data)
    elseif point then
        setupPoints(key, data)
    end
end

lib.callback.register('sidejobs:client:g', function(key)
    return ps[key]
end)

CreateThread(function()
    while not playerState.isLoggedIn do
        Wait(100)
    end

    for group, jobs in pairs(config) do
        for id, value in pairs(jobs) do
            setUp(group, id, value)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for k, v in pairs(cacheEntities) do
            if v and DoesEntityExist(v) then
                ox_target:removeLocalEntity(v)
                pcall(DeleteEntity, v)
            end
        end
    end
end)

lib.addKeybind({
    name = 'cancel_auto_work',
    description = 'Tekan X untuk batalkan auto kerja',
    defaultKey = 'X',
    onPressed = function(self)
        ls = false
    end,
})

-- RegisterCommand('placeobj', function (_, args)
--     placer.start('prop_boxpile_05a', true)
-- end, false)