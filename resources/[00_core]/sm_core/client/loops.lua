CreateThread(function()
    while true do
        local pstate = LocalPlayer.state
        if pstate.isLoggedIn then
            local hunger = QBCore.PlayerData.metadata['hunger']
            local thirst = QBCore.PlayerData.metadata['thirst']
            local isDead = QBCore.PlayerData.metadata['isdead']
            local inLastStand = QBCore.PlayerData.metadata['inlaststand']
            
            if not pstate.inGhostHunting and hunger and thirst and (hunger <= 0 or thirst <= 0) and not (isDead or inLastStand) then
                local ped = PlayerPedId()
                local currentHealth = GetEntityHealth(ped)
                local decreaseThreshold = math.random(5, 10)
                SetEntityHealth(ped, currentHealth - decreaseThreshold)
            end
        end
        Wait(QBCore.Config.StatusInterval)
    end
end)