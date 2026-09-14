const std = @import("std");
const c = @import("c.zig").c;
const api_mod = @import("api.zig");
const types = @import("types.zig");
const Variant = @import("variant.zig").Variant;
const signal = @import("signal.zig");

pub const BindingCallbacks = c.GDExtensionInstanceBindingCallbacks{ .create_callback = null, .free_callback = null, .reference_callback = null };

/// Sent by Godot after a live extension instance has been recreated and its
/// stored properties have been restored.
pub const notification_extension_reloaded: i32 = 2;

pub const MethodReturn = enum { void, bool, int, float };

const ClassRegistration = struct {
    level: c.GDExtensionInitializationLevel,
    unregister_fn: *const fn () void,
};

var class_registrations: std.ArrayList(ClassRegistration) = .empty;
var current_initialization_level: ?c.GDExtensionInitializationLevel = null;

/// Internal extension lifecycle hook. Native classes must be registered from
/// inside an initialization callback so their level can be tracked.
pub fn beginInitialization(level: c.GDExtensionInitializationLevel) void {
    std.debug.assert(current_initialization_level == null);
    current_initialization_level = level;
}

/// Internal extension lifecycle hook.
pub fn endInitialization() void {
    std.debug.assert(current_initialization_level != null);
    current_initialization_level = null;
}

fn trackClassRegistration(unregister_fn: *const fn () void) void {
    const level = current_initialization_level orelse
        @panic("NativeClass.register must be called from the extension initialization callback");
    class_registrations.append(std.heap.c_allocator, .{
        .level = level,
        .unregister_fn = unregister_fn,
    }) catch @panic("out of memory while tracking a native class registration");
}

fn forgetClassRegistration(unregister_fn: *const fn () void) void {
    var i = class_registrations.items.len;
    while (i > 0) {
        i -= 1;
        if (class_registrations.items[i].unregister_fn == unregister_fn) {
            _ = class_registrations.orderedRemove(i);
            return;
        }
    }
}

/// Unregister classes from this initialization level in reverse registration
/// order. Called automatically by `extension.entry` during deinitialization.
pub fn unregisterLevel(level: c.GDExtensionInitializationLevel) void {
    var i = class_registrations.items.len;
    while (i > 0) {
        i -= 1;
        if (class_registrations.items[i].level == level) {
            const unregister_fn = class_registrations.items[i].unregister_fn;
            _ = class_registrations.orderedRemove(i);
            unregister_fn();
        }
    }
}

/// Release registry storage after the final initialization level is torn down.
pub fn deinitRegistrationRegistry() void {
    std.debug.assert(class_registrations.items.len == 0);
    class_registrations.deinit(std.heap.c_allocator);
    class_registrations = .empty;
}

pub fn variantType(comptime ret: MethodReturn) c.GDExtensionVariantType {
    return switch (ret) {
        .void => c.GDEXTENSION_VARIANT_TYPE_NIL,
        .bool => c.GDEXTENSION_VARIANT_TYPE_BOOL,
        .int => c.GDEXTENSION_VARIANT_TYPE_INT,
        .float => c.GDEXTENSION_VARIANT_TYPE_FLOAT,
    };
}

pub fn ReturnZig(comptime ret: MethodReturn) type {
    return switch (ret) {
        .void => void,
        .bool => bool,
        .int => i64,
        .float => f64,
    };
}

pub fn makePropertyInfo(name_text: [:0]const u8, ty: c.GDExtensionVariantType, class_text: [:0]const u8) c.GDExtensionPropertyInfo {
    const name = api_mod.godot.alloc(types.StringName);
    name.* = api_mod.godot.stringName(name_text);
    const class_name = api_mod.godot.alloc(types.StringName);
    class_name.* = api_mod.godot.stringName(class_text);
    const hint_string = api_mod.godot.alloc(types.String);
    hint_string.* = api_mod.godot.string("");
    return .{ .type = ty, .name = name, .class_name = class_name, .hint = 0, .hint_string = hint_string, .usage = 6 };
}

pub fn destroyPropertyInfo(info: *c.GDExtensionPropertyInfo) void {
    api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, info.name);
    api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, info.class_name);
    api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING, info.hint_string);
    api_mod.godot.free(info.name);
    api_mod.godot.free(info.class_name);
    api_mod.godot.free(info.hint_string);
}

