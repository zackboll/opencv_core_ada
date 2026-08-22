with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with Mat_Test_Support;

package body Mat_Arg_Reduction_Tests is

   use type Interfaces.IEEE_Float_32;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use Mat_Test_Support;

   type Depth_Array is array (Positive range <>) of OpenCV.Core.Depth_Type;

   Supported_Depths : constant Depth_Array :=
     (OpenCV.Core.UInt8,
      OpenCV.Core.Int8,
      OpenCV.Core.UInt16,
      OpenCV.Core.Int16,
      OpenCV.Core.Int32,
      OpenCV.Core.Float32,
      OpenCV.Core.Float64);

   function Index_At
     (Image : OpenCV.Core.Mat; Row, Column : Integer) return Natural
   is
      As_Float32 : constant OpenCV.Core.Mat :=
        Image.Convert_To (OpenCV.Core.Float32);
   begin
      return
        Natural (OpenCV.Core.Float32_Access.Get (As_Float32, Row, Column));
   end Index_At;

   function Is_Index_Mat
     (Image : OpenCV.Core.Mat; Rows, Columns : Natural) return Boolean
   is (Image.Rows = Rows
       and then Image.Columns = Columns
       and then Image.Depth = OpenCV.Core.Int32
       and then Image.Channels = 1);

   procedure Set_Row
     (Image      : in out OpenCV.Core.Mat;
      Row        : Integer;
      A, B, C, D : Interfaces.IEEE_Float_32) is
   begin
      OpenCV.Core.Float32_Access.Set (Image, Row, 0, A);
      OpenCV.Core.Float32_Access.Set (Image, Row, 1, B);
      OpenCV.Core.Float32_Access.Set (Image, Row, 2, C);
      OpenCV.Core.Float32_Access.Set (Image, Row, 3, D);
   end Set_Row;

   procedure Arg_Minimum_And_Maximum_Across_Columns
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 1));
      Minimum : OpenCV.Core.Mat;
      Maximum : OpenCV.Core.Mat;
   begin
      Set_Row (Source, 0, 9.0, 2.0, 8.0, 4.0);
      Set_Row (Source, 1, 1.0, 7.0, 3.0, 6.0);
      Set_Row (Source, 2, 5.0, 0.0, 4.0, 10.0);
      Minimum := Source.Arg_Minimum (OpenCV.Core.Across_Columns);
      Maximum := Source.Arg_Maximum (OpenCV.Core.Across_Columns);

      AUnit.Assertions.Assert
        (Is_Index_Mat (Minimum, 3, 1)
         and then Index_At (Minimum, 0, 0) = 1
         and then Index_At (Minimum, 1, 0) = 0
         and then Index_At (Minimum, 2, 0) = 1
         and then Is_Index_Mat (Maximum, 3, 1)
         and then Index_At (Maximum, 0, 0) = 0
         and then Index_At (Maximum, 1, 0) = 1
         and then Index_At (Maximum, 2, 0) = 3,
         "Arg reductions across columns must return Int32 C1 column indices");
   end Arg_Minimum_And_Maximum_Across_Columns;

   procedure Arg_Minimum_And_Maximum_Across_Rows
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 1));
      Minimum : OpenCV.Core.Mat;
      Maximum : OpenCV.Core.Mat;
   begin
      Set_Row (Source, 0, 8.0, 6.0, 5.0, 9.0);
      Set_Row (Source, 1, 3.0, 7.0, 4.0, 1.0);
      Set_Row (Source, 2, 2.0, 0.0, 10.0, 11.0);
      Minimum := Source.Arg_Minimum (OpenCV.Core.Across_Rows);
      Maximum := Source.Arg_Maximum (OpenCV.Core.Across_Rows);

      AUnit.Assertions.Assert
        (Is_Index_Mat (Minimum, 1, 4)
         and then Index_At (Minimum, 0, 0) = 2
         and then Index_At (Minimum, 0, 1) = 2
         and then Index_At (Minimum, 0, 2) = 1
         and then Index_At (Minimum, 0, 3) = 1
         and then Is_Index_Mat (Maximum, 1, 4)
         and then Index_At (Maximum, 0, 0) = 0
         and then Index_At (Maximum, 0, 1) = 1
         and then Index_At (Maximum, 0, 2) = 2
         and then Index_At (Maximum, 0, 3) = 2,
         "Arg reductions across rows must return Int32 C1 row indices");
   end Arg_Minimum_And_Maximum_Across_Rows;

   procedure Ties_Select_Requested_Occurrence (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Min_Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
      Max_Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
   begin
      Set_Row (Min_Source, 0, 5.0, 2.0, 2.0, 7.0);
      Set_Row (Max_Source, 0, 7.0, 9.0, 9.0, 3.0);
      AUnit.Assertions.Assert
        (Index_At (Min_Source.Arg_Minimum (OpenCV.Core.Across_Columns), 0, 0)
         = 1
         and then Index_At
                    (Min_Source.Arg_Minimum
                       (OpenCV.Core.Across_Columns,
                        OpenCV.Core.Last_Occurrence),
                     0,
                     0)
                  = 2
         and then Index_At
                    (Max_Source.Arg_Maximum (OpenCV.Core.Across_Columns), 0, 0)
                  = 1
         and then Index_At
                    (Max_Source.Arg_Maximum
                       (OpenCV.Core.Across_Columns,
                        OpenCV.Core.Last_Occurrence),
                     0,
                     0)
                  = 2,
         "Arg reductions must use the requested duplicate occurrence");
   end Ties_Select_Requested_Occurrence;

   procedure Boundary_And_Degenerate_Indices (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Single_Row    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
      Single_Column : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.Float32, 1));
   begin
      Set_Row (Single_Row, 0, 0.0, 4.0, 2.0, 9.0);
      OpenCV.Core.Float32_Access.Set (Single_Column, 0, 0, 8.0);
      OpenCV.Core.Float32_Access.Set (Single_Column, 1, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Single_Column, 2, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Single_Column, 3, 0, 0.0);
      AUnit.Assertions.Assert
        (Index_At (Single_Row.Arg_Minimum (OpenCV.Core.Across_Columns), 0, 0)
         = 0
         and then Index_At
                    (Single_Row.Arg_Maximum (OpenCV.Core.Across_Columns), 0, 0)
                  = 3
         and then Index_At
                    (Single_Row.Arg_Maximum (OpenCV.Core.Across_Rows), 0, 0)
                  = 0
         and then Index_At
                    (Single_Row.Arg_Minimum (OpenCV.Core.Across_Rows), 0, 3)
                  = 0
         and then Index_At
                    (Single_Column.Arg_Minimum (OpenCV.Core.Across_Rows), 0, 0)
                  = 3
         and then Index_At
                    (Single_Column.Arg_Maximum (OpenCV.Core.Across_Rows), 0, 0)
                  = 0
         and then Index_At
                    (Single_Column.Arg_Minimum (OpenCV.Core.Across_Columns),
                     3,
                     0)
                  = 0,
         "Arg reductions must handle zero, final, and degenerate indices");
   end Boundary_And_Degenerate_Indices;

   procedure Supported_Depths_And_Noncontinuous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Float_Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Float32, 1));
      Parent       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 5, (OpenCV.Core.Float32, 1));
      View         : OpenCV.Core.Mat;
   begin
      Set_Row (Float_Source, 0, 4.0, 2.0, 8.0, 0.0);
      OpenCV.Core.Float32_Access.Set (Float_Source, 1, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Float_Source, 1, 1, 7.0);
      OpenCV.Core.Float32_Access.Set (Float_Source, 1, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Float_Source, 1, 3, 6.0);
      for Depth of Supported_Depths loop
         declare
            Converted : constant OpenCV.Core.Mat :=
              Float_Source.Convert_To (Depth);
         begin
            AUnit.Assertions.Assert
              (Index_At
                 (Converted.Arg_Minimum (OpenCV.Core.Across_Columns), 1, 0)
               = 0
               and then Index_At
                          (Converted.Arg_Maximum (OpenCV.Core.Across_Columns),
                           1,
                           0)
                        = 1,
               "Arg reductions must support every public OpenCV 4.10 depth");
         end;
      end loop;

      Set_Row (Parent, 0, 99.0, 8.0, 1.0, 7.0);
      Set_Row (Parent, 1, 99.0, 2.0, 9.0, 3.0);
      View := Parent.Region ((X => 1, Y => 0, Width => 3, Height => 2));
      AUnit.Assertions.Assert
        (not View.Is_Continuous
         and then Index_At
                    (View.Arg_Minimum (OpenCV.Core.Across_Columns), 0, 0)
                  = 1
         and then Index_At
                    (View.Arg_Maximum (OpenCV.Core.Across_Columns), 1, 0)
                  = 1,
         "Arg reductions must support non-contiguous Regions");
   end Supported_Depths_And_Noncontinuous_Region;

   procedure Result_Ownership_And_Input_Immutability
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Mat;
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      begin
         OpenCV.Core.Float32_Access.Set (Source, 0, 0, 8.0);
         OpenCV.Core.Float32_Access.Set (Source, 0, 1, 1.0);
         OpenCV.Core.Float32_Access.Set (Source, 0, 2, 4.0);
         Result := Source.Arg_Minimum (OpenCV.Core.Across_Columns);
         OpenCV.Core.Float32_Access.Set (Source, 0, 1, 99.0);
         AUnit.Assertions.Assert
           (Index_At (Result, 0, 0) = 1
            and then OpenCV.Core.Float32_Access.Get (Source, 0, 1) = 99.0,
            "Arg reduction must not modify its input or share result storage");
      end;

      AUnit.Assertions.Assert
        (Is_Index_Mat (Result, 1, 1) and then Index_At (Result, 0, 0) = 1,
         "Arg reduction results must outlive their sources");
   end Result_Ownership_And_Input_Immutability;

   procedure Invalid_Inputs_Are_Rejected (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Default_Empty : OpenCV.Core.Mat;
      Typed_Empty   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Multi_Channel : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 2));
      Float16_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float16, 1));

      procedure Check_Default is
         Ignored : constant OpenCV.Core.Mat :=
           Default_Empty.Arg_Minimum (OpenCV.Core.Across_Rows);
      begin
         pragma Unreferenced (Ignored);
      end Check_Default;

      procedure Check_Typed_Empty is
         Ignored : constant OpenCV.Core.Mat :=
           Typed_Empty.Arg_Maximum (OpenCV.Core.Across_Rows);
      begin
         pragma Unreferenced (Ignored);
      end Check_Typed_Empty;

      procedure Check_Multi_Channel is
         Ignored : constant OpenCV.Core.Mat :=
           Multi_Channel.Arg_Minimum (OpenCV.Core.Across_Columns);
      begin
         pragma Unreferenced (Ignored);
      end Check_Multi_Channel;

      procedure Check_Float16 is
         Ignored : constant OpenCV.Core.Mat :=
           Float16_Image.Arg_Maximum (OpenCV.Core.Across_Columns);
      begin
         pragma Unreferenced (Ignored);
      end Check_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Check_Default'Access, "Arg_Minimum must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Typed_Empty'Access,
         "Arg_Maximum must reject a typed empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Multi_Channel'Access,
         "Arg_Minimum must reject multi-channel input");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access,
         "Arg_Maximum must reject Float16 unsupported by OpenCV 4.10");
   end Invalid_Inputs_Are_Rejected;

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Arg minimum and maximum across columns",
            Arg_Minimum_And_Maximum_Across_Columns'Access));
      Result.Add_Test
        (Caller.Create
           ("Arg minimum and maximum across rows",
            Arg_Minimum_And_Maximum_Across_Rows'Access));
      Result.Add_Test
        (Caller.Create
           ("Arg reductions select requested tie occurrence",
            Ties_Select_Requested_Occurrence'Access));
      Result.Add_Test
        (Caller.Create
           ("Arg reductions handle boundary and degenerate indices",
            Boundary_And_Degenerate_Indices'Access));
      Result.Add_Test
        (Caller.Create
           ("Arg reductions support depths and non-contiguous Regions",
            Supported_Depths_And_Noncontinuous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Arg reduction result ownership and input immutability",
            Result_Ownership_And_Input_Immutability'Access));
      Result.Add_Test
        (Caller.Create
           ("Arg reductions reject invalid inputs",
            Invalid_Inputs_Are_Rejected'Access));
      return Result'Access;
   end Suite;

end Mat_Arg_Reduction_Tests;
