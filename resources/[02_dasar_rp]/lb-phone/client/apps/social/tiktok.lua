local function processVideo(video)
    if video.metadata then
        video.metadata = json.decode(video.metadata)
    end
    if video.music then
        video.music = json.decode(video.music)
        local song = Music.Songs[video.music and video.music.path]
        if song then
            local album = Music.Albums[song.album]
            if album and album.Cover then
                song.Cover = album.Cover
            end
            video.music = {
                title = song.Title,
                artist = song.Artist,
                cover = song.Cover,
                volume = video.music.volume,
                path = video.music.path
            }
        end
    end
    video.liked = 1 == video.liked
    video.saved = 1 == video.saved
    video.viewed = 1 == video.viewed
    return video
end

RegisterNUICallback("TikTok", function(data, cb)
    if not currentPhone then
        return
    end
    local action = data.action
    debugprint("Trendy:" .. (action or ""))
    if "login" == action then
        data = data.data
        TriggerCallback("tiktok:login", cb, data.username, data.password)
    elseif "signup" == action then
        data = data.data
        TriggerCallback("tiktok:signup", cb, data.username, data.password, data.name)
    elseif "changePassword" == action then
        TriggerCallback("tiktok:changePassword", cb, data.oldPassword, data.newPassword)
    elseif "deleteAccount" == action then
        TriggerCallback("tiktok:deleteAccount", cb, data.password)
    elseif "logout" == action then
        TriggerCallback("tiktok:logout", cb)
    elseif "isLoggedIn" == action then
        TriggerCallback("tiktok:isLoggedIn", cb)
    elseif "getProfile" == action then
        TriggerCallback("tiktok:getProfile", cb, data.username)
    elseif "updateProfile" == action then
        TriggerCallback("tiktok:updateProfile", cb, data.data)
    elseif "searchAccounts" == action then
        TriggerCallback("tiktok:searchAccounts", cb, data.query, data.page)
    elseif "toggleFollow" == action then
        data = data.data
        TriggerCallback("tiktok:toggleFollow", cb, data.username, data.follow)
    elseif "getFollowing" == action then
        TriggerCallback("tiktok:getFollowing", cb, data.username, data.page)
    elseif "getFollowers" == action then
        TriggerCallback("tiktok:getFollowers", cb, data.username, data.page)
    elseif "uploadVideo" == action then
        data = data.data
        if not (data.src and data.caption) then
            return cb({ success = false, error = "invalid_caption" })
        end
        if data.music then
            if not (data.music.path and data.music.volume) then
                return cb({ success = false, error = "invalid_music" })
            end
        end
        if data.music then
            data.music = json.encode(data.music)
        end
        if data.metadata then
            if type(data.metadata) == "table" then
                local isEmpty = true
                for _ in pairs(data.metadata) do
                    isEmpty = false
                    break
                end
                if isEmpty then
                    data.metadata = nil
                else
                    data.metadata = json.encode(data.metadata)
                end
            end
        else
            data.metadata = nil
        end
        TriggerCallback("tiktok:uploadVideo", cb, data)
    elseif "deleteVideo" == action then
        TriggerCallback("tiktok:deleteVideo", cb, data.id)
    elseif "togglePinnedVideo" == action then
        TriggerCallback("tiktok:togglePinnedVideo", cb, data.id, data.toggle)
    elseif "getVideos" == action then
        TriggerCallback("tiktok:getVideos", function(videos)
            for i = 1, #videos do
                videos[i] = processVideo(videos[i])
            end
            cb(videos)
        end, data.data, data.page or 0)
    elseif "getVideo" == action then
        TriggerCallback("tiktok:getVideo", function(result)
            if result.video then
                result.video = processVideo(result.video)
            end
            cb(result)
        end, data.id)
    elseif "setViewed" == action then
        TriggerServerEvent("phone:tiktok:setViewed", data.id)
        cb("ok")
    elseif "toggleLike" == action then
        TriggerCallback("tiktok:toggleVideoAction", cb, "like", data.id, data.toggle)
    elseif "toggleSave" == action then
        TriggerCallback("tiktok:toggleVideoAction", cb, "save", data.id, data.toggle)
    elseif "postComment" == action then
        data = data.data
        TriggerCallback("tiktok:postComment", cb, data.id, data.replyTo, data.comment)
    elseif "getComments" == action then
        TriggerCallback("tiktok:getComments", cb, data.data.id, data.data.replyTo, data.data.creator, data.page)
    elseif "deleteComment" == action then
        TriggerCallback("tiktok:deleteComment", cb, data.id, data.videoId)
    elseif "setPinnedComment" == action then
        TriggerCallback("tiktok:setPinnedComment", cb, data.commentId, data.videoId)
    elseif "toggleLikeComment" == action then
        TriggerCallback("tiktok:toggleLikeComment", cb, data.id, data.toggle)
    elseif "getRecentMessages" == action then
        TriggerCallback("tiktok:getRecentMessages", cb)
    elseif "getMessages" == action then
        TriggerCallback("tiktok:getMessages", cb, data.id, data.page)
    elseif "sendMessage" == action then
        if not CanInteract() then
            return cb(false)
        end
        TriggerCallback("tiktok:sendMessage", cb, data.data)
    elseif "getChannelId" == action then
        TriggerCallback("tiktok:getChannelId", cb, data.username)
    elseif "getNotifications" == action then
        TriggerCallback("tiktok:getNotifications", cb, data.page)
    elseif "getUnreadMessages" == action then
        TriggerCallback("tiktok:getUnreadMessages", cb)
    elseif "clearUnreadMessages" == action then
        TriggerServerEvent("phone:tiktok:clearUnreadMessages", data.id)
    end
end)

RegisterNetEvent("phone:tiktok:updateFollowers", function(username, method)
    SendNUIAction("tiktok:updateFollowers", {
        username = username,
        method = method
    })
end)

RegisterNetEvent("phone:tiktok:updateFollowing", function(username, method)
    SendNUIAction("tiktok:updateFollowing", {
        username = username,
        method = method
    })
end)

RegisterNetEvent("phone:tiktok:updateVideoStats", function(kind, id, method, count)
    local payload = {
        id = id,
        method = method,
        count = count
    }
    if "like" == kind then
        SendNUIAction("tiktok:updateLikes", payload)
    elseif "save" == kind then
        SendNUIAction("tiktok:updateSaves", payload)
    elseif "comment" == kind then
        SendNUIAction("tiktok:updateComments", payload)
    end
end)

RegisterNetEvent("phone:tiktok:updateCommentStats", function(kind, id, method)
    if "reply" == kind then
        SendNUIAction("tiktok:updateReplies", {
            id = id,
            method = method
        })
    elseif "like" == kind then
        SendNUIAction("tiktok:updateCommentLikes", {
            id = id,
            method = method
        })
    end
end)

RegisterNetEvent("phone:tiktok:receivedMessage", function(data)
    SendNUIAction("tiktok:receivedMessage", data)
end)

RegisterNetEvent("phone:tiktok:newVideo", function(data)
    TriggerEvent("lb-phone:trendy:newPost", data)
end)