fn writeVariant(out: c.GDExtensionVariantPtr, comptime kind: MethodReturn, value: ReturnZig(kind)) void {
    if (kind == .void) return;
    const ctor = api_mod.godot.get_variant_from_type_constructor.?(variantType(kind)).?;
    switch (kind) {
        .bool => {
            var v: u8 = @intFromBool(value);
            ctor(out, &v);
        },
        .int => {
            var v: i64 = value;
            ctor(out, &v);
        },
        .float => {
            var v: f64 = value;
            ctor(out, &v);
        },
        .void => {},
    }
}

fn writePtr(out: c.GDExtensionTypePtr, comptime kind: MethodReturn, value: ReturnZig(kind)) void {
    if (kind == .void or out == null) return;
    switch (kind) {
        .bool => @as(*u8, @ptrCast(@alignCast(out))).* = @intFromBool(value),
        .int => @as(*i64, @ptrCast(@alignCast(out))).* = value,
        .float => @as(*f64, @ptrCast(@alignCast(out))).* = value,
        .void => {},
    }
}

pub fn Method0(comptime T: type, comptime ret: MethodReturn, comptime function: *const fn (*T) callconv(.c) ReturnZig(ret)) type {
    return struct {
        pub fn call(_: ?*anyopaque, instance: c.GDExtensionClassInstancePtr, _: [*c]const c.GDExtensionConstVariantPtr, argc: c.GDExtensionInt, out: c.GDExtensionVariantPtr, err: [*c]c.GDExtensionCallError) callconv(.c) void {
            if (argc != 0) {
                err.*.@"error" = if (argc > 0) c.GDEXTENSION_CALL_ERROR_TOO_MANY_ARGUMENTS else c.GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS;
                err.*.expected = 0;
                return;
            }
            const self: *T = @ptrCast(@alignCast(instance.?));
            if (ret == .void) function(self) else writeVariant(out, ret, function(self));
        }

        pub fn ptrcall(_: ?*anyopaque, instance: c.GDExtensionClassInstancePtr, _: [*c]const c.GDExtensionConstTypePtr, out: c.GDExtensionTypePtr) callconv(.c) void {
            const self: *T = @ptrCast(@alignCast(instance.?));
            if (ret == .void) function(self) else writePtr(out, ret, function(self));
        }
    };
}

pub fn Method1(comptime T: type, comptime arg: MethodReturn, comptime function: *const fn (*T, ReturnZig(arg)) callconv(.c) void) type {
    if (arg == .void) @compileError("method argument cannot be void");

    return struct {
        pub fn call(_: ?*anyopaque, instance: c.GDExtensionClassInstancePtr, args: [*c]const c.GDExtensionConstVariantPtr, argc: c.GDExtensionInt, _: c.GDExtensionVariantPtr, err: [*c]c.GDExtensionCallError) callconv(.c) void {
            if (argc != 1) {
                err.*.@"error" = if (argc > 1) c.GDEXTENSION_CALL_ERROR_TOO_MANY_ARGUMENTS else c.GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS;
                err.*.expected = 1;
                return;
            }
            const self: *T = @ptrCast(@alignCast(instance.?));
            const raw: *const types.Variant = @ptrCast(@alignCast(args[0].?));
            const value = Variant{ .value = raw.* };
            function(self, value.to(ReturnZig(arg)));
        }

        pub fn ptrcall(_: ?*anyopaque, instance: c.GDExtensionClassInstancePtr, args: [*c]const c.GDExtensionConstTypePtr, _: c.GDExtensionTypePtr) callconv(.c) void {
            const self: *T = @ptrCast(@alignCast(instance.?));
            const value: ReturnZig(arg) = switch (arg) {
                .bool => @as(*const u8, @ptrCast(@alignCast(args[0].?))).* != 0,
                .int => @as(*const i64, @ptrCast(@alignCast(args[0].?))).*,
                .float => @as(*const f64, @ptrCast(@alignCast(args[0].?))).*,
                .void => unreachable,
            };
            function(self, value);
        }
    };
}

pub fn Virtual0(comptime T: type, comptime function: *const fn (*T) callconv(.c) void) type {
    return struct {
        pub fn ptrcall(_: ?*anyopaque, instance: c.GDExtensionClassInstancePtr, args: [*c]const c.GDExtensionConstTypePtr, out: c.GDExtensionTypePtr) callconv(.c) void {
            _ = args;
            _ = out;
            const self: *T = @ptrCast(@alignCast(instance.?));
            function(self);
        }
    };
}

