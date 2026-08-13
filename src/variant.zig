const c = @import("c.zig").c;
const api_mod = @import("api.zig");
const types = @import("types.zig");

pub const Variant = struct {
    value: types.Variant,

    pub fn destroy(self: *Variant) void {
        api_mod.godot.variant_destroy.?(&self.value);
    }

    pub fn getType(self: *const Variant) c.GDExtensionVariantType {
        return api_mod.godot.variant_get_type.?(&self.value);
    }

    pub fn toBuiltin(self: *Variant, comptime T: type, comptime variant_type: c.GDExtensionVariantType) T {
        var out: T = undefined;
        const ctor = api_mod.godot.get_variant_to_type_constructor.?(variant_type).?;
        ctor(&out, &self.value);
        return out;
    }

    pub fn toArray(self: *Variant) @import("collections.zig").Array {
        return .{ .value = self.toBuiltin(types.Array, c.GDEXTENSION_VARIANT_TYPE_ARRAY) };
    }

    pub fn toPackedVector3Array(self: *Variant) @import("collections.zig").PackedVector3Array {
        return .{ .value = self.toBuiltin(types.PackedVector3Array, c.GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR3_ARRAY) };
    }

    pub fn toPackedInt32Array(self: *Variant) @import("collections.zig").PackedInt32Array {
        return .{ .value = self.toBuiltin(types.PackedInt32Array, c.GDEXTENSION_VARIANT_TYPE_PACKED_INT32_ARRAY) };
    }
};
