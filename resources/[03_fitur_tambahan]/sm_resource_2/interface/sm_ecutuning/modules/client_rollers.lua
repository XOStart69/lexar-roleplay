HRS_DynoRollers = {}
local frames = {}
local pending = {}
local setup = nil
local positions = {}
local function positionKey(p) return ('%.2f:%.2f:%.2f'):format(p.x,p.y,p.z) end
local function syncPosition(base,frame)
    local p=GetEntityCoords(base)
    TriggerTokenEvent('sm_ecutuning:dyno:carriage',p.x,p.y,p.z,frame.wheelbase)
end
local slots = {
    { x = -0.85, y =  0.76, axle = 'front' },
    { x =  0.85, y =  0.76, axle = 'front' },
    { x = -0.85, y = -2.10, axle = 'rear' },
    { x =  0.85, y = -2.10, axle = 'rear' },
}
local function settings() return ECUConfig.Dyno.Rollers or {} end
local function attach(obj,base,x,y,z,angle)
    AttachEntityToEntity(obj,base,0,x,y,z,angle or 0.0,0.0,0.0,
        false,false,false,false,2,true)
end
local function frontY(frame) return -2.10 + frame.wheelbase end
local function layout(base,frame)
    for _, drum in ipairs(frame.drums) do
        attach(drum.obj,base,drum.slot.x,
            drum.slot.axle == 'front' and frontY(frame) or -2.10,0.606,drum.angle)
    end
    for _, part in ipairs(frame.parts) do
        local y = part.kind == 'front' and frontY(frame) or -2.10
        if part.stage==0 then y=-1.685+.65
        elseif part.stage==1 then y=frontY(frame)-.415-.65 end
        if part.kind ~= 'tail' then attach(part.obj,base,0,y,0) end
    end
end

function HRS_DynoRollers.adjust(base, wheelbase)
    local f = frames[base]
    if not f or type(wheelbase) ~= 'number' or wheelbase ~= wheelbase then return false end
    f.wheelbase = math.max(settings().minWheelbase or 2.2,math.min(settings().maxWheelbase or 3.4,wheelbase))
    layout(base,f)
    return true
end

local function nearest(position)
    local best, distance = nil, (ECUConfig.Dyno.MountDistance or 4.0) + 3.0
    for base,f in pairs(frames) do
        if not f.ghost and DoesEntityExist(base) then
            local d = #(position-GetEntityCoords(base))
            if d < distance then best,distance=base,d end
        end
    end
    return best
end

function HRS_DynoRollers.remove(base)
    pending[base] = nil
    local frame = frames[base]
    if not frame then return end
    frames[base] = nil
    for _, drum in ipairs(frame.drums) do
        if DoesEntityExist(drum.obj) then DeleteEntity(drum.obj) end
    end
    for _, part in ipairs(frame.parts) do
        if DoesEntityExist(part.obj) then DeleteEntity(part.obj) end
    end
end

