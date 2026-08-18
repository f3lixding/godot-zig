const std = @import("std");
const types = @import("types.zig");
const collections = @import("collections.zig");
const classes = @import("generated/classes.zig");

// Referencing this function forces Zig to analyze the generated set_mesh body
// without executing a Godot API call. This catches invalid object-argument
// pointer conversions such as passing *GDExtensionObjectPtr without @ptrCast.
fn compileMeshInstanceSetMesh(instance: classes.MeshInstance3D, mesh: classes.Mesh) void {
    instance.@"set_mesh"(mesh);
}

test "generated object arguments compile" {
    _ = &compileMeshInstanceSetMesh;
}

test "generator retains ArrayMesh methods with five arguments" {
    try std.testing.expect(@hasDecl(classes.ArrayMesh, "add_surface_from_arrays"));

    const Expected = fn (
        classes.ArrayMesh,
        i64,
        collections.Array,
        collections.Array,
        types.Dictionary,
        i64,
    ) void;
    try std.testing.expect(@TypeOf(classes.ArrayMesh.@"add_surface_from_arrays") == Expected);
}
