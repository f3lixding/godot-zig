const c = @import("c.zig").c;
const api_mod = @import("api.zig");
const types = @import("types.zig");

pub const Variant = struct {
    value: types.Variant,

    pub fn fromInt(value: i64) Variant {
        var out: types.Variant = undefined;
        var v = value;
        api_mod.godot.get_variant_from_type_constructor.?(c.GDEXTENSION_VARIANT_TYPE_INT).?(&out, &v);
        return .{ .value = out };
    }

    pub fn fromBool(value: bool) Variant {
        var out: types.Variant = undefined;
        var v: u8 = @intFromBool(value);
        api_mod.godot.get_variant_from_type_constructor.?(c.GDEXTENSION_VARIANT_TYPE_BOOL).?(&out, &v);
        return .{ .value = out };
    }

    pub fn fromFloat(value: f64) Variant {
        var out: types.Variant = undefined;
        var v = value;
        api_mod.godot.get_variant_from_type_constructor.?(c.GDEXTENSION_VARIANT_TYPE_FLOAT).?(&out, &v);
        return .{ .value = out };
    }

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

    pub fn toObjectPtr(self: *Variant) c.GDExtensionObjectPtr {
        return self.toBuiltin(c.GDExtensionObjectPtr, c.GDEXTENSION_VARIANT_TYPE_OBJECT);
    }

    pub fn toString(self: *Variant) types.String {
        return self.toBuiltin(types.String, c.GDEXTENSION_VARIANT_TYPE_STRING);
    }

    pub fn toStringName(self: *Variant) types.StringName {
        return self.toBuiltin(types.StringName, c.GDEXTENSION_VARIANT_TYPE_STRING_NAME);
    }

    pub fn toDictionary(self: *Variant) types.Dictionary {
        return self.toBuiltin(types.Dictionary, c.GDEXTENSION_VARIANT_TYPE_DICTIONARY);
    }

    pub fn toArray(self: *Variant) @import("collections.zig").Array {
        return .{ .value = self.toBuiltin(types.Array, c.GDEXTENSION_VARIANT_TYPE_ARRAY) };
    }

    pub fn toPackedVector3Array(self: *Variant) @import("collections.zig").PackedVector3Array {
        return @import("collections.zig").PackedVector3Array.fromVariant(self);
    }

    pub fn toPackedInt32Array(self: *Variant) @import("collections.zig").PackedInt32Array {
        return @import("collections.zig").PackedInt32Array.fromVariant(self);
    }
};
