const std = @import("std");

const raylib = @import("raylib");
const zui = @import("zui");

test "Orchestrator.get_id derives different ids for different bytes" {
    var orchestrator: zui.Orchestrator = zui.Orchestrator.init(raylib.Vector2{ .x = 0, .y = 0 });

    try std.testing.expect(orchestrator.get_id("alpha") != orchestrator.get_id("beta"));
    try std.testing.expect(orchestrator.get_id("") != zui.id_none);
}

test "Orchestrator.push_id fills the stack then Orchestrator.pop_id clears it" {
    var orchestrator: zui.Orchestrator = zui.Orchestrator.init(raylib.Vector2{ .x = 0, .y = 0 });
    const capacity: u8 = @intCast(orchestrator.id_stack.len);

    while (orchestrator.id_stack_length < capacity) {
        orchestrator.push_id("lain");
    }

    try std.testing.expectEqual(capacity, orchestrator.id_stack_length);
    for (orchestrator.id_stack) |slot| {
        try std.testing.expect(slot != zui.id_none);
    }

    while (orchestrator.id_stack_length > 0) {
        orchestrator.pop_id();
    }

    try std.testing.expectEqual(0, orchestrator.id_stack_length);
    for (orchestrator.id_stack) |slot| {
        try std.testing.expectEqual(zui.id_none, slot);
    }
}

test "Orchestrator.is_mouse_in" {
    var orchestrator: zui.Orchestrator = zui.Orchestrator.init(raylib.Vector2{ .x = 0, .y = 0 });
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
        orchestrator.mouse_state.position = case.position;

        std.testing.expectEqual(case.expect, orchestrator.is_mouse_in(rectangle)) catch |err| {
            std.testing.failPrint("case: {s} at ({d}, {d})\n", .{ case.name, case.position.x, case.position.y });
            return err;
        };
    }

    orchestrator.mouse_state.position = .{ .x = 10, .y = 15 };
    try std.testing.expectEqual(false, orchestrator.is_mouse_in(.{ .x = 10, .y = 10, .width = 0, .height = 10 }));
}

test "Orchestrator.update_item hover ownership" {
    var orchestrator: zui.Orchestrator = zui.Orchestrator.init(raylib.Vector2{ .x = 0, .y = 0 });

    const id: zui.Id = orchestrator.get_id("owo");
    const rectangle: raylib.Rectangle = .{
        .x = 15,
        .y = 15,
        .width = 10,
        .height = 10,
    };

    // outside `rectangle`, with no action being done, both `active` and `hovered` are false.
    var item_state: zui.ItemState = orchestrator.update_item(rectangle, id);
    try std.testing.expectEqual(false, item_state.active);
    try std.testing.expectEqual(false, item_state.hovered);
    try std.testing.expectEqual(zui.id_none, orchestrator.active_item_id);
    try std.testing.expectEqual(zui.id_none, orchestrator.hover_item_id);

    // once calling `update_item` with the mouse position inside `rectangle`, `hovered` is expected to be true.
    orchestrator.mouse_state.position = .{ .x = 16, .y = 16 };
    item_state = orchestrator.update_item(rectangle, id);
    try std.testing.expectEqual(false, item_state.active);
    try std.testing.expectEqual(true, item_state.hovered);
    try std.testing.expectEqual(zui.id_none, orchestrator.active_item_id);
    try std.testing.expectEqual(id, orchestrator.hover_item_id);

    // leaving the rectangle without an action lets the owner clear its own hover.
    orchestrator.mouse_state.position = .{ .x = 100, .y = 100 };
    item_state = orchestrator.update_item(rectangle, id);
    try std.testing.expectEqual(false, item_state.active);
    try std.testing.expectEqual(false, item_state.hovered);
    try std.testing.expectEqual(zui.id_none, orchestrator.hover_item_id);
}

