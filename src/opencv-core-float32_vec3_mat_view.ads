with OpenCV.Core.Float32_Vec3;

package OpenCV.Core.Float32_Vec3_Mat_View is

   type Buffer_Array is
     array (Natural range <>) of OpenCV.Core.Float32_Vec3.Vector;

   --  Invokes Process with a temporary writable CV_32FC3 Mat that aliases
   --  Data.  Each Data component is one complete pixel.  Image (Row, Column)
   --  is Data (Data'First + Row * Columns + Column).  Data'Length must equal
   --  Rows * Columns; it counts pixels, not scalar channels.  Image is valid
   --  only during Process and must not be retained.  Clone is the supported
   --  way to keep an independent Mat.  The aliased formal passes Data by
   --  reference, so Image denotes caller-owned storage without copying it.
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Rows    : Positive;
      Columns : Positive;
      Process : not null access procedure (Image : in out Mat));

   --  Invokes Process with a temporary writable packed N-dimensional
   --  CV_32FC3 Mat that aliases Data. One Data component is one complete C3
   --  element. Shape'Length must be in 2 .. 32 and every extent must be
   --  positive; Shape iteration order maps directly to OpenCV dimension
   --  order regardless of Shape'First. Data'Length must equal product
   --  (Shape) exactly; it counts pixels, not scalar channels. Storage is
   --  packed and continuous with the final dimension varying fastest:
   --  zero-based index (I1, .., In) is Data (Data'First + ((I1 * D2 + I2) *
   --  D3 + ..) * Dn + In). Neither Ada lower bound is exposed through the
   --  Mat. Shape => (Rows, Columns) has the same geometry as the
   --  Rows/Columns overload. No data is copied and the caller retains
   --  ownership. Callback lifetime and escape rules are identical to the
   --  Rows/Columns overload: shallow copies, Slice, and Reshape are
   --  rejected; Clone is the independent escape path. Arbitrary N-D strides
   --  are not supported.
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : in out Mat));

   --  Invokes Process with a temporary writable CV_32FC3 Mat that aliases
   --  Data with Row_Stride complete Float32_Vec3 pixels between logical row
   --  starts. Row_Stride counts pixels, not scalar channels and not bytes.
   --  Row_Stride must be at least Columns. Image (Row, Column) maps to
   --  Data (Data'First + Row * Row_Stride + Column). Data'Length must be at
   --  least Rows * Row_Stride, including padding pixels after the final
   --  logical row. Padding and extra trailing pixels are outside the logical
   --  Mat. No data is copied. Ownership, callback lifetime, and escape rules
   --  are identical to With_Writable_Mat_View; Clone is the safe escape path.
   procedure With_Writable_Strided_Mat_View
     (Data       : aliased in out Buffer_Array;
      Rows       : Positive;
      Columns    : Positive;
      Row_Stride : Positive;
      Process    : not null access procedure (Image : in out Mat));

end OpenCV.Core.Float32_Vec3_Mat_View;
