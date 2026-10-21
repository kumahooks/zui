//! The main function of the application.

const std = @import("std");

const raylib = @import("raylib");
const zui = @import("zui");

const consts = @import("consts.zig");

pub fn main() !void {
    raylib.setConfigFlags(consts.raylib_config_flags);
    raylib.setTargetFPS(consts.raylib_target_fps);

    raylib.initWindow(consts.window_width, consts.window_height, consts.window_title);

    // loads custom font and if it fails fallbacks to default.
    const font = raylib.loadFontFromMemory(".ttf", consts.font_embed, 32, null) catch font: {
        const default_font = raylib.getFontDefault() catch @panic("default font unavailable");
        break :font default_font;
    };

    var orchestrator: zui.Orchestrator = zui.Orchestrator.init(raylib.Vector2{ .x = 0, .y = 0 });

    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();
        raylib.clearBackground(consts.color_opaque_bg);

        orchestrator.update_start();

        var buffer: [64]u8 = undefined;
        const coordinate: [:0]u8 = try std.mem.printSentinel(&buffer, "{d:.0}, {d:.0}", .{ orchestrator.mouse_position.x, orchestrator.mouse_position.y }, 0);
        _ = drawTextFromLeft(coordinate, consts.header_horizontal_padding, 0, font);

        const button = zui.Button.TextButton.init("owo", font, consts.font_size, consts.font_spacing, consts.color_brand, consts.color_brand_hovered);
        if (button.render(&orchestrator, 1, raylib.Vector2{ .x = 250, .y = 250 })) {
            _ = drawTextFromLeft("hold", 250, 300, font);
        }

        orchestrator.update_finish();

        raylib.endDrawing();
    }

    raylib.closeWindow();
}

// drawTextFromLeft draws text from left origin position + margin_left.
// returns the drawn text size.
fn drawTextFromLeft(text: [:0]const u8, margin_left: f32, y: f32, font: raylib.Font) f32 {
    raylib.drawTextPro(font, text, .{ .x = margin_left, .y = y }, consts.position_origin_left, 0, consts.font_size, consts.font_spacing, consts.color_brand);

    return raylib.measureTextEx(font, text, consts.font_size, consts.font_spacing).x;
}

// drawTextFromRight draws text from right origin position + margin_right + text size.
// returns the drawn text size.
fn drawTextFromRight(text: [:0]const u8, margin_right: f32, y: f32, font: raylib.Font) f32 {
    const text_size_vector = raylib.measureTextEx(font, text, consts.font_size, consts.font_spacing);
    const right_edge = @as(f32, @floatFromInt(raylib.getRenderWidth()));
    const x = right_edge - text_size_vector.x - margin_right;

    raylib.drawTextPro(font, text, .{ .x = x, .y = y }, consts.position_origin_left, 0, consts.font_size, consts.font_spacing, consts.color_brand);

    return text_size_vector.x;
}