test "Orchestrator.update_item press and hold lifecycle" {
    var orchestrator: zui.Orchestrator = zui.Orchestrator.init(raylib.Vector2{ .x = 0, .y = 0 });
    orchestrator.mouse_state.position = .{ .x = 16, .y = 16 };

    const id: zui.Id = orchestrator.get_id("owo");
    const rectangle: raylib.Rectangle = .{
        .x = 15,
        .y = 15,
        .width = 10,
        .height = 10,
    };

    // when just hovering inside the rectangle, the active state remains false.
    var item_state: zui.ItemState = orchestrator.update_item(rectangle, id);
    try std.testing.expectEqual(false, item_state.active);
    try std.testing.expectEqual(true, item_state.hovered);

    // with a mouse press and hold, `active` becomes true.
    orchestrator.mouse_state.press = true;
    orchestrator.mouse_state.hold = true;
    item_state = orchestrator.update_item(rectangle, id);
    try std.testing.expectEqual(true, item_state.active);
    try std.testing.expectEqual(true, item_state.hovered);
    try std.testing.expectEqual(id, orchestrator.active_item_id);

    // while holding, the state remains the same.
    orchestrator.mouse_state.press = false;
    item_state = orchestrator.update_item(rectangle, id);
    try std.testing.expectEqual(true, item_state.active);
    try std.testing.expectEqual(true, item_state.hovered);
    try std.testing.expectEqual(id, orchestrator.active_item_id);

    // next frame, while `hold` is still true, `active_item_id` remains the same.
    orchestrator.update_finish();
    try std.testing.expectEqual(id, orchestrator.active_item_id);

    // now the mouse is not inside `rectangle` anymore, while `hold` is still true, so `hovered` is false and `active` remains.
    orchestrator.mouse_state.position = .{ .x = 16, .y = 35 };
    item_state = orchestrator.update_item(rectangle, id);
    try std.testing.expectEqual(true, item_state.active);
    try std.testing.expectEqual(false, item_state.hovered);
    try std.testing.expectEqual(zui.id_none, orchestrator.hover_item_id);

    // when releasing outside, `active` survives, and is reset at the end of the frame.
    orchestrator.mouse_state.press = false;
    orchestrator.mouse_state.hold = false;
    orchestrator.mouse_state.release = true;
    item_state = orchestrator.update_item(rectangle, id);
    try std.testing.expectEqual(true, item_state.active);
    try std.testing.expectEqual(false, item_state.hovered);

    orchestrator.update_finish();
    try std.testing.expectEqual(zui.id_none, orchestrator.active_item_id);

    // next frame nothing is active or hovered anymore.
    orchestrator.mouse_state.release = false;
    item_state = orchestrator.update_item(rectangle, id);
    try std.testing.expectEqual(false, item_state.active);
    try std.testing.expectEqual(false, item_state.hovered);
}

test "Orchestrator.update_item press outside claims nothing" {
    var orchestrator: zui.Orchestrator = zui.Orchestrator.init(raylib.Vector2{ .x = 0, .y = 0 });

    const id: zui.Id = orchestrator.get_id("owo");
    const rectangle: raylib.Rectangle = .{
        .x = 15,
        .y = 15,
        .width = 10,
        .height = 10,
    };

    // with a mouse press and hold, but outside `rectangle`, both `active` and `hovered` remain false.
    orchestrator.mouse_state.press = true;
    orchestrator.mouse_state.hold = true;
    var item_state: zui.ItemState = orchestrator.update_item(rectangle, id);
    try std.testing.expectEqual(false, item_state.active);
    try std.testing.expectEqual(false, item_state.hovered);
    try std.testing.expectEqual(zui.id_none, orchestrator.active_item_id);

    // `update_finish` with `hold` true keeps the empty `active_item_id`, as there's nothing below the pointer.
    orchestrator.update_finish();
    try std.testing.expectEqual(zui.id_none, orchestrator.active_item_id);

    // releasing outside also keeps `active_item_id` empty.
    orchestrator.mouse_state.press = false;
    orchestrator.mouse_state.hold = false;
    orchestrator.mouse_state.release = true;
    item_state = orchestrator.update_item(rectangle, id);
    try std.testing.expectEqual(false, item_state.active);
    try std.testing.expectEqual(false, item_state.hovered);

    orchestrator.update_finish();
    try std.testing.expectEqual(zui.id_none, orchestrator.active_item_id);
}

