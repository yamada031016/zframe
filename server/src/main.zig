const std = @import("std");
const net = std.net;
const mem = std.mem;
const fs = std.fs;
const io = std.io;

pub fn main() anyerror!void {
    var args = std.process.args();
    const exe_name = args.next() orelse "toyserver";
    const public_path = args.next() orelse {
        std.log.err("Usage: {s} <dir to serve files from>", .{exe_name});
        return;
    };

    const dir = try fs.cwd().openDir(public_path, .{});
    const self_addr = try net.Address.resolveIp("127.0.0.1", 8000);
    var listener = try net.Address.listen(self_addr, .{});
    defer listener.deinit();
    // try (&listener).listen(self_addr);

    std.log.info("listening on {};press Ctrl-C to quit...", .{self_addr});

    while (listener.accept()) |conn| {
        std.log.info("Accepted Connection from: {}", .{conn.address});

        serveFile(@constCast(&conn.stream), dir) catch |err| {
            if (@errorReturnTrace()) |bt| {
                std.log.err("Failed to serve client: {}: {}", .{ err, bt });
            } else {
                std.log.err("Failed to serve client: {}", .{err});
            }
        };

        conn.stream.close();
    } else |err| {
        return err;
    }
}

const ServeFileError = error{
    RecvHeaderEOF,
    RecvHeaderExceededBuffer,
    HeaderDidNotMatch,
    FileNotFound,
};
const Mime = enum {
    html,
    css,
    map,
    svg,
    jpg,
    png,
    other,

    pub fn asMime(mime: []const u8) Mime {
        // 超雑な変換
        return switch (mime[1]) {
            'h' => .html,
            'c' => .css,
            'm' => .map,
            's' => .svg,
            'j' => .jpg,
            'p' => .png,
            else => .other,
        };
    }
    pub fn asText(self: *const Mime) []const u8 {
        return switch (self.*) {
            .html => "text/html",
            .css => "text/css",
            .map => "application/json",
            .svg => "image/svg+xml",
            .jpg => "image/jpg",
            .png => "image/png",
            .other => "text/plain",
        };
    }
};

fn serveFile(stream: *net.Stream, dir: fs.Dir) !void {
    var recv_buf: [1024]u8 = undefined;
    var recv_total: usize = 0;

    while (stream.read(recv_buf[recv_total..])) |recv_len| {
        if (recv_len == 0)
            return ServeFileError.RecvHeaderEOF;

        recv_total += recv_len;

        if (mem.containsAtLeast(u8, recv_buf[0..recv_total], 1, "\r\n\r\n"))
            break;

        if (recv_total >= recv_buf.len)
            return ServeFileError.RecvHeaderExceededBuffer;
    } else |read_err| {
        return read_err;
    }

    const recv_slice = recv_buf[0..recv_total];
    std.log.info(" <<<\n{s}", .{recv_slice});

    var file_path: []const u8 = undefined;
    var tok_itr = mem.tokenize(u8, recv_slice, " ");

    if (!mem.eql(u8, tok_itr.next() orelse "", "GET"))
        return ServeFileError.HeaderDidNotMatch;

    const path = tok_itr.next() orelse "";
    if (path[0] != '/')
        return ServeFileError.HeaderDidNotMatch;

    if (mem.eql(u8, path, "/"))
        file_path = "index"
    else
        file_path = path[1..];

    if (!mem.startsWith(u8, tok_itr.rest(), "HTTP/1.1\r\n"))
        return ServeFileError.HeaderDidNotMatch;

    var file_ext = fs.path.extension(file_path);
    if (file_ext.len == 0) {
        // /hogeのとき.htmlを補完する
        var path_buf: [fs.MAX_PATH_BYTES]u8 = undefined;
        file_path = try std.fmt.bufPrint(&path_buf, "{s}.html", .{file_path});
        file_ext = ".html";
    }

    std.log.info("Opening {s}", .{file_path});

    var body_file = dir.openFile(file_path, .{}) catch {
        try stream.writeAll(
            \\HTTP/1.1 404 Not Found
            \\Content-Type: text/plain
            \\
            \\404 Not Found
        );
        return ServeFileError.FileNotFound;
    };
    defer body_file.close();

    const file_len = try body_file.getEndPos();

    const http_head =
        \\HTTP/1.1 200 OK
        \\Connection: close
        \\Content-Type: {s}
        \\Content-Length: {}
        \\
        \\
    ;

    const mime = Mime.asMime(file_ext);

    std.log.info(" >>>\n" ++ http_head, .{ mime.asText(), file_len });
    try stream.writer().print(http_head, .{ mime.asText(), file_len });

    // var send_total: usize = 0;
    // var send_len: usize = 0;
    // while (true) {
    var buf: [1024]u8 = undefined;
    const file_read_len = try body_file.readAll(&buf);
    try stream.writer().writeAll(buf[0..file_read_len]);

    // if (send_len == 0)
    //     break;
    //
    // send_total += send_len;
    // }
}
