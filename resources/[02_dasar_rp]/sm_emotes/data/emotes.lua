local animalEmotes = require 'animations.AnimalEmotes'
local customAnimations = require 'animations.CustomAnimations'
local dances = require 'animations.Dances'
local emotes = require 'animations.Emotes'
local expressions = require 'animations.Expressions'
local propEmotes = require 'animations.PropEmotes'
local scenario = require 'animations.Scenario'
local shared = require 'animations.Shared'
local walks = require 'animations.Walks'
local Exits = require 'animations.Exits'

local enable = require 'config.client'.menuEnable

local emoteMenu = {}
local all_emotes = {}
local emotes_category = {}

local gifPath = 'https://raw.githubusercontent.com/reyyghi/gif/main/%s'

local function getCategoryIcon(emote)
    if emote.secondPlayersAnim then
        return {
            label = 'Shared',
            icon = 'fas fa-people-pulling'
        }
    elseif emote.AnimationOptions and emote.AnimationOptions.Prop then
        return {
            label = 'Props',
            icon = 'fas fa-person-walking-luggage'
        }
    elseif emote.label:lower():match('dance') then
        return {
            label = 'Dances',
            icon = 'fas fa-child-reaching'
        }
    end
    return {
        label = 'Basic',
        icon = 'fas fa-child'
    }
end

local function createCategory(id, icon, data)
    local category = id:lower() ---@type cache_category
    
    local hasDefaultOptions = (
        category == 'walks' or category == 'expressions'
    )

    local allowedPlacement = not hasDefaultOptions and (
        category ~= 'shared' and category ~= 'animalemotes' and category ~= 'scenario'
    )

    if not emotes_category[id:lower()] then
        emotes_category[id:lower()] = {}
    end

    emoteMenu[#emoteMenu+1] = {
        id = id,
        label = Label[id],
        icon = icon,
        defaultOption = hasDefaultOptions,
        options = {}
    }

    local options = {}

    for k, v in pairs(data) do
        
        v.id = id
        v.category = id:lower() ---@type cache_category
        v.command = k:lower()
        v.label = v.label or k
    
        options[#options+1] = {
            id = id .. ':' .. k,
            label = v.label,
            command = k:lower(),
            gifPath = gifPath:format(id),
            texture = v.AnimationOptions?.PropTextureVariations,
            placement = allowedPlacement and not v.secondPlayersAnim
        }

        if v.category == 'customanimations' then
            options[#options].categoryIcon = getCategoryIcon(v)
        end

        all_emotes[k:lower()] = v
        emotes_category[id:lower()][k] = v
    end

    emoteMenu[#emoteMenu].options = options
end


if enable.animal then
    createCategory('AnimalEmotes', 'fas fa-dog', animalEmotes)
end

if enable.customAnim then
    createCategory('CustomAnimations', 'fas fa-person-rays', customAnimations)
end

if enable.dances then
    createCategory('Dances', 'fas fa-child-reaching', dances)
end

if enable.emotes then
    createCategory('Emotes', 'fas fa-child', emotes)
end

if enable.expressions then
    createCategory('Expressions', 'fas fa-face-smile', expressions)
end

if enable.propEmotes then
    createCategory('PropEmotes', 'fas fa-person-walking-luggage', propEmotes)
end

if enable.scenario then
    createCategory('Scenario', 'fas fa-person-cane', scenario)
end

if enable.shared then
    createCategory('Shared', 'fas fa-people-pulling', shared)
end

if enable.walks then
    createCategory('Walks', 'fas fa-person-walking', walks)
end

return {
    ui = emoteMenu,
    shared = all_emotes,
    exits = Exits,
    category = emotes_category
}