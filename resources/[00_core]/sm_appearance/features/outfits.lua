local ped = require "core.ped"
local editor = require "core.editor"
local settings = require "core.settings"
local halfped = require "features.halfped"
local worn = require "features.items"
local menu = require "features.menu"
local shops = require "config.shops"

local MAIN = "rhd_appearance_outfits"
local CHANGE = "rhd_appearance_outfits_change"
local UPDATE = "rhd_appearance_outfits_update"
local DELETE = "rhd_appearance_outfits_delete"
local SHARE = "rhd_appearance_outfits_share"
local JOB = "rhd_appearance_outfits_job"

local outfits = {}

---@type { components: PedComponent[], props: PedProp[] }?
local previewed

---@type number?
local previewing

---@param message string
---@param kind string?
local function notify(message, kind)
    lib.notify({ description = message, type = kind })
end

---@return Outfit[]
local function fetch()
    return lib.callback.await("rhd_appearance:outfits:get", false) or {}
end

---@return string model
---@return PedComponent[]
---@return PedProp[]
local function currentOutfit()
    local components = halfped.strip(ped.getComponents(cache.ped), ped.gender(cache.ped))

    return ped.getModel(cache.ped), components, ped.getProps(cache.ped)
end

---@param model string
---@param components PedComponent[]
---@param props PedProp[]
---@return boolean
local function saveable(model, components, props)
    local slot = settings.blocked({ model = model, components = components, props = props })

    if not slot then return true end

    notify(locale("items.blocked", settings.label(slot)), "error")

    return false
end

---@param outfit Outfit
---@return boolean
local function wearable(outfit)
    local slot = settings.blocked({ model = outfit.model, components = outfit.components, props = outfit.props })

    if not slot then return true end

    notify(locale("outfits.blocked", settings.label(slot)), "error")

    return false
end

---@param outfit Outfit
local function dress(outfit)
    worn.reapply()

    local components = halfped.strip(outfit.components, ped.gender(cache.ped))

    ped.setComponents(cache.ped, worn.without(components, "component_id"))
    ped.setProps(cache.ped, worn.without(outfit.props, "prop_id"))
end

---@param outfit Outfit
local function wear(outfit)
    if not wearable(outfit) then return end

    if ped.getModel(cache.ped) ~= outfit.model then
        local stored = lib.callback.await("rhd_appearance:get", false, outfit.model)

        if not stored then
            return notify(locale("outfits.wrongModel"), "error")
        end

        ped.applyToPlayer(stored)
    end

    dress(outfit)

    editor.commit(worn.underneath(ped.get(cache.ped)))
    notify(locale("outfits.worn", outfit.name))
end

local function save()
    local response = menu.input(locale("outfits.save.title"), {
        {
            type = "input",
            label = locale("outfits.save.name"),
            required = true
        }
    })

    if not response then return end

    local model, components, props = currentOutfit()
    local saved = lib.callback.await("rhd_appearance:outfits:save", false, response[1], model, components, props)

    notify(saved and locale("outfits.saved") or locale("outfits.saveFailed"), not saved and "error" or nil)
end

---@param outfit Outfit
local function update(outfit)
    local model, components, props = currentOutfit()
    local updated = lib.callback.await("rhd_appearance:outfits:update", false, outfit.id, model, components, props)

    notify(updated and locale("outfits.updated") or locale("outfits.updateFailed"), not updated and "error" or nil)
end

---@param outfit Outfit
local function remove(outfit)
    local deleted = lib.callback.await("rhd_appearance:outfits:delete", false, outfit.id)

    notify(deleted and locale("outfits.deleted") or locale("outfits.deleteFailed"), not deleted and "error" or nil)
end

---@param outfit Outfit
local function share(outfit)
    local code = lib.callback.await("rhd_appearance:outfits:generateCode", false, outfit.id)

    if not code then
        return notify(locale("outfits.codeFailed"), "error")
    end

    lib.setClipboard(code)

    menu.input(locale("outfits.share.title"), {
        {
            type = "input",
            label = locale("outfits.share.code"),
            default = code,
            disabled = true
        }
    })
end

local function import()
    local response = menu.input(locale("outfits.import.title"), {
        {
            type = "input",
            label = locale("outfits.import.name"),
            required = true
        },
        {
            type = "input",
            label = locale("outfits.import.code"),
            required = true
        }
    })

    if not response then return end

    local imported = lib.callback.await("rhd_appearance:outfits:import", false, response[1], response[2])

    notify(imported and locale("outfits.imported") or locale("outfits.importFailed"), not imported and "error" or nil)
end

