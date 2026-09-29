package OpenCV.Core.Sparse.Int16_Access is
   function Get (Image : Sparse_Mat; Indices : Index_Array) return Int16_Value;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : Int16_Value);
end OpenCV.Core.Sparse.Int16_Access;
