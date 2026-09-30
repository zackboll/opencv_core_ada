with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with Module_Bridge_Probe;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Float16_Access;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float32_Vec3;
with OpenCV.Core.Float32_Vec3_Access;
with OpenCV.Core.Int16_Access;
with OpenCV.Core.Int32_Access;
with OpenCV.Core.Sparse;
with OpenCV.Core.Sparse.Float16_Access;
with OpenCV.Core.Sparse.Float32_Access;
with OpenCV.Core.Sparse.Float32_Vec3_Access;
with OpenCV.Core.Sparse.Float64_Access;
with OpenCV.Core.Sparse.Int16_Access;
with OpenCV.Core.Sparse.Int32_Access;
with OpenCV.Core.Sparse.UInt8_Access;
with OpenCV.Core.Sparse.UInt8_Vec3_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Internal.C_API;

package body Sparse_Numeric_Tests is
   package C renames OpenCV.Internal.C_API;
   package S renames OpenCV.Core.Sparse;
   use type C.Status;
   use type C.Mat_Handle;
   use type C.Sparse_Mat_Handle;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Dimension_Array;
   use type OpenCV.Core.Index_Array;
   use type OpenCV.Core.Mat_Size;
   use type Interfaces.Integer_16;
   use type Interfaces.Integer_32;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.IEEE_Float_32;
   use type Interfaces.IEEE_Float_64;
   use type C.C_Float32;
   use type OpenCV.Core.Float32_Vec3.Vector;
   use Mat_Test_Support;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      AUnit.Assertions.Assert (Condition, Message);
   end Assert;

   procedure Identity (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : S.Sparse_Mat := S.Create ((4, 5), (OpenCV.Core.Int32, 1));
      Seen   : array (1 .. 3) of Boolean := (others => False);
      Count  : Natural := 0;

      procedure Visit
        (Indices : OpenCV.Core.Index_Array; Value : OpenCV.Int32_Value)
      is
         Slot : Positive;
      begin
         if Indices = (1, 2) and then Value = 7 then
            Slot := 1;
         elsif Indices = (0, 4) and then Value = 0 then
            Slot := 2;
         elsif Indices = (3, 1) and then Value = -3 then
            Slot := 3;
         else
            Assert (False, "unexpected identity node");
            return;
         end if;
         Assert (not Seen (Slot), "duplicate identity node");
         Seen (Slot) := True;
         Count := Count + 1;
      end Visit;

      Converted : S.Sparse_Mat;
   begin
      S.Int32_Access.Set (Source, (1, 2), 7);
      S.Int32_Access.Set (Source, (0, 4), 0);
      S.Int32_Access.Set (Source, (3, 1), -3);
      Converted := Source.Convert_To (Source.Depth);
      Assert
        (Converted.Shape = Source.Shape
         and then Converted.Channels = 1
         and then Converted.Depth = OpenCV.Core.Int32
         and then Converted.Stored_Element_Count = 3
         and then Converted.Contains ((1, 2))
         and then Converted.Contains ((0, 4))
         and then Converted.Contains ((3, 1))
         and then not Converted.Contains ((0, 0)),
         "identity keeps stored nodes");
      S.Int32_Access.For_Each_Stored (Converted, Visit'Access);
      Assert
        (Count = 3 and then (for all Found of Seen => Found),
         "identity traversal");
      S.Int32_Access.Set (Source, (1, 2), 99);
      S.Int32_Access.Set (Converted, (3, 1), 40);
      Assert
        (S.Int32_Access.Get (Converted, (1, 2)) = 7
         and then S.Int32_Access.Get (Source, (3, 1)) = -3,
         "independent sparse storage");
   end Identity;

   procedure Scale_To_Zero (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : S.Sparse_Mat := S.Create ((3, 3), (OpenCV.Core.Float32, 1));
      Count  : Natural := 0;

      procedure Visit
        (Indices : OpenCV.Core.Index_Array; Value : Interfaces.IEEE_Float_32)
      is
      begin
         Assert
           (Value = 0.0 and then (Indices = (0, 1) or else Indices = (2, 2)),
            "scaled-to-zero node");
         Count := Count + 1;
      end Visit;

      Converted : S.Sparse_Mat;
   begin
      S.Float32_Access.Set (Source, (0, 1), 1.5);
      S.Float32_Access.Set (Source, (2, 2), -2.0);
      Converted := Source.Convert_To (OpenCV.Core.Float32, 2.0);
      Assert
        (S.Float32_Access.Get (Converted, (0, 1)) = 3.0
         and then S.Float32_Access.Get (Converted, (2, 2)) = -4.0
         and then Converted.Stored_Element_Count = 2
         and then not Converted.Contains ((1, 1)),
         "nontrivial sparse scale");
      Converted := Source.Convert_To (OpenCV.Core.Float32, 0.0);
      S.Float32_Access.For_Each_Stored (Converted, Visit'Access);
      Assert
        (Count = 2
         and then Converted.Stored_Element_Count = Source.Stored_Element_Count
         and then Converted.Contains ((0, 1))
         and then Converted.Contains ((2, 2))
         and then not Converted.Contains ((0, 0))
         and then S.Float32_Access.Get (Source, (0, 1)) = 1.5,
         "zero scale retains one node per source node");
   end Scale_To_Zero;

   procedure Cross_Depth (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Bytes   : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.UInt8, 1));
      Shorts  : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Int16, 1));
      Doubles : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Float64, 1));
      Floats  : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Float32, 1));
   begin
      S.UInt8_Access.Set (Bytes, (0, 1), 9);
      Assert
        (S.Float32_Access.Get (Bytes.Convert_To (OpenCV.Core.Float32), (0, 1))
         = 9.0,
         "UInt8 to Float32");
      S.Int16_Access.Set (Shorts, (1, 0), -12);
      Assert
        (S.Float64_Access.Get (Shorts.Convert_To (OpenCV.Core.Float64), (1, 0))
         = -12.0,
         "Int16 to Float64");
      S.Float64_Access.Set (Doubles, (1, 1), 42.0);
      Assert
        (S.Int32_Access.Get (Doubles.Convert_To (OpenCV.Core.Int32), (1, 1))
         = 42,
         "Float64 to Int32");
      S.Float32_Access.Set (Floats, (0, 0), 300.2);
      Assert
        (S.UInt8_Access.Get (Floats.Convert_To (OpenCV.Core.UInt8), (0, 0))
         = 255,
         "Float32 to UInt8 saturates");
   end Cross_Depth;

   procedure Channels_And_Dimensions (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Color  : S.Sparse_Mat := S.Create ((2, 3), (OpenCV.Core.Float32, 3));
      Volume : S.Sparse_Mat :=
        S.Create ((2, 2, 2, 2, 2), (OpenCV.Core.Int32, 1));
      Wide   : S.Sparse_Mat :=
        S.Create ((1 .. 32 => 2), (OpenCV.Core.UInt8, 1));
      Seen   : Natural := 0;

      procedure Visit
        (Indices : OpenCV.Core.Index_Array;
         Value   : OpenCV.Core.Float32_Vec3.Vector) is
      begin
         Assert
           (Indices = (1, 0) and then Value = (2.0, -4.0, 0.0),
            "C3 converted components");
         Seen := Seen + 1;
      end Visit;

      Converted : S.Sparse_Mat;
   begin
      S.Float32_Vec3_Access.Set (Color, (1, 0), (1.0, -2.0, 0.0));
      Converted := Color.Convert_To (OpenCV.Core.Float32, 2.0);
      S.Float32_Vec3_Access.For_Each_Stored (Converted, Visit'Access);
      Assert
        (Seen = 1
         and then Converted.Channels = 3
         and then Converted.Stored_Element_Count = 1
         and then not Converted.Contains ((0, 0)),
         "C3 sparse conversion");
      S.Int32_Access.Set (Volume, (1, 0, 1, 0, 1), 4);
      S.Int32_Access.Set (Volume, (0, 0, 0, 0, 0), 0);
      Converted := Volume.Convert_To (OpenCV.Core.Float64, 0.5);
      Assert
        (Converted.Dimension_Count = 5
         and then Converted.Stored_Element_Count = 2
         and then Converted.Contains ((1, 0, 1, 0, 1))
         and then Converted.Contains ((0, 0, 0, 0, 0))
         and then S.Float64_Access.Get (Converted, (1, 0, 1, 0, 1)) = 2.0
         and then not Converted.Contains ((1, 1, 1, 1, 1)),
         "5D sparse conversion");
      S.UInt8_Access.Set (Wide, (1 .. 32 => 1), 7);
      S.UInt8_Access.Set (Wide, (1 .. 32 => 0), 0);
      Converted := Wide.Convert_To (OpenCV.Core.Int16);
      Assert
        (Converted.Dimension_Count = 32
         and then Converted.Stored_Element_Count = 2
         and then S.Int16_Access.Get (Converted, (1 .. 32 => 1)) = 7
         and then Converted.Contains ((1 .. 32 => 0)),
         "32D sparse conversion");
   end Channels_And_Dimensions;

   procedure Dense_Offset (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : S.Sparse_Mat := S.Create ((2, 3), (OpenCV.Core.Float32, 1));
      Dense  : OpenCV.Core.Mat;
   begin
      S.Float32_Access.Set (Source, (1, 2), 3.0);
      Dense :=
        Source.To_Dense (OpenCV.Core.Float32, Scale => 2.0, Offset => 5.0);
      Assert
        (Dense.Shape = (2, 3)
         and then Dense.Depth = OpenCV.Core.Float32
         and then OpenCV.Core.Float32_Access.Get (Dense, 0, 0) = 5.0
         and then OpenCV.Core.Float32_Access.Get (Dense, 1, 2) = 11.0
         and then S.Float32_Access.Get (Source, (1, 2)) = 3.0
         and then Source.Stored_Element_Count = 1,
         "missing dense positions use Offset");
      OpenCV.Core.Float32_Access.Set (Dense, 0, 0, 0.0);
      Assert
        (not Source.Contains ((0, 0)), "dense result does not share storage");
   end Dense_Offset;

   procedure Dense_Identity_And_Channels (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Int16, 1));
      Color  : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.UInt8, 3));
      Plain  : OpenCV.Core.Mat;
      Scaled : OpenCV.Core.Mat;
   begin
      S.Int16_Access.Set (Source, (0, 1), 15);
      Plain := Source.To_Dense;
      Scaled := Source.To_Dense (OpenCV.Core.Int16, 1.0, 0.0);
      Assert
        (OpenCV.Core.Int16_Access.Get (Plain, 0, 1) = 15
         and then OpenCV.Core.Int16_Access.Get (Scaled, 0, 1) = 15
         and then OpenCV.Core.Int16_Access.Get (Scaled, 1, 1) = 0
         and then Scaled.Depth = OpenCV.Core.Int16,
         "zero offset matches plain To_Dense");
      S.UInt8_Vec3_Access.Set (Color, (1, 0), (1, 2, 3));
      Scaled := Color.To_Dense (OpenCV.Core.Float32, 2.0, 1.0);
      declare
         Stored  : constant OpenCV.Core.Float32_Vec3.Vector :=
           OpenCV.Core.Float32_Vec3_Access.Get (Scaled, 1, 0);
         Missing : constant OpenCV.Core.Float32_Vec3.Vector :=
           OpenCV.Core.Float32_Vec3_Access.Get (Scaled, 0, 0);
      begin
         Assert
           (Scaled.Channels = 3
            and then Stored (0) = 3.0
            and then Stored (1) = 5.0
            and then Stored (2) = 7.0
            and then Missing (0) = 1.0
            and then Missing (1) = 0.0
            and then Missing (2) = 0.0,
            "dense offset applies per stored channel");
      end;
   end Dense_Identity_And_Channels;

   procedure Dense_Capacity (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Float64, 1));
      Wide   : S.Sparse_Mat :=
        S.Create ((1 .. 11 => 1), (OpenCV.Core.UInt8, 1));
      Dense  : OpenCV.Core.Mat;

      procedure Too_Wide is
         Ignored : constant OpenCV.Core.Mat :=
           Wide.To_Dense (OpenCV.Core.Int32, 1.0, 4.0);
      begin
         Assert (Ignored.Is_Empty, "unexpected wide dense conversion");
      end Too_Wide;
   begin
      S.Float64_Access.Set (Source, (1, 1), 300.9);
      Dense := Source.To_Dense (OpenCV.Core.UInt8, 1.0, 0.0);
      Assert
        (OpenCV.Core.UInt8_Access.Get (Dense, 1, 1) = 255
         and then OpenCV.Core.UInt8_Access.Get (Dense, 0, 0) = 0
         and then Dense.Depth = OpenCV.Core.UInt8,
         "dense conversion saturates");
      S.UInt8_Access.Set (Wide, (1 .. 11 => 0), 2);
      Assert
        (Wide.Convert_To (OpenCV.Core.Int32).Dimension_Count = 11
         and then Wide.Convert_To (OpenCV.Core.Int32).Stored_Element_Count = 1,
         "sparse conversion above dense capacity");
      if Module_Bridge_Probe.OpenCV_Major_Version >= 5 then
         begin
            Too_Wide;
            Assert (False, "OpenCV 5 dense capacity");
         exception
            when OpenCV.OpenCV_Error =>
               null;
         end;
      else
         Dense := Wide.To_Dense (OpenCV.Core.Int32, 1.0, 4.0);
         Assert
           (Dense.Dimension_Count = 11
            and then OpenCV.Core.Int32_Access.Get (Dense, (1 .. 11 => 0)) = 6,
            "OpenCV 4 accepts 11 dense dimensions");
      end if;
   end Dense_Capacity;

   procedure Float16_Rejected (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Half  : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Float16, 1));
      Float : constant S.Sparse_Mat :=
        S.Create ((2, 2), (OpenCV.Core.Float32, 1));
      Plain : OpenCV.Core.Mat;

      procedure Reject (Operation : not null access procedure) is
      begin
         Operation.all;
         Assert (False, "Float16 numeric conversion accepted");
      exception
         when OpenCV.OpenCV_Error =>
            null;
      end Reject;

      procedure From_Half is
         Ignored : constant S.Sparse_Mat :=
           Half.Convert_To (OpenCV.Core.Float32);
      begin
         Assert (not Ignored.Is_Allocated, "unexpected half source");
      end From_Half;

      procedure To_Half is
         Ignored : constant S.Sparse_Mat :=
           Float.Convert_To (OpenCV.Core.Float16);
      begin
         Assert (not Ignored.Is_Allocated, "unexpected half destination");
      end To_Half;

      procedure Dense_Half is
         Ignored : constant OpenCV.Core.Mat :=
           Half.To_Dense (OpenCV.Core.Float32, 1.0, 0.0);
      begin
         Assert (Ignored.Is_Empty, "unexpected half dense conversion");
      end Dense_Half;
   begin
      S.Float16_Access.Set
        (Half, (0, 1), OpenCV.Core.Float16_From_Bits (16#3C00#));
      Reject (From_Half'Access);
      Reject (To_Half'Access);
      Reject (Dense_Half'Access);
      Assert
        (OpenCV.Core.Float16_Bits (S.Float16_Access.Get (Half, (0, 1)))
         = 16#3C00#
         and then Half.Stored_Element_Count = 1,
         "rejection leaves exact Float16 bits");
      Plain := Half.To_Dense;
      Assert
        (Plain.Depth = OpenCV.Core.Float16
         and then OpenCV.Core.Float16_Bits
                    (OpenCV.Core.Float16_Access.Get (Plain, 0, 1))
                  = 16#3C00#,
         "plain To_Dense preserves Float16 bits");
   end Float16_Rejected;

   procedure Raw_Conversion (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Sizes  : aliased C.C_Int32_Array := (0 => 2, 1 => 2);
      Wide   : aliased C.C_Int32_Array (0 .. 10) := (others => 1);
      Source : aliased C.Sparse_Mat_Handle := C.Null_Sparse_Mat_Handle;
      Empty  : aliased C.Sparse_Mat_Handle := C.Null_Sparse_Mat_Handle;
      Sparse : aliased C.Sparse_Mat_Handle := C.Null_Sparse_Mat_Handle;
      Dense  : aliased C.Mat_Handle := C.Null_Mat_Handle;
      Index  : aliased C.C_Int32_Array := (0 => 1, 1 => 0);
      Value  : aliased C.C_Float32 := 0.0;
   begin
      Assert
        (C.Sparse_Convert_To_Sparse (Source, 5, 1.0, null)
         = C.Error_Invalid_Argument
         and then C.Sparse_Convert_To_Dense (Source, 5, 1.0, 0.0, null)
                  = C.Error_Invalid_Argument,
         "null numeric output");
      Assert
        (C.Sparse_Create (Empty'Access) = C.Success
         and then C.Sparse_Convert_To_Sparse (Empty, 5, 1.0, Sparse'Access)
                  = C.Error_Invalid_Argument
         and then Sparse = C.Null_Sparse_Mat_Handle
         and then C.Sparse_Convert_To_Dense (Empty, 5, 1.0, 0.0, Dense'Access)
                  = C.Error_Invalid_Argument
         and then Dense = C.Null_Mat_Handle
         and then C.Sparse_Convert_To_Sparse
                    (C.Null_Sparse_Mat_Handle, 5, 1.0, Sparse'Access)
                  = C.Error_Invalid_Argument
         and then Sparse = C.Null_Sparse_Mat_Handle,
         "unallocated numeric source");
      Assert
        (C.Sparse_Create_ND (2, Sizes (0)'Access, 5, 1, Source'Access)
         = C.Success
         and then C.Sparse_Set_Float32 (Source, 2, Index (0)'Access, 4.0)
                  = C.Success,
         "raw numeric source");
      Assert
        (C.Sparse_Convert_To_Sparse (Source, 99, 1.0, Sparse'Access)
         = C.Error_Invalid_Argument
         and then Sparse = C.Null_Sparse_Mat_Handle
         and then C.Sparse_Convert_To_Dense
                    (Source, -1, 1.0, 0.0, Dense'Access)
                  = C.Error_Invalid_Argument
         and then Dense = C.Null_Mat_Handle,
         "invalid depth initializes outputs");
      Assert
        (C.Sparse_Convert_To_Sparse (Source, 6, 2.0, Sparse'Access) = C.Success
         and then Sparse /= C.Null_Sparse_Mat_Handle
         and then C.Sparse_Convert_To_Dense (Source, 0, 1.0, 3.0, Dense'Access)
                  = C.Success
         and then Dense /= C.Null_Mat_Handle,
         "successful numeric handles");
      Assert
        (C.Sparse_Get_Float32 (Source, 2, Index (0)'Access, Value'Access)
         = C.Success
         and then Value = 4.0,
         "source remains valid");
      C.Sparse_Destroy (Sparse);
      Sparse := C.Null_Sparse_Mat_Handle;
      Assert
        (C.Sparse_Convert_To_Sparse (Source, 7, 1.0, Sparse'Access)
         = C.Error_OpenCV
         and then Sparse = C.Null_Sparse_Mat_Handle,
         "raw Float16 depth is an OpenCV failure");
      C.Sparse_Destroy (Source);
      C.Sparse_Destroy (Empty);
      C.Mat_Destroy (Dense);
      Source := C.Null_Sparse_Mat_Handle;
      Dense := C.Null_Mat_Handle;
      Assert
        (C.Sparse_Create_ND (11, Wide (0)'Access, 0, 1, Source'Access)
         = C.Success
         and then C.Sparse_Convert_To_Sparse (Source, 4, 1.0, Sparse'Access)
                  = C.Success,
         "raw 11D sparse conversion");
      if Module_Bridge_Probe.OpenCV_Major_Version >= 5 then
         Assert
           (C.Sparse_Convert_To_Dense (Source, 4, 1.0, 0.0, Dense'Access)
            = C.Error_Invalid_Argument
            and then Dense = C.Null_Mat_Handle,
            "raw OpenCV 5 dense capacity");
      else
         Assert
           (C.Sparse_Convert_To_Dense (Source, 4, 1.0, 0.0, Dense'Access)
            = C.Success
            and then Dense /= C.Null_Mat_Handle,
            "raw OpenCV 4 accepts 11D dense conversion");
      end if;
      C.Sparse_Destroy (Source);
      C.Sparse_Destroy (Sparse);
      C.Mat_Destroy (Dense);
   end Raw_Conversion;

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Sparse numeric identity and ownership", Identity'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse numeric scale retains zero nodes", Scale_To_Zero'Access));
      Result.Add_Test
        (Caller.Create ("Sparse numeric cross depth", Cross_Depth'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse numeric channels and dimensions",
            Channels_And_Dimensions'Access));
      Result.Add_Test
        (Caller.Create ("Sparse dense numeric offset", Dense_Offset'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse dense numeric identity and channels",
            Dense_Identity_And_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse dense numeric capacity", Dense_Capacity'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse numeric Float16 rejection", Float16_Rejected'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse raw numeric conversion", Raw_Conversion'Access));
      return Result'Access;
   end Suite;
end Sparse_Numeric_Tests;
