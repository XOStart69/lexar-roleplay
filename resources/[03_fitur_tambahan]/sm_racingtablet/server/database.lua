local function run(sql)
    return MySQL.query.await(sql)
end

CreateThread(function()
    run([=[
        CREATE TABLE IF NOT EXISTS `racing_racers` (
            `citizenid` varchar(50) NOT NULL,
            `name` varchar(64) DEFAULT NULL,
            `elo` int DEFAULT 1000,
            `wins` int DEFAULT 0,
            `losses` int DEFAULT 0,
            `races` int DEFAULT 0,
            `best_elo` int DEFAULT 1000,
            `created` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`),
            KEY `elo` (`elo`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]=])

    run([=[
        CREATE TABLE IF NOT EXISTS `racing_races` (
            `id` int NOT NULL AUTO_INCREMENT,
            `host` varchar(50) DEFAULT NULL,
            `track` varchar(64) DEFAULT NULL,
            `class` varchar(32) DEFAULT NULL,
            `laps` int DEFAULT 1,
            `ranked` tinyint DEFAULT 0,
            `started` tinyint DEFAULT 0,
            `finished` tinyint DEFAULT 0,
            `created` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]=])

    run([=[
        CREATE TABLE IF NOT EXISTS `racing_records` (
            `id` int NOT NULL AUTO_INCREMENT,
            `track` varchar(64) NOT NULL,
            `class` varchar(32) NOT NULL,
            `time` int NOT NULL,
            `citizenid` varchar(50) DEFAULT NULL,
            `name` varchar(64) DEFAULT NULL,
            `created` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `track_class` (`track`, `class`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]=])

    run([=[
        CREATE TABLE IF NOT EXISTS `racing_crews` (
            `id` int NOT NULL AUTO_INCREMENT,
            `name` varchar(48) NOT NULL,
            `tag` varchar(8) DEFAULT NULL,
            `owner` varchar(50) DEFAULT NULL,
            `points` int DEFAULT 0,
            `created` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `name` (`name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]=])

    run([=[
        CREATE TABLE IF NOT EXISTS `racing_crew_members` (
            `citizenid` varchar(50) NOT NULL,
            `crew` int NOT NULL,
            `joined` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`),
            KEY `crew` (`crew`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]=])

    run([=[
        CREATE TABLE IF NOT EXISTS `racing_bounties` (
            `id` int NOT NULL AUTO_INCREMENT,
            `target` varchar(50) NOT NULL,
            `amount` int DEFAULT 0,
            `placed` varchar(50) DEFAULT NULL,
            `claimed` tinyint DEFAULT 0,
            `created` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `target` (`target`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]=])

    run([=[
        CREATE TABLE IF NOT EXISTS `racing_head2head` (
            `id` int NOT NULL AUTO_INCREMENT,
            `challenger` varchar(50) NOT NULL,
            `opponent` varchar(50) NOT NULL,
            `track` varchar(64) DEFAULT NULL,
            `stake` int DEFAULT 0,
            `state` tinyint DEFAULT 0,
            `created` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `state` (`state`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]=])

    run([=[
        CREATE TABLE IF NOT EXISTS `racing_crypto` (
            `citizenid` varchar(50) NOT NULL,
            `amount` int DEFAULT 0,
            `updated` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]=])

    run([=[
        CREATE TABLE IF NOT EXISTS `racing_racer_names` (
            `id` int NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) NOT NULL,
            `racername` varchar(48) NOT NULL,
            `ranking` int DEFAULT 1000,
            `auth` varchar(24) DEFAULT 'racer',
            `crypto` int DEFAULT 0,
            `created` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `citizenid` (`citizenid`),
            KEY `racername` (`racername`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]=])

    run([=[
        CREATE TABLE IF NOT EXISTS `racing_tracks` (
            `id` int NOT NULL AUTO_INCREMENT,
            `owner` varchar(50) DEFAULT NULL,
            `name` varchar(64) NOT NULL,
            `curated` tinyint DEFAULT 0,
            `checkpoints` longtext DEFAULT NULL,
            `meta` longtext DEFAULT NULL,
            `created` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `owner` (`owner`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]=])

    run([=[
        CREATE TABLE IF NOT EXISTS `racing_results` (
            `id` int NOT NULL AUTO_INCREMENT,
            `race` int NOT NULL,
            `track` varchar(64) DEFAULT NULL,
            `citizenid` varchar(50) DEFAULT NULL,
            `racername` varchar(48) DEFAULT NULL,
            `position` int DEFAULT 0,
            `time` int DEFAULT 0,
            `created` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `race` (`race`),
            KEY `track` (`track`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]=])

    run([=[
        CREATE TABLE IF NOT EXISTS `racing_crew_invites` (
            `id` int NOT NULL AUTO_INCREMENT,
            `crew` int NOT NULL,
            `citizenid` varchar(50) NOT NULL,
            `invited` varchar(50) DEFAULT NULL,
            `created` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]=])

    run([=[
        CREATE TABLE IF NOT EXISTS `racing_access` (
            `citizenid` varchar(50) NOT NULL,
            `auth` varchar(24) DEFAULT 'racer',
            `hosting` tinyint DEFAULT 0,
            `autohost` tinyint DEFAULT 0,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]=])

    DebugInfo('skema database siap')
end)

---@param citizenid string
---@param name string
function ensureRacer(citizenid, name)
    MySQL.update.await('INSERT IGNORE INTO racing_racers (citizenid, name) VALUES (?, ?)', { citizenid, name })
    MySQL.update.await('UPDATE racing_racers SET name = ? WHERE citizenid = ?', { name, citizenid })
end

---@param citizenid string
---@return table?
function getRacer(citizenid)
    return MySQL.single.await('SELECT * FROM racing_racers WHERE citizenid = ?', { citizenid })
end

---@param limit? number
---@return table
function getLeaderboard(limit)
    return MySQL.query.await('SELECT name, elo, wins, losses, races FROM racing_racers ORDER BY elo DESC LIMIT ?', { limit or 25 }) or {}
end