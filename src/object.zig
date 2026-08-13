const c = @import("c.zig").c;
const api_mod = @import("api.zig");

/// Minimal raw object handle used by generated class wrappers.
///
/// Godot engine classes themselves are generated from `extension_api.json` in
/// `src/generated/classes.zig`. Keep this file small: it is the common object
/// storage/escape hatch, not a hand-written class binding layer.
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
};
