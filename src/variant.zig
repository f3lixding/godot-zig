const std = @import("std");
const c = @import("c.zig").c;
const api_mod = @import("api.zig");
const types = @import("types.zig");

pub const Variant = struct {
    value: types.Variant,

    pub fn fromInt(value: i64) Variant {
        var out: types.Variant = std.mem.zeroes(types.Variant);
        var v = value;
        api_mod.godot.get_variant_from_type_constructor.?(c.GDEXTENSION_VARIANT_TYPE_INT).?(&out, &v);
        return .{ .value = out };
    }

    pub fn fromBool(value: bool) Variant {
        var out: types.Variant = std.mem.zeroes(types.Variant);
        var v: u8 = @intFromBool(value);
        api_mod.godot.get_variant_from_type_constructor.?(c.GDEXTENSION_VARIANT_TYPE_BOOL).?(&out, &v);
        return .{ .value = out };
    }

    pub fn fromFloat(value: f64) Variant {
        var out: types.Variant = std.mem.zeroes(types.Variant);
        var v = value;
        api_mod.godot.get_variant_from_type_constructor.?(c.GDEXTENSION_VARIANT_TYPE_FLOAT).?(&out, &v);
        return .{ .value = out };
    }

    pub fn fromVector2(value: types.Vector2) Variant {
        return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_VECTOR2);
    }

    pub fn fromVector3(value: types.Vector3) Variant {
        return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_VECTOR3);
    }

    pub fn fromVector4(value: types.Vector4) Variant {
        return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_VECTOR4);
    }

    pub fn fromColor(value: types.Color) Variant {
        return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_COLOR);
    }

    pub fn fromStringName(value: types.StringName) Variant {
        return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_STRING_NAME);
    }

    fn fromBuiltin(value: anytype, variant_type: c.GDExtensionVariantType) Variant {
        var out: types.Variant = std.mem.zeroes(types.Variant);
        var input = value;
        api_mod.godot.get_variant_from_type_constructor.?(variant_type).?(&out, &input);
        return .{ .value = out };
    }

    pub fn from(value: anytype) Variant {
        const T = @TypeOf(value);
        return switch (T) {
            bool => fromBool(value),
            f32 => fromFloat(@floatCast(value)),
            f64 => fromFloat(value),
            i8, i16, i32, i64, u8, u16, u32 => fromInt(@intCast(value)),
            types.Vector2 => fromVector2(value),
            types.Vector3 => fromVector3(value),
            types.Vector4 => fromVector4(value),
            types.Color => fromColor(value),
            types.StringName => fromStringName(value),
            else => @compileError("unsupported Variant conversion from " ++ @typeName(T)),
        };
    }

    pub fn destroy(self: *Variant) void {
        api_mod.godot.variant_destroy.?(&self.value);
    }

    pub fn getType(self: *const Variant) c.GDExtensionVariantType {
        return api_mod.godot.variant_get_type.?(&self.value);
    }

    pub fn toBuiltin(self: *const Variant, comptime T: type, comptime variant_type: c.GDExtensionVariantType) T {
        var out: T = std.mem.zeroes(T);
        const ctor = api_mod.godot.get_variant_to_type_constructor.?(variant_type).?;
        ctor(@ptrCast(&out), @ptrCast(@constCast(&self.value)));
        return out;
    }

    pub fn to(self: *const Variant, comptime T: type) T {
        return switch (T) {
            bool => self.toBuiltin(u8, c.GDEXTENSION_VARIANT_TYPE_BOOL) != 0,
            f32 => @floatCast(self.toBuiltin(f64, c.GDEXTENSION_VARIANT_TYPE_FLOAT)),
            f64 => self.toBuiltin(f64, c.GDEXTENSION_VARIANT_TYPE_FLOAT),
            i8, i16, i32, i64, u8, u16, u32 => @intCast(self.toBuiltin(i64, c.GDEXTENSION_VARIANT_TYPE_INT)),
            types.Vector2 => self.toBuiltin(types.Vector2, c.GDEXTENSION_VARIANT_TYPE_VECTOR2),
            types.Vector3 => self.toBuiltin(types.Vector3, c.GDEXTENSION_VARIANT_TYPE_VECTOR3),
            types.Vector4 => self.toBuiltin(types.Vector4, c.GDEXTENSION_VARIANT_TYPE_VECTOR4),
            types.Color => self.toBuiltin(types.Color, c.GDEXTENSION_VARIANT_TYPE_COLOR),
            else => @compileError("unsupported Variant conversion to " ++ @typeName(T)),
        };
    }

    pub fn toObjectPtr(self: *const Variant) c.GDExtensionObjectPtr {
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

    pub fn toPackedByteArray(self: *Variant) @import("collections.zig").PackedByteArray {
        return @import("collections.zig").PackedByteArray.fromVariant(self);
    }

    pub fn toPackedVector3Array(self: *Variant) @import("collections.zig").PackedVector3Array {
        return @import("collections.zig").PackedVector3Array.fromVariant(self);
    }

    pub fn toPackedInt32Array(self: *Variant) @import("collections.zig").PackedInt32Array {
        return @import("collections.zig").PackedInt32Array.fromVariant(self);
    }
};
