package OpenCV.Core.Sparse.Int8_Access is
   function Get (Image : Sparse_Mat; Indices : Index_Array) return Int8_Value;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : Int8_Value);
end OpenCV.Core.Sparse.Int8_Access;
