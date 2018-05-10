// Copyright 2014-present Ryan Gomba. All rights reserved.

#ifndef RGFoundation_RGMacros_h
#define RGFoundation_RGMacros_h

#define rg_macro_concat_(x, y) x ## y
#define rg_macro_concat(x, y) rg_macro_concat_(x, y)

// Macro for declaring compile-time checked kvo paths
// usage:
//  [receiver setValue:foo
//          forKeyPath:(receiver, property.key.path)]  // generates compile-time error if path is invalid for receiver
//
#define RGKeypath(object, keyPath) \
@(((void)(NO && ((void)object.keyPath, NO)), # keyPath))

// weakify and strongify macros
// usage:
//
//  weakify(self);
//  self.block = ^{
//      stronfigy(self);
//      [self doStuff];
//  };
//
#define weakify(arg) \
typeof(arg) __weak rg_weak_##arg = arg

#define strongify(arg) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
typeof(arg) arg = rg_weak_##arg \
_Pragma("clang diagnostic pop")


// A construct that executes when we exit the current scope
// usage:
//  if (a == b) {
//      FILE *file = fopen("/foo", "rw");
//      on_exit{
//          fclose(file);
//      };
//      ...
//  }           <--- on_exit block executes here
#define on_exit \
__strong dispatch_block_t rg_macro_concat(rg_exit_block_, __LINE__) __attribute__((cleanup(rg_executeScopeExitBlock), unused)) = ^


// implementation detail, do not use directly
NS_INLINE void rg_executeScopeExitBlock(__strong dispatch_block_t *block) {
    (*block)();
}

NS_INLINE void CFSafeRelease(CFTypeRef cfobject) {
    if(cfobject) {
        CFRelease(cfobject);
    }
}


// MIN_MAX macro
// usage: (value, min_allowable, max_allowable)
#define MIN_MAX(A,B,C) ({ \
__typeof__(A) __a = (A); __typeof__(B) __b = (B); __typeof__(C) __c = (C); \
__a < __b ? __b : (__a > __c ? __c : __a); \
})


// Safely cast an object to a particular class type
// If the object is not an instance of this class, the cast returns nil
#define RGSafeCast(object, cls) ((cls *)([object isKindOfClass:[cls class]] ? object : nil))


#endif
