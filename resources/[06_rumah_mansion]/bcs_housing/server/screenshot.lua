local T = Config.Server.tables
local fs = require 'server.convertion.image'

lib.callback.register('Housing:server:RequestScreenshot', function(source)
    TriggerClientEvent('continueScreenshot', source)
    return true
end)

RegisterNetEvent('takeScreenshot', function(name, screenshotType)
    local src = source
    TriggerClientEvent('Housing:client:TakeScreenshot', src, name, screenshotType)
end)

RegisterNetEvent('Housing:server:SetThumbnail', function(interior, thumbnail)
    if not interior or not thumbnail then return end
    MySQL.update(('UPDATE `%s` SET `label` = `label` WHERE `interior` = ?'):format(T.catalogues), { interior })
    MySQL.update(('UPDATE `%s` SET `thumbnail` = ? WHERE `interior` = ?'):format(T.homes), { thumbnail, interior })
end)

RegisterNetEvent('bcs_housing:server:SaveThumbnail', function(data)
    local src = source
    if type(data) ~= 'table' or not data.base64 or not data.name then return end

    local url = fs.save(data.name, data.base64)
    if not url then
        Housing:Notify(src, 'Gagal menyimpan thumbnail', 'error')
        return
    end

    if data.type == 'interior' then
        MySQL.query(('INSERT INTO `%s` (`interior`, `type`, `label`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `label` = ?'):format(T.catalogues), {
            data.name, 'interior', url, url,
        })
    elseif data.type == 'furniture' then
        MySQL.query(('INSERT INTO `%s` (`interior`, `type`, `label`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `label` = ?'):format(T.catalogues), {
            data.name, 'furniture', url, url,
        })
    elseif data.homeId then
        local home = Housing:GetHome(data.homeId)
        if home then
            home:SetProperty('thumbnail', url)
            TriggerClientEvent('Housing:client:UpdateThumbnail', -1, data.homeId, url)
        end
    end
end)