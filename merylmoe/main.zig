//! The main function of the application.

const std = @import("std");

const raylib = @import("raylib");
const zui = @import("zui");

const constants = @import("constants.zig");

const background_color: raylib.Color = .{ .r = 0, .g = 0, .b = 0, .a = 212 };
const idle_color: raylib.Color = .{ .r = 184, .g = 92, .b = 131, .a = 255 };
const hovered_color: raylib.Color = .{ .r = 184, .g = 192, .b = 131, .a = 255 };
const active_color: raylib.Color = .{ .r = 230, .g = 130, .b = 170, .a = 255 };
const border_color: raylib.Color = .{ .r = 96, .g = 96, .b = 96, .a = 255 };

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

        .widget_spacing = 8,
        .widget_size = .{ .x = 160, .y = 28 },
        .border_color = border_color,
    };
    var orchestrator: zui.Orchestrator = zui.Orchestrator.init(.{ .x = 0, .y = 0 });

    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();
        raylib.clearBackground(background_color);

        // main window page.
        const page: raylib.Rectangle = .{
            .x = 0,
            .y = 0,
            .width = @as(f32, @floatFromInt(raylib.getScreenWidth())),
            .height = @as(f32, @floatFromInt(raylib.getScreenHeight())),
        };
        orchestrator.update_start(page);

        const spacing: f32 = default_style.widget_spacing;
        const content: raylib.Rectangle = .{
            .x = page.x + spacing,
            .y = page.y + spacing,
            .width = @max(0, page.width - spacing * 2),
            .height = @max(0, page.height - spacing * 2),
        };
        orchestrator.push_layout(content);

        const header_buttons_widths: [3]zui.layout.SlotWidth = .{
            .{ .exact = 100 },
            .{ .exact = 100 },
            .{ .exact = 100 },
        };
        orchestrator.declare_layout_row(&header_buttons_widths, default_style.font_size);
        const header_buttons_labels: [3][:0]const u8 = .{ "-", "O", "X" };
        for (header_buttons_labels) |label| {
            const rectangle: raylib.Rectangle = orchestrator.next_layout(&default_style);
            _ = zui.button.render(&orchestrator, label, &default_style, rectangle);
        }

        orchestrator.pop_layout();

        orchestrator.update_finish();

        raylib.endDrawing();
    }
}
