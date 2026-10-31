const std = @import("std");

const xbox_rdev = @import("xbox_rdev");
const rl = @import("raylib");
const rg = @import("raygui");

pub fn main(init: std.process.Init) !void {
    rl.setConfigFlags(.{ .vsync_hint = true, .window_highdpi = true });
    rl.initWindow(640, 480, "xbox-rdev");
    defer rl.closeWindow();

    var server: xbox_rdev.Server = try .init(init.io);
    defer server.deinit(init.io, init.gpa);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.dark_green);
        if (server.connection) |*con| {
            std.log.debug("waiting for msg from client...", .{});
            _ = rg.label(.init(10, 10, 100, 20), "waiting for msg from client...");
            const msg = xbox_rdev.Message.read(&con.reader) catch |err| switch (err) {
                error.EndOfStream => {
                    std.log.debug("client disconnected...", .{});
                    _ = rg.label(.init(10, 30, 100, 20), "client disconnected...");
                    con.deinit(init.io, init.gpa);
                    server.connection = null;
                    continue;
                },
                else => return err,
            };
            std.log.debug("recieved msg from client", .{});
            _ = rg.label(.init(10, 30, 100, 20), "recieved msg from client");
            _ = msg;
        } else {
            std.log.debug("waiting for client to connect to server...", .{});
            _ = rg.label(.init(10, 10, 100, 20), "waiting for client to connect to sever...");
            const stream = server.server.accept(init.io) catch |err| switch (err) {
                error.NetworkDown, error.WouldBlock, error.ConnectionAborted => continue,
                else => return err,
            };
            server.connection = try .init(init.io, init.gpa, stream);
            std.log.debug("client connected...", .{});
            _ = rg.label(.init(10, 30, 100, 20), "client connected...");
        }
    }
}
