const std = @import("std");

const raylib = @import("raylib");

const zui = @import("root.zig");

pub fn render(orchestrator: *zui.Orchestrator, label: [:0]const u8, style: *const zui.Style, rectangle: raylib.Rectangle) zui.WidgetResult {
    std.debug.assert(style.font.texture.id != 0);
    std.debug.assert(style.font_size > 0);
    std.debug.assert(std.math.isFinite(style.font_size));
    std.debug.assert(std.math.isFinite(style.font_spacing));
    std.debug.assert(std.math.isFinite(rectangle.x));
    std.debug.assert(std.math.isFinite(rectangle.y));
    std.debug.assert(std.math.isFinite(rectangle.width));
    std.debug.assert(std.math.isFinite(rectangle.height));
    std.debug.assert(rectangle.width >= 0);
    std.debug.assert(rectangle.height >= 0);

    const id: zui.Id = orchestrator.get_id(label);

    // updates the hover and active status based on mouse position and the button's slot area.
    const item_state: zui.ItemState = orchestrator.update_item(rectangle, id);

    // handles the mouse action.
    var result: zui.WidgetResult = .{};
    if (item_state.active) {
        if (item_state.hovered) result.clicked = orchestrator.mouse_state.release;

        result.held = orchestrator.mouse_state.hold;
    }

    // draws the button at the slot's top-left corner.
    var color: raylib.Color = style.font_idle_color;
    if (item_state.active) {
        color = style.font_active_color;
    } else {
        if (item_state.hovered) {
            color = style.font_hovered_color;
        }
    }
    raylib.drawTextPro(
        style.font,
        label,
        .{ .x = rectangle.x, .y = rectangle.y },
        orchestrator.origin_left_position,
        0,
        style.font_size,
        style.font_spacing,
        color,
    );

    // TODO: this is just to visualize the layout grid, needs to change once the button's default style is settled.
    raylib.drawRectangleLinesEx(rectangle, 1, style.border_color);

    return result;
}

// TODO: implement tests
