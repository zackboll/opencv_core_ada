with OpenCV.Core.Sparse.Typed_Impl;
with OpenCV.Core.Sparse.Typed_Iteration_Impl;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Sparse.Int32_Access is
   function To_ABI (V : Int32_Value) return OpenCV.Internal.C_API.C_Int32
   is (OpenCV.Internal.C_API.C_Int32 (V));
   function From_ABI (V : OpenCV.Internal.C_API.C_Int32) return Int32_Value
   is (Int32_Value (V));
   package Impl is new
     Typed_Impl
       (Int32_Value,
        OpenCV.Internal.C_API.C_Int32,
        Int32,
        To_ABI,
        From_ABI,
        OpenCV.Internal.C_API.Sparse_Get_Int32,
        OpenCV.Internal.C_API.Sparse_Set_Int32);
   function Get (Image : Sparse_Mat; Indices : Index_Array) return Int32_Value
   renames Impl.Get;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : Int32_Value)
   renames Impl.Set;
   package Iteration is new
     Typed_Iteration_Impl
       (Int32_Value,
        OpenCV.Internal.C_API.C_Int32,
        Int32,
        From_ABI,
        OpenCV.Internal.C_API.Sparse_Iterator_Next_Int32);
   procedure For_Each_Stored
     (Image   : Sparse_Mat;
      Process :
        not null access procedure (Indices : Index_Array; Value : Int32_Value))
   renames Iteration.For_Each_Stored;
end OpenCV.Core.Sparse.Int32_Access;
