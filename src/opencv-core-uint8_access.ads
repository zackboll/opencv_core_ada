package OpenCV.Core.UInt8_Access is

   function Get (Image : Mat; Row, Column : Integer) return UInt8_Value;

   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : UInt8_Value);

   --  Zero-based N-dimensional access. Indices'Length must equal
   --  Image.Dimension_Count. Iteration order maps to OpenCV dimensions
   --  regardless of the array's index bounds.
   function Get (Image : Mat; Indices : Index_Array) return UInt8_Value;

   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : UInt8_Value);

end OpenCV.Core.UInt8_Access;
