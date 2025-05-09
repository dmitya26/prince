Render = { -- idk how I feel about this table. code smell... works for now though.
	["WATER"]  = string.char(27) .. "[94m@"  .. string.char(27) .. "[0m", -- Water.
	["TREE"]   = string.char(27) .. "[32m♠"  .. string.char(27) .. "[0m", -- Tree.
	["GRASS"]  = string.char(27) .. "[92m%"  .. string.char(27) .. "[0m", -- Grass.
	["STONE"]  = string.char(27) .. "[37m&"  .. string.char(27) .. "[0m", -- Stone.
	["CURSOR"] = string.char(27) .. "[1;31m*" .. string.char(27) .. "[0m", -- Cursor.
}

-- Represents a Battalion of Dwarves (Battalion=1 million soldiers).
Dwarf = {

}

-- Represents a Battalion of Stalkers (Battalion=1 million soldiers).
Stalker = {

}

-- Represents a Battalion of Royal Guards (Battalion=1 million soldiers).
Guard = {

}

State = {
	cursor_x=1,
	cursor_y=1,

	map_x = 100,
	map_y = 100,

	-- basically this is for sliding window.
	cursor_window_radius = 20,

	buffered_entity={},

	--[[
	stalkers={}
	dwarves={}
	guards={}
	--]]
	--[[
	-- water 1
	-- tree  2
	-- grass 3
	-- stone 4
	--]]
	map={},
}

function organic (seed)
	math.randomseed(seed)
	-- layer1, grass
	for i=1,State.map_y do
		print(i)
		table.insert(State.map, {})
		for j=1,State.map_x do
			table.insert(State.map[i], "GRASS")
			--map[i][j].insert("WATER")
		end
	end

	-- layer2, tree
	for i,c in ipairs(State.map) do
		for j,d in ipairs(c) do
			local random = math.random(1,4)
			if j > 1 and random==1 then --left
				State.map[i][j-1] = "TREE"
			elseif i > 1 and random==2 then --up
				State.map[i-1][j] = "TREE"
			elseif j < State.map_x and random == 3 then --right
				State.map[i][j+1] = "TREE"
			elseif j > State.map_y and random == 4 then --down
				State.map[i+1][j] = "TREE"
			end
		end
	end

	-- layer3, water
	for i,c in ipairs(State.map) do
		for j,d in ipairs(c) do
			local random = math.random(1,4)
			if j > 1 and random==1 then --left
				State.map[i][j-1] = "WATER"
			elseif i > 1 and random==2 then --up
				State.map[i-1][j] = "WATER"
			elseif j < State.map_x and random == 3 then --right
				State.map[i][j+1] = "WATER"
			elseif j > State.map_y and random == 4 then --down
				State.map[i+1][j] = "WATER"
			end
		end
	end

	-- layer4, stone
	for i,c in ipairs(State.map) do
		for j,d in ipairs(c) do
			local random=math.random(1,10)
			if random==1 then
				State.map[i][j]="STONE"
			end
		end
	end

end

-- A boolean is returned for whether the input counts as a turn.
function keyboard_handler ()
	io.write("Input > ")
	local ch = io.read(1)
	io.flush()
	if ch == "s" then
		-- down
		State.cursor_y = State.cursor_y + 1
		return false
	elseif ch == "a" then
		-- left
		State.cursor_x = State.cursor_x - 1
		return false
	elseif ch == "w" then
		-- up
		State.cursor_y = State.cursor_y - 1
		return false
	elseif ch == "d" then
		-- right
		State.cursor_x = State.cursor_x + 1
		return false
	end
end

function render_map ()
	local nums = ""
	local num=0
	io.write("\n")
	for i, c in ipairs(State.map) do
		for j, _ in ipairs(c) do
			local current = State.map[i][j]
			local render = Render[current]
			if i == State.cursor_y and j == State.cursor_x then
				io.write(Render["CURSOR"])
			elseif render ~= nil then
				io.write(render)
			end
		end
		io.write("\n")
	end
end

function state_init ()
	-- potentially load save files in this function.
	-- load seeds and world changes.
	organic(10)
end

function frame ()
	keyboard_handler()
	render_map()
end

function main()
	state_init()
	while true do
		frame()
	end
end
main()
