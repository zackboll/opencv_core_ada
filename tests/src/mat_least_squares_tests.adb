with AUnit.Assertions;
with AUnit.Test_Caller;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with Mat_Test_Support;

package body Mat_Least_Squares_Tests is

   use Mat_Test_Support;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;

   procedure Fill_Inconsistent (A, B : in out OpenCV.Core.Mat) is
   begin
      OpenCV.Core.Float32_Access.Set (A, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (A, 0, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (A, 1, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (A, 1, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (A, 2, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (A, 2, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (B, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (B, 1, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (B, 2, 0, 4.0);
   end Fill_Inconsistent;

   function Is_Inconsistent_Solution (X : OpenCV.Core.Mat) return Boolean is
   begin
      return
        X.Rows = 2
        and then X.Columns = 1
        and then X.Depth = OpenCV.Core.Float32
        and then X.Channels = 1
        and then Approximately_Equal
                   (Long_Float (OpenCV.Core.Float32_Access.Get (X, 0, 0)),
                    4.0 / 3.0,
                    0.000_1)
        and then Approximately_Equal
                   (Long_Float (OpenCV.Core.Float32_Access.Get (X, 1, 0)),
                    7.0 / 3.0,
                    0.000_1);
   end Is_Inconsistent_Solution;

   procedure Overdetermined_Float32_Is_Least_Squares
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      A : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      B : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      X : OpenCV.Core.Mat;
   begin
      Fill_Inconsistent (A, B);
      X := A.Solve_Least_Squares (B);
      AUnit.Assertions.Assert
        (Is_Inconsistent_Solution (X),
         "SVD least squares must return [4/3, 7/3] for the inconsistent"
         & " system");
      AUnit.Assertions.Assert
        (A.Matrix_Multiply (X).Subtract (B).Norm (OpenCV.Core.L2) > 0.0,
         "The inconsistent system must not be treated as an exact subset"
         & " solve");
   end Overdetermined_Float32_Is_Least_Squares;

   procedure Exact_And_Multiple_Right_Hand_Sides
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      A : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      B : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      X : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (A, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (A, 0, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (A, 1, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (A, 1, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (A, 2, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (A, 2, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (B, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (B, 1, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (B, 2, 0, 5.0);
      OpenCV.Core.Float32_Access.Set (B, 0, 1, 4.0);
      OpenCV.Core.Float32_Access.Set (B, 1, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (B, 2, 1, 5.0);
      X := A.Solve_Least_Squares (B);
      AUnit.Assertions.Assert
        (X.Rows = 2
         and then X.Columns = 2
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (X, 0, 0)),
                     2.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (X, 1, 0)),
                     3.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (X, 0, 1)),
                     4.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (X, 1, 1)),
                     1.0)
         and then A.Matrix_Multiply (X).Subtract (B).Norm (OpenCV.Core.L2)
                  < 0.000_1,
         "Least squares must solve exact systems and all RHS columns");
   end Exact_And_Multiple_Right_Hand_Sides;

   procedure Rank_Deficient_Returns_Pseudo_Solution
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      A : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      B : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      X : OpenCV.Core.Mat;
   begin
      for Row in 0 .. 2 loop
         OpenCV.Core.Float32_Access.Set
           (A, Row, 0, OpenCV.Core.Float32_Value (Row + 1));
         OpenCV.Core.Float32_Access.Set
           (A, Row, 1, OpenCV.Core.Float32_Value (Row + 1));
         OpenCV.Core.Float32_Access.Set
           (B, Row, 0, OpenCV.Core.Float32_Value (2 * (Row + 1)));
      end loop;
      X := A.Solve_Least_Squares (B);
      declare
         X0       : constant Long_Float :=
           Long_Float (OpenCV.Core.Float32_Access.Get (X, 0, 0));
         X1       : constant Long_Float :=
           Long_Float (OpenCV.Core.Float32_Access.Get (X, 1, 0));
         Residual : constant Long_Float :=
           A.Matrix_Multiply (X).Subtract (B).Norm (OpenCV.Core.L2);
         Observed : constant String :=
           " X=["
           & X0'Image
           & ","
           & X1'Image
           & "], residual="
           & Residual'Image;
      begin
         AUnit.Assertions.Assert
           (X.Rows = 2
            and then X.Columns = 1
            and then X.Depth = OpenCV.Core.Float32
            and then X.Channels = 1,
            "Rank-deficient least-squares result must remain 2 x 1 Float32 C1;"
            & Observed);
         AUnit.Assertions.Assert
           (X0 = X0
            and then X1 = X1
            and then abs (X0) < Long_Float'Last
            and then abs (X1) < Long_Float'Last,
            "Rank-deficient least-squares solution must be finite;"
            & Observed);
         AUnit.Assertions.Assert
           (Residual < 0.000_1,
            "Rank-deficient residual ||A*X-B|| expected < 1e-4, got"
            & Residual'Image
            & ";"
            & Observed);
         AUnit.Assertions.Assert
           (Approximately_Equal (X0 + X1, 2.0, 0.000_1),
            "Rank-deficient solution must satisfy X(0)+X(1)~=2, got"
            & Long_Float'(X0 + X1)'Image
            & ";"
            & Observed);
      end;
   end Rank_Deficient_Returns_Pseudo_Solution;

   procedure Square_And_Float64_Agree_With_Solve
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      A32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      B32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      LU  : OpenCV.Core.Solve_Result;
      SVD : OpenCV.Core.Mat;
      X64 : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (A32, 0, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (A32, 0, 1, 7.0);
      OpenCV.Core.Float32_Access.Set (A32, 1, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (A32, 1, 1, 6.0);
      OpenCV.Core.Float32_Access.Set (B32, 0, 0, 15.0);
      OpenCV.Core.Float32_Access.Set (B32, 1, 0, 10.0);
      LU := A32.Solve (B32);
      SVD := A32.Solve_Least_Squares (B32);
      declare
         A64 : constant OpenCV.Core.Mat :=
           A32.Convert_To (OpenCV.Core.Float64);
         B64 : constant OpenCV.Core.Mat :=
           B32.Convert_To (OpenCV.Core.Float64);
      begin
         X64 := A64.Solve_Least_Squares (B64);
         AUnit.Assertions.Assert
           (LU.Solved
            and then LU.Solution.Abs_Diff (SVD).Norm (OpenCV.Core.L2) < 0.000_1
            and then X64.Depth = OpenCV.Core.Float64
            and then X64.Channels = 1
            and then A64.Matrix_Multiply (X64).Subtract (B64).Norm
                       (OpenCV.Core.L2)
                     < 0.000_000_001,
            "SVD least squares must agree with LU when square and preserve"
            & " Float64");
      end;
   end Square_And_Float64_Agree_With_Solve;

   procedure Regions_Inputs_And_Result_Ownership
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Mat;
      Saved  : OpenCV.Core.Mat;
   begin
      declare
         AP : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (5, 4, (OpenCV.Core.Float32, 1));
         BP : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (5, 2, (OpenCV.Core.Float32, 1));
         A  : OpenCV.Core.Mat :=
           AP.Region ((X => 1, Y => 1, Width => 2, Height => 3));
         B  : OpenCV.Core.Mat :=
           BP.Region ((X => 1, Y => 1, Width => 1, Height => 3));
      begin
         Fill_Inconsistent (A, B);
         AUnit.Assertions.Assert
           (not A.Is_Continuous and then not B.Is_Continuous,
            "Least-squares Regions must be genuinely non-contiguous");
         Result := A.Solve_Least_Squares (B);
         Saved := Result.Clone;
         A.Set_To (OpenCV.Core.Make_Scalar (99.0));
         B.Set_To (OpenCV.Core.Make_Scalar (88.0));
         AUnit.Assertions.Assert
           (Result.Abs_Diff (Saved).Norm (OpenCV.Core.L2) = 0.0,
            "Least-squares result must own storage independent of inputs");
      end;
      AUnit.Assertions.Assert
        (Is_Inconsistent_Solution (Result),
         "Least-squares result must survive input finalization");
   end Regions_Inputs_And_Result_Ownership;

   procedure Rejects_Invalid_Input (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Empty   : OpenCV.Core.Mat;
      Empty32 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      F32     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      F64     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float64, 1));
      C2      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 2));
      I32     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Int32, 1));
      F16     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float16, 1));
      Wide    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Short   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      procedure Check_Empty is
         X : constant OpenCV.Core.Mat := Empty.Solve_Least_Squares (F32);
      begin
         pragma Unreferenced (X);
      end Check_Empty;
      procedure Check_Empty_B is
         X : constant OpenCV.Core.Mat := F32.Solve_Least_Squares (Empty);
      begin
         pragma Unreferenced (X);
      end Check_Empty_B;
      procedure Check_Typed_Empty_A is
         X : constant OpenCV.Core.Mat := Empty32.Solve_Least_Squares (F32);
      begin
         pragma Unreferenced (X);
      end Check_Typed_Empty_A;
      procedure Check_Typed_Empty_B is
         X : constant OpenCV.Core.Mat := F32.Solve_Least_Squares (Empty32);
      begin
         pragma Unreferenced (X);
      end Check_Typed_Empty_B;
      procedure Check_C2 is
         X : constant OpenCV.Core.Mat := C2.Solve_Least_Squares (F32);
      begin
         pragma Unreferenced (X);
      end Check_C2;
      procedure Check_C2_B is
         X : constant OpenCV.Core.Mat := F32.Solve_Least_Squares (C2);
      begin
         pragma Unreferenced (X);
      end Check_C2_B;
      procedure Check_I32 is
         X : constant OpenCV.Core.Mat := F32.Solve_Least_Squares (I32);
      begin
         pragma Unreferenced (X);
      end Check_I32;
      procedure Check_F16 is
         X : constant OpenCV.Core.Mat := F32.Solve_Least_Squares (F16);
      begin
         pragma Unreferenced (X);
      end Check_F16;
      procedure Check_Depth is
         X : constant OpenCV.Core.Mat := F32.Solve_Least_Squares (F64);
      begin
         pragma Unreferenced (X);
      end Check_Depth;
      procedure Check_Rows is
         X : constant OpenCV.Core.Mat := F32.Solve_Least_Squares (Short);
      begin
         pragma Unreferenced (X);
      end Check_Rows;
      procedure Check_Wide is
         X : constant OpenCV.Core.Mat := Wide.Solve_Least_Squares (F32);
      begin
         pragma Unreferenced (X);
      end Check_Wide;
   begin
      Assert_Raises_OpenCV_Error
        (Check_Empty'Access, "Least squares must reject empty A");
      Assert_Raises_OpenCV_Error
        (Check_Empty_B'Access, "Least squares must reject empty B");
      Assert_Raises_OpenCV_Error
        (Check_Typed_Empty_A'Access,
         "Least squares must reject typed empty A");
      Assert_Raises_OpenCV_Error
        (Check_Typed_Empty_B'Access,
         "Least squares must reject typed empty B");
      Assert_Raises_OpenCV_Error
        (Check_C2'Access, "Least squares must reject multi-channel A");
      Assert_Raises_OpenCV_Error
        (Check_C2_B'Access, "Least squares must reject multi-channel B");
      Assert_Raises_OpenCV_Error
        (Check_I32'Access, "Least squares must reject integer B");
      Assert_Raises_OpenCV_Error
        (Check_F16'Access, "Least squares must reject Float16 B");
      Assert_Raises_OpenCV_Error
        (Check_Depth'Access, "Least squares must reject mismatched depths");
      Assert_Raises_OpenCV_Error
        (Check_Rows'Access, "Least squares must reject mismatched rows");
      Assert_Raises_OpenCV_Error
        (Check_Wide'Access, "Least squares must reject underdetermined A");
   end Rejects_Invalid_Input;

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("SVD least squares overdetermined Float32",
            Overdetermined_Float32_Is_Least_Squares'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD least squares exact multiple RHS",
            Exact_And_Multiple_Right_Hand_Sides'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD least squares rank deficient",
            Rank_Deficient_Returns_Pseudo_Solution'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD least squares square and Float64",
            Square_And_Float64_Agree_With_Solve'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD least squares Regions ownership",
            Regions_Inputs_And_Result_Ownership'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD least squares rejects invalid input",
            Rejects_Invalid_Input'Access));
      return Result'Access;
   end Suite;

end Mat_Least_Squares_Tests;
