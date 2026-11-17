---Returns the identifier (with prefix, e.g. 'license:abc' or 'steam:110000...') of a connected player.
---`idtype` defaults to 'license' (qb-core behaviour). Core code passes QBConfig.LicenseType explicitly.
---@param source Source|string
---@param idtype? string
---@return string?
function PlayerIdentifier(source, idtype)
    return GetPlayerIdentifierByType(tostring(source), idtype or 'license')
end
