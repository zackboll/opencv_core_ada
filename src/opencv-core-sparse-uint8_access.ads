package OpenCV.Core.Sparse.UInt8_Access is
   function Get (Image : Sparse_Mat; Indices : Index_Array) return UInt8_Value;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : UInt8_Value);
   --  Stored nodes only, in unspecified order. Indices are zero-based
   --  with bounds 1 .. Dimension_Count. Do not structurally mutate Image or a
   --  shallow alias during the callback. No native iterator escapes this call.
   procedure For_Each_Stored
     (Image   : Sparse_Mat;
      Process :
        not null access procedure
          (Indices : Index_Array; Value : UInt8_Value));
end OpenCV.Core.Sparse.UInt8_Access;
