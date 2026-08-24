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

### Native instance lifecycle

`NativeClass` automatically invokes optional Zig lifecycle declarations for every instance:

```text
Godot creates the native object
→ NativeClass.create()
→ T.init(object), when T declares init

Godot frees the native object
→ T.deinit(), when T declares deinit
→ NativeClass frees the Zig instance storage
```

`init` initializes instance-owned fields:

```zig
pub fn init(object: godot.c.GDExtensionObjectPtr) MyBody {
    return .{ .object = object };
}
```

`deinit` releases instance-owned resources:

```zig
pub fn deinit(self: *MyBody) void {
    _ = self;
}
```

These names are `godot-zig` conventions used by `NativeClass.create()` and `NativeClass.free()`. Godot scene callbacks such as `_ready` are separate virtual callbacks that run after construction.

## Overriding Godot virtual methods

A native class that overrides Godot callbacks such as `_ready`, `_physics_process`, or `_input` defines the following pair of public methods. `NativeClass.register()` detects them and installs them as the class's virtual dispatch callbacks. Classes without Godot virtual overrides may omit them.

`register()` supplies null class userdata. To provide shared class context, use module-lifetime storage and `registerWithUserdata()`:

```zig
var class_context = ClassContext{ /* ... */ };

const Native = godot.class.NativeClass(MyNode, "Node", "MyNode");
Native.registerWithUserdata(&class_context);
```

The userdata pointer must remain valid for the entire class registration.

### `getVirtualCallData`

```zig
pub fn getVirtualCallData(
    class_userdata: ?*anyopaque,
    name: godot.c.GDExtensionConstStringNamePtr,
    hash: u32,
) callconv(.c) ?*anyopaque
```

Godot calls this while resolving a virtual method for the class. It returns an opaque token identifying the Zig callback, or `null` when the class does not override the requested method.

Arguments:

- `class_userdata`: Per-class data supplied through `registerWithUserdata()`, or `null` when the class was registered with `register()`.
- `name`: Godot `StringName` identifying the requested virtual method, such as `_ready` or `_physics_process`.
- `hash`: Godot's compatibility hash for that virtual method signature. It can distinguish methods whose signatures change between API versions; simple implementations may ignore it.

A function pointer can serve as the opaque token:

```zig
pub fn getVirtualCallData(
    _: ?*anyopaque,
    name: godot.c.GDExtensionConstStringNamePtr,
    _: u32,
) callconv(.c) ?*anyopaque {
    var ready_name = godot.api.godot.stringName("_ready");
    defer godot.api.godot.destroy(
        godot.c.GDEXTENSION_VARIANT_TYPE_STRING_NAME,
        &ready_name,
    );

    if (stringNameEqual(name, &ready_name)) {
        return @ptrCast(@constCast(&ready));
    }
    return null;
}
```

### `callVirtualWithData`

```zig
pub fn callVirtualWithData(
    instance: godot.c.GDExtensionClassInstancePtr,
    name: godot.c.GDExtensionConstStringNamePtr,
    virtual_call_userdata: ?*anyopaque,
    args: [*c]const godot.c.GDExtensionConstTypePtr,
    ret: godot.c.GDExtensionTypePtr,
) callconv(.c) void
```

Godot calls this to execute a virtual method previously resolved by `getVirtualCallData`.

Arguments:

- `instance`: Pointer to the specific Zig class instance receiving the callback. Cast it to `*Self` with `@ptrCast(@alignCast(instance.?))`.
- `name`: Name of the virtual method being called. Dispatch can use this value, although the opaque token is usually sufficient.
- `virtual_call_userdata`: The exact token returned by `getVirtualCallData`. It identifies which Zig callback to invoke.
- `args`: Array of raw pointers to the virtual method arguments in declaration order. For `_physics_process`, `args[0]` points to an `f64` delta. For `_input`, `args[0]` points to a Godot object pointer.
- `ret`: Raw output location for the virtual method's return value. Void callbacks ignore it; callbacks with return values must write the correctly typed value here.

Example dispatch:

```zig
pub fn callVirtualWithData(
    instance: godot.c.GDExtensionClassInstancePtr,
    _: godot.c.GDExtensionConstStringNamePtr,
    userdata: ?*anyopaque,
    args: [*c]const godot.c.GDExtensionConstTypePtr,
    ret: godot.c.GDExtensionTypePtr,
) callconv(.c) void {
    _ = ret;
    const self: *Self = @ptrCast(@alignCast(instance.?));

    if (userdata == @as(?*anyopaque, @ptrCast(@constCast(&physicsProcess)))) {
        const delta: *const f64 = @ptrCast(@alignCast(args[0].?));
        physicsProcess(self, delta.*);
    }
}
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

## Typed signals

Declare signal arguments as a Zig struct with a Godot signal name:

```zig
const ContactSignal = struct {
    pub const signal_name: [:0]const u8 = "contact_requested";
    point: godot.Vector3,
    normal: godot.Vector3,
    strength: f64,
};
```

Register the signal on its sender class and a matching handler on its receiver class after registering both native classes:

```zig
godot.class.registerSignal("MouseInteractor", ContactSignal);
godot.class.registerSignalHandler(
    JelloVisual,
    "JelloVisual",
    "on_contact_requested",
    ContactSignal,
    &JelloVisual.onContactRequested,
);
```

The receiver signature must match the signal fields:

```zig
fn onContactRequested(
    self: *JelloVisual,
    point: godot.Vector3,
    normal: godot.Vector3,
    strength: f64,
) callconv(.c) void {
    // Handle contact.
}
```

Connect specific object instances:

```zig
var callable = godot.Callable.fromObjectMethod(
    receiver_object,
    "on_contact_requested",
);
defer callable.destroy();

const result = sender_object.connectSignal(ContactSignal, callable);
```

Emit the typed payload from the sender:

```zig
_ = try sender_object.emitSignal(ContactSignal, .{
    .point = point,
    .normal = normal,
    .strength = 4.0,
});
```

The signal payload is converted to a fixed-size stack array of Godot Variants, allowing signals with different argument counts without a Zig vararg wrapper.

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
