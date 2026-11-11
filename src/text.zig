const std = @import("std");

const raylib = @import("raylib");

const zui = @import("root.zig");

pub const Alignment = enum { left, center, right };

pub const Options = struct {
    font_size: ?f32 = null,
    font_spacing: ?f32 = null,

    color: ?raylib.Color = null,
    alignment: Alignment = .left,
};

pub fn render(
    text: [:0]const u8,
    rectangle: raylib.Rectangle,
    theme: *const zui.theme.Theme,
    options: Options,
) void {
    std.debug.assert(theme.typography.font.texture.id != 0);
    std.debug.assert(theme.typography.font.baseSize > 0);
    std.debug.assert(std.math.isFinite(rectangle.x));
    std.debug.assert(rectangle.x >= 0);
    std.debug.assert(std.math.isFinite(rectangle.y));
    std.debug.assert(rectangle.y >= 0);
    std.debug.assert(std.math.isFinite(rectangle.width));
    std.debug.assert(rectangle.width >= 0);
    std.debug.assert(std.math.isFinite(rectangle.height));
    std.debug.assert(rectangle.height >= 0);

    const font_size: f32 = options.font_size orelse theme.typography.size;
    const font_spacing: f32 = options.font_spacing orelse theme.typography.spacing;
    const text_color: raylib.Color = options.color orelse theme.palette.text;

    std.debug.assert(std.math.isFinite(font_size));
    std.debug.assert(font_size > 0);
    std.debug.assert(std.math.isFinite(font_spacing));
    std.debug.assert(font_spacing >= 0);

    // TODO: `raylib.measureTextEx` could become expensive eventually, probably needs to be improved at some point.
    const text_size: raylib.Vector2 = raylib.measureTextEx(theme.typography.font, text, font_size, font_spacing);
    const text_x: f32 = switch (options.alignment) {
        .left => rectangle.x,
        .center => rectangle.x + (rectangle.width - text_size.x) / 2,
        .right => rectangle.x + rectangle.width - text_size.x,
    };
    const text_y: f32 = rectangle.y + (rectangle.height - text_size.y) / 2;

    raylib.drawTextEx(theme.typography.font, text, .{ .x = text_x, .y = text_y }, font_size, font_spacing, text_color);
}
