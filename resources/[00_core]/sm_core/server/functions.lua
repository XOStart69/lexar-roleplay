-- sm_core/server/functions.lua
-- API QBCore.Functions yang dipanggil commands/loops/connecting tetapi belum pernah didefinisikan.
-- Kompatibel qb-core; semua akses lewat QBCore.Players, tidak membuat tabel baru.

QBCore.Functions = QBCore.Functions or {}

---@param source Source|string|number
---@return table?
function QBCore.Functions.GetPlayer(source)
    local src = tonumber(source)
    if not src then return end
    return QBCore.Players[src]
end

---@return table
function QBCore.Functions.GetPlayers()
    return QBCore.Players
end

---@param citizenid string
---@return table?
function QBCore.Functions.GetPlayerByCitizenId(citizenid)
    for _, player in pairs(QBCore.Players) do
        if player.PlayerData.citizenid == citizenid then return player end
    end
end

---@param phone string
---@return table?
function QBCore.Functions.GetPlayerByPhone(phone)
    for _, player in pairs(QBCore.Players) do
        if player.PlayerData.charinfo.phone == phone then return player end
    end
end

---@param job string
---@return table[]
function QBCore.Functions.GetPlayersByJob(job)
    local list = {}
    for _, player in pairs(QBCore.Players) do
        if player.PlayerData.job.name == job then list[#list + 1] = player end
    end
    return list
end

---@param gang string
---@return table[]
function QBCore.Functions.GetPlayersByGang(gang)
    local list = {}
    for _, player in pairs(QBCore.Players) do
        if player.PlayerData.gang.name == gang then list[#list + 1] = player end
    end
    return list
end

---@param identifier string
---@return number?
function QBCore.Functions.GetSource(identifier)
    for src, player in pairs(QBCore.Players) do
        if player.PlayerData.license == identifier then return src end
    end
end

---@param source Source|string|number
---@param idtype? string
---@return string?
function QBCore.Functions.GetIdentifier(source, idtype)
    return PlayerIdentifier(source, idtype)
end

---@param source Source|string|number
---@return string[]
function QBCore.Functions.GetPlayerIdentifiers(source)
    return GetPlayerIdentifiers(tostring(source))
end

---@param license string
---@return boolean
function QBCore.Functions.IsLicenseInUse(license)
    for _, player in pairs(QBCore.Players) do
        if player.PlayerData.license == license then return true end
    end
    return false
end

---@param source Source|string|number
---@return boolean
function QBCore.Functions.IsWhitelisted(source)
    local src = tostring(source)

    if IsPlayerAceAllowed(src, QBConfig.Server.WhitelistPermission) then return true end

    for i = 1, #QBConfig.Server.Permissions do
        if IsPlayerAceAllowed(src, QBConfig.Server.Permissions[i]) then return true end
    end

    return false
end

---@param source Source|string|number
---@param text string
---@param kind? string
---@param duration? number
function QBCore.Functions.Notify(source, text, kind, duration)
    TriggerClientEvent('ox_lib:notify', tonumber(source) or source, {
        description = text,
        type = kind or 'inform',
        duration = duration,
    })
end

---@param source Source|string|number
---@param permission string
function QBCore.Functions.AddPermission(source, permission)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end

    ExecuteCommand(('add_principal identifier.%s group.%s'):format(player.PlayerData.license, permission))
end

---@param source Source|string|number
---@param permission string
function QBCore.Functions.RemovePermission(source, permission)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end

    ExecuteCommand(('remove_principal identifier.%s group.%s'):format(player.PlayerData.license, permission))
end

---@param name string
---@param cb fun(source: number, ...): any
function QBCore.Functions.CreateCallback(name, cb)
    lib.callback.register(name, cb)
end