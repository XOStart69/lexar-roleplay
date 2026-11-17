local animData = require "data.anim"
local pedData = require "data.ped"

local functions = {}
local PlacingPed = false
local CurrentPedCreated = nil
local CurrentAnimation = {}

local function ButtonMessage(text)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end

local function Button(ControlButton)
    N_0xe83a3e3557a56640(ControlButton)
end

local function setupScaleform(scaleform)
    local scaleform = RequestScaleformMovie(scaleform)
    while not HasScaleformMovieLoaded(scaleform) do
        Wait(0)
    end

    DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 0, 0)

    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()
    
    PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()


    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(0)
    Button(GetControlInstructionalButton(2, 73, true))
    ButtonMessage("Cancel")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(1)
    Button(GetControlInstructionalButton(2, 176, true))
    ButtonMessage("Confirm")
    PopScaleformMovieFunctionVoid()
    
    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(2)
    Button(GetControlInstructionalButton(2, 172, true))
    Button(GetControlInstructionalButton(2, 173, true))
    ButtonMessage("Change Anim")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(3)
    Button(GetControlInstructionalButton(2, 189, true))
    Button(GetControlInstructionalButton(2, 190, true))
    ButtonMessage("Change Ped")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(4)
    Button(GetControlInstructionalButton(2, 15, true))
    Button(GetControlInstructionalButton(2, 14, true))
    ButtonMessage("Rotate Ped")
    PopScaleformMovieFunctionVoid()

    
    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(5)
    Button(GetControlInstructionalButton(2, 15, true))
    Button(GetControlInstructionalButton(2, 14, true))
    Button(GetControlInstructionalButton(2, 21, true))
    ButtonMessage("Zone Radius")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(80)
    PopScaleformMovieFunctionVoid()

    return scaleform
end

local RotationToDirection = function(rot)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosOfRotX = math.abs(math.cos(rotX))
    return vector3(-math.sin(rotZ) * cosOfRotX, math.cos(rotZ) * cosOfRotX, math.sin(rotX))
end

local function RayCastGamePlayCamera(distance)
    local camRot = GetGameplayCamRot()
    local camPos = GetGameplayCamCoord()
    local dir = RotationToDirection(camRot)
    local dest = camPos + (dir * distance)
    local ray = StartShapeTestRay(camPos, dest, 17, -1, 0)
    local _, hit, endPos, surfaceNormal, entityHit = GetShapeTestResult(ray)
    if hit == 0 then endPos = dest end
    return hit, endPos, entityHit, surfaceNormal
end

local function CancelPlacement()
    DeletePed(CurrentPedCreated)
    PlacingPed = false
    CurrentPedCreated = nil
end

