local common = require "compat.common"
local ped = require "core.ped"
local editor = require "core.editor"
local shops = require "features.shops"

RegisterNetEvent("esx_skin:openSaveableMenu", function(onSubmit, onCancel)
    shops.clear()

    editor.open(nil, function(appearance)
        if appearance then
            if onSubmit then onSubmit() end
        elseif onCancel then
            onCancel()
        end
    end)
end)

RegisterNetEvent("esx_skin:openRestrictedMenu", function(_, onSubmit, onCancel)
    TriggerEvent("esx_skin:openSaveableMenu", onSubmit, onCancel)
end)

RegisterNetEvent("skinchanger:loadSkin", function(skin, cb)
    if skin then ped.applyToPlayer(skin) end

    if cb then cb() end
end)

RegisterNetEvent("skinchanger:loadSkin2", function(entity, skin)
    if skin then ped.apply(entity, skin) end
end)

RegisterNetEvent("skinchanger:loadClothes", function(_, clothes)
    common.wearClothes(clothes)
end)

RegisterNetEvent("skinchanger:getSkin", function(cb)
    if cb then cb(ped.get(cache.ped)) end
end)