pub fn Virtual1Float(comptime T: type, comptime function: *const fn (*T, f64) callconv(.c) void) type {
    return struct {
        pub fn ptrcall(_: ?*anyopaque, instance: c.GDExtensionClassInstancePtr, args: [*c]const c.GDExtensionConstTypePtr, out: c.GDExtensionTypePtr) callconv(.c) void {
            _ = out;
            const self: *T = @ptrCast(@alignCast(instance.?));
            const value: *const f64 = @ptrCast(@alignCast(args[0].?));
            function(self, value.*);
        }
    };
}

fn signalPtrArgument(comptime T: type, raw: c.GDExtensionConstTypePtr) T {
    return switch (T) {
        bool => @as(*const u8, @ptrCast(@alignCast(raw.?))).* != 0,
        f32 => @floatCast(@as(*const f64, @ptrCast(@alignCast(raw.?))).*),
        f64 => @as(*const f64, @ptrCast(@alignCast(raw.?))).*,
        i8, i16, i32, i64, u8, u16, u32 => @intCast(@as(*const i64, @ptrCast(@alignCast(raw.?))).*),
        types.Vector2, types.Vector3, types.Vector4, types.Color => @as(*const T, @ptrCast(@alignCast(raw.?))).*,
        else => @compileError("unsupported signal method argument: " ++ @typeName(T)),
    };
}

fn SignalMethod(comptime T: type, comptime Signal: type, comptime function: anytype) type {
    const Function = @typeInfo(@TypeOf(function)).pointer.child;
    const function_info = @typeInfo(Function).@"fn";
    const fields = @typeInfo(Signal).@"struct".fields;

    comptime {
        if (function_info.params.len != fields.len + 1) {
            @compileError("signal receiver method must take self followed by every signal field");
        }
        if (function_info.params[0].type.? != *T) {
            @compileError("signal receiver method has the wrong self type");
        }
        for (fields, 0..) |field, i| {
            if (function_info.params[i + 1].type.? != field.type) {
                @compileError("signal receiver argument does not match field " ++ field.name);
            }
        }
        if (function_info.return_type.? != void) {
            @compileError("signal receiver method must return void");
        }
    }

    return struct {
        pub fn call(_: ?*anyopaque, instance: c.GDExtensionClassInstancePtr, args: [*c]const c.GDExtensionConstVariantPtr, argc: c.GDExtensionInt, _: c.GDExtensionVariantPtr, err: [*c]c.GDExtensionCallError) callconv(.c) void {
            if (argc != fields.len) {
                err.*.@"error" = if (argc > fields.len) c.GDEXTENSION_CALL_ERROR_TOO_MANY_ARGUMENTS else c.GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS;
                err.*.expected = @intCast(fields.len);
                return;
            }

            var function_args: std.meta.ArgsTuple(Function) = undefined;
            function_args[0] = @ptrCast(@alignCast(instance.?));
            inline for (fields, 0..) |field, i| {
                const raw: *const types.Variant = @ptrCast(@alignCast(args[i].?));
                const value = Variant{ .value = raw.* };
                function_args[i + 1] = value.to(field.type);
            }
            @call(.auto, function, function_args);
        }

        pub fn ptrcall(_: ?*anyopaque, instance: c.GDExtensionClassInstancePtr, args: [*c]const c.GDExtensionConstTypePtr, _: c.GDExtensionTypePtr) callconv(.c) void {
            var function_args: std.meta.ArgsTuple(Function) = undefined;
            function_args[0] = @ptrCast(@alignCast(instance.?));
            inline for (fields, 0..) |field, i| {
                function_args[i + 1] = signalPtrArgument(field.type, args[i]);
            }
            @call(.auto, function, function_args);
        }
    };
}

pub fn registerSignal(class_name_text: [:0]const u8, comptime Signal: type) void {
    const fields = @typeInfo(Signal).@"struct".fields;
    var class_name = api_mod.godot.stringName(class_name_text);
    var signal_name = api_mod.godot.stringName(signal.name(Signal));
    defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &signal_name);
    defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &class_name);

    var arguments: [fields.len]c.GDExtensionPropertyInfo = undefined;
    inline for (fields, 0..) |field, i| {
        arguments[i] = makePropertyInfo(field.name, signal.variantType(field.type), "");
    }
    defer inline for (&arguments) |*argument| destroyPropertyInfo(argument);

    api_mod.godot.classdb_register_extension_class_signal.?(
        api_mod.godot.library,
        &class_name,
        &signal_name,
        if (arguments.len == 0) null else &arguments,
        @intCast(arguments.len),
    );
}

