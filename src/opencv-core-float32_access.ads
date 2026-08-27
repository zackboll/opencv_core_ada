package OpenCV.Core.Float32_Access is

   type Float32_Classification is
     (Finite, Positive_Infinity, Negative_Infinity, Not_A_Number);

   function Get (Image : Mat; Row, Column : Integer) return Float32_Value;

   --  Classifies the stored Float32 value without converting non-finite IEEE
   --  values into the public Float32_Value subtype.
   function Classify
     (Image : Mat; Row, Column : Integer) return Float32_Classification;

   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : Float32_Value);

   --  Zero-based N-dimensional access. Indices'Length must equal
   --  Image.Dimension_Count. Iteration order maps to OpenCV dimensions
   --  regardless of the array's index bounds.
   function Get (Image : Mat; Indices : Index_Array) return Float32_Value;

   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : Float32_Value);

end OpenCV.Core.Float32_Access;
