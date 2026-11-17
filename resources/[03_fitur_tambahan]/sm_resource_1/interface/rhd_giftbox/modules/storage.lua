local Storage = {}

local config = localmodule 'config'
local tableName = config.Drop.tableName

local function safeCall(fn)
    local ok, result = pcall(fn)
    if not ok then
        print(('[rhd_giftbox] oxmysql error: %s'):format(result))
        return nil
    end

    return result
end

function Storage.init()
    if not config.PrepareDB then return end
    return safeCall(function()
        return db:query_async(([[
            CREATE TABLE IF NOT EXISTS `%s` (
                `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
                `item_name` VARCHAR(64) NOT NULL,
                `metadata` LONGTEXT NOT NULL,
                `coords` LONGTEXT NOT NULL,
                `heading` FLOAT NOT NULL DEFAULT 0,
                `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]):format(tableName), {})
    end)
end

function Storage.getAllDrops()
    return safeCall(function()
        return db:query_async(('SELECT id, item_name, metadata, coords, heading FROM `%s`'):format(tableName), {})
    end) or {}
end

function Storage.createDrop(itemName, metadata, coords, heading)
    return safeCall(function()
        return db:insert_async(
            ('INSERT INTO `%s` (item_name, metadata, coords, heading) VALUES (?, ?, ?, ?)'):format(tableName),
            { itemName, json.encode(metadata or {}), json.encode(coords), heading or 0.0 }
        )
    end)
end

function Storage.deleteDrop(id)
    return safeCall(function()
        return db:update_async(('DELETE FROM `%s` WHERE id = ?'):format(tableName), { id })
    end)
end

return Storage
