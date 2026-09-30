package body OpenCV.Core.Sparse.Typed_Vector_Impl is
   package C renames OpenCV.Internal.C_API;

   function Get (Image : Sparse_Mat; Indices : Index_Array) return Value_Type
   is
      Coordinates : C.C_Int32_Array := C_Indices (Indices);
      Result      : aliased ABI_Type := Zero_ABI;
   begin
      Check_Layout (Image, Indices, Expected_Depth, Expected_Channels);
      Check
        (Raw_Get
           (Image.Handle,
            C.C_Int32 (Coordinates'Length),
            Coordinates (0)'Access,
            Result'Access),
         "sparse vector read");
      return From_ABI (Result);
   end Get;

   procedure Set
     (Image : in out Sparse_Mat; Indices : Index_Array; Value : Value_Type)
   is
      Coordinates : C.C_Int32_Array := C_Indices (Indices);
      C_Value     : aliased constant ABI_Type := To_ABI (Value);
   begin
      Check_Layout (Image, Indices, Expected_Depth, Expected_Channels);
      Check
        (Raw_Set
           (Image.Handle,
            C.C_Int32 (Coordinates'Length),
            Coordinates (0)'Access,
            C_Value'Access),
         "sparse vector write");
   end Set;
end OpenCV.Core.Sparse.Typed_Vector_Impl;
