local Render = {
	["WATER"]   = string.char(27) .. "[94m@"  .. string.char(27) .. "[0m", -- Water.
	["TREE"]    = string.char(27) .. "[32m♠"  .. string.char(27) .. "[0m", -- Tree.
	["GRASS"]   = string.char(27) .. "[92m%"  .. string.char(27) .. "[0m", -- Grass.
	["STONE"]   = string.char(27) .. "[37m&"  .. string.char(27) .. "[0m", -- Stone.

	["GUARD"]   = string.char(27) .. "[1;31mG" .. string.char(27) .. "[0m",  -- Guard Legion.
	["STALKER"] = string.char(27) .. "[1;38;5;201mS"   .. string.char(27) .. "[0m",  -- Stalker Legion.
	["DWARF"]   = string.char(27) .. "[1;1mD"   .. string.char(27) .. "[0m",  -- Stalker Legion.

	["VAMPIRE"]    = string.char(27) .. "[41;30mV" .. string.char(27) .. "[0m", -- Vampire Legion.
	["FOMORIAN"]   = string.char(27) .. "[43;30mF"  .. string.char(27) .. "[0m",
	["LIZARDFOLK"] = string.char(27) .. "[42;30mL" .. string.char(27) .. "[0m",
}

local Module = {
	map_x = 80,
	map_y = 30,

	legions = {},
--	opponent_legion = {},
	terrain="",

	map    = {},
	squads = {},
}

function Module.init (State)
	Module.legions=State.zoom_legions
--	Module.opponent_legion=State.legions[State.opponent_fighting["y"]][State.opponent_fighting["x"]]
	Module.terrain=State.zoom_terrain
end

function Module.organic(seed)
	local firstlayer
	local secondlayer

	if Module.terrain == "TREE" then
		firstlayer = "TREE"
		secondlayer = "WATER"
	elseif Module.terrain == "GRASS" then
		firstlayer = "GRASS"
		secondlayer = "WATER"
	elseif Module.terrain == "STONE" then
		firstlayer = "STONE"
		secondlayer = "GRASS"
	elseif Module.terrain == "WATER" then
		firstlayer = "WATER"
	end

	math.randomseed(seed)
	for i=1,Module.map_y do
		Module.map[i]={}
		for j=1,Module.map_x do
			Module.map[i][j] = firstlayer
		end
	end

	if secondlayer ~= nil then
		for i=1,Module.map_y do
			for j=1,Module.map_x do
				local direction = math.random(1, 10)
				if direction == 1 then -- left
					if j-1 >= 1 then
						Module.map[i][j-1] = secondlayer
					end
				elseif direction == 2 then -- up
					if i-1 >= 1 then
						Module.map[i-1][j] = secondlayer
					end
				elseif direction == 3 then -- right
					if j+1 <= #Module.map[i] then
						Module.map[i][j+1] = secondlayer
					end
				elseif direction == 4 then -- down
					if i+1 <= #Module.map then
						Module.map[i+1][j] = secondlayer
					end
				end
			end
		end
	end

end

function Module.render ()
	os.execute("clear")
	for i,c in ipairs(Module.map) do
		for j,d in ipairs(c) do
			local render = Render[d]
			local fighting = Module.fighting_legion.zoom_map[i][j]

			if fighting == 1 then
				io.write(Render[Module.fighting_legion["class"]])
			elseif render ~= nil then
				io.write(render)
			end
			fighting=0
		end
		io.write("\n")
	end
end

return Module
