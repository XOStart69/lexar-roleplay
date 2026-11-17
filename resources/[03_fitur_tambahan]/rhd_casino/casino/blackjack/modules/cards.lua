local cards = {}

local ranks = {'02', '03', '04', '05', '06', '07', '08', '09', '10', --[['11',]] 'JACK', 'QUEEN', 'KING', 'ACE'}
local suits = {'SPD', 'HRT', 'DIA', 'CLUB'}

cards.offset = {
	[1] = {
		vector3(0.5737, 0.2376, 0.948025),
		vector3(0.562975, 0.2523, 0.94875),
		vector3(0.553875, 0.266325, 0.94955),
		vector3(0.5459, 0.282075, 0.9501),
		vector3(0.536125, 0.29645, 0.95085),
		vector3(0.524975, 0.30975, 0.9516),
		vector3(0.515775, 0.325325, 0.95235),
	},

	[2] = {
		vector3(0.2325, -0.1082, 0.94805),
		vector3(0.23645, -0.0918, 0.949),
		vector3(0.2401, -0.074475, 0.950225),
		vector3(0.244625, -0.057675, 0.951125),
		vector3(0.249675, -0.041475, 0.95205),
		vector3(0.257575, -0.0256, 0.9532),
		vector3(0.2601, -0.008175, 0.954375),
	},

	[3] = {
		vector3(-0.2359, -0.1091, 0.9483),
		vector3(-0.221025, -0.100675, 0.949),
		vector3(-0.20625, -0.092875, 0.949725),
		vector3(-0.193225, -0.07985, 0.950325),
		vector3(-0.1776, -0.072, 0.951025),
		vector3(-0.165, -0.060025, 0.951825),
		vector3(-0.14895, -0.05155, 0.95255),
	},

	[4] = {
		vector3(-0.5765, 0.2229, 0.9482),
		vector3(-0.558925, 0.2197, 0.949175),
		vector3(-0.5425, 0.213025, 0.9499),
		vector3(-0.525925, 0.21105, 0.95095),
		vector3(-0.509475, 0.20535, 0.9519),
		vector3(-0.491775, 0.204075, 0.952825),
		vector3(-0.4752, 0.197525, 0.9543),
	}
}

cards.rotOffset = {
	[1] = { 69.12, 67.8, 66.6, 70.44, 70.84, 67.88, 69.56 },
	[2] = { 22.11, 22.32, 20.8, 19.8, 19.44, 26.28, 22.68 },
	[3] = { -21.43, -20.16, -16.92, -23.4, -21.24, -23.76, -19.44 },
	[4] = { -67.03, -69.12, -64.44, -67.68, -63.72, -68.4, -64.44 },
}

cards.splitOffset = {
	[1] = {
		vector3(0.6083, 0.3523, 0.94795),
		vector3(0.598475, 0.366475, 0.948925),
		vector3(0.589525, 0.3807, 0.94975),
		vector3(0.58045, 0.39435, 0.950375),
		vector3(0.571975, 0.4092, 0.951075),
		vector3(0.5614, 0.4237, 0.951775),
		vector3(0.554325, 0.4402, 0.952525),
	},

	[2] = {
		vector3(0.3431, -0.0527, 0.94855),
		vector3(0.348575, -0.0348, 0.949425),
		vector3(0.35465, -0.018825, 0.9502),
		vector3(0.3581, -0.001625, 0.95115),
		vector3(0.36515, 0.015275, 0.952075),
		vector3(0.368525, 0.032475, 0.95335),
		vector3(0.373275, 0.0506, 0.9543),
	},

	[3] = {
		vector3(-0.116, -0.1501, 0.947875),
		vector3(-0.102725, -0.13795, 0.948525),
		vector3(-0.08975, -0.12665, 0.949175),
		vector3(-0.075025, -0.1159, 0.949875),
		vector3(-0.0614, -0.104775, 0.9507),
		vector3(-0.046275, -0.095025, 0.9516),
		vector3(-0.031425, -0.0846, 0.952675),
	},

	[4] = {
		vector3(-0.5205, 0.1122, 0.9478),
		vector3(-0.503175, 0.108525, 0.94865),
		vector3(-0.485125, 0.10475, 0.949175),
		vector3(-0.468275, 0.099175, 0.94995),
		vector3(-0.45155, 0.09435, 0.95085),
		vector3(-0.434475, 0.089725, 0.95145),
		vector3(-0.415875, 0.0846, 0.9523),
	}
}

