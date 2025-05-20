Render = { -- idk how I feel about this table. code smell... works for now though.
	["WATER"]   = string.char(27) .. "[94m@"  .. string.char(27) .. "[0m", -- Water.
	["TREE"]    = string.char(27) .. "[32m♠"  .. string.char(27) .. "[0m", -- Tree.
	["GRASS"]   = string.char(27) .. "[92m%"  .. string.char(27) .. "[0m", -- Grass.
	["STONE"]   = string.char(27) .. "[37m&"  .. string.char(27) .. "[0m", -- Stone.

	["CURSOR"]  = string.char(27) .. "[1;48;5;196m*" .. string.char(27) .. "[0m", -- Cursor.
	["GUARD"]   = string.char(27) .. "[1;31mG" .. string.char(27) .. "[0m",  -- Guard Legion.
	["STALKER"] = string.char(27) .. "[1;38;5;201mS"   .. string.char(27) .. "[0m",  -- Stalker Legion.
	["DWARF"]   = string.char(27) .. "[1;1mD"   .. string.char(27) .. "[0m",  -- Stalker Legion.

	["WYVERN"]    = string.char(27) .. "[41;30mW" .. string.char(27) .. "[0m", -- Vampire Legion.
	["DEMON"]   = string.char(27) .. "[43;30mD"  .. string.char(27) .. "[0m",
	["GARGOYLE"] = string.char(27) .. "[42;30mG" .. string.char(27) .. "[0m",
}
--♠
MAPSIZE_X=80
MAPSIZE_Y=80


State = {
	map_x = MAPSIZE_X,
	map_y = MAPSIZE_Y,

	cursor_x=10,
	cursor_y=MAPSIZE_Y-5,

	-- basically this is for sliding window.
	cursor_window_radius_y = 15,
	cursor_window_radius_x = 25,

	buffered_entity={},

	legions={},

	turn=true, -- true=player false=opponent

	map={},

	code=0, -- continue, -1 error, 1 exit.

	zoom_mode=1, -- -1=zoom-out 1=zoom-in
	zoom_legions={},
	zoom_terrain="",

	zoom_map_x = 100,
	zoom_map_y = 50,

	legions_overlapping={},
}

status_print=""

