local QBCore = exports[Config.Core]:GetCoreObject()

-- Isi webhook discord per job di sini
local Webhooks = {
    ['police'] = '',
    ['ambulance'] = '',
    ['rsroxwood'] = '',
    ['mechanic'] = '',
    ['government'] = '',
    ['paspampres'] = '',
    ['mechanic969'] = '',
    ['maxspeedgarage'] = '',
    ['burgenkcafe'] = '',
    ['kkpresto'] = '',
    ['resto'] = '',
    ['mhcafe'] = '',
    ['stunberg'] = '',
    ['pengadilan'] = '',
    ['usmarshal'] = '',
    ['taxism'] = '',
    ['pdcafe'] = '',
    ['mercenarysm'] = '',
    ['smmotel'] = '',
    ['kkpgarage'] = '',
}

local function stamp()
    return os.date('%d/%m/%Y %H:%M:%S')
end

local function send(source, job, state)
    local jobConfig = Config.AuthJobs[job]
    local url = Webhooks[job]

    if not jobConfig or not url or url == '' then return end

    local player = QBCore.Functions.GetPlayer(source)
    local name = player and player.PlayerData.charinfo
        and ('%s %s'):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname)
        or GetPlayerName(source)

    local identifier = player and player.PlayerData.citizenid or 'unknown'

    local payload = {
        username = 'Duty Log',
        embeds = {
            {
                title = jobConfig.LogTitle,
                description = ('**%s**\nCitizen ID: `%s`\nJob: `%s`\nStatus: **%s**\nWaktu: %s')
                    :format(name, identifier, job, state, stamp()),
                color = jobConfig.Color,
                thumbnail = { url = jobConfig.IconURL },
                footer = { text = ('Server ID %s'):format(source) },
            },
        },
    }

    PerformHttpRequest(url, function() end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent('sm_dutylog:server:userjoined', function(job, duty)
    local source = source

    if type(job) ~= 'string' then return end

    send(source, job, duty and 'Masuk kota (On Duty)' or 'Masuk kota (Off Duty)')
end)

RegisterNetEvent('sm_dutylog:server:onDuty', function(job)
    local source = source

    if type(job) ~= 'string' then return end

    send(source, job, 'On Duty')
end)

RegisterNetEvent('sm_dutylog:server:offDuty', function(job)
    local source = source

    if type(job) ~= 'string' then return end

    send(source, job, 'Off Duty')
end)

lib.print.info('sm_dutylog server siap')
