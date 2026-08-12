const c = @import("c.zig").c;
const api_mod = @import("api.zig");
const types = @import("types.zig");

pub const Object = struct {
    ptr: c.GDExtensionObjectPtr = null,

    pub fn init(ptr: c.GDExtensionObjectPtr) Object {
        return .{ .ptr = ptr };
    }

    pub fn isNull(self: Object) bool {
        return self.ptr == null;
    }

    pub fn destroy(self: Object) void {
        if (self.ptr != null) api_mod.godot.object_destroy.?(self.ptr);
    }

    pub fn instanceId(self: Object) c.GDObjectInstanceID {
        return api_mod.godot.object_get_instance_id.?(self.ptr);
    }

    pub fn fromInstanceId(id: c.GDObjectInstanceID) Object {
        return .{ .ptr = api_mod.godot.object_get_instance_from_id.?(id) };
    }

    pub fn ptrcall(self: Object, method: c.GDExtensionMethodBindPtr, args: ?[*]const c.GDExtensionConstTypePtr, ret: c.GDExtensionTypePtr) void {
        api_mod.godot.object_method_bind_ptrcall.?(method, self.ptr, if (args) |a| a else null, ret);
    }

    pub fn call0(self: Object, method: c.GDExtensionMethodBindPtr) void {
        self.ptrcall(method, null, null);
    }

    pub fn callRet(self: Object, comptime T: type, method: c.GDExtensionMethodBindPtr) T {
        var out: T = undefined;
        self.ptrcall(method, null, &out);
        return out;
    }

    pub fn call1(self: Object, method: c.GDExtensionMethodBindPtr, arg0: anytype) void {
        var a0 = arg0;
        const args = [_]c.GDExtensionConstTypePtr{&a0};
        self.ptrcall(method, &args, null);
    }

    pub fn call1Ret(self: Object, comptime T: type, method: c.GDExtensionMethodBindPtr, arg0: anytype) T {
        var a0 = arg0;
        const args = [_]c.GDExtensionConstTypePtr{&a0};
        var out: T = undefined;
        self.ptrcall(method, &args, &out);
        return out;
    }

    pub fn call2Ret(self: Object, comptime T: type, method: c.GDExtensionMethodBindPtr, arg0: anytype, arg1: anytype) T {
        var a0 = arg0;
        var a1 = arg1;
        const args = [_]c.GDExtensionConstTypePtr{ &a0, &a1 };
        var out: T = undefined;
        self.ptrcall(method, &args, &out);
        return out;
    }

    pub fn call3Ret(self: Object, comptime T: type, method: c.GDExtensionMethodBindPtr, arg0: anytype, arg1: anytype, arg2: anytype) T {
        var a0 = arg0;
        var a1 = arg1;
        var a2 = arg2;
        const args = [_]c.GDExtensionConstTypePtr{ &a0, &a1, &a2 };
        var out: T = undefined;
        self.ptrcall(method, &args, &out);
        return out;
    }

    pub fn isClass(self: Object, class_name: [:0]const u8) bool {
        const method = api_mod.godot.bind("Object", "is_class", 2619796661);
        var name = api_mod.godot.stringName(class_name);
        defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &name);
        return self.call1Ret(u8, method, name) != 0;
    }
};

pub const Node = struct {
    object: Object,

    pub fn init(ptr: c.GDExtensionObjectPtr) Node { return .{ .object = .init(ptr) }; }

    pub fn findChild(self: Node, pattern_text: [:0]const u8, recursive: bool, owned: bool) Object {
        const method = api_mod.godot.bind("Node", "find_child", 2008217037);
        var pattern = api_mod.godot.string(pattern_text);
        defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING, &pattern);
        return .{ .ptr = self.object.call3Ret(c.GDExtensionObjectPtr, method, pattern, @as(u8, @intFromBool(recursive)), @as(u8, @intFromBool(owned))) };
    }
};

pub const Node3D = struct {
    object: Object,

    pub fn init(ptr: c.GDExtensionObjectPtr) Node3D { return .{ .object = .init(ptr) }; }

    pub fn setRotationDegrees(self: Node3D, rot: types.Vector3) void {
        const method = api_mod.godot.bind("Node3D", "set_rotation_degrees", 3460891852);
        self.object.call1(method, rot);
    }
};

pub const CharacterBody3D = struct {
    object: Object,

    pub fn init(ptr: c.GDExtensionObjectPtr) CharacterBody3D { return .{ .object = .init(ptr) }; }

    pub fn velocity(self: CharacterBody3D) types.Vector3 {
        const method = api_mod.godot.bind("CharacterBody3D", "get_velocity", 3360562783);
        return self.object.callRet(types.Vector3, method);
    }

    pub fn setVelocity(self: CharacterBody3D, value: types.Vector3) void {
        const method = api_mod.godot.bind("CharacterBody3D", "set_velocity", 3460891852);
        self.object.call1(method, value);
    }

    pub fn moveAndSlide(self: CharacterBody3D) bool {
        const method = api_mod.godot.bind("CharacterBody3D", "move_and_slide", 2240911060);
        return self.object.callRet(u8, method) != 0;
    }

    pub fn isOnFloor(self: CharacterBody3D) bool {
        const method = api_mod.godot.bind("CharacterBody3D", "is_on_floor", 36873697);
        return self.object.callRet(u8, method) != 0;
    }
};
