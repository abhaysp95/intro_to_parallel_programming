// no synchronization to write

const std = @import("std");
const dprint = std.debug.print;
const time = std.time;
const Thread = std.Thread;

const Counter = struct {
    count: u8 = 0,

    pub fn increment(self: *Counter) void {
        const before = self.count;
        time.sleep(250 * time.ns_per_ms);
        self.count +%= 1;
        dprint("write count {} -> {}\n", .{ before, self.count });
    }

    pub fn print(self: *Counter) void {
        dprint("read count: {}, ", .{self.count});
    }
};

fn increment_counter(counter: *Counter) void {
    while (true) {
        time.sleep(500 * time.ns_per_ms);
        counter.increment();
    }
}

fn print_counter(counter: *Counter) void {
    while (true) {
        time.sleep(250 * time.ns_per_ms);
        counter.print();
    }
}

pub fn main() !void {
    var counter = Counter{};

    for (0..10) |_| {
        var thread = try Thread.spawn(.{}, increment_counter, .{&counter});
        thread.detach();
    }

    for (0..100) |_| {
        var thread = try Thread.spawn(.{}, print_counter, .{&counter});
        thread.detach();
    }

    time.sleep(1 * time.ns_per_s);
    dprint("\n", .{});
}