pub fn registerSignalHandler(comptime T: type, class_name_text: [:0]const u8, method_name_text: [:0]const u8, comptime Signal: type, comptime function: anytype) void {
    const fields = @typeInfo(Signal).@"struct".fields;
    // Instantiate the callback type here so signature mismatches fail while
    // registering rather than at the first signal emission.
    const Callback = SignalMethod(T, Signal, function);

    var method_name = api_mod.godot.stringName(method_name_text);
    var class_name = api_mod.godot.stringName(class_name_text);
    defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &method_name);
    defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &class_name);

    var arguments: [fields.len]c.GDExtensionPropertyInfo = undefined;
    var metadata: [fields.len]c.GDExtensionClassMethodArgumentMetadata = @splat(c.GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE);
    inline for (fields, 0..) |field, i| {
        arguments[i] = makePropertyInfo(field.name, signal.variantType(field.type), "");
    }
    defer inline for (&arguments) |*argument| destroyPropertyInfo(argument);

    var info: c.GDExtensionClassMethodInfo = std.mem.zeroes(c.GDExtensionClassMethodInfo);
    info.name = &method_name;
    info.call_func = Callback.call;
    info.ptrcall_func = Callback.ptrcall;
    info.method_flags = c.GDEXTENSION_METHOD_FLAGS_DEFAULT;
    info.argument_count = @intCast(fields.len);
    info.arguments_info = if (arguments.len == 0) null else &arguments;
    info.arguments_metadata = if (metadata.len == 0) null else &metadata;
    api_mod.godot.classdb_register_extension_class_method.?(api_mod.godot.library, &class_name, &info);
}

pub fn registerMethod0(comptime T: type, class_name_text: [:0]const u8, method_name_text: [:0]const u8, comptime ret: MethodReturn, comptime function: *const fn (*T) callconv(.c) ReturnZig(ret)) void {
    var method_name = api_mod.godot.stringName(method_name_text);
    var class_name = api_mod.godot.stringName(class_name_text);
    defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &method_name);
    defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &class_name);

    var return_info: c.GDExtensionPropertyInfo = std.mem.zeroes(c.GDExtensionPropertyInfo);
    var info: c.GDExtensionClassMethodInfo = std.mem.zeroes(c.GDExtensionClassMethodInfo);
    info.name = &method_name;
    info.call_func = Method0(T, ret, function).call;
    info.ptrcall_func = Method0(T, ret, function).ptrcall;
    info.method_flags = c.GDEXTENSION_METHOD_FLAGS_DEFAULT;
    if (ret != .void) {
        return_info = makePropertyInfo("", variantType(ret), "");
        defer destroyPropertyInfo(&return_info);
        info.has_return_value = 1;
        info.return_value_info = &return_info;
        info.return_value_metadata = c.GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE;
    }
    api_mod.godot.classdb_register_extension_class_method.?(api_mod.godot.library, &class_name, &info);
}

pub fn registerMethod1(comptime T: type, class_name_text: [:0]const u8, method_name_text: [:0]const u8, comptime arg: MethodReturn, comptime function: *const fn (*T, ReturnZig(arg)) callconv(.c) void) void {
    if (arg == .void) @compileError("method argument cannot be void");

    var method_name = api_mod.godot.stringName(method_name_text);
    var class_name = api_mod.godot.stringName(class_name_text);
    defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &method_name);
    defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &class_name);

    var argument_info = makePropertyInfo("value", variantType(arg), "");
    defer destroyPropertyInfo(&argument_info);
    var argument_metadata = [_]c.GDExtensionClassMethodArgumentMetadata{c.GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE};

    var info: c.GDExtensionClassMethodInfo = std.mem.zeroes(c.GDExtensionClassMethodInfo);
    info.name = &method_name;
    info.call_func = Method1(T, arg, function).call;
    info.ptrcall_func = Method1(T, arg, function).ptrcall;
    info.method_flags = c.GDEXTENSION_METHOD_FLAGS_DEFAULT;
    info.argument_count = 1;
    info.arguments_info = &argument_info;
    info.arguments_metadata = &argument_metadata;
    api_mod.godot.classdb_register_extension_class_method.?(api_mod.godot.library, &class_name, &info);
}

