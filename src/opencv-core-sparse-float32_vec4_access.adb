with OpenCV.Core.Sparse.Typed_Vector_Impl;
with OpenCV.Core.Sparse.Typed_Vector_Iteration_Impl;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Sparse.Float32_Vec4_Access is
   package C renames OpenCV.Internal.C_API;
   subtype Vector is OpenCV.Core.Float32_Vec4.Vector;

   function To_ABI (V : Vector) return C.Float32_Vec4
   is (Component_0 => C.C_Float32 (V (0)),
       Component_1 => C.C_Float32 (V (1)),
       Component_2 => C.C_Float32 (V (2)),
       Component_3 => C.C_Float32 (V (3)));
   function From_ABI (V : C.Float32_Vec4) return Vector
   is (0 => Float32_Value (V.Component_0),
       1 => Float32_Value (V.Component_1),
       2 => Float32_Value (V.Component_2),
       3 => Float32_Value (V.Component_3));
   Zero : constant C.Float32_Vec4 := (others => 0.0);

   package Impl is new
     Typed_Vector_Impl
       (Vector,
        C.Float32_Vec4,
        Float32,
        4,
        Zero,
        To_ABI,
        From_ABI,
        C.Sparse_Get_Float32_Vec4,
        C.Sparse_Set_Float32_Vec4);
   package Iteration is new
     Typed_Vector_Iteration_Impl
       (Vector,
        C.Float32_Vec4,
        Float32,
        4,
        Zero,
        From_ABI,
        C.Sparse_Iterator_Next_Float32_Vec4);

   function Get
     (Image : Sparse_Mat; Indices : Index_Array)
      return OpenCV.Core.Float32_Vec4.Vector
   renames Impl.Get;
   procedure Set
     (Image   : in out Sparse_Mat;
      Indices : Index_Array;
      Value   : OpenCV.Core.Float32_Vec4.Vector)
   renames Impl.Set;
   procedure For_Each_Stored
     (Image   : Sparse_Mat;
      Process :
        not null access procedure
          (Indices : Index_Array; Value : OpenCV.Core.Float32_Vec4.Vector))
   renames Iteration.For_Each_Stored;
end OpenCV.Core.Sparse.Float32_Vec4_Access;
