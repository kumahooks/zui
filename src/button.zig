const raylib = @import("raylib");

const zui = @import("lib.zig");

pub const TextButton = struct {
    const Self = @This();

    label: [:0]const u8,
    label_size: raylib.Vector2,

    font: raylib.Font,
    font_size: f32,
    font_spacing: f32,
    font_idle_color: raylib.Color,
    font_hot_color: raylib.Color,

    pub fn init(label: [:0]const u8, font: raylib.Font, font_size: f32, font_spacing: f32, font_idle_color: raylib.Color, font_hot_color: raylib.Color) Self {
        const label_size = raylib.measureTextEx(font, label, font_size, font_spacing);

        return .{ .label = label, .label_size = label_size, .font = font, .font_size = font_size, .font_spacing = font_spacing, .font_idle_color = font_idle_color, .font_hot_color = font_hot_color };
    }

    pub fn render(self: Self, orchestrator: *zui.Orchestrator, id: i32, coordinate: raylib.Vector2) bool {
        if (orchestrator.is_mouse_in(raylib.Rectangle{ .x = coordinate.x, .y = coordinate.y, .width = self.label_size.x, .height = self.label_size.y })) {
            orchestrator.set_hot_item_id(id);
            self.draw(coordinate, orchestrator.origin_left_position, true);
        } else {
            self.draw(coordinate, orchestrator.origin_left_position, false);
        }

        return false;
    }

    pub fn draw(self: Self, coordinate: raylib.Vector2, origin_left_position: raylib.Vector2, is_hot: bool) void {
        if (is_hot) {
            raylib.drawTextPro(self.font, self.label, coordinate, origin_left_position, 0, self.font_size, self.font_spacing, self.font_hot_color);
        } else {
            raylib.drawTextPro(self.font, self.label, coordinate, origin_left_position, 0, self.font_size, self.font_spacing, self.font_idle_color);
        }
    }
};
