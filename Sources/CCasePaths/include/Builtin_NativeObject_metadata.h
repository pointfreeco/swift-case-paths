#ifndef Builtin_NativeObject_metadata_H
#define Builtin_NativeObject_metadata_H

/// Return the address of the “full” metadata for Builtin.NativeObject. A pointer to metadata usually points to the `kind` field of the metadata, which is not the first field of the metadata. The value witness table pointer precedes the `kind` field.
///
/// Ideally this would be declared `__nonnull`, but the Linux compiler doesn't like that.
void const *getBuiltinNativeObjectFullMetadata();

#endif /* Builtin_NativeObject_metadata_H */
