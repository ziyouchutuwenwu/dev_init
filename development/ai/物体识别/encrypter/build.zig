const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const arch_name = switch (target.result.cpu.arch) {
        .aarch64 => "aarch64",
        .x86_64 => "x86_64",
        else => @tagName(target.result.cpu.arch),
    };
    if (std.mem.endsWith(u8, b.install_prefix, "zig-out") or std.mem.endsWith(u8, b.install_prefix, "zig-out/")) {
        b.install_prefix = b.pathJoin(&.{ b.install_prefix, arch_name });
        b.install_path = b.install_prefix;
        b.lib_dir = b.pathJoin(&.{ b.install_path, "lib" });
        b.exe_dir = b.pathJoin(&.{ b.install_path, "bin" });
        b.h_dir = b.pathJoin(&.{ b.install_path, "include" });
    }

    const base_mod = b.createModule(.{
        .root_source_file = b.path("src/base/mod.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const lib_license = b.addLibrary(.{
        .linkage = .static,
        .name = "model_license",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/c/mod.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{
                .{ .name = "base", .module = base_mod },
            },
        }),
    });
    lib_license.bundle_compiler_rt = true;
    b.installArtifact(lib_license);

    const exe_gen_header = b.addExecutable(.{
        .name = "gen_header",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/gen_header.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const run_gen_h = b.addRunArtifact(exe_gen_header);
    run_gen_h.addArg(b.pathJoin(&.{ b.install_path, "include", "model_license.h" }));
    b.getInstallStep().dependOn(&run_gen_h.step);
    lib_license.step.dependOn(&run_gen_h.step);

    const exe_hwid = b.addExecutable(.{
        .name = "hwid_tool",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/cli/hwid_cli.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{
                .{ .name = "base", .module = base_mod },
            },
        }),
    });
    b.installArtifact(exe_hwid);

    const default_tools = (target.result.cpu.arch == .x86_64);
    const build_tools = b.option(bool, "tools", "Build CLI license and model tools") orelse default_tools;
    if (build_tools) {
        const exe_license = b.addExecutable(.{
            .name = "license_tool",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/cli/license_cli.zig"),
                .target = target,
                .optimize = optimize,
                .link_libc = true,
                .imports = &.{
                    .{ .name = "base", .module = base_mod },
                },
            }),
        });
        b.installArtifact(exe_license);

        const exe_model = b.addExecutable(.{
            .name = "model_tool",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/cli/model_cli.zig"),
                .target = target,
                .optimize = optimize,
                .link_libc = true,
                .imports = &.{
                    .{ .name = "base", .module = base_mod },
                },
            }),
        });
        b.installArtifact(exe_model);
    }
}
