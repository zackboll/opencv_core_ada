with AUnit.Assertions;
with AUnit.Test_Caller;
with Ada.Numerics.Long_Elementary_Functions;
with Interfaces;
with Mat_Test_Support;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;

package body Polynomial_Tests is

   package Caller is new AUnit.Test_Caller (Mat_Test_Support.Mat_Test_Fixture);

   use type Interfaces.IEEE_Float_32;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use Mat_Test_Support;

   type Values is array (Natural range <>) of Long_Float;

   type Complex_Value is record
      Real      : Long_Float;
      Imaginary : Long_Float;
   end record;

   function Coefficients
     (Input  : Values;
      Column : Boolean := False;
      Depth  : OpenCV.Core.Depth_Type := OpenCV.Core.Float32)
      return OpenCV.Core.Mat
   is
      Result : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => (if Column then Input'Length else 1),
           Columns      => (if Column then 1 else Input'Length),
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
   begin
      for Index in Input'Range loop
         OpenCV.Core.Float32_Access.Set
           (Result,
            Row    => (if Column then Index - Input'First else 0),
            Column => (if Column then 0 else Index - Input'First),
            Value  => Interfaces.IEEE_Float_32 (Input (Index)));
      end loop;
      return
        (if Depth = OpenCV.Core.Float32
         then Result
         else Result.Convert_To (Depth));
   end Coefficients;

   function Complex_Coefficients
     (Real, Imaginary : Values;
      Depth           : OpenCV.Core.Depth_Type := OpenCV.Core.Float32)
      return OpenCV.Core.Mat
   is
      Real_Part      : constant OpenCV.Core.Mat :=
        Coefficients (Real, Depth => Depth);
      Imaginary_Part : constant OpenCV.Core.Mat :=
        Coefficients (Imaginary, Depth => Depth);
   begin
      return OpenCV.Core.Merge ((Real_Part, Imaginary_Part));
   end Complex_Coefficients;

   function Roots
     (Result : OpenCV.Core.Polynomial_Solution_Result)
      return OpenCV.Core.Mat_Array
   is (Result.Roots.Convert_To (OpenCV.Core.Float32).Split);

   function Root
     (Result : OpenCV.Core.Polynomial_Solution_Result; Index : Natural)
      return Complex_Value
   is
      Parts : constant OpenCV.Core.Mat_Array := Roots (Result);
   begin
      return
        (Real      =>
           Long_Float (OpenCV.Core.Float32_Access.Get (Parts (0), Index, 0)),
         Imaginary =>
           Long_Float (OpenCV.Core.Float32_Access.Get (Parts (1), Index, 0)));
   end Root;

   function Add (Left, Right : Complex_Value) return Complex_Value
   is ((Left.Real + Right.Real, Left.Imaginary + Right.Imaginary));

   function Multiply (Left, Right : Complex_Value) return Complex_Value
   is ((Left.Real * Right.Real - Left.Imaginary * Right.Imaginary,
        Left.Real * Right.Imaginary + Left.Imaginary * Right.Real));

   function Magnitude (Value : Complex_Value) return Long_Float
   is (Ada.Numerics.Long_Elementary_Functions.Sqrt
         (Value.Real * Value.Real + Value.Imaginary * Value.Imaginary));

   procedure Assert_Residuals
     (Result    : OpenCV.Core.Polynomial_Solution_Result;
      Input     : Values;
      Tolerance : Long_Float) is
   begin
      for Index in 0 .. Result.Roots.Rows - 1 loop
         declare
            Value : Complex_Value := (0.0, 0.0);
            X     : constant Complex_Value := Root (Result, Index);
         begin
            for Coefficient of reverse Input loop
               Value := Add (Multiply (Value, X), (Coefficient, 0.0));
            end loop;
            AUnit.Assertions.Assert
              (Magnitude (Value) <= Tolerance,
               "Each Solve_Polynomial root must satisfy its polynomial");
         end;
      end loop;
   end Assert_Residuals;

   procedure Assert_Contains
     (Result    : OpenCV.Core.Polynomial_Solution_Result;
      Expected  : Complex_Value;
      Tolerance : Long_Float)
   is
      Found : Boolean := False;
   begin
      for Index in 0 .. Result.Roots.Rows - 1 loop
         declare
            Actual : constant Complex_Value := Root (Result, Index);
         begin
            Found :=
              Found
              or else Magnitude
                        ((Actual.Real - Expected.Real,
                          Actual.Imaginary - Expected.Imaginary))
                      <= Tolerance;
         end;
      end loop;
      AUnit.Assertions.Assert
        (Found, "Solve_Polynomial must contain each root");
   end Assert_Contains;

   procedure Real_And_Complex_Quadratics (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Real_Input     : constant Values := (2.0, -3.0, 1.0);
      Complex_Input  : constant Values := (1.0, 0.0, 1.0);
      Real_Result    : constant OpenCV.Core.Polynomial_Solution_Result :=
        OpenCV.Core.Solve_Polynomial (Coefficients (Real_Input));
      Complex_Result : constant OpenCV.Core.Polynomial_Solution_Result :=
        OpenCV.Core.Solve_Polynomial (Coefficients (Complex_Input));
   begin
      AUnit.Assertions.Assert
        (Real_Result.Roots.Rows = 2
         and then Real_Result.Roots.Columns = 1
         and then Real_Result.Roots.Depth = OpenCV.Core.Float32
         and then Real_Result.Roots.Channels = 2,
         "Solve_Polynomial roots must be an N x 1 Float32 C2 Mat");
      Assert_Contains (Real_Result, (1.0, 0.0), 1.0E-4);
      Assert_Contains (Real_Result, (2.0, 0.0), 1.0E-4);
      Assert_Residuals (Real_Result, Real_Input, 1.0E-4);
      Assert_Contains (Complex_Result, (0.0, 1.0), 1.0E-4);
      Assert_Contains (Complex_Result, (0.0, -1.0), 1.0E-4);
      Assert_Residuals (Complex_Result, Complex_Input, 1.0E-4);
      AUnit.Assertions.Assert
        (Complex_Result.Maximum_Correction >= 0.0
         and then Complex_Result.Maximum_Correction < 1.0E-5,
         "Solve_Polynomial must return a small final maximum correction");
   end Real_And_Complex_Quadratics;

   procedure Cubic_And_Quartic_Order (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Cubic_Input    : constant Values := (-6.0, 11.0, -6.0, 1.0);
      Quartic_Input  : constant Values := (0.0, 0.0, -1.0, 0.0, 1.0);
      Cubic_Result   : constant OpenCV.Core.Polynomial_Solution_Result :=
        OpenCV.Core.Solve_Polynomial
          (Coefficients (Cubic_Input, Column => True));
      Quartic_Result : constant OpenCV.Core.Polynomial_Solution_Result :=
        OpenCV.Core.Solve_Polynomial (Coefficients (Quartic_Input));
   begin
      Assert_Contains (Cubic_Result, (1.0, 0.0), 1.0E-3);
      Assert_Contains (Cubic_Result, (2.0, 0.0), 1.0E-3);
      Assert_Contains (Cubic_Result, (3.0, 0.0), 1.0E-3);
      Assert_Residuals (Cubic_Result, Cubic_Input, 1.0E-3);
      Assert_Contains (Quartic_Result, (-1.0, 0.0), 1.0E-4);
      Assert_Contains (Quartic_Result, (0.0, 0.0), 1.0E-4);
      Assert_Contains (Quartic_Result, (1.0, 0.0), 1.0E-4);
      Assert_Residuals (Quartic_Result, Quartic_Input, 1.0E-4);
   end Cubic_And_Quartic_Order;

   procedure Repeated_And_Complex_Coefficients (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Repeated_Input : constant Values := (1.0, -2.0, 1.0);
      Repeated       : constant OpenCV.Core.Polynomial_Solution_Result :=
        OpenCV.Core.Solve_Polynomial (Coefficients (Repeated_Input));
      Complex_Result : constant OpenCV.Core.Polynomial_Solution_Result :=
        OpenCV.Core.Solve_Polynomial
          (Complex_Coefficients ((-1.0, 0.0), (0.0, 1.0)));
   begin
      Assert_Contains (Repeated, (1.0, 0.0), 1.0E-3);
      Assert_Residuals (Repeated, Repeated_Input, 1.0E-3);
      Assert_Contains (Complex_Result, (0.0, -1.0), 1.0E-3);
      AUnit.Assertions.Assert
        (Complex_Result.Roots.Channels = 2,
         "Complex coefficients must retain complex roots");
   end Repeated_And_Complex_Coefficients;

   procedure Depths_Views_And_Independent_Result
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      View           : constant OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 0, Width => 1, Height => 3));
      Float64_Result : constant OpenCV.Core.Polynomial_Solution_Result :=
        OpenCV.Core.Solve_Polynomial
          (Coefficients ((2.0, -3.0, 1.0), Depth => OpenCV.Core.Float64));
      Result         : OpenCV.Core.Polynomial_Solution_Result;
   begin
      OpenCV.Core.Float32_Access.Set (Parent, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set
        (Parent, 1, 1, Interfaces.IEEE_Float_32'(-3.0));
      OpenCV.Core.Float32_Access.Set (Parent, 2, 1, 1.0);
      AUnit.Assertions.Assert
        (not View.Is_Continuous
         and then Float64_Result.Roots.Depth = OpenCV.Core.Float64,
         "Solve_Polynomial must support Float64 and non-contiguous Regions");
      Assert_Contains (Float64_Result, (1.0, 0.0), 1.0E-10);
      Assert_Contains (Float64_Result, (2.0, 0.0), 1.0E-10);
      Assert_Residuals (Float64_Result, (2.0, -3.0, 1.0), 1.0E-10);
      Result := OpenCV.Core.Solve_Polynomial (View, Maximum_Iterations => 50);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 1, 99.0);
      Assert_Contains (Result, (1.0, 0.0), 1.0E-4);
      Assert_Contains (Result, (2.0, 0.0), 1.0E-4);
   end Depths_Views_And_Independent_Result;

   procedure Degenerate_And_Invalid_Inputs (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      procedure Empty is
         Input   : OpenCV.Core.Mat;
         Ignored : constant OpenCV.Core.Polynomial_Solution_Result :=
           OpenCV.Core.Solve_Polynomial (Input);
      begin
         pragma Unreferenced (Ignored);
      end Empty;
      procedure Typed_Empty is
         Ignored : constant OpenCV.Core.Polynomial_Solution_Result :=
           OpenCV.Core.Solve_Polynomial
             (OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1)));
      begin
         pragma Unreferenced (Ignored);
      end Typed_Empty;
      procedure Square is
         Ignored : constant OpenCV.Core.Polynomial_Solution_Result :=
           OpenCV.Core.Solve_Polynomial
             (OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1)));
      begin
         pragma Unreferenced (Ignored);
      end Square;
      procedure Integer is
         Ignored : constant OpenCV.Core.Polynomial_Solution_Result :=
           OpenCV.Core.Solve_Polynomial
             (OpenCV.Core.Create (1, 2, (OpenCV.Core.Int32, 1)));
      begin
         pragma Unreferenced (Ignored);
      end Integer;
      procedure Float16 is
         Ignored : constant OpenCV.Core.Polynomial_Solution_Result :=
           OpenCV.Core.Solve_Polynomial
             (OpenCV.Core.Create (1, 2, (OpenCV.Core.Float16, 1)));
      begin
         pragma Unreferenced (Ignored);
      end Float16;
      procedure Channels is
         Ignored : constant OpenCV.Core.Polynomial_Solution_Result :=
           OpenCV.Core.Solve_Polynomial
             (OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 3)));
      begin
         pragma Unreferenced (Ignored);
      end Channels;
      procedure All_Zero is
         Ignored : constant OpenCV.Core.Polynomial_Solution_Result :=
           OpenCV.Core.Solve_Polynomial (Coefficients ((0.0, 0.0, 0.0)));
      begin
         pragma Unreferenced (Ignored);
      end All_Zero;
      Leading_Zero : constant OpenCV.Core.Polynomial_Solution_Result :=
        OpenCV.Core.Solve_Polynomial (Coefficients ((2.0, -3.0, 1.0, 0.0)));
   begin
      Assert_Contains (Leading_Zero, (1.0, 0.0), 1.0E-4);
      Assert_Contains (Leading_Zero, (2.0, 0.0), 1.0E-4);
      AUnit.Assertions.Assert
        (Leading_Zero.Roots.Rows = 3,
         "Leading zeros must preserve OpenCV's original-degree root shape");
      Assert_Raises_OpenCV_Error
        (Empty'Access, "Must reject default empty Mat");
      Assert_Raises_OpenCV_Error
        (Typed_Empty'Access, "Must reject typed empty Mat");
      Assert_Raises_OpenCV_Error (Square'Access, "Must reject non-vectors");
      Assert_Raises_OpenCV_Error
        (Integer'Access, "Must reject integer coefficients");
      Assert_Raises_OpenCV_Error
        (Float16'Access, "Must reject Float16 coefficients");
      Assert_Raises_OpenCV_Error
        (Channels'Access, "Must reject more than two channels");
      Assert_Raises_OpenCV_Error
        (All_Zero'Access, "Must reject all-zero polynomials");
   end Degenerate_And_Invalid_Inputs;

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Solve_Polynomial real and complex quadratics",
            Real_And_Complex_Quadratics'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve_Polynomial cubic and quartic coefficient order",
            Cubic_And_Quartic_Order'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve_Polynomial repeated and complex coefficients",
            Repeated_And_Complex_Coefficients'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve_Polynomial depths views and independent results",
            Depths_Views_And_Independent_Result'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve_Polynomial degenerate and invalid inputs",
            Degenerate_And_Invalid_Inputs'Access));
      return Result'Access;
   end Suite;

end Polynomial_Tests;
