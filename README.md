A mod similar to [Pipe Visualizer](https://mods.factorio.com/mod/PipeVisualizer) but for circuit networks.

# Visualize all networks
Use a shortcut to visualize all circuit connections.
Visualization appears around the selected entity so it should work with radars.

# Visualize selected networks
Select a connected entity and press `V` to visualize a network.
Press `V` again to hide it.

# Visualize hovered networks
Use a shortcut to visualize hovered networks.
Also useful for updating bugged entities by hovering them.

# Whole network mode
With whole network mode on the `V` key and mouse-over visualization will spread over all connected networks eg. trough combinators. I reccomend having it always on.

![Whole network mode off](https://github.com/M10241024/Factorio-Circuit-Visualizer/blob/main/screenshots/whole_network_mode_off.png)
![Whole network mode on](https://github.com/M10241024/Factorio-Circuit-Visualizer/blob/main/screenshots/visualization_on.png)

# Bugs
The visualization updates when:
- an entity is destroyed.
- a player connects or disconnects two entities.

It does not update when:
- a blueprint with circuit connections is placed.
- any other case.
If you see a bugged entity you can use the mouse-over visualization and hover it to update, or just use the "reload all" shortcut.

# Network colors
You can change the colors of red and green networks is settings.

![Whole network mode off](https://github.com/M10241024/Factorio-Circuit-Visualizer/blob/main/screenshots/alternative_colors.png)

There is an extra option to randomise the darknes per network to help differentiate networks crossing eachother. It's not very good.

![Whole network mode off](https://github.com/M10241024/Factorio-Circuit-Visualizer/blob/main/screenshots/random_darkness.png)

# Extra settings, commands and shortcuts
You can change the color of both networks in settings.
You can change the overlay opacity in settings.
There is a shortcut to hide all networks.
There is a command `/circuit_visualizer_hide_networks` that works the same as the shortcut and `/circuit_visualizer_hide_networks all` that hides all networks for all players.

# Compatibility
[UPS-friendly Selector combinator](https://mods.factorio.com/mod/selector-combinator) and [Crafting Combinator](https://mods.factorio.com/mod/crafting_combinator) do work, but look a little bit weird.
I haven't tested other mods but the results should be similar.

# Ugly icons
I can't draw so the shortcut icons are horrible. If someone wants to make better icons, please do.

# Credits
[raiguard](https://mods.factorio.com/user/raiguard) for creating the [Pipe Visualizer](https://mods.factorio.com/mod/PipeVisualizer).

The Factorio wiki for the mod tutorial.
