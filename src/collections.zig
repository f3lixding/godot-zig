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
        method(&self.value, null, &out, 0);
        return out;
    }

    pub fn getVariant(self: *Array, index: i64) Variant {
        const method = builtinMethod(c.GDEXTENSION_VARIANT_TYPE_ARRAY, "get", 708700221);
        var idx = index;
        const args = [_]c.GDExtensionConstTypePtr{&idx};
        var out: types.Variant = undefined;
        method(&self.value, &args, &out, 1);
        return .{ .value = out };
    }

    pub fn getMeshArray(self: *Array, array_type: MeshArrayType) Variant {
        return self.getVariant(@intFromEnum(array_type));
    }

    pub fn vertices(self: *Array) PackedVector3Array {
        var v = self.getMeshArray(.vertex);
        defer v.destroy();
        return v.toPackedVector3Array();
    }

    pub fn indices(self: *Array) PackedInt32Array {
        var v = self.getMeshArray(.index);
        defer v.destroy();
        return v.toPackedInt32Array();
    }
};

pub const PackedVector3Array = struct {
    value: types.PackedVector3Array,

    pub fn destroy(self: *PackedVector3Array) void {
        api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR3_ARRAY, &self.value);
    }

    pub fn size(self: *PackedVector3Array) i64 {
        const method = builtinMethod(c.GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR3_ARRAY, "size", 3173160232);
        var out: i64 = 0;
        method(&self.value, null, &out, 0);
        return out;
    }

    pub fn get(self: *PackedVector3Array, index: i64) types.Vector3 {
        const method = builtinMethod(c.GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR3_ARRAY, "get", 1394941017);
        var idx = index;
        const args = [_]c.GDExtensionConstTypePtr{&idx};
        var out: types.Vector3 = .{};
        method(&self.value, &args, &out, 1);
        return out;
    }
};

pub const PackedInt32Array = struct {
    value: types.PackedInt32Array,

    pub fn destroy(self: *PackedInt32Array) void {
        api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_PACKED_INT32_ARRAY, &self.value);
    }

    pub fn size(self: *PackedInt32Array) i64 {
        const method = builtinMethod(c.GDEXTENSION_VARIANT_TYPE_PACKED_INT32_ARRAY, "size", 3173160232);
        var out: i64 = 0;
        method(&self.value, null, &out, 0);
        return out;
    }

    pub fn get(self: *PackedInt32Array, index: i64) i64 {
        const method = builtinMethod(c.GDEXTENSION_VARIANT_TYPE_PACKED_INT32_ARRAY, "get", 4103005248);
        var idx = index;
        const args = [_]c.GDExtensionConstTypePtr{&idx};
        var out: i64 = 0;
        method(&self.value, &args, &out, 1);
        return out;
    }
};
