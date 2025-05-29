const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const nfd_dep = b.dependency("nfd_src", .{});

    const nfd_mod = b.addModule("nfd", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const cflags = switch (target.result.os.tag) {
        // window hack, nfd has a comment about unicode, this is just to make it work (not
        // correctly)
        .windows => &[_][]const u8{ "-Wall", "-DUNICODE", "-D_UNICODE" },
        else => &[_][]const u8{"-Wall"},
    };
    nfd_mod.addIncludePath(nfd_dep.path("src/include"));
    nfd_mod.addCSourceFile(.{ .file = nfd_dep.path("src/nfd_common.c"), .flags = cflags });
    switch (target.result.os.tag) {
        .macos => nfd_mod.addCSourceFile(.{
            .file = nfd_dep.path("src/nfd_cocoa.m"),
            .flags = cflags,
        }),
        .windows => nfd_mod.addCSourceFile(.{
            .file = nfd_dep.path("src/nfd_win.cpp"),
            .flags = cflags,
        }),
        .linux => nfd_mod.addCSourceFile(.{
            .file = nfd_dep.path("src/nfd_zenity.c"),
            .flags = cflags,
        }),
        else => @panic("unsupported OS"),
    }

    switch (target.result.os.tag) {
        .macos => nfd_mod.linkFramework("AppKit", .{}),
        .windows => {
            nfd_mod.linkSystemLibrary("shell32", .{});
            nfd_mod.linkSystemLibrary("ole32", .{});
            nfd_mod.linkSystemLibrary("uuid", .{}); // needed by MinGW
        },
        .linux => {},
        else => @panic("unsupported OS"),
    }

    var demo = b.addExecutable(.{
        .name = "nfd-demo",
        .root_source_file = b.path("src/demo.zig"),
        .target = target,
        .optimize = optimize,
    });
    demo.addIncludePath(nfd_dep.path("src/include"));
    demo.root_module.addImport("nfd", nfd_mod);
    b.installArtifact(demo);

    const run_demo_cmd = b.addRunArtifact(demo);
    run_demo_cmd.step.dependOn(b.getInstallStep());

    const run_demo_step = b.step("run", "Run the demo");
    run_demo_step.dependOn(&run_demo_cmd.step);
}
