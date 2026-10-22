//! The main layout consts of the application.

const raylib = @import("raylib");

pub const raylib_config_flags = raylib.ConfigFlags{ .window_resizable = true, .window_transparent = true };
pub const raylib_target_fps = 144;
pub const window_width = 600;
pub const window_height = 600;
pub const window_title = "meryl.moe";

pub const font_embed = @embedFile("assets/0xProtoNerdFont-Regular.ttf");
pub const font_size = 32;
pub const font_spacing = 1;

pub const position_origin_left = raylib.Vector2{ .x = 0, .y = 0 };

pub const header_horizontal_padding = 10;
