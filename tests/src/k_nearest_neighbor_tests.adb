with AUnit.Assertions;
with AUnit.Test_Caller;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.UInt8_Access;
with Mat_Test_Support;

package body K_Nearest_Neighbor_Tests is

   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use Mat_Test_Support;

   function Float_Indices
     (Result : OpenCV.Core.Nearest_Neighbor_Result) return OpenCV.Core.Mat
   is (Result.Indices.Convert_To (OpenCV.Core.Float32));

   procedure Set_Float_Row
     (Image : in out OpenCV.Core.Mat; Row : Natural; X, Y : Long_Float) is
   begin
      OpenCV.Core.Float32_Access.Set
        (Image, Row, 0, OpenCV.Core.Float32_Value (X));
      OpenCV.Core.Float32_Access.Set
        (Image, Row, 1, OpenCV.Core.Float32_Value (Y));
   end Set_Float_Row;

   procedure Float32_Distances_And_Ordering (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Candidates : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Queries    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result     : OpenCV.Core.Nearest_Neighbor_Result;
      Indices    : OpenCV.Core.Mat;
   begin
      Set_Float_Row (Candidates, 0, 0.0, 0.0);
      Set_Float_Row (Candidates, 1, 3.0, 0.0);
      Set_Float_Row (Candidates, 2, 10.0, 0.0);
      Set_Float_Row (Candidates, 3, 20.0, 0.0);
      Set_Float_Row (Queries, 0, 1.0, 0.0);
      Set_Float_Row (Queries, 1, 12.0, 0.0);
      Result := OpenCV.Core.K_Nearest_Neighbors (Queries, Candidates, 2);
      Indices := Float_Indices (Result);
      AUnit.Assertions.Assert
        (Result.Distances.Rows = 2
         and then Result.Distances.Columns = 2
         and then Result.Distances.Depth = OpenCV.Core.Float32
         and then Result.Distances.Channels = 1
         and then Result.Indices.Rows = 2
         and then Result.Indices.Columns = 2
         and then Result.Indices.Depth = OpenCV.Core.Int32
         and then Result.Indices.Channels = 1
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Indices, 0, 0)),
                     0.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Indices, 0, 1)),
                     1.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Indices, 1, 0)),
                     2.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Indices, 1, 1)),
                     3.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Result.Distances, 0, 0)),
                     1.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Result.Distances, 0, 1)),
                     2.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Result.Distances, 1, 0)),
                     2.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Result.Distances, 1, 1)),
                     8.0),
         "Float32 L2 must return nearest-first unambiguous candidates");
      declare
         Distances_Before : constant OpenCV.Core.Mat := Result.Distances.Clone;
         Indices_Before   : constant OpenCV.Core.Mat := Result.Indices.Clone;
      begin
         Queries.Set_To (OpenCV.Core.Make_Scalar (99.0));
         Candidates.Set_To (OpenCV.Core.Make_Scalar (99.0));
         AUnit.Assertions.Assert
           (Result.Distances.Rows = Distances_Before.Rows
            and then Result.Distances.Columns = Distances_Before.Columns
            and then Result.Distances.Depth = Distances_Before.Depth
            and then Result.Distances.Channels = Distances_Before.Channels
            and then Result.Indices.Rows = Indices_Before.Rows
            and then Result.Indices.Columns = Indices_Before.Columns
            and then Result.Indices.Depth = Indices_Before.Depth
            and then Result.Indices.Channels = Indices_Before.Channels
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get
                             (Result.Distances, 0, 0)),
                        Long_Float
                          (OpenCV.Core.Float32_Access.Get
                             (Distances_Before, 0, 0)))
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get
                             (Result.Distances, 1, 1)),
                        Long_Float
                          (OpenCV.Core.Float32_Access.Get
                             (Distances_Before, 1, 1)))
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get
                             (Float_Indices (Result), 0, 0)),
                        Long_Float
                          (OpenCV.Core.Float32_Access.Get
                             (Indices_Before.Convert_To (OpenCV.Core.Float32),
                              0,
                              0)))
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get
                             (Float_Indices (Result), 1, 1)),
                        Long_Float
                          (OpenCV.Core.Float32_Access.Get
                             (Indices_Before.Convert_To (OpenCV.Core.Float32),
                              1,
                              1))),
            "Nearest-neighbor outputs must retain independent shapes, types,"
            & " distances, and indices after input mutation");
      end;
   end Float32_Distances_And_Ordering;

   procedure Float32_L1_And_Squared_L2 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Candidates : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Queries    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
   begin
      Set_Float_Row (Candidates, 0, 3.0, 4.0);
      Set_Float_Row (Queries, 0, 0.0, 0.0);
      declare
         L1      : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors
             (Queries, Candidates, 1, OpenCV.Core.L1_Distance);
         Squared : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors
             (Queries, Candidates, 1, OpenCV.Core.Squared_L2_Distance);
      begin
         AUnit.Assertions.Assert
           (Approximately_Equal
              (Long_Float
                 (OpenCV.Core.Float32_Access.Get (L1.Distances, 0, 0)),
               7.0)
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get
                             (Squared.Distances, 0, 0)),
                        25.0),
            "Float32 L1 and squared L2 must retain their distinct meanings");
      end;
   end Float32_L1_And_Squared_L2;

   procedure UInt8_Distances (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Candidates : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 1));
      Queries    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Candidates, 0, 0, 3);
      OpenCV.Core.UInt8_Access.Set (Candidates, 1, 0, 15);
      OpenCV.Core.UInt8_Access.Set (Queries, 0, 0, 0);
      declare
         Hamming   : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors
             (Queries, Candidates, 2, OpenCV.Core.Hamming_Distance);
         Hamming_2 : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors
             (Queries, Candidates, 2, OpenCV.Core.Hamming_2_Distance);
         L1        : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors
             (Queries, Candidates, 1, OpenCV.Core.L1_Distance);
      begin
         AUnit.Assertions.Assert
           (Hamming.Distances.Depth = OpenCV.Core.Int32
            and then Hamming_2.Distances.Depth = OpenCV.Core.Int32
            and then L1.Distances.Depth = OpenCV.Core.Float32
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get
                             (Hamming.Distances.Convert_To
                                (OpenCV.Core.Float32),
                              0,
                              0)),
                        2.0)
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get
                             (Hamming_2.Distances.Convert_To
                                (OpenCV.Core.Float32),
                              0,
                              0)),
                        1.0)
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get
                             (L1.Distances, 0, 0)),
                        3.0),
            "UInt8 Hamming, Hamming2, and L1 must use OpenCV output depths");
      end;
   end UInt8_Distances;

   procedure Region_And_Validation (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Parent                : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Other                 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Empty                 : OpenCV.Core.Mat;
      Typed_Empty_Rows      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 2, (OpenCV.Core.Float32, 1));
      Typed_Empty_Columns   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 0, (OpenCV.Core.Float32, 1));
      UInt8_Other           : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Different_Width       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Float32_Multi_Channel : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 2));
      Float64_Other         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float64, 1));
      Int32_Other           : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int32, 1));
      procedure Empty_Query is
         Ignored : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors (Empty, Other, 1);
      begin
         pragma Unreferenced (Ignored);
      end Empty_Query;
      procedure Empty_Candidates is
         Ignored : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors (Other, Empty, 1);
      begin
         pragma Unreferenced (Ignored);
      end Empty_Candidates;
      procedure Typed_Empty_Query is
         Ignored : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors (Typed_Empty_Rows, Other, 1);
      begin
         pragma Unreferenced (Ignored);
      end Typed_Empty_Query;
      procedure Typed_Empty_Candidates is
         Ignored : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors (Other, Typed_Empty_Columns, 1);
      begin
         pragma Unreferenced (Ignored);
      end Typed_Empty_Candidates;
      procedure Mismatched_Depths is
         Ignored : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors (Other, UInt8_Other, 1);
      begin
         pragma Unreferenced (Ignored);
      end Mismatched_Depths;
      procedure Mismatched_Widths is
         Ignored : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors (Different_Width, Other, 1);
      begin
         pragma Unreferenced (Ignored);
      end Mismatched_Widths;
      procedure Multi_Channel_Query is
         Ignored : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors (Float32_Multi_Channel, Other, 1);
      begin
         pragma Unreferenced (Ignored);
      end Multi_Channel_Query;
      procedure Multi_Channel_Candidates is
         Ignored : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors (Other, Float32_Multi_Channel, 1);
      begin
         pragma Unreferenced (Ignored);
      end Multi_Channel_Candidates;
      procedure Float64_Input is
         Ignored : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors (Float64_Other, Float64_Other, 1);
      begin
         pragma Unreferenced (Ignored);
      end Float64_Input;
      procedure Int32_Input is
         Ignored : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors (Int32_Other, Int32_Other, 1);
      begin
         pragma Unreferenced (Ignored);
      end Int32_Input;
      procedure Too_Many is
         Ignored : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors (Other, Other, 3);
      begin
         pragma Unreferenced (Ignored);
      end Too_Many;
      procedure Hamming_Float is
         Ignored : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors
             (Other, Other, 1, OpenCV.Core.Hamming_Distance);
      begin
         pragma Unreferenced (Ignored);
      end Hamming_Float;
      procedure Hamming_2_Float is
         Ignored : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors
             (Other, Other, 1, OpenCV.Core.Hamming_2_Distance);
      begin
         pragma Unreferenced (Ignored);
      end Hamming_2_Float;
   begin
      Set_Float_Row (Parent, 0, 0.0, 0.0);
      Set_Float_Row (Parent, 1, 10.0, 0.0);
      declare
         Region : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 0, Y => 0, Width => 2, Height => 2));
         Result : constant OpenCV.Core.Nearest_Neighbor_Result :=
           OpenCV.Core.K_Nearest_Neighbors (Region, Region, 1);
      begin
         AUnit.Assertions.Assert
           (not Region.Is_Continuous and then Result.Indices.Rows = 2,
            "K_Nearest_Neighbors must accept non-contiguous Regions");
      end;
      Assert_Raises_OpenCV_Error
        (Empty_Query'Access, "K_Nearest_Neighbors must reject empty input");
      Assert_Raises_OpenCV_Error
        (Empty_Candidates'Access,
         "K_Nearest_Neighbors must reject empty candidates");
      Assert_Raises_OpenCV_Error
        (Typed_Empty_Query'Access,
         "K_Nearest_Neighbors must reject typed-empty queries");
      Assert_Raises_OpenCV_Error
        (Typed_Empty_Candidates'Access,
         "K_Nearest_Neighbors must reject typed-empty candidates");
      Assert_Raises_OpenCV_Error
        (Mismatched_Depths'Access,
         "K_Nearest_Neighbors must reject mismatched depths");
      Assert_Raises_OpenCV_Error
        (Mismatched_Widths'Access,
         "K_Nearest_Neighbors must reject mismatched vector widths");
      Assert_Raises_OpenCV_Error
        (Multi_Channel_Query'Access,
         "K_Nearest_Neighbors must reject multi-channel queries");
      Assert_Raises_OpenCV_Error
        (Multi_Channel_Candidates'Access,
         "K_Nearest_Neighbors must reject multi-channel candidates");
      Assert_Raises_OpenCV_Error
        (Float64_Input'Access,
         "K_Nearest_Neighbors must reject Float64 inputs");
      Assert_Raises_OpenCV_Error
        (Int32_Input'Access,
         "K_Nearest_Neighbors must reject unsupported integer inputs");
      Assert_Raises_OpenCV_Error
        (Too_Many'Access, "K_Nearest_Neighbors must reject excessive K");
      Assert_Raises_OpenCV_Error
        (Hamming_Float'Access,
         "K_Nearest_Neighbors must reject Float32 Hamming");
      Assert_Raises_OpenCV_Error
        (Hamming_2_Float'Access,
         "K_Nearest_Neighbors must reject Float32 Hamming2");
   end Region_And_Validation;

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("K nearest Float32 L2 ordering",
            Float32_Distances_And_Ordering'Access));
      Result.Add_Test
        (Caller.Create
           ("K nearest Float32 L1 and squared L2",
            Float32_L1_And_Squared_L2'Access));
      Result.Add_Test
        (Caller.Create ("K nearest UInt8 distances", UInt8_Distances'Access));
      Result.Add_Test
        (Caller.Create
           ("K nearest Region and validation", Region_And_Validation'Access));
      return Result'Access;
   end Suite;
end K_Nearest_Neighbor_Tests;
