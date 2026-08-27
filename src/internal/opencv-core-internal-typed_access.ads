with OpenCV.Core.Float32_Vec3;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Internal.C_API;

package OpenCV.Core.Internal.Typed_Access is

   function Get_UInt8 (Image : Mat; Row, Column : Integer) return UInt8_Value;

   procedure Set_UInt8
     (Image : in out Mat; Row, Column : Integer; Value : UInt8_Value);
   function Get_UInt8 (Image : Mat; Indices : Index_Array) return UInt8_Value;

   procedure Set_UInt8
     (Image : in out Mat; Indices : Index_Array; Value : UInt8_Value);

   function Get_Float32
     (Image : Mat; Indices : Index_Array) return Float32_Value;

   procedure Set_Float32
     (Image : in out Mat; Indices : Index_Array; Value : Float32_Value);

   function Get_Float32
     (Image : Mat; Row, Column : Integer) return Float32_Value;

   procedure Set_Float32
     (Image : in out Mat; Row, Column : Integer; Value : Float32_Value);

   type UInt8_Row_Buffer is
     array (Natural range <>) of OpenCV.Internal.C_API.C_UInt8
   with Convention => C;

   type Float32_Row_Buffer is
     array (Natural range <>) of OpenCV.Internal.C_API.C_Float32
   with Convention => C;

   procedure Read_UInt8_Row
     (Image : Mat; Row : Integer; Data : out UInt8_Row_Buffer);

   procedure Write_UInt8_Row
     (Image : in out Mat; Row : Integer; Data : UInt8_Row_Buffer);

   procedure Read_Float32_Row
     (Image : Mat; Row : Integer; Data : out Float32_Row_Buffer);

   procedure Write_Float32_Row
     (Image : in out Mat; Row : Integer; Data : Float32_Row_Buffer);

   procedure Read_UInt8_Vec3_Row
     (Image : Mat; Row : Integer; Data : out UInt8_Row_Buffer);

   procedure Write_UInt8_Vec3_Row
     (Image : in out Mat; Row : Integer; Data : UInt8_Row_Buffer);

   procedure Read_Float32_Vec3_Row
     (Image : Mat; Row : Integer; Data : out Float32_Row_Buffer);

   procedure Write_Float32_Vec3_Row
     (Image : in out Mat; Row : Integer; Data : Float32_Row_Buffer);

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
