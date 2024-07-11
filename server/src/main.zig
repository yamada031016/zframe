const std = @import("std");
const HTTPServer = @import("server.zig").HTTPServer;

pub fn main() !void {
    var args = std.process.args();
    const exe_name = args.next() orelse "toyserver";
    const public_path = args.next() orelse {
        std.log.err("Usage: {s} <dir to serve files from>", .{exe_name});
        return;
    };
    const act = std.posix.Sigaction{
        .handler = .{ .handler = std.posix.SIG.ERR },
        .mask = std.posix.empty_sigset,
        .flags = 0,
    };

    const port_addr:u16 = 8000;
    const ip_addr = "127.0.0.1";
    try std.posix.sigaction(std.posix.SIG.INT, &act, null);

    var server = try HTTPServer.init(public_path,ip_addr,  port_addr);
    try server.serve();
}
