with AUnit.Assertions;
with AUnit.Test_Caller;
with AUnit.Test_Fixtures;
with OpenCV.Core;

package body Float32_Point_Tests is

   use type OpenCV.Core.Float32_Value;

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   procedure Default_Is_Zero (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Point : OpenCV.Core.Float32_Point;
   begin
      AUnit.Assertions.Assert (Point.X = 0.0, "default X must be 0.0");
      AUnit.Assertions.Assert (Point.Y = 0.0, "default Y must be 0.0");
   end Default_Is_Zero;

   procedure Fractional_Coordinates (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Point : constant OpenCV.Core.Float32_Point := (X => 1.5, Y => -2.25);
   begin
      AUnit.Assertions.Assert (Point.X = 1.5, "fractional X must be retained");
      AUnit.Assertions.Assert
        (Point.Y = -2.25, "fractional Y must be retained");
   end Fractional_Coordinates;

   procedure Negative_Coordinates (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Point : constant OpenCV.Core.Float32_Point :=
        (X => -8.0, Y => OpenCV.Core.Float32_Value'First);
   begin
      AUnit.Assertions.Assert (Point.X = -8.0, "negative X must be retained");
      AUnit.Assertions.Assert
        (Point.Y = OpenCV.Core.Float32_Value'First,
         "minimum finite Y must be retained");
   end Negative_Coordinates;

   procedure Finite_Limits (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Point : constant OpenCV.Core.Float32_Point :=
        (X => OpenCV.Core.Float32_Value'Last,
         Y => OpenCV.Core.Float32_Value'First);
   begin
      AUnit.Assertions.Assert
        (Point.X = OpenCV.Core.Float32_Value'Last,
         "maximum finite X must be retained");
      AUnit.Assertions.Assert
        (Point.Y = OpenCV.Core.Float32_Value'First,
         "minimum finite Y must be retained");
   end Finite_Limits;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Float32_Point default is zero", Default_Is_Zero'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32_Point fractional coordinates",
            Fractional_Coordinates'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32_Point negative coordinates",
            Negative_Coordinates'Access));
      Result.Add_Test
        (Caller.Create ("Float32_Point finite limits", Finite_Limits'Access));
      return Result'Access;
   end Suite;

end Float32_Point_Tests;
