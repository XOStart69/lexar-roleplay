cwCallback.register('sm_racingtablet:server:getHead2Head', function()
    return MySQL.query.await(
        'SELECT h.id, h.track, h.stake, h.state, c.racername AS challenger, o.racername AS opponent FROM racing_head2head h LEFT JOIN racing_racer_names c ON c.citizenid = h.challenger LEFT JOIN racing_racer_names o ON o.citizenid = h.opponent WHERE h.state < 2 ORDER BY h.id DESC LIMIT 25'
    ) or {}
end)