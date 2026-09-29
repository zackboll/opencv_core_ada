package OpenCV.Core.Sparse.UInt16_Access is
   function Get
     (Image : Sparse_Mat; Indices : Index_Array) return UInt16_Value;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : UInt16_Value);
end OpenCV.Core.Sparse.UInt16_Access;
