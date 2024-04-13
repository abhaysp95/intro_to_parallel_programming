const std = @import("std");
const Thread = std.Thread;
const Atomic = std.atomic.Atomic;
const time = std.time;
const dprint = std.debug.print;

// std already have a WaitGroup implementation, this is just an example
const WaitGroup = struct {
    members: Atomic(usize),
    const Self = @This();

    fn init() Self {
        return .{
            .members = Atomic(usize).init(0),
        };
    }

    // new member joins the group
    fn add(self: *WaitGroup) void {
        _ = self.members.fetchAdd(1, .Acquire);
    }

    // existing members leave the group
    fn done(self: *WaitGroup) void {
        _ = self.members.fetchSub(1, .Release);
    }

    // wait for all members to leave
    fn wait(self: *WaitGroup) void {
        while (self.members.load(.Monotonic) > 0) {
            time.sleep(500 * time.ns_per_ms);
        }
    }
};

fn worker(id: usize, wg: *WaitGroup) void {
    // decrease the member from waitgroup on exiting
    defer wg.done();

    dprint("{} started\n", .{id});
    time.sleep(1 * time.ns_per_ms);
    dprint("{} finished\n", .{id});
}

pub fn main() !void {
    var wg = WaitGroup.init();
    defer wg.wait();

    for (0..5) |i| {
        wg.add();
        const thread = try Thread.spawn(.{}, worker, .{ i, &wg });
        thread.detach();
    }
}
