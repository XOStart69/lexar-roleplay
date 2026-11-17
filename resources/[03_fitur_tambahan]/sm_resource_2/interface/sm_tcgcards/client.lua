if not lib.checkDependency('ox_lib', '3.30.0', true) then return end

local config = localmodule 'config'
local locale = localmodule 'modules.locale'
local Nui = localmodule 'modules.nui'

Nui.on('ready', function()
    local strings = {}

    for key, value in pairs(locale.all()) do
        local name = key:match('^ui%.(.+)$')

        if name then strings[name] = value end
    end

    return {
        locale = strings,
        classes = config.classes,
        templates = config.templates,
        effects = config.effects,
        booster = { slots = config.pack.slots, noDuplicate = config.pack.noDuplicate },
        quality = config.quality,
        conditions = config.conditions,
        grades = config.grades,
        reusableSleeve = config.sleeve.reusable,
    }
end)
