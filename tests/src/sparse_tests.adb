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
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.Float16_Access;
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

   Result : aliased AUnit.Test_Suites.Test_Suite;
   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
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
