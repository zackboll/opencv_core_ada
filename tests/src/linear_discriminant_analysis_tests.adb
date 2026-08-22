with AUnit.Assertions;
with AUnit.Test_Caller;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with Mat_Test_Support;

package body Linear_Discriminant_Analysis_Tests is

   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Mat_Size;
   use Mat_Test_Support;

   type Label_Values is array (Natural range <>) of Long_Float;

   procedure Set_Point
     (Samples : in out OpenCV.Core.Mat; Row : Natural; X, Y : Long_Float) is
   begin
      OpenCV.Core.Float32_Access.Set
        (Samples, Row, 0, OpenCV.Core.Float32_Value (X));
      OpenCV.Core.Float32_Access.Set
        (Samples, Row, 1, OpenCV.Core.Float32_Value (Y));
   end Set_Point;

   function Labels
     (Values : Label_Values; Row_Vector : Boolean := False)
      return OpenCV.Core.Mat
   is
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          ((if Row_Vector then 1 else Values'Length),
           (if Row_Vector then Values'Length else 1),
           (OpenCV.Core.Float32, 1));
   begin
      for Index in Values'Range loop
         OpenCV.Core.Float32_Access.Set
           (Source,
            (if Row_Vector then 0 else Index - Values'First),
            (if Row_Vector then Index - Values'First else 0),
            OpenCV.Core.Float32_Value (Values (Index)));
      end loop;
      return Source.Convert_To (OpenCV.Core.Int32);
   end Labels;

   procedure Fill_Two_Classes (Samples : in out OpenCV.Core.Mat) is
   begin
      Set_Point (Samples, 0, -2.0, -1.0);
      Set_Point (Samples, 1, -1.0, 1.0);
      Set_Point (Samples, 2, 1.0, -2.0);
      Set_Point (Samples, 3, 2.0, 1.0);
   end Fill_Two_Classes;

   function Eigenvalue_At
     (Values : OpenCV.Core.Mat; Row : Natural) return Long_Float
   is
      Float32_Values : constant OpenCV.Core.Mat :=
        Values.Convert_To (OpenCV.Core.Float32);
   begin
      return
        Long_Float (OpenCV.Core.Float32_Access.Get (Float32_Values, Row, 0));
   end Eigenvalue_At;

   procedure Basic_Basis_And_Projection (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Samples                 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Result                  :
        OpenCV.Core.Linear_Discriminant_Analysis_Result;
      Projected               : OpenCV.Core.Mat;
      First_Mean, Second_Mean : Long_Float := 0.0;
   begin
      Fill_Two_Classes (Samples);
      Result :=
        OpenCV.Core.Linear_Discriminant_Analysis
          (Samples, Labels ((0 => 0.0, 1 => 0.0, 2 => 1.0, 3 => 1.0)), 1);
      Projected :=
        Samples.Convert_To (OpenCV.Core.Float64).Matrix_Multiply
          (Result.Eigenvectors);
      for Row in 0 .. 1 loop
         First_Mean :=
           First_Mean
           + Long_Float
               (OpenCV.Core.Float32_Access.Get
                  (Projected.Convert_To (OpenCV.Core.Float32), Row, 0));
         Second_Mean :=
           Second_Mean
           + Long_Float
               (OpenCV.Core.Float32_Access.Get
                  (Projected.Convert_To (OpenCV.Core.Float32), Row + 2, 0));
      end loop;
      AUnit.Assertions.Assert
        (Result.Eigenvalues.Rows = 1
         and then Result.Eigenvalues.Columns = 1
         and then Result.Eigenvalues.Depth = OpenCV.Core.Float64
         and then Result.Eigenvalues.Channels = 1
         and then Result.Eigenvectors.Rows = 2
         and then Result.Eigenvectors.Columns = 1
         and then Result.Eigenvectors.Depth = OpenCV.Core.Float64
         and then Result.Eigenvectors.Channels = 1,
         "LDA must return the required Float64 basis shapes");
      AUnit.Assertions.Assert
        (Eigenvalue_At (Result.Eigenvalues, 0) > 0.0,
         "LDA must return a positive two-class discriminant eigenvalue");
      AUnit.Assertions.Assert
        (Projected.Rows = 4 and then Projected.Columns = 1,
         "LDA basis must multiply row-aligned samples");
      AUnit.Assertions.Assert
        (abs (First_Mean - Second_Mean) > 1.0,
         "LDA column basis must clearly separate projected class means");
   end Basic_Basis_And_Projection;

   procedure Component_Counts_And_Arbitrary_Labels
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Samples                         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (8, 2, (OpenCV.Core.Float32, 1));
      Automatic, Truncated, Arbitrary :
        OpenCV.Core.Linear_Discriminant_Analysis_Result;
      procedure Excess is
         Ignored : constant OpenCV.Core.Linear_Discriminant_Analysis_Result :=
           OpenCV.Core.Linear_Discriminant_Analysis
             (Samples,
              Labels
                ((0 => 0.0,
                  1 => 0.0,
                  2 => 1.0,
                  3 => 1.0,
                  4 => 2.0,
                  5 => 2.0,
                  6 => 3.0,
                  7 => 3.0)),
              3);
      begin
         pragma Unreferenced (Ignored);
      end Excess;
   begin
      Set_Point (Samples, 0, -3.0, -1.0);
      Set_Point (Samples, 1, -2.0, 1.0);
      Set_Point (Samples, 2, -1.0, -2.0);
      Set_Point (Samples, 3, 0.0, 0.0);
      Set_Point (Samples, 4, 1.0, -1.0);
      Set_Point (Samples, 5, 2.0, 1.0);
      Set_Point (Samples, 6, 3.0, -2.0);
      Set_Point (Samples, 7, 4.0, 0.0);
      Automatic :=
        OpenCV.Core.Linear_Discriminant_Analysis
          (Samples,
           Labels
             ((0 => 0.0,
               1 => 0.0,
               2 => 1.0,
               3 => 1.0,
               4 => 2.0,
               5 => 2.0,
               6 => 3.0,
               7 => 3.0)));
      Truncated :=
        OpenCV.Core.Linear_Discriminant_Analysis
          (Samples,
           Labels
             ((0 => 0.0,
               1 => 0.0,
               2 => 1.0,
               3 => 1.0,
               4 => 2.0,
               5 => 2.0,
               6 => 3.0,
               7 => 3.0)),
           1);
      Arbitrary :=
        OpenCV.Core.Linear_Discriminant_Analysis
          (Samples,
           Labels
             ((0 => -10.0,
               1 => -10.0,
               2 => 42.0,
               3 => 42.0,
               4 => 100.0,
               5 => 100.0,
               6 => -5.0,
               7 => -5.0)),
           1);
      AUnit.Assertions.Assert
        (Automatic.Eigenvalues.Rows = 2
         and then Automatic.Eigenvectors.Rows = 2
         and then Automatic.Eigenvectors.Columns = 2
         and then Truncated.Eigenvalues.Rows = 1
         and then Truncated.Eigenvectors.Columns = 1
         and then Approximately_Equal
                    (Eigenvalue_At (Automatic.Eigenvalues, 0),
                     Eigenvalue_At (Truncated.Eigenvalues, 0))
         and then Approximately_Equal
                    (Eigenvalue_At (Truncated.Eigenvalues, 0),
                     Eigenvalue_At (Arbitrary.Eigenvalues, 0)),
         "LDA must select min(C - 1, D), truncate exactly, and accept"
         & " signed labels");
      Assert_Raises_OpenCV_Error
        (Excess'Access,
         "LDA must reject requested components above min(C - 1, D)");
   end Component_Counts_And_Arbitrary_Labels;

   procedure Label_Vectors_Regions_And_Input_Immutability
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent                   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 3, (OpenCV.Core.Float32, 1));
      Label_Parent             : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Samples                  : OpenCV.Core.Mat;
      Column_Labels            : OpenCV.Core.Mat;
      Snapshot, Label_Snapshot : OpenCV.Core.Mat;
      Result                   :
        OpenCV.Core.Linear_Discriminant_Analysis_Result;
   begin
      for Row in 0 .. 3 loop
         Set_Point
           (Parent, Row, (if Row < 2 then -1.0 else 1.0), Long_Float (Row));
         OpenCV.Core.Float32_Access.Set
           (Label_Parent, Row, 0, (if Row < 2 then 0.0 else 1.0));
      end loop;
      Samples := Parent.Region ((X => 0, Y => 0, Width => 2, Height => 4));
      Label_Parent := Label_Parent.Convert_To (OpenCV.Core.Int32);
      Column_Labels :=
        Label_Parent.Region ((X => 0, Y => 0, Width => 1, Height => 4));
      Snapshot := Samples.Clone;
      Label_Snapshot := Column_Labels.Clone;
      Result :=
        OpenCV.Core.Linear_Discriminant_Analysis (Samples, Column_Labels, 1);
      AUnit.Assertions.Assert
        (not Samples.Is_Continuous
         and then not Column_Labels.Is_Continuous
         and then Samples.Compare (Snapshot, OpenCV.Core.Equal).Count_Non_Zero
                  = 8
         and then Column_Labels.Compare (Label_Snapshot, OpenCV.Core.Equal)
                    .Count_Non_Zero
                  = 4
         and then Result.Eigenvectors.Rows = 2,
         "LDA must support non-contiguous Regions without changing inputs");
      declare
         Row_Labels : constant OpenCV.Core.Mat :=
           Labels
             ((0 => 0.0, 1 => 0.0, 2 => 1.0, 3 => 1.0), Row_Vector => True);
         Row_Result :
           constant OpenCV.Core.Linear_Discriminant_Analysis_Result :=
             OpenCV.Core.Linear_Discriminant_Analysis (Samples, Row_Labels, 1);
      begin
         AUnit.Assertions.Assert
           (Row_Result.Eigenvalues.Rows = 1,
            "LDA must accept Int32 row-vector labels");
      end;
   end Label_Vectors_Regions_And_Input_Immutability;

   procedure Validation_Rejects_Invalid_Inputs (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Samples     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Good_Labels : constant OpenCV.Core.Mat :=
        Labels ((0 => 0.0, 1 => 0.0, 2 => 1.0, 3 => 1.0));
      procedure Wrong_Label_Depth is
         Ignored : constant OpenCV.Core.Linear_Discriminant_Analysis_Result :=
           OpenCV.Core.Linear_Discriminant_Analysis (Samples, Samples, 1);
      begin
         pragma Unreferenced (Ignored);
      end Wrong_Label_Depth;
      procedure Bad_Label_Shape is
         Ignored : constant OpenCV.Core.Linear_Discriminant_Analysis_Result :=
           OpenCV.Core.Linear_Discriminant_Analysis
             (Samples, OpenCV.Core.Create (2, 2, (OpenCV.Core.Int32, 1)), 1);
      begin
         pragma Unreferenced (Ignored);
      end Bad_Label_Shape;
      procedure One_Class is
         Ignored : constant OpenCV.Core.Linear_Discriminant_Analysis_Result :=
           OpenCV.Core.Linear_Discriminant_Analysis
             (Samples, Labels ((0 => 7.0, 1 => 7.0, 2 => 7.0, 3 => 7.0)), 1);
      begin
         pragma Unreferenced (Ignored);
      end One_Class;
      procedure Bad_Sample_Type is
         Ignored : constant OpenCV.Core.Linear_Discriminant_Analysis_Result :=
           OpenCV.Core.Linear_Discriminant_Analysis
             (OpenCV.Core.Create (4, 2, (OpenCV.Core.UInt8, 1)),
              Good_Labels,
              1);
      begin
         pragma Unreferenced (Ignored);
      end Bad_Sample_Type;
      procedure Multi_Channel is
         Ignored : constant OpenCV.Core.Linear_Discriminant_Analysis_Result :=
           OpenCV.Core.Linear_Discriminant_Analysis
             (OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 2)),
              Good_Labels,
              1);
      begin
         pragma Unreferenced (Ignored);
      end Multi_Channel;
   begin
      Fill_Two_Classes (Samples);
      Assert_Raises_OpenCV_Error
        (Wrong_Label_Depth'Access, "LDA must reject non-Int32 labels");
      Assert_Raises_OpenCV_Error
        (Bad_Label_Shape'Access, "LDA must reject non-vector labels");
      Assert_Raises_OpenCV_Error
        (One_Class'Access, "LDA must reject one class");
      Assert_Raises_OpenCV_Error
        (Bad_Sample_Type'Access, "LDA must reject UInt8 samples");
      Assert_Raises_OpenCV_Error
        (Multi_Channel'Access, "LDA must reject C2 samples");
   end Validation_Rejects_Invalid_Inputs;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);
      Result : constant AUnit.Test_Suites.Access_Test_Suite :=
        new AUnit.Test_Suites.Test_Suite;
   begin
      Result.Add_Test
        (Caller.Create
           ("LDA basic basis and projection",
            Basic_Basis_And_Projection'Access));
      Result.Add_Test
        (Caller.Create
           ("LDA component counts and signed labels",
            Component_Counts_And_Arbitrary_Labels'Access));
      Result.Add_Test
        (Caller.Create
           ("LDA label vectors, Regions, and inputs",
            Label_Vectors_Regions_And_Input_Immutability'Access));
      Result.Add_Test
        (Caller.Create
           ("LDA rejects invalid inputs",
            Validation_Rejects_Invalid_Inputs'Access));
      return Result;
   end Suite;

end Linear_Discriminant_Analysis_Tests;
