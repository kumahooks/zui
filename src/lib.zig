const std = @import("std");

const raylib = @import("raylib");

pub const button = @import("button.zig");

/// A widget identity, derived from given bytes.
pub const Id = u64;
/// The value hover and focus hold when nothing is active.
pub const id_none: Id = 0;
// Seed for root-level items.
const id_root_seed: Id = std.math.maxInt(i64);
// Placeholder used when an action begins outside of every widget.
const id_blocked: Id = std.math.maxInt(Id);

pub const Orchestrator = struct {
    const Self = @This();

    /// Widget scopes.
    id_stack: [32]Id = undefined,
    id_stack_length: usize = 0,
    /// Item under the mouse this frame, or `id_none`. Reset every `updateStart`.
    hover_item_id: Id = id_none,
    /// Item holding the current action, or `id_none`. Set as `id_blocked` when the action began outside every widget.
    focus_item_id: Id = id_none,

    mouse_position: raylib.Vector2 = .{ .x = 0, .y = 0 },
    mouse_down: bool = false,

    origin_left_position: raylib.Vector2,

    pub fn init(origin_left_position: raylib.Vector2) Self {
        return .{
            .origin_left_position = origin_left_position,
        };
    }

    /// Begins a frame, gathering input and clearing the hover ID.
    ///
    /// Every `pushId` ran between this call and `updateFinish` must have an equivalent `popId`.
    pub fn updateStart(self: *Self) void {
        if (self.id_stack_length != 0) {
            @panic("[zui:Orchestrator.updateStart] id_stack_length is not 0");
        }

        self.mouse_position = raylib.getMousePosition();
        self.mouse_down = raylib.isMouseButtonDown(raylib.MouseButton.left);
        self.hover_item_id = id_none;
    }

    /// Ends a frame, updating focus for the next frame.
    pub fn updateFinish(self: *Self) void {
        if (self.id_stack_length != 0) {
            @panic("[zui:Orchestrator.updateFinish] id_stack not cleared");
        }

        if (!self.mouse_down) {
            self.focus_item_id = id_none;
        } else if (self.focus_item_id == id_none) {
            // A press that began outside every widget must not focus if it is dragged over one widget while at it.
            self.focus_item_id = id_blocked;
        }
    }

    pub fn isMouseIn(self: *const Self, rectangle: raylib.Rectangle) bool {
        if (self.mouse_position.x >= rectangle.x and self.mouse_position.x < rectangle.x + rectangle.width) {
            if (self.mouse_position.y >= rectangle.y and self.mouse_position.y < rectangle.y + rectangle.height) {
                return true;
            }
        }

        return false;
    }

    pub fn setHoveredItemId(self: *Self, id: Id) void {
        self.hover_item_id = id;
    }

    pub fn setFocusItemId(self: *Self, id: Id) void {
        self.focus_item_id = id;
    }

    /// Returns the identity for `bytes` in the current scope. Identical bytes (in the same scope) always result the same ID.
    pub fn getId(self: *const Self, bytes: []const u8) Id {
        return std.hash.Wyhash.hash(self.getCurrentScopeId(), bytes);
    }

    /// Pushes a child scope for `bytes`.
    ///
    /// It's necessary to use this to disambuigate widgets with identical labels within the same scope.
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
