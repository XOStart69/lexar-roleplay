---@class EditorConfig
---@field asynchronousLoading boolean
---@field hideRadar boolean
---@field invincibleDuringCustomization boolean
---@field automaticFade boolean
---@field chargePerTattoo boolean
---@field disableAnimForPeds string[]
return {
    asynchronousLoading = false,
    hideRadar = true,
    invincibleDuringCustomization = true,
    automaticFade = false,

    --- Bill every tattoo as it is applied instead of once for the whole visit.
    chargePerTattoo = false,

    --- Ped models left standing as they are rather than posed while the editor is open.
    disableAnimForPeds = {}
}
