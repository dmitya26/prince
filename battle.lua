local Battle = {
	opponent_map={},
	opponent_leader={},

	fighting_map={},
	fighting_leader={},
}

-- Update all positions on the map to be closer to their vectors.
function Battle.step ()

end

function Battle.init (fighting_map, opponent_map)
	Battle.fighting_map = fighting_map
	Battle.fighting_leader = Battle.fighting_map[0]

	Battle.opponent_map = opponent_map
	Battle.opponent_leader = Battle.opponent_map[0]
end

-- States
-- 	Idle   - troops do not move, immediately goes to chase mode.
-- 	Chase  - troops follow the leader and the leader
-- 			 follows the opponent leader, when they merge battle begins.
-- 	Battle - individual soldiers break from following the leader
-- 			 and attack the closest enemy to them.
function Battle.idle (legion)
	-- Set all vectors to the current index. Movement stops.
	for i,c in ipairs(fighting_map) do
		for j,d in ipairs(c) do
			d["x"] = j
			d["y"] = i
		end
	end
	Battle.chase()

end

function Battle.chase (legion) do
	local modifications = 0
	local doneChasing = false
	while doneChasing == false do
		Battle.step()
	end
	if modifications == 0 then
		Battle.idle(legion)
	end
	Battle.battle()
end

function Battle.battle () do
	local doneBattling = false
	while doneBattling == false do
		Battle.step()
	end
	Battle.idle()
end

function Battle.battle_loop ()
	Battle.idle()
	Battle.chase()
	Battle.battle()
end

return Battle
