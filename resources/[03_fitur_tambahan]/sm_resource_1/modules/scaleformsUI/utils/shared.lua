local f = {}

---@enum Font
f.Fonts = {
  CHALET_LONDON = 0,
  HOUSE_SCRIPT = 1,
  MONOSPACE = 2,
  CHALET_COMPRIME_COLOGNE = 4,
  PRICEDOWN = 7
}

function f.resolutionMaintainRatio()
    local screenw, screenh = GetActiveScreenResolution()
    local ratio = screenw / screenh
    local width = 1080 * ratio
    return width, 1080
end

function f.formatXWYH(Value, Value2)
    local w, h = f.resolutionMaintainRatio()
    return Value / w, Value2 / h
end

function f.safezoneBounds()
    local t = GetSafeZoneSize()
    local g = lib.math.round(t, 2)
    g = (g * 100) - 90;
    g = 10 - g;

    local screenw = 720 * GetAspectRatio(false)
    local screenh = 720
    local ratio = screenw / screenh;
    local wmp = ratio * 5.4

    return lib.math.round(g * wmp), lib.math.round(g * 5.4)
end

return f