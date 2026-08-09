package OpenCV.Core.UInt8_Access is

   function Get (Image : Mat; Row, Column : Integer) return UInt8_Value;

   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : UInt8_Value);

end OpenCV.Core.UInt8_Access;
