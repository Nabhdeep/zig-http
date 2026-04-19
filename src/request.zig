const std = @import("std");
const Method = @import("method.zig").Method;
const Stream = std.Io.net.Stream;

pub const Request = struct {
    method: Method,
    version: []const u8,
    uri: []const u8,
    pub fn init(method: Method, version: []const u8, uri: []const u8) Request {
        return Request{
            .method = method,
            .uri = uri,
            .version = version,
        };
    }

    pub fn parse_request(text: []u8) Request {
        const idx = std.mem.indexOfScalar(u8, text, '\n') orelse text.len;
        var iterator = std.mem.splitScalar(u8, text[0..idx], ' ');
        const method = try Method.init(iterator.next().?);
        const uri = iterator.next().?;
        const version = iterator.next().?;
        const request = Request.init(method, version, uri);
        return request;
    }

    pub fn read_request(io: std.Io, conn: Stream, buffer: []u8) !void {
        var recv_buffer: [1024]u8 = undefined;
        var reader = conn.reader(io, &recv_buffer);
        const reader_interface = &reader.interface;
        var idx: usize = 0;
        for (0..10) |_| {
            const len = try read_next_line(reader_interface, buffer, idx);
            idx += len;
        }
    }

    fn read_next_line(reader: *std.Io.Reader, buffer: []u8, idx: usize) !usize {
        const next_line = try reader.takeDelimiterInclusive('\n');
        @memcpy(buffer[idx..(idx + next_line.len)], next_line[0..]);
        return next_line.len;
    }
};
