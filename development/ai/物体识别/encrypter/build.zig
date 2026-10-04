const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 基础基础模块 (src/base)
    const base_mod = b.createModule(.{
        .root_source_file = b.path("src/base/mod.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    // C 接口静态库 (model_license)
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

    // 动态生成 C 头文件工具 (gen_header)
    const exe_gen_header = b.addExecutable(.{
        .name = "gen_header",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/gen_header.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const run_gen_h = b.addRunArtifact(exe_gen_header);
    run_gen_h.setCwd(b.path("."));
    const header_file = run_gen_h.addOutputFileArg("model_license.h");
    const install_header = b.addInstallHeaderFile(header_file, "model_license.h");
    b.getInstallStep().dependOn(&install_header.step);
    lib_license.step.dependOn(&install_header.step);

    // 硬件机器码工具 (hwid_tool)
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

    // CLI 工具：license_tool 与 model_tool
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

    // 单元测试 Step
    const base_tests = b.addTest(.{
        .root_module = base_mod,
    });
    const run_base_tests = b.addRunArtifact(base_tests);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_base_tests.step);
}
