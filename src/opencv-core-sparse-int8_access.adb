with OpenCV.Core.Sparse.Typed_Impl;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Sparse.Int8_Access is
   function To_ABI (V : Int8_Value) return OpenCV.Internal.C_API.C_Int8
   is (OpenCV.Internal.C_API.C_Int8 (V));
   function From_ABI (V : OpenCV.Internal.C_API.C_Int8) return Int8_Value
   is (Int8_Value (V));
   package Impl is new
     Typed_Impl
       (Int8_Value,
        OpenCV.Internal.C_API.C_Int8,
        Int8,
        To_ABI,
        From_ABI,
        OpenCV.Internal.C_API.Sparse_Get_Int8,
        OpenCV.Internal.C_API.Sparse_Set_Int8);
   function Get (Image : Sparse_Mat; Indices : Index_Array) return Int8_Value
   renames Impl.Get;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : Int8_Value)
   renames Impl.Set;
end OpenCV.Core.Sparse.Int8_Access;
