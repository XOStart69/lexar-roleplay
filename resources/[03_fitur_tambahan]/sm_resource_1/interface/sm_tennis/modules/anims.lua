local anims = {
    dict = 'mini@tennis',
    sides = { 'backhand', 'forehand' },
    distances = { 'close', 'normal', 'dive' },

    hitDelay = {
        close = 297,
        normal = 264,
        dive = 429,
    },

    distOffset = {
        backhand = {
            close = vec2(-0.3, 0.5),
            normal = vec2(-0.8, 0.6),
            dive = vec2(-2.5, -0.15),
        },
        forehand = {
            close = vec2(0.3, 0.5),
            normal = vec2(0.8, 0.6),
            dive = vec2(2.5, -0.15),
        },
    },

    groundOffset = {
        lo = -0.5,
        md = -0.1,
        hi = 0.3,
    },

    speed = {
        close = 19.0,
        normal = 20.0,
        dive = 15.0,
    },

    toIdle = {
        forehand_ts_md = 'idle_bh',
        ['run_fwd_-45'] = 'idle_bh',
        run_fwd_45 = 'idle_fh',
        ['run_bwd_-135'] = 'idle_bh',
        run_bwd_135 = 'idle_fh',
        run_fwd_0 = 'idle_bh',
        strafe_bwd = 'idle_fh',
        ['run_bwd_-90_loop'] = 'idle_bh',
        run_fwd_90_loop = 'idle_fh',
    },
}

local spinTag = { normal = '', backspin = '_bs', topspin = '_ts' }
local handTag = { backhand = 'bh', forehand = 'fh' }
local grounds = { 'lo', 'md', 'hi' }

local tree = {}

for hand, tag in pairs(handTag) do
    local byDistance = { close = {}, normal = {}, dive = {} }

    for spin, sTag in pairs(spinTag) do
        local close, normal, dive = {}, {}, {}

        for i = 1, #grounds do
            local g = grounds[i]
            close[g] = ('close_%s%s_%s'):format(tag, sTag, g)
            normal[g] = ('%s%s_%s'):format(hand, sTag, g)
        end

        if spin == 'normal' then
            normal.lo = hand .. '_bs_lo'
            normal.md = hand
            normal.hi = hand .. '_ts_hi'
        end

        dive.lo = ('dive_%s_short_lo'):format(tag)
        dive.md = ('dive_%s'):format(tag)
        dive.hi = ('dive_%s_short_hi'):format(tag)

        byDistance.close[spin] = close
        byDistance.normal[spin] = normal
        byDistance.dive[spin] = dive
    end

    tree[hand] = byDistance
end

anims.tree = tree

---@param zDiff number
---@return string
function anims.groundBand(zDiff)
    local offsets = anims.groundOffset
    local lo = math.abs(zDiff - offsets.lo)
    local md = math.abs(zDiff - offsets.md)
    local hi = math.abs(zDiff - offsets.hi)

    if lo < md and lo < hi then return 'lo' end
    if hi < md and hi < lo then return 'hi' end
    return 'md'
end

return anims
