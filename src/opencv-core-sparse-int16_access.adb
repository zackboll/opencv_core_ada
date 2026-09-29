with OpenCV.Core.Sparse.Typed_Impl;
with OpenCV.Core.Sparse.Typed_Iteration_Impl;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Sparse.Int16_Access is
   function To_ABI (V : Int16_Value) return OpenCV.Internal.C_API.C_Int16
   is (OpenCV.Internal.C_API.C_Int16 (V));
   function From_ABI (V : OpenCV.Internal.C_API.C_Int16) return Int16_Value
   is (Int16_Value (V));
   package Impl is new
     Typed_Impl
       (Int16_Value,
        OpenCV.Internal.C_API.C_Int16,
        Int16,
        To_ABI,
        From_ABI,
        OpenCV.Internal.C_API.Sparse_Get_Int16,
        OpenCV.Internal.C_API.Sparse_Set_Int16);
   function Get (Image : Sparse_Mat; Indices : Index_Array) return Int16_Value
   renames Impl.Get;
   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : Int16_Value)
   renames Impl.Set;
   package Iteration is new
     Typed_Iteration_Impl
       (Int16_Value,
        OpenCV.Internal.C_API.C_Int16,
        Int16,
        From_ABI,
        OpenCV.Internal.C_API.Sparse_Iterator_Next_Int16);
   procedure For_Each_Stored
     (Image   : Sparse_Mat;
      Process :
        not null access procedure (Indices : Index_Array; Value : Int16_Value))
   renames Iteration.For_Each_Stored;
end OpenCV.Core.Sparse.Int16_Access;
