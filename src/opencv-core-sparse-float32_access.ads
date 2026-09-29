package OpenCV.Core.Sparse.Float32_Access is
   function Get
     (Image : Sparse_Mat; Indices : Index_Array) return Float32_Value;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : Float32_Value);
end OpenCV.Core.Sparse.Float32_Access;
