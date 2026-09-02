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

    pub fn fromVector2(value: types.Vector2) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_VECTOR2); }
    pub fn fromVector2i(value: types.Vector2i) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_VECTOR2I); }
    pub fn fromRect2(value: types.Rect2) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_RECT2); }
    pub fn fromRect2i(value: types.Rect2i) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_RECT2I); }
    pub fn fromVector3(value: types.Vector3) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_VECTOR3); }
    pub fn fromVector3i(value: types.Vector3i) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_VECTOR3I); }
    pub fn fromTransform2D(value: types.Transform2D) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_TRANSFORM2D); }
    pub fn fromVector4(value: types.Vector4) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_VECTOR4); }
    pub fn fromVector4i(value: types.Vector4i) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_VECTOR4I); }
    pub fn fromPlane(value: types.Plane) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_PLANE); }
    pub fn fromQuaternion(value: types.Quaternion) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_QUATERNION); }
    pub fn fromAABB(value: types.AABB) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_AABB); }
    pub fn fromBasis(value: types.Basis) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_BASIS); }
    pub fn fromTransform3D(value: types.Transform3D) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_TRANSFORM3D); }
    pub fn fromProjection(value: types.Projection) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_PROJECTION); }
    pub fn fromColor(value: types.Color) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_COLOR); }
    pub fn fromString(value: types.String) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_STRING); }
    pub fn fromStringName(value: types.StringName) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_STRING_NAME); }
    pub fn fromNodePath(value: types.NodePath) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_NODE_PATH); }
    pub fn fromRID(value: types.RID) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_RID); }
    pub fn fromCallable(value: types.Callable) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_CALLABLE); }
    pub fn fromSignal(value: types.Signal) Variant { return fromBuiltin(value, c.GDEXTENSION_VARIANT_TYPE_SIGNAL); }

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
            types.Vector2i => fromVector2i(value),
            types.Rect2 => fromRect2(value),
            types.Rect2i => fromRect2i(value),
            types.Vector3 => fromVector3(value),
            types.Vector3i => fromVector3i(value),
            types.Transform2D => fromTransform2D(value),
            types.Vector4 => fromVector4(value),
            types.Vector4i => fromVector4i(value),
            types.Plane => fromPlane(value),
            types.Quaternion => fromQuaternion(value),
            types.AABB => fromAABB(value),
            types.Basis => fromBasis(value),
            types.Transform3D => fromTransform3D(value),
            types.Projection => fromProjection(value),
            types.Color => fromColor(value),
            types.String => fromString(value),
            types.StringName => fromStringName(value),
            types.NodePath => fromNodePath(value),
            types.RID => fromRID(value),
            types.Callable => fromCallable(value),
            types.Signal => fromSignal(value),
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
            types.Vector2i => self.toBuiltin(types.Vector2i, c.GDEXTENSION_VARIANT_TYPE_VECTOR2I),
            types.Rect2 => self.toBuiltin(types.Rect2, c.GDEXTENSION_VARIANT_TYPE_RECT2),
            types.Rect2i => self.toBuiltin(types.Rect2i, c.GDEXTENSION_VARIANT_TYPE_RECT2I),
            types.Vector3 => self.toBuiltin(types.Vector3, c.GDEXTENSION_VARIANT_TYPE_VECTOR3),
            types.Vector3i => self.toBuiltin(types.Vector3i, c.GDEXTENSION_VARIANT_TYPE_VECTOR3I),
            types.Transform2D => self.toBuiltin(types.Transform2D, c.GDEXTENSION_VARIANT_TYPE_TRANSFORM2D),
            types.Vector4 => self.toBuiltin(types.Vector4, c.GDEXTENSION_VARIANT_TYPE_VECTOR4),
            types.Vector4i => self.toBuiltin(types.Vector4i, c.GDEXTENSION_VARIANT_TYPE_VECTOR4I),
            types.Plane => self.toBuiltin(types.Plane, c.GDEXTENSION_VARIANT_TYPE_PLANE),
            types.Quaternion => self.toBuiltin(types.Quaternion, c.GDEXTENSION_VARIANT_TYPE_QUATERNION),
            types.AABB => self.toBuiltin(types.AABB, c.GDEXTENSION_VARIANT_TYPE_AABB),
            types.Basis => self.toBuiltin(types.Basis, c.GDEXTENSION_VARIANT_TYPE_BASIS),
            types.Transform3D => self.toBuiltin(types.Transform3D, c.GDEXTENSION_VARIANT_TYPE_TRANSFORM3D),
            types.Projection => self.toBuiltin(types.Projection, c.GDEXTENSION_VARIANT_TYPE_PROJECTION),
            types.Color => self.toBuiltin(types.Color, c.GDEXTENSION_VARIANT_TYPE_COLOR),
            types.NodePath => self.toBuiltin(types.NodePath, c.GDEXTENSION_VARIANT_TYPE_NODE_PATH),
            types.RID => self.toBuiltin(types.RID, c.GDEXTENSION_VARIANT_TYPE_RID),
            types.Callable => self.toBuiltin(types.Callable, c.GDEXTENSION_VARIANT_TYPE_CALLABLE),
            types.Signal => self.toBuiltin(types.Signal, c.GDEXTENSION_VARIANT_TYPE_SIGNAL),
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
