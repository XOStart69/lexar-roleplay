return {
    ---@param source number
    ---@return string
    getPlayerName = function(source)
        local ok, name = pcall(function()
            local player = exports.qbx_core:GetPlayer(source)
            local charinfo = player and player.PlayerData.charinfo
            return charinfo and ('%s %s'):format(charinfo.firstname, charinfo.lastname) or nil
        end)

        if ok and name and name ~= ' ' then return name end
        return GetPlayerName(source) or ('Player %d'):format(source)
    end,
}
