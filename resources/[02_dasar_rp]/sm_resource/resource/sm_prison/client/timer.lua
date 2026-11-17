local uiShow = false
local oocUiShow = false

local function secondToClock(seconds)
    local total_seconds = tonumber(seconds)
    if total_seconds <= 0 then return 0, 0, 0 end
    local hours = string.format('%02.f', math.floor(total_seconds / 3600))
    local mins = string.format('%02.f', math.floor(total_seconds / 60 - (hours * 60)))
    local secs = string.format('%02.f', math.floor(total_seconds - hours * 3600 - mins * 60))
    return hours, mins, secs
end

RegisterNetEvent('sm_prison:updateTimer', function(value)
    if source == '' then return end

    if not value or value < 1 then
        uiShow = false
        infoUI.remove('prison:timer')
        return
    end

    local h, m, s = secondToClock(value)
    local text = ('%s Jam %s Menit %s Detik'):format(h, m, s)

    uiShow = true
    infoUI.show({
        id = 'prison:timer',
        title = 'Masa tahanan',
        icon = 'fa-solid fa-clock',
        description = text
    })
end)

RegisterNetEvent('sm_prison:updateOOCTimer', function(value)
    if source == '' then return end

    if not value or value < 1 then
        oocUiShow = false
        infoUI.remove('oocprison:timer')
        return
    end

    local h, m, s = secondToClock(value)
    local text = ('%s Jam %s Menit %s Detik'):format(h, m, s)

    oocUiShow = true
    infoUI.show({
        id = 'oocprison:timer',
        title = 'Penjara OOC',
        icon = 'fa-solid fa-lock',
        description = text
    })
end)

exports('inPrison', function()
    return uiShow
end)

exports('inOOCPrison', function()
    return oocUiShow
end)