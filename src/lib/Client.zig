//! The Client is the PC executable which is running. It connects to the Server which is running on the Xbox
//!
//! The Client can control the server (the wrapper exe running on the xbox) and send commands to it
const std = @import("std");

const Message = @import("message.zig").Message;
const Self = @This();

queue: std.Deque(Message),
connection: struct {
    stream: std.Io.net.Stream,
    reader_buffer: []u8,
    reader: std.Io.net.Stream.Reader,
    writer_buffer: []u8,
    writer: std.Io.net.Stream.Writer,
},

pub fn init(io: std.Io, allocator: std.mem.Allocator) !Self {
    const address = try std.Io.net.IpAddress.parseIp4("192.168.0.43", 9000);
    const stream = try address.connect(io, .{
        .mode = .stream,
    });
    const reader_buffer: []u8 = try allocator.alloc(u8, 4096);
    const reader = stream.reader(io, reader_buffer);
    const writer_buffer: []u8 = try allocator.alloc(u8, 4096);
    const writer = stream.writer(io, writer_buffer);
    return .{
        .queue = .empty,
        .connection = .{
            .stream = stream,
            .reader_buffer = reader_buffer,
            .reader = reader,
            .writer_buffer = writer_buffer,
            .writer = writer,
        },
    };
}

pub fn deinit(self: *Self, io: std.Io, allocator: std.mem.Allocator) void {
    self.queue.deinit(allocator);
    allocator.free(self.connection.reader_buffer);
    allocator.free(self.connection.writer_buffer);
    self.connection.stream.close(io);
}
