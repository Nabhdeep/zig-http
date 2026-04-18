const std = @import("std");
const Stream = std.Io.net.Stream;

pub fn read_request(io: std.Io, conn: Stream, buffer: []u8) !void {
    var recv_buffer: [1024]u8 = undefined;
    var reader = conn.reader(io, &recv_buffer);
    const reader_interface = &reader.interface;
    var idx: usize = 0;
    for (0..5) |_| {
        const len = try read_next_line(reader_interface, buffer, idx);
        idx += len;
    }
}

fn read_next_line(reader: *std.Io.Reader, buffer: []u8, idx: usize) !usize {
    const next_line = try reader.takeDelimiterInclusive('\n');
    @memcpy(buffer[idx..(idx + next_line.len)], next_line[0..]);
    return next_line.len;
}
