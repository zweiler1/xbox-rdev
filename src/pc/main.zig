const std = @import("std");

const xbox_rdev = @import("xbox_rdev");

pub fn main() !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
}
