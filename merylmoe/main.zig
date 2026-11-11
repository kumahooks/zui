//! The main function of the application.

const std = @import("std");

const raylib = @import("raylib");
const zui = @import("zui");

const constants = @import("constants.zig");

pub fn main() !void {
    raylib.setConfigFlags(constants.raylib_config_flags);
    raylib.setTargetFPS(constants.raylib_target_fps);

    raylib.initWindow(constants.window_width, constants.window_height, constants.window_title);
    defer raylib.closeWindow();

    // Loads the embedded font and, if it fails, falls back to raylib's default font.
    const font = raylib.loadFontFromMemory(".ttf", constants.font_embed, constants.font_size, null) catch |err| font: {
        std.log.warn("[merylmoe:main] embedded font load failed: {s}, falling back to the default font", .{@errorName(err)});
        break :font try raylib.getFontDefault();
    };
    defer raylib.unloadFont(font);
    std.debug.assert(font.texture.id != 0);
    std.debug.assert(font.baseSize > 0);

    var orchestrator: zui.Orchestrator = .{};
    const theme: zui.theme.Theme = zui.theme.default(font);

    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();
        raylib.clearBackground(theme.palette.background);

        // main window page.
        const page: raylib.Rectangle = .{
            .x = 0,
            .y = 0,
            .width = @as(f32, @floatFromInt(raylib.getScreenWidth())),
            .height = @as(f32, @floatFromInt(raylib.getScreenHeight())),
        };
        orchestrator.update_start(page);

        // main window header.
        const header_width: [1]zui.layout.SlotWidth = .{
            .fill,
        };
        orchestrator.declare_layout_row(&header_width, constants.header_height);
        const header_rectangle: raylib.Rectangle = orchestrator.next_layout(&theme.layout);
        zui.header.render(header_rectangle, &theme, .{ .title = constants.window_title });

        // body content after the header.
        const page_padding: f32 = constants.page_padding;
        const content: raylib.Rectangle = .{
            .x = page.x + page_padding,
            .y = page.y + constants.header_height + page_padding,
            .width = @max(0, page.width - page_padding * 2),
            .height = @max(0, page.height - constants.header_height - page_padding * 2),
        };
        orchestrator.push_layout(content);

        // test buttons.
        const test_slot_widths: [3]zui.layout.SlotWidth = .{
            .{ .exact = 100 },
            .{ .exact = 100 },
            .{ .exact = 100 },
        };
        orchestrator.declare_layout_row(&test_slot_widths, theme.typography.size);

        const test_labels: [3][:0]const u8 = .{ "-", "O", "X" };
        for (test_labels) |label| {
            const rectangle: raylib.Rectangle = orchestrator.next_layout(&theme.layout);
            _ = zui.button.render(&orchestrator, label, rectangle, &theme, .{});
        }

        orchestrator.pop_layout();

        orchestrator.update_finish();

        raylib.endDrawing();
    }
}
