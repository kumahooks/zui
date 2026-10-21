const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib = raylib_dep.module("raylib");

    const zui = b.addModule("zui", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "raylib", .module = raylib },
        },
    });

    // merylmoe is just a "demo" which is not part of the zui library itself.
    if (b.isRoot()) {
        const merylmoe = b.addExecutable(.{ .name = "merylmoe", .root_module = b.createModule(.{
            .root_source_file = b.path("merylmoe/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "raylib", .module = raylib },
                .{ .name = "zui", .module = zui },
            },
        }) });
        b.installArtifact(merylmoe);

        const run_merylmoe = b.addRunArtifact(merylmoe);
        run_merylmoe.step.dependOn(b.getInstallStep());
        run_merylmoe.addPassthruArgs();
        b.step("run", "runs meryl.moe").dependOn(&run_merylmoe.step);
    }

    const zui_tests = b.addTest(.{ .root_module = zui });
    const run_zui_tests = b.addRunArtifact(zui_tests);
    b.step("test", "runs library tests").dependOn(&run_zui_tests.step);
}
