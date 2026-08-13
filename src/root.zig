pub const c = @import("c.zig").c;
pub const api = @import("api.zig");
pub const types = @import("types.zig");
pub const object = @import("object.zig");
pub const class = @import("class.zig");
pub const input = @import("input.zig");
pub const variant = @import("variant.zig");
pub const collections = @import("collections.zig");
pub const log = @import("log.zig");
pub const generated = @import("generated/root.zig");
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
pub const Node = generated.classes.Node;
pub const Node3D = generated.classes.Node3D;
pub const MeshInstance3D = generated.classes.MeshInstance3D;
pub const Mesh = generated.classes.Mesh;
pub const CharacterBody3D = generated.classes.CharacterBody3D;
pub const Array = collections.Array;
pub const PackedVector3Array = collections.PackedVector3Array;
pub const PackedInt32Array = collections.PackedInt32Array;
pub const Input = generated.classes.Input;
pub const Key = input.Key;
pub const MouseMode = input.MouseMode;
pub const input_helpers = input;

comptime {
    _ = api;
    _ = class;
    _ = variant;
    _ = collections;
    _ = log;
    _ = generated;
    _ = extension;
}

test {
    _ = @import("types.zig");
    _ = @import("api.zig");
    _ = @import("class.zig");
    _ = @import("log.zig");
}
