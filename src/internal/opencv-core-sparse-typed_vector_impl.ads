with OpenCV.Internal.C_API;

--  Shared Get/Set implementation for one complete C2/C3/C4 SparseMat element.
--  Public vector values are converted component-by-component to the existing
--  dense vector C ABI record before crossing the shim boundary.
private generic
   type Value_Type is private;
   type ABI_Type is private;
   Expected_Depth : Depth_Type;
   Expected_Channels : Channel_Count;
   Zero_ABI : ABI_Type;
   with function To_ABI (Value : Value_Type) return ABI_Type;
   with function From_ABI (Value : ABI_Type) return Value_Type;
   with
     function Raw_Get
       (Self    : OpenCV.Internal.C_API.Sparse_Mat_Handle;
        Dims    : OpenCV.Internal.C_API.C_Int32;
        Indices : access OpenCV.Internal.C_API.C_Int32;
        Value   : access ABI_Type) return OpenCV.Internal.C_API.Status;
   with
     function Raw_Set
       (Self    : OpenCV.Internal.C_API.Sparse_Mat_Handle;
        Dims    : OpenCV.Internal.C_API.C_Int32;
        Indices : access OpenCV.Internal.C_API.C_Int32;
        Value   : access constant ABI_Type)
        return OpenCV.Internal.C_API.Status;
package OpenCV.Core.Sparse.Typed_Vector_Impl is
   function Get (Image : Sparse_Mat; Indices : Index_Array) return Value_Type;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : Value_Type);
end OpenCV.Core.Sparse.Typed_Vector_Impl;
