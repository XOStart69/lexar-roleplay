local db = {}

local function query(q, params)
    return MySQL.query.await(q, params or {})
end

CreateThread(function()
    query([[CREATE TABLE IF NOT EXISTS sm_pdtablet_tracks (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(32) NOT NULL,
        track_type VARCHAR(8) NOT NULL DEFAULT 'ground',
        citizenid VARCHAR(50) NOT NULL,
        checkpoints LONGTEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_owner (citizenid)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])

    query([[CREATE TABLE IF NOT EXISTS sm_pdtablet_history (
        id INT AUTO_INCREMENT PRIMARY KEY,
        track_id INT NOT NULL,
        citizenid VARCHAR(50) NOT NULL,
        elapsed INT NOT NULL DEFAULT 0,
        lap INT NOT NULL DEFAULT 1,
        finished TINYINT(1) NOT NULL DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_track (track_id),
        INDEX idx_player (citizenid)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])

    query([[CREATE TABLE IF NOT EXISTS sm_pdtablet_profile (
        citizenid VARCHAR(50) PRIMARY KEY,
        division VARCHAR(16) NOT NULL DEFAULT 'stf'
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])
end)

function db.getDivision(citizenid)
    local rows = query('SELECT division FROM sm_pdtablet_profile WHERE citizenid = ?', { citizenid })

    return rows and rows[1] and rows[1].division or nil
end

function db.setDivision(citizenid, division)
    query([[INSERT INTO sm_pdtablet_profile (citizenid, division) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE division = VALUES(division)]], { citizenid, division })
end

function db.listTracks(citizenid)
    return query('SELECT id, name, track_type, citizenid, updated_at FROM sm_pdtablet_tracks WHERE citizenid = ? ORDER BY updated_at DESC', { citizenid })
end

function db.getTrack(id)
    local rows = query('SELECT id, name, track_type, citizenid, checkpoints FROM sm_pdtablet_tracks WHERE id = ?', { id })

    return rows and rows[1] or nil
end

function db.insertTrack(citizenid, name, trackType, checkpoints)
    return query('INSERT INTO sm_pdtablet_tracks (citizenid, name, track_type, checkpoints) VALUES (?, ?, ?, ?)', {
        citizenid,
        name,
        trackType,
        checkpoints,
    })
end

function db.updateTrack(id, name, checkpoints)
    query('UPDATE sm_pdtablet_tracks SET name = ?, checkpoints = ? WHERE id = ?', { name, checkpoints, id })
end

function db.deleteTrack(id)
    query('DELETE FROM sm_pdtablet_tracks WHERE id = ?', { id })
end

function db.countTracks(citizenid)
    local rows = query('SELECT COUNT(*) AS c FROM sm_pdtablet_tracks WHERE citizenid = ?', { citizenid })

    return rows and rows[1] and rows[1].c or 0
end

function db.addHistory(trackId, citizenid, elapsed, lap, finished)
    query('INSERT INTO sm_pdtablet_history (track_id, citizenid, elapsed, lap, finished) VALUES (?, ?, ?, ?, ?)', {
        trackId,
        citizenid,
        elapsed,
        lap,
        finished and 1 or 0,
    })
end

function db.getHistory(citizenid, limit)
    return query([[SELECT h.track_id, h.elapsed, h.lap, h.finished, h.created_at, t.name
        FROM sm_pdtablet_history h
        JOIN sm_pdtablet_tracks t ON t.id = h.track_id
        WHERE h.citizenid = ?
        ORDER BY h.id DESC LIMIT ?]], { citizenid, limit })
end

function db.getLeaderboard(trackId, limit)
    return query([[SELECT citizenid, elapsed, lap, created_at
        FROM sm_pdtablet_history
        WHERE track_id = ? AND finished = 1
        ORDER BY elapsed ASC LIMIT ?]], { trackId, limit })
end

return db
