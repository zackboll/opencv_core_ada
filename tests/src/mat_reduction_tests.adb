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

package body Mat_Reduction_Tests is

   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_8;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Point_Coordinate;
   use type OpenCV.Core.UInt8_Vec3.Vector;

   use Mat_Test_Support;

   procedure Float32_Mean_Returns_Arithmetic_Mean_And_Zeroes
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Result : OpenCV.Core.Scalar;
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 6.0);
      Result := Image.Mean;

      AUnit.Assertions.Assert
        (Approximately_Equal (Result.Component_0, 3.0),
         "Mean must return the arithmetic mean of Float32 values");
      AUnit.Assertions.Assert
        (Result.Component_1 = 0.0
         and then Result.Component_2 = 0.0
         and then Result.Component_3 = 0.0,
         "Mean must leave unused Scalar components at zero");
   end Float32_Mean_Returns_Arithmetic_Mean_And_Zeroes;

   procedure UInt8_Mean_Is_Not_Float32_Specific
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Image, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Image, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Image, 0, 2, 9);

      AUnit.Assertions.Assert
        (Approximately_Equal (Image.Mean.Component_0, 4.0),
         "Mean must support UInt8 data");
   end UInt8_Mean_Is_Not_Float32_Specific;

   procedure Trace_Uses_Main_Diagonal_For_Square_And_Rectangular_Mats
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Square : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.UInt8, 1));
      Wide   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Tall   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.UInt8, 1));
   begin
      for Row in 0 .. 2 loop
         for Column in 0 .. 2 loop
            OpenCV.Core.UInt8_Access.Set
              (Square,
               Row,
               Column,
               Interfaces.Unsigned_8 (Row * 3 + Column + 1));
         end loop;
      end loop;
      OpenCV.Core.UInt8_Access.Set (Wide, 0, 0, 2);
      OpenCV.Core.UInt8_Access.Set (Wide, 1, 1, 5);
      OpenCV.Core.UInt8_Access.Set (Wide, 0, 2, 99);
      OpenCV.Core.UInt8_Access.Set (Tall, 0, 0, 3);
      OpenCV.Core.UInt8_Access.Set (Tall, 1, 1, 7);
      OpenCV.Core.UInt8_Access.Set (Tall, 2, 0, 99);

      AUnit.Assertions.Assert
        (Square.Trace.Component_0 = 15.0
         and then Wide.Trace.Component_0 = 7.0
         and then Tall.Trace.Component_0 = 10.0,
         "Trace must sum the main diagonal through the shorter matrix axis");
   end Trace_Uses_Main_Diagonal_For_Square_And_Rectangular_Mats;

   procedure Reduce_Sum_Maps_Axes_Depth_And_Independent_Storage
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Across_Rows  : OpenCV.Core.Mat;
      Across_Cols  : OpenCV.Core.Mat;
      Default_Avg  : OpenCV.Core.Mat;
      Changed_Copy : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 2, 3);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 0, 4);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 1, 5);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 2, 6);
      Across_Rows :=
        Source.Reduce
          (OpenCV.Core.Across_Rows, OpenCV.Core.Sum, OpenCV.Core.Float32);
      Across_Cols :=
        Source.Reduce
          (OpenCV.Core.Across_Columns, OpenCV.Core.Sum, OpenCV.Core.Float32);
      Default_Avg :=
        Source.Reduce (OpenCV.Core.Across_Rows, OpenCV.Core.Average);

      AUnit.Assertions.Assert
        (Across_Rows.Rows = 1
         and then Across_Rows.Columns = 3
         and then Across_Rows.Depth = OpenCV.Core.Float32
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Across_Rows, 0, 0)),
                     5.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Across_Rows, 0, 1)),
                     7.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Across_Rows, 0, 2)),
                     9.0)
         and then Across_Cols.Rows = 2
         and then Across_Cols.Columns = 1
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Across_Cols, 0, 0)),
                     6.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Across_Cols, 1, 0)),
                     15.0)
         and then Default_Avg.Depth = OpenCV.Core.UInt8
         and then OpenCV.Core.UInt8_Access.Get (Default_Avg, 0, 0) = 2,
         "Reduce must map axes, preserve requested/default depth, and sum"
         & " exact values");

      Changed_Copy := Across_Rows;
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 99);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Changed_Copy, 0, 0) = 5.0,
         "A Reduce result must own storage independent of its source");
   end Reduce_Sum_Maps_Axes_Depth_And_Independent_Storage;

   procedure Reduce_Supports_Kinds_Float_Multi_Channel_And_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Float_Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Vec_Source   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 3));
      Parent       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.UInt8, 1));
      View         : OpenCV.Core.Mat;
      Maximum      : OpenCV.Core.Mat;
      Minimum      : OpenCV.Core.Mat;
      Squares      : OpenCV.Core.Mat;
      Vec_Result   : OpenCV.Core.Mat;
      View_Result  : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Float_Source, 0, 0, -1.5);
      OpenCV.Core.Float32_Access.Set (Float_Source, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Float_Source, 1, 0, 3.5);
      OpenCV.Core.Float32_Access.Set (Float_Source, 1, 1, -4.0);
      Maximum :=
        Float_Source.Reduce (OpenCV.Core.Across_Rows, OpenCV.Core.Maximum);
      Minimum :=
        Float_Source.Reduce (OpenCV.Core.Across_Columns, OpenCV.Core.Minimum);
      Squares :=
        Float_Source.Reduce
          (OpenCV.Core.Across_Rows,
           OpenCV.Core.Sum_Of_Squares,
           OpenCV.Core.Float32);

      OpenCV.Core.UInt8_Vec3_Access.Set (Vec_Source, 0, 0, (1, 10, 100));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vec_Source, 1, 0, (4, 40, 200));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vec_Source, 0, 1, (2, 20, 110));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vec_Source, 1, 1, (5, 50, 210));
      Vec_Result :=
        Vec_Source.Reduce (OpenCV.Core.Across_Rows, OpenCV.Core.Average);

      for Row in 0 .. 1 loop
         for Column in 0 .. 3 loop
            OpenCV.Core.UInt8_Access.Set
              (Parent, Row, Column, Interfaces.Unsigned_8 (Row * 10 + Column));
         end loop;
      end loop;
      View := Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      View_Result :=
        View.Reduce
          (OpenCV.Core.Across_Rows, OpenCV.Core.Sum, OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Maximum, 0, 0) = 3.5
         and then OpenCV.Core.Float32_Access.Get (Maximum, 0, 1) = 2.0
         and then OpenCV.Core.Float32_Access.Get (Minimum, 0, 0) = -1.5
         and then OpenCV.Core.Float32_Access.Get (Minimum, 1, 0) = -4.0
         and then OpenCV.Core.Float32_Access.Get (Squares, 0, 0) = 14.5
         and then OpenCV.Core.Float32_Access.Get (Squares, 0, 1) = 20.0
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 0, 0)
                  = (2, 25, 150)
         and then not View.Is_Continuous
         and then View_Result.Rows = 1
         and then View_Result.Columns = 2
         and then OpenCV.Core.Float32_Access.Get (View_Result, 0, 0) = 12.0
         and then OpenCV.Core.Float32_Access.Get (View_Result, 0, 1) = 14.0,
         "Reduce must support all reduction kinds, channels, Float32, and"
         & " non-continuous Regions");
   end Reduce_Supports_Kinds_Float_Multi_Channel_And_Regions;

   procedure Reduce_Handles_Empty_And_Invalid_Depth_Combinations
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Empty        : OpenCV.Core.Mat;
      Empty_Result : OpenCV.Core.Mat;
      UInt8_Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));

      procedure Default_Sum is
         Result : constant OpenCV.Core.Mat :=
           UInt8_Source.Reduce (OpenCV.Core.Across_Rows, OpenCV.Core.Sum);
      begin
         pragma Unreferenced (Result);
      end Default_Sum;

      procedure Converted_Maximum is
         Result : constant OpenCV.Core.Mat :=
           UInt8_Source.Reduce
             (OpenCV.Core.Across_Rows,
              OpenCV.Core.Maximum,
              OpenCV.Core.Float32);
      begin
         pragma Unreferenced (Result);
      end Converted_Maximum;
   begin
      Empty_Result :=
        Empty.Reduce (OpenCV.Core.Across_Rows, OpenCV.Core.Average);
      AUnit.Assertions.Assert
        (Empty_Result.Is_Empty
         and then Empty_Result.Rows = 1
         and then Empty_Result.Columns = 0
         and then Empty_Result.Depth = OpenCV.Core.UInt8,
         "Reduce must preserve OpenCV's empty result shape and default depth");
      Assert_Raises_OpenCV_Error
        (Default_Sum'Access,
         "Default UInt8 Sum must expose OpenCV's unsupported dtype"
         & " combination");
      Assert_Raises_OpenCV_Error
        (Converted_Maximum'Access,
         "Maximum must reject output-depth conversion before entering OpenCV");
   end Reduce_Handles_Empty_And_Invalid_Depth_Combinations;

   procedure Trace_Supports_Float32_And_Multiple_Channels
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Float_Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Vec_Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 3));
      Result      : OpenCV.Core.Scalar;
   begin
      OpenCV.Core.Float32_Access.Set (Float_Image, 0, 0, 1.25);
      OpenCV.Core.Float32_Access.Set (Float_Image, 1, 1, -2.5);
      OpenCV.Core.UInt8_Vec3_Access.Set (Vec_Image, 0, 0, (1, 10, 100));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vec_Image, 1, 1, (3, 14, 104));
      Result := Vec_Image.Trace;

      AUnit.Assertions.Assert
        (Approximately_Equal (Float_Image.Trace.Component_0, -1.25)
         and then Approximately_Equal (Result.Component_0, 4.0)
         and then Approximately_Equal (Result.Component_1, 24.0)
         and then Approximately_Equal (Result.Component_2, 204.0)
         and then Result.Component_3 = 0.0,
         "Trace must preserve Float32 precision and sum each used channel");
   end Trace_Supports_Float32_And_Multiple_Channels;

   procedure Trace_Handles_Regions_Empty_And_Invalid_Types
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent             : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.UInt8, 1));
      Region             : OpenCV.Core.Mat;
      Empty              : OpenCV.Core.Mat;
      Five_Channel_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 5));
      Float16_Image      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float16, 1));

      procedure Trace_Five_Channel_Image is
         Result : constant OpenCV.Core.Scalar := Five_Channel_Image.Trace;
      begin
         pragma Unreferenced (Result);
      end Trace_Five_Channel_Image;

      procedure Trace_Float16_Image is
         Result : constant OpenCV.Core.Scalar := Float16_Image.Trace;
      begin
         pragma Unreferenced (Result);
      end Trace_Float16_Image;
   begin
      for Row in 0 .. 2 loop
         for Column in 0 .. 3 loop
            OpenCV.Core.UInt8_Access.Set
              (Parent,
               Row,
               Column,
               Interfaces.Unsigned_8 (Row * 4 + Column + 1));
         end loop;
      end loop;
      Region := Parent.Region ((X => 1, Y => 0, Width => 2, Height => 3));

      AUnit.Assertions.Assert
        (not Region.Is_Continuous
         and then Region.Trace.Component_0 = 9.0
         and then Region.Trace.Component_0
                  = Region.Diagonal_View.Sum.Component_0
         and then Region.Trace.Component_1
                  = Region.Diagonal_View.Sum.Component_1
         and then Region.Trace.Component_2
                  = Region.Diagonal_View.Sum.Component_2
         and then Region.Trace.Component_3
                  = Region.Diagonal_View.Sum.Component_3
         and then Empty.Trace.Component_0 = 0.0
         and then Empty.Trace.Component_1 = 0.0
         and then Empty.Trace.Component_2 = 0.0
         and then Empty.Trace.Component_3 = 0.0,
         "Trace must accept non-continuous Regions and empty Mats");
      Assert_Raises_OpenCV_Error
        (Trace_Five_Channel_Image'Access,
         "Trace must reject channel results that do not fit Scalar");
      Assert_Raises_OpenCV_Error
        (Trace_Float16_Image'Access,
         "Trace must reject unsupported Float16 Mats");
   end Trace_Handles_Regions_Empty_And_Invalid_Types;

   procedure Fill_2x2
     (Image : in out OpenCV.Core.Mat; A, B, C, D : OpenCV.Core.Float32_Value)
   is
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, A);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, B);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, C);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, D);
   end Fill_2x2;

   function Unchanged_2x2
     (Image : OpenCV.Core.Mat; A, B, C, D : OpenCV.Core.Float32_Value)
      return Boolean
   is (OpenCV.Core.Float32_Access.Get (Image, 0, 0) = A
       and then OpenCV.Core.Float32_Access.Get (Image, 0, 1) = B
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 0) = C
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 1) = D);

   procedure Determinant_1x1_Uses_Sole_Float32_Value
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 7.0);

      AUnit.Assertions.Assert
        (Image.Determinant = 7.0,
         "A 1x1 Determinant must return the sole matrix value");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Image, 0, 0) = 7.0,
         "Determinant must not modify a 1x1 source");
   end Determinant_1x1_Uses_Sole_Float32_Value;

   procedure Determinant_2x2_Uses_Direct_Path (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
   begin
      Fill_2x2 (Image, 4.0, 7.0, 2.0, 6.0);

      AUnit.Assertions.Assert
        (Image.Determinant = 10.0,
         "A 2x2 Determinant must use OpenCV's direct formula");
      AUnit.Assertions.Assert
        (Unchanged_2x2 (Image, 4.0, 7.0, 2.0, 6.0),
         "Determinant must not modify a 2x2 source");
   end Determinant_2x2_Uses_Direct_Path;

   procedure Determinant_2x2_Preserves_Sign (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
   begin
      Fill_2x2 (Image, 1.0, 2.0, 3.0, 4.0);

      AUnit.Assertions.Assert
        (Image.Determinant = -2.0,
         "Determinant must preserve a negative sign");
   end Determinant_2x2_Preserves_Sign;

   procedure Determinant_3x3_Uses_Direct_Path (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 6.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, -2.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 2, 5.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 1, 8.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 2, 7.0);

      AUnit.Assertions.Assert
        (Image.Determinant = -306.0,
         "A 3x3 Determinant must use OpenCV's dedicated direct path");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Image, 0, 0) = 6.0
         and then OpenCV.Core.Float32_Access.Get (Image, 1, 1) = -2.0
         and then OpenCV.Core.Float32_Access.Get (Image, 2, 2) = 7.0,
         "Determinant must not modify a 3x3 source");
   end Determinant_3x3_Uses_Direct_Path;

   procedure Determinant_4x4_Uses_LU_Path (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 3.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 2, 4.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 3, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 3, 3, 5.0);

      AUnit.Assertions.Assert
        (Image.Determinant = 120.0,
         "A 4x4 upper-triangular Determinant must follow OpenCV's LU path");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Image, 0, 0) = 2.0
         and then OpenCV.Core.Float32_Access.Get (Image, 1, 1) = 3.0
         and then OpenCV.Core.Float32_Access.Get (Image, 2, 2) = 4.0
         and then OpenCV.Core.Float32_Access.Get (Image, 3, 3) = 5.0,
         "Determinant must not modify a 4x4 source");
   end Determinant_4x4_Uses_LU_Path;

   procedure Determinant_Singular_4x4_Returns_Zero
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
      Value : Long_Float;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 3, 4.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 3, 4.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 0, 5.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 2, 6.0);
      OpenCV.Core.Float32_Access.Set (Image, 3, 1, 7.0);
      OpenCV.Core.Float32_Access.Set (Image, 3, 3, 8.0);
      Value := Image.Determinant;

      AUnit.Assertions.Assert
        (Value = 0.0,
         "A singular 4x4 matrix must return determinant 0 without error");
   end Determinant_Singular_4x4_Returns_Zero;

   procedure Determinant_Supports_Float64 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Float32_Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Image         : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Float32_Image, 4.0, 7.0, 2.0, 6.0);
      Image := Float32_Image.Convert_To (OpenCV.Core.Float64);

      AUnit.Assertions.Assert
        (Image.Depth = OpenCV.Core.Float64 and then Image.Determinant = 10.0,
         "Determinant must succeed on an actual Float64 matrix");
   end Determinant_Supports_Float64;

   procedure Determinant_Supports_Noncontiguous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 1));
      Region : OpenCV.Core.Mat;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Region := Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      Fill_2x2 (Region, 4.0, 7.0, 2.0, 6.0);

      AUnit.Assertions.Assert
        (not Region.Is_Continuous,
         "The Region used for Determinant must be non-contiguous");
      AUnit.Assertions.Assert
        (Region.Determinant = 10.0,
         "Determinant must support a non-contiguous square Region");
      AUnit.Assertions.Assert
        (Unchanged_2x2 (Region, 4.0, 7.0, 2.0, 6.0)
         and then OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 0, 3) = 99.0,
         "Determinant must not modify the Region or its parent");
   end Determinant_Supports_Noncontiguous_Region;

   procedure Determinant_Equals_Transpose_Determinant
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
   begin
      Fill_2x2 (Image, 1.0, 2.0, 3.0, 4.0);

      AUnit.Assertions.Assert
        (Approximately_Equal (Image.Determinant, Image.Transpose.Determinant),
         "det(A) must equal det(A.Transpose) for an ordinary finite matrix");
   end Determinant_Equals_Transpose_Determinant;

   procedure Determinant_Rejects_Empty_And_Invalid_Types
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Empty : OpenCV.Core.Mat;
      Empty32       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Empty64       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float64, 1));
      Rectangular   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Multi         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 3));
      UInt8_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Int32_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int32, 1));
      Float16_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float16, 1));

      procedure Check_Default is
         Value : constant Long_Float := Default_Empty.Determinant;
      begin
         pragma Unreferenced (Value);
      end Check_Default;

      procedure Check_Empty32 is
         Value : constant Long_Float := Empty32.Determinant;
      begin
         pragma Unreferenced (Value);
      end Check_Empty32;

      procedure Check_Empty64 is
         Value : constant Long_Float := Empty64.Determinant;
      begin
         pragma Unreferenced (Value);
      end Check_Empty64;

      procedure Check_Rectangular is
         Value : constant Long_Float := Rectangular.Determinant;
      begin
         pragma Unreferenced (Value);
      end Check_Rectangular;

      procedure Check_Multi is
         Value : constant Long_Float := Multi.Determinant;
      begin
         pragma Unreferenced (Value);
      end Check_Multi;

      procedure Check_UInt8 is
         Value : constant Long_Float := UInt8_Image.Determinant;
      begin
         pragma Unreferenced (Value);
      end Check_UInt8;

      procedure Check_Int32 is
         Value : constant Long_Float := Int32_Image.Determinant;
      begin
         pragma Unreferenced (Value);
      end Check_Int32;

      procedure Check_Float16 is
         Value : constant Long_Float := Float16_Image.Determinant;
      begin
         pragma Unreferenced (Value);
      end Check_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Check_Default'Access, "Determinant must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access,
         "Determinant must reject a typed empty Float32 Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty64'Access,
         "Determinant must reject a typed empty Float64 Mat");
      Assert_Raises_OpenCV_Error
        (Check_Rectangular'Access,
         "Determinant must reject a rectangular Mat");
      Assert_Raises_OpenCV_Error
        (Check_Multi'Access, "Determinant must reject a multi-channel Mat");
      Assert_Raises_OpenCV_Error
        (Check_UInt8'Access, "Determinant must reject UInt8 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access, "Determinant must reject Int32 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access, "Determinant must reject Float16 Mats");
   end Determinant_Rejects_Empty_And_Invalid_Types;

   function Invertible_2x2
     (Image : OpenCV.Core.Mat; A, B, C, D : Long_Float) return Boolean
   is (Image.Rows = 2
       and then Image.Columns = 2
       and then Image.Channels = 1
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 0, 0)),
                   A)
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 0, 1)),
                   B)
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 1, 0)),
                   C)
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 1, 1)),
                   D));

   procedure Invert_1x1_Uses_Direct_Path (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Inversion_Result;
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 4.0);
      Result := Image.Invert;

      AUnit.Assertions.Assert
        (Result.Invertible
         and then Result.Inverse.Rows = 1
         and then Result.Inverse.Columns = 1
         and then Result.Inverse.Depth = OpenCV.Core.Float32
         and then Result.Inverse.Channels = 1
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result.Inverse, 0, 0)),
                     0.25),
         "A 1x1 Invert must use OpenCV's direct reciprocal path");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Image, 0, 0) = 4.0,
         "Invert must not modify a 1x1 source");
   end Invert_1x1_Uses_Direct_Path;

   procedure Invert_2x2_Uses_Known_Inverse (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Inversion_Result;
   begin
      Fill_2x2 (Image, 4.0, 7.0, 2.0, 6.0);
      Result := Image.Invert;

      AUnit.Assertions.Assert
        (Result.Invertible
         and then Result.Inverse.Rows = 2
         and then Result.Inverse.Columns = 2
         and then Result.Inverse.Depth = OpenCV.Core.Float32
         and then Result.Inverse.Channels = 1
         and then Invertible_2x2 (Result.Inverse, 0.6, -0.7, -0.2, 0.4),
         "A 2x2 Invert must return the known inverse");
      AUnit.Assertions.Assert
        (Unchanged_2x2 (Image, 4.0, 7.0, 2.0, 6.0),
         "Invert must not modify a 2x2 source");
   end Invert_2x2_Uses_Known_Inverse;

   procedure Invert_3x3_Uses_Direct_Path (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Inversion_Result;
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 2, 4.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 0, 5.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 1, 6.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 2, 0.0);
      Result := Image.Invert;

      AUnit.Assertions.Assert
        (Result.Invertible
         and then Result.Inverse.Rows = 3
         and then Result.Inverse.Columns = 3
         and then Result.Inverse.Depth = OpenCV.Core.Float32
         and then Result.Inverse.Channels = 1
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 0, 0) = -24.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 0, 1) = 18.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 0, 2) = 5.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 1, 0) = 20.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 1, 1) = -15.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 1, 2) = -4.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 2, 0) = -5.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 2, 1) = 4.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 2, 2) = 1.0,
         "A 3x3 Invert must use OpenCV's dedicated direct path");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Image, 0, 0) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Image, 1, 1) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Image, 2, 0) = 5.0,
         "Invert must not modify a 3x3 source");
   end Invert_3x3_Uses_Direct_Path;

   procedure Invert_4x4_Uses_LU_Path (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Inversion_Result;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 3, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 3, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 3, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 3, 3, 1.0);
      Result := Image.Invert;

      AUnit.Assertions.Assert
        (Result.Invertible
         and then Result.Inverse.Rows = 4
         and then Result.Inverse.Columns = 4
         and then Result.Inverse.Depth = OpenCV.Core.Float32
         and then Result.Inverse.Channels = 1
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 0, 0) = -1.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 0, 1) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 0, 2) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 0, 3) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 1, 0) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 1, 1) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 1, 2) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 1, 3) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 2, 0) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 2, 1) = -1.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 2, 2) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 2, 3) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 3, 0) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 3, 1) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 3, 2) = -1.0
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 3, 3) = 1.0,
         "A 4x4 Invert must follow OpenCV's LU path, including a row pivot");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Image, 0, 0) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Image, 0, 1) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Image, 3, 3) = 1.0,
         "Invert must not modify a 4x4 source");
   end Invert_4x4_Uses_LU_Path;

   procedure Invert_Singular_2x2_Is_Not_An_Error
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Inversion_Result;
   begin
      Fill_2x2 (Image, 1.0, 2.0, 2.0, 4.0);
      Result := Image.Invert;

      AUnit.Assertions.Assert
        (not Result.Invertible,
         "A singular 2x2 matrix must return Invertible False without error");
      AUnit.Assertions.Assert
        (Unchanged_2x2 (Image, 1.0, 2.0, 2.0, 4.0),
         "Invert must not modify a singular 2x2 source");
   end Invert_Singular_2x2_Is_Not_An_Error;

   procedure Invert_Singular_4x4_Is_Not_An_Error
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Inversion_Result;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 3, 4.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 3, 4.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 0, 5.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 2, 6.0);
      OpenCV.Core.Float32_Access.Set (Image, 3, 1, 7.0);
      OpenCV.Core.Float32_Access.Set (Image, 3, 3, 8.0);
      Result := Image.Invert;

      AUnit.Assertions.Assert
        (not Result.Invertible,
         "A singular 4x4 matrix must return Invertible False without error");
   end Invert_Singular_4x4_Is_Not_An_Error;

   procedure Invert_Determinant_Matches_Reciprocal
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Inversion_Result;
   begin
      Fill_2x2 (Image, 4.0, 7.0, 2.0, 6.0);
      Result := Image.Invert;

      AUnit.Assertions.Assert
        (Result.Invertible
         and then Approximately_Equal
                    (Result.Inverse.Determinant, 1.0 / Image.Determinant),
         "det(A.Invert.Inverse) must equal 1 / det(A) for a well-conditioned"
         & " matrix");
   end Invert_Determinant_Matches_Reciprocal;

   procedure Invert_Supports_Float64 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Float32_Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Image         : OpenCV.Core.Mat;
      Result        : OpenCV.Core.Inversion_Result;
   begin
      Fill_2x2 (Float32_Image, 4.0, 7.0, 2.0, 6.0);
      Image := Float32_Image.Convert_To (OpenCV.Core.Float64);
      Result := Image.Invert;

      AUnit.Assertions.Assert
        (Result.Invertible
         and then Result.Inverse.Depth = OpenCV.Core.Float64
         and then Result.Inverse.Rows = 2
         and then Result.Inverse.Columns = 2
         and then Result.Inverse.Channels = 1
         and then Approximately_Equal
                    (Result.Inverse.Determinant, 1.0 / Image.Determinant),
         "Invert must preserve Float64 depth, dimensions, and invertibility");
   end Invert_Supports_Float64;

   procedure Invert_Supports_Noncontiguous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Inversion_Result;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));

      declare
         Region : OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      begin
         Fill_2x2 (Region, 4.0, 7.0, 2.0, 6.0);
         AUnit.Assertions.Assert
           (not Region.Is_Continuous,
            "The Region used for Invert must be non-contiguous");
         Result := Region.Invert;
         AUnit.Assertions.Assert
           (Result.Invertible
            and then Invertible_2x2 (Result.Inverse, 0.6, -0.7, -0.2, 0.4),
            "Invert must support a non-contiguous square Region");
         AUnit.Assertions.Assert
           (Unchanged_2x2 (Region, 4.0, 7.0, 2.0, 6.0)
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 3) = 99.0,
            "Invert must not modify the Region or its parent");
         OpenCV.Core.Float32_Access.Set (Region, 0, 0, 50.0);
         AUnit.Assertions.Assert
           (Invertible_2x2 (Result.Inverse, 0.6, -0.7, -0.2, 0.4),
            "Mutating a Region must not change its inverse");
         OpenCV.Core.Float32_Access.Set (Result.Inverse, 0, 0, 8.0);
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Access.Get (Region, 0, 0) = 50.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 1) = 50.0,
            "Mutating an inverse must not change the Region or parent");
      end;

      AUnit.Assertions.Assert
        (Result.Invertible
         and then OpenCV.Core.Float32_Access.Get (Result.Inverse, 0, 0) = 8.0
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result.Inverse, 1, 1)),
                     0.4),
         "An inverse must remain valid after Region finalization");
   end Invert_Supports_Noncontiguous_Region;

   procedure Invert_Result_Owns_Independent_Storage
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Inversion_Result;
   begin
      Fill_2x2 (Source, 4.0, 7.0, 2.0, 6.0);
      Result := Source.Invert;
      AUnit.Assertions.Assert
        (Result.Invertible, "The independence source must be invertible");

      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 99.0);
      AUnit.Assertions.Assert
        (Invertible_2x2 (Result.Inverse, 0.6, -0.7, -0.2, 0.4),
         "Mutating the source must not change its inverse");
      OpenCV.Core.Float32_Access.Set (Result.Inverse, 1, 1, 8.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Source, 0, 0) = 99.0
         and then OpenCV.Core.Float32_Access.Get (Source, 1, 1) = 6.0,
         "Mutating the inverse must not change its source");
   end Invert_Result_Owns_Independent_Storage;

   procedure Invert_Transpose_Relationship (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image                : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Inverse_Of_Transpose : OpenCV.Core.Inversion_Result;
      Transpose_Of_Inverse : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Image, 4.0, 7.0, 2.0, 6.0);
      Inverse_Of_Transpose := Image.Transpose.Invert;
      Transpose_Of_Inverse := Image.Invert.Inverse.Transpose;

      AUnit.Assertions.Assert
        (Inverse_Of_Transpose.Invertible
         and then Invertible_2x2
                    (Inverse_Of_Transpose.Inverse, 0.6, -0.2, -0.7, 0.4)
         and then Invertible_2x2 (Transpose_Of_Inverse, 0.6, -0.2, -0.7, 0.4),
         "The inverse of a transpose must match the transpose of the inverse");
   end Invert_Transpose_Relationship;

   procedure Invert_Rejects_Empty_And_Invalid_Types
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Empty : OpenCV.Core.Mat;
      Empty32       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Empty64       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float64, 1));
      Rectangular   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Multi         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 3));
      UInt8_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Int32_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int32, 1));
      Float16_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float16, 1));

      procedure Check_Default is
         Result : constant OpenCV.Core.Inversion_Result :=
           Default_Empty.Invert;
      begin
         pragma Unreferenced (Result);
      end Check_Default;

      procedure Check_Empty32 is
         Result : constant OpenCV.Core.Inversion_Result := Empty32.Invert;
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;

      procedure Check_Empty64 is
         Result : constant OpenCV.Core.Inversion_Result := Empty64.Invert;
      begin
         pragma Unreferenced (Result);
      end Check_Empty64;

      procedure Check_Rectangular is
         Result : constant OpenCV.Core.Inversion_Result := Rectangular.Invert;
      begin
         pragma Unreferenced (Result);
      end Check_Rectangular;

      procedure Check_Multi is
         Result : constant OpenCV.Core.Inversion_Result := Multi.Invert;
      begin
         pragma Unreferenced (Result);
      end Check_Multi;

      procedure Check_UInt8 is
         Result : constant OpenCV.Core.Inversion_Result := UInt8_Image.Invert;
      begin
         pragma Unreferenced (Result);
      end Check_UInt8;

      procedure Check_Int32 is
         Result : constant OpenCV.Core.Inversion_Result := Int32_Image.Invert;
      begin
         pragma Unreferenced (Result);
      end Check_Int32;

      procedure Check_Float16 is
         Result : constant OpenCV.Core.Inversion_Result :=
           Float16_Image.Invert;
      begin
         pragma Unreferenced (Result);
      end Check_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Check_Default'Access, "Invert must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access, "Invert must reject a typed empty Float32 Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty64'Access, "Invert must reject a typed empty Float64 Mat");
      Assert_Raises_OpenCV_Error
        (Check_Rectangular'Access,
         "Invert must reject a rectangular Mat; LU inversion is not a"
         & " pseudo-inverse");
      Assert_Raises_OpenCV_Error
        (Check_Multi'Access, "Invert must reject a multi-channel Mat");
      Assert_Raises_OpenCV_Error
        (Check_UInt8'Access, "Invert must reject UInt8 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access, "Invert must reject Int32 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access, "Invert must reject Float16 Mats");
   end Invert_Rejects_Empty_And_Invalid_Types;

   procedure Fill_Column_2
     (Image : in out OpenCV.Core.Mat; A, B : OpenCV.Core.Float32_Value) is
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, A);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, B);
   end Fill_Column_2;

   function Unchanged_Column_2
     (Image : OpenCV.Core.Mat; A, B : OpenCV.Core.Float32_Value) return Boolean
   is (OpenCV.Core.Float32_Access.Get (Image, 0, 0) = A
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 0) = B);

   function Solved_2x1
     (Image : OpenCV.Core.Mat; A, B : Long_Float) return Boolean
   is (Image.Rows = 2
       and then Image.Columns = 1
       and then Image.Channels = 1
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 0, 0)),
                   A)
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 1, 0)),
                   B));

   procedure Solve_1x1_Uses_Direct_Path (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      RHS          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Result       : OpenCV.Core.Solve_Result;
   begin
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (RHS, 0, 0, 2.0);
      Result := Coefficients.Solve (RHS);

      AUnit.Assertions.Assert
        (Result.Solved
         and then Result.Solution.Rows = 1
         and then Result.Solution.Columns = 1
         and then Result.Solution.Depth = OpenCV.Core.Float32
         and then Result.Solution.Channels = 1
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Result.Solution, 0, 0)),
                     0.5),
         "A 1x1 Solve must return the reciprocal-scaled right-hand side");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Coefficients, 0, 0) = 4.0
         and then OpenCV.Core.Float32_Access.Get (RHS, 0, 0) = 2.0,
         "Solve must not modify a 1x1 source or right-hand side");
   end Solve_1x1_Uses_Direct_Path;

   procedure Solve_2x2_Uses_Known_Solution (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      RHS          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      Result       : OpenCV.Core.Solve_Result;
   begin
      Fill_2x2 (Coefficients, 4.0, 7.0, 2.0, 6.0);
      Fill_Column_2 (RHS, 15.0, 10.0);
      Result := Coefficients.Solve (RHS);

      AUnit.Assertions.Assert
        (Result.Solved
         and then Result.Solution.Depth = OpenCV.Core.Float32
         and then Solved_2x1 (Result.Solution, 2.0, 1.0),
         "A 2x2 Solve must return the known unique solution");
      AUnit.Assertions.Assert
        (Unchanged_2x2 (Coefficients, 4.0, 7.0, 2.0, 6.0)
         and then Unchanged_Column_2 (RHS, 15.0, 10.0),
         "Solve must not modify a 2x2 source or right-hand side");
   end Solve_2x2_Uses_Known_Solution;

   procedure Solve_3x3_Uses_Direct_Path (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      RHS          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Result       : OpenCV.Core.Solve_Result;
   begin
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 1, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 1, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 1, 2, 4.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 2, 0, 5.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 2, 1, 6.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 2, 2, 0.0);
      RHS.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.Float32_Access.Set (RHS, 0, 0, 1.0);
      Result := Coefficients.Solve (RHS);

      AUnit.Assertions.Assert
        (Result.Solved
         and then Result.Solution.Rows = 3
         and then Result.Solution.Columns = 1
         and then Result.Solution.Depth = OpenCV.Core.Float32
         and then Result.Solution.Channels = 1
         and then OpenCV.Core.Float32_Access.Get (Result.Solution, 0, 0)
                  = -24.0
         and then OpenCV.Core.Float32_Access.Get (Result.Solution, 1, 0) = 20.0
         and then OpenCV.Core.Float32_Access.Get (Result.Solution, 2, 0)
                  = -5.0,
         "A 3x3 Solve must use OpenCV's dedicated direct path");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Coefficients, 0, 0) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Coefficients, 1, 1) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Coefficients, 2, 0) = 5.0
         and then OpenCV.Core.Float32_Access.Get (RHS, 0, 0) = 1.0
         and then OpenCV.Core.Float32_Access.Get (RHS, 1, 0) = 0.0,
         "Solve must not modify a 3x3 source or right-hand side");
   end Solve_3x3_Uses_Direct_Path;

   procedure Solve_4x4_Uses_LU_Path (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
      RHS          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.Float32, 1));
      Result       : OpenCV.Core.Solve_Result;
   begin
      Coefficients.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 1, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 1, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 2, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 2, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 2, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 3, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 3, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 3, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 3, 3, 1.0);
      RHS.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.Float32_Access.Set (RHS, 0, 0, 1.0);
      Result := Coefficients.Solve (RHS);

      AUnit.Assertions.Assert
        (Result.Solved
         and then Result.Solution.Rows = 4
         and then Result.Solution.Columns = 1
         and then Result.Solution.Depth = OpenCV.Core.Float32
         and then Result.Solution.Channels = 1
         and then OpenCV.Core.Float32_Access.Get (Result.Solution, 0, 0) = -1.0
         and then OpenCV.Core.Float32_Access.Get (Result.Solution, 1, 0) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Result.Solution, 2, 0) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Result.Solution, 3, 0) = 0.0,
         "A 4x4 Solve must follow OpenCV's LU path, including a row pivot");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Coefficients, 0, 0) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Coefficients, 0, 1) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Coefficients, 3, 3) = 1.0
         and then OpenCV.Core.Float32_Access.Get (RHS, 0, 0) = 1.0,
         "Solve must not modify a 4x4 source or right-hand side");
   end Solve_4x4_Uses_LU_Path;

   procedure Solve_Multiple_RHS_Columns (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      RHS          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result       : OpenCV.Core.Solve_Result;
   begin
      Fill_2x2 (Coefficients, 4.0, 7.0, 2.0, 6.0);
      Fill_2x2 (RHS, 1.0, 0.0, 0.0, 1.0);
      Result := Coefficients.Solve (RHS);

      AUnit.Assertions.Assert
        (Result.Solved
         and then Result.Solution.Rows = 2
         and then Result.Solution.Columns = 2
         and then Result.Solution.Depth = OpenCV.Core.Float32
         and then Result.Solution.Channels = 1
         and then Invertible_2x2 (Result.Solution, 0.6, -0.7, -0.2, 0.4),
         "Solve must accept multiple right-hand-side columns");
      AUnit.Assertions.Assert
        (Unchanged_2x2 (Coefficients, 4.0, 7.0, 2.0, 6.0)
         and then Unchanged_2x2 (RHS, 1.0, 0.0, 0.0, 1.0),
         "Solve must not modify a multi-column right-hand side");
   end Solve_Multiple_RHS_Columns;

   procedure Solve_Singular_2x2_Is_Not_An_Error
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      RHS          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      Result       : OpenCV.Core.Solve_Result;
   begin
      Fill_2x2 (Coefficients, 1.0, 2.0, 2.0, 4.0);
      Fill_Column_2 (RHS, 1.0, 0.0);
      Result := Coefficients.Solve (RHS);

      AUnit.Assertions.Assert
        (not Result.Solved,
         "A singular 2x2 system must return Solved False without error");
      AUnit.Assertions.Assert
        (Unchanged_2x2 (Coefficients, 1.0, 2.0, 2.0, 4.0)
         and then Unchanged_Column_2 (RHS, 1.0, 0.0),
         "Solve must not modify a singular 2x2 source or right-hand side");
   end Solve_Singular_2x2_Is_Not_An_Error;

   procedure Solve_Singular_4x4_Is_Not_An_Error
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
      RHS          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.Float32, 1));
      Result       : OpenCV.Core.Solve_Result;
   begin
      Coefficients.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 3, 4.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 1, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 1, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 1, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 1, 3, 4.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 2, 0, 5.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 2, 2, 6.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 3, 1, 7.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 3, 3, 8.0);
      RHS.Set_To (OpenCV.Core.Make_Scalar (1.0));
      Result := Coefficients.Solve (RHS);

      AUnit.Assertions.Assert
        (not Result.Solved,
         "A singular 4x4 system must return Solved False without error");
   end Solve_Singular_4x4_Is_Not_An_Error;

   procedure Solve_Supports_Float64 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Float32_A : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Float32_B : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      A         : OpenCV.Core.Mat;
      B         : OpenCV.Core.Mat;
      Result    : OpenCV.Core.Solve_Result;
      Converted : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Float32_A, 4.0, 7.0, 2.0, 6.0);
      Fill_Column_2 (Float32_B, 15.0, 10.0);
      A := Float32_A.Convert_To (OpenCV.Core.Float64);
      B := Float32_B.Convert_To (OpenCV.Core.Float64);
      Result := A.Solve (B);

      AUnit.Assertions.Assert (Result.Solved, "Float64 Solve must succeed");
      Converted := Result.Solution.Convert_To (OpenCV.Core.Float32);
      AUnit.Assertions.Assert
        (Result.Solution.Depth = OpenCV.Core.Float64
         and then Result.Solution.Rows = 2
         and then Result.Solution.Columns = 1
         and then Result.Solution.Channels = 1
         and then Solved_2x1 (Converted, 2.0, 1.0),
         "Solve must preserve Float64 depth and the known unique solution");
   end Solve_Supports_Float64;

   procedure Solve_Supports_Noncontiguous_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent_A : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 1));
      Parent_B : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Result   : OpenCV.Core.Solve_Result;
   begin
      Parent_A.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Parent_B.Set_To (OpenCV.Core.Make_Scalar (88.0));

      declare
         Region_A : OpenCV.Core.Mat :=
           Parent_A.Region ((X => 1, Y => 0, Width => 2, Height => 2));
         Region_B : OpenCV.Core.Mat :=
           Parent_B.Region ((X => 1, Y => 0, Width => 1, Height => 2));
      begin
         Fill_2x2 (Region_A, 4.0, 7.0, 2.0, 6.0);
         Fill_Column_2 (Region_B, 15.0, 10.0);
         AUnit.Assertions.Assert
           (not Region_A.Is_Continuous and then not Region_B.Is_Continuous,
            "The Regions used for Solve must be non-contiguous");
         Result := Region_A.Solve (Region_B);
         AUnit.Assertions.Assert
           (Result.Solved and then Solved_2x1 (Result.Solution, 2.0, 1.0),
            "Solve must support non-contiguous coefficient and RHS Regions");
         AUnit.Assertions.Assert
           (Unchanged_2x2 (Region_A, 4.0, 7.0, 2.0, 6.0)
            and then Unchanged_Column_2 (Region_B, 15.0, 10.0)
            and then OpenCV.Core.Float32_Access.Get (Parent_A, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent_A, 0, 3) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent_B, 0, 0) = 88.0,
            "Solve must not modify the Regions or their parents");
         OpenCV.Core.Float32_Access.Set (Region_A, 0, 0, 50.0);
         OpenCV.Core.Float32_Access.Set (Region_B, 0, 0, 40.0);
         AUnit.Assertions.Assert
           (Solved_2x1 (Result.Solution, 2.0, 1.0),
            "Mutating the Regions must not change the solution");
         OpenCV.Core.Float32_Access.Set (Result.Solution, 0, 0, 8.0);
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Access.Get (Region_A, 0, 0) = 50.0
            and then OpenCV.Core.Float32_Access.Get (Region_B, 0, 0) = 40.0
            and then OpenCV.Core.Float32_Access.Get (Parent_A, 0, 1) = 50.0
            and then OpenCV.Core.Float32_Access.Get (Parent_B, 0, 1) = 40.0,
            "Mutating a solution must not change the Regions or parents");
      end;

      AUnit.Assertions.Assert
        (Result.Solved
         and then OpenCV.Core.Float32_Access.Get (Result.Solution, 0, 0) = 8.0
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Result.Solution, 1, 0)),
                     1.0),
         "A solution must remain valid after Region finalization");
   end Solve_Supports_Noncontiguous_Regions;

   procedure Solve_Result_Owns_Independent_Storage
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      RHS          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      Result       : OpenCV.Core.Solve_Result;
   begin
      Fill_2x2 (Coefficients, 4.0, 7.0, 2.0, 6.0);
      Fill_Column_2 (RHS, 15.0, 10.0);
      Result := Coefficients.Solve (RHS);
      AUnit.Assertions.Assert
        (Result.Solved, "The independence source must be solved");

      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 0, 99.0);
      OpenCV.Core.Float32_Access.Set (RHS, 0, 0, 88.0);
      AUnit.Assertions.Assert
        (Solved_2x1 (Result.Solution, 2.0, 1.0),
         "Mutating the inputs must not change the solution");
      OpenCV.Core.Float32_Access.Set (Result.Solution, 1, 0, 8.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Coefficients, 0, 0) = 99.0
         and then OpenCV.Core.Float32_Access.Get (Coefficients, 1, 1) = 6.0
         and then OpenCV.Core.Float32_Access.Get (RHS, 0, 0) = 88.0
         and then OpenCV.Core.Float32_Access.Get (RHS, 1, 0) = 10.0,
         "Mutating the solution must not change its inputs");
   end Solve_Result_Owns_Independent_Storage;

   procedure Solve_Rejects_Empty_And_Invalid_Types
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Valid_A       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Valid_B       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      Default_Empty : OpenCV.Core.Mat;
      Empty32       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Empty64       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float64, 1));
      Rectangular   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Multi         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 3));
      Multi_B       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 3));
      UInt8_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Int32_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int32, 1));
      Float16_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float16, 1));
      Float64_B     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float64, 1));
      Wrong_Rows    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));

      procedure Check_Default is
         Result : constant OpenCV.Core.Solve_Result :=
           Default_Empty.Solve (Valid_B);
      begin
         pragma Unreferenced (Result);
      end Check_Default;

      procedure Check_Empty32 is
         Result : constant OpenCV.Core.Solve_Result := Empty32.Solve (Valid_B);
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;

      procedure Check_Empty64 is
         Result : constant OpenCV.Core.Solve_Result := Empty64.Solve (Valid_B);
      begin
         pragma Unreferenced (Result);
      end Check_Empty64;

      procedure Check_Empty_RHS is
         Result : constant OpenCV.Core.Solve_Result :=
           Valid_A.Solve (Default_Empty);
      begin
         pragma Unreferenced (Result);
      end Check_Empty_RHS;

      procedure Check_Rectangular is
         Result : constant OpenCV.Core.Solve_Result :=
           Rectangular.Solve (Valid_B);
      begin
         pragma Unreferenced (Result);
      end Check_Rectangular;

      procedure Check_Multi is
         Result : constant OpenCV.Core.Solve_Result := Multi.Solve (Valid_B);
      begin
         pragma Unreferenced (Result);
      end Check_Multi;

      procedure Check_Multi_B is
         Result : constant OpenCV.Core.Solve_Result := Valid_A.Solve (Multi_B);
      begin
         pragma Unreferenced (Result);
      end Check_Multi_B;

      procedure Check_UInt8 is
         Result : constant OpenCV.Core.Solve_Result :=
           UInt8_Image.Solve (UInt8_Image);
      begin
         pragma Unreferenced (Result);
      end Check_UInt8;

      procedure Check_Int32 is
         Result : constant OpenCV.Core.Solve_Result :=
           Int32_Image.Solve (Int32_Image);
      begin
         pragma Unreferenced (Result);
      end Check_Int32;

      procedure Check_Float16 is
         Result : constant OpenCV.Core.Solve_Result :=
           Float16_Image.Solve (Float16_Image);
      begin
         pragma Unreferenced (Result);
      end Check_Float16;

      procedure Check_Depth_Mismatch is
         Result : constant OpenCV.Core.Solve_Result :=
           Valid_A.Solve (Float64_B);
      begin
         pragma Unreferenced (Result);
      end Check_Depth_Mismatch;

      procedure Check_Row_Mismatch is
         Result : constant OpenCV.Core.Solve_Result :=
           Valid_A.Solve (Wrong_Rows);
      begin
         pragma Unreferenced (Result);
      end Check_Row_Mismatch;
   begin
      Fill_2x2 (Valid_A, 4.0, 7.0, 2.0, 6.0);
      Fill_Column_2 (Valid_B, 15.0, 10.0);
      Assert_Raises_OpenCV_Error
        (Check_Default'Access, "Solve must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access, "Solve must reject a typed empty Float32 Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty64'Access, "Solve must reject a typed empty Float64 Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty_RHS'Access, "Solve must reject an empty right-hand side");
      Assert_Raises_OpenCV_Error
        (Check_Rectangular'Access,
         "Solve must reject a rectangular Mat; LU solution is not a"
         & " least-squares API");
      Assert_Raises_OpenCV_Error
        (Check_Multi'Access, "Solve must reject a multi-channel Mat");
      Assert_Raises_OpenCV_Error
        (Check_Multi_B'Access,
         "Solve must reject a multi-channel right-hand side");
      Assert_Raises_OpenCV_Error
        (Check_UInt8'Access, "Solve must reject UInt8 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access, "Solve must reject Int32 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access, "Solve must reject Float16 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Depth_Mismatch'Access,
         "Solve must reject a right-hand side with a different depth");
      Assert_Raises_OpenCV_Error
        (Check_Row_Mismatch'Access,
         "Solve must reject a right-hand side with a different row count");
   end Solve_Rejects_Empty_And_Invalid_Types;

   procedure Fill_2x3
     (Image            : in out OpenCV.Core.Mat;
      A, B, C, D, E, F : OpenCV.Core.Float32_Value) is
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, A);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, B);
      OpenCV.Core.Float32_Access.Set (Image, 0, 2, C);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, D);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, E);
      OpenCV.Core.Float32_Access.Set (Image, 1, 2, F);
   end Fill_2x3;

   function Unchanged_2x3
     (Image : OpenCV.Core.Mat; A, B, C, D, E, F : OpenCV.Core.Float32_Value)
      return Boolean
   is (OpenCV.Core.Float32_Access.Get (Image, 0, 0) = A
       and then OpenCV.Core.Float32_Access.Get (Image, 0, 1) = B
       and then OpenCV.Core.Float32_Access.Get (Image, 0, 2) = C
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 0) = D
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 1) = E
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 2) = F);

   procedure Fill_3x2
     (Image            : in out OpenCV.Core.Mat;
      A, B, C, D, E, F : OpenCV.Core.Float32_Value) is
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, A);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, B);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, C);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, D);
      OpenCV.Core.Float32_Access.Set (Image, 2, 0, E);
      OpenCV.Core.Float32_Access.Set (Image, 2, 1, F);
   end Fill_3x2;

   function Unchanged_3x2
     (Image : OpenCV.Core.Mat; A, B, C, D, E, F : OpenCV.Core.Float32_Value)
      return Boolean
   is (OpenCV.Core.Float32_Access.Get (Image, 0, 0) = A
       and then OpenCV.Core.Float32_Access.Get (Image, 0, 1) = B
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 0) = C
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 1) = D
       and then OpenCV.Core.Float32_Access.Get (Image, 2, 0) = E
       and then OpenCV.Core.Float32_Access.Get (Image, 2, 1) = F);

   function Product_2x2
     (Image : OpenCV.Core.Mat; A, B, C, D : OpenCV.Core.Float32_Value)
      return Boolean
   is (Image.Rows = 2
       and then Image.Columns = 2
       and then Image.Depth = OpenCV.Core.Float32
       and then Image.Channels = 1
       and then OpenCV.Core.Float32_Access.Get (Image, 0, 0) = A
       and then OpenCV.Core.Float32_Access.Get (Image, 0, 1) = B
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 0) = C
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 1) = D);

   procedure Matrix_Multiply_2x3_Times_3x2_Float32
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Left, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Fill_3x2 (Right, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0);
      Result := Left.Matrix_Multiply (Right);

      AUnit.Assertions.Assert
        (Product_2x2 (Result, 58.0, 64.0, 139.0, 154.0),
         "2x3 * 3x2 Matrix_Multiply must compute the algebraic product");
      AUnit.Assertions.Assert
        (Unchanged_2x3 (Left, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0)
         and then Unchanged_3x2 (Right, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0),
         "Matrix_Multiply must not modify its operands");
   end Matrix_Multiply_2x3_Times_3x2_Float32;

   procedure Matrix_Multiply_Non_Square_Output (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Left, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Right.Set_To (OpenCV.Core.Make_Scalar (1.0));
      Result := Left.Matrix_Multiply (Right);

      AUnit.Assertions.Assert
        (Result.Rows = 2
         and then Result.Columns = 4
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 1
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 0) = 6.0
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 3) = 6.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 0) = 15.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 3) = 15.0,
         "2x3 * 3x4 must produce a 2x4 product without requiring squares");
   end Matrix_Multiply_Non_Square_Output;

   procedure Matrix_Multiply_Row_Times_Column (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Left, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Left, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Left, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Right, 1, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Right, 2, 0, 3.0);
      Result := Left.Matrix_Multiply (Right);

      AUnit.Assertions.Assert
        (Result.Rows = 1
         and then Result.Columns = 1
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 1
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 0) = 14.0,
         "A 1x3 row times a 3x1 column must produce the 1x1 product 14");
   end Matrix_Multiply_Row_Times_Column;

   procedure Matrix_Multiply_Column_Times_Row (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Left, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Left, 1, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Left, 2, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 1, 5.0);
      Result := Left.Matrix_Multiply (Right);

      AUnit.Assertions.Assert
        (Result.Rows = 3
         and then Result.Columns = 2
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 1
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 0) = 4.0
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 1) = 5.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 0) = 8.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 1) = 10.0
         and then OpenCV.Core.Float32_Access.Get (Result, 2, 0) = 12.0
         and then OpenCV.Core.Float32_Access.Get (Result, 2, 1) = 15.0,
         "A 3x1 column times a 1x2 row must produce the outer-product 3x2");
   end Matrix_Multiply_Column_Times_Row;

   procedure Matrix_Multiply_Identity_Integration
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Identity : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Result   : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Left, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Identity.Set_Identity;
      Result := Left.Matrix_Multiply (Identity);

      AUnit.Assertions.Assert
        (Result.Rows = 2
         and then Result.Columns = 3
         and then Unchanged_2x3 (Result, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0),
         "A 2x3 Mat times a 3x3 identity must equal the original Mat");
   end Matrix_Multiply_Identity_Integration;

   procedure Matrix_Multiply_Supports_Float64 (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left32    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Right32   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Left      : OpenCV.Core.Mat;
      Right     : OpenCV.Core.Mat;
      Result    : OpenCV.Core.Mat;
      Converted : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Left32, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Fill_3x2 (Right32, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0);
      Left := Left32.Convert_To (OpenCV.Core.Float64);
      Right := Right32.Convert_To (OpenCV.Core.Float64);
      Result := Left.Matrix_Multiply (Right);
      Converted := Result.Convert_To (OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (Result.Depth = OpenCV.Core.Float64
         and then Result.Rows = 2
         and then Result.Columns = 2
         and then Result.Channels = 1
         and then Product_2x2 (Converted, 58.0, 64.0, 139.0, 154.0),
         "Matrix_Multiply must preserve Float64 depth and the known product");
   end Matrix_Multiply_Supports_Float64;

   procedure Matrix_Multiply_Complex_Float32 (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left_Real  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Left_Imag  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Right_Real : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      Right_Imag : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      Left       : OpenCV.Core.Mat;
      Right      : OpenCV.Core.Mat;
      Result     : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Left_Real, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Left_Imag, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Left_Real, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Left_Imag, 0, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Right_Real, 0, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Right_Imag, 0, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Right_Real, 1, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Right_Imag, 1, 0, -1.0);
      Left := OpenCV.Core.Merge ((Left_Real, Left_Imag));
      Right := OpenCV.Core.Merge ((Right_Real, Right_Imag));
      Result := Left.Matrix_Multiply (Right);

      declare
         Parts : constant OpenCV.Core.Mat_Array := Result.Split;
      begin
         AUnit.Assertions.Assert
           (Result.Depth = OpenCV.Core.Float32
            and then Result.Channels = 2
            and then Result.Rows = 1
            and then Result.Columns = 1
            and then Parts'Length = 2
            and then OpenCV.Core.Float32_Access.Get (Parts (0), 0, 0) = 11.0
            and then OpenCV.Core.Float32_Access.Get (Parts (1), 0, 0) = 1.0,
            "Two-channel Matrix_Multiply must use complex arithmetic");
      end;
   end Matrix_Multiply_Complex_Float32;

   procedure Matrix_Multiply_Complex_Float64 (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left_Real  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Left_Imag  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Right_Real : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Right_Imag : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Left       : OpenCV.Core.Mat;
      Right      : OpenCV.Core.Mat;
      Result     : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Left_Real, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Left_Imag, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Right_Real, 0, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Right_Imag, 0, 0, -1.0);
      Left :=
        OpenCV.Core.Merge ((Left_Real, Left_Imag)).Convert_To
          (OpenCV.Core.Float64);
      Right :=
        OpenCV.Core.Merge ((Right_Real, Right_Imag)).Convert_To
          (OpenCV.Core.Float64);
      Result := Left.Matrix_Multiply (Right);

      declare
         Parts     : constant OpenCV.Core.Mat_Array := Result.Split;
         Real_Copy : constant OpenCV.Core.Mat :=
           Parts (0).Convert_To (OpenCV.Core.Float32);
         Imag_Copy : constant OpenCV.Core.Mat :=
           Parts (1).Convert_To (OpenCV.Core.Float32);
      begin
         AUnit.Assertions.Assert
           (Result.Depth = OpenCV.Core.Float64
            and then Result.Channels = 2
            and then Result.Rows = 1
            and then Result.Columns = 1
            and then OpenCV.Core.Float32_Access.Get (Real_Copy, 0, 0) = 7.0
            and then OpenCV.Core.Float32_Access.Get (Imag_Copy, 0, 0) = 1.0,
            "Float64 two-channel Matrix_Multiply must use complex"
            & " arithmetic");
      end;
   end Matrix_Multiply_Complex_Float64;

   procedure Matrix_Multiply_Noncontiguous_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent_Left  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 5, (OpenCV.Core.Float32, 1));
      Parent_Right : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
      Result       : OpenCV.Core.Mat;
   begin
      Parent_Left.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Parent_Right.Set_To (OpenCV.Core.Make_Scalar (88.0));

      declare
         Left  : OpenCV.Core.Mat :=
           Parent_Left.Region ((X => 1, Y => 0, Width => 3, Height => 2));
         Right : OpenCV.Core.Mat :=
           Parent_Right.Region ((X => 1, Y => 0, Width => 2, Height => 3));
      begin
         Fill_2x3 (Left, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
         Fill_3x2 (Right, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0);
         AUnit.Assertions.Assert
           (not Left.Is_Continuous and then not Right.Is_Continuous,
            "The Regions used for Matrix_Multiply must be non-contiguous");
         Result := Left.Matrix_Multiply (Right);
         AUnit.Assertions.Assert
           (Product_2x2 (Result, 58.0, 64.0, 139.0, 154.0),
            "Matrix_Multiply must support non-contiguous Left and Right"
            & " Regions");
         AUnit.Assertions.Assert
           (Unchanged_2x3 (Left, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0)
            and then Unchanged_3x2 (Right, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0)
            and then OpenCV.Core.Float32_Access.Get (Parent_Left, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent_Left, 0, 4) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent_Right, 0, 0)
                     = 88.0,
            "Matrix_Multiply must not modify the Regions or their parents");
      end;
   end Matrix_Multiply_Noncontiguous_Regions;

   procedure Matrix_Multiply_Result_Owns_Independent_Storage
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Left, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Fill_3x2 (Right, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0);
      Result := Left.Matrix_Multiply (Right);

      OpenCV.Core.Float32_Access.Set (Left, 0, 0, 50.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 0, 40.0);
      AUnit.Assertions.Assert
        (Product_2x2 (Result, 58.0, 64.0, 139.0, 154.0),
         "Mutating the operands must not change the Matrix_Multiply result");
      OpenCV.Core.Float32_Access.Set (Result, 0, 0, 8.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Left, 0, 0) = 50.0
         and then OpenCV.Core.Float32_Access.Get (Left, 1, 2) = 6.0
         and then OpenCV.Core.Float32_Access.Get (Right, 0, 0) = 40.0
         and then OpenCV.Core.Float32_Access.Get (Right, 2, 1) = 12.0,
         "Mutating the result must not change either Matrix_Multiply source");
   end Matrix_Multiply_Result_Owns_Independent_Storage;

   procedure Matrix_Multiply_Rejects_Invalid_Inputs
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Valid_Left    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Valid_Right   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Default_Empty : OpenCV.Core.Mat;
      Empty32       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Empty64       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float64, 1));
      Wrong_Shape   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Float64_Right : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float64, 1));
      UInt8_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Int32_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int32, 1));
      Float16_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float16, 1));
      Three_Channel : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 3));

      procedure Check_Default_Left is
         Result : constant OpenCV.Core.Mat :=
           Default_Empty.Matrix_Multiply (Valid_Right);
      begin
         pragma Unreferenced (Result);
      end Check_Default_Left;

      procedure Check_Default_Right is
         Result : constant OpenCV.Core.Mat :=
           Valid_Left.Matrix_Multiply (Default_Empty);
      begin
         pragma Unreferenced (Result);
      end Check_Default_Right;

      procedure Check_Empty32 is
         Result : constant OpenCV.Core.Mat :=
           Empty32.Matrix_Multiply (Valid_Right);
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;

      procedure Check_Empty64 is
         Result : constant OpenCV.Core.Mat :=
           Valid_Left.Matrix_Multiply (Empty64);
      begin
         pragma Unreferenced (Result);
      end Check_Empty64;

      procedure Check_Shape is
         Result : constant OpenCV.Core.Mat :=
           Valid_Left.Matrix_Multiply (Wrong_Shape);
      begin
         pragma Unreferenced (Result);
      end Check_Shape;

      procedure Check_Type is
         Result : constant OpenCV.Core.Mat :=
           Valid_Left.Matrix_Multiply (Float64_Right);
      begin
         pragma Unreferenced (Result);
      end Check_Type;

      procedure Check_UInt8 is
         Result : constant OpenCV.Core.Mat :=
           UInt8_Image.Matrix_Multiply (UInt8_Image);
      begin
         pragma Unreferenced (Result);
      end Check_UInt8;

      procedure Check_Int32 is
         Result : constant OpenCV.Core.Mat :=
           Int32_Image.Matrix_Multiply (Int32_Image);
      begin
         pragma Unreferenced (Result);
      end Check_Int32;

      procedure Check_Float16 is
         Result : constant OpenCV.Core.Mat :=
           Float16_Image.Matrix_Multiply (Float16_Image);
      begin
         pragma Unreferenced (Result);
      end Check_Float16;

      procedure Check_Three_Channel is
         Result : constant OpenCV.Core.Mat :=
           Three_Channel.Matrix_Multiply (Three_Channel);
      begin
         pragma Unreferenced (Result);
      end Check_Three_Channel;
   begin
      Fill_2x3 (Valid_Left, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Fill_3x2 (Valid_Right, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0);
      Assert_Raises_OpenCV_Error
        (Check_Default_Left'Access,
         "Matrix_Multiply must reject a default empty Left");
      Assert_Raises_OpenCV_Error
        (Check_Default_Right'Access,
         "Matrix_Multiply must reject a default empty Right");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access,
         "Matrix_Multiply must reject a typed empty Float32 Left");
      Assert_Raises_OpenCV_Error
        (Check_Empty64'Access,
         "Matrix_Multiply must reject a typed empty Float64 Right");
      Assert_Raises_OpenCV_Error
        (Check_Shape'Access,
         "Matrix_Multiply must reject incompatible inner dimensions");
      Assert_Raises_OpenCV_Error
        (Check_Type'Access,
         "Matrix_Multiply must reject mixed Float32 and Float64 operands");
      Assert_Raises_OpenCV_Error
        (Check_UInt8'Access, "Matrix_Multiply must reject UInt8 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access, "Matrix_Multiply must reject Int32 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access, "Matrix_Multiply must reject Float16 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Three_Channel'Access,
         "Matrix_Multiply must reject Float32 Mats with three channels");
   end Matrix_Multiply_Rejects_Invalid_Inputs;

   procedure Matrix_Multiply_Add_Weighted_Float32
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Addend : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Left, 1.0, 2.0, 3.0, 4.0);
      Fill_2x2 (Right, 5.0, 6.0, 7.0, 8.0);
      Fill_2x2 (Addend, 1.0, 2.0, 3.0, 4.0);
      Result :=
        OpenCV.Core.Matrix_Multiply_Add
          (Left, Right, Addend, Product_Scale => 2.0, Addend_Scale => 3.0);

      AUnit.Assertions.Assert
        (Product_2x2 (Result, 41.0, 50.0, 95.0, 112.0),
         "Weighted Matrix_Multiply_Add must compute 2*product + 3*addend");
      AUnit.Assertions.Assert
        (Product_2x2 (Left, 1.0, 2.0, 3.0, 4.0)
         and then Product_2x2 (Right, 5.0, 6.0, 7.0, 8.0)
         and then Product_2x2 (Addend, 1.0, 2.0, 3.0, 4.0),
         "Matrix_Multiply_Add must not modify its operands");
   end Matrix_Multiply_Add_Weighted_Float32;

   procedure Matrix_Multiply_Add_Default_Scales
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Addend : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Left, 1.0, 2.0, 3.0, 4.0);
      Fill_2x2 (Right, 5.0, 6.0, 7.0, 8.0);
      Fill_2x2 (Addend, 1.0, 2.0, 3.0, 4.0);
      Result := OpenCV.Core.Matrix_Multiply_Add (Left, Right, Addend);

      AUnit.Assertions.Assert
        (Product_2x2 (Result, 20.0, 24.0, 46.0, 54.0),
         "Default Matrix_Multiply_Add scales must both be 1.0");
   end Matrix_Multiply_Add_Default_Scales;

   procedure Matrix_Multiply_Add_Product_Scale_Zero
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Addend : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Left, 1.0, 2.0, 3.0, 4.0);
      Fill_2x2 (Right, 5.0, 6.0, 7.0, 8.0);
      Fill_2x2 (Addend, 1.0, 2.0, 3.0, 4.0);
      Result :=
        OpenCV.Core.Matrix_Multiply_Add
          (Left, Right, Addend, Product_Scale => 0.0, Addend_Scale => 2.0);

      AUnit.Assertions.Assert
        (Product_2x2 (Result, 2.0, 4.0, 6.0, 8.0),
         "Product_Scale 0.0 must yield only the scaled Addend");
   end Matrix_Multiply_Add_Product_Scale_Zero;

   procedure Matrix_Multiply_Add_Addend_Scale_Zero
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Addend : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Left, 1.0, 2.0, 3.0, 4.0);
      Fill_2x2 (Right, 5.0, 6.0, 7.0, 8.0);
      Fill_2x2 (Addend, 9.0, 8.0, 7.0, 6.0);
      Result :=
        OpenCV.Core.Matrix_Multiply_Add
          (Left, Right, Addend, Product_Scale => 2.0, Addend_Scale => 0.0);

      AUnit.Assertions.Assert
        (Product_2x2 (Result, 38.0, 44.0, 86.0, 100.0),
         "Addend_Scale 0.0 must yield only the scaled product");
   end Matrix_Multiply_Add_Addend_Scale_Zero;

   procedure Matrix_Multiply_Add_Negative_Scales
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Addend : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Left, 1.0, 2.0, 3.0, 4.0);
      Fill_2x2 (Right, 5.0, 6.0, 7.0, 8.0);
      Fill_2x2 (Addend, 2.0, 4.0, 6.0, 8.0);
      Result :=
        OpenCV.Core.Matrix_Multiply_Add
          (Left, Right, Addend, Product_Scale => -1.0, Addend_Scale => 0.5);

      AUnit.Assertions.Assert
        (Product_2x2 (Result, -18.0, -20.0, -40.0, -46.0),
         "Negative Product_Scale and fractional Addend_Scale must be"
         & " passed through to OpenCV");
   end Matrix_Multiply_Add_Negative_Scales;

   procedure Matrix_Multiply_Add_Rectangular_Product
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 1));
      Addend : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Left, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Right.Set_To (OpenCV.Core.Make_Scalar (1.0));
      Addend.Set_To (OpenCV.Core.Make_Scalar (2.0));
      Result :=
        OpenCV.Core.Matrix_Multiply_Add
          (Left, Right, Addend, Product_Scale => 1.0, Addend_Scale => 1.0);

      AUnit.Assertions.Assert
        (Result.Rows = 2
         and then Result.Columns = 4
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 1
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 0) = 8.0
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 3) = 8.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 0) = 17.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 3) = 17.0,
         "2x3 * 3x4 + 2x4 must produce a 2x4 weighted result");
   end Matrix_Multiply_Add_Rectangular_Product;

   procedure Matrix_Multiply_Add_Supports_Float64
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left32    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Right32   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Addend32  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Left      : OpenCV.Core.Mat;
      Right     : OpenCV.Core.Mat;
      Addend    : OpenCV.Core.Mat;
      Result    : OpenCV.Core.Mat;
      Converted : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Left32, 1.0, 2.0, 3.0, 4.0);
      Fill_2x2 (Right32, 5.0, 6.0, 7.0, 8.0);
      Fill_2x2 (Addend32, 1.0, 2.0, 3.0, 4.0);
      Left := Left32.Convert_To (OpenCV.Core.Float64);
      Right := Right32.Convert_To (OpenCV.Core.Float64);
      Addend := Addend32.Convert_To (OpenCV.Core.Float64);
      Result :=
        OpenCV.Core.Matrix_Multiply_Add
          (Left, Right, Addend, Product_Scale => 2.0, Addend_Scale => 3.0);
      Converted := Result.Convert_To (OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (Result.Depth = OpenCV.Core.Float64
         and then Result.Rows = 2
         and then Result.Columns = 2
         and then Result.Channels = 1
         and then Product_2x2 (Converted, 41.0, 50.0, 95.0, 112.0),
         "Matrix_Multiply_Add must preserve Float64 depth and the known"
         & " weighted result");
   end Matrix_Multiply_Add_Supports_Float64;

   procedure Matrix_Multiply_Add_Complex_Float32
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left_Real   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Left_Imag   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Right_Real  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Right_Imag  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Addend_Real : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Addend_Imag : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Left        : OpenCV.Core.Mat;
      Right       : OpenCV.Core.Mat;
      Addend      : OpenCV.Core.Mat;
      Result      : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Left_Real, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Left_Imag, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Right_Real, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Right_Imag, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Addend_Real, 0, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Addend_Imag, 0, 0, -1.0);
      Left := OpenCV.Core.Merge ((Left_Real, Left_Imag));
      Right := OpenCV.Core.Merge ((Right_Real, Right_Imag));
      Addend := OpenCV.Core.Merge ((Addend_Real, Addend_Imag));
      Result :=
        OpenCV.Core.Matrix_Multiply_Add
          (Left, Right, Addend, Product_Scale => 2.0, Addend_Scale => 0.5);

      declare
         Parts : constant OpenCV.Core.Mat_Array := Result.Split;
      begin
         AUnit.Assertions.Assert
           (Result.Depth = OpenCV.Core.Float32
            and then Result.Channels = 2
            and then Result.Rows = 1
            and then Result.Columns = 1
            and then Parts'Length = 2
            and then OpenCV.Core.Float32_Access.Get (Parts (0), 0, 0) = 3.5
            and then OpenCV.Core.Float32_Access.Get (Parts (1), 0, 0) = 5.5,
            "Two-channel Matrix_Multiply_Add must use complex arithmetic");
      end;
   end Matrix_Multiply_Add_Complex_Float32;

   procedure Matrix_Multiply_Add_Complex_Float64
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left_Real   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Left_Imag   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Right_Real  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Right_Imag  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Addend_Real : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Addend_Imag : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Left        : OpenCV.Core.Mat;
      Right       : OpenCV.Core.Mat;
      Addend      : OpenCV.Core.Mat;
      Result      : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Left_Real, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Left_Imag, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Right_Real, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Right_Imag, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Addend_Real, 0, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Addend_Imag, 0, 0, -1.0);
      Left :=
        OpenCV.Core.Merge ((Left_Real, Left_Imag)).Convert_To
          (OpenCV.Core.Float64);
      Right :=
        OpenCV.Core.Merge ((Right_Real, Right_Imag)).Convert_To
          (OpenCV.Core.Float64);
      Addend :=
        OpenCV.Core.Merge ((Addend_Real, Addend_Imag)).Convert_To
          (OpenCV.Core.Float64);
      Result :=
        OpenCV.Core.Matrix_Multiply_Add
          (Left, Right, Addend, Product_Scale => 2.0, Addend_Scale => 0.5);

      declare
         Parts     : constant OpenCV.Core.Mat_Array := Result.Split;
         Real_Copy : constant OpenCV.Core.Mat :=
           Parts (0).Convert_To (OpenCV.Core.Float32);
         Imag_Copy : constant OpenCV.Core.Mat :=
           Parts (1).Convert_To (OpenCV.Core.Float32);
      begin
         AUnit.Assertions.Assert
           (Result.Depth = OpenCV.Core.Float64
            and then Result.Channels = 2
            and then Result.Rows = 1
            and then Result.Columns = 1
            and then OpenCV.Core.Float32_Access.Get (Real_Copy, 0, 0) = 3.5
            and then OpenCV.Core.Float32_Access.Get (Imag_Copy, 0, 0) = 5.5,
            "Float64 two-channel Matrix_Multiply_Add must use complex"
            & " arithmetic");
      end;
   end Matrix_Multiply_Add_Complex_Float64;

   procedure Matrix_Multiply_Add_Noncontiguous_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent_Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 5, (OpenCV.Core.Float32, 1));
      Parent_Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
      Parent_Addend : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 1));
      Result        : OpenCV.Core.Mat;
   begin
      Parent_Left.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Parent_Right.Set_To (OpenCV.Core.Make_Scalar (88.0));
      Parent_Addend.Set_To (OpenCV.Core.Make_Scalar (77.0));

      declare
         Left   : OpenCV.Core.Mat :=
           Parent_Left.Region ((X => 1, Y => 0, Width => 3, Height => 2));
         Right  : OpenCV.Core.Mat :=
           Parent_Right.Region ((X => 1, Y => 0, Width => 2, Height => 3));
         Addend : OpenCV.Core.Mat :=
           Parent_Addend.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      begin
         Fill_2x3 (Left, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
         Fill_3x2 (Right, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0);
         Fill_2x2 (Addend, 1.0, 2.0, 3.0, 4.0);
         AUnit.Assertions.Assert
           (not Left.Is_Continuous
            and then not Right.Is_Continuous
            and then not Addend.Is_Continuous,
            "The Regions used for Matrix_Multiply_Add must be"
            & " non-contiguous");
         Result :=
           OpenCV.Core.Matrix_Multiply_Add
             (Left, Right, Addend, Product_Scale => 1.0, Addend_Scale => 1.0);
         AUnit.Assertions.Assert
           (Product_2x2 (Result, 59.0, 66.0, 142.0, 158.0),
            "Matrix_Multiply_Add must support non-contiguous Left, Right,"
            & " and Addend Regions");
         AUnit.Assertions.Assert
           (Unchanged_2x3 (Left, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0)
            and then Unchanged_3x2 (Right, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0)
            and then Product_2x2 (Addend, 1.0, 2.0, 3.0, 4.0)
            and then OpenCV.Core.Float32_Access.Get (Parent_Left, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent_Left, 0, 4) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent_Right, 0, 0) = 88.0
            and then OpenCV.Core.Float32_Access.Get (Parent_Addend, 0, 0)
                     = 77.0,
            "Matrix_Multiply_Add must not modify the Regions or their"
            & " parents");
      end;
   end Matrix_Multiply_Add_Noncontiguous_Regions;

   procedure Matrix_Multiply_Add_Result_Owns_Independent_Storage
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Addend : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Left, 1.0, 2.0, 3.0, 4.0);
      Fill_2x2 (Right, 5.0, 6.0, 7.0, 8.0);
      Fill_2x2 (Addend, 1.0, 2.0, 3.0, 4.0);
      Result :=
        OpenCV.Core.Matrix_Multiply_Add
          (Left, Right, Addend, Product_Scale => 2.0, Addend_Scale => 3.0);

      OpenCV.Core.Float32_Access.Set (Left, 0, 0, 50.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 0, 40.0);
      OpenCV.Core.Float32_Access.Set (Addend, 0, 0, 30.0);
      AUnit.Assertions.Assert
        (Product_2x2 (Result, 41.0, 50.0, 95.0, 112.0),
         "Mutating the operands must not change the Matrix_Multiply_Add"
         & " result");
      OpenCV.Core.Float32_Access.Set (Result, 0, 0, 8.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Left, 0, 0) = 50.0
         and then OpenCV.Core.Float32_Access.Get (Left, 1, 1) = 4.0
         and then OpenCV.Core.Float32_Access.Get (Right, 0, 0) = 40.0
         and then OpenCV.Core.Float32_Access.Get (Right, 1, 1) = 8.0
         and then OpenCV.Core.Float32_Access.Get (Addend, 0, 0) = 30.0
         and then OpenCV.Core.Float32_Access.Get (Addend, 1, 1) = 4.0,
         "Mutating the result must not change any Matrix_Multiply_Add"
         & " source");
   end Matrix_Multiply_Add_Result_Owns_Independent_Storage;

   procedure Matrix_Multiply_Add_Rejects_Invalid_Inputs
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Valid_Left     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Valid_Right    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Valid_Addend   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Default_Empty  : OpenCV.Core.Mat;
      Empty32        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Empty64        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float64, 1));
      Wrong_Inner    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Wrong_Addend   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Float64_Addend : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float64, 1));
      Float64_Right  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float64, 1));
      UInt8_Image    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Int32_Image    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int32, 1));
      Float16_Image  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float16, 1));
      Three_Channel  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 3));

      procedure Check_Default_Left is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.Matrix_Multiply_Add
             (Default_Empty, Valid_Right, Valid_Addend);
      begin
         pragma Unreferenced (Result);
      end Check_Default_Left;

      procedure Check_Default_Right is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.Matrix_Multiply_Add
             (Valid_Left, Default_Empty, Valid_Addend);
      begin
         pragma Unreferenced (Result);
      end Check_Default_Right;

      procedure Check_Default_Addend is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.Matrix_Multiply_Add
             (Valid_Left, Valid_Right, Default_Empty);
      begin
         pragma Unreferenced (Result);
      end Check_Default_Addend;

      procedure Check_Empty32 is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.Matrix_Multiply_Add
             (Empty32, Valid_Right, Valid_Addend);
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;

      procedure Check_Empty64 is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.Matrix_Multiply_Add (Valid_Left, Empty64, Valid_Addend);
      begin
         pragma Unreferenced (Result);
      end Check_Empty64;

      procedure Check_Empty_Addend is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.Matrix_Multiply_Add (Valid_Left, Valid_Right, Empty32);
      begin
         pragma Unreferenced (Result);
      end Check_Empty_Addend;

      procedure Check_Inner_Shape is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.Matrix_Multiply_Add
             (Valid_Left, Wrong_Inner, Valid_Addend);
      begin
         pragma Unreferenced (Result);
      end Check_Inner_Shape;

      procedure Check_Addend_Shape is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.Matrix_Multiply_Add
             (Valid_Left, Valid_Right, Wrong_Addend);
      begin
         pragma Unreferenced (Result);
      end Check_Addend_Shape;

      procedure Check_Addend_Type is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.Matrix_Multiply_Add
             (Valid_Left, Valid_Right, Float64_Addend);
      begin
         pragma Unreferenced (Result);
      end Check_Addend_Type;

      procedure Check_Left_Right_Type is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.Matrix_Multiply_Add
             (Valid_Left, Float64_Right, Valid_Addend);
      begin
         pragma Unreferenced (Result);
      end Check_Left_Right_Type;

      procedure Check_UInt8 is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.Matrix_Multiply_Add
             (UInt8_Image, UInt8_Image, UInt8_Image);
      begin
         pragma Unreferenced (Result);
      end Check_UInt8;

      procedure Check_Int32 is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.Matrix_Multiply_Add
             (Int32_Image, Int32_Image, Int32_Image);
      begin
         pragma Unreferenced (Result);
      end Check_Int32;

      procedure Check_Float16 is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.Matrix_Multiply_Add
             (Float16_Image, Float16_Image, Float16_Image);
      begin
         pragma Unreferenced (Result);
      end Check_Float16;

      procedure Check_Three_Channel is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.Matrix_Multiply_Add
             (Three_Channel, Three_Channel, Three_Channel);
      begin
         pragma Unreferenced (Result);
      end Check_Three_Channel;

      procedure Check_Addend_Scale_Zero_Still_Validates is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.Matrix_Multiply_Add
             (Valid_Left,
              Valid_Right,
              Wrong_Addend,
              Product_Scale => 1.0,
              Addend_Scale  => 0.0);
      begin
         pragma Unreferenced (Result);
      end Check_Addend_Scale_Zero_Still_Validates;

   begin
      Fill_2x3 (Valid_Left, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Fill_3x2 (Valid_Right, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0);
      Fill_2x2 (Valid_Addend, 1.0, 2.0, 3.0, 4.0);
      Assert_Raises_OpenCV_Error
        (Check_Default_Left'Access,
         "Matrix_Multiply_Add must reject a default empty Left");
      Assert_Raises_OpenCV_Error
        (Check_Default_Right'Access,
         "Matrix_Multiply_Add must reject a default empty Right");
      Assert_Raises_OpenCV_Error
        (Check_Default_Addend'Access,
         "Matrix_Multiply_Add must reject a default empty Addend");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access,
         "Matrix_Multiply_Add must reject a typed empty Float32 Left");
      Assert_Raises_OpenCV_Error
        (Check_Empty64'Access,
         "Matrix_Multiply_Add must reject a typed empty Float64 Right");
      Assert_Raises_OpenCV_Error
        (Check_Empty_Addend'Access,
         "Matrix_Multiply_Add must reject a typed empty Float32 Addend");
      Assert_Raises_OpenCV_Error
        (Check_Inner_Shape'Access,
         "Matrix_Multiply_Add must reject incompatible inner dimensions");
      Assert_Raises_OpenCV_Error
        (Check_Addend_Shape'Access,
         "Matrix_Multiply_Add must reject an Addend with the wrong product"
         & " shape");
      Assert_Raises_OpenCV_Error
        (Check_Addend_Type'Access,
         "Matrix_Multiply_Add must reject a Float64 Addend with Float32"
         & " operands");
      Assert_Raises_OpenCV_Error
        (Check_Left_Right_Type'Access,
         "Matrix_Multiply_Add must reject mixed Float32 and Float64 Left"
         & " and Right");
      Assert_Raises_OpenCV_Error
        (Check_UInt8'Access, "Matrix_Multiply_Add must reject UInt8 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access, "Matrix_Multiply_Add must reject Int32 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access, "Matrix_Multiply_Add must reject Float16 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Three_Channel'Access,
         "Matrix_Multiply_Add must reject Float32 Mats with three"
         & " channels");
      Assert_Raises_OpenCV_Error
        (Check_Addend_Scale_Zero_Still_Validates'Access,
         "Matrix_Multiply_Add must reject an invalid Addend even when"
         & " Addend_Scale is 0.0");
   end Matrix_Multiply_Add_Rejects_Invalid_Inputs;

   function Product_3x3
     (Image                     : OpenCV.Core.Mat;
      A, B, C, D, E, F, G, H, I : OpenCV.Core.Float32_Value) return Boolean
   is (Image.Rows = 3
       and then Image.Columns = 3
       and then Image.Depth = OpenCV.Core.Float32
       and then Image.Channels = 1
       and then OpenCV.Core.Float32_Access.Get (Image, 0, 0) = A
       and then OpenCV.Core.Float32_Access.Get (Image, 0, 1) = B
       and then OpenCV.Core.Float32_Access.Get (Image, 0, 2) = C
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 0) = D
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 1) = E
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 2) = F
       and then OpenCV.Core.Float32_Access.Get (Image, 2, 0) = G
       and then OpenCV.Core.Float32_Access.Get (Image, 2, 1) = H
       and then OpenCV.Core.Float32_Access.Get (Image, 2, 2) = I);

   procedure Transposed_Product_Float32_Transpose_Times_Self
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Result :=
        Source.Transposed_Product (Order => OpenCV.Core.Transpose_Times_Self);

      AUnit.Assertions.Assert
        (Product_3x3
           (Result, 17.0, 22.0, 27.0, 22.0, 29.0, 36.0, 27.0, 36.0, 45.0),
         "Transpose_Times_Self must compute Scale * Self'T * Self");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Result, 0, 1)
         = OpenCV.Core.Float32_Access.Get (Result, 1, 0)
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 2)
                  = OpenCV.Core.Float32_Access.Get (Result, 2, 0)
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 2)
                  = OpenCV.Core.Float32_Access.Get (Result, 2, 1),
         "Transposed_Product must produce a symmetric result");
      AUnit.Assertions.Assert
        (Unchanged_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0),
         "Transposed_Product must not modify its source");
   end Transposed_Product_Float32_Transpose_Times_Self;

   procedure Transposed_Product_Float32_Self_Times_Transpose
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Result :=
        Source.Transposed_Product (Order => OpenCV.Core.Self_Times_Transpose);

      AUnit.Assertions.Assert
        (Product_2x2 (Result, 14.0, 32.0, 32.0, 77.0),
         "Self_Times_Transpose must compute Scale * Self * Self'T");
   end Transposed_Product_Float32_Self_Times_Transpose;

   procedure Transposed_Product_Applies_Scale (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Half   : OpenCV.Core.Mat;
      Zero   : OpenCV.Core.Mat;
      Neg    : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Half :=
        Source.Transposed_Product
          (Order => OpenCV.Core.Transpose_Times_Self, Scale => 0.5);
      Zero :=
        Source.Transposed_Product
          (Order => OpenCV.Core.Transpose_Times_Self, Scale => 0.0);
      Neg :=
        Source.Transposed_Product
          (Order => OpenCV.Core.Transpose_Times_Self, Scale => -1.0);

      AUnit.Assertions.Assert
        (Product_3x3
           (Half, 8.5, 11.0, 13.5, 11.0, 14.5, 18.0, 13.5, 18.0, 22.5),
         "Transposed_Product must apply a fractional Scale");
      AUnit.Assertions.Assert
        (Product_3x3 (Zero, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0),
         "Transposed_Product must apply a zero Scale");
      AUnit.Assertions.Assert
        (Product_3x3
           (Neg,
            -17.0,
            -22.0,
            -27.0,
            -22.0,
            -29.0,
            -36.0,
            -27.0,
            -36.0,
            -45.0),
         "Transposed_Product must apply a negative Scale");
   end Transposed_Product_Applies_Scale;

   procedure Transposed_Product_UInt8_Automatic_Output
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Result : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 2, 3);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 0, 4);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 1, 5);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 2, 6);
      Result :=
        Source.Transposed_Product (Order => OpenCV.Core.Transpose_Times_Self);

      AUnit.Assertions.Assert
        (Source.Depth = OpenCV.Core.UInt8
         and then Product_3x3
                    (Result,
                     17.0,
                     22.0,
                     27.0,
                     22.0,
                     29.0,
                     36.0,
                     27.0,
                     36.0,
                     45.0),
         "UInt8 Transposed_Product must promote automatically to Float32");
   end Transposed_Product_UInt8_Automatic_Output;

   procedure Transposed_Product_UInt16_Automatic_Output
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source8 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Source  : OpenCV.Core.Mat;
      Result  : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Source8, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Source8, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Source8, 0, 2, 3);
      OpenCV.Core.UInt8_Access.Set (Source8, 1, 0, 4);
      OpenCV.Core.UInt8_Access.Set (Source8, 1, 1, 5);
      OpenCV.Core.UInt8_Access.Set (Source8, 1, 2, 6);
      Source := Source8.Convert_To (OpenCV.Core.UInt16);
      Result :=
        Source.Transposed_Product (Order => OpenCV.Core.Transpose_Times_Self);

      AUnit.Assertions.Assert
        (Source.Depth = OpenCV.Core.UInt16
         and then Product_3x3
                    (Result,
                     17.0,
                     22.0,
                     27.0,
                     22.0,
                     29.0,
                     36.0,
                     27.0,
                     36.0,
                     45.0),
         "UInt16 Transposed_Product must promote automatically to Float32");
   end Transposed_Product_UInt16_Automatic_Output;

   procedure Transposed_Product_Int16_Automatic_Output
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Source   : OpenCV.Core.Mat;
      Result   : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Source32, 1.0, -2.0, -3.0, 4.0);
      Source := Source32.Convert_To (OpenCV.Core.Int16);
      Result :=
        Source.Transposed_Product (Order => OpenCV.Core.Transpose_Times_Self);

      AUnit.Assertions.Assert
        (Source.Depth = OpenCV.Core.Int16
         and then Product_2x2 (Result, 10.0, -14.0, -14.0, 20.0),
         "Int16 Transposed_Product must promote automatically to Float32");
   end Transposed_Product_Int16_Automatic_Output;

   procedure Transposed_Product_Float64_Automatic_Output
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Source    : OpenCV.Core.Mat;
      Result    : OpenCV.Core.Mat;
      Converted : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source32, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Source := Source32.Convert_To (OpenCV.Core.Float64);
      Result :=
        Source.Transposed_Product (Order => OpenCV.Core.Transpose_Times_Self);
      Converted := Result.Convert_To (OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (Result.Depth = OpenCV.Core.Float64
         and then Result.Rows = 3
         and then Result.Columns = 3
         and then Result.Channels = 1
         and then Product_3x3
                    (Converted,
                     17.0,
                     22.0,
                     27.0,
                     22.0,
                     29.0,
                     36.0,
                     27.0,
                     36.0,
                     45.0),
         "Float64 Transposed_Product must keep Float64 automatic depth");
   end Transposed_Product_Float64_Automatic_Output;

   procedure Transposed_Product_Explicit_Float64_From_Float32
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Result    : OpenCV.Core.Mat;
      Converted : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Result :=
        Source.Transposed_Product
          (Order        => OpenCV.Core.Transpose_Times_Self,
           Output_Depth => OpenCV.Core.Float64);
      Converted := Result.Convert_To (OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (Result.Depth = OpenCV.Core.Float64
         and then Source.Depth = OpenCV.Core.Float32
         and then Product_3x3
                    (Converted,
                     17.0,
                     22.0,
                     27.0,
                     22.0,
                     29.0,
                     36.0,
                     27.0,
                     36.0,
                     45.0),
         "Explicit Float64 output from Float32 must preserve values");
   end Transposed_Product_Explicit_Float64_From_Float32;

   procedure Transposed_Product_Explicit_Float64_From_UInt8
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Result    : OpenCV.Core.Mat;
      Converted : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 2, 3);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 0, 4);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 1, 5);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 2, 6);
      Result :=
        Source.Transposed_Product
          (Order        => OpenCV.Core.Transpose_Times_Self,
           Output_Depth => OpenCV.Core.Float64);
      Converted := Result.Convert_To (OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (Result.Depth = OpenCV.Core.Float64
         and then Source.Depth = OpenCV.Core.UInt8
         and then Product_3x3
                    (Converted,
                     17.0,
                     22.0,
                     27.0,
                     22.0,
                     29.0,
                     36.0,
                     27.0,
                     36.0,
                     45.0),
         "Explicit Float64 output from UInt8 must use the 64-bit kernel");
   end Transposed_Product_Explicit_Float64_From_UInt8;

   procedure Transposed_Product_Noncontiguous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 5, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));

      declare
         Source : OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 3, Height => 2));
      begin
         Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
         AUnit.Assertions.Assert
           (not Source.Is_Continuous,
            "The Region used for Transposed_Product must be non-contiguous");
         Result :=
           Source.Transposed_Product
             (Order => OpenCV.Core.Transpose_Times_Self);
         AUnit.Assertions.Assert
           (Product_3x3
              (Result, 17.0, 22.0, 27.0, 22.0, 29.0, 36.0, 27.0, 36.0, 45.0),
            "Transposed_Product must honor a non-contiguous Region");
         AUnit.Assertions.Assert
           (Unchanged_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0)
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 4) = 99.0,
            "Transposed_Product must not modify the Region or its parent");
      end;
   end Transposed_Product_Noncontiguous_Region;

   procedure Transposed_Product_Result_Owns_Independent_Storage
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Result :=
        Source.Transposed_Product (Order => OpenCV.Core.Transpose_Times_Self);

      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 50.0);
      AUnit.Assertions.Assert
        (Product_3x3
           (Result, 17.0, 22.0, 27.0, 22.0, 29.0, 36.0, 27.0, 36.0, 45.0),
         "Mutating the source must not change the Transposed_Product result");
      OpenCV.Core.Float32_Access.Set (Result, 0, 0, 8.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Source, 0, 0) = 50.0
         and then OpenCV.Core.Float32_Access.Get (Source, 1, 2) = 6.0,
         "Mutating the result must not change the Transposed_Product source");
   end Transposed_Product_Result_Owns_Independent_Storage;

   procedure Transposed_Product_Rejects_Invalid_Inputs
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Valid          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Default_Empty  : OpenCV.Core.Mat;
      Empty_UInt8    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.UInt8, 1));
      Empty32        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Empty64        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float64, 1));
      Int8_Image     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int8, 1));
      Int32_Image    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int32, 1));
      Float16_Image  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float16, 1));
      Two_Channel    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 2));
      Three_Channel  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 3));
      Float64_Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float64, 1));

      procedure Check_Default is
         Result : constant OpenCV.Core.Mat :=
           Default_Empty.Transposed_Product
             (Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_Default;

      procedure Check_Empty_UInt8 is
         Result : constant OpenCV.Core.Mat :=
           Empty_UInt8.Transposed_Product
             (Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_Empty_UInt8;

      procedure Check_Empty32 is
         Result : constant OpenCV.Core.Mat :=
           Empty32.Transposed_Product
             (Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;

      procedure Check_Empty64 is
         Result : constant OpenCV.Core.Mat :=
           Empty64.Transposed_Product
             (Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_Empty64;

      procedure Check_Int8 is
         Result : constant OpenCV.Core.Mat :=
           Int8_Image.Transposed_Product
             (Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_Int8;

      procedure Check_Int32 is
         Result : constant OpenCV.Core.Mat :=
           Int32_Image.Transposed_Product
             (Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_Int32;

      procedure Check_Float16 is
         Result : constant OpenCV.Core.Mat :=
           Float16_Image.Transposed_Product
             (Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_Float16;

      procedure Check_Two_Channel is
         Result : constant OpenCV.Core.Mat :=
           Two_Channel.Transposed_Product
             (Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_Two_Channel;

      procedure Check_Three_Channel is
         Result : constant OpenCV.Core.Mat :=
           Three_Channel.Transposed_Product
             (Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_Three_Channel;

      procedure Check_Float64_To_Float32 is
         Result : constant OpenCV.Core.Mat :=
           Float64_Source.Transposed_Product
             (Order        => OpenCV.Core.Transpose_Times_Self,
              Output_Depth => OpenCV.Core.Float32);
      begin
         pragma Unreferenced (Result);
      end Check_Float64_To_Float32;

      procedure Check_Integer_Output is
         Result : constant OpenCV.Core.Mat :=
           Valid.Transposed_Product
             (Order        => OpenCV.Core.Transpose_Times_Self,
              Output_Depth => OpenCV.Core.UInt8);
      begin
         pragma Unreferenced (Result);
      end Check_Integer_Output;
   begin
      Fill_2x3 (Valid, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Assert_Raises_OpenCV_Error
        (Check_Default'Access,
         "Transposed_Product must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty_UInt8'Access,
         "Transposed_Product must reject a typed empty UInt8 Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access,
         "Transposed_Product must reject a typed empty Float32 Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty64'Access,
         "Transposed_Product must reject a typed empty Float64 Mat");
      Assert_Raises_OpenCV_Error
        (Check_Int8'Access, "Transposed_Product must reject Int8 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access, "Transposed_Product must reject Int32 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access, "Transposed_Product must reject Float16 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Two_Channel'Access,
         "Transposed_Product must reject Float32 C2 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Three_Channel'Access,
         "Transposed_Product must reject Float32 C3 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Float64_To_Float32'Access,
         "Transposed_Product must reject Float64 source with Float32 output");
      Assert_Raises_OpenCV_Error
        (Check_Integer_Output'Access,
         "Transposed_Product must reject a non-floating output depth");
   end Transposed_Product_Rejects_Invalid_Inputs;

   procedure Vec3_Mean_Returns_Independent_Channel_Values
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Result : OpenCV.Core.Scalar;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (Image, 0, 0, (1, 10, 100));
      OpenCV.Core.UInt8_Vec3_Access.Set (Image, 0, 1, (3, 14, 104));
      Result := Image.Mean;

      AUnit.Assertions.Assert
        (Approximately_Equal (Result.Component_0, 2.0)
         and then Approximately_Equal (Result.Component_1, 12.0)
         and then Approximately_Equal (Result.Component_2, 102.0)
         and then Result.Component_3 = 0.0,
         "Mean must report each Vec3 channel independently and preserve zero"
         & " in the unused Scalar component");
   end Vec3_Mean_Returns_Independent_Channel_Values;

   procedure Float32_Mean_Std_Dev_Uses_Population_Deviation
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Result : OpenCV.Core.Mean_Std_Dev_Result;
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 4.0);
      Result := Image.Mean_Std_Dev;

      AUnit.Assertions.Assert
        (Approximately_Equal (Result.Mean.Component_0, 2.5)
         and then Approximately_Equal
                    (Result.Standard_Deviation.Component_0,
                     1.118_033_988_749_895),
         "Mean_Std_Dev must use OpenCV's population standard deviation");
      AUnit.Assertions.Assert
        (Result.Mean.Component_1 = 0.0
         and then Result.Standard_Deviation.Component_1 = 0.0,
         "Mean_Std_Dev must preserve zero in unused Scalar components");
   end Float32_Mean_Std_Dev_Uses_Population_Deviation;

   procedure Vec3_Mean_Std_Dev_Returns_Independent_Channel_Values
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Result : OpenCV.Core.Mean_Std_Dev_Result;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (Image, 0, 0, (1, 10, 100));
      OpenCV.Core.UInt8_Vec3_Access.Set (Image, 0, 1, (3, 14, 104));
      Result := Image.Mean_Std_Dev;

      AUnit.Assertions.Assert
        (Approximately_Equal (Result.Mean.Component_0, 2.0)
         and then Approximately_Equal (Result.Mean.Component_1, 12.0)
         and then Approximately_Equal (Result.Mean.Component_2, 102.0)
         and then Approximately_Equal
                    (Result.Standard_Deviation.Component_0, 1.0)
         and then Approximately_Equal
                    (Result.Standard_Deviation.Component_1, 2.0)
         and then Approximately_Equal
                    (Result.Standard_Deviation.Component_2, 2.0),
         "Mean_Std_Dev must reduce every Vec3 channel independently");
   end Vec3_Mean_Std_Dev_Returns_Independent_Channel_Values;

   procedure Mean_Reductions_Operate_On_Non_Continuous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      View   : OpenCV.Core.Mat;
      Result : OpenCV.Core.Mean_Std_Dev_Result;
   begin
      for Row in 0 .. 2 loop
         for Column in 0 .. 3 loop
            OpenCV.Core.UInt8_Access.Set
              (Source,
               Row,
               Column,
               OpenCV.Core.UInt8_Value (Row * 4 + Column));
         end loop;
      end loop;

      View := Source.Region ((X => 1, Y => 1, Width => 2, Height => 2));
      Result := View.Mean_Std_Dev;

      AUnit.Assertions.Assert
        (not View.Is_Continuous
         and then Approximately_Equal (View.Mean.Component_0, 7.5)
         and then Approximately_Equal (Result.Mean.Component_0, 7.5)
         and then Approximately_Equal
                    (Result.Standard_Deviation.Component_0,
                     2.061_552_812_808_831),
         "Mean reductions must use only values in a non-continuous Region");
   end Mean_Reductions_Operate_On_Non_Continuous_Region;

   procedure Reshape_Preserves_Single_Channel_Mean_Reductions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Reshaped     : OpenCV.Core.Mat;
      Source_Stats : OpenCV.Core.Mean_Std_Dev_Result;
      View_Stats   : OpenCV.Core.Mean_Std_Dev_Result;
   begin
      for Row in 0 .. 1 loop
         for Column in 0 .. 2 loop
            OpenCV.Core.Float32_Access.Set
              (Source,
               Row,
               Column,
               OpenCV.Core.Float32_Value (Row * 3 + Column + 1));
         end loop;
      end loop;

      Reshaped := Source.Reshape (Channels => 1, Rows => 3);
      Source_Stats := Source.Mean_Std_Dev;
      View_Stats := Reshaped.Mean_Std_Dev;

      AUnit.Assertions.Assert
        (Approximately_Equal
           (Source.Mean.Component_0, Reshaped.Mean.Component_0)
         and then Approximately_Equal
                    (Source_Stats.Mean.Component_0,
                     View_Stats.Mean.Component_0)
         and then Approximately_Equal
                    (Source_Stats.Standard_Deviation.Component_0,
                     View_Stats.Standard_Deviation.Component_0),
         "Reshape must preserve single-channel mean reduction results");
   end Reshape_Preserves_Single_Channel_Mean_Reductions;

   procedure Mean_Reductions_Handle_Empty_And_Too_Many_Channels
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Empty_Image        : OpenCV.Core.Mat;
      Five_Channel_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 5));

      procedure Compute_Empty_Std_Dev is
         Result : constant OpenCV.Core.Mean_Std_Dev_Result :=
           Empty_Image.Mean_Std_Dev;
      begin
         pragma Unreferenced (Result);
      end Compute_Empty_Std_Dev;

      procedure Compute_Five_Channel_Mean is
         Result : constant OpenCV.Core.Scalar := Five_Channel_Image.Mean;
      begin
         pragma Unreferenced (Result);
      end Compute_Five_Channel_Mean;

      procedure Compute_Five_Channel_Std_Dev is
         Result : constant OpenCV.Core.Mean_Std_Dev_Result :=
           Five_Channel_Image.Mean_Std_Dev;
      begin
         pragma Unreferenced (Result);
      end Compute_Five_Channel_Std_Dev;
   begin
      AUnit.Assertions.Assert
        (Empty_Image.Mean.Component_0 = 0.0
         and then Empty_Image.Mean.Component_1 = 0.0
         and then Empty_Image.Mean.Component_2 = 0.0
         and then Empty_Image.Mean.Component_3 = 0.0,
         "Mean must return OpenCV's zero Scalar for an empty Mat");
      Assert_Raises_OpenCV_Error
        (Compute_Empty_Std_Dev'Access,
         "Mean_Std_Dev must reject an empty Mat");
      Assert_Raises_OpenCV_Error
        (Compute_Five_Channel_Mean'Access,
         "Mean must reject channel results that do not fit Scalar");
      Assert_Raises_OpenCV_Error
        (Compute_Five_Channel_Std_Dev'Access,
         "Mean_Std_Dev must reject channel results that do not fit Scalar");
   end Mean_Reductions_Handle_Empty_And_Too_Many_Channels;

   procedure Masked_Mean_UInt8_Selective_And_Nonzero_Semantics
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Mask   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Result : OpenCV.Core.Scalar;
   begin
      OpenCV.Core.UInt8_Access.Set (Image, 0, 0, 10);
      OpenCV.Core.UInt8_Access.Set (Image, 0, 1, 20);
      OpenCV.Core.UInt8_Access.Set (Image, 1, 0, 30);
      OpenCV.Core.UInt8_Access.Set (Image, 1, 1, 40);
      OpenCV.Core.UInt8_Access.Set (Mask, 0, 0, 0);
      OpenCV.Core.UInt8_Access.Set (Mask, 0, 1, 1);
      OpenCV.Core.UInt8_Access.Set (Mask, 1, 0, 255);
      OpenCV.Core.UInt8_Access.Set (Mask, 1, 1, 0);
      Result := Image.Mean (Mask);

      AUnit.Assertions.Assert
        (Approximately_Equal (Result.Component_0, 25.0)
         and then Result.Component_1 = 0.0
         and then Result.Component_2 = 0.0
         and then Result.Component_3 = 0.0,
         "Masked Mean must average only nonzero-mask UInt8 elements and treat"
         & " 1 and 255 as selecting");
   end Masked_Mean_UInt8_Selective_And_Nonzero_Semantics;

   procedure Masked_Mean_Vec3_Per_Channel (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.UInt8, 3));
      Mask   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.UInt8, 1));
      Result : OpenCV.Core.Scalar;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (Image, 0, 0, (1, 10, 100));
      OpenCV.Core.UInt8_Vec3_Access.Set (Image, 0, 1, (5, 50, 50));
      OpenCV.Core.UInt8_Vec3_Access.Set (Image, 0, 2, (3, 14, 104));
      OpenCV.Core.UInt8_Access.Set (Mask, 0, 0, 255);
      OpenCV.Core.UInt8_Access.Set (Mask, 0, 1, 0);
      OpenCV.Core.UInt8_Access.Set (Mask, 0, 2, 1);
      Result := Image.Mean (Mask);

      AUnit.Assertions.Assert
        (Approximately_Equal (Result.Component_0, 2.0)
         and then Approximately_Equal (Result.Component_1, 12.0)
         and then Approximately_Equal (Result.Component_2, 102.0)
         and then Result.Component_3 = 0.0,
         "Masked Mean must reduce each Vec3 channel independently over"
         & " selected elements");
   end Masked_Mean_Vec3_Per_Channel;

   procedure Masked_Mean_Compare_And_In_Range_Interop
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image                    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.UInt8, 1));
      Threshold                : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.UInt8, 1));
      Compare_Mask, Range_Mask : OpenCV.Core.Mat;
      Compare_Mean, Range_Mean : OpenCV.Core.Scalar;
   begin
      OpenCV.Core.UInt8_Access.Set (Image, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Image, 0, 1, 5);
      OpenCV.Core.UInt8_Access.Set (Image, 0, 2, 10);
      OpenCV.Core.UInt8_Access.Set (Image, 0, 3, 20);
      Threshold.Set_To (OpenCV.Core.Make_Scalar (5.0));
      Compare_Mask := Image.Compare (Threshold, OpenCV.Core.Greater_Than);
      Range_Mask :=
        Image.In_Range
          (OpenCV.Core.Make_Scalar (5.0), OpenCV.Core.Make_Scalar (10.0));
      Compare_Mean := Image.Mean (Compare_Mask);
      Range_Mean := Image.Mean (Range_Mask);

      AUnit.Assertions.Assert
        (Approximately_Equal (Compare_Mean.Component_0, 15.0),
         "Masked Mean must accept Compare masks (values 10 and 20)");
      AUnit.Assertions.Assert
        (Approximately_Equal (Range_Mean.Component_0, 7.5),
         "Masked Mean must accept In_Range masks (values 5 and 10)");
   end Masked_Mean_Compare_And_In_Range_Interop;

   procedure Masked_Mean_Non_Continuous_Views_And_All_Zero_Mask
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source                 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.UInt8, 1));
      Mask_Parent            : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.UInt8, 1));
      View, Mask_View        : OpenCV.Core.Mat;
      Zero_Mask              : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Region_Mean, Zero_Mean : OpenCV.Core.Scalar;
   begin
      Source.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 2, 3);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 0, 4);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 1, 10);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 2, 20);
      OpenCV.Core.UInt8_Access.Set (Source, 2, 0, 7);
      OpenCV.Core.UInt8_Access.Set (Source, 2, 1, 30);
      OpenCV.Core.UInt8_Access.Set (Source, 2, 2, 40);
      Mask_Parent.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Mask_Parent, 1, 1, 255);
      OpenCV.Core.UInt8_Access.Set (Mask_Parent, 1, 2, 1);
      OpenCV.Core.UInt8_Access.Set (Mask_Parent, 2, 1, 1);
      OpenCV.Core.UInt8_Access.Set (Mask_Parent, 2, 2, 0);
      View := Source.Region ((X => 1, Y => 1, Width => 2, Height => 2));
      Mask_View :=
        Mask_Parent.Region ((X => 1, Y => 1, Width => 2, Height => 2));
      Region_Mean := View.Mean (Mask_View);
      Zero_Mask.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Zero_Mean := View.Mean (Zero_Mask);

      AUnit.Assertions.Assert
        (not View.Is_Continuous and then not Mask_View.Is_Continuous,
         "Region source and mask must be non-continuous for this case");
      AUnit.Assertions.Assert
        (Approximately_Equal (Region_Mean.Component_0, 20.0),
         "Masked Mean must support non-contiguous source and mask views"
         & " (10, 20, 30 selected)");
      AUnit.Assertions.Assert
        (Zero_Mean.Component_0 = 0.0
         and then Zero_Mean.Component_1 = 0.0
         and then Zero_Mean.Component_2 = 0.0
         and then Zero_Mean.Component_3 = 0.0,
         "All-zero mask must return a zero Scalar");
   end Masked_Mean_Non_Continuous_Views_And_All_Zero_Mask;

   procedure Masked_Mean_Rejects_Invalid_Masks_And_Channels
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source                   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Float_Mask               : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Multi_Mask               : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 3));
      Rows_Mask                : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.UInt8, 1));
      Columns_Mask             : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Five_Channel             : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 5));
      Five_Mask                : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Empty_Source, Empty_Mask : OpenCV.Core.Mat;
      Empty_Result             : OpenCV.Core.Scalar;

      procedure Float_Depth is
         Result : constant OpenCV.Core.Scalar := Source.Mean (Float_Mask);
      begin
         pragma Unreferenced (Result);
      end Float_Depth;

      procedure Multi_Channel is
         Result : constant OpenCV.Core.Scalar := Source.Mean (Multi_Mask);
      begin
         pragma Unreferenced (Result);
      end Multi_Channel;

      procedure Wrong_Rows is
         Result : constant OpenCV.Core.Scalar := Source.Mean (Rows_Mask);
      begin
         pragma Unreferenced (Result);
      end Wrong_Rows;

      procedure Wrong_Columns is
         Result : constant OpenCV.Core.Scalar := Source.Mean (Columns_Mask);
      begin
         pragma Unreferenced (Result);
      end Wrong_Columns;

      procedure Too_Many_Channels is
         Result : constant OpenCV.Core.Scalar := Five_Channel.Mean (Five_Mask);
      begin
         pragma Unreferenced (Result);
      end Too_Many_Channels;
   begin
      Empty_Result := Empty_Source.Mean (Empty_Mask);
      AUnit.Assertions.Assert
        (Empty_Result.Component_0 = 0.0
         and then Empty_Result.Component_1 = 0.0
         and then Empty_Result.Component_2 = 0.0
         and then Empty_Result.Component_3 = 0.0,
         "Masked Mean must return OpenCV's zero Scalar for empty source/mask");
      Assert_Raises_OpenCV_Error
        (Float_Depth'Access, "Masked Mean must reject Float32 mask depth");
      Assert_Raises_OpenCV_Error
        (Multi_Channel'Access, "Masked Mean must reject multi-channel mask");
      Assert_Raises_OpenCV_Error
        (Wrong_Rows'Access, "Masked Mean must reject wrong mask rows");
      Assert_Raises_OpenCV_Error
        (Wrong_Columns'Access, "Masked Mean must reject wrong mask columns");
      Assert_Raises_OpenCV_Error
        (Too_Many_Channels'Access,
         "Masked Mean must reject source with more than four channels");
   end Masked_Mean_Rejects_Invalid_Masks_And_Channels;

   procedure Masked_Mean_Std_Dev_UInt8_Selective_And_Nonzero_Semantics
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Mask   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Result : OpenCV.Core.Mean_Std_Dev_Result;
   begin
      OpenCV.Core.UInt8_Access.Set (Image, 0, 0, 10);
      OpenCV.Core.UInt8_Access.Set (Image, 0, 1, 20);
      OpenCV.Core.UInt8_Access.Set (Image, 1, 0, 30);
      OpenCV.Core.UInt8_Access.Set (Image, 1, 1, 40);
      OpenCV.Core.UInt8_Access.Set (Mask, 0, 0, 0);
      OpenCV.Core.UInt8_Access.Set (Mask, 0, 1, 1);
      OpenCV.Core.UInt8_Access.Set (Mask, 1, 0, 255);
      OpenCV.Core.UInt8_Access.Set (Mask, 1, 1, 0);
      Result := Image.Mean_Std_Dev (Mask);

      AUnit.Assertions.Assert
        (Approximately_Equal (Result.Mean.Component_0, 25.0)
         and then Approximately_Equal
                    (Result.Standard_Deviation.Component_0, 5.0),
         "Masked Mean_Std_Dev must reduce nonzero-mask UInt8 elements");
   end Masked_Mean_Std_Dev_UInt8_Selective_And_Nonzero_Semantics;

   procedure Masked_Mean_Std_Dev_Vec3_Per_Channel
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.UInt8, 3));
      Mask   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.UInt8, 1));
      Result : OpenCV.Core.Mean_Std_Dev_Result;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (Image, 0, 0, (1, 10, 100));
      OpenCV.Core.UInt8_Vec3_Access.Set (Image, 0, 1, (5, 50, 50));
      OpenCV.Core.UInt8_Vec3_Access.Set (Image, 0, 2, (3, 14, 104));
      OpenCV.Core.UInt8_Access.Set (Mask, 0, 0, 255);
      OpenCV.Core.UInt8_Access.Set (Mask, 0, 1, 0);
      OpenCV.Core.UInt8_Access.Set (Mask, 0, 2, 1);
      Result := Image.Mean_Std_Dev (Mask);

      AUnit.Assertions.Assert
        (Approximately_Equal (Result.Mean.Component_0, 2.0)
         and then Approximately_Equal (Result.Mean.Component_1, 12.0)
         and then Approximately_Equal (Result.Mean.Component_2, 102.0)
         and then Approximately_Equal
                    (Result.Standard_Deviation.Component_0, 1.0)
         and then Approximately_Equal
                    (Result.Standard_Deviation.Component_1, 2.0)
         and then Approximately_Equal
                    (Result.Standard_Deviation.Component_2, 2.0),
         "Masked Mean_Std_Dev must reduce each Vec3 channel independently");
   end Masked_Mean_Std_Dev_Vec3_Per_Channel;

   procedure Masked_Mean_Std_Dev_Compare_Interop
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.UInt8, 1));
      Threshold : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.UInt8, 1));
      Mask      : OpenCV.Core.Mat;
      Result    : OpenCV.Core.Mean_Std_Dev_Result;
   begin
      OpenCV.Core.UInt8_Access.Set (Image, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Image, 0, 1, 5);
      OpenCV.Core.UInt8_Access.Set (Image, 0, 2, 10);
      OpenCV.Core.UInt8_Access.Set (Image, 0, 3, 20);
      Threshold.Set_To (OpenCV.Core.Make_Scalar (5.0));
      Mask := Image.Compare (Threshold, OpenCV.Core.Greater_Than);
      Result := Image.Mean_Std_Dev (Mask);

      AUnit.Assertions.Assert
        (Approximately_Equal (Result.Mean.Component_0, 15.0)
         and then Approximately_Equal
                    (Result.Standard_Deviation.Component_0, 5.0),
         "Masked Mean_Std_Dev must accept masks produced by Compare");
   end Masked_Mean_Std_Dev_Compare_Interop;

   procedure Masked_Mean_Std_Dev_Non_Continuous_Views_And_All_Zero_Mask
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source                     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.UInt8, 1));
      Mask_Parent                : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.UInt8, 1));
      View, Mask_View            : OpenCV.Core.Mat;
      Zero_Mask                  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Region_Result, Zero_Result : OpenCV.Core.Mean_Std_Dev_Result;
   begin
      Source.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Source, 1, 1, 10);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 2, 20);
      OpenCV.Core.UInt8_Access.Set (Source, 2, 1, 30);
      OpenCV.Core.UInt8_Access.Set (Source, 2, 2, 40);
      Mask_Parent.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Mask_Parent, 1, 1, 255);
      OpenCV.Core.UInt8_Access.Set (Mask_Parent, 1, 2, 1);
      OpenCV.Core.UInt8_Access.Set (Mask_Parent, 2, 1, 1);
      View := Source.Region ((X => 1, Y => 1, Width => 2, Height => 2));
      Mask_View :=
        Mask_Parent.Region ((X => 1, Y => 1, Width => 2, Height => 2));
      Region_Result := View.Mean_Std_Dev (Mask_View);
      Zero_Mask.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Zero_Result := View.Mean_Std_Dev (Zero_Mask);

      AUnit.Assertions.Assert
        (not View.Is_Continuous and then not Mask_View.Is_Continuous,
         "Region source and mask must be non-continuous for this case");
      AUnit.Assertions.Assert
        (Approximately_Equal (Region_Result.Mean.Component_0, 20.0)
         and then Approximately_Equal
                    (Region_Result.Standard_Deviation.Component_0,
                     8.164_965_809_277_26),
         "Masked Mean_Std_Dev must support non-contiguous source and mask"
         & " views");
      AUnit.Assertions.Assert
        (Zero_Result.Mean.Component_0 = 0.0
         and then Zero_Result.Standard_Deviation.Component_0 = 0.0,
         "An all-zero mask must return zero mean and standard deviation");
   end Masked_Mean_Std_Dev_Non_Continuous_Views_And_All_Zero_Mask;

   procedure Masked_Mean_Std_Dev_Handles_Empty_And_Invalid_Input
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Empty_Source, Empty_Mask : OpenCV.Core.Mat;
      Source                   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Float_Mask               : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Five_Channel             : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 5));
      Valid_Mask               : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      procedure Empty_Input is
         Result : constant OpenCV.Core.Mean_Std_Dev_Result :=
           Empty_Source.Mean_Std_Dev (Empty_Mask);
      begin
         pragma Unreferenced (Result);
      end Empty_Input;

      procedure Invalid_Mask is
         Result : constant OpenCV.Core.Mean_Std_Dev_Result :=
           Source.Mean_Std_Dev (Float_Mask);
      begin
         pragma Unreferenced (Result);
      end Invalid_Mask;

      procedure Too_Many_Channels is
         Result : constant OpenCV.Core.Mean_Std_Dev_Result :=
           Five_Channel.Mean_Std_Dev (Valid_Mask);
      begin
         pragma Unreferenced (Result);
      end Too_Many_Channels;
   begin
      Assert_Raises_OpenCV_Error
        (Empty_Input'Access,
         "Masked Mean_Std_Dev must reject an empty source Mat");
      Assert_Raises_OpenCV_Error
        (Invalid_Mask'Access,
         "Masked Mean_Std_Dev must reject invalid mask depth");
      Assert_Raises_OpenCV_Error
        (Too_Many_Channels'Access,
         "Masked Mean_Std_Dev must reject source channels beyond Scalar");
   end Masked_Mean_Std_Dev_Handles_Empty_And_Invalid_Input;

   procedure Float32_Norm_Computes_L1_L2_And_Infinity
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, -1.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, -3.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 4.0);

      AUnit.Assertions.Assert
        (Approximately_Equal (Image.Norm (OpenCV.Core.L1), 10.0),
         "L1 norm must sum the absolute Float32 scalar values");
      AUnit.Assertions.Assert
        (Approximately_Equal (Image.Norm, 5.477_225_575_051_661),
         "The default norm must be the L2 norm");
      AUnit.Assertions.Assert
        (Approximately_Equal (Image.Norm (OpenCV.Core.Infinity), 4.0),
         "Infinity norm must be the greatest absolute scalar value");
   end Float32_Norm_Computes_L1_L2_And_Infinity;

   procedure UInt8_Norm_Is_Not_Float32_Specific
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Image, 0, 0, 3);
      OpenCV.Core.UInt8_Access.Set (Image, 0, 1, 4);
      OpenCV.Core.UInt8_Access.Set (Image, 0, 2, 12);

      AUnit.Assertions.Assert
        (Approximately_Equal (Image.Norm (OpenCV.Core.L1), 19.0)
         and then Approximately_Equal (Image.Norm (OpenCV.Core.L2), 13.0)
         and then Approximately_Equal
                    (Image.Norm (OpenCV.Core.Infinity), 12.0),
         "Norm must support UInt8 data for every exposed norm kind");
   end UInt8_Norm_Is_Not_Float32_Specific;

   procedure Vec3_Norm_Combines_All_Channels (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (Image, 0, 0, (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set (Image, 0, 1, (4, 5, 6));

      AUnit.Assertions.Assert
        (Approximately_Equal (Image.Norm (OpenCV.Core.L1), 21.0)
         and then Approximately_Equal
                    (Image.Norm (OpenCV.Core.L2), 9.539_392_014_169_456)
         and then Approximately_Equal (Image.Norm (OpenCV.Core.Infinity), 6.0),
         "Norm must combine every scalar component of a multi-channel Mat");
   end Vec3_Norm_Combines_All_Channels;

   procedure Masked_Norm_Computes_L1_L2_And_Infinity
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Mask  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, -1.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, -3.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 4.0);
      OpenCV.Core.UInt8_Access.Set (Mask, 0, 0, 0);
      OpenCV.Core.UInt8_Access.Set (Mask, 0, 1, 1);
      OpenCV.Core.UInt8_Access.Set (Mask, 1, 0, 255);
      OpenCV.Core.UInt8_Access.Set (Mask, 1, 1, 0);

      AUnit.Assertions.Assert
        (Approximately_Equal (Image.Norm (Mask, OpenCV.Core.L1), 5.0)
         and then Approximately_Equal
                    (Image.Norm (Mask), 3.605_551_275_463_989)
         and then Approximately_Equal
                    (Image.Norm (Mask, OpenCV.Core.Infinity), 3.0),
         "Masked Norm must use nonzero 1 and 255 mask values for L1, L2,"
         & " and Infinity");
   end Masked_Norm_Computes_L1_L2_And_Infinity;

   procedure Masked_Norm_Uses_Compare_And_In_Range_Masks
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image                    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.UInt8, 1));
      Threshold                : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.UInt8, 1));
      Compare_Mask, Range_Mask : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Image, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Image, 0, 1, 5);
      OpenCV.Core.UInt8_Access.Set (Image, 0, 2, 10);
      OpenCV.Core.UInt8_Access.Set (Image, 0, 3, 20);
      Threshold.Set_To (OpenCV.Core.Make_Scalar (5.0));
      Compare_Mask := Image.Compare (Threshold, OpenCV.Core.Greater_Than);
      Range_Mask :=
        Image.In_Range
          (OpenCV.Core.Make_Scalar (5.0), OpenCV.Core.Make_Scalar (10.0));

      AUnit.Assertions.Assert
        (Approximately_Equal (Image.Norm (Compare_Mask, OpenCV.Core.L1), 30.0)
         and then Approximately_Equal
                    (Image.Norm (Range_Mask, OpenCV.Core.L1), 15.0),
         "Masked Norm must accept masks produced by Compare and In_Range");
   end Masked_Norm_Uses_Compare_And_In_Range_Masks;

   procedure Masked_Norm_Supports_Vec3_And_Non_Continuous_Views
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.UInt8, 3));
      Mask_Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.UInt8, 1));
      View, Mask  : OpenCV.Core.Mat;
   begin
      Source.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Vec3_Access.Set (Source, 1, 1, (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set (Source, 1, 2, (4, 5, 6));
      OpenCV.Core.UInt8_Vec3_Access.Set (Source, 2, 1, (7, 8, 9));
      OpenCV.Core.UInt8_Vec3_Access.Set (Source, 2, 2, (10, 11, 12));
      Mask_Parent.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Mask_Parent, 1, 1, 1);
      OpenCV.Core.UInt8_Access.Set (Mask_Parent, 2, 2, 255);
      View := Source.Region ((X => 1, Y => 1, Width => 2, Height => 2));
      Mask := Mask_Parent.Region ((X => 1, Y => 1, Width => 2, Height => 2));

      AUnit.Assertions.Assert
        (not View.Is_Continuous
         and then not Mask.Is_Continuous
         and then Approximately_Equal (View.Norm (Mask, OpenCV.Core.L1), 39.0)
         and then Approximately_Equal
                    (View.Norm (Mask, OpenCV.Core.L2), 19.467_922_333_931_785)
         and then Approximately_Equal
                    (View.Norm (Mask, OpenCV.Core.Infinity), 12.0),
         "Masked Norm must select all Vec3 components and support"
         & " non-continuous source and mask views");
   end Masked_Norm_Supports_Vec3_And_Non_Continuous_Views;

   procedure Masked_Norm_Handles_Zero_Empty_And_Invalid_Masks
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image             : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Zero_Mask         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Invalid_Mask      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 3));
      Empty_Image, Mask : OpenCV.Core.Mat;

      procedure Compute_Invalid_Mask is
         Result : constant Long_Float := Image.Norm (Invalid_Mask);
      begin
         pragma Unreferenced (Result);
      end Compute_Invalid_Mask;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (7.0));
      Zero_Mask.Set_To (OpenCV.Core.Make_Scalar (0.0));

      AUnit.Assertions.Assert
        (Image.Norm (Zero_Mask, OpenCV.Core.L1) = 0.0
         and then Image.Norm (Zero_Mask) = 0.0
         and then Image.Norm (Zero_Mask, OpenCV.Core.Infinity) = 0.0
         and then Empty_Image.Norm (Mask, OpenCV.Core.L1) = 0.0
         and then Empty_Image.Norm (Mask) = 0.0
         and then Empty_Image.Norm (Mask, OpenCV.Core.Infinity) = 0.0,
         "Masked Norm must return zero for all-zero masks and empty inputs");
      Assert_Raises_OpenCV_Error
        (Compute_Invalid_Mask'Access,
         "Masked Norm must reject multi-channel masks");
   end Masked_Norm_Handles_Zero_Empty_And_Invalid_Masks;

   procedure Norm_Operates_On_Non_Continuous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      View   : OpenCV.Core.Mat;
   begin
      for Row in 0 .. 2 loop
         for Column in 0 .. 3 loop
            OpenCV.Core.UInt8_Access.Set
              (Source,
               Row,
               Column,
               OpenCV.Core.UInt8_Value (Row * 4 + Column));
         end loop;
      end loop;

      View := Source.Region ((X => 1, Y => 1, Width => 2, Height => 2));

      AUnit.Assertions.Assert
        (not View.Is_Continuous
         and then Approximately_Equal (View.Norm (OpenCV.Core.L1), 30.0)
         and then Approximately_Equal (View.Norm (OpenCV.Core.Infinity), 10.0),
         "Norm must use only the scalar values in a non-continuous Region");
   end Norm_Operates_On_Non_Continuous_Region;

   procedure Reshape_Preserves_Norm (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      View   : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, -1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 2, -3.0);
      OpenCV.Core.Float32_Access.Set (Source, 1, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Source, 1, 1, -5.0);
      OpenCV.Core.Float32_Access.Set (Source, 1, 2, 6.0);
      View := Source.Reshape (Channels => 3);

      AUnit.Assertions.Assert
        (Approximately_Equal (Source.Norm, View.Norm),
         "Reshape must preserve the L2 norm of unchanged scalar storage");
   end Reshape_Preserves_Norm;

   procedure Empty_Mat_Norm_Is_Zero (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat;
   begin
      AUnit.Assertions.Assert
        (Image.Norm (OpenCV.Core.L1) = 0.0
         and then Image.Norm = 0.0
         and then Image.Norm (OpenCV.Core.Infinity) = 0.0,
         "OpenCV norm semantics require empty Mats to return zero");
   end Empty_Mat_Norm_Is_Zero;

   procedure Float16_Norm_Is_Supported (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float16, Channels => 1));
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (3.0));

      AUnit.Assertions.Assert
        (Approximately_Equal (Image.Norm (OpenCV.Core.L1), 12.0)
         and then Approximately_Equal (Image.Norm, 6.0)
         and then Approximately_Equal (Image.Norm (OpenCV.Core.Infinity), 3.0),
         "Norm must preserve installed OpenCV Float16 support");
   end Float16_Norm_Is_Supported;

   procedure Float32_Normalize_L2_Preserves_Metadata_And_Source
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Result : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 4.0);
      Result :=
        Source.Normalize (Kind => OpenCV.Core.L2, Alpha => 1.0, Beta => 123.0);

      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Result, 0, 0)), 0.6)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 1)),
                     0.8)
         and then Approximately_Equal (Result.Norm, 1.0),
         "L2 normalization must scale Float32 values to the requested norm");
      AUnit.Assertions.Assert
        (Result.Rows = Source.Rows
         and then Result.Columns = Source.Columns
         and then Result.Channels = Source.Channels
         and then Result.Depth = Source.Depth,
         "Normalization must preserve source Mat metadata");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Source, 0, 0)), 3.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Source, 0, 1)),
                     4.0),
         "Norm-based normalization must ignore Beta and leave its source"
         & " unchanged");
   end Float32_Normalize_L2_Preserves_Metadata_And_Source;

   procedure Normalize_L1_And_Infinity_Support_Vec3
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source     : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      L1_Result  : OpenCV.Core.Mat;
      Inf_Result : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set
        (Source, Row => 0, Column => 0, Value => (1.0, -2.0, 3.0));
      L1_Result := Source.Normalize (Kind => OpenCV.Core.L1, Alpha => 12.0);
      Inf_Result :=
        Source.Normalize (Kind => OpenCV.Core.Infinity, Alpha => 7.0);

      AUnit.Assertions.Assert
        (Approximately_Equal (L1_Result.Norm (OpenCV.Core.L1), 12.0),
         "L1 normalization must include every Vec3 scalar component");
      AUnit.Assertions.Assert
        (Approximately_Equal (Inf_Result.Norm (OpenCV.Core.Infinity), 7.0),
         "Infinity normalization must include every Vec3 scalar component");
   end Normalize_L1_And_Infinity_Support_Vec3;

   procedure Float32_Normalize_Min_Max_Maps_Range
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Result  : OpenCV.Core.Mat;
      Extrema : OpenCV.Core.Min_Max_Result;
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, -2.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 2, 4.0);
      Result :=
        Source.Normalize
          (Kind => OpenCV.Core.Min_Max, Alpha => 0.0, Beta => 1.0);
      Extrema := Result.Min_Max_Loc;

      AUnit.Assertions.Assert
        (Approximately_Equal (Extrema.Minimum, 0.0)
         and then Approximately_Equal (Extrema.Maximum, 1.0),
         "Min_Max normalization must map distinct Float32 extrema to its"
         & " range");
   end Float32_Normalize_Min_Max_Maps_Range;

   procedure Normalize_Returns_Independent_Storage
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Result : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 4.0);
      Result := Source.Normalize;
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 30.0);

      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Result, 0, 0)), 0.6),
         "A normalized result must not share later source writes");

      OpenCV.Core.Float32_Access.Set (Result, 0, 1, 9.0);
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Source, 0, 1)), 4.0),
         "A source Mat must not share later normalized-result writes");
   end Normalize_Returns_Independent_Storage;

   procedure Normalize_Operates_On_Non_Continuous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      View   : OpenCV.Core.Mat;
      Result : OpenCV.Core.Mat;
   begin
      for Row in 0 .. 3 loop
         for Column in 0 .. 3 loop
            OpenCV.Core.Float32_Access.Set
              (Source,
               Row,
               Column,
               OpenCV.Core.Float32_Value (Row * 10 + Column));
         end loop;
      end loop;

      View := Source.Region ((X => 1, Y => 1, Width => 2, Height => 2));
      Result := View.Normalize (Kind => OpenCV.Core.L1, Alpha => 1.0);

      AUnit.Assertions.Assert
        (not View.Is_Continuous
         and then Result.Is_Continuous
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 0)),
                     11.0 / 66.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 1, 1)),
                     22.0 / 66.0)
         and then Approximately_Equal (Result.Norm (OpenCV.Core.L1), 1.0),
         "Normalization must use only a non-continuous Region's values");
   end Normalize_Operates_On_Non_Continuous_Region;

   procedure UInt8_Normalize_Uses_OpenCV_Rounding_And_Saturation
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Rounded   : OpenCV.Core.Mat;
      Saturated : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 0);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 2, 3);
      Rounded :=
        Source.Normalize
          (Kind => OpenCV.Core.Min_Max, Alpha => 0.0, Beta => 10.0);
      Saturated :=
        Source.Normalize
          (Kind => OpenCV.Core.Min_Max, Alpha => 0.0, Beta => 300.0);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Rounded, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Rounded, 0, 1) = 7
         and then OpenCV.Core.UInt8_Access.Get (Rounded, 0, 2) = 10,
         "UInt8 normalization must use OpenCV's rounded preserved-depth"
         & " output");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Saturated, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Saturated, 0, 1) = 200
         and then OpenCV.Core.UInt8_Access.Get (Saturated, 0, 2) = 255,
         "UInt8 normalization must saturate preserved-depth output");
   end UInt8_Normalize_Uses_OpenCV_Rounding_And_Saturation;

   procedure Normalize_Handles_Empty_And_Zero_Input
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Empty_Source : OpenCV.Core.Mat;
      Empty_Result : OpenCV.Core.Mat;
      Zero_Source  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Zero_Result  : OpenCV.Core.Mat;
   begin
      Empty_Result := Empty_Source.Normalize;
      Zero_Result :=
        Zero_Source.Normalize (Kind => OpenCV.Core.L2, Alpha => 5.0);

      AUnit.Assertions.Assert
        (Empty_Result.Is_Empty,
         "OpenCV normalization of an empty Mat must return an empty Mat");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Zero_Result, 0, 0) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Zero_Result, 0, 1) = 0.0
         and then Zero_Result.Norm = 0.0,
         "OpenCV normalization of a zero Mat must retain zero values");
   end Normalize_Handles_Empty_And_Zero_Input;

   procedure Min_Max_Loc_UInt8_Returns_Values_And_Column_Row_Points
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Result : OpenCV.Core.Min_Max_Result;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (50.0));
      OpenCV.Core.UInt8_Access.Set (Image, Row => 1, Column => 3, Value => 4);
      OpenCV.Core.UInt8_Access.Set
        (Image, Row => 2, Column => 0, Value => 220);

      Result := Image.Min_Max_Loc;

      AUnit.Assertions.Assert
        (Result.Minimum = 4.0 and then Result.Maximum = 220.0,
         "Min_Max_Loc must return UInt8 extrema as Long_Float values");
      AUnit.Assertions.Assert
        (Result.Minimum_Location.X = 3 and then Result.Minimum_Location.Y = 1,
         "The minimum Point must map X to column and Y to row");
      AUnit.Assertions.Assert
        (Result.Maximum_Location.X = 0 and then Result.Maximum_Location.Y = 2,
         "The maximum Point must map X to column and Y to row");
   end Min_Max_Loc_UInt8_Returns_Values_And_Column_Row_Points;

   procedure Min_Max_Loc_Float32_Returns_Negative_Fractional_Values
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Result : OpenCV.Core.Min_Max_Result;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (0.25));
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 2, Value => -3.5);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 1, Column => 1, Value => 7.125);

      Result := Image.Min_Max_Loc;

      AUnit.Assertions.Assert
        (Approximately_Equal (Result.Minimum, -3.5)
         and then Approximately_Equal (Result.Maximum, 7.125),
         "Min_Max_Loc must preserve Float32 negative fractional extrema");
      AUnit.Assertions.Assert
        (Result.Minimum_Location.X = 2
         and then Result.Minimum_Location.Y = 0
         and then Result.Maximum_Location.X = 1
         and then Result.Maximum_Location.Y = 1,
         "Float32 extrema locations must use column-row Point ordering");
   end Min_Max_Loc_Float32_Returns_Negative_Fractional_Values;

   procedure Min_Max_Loc_Supports_Int32 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Int32, Channels => 1));
      Result : OpenCV.Core.Min_Max_Result;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (-100.0));
      Result := Image.Min_Max_Loc;

      AUnit.Assertions.Assert
        (Result.Minimum = -100.0 and then Result.Maximum = -100.0,
         "Min_Max_Loc must support OpenCV's Int32 depth");
   end Min_Max_Loc_Supports_Int32;

   procedure Min_Max_Loc_Uses_Region_Relative_Coordinates
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 5,
           Columns      => 6,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      View   : OpenCV.Core.Mat;
      Result : OpenCV.Core.Min_Max_Result;
   begin
      Source.Set_To (OpenCV.Core.Make_Scalar (100.0));
      View := Source.Region ((X => 1, Y => 1, Width => 4, Height => 3));
      OpenCV.Core.UInt8_Access.Set (View, Row => 0, Column => 3, Value => 2);
      OpenCV.Core.UInt8_Access.Set (View, Row => 2, Column => 0, Value => 240);

      AUnit.Assertions.Assert
        (not View.Is_Continuous,
         "The Region test must exercise a non-contiguous view");
      Result := View.Min_Max_Loc;

      AUnit.Assertions.Assert
        (Result.Minimum = 2.0 and then Result.Maximum = 240.0,
         "Min_Max_Loc must operate on a non-contiguous Region");
      AUnit.Assertions.Assert
        (Result.Minimum_Location.X = 3
         and then Result.Minimum_Location.Y = 0
         and then Result.Maximum_Location.X = 0
         and then Result.Maximum_Location.Y = 2,
         "Region extrema locations must be relative to the Region");
   end Min_Max_Loc_Uses_Region_Relative_Coordinates;

   procedure Min_Max_Loc_Operates_On_Row_View (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      View   : OpenCV.Core.Mat;
      Result : OpenCV.Core.Min_Max_Result;
   begin
      Source.Set_To (OpenCV.Core.Make_Scalar (30.0));
      View := Source.Row_View (1);
      OpenCV.Core.UInt8_Access.Set (View, Row => 0, Column => 3, Value => 1);
      OpenCV.Core.UInt8_Access.Set (View, Row => 0, Column => 0, Value => 99);

      Result := View.Min_Max_Loc;

      AUnit.Assertions.Assert
        (Result.Minimum = 1.0 and then Result.Maximum = 99.0,
         "Min_Max_Loc must operate on a row view");
      AUnit.Assertions.Assert
        (Result.Minimum_Location.X = 3
         and then Result.Minimum_Location.Y = 0
         and then Result.Maximum_Location.X = 0
         and then Result.Maximum_Location.Y = 0,
         "Row-view extrema locations must be relative to the view");
   end Min_Max_Loc_Operates_On_Row_View;

   procedure Min_Max_Loc_Rejects_Invalid_Mats (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Empty_Image   : OpenCV.Core.Mat;
      Multi_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Float16_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.Float16, Channels => 1));

      procedure Find_Empty is
         Result : constant OpenCV.Core.Min_Max_Result :=
           Empty_Image.Min_Max_Loc;
      begin
         pragma Unreferenced (Result);
      end Find_Empty;

      procedure Find_Multi_Channel is
         Result : constant OpenCV.Core.Min_Max_Result :=
           Multi_Image.Min_Max_Loc;
      begin
         pragma Unreferenced (Result);
      end Find_Multi_Channel;

      procedure Find_Float16 is
         Result : constant OpenCV.Core.Min_Max_Result :=
           Float16_Image.Min_Max_Loc;
      begin
         pragma Unreferenced (Result);
      end Find_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Find_Empty'Access, "Min_Max_Loc must reject an empty Mat");
      Assert_Raises_OpenCV_Error
        (Find_Multi_Channel'Access,
         "Min_Max_Loc must reject a multi-channel Mat");
      Assert_Raises_OpenCV_Error
        (Find_Float16'Access,
         "Min_Max_Loc must reject OpenCV's unsupported Float16 depth");
   end Min_Max_Loc_Rejects_Invalid_Mats;

   procedure Masked_Min_Max_Loc_UInt8_Selects_Extrema_And_Column_Row_Points
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.UInt8, 1));
      Mask   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.UInt8, 1));
      Result : OpenCV.Core.Min_Max_Result;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (50.0));
      OpenCV.Core.UInt8_Access.Set (Image, 1, 3, 4);
      OpenCV.Core.UInt8_Access.Set (Image, 2, 0, 220);
      Mask.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Mask, 1, 3, 1);
      OpenCV.Core.UInt8_Access.Set (Mask, 2, 0, 255);
      Result := Image.Min_Max_Loc (Mask);

      AUnit.Assertions.Assert
        (Result.Minimum = 4.0 and then Result.Maximum = 220.0,
         "Masked Min_Max_Loc must reduce only nonzero-mask UInt8 elements");
      AUnit.Assertions.Assert
        (Result.Minimum_Location.X = 3
         and then Result.Minimum_Location.Y = 1
         and then Result.Maximum_Location.X = 0
         and then Result.Maximum_Location.Y = 2,
         "Masked Min_Max_Loc Points must map X to column and Y to row");
   end Masked_Min_Max_Loc_UInt8_Selects_Extrema_And_Column_Row_Points;

   procedure Masked_Min_Max_Loc_Excludes_Global_Extrema_And_Uses_In_Range_Mask
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Mask   : OpenCV.Core.Mat;
      Result : OpenCV.Core.Min_Max_Result;
   begin
      OpenCV.Core.UInt8_Access.Set (Image, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Image, 0, 1, 20);
      OpenCV.Core.UInt8_Access.Set (Image, 0, 2, 30);
      OpenCV.Core.UInt8_Access.Set (Image, 1, 0, 40);
      OpenCV.Core.UInt8_Access.Set (Image, 1, 1, 50);
      OpenCV.Core.UInt8_Access.Set (Image, 1, 2, 250);
      Mask :=
        Image.In_Range
          (OpenCV.Core.Make_Scalar (10.0), OpenCV.Core.Make_Scalar (60.0));
      Result := Image.Min_Max_Loc (Mask);

      AUnit.Assertions.Assert
        (Result.Minimum = 20.0
         and then Result.Maximum = 50.0
         and then Result.Minimum_Location.X = 1
         and then Result.Minimum_Location.Y = 0
         and then Result.Maximum_Location.X = 1
         and then Result.Maximum_Location.Y = 1,
         "In_Range mask must exclude otherwise-global extrema from"
         & " Min_Max_Loc");
   end Masked_Min_Max_Loc_Excludes_Global_Extrema_And_Uses_In_Range_Mask;

   procedure Masked_Min_Max_Loc_Operates_On_Non_Continuous_Views
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.UInt8, 1));
      Mask_Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.UInt8, 1));
      View, Mask  : OpenCV.Core.Mat;
      Result      : OpenCV.Core.Min_Max_Result;
   begin
      Source.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Source, 1, 1, 10);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 2, 20);
      OpenCV.Core.UInt8_Access.Set (Source, 2, 1, 30);
      OpenCV.Core.UInt8_Access.Set (Source, 2, 2, 40);
      Mask_Parent.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Mask_Parent, 1, 2, 1);
      OpenCV.Core.UInt8_Access.Set (Mask_Parent, 2, 1, 255);
      View := Source.Region ((X => 1, Y => 1, Width => 2, Height => 2));
      Mask := Mask_Parent.Region ((X => 1, Y => 1, Width => 2, Height => 2));
      Result := View.Min_Max_Loc (Mask);

      AUnit.Assertions.Assert
        (not View.Is_Continuous and then not Mask.Is_Continuous,
         "Region source and mask must be non-continuous for this case");
      AUnit.Assertions.Assert
        (Result.Minimum = 20.0
         and then Result.Maximum = 30.0
         and then Result.Minimum_Location.X = 1
         and then Result.Minimum_Location.Y = 0
         and then Result.Maximum_Location.X = 0
         and then Result.Maximum_Location.Y = 1,
         "Masked Min_Max_Loc must support non-contiguous source and mask"
         & " views");
   end Masked_Min_Max_Loc_Operates_On_Non_Continuous_Views;

   procedure Masked_Min_Max_Loc_All_Zero_Mask_Returns_OpenCV_Sentinels
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Mask   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Result : OpenCV.Core.Min_Max_Result;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (42.0));
      Mask.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Result := Image.Min_Max_Loc (Mask);

      AUnit.Assertions.Assert
        (Result.Minimum = 0.0
         and then Result.Maximum = 0.0
         and then Result.Minimum_Location.X = -1
         and then Result.Minimum_Location.Y = -1
         and then Result.Maximum_Location.X = -1
         and then Result.Maximum_Location.Y = -1,
         "An all-zero mask must return OpenCV's zero extrema and (-1, -1)"
         & " locations");
   end Masked_Min_Max_Loc_All_Zero_Mask_Returns_OpenCV_Sentinels;

   procedure Masked_Min_Max_Loc_Rejects_Invalid_Input
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Empty_Source : OpenCV.Core.Mat;
      Empty_Mask   : OpenCV.Core.Mat;
      Source       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Float_Mask   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Multi_Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 3));
      Valid_Mask   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));

      procedure Find_Empty is
         Result : constant OpenCV.Core.Min_Max_Result :=
           Empty_Source.Min_Max_Loc (Empty_Mask);
      begin
         pragma Unreferenced (Result);
      end Find_Empty;

      procedure Find_Invalid_Mask is
         Result : constant OpenCV.Core.Min_Max_Result :=
           Source.Min_Max_Loc (Float_Mask);
      begin
         pragma Unreferenced (Result);
      end Find_Invalid_Mask;

      procedure Find_Multi_Channel is
         Result : constant OpenCV.Core.Min_Max_Result :=
           Multi_Source.Min_Max_Loc (Valid_Mask);
      begin
         pragma Unreferenced (Result);
      end Find_Multi_Channel;
   begin
      Assert_Raises_OpenCV_Error
        (Find_Empty'Access,
         "Masked Min_Max_Loc must reject an empty source Mat");
      Assert_Raises_OpenCV_Error
        (Find_Invalid_Mask'Access,
         "Masked Min_Max_Loc must reject an invalid mask");
      Assert_Raises_OpenCV_Error
        (Find_Multi_Channel'Access,
         "Masked Min_Max_Loc must reject a multi-channel source Mat");
   end Masked_Min_Max_Loc_Rejects_Invalid_Input;

   procedure UInt8_Set_To_And_Sum (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Total : OpenCV.Core.Scalar;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (10.0));
      Total := Image.Sum;

      AUnit.Assertions.Assert
        (Total.Component_0 = 60.0,
         "A 2x3 UInt8 Mat filled with 10 should sum to 60");
      AUnit.Assertions.Assert
        (Total.Component_1 = 0.0
         and then Total.Component_2 = 0.0
         and then Total.Component_3 = 0.0,
         "Unused Scalar components should remain zero");
   end UInt8_Set_To_And_Sum;

   procedure Three_Channel_Set_To_And_Sum (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Total : OpenCV.Core.Scalar;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (1.0, 2.0, 3.0));
      Total := Image.Sum;

      AUnit.Assertions.Assert
        (Total.Component_0 = 4.0,
         "The first channel should sum independently");
      AUnit.Assertions.Assert
        (Total.Component_1 = 8.0,
         "The second channel should sum independently");
      AUnit.Assertions.Assert
        (Total.Component_2 = 12.0,
         "The third channel should sum independently");
      AUnit.Assertions.Assert
        (Total.Component_3 = 0.0,
         "The unused fourth channel total should be zero");
   end Three_Channel_Set_To_And_Sum;

   procedure Float32_Set_To_And_Sum (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Total : OpenCV.Core.Scalar;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (1.25));
      Total := Image.Sum;

      AUnit.Assertions.Assert
        (Approximately_Equal (Total.Component_0, 7.5),
         "A Float32 Mat sum should preserve fractional values");
   end Float32_Set_To_And_Sum;

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Float32 Mean returns arithmetic mean and zeroes",
            Float32_Mean_Returns_Arithmetic_Mean_And_Zeroes'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Mean is not Float32-specific",
            UInt8_Mean_Is_Not_Float32_Specific'Access));
      Result.Add_Test
        (Caller.Create
           ("Vec3 Mean returns independent channel values",
            Vec3_Mean_Returns_Independent_Channel_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Mean_Std_Dev uses population deviation",
            Float32_Mean_Std_Dev_Uses_Population_Deviation'Access));
      Result.Add_Test
        (Caller.Create
           ("Vec3 Mean_Std_Dev returns independent channel values",
            Vec3_Mean_Std_Dev_Returns_Independent_Channel_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Mean reductions operate on a non-continuous Region",
            Mean_Reductions_Operate_On_Non_Continuous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Reshape preserves single-channel Mean reductions",
            Reshape_Preserves_Single_Channel_Mean_Reductions'Access));
      Result.Add_Test
        (Caller.Create
           ("Mean reductions handle empty and unsupported channel layouts",
            Mean_Reductions_Handle_Empty_And_Too_Many_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Mean UInt8 selective and nonzero semantics",
            Masked_Mean_UInt8_Selective_And_Nonzero_Semantics'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Mean Vec3 per-channel",
            Masked_Mean_Vec3_Per_Channel'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Mean Compare and In_Range interop",
            Masked_Mean_Compare_And_In_Range_Interop'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Mean non-continuous views and all-zero mask",
            Masked_Mean_Non_Continuous_Views_And_All_Zero_Mask'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Mean rejects invalid masks and channels",
            Masked_Mean_Rejects_Invalid_Masks_And_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Mean_Std_Dev UInt8 selective and nonzero semantics",
            Masked_Mean_Std_Dev_UInt8_Selective_And_Nonzero_Semantics'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Mean_Std_Dev Vec3 per-channel",
            Masked_Mean_Std_Dev_Vec3_Per_Channel'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Mean_Std_Dev Compare interop",
            Masked_Mean_Std_Dev_Compare_Interop'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Mean_Std_Dev non-continuous views and all-zero mask",
            Masked_Mean_Std_Dev_Non_Continuous_Views_And_All_Zero_Mask'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Mean_Std_Dev handles empty and invalid input",
            Masked_Mean_Std_Dev_Handles_Empty_And_Invalid_Input'Access));
      Result.Add_Test
        (Caller.Create
           ("Trace uses main diagonal for square and rectangular Mats",
            Trace_Uses_Main_Diagonal_For_Square_And_Rectangular_Mats'Access));
      Result.Add_Test
        (Caller.Create
           ("Trace supports Float32 and multiple channels",
            Trace_Supports_Float32_And_Multiple_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("Trace handles Regions, empty Mats, and invalid types",
            Trace_Handles_Regions_Empty_And_Invalid_Types'Access));
      Result.Add_Test
        (Caller.Create
           ("Determinant 1x1 uses the sole Float32 value",
            Determinant_1x1_Uses_Sole_Float32_Value'Access));
      Result.Add_Test
        (Caller.Create
           ("Determinant 2x2 uses the direct path",
            Determinant_2x2_Uses_Direct_Path'Access));
      Result.Add_Test
        (Caller.Create
           ("Determinant 2x2 preserves sign",
            Determinant_2x2_Preserves_Sign'Access));
      Result.Add_Test
        (Caller.Create
           ("Determinant 3x3 uses the direct path",
            Determinant_3x3_Uses_Direct_Path'Access));
      Result.Add_Test
        (Caller.Create
           ("Determinant 4x4 uses the LU path",
            Determinant_4x4_Uses_LU_Path'Access));
      Result.Add_Test
        (Caller.Create
           ("Determinant of a singular 4x4 returns zero",
            Determinant_Singular_4x4_Returns_Zero'Access));
      Result.Add_Test
        (Caller.Create
           ("Determinant supports Float64",
            Determinant_Supports_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("Determinant supports a non-contiguous Region",
            Determinant_Supports_Noncontiguous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Determinant equals the transpose determinant",
            Determinant_Equals_Transpose_Determinant'Access));
      Result.Add_Test
        (Caller.Create
           ("Determinant rejects empty and invalid types",
            Determinant_Rejects_Empty_And_Invalid_Types'Access));
      Result.Add_Test
        (Caller.Create
           ("Invert 1x1 uses the direct path",
            Invert_1x1_Uses_Direct_Path'Access));
      Result.Add_Test
        (Caller.Create
           ("Invert 2x2 uses a known inverse",
            Invert_2x2_Uses_Known_Inverse'Access));
      Result.Add_Test
        (Caller.Create
           ("Invert 3x3 uses the direct path",
            Invert_3x3_Uses_Direct_Path'Access));
      Result.Add_Test
        (Caller.Create
           ("Invert 4x4 uses the LU path", Invert_4x4_Uses_LU_Path'Access));
      Result.Add_Test
        (Caller.Create
           ("Invert of a singular 2x2 is not an error",
            Invert_Singular_2x2_Is_Not_An_Error'Access));
      Result.Add_Test
        (Caller.Create
           ("Invert of a singular 4x4 is not an error",
            Invert_Singular_4x4_Is_Not_An_Error'Access));
      Result.Add_Test
        (Caller.Create
           ("Invert determinant matches the reciprocal",
            Invert_Determinant_Matches_Reciprocal'Access));
      Result.Add_Test
        (Caller.Create
           ("Invert supports Float64", Invert_Supports_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("Invert supports a non-contiguous Region",
            Invert_Supports_Noncontiguous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Invert result owns independent storage",
            Invert_Result_Owns_Independent_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Invert transpose relationship",
            Invert_Transpose_Relationship'Access));
      Result.Add_Test
        (Caller.Create
           ("Invert rejects empty and invalid types",
            Invert_Rejects_Empty_And_Invalid_Types'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve 1x1 uses the direct path",
            Solve_1x1_Uses_Direct_Path'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve 2x2 uses a known solution",
            Solve_2x2_Uses_Known_Solution'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve 3x3 uses the direct path",
            Solve_3x3_Uses_Direct_Path'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve 4x4 uses the LU path", Solve_4x4_Uses_LU_Path'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve accepts multiple right-hand-side columns",
            Solve_Multiple_RHS_Columns'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve of a singular 2x2 is not an error",
            Solve_Singular_2x2_Is_Not_An_Error'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve of a singular 4x4 is not an error",
            Solve_Singular_4x4_Is_Not_An_Error'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve supports Float64", Solve_Supports_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve supports non-contiguous Regions",
            Solve_Supports_Noncontiguous_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve result owns independent storage",
            Solve_Result_Owns_Independent_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Solve rejects empty and invalid types",
            Solve_Rejects_Empty_And_Invalid_Types'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply 2x3 times 3x2 Float32",
            Matrix_Multiply_2x3_Times_3x2_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply non-square output",
            Matrix_Multiply_Non_Square_Output'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply row times column",
            Matrix_Multiply_Row_Times_Column'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply column times row",
            Matrix_Multiply_Column_Times_Row'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply identity integration",
            Matrix_Multiply_Identity_Integration'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply supports Float64",
            Matrix_Multiply_Supports_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply complex Float32",
            Matrix_Multiply_Complex_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply complex Float64",
            Matrix_Multiply_Complex_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply supports non-contiguous Regions",
            Matrix_Multiply_Noncontiguous_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply result owns independent storage",
            Matrix_Multiply_Result_Owns_Independent_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply rejects invalid inputs",
            Matrix_Multiply_Rejects_Invalid_Inputs'Access));

      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply_Add weighted Float32",
            Matrix_Multiply_Add_Weighted_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply_Add default scales",
            Matrix_Multiply_Add_Default_Scales'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply_Add product scale zero",
            Matrix_Multiply_Add_Product_Scale_Zero'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply_Add addend scale zero",
            Matrix_Multiply_Add_Addend_Scale_Zero'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply_Add negative scales",
            Matrix_Multiply_Add_Negative_Scales'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply_Add rectangular product",
            Matrix_Multiply_Add_Rectangular_Product'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply_Add supports Float64",
            Matrix_Multiply_Add_Supports_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply_Add complex Float32",
            Matrix_Multiply_Add_Complex_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply_Add complex Float64",
            Matrix_Multiply_Add_Complex_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply_Add supports non-contiguous Regions",
            Matrix_Multiply_Add_Noncontiguous_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply_Add result owns independent storage",
            Matrix_Multiply_Add_Result_Owns_Independent_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Matrix_Multiply_Add rejects invalid inputs",
            Matrix_Multiply_Add_Rejects_Invalid_Inputs'Access));

      Result.Add_Test
        (Caller.Create
           ("Transposed_Product Float32 Transpose_Times_Self",
            Transposed_Product_Float32_Transpose_Times_Self'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product Float32 Self_Times_Transpose",
            Transposed_Product_Float32_Self_Times_Transpose'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product applies Scale",
            Transposed_Product_Applies_Scale'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product UInt8 automatic output",
            Transposed_Product_UInt8_Automatic_Output'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product UInt16 automatic output",
            Transposed_Product_UInt16_Automatic_Output'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product Int16 automatic output",
            Transposed_Product_Int16_Automatic_Output'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product Float64 automatic output",
            Transposed_Product_Float64_Automatic_Output'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product explicit Float64 from Float32",
            Transposed_Product_Explicit_Float64_From_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product explicit Float64 from UInt8",
            Transposed_Product_Explicit_Float64_From_UInt8'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product supports non-contiguous Regions",
            Transposed_Product_Noncontiguous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product result owns independent storage",
            Transposed_Product_Result_Owns_Independent_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product rejects invalid inputs",
            Transposed_Product_Rejects_Invalid_Inputs'Access));

      Result.Add_Test
        (Caller.Create
           ("Reduce Sum maps axes, depth, and independent storage",
            Reduce_Sum_Maps_Axes_Depth_And_Independent_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Reduce supports kinds, Float32, channels, and Regions",
            Reduce_Supports_Kinds_Float_Multi_Channel_And_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("Reduce handles empty and invalid depth combinations",
            Reduce_Handles_Empty_And_Invalid_Depth_Combinations'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Norm computes L1, L2, and Infinity",
            Float32_Norm_Computes_L1_L2_And_Infinity'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Norm is not Float32-specific",
            UInt8_Norm_Is_Not_Float32_Specific'Access));
      Result.Add_Test
        (Caller.Create
           ("Vec3 Norm combines all channels",
            Vec3_Norm_Combines_All_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Norm computes L1, L2, and Infinity",
            Masked_Norm_Computes_L1_L2_And_Infinity'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Norm uses Compare and In_Range masks",
            Masked_Norm_Uses_Compare_And_In_Range_Masks'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Norm supports Vec3 and non-continuous views",
            Masked_Norm_Supports_Vec3_And_Non_Continuous_Views'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Norm handles zero, empty, and invalid masks",
            Masked_Norm_Handles_Zero_Empty_And_Invalid_Masks'Access));
      Result.Add_Test
        (Caller.Create
           ("Norm operates on a non-continuous Region",
            Norm_Operates_On_Non_Continuous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Reshape preserves Norm", Reshape_Preserves_Norm'Access));
      Result.Add_Test
        (Caller.Create
           ("Empty Mat Norm is zero", Empty_Mat_Norm_Is_Zero'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Norm is supported", Float16_Norm_Is_Supported'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Normalize L2 preserves metadata and source",
            Float32_Normalize_L2_Preserves_Metadata_And_Source'Access));
      Result.Add_Test
        (Caller.Create
           ("Normalize L1 and Infinity support Vec3",
            Normalize_L1_And_Infinity_Support_Vec3'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Normalize Min_Max maps range",
            Float32_Normalize_Min_Max_Maps_Range'Access));
      Result.Add_Test
        (Caller.Create
           ("Normalize returns independent storage",
            Normalize_Returns_Independent_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Normalize operates on a non-continuous Region",
            Normalize_Operates_On_Non_Continuous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Normalize uses OpenCV rounding and saturation",
            UInt8_Normalize_Uses_OpenCV_Rounding_And_Saturation'Access));
      Result.Add_Test
        (Caller.Create
           ("Normalize handles empty and zero input",
            Normalize_Handles_Empty_And_Zero_Input'Access));
      Result.Add_Test
        (Caller.Create
           ("Min_Max_Loc UInt8 returns values and column-row Points",
            Min_Max_Loc_UInt8_Returns_Values_And_Column_Row_Points'Access));
      Result.Add_Test
        (Caller.Create
           ("Min_Max_Loc Float32 returns negative fractional values",
            Min_Max_Loc_Float32_Returns_Negative_Fractional_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Min_Max_Loc supports Int32", Min_Max_Loc_Supports_Int32'Access));
      Result.Add_Test
        (Caller.Create
           ("Min_Max_Loc uses Region-relative coordinates",
            Min_Max_Loc_Uses_Region_Relative_Coordinates'Access));
      Result.Add_Test
        (Caller.Create
           ("Min_Max_Loc operates on a row view",
            Min_Max_Loc_Operates_On_Row_View'Access));
      Result.Add_Test
        (Caller.Create
           ("Min_Max_Loc rejects invalid Mats",
            Min_Max_Loc_Rejects_Invalid_Mats'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Min_Max_Loc UInt8 selects extrema and column-row"
            & " Points",
            Masked_Min_Max_Loc_UInt8_Selects_Extrema_And_Column_Row_Points'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Min_Max_Loc excludes global extrema with In_Range mask",
            Masked_Min_Max_Loc_Excludes_Global_Extrema_And_Uses_In_Range_Mask'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Min_Max_Loc operates on non-continuous views",
            Masked_Min_Max_Loc_Operates_On_Non_Continuous_Views'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Min_Max_Loc all-zero mask returns OpenCV sentinels",
            Masked_Min_Max_Loc_All_Zero_Mask_Returns_OpenCV_Sentinels'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Min_Max_Loc rejects invalid input",
            Masked_Min_Max_Loc_Rejects_Invalid_Input'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Mat set-to and sum", UInt8_Set_To_And_Sum'Access));
      Result.Add_Test
        (Caller.Create
           ("Three-channel Mat set-to and sum",
            Three_Channel_Set_To_And_Sum'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Mat set-to and sum", Float32_Set_To_And_Sum'Access));
      return Result'Access;
   end Suite;

end Mat_Reduction_Tests;
