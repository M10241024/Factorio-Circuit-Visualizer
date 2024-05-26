
local NAMESPACE = "cv_"

local overlay_opacity = {
    name = NAMESPACE .. "overlay_opacity",
    type = "double-setting",
    setting_type = "runtime-per-user",
    default_value = 1,
    minimum_value = 0,
    maximum_value = 1,
    order = "0",
}
local red_network_color = {
    name = NAMESPACE .. "red_network_color",
    type = "color-setting",
    setting_type = "runtime-per-user",
    default_value = {1, 0, 0},
    order = "1",
}
local green_network_color = {
    name = NAMESPACE .. "green_network_color",
    type = "color-setting",
    setting_type = "runtime-per-user",
    default_value = {0, 1, 0},
    order = "2",
}
local max_brightness_change = {
    name = NAMESPACE .. "max_brightness_change",
    type = "double-setting",
    setting_type = "runtime-per-user",
    default_value = 0,
    minimum_value = 0,
    maximum_value = 1,
    order = "3",
}

data:extend({
    overlay_opacity,
    red_network_color,
    green_network_color,
    max_brightness_change,
})
