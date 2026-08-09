with OpenCV.Core.Float32_Vec3;
with OpenCV.Core.UInt8_Vec3;

package OpenCV.Core.Internal.Typed_Access is

   function Get_UInt8 (Image : Mat; Row, Column : Integer) return UInt8_Value;

   procedure Set_UInt8
     (Image : in out Mat; Row, Column : Integer; Value : UInt8_Value);

   function Get_Float32
     (Image : Mat; Row, Column : Integer) return Float32_Value;

   procedure Set_Float32
     (Image : in out Mat; Row, Column : Integer; Value : Float32_Value);

   function Get_UInt8_Vec3
     (Image : Mat; Row, Column : Integer) return OpenCV.Core.UInt8_Vec3.Vector;

   procedure Set_UInt8_Vec3
     (Image  : in out Mat;
      Row    : Integer;
      Column : Integer;
      Value  : OpenCV.Core.UInt8_Vec3.Vector);

   function Get_Float32_Vec3
     (Image : Mat; Row, Column : Integer)
      return OpenCV.Core.Float32_Vec3.Vector;

   procedure Set_Float32_Vec3
     (Image  : in out Mat;
      Row    : Integer;
      Column : Integer;
      Value  : OpenCV.Core.Float32_Vec3.Vector);

end OpenCV.Core.Internal.Typed_Access;
