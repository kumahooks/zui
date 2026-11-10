const std = @import("std");

const raylib = @import("raylib");

/// Maximum slots in one row.
const slot_width_capacity: u8 = 32;

comptime {
    std.debug.assert(slot_width_capacity > 0);
}

pub const SlotWidth = union(enum) {
    /// Exactly this many pixels.
    exact: f32,

    /// From the last slot position to the body's right edge.
    fill,

    /// The default widget width.
    default,
};

pub const Layout = struct {
    const Self = @This();

    /// The content body this layout draws into.
    body_rectangle: raylib.Rectangle = .{ .x = 0, .y = 0, .height = 0, .width = 0 },

    /// Local position of where the next slot starts. While slots are built, only x advances.
    slot_position: raylib.Vector2 = .{ .x = 0, .y = 0 },

    /// Declared dimensions of each slot within the current row.
    slot_widths: [slot_width_capacity]SlotWidth = @splat(.default),
    slot_height: f32 = 0,
    slot_count: u8 = 0,
    slot_next: u8 = 0,

    /// Local y of where the next row starts.
    next_row_y: f32 = 0,

    /// Declares a row, starting it at `next_row_y`.
    pub fn declare_row(self: *Self, slot_widths: []const SlotWidth, slot_height: f32) void {
        std.debug.assert(slot_widths.len <= slot_width_capacity);
        std.debug.assert(slot_widths.len > 0);
        std.debug.assert(std.math.isFinite(slot_height));
        std.debug.assert(slot_height >= 0);

        @memcpy(self.slot_widths[0..slot_widths.len], slot_widths);
        self.slot_count = @intCast(slot_widths.len);
        self.slot_height = slot_height;
        self.start_row();
    }

    /// Starts a row at its left edge, at `next_row_y`.
    pub fn start_row(self: *Self) void {
        std.debug.assert(self.slot_count > 0);

        self.slot_next = 0;
        self.slot_position = .{ .x = 0, .y = self.next_row_y };
    }
};
