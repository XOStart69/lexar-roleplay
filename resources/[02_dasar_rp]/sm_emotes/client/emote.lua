---@class EmoteState
local state = {
    curentTexture = nil,
    threadStatus = false,
    emoteCanPlay = false,
    canCancel = true,
    inExitEmote = false,
    exitAndPlay = false,
    cooldownTime = nil,
    openingDoor = false
}

local emoteClient = {}
local config = require 'config.client'
local emote_exits = require 'data.emotes'.exits

local function isCooldown()
    local gameTimer = GetGameTimer()

    if state.cooldownTime and (gameTimer - state.cooldownTime) < 800 then
        return true
    end

    state.cooldownTime = gameTimer

    return false
end

local function runAnimationThread()
    if state.threadStatus then
        return
    end

    state.threadStatus = true

    CreateThread(function()
        local sleep
        while state.threadStatus and PState.isInAnimation do
            sleep = 500

            if PState.isInAnimation then
                sleep = 0

                if utils.isAiming() then
                    emoteClient.emoteCancel()
                end

                if config.disarmPlayerOnEmote and cache.weapon then
                    TriggerEvent('ox_inventory:disarm', true)
                end

                if not config.allowPunchDurringEmote then
                    DisableControlAction(2, 140, true)
                    DisableControlAction(2, 141, true)
                    DisableControlAction(2, 142, true)
                end
            end

            Wait(sleep)
        end
    end)
end

local function checkStatusThread(dict, anim)
    CreateThread(function()
        local timeout = 0
        local maxTimeout = 100

        while not IsEntityPlayingAnim(cache.ped, dict, anim, 3) and timeout < maxTimeout do
            Wait(100)
            timeout = timeout + 1
        end

        if timeout >= maxTimeout then
            if PState.isInAnimation then
                PState:set('isInAnimation', false, false)
            end
            state.threadStatus = false
            return
        end

        while state.threadStatus and PState.isInAnimation do
            if not state.openingDoor and not state.inExitEmote and not IsEntityPlayingAnim(cache.ped, dict, anim, 3) then
                PState:set('emote_prop', nil, true)
                emoteClient.emoteCancel()
                break
            end
            Wait(100)
        end
    end)
end

local function playScenario(emoteData)
    PState:set('emote_prop', nil, true)
    ClearPedTasks(cache.ped)

    local scenario, scenarioType in emoteData

    ---@cast scenarioType ScenarioType
    ---@cast scenario string
    if scenarioType == ScenarioType.MALE then
        if utils.isMale() then
            TaskStartScenarioInPlace(cache.ped, scenario, 0, true)
        else
            emoteClient.emoteCancel()
            lib.notify({ description = 'Hanya untuk karakter laki-laki', type = 'error' })
            return
        end
    elseif scenarioType == ScenarioType.OBJECT then
        local behindPlayer = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, -0.5, -0.5)
        TaskStartScenarioAtPosition(cache.ped, scenario, behindPlayer.x, behindPlayer.y, behindPlayer.z, GetEntityHeading(cache.ped), 0, true, false)
    else
        TaskStartScenarioInPlace(cache.ped, scenario, 0, true)
    end

    PState:set('isInAnimation', true, false)
end

---@param emote CacheEmote
---@param textureVariation? number
local function playExitAndEnterEmote(emote, textureVariation)
    local currentEmote = PState.currentEmote
    local emote_data = utils.getEmote(currentEmote)

    if not emote_data then
        return emoteClient.emoteCancel()
    end

    if not state.canCancel then
        return
    end

    PState.canEmote = false
    state.exitAndPlay = true
    utils.cancelScenario()
    emoteClient.emoteCancel()
    DetachEntity(cache.ped, true, false)

    Wait(500)

    if emote_data?.AnimationOptions?.ExitEmote then
        local AnimationOptions in emote_data

        ---@cast AnimationOptions AnimationOptions
        local exitData = emote_exits[AnimationOptions.ExitEmote] ---@type CacheEmote

        if not exitData then
            Wait(100)
            PState.canEmote = true
            state.exitAndPlay = false
            emoteClient.play(emote, textureVariation)
            return
        end

        local options = exitData.AnimationOptions

        if options and options?.EmoteDuration then
            state.inExitEmote = true
            SetTimeout(options.EmoteDuration, function()
                Wait(100)
                state.inExitEmote = false
                state.exitAndPlay = false
            PState.canEmote = true
                emoteClient.play(emote, textureVariation)
            end)
            return
        end
        
        emoteClient.play(exitData, nil)
    end

    Wait(100)
    state.exitAndPlay = false
            PState.canEmote = true
    emoteClient.play(emote, textureVariation)
end

