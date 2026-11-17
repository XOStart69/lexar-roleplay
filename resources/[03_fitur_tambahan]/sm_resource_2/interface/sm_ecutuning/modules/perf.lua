HRSPerf = HRSPerf or {}

HRSPerf.Stages = {
    [0] = { basis = 0,  nutzung = 0.0, deckel = 0,  mapBonus = 0,  vmaxGain = 0.00 },
    [1] = { basis = 8,  nutzung = 0.4, deckel = 12, mapBonus = 6,  vmaxGain = 0.04 },
    [2] = { basis = 14, nutzung = 0.7, deckel = 25, mapBonus = 12, vmaxGain = 0.08 },
    [3] = { basis = 18, nutzung = 1.0, deckel = 38, mapBonus = 20, vmaxGain = 0.11 },
}

HRSPerf.BoostRef = 82

HRSPerf.BoostBar = { min = 0.5, max = 3.0 }

HRSPerf.Hardware = {
    turbo             = { reserve = 18, ceiling = 70 },
    downpipe          = { reserve = 4  },
    straightpipe      = { reserve = 5  },
    endschalldaempfer = { reserve = 2  },
    ladeluftkuehler   = { reserve = 3,  cooling = 10 },
    airfilter         = { reserve = 2,  cooling = 5 },
}
HRSPerf.StockCeiling = 60

HRSPerf.Sliders = {
    { key = 'boost', min = 50, max = 100, def = 82 },
    { key = 'vmax',  min = 0,  max = 100, def = 100 },
    { key = 'resp',  min = 0,  max = 100, def = 50 },
    { key = 'shift', min = 0,  max = 100, def = 30 },
    { key = 'tq',    min = 50, max = 100, def = 85 },
    { key = 'rev',   min = 60, max = 100, def = 100 },
    { key = 'ign',   min = 0,  max = 100, def = 50 },
    { key = 'mix',   min = 0,  max = 100, def = 50 },
}
HRSPerf.StageBoostMax = { [0] = 50, [1] = 90, [2] = 100, [3] = 100 }

HRSPerf.Clamp = {
    driveForceMul = { [0] = 1.0, [1] = 1.16, [2] = 1.31, [3] = 1.48 },
    driveForceAbs = 0.95,
    inertiaMin    = 0.6,
    inertiaMax    = 1.4,
    clutchAbs     = 8.0,
    driveForceExp = 0.85,
}

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function HRSPerf.defaultMap()
    local m = {}
    for _, s in ipairs(HRSPerf.Sliders) do m[s.key] = s.def end
    return m
end

function HRSPerf.sanitizeMap(map, stage)
    local out = HRSPerf.defaultMap()
    if type(map) ~= 'table' then return out end
    for _, s in ipairs(HRSPerf.Sliders) do
        local v = tonumber(map[s.key])
        if v then
            v = math.floor(v + 0.5)
            local hi = s.max
            if s.key == 'boost' then hi = HRSPerf.StageBoostMax[stage] or s.max end
            out[s.key] = clamp(v, s.min, hi)
        end
    end
    return out
end

function HRSPerf.stageOf(parts)
    local st = 0
    for _, p in ipairs(parts or {}) do
        if p == 'ecustage3' then st = math.max(st, 3)
        elseif p == 'ecustage2' then st = math.max(st, 2)
        elseif p == 'ecustage1' then st = math.max(st, 1) end
    end
    return st
end

