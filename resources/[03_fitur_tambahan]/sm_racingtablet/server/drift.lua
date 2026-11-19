---@type table<number, number>
local scores = {}

cwCallback.register('sm_racingtablet:server:driftStart', function(src)
    scores[src] = 0
end)

cwCallback.register('sm_racingtablet:server:driftSubmit', function(src, score)
    scores[src] = math.floor(tonumber(score) or 0)

    return scores[src]
end)

cwCallback.register('sm_racingtablet:server:driftFinish', function(src)
    local score = scores[src]

    scores[src] = nil

    return score or 0
end)

AddEventHandler('playerDropped', function() scores[source] = nil end)