---@param emote CacheEmote
---@param variation? number
---@param check? boolean
---@param isExitEmote? boolean
function emoteClient.play(emote, variation, check, isExitEmote)
    if not emote then return end

    if not isExitEmote then
        if PState.isdead or utils.isDead() then
            return lib.notify({
                description = 'Tidak bisa melakukan emote saat ini', type = 'error'
            })
        end

        if utils.isCuffed() then
            return
        end

        if not PState.canEmote then
            lib.notify({ description = 'Tidak bisa melakukan emote saat ini', type = 'error'})
            return
        end

        if (check and isCooldown()) or state.exitAndPlay then
            return lib.notify({ description = 'Emote cooldown', type = 'error' })
        end

        if state.inExitEmote then
            return false
        end

        if config.cancelPreviousEmote and PState.isInAnimation and not state.exitAndPlay and not state.inExitEmote then
            playExitAndEnterEmote(emote, variation)
            return
        end
    end

    if not DoesEntityExist(cache.ped) then
        return false
    end

    utils.clearScenarioObject()

    if not isExitEmote then
        if not config.allowEmoteInVehicle and cache.vehicle then return end
        if config.adultEmotesDisabled and emote.AdultAnimation then return end
    end

    if PState.isInAnimation then
        PState:set('isInAnimation', false, false)
        state.threadStatus = false
    end

    local animOption = emote.AnimationOptions
    if animOption then
        if cache.vehicle and animOption.NotInVehicle then
            return lib.notify({ description = 'Tidak bisa digunakan di dalam kendaraan', type = 'error' })
        elseif not cache.vehicle and animOption.onlyInVehicle then
            return lib.notify({ description = 'Hanya bisa digunakan di dalam kendaraan', type = 'error' })
        end
    end

    state.curentTexture = variation
    PState:set('currentEmote', emote.command, true)

    if config.disarmPlayerOnEmote and cache.weapon then
        TriggerEvent('ox_inventory:disarm', true)
    end

    if animOption and animOption.Prop then
        PState:set('emote_prop', nil, true)
    end

    if emote.scenario then
        if not cache.vehicle then
            playScenario(emote)
        end
        return
    end

    if animOption and animOption.StartDelay then
        Wait(animOption.StartDelay)
    end

    if not lib.requestAnimDict(emote.dict) then
        return
    end

    local movementType = 0

    if cache.vehicle then
        if animOption and animOption.FullBody then
            movementType = 35
        else
            movementType = 51
        end
    elseif animOption and animOption.onFootFlag then
        movementType = animOption.onFootFlag
    end

    local ptfxData = {}

    if animOption and animOption.PtfxAsset then
        local Ptfx1, Ptfx2, Ptfx3, Ptfx4, Ptfx5, Ptfx6, PtfxScale = table.unpack(animOption.PtfxPlacement)

        PState:set('ptfxPrompt', {
            canHold = animOption.PtfxCanHold,
            holdTime = animOption.PtfxWait
        }, false)

        local PtfxAsset, PtfxName, PtfxBone, PtfxColor in animOption

        ptfxData = {
            asset = PtfxAsset,
            name = PtfxName,
            bone = PtfxBone,
            color = PtfxColor,
            offset = vector3(Ptfx1, Ptfx2, Ptfx3),
            rotation = vector3(Ptfx4, Ptfx5, Ptfx6),
            scale = PtfxScale
        }

        PState:set('ptfxData', ptfxData, true)
    else
        PState:set('ptfxPrompt', nil, false)
    end

    if IsPedUsingAnyScenario(cache.ped) or IsPedActiveInScenario(cache.ped) then
        ClearPedTasksImmediately(cache.ped)
    end

    PState:set('isInAnimation', true, false)
    runAnimationThread()

    if emote.Advanced then
        local coords, heading in emote.Advanced
        TaskPlayAnimAdvanced(
            cache.ped, emote.dict, emote.anim,
            coords.x, coords.y, coords.z, 0, 0, heading,
            animOption?.BlendInSpeed or 5.0,
            animOption?.BlendOutSpeed or 5.0,
            animOption?.EmoteDuration or -1,
            animOption?.Flag or movementType or 0,
            1.0, false, false
        )
    else
        lib.playAnim(
            cache.ped, emote.dict, emote.anim,
            animOption?.BlendInSpeed or 5.0,
            animOption?.BlendOutSpeed or 5.0,
            animOption?.EmoteDuration or -1,
            animOption?.Flag or movementType or 0,
            0, false, false, false
        )
    end

    RemoveAnimDict(emote.dict)

    checkStatusThread(emote.dict, emote.anim)

    if animOption and animOption.Prop then
        local propData = { emote = emote.command, variant = variation}
        PState:set('emote_prop', propData, true)

        if animOption.PtfxAsset and not animOption.PtfxNoProp then
            ptfxData.prop = true
            PState:set('ptfxData', ptfxData, true)
        end
    end
