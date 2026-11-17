local CONNECT_TIMEOUT = 10000

local busy = false

local function resetVoice()
    local address = GetConvar('voice_externalAddress', '')
    local port = GetConvarInt('voice_externalPort', 0)

    if address ~= '' and port ~= 0 then
        MumbleSetServerAddress(address, port)

        local deadline = GetGameTimer() + CONNECT_TIMEOUT

        while not MumbleIsConnected() and GetGameTimer() < deadline do
            Wait(250)
        end
    end

    NetworkClearVoiceChannel()
    NetworkSessionVoiceLeave()
    Wait(50)
    NetworkSetVoiceActive(false)
    MumbleClearVoiceTarget(2)
    Wait(3000)
    MumbleSetVoiceTarget(2)
    NetworkSetVoiceActive(true)
end

RegisterCommand('batuk', function()
    if busy then return end

    busy = true

    local done = lib.progressBar({
        duration = 3000,
        label = 'batuk..',
        useWhileDead = false,
        canCancel = false,
        disable = {
            combat = true,
        },
        anim = {
            dict = 'timetable@gardener@smoking_joint',
            clip = 'idle_cough',
        }
    })

    if done then
        resetVoice()
        lib.notify({ description = 'Voice/Mumble reset', type = 'success' })
    end

    busy = false
end, false)
