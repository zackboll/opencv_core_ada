with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Sparse;
with OpenCV.Core.Sparse.UInt8_Access;
with OpenCV.Core.Sparse.Int8_Access;
with OpenCV.Core.Sparse.UInt16_Access;
with OpenCV.Core.Sparse.Int16_Access;
with OpenCV.Core.Sparse.Int32_Access;
with OpenCV.Core.Sparse.Float16_Access;
with OpenCV.Core.Sparse.Float32_Access;
with OpenCV.Core.Sparse.Float64_Access;
with OpenCV.Core.Float16_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;
with OpenCV.Internal.C_API;

package body Sparse_Tests is
   package C renames OpenCV.Internal.C_API;
   package S renames OpenCV.Core.Sparse;
   package U8 renames S.UInt8_Access;
   use type C.Status;
   use type C.Mat_Handle;
   use type C.Sparse_Mat_Handle;
   use type C.Sparse_Iterator_Handle;
   use type C.C_Int32_Array;
   use type OpenCV.Core.Index_Array;
   use type C.C_UInt8;
   use type C.C_UInt16;
   use type OpenCV.Core.Mat_Size;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Dimension_Array;
   use type OpenCV.Size_Coordinate;
   use type Interfaces.Integer_8;
   use type Interfaces.Integer_16;
   use type Interfaces.Integer_32;
   use type Interfaces.IEEE_Float_32;
   use type Interfaces.IEEE_Float_64;
   use type OpenCV.Core.UInt8_Vec3.Vector;
   use type Interfaces.Unsigned_64;
   use Mat_Test_Support;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   procedure Assert (Condition : Boolean; Message : String) is
   begin
      AUnit.Assertions.Assert (Condition, Message);
   end Assert;

   procedure Metadata_And_Zero (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Empty : S.Sparse_Mat;
      Shape : OpenCV.Core.Dimension_Array (4 .. 6) := (2, 3, 4);
      Image : S.Sparse_Mat :=
        S.Create (Shape, (Depth => OpenCV.Core.UInt8, Channels => 1));
      Index : constant OpenCV.Core.Index_Array := (1, 2, 3);
   begin
      Assert
        (not Empty.Is_Allocated
         and then Empty.Dimension_Count = 0
         and then Empty.Shape'Length = 0
         and then Empty.Stored_Element_Count = 0,
         "default sparse");
      Empty.Clear;
      Assert (not Empty.Clone.Is_Allocated, "empty clone");
      Assert
        (Image.Shape = (2, 3, 4)
         and then Image.Dimension_Count = 3
         and then Image.Depth = OpenCV.Core.UInt8
         and then Image.Channels = 1
         and then Image.Element_Size = 1
         and then Image.Channel_Size = 1,
         "sparse metadata");
      Assert
        (not Image.Contains (Index) and then U8.Get (Image, Index) = 0,
         "absent zero");
      U8.Set (Image, Index, 0);
      Assert
        (Image.Contains (Index)
         and then Image.Stored_Element_Count = 1
         and then U8.Get (Image, Index) = 0,
         "explicit zero node");
      Image.Erase (Index);
      Assert
        (not Image.Contains (Index) and then Image.Stored_Element_Count = 0,
         "erase node");
      Shape (4) := 0;
      begin
         declare
            Invalid : constant S.Sparse_Mat :=
              S.Create (Shape, (Depth => OpenCV.Core.UInt8, Channels => 1));
         begin
            Assert (Invalid.Is_Allocated, "unreachable");
         end;
         Assert (False, "zero extent accepted");
      exception
         when OpenCV.OpenCV_Error =>
            null;
      end;
   end Metadata_And_Zero;

   procedure Ownership (Test : in out Fixture) is
      pragma Unreferenced (Test);
      A : S.Sparse_Mat :=
        S.Create ((2, 2), (Depth => OpenCV.Core.UInt8, Channels => 1));
      B : S.Sparse_Mat;
   begin
      U8.Set (A, (0, 1), 7);
      B := A;
      declare
         Copy : constant S.Sparse_Mat := A.Clone;
      begin
         U8.Set (B, (0, 1), 9);
         Assert
           (U8.Get (A, (0, 1)) = 9 and then U8.Get (Copy, (0, 1)) = 7,
            "shallow vs deep");
         B.Clear;
         Assert
           (A.Stored_Element_Count = 0
            and then Copy.Stored_Element_Count = 1
            and then Copy.Shape = (2, 2),
            "clear aliases only");
      end;
      U8.Set (A, (1, 1), 11);
      Assert (U8.Get (B, (1, 1)) = 11, "copy survives clone finalization");
   end Ownership;

   procedure All_Depths (Test : in out Fixture) is
      pragma Unreferenced (Test);
      I8        : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Int8, 1));
      U16       : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.UInt16, 1));
      I16       : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Int16, 1));
      I32       : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Int32, 1));
      F32       : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Float32, 1));
      F64       : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Float64, 1));
      F16       : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Float16, 1));
      Encodings : constant array (1 .. 8) of Interfaces.Unsigned_16 :=
        (16#0000#,
         16#8000#,
         16#0001#,
         16#7BFF#,
         16#7C00#,
         16#FC00#,
         16#7C01#,
         16#7E05#);
   begin
      S.Int8_Access.Set (I8, (1, 1), -8);
      S.UInt16_Access.Set (U16, (1, 1), 65_000);
      S.Int16_Access.Set (I16, (1, 1), -32000);
      S.Int32_Access.Set (I32, (1, 1), -2_000_000);
      S.Float32_Access.Set (F32, (1, 1), 1.25);
      S.Float64_Access.Set (F64, (1, 1), 2.5);
      Assert
        (S.Int8_Access.Get (I8, (1, 1)) = -8
         and then S.UInt16_Access.Get (U16, (1, 1)) = 65_000
         and then S.Int16_Access.Get (I16, (1, 1)) = -32000
         and then S.Int32_Access.Get (I32, (1, 1)) = -2_000_000
         and then S.Float32_Access.Get (F32, (1, 1)) = 1.25
         and then S.Float64_Access.Get (F64, (1, 1)) = 2.5,
         "all scalar depths");
      for Bits of Encodings loop
         S.Float16_Access.Set
           (F16, (0, 1), OpenCV.Core.Float16_From_Bits (Bits));
         Assert
           (OpenCV.Core.Float16_Bits (S.Float16_Access.Get (F16, (0, 1)))
            = Bits,
            "Float16 exact bits");
      end loop;
   end All_Depths;

   procedure Dense_Conversion (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Dense : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (1 => 2, 2 => 3), Element_Type => (OpenCV.Core.UInt8, 1));
   begin
      Dense.Set_To (OpenCV.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Dense, 1, 2, 17);
      declare
         Sparse    : S.Sparse_Mat := S.From_Dense (Dense);
         Roundtrip : constant OpenCV.Core.Mat := Sparse.To_Dense;
      begin
         Assert
           (Sparse.Stored_Element_Count = 1
            and then U8.Get (Sparse, (1, 2)) = 17
            and then OpenCV.Core.UInt8_Access.Get (Roundtrip, 1, 2) = 17
            and then OpenCV.Core.UInt8_Access.Get (Roundtrip, 0, 0) = 0,
            "dense roundtrip");
         OpenCV.Core.UInt8_Access.Set (Dense, 1, 2, 1);
         U8.Set (Sparse, (1, 2), 3);
         Assert
           (OpenCV.Core.UInt8_Access.Get (Roundtrip, 1, 2) = 17
            and then U8.Get (Sparse, (1, 2)) = 3,
            "independent copies");
      end;
   end Dense_Conversion;

   procedure Conversion_Layouts (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 5, (OpenCV.Core.UInt8, 1));
      Color  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 3));
      Half   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float16, 1));
   begin
      Parent.Set_To (OpenCV.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Parent, 2, 2, 31);
      declare
         View   : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
         Sparse : constant S.Sparse_Mat := S.From_Dense (View);
         Dense  : constant OpenCV.Core.Mat := Sparse.To_Dense;
      begin
         Assert
           (Sparse.Shape = (2, 3)
            and then Sparse.Stored_Element_Count = 1
            and then U8.Get (Sparse, (1, 1)) = 31
            and then OpenCV.Core.UInt8_Access.Get (Dense, 1, 1) = 31,
            "non-contiguous Region conversion");
      end;
      Color.Set_To (OpenCV.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Vec3_Access.Set (Color, 1, 2, (1, 0, 255));
      declare
         Sparse : constant S.Sparse_Mat := S.From_Dense (Color);
         Dense  : constant OpenCV.Core.Mat := Sparse.To_Dense;
      begin
         Assert
           (Sparse.Channels = 3
            and then Sparse.Element_Size = 3
            and then Sparse.Stored_Element_Count = 1
            and then Sparse.Contains ((1, 2))
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Dense, 1, 2)
                     = (1, 0, 255),
            "multi-channel complete element");
      end;
      OpenCV.Core.Float16_Access.Set
        (Half, 0, 0, OpenCV.Core.Float16_From_Bits (16#0000#));
      OpenCV.Core.Float16_Access.Set
        (Half, 0, 1, OpenCV.Core.Float16_From_Bits (16#8000#));
      OpenCV.Core.Float16_Access.Set
        (Half, 0, 2, OpenCV.Core.Float16_From_Bits (16#7E05#));
      declare
         Sparse : constant S.Sparse_Mat := S.From_Dense (Half);
      begin
         Assert
           (Sparse.Stored_Element_Count = 2
            and then not Sparse.Contains ((0, 0))
            and then Sparse.Contains ((0, 1))
            and then Sparse.Contains ((0, 2))
            and then OpenCV.Core.Float16_Bits
                       (S.Float16_Access.Get (Sparse, (0, 1)))
                     = 16#8000#
            and then OpenCV.Core.Float16_Bits
                       (S.Float16_Access.Get (Sparse, (0, 2)))
                     = 16#7E05#,
            "dense zero detection uses complete element bytes");
      end;
   end Conversion_Layouts;

   procedure Higher_Dimensions (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image : S.Sparse_Mat :=
        S.Create ((2, 2, 2, 2, 2), (OpenCV.Core.Int32, 1));
      Large : S.Sparse_Mat :=
        S.Create ((1 .. 32 => 1), (OpenCV.Core.UInt8, 1));
   begin
      S.Int32_Access.Set (Image, (1, 0, 1, 0, 1), -100);
      Assert
        (Image.Contains ((1, 0, 1, 0, 1))
         and then S.Int32_Access.Get (Image, (1, 0, 1, 0, 1)) = -100,
         "5D node indexing");
      U8.Set (Large, (1 .. 32 => 0), 8);
      Assert
        (Large.Dimension_Count = 32 and then Large.Stored_Element_Count = 1,
         "32D sparse construction");
   end Higher_Dimensions;

   procedure Public_Errors (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Empty : S.Sparse_Mat;
      Image : S.Sparse_Mat := S.Create ((2, 3), (OpenCV.Core.UInt8, 1));
      procedure Expect_Error (Operation : not null access procedure) is
      begin
         Operation.all;
         Assert (False, "expected OpenCV_Error");
      exception
         when OpenCV.OpenCV_Error =>
            null;
      end Expect_Error;
      procedure Unallocated_Read is
         Value : constant OpenCV.Core.Depth_Type := Empty.Depth;
      begin
         Assert (Value = OpenCV.Core.UInt8, "unexpected metadata");
      end Unallocated_Read;
      procedure Invalid_Axis is
         Value : constant OpenCV.Size_Coordinate := Image.Extent (3);
      begin
         Assert (Value = 0, "unexpected extent");
      end Invalid_Axis;
      procedure Invalid_Index is
      begin
         U8.Set (Image, (1, 3), 1);
      end Invalid_Index;
      procedure Wrong_Depth is
      begin
         S.Int8_Access.Set (Image, (1, 1), 1);
      end Wrong_Depth;
      procedure Empty_Dense is
         Dense : constant OpenCV.Core.Mat := S.To_Dense (Empty);
      begin
         Assert (Dense.Is_Empty, "unexpected empty dense");
      end Empty_Dense;
   begin
      Expect_Error (Unallocated_Read'Access);
      Expect_Error (Invalid_Axis'Access);
      Expect_Error (Invalid_Index'Access);
      Expect_Error (Wrong_Depth'Access);
      Expect_Error (Empty_Dense'Access);
      Assert
        (Image.Stored_Element_Count = 0,
         "rejected typed write must not create nodes");
   end Public_Errors;

   procedure Raw_Safety (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Sizes              : aliased C.C_Int32_Array := (0 => 2, 1 => 3);
      Negative           : aliased C.C_Int32_Array := (0 => -1, 1 => 2);
      Inner              : aliased C.C_Int32_Array := (0 => 1, 1 => 3);
      Good               : aliased C.C_Int32_Array := (0 => 1, 1 => 2);
      Bad                : aliased C.C_Int32_Array := (0 => 2, 1 => 2);
      Raw                : aliased C.Sparse_Mat_Handle :=
        C.Null_Sparse_Mat_Handle;
      Scalar             : aliased C.C_UInt8 := 255;
      Count              : aliased C.C_UInt64 := 0;
      D, Depth, Channels : aliased C.C_Int32 := 0;
      E, B               : aliased C.C_UInt64 := 0;
   begin
      Assert
        (C.Sparse_Create_ND (2, Sizes (0)'Access, 0, 1, Raw'Access)
         = C.Success,
         "raw create");
      Assert
        (C.Sparse_Get_UInt8 (Raw, 2, Bad (0)'Access, Scalar'Access)
         = C.Error_Invalid_Argument
         and then Scalar = 0,
         "invalid get zeroes output");
      Assert
        (C.Sparse_Set_UInt8 (Raw, 2, Bad (0)'Access, 7)
         = C.Error_Invalid_Argument,
         "invalid set");
      Assert
        (C.Sparse_Set_UInt8 (Raw, 2, Negative (0)'Access, 7)
         = C.Error_Invalid_Argument
         and then C.Sparse_Set_UInt8 (Raw, 2, Inner (0)'Access, 7)
                  = C.Error_Invalid_Argument
         and then C.Sparse_Set_UInt8 (Raw, 1, Good (0)'Access, 7)
                  = C.Error_Invalid_Argument
         and then C.Sparse_Set_UInt8 (Raw, 2, null, 7)
                  = C.Error_Invalid_Argument
         and then C.Sparse_Set_UInt8
                    (C.Null_Sparse_Mat_Handle, 2, Good (0)'Access, 7)
                  = C.Error_Invalid_Argument,
         "all raw coordinate errors rejected");
      Assert
        (C.Sparse_Set_UInt8 (Raw, 2, Good (0)'Access, 7) = C.Success,
         "raw set");
      declare
         Signed_Scalar : aliased C.C_Int8 := 1;
      begin
         Assert
           (C.Sparse_Get_Int8 (Raw, 2, Good (0)'Access, Signed_Scalar'Access)
            = C.Error_Invalid_Argument
            and then Signed_Scalar = 0,
            "wrong layout");
      end;
      Assert
        (C.Sparse_Metadata
           (Raw,
            D'Access,
            Depth'Access,
            Channels'Access,
            E'Access,
            B'Access,
            Count'Access)
         = C.Success
         and then Count = 1,
         "invalid write leaves node count");
      Assert
        (C.Sparse_Erase (Raw, 2, Bad (0)'Access) = C.Error_Invalid_Argument
         and then C.Sparse_Erase (Raw, 2, Inner (0)'Access)
                  = C.Error_Invalid_Argument
         and then C.Sparse_Erase (Raw, 2, Negative (0)'Access)
                  = C.Error_Invalid_Argument,
         "raw erase validates both dimensions");
      Assert
        (C.Sparse_Get_UInt8 (Raw, 2, Good (0)'Access, Scalar'Access)
         = C.Success
         and then Scalar = 7,
         "rejected erase preserves existing node");
      C.Sparse_Destroy (Raw);
   end Raw_Safety;

   procedure Raw_Layout_Matrix (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Sizes              : aliased C.C_Int32_Array := (0 => 2, 1 => 2);
      Index              : aliased C.C_Int32_Array := (0 => 1, 1 => 1);
      Raw                : aliased C.Sparse_Mat_Handle :=
        C.Null_Sparse_Mat_Handle;
      U8                 : aliased C.C_UInt8 := 255;
      I8                 : aliased C.C_Int8 := 1;
      U16                : aliased C.C_UInt16 := 255;
      I32                : aliased C.C_Int32 := 1;
      F32                : aliased C.C_Float32 := 1.0;
      D, Depth, Channels : aliased C.C_Int32 := 0;
      E, B, Nodes        : aliased C.C_UInt64 := 0;
      procedure Make (Kind, Count : C.C_Int32) is
      begin
         C.Sparse_Destroy (Raw);
         Raw := C.Null_Sparse_Mat_Handle;
         Assert
           (C.Sparse_Create_ND (2, Sizes (0)'Access, Kind, Count, Raw'Access)
            = C.Success,
            "raw layout fixture");
      end Make;
      procedure No_Nodes is
      begin
         Assert
           (C.Sparse_Metadata
              (Raw,
               D'Access,
               Depth'Access,
               Channels'Access,
               E'Access,
               B'Access,
               Nodes'Access)
            = C.Success
            and then Nodes = 0,
            "rejected writes must not insert nodes");
      end No_Nodes;
   begin
      Make (1, 1);
      Assert
        (C.Sparse_Get_UInt8 (Raw, 2, Index (0)'Access, U8'Access)
         = C.Error_Invalid_Argument
         and then U8 = 0
         and then C.Sparse_Set_UInt8 (Raw, 2, Index (0)'Access, 2)
                  = C.Error_Invalid_Argument,
         "UInt8 against Int8");
      No_Nodes;
      Make (0, 1);
      Assert
        (C.Sparse_Get_Int8 (Raw, 2, Index (0)'Access, I8'Access)
         = C.Error_Invalid_Argument
         and then I8 = 0
         and then C.Sparse_Set_Int8 (Raw, 2, Index (0)'Access, 2)
                  = C.Error_Invalid_Argument,
         "Int8 against UInt8");
      No_Nodes;
      for Kind in C.C_Int32'(3) .. C.C_Int32'(7) loop
         if Kind = 3 or else Kind = 7 then
            Make (Kind, 1);
            U16 := 255;
            Assert
              (C.Sparse_Get_UInt16 (Raw, 2, Index (0)'Access, U16'Access)
               = C.Error_Invalid_Argument
               and then U16 = 0
               and then C.Sparse_Set_UInt16 (Raw, 2, Index (0)'Access, 2)
                        = C.Error_Invalid_Argument,
               "UInt16 wrong 2-byte depth");
            No_Nodes;
         end if;
      end loop;
      Make (2, 1);
      Assert
        (C.Sparse_Get_Float16 (Raw, 2, Index (0)'Access, U16'Access)
         = C.Error_Invalid_Argument
         and then U16 = 0
         and then C.Sparse_Set_Float16 (Raw, 2, Index (0)'Access, 2)
                  = C.Error_Invalid_Argument,
         "Float16 against UInt16");
      No_Nodes;
      Make (3, 1);
      Assert
        (C.Sparse_Get_Float16 (Raw, 2, Index (0)'Access, U16'Access)
         = C.Error_Invalid_Argument
         and then U16 = 0,
         "Float16 against Int16");
      No_Nodes;
      Make (5, 1);
      Assert
        (C.Sparse_Get_Int32 (Raw, 2, Index (0)'Access, I32'Access)
         = C.Error_Invalid_Argument
         and then I32 = 0
         and then C.Sparse_Set_Int32 (Raw, 2, Index (0)'Access, 2)
                  = C.Error_Invalid_Argument,
         "Int32 against Float32");
      No_Nodes;
      Make (4, 1);
      Assert
        (C.Sparse_Get_Float32 (Raw, 2, Index (0)'Access, F32'Access)
         = C.Error_Invalid_Argument
         and then C.Sparse_Set_Float32 (Raw, 2, Index (0)'Access, 2.0)
                  = C.Error_Invalid_Argument,
         "Float32 against Int32");
      No_Nodes;
      Make (2, 2);
      Assert
        (C.Sparse_Get_UInt16 (Raw, 2, Index (0)'Access, U16'Access)
         = C.Error_Invalid_Argument
         and then U16 = 0
         and then C.Sparse_Set_UInt16 (Raw, 2, Index (0)'Access, 2)
                  = C.Error_Invalid_Argument,
         "C2 rejects typed C1 access");
      No_Nodes;
      C.Sparse_Destroy (Raw);
   end Raw_Layout_Matrix;

   procedure Raw_Handles_And_Unallocated (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Default : aliased C.Sparse_Mat_Handle := C.Null_Sparse_Mat_Handle;
      Output  : aliased C.Sparse_Mat_Handle := C.Null_Sparse_Mat_Handle;
      Dense   : aliased C.Mat_Handle := C.Null_Mat_Handle;
      Indices : aliased C.C_Int32_Array := (0 => 0, 1 => 0);
      Scalar  : aliased C.C_UInt16 := 16#FFFF#;
      Found   : aliased C.C_UInt8 := 255;
   begin
      Assert
        (C.Sparse_Create (Default'Access) = C.Success,
         "raw default construction");
      Assert
        (C.Sparse_Get_Float16 (Default, 2, Indices (0)'Access, Scalar'Access)
         = C.Error_Invalid_Argument
         and then Scalar = 0,
         "unallocated get zeroes result");
      Assert
        (C.Sparse_Set_Float16 (Default, 2, Indices (0)'Access, 0)
         = C.Error_Invalid_Argument
         and then C.Sparse_Erase (Default, 2, Indices (0)'Access)
                  = C.Error_Invalid_Argument
         and then C.Sparse_Contains
                    (Default, 2, Indices (0)'Access, Found'Access)
                  = C.Error_Invalid_Argument
         and then Found = 0,
         "unallocated node operations reject");
      Assert
        (C.Sparse_To_Dense (Default, Dense'Access) = C.Error_Invalid_Argument
         and then Dense = C.Null_Mat_Handle,
         "unallocated dense conversion");
      Assert
        (C.Sparse_Copy (C.Null_Sparse_Mat_Handle, Output'Access)
         = C.Error_Invalid_Argument
         and then Output = C.Null_Sparse_Mat_Handle,
         "failed copy initializes output");
      Assert
        (C.Sparse_Create (null) = C.Error_Invalid_Argument,
         "null output pointer");
      C.Sparse_Destroy (Default);
      C.Sparse_Destroy (C.Null_Sparse_Mat_Handle);
   end Raw_Handles_And_Unallocated;

   procedure Stored_Entries (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Empty : constant S.Sparse_Mat :=
        S.Create ((3, 4), (OpenCV.Core.UInt8, 1));
      Image : S.Sparse_Mat := S.Create ((3, 4), (OpenCV.Core.UInt8, 1));
      Alias : S.Sparse_Mat;
      Seen  : array (1 .. 3) of Boolean := (others => False);
      Count : Natural := 0;
      procedure Visit
        (Indices : OpenCV.Core.Index_Array; Value : OpenCV.UInt8_Value)
      is
         Slot : Positive;
      begin
         Assert (Indices'First = 1 and then Indices'Last = 2, "2D bounds");
         if Indices = (2, 3) and then Value = 14 then
            Slot := 1;
         elsif Indices = (0, 1) and then Value = 0 then
            Slot := 2;
         elsif Indices = (1, 2) and then Value = 29 then
            Slot := 3;
         else
            Assert (False, "unexpected stored entry");
            return;
         end if;
         Assert (not Seen (Slot), "duplicate stored entry");
         Seen (Slot) := True;
         Count := Count + 1;
      end Visit;
   begin
      U8.For_Each_Stored (Empty, Visit'Access);
      Assert (Count = 0, "allocated empty traversal");
      U8.Set (Image, (2, 3), 14);
      U8.Set (Image, (0, 1), 0);
      U8.Set (Image, (1, 2), 29);
      Alias := Image;
      Assert
        (Image.Contains ((0, 1)) and then not Image.Contains ((0, 0)),
         "explicit zero node and missing node");
      U8.For_Each_Stored (Alias, Visit'Access);
      Assert
        (Count = Natural (Image.Stored_Element_Count)
         and then (for all Found of Seen => Found),
         "all shallow-shared nodes");
   end Stored_Entries;

   procedure Stored_Depths (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Shape : constant OpenCV.Core.Dimension_Array := (1 => 2, 2 => 2);
      Count : Natural := 0;
      procedure Check_U8 (I : OpenCV.Core.Index_Array; V : OpenCV.UInt8_Value)
      is
      begin
         Assert (I = (1, 0) and then V = 255, "uint8 iteration");
         Count := Count + 1;
      end Check_U8;
      procedure Check_I8 (I : OpenCV.Core.Index_Array; V : OpenCV.Int8_Value)
      is
      begin
         Assert (I = (1, 0) and then V = -128, "int8 iteration");
         Count := Count + 1;
      end Check_I8;
      procedure Check_U16
        (I : OpenCV.Core.Index_Array; V : OpenCV.UInt16_Value) is
      begin
         Assert (I = (1, 0) and then V = 65535, "uint16 iteration");
         Count := Count + 1;
      end Check_U16;
      procedure Check_I16 (I : OpenCV.Core.Index_Array; V : OpenCV.Int16_Value)
      is
      begin
         Assert (I = (1, 0) and then V = -32768, "int16 iteration");
         Count := Count + 1;
      end Check_I16;
      procedure Check_I32 (I : OpenCV.Core.Index_Array; V : OpenCV.Int32_Value)
      is
      begin
         Assert (I = (1, 0) and then V = -2_147_483_648, "int32 iteration");
         Count := Count + 1;
      end Check_I32;
      procedure Check_F32
        (I : OpenCV.Core.Index_Array; V : OpenCV.Float32_Value) is
      begin
         Assert (I = (1, 0) and then V = -3.25, "float32 iteration");
         Count := Count + 1;
      end Check_F32;
      procedure Check_F64
        (I : OpenCV.Core.Index_Array; V : OpenCV.Float64_Value) is
      begin
         Assert (I = (1, 0) and then V = 1.25E100, "float64 iteration");
         Count := Count + 1;
      end Check_F64;
   begin
      declare
         M : S.Sparse_Mat := S.Create (Shape, (OpenCV.Core.UInt8, 1));
      begin
         U8.Set (M, (1, 0), 255);
         U8.For_Each_Stored (M, Check_U8'Access);
      end;
      declare
         M : S.Sparse_Mat := S.Create (Shape, (OpenCV.Core.Int8, 1));
      begin
         S.Int8_Access.Set (M, (1, 0), -128);
         S.Int8_Access.For_Each_Stored (M, Check_I8'Access);
      end;
      declare
         M : S.Sparse_Mat := S.Create (Shape, (OpenCV.Core.UInt16, 1));
      begin
         S.UInt16_Access.Set (M, (1, 0), 65535);
         S.UInt16_Access.For_Each_Stored (M, Check_U16'Access);
      end;
      declare
         M : S.Sparse_Mat := S.Create (Shape, (OpenCV.Core.Int16, 1));
      begin
         S.Int16_Access.Set (M, (1, 0), -32768);
         S.Int16_Access.For_Each_Stored (M, Check_I16'Access);
      end;
      declare
         M : S.Sparse_Mat := S.Create (Shape, (OpenCV.Core.Int32, 1));
      begin
         S.Int32_Access.Set (M, (1, 0), -2_147_483_648);
         S.Int32_Access.For_Each_Stored (M, Check_I32'Access);
      end;
      declare
         M : S.Sparse_Mat := S.Create (Shape, (OpenCV.Core.Float32, 1));
      begin
         S.Float32_Access.Set (M, (1, 0), -3.25);
         S.Float32_Access.For_Each_Stored (M, Check_F32'Access);
      end;
      declare
         M : S.Sparse_Mat := S.Create (Shape, (OpenCV.Core.Float64, 1));
      begin
         S.Float64_Access.Set (M, (1, 0), 1.25E100);
         S.Float64_Access.For_Each_Stored (M, Check_F64'Access);
      end;
      Assert (Count = 7, "one callback for each non-half depth");
   end Stored_Depths;

   procedure Stored_Half_And_ND (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Bits  :
        constant array (Natural range 0 .. 4) of Interfaces.Unsigned_16 :=
          (16#0000#, 16#8000#, 16#0001#, 16#7C00#, 16#7E05#);
      Image : S.Sparse_Mat :=
        S.Create ((2, 2, 2, 2, 5), (OpenCV.Core.Float16, 1));
      Seen  : array (Bits'Range) of Boolean := (others => False);
      Count : Natural := 0;
      procedure Visit
        (I : OpenCV.Core.Index_Array; V : OpenCV.Core.Float16_Value) is
      begin
         Assert (I'First = 1 and then I'Last = 5, "5D bounds");
         Assert (I (1 .. 4) = (0, 1, 0, 1), "5D coordinates");
         Assert (I (5) <= 4, "5D last index");
         Assert (not Seen (Natural (I (5))), "duplicate half");
         Seen (Natural (I (5))) := True;
         Assert
           (OpenCV.Core.Float16_Bits (V) = Bits (Natural (I (5))),
            "exact half encoding");
         Count := Count + 1;
      end Visit;
   begin
      for N in Bits'Range loop
         S.Float16_Access.Set
           (Image,
            (0, 1, 0, 1, OpenCV.Size_Coordinate (N)),
            OpenCV.Core.Float16_From_Bits (Bits (N)));
      end loop;
      S.Float16_Access.For_Each_Stored (Image, Visit'Access);
      Assert
        (Count = 5 and then (for all B of Seen => B), "five exact halves");
   end Stored_Half_And_ND;

   procedure Stored_Max_Dimensions (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Extents     : constant OpenCV.Core.Dimension_Array (1 .. 32) :=
        (others => 2);
      Image       : S.Sparse_Mat := S.Create (Extents, (OpenCV.Core.UInt8, 1));
      Coordinates : OpenCV.Core.Index_Array (1 .. 32) := (others => 0);
      Seen        : Natural := 0;
      procedure Visit (I : OpenCV.Core.Index_Array; V : OpenCV.UInt8_Value) is
      begin
         Assert
           (I'First = 1
            and then I'Last = 32
            and then I = Coordinates
            and then V = 71,
            "32D stored node");
         Seen := Seen + 1;
      end Visit;
   begin
      Coordinates (32) := 1;
      U8.Set (Image, Coordinates, 71);
      U8.For_Each_Stored (Image, Visit'Access);
      Assert (Seen = 1, "32D visit count");
   end Stored_Max_Dimensions;

   procedure Stored_Errors (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Empty           : S.Sparse_Mat;
      Wrong           : constant S.Sparse_Mat :=
        S.Create ((2, 2), (OpenCV.Core.Int16, 1));
      Multi           : constant S.Sparse_Mat :=
        S.Create ((2, 2), (OpenCV.Core.UInt8, 2));
      Image           : S.Sparse_Mat :=
        S.Create ((2, 2), (OpenCV.Core.UInt8, 1));
      Count           : Natural := 0;
      Callback_Failed : exception;
      procedure Visit (I : OpenCV.Core.Index_Array; V : OpenCV.UInt8_Value) is
         pragma Unreferenced (I, V);
      begin
         Count := Count + 1;
      end Visit;
      procedure Explode (I : OpenCV.Core.Index_Array; V : OpenCV.UInt8_Value)
      is
         pragma Unreferenced (I, V);
      begin
         Count := Count + 1;
         raise Callback_Failed;
      end Explode;
   begin
      begin
         U8.For_Each_Stored (Empty, Visit'Access);
         Assert (False, "unallocated accepted");
      exception
         when OpenCV.OpenCV_Error =>
            null;
      end;
      begin
         U8.For_Each_Stored (Wrong, Visit'Access);
         Assert (False, "wrong depth accepted");
      exception
         when OpenCV.OpenCV_Error =>
            null;
      end;
      begin
         U8.For_Each_Stored (Multi, Visit'Access);
         Assert (False, "C2 accepted");
      exception
         when OpenCV.OpenCV_Error =>
            null;
      end;
      Assert (Count = 0, "rejected callbacks never run");
      U8.Set (Image, (0, 0), 1);
      U8.Set (Image, (1, 1), 2);
      begin
         U8.For_Each_Stored (Image, Explode'Access);
         Assert (False, "callback did not raise");
      exception
         when Callback_Failed =>
            null;
      end;
      Assert
        (Count = 1 and then Image.Stored_Element_Count = 2,
         "callback exception stops traversal");
      Count := 0;
      U8.For_Each_Stored (Image, Visit'Access);
      Assert
        (Count = 2 and then U8.Get (Image, (1, 1)) = 2,
         "source usable after callback exception");
   end Stored_Errors;

   procedure Raw_Stored_Iterator (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source, Wrong, Multi : aliased C.Sparse_Mat_Handle :=
        C.Null_Sparse_Mat_Handle;
      Half                 : aliased C.Sparse_Mat_Handle :=
        C.Null_Sparse_Mat_Handle;
      It                   : aliased C.Sparse_Iterator_Handle :=
        C.Null_Sparse_Iterator_Handle;
      Sizes                : aliased C.C_Int32_Array := (0 => 2, 1 => 2);
      Node_Index           : aliased C.C_Int32_Array := (0 => 1, 1 => 0);
      Indices              : aliased C.C_Int32_Array (0 .. 2) :=
        (others => -1);
      Value                : aliased C.C_UInt8 := 99;
      Found                : aliased C.C_UInt8 := 99;
   begin
      Assert
        (C.Sparse_Iterator_Create (C.Null_Sparse_Mat_Handle, It'Access)
         = C.Error_Invalid_Argument
         and then It = C.Null_Sparse_Iterator_Handle,
         "failed create clears handle");
      Assert
        (C.Sparse_Iterator_Create (C.Null_Sparse_Mat_Handle, null)
         = C.Error_Invalid_Argument,
         "null create output");
      Assert
        (C.Sparse_Create_ND (2, Sizes (0)'Access, 0, 1, Source'Access)
         = C.Success,
         "raw iterator source");
      Assert
        (C.Sparse_Create_ND (2, Sizes (0)'Access, 1, 1, Wrong'Access)
         = C.Success,
         "raw wrong depth");
      Assert
        (C.Sparse_Create_ND (2, Sizes (0)'Access, 0, 2, Multi'Access)
         = C.Success,
         "raw C2");
      Assert
        (C.Sparse_Create_ND (2, Sizes (0)'Access, 7, 1, Half'Access)
         = C.Success,
         "raw Float16 layout");
      Assert
        (C.Sparse_Set_UInt8 (Source, 2, Node_Index (0)'Access, 37) = C.Success,
         "raw stored node");
      Assert
        (C.Sparse_Iterator_Create (Source, It'Access) = C.Success,
         "create raw iterator");
      C.Sparse_Destroy (Source);
      Source := C.Null_Sparse_Mat_Handle;
      Assert
        (C.Sparse_Iterator_Next_UInt8
           (C.Null_Sparse_Iterator_Handle,
            2,
            Indices (0)'Access,
            Value'Access,
            Found'Access)
         = C.Error_Invalid_Argument
         and then Value = 0
         and then Found = 0,
         "null iterator clears outputs");
      Value := 99;
      Found := 99;
      Assert
        (C.Sparse_Iterator_Next_UInt8 (It, 2, null, Value'Access, Found'Access)
         = C.Error_Invalid_Argument
         and then Value = 0
         and then Found = 0,
         "null indices");
      Found := 99;
      Assert
        (C.Sparse_Iterator_Next_UInt8
           (It, 2, Indices (0)'Access, null, Found'Access)
         = C.Error_Invalid_Argument
         and then Found = 0,
         "null scalar");
      Value := 99;
      Assert
        (C.Sparse_Iterator_Next_UInt8
           (It, 2, Indices (0)'Access, Value'Access, null)
         = C.Error_Invalid_Argument
         and then Value = 0,
         "null found");
      Value := 99;
      Found := 99;
      Assert
        (C.Sparse_Iterator_Next_UInt8
           (It, 3, Indices (0)'Access, Value'Access, Found'Access)
         = C.Error_Invalid_Argument
         and then Value = 0
         and then Found = 0,
         "wrong dimension without index write");
      Assert (Indices (0 .. 1) = (-1, -1), "failure leaves indices intact");
      declare
         Signed_Value : aliased C.C_Int8 := 99;
         Wide_Value   : aliased C.C_UInt16 := 99;
      begin
         Assert
           (C.Sparse_Iterator_Next_Int8
              (It, 2, Indices (0)'Access, Signed_Value'Access, Found'Access)
            = C.Error_Invalid_Argument
            and then Signed_Value = 0
            and then Found = 0,
            "same-size wrong depth");
         Assert
           (C.Sparse_Iterator_Next_UInt16
              (It, 2, Indices (0)'Access, Wide_Value'Access, Found'Access)
            = C.Error_Invalid_Argument
            and then Wide_Value = 0
            and then Found = 0,
            "wrong scalar size");
      end;
      Assert
        (C.Sparse_Iterator_Next_UInt8
           (It, 2, Indices (0)'Access, Value'Access, Found'Access)
         = C.Success
         and then Found = 1
         and then Value = 37
         and then Indices (0 .. 1) = (1, 0),
         "rejected calls do not advance");
      Value := 99;
      Found := 99;
      Assert
        (C.Sparse_Iterator_Next_UInt8
           (It, 2, Indices (0)'Access, Value'Access, Found'Access)
         = C.Success
         and then Found = 0
         and then Value = 0,
         "end does not advance and clears scalar");
      Assert
        (C.Sparse_Iterator_Next_UInt8
           (It, 2, Indices (0)'Access, Value'Access, Found'Access)
         = C.Success
         and then Found = 0,
         "repeated end remains at end");
      C.Sparse_Iterator_Destroy (It);
      It := C.Null_Sparse_Iterator_Handle;
      Assert
        (C.Sparse_Iterator_Create (Wrong, It'Access) = C.Success,
         "wrong depth iterator creation");
      Assert
        (C.Sparse_Iterator_Next_UInt8
           (It, 2, Indices (0)'Access, Value'Access, Found'Access)
         = C.Error_Invalid_Argument
         and then Value = 0
         and then Found = 0,
         "raw wrong depth");
      C.Sparse_Iterator_Destroy (It);
      It := C.Null_Sparse_Iterator_Handle;
      Assert
        (C.Sparse_Iterator_Create (Multi, It'Access) = C.Success,
         "C2 iterator creation");
      Assert
        (C.Sparse_Iterator_Next_UInt8
           (It, 2, Indices (0)'Access, Value'Access, Found'Access)
         = C.Error_Invalid_Argument,
         "C2 raw layout");
      C.Sparse_Iterator_Destroy (It);
      It := C.Null_Sparse_Iterator_Handle;
      Assert
        (C.Sparse_Iterator_Create (Half, It'Access) = C.Success,
         "Float16 iterator creation");
      declare
         Bits : aliased C.C_UInt16 := 99;
      begin
         Assert
           (C.Sparse_Iterator_Next_UInt16
              (It, 2, Indices (0)'Access, Bits'Access, Found'Access)
            = C.Error_Invalid_Argument
            and then Bits = 0
            and then Found = 0,
            "same-size Float16 versus UInt16");
      end;
      C.Sparse_Iterator_Destroy (It);
      C.Sparse_Iterator_Destroy (C.Null_Sparse_Iterator_Handle);
      C.Sparse_Destroy (Source);
      C.Sparse_Destroy (Wrong);
      C.Sparse_Destroy (Multi);
      C.Sparse_Destroy (Half);
   end Raw_Stored_Iterator;

   Result : aliased AUnit.Test_Suites.Test_Suite;
   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Sparse stored entries and aliases", Stored_Entries'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse all stored scalar depths", Stored_Depths'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse stored 5D exact half bits", Stored_Half_And_ND'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse stored 32D boundary", Stored_Max_Dimensions'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse stored validation and callback cleanup",
            Stored_Errors'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse raw iterator safety", Raw_Stored_Iterator'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse default, metadata, zero node", Metadata_And_Zero'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse shallow assignment and clone", Ownership'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse all typed depths and half bits", All_Depths'Access));
      Result.Add_Test
        (Caller.Create ("Sparse dense conversion", Dense_Conversion'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse Region, C3 and byte-zero conversion",
            Conversion_Layouts'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse 5D and 32D node access", Higher_Dimensions'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse public validation errors", Public_Errors'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse raw index and layout safety", Raw_Safety'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse raw exact-size layouts", Raw_Layout_Matrix'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse raw handle failure atomicity",
            Raw_Handles_And_Unallocated'Access));
      return Result'Access;
   end Suite;
end Sparse_Tests;
