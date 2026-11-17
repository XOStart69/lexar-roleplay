local config = require "config.general"
local admin = require "server.admin"

local MENU_TYPES = { clothing = true, barber = true, tattoo = true, surgeon = true }

---@param source number
---@param name string
---@param data any?
local function dispatch(source, name, data)
    TriggerClientEvent("rhd_appearance:command", source, name, data)
end

lib.addCommand("reloadskin", { help = locale("commands.reloadskin") }, function(source)
    local state = Player(source).state

    if state.smFarmRide or state.smFarmBoarded then
        return TriggerClientEvent("ox_lib:notify", source, { description = "Turun dari hewan dulu sebelum reloadskin.", type = "error" })
    end

    dispatch(source, "reloadskin")
end)

lib.addCommand("clearstuckprops", { help = locale("commands.clearstuckprops") }, function(source)
    dispatch(source, "clearstuckprops")
end)

lib.addCommand("pedmenu", {
    help = locale("commands.pedmenu"),
    params = {
        {
            name = "playerId",
            type = "playerId",
            help = locale("commands.pedmenuTarget"),
            optional = true
        },
        {
            name = "menuType",
            type = "string",
            help = locale("commands.pedmenuType"),
            optional = true
        }
    },
    restricted = 'group.admin'
}, function(source, args)
    local target = args.playerId or source

    if not Framework.GetIdentifier(target) then
        return lib.notify(source, { description = locale("commands.noPlayer"), type = "error" })
    end

    if args.menuType and not MENU_TYPES[args.menuType] then
        return lib.notify(source, { description = locale("commands.badMenuType"), type = "error" })
    end

    dispatch(target, "pedmenu", args.menuType)
end)

lib.addCommand("appearanceadmin", { help = locale("commands.appearanceadmin") }, function(source)
    if not IsPlayerAceAllowed(source, config.adminAce) then
        return lib.notify(source, { description = locale("commands.denied"), type = "error" })
    end

    admin.push(source)
    dispatch(source, "appearanceadmin")
end)

for command, identifiers in pairs(config.commandIdentifiers or {}) do
    local ace = ("command.%s"):format(command)

    for i = 1, #identifiers do
        local principal = ("identifier.%s"):format(identifiers[i])

        if not IsPrincipalAceAllowed(principal, ace) then
            lib.addAce(principal, ace)
        end
    end
end

local CLOTHING_COMMANDS = {
    { "top", "jackets" },
    { "shirt", "shirt" },
    { "pants", "pants" },
    { "shoes", "shoes" },
    { "gloves", "gloves" },
    { "vest", "vest" },
    { "neck", "neck" },
    { "mask", "mask" },
    { "hair", "hair" },
    { "bag", "bag" },
    { "bagoff", "bagoff" },
    { "hat", "hat" },
    { "visor", "visor" },
    { "glasses", "glasses" },
    { "ear", "ear" },
    { "watch", "watch" },
    { "bracelet", "bracelet" }
}

for i = 1, #CLOTHING_COMMANDS do
    local command, itemName = CLOTHING_COMMANDS[i][1], CLOTHING_COMMANDS[i][2]

    lib.addCommand(command, { help = locale("commands.clothing." .. command) }, function(source)
        dispatch(source, "clothing", itemName)
    end)
end

lib.addCommand("reset", { help = locale("commands.clothing.reset") }, function(source)
    dispatch(source, "clothingreset")
end)
