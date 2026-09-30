with OpenCV.Core.Sparse.Typed_Vector_Impl;
with OpenCV.Core.Sparse.Typed_Vector_Iteration_Impl;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Sparse.Float64_Vec2_Access is
   package C renames OpenCV.Internal.C_API;
   subtype Vector is OpenCV.Core.Float64_Vec2.Vector;

   function To_ABI (V : Vector) return C.Float64_Vec2
   is (Component_0 => C.C_Float64 (V (0)),
       Component_1 => C.C_Float64 (V (1)));
   function From_ABI (V : C.Float64_Vec2) return Vector
   is (0 => Float64_Value (V.Component_0),
       1 => Float64_Value (V.Component_1));
   Zero : constant C.Float64_Vec2 := (others => 0.0);

   package Impl is new
     Typed_Vector_Impl
       (Vector,
        C.Float64_Vec2,
        Float64,
        2,
        Zero,
        To_ABI,
        From_ABI,
        C.Sparse_Get_Float64_Vec2,
        C.Sparse_Set_Float64_Vec2);
   package Iteration is new
     Typed_Vector_Iteration_Impl
       (Vector,
        C.Float64_Vec2,
        Float64,
        2,
        Zero,
        From_ABI,
        C.Sparse_Iterator_Next_Float64_Vec2);

   function Get
     (Image : Sparse_Mat; Indices : Index_Array)
      return OpenCV.Core.Float64_Vec2.Vector
   renames Impl.Get;
   procedure Set
     (Image   : in out Sparse_Mat;
      Indices : Index_Array;
      Value   : OpenCV.Core.Float64_Vec2.Vector)
   renames Impl.Set;
   procedure For_Each_Stored
     (Image   : Sparse_Mat;
      Process :
        not null access procedure
          (Indices : Index_Array; Value : OpenCV.Core.Float64_Vec2.Vector))
   renames Iteration.For_Each_Stored;
end OpenCV.Core.Sparse.Float64_Vec2_Access;
