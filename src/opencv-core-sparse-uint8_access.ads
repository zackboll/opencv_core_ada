package OpenCV.Core.Sparse.UInt8_Access is
   function Get (Image : Sparse_Mat; Indices : Index_Array) return UInt8_Value;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : UInt8_Value);
end OpenCV.Core.Sparse.UInt8_Access;
