const std = @import("std");
const Server = @import("server.zig").Server;
const Request = @import("request.zig").Request;
const Response = @import("response.zig");
const Method = @import("method.zig");
const posix = std.posix;
const os = std.os;

var keepRunning: bool = true;

fn handleSignal(sig: os.linux.SIG) callconv(.c) void {
    std.debug.print("\n[!] Caught Ctrl+C (signal {}), Shutting down...\n", .{sig});
    keepRunning = false;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const server = try Server.init(io, "127.0.0.1", 4000);
    var listening = try server.listen();

    var act = os.linux.Sigaction{
        .handler = .{ .handler = handleSignal },
        .flags = 0,
        .mask = os.linux.sigemptyset(),
    };

    // this is saved in the stack memory
    // maybe in future we can add a GPA here with ArenaAllocator
    // as if server crashes or closed it should free up all the memory at once
    // and Arena allocator can do that at once.

    _ = os.linux.sigaction(os.linux.SIG.TERM, &act, null);
    _ = os.linux.sigaction(os.linux.SIG.INT, &act, null);
    while (keepRunning) {
        const connection = listening.accept(io) catch |err| {
            if (!keepRunning) break;
            return err;
        };

        defer connection.close(io);
        defer listening.deinit(io);

        var buffer: [10000]u8 = undefined;
        @memset(buffer[0..], 0);
        Request.read_request(io, connection, buffer[0..]) catch |err| {
            if (!keepRunning) break;
            return err;
        };
        if (!keepRunning) break;
        const req = Request.parse_request(buffer[0..]);
        if (req.method == Method.Method.GET) {
            if (std.mem.eql(u8, req.uri, "/")) {
                try Response.send_200(connection, io);
            } else {
                try Response.send_400(connection, io);
            }
        }

        std.debug.print("Requset recv: {any}\n", .{req});
    }

    std.debug.print("[*] Server shut down cleanly.\n", .{});
}
