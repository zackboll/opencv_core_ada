package ND_Strided_Mat_View_Tests.Raw_ABI is

   --  Direct opencv_core_mat_create_external_nd_strided checks through the
   --  thin interop layer. Every rejected call pre-seeds a non-null output
   --  handle and asserts that the shim clears it and leaves backing storage
   --  intact.
   procedure Check_Rejections;

   --  Valid packed-equivalent and gapped 3-D raw views report the requested
   --  geometry, type, and continuity; raw N-D Get/Set reach the expected
   --  caller offsets; extra trailing capacity is accepted; the native
   --  dimension limit is accepted; destruction leaves caller storage intact.
   procedure Check_Valid_Views;

   --  A raw strided N-D handle carries the temporary external-view flag:
   --  shallow copy, Slice, and Reshape are rejected, while Clone succeeds
   --  with independent, packed, unflagged storage holding logical values.
   procedure Check_Temporary_View;

end ND_Strided_Mat_View_Tests.Raw_ABI;
