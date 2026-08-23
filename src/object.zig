const std = @import("std");
const c = @import("c.zig").c;
const api_mod = @import("api.zig");
const types = @import("types.zig");
const Variant = @import("variant.zig").Variant;
const signal = @import("signal.zig");

pub const Callable = struct {
    value: types.Callable,

    pub fn fromObjectMethod(object: Object, method_name_text: [:0]const u8) Callable {
        var out: types.Callable = std.mem.zeroes(types.Callable);
        var raw_object = object.ptr;
        var method_name = api_mod.godot.stringName(method_name_text);
        defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &method_name);

        const args = [_]c.GDExtensionConstTypePtr{ @ptrCast(&raw_object), &method_name };
        const constructor = api_mod.godot.variant_get_ptr_constructor.?(
            c.GDEXTENSION_VARIANT_TYPE_CALLABLE,
            2,
        ).?;
        constructor(&out, &args);
        return .{ .value = out };
    }

    pub fn destroy(self: *Callable) void {
        api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_CALLABLE, &self.value);
    }
};

pub const SignalCallError = error{SignalCallFailed};

/// Minimal raw object handle used by generated class wrappers.
///
/// Godot engine classes themselves are generated from `extension_api.json` in
/// `src/generated/classes.zig`. Keep this file small: it is the common object
/// storage/escape hatch, not a hand-written class binding layer.
pub const Object = struct {
    ptr: c.GDExtensionObjectPtr = null,

    pub fn init(ptr: c.GDExtensionObjectPtr) Object {
        return .{ .ptr = ptr };
    }

    pub fn isNull(self: Object) bool {
        return self.ptr == null;
    }

    pub fn destroy(self: Object) void {
        if (self.ptr != null) api_mod.godot.object_destroy.?(self.ptr);
    }

    pub fn instanceId(self: Object) c.GDObjectInstanceID {
        return api_mod.godot.object_get_instance_id.?(self.ptr);
    }

    pub fn fromInstanceId(id: c.GDObjectInstanceID) Object {
        return .{ .ptr = api_mod.godot.object_get_instance_from_id.?(id) };
    }

    pub fn ptrcall(self: Object, method: c.GDExtensionMethodBindPtr, args: ?[*]const c.GDExtensionConstTypePtr, ret: c.GDExtensionTypePtr) void {
        api_mod.godot.object_method_bind_ptrcall.?(method, self.ptr, if (args) |a| a else null, ret);
    }

    pub fn callVariant0(self: Object, method: c.GDExtensionMethodBindPtr) Variant {
        var out: types.Variant = std.mem.zeroes(types.Variant);
        var err: c.GDExtensionCallError = std.mem.zeroes(c.GDExtensionCallError);
        api_mod.godot.object_method_bind_call.?(method, self.ptr, null, 0, &out, &err);
        return .{ .value = out };
    }

    pub fn callVariant1(self: Object, method: c.GDExtensionMethodBindPtr, arg0: *const Variant) Variant {
        var out: types.Variant = std.mem.zeroes(types.Variant);
        var err: c.GDExtensionCallError = std.mem.zeroes(c.GDExtensionCallError);
        const args = [_]c.GDExtensionConstVariantPtr{&arg0.value};
        api_mod.godot.object_method_bind_call.?(method, self.ptr, &args, 1, &out, &err);
        return .{ .value = out };
    }

    pub fn callVariant2(self: Object, method: c.GDExtensionMethodBindPtr, arg0: *const Variant, arg1: *const Variant) Variant {
        var out: types.Variant = std.mem.zeroes(types.Variant);
        var err: c.GDExtensionCallError = std.mem.zeroes(c.GDExtensionCallError);
        const args = [_]c.GDExtensionConstVariantPtr{ &arg0.value, &arg1.value };
        api_mod.godot.object_method_bind_call.?(method, self.ptr, &args, 2, &out, &err);
        return .{ .value = out };
    }

    pub fn callVariant3(self: Object, method: c.GDExtensionMethodBindPtr, arg0: *const Variant, arg1: *const Variant, arg2: *const Variant) Variant {
        var out: types.Variant = std.mem.zeroes(types.Variant);
        var err: c.GDExtensionCallError = std.mem.zeroes(c.GDExtensionCallError);
        const args = [_]c.GDExtensionConstVariantPtr{ &arg0.value, &arg1.value, &arg2.value };
        api_mod.godot.object_method_bind_call.?(method, self.ptr, &args, 3, &out, &err);
        return .{ .value = out };
    }

    pub fn connectSignal(self: Object, comptime Signal: type, callable: Callable) i64 {
        const method = api_mod.godot.bind("Object", "connect", 1518946055);
        var signal_name = api_mod.godot.stringName(signal.name(Signal));
        defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &signal_name);
        var callable_value = callable.value;
        var flags: i64 = 0;
        const args = [_]c.GDExtensionConstTypePtr{ &signal_name, &callable_value, &flags };
        var result: i64 = 0;
        self.ptrcall(method, &args, &result);
        return result;
    }

    pub fn disconnectSignal(self: Object, comptime Signal: type, callable: Callable) void {
        const method = api_mod.godot.bind("Object", "disconnect", 1874754934);
        var signal_name = api_mod.godot.stringName(signal.name(Signal));
        defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &signal_name);
        var callable_value = callable.value;
        const args = [_]c.GDExtensionConstTypePtr{ &signal_name, &callable_value };
        self.ptrcall(method, &args, null);
    }

    pub fn emitSignal(self: Object, comptime Signal: type, payload: Signal) SignalCallError!i64 {
        const fields = @typeInfo(Signal).@"struct".fields;
        var variants: [fields.len + 1]Variant = undefined;

        var signal_name = api_mod.godot.stringName(signal.name(Signal));
        defer api_mod.godot.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &signal_name);
        variants[0] = Variant.fromStringName(signal_name);
        inline for (fields, 0..) |field, i| {
            variants[i + 1] = Variant.from(@field(payload, field.name));
        }
        defer inline for (&variants) |*variant| variant.destroy();

        var args: [fields.len + 1]c.GDExtensionConstVariantPtr = undefined;
        inline for (&variants, 0..) |*variant, i| {
            args[i] = &variant.value;
        }

        const method = api_mod.godot.bind("Object", "emit_signal", 4047867050);
        var result_value: types.Variant = std.mem.zeroes(types.Variant);
        var call_error: c.GDExtensionCallError = std.mem.zeroes(c.GDExtensionCallError);
        api_mod.godot.object_method_bind_call.?(
            method,
            self.ptr,
            &args,
            @intCast(args.len),
            &result_value,
            &call_error,
        );
        if (call_error.@"error" != c.GDEXTENSION_CALL_OK) {
            return error.SignalCallFailed;
        }

        var result = Variant{ .value = result_value };
        defer result.destroy();
        return result.to(i64);
    }
};

const TestSignal = struct {
    pub const signal_name: [:0]const u8 = "test_signal";
    point: types.Vector3,
    strength: f64,
};

fn compileSignalApi(object: Object, callable: Callable, payload: TestSignal) void {
    _ = object.connectSignal(TestSignal, callable);
    _ = object.emitSignal(TestSignal, payload) catch return;
    object.disconnectSignal(TestSignal, callable);
}

test "typed signal object API compiles" {
    _ = &compileSignalApi;
}
