local _botCfg = require 'casino.holdemPoker.config'.bot or {}
if not _botCfg.enabled then
    return
end
local AUTO_BOT = _botCfg.enabled ~= false
local AUTO_BOT_COUNT = _botCfg.count or 4
local AUTO_BOT_PERSONALITY = _botCfg.personality or 'balanced'
local BOT_CHURN_INTERVAL_MIN = _botCfg.churnIntervalMin or 12
local BOT_CHURN_INTERVAL_MAX = _botCfg.churnIntervalMax or 28
local BOT_CHURN_LEAVE_CHANCE = _botCfg.churnLeaveChance or 0.40
local BOT_REJOIN_DELAY_MIN_MS = _botCfg.rejoinDelayMin or 4000
local BOT_REJOIN_DELAY_MAX_MS = _botCfg.rejoinDelayMax or 10000
local BOT_STARTING_CHIPS = _botCfg.startingChips or 50000
local BOT_THINK_MIN_MS = _botCfg.thinkMin or 1200
local BOT_THINK_MAX_MS = _botCfg.thinkMax or 3000
local BOT_NAMES = {
    "Alice", "Bob", "Charlie", "Diana", "Elvis",
    "Fiona", "George", "Hannah", "Ivan", "Julia",
    "Kevin", "Luna", "Marco", "Nina", "Oscar",
}
local BOT_ID_BASE = -1000
local BOT_PERSONALITIES = {
    AGGRESSIVE = "aggressive",
    PASSIVE = "passive",
    BALANCED = "balanced",
    TIGHT = "tight",
}
local BotManager = {
    bots = {},
    nextBotId = 1,
}
CasinoPoker.Bot = BotManager
---@class Bot
---@field src number
---@field name string
---@field chips number
---@field personality string
---@param name string?
---@param personality string?
---@return number botSrc
function BotManager:createBot(name, personality)
    local src = BOT_ID_BASE - self.nextBotId
    self.nextBotId = self.nextBotId + 1
    local botName = name or BOT_NAMES[math.random(#BOT_NAMES)]
    self.bots[src] = {
        src = src,
        name = botName,
        chips = BOT_STARTING_CHIPS,
        personality = personality or BOT_PERSONALITIES.BALANCED,
    }
    return src
end

---@param src number
function BotManager:destroyBot(src)
    self.bots[src] = nil
end

---@param src number
---@return boolean
function BotManager:isBot(src)
    return type(src) == "number" and src < 0 and self.bots[src] ~= nil
end

---@param src number
---@return Bot|nil
function BotManager:getBot(src)
    return self.bots[src]
end

local _orig_playerExist = shared.playerExist
shared.playerExist = function(source)
    if type(source) == "number" and source < 0 then
        return BotManager:isBot(source)
    end
    return _orig_playerExist(source)
end

local _orig_getChip = shared.getChip
shared.getChip = function(source)
    if type(source) == "number" and source < 0 then
        local bot = BotManager:getBot(source)
        return bot and bot.chips or 0
    end
    return _orig_getChip(source)
end

local _orig_removeChip = shared.removeChip
shared.removeChip = function(source, amount)
    if type(source) == "number" and source < 0 then
        local bot = BotManager:getBot(source)
        if bot then
            bot.chips = math.max(0, bot.chips - amount)
            for _, instance in pairs(CasinoPoker.tables) do
                local pd = instance:getPlayerChairData(source)
                if pd then pd.chips = bot.chips end
            end
        end
        return true
    end
    return _orig_removeChip(source, amount)
end

local _orig_addChip = shared.addChip
shared.addChip = function(source, amount)
    if type(source) == "number" and source < 0 then
        local bot = BotManager:getBot(source)
        if bot then
            bot.chips = bot.chips + amount
            for _, instance in pairs(CasinoPoker.tables) do
                local pd = instance:getPlayerChairData(source)
                if pd then pd.chips = bot.chips end
            end
        end
        return true
    end
    return _orig_addChip(source, amount)
end

local _orig_getPlayerName = shared.getPlayerName
shared.getPlayerName = function(source)
    if type(source) == "number" and source < 0 then
        local bot = BotManager:getBot(source)
        return bot and ("[BOT] " .. bot.name) or "[BOT] Unknown"
    end
    return _orig_getPlayerName(source)
end

local _orig_TriggerCasinoEvent = TriggerCasinoEvent
_ENV.TriggerCasinoEvent = function(event, player, ...)
    if type(player) == "number" and player < 0 then
        return
    end
    return _orig_TriggerCasinoEvent(event, player, ...)
end

local _orig_ppAddPlayer = CasinoPoker.player.addPlayer
CasinoPoker.player.addPlayer = function(self, source)
    if type(source) == "number" and source < 0 then return end
    return _orig_ppAddPlayer(self, source)
end

local _orig_ppRemovePlayer = CasinoPoker.player.removePlayer
CasinoPoker.player.removePlayer = function(self, source)
    if type(source) == "number" and source < 0 then return end
    return _orig_ppRemovePlayer(self, source)
end

local _orig_ppGetImage = CasinoPoker.player.getPlayerImage
CasinoPoker.player.getPlayerImage = function(self, source)
    if type(source) == "number" and source < 0 then return "" end
    return _orig_ppGetImage(self, source)
end

local _orig_ppUpdateChips = CasinoPoker.player.updatePlayerChips
CasinoPoker.player.updatePlayerChips = function(self, source)
    if type(source) == "number" and source < 0 then return end
    return _orig_ppUpdateChips(self, source)
end

local function getCardRank(card)
    return tonumber(card:sub(2)) or 2
end

local function getCardSuit(card)
    return card:sub(1, 1)
end

---@param holeCards string[]
---@param communityCards string[]
---@return number
local function evaluateHandStrength(holeCards, communityCards)
    local all = {}
    for i = 1, #communityCards do all[#all + 1] = communityCards[i] end
    all[#all + 1] = holeCards[1]
    all[#all + 1] = holeCards[2]
    local rankCount = {}
    local suitCount = {}
    local ranks = {}
    for i = 1, #all do
        local r = getCardRank(all[i])
        local s = getCardSuit(all[i])
        rankCount[r] = (rankCount[r] or 0) + 1
        suitCount[s] = (suitCount[s] or 0) + 1
        ranks[#ranks + 1] = r
    end
    local pairs_, threes, fours = 0, 0, 0
    for _, cnt in pairs(rankCount) do
        if cnt == 4 then fours = fours + 1
        elseif cnt == 3 then threes = threes + 1
        elseif cnt == 2 then pairs_ = pairs_ + 1
        end
    end
    local hasFlush = false
    for _, cnt in pairs(suitCount) do
        if cnt >= 5 then hasFlush = true; break end
    end
    local seen = {}
    local uniqRanks = {}
    for i = 1, #ranks do
        local r = ranks[i]
        if not seen[r] then seen[r] = true; uniqRanks[#uniqRanks + 1] = r end
    end
    table.sort(uniqRanks, function(a, b) return a > b end)
    if uniqRanks[1] == 14 then uniqRanks[#uniqRanks + 1] = 1 end
    local hasStraight = false
    local consec = 1
    for i = 2, #uniqRanks do
        if uniqRanks[i - 1] - uniqRanks[i] == 1 then
            consec = consec + 1
            if consec >= 5 then hasStraight = true; break end
        else
            consec = 1
        end
    end
    if hasStraight and hasFlush then return 9 end
    if fours >= 1 then return 8 end
    if threes >= 1 and pairs_ >= 1 then return 7 end
    if hasFlush then return 6 end
    if hasStraight then return 5 end
    if threes >= 1 then return 4 end
    if pairs_ >= 2 then return 3 end
    if pairs_ >= 1 then return 2 end
    return 1
end

---@param holeCards string[]
---@return number
local function evaluatePreFlop(holeCards)
    local r1 = getCardRank(holeCards[1])
    local r2 = getCardRank(holeCards[2])
    local s1 = getCardSuit(holeCards[1])
    local s2 = getCardSuit(holeCards[2])
    local score = 0
    if r1 == r2 then
        score = 4 + math.floor(r1 / 5)
    else
        local hi = math.max(r1, r2)
        local lo = math.min(r1, r2)
        local suited = s1 == s2
        local gap = hi - lo
        score = math.floor((hi / 14) * 3.5)
        if suited then score = score + 1 end
        if gap <= 1 then score = score + 1 end
        if gap <= 2 then score = score + 0.5 end
        if hi >= 13 then score = score + 1 end
        if lo >= 10 then score = score + 0.5 end
    end
    return math.max(1, math.min(9, math.floor(score)))
end

---@param instance PokerTable
---@param botSrc number
local function makeBotDecision(instance, botSrc)
    local playerData = instance:getPlayerChairData(botSrc)
    if not playerData then return end
    local bot = BotManager:getBot(botSrc)
    if not bot then return end
    if not instance:isPlayerCurrentPlayer(botSrc) then return end
    local community = instance._dealerCards
    local holeCards = playerData.cards
    local strength = 1
    if #holeCards >= 2 then
        if #community == 0 then
            strength = evaluatePreFlop(holeCards)
        else
            strength = evaluateHandStrength(holeCards, community)
        end
    end
    local sr = strength / 9.0
    local foldThreshold, raiseThreshold
    local p = bot.personality
    if p == BOT_PERSONALITIES.AGGRESSIVE then
        foldThreshold = 0.08
        raiseThreshold = 0.35
    elseif p == BOT_PERSONALITIES.PASSIVE then
        foldThreshold = 0.25
        raiseThreshold = 0.85
    elseif p == BOT_PERSONALITIES.TIGHT then
        foldThreshold = 0.45
        raiseThreshold = 0.72
    else
        foldThreshold = 0.22
        raiseThreshold = 0.58
    end
    local rand = math.random()
    local bluff = rand < 0.10
    local canCheck = instance:canPass(botSrc)
    local callAmount = instance:calculateCall(botSrc)
    local botChips = shared.getChip(botSrc)
    local blind = instance._blind
    local highestBet = instance:getHighestBet()
    local raiseAmt
    if highestBet > 0 then
        raiseAmt = math.floor(highestBet * 2.5)
    else
        raiseAmt = math.floor(blind * (2 + math.random(1, 3)))
    end
    if bluff and sr < foldThreshold then
        if botChips >= raiseAmt and raiseAmt > callAmount then
            instance:betPoker(botSrc, { amount = raiseAmt })
            return
        end
    end
    if sr >= raiseThreshold then
        if botChips >= raiseAmt and raiseAmt > callAmount then
            instance:betPoker(botSrc, { amount = raiseAmt })
        elseif callAmount <= botChips and callAmount > 0 then
            instance:callPoker(botSrc)
        elseif canCheck then
            instance:passPoker(botSrc)
        else
            instance:allInPoker(botSrc)
        end
    elseif sr >= foldThreshold then
        if canCheck then
            instance:passPoker(botSrc)
        elseif callAmount <= botChips then
            instance:callPoker(botSrc)
        else
            instance:throwPoker(botSrc)
        end
    else
        if canCheck then
            instance:passPoker(botSrc)
        else
            instance:throwPoker(botSrc)
        end
    end
end

local botActionPending = {}
CreateThread(function()
    while true do
        Wait(400)
        for _, instance in pairs(CasinoPoker.tables) do
            local currentSrc = instance:getCurrentPlayerSrc()
            if currentSrc and BotManager:isBot(currentSrc) then
                local key = tostring(instance._index) .. "_" .. tostring(currentSrc)
                if not botActionPending[key] then
                    botActionPending[key] = true
                    local thinkTime = math.random(BOT_THINK_MIN_MS, BOT_THINK_MAX_MS)
                    SetTimeout(thinkTime, function()
                        botActionPending[key] = nil
                        if instance:getCurrentPlayerSrc() == currentSrc then
                            local ok, err = pcall(makeBotDecision, instance, currentSrc)
                            if not ok then
                                lib.print.error(("[PokerBot] Decision error: %s"):format(err))
                            end
                        end
                    end)
                end
            end
        end
    end
end)

---@param tableId integer
---@param personality? string
---@param name? string
---@return number|false
function BotManager:addBotToTable(tableId, personality, name)
    local instance = CasinoPoker.tables[tableId]
    if not instance then
        lib.print.warn(("[PokerBot] Table %s tidak ditemukan"):format(tableId))
        return false
    end
    if instance._gamestage ~= 1 then
        lib.print.warn("[PokerBot] Tidak bisa join saat permainan berlangsung.")
        return false
    end
    local freeChairId = instance:getFreeChairId()
    if not freeChairId then
        lib.print.warn(("[PokerBot] Tidak ada kursi kosong di meja %s"):format(tableId))
        return false
    end
    local botSrc = self:createBot(name, personality)
    local bot = self.bots[botSrc]
    local botGender = math.random(2) == 1 and 'male' or 'female'
    table.insert(instance._chairPlayers, {
        src = botSrc,
        cards = {},
        throwed = false,
        passed = false,
        dealer = false,
        playername = "[BOT] " .. bot.name,
        roundbet = 0,
        chairId = freeChairId,
        wasInRound = false,
        chips = bot.chips,
        img = botGender == 'female' and 'images/user/user-women.png' or 'images/user/user-man.png',
        gender = botGender,
        isBot = true,
    })
    instance:update("everyone", "players")
    lib.print.info(('[PokerBot] %s bergabung ke meja %s (src: %s, personality: %s)')
        :format(bot.name, tableId, botSrc, bot.personality))
    return botSrc
end

---@param tableId integer
---@param botSrc number
function BotManager:removeBotFromTable(tableId, botSrc)
    local instance = CasinoPoker.tables[tableId]
    if not instance then
        lib.print.warn(("[PokerBot] Table %s tidak ditemukan"):format(tableId))
        return
    end
    if not BotManager:isBot(botSrc) then
        lib.print.warn(("[PokerBot] Source %s bukan bot"):format(botSrc))
        return
    end
    if instance._gamestage == 2 and instance:isPlayerCurrentPlayer(botSrc) then
        botActionPending[tostring(tableId) .. "_" .. tostring(botSrc)] = nil
        local ok, err = pcall(instance.throwPoker, instance, botSrc, true)
        if not ok then lib.print.error("[PokerBot] Error force-fold: " .. tostring(err)) end
    end
    for i = 1, #instance._chairPlayers do
        local p = instance._chairPlayers[i]
        if p.src == botSrc then
            table.remove(instance._chairPlayers, i)
            break
        end
    end
    local botName = self.bots[botSrc] and self.bots[botSrc].name or "Unknown"
    instance:update("everyone", "players")
    self:destroyBot(botSrc)
    lib.print.info(('[PokerBot] Bot %s (src: %s) dihapus dari meja %s'):format(botName, botSrc, tableId))
end

lib.addCommand("addbot", {
    help = "Tambah bot ke meja poker",
    params = {
        { name = "tableId", help = "ID meja (1, 2, ...)", type = "number" },
        { name = "personality", help = "aggressive | passive | balanced | tight (default: balanced)", type = "string", optional = true },
        { name = "name", help = "Nama bot (opsional)", type = "string", optional = true },
    },
    restricted = "group.admin",
}, function(source, args)
    local personality = args.personality or "balanced"
    local valid = { aggressive = true, passive = true, balanced = true, tight = true }
    if not valid[personality] then
        TriggerClientEvent("ox_lib:notify", source, {
            type = "error",
            description = ("Personality tidak valid: '%s'. Gunakan: aggressive, passive, balanced, tight"):format(personality),
        })
        return
    end
    local botSrc = BotManager:addBotToTable(args.tableId, personality, args.name)
    if botSrc then
        TriggerClientEvent("ox_lib:notify", source, {
            type = "success",
            description = ("Bot ditambahkan ke meja %s | src: %s | personality: %s"):format(args.tableId, botSrc, personality),
        })
    else
        TriggerClientEvent("ox_lib:notify", source, {
            type = "error",
            description = "Gagal menambahkan bot. Cek console server.",
        })
    end
end)

lib.addCommand("removebot", {
    help = "Hapus bot dari meja poker",
    params = {
        { name = "tableId", help = "ID meja", type = "number" },
        { name = "botSrc", help = "Source bot (negatif)", type = "number" },
    },
    restricted = "group.admin",
}, function(source, args)
    BotManager:removeBotFromTable(args.tableId, args.botSrc)
    TriggerClientEvent("ox_lib:notify", source, {
        type = "success",
        description = ("Bot %s dihapus dari meja %s"):format(args.botSrc, args.tableId),
    })
end)
lib.addCommand("listbots", {
    help = "Lihat semua bot poker aktif",
    restricted = "group.admin",
}, function(source, _args)
    local count = 0
    for src, bot in pairs(BotManager.bots) do
        count = count + 1
        TriggerClientEvent("ox_lib:notify", source, {
            type = "inform",
            description = ("src=%s | %s | chips=%s | %s"):format(src, bot.name, bot.chips, bot.personality),
        })
    end
    if count == 0 then
        TriggerClientEvent("ox_lib:notify", source, {
            type = "inform",
            description = "Tidak ada bot aktif saat ini.",
        })
    end
end)

---@param instance PokerTable
---@return integer
local function countRealPlayers(instance)
    local n = 0
    for i = 1, #instance._chairPlayers do
        if not BotManager:isBot(instance._chairPlayers[i].src) then n = n + 1 end
    end
    return n
end

---@param instance PokerTable
---@return integer
local function countBots(instance)
    local n = 0
    for i = 1, #instance._chairPlayers do
        if BotManager:isBot(instance._chairPlayers[i].src) then n = n + 1 end
    end
    return n
end

---@param instance PokerTable
---@return number[]
local function getBotSrcs(instance)
    local srcs = {}
    for i = 1, #instance._chairPlayers do
        if BotManager:isBot(instance._chairPlayers[i].src) then
            srcs[#srcs + 1] = instance._chairPlayers[i].src
        end
    end
    return srcs
end

---@param instance PokerTable
---@param targetCount integer
local function fillBots(instance, targetCount)
    local botCount = countBots(instance)
    if botCount >= targetCount then return end
    if instance._gamestage ~= 1 then return end
    local toAdd = targetCount - botCount
    for _ = 1, toAdd do
        if not instance:getFreeChairId() then break end
        BotManager:addBotToTable(instance._index, AUTO_BOT_PERSONALITY)
    end
end

---@param instance PokerTable
local function removeAllBots(instance)
    local srcs = getBotSrcs(instance)
    for i = 1, #srcs do
        BotManager:removeBotFromTable(instance._index, srcs[i])
    end
end

local churnNextTick = {}
CreateThread(function()
    Wait(3000)
    local tick = 0
    while true do
        Wait(1500)
        tick = tick + 1
        for _, instance in pairs(CasinoPoker.tables) do
            local tid = instance._index
            local realCount = countRealPlayers(instance)
            local botCount = countBots(instance)
            local gameStage = instance._gamestage
            if realCount == 0 then
                if botCount > 0 then
                    removeAllBots(instance)
                end
                churnNextTick[tid] = nil
            else
                if botCount == 0 and gameStage == 1 then
                    fillBots(instance, AUTO_BOT_COUNT)
                    local interval = math.random(BOT_CHURN_INTERVAL_MIN, BOT_CHURN_INTERVAL_MAX)
                    churnNextTick[tid] = tick + math.floor(interval / 1.5)
                end
                if gameStage == 1 and botCount < AUTO_BOT_COUNT then
                    fillBots(instance, AUTO_BOT_COUNT)
                end
                if gameStage == 1 and churnNextTick[tid] and tick >= churnNextTick[tid] then
                    local srcs = getBotSrcs(instance)
                    if #srcs > 0 and math.random() < BOT_CHURN_LEAVE_CHANCE then
                        local victim = srcs[math.random(#srcs)]
                        local botName = BotManager.bots[victim] and BotManager.bots[victim].name or "?"
                        BotManager:removeBotFromTable(tid, victim)
                        local rejoinMs = math.random(BOT_REJOIN_DELAY_MIN_MS, BOT_REJOIN_DELAY_MAX_MS)
                        SetTimeout(rejoinMs, function()
                            local inst2 = CasinoPoker.tables[tid]
                            if inst2 and countRealPlayers(inst2) > 0 and inst2._gamestage == 1 then
                                BotManager:addBotToTable(tid, AUTO_BOT_PERSONALITY)
                            end
                        end)
                    end
                    local interval = math.random(BOT_CHURN_INTERVAL_MIN, BOT_CHURN_INTERVAL_MAX)
                    churnNextTick[tid] = tick + math.floor(interval / 1.5)
                end
            end
        end
    end
end)