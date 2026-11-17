--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]


local creatorActive = false
local controlsActive = false
local zoneType, step, xCoord, yCoord, zCoord, heading, height, width, length
local steps = {{0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 25, 50, 100}, {0.25, 0.5, 1, 2.5, 5, 15, 30, 45, 60, 90, 180}}
local points = {}

local displayMode = 1
local minCheck = steps[1][1] / 2
local alignMovementWithCamera = true

local freecam = require 'modules.freecam.client'
local formatter = require 'modules.zonecreator.formatter'

local function firstToUpper(str)
    return (str:gsub('^%l', string.upper))
end

local function updateText()
	local text = {
		('------ Zone Creation [%s] ------  \n'):format(firstToUpper(zoneType)),
	}

	if zoneType == 'poly' then
		text[#text + 1] = ('Step Size (Scroll]: %sm/%s&deg;  \n'):format(steps[1][step], steps[2][step])
        text[#text + 1] = ('Coords X (Left/Right): %s  \n'):format(xCoord)
        text[#text + 1] = ('Coords Y (Up/Down): %s  \n'):format(yCoord)
        text[#text + 1] = ('Coords Z (R/F): %s  \n'):format(zCoord)
		text[#text + 1] = ('High / Low (Shift + Scroll): %s  \n'):format(height)
		text[#text + 1] = 'Create a New Point - (Space)  \n'
        text[#text + 1] = 'Edit Previous Point - (Backspace)  \n'
	elseif zoneType == 'box' then
		text[#text + 1] = ('Step Size (Scroll]: %sm/%s&deg;  \n'):format(steps[1][step], steps[2][step])
		text[#text + 1] = ('Set Direction ([ / ]): %s&deg;  \n'):format(heading)
		text[#text + 1] = ('Set Height (Shift + Scroll): %s  \n'):format(height)
		text[#text + 1] = ('Set Width (Ctrl + Scroll): %s  \n'):format(width)
		text[#text + 1] = ('Set Length (Alt + Scroll): %s  \n'):format(length)
		text[#text + 1] = 'Fit In The Middle - (Space)  \n'
	elseif zoneType == 'sphere' then
		text[#text + 1] = ('Step Size (Scroll): %sm/%s&deg;  \n'):format(steps[1][step], steps[2][step])
		text[#text + 1] = ('Set Size (Shift + Scroll): %s  \n'):format(height)
		text[#text + 1] = 'Fit In The Middle - (Space)  \n'
	end

	text[#text + 1] = 'Switch Control - (X)  \n'
	text[#text + 1] = 'Save Zone - (Enter)  \n'
	text[#text + 1] = 'Cancel Creation - (Esc)'

    infoUI.show({
        id = 'zone_creator',
        title = 'Zone Creator (dev tools)',
        icon = 'fas fa-code',
        description = table.concat(text)
    })
end

local function round(number)
	return number >= 0 and math.floor(number + 0.5) or math.ceil(number - 0.5)
end

local function closeCreator(cancel)
	if not cancel then
		if zoneType == 'poly' then
			points[#points + 1] = vec(xCoord, yCoord, zCoord)
		end

        local zoneData = {}

        zoneData.name = 'RHDZone:' .. zoneType

        if zoneType == "poly" then
            zoneData.points = points
            zoneData.thickness = height
        elseif zoneType == "box" then
            zoneData.coords = vec(xCoord, yCoord, zCoord)
            zoneData.size = vec(width, length, height)
            zoneData.rotation = heading
        elseif zoneType == "sphere" then
            zoneData.coords = vec(xCoord, yCoord, zCoord)
            zoneData.radius = height
        end

        local results = formatter[zoneType](zoneData)
        lib.setClipboard(results)
        lib.notify({ description = 'Hasil pembuatan zona telah di salin ke clipboard.', type = 'success'})
	end

    freecam.toggle()
    infoUI.remove('zone_creator')

	creatorActive = false
	controlsActive = false
	zoneType = nil
end

local function drawRectangle(rec)
    DrawPoly(rec[1].x, rec[1].y, rec[1].z, rec[2].x, rec[2].y, rec[2].z, rec[3].x, rec[3].y, rec[3].z, 180, 255, 54, 100)
    DrawPoly(rec[2].x, rec[2].y, rec[2].z, rec[1].x, rec[1].y, rec[1].z, rec[3].x, rec[3].y, rec[3].z, 180, 255, 54, 100)
    DrawPoly(rec[1].x, rec[1].y, rec[1].z, rec[4].x, rec[4].y, rec[4].z, rec[3].x, rec[3].y, rec[3].z, 180, 255, 54, 100)
    DrawPoly(rec[4].x, rec[4].y, rec[4].z, rec[1].x, rec[1].y, rec[1].z, rec[3].x, rec[3].y, rec[3].z, 180, 255, 54, 100)
end

local function drawLines()
	local thickness = vec(0, 0, height / 2)
    local activeA, activeB = vec(xCoord, yCoord, zCoord) + thickness, vec(xCoord, yCoord, zCoord) - thickness

    if zoneType == 'poly' then
        DrawLine(activeA.x, activeA.y, activeA.z, activeB.x, activeB.y, activeB.z, 180, 255, 54, 225)
    end

	for i = 1, #points do
		points[i] = vec(points[i].x, points[i].y, zCoord)
		local a = points[i] + thickness
		local b = points[i] - thickness
		local c = (points[i + 1] and vec(points[i + 1].x, points[i + 1].y, zCoord) or points[1]) + thickness
		local d = (points[i + 1] and vec(points[i + 1].x, points[i + 1].y, zCoord) or points[1]) - thickness
		local e = points[i]
		local f = (points[i + 1] and vec(points[i + 1].x, points[i + 1].y, zCoord) or points[1])

        if i == #points and zoneType == 'poly' then
            DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, 180, 255, 54, 225)
            DrawLine(activeA.x, activeA.y, activeA.z, c.x, c.y, c.z, 180, 255, 54, 225)
            DrawLine(activeB.x, activeB.y, activeB.z, d.x, d.y, d.z, 180, 255, 54, 225)
            DrawLine(a.x, a.y, a.z, activeA.x, activeA.y, activeA.z, 180, 255, 54, 225)
            DrawLine(b.x, b.y, b.z, activeB.x, activeB.y, activeB.z, 180, 255, 54, 225)
            DrawLine(xCoord, yCoord, zCoord, f.x, f.y, f.z, 180, 255, 54, 225)
            DrawLine(e.x, e.y, e.z, xCoord, yCoord, zCoord, 180, 255, 54, 225)
        else
            DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, 180, 255, 54, 225)
            DrawLine(a.x, a.y, a.z, c.x, c.y, c.z, 180, 255, 54, 225)
            DrawLine(b.x, b.y, b.z, d.x, d.y, d.z, 180, 255, 54, 225)
            DrawLine(e.x, e.y, e.z, f.x, f.y, f.z, 180, 255, 54, 225)
        end

        if i == #points and zoneType == 'poly' then
            drawRectangle({a, b, activeB, activeA})
            drawRectangle({activeA, activeB, d, c})
        else
            drawRectangle({a, b, d, c})
        end
	end
end

local function getRelativePos(origin, point, theta)
    if theta == 0.0 then return point end
    local p = point - origin
    local pX, pY = p.x, p.y
    theta = math.rad(theta)
    local cosTheta = math.cos(theta)
    local sinTheta = math.sin(theta)
    local x = math.floor(((pX * cosTheta - pY * sinTheta) + origin.x) * 100 + 0.0) / 100
    local y = math.floor(((pX * sinTheta + pY * cosTheta) + origin.y) * 100 + 0.0) / 100
    return x, y
end

local isFivem = cache.game == 'fivem'

local controls = {
    ['INPUT_LOOK_LR'] = isFivem and 1 or 0xA987235F,
    ['INPUT_LOOK_UD'] = isFivem and 2 or 0xD2047988,
    ['INPUT_MP_TEXT_CHAT_ALL'] = isFivem and 245 or 0x9720FCEE
}

return function ( zone_type )
	creatorActive = true
    controlsActive = true
	zoneType = zone_type or "poly"

	xCoord = round(RHDCache.coords.x) + 0.0
	yCoord = round(RHDCache.coords.y) + 0.0
	zCoord = round(RHDCache.coords.z) + 0.0
    
	step = 1
	heading = 0.0
	height = 4.0
	width = 4.0
	length = 4.0
	points = {}

	updateText()

    freecam.toggle()

    while creatorActive do
        Wait(0)

        if IsDisabledControlJustReleased(0, 73) then -- x
            controlsActive = not controlsActive
        end

        if displayMode == 3 or displayMode == 4 then
            if alignMovementWithCamera then
                local rightX, rightY = getRelativePos(vec2(xCoord, yCoord), vec2(xCoord + 2, yCoord), freecam.getRotation().z)
                local forwardX, forwardY = getRelativePos(vec2(xCoord, yCoord), vec2(xCoord, yCoord + 2), freecam.getRotation().z)

                DrawLine(xCoord, yCoord, zCoord, rightX, rightY or 0, zCoord, 0, 255, 0, 225)
                DrawLine(xCoord, yCoord, zCoord, forwardX, forwardY or 0, zCoord, 0, 255, 0, 225)
            end

            DrawLine(xCoord, yCoord, zCoord, xCoord + 2, yCoord, zCoord, 0, 0, 255, 225)
            DrawLine(xCoord, yCoord, zCoord, xCoord, yCoord + 2, zCoord, 0, 0, 255, 225)
            DrawLine(xCoord, yCoord, zCoord, xCoord, yCoord, zCoord + 2, 0, 0, 255, 225)
        end

        if zoneType == 'poly' then
            drawLines()
        elseif zoneType == 'box' then
            local rad = math.rad(-heading)
            local sinH = math.sin(rad)
            local cosH = math.cos(rad)
            local center = vec2(xCoord, yCoord)
            ---@type vector2[]
            points = {
                center + vec2((width * cosH + length * sinH), (length * cosH - width * sinH)) / 2,
                center + vec2(-(width * cosH - length * sinH), (length * cosH + width * sinH)) / 2,
                center + vec2(-(width * cosH + length * sinH), -(length * cosH - width * sinH)) / 2,
                center + vec2((width * cosH - length * sinH), -(length * cosH + width * sinH)) / 2,
            }

            drawLines()
        elseif zoneType == 'sphere' then
            ---@diagnostic disable-next-line: param-type-mismatch
            DrawMarker(28, xCoord, yCoord, zCoord, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, height, height, height, 180, 255, 54, 100, false, false, 0, false, false, false, false)
        end

        if controlsActive then
            DisableAllControlActions(0)
            EnableControlAction(0, controls['INPUT_LOOK_LR'], true)
            EnableControlAction(0, controls['INPUT_LOOK_UD'], true)
            EnableControlAction(0, controls['INPUT_MP_TEXT_CHAT_ALL'], true)

            local change = false
            local lStep = steps[1][step]
            local rStep = steps[2][step]

            if IsDisabledControlJustReleased(0, 17) then -- scroll up
                if IsDisabledControlPressed(0, 21) then -- shift held down
                    change = true
                    height += lStep
                elseif IsDisabledControlPressed(0, 36) then -- ctrl held down
                    change = true
                    width += lStep
                elseif IsDisabledControlPressed(0, 19) then -- alt held down
                    change = true
                    length += lStep
                elseif step < 11 then
                    change = true
                    step += 1
                end
            elseif IsDisabledControlJustReleased(0, 16) then -- scroll down
                if IsDisabledControlPressed(0, 21) then -- shift held down
                    change = true

                    if height - lStep > lStep then
                        height -= lStep
                    elseif height - lStep > 0 then
                        height = lStep
                    end
                elseif IsDisabledControlPressed(0, 36) then -- ctrl held down
                    change = true

                    if width - lStep > lStep then
                        width -= lStep
                    elseif width - lStep > 0 then
                        width = lStep
                    end
                elseif IsDisabledControlPressed(0, 19) then -- alt held down
                    change = true

                    if length - lStep > lStep then
                        length -= lStep
                    elseif length - lStep > 0 then
                        length = lStep
                    end
                elseif step > 1 then
                    change = true
                    step -= 1
                end
            elseif IsDisabledControlPressed(0, 188) then --- arrow up
                change = true

                if alignMovementWithCamera then
                    local newX, newY = getRelativePos(vec2(xCoord, yCoord), vec2(xCoord, yCoord + lStep), freecam.getRotation().z)

                    if math.abs(newX) < minCheck then
                        newX = 0.0
                    end

                    if math.abs(newY or 0) < minCheck then
                        newY = 0.0
                    end

                    xCoord = newX
                    yCoord = newY
                else
                    local newValue = yCoord + lStep

                    if math.abs(newValue) < minCheck then
                        newValue = 0.0
                    end

                    yCoord = newValue
                end
            elseif IsDisabledControlPressed(0, 187) then --- arrow down
                change = true

                if alignMovementWithCamera then
                    local newX, newY = getRelativePos(vec2(xCoord, yCoord), vec2(xCoord, yCoord - lStep), freecam.getRotation().z)

                    if math.abs(newX) < minCheck then
                        newX = 0.0
                    end

                    if math.abs(newY or 0) < minCheck then
                        newY = 0.0
                    end

                    xCoord = newX
                    yCoord = newY
                else
                    local newValue = yCoord - lStep

                    if math.abs(newValue) < minCheck then
                        newValue = 0.0
                    end

                    yCoord = newValue
                end
            elseif IsDisabledControlPressed(0, 190) then --- arrow right
                change = true

                if alignMovementWithCamera then
                    local newX, newY = getRelativePos(vec2(xCoord, yCoord), vec2(xCoord + lStep, yCoord), freecam.getRotation().z)

                    if math.abs(newX) < minCheck then
                        newX = 0.0
                    end

                    if math.abs(newY or 0) < minCheck then
                        newY = 0.0
                    end

                    xCoord = newX
                    yCoord = newY
                else
                    local newValue = xCoord + lStep

                    if math.abs(newValue) < minCheck then
                        newValue = 0.0
                    end

                    xCoord = newValue
                end
            elseif IsDisabledControlPressed(0, 189) then --- arrow left
                change = true

                if alignMovementWithCamera then
                    local newX, newY = getRelativePos(vec2(xCoord, yCoord), vec2(xCoord - lStep, yCoord), freecam.getRotation().z)

                    if math.abs(newX) < minCheck then
                        newX = 0.0
                    end

                    if math.abs(newY or 0) < minCheck then
                        newY = 0.0
                    end

                    xCoord = newX
                    yCoord = newY
                else
                    local newValue = xCoord - lStep

                    if math.abs(newValue) < minCheck then
                        newValue = 0.0
                    end

                    xCoord = newValue
                end
            elseif IsDisabledControlJustReleased(0, 45) then -- r
                change = true
                local newValue = zCoord + lStep

                if math.abs(newValue) < minCheck then
                    newValue = 0.0
                end

                zCoord = newValue
            elseif IsDisabledControlJustReleased(0, 23) then -- f
                change = true
                local newValue = zCoord - lStep

                if math.abs(newValue) < minCheck then
                    newValue = 0.0
                end

                zCoord = newValue
            elseif IsDisabledControlPressed(0, 313) then -- e
                change = true
                heading -= rStep

                if heading < 0 then
                    heading += 360
                end
            elseif IsDisabledControlPressed(0, 312) then -- q
                change = true
                heading += rStep

                if heading >= 360 then
                    heading -= 360
                end
            elseif IsDisabledControlJustReleased(0, 22) then -- space
                change = true

                if zoneType == 'poly' then
                    points[#points + 1] = vec2(xCoord, yCoord)
                end

                local newC = nil

                for i=1, #points do
                    newC = points[i]
                end

                xCoord = round(newC.x)
                yCoord = round(newC.y)
            elseif IsDisabledControlJustReleased(0, 201) then -- enter
                closeCreator(false)
            elseif IsDisabledControlJustReleased(0, 194) then -- backspace
                change = true

                if zoneType == 'poly' and #points > 0 then
                    xCoord = points[#points].x
                    yCoord = points[#points].y

                    points[#points] = nil
                end
            elseif IsDisabledControlJustReleased(0, 200) then -- esc
                SetPauseMenuActive(false)
                closeCreator(true)
            end

            if change then
                updateText()
            end
        end
    end
end