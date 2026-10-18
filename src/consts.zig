//! The main layout consts of the application.

const raylib = @import("raylib");

pub const raylib_config_flags = raylib.ConfigFlags{ .window_resizable = true, .window_transparent = true };
pub const raylib_target_fps = 144;
pub const window_width = 600;
pub const window_height = 600;
pub const window_title = "meryl.moe";

pub const font_embed = @embedFile("assets/3270NerdFont-Regular.ttf");

pub const color_brand = raylib.Color{ .r = 184, .g = 92, .b = 131, .a = 255 };
pub const color_opaque_bg = raylib.Color{ .r = 0, .g = 0, .b = 0, .a = 188 };

pub const font_size = 24;

pub const position_origin = raylib.Vector2{ .x = 0, .y = 0 };
pub const position_window_title = raylib.Vector2{ .x = 10, .y = 2 };
