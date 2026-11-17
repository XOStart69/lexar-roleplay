
local isServer = lib.context == 'server'

local casino = {
    'slots',
    'roulette',
    'luckywheel',
    'insidetrack',
    'blackjack',
    'holdemPoker',
    'sportsbook'
}

---@alias CasinoSeatType
---| 'none'
---| 'slots'
---| 'roulette'
---| 'insidetrack'
---| 'blackjack'
---| 'holdemPoker'

_ENV.shared = {}
_ENV.gstate = GlobalState
_ENV.ox_inventory = exports.ox_inventory
_ENV.sm_core = exports.sm_core

---@type CasinoSeatType
shared.activeSeat = 'none'
shared.chipItemName = 'casino_chips'
shared.voiceInfoState = false
shared.casinoJobName = GetConvar('rhd_casino:job_name', 'velvetsm')

shared.casinoCoords = {
    area = {
        vector3(917.29992675781, 11.426199913025, 69.390602111816),
        vector3(1008.971496582, 87.146003723145, 81.452796936035)
    },
    bigArea = {
        points = {
            vec3(890.64001464844, 87.220001220703, 49.799999237061),
            vec3(842.92999267578, 23.889999389648, 49.799999237061),
            vec3(1018.1799926758, -86.959999084473, 49.799999237061),
            vec3(1111.5699462891, 61.200000762939, 49.799999237061),
            vec3(953.03002929688, 175.24000549316, 49.799999237061),
        },
        thickness = 158.5,
    }
}

---@class BuyInData
---@field chips integer

if not isServer then
    _ENV.infoUI = exports.rhd_infoui
    _ENV.interact = exports.rhd_interact
    _ENV.target = exports.ox_target

    playerState = LocalPlayer.state

    require 'modules.interior'
    require 'modules.wallscreen'
    -- require 'modules.ambient'
    require 'modules.behavior'
    require 'modules.lifecycle'

    function shared.showVoiceInfo()
        if shared.voiceInfoState then return end

        infoUI:show({
            id = 'rhd_casino_voiceInfo',
            title = 'Voice Information',
            icon = 'fa-solid fa-microphone',
            description = [[
            Gunakan command /setproximity [1-3]
            untuk mengubah jarak suara kamu ketika
            bermain poker
            ]]
        })

        shared.voiceInfoState = true
    end

    function shared.hideVoiceInfo()
        if not shared.voiceInfoState then return end

        infoUI:remove('rhd_casino_voiceInfo')
        shared.voiceInfoState = false
    end

    ---@class BettorsData
    ---@field serverId number
    ---@field name string
    ---@field distance number

    ---@return BettorsData[]
    function shared.getNearbyBettors()
        local coords = GetEntityCoords(cache.ped)
        local nearbyPlayers = lib.getNearbyPlayers(coords, 5.0, true)

        local players = {}

        for i=1, #nearbyPlayers do
            local player = nearbyPlayers[i]
            local serverId = GetPlayerServerId(player.id)
            local pState = Player(serverId).state
            local distance = #(coords - player.coords)

            players[#players+1] = {
                serverId = serverId,
                name = pState.name,
                distance = math.floor(distance * 10) / 10,
            }
        end

        table.sort(players, function(a, b)
            return a.distance < b.distance
        end)

        return players
    end
