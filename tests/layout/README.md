# Float16 Vec2 layout qualification

After the normal Core build, run `sh tests/layout/run_controls.sh` from the
repository root on Linux. The tests use actual production units and GNU ld
constructor, lease, borrowed-address, and destruction interception. No mock
constructor or modified shim is used. Both O0 and O2/-gnatp are exercised.

The three distinct negative evidence categories are:

1. A padded record with Size=32, Object_Size=64 and compressed array components
   of 32 bits cannot instantiate typed row borrowing: the compiler rejects
   static matching of the aliased callback argument. This is a compile-time
   gate, not an executable borrowing negative.
2. `Layout_Guard_Controls` independently executes the exact internal layout
   helper with a legal padded object. `Object_Size_Negative` additionally rejects
   that representation through all eight external-view forms with constructor,
   callback, live-header and complete initialized-byte controls.
3. A legal borrowing instantiation with an incorrect native allowance rejects
   all four operations before any intercepted lease entry. Actual Vec2 positive
   paths establish successful lease interception and balanced destruction.

Misaligned borrowed addresses are formed only by offsetting an untyped returned
address in the test wrapper; they are rejected before typed conversion. No
invalid typed overlay is dereferenced. Exception and misalignment paths compare
the complete 32-byte initialized backing buffer and verify zero retained leases.

Only Vec2 concrete vector Object_Size/alignment compile-time conditions move
to call-time enforcement. Scalar Object_Size, Size, vector component size,
buffer/row component size, component indices and C_API assertions remain static.
The internal generic alignment conditions become ordinary call-time checks in
the shared helper. The actual address is checked before construction or typed
conversion; representation is checked before native lease acquisition.

These focused executables are not evidence of full GNAT 12 library support.