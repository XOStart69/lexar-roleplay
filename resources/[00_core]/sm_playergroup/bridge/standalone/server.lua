return {
    ---@param source number
    ---@return string
    getPlayerName = function(source)
        return GetPlayerName(source) or ('Player %d'):format(source)
    end,
}
