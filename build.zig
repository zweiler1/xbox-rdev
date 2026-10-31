const std = @import("std");
const nxdk_zig = @import("nxdk_zig");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const nxdk_dep = b.dependency("nxdk_zig", .{
        .optimize = optimize,
        .lto = null,
    });
    const raylib_dep = b.dependency("raylib_zig", .{
        .optimize = optimize,
        .platform = .xbox,
    });
    const lib = b.addModule("root", .{
        .root_source_file = b.path("src/lib/root.zig"),
        .target = b.resolveTargetQuery(nxdk_zig.target_query),
        .optimize = optimize,
        .imports = &.{
            .{ .name = "raygui", .module = raylib_dep.module("raygui") },
        },
    });
    try buildXbox(b, optimize, nxdk_dep, raylib_dep, lib);

    try buildPc(b, optimize);
}

fn buildXbox(
    b: *std.Build,
    optimize: std.builtin.Optimize,
    nxdk_dep: *std.Build.Dependency,
    raylib_dep: *std.Build.Dependency,
    lib: *std.Build.Module,
) !void {
    const exe = try nxdk_zig.createExe(nxdk_dep, b, optimize, "xbox_rdev", b.path("src/xbox/main.zig"), null, &.{
        .{ .name = "xbox_rdev", .module = lib },
        .{ .name = "raylib", .module = raylib_dep.module("raylib") },
        .{ .name = "raygui", .module = raylib_dep.module("raygui") },
    });
    const conversion = try nxdk_zig.convertExeToXboxExe(nxdk_dep, b, optimize, &exe.step, exe, "xbox");
    const create_xiso = try nxdk_zig.createXISO(nxdk_dep, b, optimize, conversion.step, exe.name, conversion.dir_path, "xbox");
    b.getInstallStep().dependOn(create_xiso);

    const run_step = b.step("run-xbox", "Boot the built XISO in xemu");
    const run_cmd = b.addSystemCommand(&.{ "xemu", "-device", "lpc47m157", "-serial", "stdio", "-dvd_path" });
    run_cmd.addFileArg2(
        b.graph.path(.install_prefix, b.fmt("xbox/{s}.iso", .{exe.name})),
        .{ .make_absolute = true },
    );
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();
}

fn buildPc(b: *std.Build, optimize: std.builtin.Optimize) !void {
    const target = b.standardTargetOptions(.{});
    const exe = b.addExecutable(.{
        .name = "xbox_rdev_pc",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/pc/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "xbox_rdev", .module = b.createModule(.{
                    .root_source_file = b.path("src/lib/root.zig"),
                    .target = target,
                    .optimize = optimize,
                }) },
            },
        }),
    });
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();
}
