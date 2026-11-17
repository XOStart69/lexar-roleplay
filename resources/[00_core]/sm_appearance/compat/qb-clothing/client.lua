local common = require "compat.common"
local ped = require "core.ped"
local editor = require "core.editor"
local outfits = require "features.outfits"
local commands = require "features.commands"
local forced = require "features.forced"

RegisterNetEvent("qb-clothing:client:openMenu", function()
    commands.pedmenu()
end)

RegisterNetEvent("qb-clothing:client:openOutfitMenu", function()
    outfits.open()
end)

RegisterNetEvent("qb-clothing:client:loadOutfit", common.wearOutfit)

RegisterNetEvent("qb-clothing:client:loadPlayerClothing", function(appearance)
    if appearance then
        ped.applyToPlayer(appearance)
        return forced.reapply()
    end

    editor.load()
end)

RegisterNetEvent("qb-multicharacter:client:chooseChar", function()
    ClearPedDecorations(cache.ped)
end)
