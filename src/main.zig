//! The main function of the application.

const raygui = @import("raygui");
const raylib = @import("raylib");

const consts = @import("consts.zig");

pub fn main() !void {
    raylib.setConfigFlags(consts.raylib_config_flags);
    raylib.setTargetFPS(consts.raylib_target_fps);

    raylib.initWindow(consts.window_width, consts.window_height, consts.window_title);

    const font = raylib.loadFontFromMemory(".ttf", consts.font_embed, 32, null) catch font: {
        const default_font = raylib.getFontDefault() catch @panic("default font unavailable");
        break :font default_font;
    };

    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();

        raylib.clearBackground(consts.color_opaque_bg);

        raylib.drawLine(0, 25, raylib.getRenderWidth(), 25, consts.color_brand);
        raylib.drawTextPro(font, consts.window_title, consts.position_window_title, consts.position_origin, 0, consts.font_size, 1, consts.color_brand);

        raylib.endDrawing();
    }

    raylib.closeWindow();
}
