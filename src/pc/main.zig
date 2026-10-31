const std = @import("std");

const xbox_rdev = @import("xbox_rdev");

fn awaitAndPrintIncomingLogs(io: std.Io, allocator: std.mem.Allocator, logfile: *std.Io.Writer) void {
    // var allocator: std.mem.Allocator = .
    var client = xbox_rdev.Client.init(io, allocator) catch unreachable;
    defer client.deinit(io, allocator);

    while (true) {
        const msg = xbox_rdev.Message.read(&client.connection.reader) catch unreachable;
        switch (msg) {
            .log => |log| {
                const len = std.mem.findSentinel(u8, '\x00', @ptrCast(&log));
                logfile.print("log: {s}\n", .{log[0..len]}) catch unreachable;
            },
            else => {},
        }
    }
}

pub fn main(init: std.process.Init) !void {
    const logfile = try std.Io.Dir.cwd().createFile(init.io, "log", .{});
    defer logfile.close(init.io);
    var logfile_writer = logfile.writer(init.io, &.{});
    defer logfile_writer.interface.flush() catch {};

    // Set up async logging
    var logging: std.Io.Future(void) = std.Io.async(init.io, awaitAndPrintIncomingLogs, .{ init.io, init.gpa, &logfile_writer.interface });
    defer logging.cancel(init.io);

    // Now comes the CLI repl
    var stdin_buffer: [512]u8 = @splat(0);
    var stdin_reader = std.Io.File.stdin().reader(init.io, &stdin_buffer);
    const stdin = &stdin_reader.interface;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &.{});
    const stdout = &stdout_writer.interface;
    // var stderr_writer = std.Io.File.stderr().writer(init.io, &.{});
    // const stderr = &stderr_writer.interface;

    try stdout.writeAll("Xbox Remote Dev Tool REPL. Run 'help' for more information\n");
    try stdout.writeAll("> ");
    var cmd_buffer: [512]u8 = @splat(0);
    var cmd_writer: std.Io.Writer = .fixed(&cmd_buffer);
    while (true) {
        const read = try stdin.streamDelimiter(&cmd_writer, '\n');
        try stdout.writeAll(cmd_buffer[0..read]);
    }
}
