local function getNearbyDevices()
    local devices = {}
    local players = GetNearbyPlayers()
    local myCoords = GetEntityCoords(PlayerPedId())

    debugprint("Nearby players:", players)

    for i = 1, #players do
        local player = players[i]
        local state = Player(player.source).state
        local distance = #(myCoords - GetEntityCoords(player.ped))

        if distance > 7.5 then
            debugprint("Player is too far away", player.source)
        else
            debugprint("Player data", player.source, player)

            if state.lbTabletOpen then
                debugprint("Player has tablet open", player.source)
                devices[#devices + 1] = {
                    name = state.lbTabletName or "??",
                    source = player.source,
                    device = "tablet"
                }
            elseif state.phoneOpen then
                debugprint("Player has phone open", player.source)
                devices[#devices + 1] = {
                    name = state.phoneName or "??",
                    source = player.source,
                    device = "phone"
                }
            else
                debugprint("Player has no device open", player.source)
            end
        end
    end

    debugprint("Nearby devices:", devices)
    return devices
end

RegisterNUICallback("AirShare", function(data, cb)
    if not currentPhone then
        return
    end

    local action = data.action
    debugprint("AirShare:" .. (action or ""))

    if action == "getNearby" then
        cb(getNearbyDevices())
    elseif action == "share" then
        TriggerCallback("airShare:share", cb, data.source, data.device, data.data)
    elseif action == "accept" then
        TriggerServerEvent("phone:airShare:interacted", data.source, data.device, true)
        cb("ok")
    elseif action == "deny" then
        TriggerServerEvent("phone:airShare:interacted", data.source, data.device, false)
        cb("ok")
    end
end)

RegisterNetEvent("phone:airShare:received", function(data)
    debugprint("phone:airShare:received", data)
    SendNUIAction("airShare:received", data)
end)

RegisterNetEvent("phone:airShare:interacted", function(source, accepted)
    SendNUIAction("airShare:interacted", {
        source = source,
        accepted = accepted
    })
end)
