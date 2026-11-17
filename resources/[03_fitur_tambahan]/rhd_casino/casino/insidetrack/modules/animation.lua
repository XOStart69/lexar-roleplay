local Anim = {}
local _scene, _seatPos, _seatRot
local _enterSeq = 0
local _exitSeq = 0
local ANIM_DICT_MALE <const> = 'anim_casino_a@amb@casino@games@insidetrack@male'
local ANIM_DICT_FEMALE <const> = 'anim_casino_a@amb@casino@games@insidetrack@female'
local function getDict()
    return IsPedMale(cache.ped) and ANIM_DICT_MALE or ANIM_DICT_FEMALE
end

local function stopScene()
    _scene = nil
    ClearPedTasksImmediately(cache.ped)
end

---@param animName string
---@param looped boolean
---@return number durasi
local function playScene(animName, looped)
    if not _seatPos or not _seatRot then return 0 end
    local dict = getDict()
    if not lib.requestAnimDict(dict, 5000) then
        return 0
    end
    local hold = looped and true or false
    local scene = NetworkCreateSynchronisedScene(
        _seatPos.x, _seatPos.y, _seatPos.z,
        _seatRot.x, _seatRot.y, _seatRot.z,
        0, false, hold, 1065353216, 0, 1065353216
    )
    NetworkAddPedToSynchronisedScene(cache.ped, scene, dict, animName, 2.0, -1.5, 13, 16, 1148846080, 0)
    NetworkStartSynchronisedScene(scene)
    _scene = scene
    return GetAnimDuration(dict, animName) * 1000
end

---@param seatPos  vector3
---@param heading  number
function Anim.setup(seatPos, heading)
    _seatPos = seatPos
    _seatRot = vector3(0.0, 0.0, heading)
    lib.requestAnimDict(getDict(), 5000)
end

---@param onDone fun()
function Anim.enter(onDone)
    local clips = {
        'enter_left_readyidle',
        'enter_left_readyidle_short',
        'enter_right_readyidle',
        'enter_right_readyidle_short',
    }
    local clip = clips[math.random(1, #clips)]
    _enterSeq = _enterSeq + 1
    local mySeq = _enterSeq
    local dur = playScene(clip, false)
    if dur <= 0 then dur = 2000 end
    CreateThread(function()
        Wait(math.max(0, math.floor(dur) - 300))
        if mySeq ~= _enterSeq or not _seatPos then return end
        FreezeEntityPosition(cache.ped, true)
        Anim.idle()
        if onDone then onDone() end
    end)
end

function Anim.idle()
    playScene('readyidle', true)
end

---@param onDone fun()|nil
function Anim.exit(onDone)
    local clips = { 'exit_left', 'exit_right' }
    local clip = clips[math.random(1, 2)]
    _exitSeq = _exitSeq + 1
    local mySeq = _exitSeq
    FreezeEntityPosition(cache.ped, false)
    local dur = playScene(clip, false)
    if dur <= 0 then dur = 1500 end
    CreateThread(function()
        local wait = math.min(5000, math.max(0, math.floor(dur) - 200))
        Wait(wait)
        if mySeq ~= _exitSeq then return end
        Anim.cleanup()
        if onDone then onDone() end
    end)
end

function Anim.cleanup()
    _enterSeq = _enterSeq + 1
    _exitSeq = _exitSeq + 1
    stopScene()
    FreezeEntityPosition(cache.ped, false)
    ClearPedTasks(cache.ped)
    _seatPos = nil
    _seatRot = nil
end
return Anim
