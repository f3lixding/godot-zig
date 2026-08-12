const c = @import("c.zig").c;
const api_mod = @import("api.zig");
const Object = @import("object.zig").Object;
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

pub const Input = struct {
    object: Object,

    pub fn singleton() Input {
        return .{ .object = .init(api_mod.godot.singleton("Input")) };
    }

    pub fn setMouseMode(self: Input, mode: MouseMode) void {
        const method = api_mod.godot.bind("Input", "set_mouse_mode", 2228490894);
        self.object.call1(method, @intFromEnum(mode));
    }

    pub fn mouseMode(self: Input) MouseMode {
        const method = api_mod.godot.bind("Input", "get_mouse_mode", 965286182);
        return @enumFromInt(self.object.callRet(i64, method));
    }

    pub fn isPhysicalKeyPressed(self: Input, key: Key) bool {
        const method = api_mod.godot.bind("Input", "is_physical_key_pressed", 1938909964);
        return self.object.call1Ret(u8, method, @intFromEnum(key)) != 0;
    }

    pub fn lastMouseVelocity(self: Input) types.Vector2 {
        const method = api_mod.godot.bind("Input", "get_last_mouse_velocity", 1497962370);
        return self.object.callRet(types.Vector2, method);
    }

    pub fn wasdVector(self: Input) types.Vector2 {
        var x: f32 = 0;
        var y: f32 = 0;
        if (self.isPhysicalKeyPressed(.a)) x -= 1;
        if (self.isPhysicalKeyPressed(.d)) x += 1;
        if (self.isPhysicalKeyPressed(.w)) y -= 1;
        if (self.isPhysicalKeyPressed(.s)) y += 1;
        return (types.Vector2{ .x = x, .y = y }).normalized();
    }
};
