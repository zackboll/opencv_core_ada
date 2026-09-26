with OpenCV.Core;

--  Test-only generic that checks one typed buffer-access package against a
--  genuine 2 x 3 x 4 Mat. The flat offset of zero-based index (I, J, K) is
--  ((I * 3) + J) * 4 + K. Value_At must return pairwise distinct values
--  for offsets 0 .. 23 and 100 .. 102.

generic
   type Element is private;
   type Buffer_Array is array (Natural range <>) of Element;
   Element_Type : OpenCV.Core.Mat_Type;
   Name : String;
   with function Value_At (Offset : Natural) return Element;
   with
     function Get
       (Image : OpenCV.Core.Mat; Indices : OpenCV.Core.Index_Array)
        return Element;
   with
     procedure Set
       (Image   : in out OpenCV.Core.Mat;
        Indices : OpenCV.Core.Index_Array;
        Value   : Element);
   with
     procedure With_Read_Only_Buffer
       (Image   : OpenCV.Core.Mat;
        Process : not null access procedure (Data : aliased Buffer_Array));
   with
     procedure With_Writable_Buffer
       (Image   : in out OpenCV.Core.Mat;
        Process :
          not null access procedure (Data : aliased in out Buffer_Array));
package ND_Buffer_Checks is

   --  Read-only and writable borrow of a packed 3-D Mat: length, zero
   --  base, flat order against N-D Get, last element, and immediate
   --  two-way alias visibility.
   procedure Check_Volume;

   --  Slice (1 .. 1, all, all) is asserted continuous, borrowed as 12
   --  elements, and written through to the source.
   procedure Check_Continuous_Slice;

   --  Slice (all, 1 .. 1, all) is asserted non-continuous and rejected by
   --  both borrows with OpenCV_Error before Process is invoked.
   procedure Check_Gapped_Slice;

end ND_Buffer_Checks;
