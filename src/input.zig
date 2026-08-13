const generated = @import("generated/root.zig");
const types = @import("types.zig");

pub const Key = enum(i64) {
    space = 32,
    a = 65,
    d = 68,
    s = 83,
    w = 87,
    escape = 4194305,
    _,
};

pub const MouseMode = enum(i64) {
    visible = 0,
    hidden = 1,
    captured = 2,
    confined = 3,
    confined_hidden = 4,
};

/// Convenience helpers over the generated Input singleton.
/// The actual Godot methods are generated in `generated.classes.Input`.
pub const Input = generated.classes.Input;

pub fn setMouseMode(input: Input, mode: MouseMode) void {
    input.@"set_mouse_mode"(@intFromEnum(mode));
}

pub fn mouseMode(input: Input) MouseMode {
    return @enumFromInt(input.@"get_mouse_mode"());
}

pub fn isPhysicalKeyPressed(input: Input, key: Key) bool {
    return input.@"is_physical_key_pressed"(@intFromEnum(key));
}

pub fn wasdVector(input: Input) types.Vector2 {
    var x: f32 = 0;
    var y: f32 = 0;
    if (isPhysicalKeyPressed(input, .a)) x -= 1;
    if (isPhysicalKeyPressed(input, .d)) x += 1;
    if (isPhysicalKeyPressed(input, .w)) y -= 1;
    if (isPhysicalKeyPressed(input, .s)) y += 1;
    return (types.Vector2{ .x = x, .y = y }).normalized();
}
