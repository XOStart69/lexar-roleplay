local Config = localmodule 'config'

local shopPoint
local shopBlip

---@param entity number
local function addShopTarget(entity)
    if targetResource ~= 'ox_target' then return end

    exports.ox_target:addLocalEntity({ entity }, {
        {
            label = locale('Speaker shop'),
            icon = 'fa-solid fa-basket-shopping',
            name = 'sm-speaker-shop',
            distance = 2.0,
            onSelect = function()
                TriggerServerEvent('sm_audio:server:openSpeakerShop')
            end,
        },
    })
end

---@param entity number
local function removeShopTarget(entity)
    if targetResource ~= 'ox_target' or not entity then return end
    exports.ox_target:removeLocalEntity({ entity }, { 'sm-speaker-shop' })
end

RegisterNetEvent('sm_audio:client:createShop', function(shop)
    if shopPoint then return end

    local coords = vec3(shop.coords.x, shop.coords.y, shop.coords.z)

    shopPoint = lib.points.new(coords, 60.0, {
        model = shop.pedModel,
        heading = shop.coords.w,
    })

    function shopPoint:onEnter()
        if not lib.requestModel(self.model, Config.modelTimeout) then return end

        self.handle = CreatePed(0, self.model, self.coords.x, self.coords.y, self.coords.z, self.heading, false, true)

        SetModelAsNoLongerNeeded(self.model)
        FreezeEntityPosition(self.handle, true)
        SetEntityInvincible(self.handle, true)
        SetBlockingOfNonTemporaryEvents(self.handle, true)

        addShopTarget(self.handle)
    end

    function shopPoint:onExit()
        removeShopTarget(self.handle)

        if self.handle and DoesEntityExist(self.handle) then
            SetEntityAsMissionEntity(self.handle, false, true)
            DeleteEntity(self.handle)
        end

        self.handle = nil
    end

    if shop.blip and shop.blip.enabled then
        shopBlip = AddBlipForCoord(coords.x, coords.y, coords.z)

        SetBlipSprite(shopBlip, shop.blip.sprite)
        SetBlipColour(shopBlip, shop.blip.color)
        SetBlipScale(shopBlip, shop.blip.scale or 1.0)
        SetBlipAsShortRange(shopBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(shop.blip.text)
        EndTextCommandSetBlipName(shopBlip)
    end
end)

RegisterNetEvent('sm_audio:client:openSpeakerShop', function(speakerTypes, maxRange, maxVolume)
    local options = {}

    for i = 1, #speakerTypes do
        local speakerType = speakerTypes[i]
        local rangeProgress = math.floor((speakerType.maxRange / maxRange) * 100)
        local volumeProgress = math.floor((speakerType.maxVolume / maxVolume) * 100)

        options[i] = {
            title = ('%s ($%.2f)'):format(speakerType.label, speakerType.price),
            description = speakerType.description,
            icon = speakerType.image,
            image = speakerType.image,
            arrow = true,
            progress = rangeProgress,
            colorScheme = 'teal',
            metadata = {
                { label = locale('Range'), value = ('%s/%s'):format(speakerType.maxRange, maxRange), progress = rangeProgress },
                { label = locale('Max volume'), value = ('%s/%s'):format(speakerType.maxVolume, maxVolume), progress = volumeProgress },
            },
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = locale('Confirmation'),
                    content = locale('Are sure you want to purchase %s for $%.2f?', speakerType.label, speakerType.price),
                    centered = true,
                    cancel = true,
                })

                if confirm ~= 'confirm' then return end

                TriggerServerEvent('sm_audio:server:purchaseSpeaker', speakerType.id)
            end,
        }
    end

    lib.registerContext({
        id = 'speaker-shop',
        title = locale('Speaker shop'),
        options = options,
    })

    lib.showContext('speaker-shop')
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('sm_audio:server:requestShop')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    if shopBlip then
        RemoveBlip(shopBlip)
    end

    if shopPoint and shopPoint.handle and DoesEntityExist(shopPoint.handle) then
        removeShopTarget(shopPoint.handle)
        SetEntityAsMissionEntity(shopPoint.handle, false, true)
        DeleteEntity(shopPoint.handle)
    end
end)
