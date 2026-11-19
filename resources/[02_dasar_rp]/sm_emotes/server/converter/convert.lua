local RES = GetCurrentResourceName()
local SOURCE = 'server/converter/RPConfig.lua'
local TARGET = 'animations/CustomAnimations.lua'

local function convertOptions(options)
    local out = {}

    if type(options) ~= 'table' then return out end

    for key, value in pairs(options) do
        if key == 'EmoteMoving' then
            out.onFootFlag = value and 51 or 1
        elseif key == 'EmoteLoop' then
            out.EmoteDuration = -1
        else
            out[key] = value
        end
    end

    return out
end

local function serialize(value, indent)
    local kind = type(value)

    if kind == 'table' then
        local parts = {}

        for key, item in pairs(value) do
            local formatted = type(key) == 'string' and key:match('^[%a_][%w_]*$')
                and key
                or ('[%q]'):format(tostring(key))

            parts[#parts + 1] = ('%s%s = %s,'):format(indent .. '    ', formatted, serialize(item, indent .. '    '))
        end

        return '{\n' .. table.concat(parts, '\n') .. '\n' .. indent .. '}'
    end

    if kind == 'string' then
        return ('%q'):format(value)
    end

    return tostring(value)
end

local function convert()
    local src = LoadResourceFile(RES, SOURCE)

    if not src then
        return lib.print.error('RPConfig tidak ditemukan')
    end

    local env = setmetatable({}, { __index = _G })
    local chunk = load(src, '@' .. SOURCE, 't', env)

    if not chunk then
        return lib.print.error('RPConfig gagal di-load')
    end

    local ok = pcall(chunk)

    if not ok or type(env.RP) ~= 'table' then
        return lib.print.error('RPConfig gagal dieksekusi')
    end

    local out = {}
    local total = 0

    local function collect(list)
        if type(list) ~= 'table' then return end

        for name, entry in pairs(list) do
            if type(entry) == 'table' and entry[1] and entry[2] then
                out[name] = {
                    dict = entry[1],
                    anim = entry[2],
                    label = entry[3] or name,
                    AnimationOptions = convertOptions(entry.AnimationOptions),
                }

                total += 1
            end
        end
    end

    collect(env.RP.CustomAnimations)
    collect(env.RP.PropEmotes)
    collect(env.RP.Shared)

    if total == 0 then
        return lib.print.warn('tidak ada animasi yang bisa dikonversi')
    end

    local current = LoadResourceFile(RES, TARGET)

    if current and not LoadResourceFile(RES, TARGET .. '.bak') then
        SaveResourceFile(RES, TARGET .. '.bak', current, -1)
    end

    local buffer = {
        '-- dibuat otomatis oleh server/converter/convert.lua',
        ('-- total %s emote'):format(total),
        'return {',
    }

    for name, data in pairs(out) do
        buffer[#buffer + 1] = ('    [%q] = %s,'):format(name, serialize(data, '    '))
    end

    buffer[#buffer + 1] = '}'

    SaveResourceFile(RES, TARGET, table.concat(buffer, '\n'), -1)

    lib.print.info(('konversi selesai: %s emote -> %s'):format(total, TARGET))
end

RegisterCommand('emotes_convert', function()
    convert()
end, true)

exports('ConvertEmotes', convert)
