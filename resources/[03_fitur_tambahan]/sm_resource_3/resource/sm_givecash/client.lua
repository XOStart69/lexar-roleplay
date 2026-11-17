local config = localmodule 'config'

local Wait = Wait
local DoesEntityExist = DoesEntityExist
local GetEntityCoords = GetEntityCoords
local groupdigits = lib.math.groupdigits

local MAX_GIVE = config.maxGive
local WATCH_DISTANCE = 2.0
local ANIM_DICT = 'mp_safehouselost@'

local dialogOpen = false

---@param text string
---@param kind string
local function notify(text, kind)
    lib.notify({ title = text, type = kind })
end

---@param entity number
local function watchTarget(entity)
    CreateThread(function()
        while dialogOpen do
            if not DoesEntityExist(entity) or #(GetEntityCoords(entity) - GetEntityCoords(cache.ped)) > WATCH_DISTANCE then
                dialogOpen = false
                lib.closeInputDialog()
                lib.closeAlertDialog()
                notify('tidak ditemukan orangnya!', 'error')
                break
            end

            Wait(500)
        end
    end)
end

---@param entity number
local function giveCash(entity)
    if dialogOpen or not IsPedAPlayer(entity) then return end

    local playerIndex = NetworkGetPlayerIndexFromPed(entity)
    if playerIndex == -1 then return end

    local targetId = GetPlayerServerId(playerIndex)
    local cash = lib.callback.await('sm_givecash:server:cash', false) or 0

    if cash <= 0 then
        return notify('tidak punya cukup uang!', 'error')
    end

    dialogOpen = true
    watchTarget(entity)

    local input = lib.inputDialog('Give Cash', {
        {
            type = 'number',
            label = 'Jumlah',
            description = 'Uang kamu $' .. groupdigits(cash),
            default = 1,
            min = 1,
            max = MAX_GIVE,
            required = true
        }
    })

    local amount = input and input[1]

    if not dialogOpen or not amount then
        dialogOpen = false
        return
    end

    if amount > cash then
        dialogOpen = false
        return notify('tidak cukup uang!', 'error')
    end

    local confirm = lib.alertDialog({
        header = 'Konfirmasi',
        content = ('Kasih $%s ke orang ini?'):format(groupdigits(amount)),
        centered = true,
        cancel = true,
        size = 'md'
    })

    local stillOpen = dialogOpen
    dialogOpen = false

    if not stillOpen or confirm ~= 'confirm' then return end

    TriggerTokenEvent('sm_givecash:server:give', targetId, amount)
end

RegisterNetEvent('sm_givecash:client:given', function()
    if not lib.requestAnimDict(ANIM_DICT, 5000) then return end

    local ped = cache.ped
    TaskPlayAnim(ped, ANIM_DICT, 'package_dropoff', 8.0, -8.0, -1, 0, 0, false, false, false)
    RemoveAnimDict(ANIM_DICT)
    Wait(3500)
    ClearPedTasks(ped)
end)

ox_target:addGlobalPlayer({
    {
        name = 'sm_givecash',
        icon = 'fa-solid fa-money-bill-wave',
        label = 'Give Cash',
        distance = 1.5,
        canInteract = function()
            return not cache.vehicle
        end,
        onSelect = function(data)
            giveCash(data.entity)
        end,
    },
})
