local events = require "modules.events"
local ped = require "core.ped"
local camera = require "core.camera"
local settings = require "core.settings"
local editor = require "core.editor"
local outfits = require "features.outfits"
local halfped = require "features.halfped"
local shops = require "features.shops"
local character = require "features.character"
local clothing = require "features.clothing"
local items = require "features.items"
local oplas = require "features.oplas"
local forced = require "features.forced"
local barber = require "features.barber"

require "features.commands"

RegisterNUICallback("appearance_get_locales", function(_, cb)
    cb(lib.getLocales())
end)

RegisterNUICallback("appearance_get_settings", function(_, cb)
    cb({ appearanceSettings = barber.settings() or settings.all(cache.ped) })
end)

RegisterNUICallback("appearance_get_data", function(_, cb)
    cb({
        config = editor.config(),
        appearanceData = editor.original() or ped.get(cache.ped),
        animations = editor.animations()
    })
end)

RegisterNUICallback("appearance_play_animation", function(name, cb)
    cb(editor.playAnimation(name))
end)

RegisterNUICallback("appearance_change_model", function(model, cb)
    if barber.active() then return cb(false) end

    local heading = GetEntityHeading(cache.ped)

    camera.suspend()
    local entity = ped.setModel(model)
    camera.resume()

    SetEntityHeading(entity, heading)
    editor.idle(entity, true)

    cb({
        appearanceSettings = settings.all(entity),
        appearanceData = ped.get(entity)
    })
end)

RegisterNUICallback("appearance_preview_model", function(model, cb)
    if barber.active() then return cb(false) end

    local heading = GetEntityHeading(cache.ped)

    camera.suspend()
    local entity = ped.setModel(model)
    camera.resume()

    SetEntityHeading(entity, heading)
    editor.idle(entity, true)

    cb({ appearanceSettings = settings.all(entity) })
end)

RegisterNUICallback("appearance_restore_model", function(appearanceData, cb)
    if barber.active() then return cb(false) end

    local heading = GetEntityHeading(cache.ped)

    camera.suspend()
    local entity = ped.applyToPlayer(appearanceData)
    camera.resume()

    SetEntityHeading(entity, heading)
    editor.idle(entity, true)

    cb({ appearanceSettings = settings.all(entity) })
end)

RegisterNUICallback("appearance_change_component", function(component, cb)
    ped.setComponent(cache.ped, component)

    if halfped.sync(cache.ped, component.component_id) then
        SendNuiMessage(json.encode({
            action = "appearance_head_blend",
            data = ped.getHeadBlend(cache.ped)
        }))
    end

    if not component.preview then
        editor.tryOn(cache.ped, component.component_id)
    end

    if clothing.forget("component", component.component_id) then
        clothing.push()
    end

    cb(settings.component(cache.ped, component.component_id))
end)

RegisterNUICallback("appearance_change_prop", function(prop, cb)
    ped.setProp(cache.ped, prop)

    if clothing.forget("prop", prop.prop_id) then
        clothing.push()
    end

    cb(settings.prop(cache.ped, prop.prop_id))
end)

RegisterNUICallback("appearance_change_hair", function(hair, cb)
    if barber.active() then return cb(barber.changeHair(hair)) end

    ped.setHair(cache.ped, hair)

    cb(settings.hair(cache.ped))
end)

RegisterNUICallback("appearance_change_head_blend", function(headBlend, cb)
    cb(1)
    ped.setHeadBlend(cache.ped, headBlend)
end)

RegisterNUICallback("appearance_change_face_feature", function(faceFeatures, cb)
    cb(1)
    ped.setFaceFeatures(cache.ped, faceFeatures)
end)

RegisterNUICallback("appearance_change_head_overlay", function(headOverlays, cb)
    cb(1)

    if barber.active() then return barber.changeOverlays(headOverlays) end

    ped.setHeadOverlays(cache.ped, headOverlays)
end)

RegisterNUICallback("appearance_change_eye_color", function(eyeColor, cb)
    if barber.active() then return cb(barber.changeEyeColor(eyeColor)) end

    ped.setEyeColor(cache.ped, eyeColor)

    cb(ped.getEyeColor(cache.ped))
end)

