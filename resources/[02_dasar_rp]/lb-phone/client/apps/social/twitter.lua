local function formatTweet(post)
    if not post then
        return {}
    end
    local attachments = post.attachments
    if type(post.attachments) == "string" then
        attachments = json.decode(post.attachments)
    end
    if attachments then
        if not (type(attachments) == "table" and table.type(attachments) == "array") then
            attachments = nil
            debugprint("Malformed attachments for birdy post", post.id)
        end
    end
    return {
        user = {
            profile_picture = post.profile_image,
            name = post.display_name,
            username = post.username,
            verified = post.verified,
            private = post.private == true,
        },
        tweet = {
            id = post.id,
            content = post.content,
            date_created = post.timestamp,
            replies = post.reply_count,
            likes = post.like_count,
            retweets = post.retweet_count,
            attachments = attachments,
            replyToId = post.reply_to,
            liked = post.liked == true,
            retweeted = post.retweeted == true,
            replyToAuthor = post.replyToAuthor,
            retweetedByName = post.retweeted_by_display_name,
            retweetedByUsername = post.retweeted_by_username,
        },
    }
end

local function getPosts(filter, page)
    local posts = AwaitCallback("birdy:getPosts", filter, page)
    local formatted = {}
    for i = 1, #posts do
        formatted[i] = formatTweet(posts[i])
    end
    local index = math.random(3, 6)
    if index >= #formatted then
        index = #formatted - 1
    end
    if Config.PromoteBirdy and Config.PromoteBirdy.Enabled then
        if #posts > 1 then
            local promoted = AwaitCallback("birdy:getRandomPromoted")
            if promoted then
                promoted = formatTweet(promoted)
                promoted.tweet.promoted = true
                table.insert(formatted, index, promoted)
            end
        end
    end
    return formatted
end

local interactionActions = {
    "login",
    "toggleFollow",
    "toggleLike",
    "toggleRetweet",
    "sendMessage",
}

