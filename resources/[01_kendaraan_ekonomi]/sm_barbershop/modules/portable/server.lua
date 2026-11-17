local config = Config
local items = config.items
local settings = config.portable
local inventory = exports.ox_inventory

local REACH_MARGIN = 1.5

local Portable = {}

---@type table<string, BarberPortableChair>
local chairs = {}

---@type table<integer, boolean>
local placed = {}

---@type table<number, boolean>
local placing = {}

---@type table<string, boolean>
local refunding = {}

local function notify(source, notifyType, description)
    TriggerClientEvent('ox_lib:notify', source, {
        type = notifyType,
        description = description,
        duration = 4500,
    })
end

---@param message string
---@return BarberActionResult
local function fail(message)
    return { success = false, message = message }
end

---@param shopId string
local function publish(shopId)
    ---@type BarberPortableSync[]
    local list = {}

    for _, chair in pairs(chairs) do
        if chair.shop == shopId then
            list[#list + 1] = { id = chair.id, coords = chair.coords, ownerId = chair.owner }
        end
    end

    Sync.setPortables(shopId, list)
end

---@param source number
---@param coords vector3
---@return boolean
local function within(source, coords)
    local ped = GetPlayerPed(source)

    return ped ~= 0 and #(GetEntityCoords(ped) - coords) <= settings.reach + REACH_MARGIN
end

---@param coords vector3
---@return boolean
local function crowded(coords)
    for i = 1, #config.shops do
        local list = config.shops[i].coords.chairs

        for j = 1, #list do
            if #(coords - list[j].xyz) < settings.spacing then return true end
        end
    end

    for _, chair in pairs(chairs) do
        if #(coords - chair.coords.xyz) < settings.spacing then return true end
    end

    return false
end

---@param source number
---@return integer
local function countOf(source)
    local total = 0

    for _, chair in pairs(chairs) do
        if chair.owner == source then
            total += 1
        end
    end

    return total
end

---@param chair BarberPortableChair
local function remove(chair)
    chairs[chair.id] = nil
    placed[chair.recordId] = nil
    publish(chair.shop)
    TriggerEvent('sm_barbershop:internal:chairRemoved', chair.shop, chair.id)
end

---@param source number
local function removeOwned(source)
    for _, chair in pairs(chairs) do
        if chair.owner == source then
            remove(chair)
        end
    end
end

---@param source number
local function refund(source)
    local citizenId = Staff.citizenId(source)

    if not citizenId or refunding[citizenId] then return end

    refunding[citizenId] = true

    local rows = Storage.portablesOf(citizenId)
    local returned, pending = 0, 0

    for i = 1, #rows do
        local row = rows[i]

        if not placed[row.id] then
            local metadata = row.used and Wear.metadata(items.chair, row.used) or nil

            if inventory:CanCarryItem(source, items.chair, 1, metadata) and inventory:AddItem(source, items.chair, 1, metadata) then
                Storage.removePortable(row.id)
                returned += 1
            else
                pending += 1
            end
        end
    end

    refunding[citizenId] = nil

    if returned > 0 then
        notify(source, 'success', ('%d kursi cukur dikembalikan ke inventory.'):format(returned))
    end

    if pending > 0 then
        notify(source, 'warning', 'Inventory penuh, kursi cukur akan dikembalikan saat login berikutnya.')
    end
end

---@param shopId string
---@param id any
---@return vector4?
function Portable.chair(shopId, id)
    local chair = type(id) == 'string' and chairs[id]

    return chair and chair.shop == shopId and chair.coords or nil
end

---@param shopId string
---@param index any
---@return boolean
function Portable.usable(shopId, index)
    local chair = type(index) == 'string' and chairs[index]

    if not chair or chair.shop ~= shopId then return type(index) ~= 'string' end

    return chair.used > 0
end

---@param shopId string
---@param index any
---@return integer? left
function Portable.consume(shopId, index)
    local chair = type(index) == 'string' and chairs[index]

    if not chair or chair.shop ~= shopId then return end

    chair.used = math.max(0, chair.used - 1)
    Storage.setPortableUsed(chair.recordId, chair.used)

    return chair.used
end

lib.callback.register('sm_barbershop:portable:place', function(source, slot, coords, heading)
    if placing[source] then return fail('Tunggu sebentar.') end

    if type(slot) ~= 'number' or type(coords) ~= 'vector3' or type(heading) ~= 'number' then
        return fail('Data penempatan tidak valid.')
    end

    heading = heading % 360.0

    if heading ~= heading or not within(source, coords) then
        return fail('Lokasi terlalu jauh.')
    end

    local shop = Shops.get(Staff.duty[source])

    if not shop then return fail('Anda harus sedang shift untuk memasang kursi cukur.') end
    if not Staff.can(source, shop.id, 'portable') then return fail('Role Anda tidak punya izin memasang kursi cukur.') end

    local citizenId = Staff.citizenId(source)

    if not citizenId then return fail('Data pemain tidak ditemukan.') end
    if countOf(source) >= settings.limit then return fail('Anda sudah memasang kursi cukur.') end
    if crowded(coords) then return fail('Terlalu dekat dengan kursi lain.') end

    local item = inventory:GetSlot(source, slot)

    if not item or item.name ~= items.chair then return fail('Kursi cukur tidak ada di inventory.') end

    local used = Wear.remaining(item.metadata)

    if used <= 0 then return fail('Kursi cukur ini sudah tidak bisa dipakai.') end
    if not inventory:RemoveItem(source, items.chair, 1, nil, slot) then return fail('Kursi cukur tidak ada di inventory.') end

    placing[source] = true

    local recordId = Storage.addPortable(citizenId, shop.id, used)

    placing[source] = nil

    if not recordId then
        inventory:AddItem(source, items.chair, 1, Wear.metadata(items.chair, used, item.metadata))

        return fail('Kursi cukur gagal dicatat.')
    end

    if not DoesPlayerExist(tostring(source)) then return fail('Pemain sudah keluar.') end

    local id = ('p%d'):format(recordId)

    chairs[id] = {
        id = id,
        shop = shop.id,
        coords = vec4(coords.x, coords.y, coords.z, heading),
        owner = source,
        citizenId = citizenId,
        recordId = recordId,
        used = used,
    }

    placed[recordId] = true
    publish(shop.id)

    return { success = true }
end)

lib.callback.register('sm_barbershop:portable:pickup', function(source, id)
    local chair = type(id) == 'string' and chairs[id]

    if not chair then return fail('Kursi cukur tidak ditemukan.') end

    local citizenId = Staff.citizenId(source)

    if not citizenId or (citizenId ~= chair.citizenId and not Staff.roleOf(source, chair.shop)) then
        return fail('Anda tidak berhak mengangkat kursi ini.')
    end

    if not within(source, chair.coords.xyz) then return fail('Anda terlalu jauh dari kursi.') end
    if Sync.chairStatus(chair.shop, chair.id) then return fail('Kursi sedang dipakai.') end

    local metadata = Wear.metadata(items.chair, chair.used)

    if not inventory:CanCarryItem(source, items.chair, 1, metadata) or not inventory:AddItem(source, items.chair, 1, metadata) then
        return fail('Inventory penuh.')
    end

    remove(chair)
    Storage.removePortable(chair.recordId)

    return { success = true }
end)

AddEventHandler('sm_barbershop:internal:sessionEnded', function(shopId, index)
    local chair = type(index) == 'string' and chairs[index]

    if not chair or chair.shop ~= shopId or chair.used > 0 then return end

    chairs[chair.id] = nil
    placed[chair.recordId] = nil
    publish(chair.shop)
    Storage.removePortable(chair.recordId)

    if DoesPlayerExist(tostring(chair.owner)) then
        notify(chair.owner, 'warning', 'Kursi cukur Anda sudah habis pakai dan dibereskan.')
    end
end)

AddEventHandler('sm_barbershop:internal:ready', function()
    for _, player in pairs(Core:GetQBPlayers()) do
        CreateThread(function()
            refund(player.PlayerData.source)
        end)
    end
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    refund(player.PlayerData.source)
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    removeOwned(source)
end)

AddEventHandler('playerDropped', function()
    local source = source

    placing[source] = nil
    removeOwned(source)
end)

return Portable