---@param length number
---@return string
function functions.GenerateId ( length )
    local length = type(length) == "string" and 5 or type(length) == "table" and 5 or length or 5
    local characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local random_id = ""

    for i = 1, length do
        local random_index = math.random(1, #characters)
        random_id = random_id .. string.sub(characters, random_index, random_index)
    end

    return random_id
end

function functions.StartPlacer ( data )
    if PlacingPed then return end

    local animId = 1
    local PedId = 1
    local ZoneSetting = false
    local ZoneRadius = 0.5
    local heading = 0.0
    local EditLocation = data.type == "edit_location" or false
    local CreateLocation = data.type == "create_location" or false
    
    CurrentAnimation = animData[animId]
    CurrentPedModel = pedData[PedId].name

    if CreateLocation then
        lib.requestModel(CurrentPedModel, 1500)
        CurrentPedCreated = CreatePed(0, CurrentPedModel, 1.0, 1.0, 1.0, 0.0, false, false)
        
        SetEntityHeading(CurrentPedCreated, 0)
        lib.requestAnimDict(CurrentAnimation.dict)
        TaskPlayAnim(CurrentPedCreated, CurrentAnimation.dict, CurrentAnimation.clip, 2.0, 2.0, -1, 1, 0, false, false, false)
        
        SetEntityCollision(CurrentPedCreated, false, false)
        FreezeEntityPosition(CurrentPedCreated, true)
    end

    CreateThread(function()
        PlacingPed = true
        From = setupScaleform("instructional_buttons")
        while PlacingPed do
            local hit, coords, entity = RayCastGamePlayCamera(data.radius or 20.0)

            if CreateLocation then
                CurrentPCoords = GetEntityCoords(CurrentPedCreated)
                CurrentTCoords = GetWorldPositionOfEntityBone(CurrentPedCreated --[[ Entity ]], GetPedBoneIndex(CurrentPedCreated, 57597) --[[ integer ]])
                ZoneSetting = false
            end

            DisableControlAction(0, 21, true)
            DisableControlAction(0, 15, true)
            DisableControlAction(0, 14, true)
            DisableControlAction(0, 173, true)
            DisableControlAction(0, 172, true)
            DisableControlAction(0, 189, true)
            DisableControlAction(0, 190, true)
            DisableControlAction(0, 73, true)
            DisableControlAction(0, 176, true)

            DrawScaleformMovieFullscreen(From, 255, 255, 255, 255, 0)

            if hit then
                if CreateLocation then
                    SetEntityCoords(CurrentPedCreated, coords.x, coords.y, coords.z)
                else
                    ZoneSetting = true
                    DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ZoneRadius, ZoneRadius, ZoneRadius, 255, 42, 24, 100, false, false, 0, false, false, false, false)
                end
            end
            
            if IsDisabledControlPressed(0, 21) then
                ZoneSetting = true
                DrawMarker(28, CurrentTCoords.x, CurrentTCoords.y, CurrentTCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ZoneRadius, ZoneRadius, ZoneRadius, 255, 42, 24, 100, false, false, 0, false, false, false, false)
            end

            if IsDisabledControlJustPressed(0, 15)then
                if not ZoneSetting then
                    heading = heading + 15
                    if heading > 360 then heading = 0.0 end
                else
                    ZoneRadius += 0.1
                end
            end

            if IsDisabledControlJustPressed(0, 14)then
                if not ZoneSetting then
                    heading = heading - 15
                    if heading < 0 then heading = 360.0 end
                else
                    if ZoneRadius > 0.1 then
                        ZoneRadius -= 0.1
                    end
                end
            end

            if IsDisabledControlJustPressed(0, 173) and CreateLocation then
                if animId > 1 then
                    animId -= 1
                    CurrentAnimation = animData[animId]
                    lib.requestAnimDict(CurrentAnimation.dict)
                    TaskPlayAnim(CurrentPedCreated, CurrentAnimation.dict, CurrentAnimation.clip, 2.0, 2.0, -1, 1, 0, false, false, false)
                end
            end

            if IsDisabledControlJustPressed(0, 172) and CreateLocation then
                if animId < #animData then
                    animId += 1
                    CurrentAnimation = animData[animId]
                    lib.requestAnimDict(CurrentAnimation.dict)
                    TaskPlayAnim(CurrentPedCreated, CurrentAnimation.dict, CurrentAnimation.clip, 2.0, 2.0, -1, 1, 0, false, false, false)
                end
            end

            if IsDisabledControlJustPressed(0, 189) and CreateLocation then
                if PedId > 1 then
                    PedId -= 1
                    DeletePed(CurrentPedCreated)
                    lib.requestModel(pedData[PedId].name)
                    CurrentPedCreated = CreatePed(0, pedData[PedId].name, CurrentPCoords.x, CurrentPCoords.y, CurrentPCoords.z, heading, false, false)
                    lib.requestAnimDict(CurrentAnimation.dict)
                    TaskPlayAnim(CurrentPedCreated, CurrentAnimation.dict, CurrentAnimation.clip, 2.0, 2.0, -1, 1, 0, false, false, false)
                end
            end

            if IsDisabledControlJustPressed(0, 190) and CreateLocation then
                if PedId < #pedData then
                    PedId += 1
                    DeletePed(CurrentPedCreated)
                    lib.requestModel(pedData[PedId].name)
                    CurrentPedCreated = CreatePed(0, pedData[PedId].name, CurrentPCoords.x, CurrentPCoords.y, CurrentPCoords.z, heading, false, false)
                    lib.requestAnimDict(CurrentAnimation.dict)
                    TaskPlayAnim(CurrentPedCreated, CurrentAnimation.dict, CurrentAnimation.clip, 2.0, 2.0, -1, 1, 0, false, false, false)
                end
            end
            
            if IsDisabledControlJustPressed(0, 73) then
                CancelPlacement()
            end

            SetEntityHeading(CurrentPedCreated, heading)
            if IsDisabledControlJustPressed(0, 176) then
                
                if hit == 1 then
                    local sendData = {}
                    
                    if CreateLocation then
                        sendData = {
                            tCoords = vec(CurrentTCoords.x, CurrentTCoords.y, CurrentTCoords.z),
                            pCoords = vec(CurrentPCoords, heading),
                            radius = ZoneRadius,
                            anim = CurrentAnimation
                        }
                    else
                        sendData = {
                            tCoords = vec(coords.x, coords.y, coords.z),
                            radius = ZoneRadius,
                        }
                    end
    
                    if data.generated then
                        data.generated(sendData)
                    end
                end

            end
            
            Wait(1)
        end
    end)
end

return functions