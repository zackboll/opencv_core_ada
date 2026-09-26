with OpenCV.Core;

--  Test-only generic that checks one typed *_Mat_View package's packed
--  N-D Shape overload against its N-D typed access and N-D continuous
--  buffer-access packages. Caller storage deliberately uses a nonzero lower
--  bound. The flat offset of zero-based index (I, J, K) in a 2 x 3 x 4 view
--  is ((I * 3) + J) * 4 + K. Value_At must return pairwise distinct values
--  for offsets 0 .. 23 and 100 .. 102.

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
     procedure With_Rows_Columns_View
       (Data    : aliased in out View_Array;
        Rows    : Positive;
        Columns : Positive;
        Process : not null access procedure (Image : in out OpenCV.Core.Mat));
   with
     procedure With_Read_Only_Buffer
       (Image   : OpenCV.Core.Mat;
        Process : not null access procedure (Data : aliased Borrow_Array));
   with
     procedure With_Writable_Buffer
       (Image   : in out OpenCV.Core.Mat;
        Process :
          not null access procedure (Data : aliased in out Borrow_Array));
package ND_Mat_View_Checks is

   --  Shape (7 .. 9) => (2, 3, 4) over Data (11 .. 34): metadata,
   --  continuity, every N-D coordinate against caller storage, two-way
   --  alias visibility, and nested N-D read-only / writable buffer borrows
   --  that expose the caller's exact storage address without copying.
   procedure Check_Volume;

   --  Shape => (2, 3) and Rows => 2, Columns => 3 over the same storage
   --  expose identical geometry and flat mapping.
   procedure Check_Two_Dimensional_Shape;

   --  Slice and N-D Reshape of the temporary view are rejected; Clone
   --  succeeds, owns independent storage, and can itself Slice and Reshape.
   procedure Check_No_Escape_And_Clone;

end ND_Mat_View_Checks;