else
    _ENV.db = exports.oxmysql
    require 'modules.players'
    require 'modules.vault'
    local storage = require 'modules.storage'
    local logger = require 'modules.logger'

    shared.casinoBankAccount = GetConvar('rhd_casino:bank_account', shared.casinoJobName)
    shared.casinoBankIncomeRate = GetConvarInt('rhd_casino:bank_income_percent', 1.0 * 100) / 100
    shared.casinoVipBankIncomeRate = GetConvarInt('rhd_casino:vip_bank_income_percent', 1.0 * 100) / 100
    shared.casinoBankPayoutEnabled = GetConvarInt('rhd_casino:bank_payout_enabled', 1) == 1
    shared.casinoBankPayoutRate = GetConvarInt('rhd_casino:bank_payout_percent', 100) / 100
    shared.casinoWinningsFeeRate = GetConvarInt('rhd_casino:winnings_fee_percent', 5) / 100

    playerState = setmetatable({}, {
        __call = function(source)
            return Player(source).state
        end
    })

    shared.casinoBigZone = lib.zones.poly(shared.casinoCoords.bigArea)

    ---@param source number
    ---@return string?
    function shared.getIdentifier(source)
        return sm_core:GetCitizenId(source)
    end

    ---@param source number
    ---@return string
    ---@diagnostic disable-next-line: duplicate-set-field
    function shared.getPlayerName(source)
        local pname = sm_core:GetName(source)

        if type(pname) == 'string' and pname ~= '' and pname:lower() ~= 'unknown' then
            return pname
        end

        return GetPlayerName(source) or ('Player %s'):format(source)
    end

    ---@param value any
    ---@return integer?
    local function parseCardExpiry(value)
        if type(value) ~= 'string' then return nil end

        local y, m, d = value:match('^(%d%d%d%d)-(%d%d?)-(%d%d?)$')
        if not y then
            d, m, y = value:match('^(%d%d?)-(%d%d?)-(%d%d%d%d)$')
        end
        if not y then return nil end

        return os.time({ year = tonumber(y) --[[@as integer]], month = tonumber(m) --[[@as integer]], day = tonumber(d) --[[@as integer]] })
    end

    ---@class CasinoVipCard
    ---@field slot integer
    ---@field expiresAt integer

    ---@param source number
    ---@return CasinoVipCard[]
    function shared.getOwnedVipCards(source)
        local citizenid = shared.getIdentifier(source)
        local items = citizenid and ox_inventory:GetInventoryItems(source)
        if not items then return {} end

        local itemName = require 'addon.config.cashier'.vip.itemName
        local cards = {}

        for _, item in pairs(items) do
            if item.name == itemName and item.metadata?.card_id == citizenid then
                cards[#cards + 1] = {
                    slot = item.slot,
                    expiresAt = parseCardExpiry(item.metadata.card_expired) or 0,
                }
            end
        end

        return cards
    end

    ---@param source number
    ---@return integer?
    function shared.getVipExpiry(source)
        local cards = shared.getOwnedVipCards(source)
        local latest = 0

        for i = 1, #cards do
            if cards[i].expiresAt > latest then latest = cards[i].expiresAt end
        end

        if os.time() < latest then return latest end
        return nil
    end

    ---@param source number
    ---@return boolean
    function shared.checkVIP(source)
        return shared.getVipExpiry(source) ~= nil
    end

    ---@param source number
    ---@return integer
    ---@diagnostic disable-next-line: duplicate-set-field
    function shared.getChip(source)
        return ox_inventory:GetItemCount(source, shared.chipItemName) or 0
    end

    ---@param source number
    ---@param amount integer
    ---@return boolean
    ---@diagnostic disable-next-line: duplicate-set-field
    function shared.removeChip(source, amount)
        amount = math.floor(tonumber(amount) or 0)
        if amount <= 0 then return false end
        return ox_inventory:RemoveItem(source, shared.chipItemName, amount)
    end

    ---@param source number
    ---@param amount integer
    ---@return boolean
    ---@diagnostic disable-next-line: duplicate-set-field
    function shared.addChip(source, amount)
        amount = math.floor(tonumber(amount) or 0)
        if amount <= 0 then return false end
        return ox_inventory:AddItem(source, shared.chipItemName, amount)
    end

    ---@param amount number
    ---@param reason string?
    ---@param rate number?
    ---@return boolean
    function shared.depositCasinoIncome(amount, reason, rate)
        amount = math.floor(tonumber(amount) or 0)
        if amount <= 0 then return false end

        rate = tonumber(rate) or shared.casinoBankIncomeRate
        local deposit = math.floor(amount * rate)
        if deposit <= 0 then return false end

        local ok, err = pcall(function()
            exports['Renewed-Banking']:addAccountMoney(shared.casinoBankAccount, deposit)
        end)

        if not ok then
            lib.print.warn(('Failed to deposit casino income (%s): %s'):format(reason or 'unknown', err))
            return false
        end

        return true
    end

    ---@param source number
    ---@param lossAmount number
    ---@param game string?
    ---@return boolean
    function shared.depositCasinoLoss(source, lossAmount, game)
        lossAmount = math.floor(tonumber(lossAmount) or 0)

        if lossAmount > 0 then
            shared.log({
                title = 'Player Loss',
                type = 'error',
                fields = {
                    { name = 'Player', value = ('%s (%s)'):format(shared.getPlayerName(source), source) },
                    { name = 'Game', value = game or 'unknown', inline = true },
                    { name = 'Loss', value = ('%s chips'):format(lossAmount), inline = true },
                },
            })
        end

        return shared.depositCasinoIncome(lossAmount, game or ('player:%s'):format(source))
    end

    ---@param winnings number
    ---@return integer fee
    function shared.getWinningsFee(winnings)
        winnings = math.floor(tonumber(winnings) or 0)
        if winnings <= 0 then return 0 end
        local fee = math.floor(winnings * shared.casinoWinningsFeeRate)
        if fee < 0 then return 0 end
        if fee > winnings then return winnings end
        return fee
    end

    ---@param difficulty CasinoDifficulty?
    ---@return number winChance 0-100
    function shared.getDifficultyWinChance(difficulty)
        if type(difficulty) ~= 'table' then return 100 end
        local preset = difficulty.presets and difficulty.presets[difficulty.level]
        local chance = preset and tonumber(preset.winChance)
        if not chance then return 100 end
        return math.min(math.max(chance, 0), 100)
    end

    ---Rolls the difficulty win-gate. Returns true when a winning outcome is allowed to pay out.
    ---@param difficulty CasinoDifficulty?
    ---@return boolean
    function shared.rollDifficulty(difficulty)
        local chance = shared.getDifficultyWinChance(difficulty)
        if chance >= 100 then return true end
        if chance <= 0 then return false end
        return math.random() * 100 <= chance
    end

    ---@param amount number
    ---@param reason string?
    ---@return boolean, number
    function shared.withdrawCasinoPayout(amount, reason)
        if not shared.casinoBankPayoutEnabled then return true, 0 end

        amount = math.floor(tonumber(amount) or 0)
        if amount <= 0 then return true, 0 end

        local withdraw = math.floor(amount * shared.casinoBankPayoutRate)
        if withdraw <= 0 then return true, 0 end

        local ok, result = pcall(function()
            return exports['Renewed-Banking']:removeAccountMoney(shared.casinoBankAccount, withdraw)
        end)

        if not ok or result == false then
            lib.print.warn(('Failed to withdraw casino payout (%s): %s'):format(reason or 'unknown', result))
            return false
        end

        return true, withdraw
    end

    ---Refunds a casino bank payout when prize delivery fails after bank withdrawal.
    ---@param amount number
    ---@param reason string?
    ---@return boolean
    function shared.refundCasinoPayout(amount, reason)
        amount = math.floor(tonumber(amount) or 0)
        if amount <= 0 then return true end

        local ok, err = pcall(function()
            exports['Renewed-Banking']:addAccountMoney(shared.casinoBankAccount, amount)
        end)

        if not ok then
            lib.print.warn(('Failed to refund casino payout (%s): %s'):format(reason or 'unknown', err))
            return false
        end

        return true
    end

    ---@param label string
    ---@param source number
    ---@param tag string
    ---@param amount integer
    ---@param winnings integer
    ---@param fee integer
    ---@param payout integer
    local function printPrizeDebug(label, source, tag, amount, winnings, fee, payout)
        lib.print.info(('\n'
            .. '┌─ %s ─────────────────────────\n'
            .. '│ player    : %s (%s)\n'
            .. '│ tag       : %s\n'
            .. '│ amount    : %s\n'
            .. '│ winnings  : %s\n'
            .. '│ fee       : %s (%s%%)\n'
            .. '│ payout    : %s\n'
            .. '└──────────────────────────────'
        ):format(label, shared.getPlayerName(source), source, tag, amount, winnings, fee, shared.casinoWinningsFeeRate * 100, payout))
    end

    ---@param source number
    ---@param amount number
    ---@param game string?
    ---@param bankAmount number?
    ---@return boolean
    function shared.payCasinoChipPrize(source, amount, game, bankAmount)
        amount = math.floor(tonumber(amount) or 0)
        if amount <= 0 then return false end

        local winnings = math.floor(tonumber(bankAmount) or amount)
        local fee = shared.getWinningsFee(winnings)
        local payout = amount - fee
        if payout <= 0 then return false end

        printPrizeDebug('CHIP PRIZE', source, game or 'chip_prize', amount, winnings, fee, payout)

        local payoutOk, withdrawn = shared.withdrawCasinoPayout(winnings, game or 'chip_prize')
        if not payoutOk then
            lib.notify(source, {
                title = 'Casino',
                description = 'Rekening casino gagal membayar hadiah. Hubungi staff.',
                type = 'warning',
            })
            return false
        end

        if ox_inventory:AddItem(source, shared.chipItemName, payout) then
            shared.recordChipWinnings(source, payout, game)
            if fee > 0 then
                shared.depositCasinoIncome(fee, (game or 'chip_prize') .. '_fee', 1.0)
            end

            shared.log({
                title = 'Chip Winnings',
                type = 'money',
                fields = {
                    { name = 'Player', value = ('%s (%s)'):format(shared.getPlayerName(source), source) },
                    { name = 'Game', value = game or 'chip_prize', inline = true },
                    { name = 'Total', value = ('%s chips'):format(amount), inline = true },
                    { name = 'Fee', value = ('%s (%s%%)'):format(fee, shared.casinoWinningsFeeRate * 100), inline = true },
                    { name = 'Payout', value = ('%s chips'):format(payout), inline = true },
                },
            })

            return true
        end

        shared.refundCasinoPayout(withdrawn, game or 'chip_prize')
        lib.notify(source, {
            title = 'Casino',
            description = 'Hadiah gagal diberikan ke inventory. Hubungi staff.',
            type = 'warning',
        })

        return false
    end

    ---@param source number
    ---@param amount number
    ---@param reason string?
    ---@return boolean
    function shared.payCasinoMoneyPrize(source, amount, reason)
        amount = math.floor(tonumber(amount) or 0)
        if amount <= 0 then return false end

        local fee = shared.getWinningsFee(amount)
        local payout = amount - fee
        if payout <= 0 then return false end

        printPrizeDebug('MONEY PRIZE', source, reason or 'money_prize', amount, amount, fee, payout)

        local payoutOk, withdrawn = shared.withdrawCasinoPayout(amount, reason or 'money_prize')
        if not payoutOk then
            lib.notify(source, {
                title = 'Casino',
                description = 'Rekening casino gagal membayar hadiah. Hubungi staff.',
                type = 'warning',
            })
            return false
        end

        ox_inventory:SetLogContext(source, 'money', ('casino-prize:%s'):format(reason or 'money_prize'))

        if ox_inventory:AddItem(source, 'money', payout) then
            if fee > 0 then
                shared.depositCasinoIncome(fee, (reason or 'money_prize') .. '_fee', 1.0)
            end

            shared.log({
                title = 'Money Winnings',
                type = 'money',
                fields = {
                    { name = 'Player', value = ('%s (%s)'):format(shared.getPlayerName(source), source) },
                    { name = 'Source', value = reason or 'money_prize', inline = true },
                    { name = 'Total', value = ('$%s'):format(amount), inline = true },
                    { name = 'Fee', value = ('$%s (%s%%)'):format(fee, shared.casinoWinningsFeeRate * 100), inline = true },
                    { name = 'Payout', value = ('$%s'):format(payout), inline = true },
                },
            })

            return true
        end

        shared.refundCasinoPayout(withdrawn, reason or 'money_prize')
        lib.notify(source, {
            title = 'Casino',
            description = 'Hadiah gagal diberikan ke inventory. Hubungi staff.',
            type = 'warning',
        })

        return false
    end

    ---@param source number
    ---@param amount number
    ---@param game string?
    ---@return boolean
    function shared.recordChipWinnings(source, amount, game)
        return storage.recordChipWinnings(source, amount, game)
    end

    ---@param source number
    ---@return integer
    function shared.getTotalChipWinnings(source)
        local identifier = shared.getIdentifier(source)
        return storage.getTotalChipWinnings(identifier)
    end

    ---@param top number?
    ---@return table[]
    function shared.getTopChipWinners(top)
        return storage.getTopChipWinners(top)
    end

    ---@param count number?
    ---@return table[]
    function shared.getTopSpender(count)
        return storage.spender.getTopSpender(count)
    end

    ---@param data { name: string, image: string?, amount: number }
    ---@return boolean
    function shared.insertOrUpdateSpender(data)
        return storage.spender.insertOrUpdate(data)
    end

    ---@param identifier string
    ---@param tableId integer
    ---@param chips integer
    function shared.saveBuyIn(identifier, tableId, chips)
        return storage.saveBuyIn(identifier, tableId, chips)
    end

    ---@param identifier string
    ---@param tableId? integer
    ---@return BuyInData?
    function shared.loadBuyIn(identifier, tableId)
        return storage.loadBuyIn(identifier, tableId)
    end

    ---@param identifier string
    ---@param tableId? integer
    function shared.clearBuyIn(identifier, tableId)
        return storage.clearBuyIn(identifier, tableId)
    end

    ---@param source number
    ---@return boolean
    ---@diagnostic disable-next-line: duplicate-set-field
    function shared.playerExist(source)
        return GetPlayerName(source) ~= nil
    end

    ---@param source number
    ---@return 'male'|'female'
    function shared.getGender(source)
        local charinfo = sm_core:GetPlayerData(source, 'charinfo')
        if charinfo then
            local g = charinfo.gender
            if g == 1 or g == 'female' or g == 'f' then return 'female' end
        end
        return 'male'
    end

    ---Sends a casino log entry to Discord through the queued logger.
    ---@param data CasinoLogData
    function shared.log(data)
        return logger.log(data)
    end

    exports('getIdentifier', shared.getIdentifier)
    exports('getPlayerName', shared.getPlayerName)
    exports('getTotalChipWinnings', shared.getTotalChipWinnings)
    exports('getTopChipWinners', shared.getTopChipWinners)
    exports('getTopSpender', shared.getTopSpender)
    exports('insertOrUpdateSpender', shared.insertOrUpdateSpender)
    exports('log', shared.log)
end

---@param v vector3
---@param angleDeg number
---@return vector3
function shared.rotateVec3(v, angleDeg)
    local rad = math.rad(angleDeg)
    local sinA = math.sin(rad)
    local cosA = math.cos(rad)
    return vec3(
        v.x * cosA - v.y * sinA,
        v.x * sinA + v.y * cosA,
        v.z
    )
end

for i = 1, #casino do
    local moduleName = casino[i]
    local modulePath = ('casino.%s.%s'):format(moduleName, lib.context)

    local success, err = pcall(require, modulePath)

    if not success then
        lib.print.warn(('Failed to load module: %s'):format(modulePath))
        lib.print.error(err)
    end
end

local duiPath = ('leaderboards.%s'):format(lib.context)
require (duiPath)
