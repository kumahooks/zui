const raylib = @import("raylib");

pub const Button = @import("button.zig");

pub const Orchestrator = struct {
    const Self = @This();

    font: raylib.Font,

    origin_left_position: raylib.Vector2,
    mouse_position: raylib.Vector2,

    hot_item: i32,
    active_item: i32,

    pub fn init(font: raylib.Font, origin_left_position: raylib.Vector2) Self {
        return .{ .font = font, .origin_left_position = origin_left_position, .mouse_position = raylib.getMousePosition(), .hot_item = 0, .active_item = 0 };
    }

    pub fn update(self: *Self) void {
        self.mouse_position = raylib.getMousePosition();
        self.hot_item = 0;
    }

    pub fn is_mouse_in(self: Self, rectangle: raylib.Rectangle) bool {
        if (self.mouse_position.x >= rectangle.x and self.mouse_position.x <= rectangle.x + rectangle.width) {
            if (self.mouse_position.y >= rectangle.y and self.mouse_position.y <= rectangle.y + rectangle.height) {
                return true;
            }
        }

        return false;
    }

    pub fn set_hot_item_id(self: *Self, id: i32) void {
        self.hot_item = id;
    }

    pub fn set_active_item_id(self: *Self, id: i32) void {
        self.active_item = id;
    }
};
