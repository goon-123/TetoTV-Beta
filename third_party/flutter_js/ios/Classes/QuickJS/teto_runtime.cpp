// Preserve the upstream FFI ABI, memory limit and interrupt deadlines.
#include "../../../android/src/main/c/quickjs_runtime.cpp"

// Referenced by Objective-C registration so the static linker includes this
// object. DLLEXPORT's used attribute retains the symbols looked up by Dart.
extern "C" __attribute__((visibility("default"))) __attribute__((used))
void tetoEnsureQuickJSLinked(void) {}

// The Dart FFI layer prefers this exported bridge name. Keeping a direct
// reference also prevents release dead stripping of QuickJS's memory limiter.
extern "C" __attribute__((visibility("default"))) __attribute__((used))
void jsSetMemoryLimit(JSRuntime *runtime, size_t limit) {
    JS_SetMemoryLimit(runtime, limit);
}