end

function emoteClient.emoteCancel(force)
    local inReloading = IsPedReloading(cache.ped)

    if inReloading or state.inExitEmote then
        return
    end

    state.emoteCanPlay = true

    if type(force) ~= 'boolean' then force = false end

    if not force then
        if PState.isdead or (utils and utils.isDead and utils.isDead()) or IsEntityDead(cache.ped) or GetEntityHealth(cache.ped) <= 0 then
            state.inExitEmote = false
            return
        end
        local ok, isCuffed = pcall(function() return exports.sm_policejob:IsHandcuffed() end)
        if ok and isCuffed then
            state.inExitEmote = false
            return
        end
    end

    local currentEmote = PState.currentEmote
    local isInAnimation = PState.isInAnimation

    if not currentEmote then
        if PState.isInAnimation then
            PState:set('isInAnimation', false, false)
        end

        state.inExitEmote = false
        state.threadStatus = false

        props.clearFromPed(cache.ped)
        props.clearLocal()
        
        if PState.emote_prop then
            PState:set('emote_prop', nil, true)
        end

        ClearPedTasks(cache.ped)
        utils.clearScenarioObject()
        return
    end

    local emote_data = utils.getEmote(currentEmote)

    if not emote_data then
        if PState.isInAnimation then
            PState:set('isInAnimation', false, false)
        end

        state.inExitEmote = false
        state.threadStatus = false

        props.clearFromPed(cache.ped)
        props.clearLocal()
        
        if PState.emote_prop then
            PState:set('emote_prop', nil, true)
        end

        ClearPedTasks(cache.ped)
        utils.clearScenarioObject()
        return
    end

    if state.inExitEmote and force then
        state.inExitEmote = false
        state.threadStatus = false
        if PState.isInAnimation then
            PState:set('isInAnimation', false, false)
        end

        props.clearFromPed(cache.ped)
        props.clearLocal()
        
        if PState.emote_prop then
            PState:set('emote_prop', nil, true)
        end
        if PState.ptfxPrompt then
            PState:set('ptfxPrompt', nil, false)
        end
        if PState.emote_ptfx then
            PState:set('emote_ptfx', nil, true)
        end

        ClearPedTasks(cache.ped)
    elseif state.inExitEmote then
        return
    end

    if not state.canCancel and not force then
        return
    end

    local AnimationOptions = emote_data.AnimationOptions

    utils.cancelScenario()

    if isInAnimation then
        props.clearFromPed(cache.ped)
        props.clearLocal()
        
        DetachEntity(cache.ped, true, false)

        if AnimationOptions?.ExitEmote then
            local exitData = emote_exits[AnimationOptions.ExitEmote]
            local animationOptions = exitData?.AnimationOptions

            if not exitData then
                ClearPedTasks(cache.ped)
                lib.print.warn("Exit emote was invalid")
            else
                state.threadStatus = false
                if PState.isInAnimation then
                    PState:set('isInAnimation', false, false)
                end
                if PState.currentEmote then
                    PState:set('currentEmote', nil, true)
                end

                if PState.emote_prop then
                    PState:set('emote_prop', nil, true)
                end
                if PState.ptfxPrompt then
                    PState:set('ptfxPrompt', nil, false)
                end
                if PState.emote_ptfx then
                    PState:set('emote_ptfx', nil, true)
                end

                state.inExitEmote = true
                emoteClient.play(exitData, nil, false, true)

                if animationOptions and animationOptions.EmoteDuration then
                    SetTimeout(animationOptions.EmoteDuration, function()
                        props.clearFromPed(cache.ped)
                        props.clearLocal()
                        ClearPedTasks(cache.ped)
                        state.inExitEmote = false
                        state.emoteCanPlay = false

                        if PState.isInAnimation then
                            PState:set('isInAnimation', false, false)
                        end
                        state.threadStatus = false
                    end)
                    return
                else
                    SetTimeout(100, function()
                        state.inExitEmote = false
                    end)
                end
                return
            end
        else
            ClearPedTasks(cache.ped)
            state.inExitEmote = false
            state.emoteCanPlay = false
        end
    end

    state.threadStatus = false

    if PState.isInAnimation then
        PState:set('isInAnimation', false, false)
    end

    if PState.ptfxPrompt then PState:set('ptfxPrompt', nil, false) end
    if PState.currentEmote then PState:set('currentEmote', nil, true) end
    if PState.targetAnim then PState:set('targetAnim', nil, true) end
    if PState.emote_ptfx then PState:set('emote_ptfx', nil, true) end
    if PState.inSharedEmote then PState:set('inSharedEmote', nil, true) end
    if PState.emote_prop then PState:set('emote_prop', nil, true) end

    utils.clearScenarioObject()
