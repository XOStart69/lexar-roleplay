local function applyStreamerMode(status)
    if disableMusic == status then return end

    disableMusic = status

    TriggerEvent("xsound:streamerMode", disableMusic)
end

AddEventHandler("sm_audio:streamerMode", function(status)
    applyStreamerMode(status and true or false)
end)

AddEventHandler("xsound:streamerMode", function(status)
    if not status then return end

    local ids = {}
    local count = 0

    for k in pairs(soundInfo) do
        count = count + 1
        ids[count] = k
    end

    for i = 1, count do
        Destroy(ids[i])
    end
end)

AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= 'sm_resource_1' then return end

    local ok, active = pcall(function()
        return exports.sm_resource_1:isStreamerMode()
    end)

    if ok then
        applyStreamerMode(active and true or false)
    end
end)
