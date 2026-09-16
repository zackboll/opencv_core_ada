with AUnit.Assertions;
with AUnit.Test_Caller;
with AUnit.Test_Fixtures;
with OpenCV;

package body Rotated_Rect_Tests is

   use type OpenCV.Float32_Value;

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   procedure Float32_Size_Defaults (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Value : OpenCV.Float32_Size;
   begin
      AUnit.Assertions.Assert
        (Value.Width = 0.0, "default width must be zero");
      AUnit.Assertions.Assert
        (Value.Height = 0.0, "default height must be zero");
   end Float32_Size_Defaults;

   procedure Float32_Size_Fractional (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Value : constant OpenCV.Float32_Size :=
        (Width => 1.5, Height => -2.25);
   begin
      AUnit.Assertions.Assert (Value.Width = 1.5, "fractional width retained");
      AUnit.Assertions.Assert
        (Value.Height = -2.25, "fractional height retained");
   end Float32_Size_Fractional;

   procedure Rotated_Rect_Defaults (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Value : OpenCV.Rotated_Rect;
   begin
      AUnit.Assertions.Assert (Value.Center.X = 0.0, "default center X");
      AUnit.Assertions.Assert (Value.Center.Y = 0.0, "default center Y");
      AUnit.Assertions.Assert (Value.Size.Width = 0.0, "default width");
      AUnit.Assertions.Assert (Value.Size.Height = 0.0, "default height");
      AUnit.Assertions.Assert (Value.Angle_Degrees = 0.0, "default angle");
   end Rotated_Rect_Defaults;

   procedure Fractional_Negative_Center (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Value : constant OpenCV.Rotated_Rect :=
        (Center        => (X => -1.25, Y => 3.5),
         Size          => (Width => 0.0, Height => 0.0),
         Angle_Degrees => 0.0);
   begin
      AUnit.Assertions.Assert (Value.Center.X = -1.25, "negative center X");
      AUnit.Assertions.Assert (Value.Center.Y = 3.5, "fractional center Y");
   end Fractional_Negative_Center;

   procedure Aggregate_Size (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Value : constant OpenCV.Rotated_Rect :=
        (Center        => (X => 0.0, Y => 0.0),
         Size          => (Width => 7.25, Height => 4.5),
         Angle_Degrees => 0.0);
   begin
      AUnit.Assertions.Assert (Value.Size.Width = 7.25, "aggregate width");
      AUnit.Assertions.Assert (Value.Size.Height = 4.5, "aggregate height");
   end Aggregate_Size;

   procedure Positive_Angle (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Value : constant OpenCV.Rotated_Rect :=
        (Center        => (X => 0.0, Y => 0.0),
         Size          => (Width => 0.0, Height => 0.0),
         Angle_Degrees => 123.5);
   begin
      AUnit.Assertions.Assert
        (Value.Angle_Degrees = 123.5, "positive angle retained");
   end Positive_Angle;

   procedure Negative_Angle (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Value : constant OpenCV.Rotated_Rect :=
        (Center        => (X => 0.0, Y => 0.0),
         Size          => (Width => 0.0, Height => 0.0),
         Angle_Degrees => -271.25);
   begin
      AUnit.Assertions.Assert
        (Value.Angle_Degrees = -271.25, "negative angle retained");
   end Negative_Angle;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Float32_Size defaults", Float32_Size_Defaults'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32_Size fractional values", Float32_Size_Fractional'Access));
      Result.Add_Test
        (Caller.Create
           ("Rotated_Rect defaults", Rotated_Rect_Defaults'Access));
      Result.Add_Test
        (Caller.Create
           ("Rotated_Rect fractional negative center",
            Fractional_Negative_Center'Access));
      Result.Add_Test
        (Caller.Create ("Rotated_Rect aggregate size", Aggregate_Size'Access));
      Result.Add_Test
        (Caller.Create ("Rotated_Rect positive angle", Positive_Angle'Access));
      Result.Add_Test
        (Caller.Create ("Rotated_Rect negative angle", Negative_Angle'Access));
      return Result'Access;
   end Suite;

end Rotated_Rect_Tests;
