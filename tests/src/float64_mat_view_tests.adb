with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV.Core;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Float64_Buffer_Access;
with OpenCV.Core.Float64_Mat_View;
with OpenCV.Core.Float64_Row_Access;
with System.Address_To_Access_Conversions;

package body Float64_Mat_View_Tests is

   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use type Interfaces.IEEE_Float_32;
   use type OpenCV.Core.Float64_Access.Float64_Classification;
   use type OpenCV.Core.Float64_Value;
   use type OpenCV.Core.Float64_Row_Access.Row_Array;
   use type OpenCV.Core.Mat_Size;
   use Mat_Test_Support;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   procedure External_View_Is_Contiguous_Zero_Copy_At_Arbitrary_Bound
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      First    : constant OpenCV.Core.Float64_Value := 1.0;
      Distinct : OpenCV.Core.Float64_Value := First;
      First_32 : OpenCV.Core.Float32_Value := 0.0;
      Other_32 : OpenCV.Core.Float32_Value := 0.0;
      Data     : aliased OpenCV.Core.Float64_Mat_View.Buffer_Array :=
        (37 => First,
         38 => Distinct,
         39 => 2.5,
         40 => -3.5,
         41 => 4.5,
         42 => 5.5,
         43 => 6.5,
         44 => 7.5);

      procedure Process (Image : in out OpenCV.Core.Mat) is
         Row : OpenCV.Core.Float64_Row_Access.Row_Array (10 .. 13);

         procedure Inspect_Row
           (Values : aliased OpenCV.Core.Float64_Row_Access.Row_Array) is
         begin
            AUnit.Assertions.Assert
              (Values (0) = Data (41) and then Values (3) = Data (44),
               "Borrowed Float64 row values must directly match caller data");
         end Inspect_Row;

         procedure Inspect_Buffer
           (Values : aliased OpenCV.Core.Float64_Buffer_Access.Buffer_Array) is
         begin
            AUnit.Assertions.Assert
              (Values'Length = Data'Length
               and then Values (0) = Data (37)
               and then Values (7) = Data (44),
               "Borrowed Float64 buffer must span the caller-owned storage");
         end Inspect_Buffer;

         procedure Mutate_Buffer
           (Values :
              aliased in out OpenCV.Core.Float64_Buffer_Access.Buffer_Array) is
         begin
            Values (7) := 91.125;
         end Mutate_Buffer;
      begin
         AUnit.Assertions.Assert
           (Image.Rows = 2
            and then Image.Columns = 4
            and then Image.Depth = OpenCV.Core.Float64
            and then Image.Channels = 1
            and then Image.Element_Size = 8
            and then Image.Is_Continuous,
            "External view metadata must describe contiguous CV_64FC1"
            & " storage");
         AUnit.Assertions.Assert
           (First /= Distinct
            and then First_32 = Other_32
            and then OpenCV.Core.Float64_Access.Get (Image, 0, 0) = First
            and then OpenCV.Core.Float64_Access.Get (Image, 0, 1) = Distinct,
            "External view must preserve values distinct only in binary64");

         Data (39) := 12.25;
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Access.Get (Image, 0, 2) = 12.25,
            "Caller writes must be immediately visible through the Mat");
         OpenCV.Core.Float64_Access.Set (Image, 0, 3, -17.75);
         AUnit.Assertions.Assert
           (Data (40) = -17.75,
            "Float64 Set must immediately update caller-owned storage");

         OpenCV.Core.Float64_Row_Access.Read_Row (Image, 0, Row);
         AUnit.Assertions.Assert
           (Row (10) = First and then Row (13) = -17.75,
            "Copied Float64 rows must follow row-major caller storage");
         OpenCV.Core.Float64_Row_Access.Write_Row
           (Image, 1, (10.0, 20.0, 30.0, 40.0));
         AUnit.Assertions.Assert
           (Data (41) = 10.0 and then Data (44) = 40.0,
            "Float64 row writes must immediately update caller storage");
         OpenCV.Core.Float64_Row_Access.With_Read_Only_Row
           (Image, 1, Inspect_Row'Access);
         OpenCV.Core.Float64_Buffer_Access.With_Read_Only_Buffer
           (Image, Inspect_Buffer'Access);
         OpenCV.Core.Float64_Buffer_Access.With_Writable_Buffer
           (Image, Mutate_Buffer'Access);
         AUnit.Assertions.Assert
           (Data (44) = 91.125,
            "Writable whole-buffer borrowing must update caller storage");
      end Process;
   begin
      Distinct := First + 2.0**(-40);
      Data (38) := Distinct;
      First_32 := OpenCV.Core.Float32_Value (First);
      Other_32 := OpenCV.Core.Float32_Value (Distinct);
      OpenCV.Core.Float64_Mat_View.With_Writable_Mat_View
        (Data, Rows => 2, Columns => 4, Process => Process'Access);
      AUnit.Assertions.Assert
        (Data (40) = -17.75 and then Data (44) = 91.125,
         "View finalization must preserve completed writes in caller storage");
      Data (37) := 123.5;
      AUnit.Assertions.Assert
        (Data (37) = 123.5,
         "Caller storage must remain usable after Mat header finalization");
   end External_View_Is_Contiguous_Zero_Copy_At_Arbitrary_Bound;

   procedure External_View_Preserves_Nonfinite_Classification
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Numerator   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float64, 1));
      Denominator : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float64, 1));
      Nonfinite   : OpenCV.Core.Mat;
      Data        : aliased OpenCV.Core.Float64_Mat_View.Buffer_Array :=
        (5 .. 7 => 0.0);

      procedure Copy_Nonfinite
        (Values : aliased OpenCV.Core.Float64_Buffer_Access.Buffer_Array)
      is
         subtype Three_Values is
           OpenCV.Core.Float64_Mat_View.Buffer_Array (5 .. 7);
         package Conversions is new
           System.Address_To_Access_Conversions (Three_Values);
      begin
         Data := Conversions.To_Pointer (Values'Address).all;
      end Copy_Nonfinite;

      procedure Inspect (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Access.Classify (Image, 0, 0)
            = OpenCV.Core.Float64_Access.Positive_Infinity
            and then OpenCV.Core.Float64_Access.Classify (Image, 0, 1)
                     = OpenCV.Core.Float64_Access.Negative_Infinity
            and then OpenCV.Core.Float64_Access.Classify (Image, 0, 2)
                     = OpenCV.Core.Float64_Access.Not_A_Number,
            "External CV_64F storage must preserve infinities and NaN");
      end Inspect;
   begin
      OpenCV.Core.Float64_Access.Set (Numerator, 0, 0, 1.0);
      OpenCV.Core.Float64_Access.Set (Numerator, 0, 1, -1.0);
      OpenCV.Core.Float64_Access.Set (Numerator, 0, 2, 0.0);
      Denominator.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Nonfinite := Numerator.Divide (Denominator);
      OpenCV.Core.Float64_Buffer_Access.With_Read_Only_Buffer
        (Nonfinite, Copy_Nonfinite'Access);
      OpenCV.Core.Float64_Mat_View.With_Writable_Mat_View
        (Data, 1, 3, Inspect'Access);
   end External_View_Preserves_Nonfinite_Classification;

   procedure External_View_Clone_Is_Independent_And_Escape_Is_Rejected
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data  : aliased OpenCV.Core.Float64_Mat_View.Buffer_Array :=
        (11 => 1.25, 12 => 2.5, 13 => 3.75, 14 => 5.0);
      Saved : OpenCV.Core.Mat;

      procedure Process (Image : in out OpenCV.Core.Mat) is
         procedure Copy_Alias is
            Alias : OpenCV.Core.Mat;
            pragma Unreferenced (Alias);
         begin
            begin
               Alias := Image;
            exception
               when Program_Error =>
                  raise OpenCV.OpenCV_Error;
            end;
         end Copy_Alias;
      begin
         Assert_Raises_OpenCV_Error
           (Copy_Alias'Access,
            "Temporary Float64 external views must reject shallow aliases");
         OpenCV.Core.Float64_Access.Set (Image, 0, 0, 6.25);
         Saved := Image.Clone;
      end Process;
   begin
      OpenCV.Core.Float64_Mat_View.With_Writable_Mat_View
        (Data, 2, 2, Process'Access);
      Data (11) := 8.5;
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Access.Get (Saved, 0, 0) = 6.25,
         "Clone must not observe later caller-buffer mutations");
      OpenCV.Core.Float64_Access.Set (Saved, 0, 0, -9.75);
      AUnit.Assertions.Assert
        (Data (11) = 8.5,
         "Writes to Clone must not affect external caller storage");
   end External_View_Clone_Is_Independent_And_Escape_Is_Rejected;

   procedure Invalid_Geometry_Does_Not_Invoke_Callback (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data    : aliased OpenCV.Core.Float64_Mat_View.Buffer_Array :=
        (1 .. 5 => 1.0);
      Invoked : Boolean := False;

      procedure Mark (Image : in out OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Mark;

      procedure Wrong_Length is
      begin
         OpenCV.Core.Float64_Mat_View.With_Writable_Mat_View
           (Data, 2, 3, Mark'Access);
      end Wrong_Length;

      procedure Oversized_Geometry is
      begin
         OpenCV.Core.Float64_Mat_View.With_Writable_Mat_View
           (Data, Positive'Last, Positive'Last, Mark'Access);
      end Oversized_Geometry;

   begin
      Assert_Raises_OpenCV_Error (Wrong_Length'Access, "Float64 view length");
      Assert_Raises_OpenCV_Error
        (Oversized_Geometry'Access, "Float64 view geometry range");
      AUnit.Assertions.Assert
        (not Invoked,
         "Invalid Float64 external view construction must not invoke"
         & " callback");
   end Invalid_Geometry_Does_Not_Invoke_Callback;

   procedure Strided_View_Integrates_Access_And_Preserves_Padding
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Sentinel : constant OpenCV.Core.Float64_Value := -9_876.5;
      First    : constant OpenCV.Core.Float64_Value := 1.0;
      Distinct : OpenCV.Core.Float64_Value := First;
      Data     : aliased OpenCV.Core.Float64_Mat_View.Buffer_Array :=
        (37 .. 54 => Sentinel);
      Clone    : OpenCV.Core.Mat;

      function Padding_Is_Intact return Boolean
      is (Data (41) = Sentinel
          and then Data (42) = Sentinel
          and then Data (47) = Sentinel
          and then Data (48) = Sentinel
          and then Data (53) = Sentinel
          and then Data (54) = Sentinel);

      procedure Process (Image : in out OpenCV.Core.Mat) is
         Readback       : OpenCV.Core.Float64_Row_Access.Row_Array (8 .. 11);
         Buffer_Invoked : Boolean := False;

         procedure Inspect_Row
           (Values : aliased OpenCV.Core.Float64_Row_Access.Row_Array) is
         begin
            AUnit.Assertions.Assert
              (Values'First = 0
               and then Values'Last = 3
               and then Values'Length = 4
               and then Values (0) = First
               and then Values (1) = Distinct
               and then Values (3) = 23.0,
               "Borrowed strided row must expose logical columns only");
         end Inspect_Row;

         procedure Mutate_Row
           (Values : aliased in out OpenCV.Core.Float64_Row_Access.Row_Array)
         is
         begin
            Values (1) := 71.125;
         end Mutate_Row;

         procedure Mark_Buffer
           (Values : aliased OpenCV.Core.Float64_Buffer_Access.Buffer_Array)
         is
            pragma Unreferenced (Values);
         begin
            Buffer_Invoked := True;
         end Mark_Buffer;

         procedure Borrow_Buffer is
         begin
            OpenCV.Core.Float64_Buffer_Access.With_Read_Only_Buffer
              (Image, Mark_Buffer'Access);
         end Borrow_Buffer;

         procedure Assign_Shallow_Copy is
            Copy : OpenCV.Core.Mat;
            pragma Unreferenced (Copy);
         begin
            begin
               Copy := Image;
            exception
               when Program_Error =>
                  raise OpenCV.OpenCV_Error;
            end;
         end Assign_Shallow_Copy;
      begin
         AUnit.Assertions.Assert
           (Image.Rows = 3
            and then Image.Columns = 4
            and then Image.Depth = OpenCV.Core.Float64
            and then Image.Channels = 1
            and then Image.Element_Size = 8
            and then not Image.Is_Continuous,
            "Padded multirow view must report strided CV_64FC1 metadata");
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Access.Get (Image, 1, 0) = First
            and then OpenCV.Core.Float64_Access.Get (Image, 1, 1) = Distinct
            and then OpenCV.Core.Float32_Value (First)
                     = OpenCV.Core.Float32_Value (Distinct)
            and then OpenCV.Core.Float64_Access.Classify (Image, 0, 0)
                     = OpenCV.Core.Float64_Access.Positive_Infinity
            and then OpenCV.Core.Float64_Access.Classify (Image, 0, 1)
                     = OpenCV.Core.Float64_Access.Negative_Infinity
            and then OpenCV.Core.Float64_Access.Classify (Image, 0, 2)
                     = OpenCV.Core.Float64_Access.Not_A_Number,
            "Strided scalar access must preserve binary64 and special values");

         OpenCV.Core.Float64_Access.Set (Image, 2, 3, 99.25);
         OpenCV.Core.Float64_Row_Access.Read_Row (Image, 1, Readback);
         AUnit.Assertions.Assert
           (Data (52) = 99.25
            and then Readback = (First, Distinct, 22.0, 23.0),
            "Scalar and copied row reads must respect the supplied stride");
         OpenCV.Core.Float64_Row_Access.Write_Row
           (Image, 2, (30.0, 31.0, 32.0, 33.0));
         OpenCV.Core.Float64_Row_Access.With_Read_Only_Row
           (Image, 1, Inspect_Row'Access);
         OpenCV.Core.Float64_Row_Access.With_Writable_Row
           (Image, 1, Mutate_Row'Access);
         AUnit.Assertions.Assert
           (Data (44) = 71.125
            and then Data (49) = 30.0
            and then Data (52) = 33.0
            and then Padding_Is_Intact,
            "Copied and borrowed row writes must not touch padding");

         Assert_Raises_OpenCV_Error
           (Borrow_Buffer'Access,
            "Whole-buffer borrowing must reject a non-contiguous view");
         AUnit.Assertions.Assert
           (not Buffer_Invoked,
            "Rejected whole-buffer borrowing must suppress its callback");
         Assert_Raises_OpenCV_Error
           (Assign_Shallow_Copy'Access,
            "A strided external view must retain no-escape enforcement");

         Clone := Image.Clone;
         AUnit.Assertions.Assert
           (Clone.Is_Continuous
            and then OpenCV.Core.Float64_Access.Get (Clone, 1, 1) = 71.125
            and then OpenCV.Core.Float64_Access.Get (Clone, 2, 3) = 33.0,
            "Clone must copy logical values into continuous owned storage");
         Image.Set_To (OpenCV.Core.Make_Scalar (4.5));
         AUnit.Assertions.Assert
           (Padding_Is_Intact,
            "An OpenCV logical-element operation must preserve row padding");
      end Process;
   begin
      Distinct := First + 2.0**(-40);
      declare
         Numerator   : OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 3, (OpenCV.Core.Float64, 1));
         Denominator : OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 3, (OpenCV.Core.Float64, 1));
         Nonfinite   : OpenCV.Core.Mat;
         procedure Copy_Nonfinite
           (Values : aliased OpenCV.Core.Float64_Buffer_Access.Buffer_Array)
         is
            subtype Three_Values is
              OpenCV.Core.Float64_Mat_View.Buffer_Array (37 .. 39);
            package Conversions is new
              System.Address_To_Access_Conversions (Three_Values);
         begin
            Conversions.To_Pointer (Data (37)'Address).all :=
              Conversions.To_Pointer (Values'Address).all;
         end Copy_Nonfinite;
      begin
         OpenCV.Core.Float64_Access.Set (Numerator, 0, 0, 1.0);
         OpenCV.Core.Float64_Access.Set (Numerator, 0, 1, -1.0);
         OpenCV.Core.Float64_Access.Set (Numerator, 0, 2, 0.0);
         Denominator.Set_To (OpenCV.Core.Make_Scalar (0.0));
         Nonfinite := Numerator.Divide (Denominator);
         OpenCV.Core.Float64_Buffer_Access.With_Read_Only_Buffer
           (Nonfinite, Copy_Nonfinite'Access);
      end;
      Data (40) := 10.0;
      Data (43) := First;
      Data (44) := Distinct;
      Data (45) := 22.0;
      Data (46) := 23.0;
      Data (49) := 30.0;
      Data (50) := 31.0;
      Data (51) := 32.0;
      Data (52) := 33.0;

      OpenCV.Core.Float64_Mat_View.With_Writable_Strided_Mat_View
        (Data,
         Rows       => 3,
         Columns    => 4,
         Row_Stride => 6,
         Process    => Process'Access);
      AUnit.Assertions.Assert
        (Data (37) = 4.5 and then Data (52) = 4.5 and then Padding_Is_Intact,
         "View finalization must preserve storage ownership and padding");
      Data (37) := 8.0;
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Access.Classify (Clone, 0, 0)
         = OpenCV.Core.Float64_Access.Positive_Infinity,
         "Backing mutation after callback must not affect Clone");
      OpenCV.Core.Float64_Access.Set (Clone, 0, 0, -8.0);
      AUnit.Assertions.Assert
        (Data (37) = 8.0,
         "Clone mutation must not affect caller-owned backing storage");
   end Strided_View_Integrates_Access_And_Preserves_Padding;

   procedure Strided_View_Handles_Special_Shapes_And_Minimum_Storage
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      One_Row    : aliased OpenCV.Core.Float64_Mat_View.Buffer_Array :=
        (10 => 1.0, 11 => 2.0, 12 => 3.0, 13 => 4.0, 14 => 900.0);
      One_Column : aliased OpenCV.Core.Float64_Mat_View.Buffer_Array :=
        (20 => 1.0,
         21 => 700.0,
         22 => 700.0,
         23 => 2.0,
         24 => 700.0,
         25 => 700.0,
         26 => 3.0);
      Tight      : aliased OpenCV.Core.Float64_Mat_View.Buffer_Array :=
        (1.0, 2.0, 3.0, 4.0, 5.0, 6.0);

      procedure Check_One_Row (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (Image.Is_Continuous
            and then OpenCV.Core.Float64_Access.Get (Image, 0, 3) = 4.0,
            "OpenCV must classify a one-row padded-step Mat as continuous");
         OpenCV.Core.Float64_Access.Set (Image, 0, 3, 44.0);
      end Check_One_Row;

      procedure Check_One_Column (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (not Image.Is_Continuous
            and then OpenCV.Core.Float64_Access.Get (Image, 2, 0) = 3.0,
            "A padded single-column view must preserve its row stride");
         OpenCV.Core.Float64_Access.Set (Image, 1, 0, 22.0);
      end Check_One_Column;

      procedure Check_Tight (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (Image.Is_Continuous,
            "Row_Stride equal to Columns must be equivalent to packed layout");
         OpenCV.Core.Float64_Access.Set (Image, 1, 2, 66.0);
      end Check_Tight;
   begin
      OpenCV.Core.Float64_Mat_View.With_Writable_Strided_Mat_View
        (One_Row, 1, 4, 6, Check_One_Row'Access);
      OpenCV.Core.Float64_Mat_View.With_Writable_Strided_Mat_View
        (One_Column, 3, 1, 3, Check_One_Column'Access);
      OpenCV.Core.Float64_Mat_View.With_Writable_Strided_Mat_View
        (Tight, 2, 3, 3, Check_Tight'Access);
      AUnit.Assertions.Assert
        (One_Row (13) = 44.0
         and then One_Row (14) = 900.0
         and then One_Column (23) = 22.0
         and then One_Column (21) = 700.0
         and then Tight (5) = 66.0,
         "Special-shape writes must preserve non-logical storage");
   end Strided_View_Handles_Special_Shapes_And_Minimum_Storage;

   procedure Invalid_Strided_Layouts_Do_Not_Invoke_Callback
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data    : aliased OpenCV.Core.Float64_Mat_View.Buffer_Array :=
        (1 .. 15 => 1.0);
      Invoked : Boolean := False;

      procedure Mark (Image : in out OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Mark;

      procedure Short_Stride is
      begin
         OpenCV.Core.Float64_Mat_View.With_Writable_Strided_Mat_View
           (Data, 3, 4, 3, Mark'Access);
      end Short_Stride;

      procedure Short_Buffer is
      begin
         OpenCV.Core.Float64_Mat_View.With_Writable_Strided_Mat_View
           (Data, 3, 4, 6, Mark'Access);
      end Short_Buffer;

      procedure Capacity_Overflow is
      begin
         OpenCV.Core.Float64_Mat_View.With_Writable_Strided_Mat_View
           (Data, 2, 1, Positive'Last, Mark'Access);
      end Capacity_Overflow;
   begin
      Assert_Raises_OpenCV_Error (Short_Stride'Access, "Float64 short stride");
      Assert_Raises_OpenCV_Error (Short_Buffer'Access, "Float64 short buffer");
      Assert_Raises_OpenCV_Error
        (Capacity_Overflow'Access, "Float64 strided capacity overflow");
      AUnit.Assertions.Assert
        (not Invoked,
         "Invalid strided layouts must be rejected before callback"
         & " invocation");
   end Invalid_Strided_Layouts_Do_Not_Invoke_Callback;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Float64 external view is zero-copy at arbitrary lower bound",
            External_View_Is_Contiguous_Zero_Copy_At_Arbitrary_Bound'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 external view preserves nonfinite classification",
            External_View_Preserves_Nonfinite_Classification'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 external view clone isolates and shallow escape rejects",
            External_View_Clone_Is_Independent_And_Escape_Is_Rejected'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 external view rejects invalid geometry before callback",
            Invalid_Geometry_Does_Not_Invoke_Callback'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 strided view integrates typed access and padding",
            Strided_View_Integrates_Access_And_Preserves_Padding'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 strided view handles special shapes and minimum storage",
            Strided_View_Handles_Special_Shapes_And_Minimum_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 strided view rejects invalid layouts before callback",
            Invalid_Strided_Layouts_Do_Not_Invoke_Callback'Access));
      return Result'Access;
   end Suite;

end Float64_Mat_View_Tests;
