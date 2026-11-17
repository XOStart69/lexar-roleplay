local Config = SmPets.Config
local vet = Config.Vet

local DoesEntityExist = DoesEntityExist
local SetEntityCoords = SetEntityCoords
local SetEntityHeading = SetEntityHeading
local FreezeEntityPosition = FreezeEntityPosition
local DetachEntity = DetachEntity
local ClearPedTasks = ClearPedTasks
local sformat = string.format
local mrad = math.rad
local msin = math.sin
local mcos = math.cos

local tablePoints = {}

---@return boolean
local function isVet()
    local job = QBPlayerData.job
    if not job then return false end
    if vet.jobs[job.name] then return true end
    local level = job.grade and job.grade.level or 0
    local shops = GlobalState.smPetShops
    if not shops then return false end
    for i = 1, #shops do
        local shop = shops[i]
        if shop.job == job.name and level >= shop.vetGrade then return true end
    end
    return false
end

---@param anim table
---@param label string
---@return boolean
local function treatProgress(anim, label)
    return lib.progressBar({
        duration = anim.duration,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = anim.dict, clip = anim.clip, flag = 1 },
    })
end

---@param point table
---@return vector3 spot
---@return number heading
local function tableSpot(point)
    local heading = point.w or 0.0
    local rad = mrad(heading)
    local forward = vet.tableForward
    return vec3(point.x - msin(rad) * forward, point.y + mcos(rad) * forward, point.z + vet.tableHeight), heading + 90.0
end

---@param shopId integer
---@param index integer
---@param point table
local function placePet(shopId, index, point)
    local pet = SmPets.pet
    if not pet then return SmPets.notify('Kamu tidak sedang membawa pet.', 'error') end
    local result = lib.callback.await('sm_pets:vet:placeOnTable', false, shopId, index)
    if not result or not result.ok then return SmPets.notify(result and result.msg or 'Meja tidak bisa dipakai.', 'error') end

    if pet.cancel then
        local cancel = pet.cancel
        pet.cancel = nil
        cancel(true)
    end
    local ped = pet.ped
    DetachEntity(ped, true, true)
    ClearPedTasks(ped)
    local spot, heading = tableSpot(point)
    SetEntityCoords(ped, spot.x, spot.y, spot.z, false, false, false, false)
    SetEntityHeading(ped, heading)
    FreezeEntityPosition(ped, true)
    if pet.state ~= 'dead' then SmPets.playAnim(ped, pet.anims.sleep, 1) end
    SmPets.setAction(pet.state == 'dead' and 'dead' or 'table', function()
        lib.callback('sm_pets:vet:removeFromTable', false, function() end)
        local p = SmPets.pet
        if p and DoesEntityExist(p.ped) then
            FreezeEntityPosition(p.ped, false)
            SetEntityCoords(p.ped, point.x, point.y, point.z, false, false, false, false)
        end
    end)
end

---@param key string
---@return boolean
local function petOnThisTable(key)
    local pet = SmPets.pet
    return pet ~= nil and pet.tableKey == key
end

local function clearTables()
    local ready = SmPets.interactReady()
    for i = 1, #tablePoints do
        if ready then exports.rhd_interact:removeCoords(tablePoints[i]) end
        tablePoints[i] = nil
    end
end

---@param shops table[]|nil
local function buildTables(shops)
    clearTables()
    if not shops or not SmPets.interactReady() then return end
    for i = 1, #shops do
        local shop = shops[i]
        local tables = shop.points.tables or {}
        for index = 1, #tables do
            local point = tables[index]
            local key = sformat('%d:%d', shop.id, index)
            local id = 'sm_pets:table:' .. key
            local spot = tableSpot(point)
            exports.rhd_interact:addCoords({
                id = id,
                coords = spot,
                options = {
                    {
                        name = 'sm_pets:table:place',
                        label = 'Taruh Pet di Meja',
                        icon = 'fas fa-paw',
                        distance = vet.tableDistance,
                        canInteract = function()
                            local occupied = GlobalState.smPetTables
                            return SmPets.pet ~= nil and not (occupied and occupied[key])
                        end,
                        onSelect = function()
                            placePet(shop.id, index, point)
                            if SmPets.pet then SmPets.pet.tableKey = key end
                        end,
                    },
                    {
                        name = 'sm_pets:table:take',
                        label = 'Ambil Pet dari Meja',
                        icon = 'fas fa-hand',
                        distance = vet.tableDistance,
                        canInteract = function() return petOnThisTable(key) end,
                        onSelect = function()
                            SmPets.pet.tableKey = nil
                            SmPets.cancelAction()
                        end,
                    },
                    {
                        name = 'sm_pets:table:treat',
                        label = 'Rawat Pet',
                        icon = 'fas fa-stethoscope',
                        distance = vet.tableDistance,
                        canInteract = function()
                            local occupied = GlobalState.smPetTables
                            return occupied ~= nil and occupied[key] ~= nil and isVet()
                        end,
                        onSelect = function()
                            if not treatProgress(vet.tableAnim, 'Merawat pet...') then return end
                            local result = lib.callback.await('sm_pets:vet:treat', false, shop.id, index)
                            if result and result.msg then SmPets.notify(result.msg, result.ok and 'success' or 'error') end
                        end,
                    },
                },
            })
            tablePoints[#tablePoints + 1] = id
        end
    end
end

AddEventHandler('sm_pets:client:shopsUpdated', buildTables)

SmPets.onInteractReady(function()
    buildTables(GlobalState.smPetShops)
end)

AddEventHandler('sm_pets:client:removed', function(pet)
    pet.tableKey = nil
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end
    clearTables()
end)
