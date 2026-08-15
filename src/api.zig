const std = @import("std");
const c = @import("c.zig").c;
const types = @import("types.zig");

pub const StringName = types.StringName;
pub const String = types.String;
pub const Variant = types.Variant;

pub fn proc(comptime T: type, get_proc_address: c.GDExtensionInterfaceGetProcAddress, name: [*:0]const u8) T {
    return @ptrCast(get_proc_address.?(name));
}

pub const Interface = struct {
    get_proc_address: c.GDExtensionInterfaceGetProcAddress = null,
    library: c.GDExtensionClassLibraryPtr = null,

    mem_alloc: c.GDExtensionInterfaceMemAlloc = null,
    mem_realloc: c.GDExtensionInterfaceMemRealloc = null,
    mem_free: c.GDExtensionInterfaceMemFree = null,

    print_error: c.GDExtensionInterfacePrintError = null,
    print_error_with_message: c.GDExtensionInterfacePrintErrorWithMessage = null,
    print_warning: c.GDExtensionInterfacePrintWarning = null,
    print_warning_with_message: c.GDExtensionInterfacePrintWarningWithMessage = null,
    print_script_error: c.GDExtensionInterfacePrintScriptError = null,
    print_script_error_with_message: c.GDExtensionInterfacePrintScriptErrorWithMessage = null,

    classdb_construct_object: c.GDExtensionInterfaceClassdbConstructObject = null,
    classdb_get_method_bind: c.GDExtensionInterfaceClassdbGetMethodBind = null,
    classdb_register_extension_class6: c.GDExtensionInterfaceClassdbRegisterExtensionClass6 = null,
    classdb_register_extension_class_method: c.GDExtensionInterfaceClassdbRegisterExtensionClassMethod = null,
    classdb_register_extension_class_property: c.GDExtensionInterfaceClassdbRegisterExtensionClassProperty = null,
    classdb_register_extension_class_signal: c.GDExtensionInterfaceClassdbRegisterExtensionClassSignal = null,

    object_method_bind_ptrcall: c.GDExtensionInterfaceObjectMethodBindPtrcall = null,
    object_method_bind_call: c.GDExtensionInterfaceObjectMethodBindCall = null,
    object_set_instance: c.GDExtensionInterfaceObjectSetInstance = null,
    object_set_instance_binding: c.GDExtensionInterfaceObjectSetInstanceBinding = null,
    object_get_instance_binding: c.GDExtensionInterfaceObjectGetInstanceBinding = null,
    object_get_instance_from_id: c.GDExtensionInterfaceObjectGetInstanceFromId = null,
    object_get_instance_id: c.GDExtensionInterfaceObjectGetInstanceId = null,
    object_destroy: c.GDExtensionInterfaceObjectDestroy = null,

    global_get_singleton: c.GDExtensionInterfaceGlobalGetSingleton = null,

    variant_destroy: c.GDExtensionInterfaceVariantDestroy = null,
    variant_get_ptr_constructor: c.GDExtensionInterfaceVariantGetPtrConstructor = null,
    variant_get_ptr_destructor: c.GDExtensionInterfaceVariantGetPtrDestructor = null,
    variant_get_ptr_operator_evaluator: c.GDExtensionInterfaceVariantGetPtrOperatorEvaluator = null,
    variant_get_ptr_builtin_method: c.GDExtensionInterfaceVariantGetPtrBuiltinMethod = null,
    variant_get_ptr_internal_getter: c.GDExtensionInterfaceGetVariantGetInternalPtrFunc = null,
    variant_get_ptr_indexed_getter: c.GDExtensionInterfaceVariantGetPtrIndexedGetter = null,
    variant_get_ptr_indexed_setter: c.GDExtensionInterfaceVariantGetPtrIndexedSetter = null,
    variant_get_type: c.GDExtensionInterfaceVariantGetType = null,
    get_variant_from_type_constructor: c.GDExtensionInterfaceGetVariantFromTypeConstructor = null,
    get_variant_to_type_constructor: c.GDExtensionInterfaceGetVariantToTypeConstructor = null,

    string_new_with_utf8_chars: c.GDExtensionInterfaceStringNewWithUtf8Chars = null,
    string_new_with_utf8_chars_and_len: c.GDExtensionInterfaceStringNewWithUtf8CharsAndLen = null,
    string_name_new_with_latin1_chars: c.GDExtensionInterfaceStringNameNewWithLatin1Chars = null,
    string_name_new_with_utf8_chars: c.GDExtensionInterfaceStringNameNewWithUtf8Chars = null,
    string_name_new_with_utf8_chars_and_len: c.GDExtensionInterfaceStringNameNewWithUtf8CharsAndLen = null,

    packed_vector3_array_operator_index_const: c.GDExtensionInterfacePackedVector3ArrayOperatorIndexConst = null,
    packed_int32_array_operator_index_const: c.GDExtensionInterfacePackedInt32ArrayOperatorIndexConst = null,

    pub fn load(self: *Interface, get_proc_address: c.GDExtensionInterfaceGetProcAddress, library: c.GDExtensionClassLibraryPtr) void {
        self.* = .{ .get_proc_address = get_proc_address, .library = library };
        self.mem_alloc = proc(c.GDExtensionInterfaceMemAlloc, get_proc_address, "mem_alloc");
        self.mem_realloc = proc(c.GDExtensionInterfaceMemRealloc, get_proc_address, "mem_realloc");
        self.mem_free = proc(c.GDExtensionInterfaceMemFree, get_proc_address, "mem_free");
        self.print_error = proc(c.GDExtensionInterfacePrintError, get_proc_address, "print_error");
        self.print_error_with_message = proc(c.GDExtensionInterfacePrintErrorWithMessage, get_proc_address, "print_error_with_message");
        self.print_warning = proc(c.GDExtensionInterfacePrintWarning, get_proc_address, "print_warning");
        self.print_warning_with_message = proc(c.GDExtensionInterfacePrintWarningWithMessage, get_proc_address, "print_warning_with_message");
        self.print_script_error = proc(c.GDExtensionInterfacePrintScriptError, get_proc_address, "print_script_error");
        self.print_script_error_with_message = proc(c.GDExtensionInterfacePrintScriptErrorWithMessage, get_proc_address, "print_script_error_with_message");
        self.classdb_construct_object = proc(c.GDExtensionInterfaceClassdbConstructObject, get_proc_address, "classdb_construct_object");
        self.classdb_get_method_bind = proc(c.GDExtensionInterfaceClassdbGetMethodBind, get_proc_address, "classdb_get_method_bind");
        self.classdb_register_extension_class6 = proc(c.GDExtensionInterfaceClassdbRegisterExtensionClass6, get_proc_address, "classdb_register_extension_class6");
        self.classdb_register_extension_class_method = proc(c.GDExtensionInterfaceClassdbRegisterExtensionClassMethod, get_proc_address, "classdb_register_extension_class_method");
        self.classdb_register_extension_class_property = proc(c.GDExtensionInterfaceClassdbRegisterExtensionClassProperty, get_proc_address, "classdb_register_extension_class_property");
        self.classdb_register_extension_class_signal = proc(c.GDExtensionInterfaceClassdbRegisterExtensionClassSignal, get_proc_address, "classdb_register_extension_class_signal");
        self.object_method_bind_ptrcall = proc(c.GDExtensionInterfaceObjectMethodBindPtrcall, get_proc_address, "object_method_bind_ptrcall");
        self.object_method_bind_call = proc(c.GDExtensionInterfaceObjectMethodBindCall, get_proc_address, "object_method_bind_call");
        self.object_set_instance = proc(c.GDExtensionInterfaceObjectSetInstance, get_proc_address, "object_set_instance");
        self.object_set_instance_binding = proc(c.GDExtensionInterfaceObjectSetInstanceBinding, get_proc_address, "object_set_instance_binding");
        self.object_get_instance_binding = proc(c.GDExtensionInterfaceObjectGetInstanceBinding, get_proc_address, "object_get_instance_binding");
        self.object_get_instance_from_id = proc(c.GDExtensionInterfaceObjectGetInstanceFromId, get_proc_address, "object_get_instance_from_id");
        self.object_get_instance_id = proc(c.GDExtensionInterfaceObjectGetInstanceId, get_proc_address, "object_get_instance_id");
        self.object_destroy = proc(c.GDExtensionInterfaceObjectDestroy, get_proc_address, "object_destroy");
        self.global_get_singleton = proc(c.GDExtensionInterfaceGlobalGetSingleton, get_proc_address, "global_get_singleton");
        self.variant_destroy = proc(c.GDExtensionInterfaceVariantDestroy, get_proc_address, "variant_destroy");
        self.variant_get_ptr_constructor = proc(c.GDExtensionInterfaceVariantGetPtrConstructor, get_proc_address, "variant_get_ptr_constructor");
        self.variant_get_ptr_destructor = proc(c.GDExtensionInterfaceVariantGetPtrDestructor, get_proc_address, "variant_get_ptr_destructor");
        self.variant_get_ptr_operator_evaluator = proc(c.GDExtensionInterfaceVariantGetPtrOperatorEvaluator, get_proc_address, "variant_get_ptr_operator_evaluator");
        self.variant_get_ptr_builtin_method = proc(c.GDExtensionInterfaceVariantGetPtrBuiltinMethod, get_proc_address, "variant_get_ptr_builtin_method");
        self.variant_get_ptr_internal_getter = proc(c.GDExtensionInterfaceGetVariantGetInternalPtrFunc, get_proc_address, "variant_get_ptr_internal_getter");
        self.variant_get_ptr_indexed_getter = proc(c.GDExtensionInterfaceVariantGetPtrIndexedGetter, get_proc_address, "variant_get_ptr_indexed_getter");
        self.variant_get_ptr_indexed_setter = proc(c.GDExtensionInterfaceVariantGetPtrIndexedSetter, get_proc_address, "variant_get_ptr_indexed_setter");
        self.variant_get_type = proc(c.GDExtensionInterfaceVariantGetType, get_proc_address, "variant_get_type");
        self.get_variant_from_type_constructor = proc(c.GDExtensionInterfaceGetVariantFromTypeConstructor, get_proc_address, "get_variant_from_type_constructor");
        self.get_variant_to_type_constructor = proc(c.GDExtensionInterfaceGetVariantToTypeConstructor, get_proc_address, "get_variant_to_type_constructor");
        self.string_new_with_utf8_chars = proc(c.GDExtensionInterfaceStringNewWithUtf8Chars, get_proc_address, "string_new_with_utf8_chars");
        self.string_new_with_utf8_chars_and_len = proc(c.GDExtensionInterfaceStringNewWithUtf8CharsAndLen, get_proc_address, "string_new_with_utf8_chars_and_len");
        self.string_name_new_with_latin1_chars = proc(c.GDExtensionInterfaceStringNameNewWithLatin1Chars, get_proc_address, "string_name_new_with_latin1_chars");
        self.string_name_new_with_utf8_chars = proc(c.GDExtensionInterfaceStringNameNewWithUtf8Chars, get_proc_address, "string_name_new_with_utf8_chars");
        self.string_name_new_with_utf8_chars_and_len = proc(c.GDExtensionInterfaceStringNameNewWithUtf8CharsAndLen, get_proc_address, "string_name_new_with_utf8_chars_and_len");
        self.packed_vector3_array_operator_index_const = proc(c.GDExtensionInterfacePackedVector3ArrayOperatorIndexConst, get_proc_address, "packed_vector3_array_operator_index_const");
        self.packed_int32_array_operator_index_const = proc(c.GDExtensionInterfacePackedInt32ArrayOperatorIndexConst, get_proc_address, "packed_int32_array_operator_index_const");
    }

    pub fn alloc(self: *const Interface, comptime T: type) *T {
        return @ptrCast(@alignCast(self.mem_alloc.?(@sizeOf(T))));
    }

    pub fn free(self: *const Interface, ptr: anytype) void {
        self.mem_free.?(@ptrCast(ptr));
    }

    pub fn stringName(self: *const Interface, text: [:0]const u8) StringName {
        var value: StringName = undefined;
        self.string_name_new_with_utf8_chars_and_len.?(&value, text.ptr, @intCast(text.len));
        return value;
    }

    pub fn stringNameLatin1(self: *const Interface, text: [*:0]const u8) StringName {
        var value: StringName = undefined;
        self.string_name_new_with_latin1_chars.?(&value, text, 0);
        return value;
    }

    pub fn string(self: *const Interface, text: [:0]const u8) String {
        var value: String = undefined;
        self.string_new_with_utf8_chars_and_len.?(&value, text.ptr, @intCast(text.len));
        return value;
    }

    pub fn destroy(self: *const Interface, comptime variant_type: c.GDExtensionVariantType, value: anytype) void {
        const destructor = self.variant_get_ptr_destructor.?(variant_type);
        if (destructor) |d| d(@ptrCast(value));
    }

    pub fn bind(self: *const Interface, class_name_text: [:0]const u8, method_name_text: [:0]const u8, hash: i64) c.GDExtensionMethodBindPtr {
        var class_name = self.stringName(class_name_text);
        var method_name = self.stringName(method_name_text);
        defer self.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &method_name);
        defer self.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &class_name);
        return self.classdb_get_method_bind.?(&class_name, &method_name, hash);
    }

    pub fn singleton(self: *const Interface, name_text: [:0]const u8) c.GDExtensionObjectPtr {
        var name = self.stringName(name_text);
        defer self.destroy(c.GDEXTENSION_VARIANT_TYPE_STRING_NAME, &name);
        return self.global_get_singleton.?(&name);
    }
};

pub var godot: Interface = .{};

pub fn init(get_proc_address: c.GDExtensionInterfaceGetProcAddress, library: c.GDExtensionClassLibraryPtr) void {
    godot.load(get_proc_address, library);
}

pub fn deinit() void {
    godot = .{};
}

test "Interface is constructible" {
    const iface: Interface = .{};
    try std.testing.expect(iface.library == null);
}
