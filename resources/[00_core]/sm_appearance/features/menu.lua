local menus = {}
local currentMenu = nil
local returnMenu = nil
local dialogPromise = nil

---@param action string
---@param data table
local function send(action, data)
    SendNuiMessage(json.encode({ action = action, data = data }))
end

---@param menu MenuDefinition
---@return table
local function serialise(menu)
    local options = {}

    for i = 1, #menu.options do
        local option = menu.options[i]

        options[i] = {
            title = option.title,
            description = option.description,
            submenu = option.menu ~= nil
        }
    end

    return {
        title = menu.title,
        hasParent = menu.menu ~= nil,
        options = options
    }
end

local menu = {}

function menu.close()
    currentMenu = nil
    SetNuiFocus(false, false)
    send("menu_hide", {})
end

---@return boolean
function menu.active()
    return currentMenu ~= nil or dialogPromise ~= nil
end

---@param definition MenuDefinition
function menu.register(definition)
    menus[definition.id] = definition
end

---@param id string
function menu.show(id)
    local definition = menus[id]

    if not definition then return end

    currentMenu = id
    send("menu_display", serialise(definition))
    SetNuiFocus(true, true)
end

---@param title string
---@param fields DialogField[]
---@return string[]? values one entry per field, nil when cancelled
function menu.input(title, fields)
    if dialogPromise then return end

    dialogPromise = promise.new()
    send("menu_dialog", { title = title, fields = fields })
    SetNuiFocus(true, true)

    local result = Citizen.Await(dialogPromise)
    dialogPromise = nil

    if returnMenu then
        menu.show(returnMenu)
    else
        SetNuiFocus(false, false)
    end

    if result == false then return end

    return result
end

RegisterNUICallback("menu_select", function(data, cb)
    cb(1)

    local definition = menus[currentMenu]
    local option = definition and definition.options[data.index]

    if not option then return end

    if option.menu then
        return menu.show(option.menu)
    end

    returnMenu = currentMenu
    menu.close()

    if option.onSelect then
        option.onSelect(option.args)
    end
end)

RegisterNUICallback("menu_back", function(_, cb)
    cb(1)

    local definition = menus[currentMenu]

    if definition and definition.menu then
        return menu.show(definition.menu)
    end

    menu.close()
end)

RegisterNUICallback("menu_close", function(_, cb)
    cb(1)
    returnMenu = nil
    menu.close()
end)

RegisterNUICallback("menu_dialog_submit", function(data, cb)
    cb(1)

    if not dialogPromise then return end

    dialogPromise:resolve(data.values or false)
end)

return menu
