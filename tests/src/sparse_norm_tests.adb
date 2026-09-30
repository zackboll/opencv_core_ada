with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV.Core;
with OpenCV.Core.Sparse;
with OpenCV.Core.Sparse.Float16_Access;
with OpenCV.Core.Sparse.Float32_Access;
with OpenCV.Core.Sparse.Float32_Vec2_Access;
with OpenCV.Core.Sparse.Float64_Access;
with OpenCV.Core.Sparse.Float64_Vec2_Access;
with OpenCV.Core.Sparse.Int16_Access;
with OpenCV.Core.Sparse.Int32_Access;
with OpenCV.Core.Sparse.Int8_Access;
with OpenCV.Core.Sparse.UInt16_Access;
with OpenCV.Core.Sparse.UInt8_Access;
with OpenCV.Core.Float32_Vec2;
with OpenCV.Internal.C_API;

package body Sparse_Norm_Tests is
   package C renames OpenCV.Internal.C_API;
   package S renames OpenCV.Core.Sparse;
   use type C.Status;
   use type C.Sparse_Mat_Handle;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Dimension_Array;
   use type OpenCV.Core.Mat_Size;
   use type OpenCV.Core.Norm_Kind;
   use type Interfaces.Integer_8;
   use type Interfaces.Integer_16;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.IEEE_Float_32;
   use type Interfaces.IEEE_Float_64;
   use type OpenCV.Core.Float32_Vec2.Vector;
   use Mat_Test_Support;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      AUnit.Assertions.Assert (Condition, Message);
   end Assert;

   function Near (Left, Right : Long_Float) return Boolean
   is (abs (Left - Right) <= 1.0e-5);

   function Stored
     (Source : S.Sparse_Mat; Indices : OpenCV.Core.Index_Array)
      return Long_Float
   is (if Source.Depth = OpenCV.Core.Float32
       then Long_Float (S.Float32_Access.Get (Source, Indices))
       else Long_Float (S.Float64_Access.Get (Source, Indices)));

   procedure Norm_Values (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      for Depth in OpenCV.Core.Float32 .. OpenCV.Core.Float64 loop
         declare
            Source : S.Sparse_Mat := S.Create ((3, 4), (Depth, 1));
         begin
            if Depth = OpenCV.Core.Float32 then
               S.Float32_Access.Set (Source, (0, 0), 3.0);
               S.Float32_Access.Set (Source, (0, 2), -4.0);
               S.Float32_Access.Set (Source, (1, 1), 0.0);
            else
               S.Float64_Access.Set (Source, (0, 0), 3.0);
               S.Float64_Access.Set (Source, (0, 2), -4.0);
               S.Float64_Access.Set (Source, (1, 1), 0.0);
            end if;
            Assert
              (not Source.Contains ((0, 1))
               and then Source.Contains ((1, 1))
               and then Source.Stored_Element_Count = 3
               and then Near (Source.Norm (OpenCV.Core.L1), 7.0)
               and then Near (Source.Norm (OpenCV.Core.L2), 5.0)
               and then Near (Source.Norm, 5.0)
               and then Near (Source.Norm (OpenCV.Core.Infinity), 4.0)
               and then Near (Stored (Source, (0, 0)), 3.0)
               and then Near (Stored (Source, (1, 1)), 0.0),
               "stored-node norms ignore missing cells");
         end;
      end loop;
   end Norm_Values;

   procedure Empty_And_Zero (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Empty      : constant S.Sparse_Mat :=
        S.Create ((2, 3), (OpenCV.Core.Float64, 1));
      Zeros      : S.Sparse_Mat := S.Create ((4, 4), (OpenCV.Core.Float32, 1));
      Normalized : S.Sparse_Mat;
   begin
      Assert
        (Empty.Stored_Element_Count = 0
         and then Empty.Norm = 0.0
         and then Empty.Norm (OpenCV.Core.L1) = 0.0
         and then Empty.Norm (OpenCV.Core.Infinity) = 0.0,
         "empty allocated norm is zero");
      Normalized := Empty.Normalize (Target_Norm => 10.0);
      Assert
        (Normalized.Is_Allocated
         and then Normalized.Stored_Element_Count = 0
         and then Normalized.Shape = Empty.Shape
         and then Normalized.Depth = OpenCV.Core.Float64
         and then Normalized.Channels = 1,
         "empty normalization stays empty");
      S.Float32_Access.Set (Zeros, (0, 3), 0.0);
      S.Float32_Access.Set (Zeros, (2, 1), 0.0);
      Assert
        (Zeros.Stored_Element_Count = 2
         and then Zeros.Norm (OpenCV.Core.L1) = 0.0
         and then Zeros.Norm (OpenCV.Core.L2) = 0.0
         and then Zeros.Norm (OpenCV.Core.Infinity) = 0.0,
         "explicit zeros have zero norms");
      Normalized :=
        Zeros.Normalize (Target_Norm => 4.0, Kind => OpenCV.Core.L1);
      Assert
        (Normalized.Stored_Element_Count = 2
         and then Normalized.Contains ((0, 3))
         and then Normalized.Contains ((2, 1))
         and then not Normalized.Contains ((0, 0))
         and then Stored (Normalized, (0, 3)) = 0.0
         and then Stored (Normalized, (2, 1)) = 0.0
         and then Zeros.Stored_Element_Count = 2,
         "zero-norm normalization retains stored zeros");
   end Empty_And_Zero;

   procedure Normalization (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      for Depth in OpenCV.Core.Float32 .. OpenCV.Core.Float64 loop
         declare
            Source : S.Sparse_Mat := S.Create ((2, 3), (Depth, 1));
            Scaled : S.Sparse_Mat;
         begin
            if Depth = OpenCV.Core.Float32 then
               S.Float32_Access.Set (Source, (0, 0), 3.0);
               S.Float32_Access.Set (Source, (1, 2), 4.0);
            else
               S.Float64_Access.Set (Source, (0, 0), 3.0);
               S.Float64_Access.Set (Source, (1, 2), 4.0);
            end if;
            Scaled := Source.Normalize (Target_Norm => 10.0);
            Assert
              (Near (Stored (Scaled, (0, 0)), 6.0)
               and then Near (Stored (Scaled, (1, 2)), 8.0)
               and then not Scaled.Contains ((0, 1))
               and then Scaled.Stored_Element_Count = 2
               and then Near (Scaled.Norm, 10.0)
               and then Scaled.Shape = Source.Shape
               and then Scaled.Depth = Depth,
               "L2 normalization");
            Scaled :=
              Source.Normalize (Target_Norm => 14.0, Kind => OpenCV.Core.L1);
            Assert
              (Near (Stored (Scaled, (0, 0)), 6.0)
               and then Near (Stored (Scaled, (1, 2)), 8.0)
               and then Near (Scaled.Norm (OpenCV.Core.L1), 14.0),
               "L1 normalization");
            Scaled :=
              Source.Normalize
                (Target_Norm => 8.0, Kind => OpenCV.Core.Infinity);
            Assert
              (Near (Stored (Scaled, (0, 0)), 6.0)
               and then Near (Stored (Scaled, (1, 2)), 8.0)
               and then Near (Scaled.Norm (OpenCV.Core.Infinity), 8.0),
               "infinity normalization");
            Scaled := Source.Normalize (Target_Norm => -10.0);
            Assert
              (Near (Stored (Scaled, (0, 0)), -6.0)
               and then Near (Stored (Scaled, (1, 2)), -8.0)
               and then Near (Scaled.Norm, 10.0),
               "negative target reverses signs");
         end;
      end loop;
   end Normalization;

   procedure Ownership (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : S.Sparse_Mat := S.Create ((3, 3), (OpenCV.Core.Float64, 1));
      Scaled : S.Sparse_Mat;
   begin
      S.Float64_Access.Set (Source, (0, 2), 3.0);
      S.Float64_Access.Set (Source, (2, 0), 4.0);
      Scaled := Source.Normalize (Target_Norm => 10.0);
      S.Float64_Access.Set (Source, (0, 2), 30.0);
      S.Float64_Access.Set (Scaled, (2, 0), 80.0);
      Assert
        (Near (Stored (Scaled, (0, 2)), 6.0)
         and then Near (Stored (Source, (2, 0)), 4.0)
         and then Source.Stored_Element_Count = 2
         and then Scaled.Stored_Element_Count = 2,
         "normalization storage is independent");
   end Ownership;

   procedure Higher_Dimensions (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Volume : S.Sparse_Mat :=
        S.Create ((2, 2, 2, 2, 2), (OpenCV.Core.Float32, 1));
      Wide   : S.Sparse_Mat :=
        S.Create ((1 .. 32 => 2), (OpenCV.Core.Float64, 1));
      Scaled : S.Sparse_Mat;
   begin
      S.Float32_Access.Set (Volume, (0, 1, 0, 1, 0), 3.0);
      S.Float32_Access.Set (Volume, (1, 0, 1, 0, 1), 4.0);
      Scaled := Volume.Normalize (Target_Norm => 5.0, Kind => OpenCV.Core.L1);
      Assert
        (Scaled.Dimension_Count = 5
         and then Scaled.Contains ((0, 1, 0, 1, 0))
         and then Scaled.Contains ((1, 0, 1, 0, 1))
         and then not Scaled.Contains ((0, 0, 0, 0, 0))
         and then Near (Stored (Scaled, (0, 1, 0, 1, 0)), 15.0 / 7.0)
         and then Near (Stored (Scaled, (1, 0, 1, 0, 1)), 20.0 / 7.0)
         and then Near (Scaled.Norm (OpenCV.Core.L1), 5.0),
         "5-D normalization preserves topology");
      S.Float64_Access.Set (Wide, (1 .. 32 => 1), 3.0);
      S.Float64_Access.Set (Wide, (1 .. 32 => 0), -4.0);
      Scaled := Wide.Normalize;
      Assert
        (Scaled.Dimension_Count = 32
         and then Scaled.Stored_Element_Count = 2
         and then Scaled.Contains ((1 .. 32 => 1))
         and then Scaled.Contains ((1 .. 32 => 0))
         and then Near (Scaled.Norm, 1.0)
         and then Near (Stored (Scaled, (1 .. 32 => 1)), 0.6)
         and then Near (Stored (Scaled, (1 .. 32 => 0)), -0.8),
         "32-D normalization");
   end Higher_Dimensions;

   procedure Rejected_Layouts (Test : in out Fixture) is
      pragma Unreferenced (Test);

      procedure Expect_Rejected (Source : S.Sparse_Mat) is
         Before : constant OpenCV.Core.Mat_Size :=
           (if Source.Is_Allocated then Source.Stored_Element_Count else 0);
      begin
         begin
            declare
               Ignored : constant Long_Float := Source.Norm;
            begin
               Assert (Ignored = 0.0, "rejected norm returned a value");
            end;
            Assert (False, "unsupported sparse norm accepted");
         exception
            when OpenCV.OpenCV_Error =>
               null;
         end;
         begin
            declare
               Ignored : constant S.Sparse_Mat := Source.Normalize;
            begin
               Assert (not Ignored.Is_Allocated, "rejected normalize");
            end;
            Assert (False, "unsupported sparse normalization accepted");
         exception
            when OpenCV.OpenCV_Error =>
               null;
         end;
         Assert
           ((if Source.Is_Allocated
             then Source.Stored_Element_Count = Before
             else not Source.Is_Allocated),
            "rejection changes stored-node count");
      end Expect_Rejected;
   begin
      declare
         Bytes   : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.UInt8, 1));
         Signed  : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Int8, 1));
         Words   : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.UInt16, 1));
         Shorts  : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Int16, 1));
         Cells   : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Int32, 1));
         Half    : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Float16, 1));
         Color   : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Float32, 2));
         Pairs   : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Float64, 2));
         Missing : S.Sparse_Mat;
      begin
         S.UInt8_Access.Set (Bytes, (0, 1), 3);
         S.Int8_Access.Set (Signed, (0, 1), -3);
         S.UInt16_Access.Set (Words, (0, 1), 3);
         S.Int16_Access.Set (Shorts, (0, 1), -4);
         S.Int32_Access.Set (Cells, (0, 1), 5);
         S.Float16_Access.Set
           (Half, (0, 1), OpenCV.Core.Float16_From_Bits (16#3C00#));
         S.Float32_Vec2_Access.Set (Color, (1, 0), (3.0, 4.0));
         S.Float64_Vec2_Access.Set (Pairs, (1, 0), (3.0, 4.0));
         Expect_Rejected (Bytes);
         Expect_Rejected (Signed);
         Expect_Rejected (Words);
         Expect_Rejected (Shorts);
         Expect_Rejected (Cells);
         Expect_Rejected (Half);
         Expect_Rejected (Color);
         Expect_Rejected (Pairs);
         Expect_Rejected (Missing);
         Assert
           (S.UInt8_Access.Get (Bytes, (0, 1)) = 3
            and then S.Int16_Access.Get (Shorts, (0, 1)) = -4
            and then OpenCV.Core.Float16_Bits
                       (S.Float16_Access.Get (Half, (0, 1)))
                     = 16#3C00#
            and then S.Float32_Vec2_Access.Get (Color, (1, 0)) = (3.0, 4.0)
            and then Pairs.Stored_Element_Count = 1,
            "rejection does not mutate stored values");
      end;
   end Rejected_Layouts;

   procedure Raw_Norm (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Sizes  : aliased C.C_Int32_Array := (0 => 2, 1 => 3);
      Wide   : aliased C.C_Int32_Array (0 .. 31) := (others => 2);
      Source : aliased C.Sparse_Mat_Handle := C.Null_Sparse_Mat_Handle;
      Empty  : aliased C.Sparse_Mat_Handle := C.Null_Sparse_Mat_Handle;
      Output : aliased C.Sparse_Mat_Handle := C.Null_Sparse_Mat_Handle;
      Index  : aliased C.C_Int32_Array := (0 => 0, 1 => 2);
      Bits   : aliased C.C_UInt16 := 0;
      Result : aliased C.C_Float64 := 99.0;
   begin
      Assert
        (C.Sparse_Norm (C.Null_Sparse_Mat_Handle, C.Norm_L2, null)
         = C.Error_Invalid_Argument
         and then C.Sparse_Normalize
                    (C.Null_Sparse_Mat_Handle, 1.0, C.Norm_L2, null)
                  = C.Error_Invalid_Argument,
         "null outputs");
      Assert
        (C.Sparse_Create (Empty'Access) = C.Success
         and then C.Sparse_Norm
                    (C.Null_Sparse_Mat_Handle, C.Norm_L2, Result'Access)
                  = C.Error_Invalid_Argument
         and then Result = 0.0
         and then C.Sparse_Norm (Empty, C.Norm_L1, Result'Access)
                  = C.Error_Invalid_Argument
         and then Result = 0.0
         and then C.Sparse_Normalize (Empty, 1.0, C.Norm_L2, Output'Access)
                  = C.Error_Invalid_Argument
         and then Output = C.Null_Sparse_Mat_Handle,
         "null and unallocated sources");
      Assert
        (C.Sparse_Create_ND
           (2, Sizes (0)'Access, C.Depth_Float32, 1, Source'Access)
         = C.Success
         and then C.Sparse_Set_Float32 (Source, 2, Index (0)'Access, 3.0)
                  = C.Success,
         "raw float source");
      Result := 99.0;
      Assert
        (C.Sparse_Norm (Source, 99, Result'Access) = C.Error_Invalid_Argument
         and then Result = 0.0
         and then C.Sparse_Normalize (Source, 1.0, 0, Output'Access)
                  = C.Error_Invalid_Argument
         and then Output = C.Null_Sparse_Mat_Handle
         and then C.Sparse_Norm (Source, C.Norm_L1, Result'Access) = C.Success
         and then Result = 3.0,
         "invalid kind and successful Float32 norm");
      C.Sparse_Destroy (Source);
      Source := C.Null_Sparse_Mat_Handle;
      Assert
        (C.Sparse_Create_ND
           (2, Sizes (0)'Access, C.Depth_Float64, 1, Source'Access)
         = C.Success
         and then C.Sparse_Set_Float64 (Source, 2, Index (0)'Access, -4.0)
                  = C.Success
         and then C.Sparse_Normalize (Source, 2.0, C.Norm_Inf, Output'Access)
                  = C.Success
         and then Output /= C.Null_Sparse_Mat_Handle
         and then C.Sparse_Get_Float64
                    (Source, 2, Index (0)'Access, Result'Access)
                  = C.Success
         and then Result = -4.0,
         "successful Float64 normalization leaves source usable");
      C.Sparse_Destroy (Output);
      Output := C.Null_Sparse_Mat_Handle;
      C.Sparse_Destroy (Source);
      Source := C.Null_Sparse_Mat_Handle;
      for Depth in C.Depth_UInt8 .. C.Depth_Int32 loop
         Result := 99.0;
         Assert
           (C.Sparse_Create_ND (2, Sizes (0)'Access, Depth, 1, Source'Access)
            = C.Success
            and then C.Sparse_Norm (Source, C.Norm_L2, Result'Access)
                     = C.Error_OpenCV
            and then Result = 0.0
            and then C.Sparse_Normalize (Source, 1.0, C.Norm_L2, Output'Access)
                     = C.Error_OpenCV
            and then Output = C.Null_Sparse_Mat_Handle,
            "raw integer layout is an OpenCV failure");
         C.Sparse_Destroy (Source);
         Source := C.Null_Sparse_Mat_Handle;
      end loop;
      Assert
        (C.Sparse_Create_ND
           (2, Sizes (0)'Access, C.Depth_Float16, 1, Source'Access)
         = C.Success
         and then C.Sparse_Set_Float16 (Source, 2, Index (0)'Access, 16#3C00#)
                  = C.Success
         and then C.Sparse_Norm (Source, C.Norm_Inf, Result'Access)
                  = C.Error_OpenCV
         and then Result = 0.0
         and then C.Sparse_Normalize (Source, 1.0, C.Norm_L1, Output'Access)
                  = C.Error_OpenCV
         and then Output = C.Null_Sparse_Mat_Handle
         and then C.Sparse_Get_Float16
                    (Source, 2, Index (0)'Access, Bits'Access)
                  = C.Success
         and then Bits = 16#3C00#,
         "raw Float16 failure leaves the source usable");
      C.Sparse_Destroy (Source);
      Source := C.Null_Sparse_Mat_Handle;
      Assert
        (C.Sparse_Create_ND
           (32, Wide (0)'Access, C.Depth_Float32, 1, Source'Access)
         = C.Success
         and then C.Sparse_Norm (Source, C.Norm_L2, Result'Access) = C.Success
         and then Result = 0.0
         and then C.Sparse_Normalize (Source, 1.0, C.Norm_L2, Output'Access)
                  = C.Success
         and then Output /= C.Null_Sparse_Mat_Handle,
         "raw 32-D norm and normalization");
      C.Sparse_Destroy (Source);
      C.Sparse_Destroy (Empty);
      C.Sparse_Destroy (Output);
   end Raw_Norm;

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create ("Sparse stored-node norm values", Norm_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse empty and explicit-zero norms", Empty_And_Zero'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse norm-based normalization", Normalization'Access));
      Result.Add_Test
        (Caller.Create ("Sparse normalization ownership", Ownership'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse 5-D and 32-D normalization", Higher_Dimensions'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse norm layout rejection", Rejected_Layouts'Access));
      Result.Add_Test
        (Caller.Create ("Sparse raw norm and normalization", Raw_Norm'Access));
      return Result'Access;
   end Suite;
end Sparse_Norm_Tests;
