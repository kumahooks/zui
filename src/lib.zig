const std = @import("std");

const raylib = @import("raylib");

pub const button = @import("button.zig");

/// An item identity, derived from given bytes.
pub const Id = u64;
/// The value hover and active hold when no item owns them.
pub const id_none: Id = 0;
/// Seed for root-level items.
const id_root_seed: Id = std.math.maxInt(Id);
/// Fixed length of the widget identity stack.
const id_stack_capacity: u8 = 32;

comptime {
    std.debug.assert(id_root_seed != id_none);
    std.debug.assert(id_stack_capacity > 0);
}

/// Defines styles for each widget.
pub const Style = struct {
    font: raylib.Font,
    font_size: f32,
    font_spacing: f32,
    font_idle_color: raylib.Color,
    font_hovered_color: raylib.Color,
    font_active_color: raylib.Color,
};

/// Defines types of actions on widgets.
pub const WidgetResult = struct {
    /// A click action happened (raylib.isMouseButtonReleased).
    clicked: bool = false,
    /// A hold action happened (raylib.isMouseButtonDown).
    held: bool = false,
};

/// The hover and active ownership of one item.
pub const ItemState = struct {
    /// The item owns the mouse pointer hovering over it.
    hovered: bool,
    /// The item owns the mouse press until it releases.
    active: bool,
};

pub const Orchestrator = struct {
    const Self = @This();

    /// Widget identity scopes.
    id_stack: [id_stack_capacity]Id = @splat(id_none),
    id_stack_length: u8 = 0,
    /// Item owning hover, or `id_none`. Written only by `update_item`.
    hover_item_id: Id = id_none,
    /// Item owning the current press, or `id_none`. Written by `update_item` and cleared by `update_finish`.
    active_item_id: Id = id_none,

    mouse_position: raylib.Vector2 = .{ .x = 0, .y = 0 },
    mouse_press: bool = false,
    mouse_hold: bool = false,
    mouse_release: bool = false,

    origin_left_position: raylib.Vector2 = .{ .x = 0, .y = 0 },

    pub fn init(origin_left_position: raylib.Vector2) Self {
        std.debug.assert(std.math.isFinite(origin_left_position.x));
        std.debug.assert(std.math.isFinite(origin_left_position.y));

        return .{
            .origin_left_position = origin_left_position,
        };
    }

    /// Begins a frame, gathering input.
    ///
    /// Every `push_id` ran between this call and `update_finish` must have an equivalent `pop_id`.
    pub fn update_start(self: *Self) void {
        std.debug.assert(self.id_stack_length == 0);

        self.mouse_position = raylib.getMousePosition();
        self.mouse_press = raylib.isMouseButtonPressed(raylib.MouseButton.left);
        self.mouse_hold = raylib.isMouseButtonDown(raylib.MouseButton.left);
        self.mouse_release = raylib.isMouseButtonReleased(raylib.MouseButton.left);
    }

    /// Ends a frame, releasing the active item once the mouse is up.
    pub fn update_finish(self: *Self) void {
        std.debug.assert(self.id_stack_length == 0);

        if (self.mouse_hold) return;

        self.active_item_id = id_none;
    }

    /// Updates hover and active ownership for the item occupying `rectangle`, and reports what the item now owns.
    ///
    /// Must run after `update_start` and before `update_finish`, within a widget renderer.
    pub fn update_item(self: *Self, rectangle: raylib.Rectangle, id: Id) ItemState {
        std.debug.assert(id != id_none);
        std.debug.assert(rectangle.x >= 0);
        std.debug.assert(rectangle.y >= 0);
        std.debug.assert(rectangle.width >= 0);
        std.debug.assert(rectangle.height >= 0);
        std.debug.assert(std.math.isFinite(rectangle.x));
        std.debug.assert(std.math.isFinite(rectangle.y));

        const is_mouse_pointer_inside: bool = self.is_mouse_in(rectangle);

        // hover is owned: while an action is held it stays with the item while the pointer is above it.
        if (is_mouse_pointer_inside and !self.mouse_hold) {
            self.hover_item_id = id;
        } else {
            if (!is_mouse_pointer_inside and self.hover_item_id == id) {
                // only the owner of the hover clears it.
                self.hover_item_id = id_none;
            }
        }

        // the area where the press happened claims the item under the pointer as active.
        if (self.mouse_press and is_mouse_pointer_inside) {
            self.active_item_id = id;
        }

        return .{
            .hovered = self.hover_item_id == id,
            .active = self.active_item_id == id,
        };
    }

    /// Returns whether `mouse_position` is within `rectangle`.
    ///
    /// `rectangle` must be finite with a non-negative width and height.
    pub fn is_mouse_in(self: *const Self, rectangle: raylib.Rectangle) bool {
        std.debug.assert(std.math.isFinite(self.mouse_position.x));
        std.debug.assert(std.math.isFinite(self.mouse_position.y));
        std.debug.assert(rectangle.x >= 0);
        std.debug.assert(rectangle.y >= 0);
        std.debug.assert(rectangle.width >= 0);
        std.debug.assert(rectangle.height >= 0);
        std.debug.assert(std.math.isFinite(rectangle.x));
        std.debug.assert(std.math.isFinite(rectangle.y));

        if (self.mouse_position.x >= rectangle.x and self.mouse_position.x < rectangle.x + rectangle.width) {
            if (self.mouse_position.y >= rectangle.y and self.mouse_position.y < rectangle.y + rectangle.height) {
                return true;
            }
        }

        return false;
    }

    /// Returns the identity for `bytes` in the current scope. Identical bytes (in the same scope) always result the same ID.
    pub fn get_id(self: *const Self, bytes: []const u8) Id {
        std.debug.assert(self.id_stack_length <= self.id_stack.len);

        const id: Id = std.hash.Wyhash.hash(self.get_current_scope_id(), bytes);
        if (id == id_none) return id_none + 1;

        return id;
    }

    /// Pushes a child scope for `bytes`.
    ///
    /// It's necessary to use this to disambiguate widgets with identical labels within the same scope.
    pub fn push_id(self: *Self, bytes: []const u8) void {
        std.debug.assert(self.id_stack_length < self.id_stack.len);

        const id: Id = self.get_id(bytes);
        std.debug.assert(id != id_none);

        self.id_stack[self.id_stack_length] = id;
        self.id_stack_length += 1;
    }

    /// Pops the innermost scope, while asserting that one is open.
    ///
    /// Every call must be matched by a previously called `push_id`, and before `update_finish`.
    pub fn pop_id(self: *Self) void {
        std.debug.assert(self.id_stack_length > 0);

        self.id_stack[self.id_stack_length - 1] = id_none;
        self.id_stack_length -= 1;
    }

    fn get_current_scope_id(self: *const Self) Id {
        std.debug.assert(self.id_stack_length <= self.id_stack.len);

        if (self.id_stack_length > 0) {
            const id: Id = self.id_stack[self.id_stack_length - 1];
            std.debug.assert(id != id_none);

            return id;
        }

        return id_root_seed;
    }
};

