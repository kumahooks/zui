const raylib = @import("raylib");

const zui = @import("lib.zig");

pub fn render(orchestrator: *zui.Orchestrator, label: [:0]const u8, style: zui.Style, coordinate: raylib.Vector2) zui.WidgetResult {
    const id: zui.Id = orchestrator.getId(label);

    // gathers the area of the button.
    const label_size: raylib.Vector2 = raylib.measureTextEx(style.font, label, style.font_size, style.font_spacing);
    const rectangle: raylib.Rectangle = .{
        .x = coordinate.x,
        .y = coordinate.y,
        .width = label_size.x,
        .height = label_size.y,
    };

    // updates the hover and active status based on mouse position and button area.
    const item_state: zui.ItemState = orchestrator.updateItem(rectangle, id);

    // handles the mouse action.
    var result: zui.WidgetResult = .{};
    if (item_state.active) {
        result.clicked = item_state.hovered and orchestrator.mouse_release;
        result.held = orchestrator.mouse_hold;
    }

    // draws the button.
    var color: raylib.Color = style.font_idle_color;
    if (item_state.active) {
        color = style.font_active_color;
    } else if (item_state.hovered) {
        color = style.font_hovered_color;
    }
    draw(label, style, coordinate, orchestrator.origin_left_position, color);

    return result;
}

fn draw(label: [:0]const u8, style: zui.Style, coordinate: raylib.Vector2, origin_left_position: raylib.Vector2, color: raylib.Color) void {
    raylib.drawTextPro(
        style.font,
        label,
        coordinate,
        origin_left_position,
        0,
        style.font_size,
        style.font_spacing,
        color,
    );
}
