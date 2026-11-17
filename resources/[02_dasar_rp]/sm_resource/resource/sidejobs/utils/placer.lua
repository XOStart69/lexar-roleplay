local placer = {}

local placing_status = false

local entities = {}
local textdata = {}
local current_ent

local coordsFormat = [[
local data = {
    distance = %s,
    coords = vec(%.2f, %.2f, %.2f),
    positions = {
        %s
    }
}
]]

local function setupScaleform()
    local sc = lib.scaleform:new({
        name = 'instructional_buttons',
        fullScreen = true
    })

    sc:callMethod('CLEAR_ALL')
    sc:callMethod('SET_CLEAR_SPACE', {200})

    sc:callMethod('SET_DATA_SLOT', {
        0,
        GetControlInstructionalButton(2, 73, true),
        'Finish'
    })

    sc:callMethod('SET_DATA_SLOT', {
        1,
        GetControlInstructionalButton(2, 194, true),
        'Remove previous'
    })

    sc:callMethod('SET_DATA_SLOT', {
        2,
        GetControlInstructionalButton(2, 38, true),
        'Place object'
    })

    sc:callMethod('SET_DATA_SLOT', {
        3,
        GetControlInstructionalButton(2, 175, true), GetControlInstructionalButton(2, 174, true),
        'Rotate object'
    })

    sc:callMethod('SET_DATA_SLOT', {
        4,
        GetControlInstructionalButton(2, 172, true), GetControlInstructionalButton(2, 173, true),
        'Adjust height'
    })

    sc:callMethod('DRAW_INSTRUCTIONAL_BUTTONS')
    sc:callMethod('SET_BACKGROUND_COLOUR', {0, 0, 0, 80})

    sc:startDrawing()
    return sc
end

local function cancelPlacement(sc)
    placing_status = false

    if current_ent and DoesEntityExist(current_ent) then
        pcall(DeleteEntity, current_ent)
        current_ent = nil
    end

    if entities[1] then
        lib.array.forEach(entities, function (val)
            if val and DoesEntityExist(val) then
                pcall(DeleteEntity, val)
            end
        end)
        entities = {}
    end

    if sc then
        sc:dispose()
    end
end

local function addObject(model, coords, heading)
    if not pcall(function ()
        return lib.requestModel(model, 1500)
    end) then return end

    local new = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)

    SetEntityHeading(new, heading or 0.0)
    SetEntityCollision(new, false, false)
    FreezeEntityPosition(new, true)
    SetEntityCollision(new, false, false)

    return new
end

function placer.start(model, onground, distance)
    if placing_status then return end

    if not (model and IsModelInCdimage(model)) then
        return
    end

    distance = distance or 20

    local pc = GetEntityCoords(cache.ped)
    current_ent = addObject(model, pc, GetEntityHeading(cache.ped))

    if not current_ent then
        return
    end

    placing_status = true
    local sc = setupScaleform()
    local inDistance = false
    local zOffset = 0.0

    CreateThread(function()
        while placing_status do
            local coords = GetEntityCoords(current_ent)

            local dist = math.floor(#(coords - pc))
            local red, green, blue, alpha
            if dist > distance then
                red, green, blue, alpha = 255, 0, 0, 150
                inDistance = false
            else
                red, green, blue, alpha = 0, 255, 0, 150
                inDistance = true
            end

            DrawMarker(
                1,
                pc.x,
                pc.y,
                pc.z - 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                distance * 2.0,
                distance * 2.0,
                0.5,
                red, green, blue, alpha,
                false, false, 2, false,
                nil, nil, false
            )

            Wait(1)
        end
    end)

    CreateThread(function()
        while placing_status do
            local hit, _, coords = lib.raycast.fromCamera()
            
            DisableControlAction(0, 175, true)  -- Arrow Right
            DisableControlAction(0, 174, true)  -- Arrow Left
            DisableControlAction(0, 73, true)   -- X
            DisableControlAction(0, 38, true)   -- E
            DisableControlAction(0, 194, true)  -- Backspace
            DisableControlAction(0, 172, true)  -- Arrow Up
            DisableControlAction(0, 173, true)  -- Arrow Down

            local heading = GetEntityHeading(current_ent)

            if hit then
                SetEntityCoords(current_ent, coords.x, coords.y, coords.z + zOffset, false, false, false, false)

                if onground then
                    PlaceObjectOnGroundProperly(current_ent)
                    local groundCoords = GetEntityCoords(current_ent)
                    zOffset = groundCoords.z - coords.z
                end
            end

            if IsDisabledControlPressed(0, 175) then
                heading = heading + 5
            end

            if IsDisabledControlPressed(0, 174) then
                heading = heading - 5
            end

            if IsDisabledControlPressed(0, 172) then
                zOffset = zOffset + 0.05
            end

            if IsDisabledControlPressed(0, 173) then
                zOffset = zOffset - 0.05
            end

            if IsDisabledControlPressed(0, 73) then
                cancelPlacement()
                sc:dispose()

                if #textdata > 0 then
                    local x, y, z = table.unpack(pc)
                    local message = coordsFormat:format(distance, x, y, z, table.concat(textdata, ', \n\t'))
                    lib.setClipboard(message)
                    textdata = {}
                end
            end

            SetEntityHeading(current_ent, heading)

            if IsDisabledControlJustPressed(0, 38) and hit then
                if inDistance then
                    local finalCoords = GetEntityCoords(current_ent) 
                    local newindex = #entities + 1
                    entities[newindex] = addObject(model, finalCoords, heading)

                    textdata[newindex] = ('vec(%.2f, %.2f, %.2f, %.2f)'):format(finalCoords.x, finalCoords.y, finalCoords.z, heading)
                else
                    lib.notify({
                        description = 'Lokasi ini diluar jarak yang sudah di tentukan, distance: ' .. distance,
                        type = 'warning'
                    })
                end
            end
            
            if IsDisabledControlJustPressed(0, 194) then
                local index = #entities

                if index > 0 then
                    local ent = entities[index]
                    if ent and DoesEntityExist(ent) then
                        pcall(DeleteEntity, ent)
                    end
                    table.remove(entities, index)
                    table.remove(textdata, index)
                end
            end
            Wait(1)
        end
    end)
end

return placer