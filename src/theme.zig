const std = @import("std");

const raylib = @import("raylib");

pub const Typography = struct {
    font: raylib.Font,
    size: f32,
    spacing: f32,
};

const default_typography_spacing: f32 = 1;

comptime {
    std.debug.assert(default_typography_spacing >= 0);
}

pub const Layout = struct {
    widget_size: raylib.Vector2,
    widget_spacing: f32,
};

const default_layout: Layout = .{
    .widget_size = .{ .x = 160, .y = 28 },
    .widget_spacing = 8,
};

comptime {
    std.debug.assert(default_layout.widget_size.x > 0);
    std.debug.assert(default_layout.widget_size.y > 0);
    std.debug.assert(default_layout.widget_spacing >= 0);
}

pub const Palette = struct {
    background: raylib.Color,
    background_header: raylib.Color,

    text: raylib.Color,
    text_hovered: raylib.Color,
    text_active: raylib.Color,

    border: raylib.Color,
};

const default_palette: Palette = .{
    .background = .{ .r = 0, .g = 0, .b = 0, .a = 255 },
    .background_header = .{ .r = 13, .g = 13, .b = 13, .a = 255 },

    .text = .{ .r = 184, .g = 92, .b = 131, .a = 255 },
    .text_hovered = .{ .r = 184, .g = 192, .b = 131, .a = 255 },
    .text_active = .{ .r = 230, .g = 130, .b = 170, .a = 255 },

    .border = .{ .r = 96, .g = 96, .b = 96, .a = 255 },
};

pub const Theme = struct {
    typography: Typography,
    layout: Layout,
    palette: Palette,
};

pub fn default(font: raylib.Font) Theme {
    std.debug.assert(font.texture.id != 0);
    std.debug.assert(font.baseSize > 0);

    return .{
        .typography = .{
            .font = font,
            .size = @floatFromInt(font.baseSize),
            .spacing = default_typography_spacing,
        },
        .layout = default_layout,
        .palette = default_palette,
    };
}
