local function getPlaylists()
    local rows = AwaitCallback("music:getPlaylists")
    local playlists = {}
    local seen = {}
    for i = 1, #rows do
        local row = rows[i]
        if not seen[row.id] then
            seen[row.id] = true
            playlists[#playlists + 1] = {
                Id = row.id,
                Title = row.name,
                Cover = row.cover,
                IsOwner = row.phone_number == currentPhone,
                Songs = {}
            }
        end
        if row.song_id then
            local songs = playlists[#playlists].Songs
            songs[#songs + 1] = row.song_id
        end
    end
    return playlists
end

RegisterNUICallback("Music", function(data, cb)
    local action = data.action
    debugprint("Music:" .. (action or ""))

    if action == "getConfig" then
        cb(Music)
    end

    if action == "createPlaylist" then
        TriggerCallback("music:createPlaylist", cb, data.name)
    elseif action == "editPlaylist" then
        TriggerCallback("music:editPlaylist", cb, data.id, data.title, data.cover)
    elseif action == "getPlaylists" then
        cb(getPlaylists())
    elseif action == "deletePlaylist" then
        TriggerCallback("music:deletePlaylist", cb, data.id)
    elseif action == "savePlaylist" then
        TriggerCallback("music:savePlaylist", cb, data.id)
    elseif action == "addSong" then
        TriggerCallback("music:addSong", cb, data.id, data.song)
    elseif action == "removeSong" then
        TriggerCallback("music:removeSong", cb, data.id, data.song)
    end
end)
