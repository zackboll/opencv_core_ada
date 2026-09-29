with OpenCV.Core.Sparse.Typed_Impl;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Sparse.UInt8_Access is
   function To_ABI (V : UInt8_Value) return OpenCV.Internal.C_API.C_UInt8
   is (OpenCV.Internal.C_API.C_UInt8 (V));
   function From_ABI (V : OpenCV.Internal.C_API.C_UInt8) return UInt8_Value
   is (UInt8_Value (V));
   package Impl is new
     Typed_Impl
       (UInt8_Value,
        OpenCV.Internal.C_API.C_UInt8,
        UInt8,
        To_ABI,
        From_ABI,
        OpenCV.Internal.C_API.Sparse_Get_UInt8,
        OpenCV.Internal.C_API.Sparse_Set_UInt8);
   function Get (Image : Sparse_Mat; Indices : Index_Array) return UInt8_Value
   renames Impl.Get;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : UInt8_Value)
   renames Impl.Set;
end OpenCV.Core.Sparse.UInt8_Access;
