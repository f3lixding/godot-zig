const c = @import("c.zig").c;
const types = @import("types.zig");

/// Signal payload types declare their Godot signal name as:
/// `pub const signal_name: [:0]const u8 = "signal_name";`
pub fn name(comptime Signal: type) [:0]const u8 {
    if (!@hasDecl(Signal, "signal_name")) {
        @compileError(@typeName(Signal) ++ " must declare `pub const signal_name: [:0]const u8`");
    }
    return Signal.signal_name;
}

pub fn variantType(comptime T: type) c.GDExtensionVariantType {
    return switch (T) {
        bool => c.GDEXTENSION_VARIANT_TYPE_BOOL,
        f32, f64 => c.GDEXTENSION_VARIANT_TYPE_FLOAT,
        i8, i16, i32, i64, u8, u16, u32 => c.GDEXTENSION_VARIANT_TYPE_INT,
        types.Vector2 => c.GDEXTENSION_VARIANT_TYPE_VECTOR2,
        types.Vector3 => c.GDEXTENSION_VARIANT_TYPE_VECTOR3,
        types.Vector4 => c.GDEXTENSION_VARIANT_TYPE_VECTOR4,
        types.Color => c.GDEXTENSION_VARIANT_TYPE_COLOR,
        types.StringName => c.GDEXTENSION_VARIANT_TYPE_STRING_NAME,
        else => @compileError("unsupported signal field type: " ++ @typeName(T)),
    };
}

test "typed signal metadata" {
    const Contact = struct {
        pub const signal_name: [:0]const u8 = "contact";
        point: types.Vector3,
        strength: f64,
    };

    try @import("std").testing.expectEqualStrings("contact", name(Contact));
    try @import("std").testing.expect(variantType(types.Vector3) == c.GDEXTENSION_VARIANT_TYPE_VECTOR3);
    try @import("std").testing.expect(variantType(f64) == c.GDEXTENSION_VARIANT_TYPE_FLOAT);
}
