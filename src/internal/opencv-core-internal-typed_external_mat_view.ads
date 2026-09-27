generic
   type Element_Type is private;
   type Buffer_Array is array (Natural range <>) of Element_Type;
   Required_Depth : Depth_Type;
   Required_Channels : Channel_Count;
   Expected_Element_Bits : Positive;
   Native_Element_Alignment : Positive;
   Type_Name : String;
package OpenCV.Core.Internal.Typed_External_Mat_View is

   --  Invokes Process with a temporary Mat whose pixels alias Data.
   --  The Mat header does not own Data and is valid only during Process.
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Rows    : Positive;
      Columns : Positive;
      Process : not null access procedure (Image : in out Mat));

   --  Invokes Process with a temporary packed N-D Mat whose elements alias
   --  Data. Shape'Length must be in 2 .. 32, every extent must be positive,
   --  and Data'Length must equal product (Shape) exactly. Shape iteration
   --  order maps to OpenCV dimension order and the final dimension varies
   --  fastest in Data. Neither Ada lower bound is visible through the Mat.
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : in out Mat));

   --  Invokes Process with a temporary Mat whose logical rows alias Data at
   --  Row_Stride_Elements complete Buffer_Array elements apart. Data must
   --  contain a complete stride for every row, including padding after the
   --  final logical row: Data'Length >= Rows * Row_Stride_Elements.
   procedure With_Writable_Strided_Mat_View
     (Data                : aliased in out Buffer_Array;
      Rows                : Positive;
      Columns             : Positive;
      Row_Stride_Elements : Positive;
      Process             : not null access procedure (Image : in out Mat));

   --  Invokes Process with a temporary strided N-D Mat whose elements alias
   --  Data. Shape'Length must be in 2 .. 32 with positive extents, and
   --  Strides'Length must equal Shape'Length. Strides count complete
   --  Buffer_Array elements; the final stride must be 1 and every outer
   --  stride must cover its complete nested inner block:
   --  Stride (I) >= Stride (I + 1) * Shape (I + 1). Zero-based index
   --  (I1, .., In) is Data (Data'First + I1 * S1 + .. + In * Sn). Data must
   --  contain the complete outer stride, including padding after the final
   --  logical outer block: Data'Length >= Shape (first) * Stride (first).
   procedure With_Writable_Strided_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Strides : Dimension_Stride_Array;
      Process : not null access procedure (Image : in out Mat));

   --  Caller-owned, zero-copy views with the same geometry and capacity
   --  rules as the writable counterparts. Aliased constant Data is accepted.
   --  The mode-in callback cannot call normal in-place Ada Mat operations;
   --  memory is not page-protected. Shallow escape is forbidden; Clone owns
   --  independent pixels and Module_Interop input handles remain available.
   procedure With_Read_Only_Mat_View
     (Data    : aliased Buffer_Array;
      Rows    : Positive;
      Columns : Positive;
      Process : not null access procedure (Image : Mat));

   procedure With_Read_Only_Mat_View
     (Data    : aliased Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : Mat));

   procedure With_Read_Only_Strided_Mat_View
     (Data                : aliased Buffer_Array;
      Rows                : Positive;
      Columns             : Positive;
      Row_Stride_Elements : Positive;
      Process             : not null access procedure (Image : Mat));

   procedure With_Read_Only_Strided_Mat_View
     (Data    : aliased Buffer_Array;
      Shape   : Dimension_Array;
      Strides : Dimension_Stride_Array;
      Process : not null access procedure (Image : Mat));

end OpenCV.Core.Internal.Typed_External_Mat_View;
