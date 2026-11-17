---@class PokerPlayers
local Players = lib.class('PokerPlayers')

local storage = require 'modules.storage'

function Players:constructor()
    self._players = {}
    self._identifiers = {}
end

---@param source number
function Players:addPlayer(source)
    local identifier = shared.getIdentifier(source)
    if not identifier then return end

    local savedImg = storage.getPokerImage(identifier)
    if not savedImg or savedImg == '' then
        local gender = shared.getGender(source)
        savedImg = gender == 'female' and 'images/user/user-women.png' or 'images/user/user-man.png'
    end

    self._players[identifier] = {
        img = savedImg,
    }
    self._identifiers[source] = identifier
end

---@param source number
function Players:removePlayer(source)
    local identifier = self._identifiers[source]
    if not identifier then return end

    self._players[identifier] = nil
    self._identifiers[source] = nil
end

---@param source number
---@param url string
function Players:setImage(source, url)
    local identifier = self._identifiers[source]
    local player = identifier and self._players[identifier]
    if not player then return end

    player.img = url
    storage.setPokerImage(identifier, url)

    local tableId = CasinoPoker.getPlayerTableId(source)
    local tableInstance = CasinoPoker.tables[tableId]

    if tableInstance then
        tableInstance:updatePlayerImages()
    end
end

---@param source number
---@return string|nil
function Players:getPlayerImage(source)
    local identifier = self._identifiers[source]
    local player = identifier and self._players[identifier]
    return player and player.img or nil
end

---@param source number
function Players:updatePlayerChips(source)
    local instance = CasinoPoker.getInstanceBySource(source)
    local playerData = instance and instance:getPlayerChairData(source)
    local chips = playerData and playerData.chips or shared.getChip(source)
    TriggerCasinoEvent('rhd_casino_holdemPoker:setVariables', source, 'mychips', chips)
end

---@diagnostic disable-next-line: undefined-field
CasinoPoker.player = Players:new()

AddEventHandler('rhd_casino:interiorChanged', function (source, state)
    if state then
        CasinoPoker.player:addPlayer(source)
        CasinoPoker.player:updatePlayerChips(source)
    else
        CasinoPoker.player:removePlayer(source)
    end
end)

AddEventHandler('playerDropped', function()
    local source = source
    CasinoPoker.player:removePlayer(source)
end)
