package OpenCV.Core.Float32_Access is

   function Get (Image : Mat; Row, Column : Integer) return Float32_Value;

   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : Float32_Value);

end OpenCV.Core.Float32_Access;
