const c = @import("c.zig").c;
const api = @import("api.zig");

pub const InitLevel = enum(c_int) {
    core = c.GDEXTENSION_INITIALIZATION_CORE,
    servers = c.GDEXTENSION_INITIALIZATION_SERVERS,
    scene = c.GDEXTENSION_INITIALIZATION_SCENE,
    editor = c.GDEXTENSION_INITIALIZATION_EDITOR,
};

/// Build an exported GDExtension entry point.
///
/// Example:
/// ```zig
/// const godot = @import("godot_zig");
/// fn initialize(level: godot.c.GDExtensionInitializationLevel) callconv(.c) void { ... }
/// fn deinitialize(level: godot.c.GDExtensionInitializationLevel) callconv(.c) void { ... }
/// pub export fn my_extension_init(get: godot.c.GDExtensionInterfaceGetProcAddress,
///     lib: godot.c.GDExtensionClassLibraryPtr,
///     init: [*c]godot.c.GDExtensionInitialization) godot.c.GDExtensionBool {
///     return godot.extension.entry(get, lib, init, .scene, initialize, deinitialize);
/// }
/// ```
pub fn entry(
    get_proc_address: c.GDExtensionInterfaceGetProcAddress,
    library: c.GDExtensionClassLibraryPtr,
    initialization: [*c]c.GDExtensionInitialization,
    comptime minimum_level: InitLevel,
    comptime initializeFn: *const fn (c.GDExtensionInitializationLevel) callconv(.c) void,
    comptime deinitializeFn: *const fn (c.GDExtensionInitializationLevel) callconv(.c) void,
) c.GDExtensionBool {
    api.init(get_proc_address, library);
    const Callbacks = struct {
        fn initialize(_: ?*anyopaque, level: c.GDExtensionInitializationLevel) callconv(.c) void {
            initializeFn(level);
        }
        fn deinitialize(_: ?*anyopaque, level: c.GDExtensionInitializationLevel) callconv(.c) void {
            deinitializeFn(level);
            if (level == @intFromEnum(minimum_level)) api.deinit();
        }
    };
    initialization.*.minimum_initialization_level = @intFromEnum(minimum_level);
    initialization.*.userdata = null;
    initialization.*.initialize = Callbacks.initialize;
    initialization.*.deinitialize = Callbacks.deinitialize;
    return 1;
}
