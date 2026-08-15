with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float32_Vec3;
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
   use type OpenCV.Core.Float32_Vec3.Vector;
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

   procedure Insert_Channel_UInt8_Channels_And_Shared_Destination
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Destination : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 3));
      Alias       : constant OpenCV.Core.Mat := Destination;
      First       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Middle      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Last        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (Destination, 0, 0, (10, 20, 30));
      OpenCV.Core.UInt8_Vec3_Access.Set (Destination, 0, 1, (40, 50, 60));
      OpenCV.Core.UInt8_Access.Set (First, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (First, 0, 1, 4);
      OpenCV.Core.UInt8_Access.Set (Middle, 0, 0, 2);
      OpenCV.Core.UInt8_Access.Set (Middle, 0, 1, 5);
      OpenCV.Core.UInt8_Access.Set (Last, 0, 0, 3);
      OpenCV.Core.UInt8_Access.Set (Last, 0, 1, 6);

      Destination.Insert_Channel (First, 0);
      Destination.Insert_Channel (Middle, 1);
      Destination.Insert_Channel (Last, 2);

      AUnit.Assertions.Assert
        (Destination.Rows = 1
         and then Destination.Columns = 2
         and then Destination.Depth = OpenCV.Core.UInt8
         and then Destination.Channels = 3
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Destination, 0, 0)
                  = (1, 2, 3)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Destination, 0, 1)
                  = (4, 5, 6)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Alias, 0, 0) = (1, 2, 3)
         and then OpenCV.Core.UInt8_Access.Get (First, 0, 0) = 1,
         "Insert_Channel must update each destination channel in place without"
         & " changing source, shape, or element type");
   end Insert_Channel_UInt8_Channels_And_Shared_Destination;

   procedure Insert_Channel_Float32_And_Non_Continuous_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Float_Destination  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 3));
      Float_Source       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Source_Parent      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.UInt8, 1));
      Destination_Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.UInt8, 3));
   begin
      OpenCV.Core.Float32_Vec3_Access.Set
        (Float_Destination, 0, 0, (1.0, 2.0, 3.0));
      OpenCV.Core.Float32_Access.Set (Float_Source, 0, 0, 9.5);
      Float_Destination.Insert_Channel (Float_Source, 1);

      Source_Parent.Set_To (OpenCV.Core.Make_Scalar (1.0));
      OpenCV.Core.UInt8_Access.Set (Source_Parent, 0, 1, 41);
      OpenCV.Core.UInt8_Access.Set (Source_Parent, 0, 2, 42);
      OpenCV.Core.UInt8_Access.Set (Source_Parent, 1, 1, 43);
      OpenCV.Core.UInt8_Access.Set (Source_Parent, 1, 2, 44);
      Destination_Parent.Set_To (OpenCV.Core.Make_Scalar (10.0, 20.0, 30.0));

      declare
         Source_Region      : constant OpenCV.Core.Mat :=
           Source_Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
         Destination_Region : OpenCV.Core.Mat :=
           Destination_Parent.Region
             ((X => 1, Y => 1, Width => 2, Height => 2));
      begin
         Destination_Region.Insert_Channel (Source_Region, 1);
         AUnit.Assertions.Assert
           (not Source_Region.Is_Continuous
            and then not Destination_Region.Is_Continuous
            and then OpenCV.Core.Float32_Vec3_Access.Get
                       (Float_Destination, 0, 0)
                     = (1.0, 9.5, 3.0)
            and then OpenCV.Core.UInt8_Vec3_Access.Get
                       (Destination_Parent, 1, 1)
                     = (10, 41, 30)
            and then OpenCV.Core.UInt8_Vec3_Access.Get
                       (Destination_Parent, 1, 2)
                     = (10, 42, 30)
            and then OpenCV.Core.UInt8_Vec3_Access.Get
                       (Destination_Parent, 2, 1)
                     = (10, 43, 30)
            and then OpenCV.Core.UInt8_Vec3_Access.Get
                       (Destination_Parent, 2, 2)
                     = (10, 44, 30)
            and then OpenCV.Core.UInt8_Vec3_Access.Get
                       (Destination_Parent, 0, 0)
                     = (10, 20, 30)
            and then OpenCV.Core.UInt8_Vec3_Access.Get
                       (Destination_Parent, 1, 0)
                     = (10, 20, 30)
            and then OpenCV.Core.UInt8_Access.Get (Source_Parent, 1, 2) = 44,
            "Insert_Channel must support Float32 and non-continuous Regions"
            & " while updating only the destination Region's shared storage");
      end;
   end Insert_Channel_Float32_And_Non_Continuous_Regions;

   procedure Insert_Channel_Extract_Round_Trip_And_Empty_Behavior
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source            : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 3));
      Destination       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 3));
      Single            : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Empty_Source      : OpenCV.Core.Mat;
      Empty_Destination : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (Source, 0, 0, (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set (Source, 0, 1, (4, 5, 6));
      OpenCV.Core.UInt8_Vec3_Access.Set (Destination, 0, 0, (10, 20, 30));
      OpenCV.Core.UInt8_Vec3_Access.Set (Destination, 0, 1, (40, 50, 60));
      OpenCV.Core.UInt8_Access.Set (Single, 0, 0, 99);

      declare
         Extracted : constant OpenCV.Core.Mat := Source.Extract_Channel (2);
      begin
         Destination.Insert_Channel (Extracted, 1);
      end;
      Single.Insert_Channel (Single, 0);
      Empty_Destination.Insert_Channel (Empty_Source, 0);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Destination, 0, 0) = (10, 3, 30)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Destination, 0, 1)
                  = (40, 6, 60)
         and then OpenCV.Core.UInt8_Access.Get (Single, 0, 0) = 99
         and then Empty_Destination.Is_Empty
         and then Empty_Destination.Channels = 1
         and then Empty_Destination.Depth = OpenCV.Core.UInt8,
         "Extract_Channel output must insert into the selected destination"
         & " channel; single-channel and empty Mats accept channel zero");
   end Insert_Channel_Extract_Round_Trip_And_Empty_Behavior;

   procedure Insert_Channel_Validation (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Destination          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 3));
      Multi_Channel_Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 2));
      Different_Rows       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Different_Columns    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 1));
      Different_Depth      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));

      procedure Insert_Multi_Channel_Source is
      begin
         Destination.Insert_Channel (Multi_Channel_Source, 0);
      end Insert_Multi_Channel_Source;

      procedure Insert_Different_Rows is
      begin
         Destination.Insert_Channel (Different_Rows, 0);
      end Insert_Different_Rows;

      procedure Insert_Different_Columns is
      begin
         Destination.Insert_Channel (Different_Columns, 0);
      end Insert_Different_Columns;

      procedure Insert_Different_Depth is
      begin
         Destination.Insert_Channel (Different_Depth, 0);
      end Insert_Different_Depth;

      procedure Insert_Channel_Count is
      begin
         Destination.Insert_Channel (Different_Depth, 3);
      end Insert_Channel_Count;
   begin
      Assert_Raises_OpenCV_Error
        (Insert_Multi_Channel_Source'Access,
         "Insert_Channel must reject a source with more than one channel");
      Assert_Raises_OpenCV_Error
        (Insert_Different_Rows'Access,
         "Insert_Channel must reject mismatched row counts");
      Assert_Raises_OpenCV_Error
        (Insert_Different_Columns'Access,
         "Insert_Channel must reject mismatched column counts");
      Assert_Raises_OpenCV_Error
        (Insert_Different_Depth'Access,
         "Insert_Channel must reject mismatched depths");
      Assert_Raises_OpenCV_Error
        (Insert_Channel_Count'Access,
         "Insert_Channel must reject a channel equal to Self.Channels");
   end Insert_Channel_Validation;

   procedure Mix_Channels_Uses_Ada_Indices_And_Zero_Fill
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Sources      : OpenCV.Core.Mat_Array (5 .. 6) :=
        (5 => OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 3)),
         6 => OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1)));
      Destinations : OpenCV.Core.Mat_Array (10 .. 11) :=
        (10 => OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 3)),
         11 => OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 3)));
      Routes       : constant OpenCV.Core.Channel_Route_Array (2 .. 5) :=
        (2 =>
           (Source_Kind         => OpenCV.Core.From_Source,
            Destination_Index   => 10,
            Destination_Channel => 0,
            Source_Index        => 5,
            Source_Channel      => 1),
         3 =>
           (Source_Kind         => OpenCV.Core.From_Source,
            Destination_Index   => 10,
            Destination_Channel => 1,
            Source_Index        => 6,
            Source_Channel      => 0),
         4 =>
           (Source_Kind         => OpenCV.Core.Zero_Fill,
            Destination_Index   => 11,
            Destination_Channel => 0),
         5 =>
           (Source_Kind         => OpenCV.Core.From_Source,
            Destination_Index   => 11,
            Destination_Channel => 1,
            Source_Index        => 5,
            Source_Channel      => 0));
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (Sources (5), 0, 0, (11, 12, 0));
      OpenCV.Core.UInt8_Vec3_Access.Set (Sources (5), 0, 1, (21, 22, 0));
      OpenCV.Core.UInt8_Access.Set (Sources (6), 0, 0, 13);
      OpenCV.Core.UInt8_Access.Set (Sources (6), 0, 1, 23);
      OpenCV.Core.Mix_Channels (Sources, Destinations, Routes);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Destinations (10), 0, 0)
         = (12, 13, 0)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Destinations (10), 0, 1)
                  = (22, 23, 0)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Destinations (11), 0, 0)
                  = (0, 11, 0)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Destinations (11), 0, 1)
                  = (0, 21, 0),
         "Mix_Channels must use actual Ada array indices and zero-fill"
         & " routes");
   end Mix_Channels_Uses_Ada_Indices_And_Zero_Fill;

   procedure Mix_Channels_Validation_And_Empty_Routes
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source              : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Destinations        : OpenCV.Core.Mat_Array (3 .. 3) :=
        (3 => OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1)));
      Sources             : constant OpenCV.Core.Mat_Array (7 .. 7) :=
        (7 => Source);
      Duplicate_Routes    :
        constant OpenCV.Core.Channel_Route_Array (0 .. 1) :=
          (0 => (OpenCV.Core.From_Source, 3, 0, 7, 0),
           1 => (OpenCV.Core.Zero_Fill, 3, 0));
      Invalid_Index_Route :
        constant OpenCV.Core.Channel_Route_Array (0 .. 0) :=
          (0 => (OpenCV.Core.From_Source, 4, 0, 7, 0));
      Empty_Routes        :
        constant OpenCV.Core.Channel_Route_Array (1 .. 0) := (others => <>);

      procedure Mix_Duplicate is
      begin
         OpenCV.Core.Mix_Channels (Sources, Destinations, Duplicate_Routes);
      end Mix_Duplicate;

      procedure Mix_Invalid_Index is
      begin
         OpenCV.Core.Mix_Channels (Sources, Destinations, Invalid_Index_Route);
      end Mix_Invalid_Index;
   begin
      OpenCV.Core.UInt8_Access.Set (Destinations (3), 0, 0, 77);
      OpenCV.Core.Mix_Channels (Sources, Destinations, Empty_Routes);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Destinations (3), 0, 0) = 77,
         "Mix_Channels with empty Routes must be a no-op");
      Assert_Raises_OpenCV_Error
        (Mix_Duplicate'Access,
         "Mix_Channels must reject duplicate destination channels");
      Assert_Raises_OpenCV_Error
        (Mix_Invalid_Index'Access,
         "Mix_Channels must validate actual destination array indices");
   end Mix_Channels_Validation_And_Empty_Routes;

   procedure Mix_Channels_Mutates_In_Place (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Sources      : constant OpenCV.Core.Mat_Array (5 .. 5) := (5 => Image);
      Destinations : OpenCV.Core.Mat_Array (10 .. 10) := (10 => Image);
      Routes       : constant OpenCV.Core.Channel_Route_Array (0 .. 0) :=
        (0 =>
           (Source_Kind         => OpenCV.Core.From_Source,
            Destination_Index   => 10,
            Destination_Channel => 0,
            Source_Index        => 5,
            Source_Channel      => 2));
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (Image, 0, 0, (1, 2, 3));
      OpenCV.Core.Mix_Channels (Sources, Destinations, Routes);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Image, 0, 0) = (3, 2, 3),
         "Mix_Channels must mutate preallocated shared destination storage"
         & " in place");
   end Mix_Channels_Mutates_In_Place;

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
   Insert_UInt8_Test         : constant Caller.Test_Method :=
     Insert_Channel_UInt8_Channels_And_Shared_Destination'Access;
   Insert_Region_Test        : constant Caller.Test_Method :=
     Insert_Channel_Float32_And_Non_Continuous_Regions'Access;
   Insert_Round_Trip_Test    : constant Caller.Test_Method :=
     Insert_Channel_Extract_Round_Trip_And_Empty_Behavior'Access;
   Insert_Validation_Test    : constant Caller.Test_Method :=
     Insert_Channel_Validation'Access;
   Mix_Indices_Test          : constant Caller.Test_Method :=
     Mix_Channels_Uses_Ada_Indices_And_Zero_Fill'Access;
   Mix_Validation_Test       : constant Caller.Test_Method :=
     Mix_Channels_Validation_And_Empty_Routes'Access;
   Mix_In_Place_Test         : constant Caller.Test_Method :=
     Mix_Channels_Mutates_In_Place'Access;

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
           ("Mix channels uses Ada indices and zero fill", Mix_Indices_Test));
      Result.Add_Test
        (Caller.Create
           ("Mix channels validation and empty routes", Mix_Validation_Test));
      Result.Add_Test
        (Caller.Create ("Mix channels mutates in place", Mix_In_Place_Test));
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
      Result.Add_Test
        (Caller.Create
           ("Insert channel UInt8 channels and shared destination",
            Insert_UInt8_Test));
      Result.Add_Test
        (Caller.Create
           ("Insert channel Float32 and non-continuous Regions",
            Insert_Region_Test));
      Result.Add_Test
        (Caller.Create
           ("Insert channel Extract round trip and empty behavior",
            Insert_Round_Trip_Test));
      Result.Add_Test
        (Caller.Create ("Insert channel validation", Insert_Validation_Test));
      return Result'Access;
   end Suite;

end Mat_Channel_Tests;
