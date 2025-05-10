Render = { -- idk how I feel about this table. code smell... works for now though.
	["WATER"]  = string.char(27) .. "[94m@"  .. string.char(27) .. "[0m", -- Water.
	["TREE"]   = string.char(27) .. "[32m♠"  .. string.char(27) .. "[0m", -- Tree.
	["GRASS"]  = string.char(27) .. "[92m%"  .. string.char(27) .. "[0m", -- Grass.
	["STONE"]  = string.char(27) .. "[37m&"  .. string.char(27) .. "[0m", -- Stone.
	["CURSOR"] = string.char(27) .. "[1;31m*" .. string.char(27) .. "[0m", -- Cursor.
	["GUARD"]  = string.char(27) .. "[1;31mG" .. string.char(27) .. "[0m",  -- Guard Legion.
--	["GUARD"]  = string.char(27) .. "[33mG"   .. string.char(27) .. "[0m",  -- Guard Legion.
}

Legion = {
	class="", -- Can be dwarf, stalker, or guard.
	amount=1000000,
	health=0, -- change as needed.
	damage=0, -- change as needed.

	location_x=0,
	location_y=0,

	target_x=nil,
	target_y=nil,
}

State = {
	cursor_x=1,
	cursor_y=1,

	map_x = 100,
	map_y = 100,

	-- basically this is for sliding window.
	cursor_window_radius_y = 20,
	cursor_window_radius_x = 41,

	buffered_entity=nil,

	legions={},

	turn=true, -- true=player false=opponent

	--[[
	-- water 1
	-- tree  2
	-- grass 3
	-- stone 4
	--]]
	map={},

	code=0, -- continue, -1 error, 1 exit.
}

status_print=""

function table.clone(org)
	local u = { }
	for k, v in ipairs(org) do u[k] = v end
	return setmetatable(u, getmetatable(org))
end

function contains_legion (x, y)
	for i,c in ipairs(State.legions) do
		if c.location_x == x and c.location_y == y then
			return c
		else
			return nil
		end
	end
	return nil
end

function organic (seed)
	math.randomseed(seed)
	-- layer1, grass
	for i=1,State.map_y do
-- 		print(i)
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

	-- layer4, stone, entities.
	for i,c in ipairs(State.map) do
		for j,d in ipairs(c) do
			local random=math.random(1,10)
			if random==1 then
				State.map[i][j]="STONE"
			elseif random==2 then
--				local Legion = {
--					class="GUARD", -- Can be dwarf, stalker, or guard.
--					amount=1000000,
--					health=100, -- change as needed.
--					damage=100, -- change as needed.
--
--					location_x=math.random(1, State.map_x),
--					location_y=math.random(1, State.map_y),
--
--					target_x=nil,
--					target_y=nil,
--				}
--				l = table.clone(Legion)
--				l.class="GUARD"
--				l.location_x = math.random(1, State.map_x)
--				l.location_y = math.random(1, State.map_y)
				table.insert(State.legions, {
					class="GUARD", -- Can be dwarf, stalker, or guard.
					amount=1000000,
					health=100, -- change as needed.
					damage=100, -- change as needed.

					location_x=math.random(1, State.map_x),
					location_y=math.random(1, State.map_y),

					target_x=nil,
					target_y=nil,
				})
			end
		end
	end
end

-- A boolean is returned for whether the input counts as a turn.
function keyboard_handler ()
--	io.write("Input > ")
	local ch = io.read(1)
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
		legion = contains_legion(State.cursor_x, State.cursor_y)
		if legion ~= nil then
			State.buffered_entity = legion
		end
		if State.buffered_entity ~= nil then
			status_print = "Buffered: " .. State.buffered_entity.class .. "\n"
		end
		return false
	elseif ch == "m" then
		-- Flush buffered legion.
		local legion = State.buffered_entity
		if legion ~= nil then
			status_print = "Moved: " .. State.buffered_entity.class .. "\n"
			legion.target_x=State.cursor_x
			legion.target_y=State.cursor_y
			State.buffered_entity=nil
		end
		return true
	end
end

function update_entity_position ()
	for i,c in ipairs(State.legions) do
		if c.target_x ~= nil and c.target_y ~= nil then
			c.location_x = c.target_x
			c.location_y = c.target_y
		end
	end
end

function render_map ()
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
			local legion = contains_legion(j, i)
			if i == State.cursor_y and j == State.cursor_x then
				io.write(Render["CURSOR"])
			elseif legion ~= nil then
				io.write(Render[legion.class])
			elseif render ~= nil then
				io.write(render)
			end
		end
		io.write("\n")
	end
	io.write(status_print)

end

function state_init ()
	-- potentially load save files in this function.
	-- load seeds and world changes.
	organic(10)
end

function frame ()
	if keyboard_handler() then
		State.turn = not State.turn
	end
	update_entity_position()
	render_map()
end

function main()
	state_init()
	while State.code == 0 do
		frame()
	end
	print(State.code)
end
main()
