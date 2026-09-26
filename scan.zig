const std = @import("std");
const net = std.net;
const Thread = std.Thread;
const Mutex = Thread.Mutex;

// ====================== CONFIG ======================
const NETWORK = "104.18.16.0/20";
const WORKERS = 32;
const TIMEOUT_MS: u64 = 500;
// ====================================================

var alive_list: std.ArrayList([]const u8) = undefined;
var mutex: Mutex = .{};

fn isAlive(ip: []const u8) bool {
    const allocator = std.heap.page_allocator;

    var args = std.ArrayList([]const u8).init(allocator);
    defer args.deinit();

    args.append("ping") catch return false;

    if (@import("builtin").os.tag == .windows) {
        args.append("-n") catch return false;
        args.append("1") catch return false;
        args.append("-w") catch return false;
        args.append(std.fmt.allocPrint(allocator, "{d}", .{TIMEOUT_MS}) catch return false) catch return false;
    } else {
        args.append("-c") catch return false;
        args.append("1") catch return false;
        args.append("-W") catch return false;
        args.append(std.fmt.allocPrint(allocator, "{d}", .{TIMEOUT_MS / 1000}) catch return false) catch return false;
    }
    args.append(ip) catch return false;

    const result = std.ChildProcess.exec(.{
        .allocator = allocator,
        .argv = args.items,
    }) catch return false;

    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    return result.term.Exited == 0;
}

fn worker(ips: [][]const u8, start: usize, end: usize) void {
    var i = start;
    while (i < end) : (i += 1) {
        if (isAlive(ips[i])) {
            mutex.lock();
            defer mutex.unlock();
            std.debug.print("[+] {s}\n", .{ips[i]});
            alive_list.append(ips[i]) catch {};
        }
    }
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    alive_list = std.ArrayList([]const u8).init(allocator);
    defer alive_list.deinit();

    std.debug.print("Scanning {s} with {d} workers...\n", .{ NETWORK, WORKERS });
    std.debug.print("This may take a while depending on the range size.\n\n", .{});

    // Simple IP generation for demo (full CIDR parsing is longer in Zig)
    // For production use a proper CIDR library
    var ips = std.ArrayList([]const u8).init(allocator);
    defer ips.deinit();

    // Generate a small range example - user should expand this
    // Full implementation would parse the CIDR properly
    try ips.append("104.18.16.1");
    try ips.append("104.18.16.2");
    // ... (in real use, implement full CIDR expansion)

    const total = ips.items.len;
    std.debug.print("Total hosts to scan: {d}\n\n", .{total});

    var threads: [WORKERS]Thread = undefined;
    const chunk = (total + WORKERS - 1) / WORKERS;

    var t: usize = 0;
    while (t < WORKERS) : (t += 1) {
        const start = t * chunk;
        const end = @min(start + chunk, total);
        if (start >= total) break;
        threads[t] = try Thread.spawn(.{}, worker, .{ ips.items, start, end });
    }

    t = 0;
    while (t < WORKERS) : (t += 1) {
        if (t * chunk < total) threads[t].join();
    }

    const file = try std.fs.cwd().createFile("reachable.txt", .{});
    defer file.close();

    for (alive_list.items) |ip| {
        try file.writer().print("{s}\n", .{ip});
    }

    std.debug.print("\n========================================\n", .{});
    std.debug.print("Done! {d}/{d} hosts are reachable\n", .{ alive_list.items.len, total });
    std.debug.print("Results saved to: reachable.txt\n", .{});
    std.debug.print("========================================\n", .{});
}
