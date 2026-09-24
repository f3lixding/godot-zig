const std = @import("std");

/// Built-in Godot value layouts for 64-bit, single-precision builds.
/// These are the layouts used by the official GDExtension C API in the common
/// Godot 4.x configuration. If you build Godot with double precision, generate
/// and substitute the corresponding layouts from extension_api.json.
pub const Bool = u8;
pub const Int = i64;
pub const Float = f64;

pub const StringName = extern struct { data: [8]u8 };
pub const String = extern struct { data: [8]u8 };
pub const Variant = extern struct { data: [24]u8 };
pub const NodePath = extern struct { data: [8]u8 };
pub const RID = extern struct { data: [8]u8 };
pub const Callable = extern struct { data: [16]u8 };
pub const Signal = extern struct { data: [16]u8 };
pub const Dictionary = extern struct { data: [8]u8 };
pub const Array = extern struct { data: [8]u8 };
// Packed arrays are 16 bytes in Godot's float_64 build configuration
// (single-precision reals, 64-bit pointers). This differs from Array and
// Dictionary, which are 8 bytes.
pub const PackedByteArray = extern struct { data: [16]u8 };
pub const PackedInt32Array = extern struct { data: [16]u8 };
pub const PackedInt64Array = extern struct { data: [16]u8 };
pub const PackedFloat32Array = extern struct { data: [16]u8 };
pub const PackedFloat64Array = extern struct { data: [16]u8 };
pub const PackedStringArray = extern struct { data: [16]u8 };
pub const PackedVector2Array = extern struct { data: [16]u8 };
pub const PackedVector3Array = extern struct { data: [16]u8 };
pub const PackedColorArray = extern struct { data: [16]u8 };
pub const PackedVector4Array = extern struct { data: [16]u8 };

pub const Vector2 = extern struct {
    x: f32 = 0,
    y: f32 = 0,

    pub fn length(self: Vector2) f32 {
        return @sqrt(self.x * self.x + self.y * self.y);
    }

    pub fn normalized(self: Vector2) Vector2 {
        const len = self.length();
        if (len == 0) return .{};
        return .{ .x = self.x / len, .y = self.y / len };
    }
};

pub const Vector2i = extern struct { x: i32 = 0, y: i32 = 0 };

pub const Rect2 = extern struct { position: Vector2 = .{}, size: Vector2 = .{} };
pub const Rect2i = extern struct { position: Vector2i = .{}, size: Vector2i = .{} };

pub const Vector3 = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,

    pub fn length(self: Vector3) f32 {
        return @sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }

    pub fn normalized(self: Vector3) Vector3 {
        const len = self.length();
        if (len == 0) return .{};
        return .{ .x = self.x / len, .y = self.y / len, .z = self.z / len };
    }
};

pub const Vector3i = extern struct { x: i32 = 0, y: i32 = 0, z: i32 = 0 };
pub const Vector4 = extern struct { x: f32 = 0, y: f32 = 0, z: f32 = 0, w: f32 = 0 };
pub const Vector4i = extern struct { x: i32 = 0, y: i32 = 0, z: i32 = 0, w: i32 = 0 };
pub const Plane = extern struct { normal: Vector3 = .{}, d: f32 = 0 };
pub const Quaternion = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
    w: f32 = 1,

    /// Composes this rotation with `other` using the Hamilton product.
    pub fn multiply(self: Quaternion, other: Quaternion) Quaternion {
        return .{
            .x = self.w * other.x + self.x * other.w + self.y * other.z - self.z * other.y,
            .y = self.w * other.y - self.x * other.z + self.y * other.w + self.z * other.x,
            .z = self.w * other.z + self.x * other.y - self.y * other.x + self.z * other.w,
            .w = self.w * other.w - self.x * other.x - self.y * other.y - self.z * other.z,
        };
    }
};
pub const AABB = extern struct { position: Vector3 = .{}, size: Vector3 = .{} };
pub const Basis = extern struct { rows: [3]Vector3 = .{ .{}, .{}, .{} } };
pub const Transform2D = extern struct { columns: [3]Vector2 = .{ .{}, .{}, .{} } };
pub const Transform3D = extern struct { basis: Basis = .{}, origin: Vector3 = .{} };
pub const Projection = extern struct { columns: [4]Vector4 = .{ .{}, .{}, .{}, .{} } };
pub const Color = extern struct { r: f32 = 0, g: f32 = 0, b: f32 = 0, a: f32 = 1 };

test "Quaternion.multiply composes rotations" {
    const identity = Quaternion{};
    const quarter_turn_y = Quaternion{
        .y = @sqrt(@as(f32, 0.5)),
        .w = @sqrt(@as(f32, 0.5)),
    };

    try std.testing.expectEqual(quarter_turn_y, identity.multiply(quarter_turn_y));
    try std.testing.expectEqual(quarter_turn_y, quarter_turn_y.multiply(identity));

    const half_turn_y = quarter_turn_y.multiply(quarter_turn_y);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), half_turn_y.x, 0.00001);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), half_turn_y.y, 0.00001);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), half_turn_y.z, 0.00001);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), half_turn_y.w, 0.00001);
}

test "common Godot ABI sizes" {
    try std.testing.expectEqual(@as(usize, 8), @sizeOf(StringName));
    try std.testing.expectEqual(@as(usize, 8), @sizeOf(String));
    try std.testing.expectEqual(@as(usize, 24), @sizeOf(Variant));
    try std.testing.expectEqual(@as(usize, 8), @sizeOf(Array));
    try std.testing.expectEqual(@as(usize, 16), @sizeOf(PackedByteArray));
    try std.testing.expectEqual(@as(usize, 16), @sizeOf(PackedVector3Array));
    try std.testing.expectEqual(@as(usize, 16), @sizeOf(PackedInt32Array));
    try std.testing.expectEqual(@as(usize, 8), @sizeOf(Vector2));
    try std.testing.expectEqual(@as(usize, 12), @sizeOf(Vector3));
}
