--[[
    sm_netfish :: server
    Profil nelayan, level/exp, roll ikan, tangkapan, umpan, toko, upgrade, misi harian, papan peringkat.
]]

local config = localmodule 'config.shared'

local QBCore = exports['qb-core']:GetCoreObject()

local IMAGE_PATH = 'nui://ox_inventory/web/images/%s.png'
local MAX_LEVEL = 100

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `sm_netfish_profiles` (
    `citizenid` varchar(64) NOT NULL,
    `name` varchar(64) NOT NULL DEFAULT 'Nelayan',
    `level` int(11) NOT NULL DEFAULT 1,
    `exp` int(11) NOT NULL DEFAULT 0,
    `total` int(11) NOT NULL DEFAULT 0,
    `caught` longtext NULL,
    `best` longtext NULL,
    `quests` longtext NULL,
    `upgrades` longtext NULL,
    `quest_reset` bigint(20) NOT NULL DEFAULT 0,
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local profiles = {}
local sessions = {}

local function ply(src)
    return QBCore.Functions.GetPlayer(src)
end

local function notify(src, description, nType)
    lib.notify(src, { title = 'Mancing', description = description, type = nType or 'inform' })
end

local function decode(raw, fallback)
    if type(raw) ~= 'string' or raw == '' then return fallback end

    local ok, value = pcall(json.decode, raw)
    if not ok or type(value) ~= 'table' then return fallback end

    return value
end

local function saveProfile(profile)
    MySQL.update('UPDATE sm_netfish_profiles SET name = ?, level = ?, exp = ?, total = ?, caught = ?, best = ?, quests = ?, upgrades = ?, quest_reset = ? WHERE citizenid = ?', {
        profile.name, profile.level, profile.exp, profile.total,
        json.encode(profile.caught), profile.best and json.encode(profile.best) or nil,
        json.encode(profile.quests), json.encode(profile.upgrades), profile.quest_reset,
        profile.citizenid
    })
end

local function getProfile(src, player)
    local citizenid = player.PlayerData.citizenid
    local cached = profiles[citizenid]
    if cached then return cached end

    local charinfo = player.PlayerData.charinfo
    local name = ('%s %s'):format(charinfo.firstname or 'Nelayan', charinfo.lastname or '')

    local row = MySQL.single.await('SELECT * FROM sm_netfish_profiles WHERE citizenid = ?', { citizenid })

    if not row then
        MySQL.insert.await('INSERT INTO sm_netfish_profiles (citizenid, name) VALUES (?, ?)', { citizenid, name })
        row = { citizenid = citizenid, name = name, level = 1, exp = 0, total = 0 }
    end

    local profile = {
        citizenid = citizenid,
        name = name,
        level = tonumber(row.level) or 1,
        exp = tonumber(row.exp) or 0,
        total = tonumber(row.total) or 0,
        caught = decode(row.caught, {}),
        best = decode(row.best, nil),
        quests = decode(row.quests, {}),
        upgrades = decode(row.upgrades, {}),
        quest_reset = tonumber(row.quest_reset) or 0
    }

    profiles[citizenid] = profile
    return profile
end

local function hasUpgrade(profile, name)
    for i = 1, #profile.upgrades do
        if profile.upgrades[i] == name then return true end
    end

    return false
end

local function upgradeValue(profile, prefix)
    local total = 0

    for i = 1, #profile.upgrades do
        local key = profile.upgrades[i]
        if key:sub(1, #prefix) == prefix then
            for j = 1, #config.upgrades do
                local upgrade = config.upgrades[j]
                if upgrade.name == key then
                    total = total + (upgrade.value or 0)
                    break
                end
            end
        end
    end

    return total
end

local function resetQuests(profile)
    local now = os.time()
    if profile.quest_reset > now then return end

    profile.quests = {}
    profile.quest_reset = now + ((config.questResetHours or 24) * 3600)
end

local function addExp(profile, amount)
    profile.exp = profile.exp + amount

    local leveled = false
    while profile.exp >= (config.expPerLevel or 100) and profile.level < MAX_LEVEL do
        profile.exp = profile.exp - (config.expPerLevel or 100)
        profile.level = profile.level + 1
        leveled = true
    end

    return leveled
end

local function inGacor(coords)
    for i = 1, #(config.gacorSpots or {}) do
        local spot = config.gacorSpots[i]
        if #(coords - spot.coords) <= spot.radius then return true end
    end

    return false
end

local function seaRank(level)
    if level == 'deep_sea' then return 3 end
    if level == 'sea' then return 2 end
    return 1
end

local function pickFish(profile, seaLevel, session)
    local ranks = seaRank(seaLevel)
    local chances = inGacor(GetEntityCoords(GetPlayerPed(session.src))) and config.gacorChances or config.chances

    local luck = upgradeValue(profile, 'better_luck')
    local mythicUnlocked = hasUpgrade(profile, 'mythical_grade')
    local noBoots = hasUpgrade(profile, 'no_boots')

    local pool, totalWeight = {}, 0

    for i = 1, #config.fishes do
        local fish = config.fishes[i]
        local chance = fish.chance
        local allowed = seaRank(fish.seaLevel or 'shore') <= ranks

        if allowed and not (fish.notAFish and noBoots) then
            if chance == 'Mythic' and not mythicUnlocked then allowed = false end
            if (chance == 'Legendary' or chance == 'Mythic') and fish.bait then
                allowed = session.bait == fish.bait
            end
            if (chance == 'Legendary' or chance == 'Mythic') and profile.level < (config.rodRarityLevel[chance] or 1) then
                allowed = false
            end
        end

        if allowed then
            local weight = chances[chance] or 1
            if chance ~= 'Default' then weight = weight + luck end

            totalWeight = totalWeight + weight
            pool[#pool + 1] = { fish = fish, weight = totalWeight }
        end
    end

    if totalWeight <= 0 then return end

    local roll = math.random() * totalWeight

    for i = 1, #pool do
        if roll <= pool[i].weight then return pool[i].fish end
    end

    return pool[#pool].fish
end

lib.callback.register('sm_netfish:start', function(src, item)
    local player = ply(src)
    if not player then return false end

    local rod = config.rods[item]
    if not rod then return false end
    if sessions[src] then return false end
    if not player.Functions.GetItemByName(item) then return false end

    local profile = getProfile(src, player)
    resetQuests(profile)

    if profile.level < (rod.level or 1) then
        return false, 'level', rod.level
    end

    sessions[src] = {
        src = src,
        citizenid = profile.citizenid,
        rod = item,
        bait = nil,
        token = nil,
        fish = nil
    }

    return true, {
        level = profile.level,
        catchBonus = upgradeValue(profile, 'shorter_catch'),
        bait = nil
    }
end)

lib.callback.register('sm_netfish:stop', function(src)
    local session = sessions[src]
    if not session then return end

    if session.bait then
        local player = ply(src)
        if player then player.Functions.AddItem(session.bait, 1) end
    end

    sessions[src] = nil
end)

lib.callback.register('sm_netfish:equipBait', function(src, item)
    local player = ply(src)
    local session = sessions[src]

    if not player or not session then return false end
    if session.bait then return false, 'has_bait' end

    local bait = config.baits[item]
    if not bait then return false end
    if not player.Functions.GetItemByName(item) then return false end

    if not player.Functions.RemoveItem(item, 1) then return false end

    session.bait = item
    return true, bait.label
end)

lib.callback.register('sm_netfish:removeBait', function(src)
    local player = ply(src)
    local session = sessions[src]

    if not player or not session or not session.bait then return false end

    player.Functions.AddItem(session.bait, 1)
    session.bait = nil

    return true
end)

lib.callback.register('sm_netfish:roll', function(src, seaLevel)
    local session = sessions[src]
    if not session then return end

    local player = ply(src)
    if not player then return end

    local profile = getProfile(src, player)
    local fish = pickFish(profile, seaLevel, session)
    if not fish then return end

    local token = ('%s:%d'):format(profile.citizenid, math.random(100000, 999999))

    local weight = math.random(fish.weight[1], fish.weight[2])
    local length = math.random(fish.length[1], fish.length[2])

    session.token = token
    session.fish = {
        label = fish.label,
        chance = fish.chance,
        item = fish.item,
        reward = fish.reward,
        notAFish = fish.notAFish,
        weight = weight,
        length = length
    }

    return {
        token = token,
        label = fish.label,
        chance = fish.chance,
        item = fish.item,
        notAFish = fish.notAFish,
        weight = weight,
        length = length,
        minigame = config.minigame[fish.chance] or config.minigame.Default
    }
end)

lib.callback.register('sm_netfish:finish', function(src, token, outcome)
    local session = sessions[src]
    local player = ply(src)

    if not session or not player or not session.token or session.token ~= token then return false end

    local fish = session.fish
    session.token = nil
    session.fish = nil

    if not fish then return false end
    if outcome == 'fail' then return true, { exp = 0 } end

    local profile = getProfile(src, player)
    local exp = math.floor((config.baseExp or 1) * (config.expMultiplier[fish.chance] or 1))
    local result = { exp = exp }

    profile.total = profile.total + 1
    profile.caught[fish.label] = true
    profile.quests.catch = (profile.quests.catch or 0) + 1

    if fish.notAFish then
        profile.quests.boot = (profile.quests.boot or 0) + 1
    else
        profile.quests[fish.chance] = (profile.quests[fish.chance] or 0) + 1
    end

    if not profile.best or fish.weight > (profile.best.weight or 0) then
        profile.best = { label = fish.label, chance = fish.chance, weight = fish.weight, length = fish.length }
        result.best = true
    end

    if outcome == 'keep' then
        local itemName = fish.reward and fish.reward.item or fish.item

        if itemName and not player.Functions.AddItem(itemName, fish.reward and fish.reward.count or 1) then
            result.full = true
        end
    end

    if addExp(profile, exp) then
        TriggerClientEvent('sm_netfish:client:levelUp', src, profile.level)
    end

    saveProfile(profile)

    return true, result
end)

local function buildProfile(profile)
    local leaderboard = MySQL.query.await('SELECT name, total FROM sm_netfish_profiles ORDER BY total DESC LIMIT 10') or {}
    local rows = {}

    for i = 1, #leaderboard do
        rows[i] = { rank = i, name = leaderboard[i].name, total = tonumber(leaderboard[i].total) or 0 }
    end

    local caught = {}
    for label in pairs(profile.caught) do caught[#caught + 1] = label end

    local quests = {}
    for key, value in pairs(profile.quests) do quests[key] = tonumber(value) or 0 end

    return {
        name = profile.name,
        level = profile.level,
        exp = profile.exp,
        expPerLevel = config.expPerLevel or 100,
        total = profile.total,
        caught = caught,
        best = profile.best,
        quests = quests,
        questReset = math.max(0, profile.quest_reset - os.time()),
        upgrades = profile.upgrades,
        leaderboard = rows
    }
end

lib.callback.register('sm_netfish:dashboard', function(src)
    local player = ply(src)
    if not player then return end

    local profile = getProfile(src, player)
    resetQuests(profile)
    saveProfile(profile)

    return buildProfile(profile)
end)

lib.callback.register('sm_netfish:buy', function(src, item, quantity, method)
    local player = ply(src)
    if not player or type(item) ~= 'string' then return false, 'Item tidak valid.' end

    local method = method == 'bank' and 'bank' or 'cash'
    local profile = getProfile(src, player)

    local rod = config.rods[item]
    local bait = config.baits[item]

    if rod then
        if player.Functions.GetItemByName(item) then return false, 'Kamu sudah punya pancingan ini.' end
        if profile.level < (rod.level or 1) then return false, ('Butuh level %d.'):format(rod.level or 1) end
        if not player.Functions.RemoveMoney(method, rod.price, 'netfish-shop') then return false, 'Uang tidak cukup.' end
        if not player.Functions.AddItem(item, 1) then
            player.Functions.AddMoney(method, rod.price, 'netfish-refund')
            return false, 'Tas penuh.'
        end

        return true, ('%s dibeli.'):format(rod.label)
    end

    if bait then
        if not bait.price then return false, 'Umpan ini tidak dijual.' end
        if profile.level < (bait.level or 1) then return false, ('Butuh level %d.'):format(bait.level or 1) end

        local count = math.floor(tonumber(quantity) or 1)
        count = math.max(1, math.min(count, config.shopMaxQuantity or 50))

        local total = bait.price * count
        if not player.Functions.RemoveMoney(method, total, 'netfish-shop') then return false, 'Uang tidak cukup.' end
        if not player.Functions.AddItem(item, count) then
            player.Functions.AddMoney(method, total, 'netfish-refund')
            return false, 'Tas penuh.'
        end

        return true, ('%d %s dibeli.'):format(count, bait.label)
    end

    return false, 'Item tidak dikenal.'
end)

lib.callback.register('sm_netfish:buyUpgrade', function(src, name, method)
    local player = ply(src)
    if not player or type(name) ~= 'string' then return false, 'Upgrade tidak valid.' end

    local method = method == 'bank' and 'bank' or 'cash'
    local profile = getProfile(src, player)

    local upgrade
    for i = 1, #config.upgrades do
        if config.upgrades[i].name == name then
            upgrade = config.upgrades[i]
            break
        end
    end

    if not upgrade then return false, 'Upgrade tidak valid.' end
    if hasUpgrade(profile, name) then return false, 'Sudah dimiliki.' end
    if profile.level < (upgrade.level or 1) then return false, ('Butuh level %d.'):format(upgrade.level or 1) end

    if upgrade.needed and not hasUpgrade(profile, upgrade.needed) then
        return false, 'Upgrade sebelumnya belum dibeli.'
    end

    if not player.Functions.RemoveMoney(method, upgrade.price, 'netfish-upgrade') then return false, 'Uang tidak cukup.' end

    profile.upgrades[#profile.upgrades + 1] = name
    saveProfile(profile)

    return true, buildProfile(profile)
end)

CreateThread(function()
    MySQL.query.await(SCHEMA)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local session = sessions[src]
    sessions[src] = nil

    if not session then return end

    local player = ply(src)
    if session.bait and player then player.Functions.AddItem(session.bait, 1) end

    local profile = profiles[session.citizenid]
    if profile then saveProfile(profile) end
end)