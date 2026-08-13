# godot-zig

> [!NOTE]
> Disclaimer: this package is currently 100% AI-generated. Review, test, and audit it carefully before using it in production.

A small Zig foundation layer for writing [Godot GDExtension](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/index.html) libraries against Godot's C API.

The package exposes:

- the raw GDExtension C API via `godot.c`
- common Godot builtin ABI types via `godot.Vector2`, `godot.Vector3`, `godot.StringName`, etc.
- loaded interface function table via `godot.api.godot`
- light wrappers for common classes like `Object`, `Node`, `Node3D`, `CharacterBody3D`, and `Input`
- helpers for native class registration and extension entry points

> Current ABI target: Godot 4.x, 64-bit, single-precision builds. If using a custom double-precision Godot build, builtin type layouts must be regenerated/adjusted from `extension_api.json`.

## Consuming from another Zig package

Add this package to your `build.zig.zon` dependencies, then import its exposed module from your `build.zig`.

```zig
const godot_zig = b.dependency("godot_zig", .{
    .target = target,
    .optimize = optimize,
});

lib.root_module.addImport("godot_zig", godot_zig.module("godot_zig"));
```

Your GDExtension shared library should usually be built as a dynamic library:

```zig
const lib = b.addSharedLibrary(.{
    .name = "my_game_native",
    .root_source_file = b.path("src/native.zig"),
    .target = target,
    .optimize = optimize,
});
lib.root_module.addImport("godot_zig", godot_zig.module("godot_zig"));
b.installArtifact(lib);
```

## Minimal extension entry point

```zig
const godot = @import("godot_zig");

fn initialize(level: godot.c.GDExtensionInitializationLevel) callconv(.c) void {
    if (level != godot.c.GDEXTENSION_INITIALIZATION_SCENE) return;
    // Register native classes here.
}

fn deinitialize(level: godot.c.GDExtensionInitializationLevel) callconv(.c) void {
    _ = level;
}

pub export fn my_extension_init(
    get_proc_address: godot.c.GDExtensionInterfaceGetProcAddress,
    library: godot.c.GDExtensionClassLibraryPtr,
    initialization: [*c]godot.c.GDExtensionInitialization,
) godot.c.GDExtensionBool {
    return godot.extension.entry(
        get_proc_address,
        library,
        initialization,
        .scene,
        initialize,
        deinitialize,
    );
}
```

In your `.gdextension` file, use the exported symbol name:

```ini
[configuration]
entry_symbol = "my_extension_init"
compatibility_minimum = "4.4"

[libraries]
linux.debug.x86_64 = "res://bin/libmy_game_native.so"
linux.release.x86_64 = "res://bin/libmy_game_native.so"
```

## Minimal native class

```zig
const godot = @import("godot_zig");

const MyBody = extern struct {
    object: godot.c.GDExtensionObjectPtr,

    pub fn init(object: godot.c.GDExtensionObjectPtr) MyBody {
        return .{ .object = object };
    }

    pub fn speed(_: *MyBody) callconv(.c) f64 {
        return 5.5;
    }
};

fn initialize(level: godot.c.GDExtensionInitializationLevel) callconv(.c) void {
    if (level != godot.c.GDEXTENSION_INITIALIZATION_SCENE) return;

    godot.class.NativeClass(MyBody, "CharacterBody3D", "MyBody").register();
    godot.class.registerMethod0(MyBody, "MyBody", "speed", .float, MyBody.speed);
}
```

After this, Godot can instantiate `MyBody` as a class derived from `CharacterBody3D`, and scripts can call:

```gdscript
var body = ClassDB.instantiate("MyBody")
print(body.speed())
```

## Calling Godot APIs from Zig

```zig
const godot = @import("godot_zig");

fn physicsProcess(self: *MyBody, delta: f64) callconv(.c) void {
    const body = godot.CharacterBody3D.init(self.object);

    var velocity = body.@"get_velocity"();
    velocity.y -= 9.8 * @as(f32, @floatCast(delta));

    body.@"set_velocity"(velocity);
    _ = body.@"move_and_slide"();
}
```

## Input singleton example

```zig
const input = godot.Input.singleton();

if (godot.input_helpers.isPhysicalKeyPressed(input, .space)) {
    // jump
}

const movement = godot.input_helpers.wasdVector(input);
```

Mouse mode:

```zig
godot.input_helpers.setMouseMode(godot.Input.singleton(), .captured);
godot.input_helpers.setMouseMode(godot.Input.singleton(), .visible);
```

## Node helpers

```zig
const node = godot.Node.init(self.object);
const camera = node.@"find_child"("Camera3D", true, false);

if (!camera.isNull()) {
    const camera_3d = godot.Node3D.init(camera.object.ptr);
    camera_3d.@"set_rotation_degrees"(.{ .x = -20, .y = 0, .z = 0 });
}
```

## Logging

Godot's GDExtension logging functions are available through `godot.log` after initialization:

```zig
godot.log.warn("Something looks suspicious", .{
    .function = @src().fn_name,
    .file = @src().file,
    .line = @src().line,
});

godot.log.errMsg("Failed to build mesh", "surface 0 had no vertex array", .{
    .function = @src().fn_name,
    .file = @src().file,
    .line = @src().line,
    .editor_notify = true,
});
```

Available helpers:

```zig
godot.log.err(...)
godot.log.errMsg(...)
godot.log.warn(...)
godot.log.warnMsg(...)
godot.log.scriptErr(...)
godot.log.scriptErrMsg(...)
```

## Raw API escape hatch

The raw C API is always available:

```zig
const c = godot.c;
const api = &godot.api.godot;

var name = api.stringName("Input");
defer api.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &name);

const input_singleton = api.global_get_singleton.?(&name);
```

## Development

Run tests:

```sh
zig build test
```

## Notes

This package now includes an experimental generated class layer from Godot's `extension_api.json`:

```sh
./tools/generate_bindings.pl extension_api.json src/generated
```

Generated classes live under:

```zig
godot.generated.classes.MeshInstance3D
godot.generated.classes.Mesh
godot.generated.classes.Node
```

A few common aliases, such as `godot.MeshInstance3D` and `godot.Mesh`, point at the generated classes. The generator is intentionally conservative: it skips vararg/static methods, limits generated methods to simple supported argument/return types, and still needs broader builtin type support before it can be considered complete.
