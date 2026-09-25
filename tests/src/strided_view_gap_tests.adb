with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Float32_Vec3;
with OpenCV.Core.Float32_Vec3_Access;
with OpenCV.Core.Float32_Vec3_Mat_View;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Mat_View;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;
with OpenCV.Core.UInt8_Vec3_Mat_View;

package body Strided_View_Gap_Tests is

   use type Interfaces.IEEE_Float_32;
   use type OpenCV.UInt8_Value;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.UInt8_Vec3.Vector;
   use Mat_Test_Support;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Close
     (Left, Right : OpenCV.Core.Float32_Vec3.Vector) return Boolean
   is (abs (Left (0) - Right (0)) < 0.000_1
       and then abs (Left (1) - Right (1)) < 0.000_1
       and then abs (Left (2) - Right (2)) < 0.000_1);

   procedure UInt8_C1_Stride_Leaves_Padding_Untouched (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data    : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (1 .. 12 => 9);
      Short   : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (1 .. 11 => 9);
      Invoked : Boolean := False;

      procedure Process (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.UInt8_Access.Set (Image, 0, 0, 11);
         OpenCV.Core.UInt8_Access.Set (Image, 1, 3, 250);
      end Process;
      procedure Mark (Image : in out OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Mark;
      procedure Too_Short is
      begin
         OpenCV.Core.UInt8_Mat_View.With_Writable_Strided_Mat_View
           (Short, 2, 4, 6, Mark'Access);
      end Too_Short;
   begin
      OpenCV.Core.UInt8_Mat_View.With_Writable_Strided_Mat_View
        (Data, 2, 4, 6, Process'Access);
      Assert_Raises_OpenCV_Error
        (Too_Short'Access, "UInt8 full-stride capacity");
      AUnit.Assertions.Assert
        (Data (1) = 11
         and then Data (10) = 250
         and then Data (5) = 9
         and then Data (12) = 9
         and then not Invoked,
         "UInt8 C1 stride must preserve padding and require full capacity");
   end UInt8_C1_Stride_Leaves_Padding_Untouched;

   procedure UInt8_Vec3_Stride_Counts_Complete_Pixels (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      function Pixel
        (A, B, C : OpenCV.UInt8_Value) return OpenCV.Core.UInt8_Vec3.Vector
      is (A, B, C);
      Data : aliased OpenCV.Core.UInt8_Vec3_Mat_View.Buffer_Array :=
        (7 .. 16 => Pixel (9, 8, 7));

      procedure Process (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (Image.Rows = 2
            and then Image.Columns = 3
            and then Image.Channels = 3
            and then not Image.Is_Continuous,
            "UInt8 Vec3 stride must describe complete padded pixels");
         OpenCV.Core.UInt8_Vec3_Access.Set (Image, 0, 2, Pixel (1, 2, 3));
         Data (13) := Pixel (4, 5, 6);
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec3_Access.Get (Image, 1, 1) = Pixel (4, 5, 6),
            "UInt8 Vec3 caller pixel writes must be immediately visible");
      end Process;
   begin
      OpenCV.Core.UInt8_Vec3_Mat_View.With_Writable_Strided_Mat_View
        (Data, 2, 3, 5, Process'Access);
      AUnit.Assertions.Assert
        (Data (9) = Pixel (1, 2, 3)
         and then Data (10) = Pixel (9, 8, 7)
         and then Data (16) = Pixel (9, 8, 7),
         "UInt8 Vec3 padding pixels must remain untouched");
   end UInt8_Vec3_Stride_Counts_Complete_Pixels;

   procedure Float32_Vec3_Stride_Counts_Complete_Pixels (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      function Pixel
        (A, B, C : Interfaces.IEEE_Float_32)
         return OpenCV.Core.Float32_Vec3.Vector
      is (A, B, C);
      Data : aliased OpenCV.Core.Float32_Vec3_Mat_View.Buffer_Array :=
        (3 .. 12 => Pixel (1.5, -2.5, 3.5));

      procedure Process (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Float32_Vec3_Access.Set
           (Image, 1, 2, Pixel (-4.25, 5.5, 6.75));
         Data (4) := Pixel (0.25, 0.5, 0.75);
         AUnit.Assertions.Assert
           (Close
              (OpenCV.Core.Float32_Vec3_Access.Get (Image, 0, 1),
               Pixel (0.25, 0.5, 0.75)),
            "Float32 Vec3 caller pixel writes must be immediately visible");
      end Process;
   begin
      OpenCV.Core.Float32_Vec3_Mat_View.With_Writable_Strided_Mat_View
        (Data, 2, 3, 5, Process'Access);
      AUnit.Assertions.Assert
        (Close (Data (10), Pixel (-4.25, 5.5, 6.75))
         and then Close (Data (6), Pixel (1.5, -2.5, 3.5))
         and then Close (Data (8), Pixel (1.5, -2.5, 3.5)),
         "Float32 Vec3 padding pixels must remain untouched");
   end Float32_Vec3_Stride_Counts_Complete_Pixels;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("UInt8 C1 strided views preserve padding and full capacity",
            UInt8_C1_Stride_Leaves_Padding_Untouched'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 strided views count complete pixels",
            UInt8_Vec3_Stride_Counts_Complete_Pixels'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec3 strided views count complete pixels",
            Float32_Vec3_Stride_Counts_Complete_Pixels'Access));
      return Result'Access;
   end Suite;

end Strided_View_Gap_Tests;
