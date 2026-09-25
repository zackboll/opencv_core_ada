with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Int8_Access;
with OpenCV.Core.Int8_Mat_View;

package body Int8_Mat_View_Tests is

   use type OpenCV.Int8_Value;
   use Mat_Test_Support;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   procedure Packed_View_Is_Bidirectional_And_Clone_Escapes
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data   : aliased OpenCV.Core.Int8_Mat_View.Buffer_Array :=
        (11 => -128, 12 => -1, 13 => 0, 14 => 127, 15 => 1, 16 => 9);
      Copy   : OpenCV.Core.Mat;
      Raised : Boolean := False;

      procedure Process (Image : in out OpenCV.Core.Mat) is
         procedure Escape is
            Alias : OpenCV.Core.Mat;
            pragma Unreferenced (Alias);
         begin
            begin
               Alias := Image;
            exception
               when Program_Error =>
                  raise OpenCV.OpenCV_Error;
            end;
         end Escape;
         procedure Region_Escape is
            View : OpenCV.Core.Mat;
            pragma Unreferenced (View);
         begin
            begin
               View :=
                 Image.Region ((X => 0, Y => 0, Width => 1, Height => 1));
            exception
               when Program_Error =>
                  raise OpenCV.OpenCV_Error;
            end;
         end Region_Escape;
      begin
         Data (12) := -127;
         AUnit.Assertions.Assert
           (OpenCV.Core.Int8_Access.Get (Image, 0, 1) = -127,
            "Int8 caller writes must be immediately visible");
         OpenCV.Core.Int8_Access.Set (Image, 1, 0, 126);
         AUnit.Assertions.Assert
           (Data (14) = 126, "Int8 Mat writes must update caller storage");
         Assert_Raises_OpenCV_Error (Escape'Access, "Int8 shallow escape");
         Assert_Raises_OpenCV_Error
           (Region_Escape'Access, "Int8 Region escape");
         Copy := Image.Clone;
      end Process;
      procedure Wrong_Length is
         procedure Mark (Image : in out OpenCV.Core.Mat) is
            pragma Unreferenced (Image);
         begin
            Raised := True;
         end Mark;
      begin
         OpenCV.Core.Int8_Mat_View.With_Writable_Mat_View
           (Data, 2, 4, Mark'Access);
      end Wrong_Length;
   begin
      OpenCV.Core.Int8_Mat_View.With_Writable_Mat_View
        (Data, 2, 3, Process'Access);
      OpenCV.Core.Int8_Access.Set (Copy, 0, 0, 7);
      Assert_Raises_OpenCV_Error (Wrong_Length'Access, "Int8 packed length");
      AUnit.Assertions.Assert
        (Data (11) = -128
         and then Data (14) = 126
         and then OpenCV.Core.Int8_Access.Get (Copy, 0, 0) = 7
         and then not Raised,
         "Int8 packed views must reject escapes and keep clones independent");
   end Packed_View_Is_Bidirectional_And_Clone_Escapes;

   procedure Strided_View_Preserves_Padding_And_Capacity
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data    : aliased OpenCV.Core.Int8_Mat_View.Buffer_Array :=
        (20 .. 31 => -99, 32 => 77);
      Short   : aliased OpenCV.Core.Int8_Mat_View.Buffer_Array :=
        (1 .. 11 => -3);
      Invoked : Boolean := False;

      procedure Process (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (not Image.Is_Continuous, "Padded Int8 view must be strided");
         OpenCV.Core.Int8_Access.Set (Image, 0, 0, -128);
         OpenCV.Core.Int8_Access.Set (Image, 1, 2, 127);
         Data (23) := -1;
         AUnit.Assertions.Assert
           (OpenCV.Core.Int8_Access.Get (Image, 0, 3) = -1,
            "Int8 padding-adjacent caller writes must be visible");
      end Process;
      procedure Mark (Image : in out OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Mark;
      procedure Too_Small_Stride is
      begin
         OpenCV.Core.Int8_Mat_View.With_Writable_Strided_Mat_View
           (Data, 2, 4, 3, Mark'Access);
      end Too_Small_Stride;
      procedure Too_Short is
      begin
         OpenCV.Core.Int8_Mat_View.With_Writable_Strided_Mat_View
           (Short, 2, 4, 6, Mark'Access);
      end Too_Short;
   begin
      OpenCV.Core.Int8_Mat_View.With_Writable_Strided_Mat_View
        (Data, 2, 4, 6, Process'Access);
      Assert_Raises_OpenCV_Error
        (Too_Small_Stride'Access, "short Int8 stride");
      Assert_Raises_OpenCV_Error (Too_Short'Access, "short Int8 capacity");
      AUnit.Assertions.Assert
        (Data (20) = -128
         and then Data (23) = -1
         and then Data (28) = 127
         and then Data (24) = -99
         and then Data (31) = -99
         and then Data (32) = 77
         and then not Invoked,
         "Int8 stride must map logical elements and leave padding untouched");
   end Strided_View_Preserves_Padding_And_Capacity;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Int8 packed views are bidirectional and clones may escape",
            Packed_View_Is_Bidirectional_And_Clone_Escapes'Access));
      Result.Add_Test
        (Caller.Create
           ("Int8 strided views preserve padding and full-stride capacity",
            Strided_View_Preserves_Padding_And_Capacity'Access));
      return Result'Access;
   end Suite;

end Int8_Mat_View_Tests;
