with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;

package body Linear_Program_Tests is

   package Caller is new AUnit.Test_Caller (Mat_Test_Support.Mat_Test_Fixture);
   use Mat_Test_Support;
   use type Interfaces.IEEE_Float_32;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Linear_Program_Status;

   procedure Set
     (M    : in out OpenCV.Core.Mat;
      R, C : Natural;
      V    : OpenCV.Core.Float32_Value) is
   begin
      OpenCV.Core.Float32_Access.Set (M, R, C, V);
   end Set;

   procedure Fill_Cormen (O, C : in out OpenCV.Core.Mat) is
   begin
      Set (O, 0, 0, 3.0);
      Set (O, 1, 0, 1.0);
      Set (O, 2, 0, 2.0);
      Set (C, 0, 0, 1.0);
      Set (C, 0, 1, 1.0);
      Set (C, 0, 2, 3.0);
      Set (C, 0, 3, 30.0);
      Set (C, 1, 0, 2.0);
      Set (C, 1, 1, 2.0);
      Set (C, 1, 2, 5.0);
      Set (C, 1, 3, 24.0);
      Set (C, 2, 0, 4.0);
      Set (C, 2, 1, 1.0);
      Set (C, 2, 2, 2.0);
      Set (C, 2, 3, 36.0);
   end Fill_Cormen;

   function Value (M : OpenCV.Core.Mat; R : Natural) return Long_Float is
      F : constant OpenCV.Core.Mat := M.Convert_To (OpenCV.Core.Float32);
   begin
      return Long_Float (OpenCV.Core.Float32_Access.Get (F, R, 0));
   end Value;

   procedure Unique_Mixed_Row_And_Immutability
     (Test : in out Mat_Test_Support.Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      O      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      C      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 1));
      OC, CC : OpenCV.Core.Mat;
      R      : OpenCV.Core.Linear_Program_Result;
   begin
      Fill_Cormen (O, C);
      OC := O.Clone;
      CC := C.Clone;
      R :=
        OpenCV.Core.Solve_Linear_Program
          (O, C.Convert_To (OpenCV.Core.Float64));
      AUnit.Assertions.Assert
        (R.Status = OpenCV.Core.Unique_Optimum
         and then R.Solution.Rows = 3
         and then R.Solution.Columns = 1
         and then R.Solution.Depth = OpenCV.Core.Float64
         and then R.Solution.Channels = 1
         and then Approximately_Equal (Value (R.Solution, 0), 8.0)
         and then Approximately_Equal (Value (R.Solution, 1), 4.0)
         and then Approximately_Equal (Value (R.Solution, 2), 0.0),
         "Cormen LP must return Float64 [8, 4, 0]^T");
      AUnit.Assertions.Assert
        (O.Abs_Diff (OC).Norm (OpenCV.Core.L2) = 0.0
         and then C.Abs_Diff (CC).Norm (OpenCV.Core.L2) = 0.0,
         "LP inputs must remain unchanged");
      R := OpenCV.Core.Solve_Linear_Program (O.Transpose, C);
      AUnit.Assertions.Assert
        (R.Status = OpenCV.Core.Unique_Optimum,
         "Row-vector objective must be accepted");
   end Unique_Mixed_Row_And_Immutability;

   procedure Statuses_Loss_And_Regions
     (Test : in out Mat_Test_Support.Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      O    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      U, I : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      MO   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      MC   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      LO   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.Float32, 1));
      LC   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 5, (OpenCV.Core.Float32, 1));
      R    : OpenCV.Core.Linear_Program_Result;
   begin
      O.Set_To (OpenCV.Core.Make_Scalar (1.0));
      Set (U, 0, 0, -1.0);
      Set (U, 0, 1, 0.0);
      Set (I, 0, 0, 1.0);
      Set (I, 0, 1, -1.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Solve_Linear_Program (O, U).Status = OpenCV.Core.Unbounded
         and then OpenCV.Core.Solve_Linear_Program (O, I).Status
                  = OpenCV.Core.Infeasible,
         "LP must distinguish unbounded and infeasible");
      MO.Set_To (OpenCV.Core.Make_Scalar (1.0));
      MC.Set_To (OpenCV.Core.Make_Scalar (1.0));
      R := OpenCV.Core.Solve_Linear_Program (MO, MC);
      AUnit.Assertions.Assert
        (R.Status = OpenCV.Core.Multiple_Optima
         and then Value (R.Solution, 0) >= -1.0E-6
         and then Value (R.Solution, 1) >= -1.0E-6
         and then Approximately_Equal
                    (Value (R.Solution, 0) + Value (R.Solution, 1), 1.0),
         "Multiple optimum must be feasible");
      LO.Set_To (OpenCV.Core.Make_Scalar (3.0));
      Set (LO, 3, 0, 4.0);
      Set (LC, 0, 0, 0.0);
      Set (LC, 0, 1, 1.0);
      Set (LC, 0, 2, 4.0);
      Set (LC, 0, 3, 4.0);
      Set (LC, 0, 4, 3.0);
      Set (LC, 1, 0, 3.0);
      Set (LC, 1, 1, 1.0);
      Set (LC, 1, 2, 2.0);
      Set (LC, 1, 3, 2.0);
      Set (LC, 1, 4, 3.0);
      Set (LC, 2, 0, 4.0);
      Set (LC, 2, 1, 4.0);
      Set (LC, 2, 2, 0.0);
      Set (LC, 2, 3, 1.0);
      Set (LC, 2, 4, 4.0);
      Set (LC, 3, 0, 4.0);
      Set (LC, 3, 1, 0.0);
      Set (LC, 3, 2, 4.0);
      Set (LC, 3, 3, 1.0);
      Set (LC, 3, 4, 4.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Solve_Linear_Program (LO, LC).Status
         = OpenCV.Core.Numerical_Loss,
         "OpenCV issue_12343 must map to Numerical_Loss");
      declare
         OP : OpenCV.Core.Mat :=
           OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
         CP : OpenCV.Core.Mat :=
           OpenCV.Core.Create (5, 6, (OpenCV.Core.Float32, 1));
         OV : OpenCV.Core.Mat := OP.Column_View (0);
         CV : OpenCV.Core.Mat :=
           CP.Region ((X => 1, Y => 1, Width => 4, Height => 3));
      begin
         Fill_Cormen (OV, CV);
         R := OpenCV.Core.Solve_Linear_Program (OV, CV);
         AUnit.Assertions.Assert
           (not OV.Is_Continuous and then not CV.Is_Continuous,
            "LP Regions must be non-contiguous");
         OP.Set_To (OpenCV.Core.Make_Scalar (99.0));
         CP.Set_To (OpenCV.Core.Make_Scalar (99.0));
      end;
      AUnit.Assertions.Assert
        (R.Status = OpenCV.Core.Unique_Optimum
         and then Approximately_Equal (Value (R.Solution, 0), 8.0),
         "LP result must survive input mutation");
   end Statuses_Loss_And_Regions;

   procedure Invalid_Inputs_And_Tolerance
     (Test : in out Mat_Test_Support.Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      O      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      C      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Z, NaN : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      procedure Bad_Shape is
         X : constant OpenCV.Core.Linear_Program_Result :=
           OpenCV.Core.Solve_Linear_Program
             (OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1)), C);
      begin
         pragma Unreferenced (X);
      end Bad_Shape;
      procedure Bad_Rows is
         X : constant OpenCV.Core.Linear_Program_Result :=
           OpenCV.Core.Solve_Linear_Program
             (O, OpenCV.Core.Create (0, 2, (OpenCV.Core.Float32, 1)));
      begin
         pragma Unreferenced (X);
      end Bad_Rows;
      procedure Bad_Type is
         X : constant OpenCV.Core.Linear_Program_Result :=
           OpenCV.Core.Solve_Linear_Program
             (OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1)), C);
      begin
         pragma Unreferenced (X);
      end Bad_Type;
      procedure Bad_NaN is
         X : constant OpenCV.Core.Linear_Program_Result :=
           OpenCV.Core.Solve_Linear_Program (NaN, C);
      begin
         pragma Unreferenced (X);
      end Bad_NaN;
      procedure Bad_Tolerance is
         X : constant OpenCV.Core.Linear_Program_Result :=
           OpenCV.Core.Solve_Linear_Program (O, C, -1.0);
      begin
         pragma Unreferenced (X);
      end Bad_Tolerance;
   begin
      O.Set_To (OpenCV.Core.Make_Scalar (1.0));
      C.Set_To (OpenCV.Core.Make_Scalar (1.0));
      Z.Set_To (OpenCV.Core.Make_Scalar (0.0));
      NaN := Z.Divide (Z);
      AUnit.Assertions.Assert
        (OpenCV.Core.Solve_Linear_Program (O, C, 0.0).Status
         = OpenCV.Core.Unique_Optimum,
         "Zero tolerance must be accepted");
      Assert_Raises_OpenCV_Error
        (Bad_Shape'Access, "LP must reject wrong shape");
      Assert_Raises_OpenCV_Error (Bad_Rows'Access, "LP must reject zero rows");
      Assert_Raises_OpenCV_Error (Bad_Type'Access, "LP must reject UInt8");
      Assert_Raises_OpenCV_Error (Bad_NaN'Access, "LP must reject NaN");
      Assert_Raises_OpenCV_Error
        (Bad_Tolerance'Access, "LP must reject negative tolerance");
   end Invalid_Inputs_And_Tolerance;

   Result : aliased AUnit.Test_Suites.Test_Suite;
   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("LP unique mixed row immutable",
            Unique_Mixed_Row_And_Immutability'Access));
      Result.Add_Test
        (Caller.Create
           ("LP statuses loss Regions", Statuses_Loss_And_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("LP invalid inputs tolerance",
            Invalid_Inputs_And_Tolerance'Access));
      return Result'Access;
   end Suite;
end Linear_Program_Tests;
