local function getMoney(moneyType)
    local money = QBPlayerData.money[moneyType]
    if not money then return 0 end
    return money
end

---@return string
local function getJobLabel()
    local job = QBPlayerData.job
    if not job then return 'Unemployed' end

    local label = job.label or 'Unemployed'
    local grade = job.grade and job.grade.name

    if grade and grade ~= '' and grade ~= label then
        return ('%s - %s'):format(label, grade)
    end

    return label
end

local function informationTick()
    if not playerState.isLoggedIn then
        return 2000
    end

    interface.send({
        action = 'updateInformation',
        data = {
            cash = getMoney('cash'),
            bank = getMoney('bank'),
            jobName = getJobLabel(),
            playerId = cache.serverId,
            serverPlayers = SM_HUD.serverPlayers,
            maxPlayers = SM_HUD.maxPlayers,
        },
    })

    return 1500
end

CreateThread(function()
    while true do
        Wait(informationTick())
    end
end)

RegisterNetEvent('sm_hud:client:updateServerInfo', function(playerCount, maxPlayers)
    SM_HUD.serverPlayers = playerCount
    SM_HUD.maxPlayers = maxPlayers
end)
