local Anim = {}

local requestedDicts = {}

function Anim.Ready(dict)
    if not dict or dict == '' then
        return false
    end

    if HasAnimDictLoaded(dict) then
        return true
    end

    local gameTimer = GetGameTimer()
    local requestedAt = requestedDicts[dict]

    if not requestedAt or (gameTimer - requestedAt > 1000) then
        RequestAnimDict(dict)
        requestedDicts[dict] = gameTimer
    end

    return false
end

function Anim.Name(animData)
    if not animData then
        return nil
    end

    local name = animData.name or animData.clip

    if not name or name == '' then
        return nil
    end

    return name
end

function Anim.Play(ped, animData, flags)
    local name = Anim.Name(animData)

    if not name or not Anim.Ready(animData.dict) then
        return false
    end

    TaskPlayAnim(ped, animData.dict, name, 8.0, -8.0, -1, flags or 50, 0.0, false, false, false)

    return true
end

function Anim.Stop(ped, animData)
    if not animData or not animData.dict or animData.dict == '' or not DoesEntityExist(ped) then
        return
    end

    StopAnimTask(ped, animData.dict, animData.name or animData.clip, 4.0)
end

function Anim.Cleanup()
    for dict in pairs(requestedDicts) do
        if HasAnimDictLoaded(dict) then
            RemoveAnimDict(dict)
        end
    end

    requestedDicts = {}
end

return Anim
