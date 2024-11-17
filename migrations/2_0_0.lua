
local ControlScript = require("__circuit_visualizer__/control")

for player_id, _ in pairs(storage) do
    local player = game.get_player(player_id)
    if player then
        ControlScript.update_all_entities(player)
    end
end
