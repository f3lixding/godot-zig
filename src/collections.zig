const c = @import("c.zig").c;
const api_mod = @import("api.zig");
const types = @import("types.zig");
const Variant = @import("variant.zig").Variant;

fn builtinMethod(comptime variant_type: c.GDExtensionVariantType, name: [:0]const u8, hash: i64) c.GDExtensionPtrBuiltInMethod {
    var method_name = api_mod.godot.stringName(name);
    defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &method_name);
    return api_mod.godot.variant_get_ptr_builtin_method.?(variant_type, &method_name, hash).?;
}

pub const Array = struct {
    value: types.Array,

    pub const MeshArrayType = enum(i64) {
        vertex = 0,
        normal = 1,
        tangent = 2,
        color = 3,
        tex_uv = 4,
        tex_uv2 = 5,
        custom0 = 6,
        custom1 = 7,
        custom2 = 8,
        custom3 = 9,
        bones = 10,
        weights = 11,
        index = 12,
        max = 13,
    };

    pub fn destroy(self: *Array) void {
        api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_ARRAY, &self.value);
    }

    pub fn size(self: *Array) i64 {
        const method = builtinMethod(c.GDEXTENSION_VARIANT_TYPE_ARRAY, "size", 3173160232);
        var out: i64 = 0;
        method.?(&self.value, null, &out, 0);
        return out;
    }

    pub fn getVariant(self: *Array, index: i64) Variant {
        const method = builtinMethod(c.GDEXTENSION_VARIANT_TYPE_ARRAY, "get", 708700221);
        var idx = index;
        const args = [_]c.GDExtensionConstTypePtr{&idx};
        var out: types.Variant = undefined;
        method.?(&self.value, &args, &out, 1);
        return .{ .value = out };
    }

    pub fn getMeshArray(self: *Array, array_type: MeshArrayType) Variant {
        return self.getVariant(@intFromEnum(array_type));
    }

    pub fn vertices(self: *Array) PackedVector3Array {
        var v = self.getMeshArray(.vertex);
        return v.toPackedVector3Array();
    }

    pub fn indices(self: *Array) PackedInt32Array {
        var v = self.getMeshArray(.index);
        return v.toPackedInt32Array();
    }
};

pub const PackedVector3Array = struct {
    value: types.PackedVector3Array = undefined,
    variant_value: ?types.Variant = null,
    internal: ?c.GDExtensionConstTypePtr = null,

    pub fn fromVariant(variant: *Variant) PackedVector3Array {
        const getter = api_mod.godot.variant_get_ptr_internal_getter.?(c.GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR3_ARRAY).?;
        const internal = getter(&variant.value);
        return .{ .variant_value = variant.value, .internal = internal };
    }

    fn ptr(self: *PackedVector3Array) c.GDExtensionConstTypePtr {
        return self.internal orelse &self.value;
    }

    pub fn destroy(self: *PackedVector3Array) void {
        if (self.variant_value) |*v| {
            api_mod.godot.variant_destroy.?(v);
            self.variant_value = null;
        } else {
            api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR3_ARRAY, &self.value);
        }
    }

    pub fn size(self: *PackedVector3Array) i64 {
        const method = builtinMethod(c.GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR3_ARRAY, "size", 3173160232);
        var out: i64 = 0;
        method.?(self.ptr(), null, &out, 0);
        return out;
    }

    pub fn get(self: *PackedVector3Array, index: i64) types.Vector3 {
        const p = api_mod.godot.packed_vector3_array_operator_index_const.?(self.ptr(), index);
        return @as(*const types.Vector3, @ptrCast(@alignCast(p))).*;
    }
};

pub const PackedInt32Array = struct {
    value: types.PackedInt32Array = undefined,
    variant_value: ?types.Variant = null,
    internal: ?c.GDExtensionConstTypePtr = null,

    pub fn fromVariant(variant: *Variant) PackedInt32Array {
        const getter = api_mod.godot.variant_get_ptr_internal_getter.?(c.GDEXTENSION_VARIANT_TYPE_PACKED_INT32_ARRAY).?;
        const internal = getter(&variant.value);
        return .{ .variant_value = variant.value, .internal = internal };
    }

    fn ptr(self: *PackedInt32Array) c.GDExtensionConstTypePtr {
        return self.internal orelse &self.value;
    }

    pub fn destroy(self: *PackedInt32Array) void {
        if (self.variant_value) |*v| {
            api_mod.godot.variant_destroy.?(v);
            self.variant_value = null;
        } else {
            api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_PACKED_INT32_ARRAY, &self.value);
        }
    }

    pub fn size(self: *PackedInt32Array) i64 {
        const method = builtinMethod(c.GDEXTENSION_VARIANT_TYPE_PACKED_INT32_ARRAY, "size", 3173160232);
        var out: i64 = 0;
        method.?(self.ptr(), null, &out, 0);
        return out;
    }

    pub fn get(self: *PackedInt32Array, index: i64) i32 {
        const p = api_mod.godot.packed_int32_array_operator_index_const.?(self.ptr(), index);
        return p.*;
    }
};
