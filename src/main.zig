const std = @import("std");
const Server = @import("server.zig").Server;
const Request = @import("request.zig");
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const server = try Server.init(io);
    var listening = try server.listen();
    const connection = try listening.accept(io);
    defer connection.close(io);

    var buffer: [1000]u8 = undefined;
    @memset(buffer[0..], 0);
    try Request.read_request(io, connection, buffer[0..]);

    std.debug.print("Requset recv: {s}\n", .{buffer});
}
