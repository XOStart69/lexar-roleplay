
local polygon = {
    points = {
        vec3(954.47998046875, 32.189998626709, 60.0),
        vec3(956.32000732422, 31.10000038147, 60.0),
        vec3(985.85998535156, 12.880000114441, 60.0),
        vec3(978.35998535156, 0.86000001430511, 60.0),
        vec3(939.5, 25.879999160767, 60.0),
        vec3(939.44000244141, 25.709999084473, 60.0),
        vec3(940.54998779297, 25.030000686646, 60.0),
        vec3(938.04998779297, 21.049999237061, 60.0),
        vec3(931.34002685547, 25.239999771118, 60.0),
        vec3(931.03997802734, 25.440000534058, 60.0),
        vec3(930.38000488281, 24.459999084473, 60.0),
        vec3(923.77001953125, 28.75, 60.0),
        vec3(927.08001708984, 33.840000152588, 60.0),
        vec3(915.04998779297, 40.75, 60.0),
        vec3(916.53002929688, 42.919998168945, 60.0),
        vec3(889.07000732422, 60.180000305176, 60.0),
        vec3(888.09002685547, 84.75, 60.0),
        vec3(900.47998046875, 100.55999755859, 60.0),
        vec3(922.46997070312, 100.44000244141, 60.0),
        vec3(950.89001464844, 82.050003051758, 60.0),
        vec3(965.83001708984, 70.839996337891, 60.0),
        vec3(969.46002197266, 73.099998474121, 60.0),
        vec3(975.25, 68.610000610352, 60.0),
        vec3(989.09997558594, 74.25, 60.0),
        vec3(995.71002197266, 72.080001831055, 60.0),
        vec3(1005.0200195312, 67.48999786377, 60.0),
        vec3(1010.1699829102, 59.569999694824, 60.0),
        vec3(1012.5399780273, 46.540000915527, 60.0),
        vec3(1005.1099853516, 33.0, 60.0),
        vec3(994.71997070312, 26.719999313354, 60.0),
        vec3(977.59997558594, 30.020000457764, 60.0),
        vec3(960.25, 42.959999084473, 60.0),
        vec3(956.01000976562, 37.0, 60.0),
    },
    thickness = 7.05,
}

local valutBucket = os.time() + 60

local cacheBucket = {}
local valutZones = lib.zones.poly(polygon)

local function resetRoutingBucket(source)
    if not cacheBucket[source] then
        return
    end
    cacheBucket[source] = nil
    SetPlayerRoutingBucket(source, 0)
    lib.print.info(('Player %s left casino vault and reset bucket'):format(source))
end

local function setPlayerBucket(source)
    cacheBucket[source] = valutBucket
    SetPlayerRoutingBucket(source, valutBucket)
    lib.print.info(('Player %s entered casino vault with bucket %s'):format(source, valutBucket))
end

RegisterNetEvent('rhd_casino:onRoom', function (roomName)
    local source = source
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local casinoContains = shared.casinoBigZone:contains(playerCoords) and valutZones:contains(playerCoords)

    if not casinoContains then
        return resetRoutingBucket(source)
    end

    setPlayerBucket(source)
end)