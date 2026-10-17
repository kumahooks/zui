//! The main function of the application.

const raygui = @import("raygui");
const raylib = @import("raylib");

pub fn main() !void {
    raylib.initWindow(600, 600, "Calenduwu");
    raylib.setTargetFPS(60);

    var button_clicked: bool = false;
    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();

        const background: i32 = raygui.getStyle(.default, .background_color);
        raylib.clearBackground(raylib.getColor(@bitCast(background)));

        if (raygui.button(raylib.Rectangle.init(24, 24, 120, 30), "owo")) {
            button_clicked = true;
        }

        if (button_clicked) {
            var button_active: i32 = -1;

            _ = raygui.messageBox(raylib.Rectangle.init(85, 70, 250, 100), "owo", "uwu", "ovo?", &button_active);

            if (button_active >= 0) {
                button_clicked = false;
            }
        }

        raylib.endDrawing();
    }

    raylib.closeWindow();
}
