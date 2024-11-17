
local NAMESPACE = "circuit_visualizer_"

local visualize_network = {
    type = "custom-input",
    name = NAMESPACE .. "visualize_network",
    key_sequence = "ALT + V",
    enabled_while_spectating = true,
    action = "lua",
}
local toggle_overlay = {
    type = "shortcut",
    name = NAMESPACE .. "toggle_overlay",
    toggleable = true,
    icon = "__circuit_visualizer__/graphics/toggle_overlay.png",
    icon_size = 64,
    small_icon = "__circuit_visualizer__/graphics/toggle_overlay.png",
    small_icon_size = 64,
    action = "lua",
}
local toggle_mouseover = {
    type = "shortcut",
    name = NAMESPACE .. "toggle_mouseover",
    toggleable = true,
    icon = "__circuit_visualizer__/graphics/toggle_mouseover.png",
    icon_size = 64,
    small_icon = "__circuit_visualizer__/graphics/toggle_mouseover.png",
    smal_icon_size = 64,
    action = "lua",
}
local toggle_whole_network = {
    type = "shortcut",
    name = NAMESPACE .. "toggle_whole_network",
    toggleable = true,
    icon = "__circuit_visualizer__/graphics/toggle_whole_network.png",
    icon_size = 64,
    small_icon = "__circuit_visualizer__/graphics/toggle_whole_network.png",
    small_icon_size = 64,
    action = "lua",
}
local hide_all = {
    type = "shortcut",
    name = NAMESPACE .. "hide_all",
    toggleable = true,
    icon = "__circuit_visualizer__/graphics/hide_all.png",
    icon_size = 64,
    small_icon = "__circuit_visualizer__/graphics/hide_all.png",
    small_icon_size = 64,
    action = "lua",
}
local reload_all = {
    type = "shortcut",
    name = NAMESPACE .. "reload_all",
    toggleable = true,
    icon = "__circuit_visualizer__/graphics/reload_all.png",
    icon_size = 96,
    small_icon = "__circuit_visualizer__/graphics/reload_all.png",
    small_icon_size = 96,
    action = "lua",
}

data:extend({
    visualize_network,
    toggle_overlay,
    toggle_mouseover,
    toggle_whole_network,
    hide_all,
    reload_all,
})
