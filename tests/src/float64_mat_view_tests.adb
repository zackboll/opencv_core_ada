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
      return Result'Access;
   end Suite;

end Float64_Mat_View_Tests;