test "Orchestrator.update_item state is properly owned by an item on hold" {
    var orchestrator: zui.Orchestrator = zui.Orchestrator.init(raylib.Vector2{ .x = 0, .y = 0 });
    orchestrator.mouse_state.position = .{ .x = 61, .y = 61 };

    const id_first: zui.Id = orchestrator.get_id("owo");
    const rectangle_first: raylib.Rectangle = .{
        .x = 15,
        .y = 15,
        .width = 10,
        .height = 10,
    };
    const id_second: zui.Id = orchestrator.get_id("uwu");
    const rectangle_second: raylib.Rectangle = .{
        .x = 60,
        .y = 60,
        .width = 10,
        .height = 10,
    };

    // inside `rectangle_second`, with no action being done.
    var item_state: zui.ItemState = orchestrator.update_item(rectangle_second, id_second);
    try std.testing.expectEqual(false, item_state.active);
    try std.testing.expectEqual(true, item_state.hovered);
    try std.testing.expectEqual(id_second, orchestrator.hover_item_id);

    // pressing inside `rectangle_second`.
    orchestrator.mouse_state.press = true;
    orchestrator.mouse_state.hold = true;
    item_state = orchestrator.update_item(rectangle_second, id_second);
    try std.testing.expectEqual(true, item_state.active);
    try std.testing.expectEqual(true, item_state.hovered);
    try std.testing.expectEqual(id_second, orchestrator.active_item_id);

    // next frame, while `hold` is still true, `active_item_id` remains the same.
    orchestrator.mouse_state.press = false;
    orchestrator.update_finish();
    try std.testing.expectEqual(id_second, orchestrator.active_item_id);

    // with the mouse within `rectangle_first`, `rectangle_second` loses the hover when the mouse leaves it.
    // `rectangle_first` can't own it while `hold` is true, as the `active` state is still owned by `rectangle_second`.
    orchestrator.mouse_state.position = .{ .x = 16, .y = 16 };

    item_state = orchestrator.update_item(rectangle_second, id_second);
    try std.testing.expectEqual(true, item_state.active);
    try std.testing.expectEqual(false, item_state.hovered);

    item_state = orchestrator.update_item(rectangle_first, id_first);
    try std.testing.expectEqual(false, item_state.active);
    try std.testing.expectEqual(false, item_state.hovered);

    try std.testing.expectEqual(id_second, orchestrator.active_item_id);
    try std.testing.expectEqual(zui.id_none, orchestrator.hover_item_id);
}

test "Orchestrator.update_item release over another item" {
    var orchestrator: zui.Orchestrator = zui.Orchestrator.init(raylib.Vector2{ .x = 0, .y = 0 });
    orchestrator.mouse_state.position = .{ .x = 61, .y = 61 };

    const id_first: zui.Id = orchestrator.get_id("owo");
    const rectangle_first: raylib.Rectangle = .{
        .x = 15,
        .y = 15,
        .width = 10,
        .height = 10,
    };
    const id_second: zui.Id = orchestrator.get_id("uwu");
    const rectangle_second: raylib.Rectangle = .{
        .x = 60,
        .y = 60,
        .width = 10,
        .height = 10,
    };

    // inside `rectangle_second`, with no action being done.
    var item_state: zui.ItemState = orchestrator.update_item(rectangle_second, id_second);
    try std.testing.expectEqual(true, item_state.hovered);
    try std.testing.expectEqual(false, item_state.active);

    // press and hold within `rectangle_second`.
    orchestrator.mouse_state.press = true;
    orchestrator.mouse_state.hold = true;
    item_state = orchestrator.update_item(rectangle_second, id_second);
    try std.testing.expectEqual(true, item_state.active);

    orchestrator.mouse_state.press = false;
    orchestrator.update_finish();

    // moving the mouse over `rectangle_first`, while `rectangle_second` owns `active`.
    orchestrator.mouse_state.position = .{ .x = 16, .y = 16 };

    item_state = orchestrator.update_item(rectangle_second, id_second);
    try std.testing.expectEqual(true, item_state.active);
    try std.testing.expectEqual(false, item_state.hovered);

    item_state = orchestrator.update_item(rectangle_first, id_first);
    try std.testing.expectEqual(false, item_state.active);
    try std.testing.expectEqual(false, item_state.hovered);

    // `rectangle_second` keeps `active` until `update_finish` if the `hold` is released on top of `rectangle_first`.
    // after the release, `rectangle_first` owns the hover.
    orchestrator.mouse_state.hold = false;
    orchestrator.mouse_state.release = true;

    item_state = orchestrator.update_item(rectangle_second, id_second);
    try std.testing.expectEqual(true, item_state.active);
    try std.testing.expectEqual(false, item_state.hovered);

    item_state = orchestrator.update_item(rectangle_first, id_first);
    try std.testing.expectEqual(false, item_state.active);
    try std.testing.expectEqual(true, item_state.hovered);

    try std.testing.expectEqual(id_second, orchestrator.active_item_id);
    try std.testing.expectEqual(id_first, orchestrator.hover_item_id);

    // at `update_finish`, `active_item_id` is reset, as the hold was released. no item had both `active` and `hovered`.
    // this is considered a click out-of-bounds.
    orchestrator.update_finish();
    try std.testing.expectEqual(zui.id_none, orchestrator.active_item_id);

    // at the next frame, `rectangle_first` is still hovered.
    orchestrator.mouse_state.release = false;
    item_state = orchestrator.update_item(rectangle_first, id_first);
    try std.testing.expectEqual(false, item_state.active);
    try std.testing.expectEqual(true, item_state.hovered);
}

