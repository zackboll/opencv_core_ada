package OpenCV.Core.Sparse.Float16_Access is
   function Get
     (Image : Sparse_Mat; Indices : Index_Array) return Float16_Value;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : Float16_Value);
   --  Stored nodes only; unspecified order; exact binary16 bits.
   --  Do not structurally mutate Image or aliases during callbacks.
   procedure For_Each_Stored
     (Image   : Sparse_Mat;
      Process :
        not null access procedure
          (Indices : Index_Array; Value : Float16_Value));
end OpenCV.Core.Sparse.Float16_Access;
