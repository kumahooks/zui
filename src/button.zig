const std = @import("std");

const raylib = @import("raylib");

const zui = @import("root.zig");

pub const Options = struct {
    font_size: ?f32 = null,
    font_spacing: ?f32 = null,

    text_color: ?raylib.Color = null,
    text_hovered_color: ?raylib.Color = null,
    text_active_color: ?raylib.Color = null,

    border_color: ?raylib.Color = null,
    border_thickness: ?f32 = null,
};

const defaults = struct {
    const border_thickness: f32 = 1;
};

pub fn render(
    orchestrator: *zui.Orchestrator,
    label: [:0]const u8,
    rectangle: raylib.Rectangle,
    theme: *const zui.theme.Theme,
    options: Options,
) zui.WidgetResult {
    std.debug.assert(theme.typography.font.texture.id != 0);
    std.debug.assert(theme.typography.font.baseSize > 0);
    std.debug.assert(std.math.isFinite(rectangle.x));
    std.debug.assert(rectangle.x >= 0);
    std.debug.assert(std.math.isFinite(rectangle.y));
    std.debug.assert(rectangle.y >= 0);
    std.debug.assert(std.math.isFinite(rectangle.width));
    std.debug.assert(rectangle.width >= 0);
    std.debug.assert(std.math.isFinite(rectangle.height));
    std.debug.assert(rectangle.height >= 0);

    const font_size: f32 = options.font_size orelse theme.typography.size;
    const font_spacing: f32 = options.font_spacing orelse theme.typography.spacing;
    const text_color: raylib.Color = options.text_color orelse theme.palette.text;
    const text_hovered_color: raylib.Color = options.text_hovered_color orelse theme.palette.text_hovered;
    const text_active_color: raylib.Color = options.text_active_color orelse theme.palette.text_active;
    const border_color: raylib.Color = options.border_color orelse theme.palette.border;
    const border_thickness: f32 = options.border_thickness orelse defaults.border_thickness;

    std.debug.assert(std.math.isFinite(font_size));
    std.debug.assert(font_size > 0);
    std.debug.assert(std.math.isFinite(font_spacing));
    std.debug.assert(font_spacing >= 0);
    std.debug.assert(std.math.isFinite(border_thickness));
    std.debug.assert(border_thickness > 0);

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
    var color: raylib.Color = text_color;
    if (item_state.active) {
        color = text_active_color;
    } else {
        if (item_state.hovered) {
            color = text_hovered_color;
        }
    }
    raylib.drawTextPro(
        theme.typography.font,
        label,
        .{ .x = rectangle.x, .y = rectangle.y },
        .{ .x = 0, .y = 0 },
        0,
        font_size,
        font_spacing,
        color,
    );

    // TODO: this is just to visualize the layout grid, needs to change once the button's default style is settled.
    raylib.drawRectangleLinesEx(rectangle, border_thickness, border_color);

    return result;
}

// TODO: implement tests