function HRS_DynoRollers.spawn(base, ghost)
    if settings().enabled == false then return end
    HRS_DynoRollers.remove(base)
    local ticket = {}
    pending[base] = ticket
    CreateThread(function()
        local names={settings().model or 'hrs_dyno_roller','hrs_dyno_carriage',
            'hrs_dyno_grate_0','hrs_dyno_grate_1','hrs_dyno_grate_2'}
        local hashes={}
        for i,name in ipairs(names) do hashes[i]=GetHashKey(name);RequestModel(hashes[i]) end
        local hash=hashes[1]
        local function loaded()
            for _,h in ipairs(hashes) do if not HasModelLoaded(h) then return false end end
            return true
        end
        local function release() for _,h in ipairs(hashes) do SetModelAsNoLongerNeeded(h) end end
        local deadline = GetGameTimer() + 8000
        while not loaded() and GetGameTimer() < deadline
            and pending[base] == ticket and DoesEntityExist(base) do Wait(0) end
        if pending[base] ~= ticket or not DoesEntityExist(base) then
            release()
            return
        end
        pending[base] = nil
        if not loaded() then
            print('^1[Debug Dyno]^7 Roller model failed to load: ' .. tostring(settings().model))
            release()
            return
        end
        local frame = { drums = {}, parts = {}, wheelbase=2.86, ghost = ghost, front = 0.0, rear = 0.0,
                        updated = 0, vehicle = nil }
        frames[base] = frame
        local p = GetEntityCoords(base)
        for _, slot in ipairs(slots) do
            local obj = CreateObjectNoOffset(hash, p.x, p.y, p.z, false, false, false)
            if obj ~= 0 and DoesEntityExist(obj) then
                SetEntityCollision(obj, false, false)
                SetEntityInvincible(obj, true)
                if ghost then SetEntityAlpha(obj, 190, false) end
                AttachEntityToEntity(obj, base, 0, slot.x, slot.y, 0.606,
                    0.0, 0.0, 0.0, false, false, false, false, 2, true)
                frame.drums[#frame.drums + 1] = { obj = obj, slot = slot, angle = 0.0 }
            end
        end
        local function part(h,kind,stage)
            local obj=CreateObjectNoOffset(h,p.x,p.y,p.z,false,false,false)
            if obj ~= 0 and DoesEntityExist(obj) then
                SetEntityCollision(obj,false,false);SetEntityInvincible(obj,true)
                FreezeEntityPosition(obj,true)
                if ghost then SetEntityAlpha(obj,190,false) end
                frame.parts[#frame.parts+1]={obj=obj,kind=kind,stage=stage}
            end
        end
        part(hashes[2],'rear');part(hashes[2],'front')
        for stage=0,1 do part(hashes[stage+3],'grate',stage) end
        part(hashes[5],'tail')
        layout(base,frame)
        local saved=positions[positionKey(p)]
        if saved then HRS_DynoRollers.adjust(base,saved) end
        release()
    end)
end

function HRS_DynoRollers.beginSetup(vehicle, confirmed)
    if setup then return false end
    local base=nearest(GetEntityCoords(vehicle))
    if not base or not frames[base] then return false end
    local f=frames[base]
    setup={base=base,vehicle=vehicle,confirm=confirmed,original=f.wheelbase,
        frozen=IsEntityPositionFrozen(vehicle),position=GetEntityCoords(vehicle),heading=GetEntityHeading(vehicle)}
    FreezeEntityPosition(vehicle,true)
    local vf,bf=GetEntityForwardVector(vehicle),GetEntityForwardVector(base)
    local reversed=vf.x*bf.x+vf.y*bf.y<0
    SetEntityHeading(vehicle,(GetEntityHeading(base)+(reversed and 180 or 0))%360)
    local axle={}
    for _,name in ipairs({'wheel_lf','wheel_rf','wheel_lr','wheel_rr'}) do
        local bone=GetEntityBoneIndexByName(vehicle,name)
        if bone ~= -1 then
            local p=GetWorldPositionOfEntityBone(vehicle,bone)
            axle[#axle+1]=GetOffsetFromEntityGivenWorldCoords(base,p.x,p.y,p.z)
        end
    end
    if #axle==4 then
        local front=(axle[1]+axle[2])/2;local rear=(axle[3]+axle[4])/2
        local fixed=front.y<rear.y and front or rear
        setup.target=math.abs(front.y-rear.y)
        local forward,right=GetEntityMatrix(base)
        local p=setup.position+right*(-fixed.x)+forward*(-2.10-fixed.y)
        SetEntityCoordsNoOffset(vehicle,p.x,p.y,p.z,false,false,false)
    end
    FreezeEntityPosition(vehicle,true)
    f.vehicle=vehicle
    setup.dir=0
    ECU_SendNUI({type='dynoAdjust',show=true,wheelbase=f.wheelbase,target=setup.target,min=settings().minWheelbase or 2.2,max=settings().maxWheelbase or 3.4})
    interface.focus(true,true)
    return true
end
function HRS_DynoRollers.isSettingUp() return setup ~= nil end
local function finishSetup(accept)
    local s=setup;if not s then return end;setup=nil
    ECU_SendNUI({type='dynoAdjust',show=false})
    interface.focus(false,false)
    if not accept then HRS_DynoRollers.adjust(s.base,s.original) end
    if DoesEntityExist(s.vehicle) then
        if not accept then
            SetEntityCoordsNoOffset(s.vehicle,s.position.x,s.position.y,s.position.z,false,false,false)
            SetEntityHeading(s.vehicle,s.heading)
        end
        FreezeEntityPosition(s.vehicle,s.frozen)
    end
    if frames[s.base] then syncPosition(s.base,frames[s.base]) end
    if accept then s.confirm() end
end

interface.callback('dynoAdjustMove',function(d,cb)
    if setup then
        local v=tonumber(d and d.dir) or 0
        setup.dir=(v>0 and 1) or (v<0 and -1) or 0
    end
    cb('ok')
end)
interface.callback('dynoAdjustConfirm',function(_,cb)
    cb('ok')
    if setup then CreateThread(function() finishSetup(true) end) end
end)
interface.callback('dynoAdjustCancel',function(_,cb)
    cb('ok')
    if setup then CreateThread(function() finishSetup(false) end) end
end)

RegisterNetEvent('sm_ecutuning:dyno:carriage',function(x,y,z,wheelbase)
    if type(x)~='number' or type(y)~='number' or type(z)~='number' or type(wheelbase)~='number' then return end
    local p=vector3(x,y,z);positions[positionKey(p)]=wheelbase
    local base=nearest(p)
    if base and #(GetEntityCoords(base)-p)<0.1 then HRS_DynoRollers.adjust(base,wheelbase) end
end)
CreateThread(function() Wait(1500);TriggerTokenEvent('sm_ecutuning:dyno:carriageSnapshot') end)

CreateThread(function()
    local last=GetGameTimer()
    while true do
        local now=GetGameTimer();local dt=math.min((now-last)/1000,0.1);last=now
        if setup then
            local s=setup;local f=frames[s.base]
            if not f or not DoesEntityExist(s.vehicle) or GetVehiclePedIsIn(PlayerPedId(),false) ~= s.vehicle then
                finishSetup(false)
            else
                for _,key in ipairs({71,72,172,173,191,177,38,199,200}) do DisableControlAction(0,key,true) end
                local direction=(IsDisabledControlPressed(0,172) and 1 or 0)-(IsDisabledControlPressed(0,173) and 1 or 0)+(s.dir or 0)
                if direction>1 then direction=1 elseif direction<-1 then direction=-1 end
                if direction ~= 0 then HRS_DynoRollers.adjust(s.base,f.wheelbase+direction*(settings().adjustSpeed or .35)*dt) end
                if now-(s.lastUI or 0)>50 then
                    s.lastUI=now
                    ECU_SendNUI({type='dynoAdjust',show=true,wheelbase=f.wheelbase,target=s.target,min=settings().minWheelbase or 2.2,max=settings().maxWheelbase or 3.4})
                end
                if IsDisabledControlJustPressed(0,191) then finishSetup(true)
                elseif IsDisabledControlJustPressed(0,177) then finishSetup(false) end
            end
        end
        Wait(setup and 0 or 100)
    end
end)

local function finite(n) return type(n) == 'number' and n == n and math.abs(n) < 100000 end

function HRS_DynoRollers.speed(vehicle, wheels, angularSpeed)
    local front, rear = 0.0, 0.0
    local count = GetVehicleNumberOfWheels(vehicle)
    for _, index in ipairs(wheels or {}) do
        if index >= 0 and index < count then
            local radius = settings().fallbackTireRadius or 0.34
            if GetVehicleWheelTireColliderSize then
                local r = GetVehicleWheelTireColliderSize(vehicle, index)
                if finite(r) and r > 0.1 and r < 1.5 then radius = r end
            end
            local speed = angularSpeed * radius
            if index <= 1 then front = speed else rear = speed end
        end
    end
    return front, rear
end

function HRS_DynoRollers.drive(vehicle, front, rear)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    if not finite(front) or not finite(rear) then return end
    local now = GetGameTimer()
    local best, bestDistance = nil, 5.0
    local pos = GetEntityCoords(vehicle)
    for base, frame in pairs(frames) do
        if not frame.ghost and DoesEntityExist(base) then
            local localPos = GetOffsetFromEntityGivenWorldCoords(base, pos.x, pos.y, pos.z)
            if math.abs(localPos.x) < 1.65 and math.abs(localPos.y) < 2.8
                and localPos.z > 0.5 and localPos.z < 3.5 then
                local distance = #(pos - GetEntityCoords(base))
                if distance < bestDistance then best, bestDistance = frame, distance end
            end
        end
    end
    if best then
        for base, frame in pairs(frames) do
            if frame == best then
                local vf, bf = GetEntityForwardVector(vehicle), GetEntityForwardVector(base)
                if vf.x * bf.x + vf.y * bf.y < 0 then front, rear = -rear, -front end
                break
            end
        end
        best.vehicle, best.front, best.rear, best.updated = vehicle,
            math.max(-120, math.min(120, front)), math.max(-120, math.min(120, rear)), now
    end
end

function HRS_DynoRollers.stop(vehicle)
    for _, frame in pairs(frames) do
        if frame.vehicle == vehicle then
            frame.front, frame.rear, frame.vehicle = 0.0, 0.0, nil
        end
    end
end

CreateThread(function()
    local last = GetGameTimer()
    while true do
        local now = GetGameTimer()
        local dt = math.min(math.max((now-last)/1000.0, 0), 0.1)
        last = now
        local moving = false
        local pedPos = GetEntityCoords(PlayerPedId())
        for base, frame in pairs(frames) do
            if not DoesEntityExist(base) then
                HRS_DynoRollers.remove(base)
            else
                if now-frame.updated > 1500 or (frame.vehicle and not DoesEntityExist(frame.vehicle)) then
                    frame.front, frame.rear, frame.vehicle = 0.0, 0.0, nil
                end
                if #(pedPos-GetEntityCoords(base)) < (settings().drawDistance or 80.0) then
                    for _, drum in ipairs(frame.drums) do
                        local speed = frame[drum.slot.axle]
                        if math.abs(speed) > 0.001 and DoesEntityExist(drum.obj) then
                            moving = true
                            drum.angle = (drum.angle - speed / (settings().radius or 0.320)
                                * dt * 180.0 / math.pi) % 360.0
                            local s = drum.slot
                            attach(drum.obj,base,s.x,s.axle=='front' and frontY(frame) or -2.10,0.606,drum.angle)
                        end
                    end
                    for _,part in ipairs(frame.parts) do
                        if part.kind=='tail' and DoesEntityExist(part.obj) then
                            local a,b=frontY(frame)+.415,2.42
                            local forward,right,up=GetEntityMatrix(base)
                            local p=GetOffsetFromEntityInWorldCoords(base,0,(a+b)/2,0)
                            local length=b-a
                            SetEntityMatrix(part.obj,forward.x*length,forward.y*length,forward.z*length,
                                right.x,right.y,right.z,up.x,up.y,up.z,p.x,p.y,p.z)
                        end
                    end
                end
            end
        end
        Wait(moving and 0 or 40)
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    finishSetup(false)
    for base in pairs(frames) do HRS_DynoRollers.remove(base) end
    pending = {}
end)
