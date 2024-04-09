const std = @import("std");
const thread = std.Thread;
const dprint = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const child_allocator = gpa.allocator();
const RndGen = std.rand.DefaultPrng;

var thread_count: usize = 10;

fn hello(rank: usize, t: u8) void {
    std.time.sleep(@as(u64, t) * 1_000_000_000);
    dprint("hello after sleeping for {}, from thread {} of {}\n", .{ t, rank, thread_count });
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(child_allocator);
    var allocator = arena.allocator();

    const seed: u64 = @intCast(std.time.nanoTimestamp());
    var prng = RndGen.init(seed);

    var pool = try allocator.alloc(thread, 10);
    for (0..10) |i| {
        pool[i] = try thread.spawn(.{}, hello, .{ i, (prng.random().int(u8) % 10) });
    }

    for (0..10) |i| {
        pool[i].join();
    }
    dprint("from main\n", .{});
}