RegisterNUICallback("appearance_apply_tattoo", function(data, cb)
    local list = data.updatedTattoos or {}

    if not shops.allowTattoo(list) then return cb(false) end

    ped.setTattoos(cache.ped, list)

    cb(true)
end)

RegisterNUICallback("appearance_preview_tattoo", function(data, cb)
    cb(1)
    ped.previewTattoo(cache.ped, data.data, data.tattoo)
end)

RegisterNUICallback("appearance_delete_tattoo", function(tattoos, cb)
    cb(1)
    ped.setTattoos(cache.ped, tattoos)
end)

RegisterNUICallback("appearance_set_camera", function(key, cb)
    cb(1)
    camera.preset(key)
end)

RegisterNUICallback("appearance_camera_move", function(data, cb)
    cb(1)
    camera.move(data.dx, data.dy)
end)

RegisterNUICallback("appearance_camera_zoom", function(data, cb)
    cb(1)
    camera.zoom(data.delta)
end)

RegisterNUICallback("appearance_get_outfits", function(_, cb)
    cb(outfits.list())
end)

RegisterNUICallback("appearance_wear_outfit", function(id, cb)
    if not outfits.apply(id) then return cb(false) end

    local appearance = ped.get(cache.ped)

    editor.commit(items.underneath(appearance))

    cb({
        appearanceSettings = settings.all(cache.ped),
        appearanceData = appearance
    })
end)

---@return boolean
local function outfitBlocked()
    if not shops.unpaid() then return false end

    lib.notify({ description = locale("outfits.unpaid"), type = "error" })

    return true
end

RegisterNUICallback("appearance_save_outfit", function(name, cb)
    if outfitBlocked() then return cb(false) end

    cb(outfits.store(name))
end)

RegisterNUICallback("appearance_update_outfit", function(id, cb)
    if outfitBlocked() then return cb(false) end

    cb(outfits.overwrite(id))
end)

RegisterNUICallback("appearance_delete_outfit", function(id, cb)
    cb(outfits.delete(id))
end)

RegisterNUICallback("appearance_outfit_code", function(id, cb)
    cb(outfits.code(id) or false)
end)

RegisterNUICallback("appearance_import_outfit", function(data, cb)
    cb(outfits.import(data.name, data.code))
end)

RegisterNUICallback("appearance_preview_outfit", function(id, cb)
    cb(outfits.preview(id))
end)

RegisterNUICallback("appearance_end_outfit_preview", function(_, cb)
    cb(1)
    outfits.endPreview()
end)

RegisterNUICallback("appearance_save", function(data, cb)
    if barber.active() then return cb(false) end

    local appearance = items.underneath(data)
    local slot = settings.blocked(appearance)

    if slot then
        lib.notify({ description = locale("items.blocked", settings.label(slot)), type = "error" })

        return cb(false)
    end

    cb(1)

    outfits.endPreview()
    editor.close(appearance)
end)

RegisterNUICallback("appearance_exit", function(_, cb)
    cb(1)

    if barber.busy() then return end

    outfits.endPreview()
    editor.close()
end)

RegisterNUICallback("appearance_barber_submit", function(data, cb)
    barber.submit(data, cb)
end)

RegisterNUICallback("clothing_toggle", function(id, cb)
    if barber.active() then return cb(false) end

    cb(clothing.toggle(id, not editor.active()))
end)

RegisterNUICallback("clothing_toggle_group", function(items, cb)
    if barber.active() then return cb(barber.toggleHat(items)) end

    cb(clothing.toggleGroup(items))
end)

RegisterNUICallback("clothing_close", function(_, cb)
    cb(1)
    clothing.closeRail()
end)

local clothingKeybind = require("config.clothing").keybind

if clothingKeybind.key then
    lib.addKeybind({
        name = "rhd_clothing",
        description = locale("clothing.keybind"),
        defaultKey = clothingKeybind.key,
        defaultMapper = clothingKeybind.mapper,
        onPressed = function()
            if clothing.railOpen() then
                return clothing.closeRail()
            end

            if editor.active() then return end

            clothing.openRail()
        end
    })
