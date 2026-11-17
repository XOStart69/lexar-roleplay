local utils = {}
local serverSide = lib.context == 'server'

---@param str string
---@return string Trimmed
function utils.stringTrim(str)
    ---@diagnostic disable-next-line: redundant-return-value
    return str:gsub('^%s*(.-)%s*$', '%1')
end

if not serverSide then
    ---@param model string|integer
    ---@param timeout? number
    ---@return integer|nil
    function utils.waitForModel(model, timeout)
        model = type(model) == 'string' and joaat(model) or model
        local ok, response = pcall(lib.requestModel, model, timeout or 15000)

        if not ok then
            return lib.print.warn(response)
        end

        return response
    end

    ---@param dict string
    ---@param timeout? number
    ---@return string|nil
    function utils.waitForAnim(dict, timeout)
        local ok, response = pcall(lib.requestAnimDict, dict, timeout or 15000)

        if not ok then
            return lib.print.warn(response)
        end

        return response
    end

    ---@param model string|integer
    ---@param coords vector3
    ---@param networked? boolean
    ---@return integer? object
    function utils.createProp(model, coords, networked)
        local modelHash = utils.waitForModel(model)
        if not modelHash then return end

        local object = CreateObject(modelHash, coords.x, coords.y, coords.z, networked == true, true, false)
        SetModelAsNoLongerNeeded(modelHash)
        return object
    end
end

return utils