end

function emoteClient.playFromMenu(name, textureVariation)
    if utils.isInInvalidActionState() then
        return
    end

    local emote_data = utils.getEmote(name)

    if not emote_data then
        lib.notify({ description = 'Emote tidak valid', type = 'error'})
        return
    end

    local category in emote_data

    ---@cast category cache_category
    if category == 'expressions' then
        return expression.set(name, true)
    elseif category == 'walks' then
        return walkstyle.set(name, true)
    elseif category == 'animalemotes' then
        if not utils.isValidAnimals(name) then
            return lib.notify({ description = 'Pet tidak valid untuk emote ini', type = 'error' })
        end

        return emoteClient.play(name, nil, true)
    end

    if emote_data.secondPlayersAnim then
        local coords = GetEntityCoords(cache.ped)
        local player = lib.getClosestPlayer(coords, 3.0)

        if not player then
            return lib.notify({
                description = 'Tidak ada pemain di sekitar kamu!',
                type = 'error'
            })
        end

        local serverId = GetPlayerServerId(player)
        TriggerServerEvent("sm_emote:server:requestShared", serverId, name)
        return
    end

    emoteClient.play(emote_data, textureVariation, true)
end

function emoteClient.emoteCommandStart(args)
    if #args <= 0 then return end

    if utils.isInInvalidActionState() then
        return
    end

    local name = args[1]:lower()

    if name == "c" and PState.isInAnimation then
        if PState.isInAnimation then
            emoteClient.emoteCancel()
        else
            lib.notify({
                description = 'Tidak ada emote yang aktif'
            })
        end
        return
    end

    local emoteData = utils.getEmote(name)

    if not emoteData then
        lib.notify({ description = 'Emote tidak valid', type = 'error'})
        return
    end

    emoteClient.playFromMenu(name, emoteData?.AnimationOptions?.PropTextureVariations)
end


local fun = {
    play = emoteClient.play,
    playFromMenu = emoteClient.playFromMenu,
    cancel = emoteClient.emoteCancel
}

_ENV.Emote = setmetatable({}, {
    __index = fun,
    __newindex = function()
        error('Emote table is read-only', 2)
    end,
    __metatable = false
})

RegisterNetEvent('animations:client:EmoteCommandStart', function(args)
    emoteClient.emoteCommandStart(args)
end)

exportWrapper("EmoteCommandStart", function(emoteName, textureVariation)
    emoteClient.emoteCommandStart({ emoteName, textureVariation })
end)

exportWrapper("EmoteCancel", function(force)
    emoteClient.emoteCancel(force)
end)

exportWrapper("CanCancelEmote", function(value)
    state.canCancel = value == true
end)

exportWrapper('IsPlayerInAnim', function()
    return PState.currentEmote
end)

exportWrapper('getCurrentEmote', function()
    return {}
end)

AddEventHandler('CEventOpenDoor', function(unk1)
    if unk1[1] ~= cache.ped then return end

    if not PState.isInAnimation then
        return
    end

    if state.openingDoor then
        return
    end

    state.openingDoor = true

    while IsPedOpeningADoor(cache.ped) do
        Wait(100)
    end

    Wait(1500)
    state.openingDoor = false

    local emote = PState.currentEmote
    local emote_data = utils.getEmote(emote)

    if emote_data then
        if not emote_data?.secondPlayersAnim then
            emoteClient.emoteCancel()
            Wait(200)

            if not emote_data then
                return
            end

            emoteClient.play(emote_data, state.curentTexture)
        else

        local movementType = 0

        if cache.vehicle then
            if emote_data?.AnimationOptions and emote_data?.AnimationOptions.FullBody then
                movementType = 35
            else
                movementType = 51
            end
        elseif emote_data?.AnimationOptions and emote_data?.AnimationOptions.onFootFlag then
            movementType = emote_data?.AnimationOptions.onFootFlag
        end

            lib.playAnim(
                cache.ped, emote_data.dict, emote_data.anim,
                emote_data?.AnimationOptions?.BlendInSpeed or 5.0,
                emote_data?.AnimationOptions?.BlendOutSpeed or 5.0,
                emote_data?.AnimationOptions?.EmoteDuration or -1,
                emote_data?.AnimationOptions?.Flag or movementType or 0,
                0, false, false, false
            )
        end
    end

end)


exportWrapper("getEmoteByCommand", function(name)
    if not name then return nil end
    return utils.getEmote(name)
end)