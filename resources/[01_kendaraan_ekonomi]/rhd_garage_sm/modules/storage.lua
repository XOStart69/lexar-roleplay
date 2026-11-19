local storage = {}

local query = {
    fetchPlayerVehicles = {
        shared = {
            query = [[
                SELECT 
                    pv.vehicle, pv.hash, pv.plate, pv.state, pv.depotprice,
                    JSON_EXTRACT(pv.mods, '$.plateIndex') AS plateIndex,
                    CONCAT(
                        JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')),
                        ' ',
                        JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname'))
                    ) AS owner_name
                FROM player_vehicles pv
                JOIN players p ON pv.citizenid = p.citizenid
                WHERE pv.garage = ? AND pv.state = ?
            ]],
            values = function (data)
                return { data.garageId, 1 }
            end
        },
        default = {
            query = [[
                SELECT vehicle, hash, plate, state, depotprice, JSON_EXTRACT(mods, '$.plateIndex') AS plateIndex FROM player_vehicles
                WHERE citizenid = ? AND garage = ? AND state = ?
            ]],
            values = function (data)
                return { data.citizenid, data.garageId, 1 }
            end
        },
        depot = {
            query = [[
                SELECT 
                    pv.vehicle, pv.hash, pv.plate, pv.state, pv.depotprice, JSON_EXTRACT(pv.mods, '$.plateIndex') AS plateIndex, (
                        SELECT 1 FROM sm_impound rp WHERE pv.citizenid = rp.citizenid AND pv.plate = rp.plate AND rp.released = 0) AS impounded
                FROM player_vehicles pv
                WHERE pv.citizenid = ? AND (pv.state = 0 OR pv.state = 2)
            ]],
            values = function (data)
                return { data.citizenid }
            end
        }
    },
}

Citizen.CreateThreadNow(function ()
    db:execute([[
        UPDATE player_vehicles pv
        SET pv.state = 0
        WHERE pv.state = 2 AND NOT EXISTS (
            SELECT 1 FROM sm_impound rp
            WHERE pv.citizenid = rp.citizenid AND pv.plate = rp.plate AND rp.released = 0
        )
    ]])
end)

---@param citizenid string
---@param plate string
---@param garageId GarageId
---@param request table
---@return table|nil
function storage.getVehicleData(citizenid, plate, garageId, request)
    local garage_data = glocations.registered[garageId] ---@type GarageData
    if not garage_data then return nil end

    if not request or #request == 0 then return nil end

    local select_clause = table.concat(request, ', ')
    local q, values

    if garage_data.category == 'shared' then
        q = string.format('SELECT %s FROM player_vehicles WHERE plate = ?', select_clause)
        values = { plate }
    else
        q = string.format('SELECT %s FROM player_vehicles WHERE citizenid = ? AND plate = ?', select_clause)
        values = { citizenid, plate }
    end

    local results = db:query_async(q, values)
    if not results or #results == 0 then return nil end

    local data = results[1]
    if data.mods then
        data.mods = json.decode(data.mods)

        if type(data.mods.model) == 'string' then
            data.mods.model = joaat(data.mods.model)
        end

    end

    return data
end

