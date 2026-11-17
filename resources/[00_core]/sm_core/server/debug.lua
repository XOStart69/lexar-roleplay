-- Rekonstruksi sm_core/server/debug.lua

local function dump(obj, indent)
    indent = indent or 0
    if type(obj) ~= 'table' then return tostring(obj) end
    local pad = ('  '):rep(indent)
    local out = '{\n'
    for k, v in pairs(obj) do
        out = out .. ('%s  %s = %s\n'):format(pad, tostring(k), type(v) == 'table' and dump(v, indent + 1) or tostring(v))
    end
    return out .. pad .. '}'
end

function QBCore.Debug(resource, obj)
    print(('^3[DEBUG:%s]^7 %s'):format(resource or 'unknown', dump(obj)))
end

function QBCore.ShowError(resource, msg)
    print(('^1[ERROR:%s]^7 %s'):format(resource or 'unknown', msg))
end

function QBCore.ShowSuccess(resource, msg)
    print(('^2[OK:%s]^7 %s'):format(resource or 'unknown', msg))
end

AddEventHandler('QBCore:DebugSomething', function(resource, obj)
    QBCore.Debug(resource, obj)
end)

local function GetQBPlayers()
    return QBCore.Players
end

exports('GetQBPlayers', GetQBPlayers)
