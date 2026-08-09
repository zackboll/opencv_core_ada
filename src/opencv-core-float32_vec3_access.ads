with OpenCV.Core.Float32_Vec3;

package OpenCV.Core.Float32_Vec3_Access is

   function Get
     (Image : Mat; Row, Column : Integer)
      return OpenCV.Core.Float32_Vec3.Vector;

   procedure Set
     (Image  : in out Mat;
      Row    : Integer;
      Column : Integer;
      Value  : OpenCV.Core.Float32_Vec3.Vector);

end OpenCV.Core.Float32_Vec3_Access;
