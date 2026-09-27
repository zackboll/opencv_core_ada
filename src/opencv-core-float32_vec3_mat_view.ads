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
   --  rejected; Clone is the independent escape path. Gapped N-D storage
   --  uses With_Writable_Strided_Mat_View (Shape, Strides).
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

   --  Invokes Process with a temporary writable strided N-dimensional
   --  CV_32FC3 Mat that aliases Data. Shape'Length must be in 2 .. 32 with
   --  positive extents, and Strides supplies exactly one stride per
   --  dimension in the same order; neither array's index bounds matter.
   --  Strides count complete Float32_Vec3 pixels, not scalar channels and
   --  not bytes. The final stride must be 1 and each outer stride must cover
   --  its nested inner block: Strides (I) >= Strides (I + 1) * Shape (I + 1).
   --  Zero-based index (I1, .., In) is Data (Data'First + I1 * S1 + .. +
   --  In * Sn). Data'Length must be at least Shape (first) * Strides
   --  (first) pixels, including padding after the final logical outer
   --  block, which the native header covers. Extra trailing pixels are
   --  allowed and are outside the header; padding is never touched.
   --  Is_Continuous reports the actual layout. No data is copied and the
   --  caller retains ownership. Shallow copies, Slice, Reshape, and output
   --  handles are rejected; Clone is the independent escape path.
   procedure With_Writable_Strided_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Strides : Dimension_Stride_Array;
      Process : not null access procedure (Image : in out Mat));

   --  Read-only zero-copy caller-owned views (one Data entry per vector).
   --  Aliased constant Data is accepted; geometry/capacity are exactly those
   --  of the corresponding writable overloads. Mode-in Image prevents normal
   --  Ada mutation, not OS/page writes. Shallow escape is rejected; Clone
   --  owns independent pixels and Module_Interop input is allowed.
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
end OpenCV.Core.Float32_Vec3_Mat_View;
