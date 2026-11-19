local T = Config.Server.tables

---@param src number
---@return boolean
local function canEdit(src)
    return Housing:IsAdmin(src) or Housing:IsAgent(src, 'createhome')
end

lib.callback.register('Housing:server:GetCatalogues', function(source)
    return MySQL.query(('SELECT * FROM `%s` ORDER BY `interior`'):format(T.catalogues)) or {}
end)

lib.callback.register('Housing:server:GetCatalogue', function(source, interior)
    if not interior then return nil end
    return MySQL.single.await(('SELECT * FROM `%s` WHERE `interior` = ?'):format(T.catalogues), { interior })
end)

lib.callback.register('Housing:server:AddCatalogue', function(source, data)
    local src = source
    if not canEdit(src) or type(data) ~= 'table' or not data.interior or not data.type then return false end

    MySQL.insert(('INSERT INTO `%s` (`interior`, `type`, `price`, `label`) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE `price` = ?, `label` = ?'):format(T.catalogues), {
        data.interior, data.type, data.price or 0, data.label,
        data.price or 0, data.label,
    })
    return true
end)

lib.callback.register('Housing:server:UpdateCatalogue', function(source, data)
    local src = source
    if not canEdit(src) or type(data) ~= 'table' or not data.interior or not data.type then return false end

    MySQL.update(('UPDATE `%s` SET `price` = ?, `label` = ? WHERE `interior` = ? AND `type` = ?'):format(T.catalogues),
        { data.price or 0, data.label, data.interior, data.type })
    return true
end)

lib.callback.register('Housing:server:DeleteCatalogue', function(source, interior, catalogueType)
    local src = source
    if not canEdit(src) or not interior or not catalogueType then return false end

    MySQL.query(('DELETE FROM `%s` WHERE `interior` = ? AND `type` = ?'):format(T.catalogues),
        { interior, catalogueType })
    return true
end)