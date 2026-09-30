with OpenCV.Internal.C_API;

--  Read-only stored-node traversal for one complete C2/C3/C4 SparseMat
--  element. Reuses the controlled iterator lifetime of the C1 traversal.
private generic
   type Value_Type is private;
   type ABI_Type is private;
   Expected_Depth : Depth_Type;
   Expected_Channels : Channel_Count;
   Zero_ABI : ABI_Type;
   with function From_ABI (Value : ABI_Type) return Value_Type;
   with
     function Raw_Next
       (Self    : OpenCV.Internal.C_API.Sparse_Iterator_Handle;
        Dims    : OpenCV.Internal.C_API.C_Int32;
        Indices : access OpenCV.Internal.C_API.C_Int32;
        Value   : access ABI_Type;
        Found   : access OpenCV.Internal.C_API.C_UInt8)
        return OpenCV.Internal.C_API.Status;
package OpenCV.Core.Sparse.Typed_Vector_Iteration_Impl is
   procedure For_Each_Stored
     (Image   : Sparse_Mat;
      Process :
        not null access procedure (Indices : Index_Array; Value : Value_Type));
end OpenCV.Core.Sparse.Typed_Vector_Iteration_Impl;
