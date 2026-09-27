package OpenCV.Core.UInt16_Mat_View is

   type Buffer_Array is array (Natural range <>) of UInt16_Value;

   --  Invokes Process with a temporary writable CV_16UC1 Mat that aliases
   --  Data. Image (0, 0) is Data (Data'First), and row-major element Image
   --  (Row, Column) is Data (Data'First + Row * Columns + Column).
   --  Data'Length must equal Rows * Columns. The Ada lower bound is not
   --  exposed through the Mat. Image is valid only during Process and must
   --  not be retained. Ordinary shallow copies and views are rejected
   --  because they would share the caller-owned buffer after Process returns.
   --  Clone is the supported way to keep an independent Mat. Writes through
   --  Image immediately modify Data, and writes through Data immediately
   --  affect Image. The temporary cv::Mat header does not own or copy Data.
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Rows    : Positive;
      Columns : Positive;
      Process : not null access procedure (Image : in out Mat));

   --  Invokes Process with a temporary writable packed N-dimensional
   --  CV_16UC1 Mat that aliases Data. Shape'Length must be in 2 .. 32 and
   --  every extent must be positive; Shape iteration order maps directly to
   --  OpenCV dimension order regardless of Shape'First. Data'Length must
   --  equal product (Shape) exactly. Storage is packed and continuous with
   --  the final dimension varying fastest: zero-based index (I1, .., In)
   --  is Data (Data'First + ((I1 * D2 + I2) * D3 + ..) * Dn + In). Neither
   --  Ada lower bound is exposed through the Mat. Shape => (Rows, Columns)
   --  has the same geometry as the Rows/Columns overload. No data is
   --  copied and the caller retains ownership. Callback lifetime and escape
   --  rules are identical to the Rows/Columns overload: shallow copies,
   --  Slice, and Reshape are rejected; Clone is the independent escape path.
   --  Gapped N-D storage uses With_Writable_Strided_Mat_View (Shape,
   --  Strides).
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : in out Mat));

   --  Invokes Process with a temporary writable CV_16UC1 Mat that aliases
   --  Data with Row_Stride UInt16 elements between logical row starts.
   --  Row_Stride must be at least Columns. Image (Row, Column) maps to
   --  Data (Data'First + Row * Row_Stride + Column). Data'Length must be at
   --  least Rows * Row_Stride, including padding after the final logical row.
   --  Padding and extra trailing storage are outside the logical Mat.
   --  No data is copied. Ownership, callback lifetime, and escape rules are
   --  identical to With_Writable_Mat_View; Clone is the safe escape path.
   procedure With_Writable_Strided_Mat_View
     (Data       : aliased in out Buffer_Array;
      Rows       : Positive;
      Columns    : Positive;
      Row_Stride : Positive;
      Process    : not null access procedure (Image : in out Mat));

   --  Invokes Process with a temporary writable strided N-dimensional
   --  CV_16UC1 Mat that aliases Data. Shape'Length must be in 2 .. 32 with
   --  positive extents, and Strides supplies exactly one stride per
   --  dimension in the same order; neither array's index bounds matter.
   --  Strides count complete UInt16 elements, not bytes. The final stride
   --  must be 1 and each outer stride must cover its nested inner block:
   --  Strides (I) >= Strides (I + 1) * Shape (I + 1), so layouts never
   --  overlap or run backwards. Zero-based index (I1, .., In) is
   --  Data (Data'First + I1 * S1 + .. + In * Sn). Data'Length must be at
   --  least Shape (first) * Strides (first): the complete outer stride,
   --  including padding after the final logical outer block, is part of the
   --  native header and must exist. Extra trailing storage is allowed and is
   --  outside the header; padding is never a logical element and is not
   --  touched. Is_Continuous reports the actual layout, so packed-equivalent
   --  strides are continuous. No data is copied and the caller retains
   --  ownership. Callback lifetime and escape rules match the other
   --  overloads: shallow copies, Slice, Reshape, and output handles are
   --  rejected; Clone is the independent escape path and holds only the
   --  logical values.
   procedure With_Writable_Strided_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Strides : Dimension_Stride_Array;
      Process : not null access procedure (Image : in out Mat));

   --  Read-only caller-owned zero-copy views; aliased constant Data is valid.
   --  Geometry/capacity match the corresponding writable overloads above.
   --  Mode-in Image forbids normal Ada mutation (not OS page protection).
   --  Shallow escape is rejected; Clone owns pixels; module input is allowed.
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
end OpenCV.Core.UInt16_Mat_View;
