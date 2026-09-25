with OpenCV.Core.Float16_Vec3;

package OpenCV.Core.Float16_Vec3_Access is

   function Get
     (Image : Mat; Row, Column : Integer)
      return OpenCV.Core.Float16_Vec3.Vector;

   procedure Set
     (Image  : in out Mat;
      Row    : Integer;
      Column : Integer;
      Value  : OpenCV.Core.Float16_Vec3.Vector);

   --  Zero-based N-dimensional access. Indices'Length must equal
   --  Image.Dimension_Count. Iteration order maps to OpenCV dimensions
   --  regardless of the array's index bounds. One vector is one complete
   --  three-channel element. Component encodings stay exact binary16 bits.
   function Get
     (Image : Mat; Indices : Index_Array)
      return OpenCV.Core.Float16_Vec3.Vector;

   procedure Set
     (Image   : in out Mat;
      Indices : Index_Array;
      Value   : OpenCV.Core.Float16_Vec3.Vector);

end OpenCV.Core.Float16_Vec3_Access;
