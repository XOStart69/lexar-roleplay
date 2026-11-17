---@class HalfPedConfig
---@field disabledFace table<string, number>
return {
    --[[
        The empty face worn together with a half ped decal. It is a head blend parent rather than a
        component, and it stays blocked for everyone who was not granted a decal.
    ]]
    disabledFace = {
        male = 92,
        female = 92
    }
}
