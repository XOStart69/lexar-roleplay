local minigameList = localmodule 'config.minigame'

local minigameBusy = false
local minigameOptions = {}

for k, v in pairs(minigameList) do
    minigameOptions[#minigameOptions+1] = {
        title = v.label,
        icon = 'gamepad',
        onSelect = function ()
            minigameBusy = true
            local level = v.level?[2]?.value

            if v.level then
                local input = lib.inputDialog(v.label, {
                    { type = 'select', label = 'Pilih Level', placeholder = '', options = v.level },
                })
                if input?[1] then
                    level = input[1]
                end
            end
            
            local ok, response = pcall(function ()
                return v.onSelect(level)
            end)

            minigameBusy = false
            
            if not ok then
                return lib.print.error('Error executing minigame onSelect:', response)
            end

            if response then
                lib.notify({
                    description = 'Minigame berhasil diselesaikan!',
                    type = 'success'
                })
            else
                lib.notify({
                    description = 'Minigame gagal, coba lagi.',
                    type = 'error'
                })
            end
        end
    }
end

lib.registerContext({
    id = 'latihan_minigame_menu',
    title = 'Latihan Minigame',
    options = minigameOptions
})

RegisterCommand('latihanminigame', function ()
    if minigameBusy then
        return lib.notify({
            description = 'Selesaikan minigame yang sedang berlangsung terlebih dahulu.',
            type = 'error'
        })
    end
    lib.showContext('latihan_minigame_menu')
end, false)