---@param id string
---@param title string
---@param list Outfit[]
---@param action fun(outfit: Outfit)
local function registerList(id, title, list, action)
    local options = table.create(#list, 0)

    for i = 1, #list do
        options[i] = {
            title = list[i].name,
            description = list[i].model,
            onSelect = action,
            args = list[i]
        }
    end

    table.sort(options, function(a, b) return a.title < b.title end)

    menu.register({ id = id, title = title, menu = MAIN, options = options })
end

---@return Outfit[]
function outfits.list()
    return fetch()
end

---@param id number
---@return Outfit?
local function byId(id)
    local list = fetch()

    for i = 1, #list do
        if list[i].id == id then return list[i] end
    end
end

---@param id number
---@return boolean
function outfits.apply(id)
    local outfit = byId(id)

    if not outfit then
        notify(locale("outfits.missing"), "error")

        return false
    end

    if not wearable(outfit) then return false end

    previewing = nil
    previewed = nil

    if ped.getModel(cache.ped) ~= outfit.model then
        local stored = lib.callback.await("rhd_appearance:get", false, outfit.model)

        if not stored then
            notify(locale("outfits.wrongModel"), "error")

            return false
        end

        ped.applyToPlayer(stored)
    end

    dress(outfit)

    notify(locale("outfits.worn", outfit.name), "success")

    return true
end

---@param id number
---@return boolean
function outfits.preview(id)
    previewing = id

    local outfit = byId(id)

    if previewing ~= id then return false end

    if not outfit or ped.getModel(cache.ped) ~= outfit.model then return false end

    if not previewed then
        previewed = { components = ped.getComponents(cache.ped), props = ped.getProps(cache.ped) }
    end

    dress(outfit)

    return true
end

function outfits.endPreview()
    previewing = nil

    if not previewed then return end

    ped.setComponents(cache.ped, previewed.components)
    ped.setProps(cache.ped, previewed.props)

    previewed = nil
end

---@param name string
---@return boolean
function outfits.store(name)
    local model, components, props = currentOutfit()

    if not saveable(model, components, props) then return false end

    local saved = lib.callback.await("rhd_appearance:outfits:save", false, name, model, components, props)

    notify(saved and locale("outfits.saved") or locale("outfits.saveFailed"), not saved and "error" or nil)

    return saved == true
end

---@param id number
---@return boolean
function outfits.overwrite(id)
    local model, components, props = currentOutfit()

    if not saveable(model, components, props) then return false end

    local updated = lib.callback.await("rhd_appearance:outfits:update", false, id, model, components, props)

    notify(updated and locale("outfits.updated") or locale("outfits.updateFailed"), not updated and "error" or nil)

    return updated == true
end

---@param id number
---@return boolean
function outfits.delete(id)
    local deleted = lib.callback.await("rhd_appearance:outfits:delete", false, id)

    notify(deleted and locale("outfits.deleted") or locale("outfits.deleteFailed"), not deleted and "error" or nil)

    return deleted == true
end

---@param id number
---@return string?
function outfits.code(id)
    local code = lib.callback.await("rhd_appearance:outfits:generateCode", false, id)

    if not code then
        notify(locale("outfits.codeFailed"), "error")

        return
    end

    lib.setClipboard(code)
    notify(locale("outfits.share.code"))

    return code
end

---@param name string
---@param code string
---@return boolean
function outfits.import(name, code)
    local imported = lib.callback.await("rhd_appearance:outfits:import", false, name, code)

    notify(imported and locale("outfits.imported") or locale("outfits.importFailed"), not imported and "error" or nil)

    return imported == true
end

function outfits.open()
    local list = fetch()

    registerList(CHANGE, locale("outfits.change.title"), list, wear)
    registerList(UPDATE, locale("outfits.update.title"), list, update)
    registerList(DELETE, locale("outfits.delete.title"), list, remove)
    registerList(SHARE, locale("outfits.share.title"), list, share)

    menu.register({
        id = MAIN,
        title = locale("outfits.title"),
        options = {
            { title = locale("outfits.change.title"), description = locale("outfits.change.description"), menu = CHANGE },
            { title = locale("outfits.update.title"), description = locale("outfits.update.description"), menu = UPDATE },
            { title = locale("outfits.save.title"), description = locale("outfits.save.description"), onSelect = save },
            { title = locale("outfits.share.title"), description = locale("outfits.share.description"), menu = SHARE },
            { title = locale("outfits.delete.title"), description = locale("outfits.delete.description"), menu = DELETE },
            { title = locale("outfits.import.title"), description = locale("outfits.import.description"), onSelect = import }
        }
    })

    menu.show(MAIN)
end

---@param room ShopZone
function outfits.openJob(room)
    local group = room.job or room.gang

    if not group then return end

    local gender = ped.gender(cache.ped)
    local model = ped.getModel(cache.ped)
    local uniforms = shops.jobOutfits[group] or {}
    local options = {}

    for i = 1, #uniforms do
        local uniform = uniforms[i]

        if not uniform.gender or uniform.gender == gender then
            options[#options + 1] = {
                title = uniform.name,
                onSelect = wear,
                args = {
                    name = uniform.name,
                    model = uniform.model or model,
                    components = uniform.components or {},
                    props = uniform.props or {}
                }
            }
        end
    end

    if #options == 0 then
        return notify(locale("shops.noUniforms"), "error")
    end

    menu.register({ id = JOB, title = locale("shops.clothingRoom"), options = options })
    menu.show(JOB)
end

return outfits
