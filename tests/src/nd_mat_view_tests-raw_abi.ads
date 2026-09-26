package ND_Mat_View_Tests.Raw_ABI is

   --  Direct opencv_core_mat_create_external_nd checks through the thin
   --  interop layer. Every rejected call pre-seeds a non-null output handle
   --  and asserts that the shim clears it and leaves backing storage intact.
   procedure Check_Rejections;

   --  Valid 2-D and 3-D packed raw views report the requested geometry and
   --  type, are continuous, and borrow exactly the caller buffer.
   procedure Check_Valid_Views;

   --  A raw N-D external handle carries the temporary external-view flag:
   --  shallow copy, Slice, and Reshape are rejected, while Clone succeeds
   --  with independent, unflagged storage.
   procedure Check_Temporary_View;

end ND_Mat_View_Tests.Raw_ABI;
