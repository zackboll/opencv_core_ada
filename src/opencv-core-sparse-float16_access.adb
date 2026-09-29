with OpenCV.Core.Sparse.Typed_Impl;
with OpenCV.Core.Sparse.Typed_Iteration_Impl;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Sparse.Float16_Access is
   function To_ABI (V : Float16_Value) return OpenCV.Internal.C_API.C_UInt16
   is (OpenCV.Internal.C_API.C_UInt16 (Float16_Bits (V)));
   function From_ABI (V : OpenCV.Internal.C_API.C_UInt16) return Float16_Value
   is (Float16_From_Bits (V));
   package Impl is new
     Typed_Impl
       (Float16_Value,
        OpenCV.Internal.C_API.C_UInt16,
        Float16,
        To_ABI,
        From_ABI,
        OpenCV.Internal.C_API.Sparse_Get_Float16,
        OpenCV.Internal.C_API.Sparse_Set_Float16);
   function Get
     (Image : Sparse_Mat; Indices : Index_Array) return Float16_Value
   renames Impl.Get;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : Float16_Value)
   renames Impl.Set;
   package Iteration is new
     Typed_Iteration_Impl
       (Float16_Value,
        OpenCV.Internal.C_API.C_UInt16,
        Float16,
        From_ABI,
        OpenCV.Internal.C_API.Sparse_Iterator_Next_Float16);
   procedure For_Each_Stored
     (Image   : Sparse_Mat;
      Process :
        not null access procedure
          (Indices : Index_Array; Value : Float16_Value))
   renames Iteration.For_Each_Stored;
end OpenCV.Core.Sparse.Float16_Access;
