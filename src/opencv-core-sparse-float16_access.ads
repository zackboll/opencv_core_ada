package OpenCV.Core.Sparse.Float16_Access is
   function Get
     (Image : Sparse_Mat; Indices : Index_Array) return Float16_Value;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : Float16_Value);
end OpenCV.Core.Sparse.Float16_Access;
