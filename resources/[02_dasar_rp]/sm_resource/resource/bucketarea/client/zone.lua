local zoneConfig = localmodule 'config.zones'
local sharedConfig = localmodule 'config.shared'

local zones = {}

CreateThread(function ()
    local debug = sharedConfig.debug

    for k, v in pairs(zoneConfig) do
        local zone

        if debug then
            v.zone.debug = true
        end

        if v.type == 'poly' then
            zone = lib.zones.poly(v.zone)
        elseif v.type == 'sphere' then
            zone = lib.zones.sphere(v.zone)
        elseif v.type == 'box' then
            zone = lib.zones.box(v.zone)
        end

        function zone:onEnter()
            if not playerState.isLoggedIn then return end
            TriggerServerEvent('rhd_bucketArea:oczn', k)
        end

        function zone:onExit()
            if not playerState.isLoggedIn then return end
            TriggerServerEvent('rhd_bucketArea:oczn', false)
        end

        zones[k] = zone
    end
end)