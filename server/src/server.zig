const std = @import("std");
const net = std.net;
const mem = std.mem;
const fs = std.fs;
const Mime = @import("mime.zig").Mime;
const FileMonitor = @import("./file-monitor.zig").FileMonitor;

pub const HTTPServer = struct {
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var self_port_addr: u16 = undefined;
    var self_ipaddr: []const u8 = undefined;
    var monitor: FileMonitor = undefined;
    // var files = std.ArrayList([]const u8).init(allocator);
    var files: [][]const u8 = undefined;

    listener: net.Server,
    dir: fs.Dir,
    // files: ?[]fs.File = null,

    pub fn init(public_path:[]const u8,ipaddr:[]const u8,  port_addr:u16) !HTTPServer {
        self_port_addr = port_addr;
        self_ipaddr = ipaddr;
        const dir = try fs.cwd().openDir(public_path, .{});
        var self_addr = try net.Address.resolveIp(self_ipaddr, self_port_addr);
        const listener = listen: while(true) {
            if(net.Address.listen(self_addr, .{})) |_listener| {
                break :listen _listener;
            } else |err| {
                switch(err) {
                    error.AddressInUse => {
                        try stdout.print("port :{} is already in use.\n", .{port_addr});
                        self_port_addr += 1;
                        self_addr = try net.Address.resolveIp(self_ipaddr, self_port_addr);
                    },
                    else => std.debug.print("{s}\n", .{@errorName(err)}),
                }
            }
        };

        var _server=  .{
            .dir = dir,
            .listener = listener,
        };
        _=&_server;

        return _server;
    }

    pub fn serve(self:*HTTPServer) !noreturn {
        try stdout.print("listening on {s}:{}\npress Ctrl-C to quit...\n", .{self_ipaddr, self_port_addr});
        while (self.listener.accept()) |conn| {
            const fork_pid = try std.posix.fork();
            if (fork_pid == 0) {
                // child process
                std.log.info("Accepted Connection from: {}", .{conn.address});
                self.handleStream(@constCast(&conn.stream)) catch |err| {
                    if (@errorReturnTrace()) |bt| {
                        std.log.err("Failed to serve client: {}: {}", .{ err, bt });
                    } else {
                        std.log.err("Failed to serve client: {}", .{err});
                    }
                };
            } else {
                // parent process
                const wait_result = std.posix.waitpid(fork_pid, 0);
                if (wait_result.status != 0) {
                    try stdout.print("終了コード: {}\n", .{wait_result.status});
                }
            }
            // std.debug.print("fileName:{s}\n", .{files[0]});
            // monitor = try FileMonitor.init("index.html", self.dir);
            //
            // while(true) {
            //     std.time.sleep(1_000_000_000);
            //     if(try monitor.detectChanges()) {
            //         self.sendFile(@constCast(&conn.stream), "index.html") catch |err| {
            //             if (@errorReturnTrace()) |bt| {
            //                 std.log.err("Failed to serve client: {}: {}", .{ err, bt });
            //             } else {
            //                 std.log.err("Failed to serve client: {}", .{err});
            //             }
            //         };
            //     }
            // }
            conn.stream.close();
        } else |err| {
            std.log.err("Failed to accept connection: {}", .{err});
            return err;
        }
    }

    fn handleStream(self:*HTTPServer, stream: *net.Stream) !void {
        var recv_buf: [2048]u8 = undefined;
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

        const file_path = try self.extractFileName(recv_slice);
        try self.sendFile(stream, file_path);
    }

    fn extractFileName(self:*HTTPServer, recv:[]u8) ![]const u8 {
        _=&self;
        var file_path: []const u8 = undefined;
        var tok_itr = mem.tokenize(u8, recv, " ");

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

        return file_path;
    }

    fn complementFileName(self:*HTTPServer, fileName:[]const u8) ![]const u8 {
        _=&self;
        var tmp_fileName = fileName;
        const file_ext = fs.path.extension(tmp_fileName);
        if (file_ext.len == 0) {
            // /hogeのとき.htmlを補完する
            var path_buf: [fs.MAX_PATH_BYTES]u8 = undefined;
            // try files.insert(0, try std.fmt.bufPrint(&path_buf, "{s}.html", .{files.pop()}));
            tmp_fileName = try std.fmt.bufPrint(&path_buf, "{s}.html", .{tmp_fileName});
        }
        return tmp_fileName;
    }

    fn sendFile(self:*HTTPServer,stream: *net.Stream, fileName:[]const u8) !void {
        const file = try self.complementFileName(fileName);
        try stdout.print("Opening {s}\n", .{file});

        // openFile()に渡す引数fileはなぜか""で上書きされて返ってくる...?
        var body_file = self.dir.openFile(file, .{}) catch {
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

        const mime = Mime.asMime(file);

        std.log.info(" >>>\n" ++ http_head, .{ mime.asText(), file_len });
        try stream.writer().print(http_head, .{ mime.asText(), file_len });

        var send_total: usize = 0;
        var send_len: usize = 0;
        while (true) {
            var buf: [2048]u8 = undefined;
            send_len = try body_file.read(&buf);
            if (send_len == 0)
            break;
            try stream.writer().writeAll(buf[0..send_len]);

            send_total += send_len;
        }

    }
};

const ServeFileError = error{
RecvHeaderEOF,
RecvHeaderExceededBuffer,
HeaderDidNotMatch,
FileNotFound,
};
