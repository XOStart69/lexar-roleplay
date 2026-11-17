local db = exports.oxmysql
local config = require "config.general"

local SCHEMA = {
    [[
    CREATE TABLE IF NOT EXISTS `player_outfits` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `citizenid` varchar(50) DEFAULT NULL,
        `outfitname` varchar(50) NOT NULL DEFAULT '0',
        `model` varchar(50) DEFAULT NULL,
        `props` varchar(1000) DEFAULT NULL,
        `components` varchar(1500) DEFAULT NULL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `citizenid_outfitname_model` (`citizenid`,`outfitname`,`model`),
        KEY `citizenid` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
    [[
    CREATE TABLE IF NOT EXISTS `player_outfit_codes` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `outfitid` int(11) NOT NULL,
        `code` varchar(50) NOT NULL DEFAULT '',
        PRIMARY KEY (`id`),
        KEY `outfitid` (`outfitid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]
}

local outfits = {}

if config.autoCreateTables then
    CreateThread(function()
        for i = 1, #SCHEMA do
            db:query_async(SCHEMA[i])
        end
    end)
end

---@param identifier string
---@return Outfit[]
function outfits.all(identifier)
    local rows = db:query_async("SELECT * FROM player_outfits WHERE citizenid = ?", { identifier }) or {}
    local list = table.create(#rows, 0)

    for i = 1, #rows do
        local row = rows[i]

        list[i] = {
            id = row.id,
            name = row.outfitname,
            model = row.model,
            components = json.decode(row.components),
            props = json.decode(row.props)
        }
    end

    return list
end

---@param id number
---@return table?
function outfits.byId(id)
    return db:single_async("SELECT * FROM player_outfits WHERE id = ?", { id })
end

---@param identifier string
---@param name string
---@return table?
function outfits.byName(identifier, name)
    return db:single_async("SELECT * FROM player_outfits WHERE outfitname = ? AND citizenid = ?", {
        name, identifier
    })
end

---@param identifier string
---@param name string
---@param model string
---@param components PedComponent[]
---@param props PedProp[]
---@return number? id
function outfits.add(identifier, name, model, components, props)
    return db:insert_async(
        "INSERT INTO player_outfits (citizenid, outfitname, model, components, props) VALUES (?, ?, ?, ?, ?)", {
            identifier, name, model, json.encode(components), json.encode(props)
        })
end

---@param id number
---@param model string
---@param components PedComponent[]
---@param props PedProp[]
function outfits.update(id, model, components, props)
    db:update_async("UPDATE player_outfits SET model = ?, components = ?, props = ? WHERE id = ?", {
        model, json.encode(components), json.encode(props), id
    })
end

---@param id number
function outfits.delete(id)
    db:transaction_async({
        { query = "DELETE FROM player_outfit_codes WHERE outfitid = ?", values = { id } },
        { query = "DELETE FROM player_outfits WHERE id = ?", values = { id } }
    })
end

---@param code string
---@return table?
function outfits.byCode(code)
    return db:single_async("SELECT * FROM player_outfit_codes WHERE code = ?", { code })
end

---@param id number
---@return table?
function outfits.codeOf(id)
    return db:single_async("SELECT * FROM player_outfit_codes WHERE outfitid = ?", { id })
end

---@param id number
---@param code string
---@return number?
function outfits.addCode(id, code)
    return db:insert_async("INSERT INTO player_outfit_codes (outfitid, code) VALUES (?, ?)", { id, code })
end

return outfits
