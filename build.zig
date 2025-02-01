const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "zigenoid",
        .root_source_file = b.path("src/main.zig"),
        .target = b.host,
    });

    exe.linkLibC();
    exe.linkSystemLibrary("SDL3");
    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run zigenoid");
    run_step.dependOn(&run_exe.step);
}
