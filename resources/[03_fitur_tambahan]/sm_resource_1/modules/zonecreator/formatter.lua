--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

local function formatNumber(num)
	return tostring(num):gsub(",", ".")
end

return {
	poly = function(data)
		local points = {}
		for i = 1, #data.points do
			points[#points + 1] = ('\t\tvec3(%s, %s, %s),\n'):format((data.points[i].x), (data.points[i].y), (data.points[i].z))
		end

		local pattern = {
            '{\n',
            ('\tname = "%s",\n'):format(data.name),
            '\tpoints = {\n',
            ('%s\t},\n'):format(table.concat(points)),
            ('\tthickness = %s,\n'):format(data.thickness),
            '},\n'
        }

		return table.concat(pattern)
	end,
	box = function(data)
		local pattern = {
            '{\n',
            ('\tname = "%s",\n'):format(data.name),
            ('\tcoords = vec3(%s, %s, %s),\n'):format(
                formatNumber(data.coords.x),
                formatNumber(data.coords.y),
                formatNumber(data.coords.z)
            ),
            ('\tsize = vec3(%s, %s, %s),\n'):format(
                formatNumber(data.size.x),
                formatNumber(data.size.y),
                formatNumber(data.size.z)
            ),
            ('\trotation = %s,\n'):format(formatNumber(data.rotation)),
            '},\n',
        }

		return table.concat(pattern)
	end,
	sphere = function(data)
		local pattern = {
            '{\n',
            ('\tname = "%s",\n'):format(data.name),
            ('\tcoords = vec3(%s, %s, %s),\n'):format(data.coords.x, data.coords.y, data.coords.z),
            ('\tradius = %s,\n'):format(data.radius),
            '},\n',
        }
		return table.concat(pattern)
	end,
}