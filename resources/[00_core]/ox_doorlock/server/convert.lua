-- Migrasi tabel lama `doors` (format qb-doorlock) ke `ox_doorlock`.
CreateThread(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS ox_doorlock (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(64) NOT NULL,
        data LONGTEXT NOT NULL,
        state TINYINT NOT NULL DEFAULT 1
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])

    local legacy = MySQL.query.await([[SELECT 1 FROM information_schema.tables
        WHERE table_schema = DATABASE() AND table_name = 'doors']])

    if not legacy or not legacy[1] then return end

    local existing = MySQL.query.await('SELECT COUNT(*) AS c FROM ox_doorlock')

    if existing and existing[1] and existing[1].c > 0 then return end

    local rows = MySQL.query.await('SELECT * FROM doors')

    if not rows then return end

    for i = 1, #rows do
        local row = rows[i]
        local data = {
            model = row.model,
            coords = { x = row.coords_x or 0.0, y = row.coords_y or 0.0, z = row.coords_z or 0.0 },
            heading = row.heading or 0.0,
            maxDistance = row.max_distance or 1.5,
            auto = row.automatic == 1,
            holdOpen = row.hold_open == 1,
            items = row.items and json.decode(row.items) or nil,
            groups = row.job and { [row.job] = 0 } or nil,
            passcode = row.passcode,
            lockpick = row.lockpick == 1,
        }

        MySQL.insert.await('INSERT INTO ox_doorlock (name, data, state) VALUES (?, ?, ?)', {
            row.name or ('door_' .. row.id),
            json.encode(data),
            row.state or 1,
        })
    end

    print(('^3ox_doorlock: %d door lama dimigrasi^0'):format(#rows))
end)
