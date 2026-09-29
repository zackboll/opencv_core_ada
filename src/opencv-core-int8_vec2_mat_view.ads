with OpenCV.Core.Int8_Vec2;

package OpenCV.Core.Int8_Vec2_Mat_View is
   type Buffer_Array is array (Natural range <>) of Int8_Vec2.Vector;
   --  Callback-scoped CV_8SC2 Mat headers over caller-owned Data. One Data
   --  entry is one complete 2-byte C2 element; each component is a signed
   --  -128 .. 127 value. Packed views require Data'Length = Rows * Columns
   --  or product (Shape). Strides count complete Int8_Vec2 elements, not
   --  scalar Int8 channels or bytes; the final N-D stride is 1 and padding
   --  is never touched. No data is copied and the caller retains ownership.
   --  The Mat is valid only during Process: shallow copies, Region, Slice
   --  and Reshape are rejected; Clone is the independent escape path.
   --  Components 0 and 1 are OpenCV channels 0 and 1; no semantic channel
   --  meaning is assigned.
   procedure With_Writable_Mat_View
     (Data          : aliased in out Buffer_Array;
      Rows, Columns : Positive;
      Process       : not null access procedure (Image : in out Mat));
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : in out Mat));
   procedure With_Writable_Strided_Mat_View
     (Data                      : aliased in out Buffer_Array;
      Rows, Columns, Row_Stride : Positive;
      Process                   :
        not null access procedure (Image : in out Mat));
   procedure With_Writable_Strided_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Strides : Dimension_Stride_Array;
      Process : not null access procedure (Image : in out Mat));
   procedure With_Read_Only_Mat_View
     (Data          : aliased Buffer_Array;
      Rows, Columns : Positive;
      Process       : not null access procedure (Image : Mat));
   procedure With_Read_Only_Mat_View
     (Data    : aliased Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : Mat));
   procedure With_Read_Only_Strided_Mat_View
     (Data                      : aliased Buffer_Array;
      Rows, Columns, Row_Stride : Positive;
      Process                   : not null access procedure (Image : Mat));
   procedure With_Read_Only_Strided_Mat_View
     (Data    : aliased Buffer_Array;
      Shape   : Dimension_Array;
      Strides : Dimension_Stride_Array;
      Process : not null access procedure (Image : Mat));
end OpenCV.Core.Int8_Vec2_Mat_View;
