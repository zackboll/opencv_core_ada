with Ada.Finalization;

package body OpenCV.Core.Sparse.Typed_Vector_Iteration_Impl is
   package C renames OpenCV.Internal.C_API;
   use type C.C_UInt8;

   type Iterator_Guard is new Ada.Finalization.Limited_Controlled with record
      Handle : aliased C.Sparse_Iterator_Handle :=
        C.Null_Sparse_Iterator_Handle;
   end record;
   overriding
   procedure Finalize (Self : in out Iterator_Guard) is
   begin
      C.Sparse_Iterator_Destroy (Self.Handle);
      Self.Handle := C.Null_Sparse_Iterator_Handle;
   end Finalize;

   procedure For_Each_Stored
     (Image   : Sparse_Mat;
      Process :
        not null access procedure (Indices : Index_Array; Value : Value_Type))
   is
   begin
      Check_Layout (Image, Expected_Depth, Expected_Channels);
      declare
         Count       : constant Positive := Image.Dimension_Count;
         Guard       : Iterator_Guard;
         Coordinates : C.C_Int32_Array (0 .. Count - 1) := (others => 0);
         Item        : aliased ABI_Type := Zero_ABI;
         Found       : aliased C.C_UInt8 := 0;
      begin
         Check
           (C.Sparse_Iterator_Create (Image.Handle, Guard.Handle'Access),
            "sparse iterator creation");
         loop
            Check
              (Raw_Next
                 (Guard.Handle,
                  C.C_Int32 (Count),
                  Coordinates (0)'Access,
                  Item'Access,
                  Found'Access),
               "sparse vector iterator next");
            exit when Found = 0;
            declare
               Indices : Index_Array (1 .. Count);
            begin
               for Axis in Indices'Range loop
                  Indices (Axis) := Size_Coordinate (Coordinates (Axis - 1));
               end loop;
               Process (Indices, From_ABI (Item));
            end;
         end loop;
      end;
   end For_Each_Stored;
end OpenCV.Core.Sparse.Typed_Vector_Iteration_Impl;
