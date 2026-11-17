
local isCalling = false
local cooldown
local cooldownTime = 18 -- menit

local timer = require 'modules.timers.shared'
local config = require 'resource.illegal_activity.phone.config'

local function callingProgress()
    return lib.progressBar({
        duration = 5000,
        label = 'Menghubungi...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'random@kidnap_girl',
            clip = 'ig_1_girl_on_phone_loop'
        },
        prop = {
            model = `prop_phone_ing`,
            pos = vec3(0.0, 0.0, 0.0),
            rot = vec3(0.0, 0.0, 0.0),
            bone = 28422,
            rotOrder = 1
        }
    })
end

local function requestInfo(infoType)
    if isCalling then return end

    if cooldown then
        return lib.notify({
            title = 'Telepon umum',
            description = 'Kontak sedang sibuk! Coba lagi dalam ' .. cooldown:getTimeLeftFormat(),
            type = 'error'
        })
    end

    isCalling = true

    if not callingProgress() then
        isCalling = false

        return lib.notify({
            title = 'Telepon Umum',
            description = 'Panggilan dibatalkan',
            type = 'error'
        })
    end

    local result = lib.callback.await('phonebooth:server:requestInfo', false, infoType)
    isCalling = false

    if not result then return end

    ---@diagnostic disable-next-line: undefined-field
    cooldown = timer:new('menit', cooldownTime, function()
        cooldown = nil
    end)

    return result
end

local function openMenu()
    local moneyLabel = ox_items[config.price.money]?.label or config.price.money

    if ox_inventory:GetItemCount(config.price.money) < config.price.count then
        return lib.notify({
            title = 'Telepon umum',
            description = ('%s tidak cukup! Butuh $%s %s'):format(moneyLabel, config.price.count, moneyLabel),
            type = 'error'
        })
    end

    local priceText = ('$%s %s'):format(config.price.count, moneyLabel)

    lib.registerContext({
        id = 'phonebooth_menu',
        title = 'Informasi',
        options = {
            {
                title = 'Dapatkan Informasi Rumah Target',
                description = ('Dapatkan informasi lokasi rumah yang bisa dirampok (%s)'):format(priceText),
                icon = 'home',
                onSelect = function()
                    local house = requestInfo('house')
                    if not house then return end

                    houserobbery.createInfoLocation(house)
                end
            },
            {
                title = 'Dapatkan Informasi Gruppe',
                description = ('Informasi lokasi truck (%s)'):format(priceText),
                icon = 'truck',
                onSelect = function()
                    requestInfo('truck')
                end
            },
        }
    })

    lib.showContext('phonebooth_menu')
end

CreateThread(function()
    local moneyLabel = ox_items[config.price.money]?.label or config.price.money

    ox_target:addModel(config.model, {
        {
            name = "phonebooth_houseinfo",
            onSelect = openMenu,
            canInteract = function()
                return not isCalling
            end,
            icon = "fas fa-phone",
            label = ('Telepon Umum ($%s %s)'):format(config.price.count, moneyLabel),
            distance = 2.0,
        }
    })
end)