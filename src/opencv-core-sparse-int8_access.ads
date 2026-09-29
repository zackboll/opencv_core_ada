package OpenCV.Core.Sparse.Int8_Access is
   function Get (Image : Sparse_Mat; Indices : Index_Array) return Int8_Value;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : Int8_Value);
   --  Stored nodes only; order unspecified. No structural mutation through
   --  Image or shallow aliases while the callback is active.
   procedure For_Each_Stored
     (Image   : Sparse_Mat;
      Process :
        not null access procedure (Indices : Index_Array; Value : Int8_Value));
end OpenCV.Core.Sparse.Int8_Access;
