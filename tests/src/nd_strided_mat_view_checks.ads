with OpenCV.Core;

--  Test-only generic that checks one typed *_Mat_View package's strided N-D
--  overload With_Writable_Strided_Mat_View (Data, Shape, Strides, Process)
--  against the packed Shape overload, the 2-D row-strided overload, N-D typed
--  access, and N-D continuous buffer access. One Data element is one complete
--  Mat element. Value_At must return pairwise distinct values for offsets
--  0 .. 23, 50 (padding sentinel), 60 (trailing sentinel), and 100 .. 103.
--
--  The canonical gapped fixture is Shape (2, 3, 4) with Strides (20, 6, 1)
--  over 40 elements. Logical (I, J, K) lives at offset I * 20 + J * 6 + K;
--  offsets 4 .. 5, 10 .. 11, 16 .. 19, 24 .. 25, 30 .. 31, and 36 .. 39 are
--  padding, including the final outer padding 36 .. 39.

generic
   type Element is private;
   type View_Array is array (Natural range <>) of Element;
   type Borrow_Array is array (Natural range <>) of Element;
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
     procedure With_Shape_View
       (Data    : aliased in out View_Array;
        Shape   : OpenCV.Core.Dimension_Array;
        Process : not null access procedure (Image : in out OpenCV.Core.Mat));
   with
     procedure With_Strided_View
       (Data    : aliased in out View_Array;
        Shape   : OpenCV.Core.Dimension_Array;
        Strides : OpenCV.Core.Dimension_Stride_Array;
        Process : not null access procedure (Image : in out OpenCV.Core.Mat));
   with
     procedure With_Row_Strided_View
       (Data       : aliased in out View_Array;
        Rows       : Positive;
        Columns    : Positive;
        Row_Stride : Positive;
        Process    :
          not null access procedure (Image : in out OpenCV.Core.Mat));
   with
     procedure With_Read_Only_Buffer
       (Image   : OpenCV.Core.Mat;
        Process : not null access procedure (Data : aliased Borrow_Array));
   with
     procedure With_Writable_Buffer
       (Image   : in out OpenCV.Core.Mat;
        Process :
          not null access procedure (Data : aliased in out Borrow_Array));
package ND_Strided_Mat_View_Checks is

   --  Shape (7 .. 9) => (2, 3, 4), Strides (11 .. 13) => (20, 6, 1) over
   --  Data (17 .. 56): metadata, non-continuity, every coordinate against
   --  caller offsets (including (0, 1, 2) -> Data (25), (1, 0, 0) ->
   --  Data (37), (1, 2, 3) -> Data (52)), N-D Set into caller Data, direct
   --  caller writes visible to N-D Get, rejection of both continuous buffer
   --  borrows before their callbacks, and untouched padding.
   procedure Check_Gapped_Volume;

   --  Strides (12, 4, 1) describe packed storage: the view is continuous,
   --  agrees with the packed Shape overload, and nested read-only / writable
   --  buffer borrows alias caller Data exactly. Extra trailing storage past
   --  Shape (first) * Strides (first) is untouched.
   procedure Check_Packed_Equivalent;

   --  Shape (2, 3), Strides (5, 1) and Rows => 2, Columns => 3,
   --  Row_Stride => 5 over the same storage expose identical geometry,
   --  offsets, continuity classification, and padding behavior.
   procedure Check_Two_Dimensional_Equivalence;

   --  Slice, Reshape, and shallow copy of a gapped view are rejected. Clone
   --  keeps only the logical values, is continuous owned storage independent
   --  of later caller writes to logical data and padding, and can Slice and
   --  Reshape normally.
   procedure Check_No_Escape_And_Clone;

end ND_Strided_Mat_View_Checks;