local function new_legion (legion_class, hp, dmg, is_evil)
	local zoom_map = {}
	for i=1,State.zoom_map_y do
		table.insert(zoom_map, {})
		for j=1,State.zoom_map_x do
			if j%2 == 0 and i%2 == 0 then
				zoom_map[i][j] = 1
			end
		end
	end
	return {
		["class"]=legion_class, -- Can be dwarf, stalker, or guard.
		["amount"]=1000000,
		["health"]=hp, -- change as needed.
		["damage"]=dmg, -- change as needed.
		["evil"]=is_evil,

		["target_x"]=nil,
		["target_y"]=nil,

		["zoom_map"]=zoom_map,
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
			elseif random==6 then
				local guard_x = math.random(1, State.map_x)
				local guard_y = math.random(State.map_y*(3/4), State.map_y)

				local guard_legion = new_legion("GUARD", 100, 100, false)
				State.legions[guard_y][guard_x] = guard_legion
			elseif random==7 then
				local stalker_x = math.random(1, State.map_x)
				local stalker_y = math.random(State.map_y*(3/4), State.map_y)

				local stalker_legion = new_legion("STALKER", 100, 100, false)
				State.legions[stalker_y][stalker_x] = stalker_legion
			elseif random==8 then
				local dwarf_x = math.random(1, State.map_x)
				local dwarf_y = math.random(State.map_y*(3/4), State.map_y)

				local dwarf_legion = new_legion("DWARF", 100, 100, false)
				State.legions[dwarf_y][dwarf_x] = dwarf_legion
			elseif random==9 then
				local vampire_x = math.random(1, State.map_x)
				local vampire_y = math.random(1, State.map_y*(3/4))

				local vampire_legion = new_legion("WYVERN", 100, 100, 1, true)
				State.legions[vampire_y][vampire_x] = vampire_legion
			elseif random==10 then
				local fomorian_x = math.random(1, State.map_x)
				local fomorian_y = math.random(1, State.map_y*(3/4))

				local fomorian_legion = new_legion("DEMON", 100, 100, 1, true)
				State.legions[fomorian_y][fomorian_x] = fomorian_legion
			elseif random==11 then
				local lizardfolk_x = math.random(1, State.map_x)
				local lizardfolk_y = math.random(1, State.map_y*(3/4))

				local lizardfolk_legion = new_legion("GARGOYLE", 100, 100, 1, true)
				State.legions[lizardfolk_y][lizardfolk_x] = lizardfolk_legion
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
		if State.cursor_y < State.map_y then
			State.cursor_y = State.cursor_y + 1
		end
	elseif ch == "a" then
		-- left
		if State.cursor_x > 1 then
			State.cursor_x = State.cursor_x - 1
		end
	elseif ch == "w" then
		-- up
		if State.cursor_y > 1 then
			State.cursor_y = State.cursor_y - 1
		end
	elseif ch == "d" then
		-- right
		if State.cursor_x < State.map_x then
			State.cursor_x = State.cursor_x + 1
		end
	elseif ch == "+" then
		State.cursor_window_radius_x = State.cursor_window_radius_x + 2
		State.cursor_window_radius_y = State.cursor_window_radius_y + 1
	elseif ch == "-" then
		State.cursor_window_radius_x = State.cursor_window_radius_x - 2
		State.cursor_window_radius_y = State.cursor_window_radius_y - 1
	elseif ch == "z" then
		State.zoom_mode = State.zoom_mode * -1
		State.zoom_opponent = State.legions[State.cursor_y][State.cursor_x]
		State.zoom_terrain = State.map[State.cursor_y][State.cursor_x]
		table.insert(State.zoom_legions, State.buffered_entity)
	elseif ch == "b" then
		-- Buffer a legion.
		local legion = contains_legion(State.cursor_x, State.cursor_y, start_x, end_x, start_y, end_y)
		if legion ~= nil and legion["evil"] == false then
			local coords = {["x"]=State.cursor_x, ["y"]=State.cursor_y}
			State.buffered_entity = coords
			status_print = "Buffered: " .. legion.class .. "\n"
			coords=nil
		end

		legion=nil
	elseif ch == "m" then
		-- Flush buffered legion.
		local x = State.buffered_entity["x"]
		local y = State.buffered_entity["y"]
		local legion = contains_legion(x, y, start_x, end_x, start_y, end_y)
		if legion ~= nil then
			status_print = "Moved: " .. legion.class .. "\n"
			State.legions[State.cursor_y][State.cursor_x] = legion
			State.legions[y][x]=nil
		end
		legion=nil
	end
end

local function update_entity_position ()
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

	for i,c in ipairs(State.legions) do
		for j,d in ipairs(c) do
			local legion = contains_legion(j, i, start_x, end_x, start_y, end_y)
			if legion ~= nil then
				if d.target_y ~= nil and d.target_x ~= nil then
					State.legions[d.target_y][d.target_x] = legion
				end
				State.legions[i][j] = nil
			end
		end
	end
end

local function render_map ()
	os.execute("clear")
	local nums=""
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

	io.write("\n\n\n")
	for i=start_y,end_y do
		for j=start_x,end_x do
			local current = State.map[i][j]
			local render = Render[current]
			local legion = contains_legion(j, i, start_x, end_x, start_y, end_y)
			if j == start_x then
				io.write("\t\t\t")
			end
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

local function state_init (seed)
	-- potentially load save files in this function.
	-- load seeds and world changes.
	organic(seed)
end

local Zoom = require("render_zoomed")
local sleep = require("socket").sleep
local function frame (seed)
	local update_entity = coroutine.create(update_entity_position)
	local keyboard = coroutine.create(keyboard_handler)
	local render
	if State.zoom_mode == 1 then
		render = coroutine.create(render_map)
	elseif State.zoom_mode == -1 then
--		Zoom.init(State.zoom_fighting, State.zoom_opponent, State.zoom_terrain)
		Zoom.init(State)
		Zoom.organic(seed)
		render = coroutine.create(Zoom.render)
	end

	coroutine.resume(render)
	if coroutine.status(keyboard) ~= "dead" then
		coroutine.resume(keyboard)
	end
	if coroutine.status(update_entity) ~= "dead" then
		coroutine.resume(update_entity)
	end
end

local function main()
	local seed = 10
	state_init(seed)

	while State.code == 0 do
		frame(seed)
		sleep(0.01)
	end
	print(State.code)
end
main()
