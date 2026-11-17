local releasedForDeath = false

local function isDead()
    return playerState.isdead or IsEntityDead(cache.ped)
end

local function releaseCasinoSeat()
    if releasedForDeath or not isDead() then return end

    releasedForDeath = true
    TriggerServerEvent('rhd_casino:server:releasePlayer', 'death')
    TriggerEvent('rhd_casino:client:forceLeave', 'death')
end

local function refreshDeathState()
    if isDead() then
        releaseCasinoSeat()
    else
        releasedForDeath = false
    end
end

local playerBag = ('player:%s'):format(GetPlayerServerId(PlayerId()))

AddStateBagChangeHandler('isdead', playerBag, function ()
    SetTimeout(5, refreshDeathState)
end)

AddEventHandler('baseevents:onPlayerDied', releaseCasinoSeat)
AddEventHandler('baseevents:onPlayerKilled', releaseCasinoSeat)

AddEventHandler('gameEventTriggered', function(eventName, args)
    if eventName ~= 'CEventNetworkEntityDamage' or args[1] ~= cache.ped then return end
    SetTimeout(0, releaseCasinoSeat)
end)

AddEventHandler('playerSpawned', function()
    releasedForDeath = false
end)
