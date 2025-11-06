const std = @import("std");

pub fn build(b: *std.Build) void {
    const gpa = std.heap.page_allocator;

    // Options
    const s_log_level = b.option(
        []const u8,
        "log_level",
        "the log level",
    ) orelse "info";
    const log_level: std.log.Level = b: {
        const eql = std.mem.eql;
        break :b if (eql(u8, s_log_level, "debug"))
            .debug
        else if (eql(u8, s_log_level, "info"))
            .info
        else if (eql(u8, s_log_level, "warn"))
            .warn
        else if (eql(u8, s_log_level, "error"))
            .err
        else
            @panic("Invalid log level");
    };

    const optimize = b.standardOptimizeOption(.{});

    // Surtr Executable
    const surtr = b.addExecutable(.{
        .name = "BOOTX64.EFI",
        .root_module = b.createModule(.{
            .root_source_file = b.path("surtr/boot.zig"),
            .target = b.resolveTargetQuery(.{
                .cpu_arch = .x86_64,
                .os_tag = .uefi,
            }),
            .optimize = optimize,
        }),
        .linkage = .static,
    });
    const options = b.addOptions();
    options.addOption(std.log.Level, "log_level", log_level);
    surtr.root_module.addOptions("option", options);
    b.installArtifact(surtr);

    // EFI directory
    const out_dir_name = "img";
    const install_surtr = b.addInstallFile(
        surtr.getEmittedBin(),
        b.fmt("{s}/efi/boot/{s}", .{ out_dir_name, surtr.name }),
    );
    install_surtr.step.dependOn(&surtr.step);
    b.getInstallStep().dependOn(&install_surtr.step);

    const ovmf_code_fd_path = std.process.getEnvVarOwned(gpa, "OVMF_CODE_FD") catch unreachable;
    const ovmf_vars_fd_path = "/tmp/OVMF_VARS.fd"; // FIXME

    const qemu_args = [_][]const u8{
        "qemu-system-x86_64",
        "-m",
        "512M",
        "-drive",
        b.fmt("if=pflash,format=raw,unit=0,readonly=on,file={s}", .{ovmf_code_fd_path}),
        "-drive",
        b.fmt("if=pflash,format=raw,unit=1,file={s}", .{ovmf_vars_fd_path}),
        "-drive",
        b.fmt("file=fat:rw:{s}/{s},format=raw", .{ b.install_path, out_dir_name }),
        "-nographic",
        "-serial",
        "mon:stdio",
        "-no-reboot",
        "-enable-kvm",
        "-cpu",
        "host",
        "-s",
    };
    const qemu_cmd = b.addSystemCommand(&qemu_args);
    qemu_cmd.step.dependOn(b.getInstallStep());

    const run_qemu_cmd = b.step("run", "Run QEMU");
    run_qemu_cmd.dependOn(&qemu_cmd.step);
}
