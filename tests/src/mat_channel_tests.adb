with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float32_Vec3_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;
with Mat_Test_Support;

package body Mat_Channel_Tests is

   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_8;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.UInt8_Vec3.Vector;

   use Mat_Test_Support;

   procedure Split_UInt8_Vec3_Preserves_Channels_And_Is_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 3));
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (Source, 0, 0, (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set (Source, 0, 1, (4, 5, 6));
      OpenCV.Core.UInt8_Vec3_Access.Set (Source, 1, 0, (7, 8, 9));
      OpenCV.Core.UInt8_Vec3_Access.Set (Source, 1, 1, (10, 11, 12));

      declare
         Channels : OpenCV.Core.Mat_Array := Source.Split;
      begin
         AUnit.Assertions.Assert
           (Channels'First = 0
            and then Channels'Last = 2
            and then Channels'Length = Natural (Source.Channels)
            and then (for all Channel of Channels =>
                        Channel.Channels = 1
                        and then Channel.Depth = Source.Depth
                        and then Channel.Rows = Source.Rows
                        and then Channel.Columns = Source.Columns)
            and then OpenCV.Core.UInt8_Access.Get (Channels (0), 1, 1) = 10
            and then OpenCV.Core.UInt8_Access.Get (Channels (1), 1, 1) = 11
            and then OpenCV.Core.UInt8_Access.Get (Channels (2), 1, 1) = 12,
            "Split must return one correctly shaped single-channel Mat per"
            & " Vec3 component");

         OpenCV.Core.UInt8_Access.Set (Channels (1), 0, 0, 99);
         OpenCV.Core.UInt8_Vec3_Access.Set (Source, 0, 1, (40, 50, 60));
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec3_Access.Get (Source, 0, 0) = (1, 2, 3)
            and then OpenCV.Core.UInt8_Access.Get (Channels (1), 0, 1) = 5,
            "Split outputs and their source must have independent storage");
      end;
   end Split_UInt8_Vec3_Preserves_Channels_And_Is_Independent;

   procedure Split_Float32_And_Non_Continuous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Float32, 3));
   begin
      OpenCV.Core.Float32_Vec3_Access.Set (Parent, 0, 1, (1.5, 2.5, 3.5));
      OpenCV.Core.Float32_Vec3_Access.Set (Parent, 0, 2, (4.5, 5.5, 6.5));
      OpenCV.Core.Float32_Vec3_Access.Set (Parent, 1, 1, (7.5, 8.5, 9.5));
      OpenCV.Core.Float32_Vec3_Access.Set (Parent, 1, 2, (10.5, 11.5, 12.5));

      declare
         Region   : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
         Channels : constant OpenCV.Core.Mat_Array := Region.Split;
      begin
         AUnit.Assertions.Assert
           (not Region.Is_Continuous
            and then Channels'Length = 3
            and then Channels (0).Depth = OpenCV.Core.Float32
            and then Channels (0).Rows = 2
            and then Channels (0).Columns = 2
            and then OpenCV.Core.Float32_Access.Get (Channels (0), 1, 1) = 10.5
            and then OpenCV.Core.Float32_Access.Get (Channels (1), 1, 1) = 11.5
            and then OpenCV.Core.Float32_Access.Get (Channels (2), 1, 1)
                     = 12.5,
            "Split must support Float32 non-continuous Regions");
      end;
   end Split_Float32_And_Non_Continuous_Region;

   procedure Split_Single_Channel_And_Empty_Behavior
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Empty  : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 17);
      declare
         Channels       : OpenCV.Core.Mat_Array := Source.Split;
         Empty_Channels : constant OpenCV.Core.Mat_Array := Empty.Split;
      begin
         OpenCV.Core.UInt8_Access.Set (Channels (0), 0, 0, 99);
         AUnit.Assertions.Assert
           (Channels'Length = 1
            and then Channels (0).Channels = 1
            and then OpenCV.Core.UInt8_Access.Get (Source, 0, 0) = 17
            and then Empty_Channels'Length = 0
            and then Empty_Channels'First = 1
            and then Empty_Channels'Last = 0,
            "Single-channel Split must deep-copy and empty Split must return"
            & " an empty Mat_Array");
      end;
   end Split_Single_Channel_And_Empty_Behavior;

   procedure Split_Outputs_Survive_Source_Finalization
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Channels : OpenCV.Core.Mat_Array (0 .. 2);
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      begin
         OpenCV.Core.UInt8_Vec3_Access.Set (Source, 0, 0, (21, 22, 23));
         Channels := Source.Split;
      end;

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Channels (0), 0, 0) = 21
         and then OpenCV.Core.UInt8_Access.Get (Channels (1), 0, 0) = 22
         and then OpenCV.Core.UInt8_Access.Get (Channels (2), 0, 0) = 23,
         "Split output Mats must remain valid after their source finalizes");
   end Split_Outputs_Survive_Source_Finalization;

   procedure Merge_UInt8_Channels_Preserves_Shape_And_Values
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Red, Green, Blue : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Red, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Green, 0, 0, 2);
      OpenCV.Core.UInt8_Access.Set (Blue, 0, 0, 3);
      OpenCV.Core.UInt8_Access.Set (Red, 1, 1, 10);
      OpenCV.Core.UInt8_Access.Set (Green, 1, 1, 11);
      OpenCV.Core.UInt8_Access.Set (Blue, 1, 1, 12);

      declare
         Channels : constant OpenCV.Core.Mat_Array (1 .. 3) :=
           (Red, Green, Blue);
         Merged   : OpenCV.Core.Mat := OpenCV.Core.Merge (Channels);
      begin
         AUnit.Assertions.Assert
           (Merged.Rows = 2
            and then Merged.Columns = 2
            and then Merged.Depth = OpenCV.Core.UInt8
            and then Merged.Channels = 3
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Merged, 0, 0)
                     = (1, 2, 3)
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Merged, 1, 1)
                     = (10, 11, 12),
            "Merge must concatenate UInt8 channels in array iteration order");

         OpenCV.Core.UInt8_Access.Set (Green, 0, 0, 99);
         OpenCV.Core.UInt8_Vec3_Access.Set (Merged, 1, 1, (20, 21, 22));
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec3_Access.Get (Merged, 0, 0) = (1, 2, 3)
            and then OpenCV.Core.UInt8_Access.Get (Green, 1, 1) = 11,
            "Merge output must have storage independent of all inputs");
      end;
   end Merge_UInt8_Channels_Preserves_Shape_And_Values;

   procedure Merge_Float32_Non_Continuous_Regions_And_Multi_Channel_Inputs
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Float32, 3));
   begin
      OpenCV.Core.Float32_Vec3_Access.Set (Parent, 0, 1, (1.5, 2.5, 3.5));
      OpenCV.Core.Float32_Vec3_Access.Set (Parent, 1, 2, (4.5, 5.5, 6.5));

      declare
         Region : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
         Parts  : constant OpenCV.Core.Mat_Array := Region.Split;
         Input  : constant OpenCV.Core.Mat_Array (4 .. 5) :=
           (Parts (0), Region);
         Merged : constant OpenCV.Core.Mat := OpenCV.Core.Merge (Input);
         Output : constant OpenCV.Core.Mat_Array := Merged.Split;
      begin
         AUnit.Assertions.Assert
           (not Region.Is_Continuous
            and then Merged.Rows = 2
            and then Merged.Columns = 2
            and then Merged.Depth = OpenCV.Core.Float32
            and then Merged.Channels = 4
            and then OpenCV.Core.Float32_Access.Get (Output (0), 1, 1) = 4.5
            and then OpenCV.Core.Float32_Access.Get (Output (1), 1, 1) = 4.5
            and then OpenCV.Core.Float32_Access.Get (Output (2), 1, 1) = 5.5
            and then OpenCV.Core.Float32_Access.Get (Output (3), 1, 1) = 6.5,
            "Merge must support Float32 non-continuous and multi-channel"
            & " inputs");
      end;
   end Merge_Float32_Non_Continuous_Regions_And_Multi_Channel_Inputs;

   procedure Merge_Validation_And_Single_Element_Behavior
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      First             : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Different_Rows    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Different_Columns : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Different_Depth   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));

      procedure Merge_Empty is
         Empty : OpenCV.Core.Mat_Array (1 .. 0);
         Value : OpenCV.Core.Mat := OpenCV.Core.Merge (Empty);
      begin
         pragma Unreferenced (Value);
      end Merge_Empty;

      procedure Merge_Different_Rows is
         Value : OpenCV.Core.Mat :=
           OpenCV.Core.Merge ((0 => First, 1 => Different_Rows));
      begin
         pragma Unreferenced (Value);
      end Merge_Different_Rows;

      procedure Merge_Different_Columns is
         Value : OpenCV.Core.Mat :=
           OpenCV.Core.Merge ((0 => First, 1 => Different_Columns));
      begin
         pragma Unreferenced (Value);
      end Merge_Different_Columns;

      procedure Merge_Different_Depth is
         Value : OpenCV.Core.Mat :=
           OpenCV.Core.Merge ((0 => First, 1 => Different_Depth));
      begin
         pragma Unreferenced (Value);
      end Merge_Different_Depth;
   begin
      OpenCV.Core.UInt8_Access.Set (First, 0, 0, 7);
      OpenCV.Core.UInt8_Access.Set (First, 0, 1, 8);
      declare
         Merged : constant OpenCV.Core.Mat := OpenCV.Core.Merge ((5 => First));
      begin
         AUnit.Assertions.Assert
           (Merged.Channels = 1
            and then OpenCV.Core.UInt8_Access.Get (Merged, 0, 0) = 7
            and then OpenCV.Core.UInt8_Access.Get (Merged, 0, 1) = 8,
            "Merge must copy a single input Mat");
      end;

      Assert_Raises_OpenCV_Error
        (Merge_Empty'Access, "Merge must reject an empty Mat_Array");
      Assert_Raises_OpenCV_Error
        (Merge_Different_Rows'Access, "Merge must reject mismatched rows");
      Assert_Raises_OpenCV_Error
        (Merge_Different_Columns'Access,
         "Merge must reject mismatched columns");
      Assert_Raises_OpenCV_Error
        (Merge_Different_Depth'Access, "Merge must reject mismatched depths");
   end Merge_Validation_And_Single_Element_Behavior;

   procedure Split_Merge_Round_Trip_Is_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Merged : OpenCV.Core.Mat;
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 3));
      begin
         OpenCV.Core.UInt8_Vec3_Access.Set (Source, 0, 0, (30, 31, 32));
         OpenCV.Core.UInt8_Vec3_Access.Set (Source, 0, 1, (40, 41, 42));
         Merged := OpenCV.Core.Merge (Source.Split);
         OpenCV.Core.UInt8_Vec3_Access.Set (Source, 0, 0, (1, 2, 3));
      end;

      AUnit.Assertions.Assert
        (Merged.Rows = 1
         and then Merged.Columns = 2
         and then Merged.Depth = OpenCV.Core.UInt8
         and then Merged.Channels = 3
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Merged, 0, 0)
                  = (30, 31, 32)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Merged, 0, 1)
                  = (40, 41, 42),
         "Split then Merge must reproduce an independent multi-channel Mat");
   end Split_Merge_Round_Trip_Is_Independent;

   procedure Extract_Channel_UInt8_Values_Split_Equivalence_And_Independence
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 3));
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (Source, 0, 0, (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set (Source, 0, 1, (4, 5, 6));
      OpenCV.Core.UInt8_Vec3_Access.Set (Source, 1, 0, (7, 8, 9));
      OpenCV.Core.UInt8_Vec3_Access.Set (Source, 1, 1, (10, 11, 12));

      declare
         First       : constant OpenCV.Core.Mat := Source.Extract_Channel (0);
         Middle      : OpenCV.Core.Mat := Source.Extract_Channel (1);
         Last        : constant OpenCV.Core.Mat := Source.Extract_Channel (2);
         Split_Parts : constant OpenCV.Core.Mat_Array := Source.Split;
      begin
         AUnit.Assertions.Assert
           (First.Channels = 1
            and then First.Rows = Source.Rows
            and then First.Columns = Source.Columns
            and then First.Depth = Source.Depth
            and then OpenCV.Core.UInt8_Access.Get (First, 0, 0) = 1
            and then OpenCV.Core.UInt8_Access.Get (First, 0, 1) = 4
            and then OpenCV.Core.UInt8_Access.Get (First, 1, 0) = 7
            and then OpenCV.Core.UInt8_Access.Get (First, 1, 1) = 10
            and then OpenCV.Core.UInt8_Access.Get (Middle, 0, 0) = 2
            and then OpenCV.Core.UInt8_Access.Get (Middle, 0, 1) = 5
            and then OpenCV.Core.UInt8_Access.Get (Middle, 1, 0) = 8
            and then OpenCV.Core.UInt8_Access.Get (Middle, 1, 1) = 11
            and then OpenCV.Core.UInt8_Access.Get (Last, 0, 0) = 3
            and then OpenCV.Core.UInt8_Access.Get (Last, 0, 1) = 6
            and then OpenCV.Core.UInt8_Access.Get (Last, 1, 0) = 9
            and then OpenCV.Core.UInt8_Access.Get (Last, 1, 1) = 12
            and then (for all Row in 0 .. 1 =>
                        (for all Column in 0 .. 1 =>
                           OpenCV.Core.UInt8_Access.Get (Middle, Row, Column)
                           = OpenCV.Core.UInt8_Access.Get
                               (Split_Parts (1), Row, Column))),
            "Extract_Channel must return the requested UInt8 channel with"
            & " the source shape and depth");

         OpenCV.Core.UInt8_Access.Set (Middle, 0, 0, 99);
         OpenCV.Core.UInt8_Vec3_Access.Set (Source, 0, 1, (40, 50, 60));
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec3_Access.Get (Source, 0, 0) = (1, 2, 3)
            and then OpenCV.Core.UInt8_Access.Get (Middle, 0, 1) = 5,
            "Extract_Channel results and their source must have independent"
            & " storage");
      end;
   end Extract_Channel_UInt8_Values_Split_Equivalence_And_Independence;

   procedure Extract_Channel_Float32_Non_Continuous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Float32, 3));
   begin
      OpenCV.Core.Float32_Vec3_Access.Set (Parent, 0, 1, (1.5, 2.5, 3.5));
      OpenCV.Core.Float32_Vec3_Access.Set (Parent, 0, 2, (4.5, 5.5, 6.5));
      OpenCV.Core.Float32_Vec3_Access.Set (Parent, 1, 1, (7.5, 8.5, 9.5));
      OpenCV.Core.Float32_Vec3_Access.Set (Parent, 1, 2, (10.5, 11.5, 12.5));

      declare
         Region : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
         Result : constant OpenCV.Core.Mat := Region.Extract_Channel (1);
      begin
         AUnit.Assertions.Assert
           (not Region.Is_Continuous
            and then Result.Channels = 1
            and then Result.Depth = OpenCV.Core.Float32
            and then Result.Rows = 2
            and then Result.Columns = 2
            and then OpenCV.Core.Float32_Access.Get (Result, 0, 0) = 2.5
            and then OpenCV.Core.Float32_Access.Get (Result, 0, 1) = 5.5
            and then OpenCV.Core.Float32_Access.Get (Result, 1, 0) = 8.5
            and then OpenCV.Core.Float32_Access.Get (Result, 1, 1) = 11.5,
            "Extract_Channel must support Float32 non-continuous Regions");
      end;
   end Extract_Channel_Float32_Non_Continuous_Region;

   procedure Extract_Channel_Result_Survives_Source_Finalization
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Mat;
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      begin
         OpenCV.Core.UInt8_Vec3_Access.Set (Source, 0, 0, (21, 22, 23));
         Result := Source.Extract_Channel (2);
      end;

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Result, 0, 0) = 23,
         "Extract_Channel result must remain valid after its source"
         & " finalizes");
   end Extract_Channel_Result_Survives_Source_Finalization;

   procedure Extract_Channel_Single_Channel_Validation_And_Empty_Behavior
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Empty  : OpenCV.Core.Mat;

      procedure Extract_Channel_Count is
         Value : OpenCV.Core.Mat := Source.Extract_Channel (1);
      begin
         pragma Unreferenced (Value);
      end Extract_Channel_Count;

      procedure Extract_Channel_Out_Of_Range is
         Value : OpenCV.Core.Mat := Source.Extract_Channel (100);
      begin
         pragma Unreferenced (Value);
      end Extract_Channel_Out_Of_Range;
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 17);
      declare
         Single       : OpenCV.Core.Mat := Source.Extract_Channel (0);
         Empty_Result : constant OpenCV.Core.Mat := Empty.Extract_Channel (0);
      begin
         OpenCV.Core.UInt8_Access.Set (Single, 0, 0, 99);
         AUnit.Assertions.Assert
           (Single.Channels = 1
            and then OpenCV.Core.UInt8_Access.Get (Source, 0, 0) = 17
            and then Empty_Result.Is_Empty
            and then Empty_Result.Channels = 1
            and then Empty_Result.Depth = OpenCV.Core.UInt8,
            "Extract_Channel must copy a single channel and preserve OpenCV"
            & " empty Mat semantics");
      end;

      Assert_Raises_OpenCV_Error
        (Extract_Channel_Count'Access,
         "Extract_Channel must reject a channel equal to Self.Channels");
      Assert_Raises_OpenCV_Error
        (Extract_Channel_Out_Of_Range'Access,
         "Extract_Channel must reject clearly out-of-range channels");
   end Extract_Channel_Single_Channel_Validation_And_Empty_Behavior;

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   Merge_Float32_Region_Test : constant Caller.Test_Method :=
     Merge_Float32_Non_Continuous_Regions_And_Multi_Channel_Inputs'Access;
   Extract_UInt8_Test        : constant Caller.Test_Method :=
     Extract_Channel_UInt8_Values_Split_Equivalence_And_Independence'Access;
   Extract_Finalization_Test : constant Caller.Test_Method :=
     Extract_Channel_Result_Survives_Source_Finalization'Access;
   Extract_Validation_Test   : constant Caller.Test_Method :=
     Extract_Channel_Single_Channel_Validation_And_Empty_Behavior'Access;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Split UInt8 Vec3 preserves channels and independence",
            Split_UInt8_Vec3_Preserves_Channels_And_Is_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Split Float32 and non-continuous Region",
            Split_Float32_And_Non_Continuous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Split single-channel and empty behavior",
            Split_Single_Channel_And_Empty_Behavior'Access));
      Result.Add_Test
        (Caller.Create
           ("Split outputs survive source finalization",
            Split_Outputs_Survive_Source_Finalization'Access));
      Result.Add_Test
        (Caller.Create
           ("Merge UInt8 channels preserves shape and values",
            Merge_UInt8_Channels_Preserves_Shape_And_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Merge Float32 non-continuous Regions and"
            & " multi-channel inputs",
            Merge_Float32_Region_Test));
      Result.Add_Test
        (Caller.Create
           ("Merge validation and single-element behavior",
            Merge_Validation_And_Single_Element_Behavior'Access));
      Result.Add_Test
        (Caller.Create
           ("Split Merge round trip is independent",
            Split_Merge_Round_Trip_Is_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Extract channel UInt8 values Split equivalence and independence",
            Extract_UInt8_Test));
      Result.Add_Test
        (Caller.Create
           ("Extract channel Float32 non-continuous Region",
            Extract_Channel_Float32_Non_Continuous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Extract channel result survives source finalization",
            Extract_Finalization_Test));
      Result.Add_Test
        (Caller.Create
           ("Extract channel single-channel validation and empty behavior",
            Extract_Validation_Test));
      return Result'Access;
   end Suite;

end Mat_Channel_Tests;
