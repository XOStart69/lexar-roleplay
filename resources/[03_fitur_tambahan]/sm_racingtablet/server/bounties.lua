cwCallback.register('sm_racingtablet:server:getBounties', function()
    return MySQL.query.await(
        'SELECT b.id, b.amount, b.created, t.racername AS target, p.racername AS placed FROM racing_bounties b LEFT JOIN racing_racer_names t ON t.citizenid = b.target LEFT JOIN racing_racer_names p ON p.citizenid = b.placed WHERE b.claimed = 0 ORDER BY b.amount DESC LIMIT 25'
    ) or {}
end)