/// Register a stored property backed by a zero-argument getter and a
/// one-argument setter. Godot snapshots stored properties before hot reload
/// and applies them to the recreated instance afterwards.
pub fn registerProperty(
    comptime T: type,
    comptime class_name_text: [:0]const u8,
    comptime property_name_text: [:0]const u8,
    comptime kind: MethodReturn,
    comptime getter: *const fn (*T) callconv(.c) ReturnZig(kind),
    comptime setter: *const fn (*T, ReturnZig(kind)) callconv(.c) void,
) void {
    if (kind == .void) @compileError("property type cannot be void");

    const getter_name: [:0]const u8 = "get_" ++ property_name_text;
    const setter_name: [:0]const u8 = "set_" ++ property_name_text;
    registerMethod0(T, class_name_text, getter_name, kind, getter);
    registerMethod1(T, class_name_text, setter_name, kind, setter);

    var class_name = api_mod.godot.stringName(class_name_text);
    var property_info = makePropertyInfo(property_name_text, variantType(kind), "");
    var getter_string_name = api_mod.godot.stringName(getter_name);
    var setter_string_name = api_mod.godot.stringName(setter_name);
    defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &class_name);
    defer destroyPropertyInfo(&property_info);
    defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &getter_string_name);
    defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &setter_string_name);

    api_mod.godot.classdb_register_extension_class_property.?(
        api_mod.godot.library,
        &class_name,
        &property_info,
        &setter_string_name,
        &getter_string_name,
    );
}

pub fn NativeClass(comptime T: type, comptime parent_name_text: [:0]const u8, comptime class_name_text: [:0]const u8) type {
    return struct {
        fn allocateInstance(object: c.GDExtensionObjectPtr, class_userdata: ?*anyopaque) *T {
            const self = api_mod.godot.alloc(T);
            if (@hasDecl(T, "initWithUserdata")) {
                self.* = T.initWithUserdata(object, class_userdata);
            } else if (@hasDecl(T, "init")) {
                self.* = T.init(object);
            } else {
                self.* = std.mem.zeroes(T);
            }
            return self;
        }

        fn attachInstance(object: c.GDExtensionObjectPtr, self: *T) void {
            var class_name = api_mod.godot.stringName(class_name_text);
            defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &class_name);
            api_mod.godot.object_set_instance.?(object, &class_name, self);
            api_mod.godot.object_set_instance_binding.?(object, api_mod.godot.library, self, &BindingCallbacks);
        }

        pub fn create(class_userdata: ?*anyopaque, _: c.GDExtensionBool) callconv(.c) c.GDExtensionObjectPtr {
            var parent_name = api_mod.godot.stringName(parent_name_text);
            defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &parent_name);
            const object = api_mod.godot.classdb_construct_object.?(&parent_name);

            const self = allocateInstance(object, class_userdata);
            attachInstance(object, self);
            return object;
        }

        /// Rebuild only the Zig instance around an existing Godot object. Godot
        /// uses this callback while hot-reloading a reloadable extension.
        pub fn recreate(class_userdata: ?*anyopaque, object: c.GDExtensionObjectPtr) callconv(.c) c.GDExtensionClassInstancePtr {
            const self = allocateInstance(object, class_userdata);
            attachInstance(object, self);
            return self;
        }

        pub fn free(_: ?*anyopaque, instance: c.GDExtensionClassInstancePtr) callconv(.c) void {
            if (instance) |raw| {
                const self: *T = @ptrCast(@alignCast(raw));
                if (@hasDecl(T, "deinit")) self.deinit();
                api_mod.godot.free(self);
            }
        }

        fn notification(instance: c.GDExtensionClassInstancePtr, what: i32, reversed: c.GDExtensionBool) callconv(.c) void {
            const self: *T = @ptrCast(@alignCast(instance.?));
            if (@hasDecl(T, "notification")) self.notification(what, reversed != 0);
            if (what == notification_extension_reloaded and @hasDecl(T, "extensionReloaded")) self.extensionReloaded();
        }

        pub fn register() void {
            registerWithUserdata(null);
        }

        /// Register the native class with context shared by its class-level
        /// callbacks. The pointed-to data must outlive the registration.
        pub fn registerWithUserdata(class_userdata: ?*anyopaque) void {
            var class_name = api_mod.godot.stringName(class_name_text);
            var parent_name = api_mod.godot.stringName(parent_name_text);
            defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &class_name);
            defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &parent_name);
            var info: c.GDExtensionClassCreationInfo6 = std.mem.zeroes(c.GDExtensionClassCreationInfo6);
            info.is_exposed = 1;
            info.class_userdata = class_userdata;
            info.create_instance_func = create;
            info.free_instance_func = free;
            info.recreate_instance_func = recreate;
            if (@hasDecl(T, "notification") or @hasDecl(T, "extensionReloaded")) info.notification_func = notification;
            if (@hasDecl(T, "getVirtualCallData")) info.get_virtual_call_data_func = T.getVirtualCallData;
            if (@hasDecl(T, "callVirtualWithData")) info.call_virtual_with_data_func = T.callVirtualWithData;
            api_mod.godot.classdb_register_extension_class6.?(api_mod.godot.library, &class_name, &parent_name, &info);
            trackClassRegistration(unregisterRaw);
        }

        fn unregisterRaw() void {
            var class_name = api_mod.godot.stringName(class_name_text);
            defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &class_name);
            api_mod.godot.classdb_unregister_extension_class.?(api_mod.godot.library, &class_name);
        }

        /// Unregister a class early. Normally `extension.entry` unregisters all
        /// classes automatically during deinitialization.
        pub fn unregister() void {
            forgetClassRegistration(unregisterRaw);
            unregisterRaw();
        }
    };
}

