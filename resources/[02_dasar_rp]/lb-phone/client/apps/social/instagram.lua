local live = false
local watchingHost = nil
local interactionActions = {
    "sendLiveMessage",
    "logIn",
    "toggleFollow",
    "toggleLike",
    "postComment",
    "sendMessage"
}
watchingSources = {}

RegisterNUICallback("Instagram", function(data, cb)
    if not currentPhone then
        return
    end
    local action = data.action
    debugprint("InstaPic:" .. (action or ""))
    if table.contains(interactionActions, action) then
        if not CanInteract() then
            return cb(false)
        end
    end
    if action == "getLives" then
        TriggerCallback("instagram:getLives", cb)
    elseif action == "getLiveViewers" then
        TriggerCallback("instagram:getLiveViewers", cb, data.username)
    elseif action == "goLive" then
        local allowed = AwaitCallback("instagram:canGoLive")
        if not allowed then
            debugprint("not allowed to go live")
            cb(false)
            return
        end
        debugprint("allowed to go live; setting live stream on ui")
        cb(true)
    elseif action == "setLive" then
        debugprint("sending server event to start livestream")
        TriggerServerEvent("phone:instagram:startLive", data.id)
        live = true
        EnableWalkableCam()
    elseif action == "endLive" then
        EndLive()
        cb(true)
    elseif action == "viewLive" then
        local stream = AwaitCallback("instagram:viewLive", data.username)
        if not stream then
            return cb(false)
        end
        local volume = (settings and settings.sound and settings.sound.volume) or 0.5
        volume = volume / 1
        watchingHost = data.username
        watchingSources[#watchingSources + 1] = stream.host
        for i = 1, #stream.participants do
            watchingSources[#watchingSources + 1] = stream.participants[i].source
        end
        debugprint("InstaPic: adding voice targets. Volume:", volume)
        MumbleClearVoiceTargetPlayers(1)
        for i = 1, #watchingSources do
            local source = watchingSources[i]
            MumbleAddVoiceTargetPlayerByServerId(1, source)
            MumbleSetVolumeOverrideByServerId(source, volume)
            debugprint("started listening to", source)
        end
        cb(#stream.viewers)
    elseif action == "stopViewing" then
        AwaitCallback("instagram:stopViewing", data.username)
        MumbleClearVoiceTargetPlayers(1)
        for i = 1, #watchingSources do
            MumbleSetVolumeOverrideByServerId(watchingSources[i], -1.0)
            debugprint("stopped listening to", watchingSources[i])
        end
        watchingHost = nil
        watchingSources = {}
        cb("ok")
    elseif action == "sendLiveMessage" then
        TriggerServerEvent("phone:instagram:sendLiveMessage", data.data)
    elseif action == "addCall" then
        TriggerServerEvent("phone:instagram:addCall", data.id)
    elseif action == "inviteLive" then
        TriggerServerEvent("phone:instagram:inviteLive", data.username)
    elseif action == "removeLive" then
        TriggerServerEvent("phone:instagram:removeLive", data.username)
    elseif action == "joinLive" then
        local joined = AwaitCallback("instagram:joinLive", data.username, data.streamId)
        cb(joined)
        if not joined then
            return
        end
        live = true
        EnableWalkableCam()
    end

    if action == "addToStory" then
        local allowed = AwaitCallback("instagram:canCreateStory")
        if not allowed then
            debugprint("not allowed to go create story")
            cb(false)
            return
        end
        debugprint("allowed to create story")
        TriggerCallback("instagram:addToStory", cb, data.media, data.metadata)
    elseif action == "removeFromStory" then
        TriggerCallback("instagram:removeFromStory", cb, data.id)
    elseif action == "getStories" then
        TriggerCallback("instagram:getStories", cb)
    elseif action == "getStory" then
        TriggerCallback("instagram:getStory", cb, data.username)
    elseif action == "getViewers" then
        TriggerCallback("instagram:getViewers", cb, data.id, data.page)
    elseif action == "viewedStory" then
        TriggerCallback("instagram:viewedStory", cb, data.id)
    end

    if action == "flipCamera" then
        ToggleSelfieCam(not IsSelfieCam())
    elseif action == "createAccount" then
        TriggerCallback("instagram:createAccount", cb, data.name, data.username, data.password)
    elseif action == "changePassword" then
        TriggerCallback("instagram:changePassword", cb, data.oldPassword, data.newPassword)
    elseif action == "deleteAccount" then
        TriggerCallback("instagram:deleteAccount", cb, data.password)
    elseif action == "logIn" then
        TriggerCallback("instagram:logIn", cb, data.username, data.password)
    elseif action == "signOut" then
        TriggerCallback("instagram:signOut", cb)
    elseif action == "isLoggedIn" then
        TriggerCallback("instagram:isLoggedIn", cb)
    elseif action == "getProfile" then
        TriggerCallback("instagram:getProfile", cb, data.username)
    elseif action == "newPost" then
        TriggerCallback("instagram:createPost", cb, data.data.images, data.data.caption, data.data.location)
    elseif action == "deletePost" then
        TriggerCallback("instagram:deletePost", cb, data.id)
    elseif action == "getPosts" then
        TriggerCallback("instagram:getPosts", cb, data.filters, data.page)
    elseif action == "getPost" then
        TriggerCallback("instagram:getPost", cb, data.id)
    elseif action == "updateProfile" then
        TriggerCallback("instagram:updateProfile", cb, data.data)
    elseif action == "getFollowers" then
        TriggerCallback("instagram:getData", cb, "followers", data.data)
    elseif action == "getFollowing" then
        TriggerCallback("instagram:getData", cb, "following", data.data)
    elseif action == "getLikes" then
        TriggerCallback("instagram:getData", cb, "likes", data.data)
    elseif action == "toggleFollow" then
        TriggerCallback("instagram:toggleFollow", cb, data.data.username, data.data.following)
    elseif action == "toggleLike" then
        TriggerCallback("instagram:toggleLike", cb, data.data.postId, data.data.toggle, data.data.isComment)
    elseif action == "getComments" then
        local comments = AwaitCallback("instagram:getComments", data.postId, data.page or 0)
        local result = {}
        for i = 1, #comments do
            local entry = comments[i]
            result[i] = {
                user = {
                    username = entry.username,
                    avatar = entry.profile_image,
                    verified = entry.verified
                },
                comment = {
                    content = entry.comment,
                    timestamp = entry.timestamp,
                    likes = entry.like_count,
                    liked = entry.liked,
                    id = entry.id
                }
            }
        end
        cb(result)
    elseif action == "postComment" then
        TriggerCallback("instagram:postComment", cb, data.data.postId, data.data.comment)
    elseif action == "signOut" then
        TriggerCallback("instagram:signOut", cb)
    elseif action == "getNotifications" then
        TriggerCallback("instagram:getNotifications", cb, data.page or 0)
    elseif action == "getFollowRequests" then
        TriggerCallback("instagram:getFollowRequests", cb, data.page or 0)
    elseif action == "handleFollowRequest" then
        TriggerCallback("instagram:handleFollowRequest", cb, data.username, data.accept)
    end

    if action == "getRecentMessages" then
        local messages = AwaitCallback("instagram:getRecentMessages", data.page)
        for i = 1, #messages do
            if messages[i].attachments then
                messages[i].attachments = json.decode(messages[i].attachments)
            end
        end
        cb(messages)
    elseif action == "getMessages" then
        local messages = AwaitCallback("instagram:getMessages", data.username, data.page)
        for i = 1, #messages do
            if messages[i].attachments then
                messages[i].attachments = json.decode(messages[i].attachments)
            end
        end
        cb(messages)
    elseif action == "sendMessage" then
        TriggerCallback("instagram:sendMessage", cb, data.username, data.message)
    elseif action == "search" then
        TriggerCallback("instagram:search", cb, data.query, data.page)
    end
end)

RegisterNetEvent("phone:instagram:addLiveMessage", function(data)
    SendNUIAction("instagram:addMessage", data)
end)

RegisterNetEvent("phone:instagram:updateLives", function(data)
    SendNUIAction("instagram:updateLives", data)
end)

RegisterNetEvent("phone:instagram:endLive", function(host)
    if host == watchingHost then
        MumbleClearVoiceTargetPlayers(1)
        for i = 1, #watchingSources do
            MumbleSetVolumeOverrideByServerId(watchingSources[i], -1.0)
            debugprint("InstaPic endLive: stopped listening to", watchingSources[i])
        end
        watchingHost = nil
        watchingSources = {}
    end
    SendNUIAction("instagram:liveEnded", host)
end)

RegisterNetEvent("phone:instagram:joinedLive", function(data)
    SendNUIAction("instagram:joinedLive", data)
    if data.source == GetPlayerServerId(PlayerId()) then
        return
    end
    watchingSources[#watchingSources + 1] = data.source
    local volume = (settings and settings.sound and settings.sound.volume) or 0.5
    volume = volume / 1
    MumbleAddVoiceTargetPlayerByServerId(1, data.source)
    MumbleSetVolumeOverrideByServerId(data.source, volume)
    debugprint("InstaPic joinedLive: started listening to", data.source, "volume:", volume)
end)

AddEventHandler("lb-phone:settingsUpdated", function()
    if not (watchingHost and #watchingSources ~= 0) then
        return
    end
    local volume = (settings and settings.sound and settings.sound.volume) or 0.5
    volume = volume / 1
    for i = 1, #watchingSources do
        local source = watchingSources[i]
        if source ~= GetPlayerServerId(PlayerId()) then
            MumbleSetVolumeOverrideByServerId(source, volume)
            debugprint("InstaPic settingsUpdated: set volume to", volume, "for", source)
        end
    end
end)

RegisterNetEvent("phone:instagram:leftLive", function(host, participant, source)
    SendNUIAction("instagram:leftLive", { host = host, participant = participant })
    if source == GetPlayerServerId(PlayerId()) then
        return
    end
    for i = 1, #watchingSources do
        if watchingSources[i] == source then
            MumbleSetVolumeOverrideByServerId(source, -1.0)
            MumbleRemoveVoiceTargetPlayerByServerId(1, source)
            debugprint("InstaPic leftLive: stopped listening to", source)
            table.remove(watchingSources, i)
            break
        end
    end
end)

RegisterNetEvent("phone:instagram:endCall", function(data)
    SendNUIAction("instagram:endCall", data)
end)

RegisterNetEvent("phone:instagram:updateViewers", function(username, viewers)
    SendNUIAction("instagram:updateViewers", { username = username, viewers = viewers })
end)

RegisterNetEvent("phone:instagram:updateProfileData", function(username, profileData, increment)
    debugprint("updateProfileData", username, profileData, increment)
    SendNUIAction("instagram:updateProfileData", { username = username, data = profileData, increment = increment })
end)

RegisterNetEvent("phone:instagram:updatePostData", function(postId, postData, increment)
    debugprint("updatePostData", postId, postData, increment)
    SendNUIAction("instagram:updatePostData", { postId = postId, data = postData, increment = increment })
end)

RegisterNetEvent("phone:instagram:updateCommentLikes", function(commentId, increment)
    debugprint("updateCommentLikes", commentId, increment)
    SendNUIAction("instagram:updateCommentLikes", { commentId = commentId, increment = increment })
end)

RegisterNetEvent("phone:instagram:newMessage", function(data)
    SendNUIAction("instagram:newMessage", data)
end)

RegisterNetEvent("phone:instagram:invitedLive", function(data)
    SendNUIAction("instagram:invitedLive", data)
end)

RegisterNetEvent("phone:instagram:removedLive", function()
    EndLive()
end)

RegisterNetEvent("phone:instagram:newPost", function(data)
    TriggerEvent("lb-phone:instapic:newPost", data)
end)

function EndLive()
    if not live then
        return
    end
    live = false
    DisableWalkableCam()
    AwaitCallback("instagram:endLive")
end

function IsLive()
    return live
end

function IsWatchingLive()
    return watchingHost
end

exports("IsLive", IsLive)
