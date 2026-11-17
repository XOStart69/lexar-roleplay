local common = require "compat.common"
local ped = require "core.ped"
local editor = require "core.editor"
local outfits = require "features.outfits"
local shops = require "features.shops"
local commands = require "features.commands"
local forced = require "features.forced"

local RESOURCE = "illenium-appearance"

---@param name string
---@param fn function
local function alias(name, fn)
    common.alias(RESOURCE, name, fn)
end

alias("startPlayerCustomization", function()
    shops.clear()
    editor.open()
end)

alias("getPedModel", function(entity)
    return ped.getModel(entity)
end)

alias("getPedComponents", function(entity)
    return ped.getComponents(entity)
end)

alias("getPedProps", function(entity)
    return ped.getProps(entity)
end)

alias("getPedHeadBlend", function(entity)
    return ped.getHeadBlend(entity)
end)

alias("getPedFaceFeatures", function(entity)
    return ped.getFaceFeatures(entity)
end)

alias("getPedHeadOverlays", function(entity)
    return ped.getHeadOverlays(entity)
end)

alias("getPedHair", function(entity)
    return ped.getHair(entity)
end)

alias("getPedAppearance", function(entity)
    return ped.get(entity)
end)

alias("setPlayerModel", function(model)
    return ped.setModel(model)
end)

alias("setPedHeadBlend", function(entity, headBlend)
    ped.setHeadBlend(entity, headBlend)
end)

alias("setPedFaceFeatures", function(entity, faceFeatures)
    ped.setFaceFeatures(entity, faceFeatures)
end)

alias("setPedHeadOverlays", function(entity, headOverlays)
    ped.setHeadOverlays(entity, headOverlays)
end)

alias("setPedHair", function(entity, hair, tattoos)
    ped.setHair(entity, hair)

    if tattoos then
        ped.setTattoos(entity, tattoos)
    end
end)

alias("setPedEyeColor", function(entity, eyeColor)
    ped.setEyeColor(entity, eyeColor)
end)

alias("setPedComponent", function(entity, component)
    ped.setComponent(entity, component)
    forced.reapply(entity)
end)

alias("setPedComponents", function(entity, components)
    ped.setComponents(entity, components)
    forced.reapply(entity)
end)

alias("setPedProp", function(entity, prop)
    ped.setProp(entity, prop)
end)

alias("setPedProps", function(entity, props)
    ped.setProps(entity, props)
end)

alias("setPlayerAppearance", function(appearance)
    ped.applyToPlayer(appearance)
    forced.reapply()
end)

alias("setPedAppearance", function(entity, appearance)
    ped.apply(entity, appearance)
    forced.reapply(entity)
end)

alias("setPedTattoos", function(entity, tattoos)
    ped.setTattoos(entity, tattoos)
end)

alias("GetSkin", function()
    return ped.get(cache.ped)
end)

alias("LoadSkin", function(skin, cb)
    if skin then
        ped.applyToPlayer(skin)
        forced.reapply()
    end

    if cb then cb() end
end)

alias("LoadClothes", function(_, clothes)
    common.wearClothes(clothes)
end)

local SHOP_EVENTS = {
    ["illenium-appearance:client:openClothingShop"] = "clothing",
    ["illenium-appearance:client:openClothingShopMenu"] = "clothing",
    ["illenium-appearance:client:OpenBarberShop"] = "barber",
    ["illenium-appearance:client:OpenTattooShop"] = "tattoo",
    ["illenium-appearance:client:OpenSurgeonShop"] = "surgeon"
}

for event, shopType in pairs(SHOP_EVENTS) do
    RegisterNetEvent(event, function(isPedMenu)
        if isPedMenu then
            return commands.pedmenu()
        end

        shops.open(shopType)
    end)
end

RegisterNetEvent("illenium-appearance:client:openOutfitMenu", function()
    outfits.open()
end)

RegisterNetEvent("illenium-appearance:client:OpenPlayerOutfitRoom", function()
    outfits.open()
end)

RegisterNetEvent("illenium-appearance:client:saveOutfit", function()
    outfits.open()
end)

RegisterNetEvent("illenium-appearance:client:updateOutfit", function()
    outfits.open()
end)

RegisterNetEvent("illenium-appearance:client:importOutfitCode", function()
    outfits.open()
end)

RegisterNetEvent("illenium-appearance:client:OpenClothingRoom", function()
    outfits.openJob(Framework.getState())
end)

RegisterNetEvent("illenium-appearance:client:openJobOutfitsMenu", function()
    outfits.openJob(Framework.getState())
end)

RegisterNetEvent("illenium-apearance:client:outfitsCommand", function(isJob)
    if isJob then
        return outfits.openJob(Framework.getState())
    end

    outfits.open()
end)

RegisterNetEvent("illenium-appearance:client:changeOutfit", common.wearOutfit)
RegisterNetEvent("illenium-appearance:client:loadJobOutfit", common.wearOutfit)

RegisterNetEvent("illenium-appearance:client:deleteOutfit", function(id)
    lib.callback.await("rhd_appearance:outfits:delete", false, id)
end)

RegisterNetEvent("illenium-appearance:client:generateOutfitCode", function(id)
    local code = lib.callback.await("rhd_appearance:outfits:generateCode", false, id)

    if not code then
        return lib.notify({ description = locale("outfits.codeFailed"), type = "error" })
    end

    lib.setClipboard(code)
    lib.notify({ description = locale("outfits.share.code"), type = "success" })
end)

RegisterNetEvent("illenium-appearance:client:reloadSkin", function()
    editor.load()
end)

RegisterNetEvent("illenium-appearance:client:ClearStuckProps", function()
    commands.clearstuckprops()
end)

local unsupported = common.reporter()

local UNSUPPORTED = {
    "illenium-appearance:client:OutfitManagementMenu",
    "illenium-appearance:client:SaveManagementOutfit",
    "illenium-appearance:client:DeleteManagementOutfit"
}

for i = 1, #UNSUPPORTED do
    local event = UNSUPPORTED[i]

    RegisterNetEvent(event, function()
        unsupported(event)
    end)
end
