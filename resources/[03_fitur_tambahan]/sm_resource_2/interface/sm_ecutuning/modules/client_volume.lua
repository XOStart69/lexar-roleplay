local VOL = {
    applied = {},
    scenes  = {},
    range   = 120.0,
    maxIdx  = 10,
}

local function sceneName(n) return n < 0 and ('hrs_vol_qscene_' .. -n) or ('hrs_vol_scene_' .. n) end
local function groupName(n) return n < 0 and ('hrs_vol_qgroup_' .. -n) or ('hrs_vol_group_' .. n) end
HRS_ValveLocal = 0

function HRS_ValveClosed()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return false end
    local st = Entity(veh).state.hrsValve
    if st == nil and not NetworkGetEntityIsNetworked(veh) then st = HRS_ValveLocal end
    return st == 1
end

local function ensureScene(n)
    local sc = sceneName(n)
    if not IsAudioSceneActive(sc) then
        if not StartAudioScene(sc) then
            print(('^1[Debug EcuTuning]^7 engine volume scene %s missing, reconnect once after update.'):format(sc))
            return false
        end
    end
    SetAudioSceneVariable(sc, 'apply', 1.0)
    VOL.scenes[n] = true
    return true
end

local function applyTo(veh, n)
    local alt = VOL.applied[veh] or 0
    if alt == n then return end
    if alt ~= 0 then RemoveEntityFromAudioMixGroup(veh, 0.0) end
    if n ~= 0 and ensureScene(n) then
        AddEntityToAudioMixGroup(veh, groupName(n), 0.0)
    end
    VOL.applied[veh] = (n ~= 0) and n or nil
end

local function levelOf(veh, myVeh)
    local st = Entity(veh).state
    local mine = (veh == myVeh)
    if not mine and not HRS_HearOthers() then return 0 end
    local n = st.hrsVol
    local closed = st.hrsValve
    if mine and not NetworkGetEntityIsNetworked(veh) then
        if n == nil and HRS_MyEngineVol then local _, i = HRS_EngVolSnap(HRS_MyEngineVol() or 0) n = i end
        if closed == nil then closed = HRS_ValveLocal end
    end
    n = tonumber(n) or 0
    if n < 0 or n > VOL.maxIdx then n = 0 end
    if closed == 1 and n > 0 then
        local q = math.floor(-((ECUConfig.EngineVolume or {}).closed or 0) / 10 + 0.5)
        if q < 0 then q = 0 end
        if q > 5 then q = 5 end
        return -q
    end
    return n
end

CreateThread(function()
    while true do
        Wait(500)
        if (ECUConfig.EngineVolume or {}).enabled == false then
            Wait(5000)
        else
            local ped  = PlayerPedId()
            local me   = GetEntityCoords(ped)
            local myV  = GetVehiclePedIsIn(ped, false)
            local seen = {}
            for _, veh in ipairs(GetGamePool('CVehicle')) do
                if #(GetEntityCoords(veh) - me) < VOL.range then
                    applyTo(veh, levelOf(veh, myV))
                    seen[veh] = true
                end
            end
            for veh in pairs(VOL.applied) do
                if not seen[veh] then
                    if DoesEntityExist(veh) then RemoveEntityFromAudioMixGroup(veh, 0.0) end
                    VOL.applied[veh] = nil
                end
            end
        end
    end
end)


AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for veh in pairs(VOL.applied) do
        if DoesEntityExist(veh) then RemoveEntityFromAudioMixGroup(veh, 0.0) end
    end
    for n in pairs(VOL.scenes) do StopAudioScene(sceneName(n)) end
end)
