with OpenCV.Internal.C_API;

private generic
   type Value_Type is private;
   type ABI_Type is private;
   Expected_Depth : Depth_Type;
   with function From_ABI (Value : ABI_Type) return Value_Type;
   with
     function Raw_Next
       (Self    : OpenCV.Internal.C_API.Sparse_Iterator_Handle;
        Dims    : OpenCV.Internal.C_API.C_Int32;
        Indices : access OpenCV.Internal.C_API.C_Int32;
        Value   : access ABI_Type;
        Found   : access OpenCV.Internal.C_API.C_UInt8)
        return OpenCV.Internal.C_API.Status;
package OpenCV.Core.Sparse.Typed_Iteration_Impl is
   procedure For_Each_Stored
     (Image   : Sparse_Mat;
      Process :
        not null access procedure (Indices : Index_Array; Value : Value_Type));
end OpenCV.Core.Sparse.Typed_Iteration_Impl;
