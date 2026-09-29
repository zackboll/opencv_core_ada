with OpenCV.Core.Sparse.Typed_Impl;
with OpenCV.Core.Sparse.Typed_Iteration_Impl;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Sparse.Float64_Access is
   function To_ABI (V : Float64_Value) return OpenCV.Internal.C_API.C_Float64
   is (OpenCV.Internal.C_API.C_Float64 (V));
   function From_ABI (V : OpenCV.Internal.C_API.C_Float64) return Float64_Value
   is (Float64_Value (V));
   package Impl is new
     Typed_Impl
       (Float64_Value,
        OpenCV.Internal.C_API.C_Float64,
        Float64,
        To_ABI,
        From_ABI,
        OpenCV.Internal.C_API.Sparse_Get_Float64,
        OpenCV.Internal.C_API.Sparse_Set_Float64);
   function Get
     (Image : Sparse_Mat; Indices : Index_Array) return Float64_Value
   renames Impl.Get;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : Float64_Value)
   renames Impl.Set;
   package Iteration is new
     Typed_Iteration_Impl
       (Float64_Value,
        OpenCV.Internal.C_API.C_Float64,
        Float64,
        From_ABI,
        OpenCV.Internal.C_API.Sparse_Iterator_Next_Float64);
   procedure For_Each_Stored
     (Image   : Sparse_Mat;
      Process :
        not null access procedure
          (Indices : Index_Array; Value : Float64_Value))
   renames Iteration.For_Each_Stored;
end OpenCV.Core.Sparse.Float64_Access;