---@param citizenid string
---@param plate string
---@param garageId GarageId
---@param newData table
---@return boolean Success
function storage.setVehicleData(citizenid, plate, garageId, newData)
    local garage_data = glocations.registered[garageId] ---@type GarageData
    if not garage_data then return false end

    if not newData or next(newData) == nil then return false end

    local set_parts = {}
    local values = {}

    for k, v in pairs(newData) do
        set_parts[#set_parts + 1] = k .. ' = ?'
        if k == 'mods' and type(v) == 'table' then
            values[#values + 1] = json.encode(v)
        else
            values[#values + 1] = v
        end
    end

    local q
    if garage_data.category == 'shared' then
        q = string.format('UPDATE player_vehicles SET %s WHERE plate = ?', table.concat(set_parts, ', '))
        values[#values + 1] = plate
    else
        q = string.format('UPDATE player_vehicles SET %s WHERE citizenid = ? AND plate = ?', table.concat(set_parts, ', '))
        values[#values + 1] = citizenid
        values[#values + 1] = plate
    end

    return db:update_async(q, values) > 0
end

---@param hash number|string|nil
---@return integer|nil
local function normalizeHash(hash)
    if type(hash) == 'string' and not tonumber(hash) then
        hash = joaat(hash)
    end
    hash = tonumber(hash)
    hash = hash and math.tointeger(hash)
    if not hash or hash == 0 then return nil end
    return hash & 0xFFFFFFFF
end

---@param row {vehicle?: string, hash?: number|string}
---@return integer|nil
function storage.rowModel(row)
    local name = row.vehicle
    if type(name) == 'string' and name ~= '' then
        return normalizeHash(name)
    end
    return normalizeHash(row.hash)
end

---@param a number|string|nil
---@param b number|string|nil
---@return boolean
function storage.sameModel(a, b)
    local na = normalizeHash(a)
    return na ~= nil and na == normalizeHash(b)
end

---@param citizenid string
---@param vehicle {model: string|number, plate: string}
---@param garageId GarageId
---@return boolean isOwner
function storage.checkVehicleOwner(citizenid, vehicle, garageId)
    local garage_data = glocations.registered[garageId] ---@type GarageData
    if not garage_data then return false end

    local vehicleData = storage.getVehicleData(citizenid, vehicle.plate, garageId, { 'mods', 'vehicle', 'hash' })
    if not vehicleData then return false end

    local rowModel = storage.rowModel(vehicleData)
    if rowModel then
        return storage.sameModel(rowModel, vehicle.model)
    end

    return storage.sameModel(vehicleData.mods?.model, vehicle.model)
end

---@param plate string
---@return string|nil citizenid
function storage.getVehicleOwnerByPlate(plate)
    local results = db:query_async('SELECT citizenid FROM player_vehicles WHERE plate = ?', { plate })
    if not results or #results == 0 then return nil end

    if #results > 1 then
        lib.print.warn(('Plate %s dimiliki %d kendaraan, pemilik tidak dapat ditentukan'):format(plate, #results))
        return nil
    end

    return results[1].citizenid
end

---@param citizenid string
---@param garageId GarageId
---@return table PlayerVehicles[]
function storage.fetchGarageVehicles(citizenid, garageId)
    local garage_data = glocations.registered[garageId] ---@type GarageData
    if not garage_data then return {} end

    local q = query.fetchPlayerVehicles[garage_data.category]
    local results = db:query_async(q.query, q.values({ citizenid = citizenid, garageId = garageId }))

    local vehicles = {}
    local isDepot = garage_data.category == 'depot'
    local isShared = garage_data.category == 'shared'
    local isDefault = garage_data.category == 'default'

    for i=1, #results do
        local v = results[i]
        local outside = utils.findPlateOnServer(v.plate)
        local vehdata = qb_vehicles.hash(v.hash) or qb_vehicles(v.vehicle)
        local vehmodel = vehdata?.model or (v.vehicle or v.hash)

        local metadata = {
            plateIndex = v.plateIndex,
        }

        if isDepot then
            metadata.depotPrice = utils.calculateDepotPrice(
                vehmodel,
                v.depotprice
            )
            metadata.outside = outside
            metadata.impounded = v.state == 2 and v.impounded
        elseif isShared then
            metadata.owner_name = v.owner_name
        end

        local vehicle = {
            name = vehdata?.name or 'Unknown',
            model = vehmodel,
            plate = v.plate,
            metadata = metadata
        }

        if (isDefault or isShared) and outside then
            goto continue
        end

        vehicles[#vehicles+1] = vehicle

        ::continue::
    end

    return vehicles
end

return storage
