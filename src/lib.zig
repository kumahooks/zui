const raylib = @import("raylib");

pub const Button = @import("button.zig");

pub const Orchestrator = struct {
    const Self = @This();

    origin_left_position: raylib.Vector2,
    mouse_position: raylib.Vector2,
    mouse_down: bool,

    hover_item: i32,
    focus_item: i32,

    pub fn init(origin_left_position: raylib.Vector2) Self {
        return .{
            .origin_left_position = origin_left_position,
            .mouse_position = raylib.getMousePosition(),
            .mouse_down = false,
            .hover_item = 0,
            .focus_item = 0,
        };
    }

    pub fn update_start(self: *Self) void {
        self.mouse_position = raylib.getMousePosition();
        self.mouse_down = raylib.isMouseButtonDown(raylib.MouseButton.left);
        self.hover_item = 0;
    }

    pub fn update_finish(self: *Self) void {
        if (!self.mouse_down) {
            // if mouse isn't down, clear the focused item.
            self.focus_item = 0;
        } else {
            // if the mouse is down but there's no focused item, set the focus to a sentinel so entering an item does not trigger it's focus.
            if (self.focus_item == 0) {
                self.focus_item = -1;
            }
        }
    }

    pub fn is_mouse_in(self: Self, rectangle: raylib.Rectangle) bool {
        if (self.mouse_position.x >= rectangle.x and self.mouse_position.x < rectangle.x + rectangle.width) {
            if (self.mouse_position.y >= rectangle.y and self.mouse_position.y < rectangle.y + rectangle.height) {
                return true;
            }
        }

        return false;
    }

    pub fn set_hovered_item_id(self: *Self, id: i32) void {
        self.hover_item = id;
    }

    pub fn set_focus_item_id(self: *Self, id: i32) void {
        self.focus_item = id;
    }
};
