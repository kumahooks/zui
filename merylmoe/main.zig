//! The main function of the application.

const std = @import("std");

const raylib = @import("raylib");
const zui = @import("zui");

const consts = @import("consts.zig");

pub fn main() !void {
    raylib.setConfigFlags(consts.raylib_config_flags);
    raylib.setTargetFPS(consts.raylib_target_fps);

    raylib.initWindow(consts.window_width, consts.window_height, consts.window_title);
    defer raylib.closeWindow();

    // loads custom font and if it fails fallbacks to default.
    const font = raylib.loadFontFromMemory(".ttf", consts.font_embed, 32, null) catch font: {
        const default_font = raylib.getFontDefault() catch @panic("default font unavailable");
        break :font default_font;
    };

    const default_style: zui.Style = .{
        .font = font,
        .font_size = 32,
        .font_spacing = 1,
        .font_idle_color = raylib.Color{ .r = 184, .g = 92, .b = 131, .a = 255 },
        .font_hovered_color = raylib.Color{ .r = 184, .g = 192, .b = 131, .a = 255 },
        .font_active_color = raylib.Color{ .r = 230, .g = 130, .b = 170, .a = 255 },
    };
    var orchestrator: zui.Orchestrator = zui.Orchestrator.init(raylib.Vector2{ .x = 0, .y = 0 });

    // TODO: temp debug.
    var clicks: u32 = 0;

    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();
        raylib.clearBackground(raylib.Color{ .r = 0, .g = 0, .b = 0, .a = 212 });

        orchestrator.updateStart();

        // TODO: temp debug.
        var coordinates_buffer: [64]u8 = undefined;
        const coordinate: [:0]u8 = try std.mem.printSentinel(
            &coordinates_buffer,
            "{d:.0}, {d:.0}",
            .{
                orchestrator.mouse_position.x,
                orchestrator.mouse_position.y,
            },
            0,
        );
        _ = drawTextFromLeft(coordinate, consts.header_horizontal_padding, 0, font);

        // TODO: temp debug.
        const button_result = zui.button.render(&orchestrator, "owo", default_style, raylib.Vector2{ .x = 250, .y = 250 });
        if (button_result.clicked) {
            clicks += 1;
        }
        if (button_result.held) {
            _ = drawTextFromLeft("held", 250, 300, font);
        }

        // TODO: temp debug.
        var clicks_counter_buffer: [32]u8 = undefined;
        const counter: [:0]u8 = try std.mem.printSentinel(&clicks_counter_buffer, "clicks: {d}", .{clicks}, 0);
        _ = drawTextFromLeft(counter, 250, 330, font);

        orchestrator.updateFinish();

        raylib.endDrawing();
    }
}

// drawTextFromLeft draws text from left origin position + margin_left.
// returns the drawn text size.
// TODO: temporary, this will be its own text control later.
fn drawTextFromLeft(text: [:0]const u8, margin_left: f32, y: f32, font: raylib.Font) f32 {
    raylib.drawTextPro(
        font,
        text,
        .{ .x = margin_left, .y = y },
        consts.position_origin_left,
        0,
        consts.font_size,
        consts.font_spacing,
        raylib.Color{ .r = 184, .g = 92, .b = 131, .a = 255 },
    );

    return raylib.measureTextEx(font, text, consts.font_size, consts.font_spacing).x;
}

// drawTextFromRight draws text from right origin position + margin_right + text size.
// returns the drawn text size.
// TODO: temporary, this will be its own text control later.
fn drawTextFromRight(text: [:0]const u8, margin_right: f32, y: f32, font: raylib.Font) f32 {
    const text_size_vector = raylib.measureTextEx(font, text, consts.font_size, consts.font_spacing);
    const right_edge = @as(f32, @floatFromInt(raylib.getRenderWidth()));
    const x = right_edge - text_size_vector.x - margin_right;

    raylib.drawTextPro(
        font,
        text,
        .{ .x = x, .y = y },
        consts.position_origin_left,
        0,
        consts.font_size,
        consts.font_spacing,
        raylib.Color{ .r = 184, .g = 92, .b = 131, .a = 255 },
    );

    return text_size_vector.x;
}
