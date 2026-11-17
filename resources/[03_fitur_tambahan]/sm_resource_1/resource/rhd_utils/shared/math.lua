
---Clamp a number between 2 other numbers
---@param val number
---@param lower number
---@param upper number
---@return number
function math.clamp(val, lower, upper)
    if lower > upper then lower, upper = upper, lower end
    return math.max(lower, math.min(upper, val))
end

---Rounds a number to a whole number or to the specified number of decimal places.
---@param value number | string
---@param places? number | string
---@return number
function math.round(value, places)
    ---@type number
    local n = type(value) == 'string' and tonumber(value) or value --[[@as number]]
    if type(n) ~= 'number' then error('Value must be a number') end

    if places then
        ---@type number
        local p = type(places) == 'string' and tonumber(places) or places --[[@as number]]
        if type(p) ~= 'number' then error('Places must be a number') end
        places = p

        if p > 0 then
            local mult = 10 ^ p
            return math.floor(n * mult + 0.5) / mult
        end
    end

    return math.floor(n + 0.5)
end

---Converts input number into grouped digits
---@param number number
---@param separator? string
---@return string
function math.groupdigits(number, separator)
    local left, num, right = string.match(tostring(number), '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1' .. (separator or ',')):reverse()) .. right
end

---Formats a number as a hexadecimal string.
---@param n number | string
---@param upper? boolean
---@return string
function math.tohex(n, upper)
    local formatString = ('0x%s'):format(upper and '%X' or '%x')
    return formatString:format(n)
end

---Takes a hexadecimal string and returns three integers (R, G, B).
---@param input string
---@return integer r
---@return integer g
---@return integer b
function math.hextorgb(input)
    local r, g, b = string.match(input, '([^#]+.)(..)(..)')
    return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

---Calculates an intermediate value between `start` and `finish` based on the interpolation `factor`.
---@param start number
---@param finish number
---@param factor number The interpolation factor between 0 and 1.
---@return number
function math.interp(start, finish, factor)
    return start + (finish - start) * factor
end

-- ─── Fungsi Tambahan ─────────────────────────────────────────────────────────

---Check if a number is NaN (not a number).
---@param n any
---@return boolean
function math.isnan(n)
    return n ~= n
end

---Check if a number is finite (not NaN or infinity).
---@param n number
---@return boolean
function math.isfinite(n)
    return n == n and n ~= math.huge and n ~= -math.huge
end

---Check if a number is infinite.
---@param n number
---@return boolean
function math.isinfinite(n)
    return n == math.huge or n == -math.huge
end

---Check if a number is an integer (no fractional part).
---@param n number
---@return boolean
function math.isinteger(n)
    return n == math.floor(n)
end

---Get the sign of a number: returns 1, -1, or 0.
---@param n number
---@return number
function math.sign(n)
    if n > 0 then return 1
    elseif n < 0 then return -1
    else return 0 end
end

---Truncate a number toward zero (remove decimal part).
---@param n number
---@return number
function math.trunc(n)
    return n >= 0 and math.floor(n) or math.ceil(n)
end

---Get the fractional part of a number.
---@param n number
---@return number
function math.frac(n)
    return n - math.trunc(n)
end

---Wrap a value within a range [min, max).
---Useful for angles, cyclic values, etc.
---@param n number
---@param min number
---@param max number
---@return number
function math.wrap(n, min, max)
    local range = max - min
    if range == 0 then return min end
    return min + ((n - min) % range)
end

---Map a value from one range to another.
---@param value number
---@param inMin number
---@param inMax number
---@param outMin number
---@param outMax number
---@return number
function math.map(value, inMin, inMax, outMin, outMax)
    if inMin == inMax then return outMin end
    return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin)
end

---Normalize a value to a 0..1 range within [min, max].
---@param value number
---@param min number
---@param max number
---@return number
function math.normalize(value, min, max)
    if min == max then return 0 end
    return (value - min) / (max - min)
end

---Smooth step interpolation (ease-in-out) between 0 and 1.
---@param edge0 number Lower edge
---@param edge1 number Upper edge
---@param x number Input value
---@return number
function math.smoothstep(edge0, edge1, x)
    x = math.clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
    return x * x * (3 - 2 * x)
end