function HRSPerf.compute(base, parts, map)
    local stage = HRSPerf.stageOf(parts)
    local st    = HRSPerf.Stages[stage]
    map = HRSPerf.sanitizeMap(map, stage)

    local R, D, cool, fuel = 0, HRSPerf.StockCeiling, 0, 0
    local hasShift = false
    for _, p in ipairs(parts or {}) do
        local h = HRSPerf.Hardware[p]
        if h then
            R    = R + (h.reserve or 0)
            D    = math.max(D, h.ceiling or 0)
            cool = cool + (h.cooling or 0)
            fuel = fuel + (h.fuel or 0)
        end
        if p == 'getriebeflash' then hasShift = true end
    end
    local engine = base.engine or 'turbo'
    if engine == 'na' then R = R * 0.6 end
    if engine == 'ev' then R = R * 0.4 end

    local boost = map.boost / 100
    local ref   = HRSPerf.BoostRef / 100

    local G = st.basis + st.nutzung * R * ref
    G = clamp(G, 0, st.deckel)

    if stage > 0 and (st.mapBonus or 0) > 0 then
        local aBoost = clamp((map.boost - HRSPerf.BoostRef) / (100 - HRSPerf.BoostRef), 0, 1)
        local aIgn   = clamp((map.ign - 50) / 50, 0, 1)
        local aMix   = clamp((map.mix - 50) / 50, 0, 1)
        local aggr   = 0.5 * aBoost + 0.3 * aIgn + 0.2 * aMix
        G = G + st.mapBonus * aggr
    end

    local q = 1 + G / 100
    local tqFactor = (engine == 'turbo') and 1.15 or (engine == 'ev' and 1.0 or 0.95)

    local ps = math.floor(base.ps * q + 0.5)
    local nm = math.floor(base.nm * (1 + G / 100 * tqFactor) + 0.5)

    local stress = 45
        + 30 * (boost - 0.5) / 0.5
        + 25 * (map.ign - 50) / 50
        + 20 * math.max(0, map.mix - 50) / 50
        - fuel - cool
    stress = clamp(stress, 0, 150)
    local rel = clamp(100 - math.max(0, stress - D), 0, 100)

    local C = HRSPerf.Clamp
    local dfMul = math.min(q ^ C.driveForceExp, C.driveForceMul[stage] or 1.0)
    local vmMul = 1 + (st.vmaxGain or 0) * (map.vmax / 100)
    local inMul = (1 + 0.05 * stage) * (0.8 + 0.4 * map.resp / 100) * (1 + 0.10 * (map.ign - 50) / 50)
    inMul = clamp(inMul, C.inertiaMin, C.inertiaMax)
    local clMul = (1 + 0.10 * stage) * (1 + 0.6 * map.shift / 100) * (hasShift and 1.25 or 1.0)

    local curve = {
        spool = (engine == 'turbo') and (0.35 - 0.15 * boost) or 0.0,
        fall  = 0.78 + (fuel > 0 and 0.10 or 0.0),
        rev   = map.rev / 100,
        tqLow = map.tq / 100,
        shaped = stage > 0,
    }

    if ECUConfig and ECUConfig.ModifyHandling == false then
        G, ps, nm = 0, base.ps or ps, base.nm or nm
        dfMul, vmMul, inMul, clMul = 1.0, 1.0, 1.0, 1.0
        curve.shaped = false
        curve.rev    = 1.0
        curve.tqLow  = 1.0
    end

    return {
        stage = stage, map = map,
        reserve = R, ceiling = D, gain = G, q = q,
        ps = ps, nm = nm,
        stress = math.floor(stress + 0.5), rel = math.floor(rel + 0.5),
        mult = { driveForce = dfMul, vmax = vmMul, inertia = inMul, clutch = clMul },
        curve = curve,
    }
end

function HRSPerf.torqueAt(curve, rpm, gear)
    if not curve or not curve.shaped then return 1.0 end
    local f = 1.0
    if rpm < curve.spool then
        f = 0.60 + 0.40 * (rpm / math.max(0.01, curve.spool))
    end
    if gear and gear <= 2 then f = f * curve.tqLow end
    return clamp(f, 0.2, 1.8)
end

function HRSPerf.torqueShapeForChart(curve, rpm)
    if not curve then return 1.0 end
    if rpm < curve.spool then
        return 0.45 + 0.55 * (rpm / math.max(0.01, curve.spool))
    elseif rpm < curve.fall then
        return 1.0
    end
    return 1.0 - 0.35 * ((rpm - curve.fall) / math.max(0.01, 1.0 - curve.fall))
end