test "Orchestrator.update_item hover transfers without an action" {
    var orchestrator: zui.Orchestrator = zui.Orchestrator.init(raylib.Vector2{ .x = 0, .y = 0 });

    const id_first: zui.Id = orchestrator.get_id("owo");
    const rectangle_first: raylib.Rectangle = .{
        .x = 15,
        .y = 15,
        .width = 10,
        .height = 10,
    };
    const id_second: zui.Id = orchestrator.get_id("uwu");
    const rectangle_second: raylib.Rectangle = .{
        .x = 60,
        .y = 60,
        .width = 10,
        .height = 10,
    };

    // the pointer starts inside `rectangle_second`, which claims the hover.
    orchestrator.mouse_state.position = .{ .x = 61, .y = 61 };
    var item_state: zui.ItemState = orchestrator.update_item(rectangle_second, id_second);
    try std.testing.expectEqual(true, item_state.hovered);
    try std.testing.expectEqual(id_second, orchestrator.hover_item_id);

    // moving into `rectangle_first` without any action transfers the hover ownership.
    orchestrator.mouse_state.position = .{ .x = 16, .y = 16 };
    item_state = orchestrator.update_item(rectangle_first, id_first);
    try std.testing.expectEqual(true, item_state.hovered);
    try std.testing.expectEqual(id_first, orchestrator.hover_item_id);

    item_state = orchestrator.update_item(rectangle_second, id_second);
    try std.testing.expectEqual(false, item_state.hovered);
    try std.testing.expectEqual(id_first, orchestrator.hover_item_id);

    // changing the position then changes the hover ownership.
    orchestrator.mouse_state.position = .{ .x = 61, .y = 61 };
    item_state = orchestrator.update_item(rectangle_second, id_second);
    try std.testing.expectEqual(true, item_state.hovered);

    orchestrator.mouse_state.position = .{ .x = 16, .y = 16 };
    item_state = orchestrator.update_item(rectangle_second, id_second);
    try std.testing.expectEqual(false, item_state.hovered);
    try std.testing.expectEqual(zui.id_none, orchestrator.hover_item_id);

    item_state = orchestrator.update_item(rectangle_first, id_first);
    try std.testing.expectEqual(true, item_state.hovered);
    try std.testing.expectEqual(id_first, orchestrator.hover_item_id);
}

test "Orchestrator.update_item press outside any area does not claim active" {
    var orchestrator: zui.Orchestrator = zui.Orchestrator.init(raylib.Vector2{ .x = 0, .y = 0 });

    const id: zui.Id = orchestrator.get_id("owo");
    const rectangle: raylib.Rectangle = .{
        .x = 15,
        .y = 15,
        .width = 10,
        .height = 10,
    };

    // the press starts outside.
    orchestrator.mouse_state.position = .{ .x = 100, .y = 100 };
    orchestrator.mouse_state.press = true;
    orchestrator.mouse_state.hold = true;

    var item_state: zui.ItemState = orchestrator.update_item(rectangle, id);
    try std.testing.expectEqual(false, item_state.active);
    try std.testing.expectEqual(false, item_state.hovered);
    try std.testing.expectEqual(zui.id_none, orchestrator.active_item_id);

    // no claim happens if moving inside while the button is still held from outside.
    orchestrator.mouse_state.position = .{ .x = 16, .y = 16 };
    orchestrator.mouse_state.press = false;

    item_state = orchestrator.update_item(rectangle, id);
    try std.testing.expectEqual(false, item_state.active);
    try std.testing.expectEqual(false, item_state.hovered);
    try std.testing.expectEqual(zui.id_none, orchestrator.active_item_id);
    try std.testing.expectEqual(zui.id_none, orchestrator.hover_item_id);

    // releasing inside restores hover but cannot produce a click, because active was never claimed.
    orchestrator.mouse_state.hold = false;
    orchestrator.mouse_state.release = true;

    item_state = orchestrator.update_item(rectangle, id);
    try std.testing.expectEqual(false, item_state.active);
    try std.testing.expectEqual(true, item_state.hovered);
    try std.testing.expectEqual(id, orchestrator.hover_item_id);

    orchestrator.update_finish();
    try std.testing.expectEqual(zui.id_none, orchestrator.active_item_id);
}
