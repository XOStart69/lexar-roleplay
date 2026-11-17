QBShared = QBShared or {}

QBShared.StarterItems = {
    ['phone'] = { amount = 1, item = 'phone' },
    ['id_card'] = { amount = 1, item = 'id_card' },
    ['driver_license'] = { amount = 1, item = 'driver_license' },
}

---@deprecated use lib.string.random from ox_lib
QBShared.RandomStr = function(length)
    if length <= 0 then return '' end
    local pattern = math.random(2) == 1 and 'a' or 'A'

    ---@diagnostic disable-next-line: deprecated
    return QBShared.RandomStr(length - 1) .. lib.string.random(pattern)
end

---@deprecated use lib.string.random from ox_lib
QBShared.RandomInt = function(length)
    if length <= 0 then return '' end

    ---@diagnostic disable-next-line: deprecated
    return QBShared.RandomInt(length - 1) .. lib.string.random('1')
end

---@deprecated use string.strsplit with CfxLua 5.4
QBShared.SplitStr = function(str, delimiter)
    local result = table.pack(string.strsplit(delimiter, str))
    result.n = nil
    return result
end

---@deprecated use qbLib.string.trim from modules/lib.lua
QBShared.Trim = function(str)
    if not str then return nil end
    return qbLib.string.trim(str)
end

---@deprecated use qbLib.string.capitalize from modules/lib.lua
QBShared.FirstToUpper = function(str)
    if not str then return nil end
    return qbLib.string.capitalize(str)
end

---@deprecated use qbLib.math.round from modules/lib.lua
QBShared.Round = qbLib.math.round

---@deprecated use qbLib.setVehicleExtra from modules/lib.lua
QBShared.ChangeVehicleExtra = qbLib.setVehicleExtras


QBShared.IsFunction = function(value)
    if type(value) == 'table' then
        return value.__cfx_functionReference ~= nil and type(value.__cfx_functionReference) == "string"
    end

    return type(value) == 'function'
end

---@deprecated use qbLib.setVehicleExtra from modules/lib.lua
QBShared.SetDefaultVehicleExtras = qbLib.setVehicleExtras

---@deprecated use qbLib.armsWithoutGloves.male from modules/lib.lua
QBShared.MaleNoGloves = qbLib.armsWithoutGloves.male

---@deprecated use qbLib.armsWithoutGloves.female from modules/lib.lua
QBShared.FemaleNoGloves = qbLib.armsWithoutGloves.female