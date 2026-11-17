---@class GeneralConfig
---@field locale string
---@field freemodeModels table<string, string>
---@field compat { illenium: boolean, esxSkin: boolean, qbClothing: boolean }
---@field adminAce string
---@field commandIdentifiers table<string, string[]>
---@field autoCreateTables boolean
return {
    locale = "id",

    freemodeModels = {
        male = "mp_m_freemode_01",
        female = "mp_f_freemode_01"
    },

    --[[
        Answer the events, exports and callbacks of the resources this one replaces. Each layer can
        be turned off on its own; nothing is loaded for the ones left false.
    ]]
    compat = {
        illenium = true,
        esxSkin = false,
        qbClothing = false
    },

    --- Grants /appearanceadmin and the blacklist and half ped panels behind it.
    adminAce = "admin",

    --[[
        Grants a restricted command to single identifiers, without putting them in an admin group.
        Each key is a command name, each value the list of identifiers allowed to run it.
    ]]
    commandIdentifiers = {
        pedmenu = {
            "steam:110000115ee47ad" -- roelsfam
        }
    },

    autoCreateTables = true
}
