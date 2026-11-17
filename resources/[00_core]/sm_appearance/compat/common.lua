local ped = require "core.ped"
local editor = require "core.editor"
local settings = require "core.settings"
local halfped = require "features.halfped"
local forced = require "features.forced"

local compat = {}

---@param resource string
---@param name string
---@param fn function
function compat.alias(resource, name, fn)
    AddEventHandler(("__cfx_export_%s_%s"):format(resource, name), function(setCB)
        setCB(fn)
    end)
end

---@param outfit table?
function compat.wearOutfit(outfit)
    if not outfit then return end

    local model = outfit.model or ped.getModel(cache.ped)
    local slot = settings.blocked({ model = model, components = outfit.components or {}, props = outfit.props or {} })

    if slot then
        return lib.notify({ description = locale("outfits.blocked", settings.label(slot)), type = "error" })
    end

    if outfit.model and ped.getModel(cache.ped) ~= outfit.model then
        local stored = lib.callback.await("rhd_appearance:get", false, outfit.model)

        if not stored then
            return lib.notify({ description = locale("outfits.wrongModel"), type = "error" })
        end

        ped.applyToPlayer(stored)
    end

    ped.setComponents(cache.ped, halfped.strip(outfit.components or {}, ped.gender(cache.ped)))
    ped.setProps(cache.ped, outfit.props or {})

    editor.save(ped.get(cache.ped))
end

---@param clothes table?
function compat.wearClothes(clothes)
    if not clothes then return end

    ped.setComponents(cache.ped, clothes.components or {})
    ped.setProps(cache.ped, clothes.props or {})
    forced.reapply()
end

---@return fun(name: string)
function compat.reporter()
    local warned = {}

    return function(name)
        if warned[name] then return end

        warned[name] = true

        print(("^3[rhd_appearance]^7 '%s' is part of illenium job management, which is not implemented.")
            :format(name))
    end
end

return compat
