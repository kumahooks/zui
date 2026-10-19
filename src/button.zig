const raylib = @import("raylib");

const consts = @import("consts.zig");

pub const TextButton = struct {
    const Self = @This();

    font: raylib.Font,
    label: [:0]const u8,
    y: f32,
    margin_left: f32,
    margin_right: f32,

    pub fn init(label: [:0]const u8, y: f32, margin_left: f32, margin_right: f32, font: raylib.Font) Self {
        return .{ .label = label, .y = y, .margin_left = margin_left, .margin_right = margin_right, .font = font };
    }

    pub fn sizeVector(self: Self) raylib.Vector2 {
        return raylib.measureTextEx(self.font, self.label, consts.font_size, consts.font_spacing);
    }

    pub fn drawFromleft(self: Self) void {
        raylib.drawTextPro(self.font, self.label, .{ .x = self.margin_left, .y = self.y }, consts.position_origin_left, 0, consts.font_size, consts.font_spacing, consts.color_brand);
    }

    pub fn drawFromRight(self: Self) void {
        const text_size = self.sizeVector();
        const right_edge = @as(f32, @floatFromInt(raylib.getRenderWidth()));
        const x = right_edge - text_size.x - self.margin_right;

        raylib.drawTextPro(self.font, self.label, .{ .x = x, .y = self.y }, consts.position_origin_left, 0, consts.font_size, consts.font_spacing, consts.color_brand);
    }
};
