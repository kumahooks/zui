const std = @import("std");

const raylib = @import("raylib");

pub const button = @import("button.zig");

/// An item identity, derived from given bytes.
pub const Id = u64;
/// The value hover and active hold when no item owns them.
pub const id_none: Id = 0;
// Seed for root-level items.
const id_root_seed: Id = std.math.maxInt(i64);

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

    /// Identity scopes.
    id_stack: [32]Id = undefined,
    id_stack_length: usize = 0,
    /// Item owning hover, or `id_none`. Written only by `updateItem`.
    hover_item_id: Id = id_none,
    /// Item owning the current press, or `id_none`. Written by `updateItem` and cleared by `updateFinish`.
    active_item_id: Id = id_none,

    mouse_position: raylib.Vector2 = .{ .x = 0, .y = 0 },
    mouse_press: bool = false,
    mouse_hold: bool = false,
    mouse_release: bool = false,

    origin_left_position: raylib.Vector2 = .{ .x = 0, .y = 0 },

    pub fn init(origin_left_position: raylib.Vector2) Self {
        return .{
            .origin_left_position = origin_left_position,
        };
    }

    /// Begins a frame, gathering input.
    ///
    /// Every `pushId` ran between this call and `updateFinish` must have an equivalent `popId`.
    pub fn updateStart(self: *Self) void {
        if (self.id_stack_length != 0) {
            @panic("[zui:Orchestrator.updateStart] id_stack_length is not 0");
        }

        self.mouse_position = raylib.getMousePosition();
        self.mouse_press = raylib.isMouseButtonPressed(raylib.MouseButton.left);
        self.mouse_hold = raylib.isMouseButtonDown(raylib.MouseButton.left);
        self.mouse_release = raylib.isMouseButtonReleased(raylib.MouseButton.left);
    }

    /// Ends a frame, releasing the active item once the mouse is up.
    pub fn updateFinish(self: *Self) void {
        if (self.id_stack_length != 0) {
            @panic("[zui:Orchestrator.updateFinish] id_stack not cleared");
        }

        if (!self.mouse_hold) {
            self.active_item_id = id_none;
        }
    }

    /// Updates hover and active ownership for the item occupying `rectangle`, and reports what the item now owns.
    ///
    /// Must run after `updateStart` and before `updateFinish`, within a widget renderer.
    pub fn updateItem(self: *Self, rectangle: raylib.Rectangle, id: Id) ItemState {
        const is_mouse_in: bool = self.isMouseIn(rectangle);

        // hover is owned: while an action is held it stays with the item while the pointer is above it.
        if (is_mouse_in and !self.mouse_hold) {
            self.hover_item_id = id;
        } else if (!is_mouse_in and self.hover_item_id == id) {
            // only the owner of the hover clears it.
            self.hover_item_id = id_none;
        }

        // the area where the press happened claims the item under the pointer as active.
        if (self.mouse_press and is_mouse_in) {
            self.active_item_id = id;
        }

        return .{
            .hovered = self.hover_item_id == id,
            .active = self.active_item_id == id,
        };
    }

    pub fn isMouseIn(self: *const Self, rectangle: raylib.Rectangle) bool {
        if (self.mouse_position.x >= rectangle.x and self.mouse_position.x < rectangle.x + rectangle.width) {
            if (self.mouse_position.y >= rectangle.y and self.mouse_position.y < rectangle.y + rectangle.height) {
                return true;
            }
        }

        return false;
    }

    /// Returns the identity for `bytes` in the current scope. Identical bytes (in the same scope) always result the same ID.
    pub fn getId(self: *const Self, bytes: []const u8) Id {
        return std.hash.Wyhash.hash(self.getCurrentScopeId(), bytes);
    }

    /// Pushes a child scope for `bytes`.
    ///
    /// It's necessary to use this to disambiguate widgets with identical labels within the same scope.
    pub fn pushId(self: *Self, bytes: []const u8) void {
        if (self.id_stack_length == self.id_stack.len) {
            @panic("[zui:Orchestrator.pushId] id_stack depth exceeded");
        }

        const id: Id = self.getId(bytes);
        self.id_stack[self.id_stack_length] = id;
        self.id_stack_length += 1;
    }

    /// Pops the innermost scope, while panicking if none is open.
    ///
    /// Every call must be matched by a previously called `pushId`, and before `updateFinish`.
    pub fn popId(self: *Self) void {
        if (self.id_stack_length == 0) {
            @panic("[zui:Orchestrator.popId] id_stack is empty");
        }

        self.id_stack_length -= 1;
    }

    fn getCurrentScopeId(self: *const Self) Id {
        if (self.id_stack_length > 0) {
            return self.id_stack[self.id_stack_length - 1];
        }

        return id_root_seed;
    }
};

test "zui: id_stack scopes correctly" {
    var orchestrator: Orchestrator = Orchestrator.init(raylib.Vector2{ .x = 0, .y = 0 });
    try std.testing.expectEqual(0, orchestrator.id_stack_length);

    const owo_id: Id = orchestrator.getId("owo");

    orchestrator.pushId("owo");
    try std.testing.expectEqual(1, orchestrator.id_stack_length);
    try std.testing.expectEqual(owo_id, orchestrator.getCurrentScopeId());
    try std.testing.expect(owo_id != orchestrator.getId("owo"));

    const x_1: Id = orchestrator.getId("x");
    orchestrator.pushId("uwu");
    const x_2: Id = orchestrator.getId("x");
    orchestrator.pushId("ovo");
    try std.testing.expect(x_2 != orchestrator.getId("x"));
    orchestrator.popId();
    try std.testing.expectEqual(x_2, orchestrator.getId("x"));
    orchestrator.popId();
    try std.testing.expectEqual(x_1, orchestrator.getId("x"));

    orchestrator.popId();
    try std.testing.expectEqual(0, orchestrator.id_stack_length);
    try std.testing.expectEqual(owo_id, orchestrator.getId("owo"));
}

test "zui: isMouseIn" {
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

        std.testing.expectEqual(case.expect, orchestrator.isMouseIn(rectangle)) catch |err| {
            std.testing.failPrint("case: {s} at ({d}, {d})\n", .{ case.name, case.position.x, case.position.y });
            return err;
        };
    }

    orchestrator.mouse_position = .{ .x = 10, .y = 15 };
    try std.testing.expectEqual(false, orchestrator.isMouseIn(.{ .x = 10, .y = 10, .width = 0, .height = 10 }));

    orchestrator.mouse_position = .{ .x = 0, .y = 15 };
    try std.testing.expectEqual(false, orchestrator.isMouseIn(.{ .x = 10, .y = 10, .width = -10, .height = 10 }));
}
