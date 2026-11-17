---@alias MotelInteriorChangeCallback fun(currentRoom: string?)

---@class MotelInteriorPrivate
---@field currentRoom string?
---@field hooks MotelInteriorChangeCallback[]

---@class MotelInteriorClass
---@field private private MotelInteriorPrivate

---@class MotelInteriorPublic
---@field currentRoom string?
---@field onInteriorChange fun(cb: MotelInteriorChangeCallback)

local MotelInteriorClass = lib.class('MotelInterior')

function MotelInteriorClass:constructor()
	self.private.currentRoom = nil
	self.private.interiorCoords = nil
	self.private.hooks = {}
end

---@return string?
function MotelInteriorClass:getCurrentRoom()
	return self.private.currentRoom
end

---@param cb MotelInteriorChangeCallback
function MotelInteriorClass:onInteriorChange(cb)
	assert(type(cb) == 'function', 'MotelInterior.onInteriorChange expected callback function')
	self.private.hooks[#self.private.hooks + 1] = cb
end

---@param roomName string?
---@return boolean changed
function MotelInteriorClass:setCurrentRoom(roomName)
	if self.private.currentRoom == roomName then
		return false
	end

	self.private.currentRoom = roomName

	return true
end

function MotelInteriorClass:emitInteriorChange()
	local currentRoom = self.private.currentRoom
	local hooks = self.private.hooks

	for index = 1, #hooks do
		local cb = hooks[index]

		CreateThread(function()
			local success, errorMessage = pcall(cb, currentRoom)

			if not success then
				lib.print.error(('[rhd_motel] MotelInterior hook failed: %s'):format(errorMessage))
			end
		end)
	end
end

---@return string?
local function readCurrentInteriorRoom()
	if not LocalPlayer.state.isLoggedIn then
		return nil
	end

	local interiorId = GetInteriorFromEntity(cache.ped)

	if interiorId == 0 then
		return nil
	end

	local roomHash = GetRoomKeyFromEntity(cache.ped)
	local roomId = GetInteriorRoomIndexByHash(interiorId, roomHash)

	return roomId ~= -1 and GetInteriorRoomName(interiorId, roomId) or 'unknown'
end

local motelInterior = MotelInteriorClass:new()

CreateThread(function()
	while true do
		local changed = motelInterior:setCurrentRoom(readCurrentInteriorRoom())

		if changed then
			motelInterior:emitInteriorChange()
		end

		Wait(500)
	end
end)

return setmetatable({}, {
	__index = function(_, key)
		if key == 'currentRoom' then
			return motelInterior:getCurrentRoom()
		end

		if key == 'onInteriorChange' then
			return function(cb)
				motelInterior:onInteriorChange(cb)
			end
		end
	end,
	__newindex = function(_, key)
		if key == 'currentRoom' then
			error('MotelInterior.currentRoom is read-only', 2)
		end

		error(('MotelInterior.%s cannot be changed'):format(key), 2)
	end,
	__metatable = false,
}) --[[@as MotelInteriorPublic]]
