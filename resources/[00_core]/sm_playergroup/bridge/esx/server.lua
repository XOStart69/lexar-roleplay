local ESX = exports.es_extended:getSharedObject()

return {
    ---@param source number
    ---@return string
    getPlayerName = function(source)
        local ok, name = pcall(function()
            local xPlayer = ESX.GetPlayerFromId(source)
            return xPlayer and xPlayer.getName() or nil
        end)

        if ok and name and name ~= '' then return name end
        return GetPlayerName(source) or ('Player %d'):format(source)
    end,
}
