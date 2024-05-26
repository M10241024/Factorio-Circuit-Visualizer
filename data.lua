
local NAMESPACE = "cv_"

local visualize_network = {
    type = "custom-input",
    name = NAMESPACE .. "visualize_network",
    key_sequence = "V",
    enabled_while_spectating = true,
    action = "lua",
}
local toggle_overlay = {
    type = "shortcut",
    name = NAMESPACE .. "toggle_overlay",
    toggleable = true,
    icon = {
        filename = "__circuit_visualizer__/graphics/toggle_overlay.png",
        size = 64,
        flags = {"icon"},
    },
    action = "lua",
}
local toggle_mouseover = {
    type = "shortcut",
    name = NAMESPACE .. "toggle_mouseover",
    toggleable = true,
    icon = {
        filename = "__circuit_visualizer__/graphics/toggle_mouseover.png",
        size = 64,
        flags = {"icon"},
    },
    action = "lua",
}
local toggle_whole_network = {
    type = "shortcut",
    name = NAMESPACE .. "toggle_whole_network",
    toggleable = true,
    icon = {
        filename = "__circuit_visualizer__/graphics/toggle_whole_network.png",
        size = 64,
        flags = {"icon"},
    },
    action = "lua",
}
local hide_all = {
    type = "shortcut",
    name = NAMESPACE .. "hide_all",
    toggleable = true,
    icon = {
        filename = "__circuit_visualizer__/graphics/hide_all.png",
        size = 64,
        flags = {"icon"},
    },
    action = "lua",
}
local reload_all = {
    type = "shortcut",
    name = NAMESPACE .. "reload_all",
    toggleable = true,
    icon = {
        filename = "__circuit_visualizer__/graphics/reload_all.png",
        size = 96,
        flags = {"icon"},
    },
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
