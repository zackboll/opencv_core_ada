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

end OpenCV.Core.Float32_Access;