end

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        clothing.reset(false)
        items.clear()
    end
end)

lib.callback.register("rhd_appearance:items:use", function(name)
    if editor.active() then
        lib.notify({ description = locale("items.inEditor"), type = "error" })

        return items.worn(name)
    end

    return items.toggle(name)
end)

lib.callback.register("rhd_appearance:oplas:open", function()
    return oplas.open()
end)

RegisterNetEvent("rhd_appearance:items:refuse", function(name)
    if source == '' then return end
    if not items.remove(name) then return end

    lib.notify({ description = locale("items.removedToMove"), type = "inform" })
end)

local function syncHalfPed()
    if halfped.refresh(cache.ped) then
        editor.save(ped.get(cache.ped))
    end
end

local function onPlayerLoaded()
    editor.load()
    syncHalfPed()
end

events.on("playerLoaded", onPlayerLoaded)
events.on("newCharacter", character.create)

local function suspendBodycam()
    pcall(function()
        exports.sm_bodycam:suspendProp()
    end)
end

local function restoreBodycam()
    pcall(function()
        exports.sm_bodycam:restoreProp()
    end)
end

events.on('onClothingMenuOpen', function(playerPed, conf)
    LocalPlayer.state.hide_itemattach = true
    suspendBodycam()
end)

events.on('onClothingMenuClose', function(playerPed, appearance)
    LocalPlayer.state.hide_itemattach = false
    restoreBodycam()
end)

events.on('onReloadskin', function(playerPed, data)
    if LocalPlayer.state.smFarmRide or LocalPlayer.state.smFarmBoarded then
        lib.notify({
            title = "Gagal Reload Skin",
            description = "Turun dari hewan dulu sebelum reloadskin.",
            type = "error",
        })
        return false
    end

    if exports.sm_resource_1:isCarryingSpeaker() then
        lib.notify({
            title = "Gagal Reload Skin",
            description = "Tidak bisa reloadskin saat sedang membawa speaker. Letakkan speaker terlebih dahulu.",
            type = "error",
        })
        return false
    end
    
    LocalPlayer.state.hide_itemattach = true

    suspendBodycam()

    pcall(function()
        exports['qb-ambulancejob']:HideCrutch()
    end)

    pcall(function(...)
        exports.jpx_props:clear()
    end)
end)

events.on('onReloadskinDone', function(playerPed, data)
    LocalPlayer.state.hide_itemattach = false
    restoreBodycam()
    pcall(function()
        exports['qb-ambulancejob']:ShowCrutch()
    end)
end)


AddStateBagChangeHandler("forcedOutfit", ("player:%s"):format(cache.serverId), function(_, _, value)
    if value then
        forced.apply(value)

        return
    end

    SetTimeout(0, editor.load)
end)

events.on("rhd_appearance:halfped:applied", function()
    if editor.active() then return end

    syncHalfPed()
    settings.reset()
end)

exports("openAppearance", function(conf, cb)
    shops.clear()
    editor.open(conf, cb)
end)

exports("openBarberMenu", function(options)
    shops.clear()

    return barber.open(options)
end)

exports("closeBarberMenu", barber.close)
exports("resolveBarberMenu", barber.resolve)
exports("getBarberSnapshot", barber.snapshot)
exports("applyBarberValues", barber.apply)
exports("setBarberHat", barber.setHat)

exports("loadAppearance", editor.load)
exports("openOutfits", outfits.open)
exports("openShop", shops.open)
exports("createCharacter", character.create)

exports("applyAppearance", function(entity, appearance)
    ped.apply(entity, appearance)
    forced.reapply(entity)
end)

exports("openClothingRail", function()
    if clothing.railOpen() then
        return clothing.closeRail()
    end

    if editor.active() then return end

    clothing.openRail()
end)

exports("openOutfitMenu", function()
    if editor.active() then return end

    local menu = table.clone(require("config.menu").default)

    menu.outfits = true

    shops.clear()
    editor.open(menu)
end)

local compat = require("config.general").compat

if compat.illenium then require "compat.illenium-appearance.client" end
if compat.esxSkin then require "compat.esx_skin.client" end
if compat.qbClothing then require "compat.qb-clothing.client" end
