package ND_Selected_View_Tests.Raw_ABI is

   --  Direct opencv_core_mat_select_nd_view rejections through the thin
   --  interop layer. Every rejected call pre-seeds a non-null output handle
   --  and asserts the shim clears it and leaves source data unchanged.
   procedure Check_Rejections;

   --  Valid leading-drop (continuous 2-D plane), middle-drop (gapped 2-D,
   --  the carrier-construction case whose final logical element is the
   --  source allocation end), and 4-D -> 3-D selections report the expected
   --  geometry, continuity, and submatrix state; raw N-D Get/Set map both
   --  ways between source and view.
   procedure Check_Valid_Views;

   --  Destroying the source handle leaves the selected view usable; a borrow
   --  lease taken from the view stays usable after the view is destroyed.
   procedure Check_Storage_Guard;

   --  The selected handle is temporary: copy, Slice, Reshape, output
   --  resolution, and re-selection are rejected, while Clone succeeds with
   --  independent, unflagged storage.
   procedure Check_Temporary_View;

end ND_Selected_View_Tests.Raw_ABI;