cards.splitRotOffset = {
	[1] = { 68.57, 67.52, 67.76, 67.04, 68.84, 65.96, 67.76 },
	[2] = { 22.11, 22.0, 24.44, 21.08, 25.96, 26.16, 28.76 },
	[3] = { -14.04, -15.48, -16.56, -15.84, -16.92, -14.4, -14.28 },
	[4] = { -67.03, -67.6, -69.4, -69.04, -68.68, -66.16, -63.28 },
}

cards.offsetDealer = {
	vector3(0.0436, 0.21205, 0.948875),
	vector3(-0.0636, 0.213825, 0.9496),
	vector3(-0.0806, 0.2137, 0.950225),
	vector3(-0.1006, 0.21125, 0.950875),
	vector3(-0.1256, 0.21505, 0.951875),
	vector3(-0.1416, 0.21305, 0.953),
	vector3(-0.1656, 0.21205, 0.954025),
	vector3(-0.1836, 0.21255, 0.95495),
	vector3(-0.2076, 0.21105, 0.956025),
	vector3(-0.2246, 0.21305, 0.957),
}

cards.rotOffsetDealer = {
	vector3(0.0, 0.0, 178.92),
	vector3(0.0, 0.0, -180.0),
	vector3(0.0, 0.0, -178.92),
	vector3(0.0, 0.0, -177.12),
	vector3(0.0, 0.0, 180.0),
	vector3(0.0, 0.0, 178.56),
	vector3(0.0, 0.0, 180.0),
	vector3(0.0, 0.0, 178.2),
	vector3(0.0, 0.0, -177.12),
	vector3(0.0, 0.0, 180.0),
	vector3(0.0, 0.0, 178.56),
}

cards.chipSplitOffsets = {
	[1] = {
		vector3(0.6931, 0.1952, 0.0),
		vector3(0.724925, 0.26955, 0.0),
		vector3(0.7374, 0.349625, 0.0),
		vector3(0.76415, 0.419225, 0.0),
	},

	[2] = {
		vector3(0.2827, -0.227825, 0.0),
		vector3(0.3605, -0.1898, 0.0),
		vector3(0.4309, -0.16365, 0.0),
		vector3(0.49275, -0.111575, 0.0),
	},

	[3] = {
		vector3(-0.279425, -0.2238, 0.0),
		vector3(-0.200775, -0.25855, 0.0),
		vector3(-0.125775, -0.26815, 0.0),
		vector3(-0.05615, -0.29435, 0.0),
	},

	[4] = {
		vector3(-0.685925, 0.173275, 0.0),
		vector3(-0.6568, 0.092525, 0.0),
		vector3(-0.612875, 0.033025, 0.0),
		vector3(-0.58465, -0.0374, 0.0),
	}
}

---@param tbl string[]
---@return string[]
function cards.shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

---@return string[]
function cards.getDeck()
	local tDeck = {}
	for i = 1, #ranks do
		for j = 1, #suits do
			table.insert(tDeck, suits[j] .. '_' .. ranks[i])
		end
	end
	return cards.shuffle(tDeck)
end

---@param tDeck string[]
---@return string?
function cards.takeCard(tDeck)
	return table.remove(tDeck, 1)
end

---@param hand string[]
---@return integer
function cards.handValue(hand)
	local tmpValue = 0
	local numAces = 0

	for i = 1, #hand do
		tmpValue = tmpValue + cards.cardValue(hand[i])
	end

	for i = 1, #hand do
		if string.find(hand[i], 'ACE') then numAces = numAces + 1 end
	end

	repeat
		if tmpValue > 21 and numAces > 0 then
			tmpValue = tmpValue - 10
			numAces = numAces - 1
		else
			break
		end
	until numAces == 0

	return tmpValue
end

---@param card string
---@return integer
function cards.cardValue(card)
    local rank = 10
    for i=2,11 do
        if string.find(card, tostring(i)) then
            rank = i
        end
    end
    if string.find(card, 'ACE') then
        rank = 11
    end

    return rank
end

return cards