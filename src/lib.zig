const std = @import("std");
const c = @import("c.zig");
const log = std.log.scoped(.nfd);

pub const Error = error {
    NfdError,
};

pub fn makeError() Error {
    if (c.NFD_GetError()) |ptr| {
        log.debug("{}\n", .{
            std.mem.span(ptr),
        });
    }
    return error.NfdError;
}

/// Open single file dialog
pub fn openFileDialog(filter: ?[:0]const u8, default_path: ?[:0]const u8) Error!?[:0]const u8 {
    var out_path: [*c]u8 = null;

    // allocates using malloc
    const result = c.NFD_OpenDialog(
        if (filter != null) filter.? else null, 
        if (default_path != null) default_path.? else null,
        &out_path);

    return switch (result) {
        .NFD_OKAY => if (out_path == null) null else std.mem.spanZ(out_path),
        .NFD_ERROR => makeError(),
        else => null,
    };
}

/// Open save dialog
pub fn saveFileDialog(filter: ?[:0]const u8, default_path: ?[:0]const u8) Error!?[:0]const u8 {
    var out_path: [*c]u8 = null;

    // allocates using malloc
    const result = c.NFD_SaveDialog(
        if (filter != null) filter.? else null, 
        if (default_path != null) default_path.? else null,
        &out_path);

    return switch (result) {
        .NFD_OKAY => if (out_path == null) null else std.mem.spanZ(out_path),
        .NFD_ERROR => makeError(),
        else => null,
    };
}

pub fn freePath(path: []const u8) void {
    std.c.free(@intToPtr(*c_void, @ptrToInt(path.ptr)));
}
