const raylib = @import("raylib");

const zui = @import("lib.zig");

pub const TextButton = struct {
    const Self = @This();

    label: [:0]const u8,

    font: raylib.Font,
    font_size: f32,
    font_spacing: f32,
    font_idle_color: raylib.Color,
    font_hovered_color: raylib.Color,

    pub fn init(label: [:0]const u8, font: raylib.Font, font_size: f32, font_spacing: f32, font_idle_color: raylib.Color, font_hovered_color: raylib.Color) Self {
        return .{ .label = label, .font = font, .font_size = font_size, .font_spacing = font_spacing, .font_idle_color = font_idle_color, .font_hovered_color = font_hovered_color };
    }

    pub fn render(self: Self, orchestrator: *zui.Orchestrator, id: i32, coordinate: raylib.Vector2) bool {
        const label_size = raylib.measureTextEx(self.font, self.label, self.font_size, self.font_spacing);

        // is the button hovered?
        if (orchestrator.is_mouse_in(raylib.Rectangle{ .x = coordinate.x, .y = coordinate.y, .width = label_size.x, .height = label_size.y })) {
            orchestrator.set_hovered_item_id(id);

            // is the button focused?
            if (orchestrator.focus_item == 0 and orchestrator.mouse_down) {
                orchestrator.set_focus_item_id(id);
            }
        }

        if (orchestrator.hover_item == id) {
            self.draw(coordinate, orchestrator.origin_left_position, true);

            // is the mouse down and the button focused?
            if (orchestrator.mouse_down and orchestrator.focus_item == id) {
                return true;
            }
        } else {
            self.draw(coordinate, orchestrator.origin_left_position, false);
        }

        return false;
    }

    pub fn draw(self: Self, coordinate: raylib.Vector2, origin_left_position: raylib.Vector2, is_hovered: bool) void {
        if (is_hovered) {
            raylib.drawTextPro(self.font, self.label, coordinate, origin_left_position, 0, self.font_size, self.font_spacing, self.font_hovered_color);
        } else {
            raylib.drawTextPro(self.font, self.label, coordinate, origin_left_position, 0, self.font_size, self.font_spacing, self.font_idle_color);
        }
    }
};
