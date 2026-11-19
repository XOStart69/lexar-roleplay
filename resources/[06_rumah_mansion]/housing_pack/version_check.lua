--[[
    housing_pack :: version_check
    Shell pack Fury. Pengecekan versi ringan tanpa dependency.
    URL remote opsional lewat convar housing_pack_version_url.
]]

local RESOURCE = GetCurrentResourceName()
local VERSION  = '1.0.0'

local function parseVersion(v)
    local a, b, c = (v or ''):match('^(%d+)%.(%d+)%.(%d+)')
    return tonumber(a) or 0, tonumber(b) or 0, tonumber(c) or 0
end

local function isNewer(latest, current)
    local a1, b1, c1 = parseVersion(latest)
    local a2, b2, c2 = parseVersion(current)
    if a1 ~= a2 then return a1 > a2 end
    if b1 ~= b2 then return b1 > b2 end
    return c1 > c2
end

local function report(latest)
    if not latest or latest == '' then return end
    if isNewer(latest, VERSION) then
        print(('^3[%s] versi baru tersedia: %s (terpasang %s)^7'):format(RESOURCE, latest, VERSION))
    else
        print(('^2[%s] versi terpasang terbaru (%s)^7'):format(RESOURCE, VERSION))
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= RESOURCE then return end
    local url = GetConvar('housing_pack_version_url', '')
    if url == '' then
        print(('^2[%s] v%s siap, version check offline^7'):format(RESOURCE, VERSION))
        return
    end
    PerformHttpRequest(url, function(status, body)
        if status ~= 200 or not body then
            print(('^3[%s] version check gagal (HTTP %s)^7'):format(RESOURCE, status or 'nil'))
            return
        end
        report(body:match('%d+%.%d+%.%d+'))
    end, 'GET')
end)

exports('GetVersion', function() return VERSION end)