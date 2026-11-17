local ANIM_DICT = 'cop_badge_1@dad'
local ANIM_NAME = 'cop_badge_1_clip'
local ANIM_FLAG = 51

local CARD_PROP = {
    model = `prop_franklin_dl`,
    bone = 28422,
    offset = { 0.084, 0.02, -0.026 },
    rotation = { -173.85, -88.02, 63.06 }
}

local BADGE_PROP = {
    model = `prop_cop_badge`,
    bone = 28422,
    offset = { 0.039, -0.01, -0.059 },
    rotation = { -103.1785, -176.6694, 74.9 }
}

local showing = false
local prop

local function attachProp(propData)
    local ok = pcall(lib.requestModel, propData.model, 5000)
    if not ok then return end

    local coords = GetEntityCoords(cache.ped)
    prop = CreateObject(propData.model, coords.x, coords.y, coords.z + 0.2, true, true, true)

    local offset = propData.offset
    local rotation = propData.rotation

    AttachEntityToEntity(
        prop, cache.ped,
        GetPedBoneIndex(cache.ped, propData.bone),
        offset[1], offset[2], offset[3],
        rotation[1], rotation[2], rotation[3],
        true, true, false, false, 1, true
    )

    SetModelAsNoLongerNeeded(propData.model)
end

local function cleanup()
    StopAnimTask(cache.ped, ANIM_DICT, ANIM_NAME, 1.0)

    if prop then
        DeleteEntity(prop)
        prop = nil
    end
end

local function playAnim()
    return pcall(lib.playAnim, cache.ped, ANIM_DICT, ANIM_NAME, 3.0, 3.0, -1, ANIM_FLAG, 0, false, false, false)
end

---@param isBadge boolean?
local function start(isBadge)
    if showing then return false end
    showing = true

    attachProp(isBadge and BADGE_PROP or CARD_PROP)

    if not playAnim() then
        showing = false
        cleanup()
        return false
    end

    CreateThread(function()
        while showing do
            if not IsEntityPlayingAnim(cache.ped, ANIM_DICT, ANIM_NAME, 3) then
                playAnim()
            end
            Wait(500)
        end

        cleanup()
    end)

    return true
end

local function stop()
    showing = false
end

local function isShowing()
    return showing
end

return {
    start = start,
    stop = stop,
    isShowing = isShowing
}
