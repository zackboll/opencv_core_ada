with OpenCV.Core.Sparse.Typed_Impl;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Sparse.Float32_Access is
   function To_ABI (V : Float32_Value) return OpenCV.Internal.C_API.C_Float32
   is (OpenCV.Internal.C_API.C_Float32 (V));
   function From_ABI (V : OpenCV.Internal.C_API.C_Float32) return Float32_Value
   is (Float32_Value (V));
   package Impl is new
     Typed_Impl
       (Float32_Value,
        OpenCV.Internal.C_API.C_Float32,
        Float32,
        To_ABI,
        From_ABI,
        OpenCV.Internal.C_API.Sparse_Get_Float32,
        OpenCV.Internal.C_API.Sparse_Set_Float32);
   function Get
     (Image : Sparse_Mat; Indices : Index_Array) return Float32_Value
   renames Impl.Get;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : Float32_Value)
   renames Impl.Set;
end OpenCV.Core.Sparse.Float32_Access;
