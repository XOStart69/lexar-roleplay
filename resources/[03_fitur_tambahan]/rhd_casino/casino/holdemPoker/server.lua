_ENV.CasinoPoker = {}
---@param source number
---@param message string
function CasinoPoker.notify(source, message)
    return TriggerCasinoEvent('rhd_casino_holdemPoker:notify', source, message)
end

---@param source number
---@return integer|nil
function CasinoPoker.getPlayerTableId(source)
    return lib.array.find(CasinoPoker.tables, function (table)
        return lib.array.includes(table._playersOpened, source)
    end)?._index
end

---@param source number
---@return PokerTable|nil
function CasinoPoker.getInstanceBySource(source)
    local tableId = CasinoPoker.getPlayerTableId(source)
    if not tableId then return end
    return CasinoPoker.tables[tableId]
end

local restoring = {}

---@param source number
---@return boolean
function CasinoPoker.restoreSavedChips(source)
    if restoring[source] then return false end

    local identifier = shared.getIdentifier(source)
    if not identifier then return false end

    restoring[source] = true
    local restoredAll = true

    for index, instance in pairs(CasinoPoker.tables) do
        local seat = instance:getPlayerChairData(source)
        local saved = (not seat or seat.disconnected) and shared.loadBuyIn(identifier --[[@as string]], index)

        if saved then
            if saved.chips > 0 and not shared.addChip(source, saved.chips) then
                restoredAll = false
                lib.notify(source, {
                    title = 'Casino Poker',
                    description = ('Inventory penuh. %s chip poker tersimpan belum bisa dikembalikan.'):format(saved.chips),
                    type = 'error',
                })
            else
                shared.clearBuyIn(identifier --[[@as string]], index)

                if saved.chips > 0 then
                    lib.notify(source, {
                        title = 'Casino Poker',
                        description = ('%s chip dari sesi poker sebelumnya sudah dikembalikan ke inventory.'):format(saved.chips),
                        type = 'success',
                    })
                    shared.log({
                        title = 'Poker Chips Restored',
                        type = 'money',
                        fields = {
                            { name = 'Player', value = ('%s (%s)'):format(shared.getPlayerName(source), source) },
                            { name = 'Table', value = tostring(index), inline = true },
                            { name = 'Chips', value = ('%s chips'):format(saved.chips), inline = true },
                        },
                    })
                end
            end
        end
    end

    restoring[source] = nil
    return restoredAll
end

require 'casino.holdemPoker.modules.player'
require 'casino.holdemPoker.modules.tables'
require 'casino.holdemPoker.bot.server'

CreateThread(function()
    while true do
        for _, instance in pairs(CasinoPoker.tables) do
            instance:tickTime()
        end
        Wait(1000)
    end
end)

RegisterNetEvent('rhd_casino_holdemPoker:state', function(index, state)
    local source = source
    index = math.floor(tonumber(index) or 0)
    local ptable = CasinoPoker.tables[index]
    if not ptable then return end
    ptable:openedStatePlayer(source, state == true)
end)

RegisterNetEvent('rhd_casino_holdemPoker:joinPlayer', function()
    local source = source
    local instance = CasinoPoker.getInstanceBySource(source)
    if not instance then return end
    instance:joinPlayer(source)
end)

RegisterNetEvent('rhd_casino_holdemPoker:allIn', function()
    local source = source
    local instance = CasinoPoker.getInstanceBySource(source)
    if not instance then return end
    instance:allInPoker(source)
end)

RegisterNetEvent('rhd_casino_holdemPoker:fold', function()
    local source = source
    local instance = CasinoPoker.getInstanceBySource(source)
    if not instance then return end
    instance:throwPoker(source, false)
end)

RegisterNetEvent('rhd_casino_holdemPoker:pass', function()
    local source = source
    local instance = CasinoPoker.getInstanceBySource(source)
    if not instance then return end
    instance:passPoker(source)
end)

RegisterNetEvent('rhd_casino_holdemPoker:call', function()
    local source = source
    local instance = CasinoPoker.getInstanceBySource(source)
    if not instance then return end
    instance:callPoker(source)
end)

RegisterNetEvent('rhd_casino_holdemPoker:bet', function(betAmount)
    local source = source
    local instance = CasinoPoker.getInstanceBySource(source)
    if not instance then return end
    instance:betPoker(source, { amount = betAmount })
end)

RegisterNetEvent('rhd_casino_holdemPoker:setPlayerImage', function(url)
    local source = source
    if type(url) ~= 'string' or #url > 512 then return end
    if not url:match('^https?://') and not url:match('^images/') then return end

    CasinoPoker.player:setImage(source, url)
end)

RegisterNetEvent('rhd_casino_holdemPoker:rebuy', function(args)
    local source = source
    local instance = CasinoPoker.getInstanceBySource(source)
    if not instance then return end
    local amount = type(args) == 'table' and args.amount or args
    instance:rebuyPlayer(source, amount)
end)

lib.callback.register('rhd_casino_holdemPoker:canJoin', function (source, index)
    index = math.floor(tonumber(index) or 0)
    local instance = CasinoPoker.tables[index]
    if not instance then return false end
    if not instance:isPlayerNear(source) then return false end

    for _, tableInstance in pairs(CasinoPoker.tables) do
        if tableInstance:isPlayerSitAtTable(source) then
            return false
        end
    end

    if not instance:getFreeChairId() then
        return lib.notify(source, {
            title = 'Poker',
            description = 'Semua kursi di meja ini sedang digunakan.',
            type = 'error',
        })
    end
    
    if instance._vipOnly and not shared.checkVIP(source) then
        return lib.notify(source, {
            title = 'Akses Ditolak',
            description = 'Meja ini hanya untuk pemain VIP. Dapatkan VIP untuk bisa bermain di meja ini!',
            type = 'error',
        })
    end
    
    return true
end)

---@param source number
---@param dropped boolean
local function releasePlayer(source, dropped)
    for _, instance in pairs(CasinoPoker.tables) do
        local inOpened = lib.array.includes(instance._playersOpened, source)
        local inChair = instance:isPlayerSitAtTable(source)
        if inOpened or inChair then
            local playerData = inChair and instance:getPlayerChairData(source)
            if playerData and playerData.disconnected then return end

            instance:openedStatePlayer(source, false, dropped)
            break
        end
    end
end

AddEventHandler('playerDropped', function()
    releasePlayer(source, true)
end)

AddEventHandler('rhd_casino:releasePlayer', function(playerId, reason)
    releasePlayer(playerId, reason == 'disconnect')
end)

AddEventHandler('rhd_casino:interiorChanged', function(playerId, state)
    if state then
        CasinoPoker.restoreSavedChips(playerId)
    end
end)

RegisterNetEvent('rhd_spawn:server:onSpawn', function()
    local source = source
    local identifier = shared.getIdentifier(source)
    if not identifier then return end
    local savedBuyIn = shared.loadBuyIn(identifier)
    if savedBuyIn and savedBuyIn.chips > 0 then
        lib.notify(source, {
            title = 'Casino Poker',
            description = ('Kamu memiliki %s chips yang tersimpan dari sesi poker sebelumnya. Kunjungi kasino untuk mengambilnya!'):format(savedBuyIn.chips),
            type = 'inform',
            duration = 8000,
        })
    elseif savedBuyIn then
        shared.clearBuyIn(identifier)
    end
end)
