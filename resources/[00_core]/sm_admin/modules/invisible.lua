local utils = require 'modules.lib.utils'

--- Invisible mode:
---  * Local player keeps walking/driving normally.
---  * Remote players see nothing (SetEntityVisible false is networked).
---  * Local player sees a faint silhouette of themselves (alpha marker).
---  * AI / police ignore the player.
---  * Targeting + overhead ID are blocked via the networked `invisible` state bag.
---  * Survives noclip toggling: a watcher re-applies the effect every frame
---    while active, so noclip's SetEntityVisible(true)/SetEntityAlpha reset
---    is corrected on the next tick and invisible only ends from the menu.

local invisible = false
local FAINT_ALPHA = 120 -- silhouette the invisible player sees of themselves

local function applyInvisible(ped)
    -- Networked: hides ped from everyone else.
    if IsEntityVisible(ped) then
        SetEntityVisible(ped, false, false)
    end

    -- Local-only: let ourselves see a faint version so we have a marker.
    SetLocalPlayerVisibleLocally(true)
    SetEntityAlpha(ped, FAINT_ALPHA, false)

    -- AI ignores us.
    SetEveryoneIgnorePlayer(ped, true)
    SetPoliceIgnorePlayer(ped, true)
end

local function clearInvisible(ped)
    SetEntityVisible(ped, true, false)
    ResetEntityAlpha(ped)
    SetEveryoneIgnorePlayer(ped, false)
    SetPoliceIgnorePlayer(ped, false)
end

return {
    toggle = function (actionData)
        if not utils.validate(actionData) then
            return
        end

        invisible = not invisible

        local msg = invisible and 'active' or 'non active'
        lib.notify({ description = 'Invisible mode ' .. msg })

        -- Tell every other client to skip targeting / overhead ID for us.
        LocalPlayer.state:set('invisible', invisible, true)

        if invisible then
            applyInvisible(cache.ped)

            CreateThread(function ()
                while invisible do
                    Wait(0)
                    local ped = cache.ped
                    -- Re-apply each frame: ped re-renders, model swaps, and
                    -- especially noclip's reset (SetEntityVisible/alpha 255)
                    -- get corrected here so invisible never drops on its own.
                    applyInvisible(ped)
                end
                -- Stopped from the menu: restore visibility.
                clearInvisible(cache.ped)
            end)
        end
    end
}
