const std = @import("std");
const ThreadPool = std.Thread.Pool;
const WaitGroup = std.Thread.WaitGroup;
const dprint = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const child_alloc = gpa.allocator();
const RndGen = std.rand.DefaultPrng;

const POOL_COUNT = 10;

fn hello(rank: usize, wg: *WaitGroup, t: u8) void {
    defer wg.finish();
    std.time.sleep(@as(u64, t) * 1_000_000_000);
    dprint("Hello after sleeping {} seconds, from thread {} out of {}\n", .{ t, rank, POOL_COUNT });
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(child_alloc);
    var allocator = arena.allocator();

    var seed: u64 = @intCast(std.time.nanoTimestamp());
    var prng = RndGen.init(seed);

    var wg: WaitGroup = .{};

    var pool: ThreadPool = undefined;
    try pool.init(.{
        .allocator = allocator,
        .n_jobs = POOL_COUNT,
    });

    // not using deinit() to test out WaitGroup
    errdefer pool.deinit();
    // defer pool.deinit();

    for (0..10) |i| {
        wg.start();
        try pool.spawn(hello, .{ i, &wg, (prng.random().int(u8) % 10) });
    }

    wg.wait(); // wait() is isDone() are mutually exclusive
    dprint("Hello from main\n", .{});

    // going forward the 'pool' can be used again, which is not possible if you do 'pool.deinit()'
}
