const c = @import("c.zig").c;
const api_mod = @import("api.zig");

pub const Source = struct {
    function: [*:0]const u8 = "",
    file: [*:0]const u8 = "",
    line: i32 = 0,
    editor_notify: bool = false,
};

pub fn err(description: [*:0]const u8, source: Source) void {
    api_mod.godot.print_error.?(description, source.function, source.file, source.line, @intFromBool(source.editor_notify));
}

pub fn errMsg(description: [*:0]const u8, message: [*:0]const u8, source: Source) void {
    api_mod.godot.print_error_with_message.?(description, message, source.function, source.file, source.line, @intFromBool(source.editor_notify));
}

pub fn warn(description: [*:0]const u8, source: Source) void {
    api_mod.godot.print_warning.?(description, source.function, source.file, source.line, @intFromBool(source.editor_notify));
}

pub fn warnMsg(description: [*:0]const u8, message: [*:0]const u8, source: Source) void {
    api_mod.godot.print_warning_with_message.?(description, message, source.function, source.file, source.line, @intFromBool(source.editor_notify));
}

pub fn scriptErr(description: [*:0]const u8, source: Source) void {
    api_mod.godot.print_script_error.?(description, source.function, source.file, source.line, @intFromBool(source.editor_notify));
}

pub fn scriptErrMsg(description: [*:0]const u8, message: [*:0]const u8, source: Source) void {
    api_mod.godot.print_script_error_with_message.?(description, message, source.function, source.file, source.line, @intFromBool(source.editor_notify));
}

pub fn here(comptime function: [*:0]const u8, comptime file: [*:0]const u8, comptime line: i32) Source {
    return .{ .function = function, .file = file, .line = line };
}

/// Convenience source location for the call site.
pub fn src(comptime function: [*:0]const u8, comptime file: [*:0]const u8, comptime line: i32) Source {
    return here(function, file, line);
}

test "Source defaults" {
    const s: Source = .{};
    try @import("std").testing.expect(!s.editor_notify);
}
