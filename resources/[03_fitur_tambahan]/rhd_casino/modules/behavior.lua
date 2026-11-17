local inCasinoArea = false

CreateThread(function()
    while true do
        local sleep = 1000

        if inCasinoArea and playerState.isLoggedIn then
            -- DisableControlAction(0, 22, true)   -- SPACE / loncat
            DisableControlAction(0, 44, true)   -- ragdoll

            DisableControlAction(0, 140, true)  -- melee attack ringan
            DisableControlAction(0, 141, true)  -- melee attack berat
            DisableControlAction(0, 142, true)  -- melee attack alternatif
            DisableControlAction(0, 143, true)  -- melee block

            DisableControlAction(0, 25, true)   -- aim (klik kanan)
            DisableControlAction(0, 24, true)   -- attack (klik kiri)
            DisableControlAction(0, 257, true)  -- attack 2
            DisableControlAction(0, 263, true)  -- melee attack 1
            DisableControlAction(0, 264, true)  -- melee attack 2
            sleep = 0
        end
        Wait(sleep)
    end
end)

useAreaHooks(function (inArea)
    inCasinoArea = inArea
    SetPlayerSprint(cache.playerId, not inArea)
end)