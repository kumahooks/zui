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

    // TODO: styling a button is out of scope for now... but should it really be initiated like this?
    // need to think better about this and how other widgets will be expressed later.
    pub fn init(label: [:0]const u8, font: raylib.Font, font_size: f32, font_spacing: f32, font_idle_color: raylib.Color, font_hovered_color: raylib.Color) Self {
        return .{
            .label = label,
            .font = font,
            .font_size = font_size,
            .font_spacing = font_spacing,
            .font_idle_color = font_idle_color,
            .font_hovered_color = font_hovered_color,
        };
    }

    // TODO: differ from hold and click eventually.
    pub fn render(self: Self, orchestrator: *zui.Orchestrator, coordinate: raylib.Vector2) bool {
        const label_size = raylib.measureTextEx(self.font, self.label, self.font_size, self.font_spacing);
        const id = orchestrator.getId(self.label);

        // is the button hovered?
        const is_mouse_in = orchestrator.isMouseIn(raylib.Rectangle{
            .x = coordinate.x,
            .y = coordinate.y,
            .width = label_size.x,
            .height = label_size.y,
        });
        if (is_mouse_in) {
            orchestrator.setHoveredItemId(id);

            // is the button focused?
            if (orchestrator.focus_item_id == zui.id_none and orchestrator.mouse_down) {
                orchestrator.setFocusItemId(id);
            }
        }

        if (orchestrator.hover_item_id == id) {
            self.draw(coordinate, orchestrator.origin_left_position, true);

            // is the mouse down and the button focused?
            if (orchestrator.mouse_down and orchestrator.focus_item_id == id) {
                return true;
            }
        } else {
            self.draw(coordinate, orchestrator.origin_left_position, false);
        }

        return false;
    }

    pub fn draw(self: Self, coordinate: raylib.Vector2, origin_left_position: raylib.Vector2, is_hovered: bool) void {
        if (is_hovered) {
            raylib.drawTextPro(
                self.font,
                self.label,
                coordinate,
                origin_left_position,
                0,
                self.font_size,
                self.font_spacing,
                self.font_hovered_color,
            );
        } else {
            raylib.drawTextPro(
                self.font,
                self.label,
                coordinate,
                origin_left_position,
                0,
                self.font_size,
                self.font_spacing,
                self.font_idle_color,
            );
        }
    }
};
