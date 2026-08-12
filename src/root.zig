pub const c = @import("c.zig").c;
pub const api = @import("api.zig");
pub const types = @import("types.zig");
pub const object = @import("object.zig");
pub const class = @import("class.zig");
pub const input = @import("input.zig");
pub const extension = @import("extension.zig");

pub const StringName = types.StringName;
pub const String = types.String;
pub const Variant = types.Variant;
pub const Vector2 = types.Vector2;
pub const Vector2i = types.Vector2i;
pub const Rect2 = types.Rect2;
pub const Rect2i = types.Rect2i;
pub const Vector3 = types.Vector3;
pub const Vector3i = types.Vector3i;
pub const Vector4 = types.Vector4;
pub const Vector4i = types.Vector4i;
pub const Plane = types.Plane;
pub const Quaternion = types.Quaternion;
pub const AABB = types.AABB;
pub const Basis = types.Basis;
pub const Transform2D = types.Transform2D;
pub const Transform3D = types.Transform3D;
pub const Projection = types.Projection;
pub const Color = types.Color;
pub const Object = object.Object;
pub const Node = object.Node;
pub const Node3D = object.Node3D;
pub const CharacterBody3D = object.CharacterBody3D;
pub const Input = input.Input;
pub const Key = input.Key;
pub const MouseMode = input.MouseMode;

comptime {
    _ = api;
    _ = class;
    _ = extension;
}

test {
    _ = @import("types.zig");
    _ = @import("api.zig");
    _ = @import("class.zig");
}
