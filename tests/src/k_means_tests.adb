with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.UInt8_Access;
with Mat_Test_Support;

package body K_Means_Tests is

   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Mat_Size;
   use type Interfaces.IEEE_Float_32;
   use Mat_Test_Support;

   procedure Set_Point
     (Samples : in out OpenCV.Core.Mat; Row : Natural; X, Y : Long_Float) is
   begin
      OpenCV.Core.Float32_Access.Set
        (Samples, Row, 0, OpenCV.Core.Float32_Value (X));
      OpenCV.Core.Float32_Access.Set
        (Samples, Row, 1, OpenCV.Core.Float32_Value (Y));
   end Set_Point;

   procedure Set_Label
     (Labels : in out OpenCV.Core.Mat; Row, Column : Natural; Value : Natural)
   is
   begin
      OpenCV.Core.UInt8_Access.Set
        (Labels, Row, Column, OpenCV.Core.UInt8_Value (Value));
   end Set_Label;

   function Labels_Are_Valid
     (Labels : OpenCV.Core.Mat; Cluster_Count : Positive) return Boolean
   is
      As_Float : constant OpenCV.Core.Mat :=
        Labels.Convert_To (OpenCV.Core.Float32);
   begin
      return
        (for all Row in 0 .. Labels.Rows - 1 =>
           Long_Float (OpenCV.Core.Float32_Access.Get (As_Float, Row, 0))
           >= 0.0
           and then Long_Float
                      (OpenCV.Core.Float32_Access.Get (As_Float, Row, 0))
                    < Long_Float (Cluster_Count));
   end Labels_Are_Valid;

   procedure Two_Obvious_Clusters_Have_Independent_Outputs
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Samples                                    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Result                                     : OpenCV.Core.K_Means_Result;
      Labels                                     : OpenCV.Core.Mat;
      Low, High                                  : Long_Float;
      Center_00, Center_01, Center_10, Center_11 : Long_Float;
   begin
      Set_Point (Samples, 0, 0.0, 0.0);
      Set_Point (Samples, 1, 0.0, 0.0);
      Set_Point (Samples, 2, 10.0, 10.0);
      Set_Point (Samples, 3, 10.0, 10.0);
      Result := OpenCV.Core.K_Means (Samples, 2);
      Labels := Result.Labels.Convert_To (OpenCV.Core.Float32);
      Low := Long_Float (OpenCV.Core.Float32_Access.Get (Labels, 0, 0));
      High := Long_Float (OpenCV.Core.Float32_Access.Get (Labels, 2, 0));
      AUnit.Assertions.Assert
        (Result.Labels.Rows = 4
         and then Result.Labels.Columns = 1
         and then Result.Labels.Depth = OpenCV.Core.Int32
         and then Result.Labels.Channels = 1
         and then Result.Centers.Rows = 2
         and then Result.Centers.Columns = 2
         and then Result.Centers.Depth = OpenCV.Core.Float32
         and then Result.Centers.Channels = 1
         and then Approximately_Equal (Result.Compactness, 0.0, 1.0E-5)
         and then Low
                  = Long_Float (OpenCV.Core.Float32_Access.Get (Labels, 1, 0))
         and then High
                  = Long_Float (OpenCV.Core.Float32_Access.Get (Labels, 3, 0))
         and then Low /= High
         and then Low >= 0.0
         and then Low < 2.0
         and then High >= 0.0
         and then High < 2.0,
         "K_Means must cluster obvious points without assuming cluster order");
      declare
         Low_Center_Row  : constant Natural := Natural (Integer (Low));
         High_Center_Row : constant Natural := Natural (Integer (High));
      begin
         AUnit.Assertions.Assert
           (Approximately_Equal
              (Long_Float
                 (OpenCV.Core.Float32_Access.Get
                    (Result.Centers, Low_Center_Row, 0)),
               0.0,
               1.0E-5)
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get
                             (Result.Centers, High_Center_Row, 1)),
                        10.0,
                        1.0E-5),
            "Labels must identify the corresponding returned centers");
      end;
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Samples, 0, 0) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Samples, 3, 1) = 10.0,
         "K_Means must not modify Samples");
      Center_00 :=
        Long_Float (OpenCV.Core.Float32_Access.Get (Result.Centers, 0, 0));
      Center_01 :=
        Long_Float (OpenCV.Core.Float32_Access.Get (Result.Centers, 0, 1));
      Center_10 :=
        Long_Float (OpenCV.Core.Float32_Access.Get (Result.Centers, 1, 0));
      Center_11 :=
        Long_Float (OpenCV.Core.Float32_Access.Get (Result.Centers, 1, 1));
      Samples.Set_To (OpenCV.Core.Make_Scalar (99.0));
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Result.Centers, 0, 0)),
            Center_00,
            1.0E-5)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result.Centers, 0, 1)),
                     Center_01,
                     1.0E-5)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result.Centers, 1, 0)),
                     Center_10,
                     1.0E-5)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result.Centers, 1, 1)),
                     Center_11,
                     1.0E-5)
         and then Result.Labels.Rows = 4,
         "K_Means outputs must own storage independently of Samples");
   end Two_Obvious_Clusters_Have_Independent_Outputs;

   procedure One_Cluster_Random_Is_Deterministic
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Samples : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Result  : OpenCV.Core.K_Means_Result;
      Labels  : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Samples, 0, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Samples, 1, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Samples, 2, 0, 4.0);
      Result :=
        OpenCV.Core.K_Means
          (Samples,
           1,
           Attempts       => 4,
           Initialization => OpenCV.Core.Random_Centers);
      Labels := Result.Labels.Convert_To (OpenCV.Core.Float32);
      AUnit.Assertions.Assert
        (Approximately_Equal (Result.Compactness, 8.0, 1.0E-5)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result.Centers, 0, 0)),
                     2.0,
                     1.0E-5)
         and then (for all Row in 0 .. 2 =>
                     OpenCV.Core.Float32_Access.Get (Labels, Row, 0) = 0.0),
         "K=1 must have zero labels, mean center, and expected compactness");
   end One_Cluster_Random_Is_Deterministic;

   procedure Multi_Channel_And_One_Row_Representations_Work
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      X         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.Float32, 1));
      Y         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.Float32, 1));
      One_Row_X : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
      One_Row_Y : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
   begin
      for Row in 0 .. 3 loop
         OpenCV.Core.Float32_Access.Set
           (X, Row, 0, (if Row < 2 then 0.0 else 10.0));
         OpenCV.Core.Float32_Access.Set
           (Y, Row, 0, (if Row < 2 then 0.0 else 10.0));
         OpenCV.Core.Float32_Access.Set
           (One_Row_X, 0, Row, (if Row < 2 then 0.0 else 10.0));
         OpenCV.Core.Float32_Access.Set
           (One_Row_Y, 0, Row, (if Row < 2 then 0.0 else 10.0));
      end loop;
      declare
         Multi        : constant OpenCV.Core.Mat := OpenCV.Core.Merge ((X, Y));
         Row_Multi    : constant OpenCV.Core.Mat :=
           OpenCV.Core.Merge ((One_Row_X, One_Row_Y));
         Multi_Result : constant OpenCV.Core.K_Means_Result :=
           OpenCV.Core.K_Means (Multi, 2);
         Row_Result   : constant OpenCV.Core.K_Means_Result :=
           OpenCV.Core.K_Means (Row_Multi, 2);
      begin
         AUnit.Assertions.Assert
           (Multi_Result.Labels.Rows = 4
            and then Multi_Result.Centers.Columns = 2
            and then Row_Result.Labels.Rows = 4
            and then Row_Result.Centers.Columns = 2,
            "K_Means must preserve OpenCV multi-channel and one-row forms");
      end;
   end Multi_Channel_And_One_Row_Representations_Work;

   procedure Initial_Labels_Solve_And_Preserve_Inputs
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Samples          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Label_Source     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.UInt8, 1));
      Initial_Labels   : OpenCV.Core.Mat;
      Snapshot         : OpenCV.Core.Mat;
      Result           : OpenCV.Core.K_Means_Result;
      Labels_Snapshot  : OpenCV.Core.Mat;
      Centers_Snapshot : OpenCV.Core.Mat;
   begin
      Set_Point (Samples, 0, 0.0, 0.0);
      Set_Point (Samples, 1, 0.0, 1.0);
      Set_Point (Samples, 2, 10.0, 10.0);
      Set_Point (Samples, 3, 10.0, 11.0);
      Set_Label (Label_Source, 0, 0, 0);
      Set_Label (Label_Source, 1, 0, 0);
      Set_Label (Label_Source, 2, 0, 1);
      Set_Label (Label_Source, 3, 0, 1);
      Initial_Labels := Label_Source.Convert_To (OpenCV.Core.Int32);
      Snapshot := Initial_Labels.Clone;
      Result := OpenCV.Core.K_Means (Samples, 2, Initial_Labels);
      Labels_Snapshot := Result.Labels.Clone;
      Centers_Snapshot := Result.Centers.Clone;
      AUnit.Assertions.Assert
        (Result.Labels.Rows = 4
         and then Result.Labels.Columns = 1
         and then Result.Labels.Depth = OpenCV.Core.Int32
         and then Result.Labels.Channels = 1
         and then Result.Centers.Rows = 2
         and then Result.Centers.Columns = 2
         and then Result.Centers.Depth = OpenCV.Core.Float32
         and then Result.Centers.Channels = 1
         and then Result.Compactness >= 0.0
         and then Labels_Are_Valid (Result.Labels, 2),
         "initial-label K_Means must return canonical valid outputs");
      AUnit.Assertions.Assert
        (Initial_Labels.Rows = Snapshot.Rows
         and then Initial_Labels.Columns = Snapshot.Columns
         and then Initial_Labels.Depth = Snapshot.Depth
         and then Initial_Labels.Channels = Snapshot.Channels
         and then Initial_Labels.Compare (Snapshot, OpenCV.Core.Equal)
                    .Count_Non_Zero
                  = OpenCV.Core.Mat_Size
                      (Initial_Labels.Rows * Initial_Labels.Columns)
         and then OpenCV.Core.Float32_Access.Get (Samples, 0, 0) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Samples, 3, 1) = 11.0,
         "initial-label K_Means must not modify labels or samples");
      Samples.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Initial_Labels.Set_To (OpenCV.Core.Make_Scalar (7.0));
      AUnit.Assertions.Assert
        (Result.Labels.Compare (Labels_Snapshot, OpenCV.Core.Equal)
           .Count_Non_Zero
         = 4
         and then Result.Centers.Compare (Centers_Snapshot, OpenCV.Core.Equal)
                    .Count_Non_Zero
                  = 4,
         "initial-label K_Means outputs must not alias either input");
   end Initial_Labels_Solve_And_Preserve_Inputs;

   procedure Label_Vector_Forms_And_Non_Continuous_Region_Work
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Samples    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.Float32, 1));
      Row_Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.UInt8, 1));
      Parent     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.UInt8, 1));
   begin
      for Row in 0 .. 3 loop
         OpenCV.Core.Float32_Access.Set
           (Samples, Row, 0, (if Row < 2 then 0.0 else 10.0));
         Set_Label (Row_Source, 0, Row, (if Row < 2 then 0 else 1));
         Set_Label (Parent, Row, 0, (if Row < 2 then 0 else 1));
         Set_Label (Parent, Row, 1, 9);
      end loop;
      declare
         Row_Labels      : constant OpenCV.Core.Mat :=
           Row_Source.Convert_To (OpenCV.Core.Int32);
         Parent32        : constant OpenCV.Core.Mat :=
           Parent.Convert_To (OpenCV.Core.Int32);
         Parent_Snapshot : constant OpenCV.Core.Mat := Parent32.Clone;
         Region          : constant OpenCV.Core.Mat :=
           Parent32.Region ((X => 0, Y => 0, Width => 1, Height => 4));
         Row_Result      : constant OpenCV.Core.K_Means_Result :=
           OpenCV.Core.K_Means (Samples, 2, Row_Labels);
         Region_Result   : constant OpenCV.Core.K_Means_Result :=
           OpenCV.Core.K_Means (Samples, 2, Region);
      begin
         AUnit.Assertions.Assert
           (Row_Result.Labels.Rows = 4
            and then not Region.Is_Continuous
            and then Region_Result.Labels.Rows = 4
            and then Parent32.Compare (Parent_Snapshot, OpenCV.Core.Equal)
                       .Count_Non_Zero
                     = 8,
            "initial-label K_Means must accept row vectors and"
            & " non-contiguous Regions");
      end;
   end Label_Vector_Forms_And_Non_Continuous_Region_Work;

   procedure Empty_Cluster_And_Attempts_Work (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Samples        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.Float32, 1));
      Source         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.UInt8, 1));
      Initial_Labels : OpenCV.Core.Mat;
      First, Second  : OpenCV.Core.K_Means_Result;
   begin
      for Row in 0 .. 3 loop
         OpenCV.Core.Float32_Access.Set
           (Samples, Row, 0, (if Row < 2 then 0.0 else 10.0));
      end loop;
      Initial_Labels := Source.Convert_To (OpenCV.Core.Int32);
      First :=
        OpenCV.Core.K_Means
          (Samples,
           2,
           Initial_Labels,
           Subsequent_Initialization => OpenCV.Core.Random_Centers);
      AUnit.Assertions.Assert
        (Labels_Are_Valid (First.Labels, 2),
         "K_Means must repair an empty initial cluster");
      First :=
        OpenCV.Core.K_Means
          (Samples,
           2,
           Initial_Labels,
           Subsequent_Initialization => OpenCV.Core.Plus_Plus_Centers);
      AUnit.Assertions.Assert
        (Labels_Are_Valid (First.Labels, 2),
         "both subsequent initializations must work with one attempt");
      OpenCV.Core.Set_Random_Seed (12345);
      First := OpenCV.Core.K_Means (Samples, 2, Initial_Labels, Attempts => 3);
      OpenCV.Core.Set_Random_Seed (12345);
      Second :=
        OpenCV.Core.K_Means (Samples, 2, Initial_Labels, Attempts => 3);
      AUnit.Assertions.Assert
        (Approximately_Equal (First.Compactness, Second.Compactness)
         and then First.Labels.Compare (Second.Labels, OpenCV.Core.Equal)
                    .Count_Non_Zero
                  = 4
         and then First.Centers.Compare (Second.Centers, OpenCV.Core.Equal)
                    .Count_Non_Zero
                  = 2,
         "seeded subsequent K_Means attempts must replay deterministically");
   end Empty_Cluster_And_Attempts_Work;

   procedure Invalid_Initial_Labels_Are_Rejected
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Samples      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.Float32, 1));
      Valid_Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.UInt8, 1));
      procedure Out_Of_Range is
         Labels  : OpenCV.Core.Mat := Valid_Source;
         Ignored : OpenCV.Core.K_Means_Result;
      begin
         Set_Label (Labels, 0, 0, 2);
         Ignored :=
           OpenCV.Core.K_Means
             (Samples, 2, Labels.Convert_To (OpenCV.Core.Int32));
      end Out_Of_Range;
      procedure Negative is
         Labels  : OpenCV.Core.Mat :=
           OpenCV.Core.Create (4, 1, (OpenCV.Core.Float32, 1));
         Ignored : OpenCV.Core.K_Means_Result;
      begin
         Labels.Set_To (OpenCV.Core.Make_Scalar (-1.0));
         Ignored :=
           OpenCV.Core.K_Means
             (Samples, 2, Labels.Convert_To (OpenCV.Core.Int32));
      end Negative;
      procedure Wrong_Depth is
         Ignored : OpenCV.Core.K_Means_Result :=
           OpenCV.Core.K_Means
             (Samples, 2, Valid_Source.Convert_To (OpenCV.Core.Float32));
      begin
         pragma Unreferenced (Ignored);
      end Wrong_Depth;
      procedure Multi_Channel is
         Ignored : OpenCV.Core.K_Means_Result :=
           OpenCV.Core.K_Means
             (Samples, 2, OpenCV.Core.Create (4, 1, (OpenCV.Core.Int32, 2)));
      begin
         pragma Unreferenced (Ignored);
      end Multi_Channel;
      procedure Wrong_Count is
         Ignored : OpenCV.Core.K_Means_Result :=
           OpenCV.Core.K_Means
             (Samples, 2, OpenCV.Core.Create (3, 1, (OpenCV.Core.Int32, 1)));
      begin
         pragma Unreferenced (Ignored);
      end Wrong_Count;
      procedure Non_Vector is
         Ignored : OpenCV.Core.K_Means_Result :=
           OpenCV.Core.K_Means
             (Samples, 2, OpenCV.Core.Create (2, 2, (OpenCV.Core.Int32, 1)));
      begin
         pragma Unreferenced (Ignored);
      end Non_Vector;
   begin
      Assert_Raises_OpenCV_Error
        (Out_Of_Range'Access, "out-of-range labels must fail");
      Assert_Raises_OpenCV_Error
        (Negative'Access, "negative labels must fail");
      Assert_Raises_OpenCV_Error
        (Wrong_Depth'Access, "non-Int32 labels must fail");
      Assert_Raises_OpenCV_Error
        (Multi_Channel'Access, "multi-channel labels must fail");
      Assert_Raises_OpenCV_Error
        (Wrong_Count'Access, "wrong label count must fail");
      Assert_Raises_OpenCV_Error
        (Non_Vector'Access, "non-vector labels must fail");
   end Invalid_Initial_Labels_Are_Rejected;

   procedure Non_Continuous_Region_And_Invalid_Inputs
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 3, (OpenCV.Core.Float32, 1));
      Empty       : OpenCV.Core.Mat;
      Float64     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float64, 1));
      Integer     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Int32, 1));
      Typed_Empty : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 1, (OpenCV.Core.Float32, 1));
      procedure Empty_Input is
         Ignored : constant OpenCV.Core.K_Means_Result :=
           OpenCV.Core.K_Means (Empty, 1);
      begin
         pragma Unreferenced (Ignored);
      end Empty_Input;
      procedure Typed_Empty_Input is
         Ignored : constant OpenCV.Core.K_Means_Result :=
           OpenCV.Core.K_Means (Typed_Empty, 1);
      begin
         pragma Unreferenced (Ignored);
      end Typed_Empty_Input;
      procedure Float64_Input is
         Ignored : constant OpenCV.Core.K_Means_Result :=
           OpenCV.Core.K_Means (Float64, 1);
      begin
         pragma Unreferenced (Ignored);
      end Float64_Input;
      procedure Integer_Input is
         Ignored : constant OpenCV.Core.K_Means_Result :=
           OpenCV.Core.K_Means (Integer, 1);
      begin
         pragma Unreferenced (Ignored);
      end Integer_Input;
      procedure Excess_Clusters is
         Ignored : constant OpenCV.Core.K_Means_Result :=
           OpenCV.Core.K_Means (Integer.Convert_To (OpenCV.Core.Float32), 3);
      begin
         pragma Unreferenced (Ignored);
      end Excess_Clusters;
      procedure Negative_Epsilon is
         Ignored : constant OpenCV.Core.K_Means_Result :=
           OpenCV.Core.K_Means
             (Integer.Convert_To (OpenCV.Core.Float32), 1, (2, -1.0));
      begin
         pragma Unreferenced (Ignored);
      end Negative_Epsilon;
   begin
      for Row in 0 .. 3 loop
         Set_Point
           (Parent,
            Row,
            (if Row < 2 then 0.0 else 10.0),
            (if Row < 2 then 0.0 else 10.0));
      end loop;
      declare
         Region : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 0, Y => 0, Width => 2, Height => 4));
         Result : constant OpenCV.Core.K_Means_Result :=
           OpenCV.Core.K_Means (Region, 2, Attempts => 2);
      begin
         AUnit.Assertions.Assert
           (not Region.Is_Continuous and then Result.Labels.Rows = 4,
            "K_Means must accept non-contiguous Regions");
      end;
      Assert_Raises_OpenCV_Error
        (Empty_Input'Access, "K_Means must reject default empty Mats");
      Assert_Raises_OpenCV_Error
        (Typed_Empty_Input'Access, "K_Means must reject typed empty Mats");
      Assert_Raises_OpenCV_Error
        (Float64_Input'Access, "K_Means must reject Float64 Mats");
      Assert_Raises_OpenCV_Error
        (Integer_Input'Access, "K_Means must reject integer Mats");
      Assert_Raises_OpenCV_Error
        (Excess_Clusters'Access, "K_Means must reject excess clusters");
      Assert_Raises_OpenCV_Error
        (Negative_Epsilon'Access, "K_Means must reject negative epsilon");
   end Non_Continuous_Region_And_Invalid_Inputs;

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("K_Means obvious clusters and ownership",
            Two_Obvious_Clusters_Have_Independent_Outputs'Access));
      Result.Add_Test
        (Caller.Create
           ("K_Means K=1 random initialization",
            One_Cluster_Random_Is_Deterministic'Access));
      Result.Add_Test
        (Caller.Create
           ("K_Means multi-channel representations",
            Multi_Channel_And_One_Row_Representations_Work'Access));
      Result.Add_Test
        (Caller.Create
           ("K_Means Region and validation",
            Non_Continuous_Region_And_Invalid_Inputs'Access));
      Result.Add_Test
        (Caller.Create
           ("K_Means initial labels solve and preservation",
            Initial_Labels_Solve_And_Preserve_Inputs'Access));
      Result.Add_Test
        (Caller.Create
           ("K_Means initial-label vector forms and Region",
            Label_Vector_Forms_And_Non_Continuous_Region_Work'Access));
      Result.Add_Test
        (Caller.Create
           ("K_Means empty initial cluster and attempts",
            Empty_Cluster_And_Attempts_Work'Access));
      Result.Add_Test
        (Caller.Create
           ("K_Means initial-label validation",
            Invalid_Initial_Labels_Are_Rejected'Access));
      return Result'Access;
   end Suite;
end K_Means_Tests;
