Config = Config or {}

Config.Discord = {
    enabled = false,
    token = '',
    guildId = '',

    -- roleId -> poin prioritas
    priorityRoles = {
        -- ['123456789012345678'] = 500,
    },

    -- poin dasar untuk member guild
    memberPoints = 50,

    -- cache durasi (detik)
    cacheTime = 300,
}