test "Orchestrator.id_stack scopes correctly" {
    var orchestrator: Orchestrator = Orchestrator.init(raylib.Vector2{ .x = 0, .y = 0 });
    try std.testing.expectEqual(0, orchestrator.id_stack_length);

    const owo_id: Id = orchestrator.get_id("owo");

    orchestrator.push_id("owo");
    try std.testing.expectEqual(1, orchestrator.id_stack_length);
    try std.testing.expectEqual(owo_id, orchestrator.get_current_scope_id());
    try std.testing.expect(owo_id != orchestrator.get_id("owo"));

    const x_1: Id = orchestrator.get_id("x");
    orchestrator.push_id("uwu");
    const x_2: Id = orchestrator.get_id("x");
    orchestrator.push_id("ovo");
    try std.testing.expect(x_2 != orchestrator.get_id("x"));
    orchestrator.pop_id();
    try std.testing.expectEqual(x_2, orchestrator.get_id("x"));
    orchestrator.pop_id();
    try std.testing.expectEqual(x_1, orchestrator.get_id("x"));

    orchestrator.pop_id();
    try std.testing.expectEqual(0, orchestrator.id_stack_length);
    try std.testing.expectEqual(owo_id, orchestrator.get_id("owo"));
}

test "Orchestrator.is_mouse_in" {
    var orchestrator: Orchestrator = Orchestrator.init(raylib.Vector2{ .x = 0, .y = 0 });
    const rectangle: raylib.Rectangle = .{ .x = 10, .y = 10, .width = 10, .height = 10 };

    const cases = [_]struct {
        name: []const u8,
        position: raylib.Vector2,
        expect: bool,
    }{
        .{ .name = "inside", .position = .{ .x = 14, .y = 14 }, .expect = true },

        .{ .name = "top-left is inclusive", .position = .{ .x = 10, .y = 10 }, .expect = true },
        .{ .name = "outside of top-left from x", .position = .{ .x = 9, .y = 10 }, .expect = false },
        .{ .name = "outside of top-left from y", .position = .{ .x = 10, .y = 9 }, .expect = false },

        .{ .name = "bottom-left includes x, excludes y", .position = .{ .x = 10, .y = 19 }, .expect = true },
        .{ .name = "outside of bottom-left from y", .position = .{ .x = 10, .y = 20 }, .expect = false },

        .{ .name = "top-right excludes x, includes y", .position = .{ .x = 19, .y = 10 }, .expect = true },
        .{ .name = "outside of top-right from x", .position = .{ .x = 20, .y = 10 }, .expect = false },

        .{ .name = "bottom-right excludes x and y", .position = .{ .x = 19, .y = 19 }, .expect = true },
        .{ .name = "outside of bottom-right from x and y", .position = .{ .x = 20, .y = 20 }, .expect = false },
    };

    for (cases) |case| {
        orchestrator.mouse_position = case.position;

        std.testing.expectEqual(case.expect, orchestrator.is_mouse_in(rectangle)) catch |err| {
            std.testing.failPrint("case: {s} at ({d}, {d})\n", .{ case.name, case.position.x, case.position.y });
            return err;
        };
    }

    orchestrator.mouse_position = .{ .x = 10, .y = 15 };
    try std.testing.expectEqual(false, orchestrator.is_mouse_in(.{ .x = 10, .y = 10, .width = 0, .height = 10 }));
}

// TODO: finish tests
