//! The main layout constants of the application.

const std = @import("std");

const raylib = @import("raylib");

pub const raylib_config_flags: raylib.ConfigFlags = .{ .window_resizable = true, .window_transparent = true };
pub const raylib_target_fps: i32 = 144;
pub const window_width: i32 = 600;
pub const window_height: i32 = 600;
pub const window_title: [:0]const u8 = "meryl.moe";

pub const font_embed: []const u8 = @embedFile("assets/0xProtoNerdFont-Regular.ttf");
pub const font_size: f32 = 32;
pub const font_spacing: f32 = 1;

pub const position_origin_left: raylib.Vector2 = .{ .x = 0, .y = 0 };

pub const header_horizontal_padding: f32 = 10;
pub const header_vertical_padding: f32 = 0;

comptime {
    std.debug.assert(window_width > 0);
    std.debug.assert(window_height > 0);
    std.debug.assert(raylib_target_fps > 0);
    std.debug.assert(window_title.len > 0);
    std.debug.assert(font_embed.len > 0);
    std.debug.assert(font_size > 0);
    std.debug.assert(font_spacing >= 0);
    std.debug.assert(header_horizontal_padding >= 0);
    std.debug.assert(header_vertical_padding >= 0);
}
