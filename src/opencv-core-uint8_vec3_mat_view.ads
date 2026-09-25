with OpenCV.Core.UInt8_Vec3;

package OpenCV.Core.UInt8_Vec3_Mat_View is

   type Buffer_Array is
     array (Natural range <>) of OpenCV.Core.UInt8_Vec3.Vector;

   --  Invokes Process with a temporary writable CV_8UC3 Mat that aliases
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

   --  Invokes Process with a temporary writable CV_8UC3 Mat that aliases
   --  Data with Row_Stride complete UInt8_Vec3 pixels between logical row
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

end OpenCV.Core.UInt8_Vec3_Mat_View;
