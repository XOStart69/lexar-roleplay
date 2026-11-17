--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

local borrowing = false
local waitingKey = false
local token = 0

local function release()
    if waitingKey then
        waitingKey = false
        lib.hideTextUI()
    end

    if not borrowing then return end
    borrowing = false
    SetNuiFocus(false, false)
end

---@param ms number
local function releaseAfter(ms)
    token = token + 1
    local current = token

    SetTimeout(ms, function()
        if token == current then release() end
    end)
end

RegisterNUICallback('clipboardResult', function(data, cb)
    cb(1)

    local stage = data.stage

    if stage == 'gesture' then
        if not borrowing then
            return lib.notify({ title = 'Clipboard', description = 'Gagal menyalin, tutup menu lalu coba lagi', type = 'error' })
        end

        waitingKey = true
        releaseAfter(11000)
        lib.showTextUI('[ENTER] Salin ke clipboard  \n[ESC] Batal')
        return
    end

    release()

    if stage == 'key' then
        lib.notify({
            title = 'Clipboard',
            description = data.ok and 'Berhasil disalin' or 'Gagal menyalin',
            type = data.ok and 'success' or 'error'
        })
    elseif stage == 'timeout' then
        lib.notify({ title = 'Clipboard', description = 'Batal menyalin', type = 'error' })
    end
end)

---@param value string
function lib.setClipboard(value)
    if borrowing or IsNuiFocused() then
        return SendNUIMessage({
            action = 'setClipboard',
            data = value
        })
    end

    borrowing = true
    SetNuiFocus(true, false)
    releaseAfter(1000)

    SetTimeout(0, function()
        SendNUIMessage({
            action = 'setClipboard',
            data = value
        })
    end)
end
