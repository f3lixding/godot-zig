const std = @import("std");
const c = @import("c.zig").c;
const api_mod = @import("api.zig");
const types = @import("types.zig");
const Variant = @import("variant.zig").Variant;

fn builtinMethod(comptime variant_type: c.GDExtensionVariantType, name: [:0]const u8, hash: i64) c.GDExtensionPtrBuiltInMethod {
    var method_name = api_mod.godot.stringName(name);
    defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &method_name);
    return api_mod.godot.variant_get_ptr_builtin_method.?(variant_type, &method_name, hash).?;
}

pub const PackedByteArray = struct {
    value: types.PackedByteArray = std.mem.zeroes(types.PackedByteArray),
    variant_value: ?types.Variant = null,
    internal: ?c.GDExtensionConstTypePtr = null,

    pub fn init() PackedByteArray {
        var value: types.PackedByteArray = std.mem.zeroes(types.PackedByteArray);
        api_mod.godot.variant_get_ptr_constructor.?(c.GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY, 0).?(&value, null);
        return .{ .value = value };
    }

    pub fn fromSlice(bytes: []const u8) PackedByteArray {
        var array = init();
        _ = array.resize(@intCast(bytes.len));
        for (bytes, 0..) |byte, i| array.set(@intCast(i), byte);
        return array;
    }

    pub fn fromVariant(variant: *Variant) PackedByteArray {
        var variant_copy: types.Variant = std.mem.zeroes(types.Variant);
        api_mod.godot.variant_new_copy.?(&variant_copy, &variant.value);
        return .{ .variant_value = variant_copy };
    }

    pub fn ptr(self: *PackedByteArray) c.GDExtensionConstTypePtr {
        if (self.variant_value) |*v| {
            const getter = api_mod.godot.variant_get_ptr_internal_getter.?(c.GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY).?;
            return getter(v);
        }
        return self.internal orelse &self.value;
    }

    pub fn mutPtr(self: *PackedByteArray) c.GDExtensionTypePtr {
        return @constCast(self.ptr());
    }

    pub fn destroy(self: *PackedByteArray) void {
        if (self.variant_value) |*v| {
            api_mod.godot.variant_destroy.?(v);
            self.variant_value = null;
        } else {
            api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY, &self.value);
        }
    }

    pub fn size(self: *PackedByteArray) i64 {
        const method = builtinMethod(c.GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY, "size", 3173160232);
        var out: i64 = 0;
        method.?(self.mutPtr(), null, &out, 0);
        return out;
    }

    pub fn resize(self: *PackedByteArray, new_size: i64) i64 {
        const method = builtinMethod(c.GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY, "resize", 848867239);
        var size_arg = new_size;
        const args = [_]c.GDExtensionConstTypePtr{&size_arg};
        var out: i64 = 0;
        method.?(self.mutPtr(), &args, &out, 1);
        return out;
    }

    pub fn get(self: *PackedByteArray, index: i64) u8 {
        return api_mod.godot.packed_byte_array_operator_index_const.?(self.ptr(), index).*;
    }

    pub fn set(self: *PackedByteArray, index: i64, value: u8) void {
        api_mod.godot.packed_byte_array_operator_index.?(self.mutPtr(), index).* = value;
    }
};

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
        var out: types.Variant = std.mem.zeroes(types.Variant);
        method.?(&self.value, &args, &out, 1);
        return .{ .value = out };
    }

    pub fn getMeshArray(self: *Array, array_type: MeshArrayType) Variant {
        return self.getVariant(@intFromEnum(array_type));
    }

    pub fn setVariant(self: *Array, index: i64, value: *const Variant) void {
        const method = builtinMethod(c.GDEXTENSION_VARIANT_TYPE_ARRAY, "set", 3798478031);
        var idx = index;
        const args = [_]c.GDExtensionConstTypePtr{ &idx, &value.value };
        method.?(&self.value, &args, null, 2);
    }

    pub fn setPackedVector3Array(self: *Array, array_type: MeshArrayType, value: *PackedVector3Array) void {
        var variant = value.toVariant();
        defer variant.destroy();
        self.setVariant(@intFromEnum(array_type), &variant);
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
    value: types.PackedVector3Array = std.mem.zeroes(types.PackedVector3Array),
    variant_value: ?types.Variant = null,
    internal: ?c.GDExtensionConstTypePtr = null,

    pub fn init() PackedVector3Array {
        var value: types.PackedVector3Array = std.mem.zeroes(types.PackedVector3Array);
        api_mod.godot.variant_get_ptr_constructor.?(c.GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR3_ARRAY, 0).?(&value, null);
        return .{ .value = value };
    }

    pub fn fromSlice(values: []const types.Vector3) PackedVector3Array {
        var array = init();
        _ = array.resize(@intCast(values.len));
        for (values, 0..) |value, i| array.set(@intCast(i), value);
        return array;
    }

    pub fn fromVariant(variant: *Variant) PackedVector3Array {
        const getter = api_mod.godot.variant_get_ptr_internal_getter.?(c.GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR3_ARRAY).?;
        const internal = getter(&variant.value);
        return .{ .variant_value = variant.value, .internal = internal };
    }

    pub fn ptr(self: *PackedVector3Array) c.GDExtensionConstTypePtr {
        return self.internal orelse &self.value;
    }

    pub fn mutPtr(self: *PackedVector3Array) c.GDExtensionTypePtr {
        return @constCast(self.ptr());
    }

    pub fn toVariant(self: *PackedVector3Array) Variant {
        var out: types.Variant = std.mem.zeroes(types.Variant);
        const constructor = api_mod.godot.get_variant_from_type_constructor.?(
            c.GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR3_ARRAY,
        ).?;
        constructor(&out, self.mutPtr());
        return .{ .value = out };
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
        method.?(self.mutPtr(), null, &out, 0);
        return out;
    }

    pub fn resize(self: *PackedVector3Array, new_size: i64) i64 {
        const method = builtinMethod(c.GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR3_ARRAY, "resize", 848867239);
        var size_arg = new_size;
        const args = [_]c.GDExtensionConstTypePtr{&size_arg};
        var out: i64 = 0;
        method.?(self.mutPtr(), &args, &out, 1);
        return out;
    }

    pub fn get(self: *PackedVector3Array, index: i64) types.Vector3 {
        const p = api_mod.godot.packed_vector3_array_operator_index_const.?(self.ptr(), index);
        return @as(*const types.Vector3, @ptrCast(@alignCast(p))).*;
    }

    pub fn set(self: *PackedVector3Array, index: i64, value: types.Vector3) void {
        const p = api_mod.godot.packed_vector3_array_operator_index.?(self.mutPtr(), index);
        @as(*types.Vector3, @ptrCast(@alignCast(p))).* = value;
    }
};

fn compilePackedVector3Mutation(values: []const types.Vector3, arrays: *Array) void {
    var vector_array = PackedVector3Array.fromSlice(values);
    defer vector_array.destroy();
    arrays.setPackedVector3Array(.vertex, &vector_array);
    arrays.setPackedVector3Array(.normal, &vector_array);
}

test "packed Vector3 construction and Array replacement compile" {
    _ = &compilePackedVector3Mutation;
}

pub const PackedInt32Array = struct {
    value: types.PackedInt32Array = std.mem.zeroes(types.PackedInt32Array),
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
        method.?(@constCast(self.ptr()), null, &out, 0);
        return out;
    }

    pub fn get(self: *PackedInt32Array, index: i64) i32 {
        const p = api_mod.godot.packed_int32_array_operator_index_const.?(self.ptr(), index);
        return p.*;
    }
};
