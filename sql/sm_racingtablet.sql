INSERT INTO racing_access (citizenid, auth)
SELECT citizenid, 'god' FROM players LIMIT 1
ON DUPLICATE KEY UPDATE auth = 'god';