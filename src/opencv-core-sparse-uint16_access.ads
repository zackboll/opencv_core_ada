package OpenCV.Core.Sparse.UInt16_Access is
   function Get
     (Image : Sparse_Mat; Indices : Index_Array) return UInt16_Value;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : UInt16_Value);
   --  Stored nodes only; order unspecified. No structural mutation through
   --  Image or shallow aliases while the callback is active.
   procedure For_Each_Stored
     (Image   : Sparse_Mat;
      Process :
        not null access procedure
          (Indices : Index_Array; Value : UInt16_Value));
end OpenCV.Core.Sparse.UInt16_Access;