RegisterNUICallback("Twitter", function(data, cb)
    if not currentPhone then
        return
    end
    local action = data.action
    debugprint("Birdy:" .. (action or ""))
    if table.contains(interactionActions, action) then
        if not CanInteract() then
            return cb(false)
        end
    end
    if action == "createAccount" then
        TriggerCallback("birdy:createAccount", cb, data.data.name, data.data.username, data.data.password)
    elseif action == "changePassword" then
        TriggerCallback("birdy:changePassword", cb, data.oldPassword, data.newPassword)
    elseif action == "deleteAccount" then
        TriggerCallback("birdy:deleteAccount", cb, data.password)
    elseif action == "login" then
        TriggerCallback("birdy:login", cb, data.data.username, data.data.password)
    elseif action == "isLoggedIn" then
        TriggerCallback("birdy:isLoggedIn", cb)
    elseif action == "sendTweet" then
        TriggerCallback("birdy:sendPost", cb, data.data.content, data.data.attachments, data.data.replyTo, data.data.hashtags)
    elseif action == "updateProfile" then
        TriggerCallback("birdy:updateProfile", cb, data.data)
    elseif action == "searchAccounts" then
        TriggerCallback("birdy:searchAccounts", function(accounts)
            local results = {}
            for i = 1, #accounts do
                local account = accounts[i]
                results[i] = {
                    username = account.username,
                    name = account.display_name,
                    profile_picture = account.profile_image,
                    verified = account.verified,
                    private = account.private == true,
                }
            end
            cb(results)
        end, data.query, data.page)
    elseif action == "searchTweets" then
        TriggerCallback("birdy:searchTweets", function(tweets)
            local results = {}
            for i = 1, #tweets do
                results[i] = formatTweet(tweets[i])
            end
            cb(results)
        end, data.query, data.page)
    elseif action == "getProfile" then
        TriggerCallback("birdy:getProfile", function(profile)
            if not profile then
                debugprint("Birdy: failed to get profile", data.data.username)
                return cb()
            end
            if profile.pinnedTweet then
                profile.pinnedTweet = formatTweet(profile.pinnedTweet)
            end
            cb(profile)
        end, data.data.username)
    elseif action == "getFollowers" then
        TriggerCallback("birdy:getData", cb, "followers", data.data.username, data.data.page)
    elseif action == "getFollowing" then
        TriggerCallback("birdy:getData", cb, "following", data.data.username, data.data.page)
    elseif action == "getLikes" then
        TriggerCallback("birdy:getData", cb, "likes", data.data.tweet_id, data.data.page)
    elseif action == "getRetweeters" then
        TriggerCallback("birdy:getData", cb, "retweeters", data.data.tweet_id, data.data.page)
    elseif action == "getTweets" then
        data.filter = data.filter or data.filters
        if data.filter and next(data.filter) == nil then
            data.filter = nil
        end
        cb(getPosts(data.filter, data.page))
    elseif action == "getTweet" then
        TriggerCallback("birdy:getPost", function(post)
            cb(formatTweet(post))
        end, data.tweetId)
    elseif action == "getAuthor" then
        TriggerCallback("birdy:getAuthor", cb, data.tweetId)
    elseif action == "toggleFollow" then
        TriggerCallback("birdy:toggleFollow", cb, data.data.username, data.data.following)
    elseif action == "toggleNotifications" then
        TriggerCallback("birdy:toggleNotifications", cb, data.data.username, data.data.toggle)
    elseif action == "toggleLike" then
        TriggerCallback("birdy:toggleInteraction", cb, "like", data.tweet_id, data.liked)
    elseif action == "toggleRetweet" then
        TriggerCallback("birdy:toggleInteraction", cb, "retweet", data.tweet_id, data.retweeted)
    elseif action == "deleteTweet" then
        TriggerCallback("birdy:deletePost", cb, data.tweet_id)
    elseif action == "promoteTweet" then
        TriggerCallback("birdy:promotePost", cb, data.tweet_id)
    elseif action == "sendMessage" then
        data = data.data
        TriggerCallback("birdy:sendMessage", cb, data.recipient, data.content, data.attachments)
    elseif action == "getMessages" then
        data = data.data
        TriggerCallback("birdy:getMessages", function(messages)
            for i = 1, #messages do
                local message = messages[i]
                local attachments = message.attachments
                if attachments then
                    attachments = json.decode(message.attachments)
                end
                message.attachments = attachments
            end
            cb(messages)
        end, data.username, data.page)
    elseif action == "getRecentMessages" then
        TriggerCallback("birdy:getRecentMessages", cb, data.page)
    elseif action == "signOut" then
        TriggerCallback("birdy:signOut", cb)
    elseif action == "getNotifications" then
        TriggerCallback("birdy:getNotifications", function(result)
            for _, notification in pairs(result.notifications) do
                if notification.attachments then
                    notification.attachments = json.decode(notification.attachments)
                end
            end
            cb(result)
        end, data.page)
    elseif action == "getRecentHashtags" then
        TriggerCallback("birdy:getRecentHashtags", cb)
    elseif action == "pinTweet" then
        TriggerCallback("birdy:pinPost", cb, data.toggle and data.tweet_id)
    elseif action == "getFollowRequests" then
        TriggerCallback("birdy:getFollowRequests", cb, data.page or 0)
    elseif action == "handleFollowRequest" then
        TriggerCallback("birdy:handleFollowRequest", cb, data.username, data.accept)
    end
end)

RegisterNetEvent("phone:twitter:updateTweetData", function(tweetId, data, increment)
    debugprint("updateTweetData", tweetId, data, increment)
    SendNUIAction("twitter:updateTweetData", {
        tweetId = tweetId,
        data = data,
        increment = increment,
    })
end)

RegisterNetEvent("phone:twitter:updateProfileData", function(username, data, increment)
    debugprint("updateProfileData", username, data, increment)
    SendNUIAction("twitter:updateProfileData", {
        username = username,
        data = data,
        increment = increment,
    })
end)

RegisterNetEvent("phone:twitter:newMessage", function(data)
    SendNUIAction("twitter:newMessage", data)
end)

RegisterNetEvent("phone:twitter:newtweet", function(data)
    TriggerEvent("lb-phone:birdy:newPost", data)
    SendNUIAction("twitter:newTweet", formatTweet(data))
end)

function SendTweet(data)
    assert(type(data) == "table", "Expected table for data, got " .. type(data))
    assert(type(data.content) == "string", "Expected string for data.content, got " .. type(data.content))
    assert(type(data.attachments) == "table", "Expected table / nil for data.attachments, got " .. type(data.attachments))
    assert(type(data.replyTo) == "string", "Expected string / nil for data.replyTo, got " .. type(data.replyTo))
    assert(type(data.hashtags) == "table", "Expected table / nil for data.hashtags, got " .. type(data.hashtags))
    if not CanInteract() then
        return
    end
    return AwaitCallback("birdy:sendPost", data.content, data.attachments, data.replyTo, data.hashtags)
end

exports("SendTweet", SendTweet)
exports("PostBirdy", SendTweet)
