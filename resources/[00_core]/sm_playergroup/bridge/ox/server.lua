return {
    ---@param source number
    ---@return string
    getPlayerName = function(source)
        local ok, name = pcall(function()
            local player = exports.ox_core:GetPlayer(source)
            return player and ('%s %s'):format(player.firstName, player.lastName) or nil
        end)

        if ok and name and name ~= ' ' then return name end
        return GetPlayerName(source) or ('Player %d'):format(source)
    end,
}
