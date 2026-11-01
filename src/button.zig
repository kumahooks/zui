const std = @import("std");

const raylib = @import("raylib");

const zui = @import("root.zig");

pub fn render(orchestrator: *zui.Orchestrator, label: [:0]const u8, style: *const zui.Style, coordinate: raylib.Vector2) zui.WidgetResult {
    std.debug.assert(style.font.texture.id != 0);
    std.debug.assert(style.font_size > 0);
    std.debug.assert(std.math.isFinite(style.font_size));
    std.debug.assert(std.math.isFinite(style.font_spacing));
    std.debug.assert(std.math.isFinite(coordinate.x));
    std.debug.assert(std.math.isFinite(coordinate.y));

    const id: zui.Id = orchestrator.get_id(label);

    // gathers the area of the button.
    const label_size: raylib.Vector2 = raylib.measureTextEx(style.font, label, style.font_size, style.font_spacing);
    const rectangle: raylib.Rectangle = .{
        .x = coordinate.x,
        .y = coordinate.y,
        .width = label_size.x,
        .height = label_size.y,
    };

    // updates the hover and active status based on mouse position and button area.
    const item_state: zui.ItemState = orchestrator.update_item(rectangle, id);

    // handles the mouse action.
    var result: zui.WidgetResult = .{};
    if (item_state.active) {
        if (item_state.hovered) result.clicked = orchestrator.mouse_release;

        result.held = orchestrator.mouse_hold;
    }

    // draws the button.
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
        coordinate,
        orchestrator.origin_left_position,
        0,
        style.font_size,
        style.font_spacing,
        color,
    );

    return result;
}

// TODO: implement tests
