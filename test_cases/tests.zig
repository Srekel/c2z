const std = @import("std");
const cpp = @import("cpp");
const mem = std.mem;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "inheritance" {
    const fii = @import("c005_inheritance.zig");

    var circle: fii.circle_t = fii.circle_t.init();
    //try std.testing.expectEqual(@as(usize, 0), @as(usize, @ptrToInt(circle.base.vtable)));
    try expect(circle.radius == 0);
    circle = fii.circle_t.initRadius(10);
    try expect(circle.radius == 10);
    try expect(circle.radius == 10);
    try expect(circle.area() == 3.14 * 10 * 10);
    try expect(fii.circle_t.area(&circle) == 3.14 * 10 * 10);
    circle.deinit();
}

test "enum_flags" {
    const ffi = @import("c009_enum_flags.zig");

    var wflags: ffi.ImGuiWindowFlags_ = .{};
    wflags.bits |= ffi.ImGuiWindowFlags_.NoTitleBar.bits;
    wflags = wflags.merge(ffi.ImGuiWindowFlags_.AlwaysAutoResize);
    wflags = wflags.merge(ffi.ImGuiWindowFlags_.AlwaysAutoResize);
    try expect(wflags.contains(ffi.ImGuiWindowFlags_.AlwaysAutoResize));

    var cflags: ffi.ConfigFlags = .{};
    cflags.bits |= ffi.ConfigFlags.FLAG_VSYNC_HINT.bits;
    try expect(cflags.contains(ffi.ConfigFlags.FLAG_VSYNC_HINT));
}

test "index_this" {
    const fii = @import("c011_index_this.zig");

    var p: fii.ImVec2 = .{ .x = 1, .y = 2 };
    try expect(p.get(0) == 1);
    try expect(p.get(1) == 2);
    p.getPtr(0).* = 2;
    try expect(p.get(0) == 2);
}

test "cpp_vector" {
    const fii = @import("c013_cpp_vector.zig");

    // fails on MSVC release mode because `DebugData` isn't initialized
    var v = cpp.Vector(u8).init(.{});
    try expect(@ptrToInt(v.values().ptr) != 0); // odd, but expected
    try expect(v.values().len == 0);
    _ = fii.enumerate(&v, 15);
    for (v.values(), 0..) |num, i| {
        try expect(num == i);
    }
    v.deinit();

    // // todo: std.valgrind ??
    // // dumb way of checking if the memory is leaking on my windows machine ... and after a couple of minutes it isn't
    // while (true) {
    //     _ = fii.enumerate(&v, 256);
    //     v.deinit(); // this doesn't
    //     //v = .{}; // this leaks memory
    // }
}

test "cpp_string" {
    const fii = @import("c022_cpp_string.zig");

    try expectEqual(@as(c_int, @sizeOf(cpp.String)), fii.size_of_string());

    var tmp = fii.get_str();
    try expectEqual("Hello, World!".len, tmp.size());
    try expectEqual(fii.cap(&tmp), @intCast(c_int, tmp.capacity()));
    try expectEqual(fii.data(&tmp), @ptrCast([*c]const u8, tmp.values().ptr));
    defer tmp.deinit();
    try expect(mem.eql(u8, tmp.values(), "Hello, World!"));

    var buffer = cpp.String.init(.{});
    defer buffer.deinit();

    _ = fii.write_numbers(&buffer, 5);
    try expect(mem.eql(u8, buffer.values(), "0, 1, 2, 3, 4"));
    _ = fii.write_numbers(&buffer, 5);
    try expect(mem.eql(u8, buffer.values(), "0, 1, 2, 3, 4, 0, 1, 2, 3, 4"));

    _ = fii.write_numbers(&buffer, 5);
    _ = fii.write_numbers(&buffer, 5);
    _ = fii.write_numbers(&buffer, 5);
    try expect(mem.eql(u8, buffer.values(), "0, 1, 2, 3, 4, 0, 1, 2, 3, 4, 0, 1, 2, 3, 4, 0, 1, 2, 3, 4, 0, 1, 2, 3, 4"));

    // // dumb way of checking if the memory is leaking on my windows machine ... and after a couple of minutes it isn't
    // while (true) {
    //     _ = fii.write_numbers(&buffer, 256);
    //     buffer.deinit(); // this doesn't
    //     //buffer = cpp.String.init(.{}); // this leaks memory
    // }
}