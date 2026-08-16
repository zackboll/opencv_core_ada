with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float32_Vec3_Access;
with OpenCV.Core.UInt8_Access;
with Mat_Test_Support;

package body Mat_Range_Tests is

   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_8;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Point_Coordinate;

   use Mat_Test_Support;
   use type OpenCV.Core.Float32_Access.Float32_Classification;

   procedure Valid_Finite_Float32 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Range_Check_Result;
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, -2.5);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 8.0);
      Result := Image.Check_Range;

      AUnit.Assertions.Assert
        (Result.Valid, "Finite Float32 values must be valid without bounds");
   end Valid_Finite_Float32;

   procedure Valid_Bounded_Range (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Range_Check_Result;
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 2, 2.0);
      Result := Image.Check_Range (Minimum => 0.0, Maximum => 3.0);

      AUnit.Assertions.Assert
        (Result.Valid, "Values in [0.0, 3.0) must be valid");
   end Valid_Bounded_Range;

   procedure Boundary_Is_Half_Open (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Minimum : OpenCV.Core.Range_Check_Result;
      Maximum : OpenCV.Core.Range_Check_Result;
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 1.0);
      Minimum := Image.Check_Range (Minimum => 1.0, Maximum => 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 2.0);
      Maximum := Image.Check_Range (Minimum => 1.0, Maximum => 2.0);

      AUnit.Assertions.Assert
        (Minimum.Valid, "A value equal to Minimum must be valid");
      AUnit.Assertions.Assert
        (not Maximum.Valid
         and then Maximum.First_Invalid.X = 0
         and then Maximum.First_Invalid.Y = 0,
         "A value equal to Maximum must be the first invalid element");
   end Boundary_Is_Half_Open;

   procedure First_Invalid_Uses_Column_Row_Point
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Range_Check_Result;
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 2, 99.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 88.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 2, 4.0);
      Result := Image.Check_Range (Minimum => 0.0, Maximum => 10.0);

      AUnit.Assertions.Assert
        (not Result.Valid
         and then Result.First_Invalid.X = 2
         and then Result.First_Invalid.Y = 0,
         "First_Invalid must be the first row-major outlier as column, row");
   end First_Invalid_Uses_Column_Row_Point;

   procedure Integer_Bounds_Use_OpenCV_Conversion
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Inclusive : OpenCV.Core.Range_Check_Result;
      Exclusive : OpenCV.Core.Range_Check_Result;
   begin
      OpenCV.Core.UInt8_Access.Set (Image, 0, 0, 2);
      Inclusive := Image.Check_Range (Minimum => 1.0, Maximum => 2.1);
      Exclusive := Image.Check_Range (Minimum => 1.0, Maximum => 2.0);

      AUnit.Assertions.Assert
        (Inclusive.Valid,
         "OpenCV integer conversion must accept 2 for Maximum 2.1");
      AUnit.Assertions.Assert
        (not Exclusive.Valid
         and then Exclusive.First_Invalid.X = 0
         and then Exclusive.First_Invalid.Y = 0,
         "OpenCV integer conversion must reject 2 for Maximum 2.0");
   end Integer_Bounds_Use_OpenCV_Conversion;

   procedure Multi_Channel_Reports_Element_Location
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 3));
      Result : OpenCV.Core.Range_Check_Result;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set (Image, 0, 0, (1.0, 1.0, 1.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Image, 0, 1, (1.0, 100.0, 1.0));
      Result := Image.Check_Range (Minimum => 0.0, Maximum => 10.0);

      AUnit.Assertions.Assert
        (not Result.Valid
         and then Result.First_Invalid.X = 1
         and then Result.First_Invalid.Y = 0,
         "A single invalid channel must invalidate the whole element");
   end Multi_Channel_Reports_Element_Location;

   procedure Unbounded_Rejects_NaN (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Numerator   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Denominator : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Image       : OpenCV.Core.Mat;
      Result      : OpenCV.Core.Range_Check_Result;
   begin
      Numerator.Set_To (OpenCV.Core.Make_Scalar (1.0));
      OpenCV.Core.Float32_Access.Set (Numerator, 1, 0, 0.0);
      Denominator.Set_To (OpenCV.Core.Make_Scalar (1.0));
      OpenCV.Core.Float32_Access.Set (Denominator, 1, 0, 0.0);
      Image := Numerator.Divide (Denominator);
      Result := Image.Check_Range;

      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Classify (Image, 1, 0)
         = OpenCV.Core.Float32_Access.Not_A_Number,
         "The test must place a NaN at row 1, column 0");
      AUnit.Assertions.Assert
        (not Result.Valid
         and then Result.First_Invalid.X = 0
         and then Result.First_Invalid.Y = 1,
         "Unbounded Check_Range must report the first NaN location");
   end Unbounded_Rejects_NaN;

   procedure Unbounded_Rejects_Positive_Infinity
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Numerator   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Denominator : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Image       : OpenCV.Core.Mat;
      Result      : OpenCV.Core.Range_Check_Result;
   begin
      Numerator.Set_To (OpenCV.Core.Make_Scalar (1.0));
      Denominator.Set_To (OpenCV.Core.Make_Scalar (1.0));
      OpenCV.Core.Float32_Access.Set (Denominator, 0, 1, 0.0);
      Image := Numerator.Divide (Denominator);
      Result := Image.Check_Range;

      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Classify (Image, 0, 1)
         = OpenCV.Core.Float32_Access.Positive_Infinity,
         "The test must place +Infinity at row 0, column 1");
      AUnit.Assertions.Assert
        (not Result.Valid
         and then Result.First_Invalid.X = 1
         and then Result.First_Invalid.Y = 0,
         "Unbounded Check_Range must report the first +Infinity location");
   end Unbounded_Rejects_Positive_Infinity;

   procedure Float64_Finite_And_Converted_Invalid
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Finite      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float64, 1));
      Numerator   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Denominator : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Invalid32   : OpenCV.Core.Mat;
      Invalid64   : OpenCV.Core.Mat;
      Finite_Ok   : OpenCV.Core.Range_Check_Result;
      Bounded     : OpenCV.Core.Range_Check_Result;
      Invalid     : OpenCV.Core.Range_Check_Result;
   begin
      Finite.Set_To (OpenCV.Core.Make_Scalar (1.5));
      Finite_Ok := Finite.Check_Range;
      Bounded := Finite.Check_Range (Minimum => 1.5, Maximum => 2.0);
      Numerator.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Denominator.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Invalid32 := Numerator.Divide (Denominator);
      Invalid64 := Invalid32.Convert_To (OpenCV.Core.Float64);
      Invalid := Invalid64.Check_Range;

      AUnit.Assertions.Assert
        (Finite_Ok.Valid and then Bounded.Valid,
         "Finite Float64 values must follow the same range contract");
      AUnit.Assertions.Assert
        (Invalid64.Depth = OpenCV.Core.Float64
         and then not Invalid.Valid
         and then Invalid.First_Invalid.X = 0
         and then Invalid.First_Invalid.Y = 0,
         "A Float64 NaN produced from Float32 must be reported invalid");
   end Float64_Finite_And_Converted_Invalid;

   procedure Noncontiguous_Region_Is_Relative (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (5, 6, (OpenCV.Core.UInt8, 1));
      View   : OpenCV.Core.Mat;
      Result : OpenCV.Core.Range_Check_Result;
   begin
      Source.Set_To (OpenCV.Core.Make_Scalar (5.0));
      View := Source.Region ((X => 1, Y => 1, Width => 4, Height => 3));
      OpenCV.Core.UInt8_Access.Set (View, 1, 2, 40);

      AUnit.Assertions.Assert
        (not View.Is_Continuous,
         "The Region test must exercise a non-contiguous view");
      Result := View.Check_Range (Minimum => 0.0, Maximum => 10.0);

      AUnit.Assertions.Assert
        (not Result.Valid
         and then Result.First_Invalid.X = 2
         and then Result.First_Invalid.Y = 1,
         "Region First_Invalid must be relative to the Region");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Source, 2, 3) = 40
         and then OpenCV.Core.UInt8_Access.Get (View, 1, 2) = 40
         and then OpenCV.Core.UInt8_Access.Get (View, 0, 0) = 5,
         "Check_Range must not modify the source or its Region");
   end Noncontiguous_Region_Is_Relative;

   procedure Empty_Mats_Are_Valid (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Default : OpenCV.Core.Mat;
      Empty8  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.UInt8, 1));
      Empty32 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Empty64 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float64, 1));
   begin
      AUnit.Assertions.Assert
        (Default.Check_Range.Valid, "A default empty Mat must be valid");
      AUnit.Assertions.Assert
        (Empty8.Check_Range.Valid
         and then Empty32.Check_Range.Valid
         and then Empty64.Check_Range.Valid,
         "Typed 0x0 Mats must be valid when they contain no elements");
   end Empty_Mats_Are_Valid;

   procedure Float16_Is_Rejected (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float16, 1));

      procedure Check_Float16 is
         Result : constant OpenCV.Core.Range_Check_Result := Image.Check_Range;
      begin
         pragma Unreferenced (Result);
      end Check_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access, "Check_Range must reject Float16 Mats");
   end Float16_Is_Rejected;

   procedure Does_Not_Mutate_Source (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Range_Check_Result;
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 2, 2.0);
      Result := Image.Check_Range (Minimum => 0.0, Maximum => 3.0);

      AUnit.Assertions.Assert
        (Result.Valid, "The mutation test needs a valid Mat");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Image, 0, 0) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Image, 0, 1) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Image, 0, 2) = 2.0,
         "Check_Range must leave source values unchanged");
   end Does_Not_Mutate_Source;

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Check_Range accepts finite Float32",
            Valid_Finite_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Check_Range accepts a bounded finite range",
            Valid_Bounded_Range'Access));
      Result.Add_Test
        (Caller.Create
           ("Check_Range uses a half-open [Minimum, Maximum) interval",
            Boundary_Is_Half_Open'Access));
      Result.Add_Test
        (Caller.Create
           ("Check_Range reports the first invalid column-row Point",
            First_Invalid_Uses_Column_Row_Point'Access));
      Result.Add_Test
        (Caller.Create
           ("Check_Range integer bounds follow OpenCV conversion",
            Integer_Bounds_Use_OpenCV_Conversion'Access));
      Result.Add_Test
        (Caller.Create
           ("Check_Range multi-channel reports the element location",
            Multi_Channel_Reports_Element_Location'Access));
      Result.Add_Test
        (Caller.Create
           ("Check_Range unbounded rejects NaN",
            Unbounded_Rejects_NaN'Access));
      Result.Add_Test
        (Caller.Create
           ("Check_Range unbounded rejects +Infinity",
            Unbounded_Rejects_Positive_Infinity'Access));
      Result.Add_Test
        (Caller.Create
           ("Check_Range supports Float64 finite and invalid values",
            Float64_Finite_And_Converted_Invalid'Access));
      Result.Add_Test
        (Caller.Create
           ("Check_Range uses Region-relative coordinates",
            Noncontiguous_Region_Is_Relative'Access));
      Result.Add_Test
        (Caller.Create
           ("Check_Range treats empty Mats as valid",
            Empty_Mats_Are_Valid'Access));
      Result.Add_Test
        (Caller.Create
           ("Check_Range rejects Float16", Float16_Is_Rejected'Access));
      Result.Add_Test
        (Caller.Create
           ("Check_Range does not mutate its source",
            Does_Not_Mutate_Source'Access));
      return Result'Access;
   end Suite;

end Mat_Range_Tests;
