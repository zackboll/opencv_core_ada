package OpenCV.Core.Float16_Access is

   function Get (Image : Mat; Row, Column : Integer) return Float16_Value;

   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : Float16_Value);

   --  Zero-based N-dimensional access. Indices'Length must equal
   --  Image.Dimension_Count. Iteration order maps to OpenCV dimensions
   --  regardless of the array's index bounds.
   function Get (Image : Mat; Indices : Index_Array) return Float16_Value;

   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : Float16_Value);

end OpenCV.Core.Float16_Access;
