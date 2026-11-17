local State = require 'gardener.modules.client.state'
local blipUtils = require 'modules.blips'

local Blips = {}

local labels = {
    lawnmowing = 'Misi Potong Rumput',
    prunegrass = 'Misi Pangkas Semak',
    branch = 'Misi Potong Dahan',
    flower = 'Misi Tanam Bunga',
}

---@param coords vector3 | { x: number, y: number, z: number }
---@param jobName 'lawnmowing' | 'prunegrass' | 'branch' | 'flower'
---@param index number
---@param radius? number
function Blips.addMissionBlip(coords, jobName, index, radius)
    local settings = State.cfg.blip.mission[jobName]
    if not settings then return end

    if jobName == 'flower' then
        if State.stateBlips.flowerTwo[index] then return end
    elseif State.stateBlips[jobName] and State.stateBlips[jobName][index] then
        return
    end

    if jobName == 'flower' then
        local areaBlip = blipUtils.create.radius({
            coords = coords,
            radius = radius or 10.0,
            color = settings.color,
        })
        State.stateBlips.flower[index] = { blip = areaBlip, index = index }
    end

    local blip = blipUtils.create({
        coords = coords,
        sprite = settings.sprite,
        color = settings.color,
        scale = settings.scale,
        name = labels[jobName] or 'Misi',
    })

    if jobName == 'flower' then
        State.stateBlips.flowerTwo[index] = { blip = blip, index = index }
    elseif State.stateBlips[jobName] then
        State.stateBlips[jobName][index] = { blip = blip, index = index }
    end
end

---@param jobName string
---@param index number
function Blips.removeMissionBlip(jobName, index)
    local blips = State.stateBlips[jobName]
    if blips and blips[index] then
        blipUtils.remove(blips[index].blip)
        blips[index] = nil
    end

    if jobName == 'flower' and State.stateBlips.flowerTwo[index] then
        blipUtils.remove(State.stateBlips.flowerTwo[index].blip)
        State.stateBlips.flowerTwo[index] = nil
    end
end

function Blips.removeAll()
    for _, group in pairs(State.stateBlips) do
        for index, data in pairs(group) do
            blipUtils.remove(data.blip)
            group[index] = nil
        end
    end
end

return Blips