test "return type mapping" {
    try std.testing.expect(ReturnZig(.float) == f64);
    try std.testing.expect(variantType(.int) == c.GDEXTENSION_VARIANT_TYPE_INT);
}

const TestSignal = struct {
    pub const signal_name: [:0]const u8 = "test_signal";
    point: types.Vector3,
    strength: f64,
};

const TestReceiver = struct {
    fn onSignal(_: *@This(), _: types.Vector3, _: f64) callconv(.c) void {}
};

fn compileSignalRegistration() void {
    registerSignal("TestReceiver", TestSignal);
    registerSignalHandler(TestReceiver, "TestReceiver", "on_signal", TestSignal, &TestReceiver.onSignal);
}

test "typed signal registration compiles" {
    const Callback = SignalMethod(TestReceiver, TestSignal, &TestReceiver.onSignal);
    _ = &Callback.call;
    _ = &Callback.ptrcall;
    _ = &compileSignalRegistration;
}

fn compileClassUserdataRegistration(context: ?*anyopaque) void {
    NativeClass(TestReceiver, "Object", "TestReceiver").registerWithUserdata(context);
}

test "native class userdata registration compiles" {
    _ = &compileClassUserdataRegistration;
}

const TestReloadable = struct {
    object: c.GDExtensionObjectPtr,
    health: f64,

    pub fn init(object: c.GDExtensionObjectPtr) @This() {
        return .{ .object = object, .health = 100 };
    }

    pub fn getHealth(self: *@This()) callconv(.c) f64 {
        return self.health;
    }

    pub fn setHealth(self: *@This(), health: f64) callconv(.c) void {
        self.health = health;
    }

    pub fn extensionReloaded(_: *@This()) void {}
};

fn compileHotReloadRegistration() void {
    const Native = NativeClass(TestReloadable, "Object", "TestReloadable");
    Native.register();
    registerProperty(TestReloadable, "TestReloadable", "health", .float, TestReloadable.getHealth, TestReloadable.setHealth);
    Native.unregister();
}

test "hot reload callbacks and stored properties compile" {
    const Native = NativeClass(TestReloadable, "Object", "TestReloadable");
    const Setter = Method1(TestReloadable, .float, TestReloadable.setHealth);
    _ = &Native.recreate;
    _ = &Setter.call;
    _ = &Setter.ptrcall;
    _ = &compileHotReloadRegistration;
}

var test_unregister_order: [2]u8 = undefined;
var test_unregister_count: usize = 0;

fn testUnregisterFirst() void {
    test_unregister_order[test_unregister_count] = 1;
    test_unregister_count += 1;
}

fn testUnregisterSecond() void {
    test_unregister_order[test_unregister_count] = 2;
    test_unregister_count += 1;
}

test "class registrations are unregistered automatically in reverse order" {
    test_unregister_count = 0;
    beginInitialization(c.GDEXTENSION_INITIALIZATION_SCENE);
    trackClassRegistration(testUnregisterFirst);
    trackClassRegistration(testUnregisterSecond);
    endInitialization();

    unregisterLevel(c.GDEXTENSION_INITIALIZATION_SCENE);
    try std.testing.expectEqualSlices(u8, &.{ 2, 1 }, &test_unregister_order);
    try std.testing.expectEqual(@as(usize, 0), class_registrations.items.len);
    deinitRegistrationRegistry();
}
