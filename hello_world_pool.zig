const std = @import("std");
const ThreadPool = std.Thread.Pool;
const dprint = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const child_alloc = gpa.allocator();
const RndGen = std.rand.DefaultPrng;

const pool_size = 10;

fn hello(rank: usize, t: u8) void {
    std.time.sleep(@as(u64, t) * 1_000_000_000);
    dprint("hello after sleeping for {} seconds, from thread {} of {}\n", .{ t, rank, pool_size });
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(child_alloc);
    var allocator = arena.allocator();

    const seed: u64 = @intCast(std.time.nanoTimestamp());
    var prng = RndGen.init(seed);

    var pool: ThreadPool = undefined;
    try pool.init(.{
        .allocator = allocator,
        .n_jobs = pool_size,
    });
    errdefer pool.deinit();
    defer pool.deinit();

    for (0..10) |i| {
        try pool.spawn(hello, .{ i, (prng.random().int(u8) % 10) });
    }

    dprint("from main\n", .{});
}
