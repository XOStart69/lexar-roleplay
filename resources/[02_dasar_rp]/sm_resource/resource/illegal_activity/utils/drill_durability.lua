local itemModule = require 'modules.items.server'

local MAX_FAILS = 3

local durability = {}

---@type table<number, table<string, number>>
local fails = {}

---@param source number
---@param toolItem string
---@param title string
function durability.registerFail(source, toolItem, title)
    local playerFails = fails[source]

    if not playerFails then
        playerFails = {}
        fails[source] = playerFails
    end

    local count = (playerFails[toolItem] or 0) + 1

    if count < MAX_FAILS then
        playerFails[toolItem] = count

        return lib.notify(source, {
            title = title,
            description = ('Mata bor mulai aus (%d/%d gagal).'):format(count, MAX_FAILS),
            type = 'inform',
        })
    end

    playerFails[toolItem] = nil

    if itemModule.transaction(source, { remove = { [toolItem] = 1 } }) then
        lib.notify(source, {
            title = title,
            description = ('Bor kamu rusak dan hancur setelah %dx gagal!'):format(MAX_FAILS),
            type = 'error',
        })
    end
end

---@param source number
---@param toolItem string
function durability.clearFails(source, toolItem)
    local playerFails = fails[source]

    if playerFails then
        playerFails[toolItem] = nil
    end
end

AddEventHandler('playerDropped', function()
    fails[source] = nil
end)

return durability
