CreateThread(function()
    while not interface.ready() do
        Wait(100)
    end

    interface.init(true)
end)

---@param file 'bomb'|'cough'|'stun'
---@param volume number 0-1
function playTacticalGasSound(file, volume)
    SendNUIMessage({
        target = 'tacticalgas',
        data = { action = 'play', file = file, volume = volume }
    })
end
