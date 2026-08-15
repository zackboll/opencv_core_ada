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

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

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
      return Result'Access;
   end Suite;

end Mat_Channel_Tests;
