package OpenCV.Core.Float64_Access is

   type Float64_Classification is
     (Finite, Positive_Infinity, Negative_Infinity, Not_A_Number);

   function Get (Image : Mat; Row, Column : Integer) return Float64_Value;

   --  Classifies the stored Float64 value without converting non-finite IEEE
   --  values into the public Float64_Value subtype.
   function Classify
     (Image : Mat; Row, Column : Integer) return Float64_Classification;

   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : Float64_Value);

   --  Zero-based N-dimensional access. Indices'Length must equal
   --  Image.Dimension_Count. Iteration order maps to OpenCV dimensions
   --  regardless of the array's index bounds.
   function Get (Image : Mat; Indices : Index_Array) return Float64_Value;

   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : Float64_Value);

end OpenCV.Core.Float64_Access;
