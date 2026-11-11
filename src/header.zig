const std = @import("std");

const raylib = @import("raylib");

const zui = @import("root.zig");

pub const Options = struct {
    background_color: ?raylib.Color = null,
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
}

// TODO: implement tests
