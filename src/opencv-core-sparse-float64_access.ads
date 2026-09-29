package OpenCV.Core.Sparse.Float64_Access is
   function Get
     (Image : Sparse_Mat; Indices : Index_Array) return Float64_Value;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : Float64_Value);
end OpenCV.Core.Sparse.Float64_Access;
