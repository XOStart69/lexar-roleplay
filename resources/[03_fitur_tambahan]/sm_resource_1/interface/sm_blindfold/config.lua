---@class BlindfoldConfig
---@field item string
---@field targetDistance number
---@field maxDistance number
---@field installDuration integer
---@field removeDuration integer
---@field prop integer
---@field bone integer
---@field offset vector3
---@field rotation vector3

---@type BlindfoldConfig
return {
    item = 'blindfold',
    targetDistance = 1.5,
    maxDistance = 2.0,
    installDuration = 3000,
    removeDuration = 2000,
    prop = `prop_money_bag_01`,
    bone = 12844,
    offset = vec3(0.2, 0.04, 0.0),
    rotation = vec3(0.0, 270.0, 60.0),
}
