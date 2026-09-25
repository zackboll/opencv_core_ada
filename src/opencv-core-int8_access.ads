package OpenCV.Core.Int8_Access is

   function Get (Image : Mat; Row, Column : Integer) return Int8_Value;

   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : Int8_Value);

   --  Zero-based N-dimensional access. Indices'Length must equal
   --  Image.Dimension_Count. Iteration order maps to OpenCV dimensions
   --  regardless of the array's index bounds.
   function Get (Image : Mat; Indices : Index_Array) return Int8_Value;

   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : Int8_Value);

end OpenCV.Core.Int8_Access;
