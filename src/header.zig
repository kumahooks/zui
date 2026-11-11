const std = @import("std");

const raylib = @import("raylib");

const zui = @import("root.zig");

pub const Options = struct {
    title: ?[:0]const u8 = null,
    title_padding: ?f32 = null,
    title_color: ?raylib.Color = null,

    background_color: ?raylib.Color = null,
};

const defaults = struct {
    const title_padding: f32 = 8;
};

pub fn render(
    rectangle: raylib.Rectangle,
    theme: *const zui.theme.Theme,
    options: Options,
) void {
    std.debug.assert(std.math.isFinite(rectangle.x));
    std.debug.assert(rectangle.x >= 0);
    std.debug.assert(std.math.isFinite(rectangle.y));
    std.debug.assert(rectangle.y >= 0);
    std.debug.assert(std.math.isFinite(rectangle.width));
    std.debug.assert(rectangle.width >= 0);
    std.debug.assert(std.math.isFinite(rectangle.height));
    std.debug.assert(rectangle.height > 0);

    const background_color: raylib.Color = options.background_color orelse theme.palette.background_header;
    raylib.drawRectangleRec(rectangle, background_color);

    if (options.title) |title| {
        const title_padding: f32 = options.title_padding orelse defaults.title_padding;
        std.debug.assert(std.math.isFinite(title_padding));
        std.debug.assert(title_padding >= 0);

        const title_rectangle: raylib.Rectangle = .{
            .x = rectangle.x + title_padding,
            .y = rectangle.y,
            .width = @max(0, rectangle.width - title_padding * 2),
            .height = rectangle.height,
        };

        zui.text.render(title, title_rectangle, theme, .{ .color = options.title_color, .alignment = .left });
    }
}

// TODO: implement tests
