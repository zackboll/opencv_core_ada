package OpenCV.Core.Float32_Mat_View is

   type Buffer_Array is array (Natural range <>) of Float32_Value;

   --  Invokes Process with a temporary writable Mat that aliases Data.
   --  Image (0, 0) is Data (Data'First) and row-major element Image
   --  (Row, Column) is Data (Data'First + Row * Columns + Column).
   --  Data'Length must equal Rows * Columns. The Ada lower bound is
   --  not exposed through the Mat. Image is valid only during Process
   --  and must not be retained. Ordinary shallow copies and views are
   --  rejected because they would share the caller-owned buffer after
   --  Process returns. Clone is the supported way to keep an
   --  independent Mat. Writes through Image immediately modify Data,
   --  and writes through Data immediately affect Image. The temporary
   --  cv::Mat header does not own Data and does not copy it. The aliased
   --  formal passes Data by reference, so Image denotes caller-owned storage.
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Rows    : Positive;
      Columns : Positive;
      Process : not null access procedure (Image : in out Mat));

   --  Invokes Process with a temporary writable packed N-dimensional
   --  CV_32FC1 Mat that aliases Data. Shape'Length must be in 2 .. 32 and
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
   --  Arbitrary N-D strides are not supported.
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : in out Mat));

   --  Invokes Process with a temporary writable Mat that aliases Data using
   --  Row_Stride_Elements complete Float32 elements between logical rows.
   --  Image (Row, Column) is Data (Data'First + Row *
   --  Row_Stride_Elements + Column). Row_Stride_Elements must be at least
   --  Columns, and Data'Length must be at least Rows * Row_Stride_Elements.
   --  Data must own a complete stride for every row, including padding after
   --  the final logical row. Padding and trailing storage are not part of
   --  Image. The lifetime,
   --  aliasing, and escape rules are the same as With_Writable_Mat_View.
   procedure With_Writable_Mat_View
     (Data                : aliased in out Buffer_Array;
      Rows                : Positive;
      Columns             : Positive;
      Row_Stride_Elements : Positive;
      Process             : not null access procedure (Image : in out Mat));

end OpenCV.Core.Float32_Mat_View;
