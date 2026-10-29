//! The main function of the application.

const std = @import("std");

const raylib = @import("raylib");
const zui = @import("zui");

const constants = @import("constants.zig");

const background_color: raylib.Color = .{ .r = 0, .g = 0, .b = 0, .a = 212 };
const idle_color: raylib.Color = .{ .r = 184, .g = 92, .b = 131, .a = 255 };
const hovered_color: raylib.Color = .{ .r = 184, .g = 192, .b = 131, .a = 255 };
const active_color: raylib.Color = .{ .r = 230, .g = 130, .b = 170, .a = 255 };

pub fn main() !void {
    raylib.setConfigFlags(constants.raylib_config_flags);
    raylib.setTargetFPS(constants.raylib_target_fps);

    raylib.initWindow(constants.window_width, constants.window_height, constants.window_title);
    defer raylib.closeWindow();

    // Loads the embedded font and, if it fals, fallsback to raylib's default font.
    const font = raylib.loadFontFromMemory(".ttf", constants.font_embed, constants.font_size, null) catch |err| font: {
        std.log.warn("[merylmoe:main] embedded font load failed: {s}, falling back to the default font", .{@errorName(err)});
        break :font try raylib.getFontDefault();
    };
    defer raylib.unloadFont(font);
    std.debug.assert(font.texture.id != 0);

    const default_style: zui.Style = .{
        .font = font,
        .font_size = constants.font_size,
        .font_spacing = constants.font_spacing,
        .font_idle_color = idle_color,
        .font_hovered_color = hovered_color,
        .font_active_color = active_color,
    };
    var orchestrator: zui.Orchestrator = zui.Orchestrator.init(.{ .x = 0, .y = 0 });

    // TODO: remove temp debug.
    var clicks: u64 = 0;

    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();
        raylib.clearBackground(background_color);

        orchestrator.update_start();

        // TODO: remove temp debug.
        const coordinate_buffer_capacity: u8 = 64;
        var coordinates_buffer: [coordinate_buffer_capacity]u8 = @splat(0);
        const coordinate: [:0]u8 = try std.mem.printSentinel(
            &coordinates_buffer,
            "{d:.0}, {d:.0}",
            .{ orchestrator.mouse_position.x, orchestrator.mouse_position.y },
            0,
        );
        draw_text_from_left(coordinate, .{ .x = constants.header_horizontal_padding, .y = constants.header_vertical_padding }, &font);

        // TODO: remove temp debug.
        const button_position: raylib.Vector2 = .{ .x = 250, .y = 250 };
        const debug_held_position: raylib.Vector2 = .{ .x = 250, .y = 300 };
        const debug_clicks_position: raylib.Vector2 = .{ .x = 250, .y = 330 };

        const button_result = zui.button.render(&orchestrator, "owo", &default_style, button_position);
        if (button_result.clicked) clicks += 1;
        if (button_result.held) draw_text_from_left("held", debug_held_position, &font);

        // TODO: remove temp debug.
        const counter_buffer_capacity: u8 = 32;
        var clicks_counter_buffer: [counter_buffer_capacity]u8 = @splat(0);
        const counter: [:0]u8 = try std.mem.printSentinel(&clicks_counter_buffer, "clicks: {d}", .{clicks}, 0);
        draw_text_from_left(counter, debug_clicks_position, &font);

        orchestrator.update_finish();

        raylib.endDrawing();
    }
}

// draw_text_from_left draws text from the left origin position at `coordinate`.
// TODO: temporary, this will be its own text widget later.
fn draw_text_from_left(text: [:0]const u8, coordinate: raylib.Vector2, font: *const raylib.Font) void {
    std.debug.assert(std.math.isFinite(coordinate.x));
    std.debug.assert(std.math.isFinite(coordinate.y));
    std.debug.assert(font.texture.id != 0);

    raylib.drawTextPro(
        font.*,
        text,
        coordinate,
        constants.position_origin_left,
        0,
        constants.font_size,
        constants.font_spacing,
        idle_color,
    );
}
