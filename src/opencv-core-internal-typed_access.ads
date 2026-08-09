package OpenCV.Core.Internal.Typed_Access is

   function Get_UInt8 (Image : Mat; Row, Column : Integer) return UInt8_Value;

   procedure Set_UInt8
     (Image : in out Mat; Row, Column : Integer; Value : UInt8_Value);

   function Get_Float32
     (Image : Mat; Row, Column : Integer) return Float32_Value;

   procedure Set_Float32
     (Image : in out Mat; Row, Column : Integer; Value : Float32_Value);

end OpenCV.Core.Internal.Typed_Access;