---Smoother step interpolation (Ken Perlin's version) between 0 and 1.
---@param edge0 number Lower edge
---@param edge1 number Upper edge
---@param x number Input value
---@return number
function math.smootherstep(edge0, edge1, x)
    x = math.clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
    return x * x * x * (x * (x * 6 - 15) + 10)
end

---Return average (mean) of a list of numbers.
---@param ... number
---@return number
function math.average(...)
    local args = {...}
    local sum = 0
    local count = #args
    if count == 0 then return 0 end
    for i = 1, count do
        sum = sum + args[i]
    end
    return sum / count
end

---Return the sum of a list of numbers.
---@param ... number
---@return number
function math.sum(...)
    local args = {...}
    local total = 0
    for i = 1, #args do
        total = total + args[i]
    end
    return total
end

---Return the minimum value from a table (array of numbers).
---@param t table
---@return number?
function math.tmin(t)
    local min = nil
    for i = 1, #t do
        if min == nil or t[i] < min then
            min = t[i]
        end
    end
    return min
end

---Return the maximum value from a table (array of numbers).
---@param t table
---@return number?
function math.tmax(t)
    local max = nil
    for i = 1, #t do
        if max == nil or t[i] > max then
            max = t[i]
        end
    end
    return max
end

---Return the median of a list of numbers.
---@param t table
---@return number
function math.median(t)
    local sorted = {}
    for i = 1, #t do sorted[i] = t[i] end
    table.sort(sorted)
    local n = #sorted
    if n == 0 then return 0 end
    if n % 2 == 1 then
        return sorted[math.ceil(n / 2)]
    else
        return (sorted[n / 2] + sorted[n / 2 + 1]) / 2
    end
end

---Return the variance of a list of numbers.
---@param t table
---@param population? boolean Use population variance (default: sample variance)
---@return number
function math.variance(t, population)
    local n = #t
    if n < 2 then return 0 end

    local mean = 0
    for i = 1, n do mean = mean + t[i] end
    mean = mean / n

    local sumSq = 0
    for i = 1, n do
        local diff = t[i] - mean
        sumSq = sumSq + diff * diff
    end

    return sumSq / (population and n or (n - 1))
end

---Return the standard deviation of a list of numbers.
---@param t table
---@param population? boolean Use population std dev (default: sample)
---@return number
function math.stddev(t, population)
    return math.sqrt(math.variance(t, population))
end

---Greatest common divisor (GCD) of two integers.
---@param a integer
---@param b integer
---@return integer
function math.gcd(a, b)
    a, b = math.abs(a), math.abs(b)
    while b ~= 0 do
        a, b = b, a % b
    end
    return a
end

---Least common multiple (LCM) of two integers.
---@param a integer
---@param b integer
---@return integer
function math.lcm(a, b)
    if a == 0 or b == 0 then return 0 end
    return math.abs(a * b) / math.gcd(a, b)
end

---Check if an integer is prime.
---@param n integer
---@return boolean
function math.isprime(n)
    if n < 2 then return false end
    if n == 2 then return true end
    if n % 2 == 0 then return false end
    local limit = math.floor(math.sqrt(n))
    for i = 3, limit, 2 do
        if n % i == 0 then return false end
    end
    return true
end

---Factorial of a non-negative integer.
---@param n integer
---@return integer
function math.factorial(n)
    if n < 0 then error('factorial of negative number', 2) end
    if n == 0 then return 1 end
    local result = 1
    for i = 2, n do
        result = result * i
    end
    return result
end

---Fibonacci number at position n (0-indexed).
---@param n integer
---@return integer
function math.fibonacci(n)
    if n < 0 then error('fibonacci of negative index', 2) end
    if n == 0 then return 0 end
    if n == 1 then return 1 end
    local a, b = 0, 1
    for _ = 2, n do
        a, b = b, a + b
    end
    return b
end

---Degrees to radians.
---@param deg number
---@return number
function math.torad(deg)
    return deg * (math.pi / 180.0)
end

---Radians to degrees.
---@param rad number
---@return number
function math.todeg(rad)
    return rad * (180.0 / math.pi)
end

---Calculate the 2D distance between two points.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function math.dist2d(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

---Calculate the 3D distance between two points.
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return number
function math.dist3d(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

---Calculate bearing angle in degrees from point A to point B (2D, north = 0).
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number degrees 0-360
function math.bearing(x1, y1, x2, y2)
    local angle = math.todeg(math.atan(x2 - x1, y2 - y1))
    return math.wrap(angle, 0, 360)
end

---Return a random float between min and max.
---@param min number
---@param max number
---@return number
function math.randomfloat(min, max)
    return min + math.random() * (max - min)
end

---Round to the nearest multiple of `step`.
---@param value number
---@param step number
---@return number
function math.roundtostep(value, step)
    if step == 0 then return value end
    return math.floor(value / step + 0.5) * step
end

---Linear interpolation shorthand (alias for math.interp, scalar only).
---@param a number
---@param b number
---@param t number Factor 0..1
---@return number
function math.mix(a, b, t)
    return a + (b - a) * t
end

---Inverse linear interpolation: given a value between a and b, return the factor.
---@param a number
---@param b number
---@param value number
---@return number factor 0..1 (unclamped)
function math.inverselerp(a, b, value)
    if a == b then return 0 end
    return (value - a) / (b - a)
end

---Re-map a value from one [inMin, inMax] range to [outMin, outMax], clamped.
---@param value number
---@param inMin number
---@param inMax number
---@param outMin number
---@param outMax number
---@return number
function math.remap(value, inMin, inMax, outMin, outMax)
    return math.clamp(math.map(value, inMin, inMax, outMin, outMax), outMin, outMax)
end

---Exponential decay: moves `current` toward `target` by `decay` per second.
---Use in render/tick loops: value = math.decay(value, target, decay, dt)
---@param current number
---@param target number
---@param decay number Decay rate (higher = faster)
---@param dt number Delta time in seconds
---@return number
function math.decay(current, target, decay, dt)
    return target + (current - target) * math.exp(-decay * dt)
end

---Check if two numbers are approximately equal within an epsilon.
---@param a number
---@param b number
---@param epsilon? number Default 1e-9
---@return boolean
function math.approxequal(a, b, epsilon)
    epsilon = epsilon or 1e-9
    return math.abs(a - b) <= epsilon
end

---Safe divide: returns fallback if denominator is zero.
---@param numerator number
---@param denominator number
---@param fallback? number Default 0
---@return number
function math.safediv(numerator, denominator, fallback)
    if denominator == 0 then return fallback or 0 end
    return numerator / denominator
end

---Percentage: what percent is `part` of `total`?
---@param part number
---@param total number
---@return number 0..100
function math.percent(part, total)
    if total == 0 then return 0 end
    return (part / total) * 100
end

---Convert a percentage (0..100) to a 0..1 factor.
---@param pct number
---@return number
function math.percenttofactor(pct)
    return math.clamp(pct / 100, 0, 1)
end
