const std = @import("std");
const c = @import("c.zig").c;
const api_mod = @import("api.zig");
const types = @import("types.zig");

pub const BindingCallbacks = c.GDExtensionInstanceBindingCallbacks{ .create_callback = null, .free_callback = null, .reference_callback = null };

pub const MethodReturn = enum { void, bool, int, float };

pub fn variantType(comptime ret: MethodReturn) c.GDExtensionVariantType {
    return switch (ret) {
        .void => c.GDEXTENSION_VARIANT_TYPE_NIL,
        .bool => c.GDEXTENSION_VARIANT_TYPE_BOOL,
        .int => c.GDEXTENSION_VARIANT_TYPE_INT,
        .float => c.GDEXTENSION_VARIANT_TYPE_FLOAT,
    };
}

pub fn ReturnZig(comptime ret: MethodReturn) type {
    return switch (ret) { .void => void, .bool => bool, .int => i64, .float => f64 };
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
        .bool => { var v: u8 = @intFromBool(value); ctor(out, &v); },
        .int => { var v: i64 = value; ctor(out, &v); },
        .float => { var v: f64 = value; ctor(out, &v); },
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

pub fn Virtual0(comptime T: type, comptime function: *const fn (*T) callconv(.c) void) type {
    return struct {
        pub fn ptrcall(_: ?*anyopaque, instance: c.GDExtensionClassInstancePtr, args: [*c]const c.GDExtensionConstTypePtr, out: c.GDExtensionTypePtr) callconv(.c) void {
            _ = args; _ = out;
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

pub fn registerMethod0(comptime T: type, class_name_text: [:0]const u8, method_name_text: [:0]const u8, comptime ret: MethodReturn, comptime function: *const fn (*T) callconv(.c) ReturnZig(ret)) void {
    var method_name = api_mod.godot.stringName(method_name_text);
    var class_name = api_mod.godot.stringName(class_name_text);
    defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &method_name);
    defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &class_name);

    var return_info: c.GDExtensionPropertyInfo = undefined;
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

pub fn NativeClass(comptime T: type, comptime parent_name_text: [:0]const u8, comptime class_name_text: [:0]const u8) type {
    return struct {
        pub fn create(_: ?*anyopaque, _: c.GDExtensionBool) callconv(.c) c.GDExtensionObjectPtr {
            var parent_name = api_mod.godot.stringName(parent_name_text);
            defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &parent_name);
            const object = api_mod.godot.classdb_construct_object.?(&parent_name);

            const self = api_mod.godot.alloc(T);
            if (@hasDecl(T, "init")) self.* = T.init(object) else self.* = std.mem.zeroes(T);

            var class_name = api_mod.godot.stringName(class_name_text);
            defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &class_name);
            api_mod.godot.object_set_instance.?(object, &class_name, self);
            api_mod.godot.object_set_instance_binding.?(object, api_mod.godot.library, self, &BindingCallbacks);
            return object;
        }

        pub fn free(_: ?*anyopaque, instance: c.GDExtensionClassInstancePtr) callconv(.c) void {
            if (instance != null) api_mod.godot.free(instance.?);
        }

        pub fn register() void {
            var class_name = api_mod.godot.stringName(class_name_text);
            var parent_name = api_mod.godot.stringName(parent_name_text);
            defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &class_name);
            defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &parent_name);
            var info: c.GDExtensionClassCreationInfo6 = std.mem.zeroes(c.GDExtensionClassCreationInfo6);
            info.is_exposed = 1;
            info.create_instance_func = create;
            info.free_instance_func = free;
            if (@hasDecl(T, "getVirtualCallData")) info.get_virtual_call_data_func = T.getVirtualCallData;
            if (@hasDecl(T, "callVirtualWithData")) info.call_virtual_with_data_func = T.callVirtualWithData;
            api_mod.godot.classdb_register_extension_class6.?(api_mod.godot.library, &class_name, &parent_name, &info);
        }
    };
}

test "return type mapping" {
    try std.testing.expect(ReturnZig(.float) == f64);
    try std.testing.expect(variantType(.int) == c.GDEXTENSION_VARIANT_TYPE_INT);
}
