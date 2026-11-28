const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_label = b.addLibrary(.{
        .linkage = .static,
        .name = "model_label",
        .root_module = b.createModule(.{
            .root_source_file = b.path("root.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    b.installArtifact(lib_label);

    const install_header = b.addInstallHeaderFile(b.path("include/model_label.h"), "model_label.h");
    b.getInstallStep().dependOn(&install_header.step);
    lib_label.step.dependOn(&install_header.step);
}
