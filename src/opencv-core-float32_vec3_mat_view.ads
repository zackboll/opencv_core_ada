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

end OpenCV.Core.Float32_Vec3_Mat_View;
