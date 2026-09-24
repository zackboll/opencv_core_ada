with OpenCV.Core.Float16_Vec3;
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

   function Get_UInt16
     (Image : Mat; Row, Column : Integer) return UInt16_Value;

   procedure Set_UInt16
     (Image : in out Mat; Row, Column : Integer; Value : UInt16_Value);

   function Get_UInt16
     (Image : Mat; Indices : Index_Array) return UInt16_Value;

   procedure Set_UInt16
     (Image : in out Mat; Indices : Index_Array; Value : UInt16_Value);

   function Get_Int16 (Image : Mat; Row, Column : Integer) return Int16_Value;

   procedure Set_Int16
     (Image : in out Mat; Row, Column : Integer; Value : Int16_Value);

   function Get_Int16 (Image : Mat; Indices : Index_Array) return Int16_Value;

   procedure Set_Int16
     (Image : in out Mat; Indices : Index_Array; Value : Int16_Value);

   function Get_Float16
     (Image : Mat; Row, Column : Integer) return Float16_Value;

   procedure Set_Float16
     (Image : in out Mat; Row, Column : Integer; Value : Float16_Value);

   function Get_Float16
     (Image : Mat; Indices : Index_Array) return Float16_Value;

   procedure Set_Float16
     (Image : in out Mat; Indices : Index_Array; Value : Float16_Value);

   function Get_Int32 (Image : Mat; Row, Column : Integer) return Int32_Value;

   procedure Set_Int32
     (Image : in out Mat; Row, Column : Integer; Value : Int32_Value);

   function Get_Int32 (Image : Mat; Indices : Index_Array) return Int32_Value;

   procedure Set_Int32
     (Image : in out Mat; Indices : Index_Array; Value : Int32_Value);

   function Get_Float32
     (Image : Mat; Indices : Index_Array) return Float32_Value;

   procedure Set_Float32
     (Image : in out Mat; Indices : Index_Array; Value : Float32_Value);

   function Get_Float32
     (Image : Mat; Row, Column : Integer) return Float32_Value;

   procedure Set_Float32
     (Image : in out Mat; Row, Column : Integer; Value : Float32_Value);
   function Get_Float64
     (Image : Mat; Indices : Index_Array) return Float64_Value;

   procedure Set_Float64
     (Image : in out Mat; Indices : Index_Array; Value : Float64_Value);

   function Get_Float64
     (Image : Mat; Row, Column : Integer) return Float64_Value;

   procedure Set_Float64
     (Image : in out Mat; Row, Column : Integer; Value : Float64_Value);

   type UInt8_Row_Buffer is
     array (Natural range <>) of OpenCV.Internal.C_API.C_UInt8
   with Convention => C;

   type UInt16_Row_Buffer is
     array (Natural range <>) of OpenCV.Internal.C_API.C_UInt16
   with Convention => C;

   type Int16_Row_Buffer is
     array (Natural range <>) of OpenCV.Internal.C_API.C_Int16
   with Convention => C;

   type Int32_Row_Buffer is
     array (Natural range <>) of OpenCV.Internal.C_API.C_Int32
   with Convention => C;

   type Float32_Row_Buffer is
     array (Natural range <>) of OpenCV.Internal.C_API.C_Float32
   with Convention => C;

   type Float64_Row_Buffer is
     array (Natural range <>) of OpenCV.Internal.C_API.C_Float64
   with Convention => C;

   --  Each element is the stored IEEE binary16 encoding, not an
   --  integer-valued pixel.
   type Float16_Row_Buffer is
     array (Natural range <>) of OpenCV.Internal.C_API.C_UInt16
   with Convention => C;

   procedure Read_UInt8_Row
     (Image : Mat; Row : Integer; Data : out UInt8_Row_Buffer);

   procedure Write_UInt8_Row
     (Image : in out Mat; Row : Integer; Data : UInt8_Row_Buffer);

   procedure Read_Int16_Row
     (Image : Mat; Row : Integer; Data : out Int16_Row_Buffer);

   procedure Write_Int16_Row
     (Image : in out Mat; Row : Integer; Data : Int16_Row_Buffer);

   procedure Read_Int32_Row
     (Image : Mat; Row : Integer; Data : out Int32_Row_Buffer);

   procedure Write_Int32_Row
     (Image : in out Mat; Row : Integer; Data : Int32_Row_Buffer);

   procedure Read_UInt16_Row
     (Image : Mat; Row : Integer; Data : out UInt16_Row_Buffer);

   procedure Write_UInt16_Row
     (Image : in out Mat; Row : Integer; Data : UInt16_Row_Buffer);

   procedure Read_Float32_Row
     (Image : Mat; Row : Integer; Data : out Float32_Row_Buffer);

   procedure Write_Float32_Row
     (Image : in out Mat; Row : Integer; Data : Float32_Row_Buffer);

   procedure Read_Float64_Row
     (Image : Mat; Row : Integer; Data : out Float64_Row_Buffer);

   procedure Write_Float64_Row
     (Image : in out Mat; Row : Integer; Data : Float64_Row_Buffer);

   procedure Read_Float16_Row
     (Image : Mat; Row : Integer; Data : out Float16_Row_Buffer);

   procedure Write_Float16_Row
     (Image : in out Mat; Row : Integer; Data : Float16_Row_Buffer);

   procedure Read_UInt8_Vec3_Row
     (Image : Mat; Row : Integer; Data : out UInt8_Row_Buffer);

   procedure Write_UInt8_Vec3_Row
     (Image : in out Mat; Row : Integer; Data : UInt8_Row_Buffer);

   procedure Read_Float32_Vec3_Row
     (Image : Mat; Row : Integer; Data : out Float32_Row_Buffer);

   procedure Write_Float32_Vec3_Row
     (Image : in out Mat; Row : Integer; Data : Float32_Row_Buffer);

   procedure Read_Float16_Vec3_Row
     (Image : Mat; Row : Integer; Data : out Float16_Row_Buffer);

   procedure Write_Float16_Vec3_Row
     (Image : in out Mat; Row : Integer; Data : Float16_Row_Buffer);

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

   function Get_Float16_Vec3
     (Image : Mat; Row, Column : Integer)
      return OpenCV.Core.Float16_Vec3.Vector;

   procedure Set_Float16_Vec3
     (Image  : in out Mat;
      Row    : Integer;
      Column : Integer;
      Value  : OpenCV.Core.Float16_Vec3.Vector);

end OpenCV.Core.Internal.Typed_Access;
