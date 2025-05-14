Render = { -- idk how I feel about this table. code smell... works for now though.
	["WATER"]   = string.char(27) .. "[94m@"  .. string.char(27) .. "[0m", -- Water.
	["TREE"]    = string.char(27) .. "[32m♠"  .. string.char(27) .. "[0m", -- Tree.
	["GRASS"]   = string.char(27) .. "[92m%"  .. string.char(27) .. "[0m", -- Grass.
	["STONE"]   = string.char(27) .. "[37m&"  .. string.char(27) .. "[0m", -- Stone.
	["CURSOR"]  = string.char(27) .. "[48;5;196m*" .. string.char(27) .. "[0m", -- Cursor.
	["GUARD"]   = string.char(27) .. "[1;31mG" .. string.char(27) .. "[0m",  -- Guard Legion.
	["STALKER"] = string.char(27) .. "[1;38;5;201mS"   .. string.char(27) .. "[0m",  -- Stalker Legion.
	["DWARF"] = string.char(27) .. "[1;1mD"   .. string.char(27) .. "[0m",  -- Stalker Legion.
}

MAPSIZE_X=80
MAPSIZE_Y=80


State = {
	map_x = MAPSIZE_X,
	map_y = MAPSIZE_Y,

	cursor_x=10,
	cursor_y=MAPSIZE_Y-5,

	-- basically this is for sliding window.
	cursor_window_radius_y = 15,
	cursor_window_radius_x = 30,

	buffered_entity={},

	legions={},

	turn=true, -- true=player false=opponent

	map={},

	code=0, -- continue, -1 error, 1 exit.
}


status_print=""

local function new_legion (legion_class, hp, dmg, loc_x, loc_y)
	return {
		["class"]=legion_class, -- Can be dwarf, stalker, or guard.
		["amount"]=1000000,
		["health"]=hp, -- change as needed.
		["damage"]=dmg, -- change as needed.

		["location_x"]=loc_x,
		["location_y"]=loc_y,

		["target_x"]=nil,
		["target_y"]=nil,
	}
end

local function contains_legion (x, y, lower_limit_x, upper_limit_x, lower_limit_y, upper_limit_y)
	for i=lower_limit_y,upper_limit_y do
		for j=lower_limit_x,upper_limit_x do
			if j == x and i == y then
				return State.legions[i][j]
			end
		end
	end
end

local function organic (seed)
	math.randomseed(seed)
	-- layer1, grass
	for i=1,State.map_y do
		table.insert(State.map, {})
		table.insert(State.legions, {})
		for j=1,State.map_x do
			table.insert(State.map[i], "GRASS")
			table.insert(State.legions[i], nil)
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

	-- layer4, stone, entities.
	for i,c in ipairs(State.map) do
		for j,d in ipairs(c) do
			local random=math.random(1,100)
			if random >=1 and random  <=5 then
				State.map[i][j]="STONE"
			elseif random==10 then
				local guard_x = math.random(1, State.map_x)
				local guard_y = math.random(1, State.map_y)

				local guard_legion = new_legion("GUARD", 100, 100, guard_x, guard_y)
				State.legions[guard_y][guard_x] = guard_legion
--  				table.insert(State.legions, guard_legion)
			elseif random==11 then
				local stalker_x = math.random(1, State.map_x)
				local stalker_y = math.random(1, State.map_y)

				local stalker_legion = new_legion("STALKER", 100, 100, stalker_x, stalker_y)
				State.legions[stalker_y][stalker_x] = stalker_legion
--				table.insert(State.legions, stalker_legion)
			elseif random==12 then
				local dwarf_x = math.random(1, State.map_x)
				local dwarf_y = math.random(1, State.map_y)

				local dwarf_legion = new_legion("DWARF", 100, 100, 1, dwarf_x, dwarf_y)
				State.legions[dwarf_y][dwarf_x] = dwarf_legion
--				table.insert(State.legions, dwarf_legion)
			end
		end
	end
end

-- A boolean is returned for whether the input counts as a turn.
local function keyboard_handler ()
	local ch = io.read(1)

	local start_y=(State.cursor_y-State.cursor_window_radius_y)
	if start_y < 1 then
		start_y = 1
	end
	local end_y=(State.cursor_y+State.cursor_window_radius_y)
	if end_y > State.map_y then
		end_y = State.map_y
	end

	local start_x=(State.cursor_x-State.cursor_window_radius_x)
	if start_x < 1 then
		start_x = 1
	end
	local end_x=(State.cursor_x+State.cursor_window_radius_x)
	if end_x > State.map_x then
		end_x = State.map_x
	end

	if ch == "q" then
		State.code=1
	elseif ch == "s" then
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
	elseif ch == "b" then
		-- Buffer a legion.
		local legion = contains_legion(State.cursor_x, State.cursor_y, start_x, end_x, start_y, end_y)
		if legion ~= nil then
			table.insert(State.buffered_entity, legion)
		end
		if legion ~= nil then
			status_print = "Buffered: " .. legion.class .. "\n"
		end
		legion=nil
		return false
	elseif ch == "m" then
		-- Flush buffered legion.
--		local legion = State.buffered_entity[0]
		local legion = table.remove(State.buffered_entity, 1)
		if legion ~= nil then
			status_print = "Moved: " .. legion.class .. "\n"
			legion.target_x=State.cursor_x
			legion.target_y=State.cursor_y
		end
		legion=nil
		return true
	end
end

local function update_entity_position ()
	for i,c in ipairs(State.legions) do
		if c.target_x ~= nil and c.target_y ~= nil then
			c.location_x = c.target_x
			c.location_y = c.target_y
		end
	end
end

local function render_map ()
	os.execute("clear")
	local nums = ""
	local num=0
	io.write("\n")

	local start_y=(State.cursor_y-State.cursor_window_radius_y)
	if start_y < 1 then
		start_y = 1
	end
	local end_y=(State.cursor_y+State.cursor_window_radius_y)
	if end_y > State.map_y then
		end_y = State.map_y
	end

	local start_x=(State.cursor_x-State.cursor_window_radius_x)
	if start_x < 1 then
		start_x = 1
	end
	local end_x=(State.cursor_x+State.cursor_window_radius_x)
	if end_x > State.map_x then
		end_x = State.map_x
	end

	for i=start_y,end_y do
		for j=start_x,end_x do
			local current = State.map[i][j]
			local render = Render[current]
			local legion = contains_legion(j, i, start_x, end_x, start_y, end_y)
			if legion ~= nil then
				io.write(Render[legion.class])
				legion=nil
			elseif i == State.cursor_y and j == State.cursor_x then
				io.write(Render["CURSOR"])
			elseif render ~= nil then
				io.write(render)
			end
		end
		io.write("\n")
	end
	io.write(status_print)

end

local function state_init ()
	-- potentially load save files in this function.
	-- load seeds and world changes.
	organic(100)
end

local function frame ()
	if keyboard_handler() then
		State.turn = not State.turn
	end
	update_entity_position()
	render_map()
end

local function main()
	state_init()

	while State.code == 0 do
		frame()
	end
	print(State.code)
end
main()
