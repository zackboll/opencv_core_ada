with AUnit.Assertions;
with AUnit.Test_Caller;
with AUnit.Test_Fixtures;
with Interfaces;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.UInt8_Access;

package body OpenCV_Value_Tests is

   use type OpenCV.Point;
   use type OpenCV.Point_Coordinate;
   use type OpenCV.Size;
   use type OpenCV.Size_Coordinate;
   use type OpenCV.Rect;
   use type OpenCV.Scalar;
   use type OpenCV.Border_Kind;
   use type OpenCV.Angle_Unit;
   use type Interfaces.Unsigned_8;

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   procedure Root_Defaults_And_Coordinate_Constraints (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Origin : OpenCV.Point;
      Extent : OpenCV.Size;
      Area   : OpenCV.Rect;
      Pixel  : constant OpenCV.UInt8_Value := 200;
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
   begin
      AUnit.Assertions.Assert
        (Origin.X = 0 and then Origin.Y = 0, "default Point is (0, 0)");
      AUnit.Assertions.Assert
        (Extent.Width = 0 and then Extent.Height = 0,
         "default Size is (0, 0)");
      AUnit.Assertions.Assert
        (Area.X = 0
         and then Area.Y = 0
         and then Area.Width = 0
         and then Area.Height = 0,
         "default Rect is (0, 0, 0, 0)");
      AUnit.Assertions.Assert
        (OpenCV.Point_Coordinate'First < 0, "Point coordinates remain signed");
      AUnit.Assertions.Assert
        (OpenCV.Size_Coordinate'First = 0,
         "Size coordinates remain nonnegative");
      Image.Set_To (OpenCV.Make_Scalar (Long_Float (Pixel)));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Image, 0, 0) = Pixel,
         "UInt8_Value remains usable with Core Set_To");
   end Root_Defaults_And_Coordinate_Constraints;

   procedure Point_Array_Bounds_And_Empty_Arrays (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Empty      : constant OpenCV.Point_Array (1 .. 0) := (others => <>);
      Zero_Based : constant OpenCV.Point_Array (0 .. 1) :=
        ((X => 1, Y => 2), (X => -3, Y => 4));
      One_Based  : constant OpenCV.Point_Array (1 .. 1) :=
        (1 => (X => 5, Y => 6));
   begin
      AUnit.Assertions.Assert
        (Empty'Length = 0 and then Empty'First = 1 and then Empty'Last = 0,
         "empty Point_Array uses the null range 1 .. 0");
      AUnit.Assertions.Assert
        (Zero_Based'First = 0
         and then Zero_Based (0) = (X => 1, Y => 2)
         and then Zero_Based (1) = (X => -3, Y => 4),
         "Point_Array preserves zero-based bounds and negative coordinates");
      AUnit.Assertions.Assert
        (One_Based'First = 1 and then One_Based (1) = (X => 5, Y => 6),
         "Point_Array preserves nonzero lower bounds");
   end Point_Array_Bounds_And_Empty_Arrays;

   procedure Make_Scalar_Preserves_Defaults_And_Components
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Defaulted : constant OpenCV.Scalar := OpenCV.Make_Scalar (7.0);
      Explicit  : constant OpenCV.Scalar :=
        OpenCV.Make_Scalar (1.0, 2.0, 3.0, 4.0);
      Zero      : OpenCV.Scalar;
   begin
      AUnit.Assertions.Assert
        (Defaulted.Component_0 = 7.0
         and then Defaulted.Component_1 = 0.0
         and then Defaulted.Component_2 = 0.0
         and then Defaulted.Component_3 = 0.0,
         "Make_Scalar defaults omitted components to 0.0");
      AUnit.Assertions.Assert
        (Explicit.Component_0 = 1.0
         and then Explicit.Component_1 = 2.0
         and then Explicit.Component_2 = 3.0
         and then Explicit.Component_3 = 4.0,
         "Make_Scalar preserves all four components");
      AUnit.Assertions.Assert
        (Zero = (others => 0.0), "default Scalar is all zeros");
   end Make_Scalar_Preserves_Defaults_And_Components;

   procedure Equality_And_Coordinate_Arithmetic (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Left        : constant OpenCV.Point := (X => -2, Y => 5);
      Right       : constant OpenCV.Point := (X => -2, Y => 5);
      Width       : constant OpenCV.Size_Coordinate := 3;
      Sum         : OpenCV.Point_Coordinate;
      Span        : OpenCV.Size_Coordinate;
      Extent      : constant OpenCV.Size := (Width => 2, Height => 3);
      Same_Extent : constant OpenCV.Size := (Width => 2, Height => 3);
      Area        : constant OpenCV.Rect :=
        (X => 1, Y => -1, Width => 2, Height => 4);
      Same_Area   : constant OpenCV.Rect :=
        (X => 1, Y => -1, Width => 2, Height => 4);
      Image       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Dimensions   => (Width => 4, Height => 3),
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
   begin
      AUnit.Assertions.Assert (Left = Right, "Point equality remains usable");
      Sum := Left.X + OpenCV.Point_Coordinate (Image.Rows);
      Span := Width + OpenCV.Size_Coordinate (Image.Columns);
      AUnit.Assertions.Assert
        (Sum = 1, "Point_Coordinate addition remains usable");
      AUnit.Assertions.Assert
        (Span = 7, "Size_Coordinate addition remains usable");
      AUnit.Assertions.Assert
        (Extent = Same_Extent, "Size equality remains usable");
      AUnit.Assertions.Assert
        (Area = Same_Area, "Rect equality remains usable");
   end Equality_And_Coordinate_Arithmetic;

   procedure Root_Enums_Work_With_Core_Operations (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Kind           : constant OpenCV.Border_Kind := OpenCV.Reflect_101;
      Units          : constant OpenCV.Angle_Unit := OpenCV.Degrees;
      Donor          : constant OpenCV.Core.Border_Interpolation_Result :=
        OpenCV.Core.Border_Interpolate
          (Position => -1, Length => 3, Kind => Kind);
      Constant_Donor : constant OpenCV.Core.Border_Interpolation_Result :=
        OpenCV.Core.Border_Interpolate
          (Position => -1, Length => 3, Kind => OpenCV.Constant_Border);
      Polar          : OpenCV.Core.Polar_Coordinates;
      X              : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Y              : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
   begin
      X.Set_To (OpenCV.Make_Scalar (1.0));
      Y.Set_To (OpenCV.Make_Scalar (0.0));
      Polar := OpenCV.Core.Cart_To_Polar (X, Y, Units);
      AUnit.Assertions.Assert
        (not Polar.Magnitude.Is_Empty,
         "root Angle_Unit is accepted by Core Cart_To_Polar");
      AUnit.Assertions.Assert
        (not Donor.Uses_Constant and then Donor.Index = 1,
         "root Reflect_101 is accepted by Core Border_Interpolate");
      AUnit.Assertions.Assert
        (Constant_Donor.Uses_Constant,
         "root Constant_Border is accepted by Core Border_Interpolate");
   end Root_Enums_Work_With_Core_Operations;

   procedure Root_Values_Are_Accepted_By_Core_Apis (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Dimensions : constant OpenCV.Size := (Width => 4, Height => 3);
      Area       : constant OpenCV.Rect :=
        (X => 1, Y => 1, Width => 2, Height => 1);
      Image      : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Dimensions   => Dimensions,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      View       : OpenCV.Core.Mat;
   begin
      Image.Set_To (OpenCV.Make_Scalar (9.0));
      View := Image.Region (Area);
      AUnit.Assertions.Assert
        (Image.Rows = 3
         and then Image.Columns = 4
         and then Image.Dimensions = Dimensions,
         "root Size is accepted by Core Create and Dimensions");
      AUnit.Assertions.Assert
        (View.Rows = 1
         and then View.Columns = 2
         and then OpenCV.Core.UInt8_Access.Get (View, 0, 0) = 9,
         "root Rect and Make_Scalar are accepted by Core Region and Set_To");
   end Root_Values_Are_Accepted_By_Core_Apis;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Root value defaults and coordinate constraints",
            Root_Defaults_And_Coordinate_Constraints'Access));
      Result.Add_Test
        (Caller.Create
           ("Point_Array bounds and empty arrays",
            Point_Array_Bounds_And_Empty_Arrays'Access));
      Result.Add_Test
        (Caller.Create
           ("Make_Scalar preserves defaults and components",
            Make_Scalar_Preserves_Defaults_And_Components'Access));
      Result.Add_Test
        (Caller.Create
           ("Root value equality and coordinate arithmetic",
            Equality_And_Coordinate_Arithmetic'Access));
      Result.Add_Test
        (Caller.Create
           ("Root enums work with Core operations",
            Root_Enums_Work_With_Core_Operations'Access));
      Result.Add_Test
        (Caller.Create
           ("Root values are accepted directly by Core APIs",
            Root_Values_Are_Accepted_By_Core_Apis'Access));
      return Result'Access;
   end Suite;

end OpenCV_Value_Tests;
