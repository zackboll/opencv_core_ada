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

package body Sparse_Extrema_Tests is
   package C renames OpenCV.Internal.C_API;
   package S renames OpenCV.Core.Sparse;
   use type C.Status;
   use type C.C_Float32;
   use type C.C_Int32;
   use type C.C_UInt8;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Index_Array;
   use type OpenCV.Core.Mat_Size;
   use type Interfaces.Integer_8;
   use type Interfaces.Integer_16;
   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_16;
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

   function Quotient (Numerator, Denominator : Long_Float) return Long_Float is
      pragma Suppress (Validity_Check);
   begin
      return Numerator / Denominator;
   end Quotient;

   function Quotient_32
     (Numerator, Denominator : Interfaces.IEEE_Float_32)
      return Interfaces.IEEE_Float_32
   is
      pragma Suppress (Validity_Check);
   begin
      return Numerator / Denominator;
   end Quotient_32;

   function Prefix
     (Location : OpenCV.Core.Index_Array; Count : Natural)
      return OpenCV.Core.Index_Array
   is (Location (1 .. Count));

   procedure Values_And_First_Tie (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      for Depth in OpenCV.Core.Float32 .. OpenCV.Core.Float64 loop
         declare
            Source : S.Sparse_Mat := S.Create ((3, 4), (Depth, 1));
            Result : S.Sparse_Extrema;
         begin
            if Depth = OpenCV.Core.Float32 then
               S.Float32_Access.Set (Source, (0, 3), -4.0);
               S.Float32_Access.Set (Source, (2, 1), 9.0);
               S.Float32_Access.Set (Source, (1, 0), 0.0);
               S.Float32_Access.Set (Source, (1, 2), -4.0);
               S.Float32_Access.Set (Source, (0, 1), 9.0);
            else
               S.Float64_Access.Set (Source, (0, 3), -4.0);
               S.Float64_Access.Set (Source, (2, 1), 9.0);
               S.Float64_Access.Set (Source, (1, 0), 0.0);
               S.Float64_Access.Set (Source, (1, 2), -4.0);
               S.Float64_Access.Set (Source, (0, 1), 9.0);
            end if;
            Result := Source.Min_Max_Loc;
            Assert
              (Result.Has_Minimum
               and then Result.Has_Maximum
               and then Near (Result.Minimum, -4.0)
               and then Near (Result.Maximum, 9.0)
               and then Result.Dimensions = 2
               and then (Prefix (Result.Minimum_Location, 2) = (0, 3)
                         or else Prefix (Result.Minimum_Location, 2) = (1, 2))
               and then (Prefix (Result.Maximum_Location, 2) = (0, 1)
                         or else Prefix (Result.Maximum_Location, 2) = (2, 1))
               and then not Source.Contains ((0, 0))
               and then Source.Contains ((1, 0))
               and then Source.Stored_Element_Count = 5,
               "equal extrema are one of the stored occurrences");
         end;
      end loop;
   end Values_And_First_Tie;

   procedure Empty_And_Explicit_Zero (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Empty        : constant S.Sparse_Mat :=
        S.Create ((2, 3), (OpenCV.Core.Float64, 1));
      Zeros        : S.Sparse_Mat :=
        S.Create ((2, 3), (OpenCV.Core.Float32, 1));
      Empty_Result : constant S.Sparse_Extrema := Empty.Min_Max_Loc;
      Zero_Result  : S.Sparse_Extrema;
   begin
      Assert
        (not Empty_Result.Has_Minimum
         and then not Empty_Result.Has_Maximum
         and then Empty_Result.Minimum = 0.0
         and then Empty_Result.Maximum = 0.0
         and then Empty.Stored_Element_Count = 0
         and then not Empty.Contains ((0, 0)),
         "no stored nodes means extrema were not found");
      S.Float32_Access.Set (Zeros, (1, 2), 0.0);
      S.Float32_Access.Set (Zeros, (0, 1), -0.0);
      Zero_Result := Zeros.Min_Max_Loc;
      Assert
        (Zero_Result.Has_Minimum
         and then Zero_Result.Has_Maximum
         and then Zero_Result.Minimum = 0.0
         and then Zero_Result.Maximum = 0.0
         and then (Prefix (Zero_Result.Minimum_Location, 2) = (1, 2)
                   or else Prefix (Zero_Result.Minimum_Location, 2) = (0, 1))
         and then (Prefix (Zero_Result.Maximum_Location, 2) = (1, 2)
                   or else Prefix (Zero_Result.Maximum_Location, 2) = (0, 1))
         and then Zeros.Stored_Element_Count = 2
         and then Zeros.Contains ((0, 1)),
         "explicit signed and unsigned zeros are both extrema");
   end Empty_And_Explicit_Zero;

   procedure Non_Finite (Test : in out Fixture) is
      pragma Suppress (Validity_Check);
      pragma Unreferenced (Test);
      Values : S.Sparse_Mat := S.Create ((2, 3), (OpenCV.Core.Float64, 1));
      Result : S.Sparse_Extrema;
   begin
      S.Float64_Access.Set (Values, (0, 0), 2.0);
      S.Float64_Access.Set
        (Values, (1, 2), Interfaces.IEEE_Float_64 (Quotient (1.0, 0.0)));
      S.Float64_Access.Set (Values, (0, 2), -3.0);
      Result := Values.Min_Max_Loc;
      Assert
        (Result.Has_Minimum
         and then Result.Has_Maximum
         and then Near (Result.Minimum, -3.0)
         and then Result.Maximum > Long_Float'Last
         and then Prefix (Result.Minimum_Location, 2) = (0, 2)
         and then Prefix (Result.Maximum_Location, 2) = (1, 2),
         "infinity participates and beats a finite maximum");
      S.Float64_Access.Set
        (Values, (0, 1), Interfaces.IEEE_Float_64 (Quotient (0.0, 0.0)));
      Result := Values.Min_Max_Loc;
      Assert
        (Result.Has_Minimum
         and then Result.Has_Maximum
         and then Near (Result.Minimum, -3.0)
         and then Result.Maximum > Long_Float'Last
         and then Prefix (Result.Minimum_Location, 2) = (0, 2)
         and then Prefix (Result.Maximum_Location, 2) = (1, 2),
         "NaN does not replace either finite extremum");
      declare
         Only_NaN : S.Sparse_Mat :=
           S.Create ((2, 2), (OpenCV.Core.Float32, 1));
      begin
         S.Float32_Access.Set (Only_NaN, (1, 0), Quotient_32 (0.0, 0.0));
         Result := Only_NaN.Min_Max_Loc;
         Assert
           (not Result.Has_Minimum
            and then not Result.Has_Maximum
            and then Result.Minimum = 0.0
            and then Result.Maximum = 0.0
            and then Prefix (Result.Minimum_Location, 2) = (0, 0)
            and then Prefix (Result.Maximum_Location, 2) = (0, 0)
            and then Only_NaN.Stored_Element_Count = 1
            and then Only_NaN.Contains ((1, 0)),
            "a lone NaN establishes neither extremum");
      end;
   end Non_Finite;

   procedure Higher_Dimensions (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Volume : S.Sparse_Mat :=
        S.Create ((2, 2, 2, 2, 2), (OpenCV.Core.Float32, 1));
      Wide   : S.Sparse_Mat :=
        S.Create ((1 .. 32 => 2), (OpenCV.Core.Float64, 1));
      Result : S.Sparse_Extrema;
   begin
      S.Float32_Access.Set (Volume, (0, 1, 0, 1, 0), -2.0);
      S.Float32_Access.Set (Volume, (1, 0, 1, 0, 1), 5.0);
      Result := Volume.Min_Max_Loc;
      Assert
        (Result.Has_Minimum
         and then Result.Has_Maximum
         and then Result.Dimensions = 5
         and then Near (Result.Minimum, -2.0)
         and then Near (Result.Maximum, 5.0)
         and then Prefix (Result.Minimum_Location, 5) = (0, 1, 0, 1, 0)
         and then Prefix (Result.Maximum_Location, 5) = (1, 0, 1, 0, 1)
         and then Volume.Stored_Element_Count = 2,
         "5-D extrema");
      S.Float64_Access.Set (Wide, (1 .. 32 => 1), 3.0);
      S.Float64_Access.Set (Wide, (1 .. 32 => 0), -4.0);
      Result := Wide.Min_Max_Loc;
      Assert
        (Result.Has_Minimum
         and then Result.Has_Maximum
         and then Result.Dimensions = 32
         and then Near (Result.Minimum, -4.0)
         and then Near (Result.Maximum, 3.0)
         and then Prefix (Result.Minimum_Location, 32) = (1 .. 32 => 0)
         and then Prefix (Result.Maximum_Location, 32) = (1 .. 32 => 1)
         and then Wide.Stored_Element_Count = 2,
         "32-D extrema");
   end Higher_Dimensions;

   procedure One_Sided_Boundaries (Test : in out Fixture) is
      pragma Suppress (Validity_Check);
      pragma Unreferenced (Test);

      function Positive_Infinity return Interfaces.IEEE_Float_64
      is (Interfaces.IEEE_Float_64 (Quotient (1.0, 0.0)));

      function Float32_Max return Interfaces.IEEE_Float_32
      is (Interfaces.IEEE_Float_32'Last);

      function Float64_Max return Interfaces.IEEE_Float_64
      is (Interfaces.IEEE_Float_64'Last);
   begin
      declare
         Positive : S.Sparse_Mat :=
           S.Create ((2, 2), (OpenCV.Core.Float64, 1));
         Negative : S.Sparse_Mat :=
           S.Create ((2, 2), (OpenCV.Core.Float32, 1));
         Result   : S.Sparse_Extrema;
      begin
         S.Float64_Access.Set (Positive, (1, 0), Positive_Infinity);
         Result := Positive.Min_Max_Loc;
         Assert
           (not Result.Has_Minimum
            and then Result.Has_Maximum
            and then Result.Minimum = 0.0
            and then Result.Maximum > Long_Float'Last
            and then Prefix (Result.Minimum_Location, 2) = (0, 0)
            and then Prefix (Result.Maximum_Location, 2) = (1, 0),
            "positive infinity establishes only the maximum");
         S.Float32_Access.Set (Negative, (0, 1), Quotient_32 (-1.0, 0.0));
         Result := Negative.Min_Max_Loc;
         Assert
           (Result.Has_Minimum
            and then not Result.Has_Maximum
            and then Result.Minimum
                     < -Long_Float (Interfaces.IEEE_Float_32'Last)
            and then Result.Maximum = 0.0
            and then Prefix (Result.Minimum_Location, 2) = (0, 1)
            and then Prefix (Result.Maximum_Location, 2) = (0, 0),
            "negative infinity establishes only the minimum");
      end;
      declare
         High   : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Float32, 1));
         Low    : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Float32, 1));
         Result : S.Sparse_Extrema;
      begin
         S.Float32_Access.Set (High, (1, 1), Float32_Max);
         Result := High.Min_Max_Loc;
         Assert
           (not Result.Has_Minimum
            and then Result.Has_Maximum
            and then Result.Minimum = 0.0
            and then Result.Maximum > 1.0e30
            and then Prefix (Result.Maximum_Location, 2) = (1, 1)
            and then Prefix (Result.Minimum_Location, 2) = (0, 0),
            "stored Float32 FLT_MAX establishes only the maximum");
         S.Float32_Access.Set (Low, (0, 1), -Float32_Max);
         Result := Low.Min_Max_Loc;
         Assert
           (Result.Has_Minimum
            and then not Result.Has_Maximum
            and then Result.Minimum < -1.0e30
            and then Result.Maximum = 0.0
            and then Prefix (Result.Minimum_Location, 2) = (0, 1)
            and then Prefix (Result.Maximum_Location, 2) = (0, 0),
            "stored Float32 -FLT_MAX establishes only the minimum");
      end;
      declare
         High   : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Float64, 1));
         Low    : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Float64, 1));
         Result : S.Sparse_Extrema;
      begin
         S.Float64_Access.Set (High, (0, 1), Float64_Max);
         Result := High.Min_Max_Loc;
         Assert
           (not Result.Has_Minimum
            and then Result.Has_Maximum
            and then Result.Minimum = 0.0
            and then Result.Maximum > 1.0e300
            and then Prefix (Result.Maximum_Location, 2) = (0, 1),
            "stored Float64 DBL_MAX establishes only the maximum");
         S.Float64_Access.Set (Low, (1, 0), -Float64_Max);
         Result := Low.Min_Max_Loc;
         Assert
           (Result.Has_Minimum
            and then not Result.Has_Maximum
            and then Result.Minimum < -1.0e300
            and then Result.Maximum = 0.0
            and then Prefix (Result.Minimum_Location, 2) = (1, 0),
            "stored Float64 -DBL_MAX establishes only the minimum");
      end;
   end One_Sided_Boundaries;

   procedure Does_Not_Mutate (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : S.Sparse_Mat := S.Create ((3, 3), (OpenCV.Core.Float64, 1));
      Alias  : S.Sparse_Mat;
      Result : S.Sparse_Extrema;
   begin
      S.Float64_Access.Set (Source, (2, 0), 4.0);
      S.Float64_Access.Set (Source, (0, 2), -1.0);
      Alias := Source;
      Result := Source.Min_Max_Loc;
      Assert
        (Result.Has_Minimum
         and then Result.Has_Maximum
         and then Near (Result.Minimum, -1.0)
         and then Alias.Stored_Element_Count = 2
         and then Alias.Contains ((2, 0))
         and then S.Float64_Access.Get (Alias, (0, 2)) = -1.0
         and then not Source.Contains ((1, 1)),
         "extrema do not create or modify nodes");
   end Does_Not_Mutate;

   procedure Rejected_Layouts (Test : in out Fixture) is
      pragma Unreferenced (Test);

      procedure Expect_Rejected (Source : S.Sparse_Mat) is
         Before : constant OpenCV.Core.Mat_Size :=
           (if Source.Is_Allocated then Source.Stored_Element_Count else 0);
      begin
         begin
            declare
               Ignored : constant S.Sparse_Extrema := Source.Min_Max_Loc;
            begin
               Assert
                 (not Ignored.Has_Minimum and then not Ignored.Has_Maximum,
                  "rejected extrema were found");
            end;
            Assert (False, "unsupported sparse extrema accepted");
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

   procedure Raw_Extrema (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Sizes   : aliased C.C_Int32_Array := (0 => 2, 1 => 3);
      Wide    : aliased C.C_Int32_Array (0 .. 31) := (others => 2);
      Source  : aliased C.Sparse_Mat_Handle := C.Null_Sparse_Mat_Handle;
      Empty   : aliased C.Sparse_Mat_Handle := C.Null_Sparse_Mat_Handle;
      Minimum : aliased C.C_Float64 := 99.0;
      Maximum : aliased C.C_Float64 := 99.0;
      Has_Min : aliased C.C_UInt8 := 7;
      Has_Max : aliased C.C_UInt8 := 7;
      Min_Idx : aliased C.C_Int32_Array (0 .. 31) := (others => 9);
      Max_Idx : aliased C.C_Int32_Array (0 .. 31) := (others => 9);
      Index   : aliased C.C_Int32_Array := (0 => 0, 1 => 2);
      Bits    : aliased C.C_UInt16 := 0;
   begin
      Assert
        (C.Sparse_Min_Max_Loc
           (C.Null_Sparse_Mat_Handle, null, null, null, null, 0, null, null)
         = C.Error_Invalid_Argument,
         "null outputs");
      Assert
        (C.Sparse_Create (Empty'Access) = C.Success
         and then C.Sparse_Min_Max_Loc
                    (C.Null_Sparse_Mat_Handle,
                     Minimum'Access,
                     Maximum'Access,
                     Min_Idx (0)'Access,
                     Max_Idx (0)'Access,
                     0,
                     Has_Min'Access,
                     Has_Max'Access)
                  = C.Error_Invalid_Argument
         and then Minimum = 0.0
         and then Maximum = 0.0
         and then Has_Min = 0
         and then Has_Max = 0
         and then C.Sparse_Min_Max_Loc
                    (Empty,
                     Minimum'Access,
                     Maximum'Access,
                     Min_Idx (0)'Access,
                     Max_Idx (0)'Access,
                     2,
                     Has_Min'Access,
                     Has_Max'Access)
                  = C.Error_Invalid_Argument,
         "null and unallocated sources");
      Minimum := 99.0;
      Maximum := 99.0;
      Has_Min := 7;
      Has_Max := 7;
      Min_Idx := (others => 9);
      Max_Idx := (others => 9);
      Assert
        (C.Sparse_Create_ND
           (2, Sizes (0)'Access, C.Depth_Float32, 1, Source'Access)
         = C.Success
         and then C.Sparse_Min_Max_Loc
                    (Source,
                     Minimum'Access,
                     Maximum'Access,
                     Min_Idx (0)'Access,
                     Max_Idx (0)'Access,
                     2,
                     Has_Min'Access,
                     Has_Max'Access)
                  = C.Success
         and then Has_Min = 0
         and then Has_Max = 0
         and then Minimum = 0.0
         and then Maximum = 0.0
         and then Min_Idx (0) = 0
         and then Max_Idx (1) = 0,
         "raw empty Float32 clears OpenCV sentinels and indices");
      Assert
        (C.Sparse_Set_Float32 (Source, 2, Index (0)'Access, -4.0) = C.Success
         and then C.Sparse_Min_Max_Loc
                    (Source,
                     Minimum'Access,
                     Maximum'Access,
                     Min_Idx (0)'Access,
                     Max_Idx (0)'Access,
                     1,
                     Has_Min'Access,
                     Has_Max'Access)
                  = C.Error_Invalid_Argument
         and then Minimum = 0.0
         and then Has_Min = 0
         and then Has_Max = 0
         and then C.Sparse_Min_Max_Loc
                    (Source,
                     Minimum'Access,
                     Maximum'Access,
                     Min_Idx (0)'Access,
                     Max_Idx (0)'Access,
                     2,
                     Has_Min'Access,
                     Has_Max'Access)
                  = C.Success
         and then Has_Min = 1
         and then Has_Max = 1
         and then Minimum = -4.0
         and then Maximum = -4.0
         and then Min_Idx (0) = 0
         and then Min_Idx (1) = 2
         and then Max_Idx (0) = 0
         and then Max_Idx (1) = 2,
         "raw Float32 extrema and index-count check");
      C.Sparse_Destroy (Source);
      Source := C.Null_Sparse_Mat_Handle;
      declare
         Integer_Depths : constant array (1 .. 5) of C.C_Int32 :=
           (C.Depth_UInt8,
            C.Depth_Int8,
            C.Depth_UInt16,
            C.Depth_Int16,
            C.Depth_Int32);
      begin
         for Depth of Integer_Depths loop
            Minimum := 99.0;
            Assert
              (C.Sparse_Create_ND
                 (2, Sizes (0)'Access, Depth, 1, Source'Access)
               = C.Success
               and then C.Sparse_Min_Max_Loc
                          (Source,
                           Minimum'Access,
                           Maximum'Access,
                           Min_Idx (0)'Access,
                           Max_Idx (0)'Access,
                           2,
                           Has_Min'Access,
                           Has_Max'Access)
                        = C.Error_OpenCV
               and then Minimum = 0.0
               and then Maximum = 0.0
               and then Has_Min = 0
               and then Has_Max = 0,
               "raw integer layout is an OpenCV failure");
            C.Sparse_Destroy (Source);
            Source := C.Null_Sparse_Mat_Handle;
         end loop;
      end;
      Assert
        (C.Sparse_Create_ND
           (2, Sizes (0)'Access, C.Depth_Float16, 1, Source'Access)
         = C.Success
         and then C.Sparse_Set_Float16 (Source, 2, Index (0)'Access, 16#3C00#)
                  = C.Success
         and then C.Sparse_Min_Max_Loc
                    (Source,
                     Minimum'Access,
                     Maximum'Access,
                     Min_Idx (0)'Access,
                     Max_Idx (0)'Access,
                     2,
                     Has_Min'Access,
                     Has_Max'Access)
                  = C.Error_OpenCV
         and then Has_Min = 0
         and then Has_Max = 0
         and then Minimum = 0.0
         and then C.Sparse_Get_Float16
                    (Source, 2, Index (0)'Access, Bits'Access)
                  = C.Success
         and then Bits = 16#3C00#,
         "raw Float16 failure leaves the source usable");
      C.Sparse_Destroy (Source);
      Source := C.Null_Sparse_Mat_Handle;
      Assert
        (C.Sparse_Create_ND
           (32, Wide (0)'Access, C.Depth_Float64, 1, Source'Access)
         = C.Success
         and then C.Sparse_Min_Max_Loc
                    (Source,
                     Minimum'Access,
                     Maximum'Access,
                     Min_Idx (0)'Access,
                     Max_Idx (0)'Access,
                     32,
                     Has_Min'Access,
                     Has_Max'Access)
                  = C.Success
         and then Has_Min = 0
         and then Has_Max = 0
         and then Minimum = 0.0
         and then Maximum = 0.0
         and then Min_Idx (31) = 0
         and then Max_Idx (31) = 0,
         "raw 32-D empty extrema");
      C.Sparse_Destroy (Source);
      C.Sparse_Destroy (Empty);
   end Raw_Extrema;

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Sparse stored extrema and first tie",
            Values_And_First_Tie'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse empty and explicit-zero extrema",
            Empty_And_Explicit_Zero'Access));
      Result.Add_Test
        (Caller.Create ("Sparse non-finite extrema", Non_Finite'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse 5-D and 32-D extrema", Higher_Dimensions'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse one-sided extrema boundaries",
            One_Sided_Boundaries'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse extrema do not mutate", Does_Not_Mutate'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse extrema layout rejection", Rejected_Layouts'Access));
      Result.Add_Test
        (Caller.Create ("Sparse raw extrema", Raw_Extrema'Access));
      return Result'Access;
   end Suite;
end Sparse_Extrema_Tests;
