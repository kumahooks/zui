const std = @import("std");

const raylib = @import("raylib");

pub const button = @import("button.zig");
pub const layout = @import("layout.zig");
pub const theme = @import("theme.zig");

/// An item identity, derived from given bytes.
pub const Id = u64;
/// The value hover and active hold when no item owns them.
pub const id_none: Id = 0;
/// Seed for root-level items.
const id_root_seed: Id = std.math.maxInt(Id);
/// Fixed length of the widget identity stack.
const id_stack_capacity: u8 = 32;

/// Fixed length of the layout stack.
const layout_stack_capacity: u8 = 32;

comptime {
    std.debug.assert(id_root_seed != id_none);
    std.debug.assert(id_stack_capacity > 0);
}

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

/// The mouse snapshot for one frame.
const MouseState = struct {
    const Self = @This();

    position: raylib.Vector2,
    press: bool,
    hold: bool,
    release: bool,

    fn update(self: *Self) void {
        self.position = raylib.getMousePosition();
        self.press = raylib.isMouseButtonPressed(raylib.MouseButton.left);
        self.hold = raylib.isMouseButtonDown(raylib.MouseButton.left);
        self.release = raylib.isMouseButtonReleased(raylib.MouseButton.left);
    }
};

pub const Orchestrator = struct {
    const Self = @This();

    /// Layout scopes.
    layout_stack: [layout_stack_capacity]layout.Layout = @splat(.{}),
    layout_stack_length: u8 = 0,

    /// Widget identity scopes.
    id_stack: [id_stack_capacity]Id = @splat(id_none),
    id_stack_length: u8 = 0,
    /// Item owning hover, or `id_none`. Written only by `update_item`.
    hover_item_id: Id = id_none,
    /// Item owning the current press, or `id_none`. Written by `update_item` and cleared by `update_finish`.
    active_item_id: Id = id_none,

    mouse_state: MouseState = .{
        .position = .{ .x = 0, .y = 0 },
        .press = false,
        .hold = false,
        .release = false,
    },

    /// Begins a frame, gathering input.
    ///
    /// Every `push_id` ran between this call and `update_finish` must have an equivalent `pop_id`.
    pub fn update_start(self: *Self, page: raylib.Rectangle) void {
        std.debug.assert(self.id_stack_length == 0);
        std.debug.assert(self.layout_stack_length == 0);
        std.debug.assert(std.math.isFinite(page.x));
        std.debug.assert(page.x >= 0);
        std.debug.assert(std.math.isFinite(page.y));
        std.debug.assert(page.y >= 0);
        std.debug.assert(std.math.isFinite(page.width));
        std.debug.assert(page.width >= 0);
        std.debug.assert(std.math.isFinite(page.height));
        std.debug.assert(page.height >= 0);

        // defines the app's root page layout, which represents the whole window screen.
        self.push_layout(page);

        self.mouse_state.update();
    }

    /// Ends a frame, releasing the active item once the mouse is up.
    pub fn update_finish(self: *Self) void {
        std.debug.assert(self.id_stack_length == 0);
        std.debug.assert(self.layout_stack_length == 1);

        self.layout_stack_length = 0;

        if (self.mouse_state.hold) return;

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
        if (is_mouse_pointer_inside and !self.mouse_state.hold) {
            self.hover_item_id = id;
        } else {
            if (!is_mouse_pointer_inside and self.hover_item_id == id) {
                // only the owner of the hover clears it.
                self.hover_item_id = id_none;
            }
        }

        // the area where the press happened claims the item under the pointer as active.
        if (self.mouse_state.press and is_mouse_pointer_inside) {
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
        std.debug.assert(std.math.isFinite(self.mouse_state.position.x));
        std.debug.assert(std.math.isFinite(self.mouse_state.position.y));
        std.debug.assert(rectangle.x >= 0);
        std.debug.assert(rectangle.y >= 0);
        std.debug.assert(rectangle.width >= 0);
        std.debug.assert(rectangle.height >= 0);
        std.debug.assert(std.math.isFinite(rectangle.x));
        std.debug.assert(std.math.isFinite(rectangle.y));

        if (self.mouse_state.position.x >= rectangle.x and self.mouse_state.position.x < rectangle.x + rectangle.width) {
            if (self.mouse_state.position.y >= rectangle.y and self.mouse_state.position.y < rectangle.y + rectangle.height) {
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

    /// Pushes a layout for `body_rectangle` and makes it the current one.
    ///
    /// The new layout starts with `.default` slot width and zero height. The next call for `next_layout` resolves it.
    /// `body_rectangle` represents the current screen coordinates.
    ///
    /// The layout stack is cleared by `update_finish`. Pushed layouts should be called between `update_start` and `update_finish`.
    pub fn push_layout(self: *Self, body_rectangle: raylib.Rectangle) void {
        std.debug.assert(std.math.isFinite(body_rectangle.x));
        std.debug.assert(std.math.isFinite(body_rectangle.y));
        std.debug.assert(std.math.isFinite(body_rectangle.width));
        std.debug.assert(std.math.isFinite(body_rectangle.height));
        std.debug.assert(body_rectangle.x >= 0);
        std.debug.assert(body_rectangle.y >= 0);
        std.debug.assert(body_rectangle.width >= 0);
        std.debug.assert(body_rectangle.height >= 0);
        std.debug.assert(self.layout_stack_length < layout_stack_capacity);

        var element: layout.Layout = .{};
        element.body_rectangle = body_rectangle;
        element.declare_row(&[1]layout.SlotWidth{.default}, 0);

        self.layout_stack[self.layout_stack_length] = element;
        self.layout_stack_length += 1;
    }

    pub fn pop_layout(self: *Self) void {
        std.debug.assert(self.layout_stack_length > 1); // root layout shouldn't be popped.

        self.layout_stack[self.layout_stack_length - 1] = .{};
        self.layout_stack_length -= 1;
    }

    /// Calculates and returns the next slot rectangle in screen coordinates.
    ///
    /// When the current row ended, it starts a new row below the lowest row with `start_row`.
    ///
    /// Always requires a layout pushed by `push_layout`.
    pub fn next_layout(self: *Self, layout_defaults: *const theme.Layout) raylib.Rectangle {
        std.debug.assert(std.math.isFinite(layout_defaults.widget_size.x));
        std.debug.assert(std.math.isFinite(layout_defaults.widget_size.y));
        std.debug.assert(layout_defaults.widget_size.x > 0);
        std.debug.assert(layout_defaults.widget_size.y > 0);
        std.debug.assert(std.math.isFinite(layout_defaults.widget_spacing));
        std.debug.assert(layout_defaults.widget_spacing >= 0);

        var current_layout: *layout.Layout = self.get_current_layout();
        var rectangle_result: raylib.Rectangle = .{ .x = 0, .y = 0, .width = 0, .height = 0 };

        // if every slot in the row has been used, start a new row below the last one.
        if (current_layout.slot_next == current_layout.slot_count) {
            current_layout.start_row();
        }

        // the slot starts at the body origin plus its local position. `x` is the current column, while `y` is the current row.
        rectangle_result.x = current_layout.body_rectangle.x + current_layout.slot_position.x;
        rectangle_result.y = current_layout.body_rectangle.y + current_layout.slot_position.y;

        // calculate the width of the current slot based on `slot_widths[slot_next]`.
        const width: f32 = switch (current_layout.slot_widths[current_layout.slot_next]) {
            .exact => |exact_width| exact_width,
            .fill => current_layout.body_rectangle.width - current_layout.slot_position.x,
            .default => layout_defaults.widget_size.x,
        };
        rectangle_result.width = width;

        // calculate the height of the new slot. it's either defined as `slot_height` or falls back to the layout defaults' `widget_size.y`.
        const height: f32 = if (current_layout.slot_height == 0) layout_defaults.widget_size.y else current_layout.slot_height;
        rectangle_result.height = height;

        // advance the `slot_next` index and `x` position based on the current one.
        current_layout.slot_next += 1;
        current_layout.slot_position.x += width + layout_defaults.widget_spacing;
        current_layout.next_row_y = @max(
            // keep the lowest point from the earlier rows.
            current_layout.next_row_y,
            // bottom of this row plus the gap before the next row.
            current_layout.slot_position.y + height + layout_defaults.widget_spacing,
        );

        return rectangle_result;
    }

    pub fn get_current_layout(self: *Self) *layout.Layout {
        std.debug.assert(self.layout_stack_length <= self.layout_stack.len);
        std.debug.assert(self.layout_stack_length > 0);

        return &self.layout_stack[self.layout_stack_length - 1];
    }

    pub fn declare_layout_row(self: *Self, slot_widths: []const layout.SlotWidth, slot_height: f32) void {
        return self.get_current_layout().declare_row(slot_widths, slot_height);
    }

    pub fn content_rectangle(self: *Self) raylib.Rectangle {
        std.debug.assert(self.layout_stack_length > 0);
        return self.layout_stack[self.layout_stack_length - 1].body_rectangle;
    }
};

test "Orchestrator.id_stack scopes correctly" {
    var orchestrator: Orchestrator = .{};

    try std.testing.expectEqual(0, orchestrator.id_stack_length);
    try std.testing.expectEqual(id_root_seed, orchestrator.get_current_scope_id());

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

test "Orchestrator scopes depend on parent id and label" {
    var orchestrator: Orchestrator = .{};

    // despite sharing the same label, under different parents, the ids are different.
    orchestrator.push_id("owo");
    orchestrator.push_id("lain");
    var first_lain: Id = orchestrator.get_current_scope_id();
    orchestrator.pop_id();
    orchestrator.pop_id();

    orchestrator.push_id("uwu");
    orchestrator.push_id("lain");
    var second_lain: Id = orchestrator.get_current_scope_id();
    orchestrator.pop_id();
    orchestrator.pop_id();

    try std.testing.expect(first_lain != second_lain);
    try std.testing.expectEqual(0, orchestrator.id_stack_length);

    // now, with the same parent, the ids are the same.
    orchestrator.push_id("owo");
    orchestrator.push_id("lain");
    first_lain = orchestrator.get_current_scope_id();
    orchestrator.pop_id();

    orchestrator.push_id("lain");
    second_lain = orchestrator.get_current_scope_id();
    orchestrator.pop_id();
    orchestrator.pop_id();

    try std.testing.expectEqual(first_lain, second_lain);
    try std.testing.expectEqual(0, orchestrator.id_stack_length);
}
