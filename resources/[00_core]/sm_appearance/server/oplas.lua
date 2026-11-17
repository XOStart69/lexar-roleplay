local ITEM = "oplasbaru"

---@type table<number, true>
local active = {}

---@param source number
local function run(source)
    local ok, err = pcall(lib.callback.await, "rhd_appearance:oplas:open", source)

    active[source] = nil

    if not ok then
        return lib.print.warn(("'%s' use by %s failed: %s"):format(ITEM, source, err))
    end

    lib.notify(source, { description = locale("oplas.done"), type = "success" })
end

---@param source number
local function use(source)
    if active[source] then return end

    local slot = exports.ox_inventory:GetSlotWithItem(source, ITEM)

    if not slot then return end

    if not exports.ox_inventory:RemoveItem(source, ITEM, 1, nil, slot.slot) then
        return lib.print.warn(("'%s' use by %s failed: could not remove slot %s"):format(ITEM, source, slot.slot))
    end

    active[source] = true

    CreateThread(function()
        run(source)
    end)
end

AddEventHandler("playerDropped", function()
    active[source] = nil
end)

CreateThread(function()
    if GetResourceState("ox_inventory") ~= "started" then
        return lib.print.warn(("'%s' cannot be used: ox_inventory is not running"):format(ITEM))
    end

    local registered = Framework.registerUsableItem(ITEM, use)

    if registered == false then
        lib.print.warn(("'%s' cannot be used: this framework has no usable item registry"):format(ITEM))
    end
end)
