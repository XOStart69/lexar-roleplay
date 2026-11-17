---@class ClothingConfig
---@field keybind { key: string|false, mapper: string }
---@field interval number
return {
    --- Opens the full clothing rail outside the editor. Set key to false to leave it unbound.
    keybind = {
        key = "K",
        mapper = "keyboard"
    },

    --- Milliseconds a piece is left alone after being toggled, so a double click counts once.
    interval = 500
}
