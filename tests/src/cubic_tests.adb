with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;

package body Cubic_Tests is

   package Caller is new AUnit.Test_Caller (Mat_Test_Support.Mat_Test_Fixture);

   use type Interfaces.IEEE_Float_32;
   use type OpenCV.Core.Cubic_Root_Status;
   use type OpenCV.Core.Depth_Type;
   use Mat_Test_Support;

   type Coefficient_Values is
     array (Natural range <>) of Interfaces.IEEE_Float_32;

   function Coefficients
     (Values : Coefficient_Values; Column : Boolean := False)
      return OpenCV.Core.Mat
   is
      Result : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => (if Column then Values'Length else 1),
           Columns      => (if Column then 1 else Values'Length),
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
   begin
      for Index in Values'Range loop
         OpenCV.Core.Float32_Access.Set
           (Result,
            Row    => (if Column then Index - Values'First else 0),
            Column => (if Column then 0 else Index - Values'First),
            Value  => Values (Index));
      end loop;
      return Result;
   end Coefficients;

   function Root_Value
     (Result : OpenCV.Core.Cubic_Solution_Result; Index : Natural)
      return Long_Float
   is
      Roots : constant OpenCV.Core.Mat :=
        Result.Roots.Convert_To (OpenCV.Core.Float32);
   begin
      return Long_Float (OpenCV.Core.Float32_Access.Get (Roots, Index, 0));
   end Root_Value;

   function Roots_Image
     (Result : OpenCV.Core.Cubic_Solution_Result) return String is
   begin
      case Result.Status is
         when OpenCV.Core.Infinitely_Many_Roots | OpenCV.Core.No_Real_Roots =>
            return "(none)";

         when OpenCV.Core.One_Real_Root                                     =>
            return Root_Value (Result, 0)'Image;

         when OpenCV.Core.Two_Real_Roots                                    =>
            return
              Root_Value (Result, 0)'Image
              & ","
              & Root_Value (Result, 1)'Image;

         when OpenCV.Core.Three_Real_Roots                                  =>
            return
              Root_Value (Result, 0)'Image
              & ","
              & Root_Value (Result, 1)'Image
              & ","
              & Root_Value (Result, 2)'Image;
      end case;
   end Roots_Image;

   function Reported_Root_Count
     (Result : OpenCV.Core.Cubic_Solution_Result) return Natural is
   begin
      case Result.Status is
         when OpenCV.Core.Infinitely_Many_Roots | OpenCV.Core.No_Real_Roots =>
            return 0;

         when OpenCV.Core.One_Real_Root                                     =>
            return 1;

         when OpenCV.Core.Two_Real_Roots                                    =>
            return 2;

         when OpenCV.Core.Three_Real_Roots                                  =>
            return 3;
      end case;
   end Reported_Root_Count;

   procedure Assert_Contains_Root
     (Result    : OpenCV.Core.Cubic_Solution_Result;
      Value     : Long_Float;
      Count     : Natural;
      Tolerance : Long_Float)
   is
      Found : Boolean := False;
   begin
      for Offset in 1 .. Count loop
         Found :=
           Found
           or else Approximately_Equal
                     (Root_Value (Result, Offset - 1), Value, Tolerance);
      end loop;
      AUnit.Assertions.Assert
        (Found,
         "Solve_Cubic must report expected root"
         & Value'Image
         & "; status="
         & Result.Status'Image
         & " roots=["
         & Roots_Image (Result)
         & "]");
   end Assert_Contains_Root;

   procedure Assert_Residuals
     (Result    : OpenCV.Core.Cubic_Solution_Result;
      Values    : Coefficient_Values;
      Count     : Natural;
      Monic     : Boolean;
      Tolerance : Long_Float) is
   begin
      for Offset in 1 .. Count loop
         declare
            X             : constant Long_Float :=
              Root_Value (Result, Offset - 1);
            Leading       : constant Long_Float :=
              (if Monic then 1.0 else Long_Float (Values (Values'First)));
            Quadratic     : constant Long_Float :=
              Long_Float (Values (Values'First + (if Monic then 0 else 1)));
            Linear        : constant Long_Float :=
              Long_Float (Values (Values'First + (if Monic then 1 else 2)));
            Constant_Term : constant Long_Float :=
              Long_Float (Values (Values'First + (if Monic then 2 else 3)));
         begin
            AUnit.Assertions.Assert
              (abs (((Leading * X + Quadratic) * X + Linear)
                    * X
                    + Constant_Term)
               <= Tolerance,
               "Solve_Cubic residual too large for root"
               & X'Image
               & "; status="
               & Result.Status'Image
               & " roots=["
               & Roots_Image (Result)
               & "]");
         end;
      end loop;
   end Assert_Residuals;

   procedure Three_And_Monic_Roots (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Four_Values  : constant Coefficient_Values := (1.0, -6.0, 11.0, -6.0);
      Monic_Values : constant Coefficient_Values := (-6.0, 11.0, -6.0);
      Four_Result  : constant OpenCV.Core.Cubic_Solution_Result :=
        OpenCV.Core.Solve_Cubic (Coefficients (Four_Values));
      Monic_Result : constant OpenCV.Core.Cubic_Solution_Result :=
        OpenCV.Core.Solve_Cubic (Coefficients (Monic_Values, Column => True));
   begin
      AUnit.Assertions.Assert
        (Four_Result.Status = OpenCV.Core.Three_Real_Roots
         and then Monic_Result.Status = OpenCV.Core.Three_Real_Roots,
         "Four-element and monic cubic forms must report three real roots");
      Assert_Contains_Root (Four_Result, 1.0, 3, 1.0E-5);
      Assert_Contains_Root (Four_Result, 2.0, 3, 1.0E-5);
      Assert_Contains_Root (Four_Result, 3.0, 3, 1.0E-5);
      Assert_Residuals (Four_Result, Four_Values, 3, False, 1.0E-4);
      Assert_Residuals (Monic_Result, Monic_Values, 3, True, 1.0E-4);
   end Three_And_Monic_Roots;

   procedure Distinct_Root_Counts_And_Float64 (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      One_Values    : constant Coefficient_Values := (1.0, 0.0, 0.0, 1.0);
      Two_Values    : constant Coefficient_Values := (1.0, -4.0, 5.0, -2.0);
      Triple_Values : constant Coefficient_Values := (1.0, -6.0, 12.0, -8.0);
      One_Result    : constant OpenCV.Core.Cubic_Solution_Result :=
        OpenCV.Core.Solve_Cubic (Coefficients (One_Values));
      Two_Result    : constant OpenCV.Core.Cubic_Solution_Result :=
        OpenCV.Core.Solve_Cubic (Coefficients (Two_Values, Column => True));
      Triple_Result : constant OpenCV.Core.Cubic_Solution_Result :=
        OpenCV.Core.Solve_Cubic
          (Coefficients (Triple_Values).Convert_To (OpenCV.Core.Float64));
   begin
      AUnit.Assertions.Assert
        (One_Result.Status = OpenCV.Core.One_Real_Root,
         "x^3 + 1 expected One_Real_Root, got "
         & One_Result.Status'Image
         & " roots=["
         & Roots_Image (One_Result)
         & "]");
      AUnit.Assertions.Assert
        (Reported_Root_Count (Two_Result) >= 2,
         "(x-1)^2 (x-2) expected at least two reported roots, got "
         & Two_Result.Status'Image
         & " roots=["
         & Roots_Image (Two_Result)
         & "]");
      AUnit.Assertions.Assert
        (Reported_Root_Count (Triple_Result) >= 1,
         "(x-2)^3 expected at least one reported root, got "
         & Triple_Result.Status'Image
         & " roots=["
         & Roots_Image (Triple_Result)
         & "]");
      Assert_Contains_Root
        (One_Result, -1.0, Reported_Root_Count (One_Result), 1.0E-5);
      Assert_Contains_Root
        (Two_Result, 1.0, Reported_Root_Count (Two_Result), 1.0E-5);
      Assert_Contains_Root
        (Two_Result, 2.0, Reported_Root_Count (Two_Result), 1.0E-5);
      for Offset in 1 .. Reported_Root_Count (Triple_Result) loop
         AUnit.Assertions.Assert
           (Approximately_Equal
              (Root_Value (Triple_Result, Offset - 1), 2.0, 1.0E-10),
            "(x-2)^3 reported root must be ~2, got"
            & Root_Value (Triple_Result, Offset - 1)'Image
            & "; status="
            & Triple_Result.Status'Image
            & " roots=["
            & Roots_Image (Triple_Result)
            & "]");
      end loop;
      Assert_Residuals
        (One_Result,
         One_Values,
         Reported_Root_Count (One_Result),
         False,
         1.0E-4);
      Assert_Residuals
        (Two_Result,
         Two_Values,
         Reported_Root_Count (Two_Result),
         False,
         1.0E-4);
      Assert_Residuals
        (Triple_Result,
         Triple_Values,
         Reported_Root_Count (Triple_Result),
         False,
         1.0E-10);
      AUnit.Assertions.Assert
        (Triple_Result.Roots.Depth = OpenCV.Core.Float64,
         "Float64 coefficients must produce Float64 roots");
   end Distinct_Root_Counts_And_Float64;

   procedure Degenerate_Equations (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Quadratic          : constant OpenCV.Core.Cubic_Solution_Result :=
        OpenCV.Core.Solve_Cubic (Coefficients ((0.0, 1.0, -3.0, 2.0)));
      No_Quadratic_Roots : constant OpenCV.Core.Cubic_Solution_Result :=
        OpenCV.Core.Solve_Cubic (Coefficients ((0.0, 1.0, 0.0, 1.0)));
      Linear             : constant OpenCV.Core.Cubic_Solution_Result :=
        OpenCV.Core.Solve_Cubic (Coefficients ((0.0, 0.0, 2.0, -6.0)));
      Constant_Equation  : constant OpenCV.Core.Cubic_Solution_Result :=
        OpenCV.Core.Solve_Cubic (Coefficients ((0.0, 0.0, 0.0, 4.0)));
      Zero               : constant OpenCV.Core.Cubic_Solution_Result :=
        OpenCV.Core.Solve_Cubic (Coefficients ((0.0, 0.0, 0.0, 0.0)));
   begin
      AUnit.Assertions.Assert
        (Quadratic.Status = OpenCV.Core.Two_Real_Roots
         and then No_Quadratic_Roots.Status = OpenCV.Core.No_Real_Roots
         and then Linear.Status = OpenCV.Core.One_Real_Root
         and then Constant_Equation.Status = OpenCV.Core.No_Real_Roots
         and then Zero.Status = OpenCV.Core.Infinitely_Many_Roots,
         "Zero leading cubic coefficients must preserve OpenCV degeneracy"
         & " results");
      Assert_Contains_Root (Quadratic, 1.0, 2, 1.0E-5);
      Assert_Contains_Root (Quadratic, 2.0, 2, 1.0E-5);
      Assert_Contains_Root (Linear, 3.0, 1, 1.0E-5);
   end Degenerate_Equations;

   procedure Noncontiguous_And_Independent_Result
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Cubic_Solution_Result;
   begin
      declare
         Parent : OpenCV.Core.Mat :=
           OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
         View   : constant OpenCV.Core.Mat := Parent.Column_View (0);
      begin
         OpenCV.Core.Float32_Access.Set (Parent, 0, 0, -6.0);
         OpenCV.Core.Float32_Access.Set (Parent, 1, 0, 11.0);
         OpenCV.Core.Float32_Access.Set (Parent, 2, 0, -6.0);
         AUnit.Assertions.Assert
           (not View.Is_Continuous,
            "Solve_Cubic test input must be non-contiguous");
         Result := OpenCV.Core.Solve_Cubic (View);
         OpenCV.Core.Float32_Access.Set (Parent, 0, 0, 99.0);
      end;

      AUnit.Assertions.Assert
        (Result.Status = OpenCV.Core.Three_Real_Roots
         and then Result.Roots.Rows = 3
         and then Result.Roots.Columns = 1
         and then Result.Roots.Depth = OpenCV.Core.Float32,
         "Solve_Cubic must return independent Float32 roots for a Region");
      Assert_Contains_Root (Result, 1.0, 3, 1.0E-5);
      Assert_Contains_Root (Result, 2.0, 3, 1.0E-5);
      Assert_Contains_Root (Result, 3.0, 3, 1.0E-5);
   end Noncontiguous_And_Independent_Result;

   procedure Invalid_Inputs_Are_Rejected (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      procedure Empty is
         Image   : OpenCV.Core.Mat;
         Ignored : constant OpenCV.Core.Cubic_Solution_Result :=
           OpenCV.Core.Solve_Cubic (Image);
      begin
         pragma Unreferenced (Ignored);
      end Empty;
      procedure Typed_Empty is
         Ignored : constant OpenCV.Core.Cubic_Solution_Result :=
           OpenCV.Core.Solve_Cubic
             (OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1)));
      begin
         pragma Unreferenced (Ignored);
      end Typed_Empty;
      procedure Wrong_Count is
         Ignored : constant OpenCV.Core.Cubic_Solution_Result :=
           OpenCV.Core.Solve_Cubic (Coefficients ((1.0, 2.0)));
      begin
         pragma Unreferenced (Ignored);
      end Wrong_Count;
      procedure Square is
         Ignored : constant OpenCV.Core.Cubic_Solution_Result :=
           OpenCV.Core.Solve_Cubic
             (OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1)));
      begin
         pragma Unreferenced (Ignored);
      end Square;
      procedure Multi_Channel is
         Ignored : constant OpenCV.Core.Cubic_Solution_Result :=
           OpenCV.Core.Solve_Cubic
             (OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 2)));
      begin
         pragma Unreferenced (Ignored);
      end Multi_Channel;
      procedure UInt8 is
         Ignored : constant OpenCV.Core.Cubic_Solution_Result :=
           OpenCV.Core.Solve_Cubic
             (OpenCV.Core.Create (1, 3, (OpenCV.Core.UInt8, 1)));
      begin
         pragma Unreferenced (Ignored);
      end UInt8;
      procedure Int32 is
         Ignored : constant OpenCV.Core.Cubic_Solution_Result :=
           OpenCV.Core.Solve_Cubic
             (OpenCV.Core.Create (1, 3, (OpenCV.Core.Int32, 1)));
      begin
         pragma Unreferenced (Ignored);
      end Int32;
      procedure Float16 is
         Ignored : constant OpenCV.Core.Cubic_Solution_Result :=
           OpenCV.Core.Solve_Cubic
             (OpenCV.Core.Create (1, 3, (OpenCV.Core.Float16, 1)));
      begin
         pragma Unreferenced (Ignored);
      end Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Empty'Access, "Solve_Cubic must reject default empty Mat");
      Assert_Raises_OpenCV_Error
        (Typed_Empty'Access, "Solve_Cubic must reject typed empty Mat");
      Assert_Raises_OpenCV_Error
        (Wrong_Count'Access, "Solve_Cubic must reject other counts");
      Assert_Raises_OpenCV_Error
        (Square'Access, "Solve_Cubic must reject 2 x 2 Mats");
      Assert_Raises_OpenCV_Error
        (Multi_Channel'Access, "Solve_Cubic must reject multi-channel Mats");
      Assert_Raises_OpenCV_Error
        (UInt8'Access, "Solve_Cubic must reject UInt8 Mats");
      Assert_Raises_OpenCV_Error
        (Int32'Access, "Solve_Cubic must reject Int32 Mats");
      Assert_Raises_OpenCV_Error
        (Float16'Access, "Solve_Cubic must reject Float16 Mats");
   end Invalid_Inputs_Are_Rejected;

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Solve_Cubic three and monic roots",
            Three_And_Monic_Roots'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve_Cubic distinct counts and Float64",
            Distinct_Root_Counts_And_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve_Cubic degenerate equations", Degenerate_Equations'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve_Cubic non-contiguous independent result",
            Noncontiguous_And_Independent_Result'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve_Cubic invalid inputs", Invalid_Inputs_Are_Rejected'Access));
      return Result'Access;
   end Suite;

end Cubic_Tests;
