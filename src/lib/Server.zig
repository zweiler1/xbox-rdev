const std = @import("std");

const Message = @import("message.zig").Message;
const Self = @This();

msg: ?Message = null,
server: std.Io.net.Server,
connection: ?Connection,

pub const Connection = struct {
    stream: std.Io.net.Stream,
    reader_buffer: []u8,
    reader: std.Io.net.Stream.Reader,
    writer_buffer: []u8,
    writer: std.Io.net.Stream.Writer,

    pub fn init(io: std.Io, allocator: std.mem.Allocator, stream: std.Io.net.Stream) !Connection {
        const reader_buffer: []u8 = try allocator.alloc(u8, 4096);
        const reader = stream.reader(io, reader_buffer);
        const writer_buffer: []u8 = try allocator.alloc(u8, 4096);
        const writer = stream.writer(io, writer_buffer);
        return .{
            .stream = stream,
            .reader_buffer = reader_buffer,
            .reader = reader,
            .writer_buffer = writer_buffer,
            .writer = writer,
        };
    }

    pub fn deinit(self: *Connection, io: std.Io, allocator: std.mem.Allocator) void {
        self.stream.close(io);
        allocator.free(self.reader_buffer);
        allocator.free(self.writer_buffer);
    }
};

pub fn init(io: std.Io) !Self {
    const address: std.Io.net.IpAddress = .{ .ip4 = .unspecified(9000) };
    const server = try address.listen(io, .{
        .reuse_address = true,
    });
    return .{
        .msg = null,
        .server = server,
        .connection = null,
    };
}

pub fn deinit(self: *Self, io: std.Io, allocator: std.mem.Allocator) void {
    self.server.deinit(io);
    if (self.connection) |*conn| {
        conn.deinit(io, allocator);
        self.connection = null;
    }
}
