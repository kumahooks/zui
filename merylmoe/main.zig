//! The main function of the application.

const raylib = @import("raylib");

const button = @import("button.zig");
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

    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();

        const window_width = raylib.getRenderWidth();

        raylib.clearBackground(consts.color_opaque_bg);

        // header drawing:
        // draws the header bottom line.
        raylib.drawLine(0, consts.header_height, window_width, consts.header_height, consts.color_brand);
        // draws the header title.
        _ = drawTextFromLeft(consts.window_title, consts.header_horizontal_padding, 0, font);
        // draws the header action buttons.
        const header_actions = [_][:0]const u8{ "X", "O", "_" };
        var right_edge = @as(f32, @floatFromInt(raylib.getRenderWidth())) - consts.header_horizontal_padding;
        for (header_actions) |label| {
            const width = raylib.measureTextEx(font, label, consts.font_size, consts.font_spacing).x;
            raylib.drawTextPro(font, label, .{ .x = right_edge - width, .y = 0 }, consts.position_origin_left, 0, consts.font_size, consts.font_spacing, consts.color_brand);
            right_edge -= width + consts.header_horizontal_padding;
        }

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

// fn drawTextButton(text: [:0]const u8, font: raylib.Font) void {
//
// }
//
// fn drawHeaderButtons(font: raylib.Font) void {
//     const x_width = drawTextFromRight("X", 10, 0, font);
//     _ = drawTextFromRight("_", 10 * 2 + x_width, 0, font);
// }
