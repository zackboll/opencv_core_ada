with OpenCV.Core.Float16_Vec3;

package OpenCV.Core.Float16_Vec3_Mat_View is

   type Buffer_Array is
     array (Natural range <>) of OpenCV.Core.Float16_Vec3.Vector;

   --  Invokes Process with a temporary writable CV_16FC3 Mat that aliases
   --  Data. Each Data component is one complete pixel. Image (Row, Column)
   --  is Data (Data'First + Row * Columns + Column). Data'Length must equal
   --  Rows * Columns; it counts pixels, not scalar channels. The Ada lower
   --  bound is not exposed through the Mat. Image is valid only during
   --  Process and must not be retained. Ordinary shallow copies and views
   --  are rejected because they would share the caller-owned buffer after
   --  Process returns. Clone is the supported way to keep an independent
   --  Mat. Writes through Image immediately modify Data, and writes through
   --  Data immediately affect Image. The temporary cv::Mat header does not
   --  own or copy Data. Each Vector component is the exact stored IEEE-754
   --  binary16 encoding; signed zeros, subnormals, infinities, and NaN
   --  payloads are not converted. Component 0, 1, and 2 are OpenCV channels
   --  0, 1, and 2; Core does not assign RGB or BGR meaning.
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Rows    : Positive;
      Columns : Positive;
      Process : not null access procedure (Image : in out Mat));

   --  Invokes Process with a temporary writable packed N-dimensional
   --  CV_16FC3 Mat that aliases Data. One Data component is one complete C3
   --  element. Shape'Length must be in 2 .. 32 and every extent must be
   --  positive; Shape iteration order maps directly to OpenCV dimension
   --  order regardless of Shape'First. Data'Length must equal product
   --  (Shape) exactly; it counts pixels, not scalar channels. Storage is
   --  packed and continuous with the final dimension varying fastest:
   --  zero-based index (I1, .., In) is Data (Data'First + ((I1 * D2 + I2) *
   --  D3 + ..) * Dn + In). Neither Ada lower bound is exposed through the
   --  Mat. Shape => (Rows, Columns) has the same geometry as the
   --  Rows/Columns overload. Each component is the exact stored IEEE-754
   --  binary16 encoding; nothing is converted. No data is copied and the
   --  caller retains ownership. Callback lifetime and escape rules are
   --  identical to the Rows/Columns overload: shallow copies, Slice, and
   --  Reshape are rejected; Clone is the independent escape path. Arbitrary
   --  N-D strides are not supported.
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : in out Mat));

   --  Invokes Process with a temporary writable CV_16FC3 Mat that aliases
   --  Data with Row_Stride complete C3 pixels between logical row starts.
   --  Row_Stride must be at least Columns. Image (Row, Column) maps to
   --  Data (Data'First + Row * Row_Stride + Column). Data'Length must be at
   --  least Rows * Row_Stride, including padding after the final logical row.
   --  Padding and extra trailing storage are outside the logical Mat.
   --  No data is copied. Ownership, callback lifetime, and escape
   --  rules are identical to With_Writable_Mat_View; Clone is the safe
   --  escape path. Each Vector component is the exact stored IEEE-754
   --  binary16 encoding.
   procedure With_Writable_Strided_Mat_View
     (Data       : aliased in out Buffer_Array;
      Rows       : Positive;
      Columns    : Positive;
      Row_Stride : Positive;
      Process    : not null access procedure (Image : in out Mat));

end OpenCV.Core.Float16_Vec3_Mat_View;
