const std = @import("std");

pub const Message = union(enum(u32)) {
    /// The Server (xbox exe) logs to the Client (pc exe) so that logs can be displayed
    log: [256]u8,

    /// The Client tells the Server to go back to the dashboard
    dashboard,
    /// The Client tells the Server to start the given game
    launch: [256]u8,

    pub fn write(self: *const Message, writer: *std.Io.net.Stream.Writer) !void {
        try writer.writeInt(
            u32,
            @backingInt(std.meta.activeTag(self.*)),
            .big,
        );
        switch (self.*) {
            .log => |log| try writer.writeAll(log),
            .dashboard => {},
            .launch => |launch| try writer.writeAll(launch),
        }
        try writer.flush();
    }

    pub fn read(reader: *std.Io.net.Stream.Reader) !Message {
        const tag: std.meta.Tag(Message) = blk: while (true) {
            const int = reader.interface.takeInt(u32, .big) catch |err| switch (err) {
                error.ReadFailed => {
                    // No data available yet, try again
                    continue;
                },
                else => return err,
            };
            break :blk @fromBackingInt(int);
        };

        var result: Message = undefined;
        switch (tag) {
            .log => {
                result = .{ .log = @splat(0) };
                try reader.interface.readSliceAll(&result.log);
            },
            .dashboard => {
                result = .dashboard;
            },
            .launch => {
                result = .{ .launch = @splat(0) };
                try reader.interface.readSliceAll(&result.launch);
            },
        }
        return result;
    }
};
