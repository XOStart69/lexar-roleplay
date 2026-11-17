local rankingConfig = require 'leaderboards.config'

---@class LeaderboardsDui
local dui = lib.class('LeaderboardsDui')

---@param leaderboardType 'winning' | 'spender' | 'luar1' | 'luar2' kunci texture dict yang di-replace
---@param duiName string nama folder halaman di dui/html
function dui:constructor(leaderboardType, duiName)
    
    self.texture = {
        dict = ('leaderboard%s'):format(leaderboardType),
        name = 'v_glass_dv_10percentgrey_a_1',
    }

    self.dui = lib.dui:new({
        url = ("nui://%s/dui/html/%s/index.html"):format(cache.resource, duiName),
        width = 512,
        height = 1080,
        debug = false
    })

    lib.waitFor(function ()
        if IsDuiAvailable(self.dui.duiObject) then
            return true
        end
    end, 'Failed to create leaderboard Dui after 5 seconds', 5000)

    RemoveReplaceTexture(self.texture.dict, self.texture.name)
    AddReplaceTexture(self.texture.dict, self.texture.name, self.dui.dictName, self.dui.txtName)
end

function dui:destroy()
    RemoveReplaceTexture(self.texture.dict, self.texture.name)
    self.dui:remove()
end

local function mockEntries(count, top1Amount)
    local entries = {}

    for i=1, count do
        local amount = math.floor(top1Amount * (1 - (i - 1) * 0.1))
        if amount < 0 then amount = 0 end
        table.insert(entries, {
            name = ('Player%d'):format(i),
            amount = amount,
            image = ('https://randomuser.me/api/portraits/lego/%d.jpg'):format(i)
        })
    end
    return entries
end

local casinoDui = {}
local debugMode = false

local function prepareWinners(sEntries)
    local entries = {}
    local winners = sEntries or lib.callback.await('rhd_casino_leaderboards:getWinnersLeaderboard', 500)
    if #winners > 0 then
        for i=1, #winners do
            local w = winners[i]
            entries[#entries+1] = {
                id = w.id,
                name = w.name or w.player_name,
                amount = w.amount or w.totalchipwin or w.total_chip_winnings,
                image = w.image
            }
        end
    end

    if debugMode then
        entries = lib.array.merge(entries, mockEntries(10 - #entries, entries[1] and entries[1].amount or 100000))
    end

    return entries
end

local function prepareSpenders(sEntries)
    local entries = {}
    local spenders = sEntries or lib.callback.await('rhd_casino_leaderboards:getSpendersLeaderboard', 500)
    if #spenders > 0 then
        for i=1, #spenders do
            local spender = spenders[i]
            entries[#entries+1] = {
                id = spender.id,
                name = spender.name,
                amount = spender.amount,
                image = spender.image
            }
        end
    end

    if debugMode then
        entries = lib.array.merge(entries, mockEntries(10 - #entries, entries[1] and entries[1].amount or 100000))
    end

    return entries
end

local function registerNuiServerCallback(name)
    RegisterNUICallback(name, function (data, cb)
        local success = lib.callback.await(('rhd_casino_leaderboards:%s'):format(name), 500, data)
        cb({ success =  success })
    end)
end

RegisterNetEvent('rhd_casino_leaderboards:updateWinners', function (entries)
    if source == '' then return end

    if casinoDui.winners?.dui and IsDuiAvailable(casinoDui.winners?.dui?.duiObject) then
        casinoDui.winners.dui:sendMessage({
            action = 'set_casino_winners',
            data = {
                entries = prepareWinners(entries)
             }
         })
    end
end)

RegisterNetEvent('rhd_casino_leaderboards:updateSpenders', function (entries)
    if source == '' then return end

    if casinoDui.spenders?.dui and IsDuiAvailable(casinoDui.spenders?.dui?.duiObject) then
        casinoDui.spenders.dui:sendMessage({
            action = 'set_casino_spenders',
            data = {
                entries = prepareSpenders(entries)
             }
         })
    end
end)

for _, name in ipairs({ 'getManageData', 'resetChipWinnings' }) do
    local event = ('rhd_casino_leaderboards:%s'):format(name)

    RegisterNUICallback(event, function (_, cb)
        local ok, result = lib.callback.await(event, false)

        cb({
            ok = ok == true,
            data = ok == true and result or nil,
            error = ok ~= true and result or nil,
        })
    end)
end

for _, name in ipairs({ 'getRankings', 'saveRanking', 'removeRanking' }) do
    local event = ('rhd_casino_leaderboards:%s'):format(name)

    RegisterNUICallback(event, function (data, cb)
        local ok, result = lib.callback.await(event, false, data)

        cb({
            ok = ok == true,
            data = ok == true and result or nil,
            error = ok ~= true and result or nil,
        })
    end)
end

registerNuiServerCallback('update_spender')
registerNuiServerCallback('remove_spender')

local rankingDui = {}
local rankingPending = {}
local rankingInRange = {}

---@param board string
---@param entries table[]
local function sendRanking(board, entries)
    local screen = rankingDui[board]
    if not screen?.dui or not IsDuiAvailable(screen.dui.duiObject) then return end

    local rows = {}
    for i = 1, #entries do
        local entry = entries[i]
        rows[i] = {
            name = entry.name,
            image = entry.image,
            amount = board == 'fight' and entry.wins or entry.points,
            wins = entry.wins,
            losses = entry.losses,
        }
    end

    screen.dui:sendMessage({
        action = 'set_casino_rankings',
        data = {
            entries = rows
        }
    })
end

RegisterNetEvent('rhd_casino_leaderboards:updateRanking', function (board, entries)
    if source == '' then return end
    sendRanking(board, type(entries) == 'table' and entries or {})
end)

for board, screen in pairs(rankingConfig.screens) do
    lib.points.new({
        coords = screen.coords,
        distance = rankingConfig.renderDistance,
        onEnter = function ()
            rankingInRange[board] = true
            if rankingDui[board] or rankingPending[board] then return end

            rankingPending[board] = true
            CreateThread(function ()
                local created = dui:new(screen.prop, screen.page)
                rankingPending[board] = nil

                if not rankingInRange[board] then
                    created:destroy()
                    return
                end

                rankingDui[board] = created
                Wait(1500)
                sendRanking(board, lib.callback.await('rhd_casino_leaderboards:getRankingScreen', false, board) or {})
            end)
        end,
        onExit = function ()
            rankingInRange[board] = false

            local created = rankingDui[board]
            if not created then return end

            created:destroy()
            rankingDui[board] = nil
        end,
    })
end

useAreaHooks(function (state)
    if state then
        casinoDui.winners = dui:new('winning', 'leaderboardWinners')
        casinoDui.spenders = dui:new('spender', 'leaderboardSpenders')

        Wait(1500)
        if casinoDui.winners?.dui then
            casinoDui.winners.dui:sendMessage({
                action = 'set_casino_winners',
                data = {
                    entries = prepareWinners()
                }
            })
        end

        if casinoDui.spenders?.dui then
            casinoDui.spenders.dui:sendMessage({
                action = 'set_casino_spenders',
                data = {
                    entries = prepareSpenders()
                }
            })
        end
    else
        for k, v in pairs(casinoDui) do
             if v and type(v) == 'table' and v.destroy then
                v:destroy()
                casinoDui[k] = nil
            end
        end
    end
end)
