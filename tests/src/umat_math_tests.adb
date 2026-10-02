with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Ada.Unchecked_Conversion;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Transfers;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Float32_Vec3_Access;
with OpenCV.Core.Float32_Vec3;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.Int16_Access;
with OpenCV.Internal.C_API;

package body UMat_Math_Tests is
   use OpenCV;
   use OpenCV.Core;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Integer_32;
   use type OpenCV.Internal.C_API.Status;
   use type OpenCV.Internal.C_API.UMat_Handle;
   package T renames OpenCV.Core.Transfers;
   package C renames OpenCV.Internal.C_API;
   subtype Fixture is Mat_Test_Support.Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;
   type Power_Array is array (Positive range <>) of Long_Float;

   function Use_OpenCL return Interfaces.Unsigned_8
   with Import, Convention => C, External_Name => "umat_probe_use_opencl";
   function Set_OpenCL
     (Enabled : Interfaces.Unsigned_8) return Interfaces.Unsigned_8
   with Import, Convention => C, External_Name => "umat_probe_set_opencl";

   procedure Check
     (Actual, Expected : Long_Float;
      Name             : String;
      Tolerance        : Long_Float := 0.000_01) is
   begin
      AUnit.Assertions.Assert (abs (Actual - Expected) <= Tolerance, Name);
   end Check;

   function Value (Image : UMat; Column : Natural := 0) return Long_Float is
      Host : constant Mat := T.To_Mat (Image);
   begin
      if Image.Depth = Float64 then
         return Long_Float (Float64_Access.Get (Host, 0, Column));
      elsif Image.Depth = UInt8 then
         return Long_Float (UInt8_Access.Get (Host, 0, Column));
      elsif Image.Depth = Int16 then
         return Long_Float (Int16_Access.Get (Host, 0, Column));
      else
         return Long_Float (Float32_Access.Get (Host, 0, Column));
      end if;
   end Value;

   procedure Normalize_Kinds (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Host  : Mat := Create (1, 2, (Float32, 1));
      Image : UMat;
   begin
      Float32_Access.Set (Host, 0, 0, 3.0);
      Float32_Access.Set (Host, 0, 1, 4.0);
      Image := T.To_UMat (Host);
      Check (Value (Normalize (Image, L1, 7.0)), 3.0, "L1");
      Check
        (abs Value (Normalize (Image, L1, 7.0))
         + abs Value (Normalize (Image, L1, 7.0), 1),
         7.0,
         "L1 sum");
      Check (Value (Normalize (Image, L2, 10.0)), 6.0, "L2");
      Check (Value (Normalize (Image, L2, 10.0), 1), 8.0, "L2 second");
      Check (Value (Normalize (Image, Infinity, 8.0), 1), 8.0, "Infinity");
      Check (Value (Normalize (Image, Min_Max, 2.0, 6.0)), 2.0, "MinMax min");
      Check
        (Value (Normalize (Image, Min_Max, 2.0, 6.0), 1), 6.0, "MinMax max");
      declare
         Integer_Image : UMat := Create_UMat (1, 2, (UInt8, 1));
      begin
         Integer_Image.Set_To (Make_Scalar (2.0));
         Check
           (Value (Normalize (Integer_Image, L1, 8.0)),
            4.0,
            "integer normalize");
      end;
   end Normalize_Kinds;

   procedure Unary_Values (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      for D in Float32 .. Float64 loop
         declare
            Host          : Mat := Create (1, 4, (D, 1));
            Image, Output : UMat;
         begin
            for I in 0 .. 3 loop
               if D = Float32 then
                  Float32_Access.Set (Host, 0, I, Float32_Value (I * I));
               else
                  Float64_Access.Set (Host, 0, I, Float64_Value (I * I));
               end if;
            end loop;
            Image := T.To_UMat (Host);
            Output := Sqrt (Image);
            for I in 0 .. 3 loop
               Check (Value (Output, I), Long_Float (I), "sqrt values");
            end loop;
            Image.Set_To (Make_Scalar (1.0));
            Check (Value (Output, 3), 3.0, "independent sqrt");
            Output := Exp (Image);
            Check (Value (Output), 2.718_281_828_459, "exp one");
            Check (Value (Log (Output)), 1.0, "log e");
            Check (Value (Log (Image)), 0.0, "log one");
            Image.Set_To (Make_Scalar (0.0));
            Check (Value (Exp (Image)), 1.0, "exp zero");
            Image.Set_To (Make_Scalar (4.0));
            Check (Value (Pow (Image, 1.5)), 8.0, "fractional pow");
            Check (Value (Pow (Image, -1.0)), 0.25, "negative pow");
            AUnit.Assertions.Assert
              (Output.Depth = D
               and then Output.Rows = 1
               and then Output.Columns = 4
               and then Output.Channels = 1,
               "unary metadata");
         end;
      end loop;
   end Unary_Values;

   procedure Integer_Pow (Test : in out Fixture) is
      pragma Unreferenced (Test);
      A : UMat := Create_UMat (1, 1, (UInt8, 1));
      B : UMat := Create_UMat (1, 1, (Int16, 1));
   begin
      A.Set_To (Make_Scalar (20.0));
      Check (Value (Pow (A, 2.0)), 255.0, "UInt8 saturation");
      B.Set_To (Make_Scalar (-3.0));
      Check (Value (Pow (B, 3.0)), -27.0, "integer sign");
      Check (Value (Pow (B, 0.0)), 1.0, "zero power");
      Check (Value (Pow (B, 1.0)), -3.0, "one power");
   end Integer_Pow;

   procedure Sqrt_Special_Values (Test : in out Fixture) is
      pragma Unreferenced (Test);
      --  Deliberate IEEE NaN/Infinity operands, as in existing special tests.
      pragma Suppress (Validity_Check);
      function Bits is new
        Ada.Unchecked_Conversion (Interfaces.Unsigned_32, Float32_Value);
      Host   : Mat := Create (1, 3, (Float32, 1));
      Output : Mat;
      V      : Float32_Value;
      use type Float32_Value;
   begin
      Float32_Access.Set (Host, 0, 0, -4.0);
      Float32_Access.Set (Host, 0, 1, Bits (16#FF80_0000#));
      Float32_Access.Set (Host, 0, 2, Bits (16#7F80_0000#));
      Output := T.To_Mat (Sqrt (T.To_UMat (Host)));
      for I in 0 .. 1 loop
         V := Float32_Access.Get (Output, 0, I);
         AUnit.Assertions.Assert (V /= V, "negative sqrt is NaN");
      end loop;
      V := Float32_Access.Get (Output, 0, 2);
      AUnit.Assertions.Assert (V = Bits (16#7F80_0000#), "positive infinity");
   end Sqrt_Special_Values;

   procedure Channels_And_Regions (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Host                                              : Mat :=
        Create (2, 4, (Float32, 3));
      Parent, View, Root, Power_Result, Normalized, Mag : UMat;
      Polar                                             :
        UMat_Polar_Coordinates;
   begin
      for R in 0 .. 1 loop
         for Col in 0 .. 3 loop
            Float32_Vec3_Access.Set (Host, R, Col, (1.0, 4.0, 9.0));
         end loop;
      end loop;
      Parent := T.To_UMat (Host);
      View := Parent.Region ((1, 0, 2, 2));
      AUnit.Assertions.Assert (not View.Is_Continuous, "strided region");
      Root := Sqrt (View);
      Power_Result := Pow (View, 2.0);
      Normalized := Normalize (View, Infinity, 9.0);
      Mag := Magnitude (View, View);
      Polar := Cart_To_Polar (View, View);
      declare
         R  : constant Mat := T.To_Mat (Root);
         P  : constant Mat := T.To_Mat (Power_Result);
         E  : constant Mat := T.To_Mat (Log (View));
         M  : constant Mat := T.To_Mat (Mag);
         V  : constant Mat := T.To_Mat (View);
         RV : constant OpenCV.Core.Float32_Vec3.Vector :=
           Float32_Vec3_Access.Get (R, 0, 0);
         PV : constant OpenCV.Core.Float32_Vec3.Vector :=
           Float32_Vec3_Access.Get (P, 0, 0);
         EV : constant OpenCV.Core.Float32_Vec3.Vector :=
           Float32_Vec3_Access.Get (E, 0, 0);
         MV : constant OpenCV.Core.Float32_Vec3.Vector :=
           Float32_Vec3_Access.Get (M, 0, 0);
      begin
         for I in 0 .. 2 loop
            Check (Long_Float (RV (I)), Long_Float (I + 1), "C3 sqrt");
            Check (Long_Float (PV (I)), Long_Float ((I + 1)**4), "C3 pow");
            Check
              (Long_Float (MV (I)),
               Long_Float ((I + 1) * (I + 1)) * 1.414_213_562,
               "C3 magnitude");
         end loop;
         Check (Long_Float (EV (0)), 0.0, "C3 log one");
         Check (Long_Float (EV (1)), 1.386_294_361, "C3 log four");
         Check (Long_Float (EV (2)), 2.197_224_577, "C3 log nine");
         declare
            Angle_Host     : constant Mat := T.To_Mat (Polar.Angle);
            Magnitude_Host : constant Mat := T.To_Mat (Polar.Magnitude);
         begin
            for I in 0 .. 2 loop
               Check
                 (Long_Float (Float32_Vec3_Access.Get (Angle_Host, 0, 0) (I)),
                  0.785_398_163,
                  "C3 region angle",
                  0.001);
               Check
                 (Long_Float
                    (Float32_Vec3_Access.Get (Magnitude_Host, 0, 0) (I)),
                  Long_Float (MV (I)),
                  "C3 combined magnitude");
            end loop;
         end;
         Check
           (Long_Float (Float32_Vec3_Access.Get (V, 0, 0) (2)),
            9.0,
            "source unchanged");
      end;
      Parent.Set_To (Make_Scalar (0.0));
      AUnit.Assertions.Assert
        (Root.Channels = 3
         and then Power_Result.Channels = 3
         and then Mag.Channels = 3
         and then Polar.Angle.Channels = 3,
         "C3 metadata");
      declare
         N : constant Mat := T.To_Mat (Normalized);
         R : constant Mat := T.To_Mat (Root);
      begin
         Check
           (Long_Float (Float32_Vec3_Access.Get (N, 0, 0) (2)),
            9.0,
            "normalize region independent");
         Check
           (Long_Float (Float32_Vec3_Access.Get (R, 0, 0) (2)),
            3.0,
            "sqrt region independent");
      end;
   end Channels_And_Regions;

   procedure Vector_And_Polar (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      for D in Float32 .. Float64 loop
         declare
            X : UMat := Create_UMat (1, 1, (D, 1));
            Y : UMat := Create_UMat (1, 1, (D, 1));
            P : UMat_Polar_Coordinates;
            R : UMat_Cartesian_Coordinates;
         begin
            X.Set_To (Make_Scalar (3.0));
            Y.Set_To (Make_Scalar (4.0));
            Check (Value (Magnitude (X, Y)), 5.0, "3 4 5");
            for Units in Angle_Unit loop
               P := Cart_To_Polar (X, Y, Units);
               Check
                 (Value (P.Magnitude),
                  Value (Magnitude (X, Y)),
                  "combined magnitude");
               Check
                 (Value (P.Angle),
                  Value (Phase (X, Y, Units)),
                  "combined phase",
                  0.01);
               R := Polar_To_Cart (P.Magnitude, P.Angle, Units);
               Check (Value (R.X), 3.0, "round trip X", 0.002);
               Check (Value (R.Y), 4.0, "round trip Y", 0.002);
            end loop;
            P.Magnitude.Set_To (Make_Scalar (0.0));
            AUnit.Assertions.Assert
              (Value (P.Angle) > 0.0, "polar fields independent");
            X.Set_To (Make_Scalar (0.0));
            Y.Set_To (Make_Scalar (1.0));
            Check (Value (Phase (X, Y, Degrees)), 90.0, "degrees", 0.01);
            Check (Value (Phase (X, Y)), 1.570_796_327, "radians", 0.001);
            Y.Set_To (Make_Scalar (0.0));
            Check (Value (Phase (X, Y)), 0.0, "zero vector");
            R := Polar_To_Cart (Y);
            Check (Value (R.X), 1.0, "angle only X");
            Check (Value (R.Y), 0.0, "angle only Y");
            declare
               Empty : constant UMat := Create_UMat (0, 0, (UInt8, 3));
            begin
               R := Polar_To_Cart (Empty, Y);
               Check (Value (R.X), 1.0, "typed empty unit magnitude");
            end;
            R.X.Set_To (Make_Scalar (7.0));
            Check (Value (R.Y), 0.0, "cartesian fields independent");
         end;
      end loop;
   end Vector_And_Polar;

   procedure ND_Unary (Test : in out Fixture) is
      pragma Unreferenced (Test);
      A : UMat := Create_UMat ((2, 2, 2), (Float32, 1));
      B : UMat;
   begin
      A.Set_To (Make_Scalar (4.0));
      B := Sqrt (A);
      AUnit.Assertions.Assert (B.Shape = A.Shape, "N-D sqrt shape");
      declare
         Host : constant Mat := T.To_Mat (B);
      begin
         Check
           (Long_Float (Float32_Access.Get (Host, Index_Array'(1, 1, 1))),
            2.0,
            "N-D sqrt value");
      end;
      B := Exp (A);
      AUnit.Assertions.Assert (B.Shape = A.Shape, "N-D exp shape");
      declare
         Host : constant Mat := T.To_Mat (B);
      begin
         Check
           (Long_Float (Float32_Access.Get (Host, Index_Array'(1, 0, 1))),
            54.598_150,
            "N-D exp value",
            0.001);
      end;
      B := Log (A);
      AUnit.Assertions.Assert (B.Shape = A.Shape, "N-D log shape");
      declare
         Host : constant Mat := T.To_Mat (B);
      begin
         Check
           (Long_Float (Float32_Access.Get (Host, Index_Array'(0, 1, 1))),
            1.386_294_361,
            "N-D log value");
      end;
      B := Pow (A, 3.0);
      AUnit.Assertions.Assert (B.Shape = A.Shape, "N-D pow shape");
      declare
         Host : constant Mat := T.To_Mat (B);
      begin
         Check
           (Long_Float (Float32_Access.Get (Host, Index_Array'(1, 1, 0))),
            64.0,
            "N-D pow value");
      end;
      B := Normalize (A, Infinity, 8.0);
      AUnit.Assertions.Assert (B.Shape = A.Shape, "N-D normalize shape");
   end ND_Unary;

   procedure Empty_Results (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Default : UMat;
      A       : constant UMat := Create_UMat (0, 0, (Float32, 3));
      B       : UMat;
      P       : UMat_Polar_Coordinates;
      R       : UMat_Cartesian_Coordinates;
      procedure Typed (Image : UMat) is
      begin
         AUnit.Assertions.Assert
           (Image.Is_Empty
            and then Image.Dimension_Count = 2
            and then Image.Shape = A.Shape
            and then Image.Depth = Float32
            and then Image.Channels = 3,
            "typed empty metadata");
      end Typed;
   begin
      Typed (Sqrt (A));
      Typed (Exp (A));
      Typed (Log (A));
      for Power of Power_Array'(0.0, 1.0, 2.0, 3.0, -1.0, 0.5) loop
         Typed (Pow (A, Power));
      end loop;
      B := Pow (Default, 2.0);
      AUnit.Assertions.Assert (B.Dimension_Count = 0, "default empty pow");
      Typed (Magnitude (A, A));
      Typed (Phase (A, A));
      P := Cart_To_Polar (A, A);
      Typed (P.Magnitude);
      Typed (P.Angle);
      R := Polar_To_Cart (A);
      Typed (R.X);
      Typed (R.Y);
      for Kind in Normalize_Kind loop
         B := Normalize (A, Kind);
         AUnit.Assertions.Assert
           (B.Is_Empty and then B.Dimension_Count = 0,
            "normalize matches Mat empty release");
      end loop;
   end Empty_Results;

   procedure Invalid_Inputs (Test : in out Fixture) is
      pragma Unreferenced (Test);
      A : constant UMat := Create_UMat (2, 2, (Float32, 1));
      B : UMat;
      P : UMat_Polar_Coordinates;
      R : UMat_Cartesian_Coordinates;
      type Invalid_Kind is
        (Half,
         Half_Magnitude,
         Integer_Sqrt,
         Integer_Exp,
         Integer_Log,
         Default_Sqrt,
         Default_Negative_Pow,
         Default_Fraction_Pow,
         Polar_Mismatch,
         Integer_Fraction,
         Integer_Negative,
         Rows_Mismatch,
         Columns_Mismatch,
         Depth_Mismatch,
         Channel_Mismatch,
         ND_Magnitude,
         ND_Phase,
         ND_Polar,
         Angle_Integer);
   begin
      for Kind in Invalid_Kind loop
         begin
            case Kind is
               when Half_Magnitude
               =>
                  B := Magnitude (Create_UMat (2, 2, (Float16, 1)), A);

               when Integer_Sqrt
               =>
                  B := Sqrt (Create_UMat (1, 1, (UInt8, 1)));

               when Integer_Exp
               =>
                  B := Exp (Create_UMat (1, 1, (UInt8, 1)));

               when Integer_Log
               =>
                  B := Log (Create_UMat (1, 1, (UInt8, 1)));

               when Default_Sqrt | Default_Negative_Pow | Default_Fraction_Pow
               =>
                  declare
                     Empty : UMat;
                  begin
                     case Kind is
                        when Default_Sqrt         =>
                           B := Sqrt (Empty);

                        when Default_Negative_Pow =>
                           B := Pow (Empty, -1.0);

                        when others               =>
                           B := Pow (Empty, 0.5);
                     end case;
                  end;

               when Polar_Mismatch
               =>
                  R := Polar_To_Cart (Create_UMat (1, 2, (Float32, 1)), A);

               when Half
               =>
                  B := Pow (Create_UMat (1, 1, (Float16, 1)), 2.0);

               when Integer_Fraction
               =>
                  B := Pow (Create_UMat (1, 1, (UInt8, 1)), 0.5);

               when Integer_Negative
               =>
                  B := Pow (Create_UMat (1, 1, (UInt8, 1)), -1.0);

               when Rows_Mismatch
               =>
                  B := Magnitude (A, Create_UMat (1, 2, (Float32, 1)));

               when Columns_Mismatch
               =>
                  B := Magnitude (A, Create_UMat (2, 1, (Float32, 1)));

               when Depth_Mismatch
               =>
                  B := Magnitude (A, Create_UMat (2, 2, (Float64, 1)));

               when Channel_Mismatch
               =>
                  B := Magnitude (A, Create_UMat (2, 2, (Float32, 3)));

               when ND_Magnitude
               =>
                  B := Magnitude (Create_UMat ((2, 2, 2), (Float32, 1)), A);

               when ND_Phase
               =>
                  B := Phase (Create_UMat ((2, 2, 2), (Float32, 1)), A);

               when ND_Polar
               =>
                  P :=
                    Cart_To_Polar (Create_UMat ((2, 2, 2), (Float32, 1)), A);

               when Angle_Integer
               =>
                  R := Polar_To_Cart (Create_UMat (1, 1, (UInt8, 1)));
            end case;
            AUnit.Assertions.Assert
              (B.Is_Empty
               and then P.Angle.Is_Empty
               and then R.X.Is_Empty
               and then False,
               "invalid input accepted");
         exception
            when OpenCV_Error =>
               null;
         end;
      end loop;
   end Invalid_Inputs;

   procedure Raw_ABI (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source, First, Second : aliased C.UMat_Handle := C.Null_UMat_Handle;
      Status                : C.Status;
      Rows                  : aliased C.C_Int32 := 0;
      procedure Rejected is
      begin
         AUnit.Assertions.Assert
           (Status /= C.Success and then First = C.Null_UMat_Handle,
            "ABI failure clears first");
      end Rejected;
   begin
      Status := C.UMat_Sqrt (C.Null_UMat_Handle, null);
      AUnit.Assertions.Assert (Status /= C.Success, "null output");
      Status := C.UMat_Sqrt (C.Null_UMat_Handle, First'Access);
      Rejected;
      Status := C.UMat_Create_2D (1, 1, 5, 1, Source'Access);
      AUnit.Assertions.Assert (Status = C.Success, "raw create");
      First := Source;
      Status := C.UMat_Normalize (Source, -1, 1.0, 0.0, First'Access);
      Rejected;
      Status := C.UMat_Phase (Source, Source, 2, First'Access);
      Rejected;
      Status :=
        C.UMat_Cart_To_Polar (Source, Source, 0, First'Access, First'Access);
      Rejected;
      First := Source;
      Second := Source;
      Status :=
        C.UMat_Cart_To_Polar
          (C.Null_UMat_Handle, Source, 0, First'Access, Second'Access);
      Rejected;
      AUnit.Assertions.Assert (Second = C.Null_UMat_Handle, "clear second");
      First := Source;
      Second := Source;
      Status :=
        C.UMat_Polar_To_Cart (Source, Source, 2, First'Access, Second'Access);
      Rejected;
      AUnit.Assertions.Assert (Second = C.Null_UMat_Handle, "clear second");
      Status := C.UMat_Sqrt (Source, First'Access);
      AUnit.Assertions.Assert
        (Status = C.Success and then First /= C.Null_UMat_Handle,
         "unary publication");
      C.UMat_Destroy (First);
      First := C.Null_UMat_Handle;
      Status :=
        C.UMat_Cart_To_Polar (Source, Source, 0, First'Access, Second'Access);
      AUnit.Assertions.Assert
        (Status = C.Success
         and then First /= C.Null_UMat_Handle
         and then Second /= C.Null_UMat_Handle
         and then First /= Second,
         "dual publication");
      C.UMat_Destroy (Source);
      Source := C.Null_UMat_Handle;
      Status := C.UMat_Rows (First, Rows'Access);
      AUnit.Assertions.Assert (Status = C.Success, "first survives source");
      Status := C.UMat_Rows (Second, Rows'Access);
      AUnit.Assertions.Assert (Status = C.Success, "second survives source");
      C.UMat_Destroy (First);
      C.UMat_Destroy (Second);
      First := C.Null_UMat_Handle;
      Second := C.Null_UMat_Handle;
      Status := C.UMat_Create_2D (1, 1, 5, 1, Source'Access);
      AUnit.Assertions.Assert (Status = C.Success, "raw recreate");
      Status :=
        C.UMat_Polar_To_Cart (Source, Source, 0, First'Access, Second'Access);
      AUnit.Assertions.Assert
        (Status = C.Success
         and then First /= C.Null_UMat_Handle
         and then Second /= C.Null_UMat_Handle,
         "polar publication");
      C.UMat_Destroy (Source);
      Source := C.Null_UMat_Handle;
      Status := C.UMat_Rows (First, Rows'Access);
      AUnit.Assertions.Assert (Status = C.Success, "polar survives source");
      C.UMat_Destroy (First);
      C.UMat_Destroy (Second);
   exception
      when others =>
         C.UMat_Destroy (Source);
         C.UMat_Destroy (First);
         C.UMat_Destroy (Second);
         raise;
   end Raw_ABI;

   procedure OpenCL_Disabled (Test : in out Fixture) is
      Previous : constant Interfaces.Unsigned_8 := Use_OpenCL;
      Success  : Interfaces.Unsigned_8;
   begin
      Success := Set_OpenCL (0);
      AUnit.Assertions.Assert (Success = 1, "disable OpenCL");
      Normalize_Kinds (Test);
      Unary_Values (Test);
      Integer_Pow (Test);
      Vector_And_Polar (Test);
      Success := Set_OpenCL (Previous);
      AUnit.Assertions.Assert (Success = 1, "restore OpenCL");
   exception
      when others =>
         Success := Set_OpenCL (Previous);
         raise;
   end OpenCL_Disabled;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create ("UMat normalize kinds", Normalize_Kinds'Access));
      Result.Add_Test
        (Caller.Create ("UMat unary values", Unary_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat sqrt special values", Sqrt_Special_Values'Access));
      Result.Add_Test (Caller.Create ("UMat integer Pow", Integer_Pow'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat channels and Regions", Channels_And_Regions'Access));
      Result.Add_Test
        (Caller.Create ("UMat vectors and polar", Vector_And_Polar'Access));
      Result.Add_Test (Caller.Create ("UMat N-D unary", ND_Unary'Access));
      Result.Add_Test
        (Caller.Create ("UMat math empty results", Empty_Results'Access));
      Result.Add_Test
        (Caller.Create ("UMat math invalid inputs", Invalid_Inputs'Access));
      Result.Add_Test
        (Caller.Create ("UMat math OpenCL disabled", OpenCL_Disabled'Access));
      Result.Add_Test (Caller.Create ("UMat math raw ABI", Raw_ABI'Access));
      return Result'Access;
   end Suite;
end UMat_Math_Tests;
