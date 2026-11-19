local db = {}

---@param plate string
---@return table?
function db.get(plate)
    if type(plate) ~= 'string' then return end

    return MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ?', { plate })
end

---@param plate string
---@return string?
function db.ownerOf(plate)
    local row = db.get(plate)

    return row and row.citizenid or nil
end

---@param plate string
---@return boolean
function db.exists(plate)
    return db.get(plate) ~= nil
end

---@param plate string
---@param state number
function db.setState(plate, state)
    MySQL.update.await('UPDATE player_vehicles SET state = ? WHERE plate = ?', { state, plate })
end

---@param citizenid string
---@return table
function db.byOwner(citizenid)
    return MySQL.query.await('SELECT plate, vehicle, state FROM player_vehicles WHERE citizenid = ?', { citizenid }) or {}
end

return db