local emotes = require 'data.emotes'.shared

local keybinds = {
    'NUMPAD4',
    'NUMPAD5',
    'NUMPAD6',
    'NUMPAD7',
    'NUMPAD8',
    'NUMPAD9'
}

local function EmoteBindStart(source, args, raw)
    if #args > 0 then
        local numkey = tonumber(args[1])
        local emote = string.lower(args[2])

        if not (numkey and emote) then
            lib.print.info('Invalid arguments to EmoteBindStart')
            return
        end

        if type(numkey) == "number" then
            if emotes[emote] then
                kvp.update(('bindemote_%s'):format(numkey), emote)
            else
                lib.print.error('Emote tidak valid')
            end
        else
            lib.print.error('Key tidak valid')
        end
    else
        lib.print.info('Invalid number of arguments to EmoteBindStart')
    end
end


local function ListKeybinds()
    for i = 1, #keybinds do
        local emote = kvp.getString(('bindemote_%s'):format(i))
        if emote then
            lib.print.info(('Emote %s: %s'):format(i, emote))
        end
    end
end

local function DeleteEmote(args)
    if #args > 0 then
        local numkey = tonumber(args[1])
        if type(numkey) == "number" then
            kvp.delete(('bindemote_%s'):format(numkey))
        else
            lib.print.error('Key tidak valid')
        end
    else
        lib.print.error('Invalid arguments to DeleteEmote')
    end
end

RegisterCommand('emotebind', function(source, args, raw)
    EmoteBindStart(source, args, raw)
end, false)

RegisterCommand('emotebinds', function(source, args, raw)
    ListKeybinds()
end, false)

RegisterCommand('emotedelete', function(source, args)
    DeleteEmote(args)
end, false)

for i = 1, #keybinds do
    local cmd = ('emote_select_%s'):format(i)

    RegisterCommand(cmd, function()
        local emote = kvp.getString((('bindemote_%s'):format(i)))

        if emote and emote ~= "" then
            Emote.playFromMenu(emote, 0)
        end
    end, false)

    RegisterKeyMapping(cmd, ('Emote bind %s'):format(i), 'keyboard', keybinds[i])
end