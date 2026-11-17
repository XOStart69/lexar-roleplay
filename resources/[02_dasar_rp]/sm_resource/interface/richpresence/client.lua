local discord = {
    ApplicationId = '1531038917036478484',
    IconLarge = 'satu_mimpi_logo',
    IconLargeHoverText = 'smrp',
    IconSmall = '',
    IconSmallHoverText = '',
    Buttons = {
        {
            text = 'JOIN COMMUNITY',
            url = 'https://discord.gg/73jpyAMXFP'
        },
        {
            text = '',
            url = ''
        }
    }
}

local playerCount = #GetActivePlayers()
local detailMessages = 'Release Version'

local function updateRichPresence(totalPlayers)
    Wait(5000)
    playerCount = totalPlayers or #GetActivePlayers()
    SetRichPresence(
        detailMessages:format(cache.serverId --[[@as number]], playerCount)
    )
end

SetDiscordAppId(discord.ApplicationId)
SetDiscordRichPresenceAsset(discord.IconLarge)
SetDiscordRichPresenceAssetText(discord.IconLargeHoverText)
SetDiscordRichPresenceAssetSmall(discord.IconSmall)
SetDiscordRichPresenceAssetSmallText(discord.IconSmallHoverText)

for i, v in pairs(discord.Buttons) do
    SetDiscordRichPresenceAction(i - 1,
        v.text,
        v.url
    )
end



RegisterNetEvent('sm_hud:client:updateServerInfo', function (totalPlayer, maxPlayer)
    if source == '' then return end
    updateRichPresence(totalPlayer)
end)