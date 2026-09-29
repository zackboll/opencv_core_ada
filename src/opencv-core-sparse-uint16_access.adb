with OpenCV.Core.Sparse.Typed_Impl;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Sparse.UInt16_Access is
   function To_ABI (V : UInt16_Value) return OpenCV.Internal.C_API.C_UInt16
   is (OpenCV.Internal.C_API.C_UInt16 (V));
   function From_ABI (V : OpenCV.Internal.C_API.C_UInt16) return UInt16_Value
   is (UInt16_Value (V));
   package Impl is new
     Typed_Impl
       (UInt16_Value,
        OpenCV.Internal.C_API.C_UInt16,
        UInt16,
        To_ABI,
        From_ABI,
        OpenCV.Internal.C_API.Sparse_Get_UInt16,
        OpenCV.Internal.C_API.Sparse_Set_UInt16);
   function Get (Image : Sparse_Mat; Indices : Index_Array) return UInt16_Value
   renames Impl.Get;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : UInt16_Value)
   renames Impl.Set;
end OpenCV.Core.Sparse.UInt16_Access;
