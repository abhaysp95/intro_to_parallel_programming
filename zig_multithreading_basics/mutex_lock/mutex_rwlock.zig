// synchronizing using mutex. RwLock has to do state-keeping, which can cost
// bit of performance but if you have to read some state much more than perform
// write on it, this is beneficial

const std = @import("std");
const dprint = std.debug.print;
const time = std.time;
const Thread = std.Thread;
const RwLock = std.Thread.RwLock;

const Counter = struct {
    count: u8 = 0,
    lock: RwLock = .{},

    pub fn increment(self: *Counter) void {
        self.lock.lock();
        defer self.lock.unlock();

        const before = self.count;
        time.sleep(250 * time.ns_per_ms);
        self.count +%= 1;
        dprint("write count {} -> {}\n", .{ before, self.count });
    }

    pub fn print(self: *Counter) void {
        self.lock.lockShared();
        defer self.lock.unlockShared();

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
        var thread = try std.Thread.spawn(.{}, increment_counter, .{&counter});
        thread.detach();
    }

    for (0..100) |_| {
        var thread = try std.Thread.spawn(.{}, print_counter, .{&counter});
        thread.detach();
    }

    time.sleep(5 * time.ns_per_s);
    dprint("\n", .{});
}
