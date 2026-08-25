with AUnit.Assertions;
with AUnit.Test_Caller;
with Ada.Numerics.Long_Elementary_Functions;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float32_Vec3;
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
   use type OpenCV.Core.Float32_Vec3.Vector;

   use Mat_Test_Support;
   use Ada.Numerics.Long_Elementary_Functions;

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

      procedure Default_Sum_Of_Squares is
         Result : constant OpenCV.Core.Mat :=
           UInt8_Source.Reduce
             (OpenCV.Core.Across_Rows, OpenCV.Core.Sum_Of_Squares);
      begin
         pragma Unreferenced (Result);
      end Default_Sum_Of_Squares;

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
        (Default_Sum_Of_Squares'Access,
         "Default UInt8 Sum_Of_Squares must expose OpenCV's unsupported dtype"
         & " combination");
      Assert_Raises_OpenCV_Error
        (Converted_Maximum'Access,
         "Maximum must reject output-depth conversion before entering OpenCV");
   end Reduce_Handles_Empty_And_Invalid_Depth_Combinations;

   procedure Reduce_Sum_Of_Squares_Promotes_Integer_Sources_Before_Multiply
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source           : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      As_Int32         : OpenCV.Core.Mat;
      As_Float32       : OpenCV.Core.Mat;
      Int32_As_Float32 : OpenCV.Core.Mat;
   begin
      --  200*200 and 16*16 both leave the UInt8 range. Native REDUCE_SUM2
      --  promotes to the destination type first, so the squares are 40000
      --  and 256. Multiplying in UInt8 first saturates to 255 (or wraps)
      --  and then reduces to a different pair.
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 200);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 0, 200);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 16);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 1, 1);
      As_Int32 :=
        Source.Reduce
          (OpenCV.Core.Across_Rows,
           OpenCV.Core.Sum_Of_Squares,
           OpenCV.Core.Int32);
      As_Float32 :=
        Source.Reduce
          (OpenCV.Core.Across_Rows,
           OpenCV.Core.Sum_Of_Squares,
           OpenCV.Core.Float32);
      Int32_As_Float32 := As_Int32.Convert_To (OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (As_Int32.Rows = 1
         and then As_Int32.Columns = 2
         and then As_Int32.Depth = OpenCV.Core.Int32
         and then As_Int32.Channels = 1,
         "UInt8 Sum_Of_Squares must accept the REDUCE_SUM2 Int32 dest type");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get (Int32_As_Float32, 0, 0)),
            80_000.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Int32_As_Float32, 0, 1)),
                     257.0),
         "UInt8 Sum_Of_Squares to Int32 must square after dest promotion");
      AUnit.Assertions.Assert
        (As_Float32.Rows = 1
         and then As_Float32.Columns = 2
         and then As_Float32.Depth = OpenCV.Core.Float32
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (As_Float32, 0, 0)),
                     80_000.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (As_Float32, 0, 1)),
                     257.0),
         "UInt8 Sum_Of_Squares to Float32 must square after dest promotion");
   end Reduce_Sum_Of_Squares_Promotes_Integer_Sources_Before_Multiply;

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

   procedure Dot_Product_Basic_Float32 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Result : Long_Float;
   begin
      Fill_2x3 (Left, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Fill_2x3 (Right, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0);
      Result := Left.Dot_Product (Right);

      AUnit.Assertions.Assert
        (Result = 56.0, "Float32 Dot_Product must sum every element product");
      AUnit.Assertions.Assert
        (Unchanged_2x3 (Left, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0)
         and then Unchanged_2x3 (Right, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0),
         "Dot_Product must not modify its operands");
   end Dot_Product_Basic_Float32;

   procedure Dot_Product_Supports_Float64 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Float32_Left  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Float32_Right : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Left          : OpenCV.Core.Mat;
      Right         : OpenCV.Core.Mat;
      Result        : Long_Float;
   begin
      Fill_2x3 (Float32_Left, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Fill_2x3 (Float32_Right, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0);
      Left := Float32_Left.Convert_To (OpenCV.Core.Float64);
      Right := Float32_Right.Convert_To (OpenCV.Core.Float64);
      Result := Left.Dot_Product (Right);

      AUnit.Assertions.Assert
        (Left.Depth = OpenCV.Core.Float64
         and then Right.Depth = OpenCV.Core.Float64
         and then Result = 56.0,
         "Float64 Dot_Product must return Long_Float 56.0 and keep Float64");
   end Dot_Product_Supports_Float64;

   procedure Dot_Product_Supports_Integer_Depths
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Float32_Left  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Float32_Right : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));

      function Product_Of (Depth : OpenCV.Core.Depth_Type) return Long_Float
      is (Float32_Left.Convert_To (Depth).Dot_Product
            (Float32_Right.Convert_To (Depth)));
   begin
      OpenCV.Core.Float32_Access.Set (Float32_Left, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Float32_Left, 0, 1, -2.0);
      OpenCV.Core.Float32_Access.Set (Float32_Left, 1, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Float32_Left, 1, 1, 4.0);
      OpenCV.Core.Float32_Access.Set (Float32_Right, 0, 0, 5.0);
      OpenCV.Core.Float32_Access.Set (Float32_Right, 0, 1, 6.0);
      OpenCV.Core.Float32_Access.Set (Float32_Right, 1, 0, -1.0);
      OpenCV.Core.Float32_Access.Set (Float32_Right, 1, 1, 2.0);

      AUnit.Assertions.Assert
        (Product_Of (OpenCV.Core.UInt8) = 13.0,
         "UInt8 Dot_Product must use the supported OpenCV kernel");
      AUnit.Assertions.Assert
        (Product_Of (OpenCV.Core.Int8) = -2.0,
         "Int8 Dot_Product must include negative signed values");
      AUnit.Assertions.Assert
        (Product_Of (OpenCV.Core.UInt16) = 13.0,
         "UInt16 Dot_Product must use the supported OpenCV kernel");
      AUnit.Assertions.Assert
        (Product_Of (OpenCV.Core.Int16) = -2.0,
         "Int16 Dot_Product must include negative signed values");
      AUnit.Assertions.Assert
        (Product_Of (OpenCV.Core.Int32) = -2.0,
         "Int32 Dot_Product must use the supported OpenCV kernel");
   end Dot_Product_Supports_Integer_Depths;

   procedure Dot_Product_Rejects_Float16 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Left  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float16, 1));
      Right : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float16, 1));

      procedure Check_Float16 is
         Value : constant Long_Float := Left.Dot_Product (Right);
      begin
         pragma Unreferenced (Value);
      end Check_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access, "Dot_Product must reject Float16 Mats");
   end Dot_Product_Rejects_Float16;

   procedure Dot_Product_C3_Sums_Every_Channel (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 3));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 3));
      Result : Long_Float;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set (Left, 0, 0, (1.0, 2.0, 3.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Right, 0, 0, (4.0, 5.0, 6.0));
      Result := Left.Dot_Product (Right);

      AUnit.Assertions.Assert
        (Result = 32.0,
         "C3 Dot_Product must sum every corresponding channel product");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Vec3_Access.Get (Left, 0, 0) = (1.0, 2.0, 3.0)
         and then OpenCV.Core.Float32_Vec3_Access.Get (Right, 0, 0)
                  = (4.0, 5.0, 6.0),
         "C3 Dot_Product must not modify either operand");
   end Dot_Product_C3_Sums_Every_Channel;

   procedure Dot_Product_C2_Is_Not_Complex (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Left_0  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Left_1  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Right_0 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Right_1 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Left    : OpenCV.Core.Mat;
      Right   : OpenCV.Core.Mat;
      Result  : Long_Float;
   begin
      OpenCV.Core.Float32_Access.Set (Left_0, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Left_1, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Right_0, 0, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Right_1, 0, 0, 4.0);
      Left := OpenCV.Core.Merge ((Left_0, Left_1));
      Right := OpenCV.Core.Merge ((Right_0, Right_1));
      Result := Left.Dot_Product (Right);

      AUnit.Assertions.Assert
        (Result = 11.0,
         "C2 Dot_Product must sum channel products 1*3 + 2*4, not GEMM"
         & " complex arithmetic");
   end Dot_Product_C2_Is_Not_Complex;

   procedure Dot_Product_Supports_Five_Channels
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left_Channels  : OpenCV.Core.Mat_Array (0 .. 4);
      Right_Channels : OpenCV.Core.Mat_Array (0 .. 4);
      Left           : OpenCV.Core.Mat;
      Right          : OpenCV.Core.Mat;
      Result         : Long_Float;
   begin
      for Index in Left_Channels'Range loop
         Left_Channels (Index) :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
         Right_Channels (Index) :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
         OpenCV.Core.Float32_Access.Set
           (Left_Channels (Index), 0, 0, Interfaces.IEEE_Float_32 (Index + 1));
         OpenCV.Core.Float32_Access.Set
           (Right_Channels (Index),
            0,
            0,
            Interfaces.IEEE_Float_32 (5 - Index));
      end loop;

      Left := OpenCV.Core.Merge (Left_Channels);
      Right := OpenCV.Core.Merge (Right_Channels);
      Result := Left.Dot_Product (Right);

      AUnit.Assertions.Assert
        (Left.Channels = 5 and then Right.Channels = 5 and then Result = 35.0,
         "C5 Dot_Product must include every channel, not only Scalar's four");
   end Dot_Product_Supports_Five_Channels;

   procedure Dot_Product_Sums_Multiple_Elements_And_Channels
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 3));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 3));
      Result : Long_Float;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set (Left, 0, 0, (1.0, 2.0, 3.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Left, 1, 0, (1.0, 0.0, 2.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Right, 0, 0, (4.0, 5.0, 6.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Right, 1, 0, (2.0, 3.0, 4.0));
      Result := Left.Dot_Product (Right);

      AUnit.Assertions.Assert
        (Result = 42.0,
         "Dot_Product must sum over every spatial element and every channel");
   end Dot_Product_Sums_Multiple_Elements_And_Channels;

   procedure Dot_Product_Supports_Noncontiguous_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent_Left  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 5, (OpenCV.Core.Float32, 1));
      Parent_Right : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
      Result       : Long_Float;
   begin
      Parent_Left.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Parent_Right.Set_To (OpenCV.Core.Make_Scalar (88.0));

      declare
         Left  : OpenCV.Core.Mat :=
           Parent_Left.Region ((X => 1, Y => 0, Width => 3, Height => 2));
         Right : OpenCV.Core.Mat :=
           Parent_Right.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      begin
         Fill_2x3 (Left, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
         Fill_2x3 (Right, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0);
         AUnit.Assertions.Assert
           (not Left.Is_Continuous and then not Right.Is_Continuous,
            "The Regions used for Dot_Product must be non-contiguous");
         Result := Left.Dot_Product (Right);
         AUnit.Assertions.Assert
           (Result = 56.0,
            "Dot_Product must support non-contiguous Left and Right Regions");
         AUnit.Assertions.Assert
           (Unchanged_2x3 (Left, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0)
            and then Unchanged_2x3 (Right, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0)
            and then OpenCV.Core.Float32_Access.Get (Parent_Left, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent_Left, 0, 4) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent_Right, 0, 0) = 88.0
            and then OpenCV.Core.Float32_Access.Get (Parent_Right, 1, 0)
                     = 88.0,
            "Dot_Product must not modify the Regions or their parents");
      end;
   end Dot_Product_Supports_Noncontiguous_Regions;

   procedure Dot_Product_Rejects_Mismatched_Shape_And_Type
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Row           : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Column        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Float32_C1    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Float64_C1    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float64, 1));
      Float32_C3    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 3));
      Default_Empty : OpenCV.Core.Mat;
      Empty32       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));

      procedure Check_Shape is
         Value : constant Long_Float := Row.Dot_Product (Column);
      begin
         pragma Unreferenced (Value);
      end Check_Shape;

      procedure Check_Depth is
         Value : constant Long_Float := Float32_C1.Dot_Product (Float64_C1);
      begin
         pragma Unreferenced (Value);
      end Check_Depth;

      procedure Check_Channels is
         Value : constant Long_Float := Float32_C1.Dot_Product (Float32_C3);
      begin
         pragma Unreferenced (Value);
      end Check_Channels;

      procedure Check_Default_Self is
         Value : constant Long_Float := Default_Empty.Dot_Product (Float32_C1);
      begin
         pragma Unreferenced (Value);
      end Check_Default_Self;

      procedure Check_Default_Other is
         Value : constant Long_Float := Float32_C1.Dot_Product (Default_Empty);
      begin
         pragma Unreferenced (Value);
      end Check_Default_Other;

      procedure Check_Empty32 is
         Value : constant Long_Float := Empty32.Dot_Product (Empty32);
      begin
         pragma Unreferenced (Value);
      end Check_Empty32;
   begin
      Assert_Raises_OpenCV_Error
        (Check_Shape'Access,
         "Dot_Product must reject a 1x3 C1 Mat against a 3x1 C1 Mat");
      Assert_Raises_OpenCV_Error
        (Check_Depth'Access,
         "Dot_Product must reject mixed Float32 and Float64 operands");
      Assert_Raises_OpenCV_Error
        (Check_Channels'Access,
         "Dot_Product must reject mixed C1 and C3 operands");
      Assert_Raises_OpenCV_Error
        (Check_Default_Self'Access,
         "Dot_Product must reject a default empty Self");
      Assert_Raises_OpenCV_Error
        (Check_Default_Other'Access,
         "Dot_Product must reject a default empty Other");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access,
         "Dot_Product must reject typed 0x0 Float32 operands");
   end Dot_Product_Rejects_Mismatched_Shape_And_Type;

   procedure Fill_1x2
     (Image : in out OpenCV.Core.Mat; A, B : OpenCV.Core.Float32_Value) is
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, A);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, B);
   end Fill_1x2;

   function Unchanged_1x2
     (Image : OpenCV.Core.Mat; A, B : OpenCV.Core.Float32_Value) return Boolean
   is (OpenCV.Core.Float32_Access.Get (Image, 0, 0) = A
       and then OpenCV.Core.Float32_Access.Get (Image, 0, 1) = B);

   procedure Fill_2x1
     (Image : in out OpenCV.Core.Mat; A, B : OpenCV.Core.Float32_Value) is
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, A);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, B);
   end Fill_2x1;

   function Unchanged_2x1
     (Image : OpenCV.Core.Mat; A, B : OpenCV.Core.Float32_Value) return Boolean
   is (OpenCV.Core.Float32_Access.Get (Image, 0, 0) = A
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 0) = B);

   function Identity_2x2
     (Depth : OpenCV.Core.Depth_Type) return OpenCV.Core.Mat
   is
      Image : OpenCV.Core.Mat := OpenCV.Core.Create (2, 2, (Depth, 1));
   begin
      Image.Set_Identity;
      return Image;
   end Identity_2x2;

   procedure Mahalanobis_Distance_Basic_Float32_Identity
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Self               : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Other              : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Inverse_Covariance : constant OpenCV.Core.Mat :=
        Identity_2x2 (OpenCV.Core.Float32);
      Result             : Long_Float;
   begin
      Fill_1x2 (Self, 1.0, 2.0);
      Fill_1x2 (Other, 4.0, 6.0);
      Result := Self.Mahalanobis_Distance (Other, Inverse_Covariance);

      AUnit.Assertions.Assert
        (Result = 5.0,
         "Float32 identity Mahalanobis_Distance of (1,2) and (4,6) must be 5");
      AUnit.Assertions.Assert
        (Unchanged_1x2 (Self, 1.0, 2.0)
         and then Unchanged_1x2 (Other, 4.0, 6.0)
         and then Unchanged_2x2 (Inverse_Covariance, 1.0, 0.0, 0.0, 1.0),
         "Mahalanobis_Distance must not modify its operands");
   end Mahalanobis_Distance_Basic_Float32_Identity;

   procedure Mahalanobis_Distance_Nonidentity_Diagonal
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Self               : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Other              : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Inverse_Covariance : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result             : Long_Float;
   begin
      Fill_1x2 (Self, 1.0, 2.0);
      Fill_1x2 (Other, 4.0, 6.0);
      Fill_2x2 (Inverse_Covariance, 4.0, 0.0, 0.0, 1.0);
      Result := Self.Mahalanobis_Distance (Other, Inverse_Covariance);

      AUnit.Assertions.Assert
        (Approximately_Equal (Result, 7.211_102_550_927_978),
         "Diagonal Inverse_Covariance must weight the quadratic form");
      AUnit.Assertions.Assert
        (Unchanged_1x2 (Self, 1.0, 2.0)
         and then Unchanged_1x2 (Other, 4.0, 6.0)
         and then Unchanged_2x2 (Inverse_Covariance, 4.0, 0.0, 0.0, 1.0),
         "Weighted Mahalanobis_Distance must not modify its operands");
   end Mahalanobis_Distance_Nonidentity_Diagonal;

   procedure Mahalanobis_Distance_Uses_Off_Diagonal_Terms
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Self               : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Other              : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Inverse_Covariance : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result             : Long_Float;
   begin
      Fill_1x2 (Self, 1.0, 2.0);
      Fill_1x2 (Other, 4.0, 6.0);
      Fill_2x2 (Inverse_Covariance, 1.0, 0.5, 0.5, 1.0);
      Result := Self.Mahalanobis_Distance (Other, Inverse_Covariance);

      AUnit.Assertions.Assert
        (Approximately_Equal (Result, 6.082_762_530_298_219)
         and then not Approximately_Equal (Result, 5.0),
         "Off-diagonal Inverse_Covariance must contribute to the quadratic"
         & " form");
      AUnit.Assertions.Assert
        (Unchanged_2x2 (Inverse_Covariance, 1.0, 0.5, 0.5, 1.0),
         "Off-diagonal Mahalanobis_Distance must not modify"
         & " Inverse_Covariance");
   end Mahalanobis_Distance_Uses_Off_Diagonal_Terms;

   procedure Mahalanobis_Distance_Equal_Vectors_Are_Zero
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Self               : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Other              : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Inverse_Covariance : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result             : Long_Float;
   begin
      Fill_1x2 (Self, 1.0, 2.0);
      Fill_1x2 (Other, 1.0, 2.0);
      Fill_2x2 (Inverse_Covariance, 4.0, 1.0, 1.0, 9.0);
      Result := Self.Mahalanobis_Distance (Other, Inverse_Covariance);

      AUnit.Assertions.Assert
        (Result = 0.0,
         "Equal vectors must have Mahalanobis_Distance exactly 0");
   end Mahalanobis_Distance_Equal_Vectors_Are_Zero;

   procedure Mahalanobis_Distance_Supports_Float64
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Base_32            : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Unit_32            : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Other              : OpenCV.Core.Mat;
      Unit               : OpenCV.Core.Mat;
      Self               : OpenCV.Core.Mat;
      Inverse_Covariance : OpenCV.Core.Mat;
      Result             : Long_Float;
   begin
      --  2**24 is exact in both Float32 and Float64. 2**24+1 is exact
      --  only in Float64; a Float32-only path would collapse both
      --  vectors and return 0.
      Fill_1x2 (Base_32, 16_777_216.0, 0.0);
      Fill_1x2 (Unit_32, 1.0, 0.0);
      Other := Base_32.Convert_To (OpenCV.Core.Float64);
      Unit := Unit_32.Convert_To (OpenCV.Core.Float64);
      Self := Other.Add (Unit);
      Inverse_Covariance :=
        Identity_2x2 (OpenCV.Core.Float32).Convert_To (OpenCV.Core.Float64);
      Result := Self.Mahalanobis_Distance (Other, Inverse_Covariance);

      AUnit.Assertions.Assert
        (Self.Depth = OpenCV.Core.Float64
         and then Other.Depth = OpenCV.Core.Float64
         and then Inverse_Covariance.Depth = OpenCV.Core.Float64
         and then Result = 1.0,
         "Float64 Mahalanobis_Distance must preserve 2**24+1 versus 2**24");
   end Mahalanobis_Distance_Supports_Float64;

   procedure Mahalanobis_Distance_Supports_Column_Vectors
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Self               : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      Other              : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      Inverse_Covariance : constant OpenCV.Core.Mat :=
        Identity_2x2 (OpenCV.Core.Float32);
      Result             : Long_Float;
   begin
      Fill_2x1 (Self, 1.0, 2.0);
      Fill_2x1 (Other, 4.0, 6.0);
      Result := Self.Mahalanobis_Distance (Other, Inverse_Covariance);

      AUnit.Assertions.Assert
        (Result = 5.0,
         "Column-vector Mahalanobis_Distance must match the row-vector case");
      AUnit.Assertions.Assert
        (Unchanged_2x1 (Self, 1.0, 2.0)
         and then Unchanged_2x1 (Other, 4.0, 6.0),
         "Column-vector Mahalanobis_Distance must not modify its operands");
   end Mahalanobis_Distance_Supports_Column_Vectors;

   procedure Mahalanobis_Distance_Noncontiguous_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent_Self   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 1));
      Parent_Other  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 5, (OpenCV.Core.Float32, 1));
      Parent_Icovar : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 5, (OpenCV.Core.Float32, 1));
      Result        : Long_Float;
   begin
      Parent_Self.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Parent_Other.Set_To (OpenCV.Core.Make_Scalar (88.0));
      Parent_Icovar.Set_To (OpenCV.Core.Make_Scalar (77.0));

      declare
         Self               : OpenCV.Core.Mat :=
           Parent_Self.Region ((X => 1, Y => 0, Width => 1, Height => 2));
         Other              : OpenCV.Core.Mat :=
           Parent_Other.Region ((X => 2, Y => 1, Width => 1, Height => 2));
         Inverse_Covariance : OpenCV.Core.Mat :=
           Parent_Icovar.Region ((X => 1, Y => 1, Width => 2, Height => 2));
      begin
         Fill_2x1 (Self, 1.0, 2.0);
         Fill_2x1 (Other, 4.0, 6.0);
         Fill_2x2 (Inverse_Covariance, 1.0, 0.0, 0.0, 1.0);

         AUnit.Assertions.Assert
           (not Self.Is_Continuous
            and then not Other.Is_Continuous
            and then not Inverse_Covariance.Is_Continuous,
            "Mahalanobis_Distance Region operands must be non-contiguous");
         Result := Self.Mahalanobis_Distance (Other, Inverse_Covariance);
         AUnit.Assertions.Assert
           (Result = 5.0,
            "Mahalanobis_Distance must support non-contiguous column and"
            & " Inverse_Covariance Regions");
         AUnit.Assertions.Assert
           (Unchanged_2x1 (Self, 1.0, 2.0)
            and then Unchanged_2x1 (Other, 4.0, 6.0)
            and then Unchanged_2x2 (Inverse_Covariance, 1.0, 0.0, 0.0, 1.0)
            and then OpenCV.Core.Float32_Access.Get (Parent_Self, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent_Self, 0, 2) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent_Other, 1, 1) = 88.0
            and then OpenCV.Core.Float32_Access.Get (Parent_Other, 0, 2) = 88.0
            and then OpenCV.Core.Float32_Access.Get (Parent_Icovar, 0, 0)
                     = 77.0
            and then OpenCV.Core.Float32_Access.Get (Parent_Icovar, 1, 0)
                     = 77.0
            and then OpenCV.Core.Float32_Access.Get (Parent_Icovar, 1, 3)
                     = 77.0,
            "Mahalanobis_Distance must not modify the Regions or their"
            & " parents");
      end;
   end Mahalanobis_Distance_Noncontiguous_Regions;

   procedure Mahalanobis_Distance_Rejects_Invalid_Inputs
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Row           : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Other_Row     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Long_Row      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Column        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      Matrix        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Float64_Row   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float64, 1));
      UInt8_Row     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Int32_Row     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Int32, 1));
      Float16_Row   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float16, 1));
      Multi_Row     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 3));
      Identity      : constant OpenCV.Core.Mat :=
        Identity_2x2 (OpenCV.Core.Float32);
      Identity64    : constant OpenCV.Core.Mat :=
        Identity_2x2 (OpenCV.Core.Float64);
      Multi_Icovar  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 3));
      Wide_Icovar   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Large_Icovar  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Default_Empty : OpenCV.Core.Mat;
      Empty_Vector  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 2, (OpenCV.Core.Float32, 1));
      Empty_Icovar  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));

      procedure Check_Default_Self is
         Value : constant Long_Float :=
           Default_Empty.Mahalanobis_Distance (Other_Row, Identity);
      begin
         pragma Unreferenced (Value);
      end Check_Default_Self;

      procedure Check_Default_Other is
         Value : constant Long_Float :=
           Row.Mahalanobis_Distance (Default_Empty, Identity);
      begin
         pragma Unreferenced (Value);
      end Check_Default_Other;

      procedure Check_Empty_Vector is
         Value : constant Long_Float :=
           Empty_Vector.Mahalanobis_Distance (Empty_Vector, Identity);
      begin
         pragma Unreferenced (Value);
      end Check_Empty_Vector;

      procedure Check_Length is
         Value : constant Long_Float :=
           Row.Mahalanobis_Distance (Long_Row, Identity);
      begin
         pragma Unreferenced (Value);
      end Check_Length;

      procedure Check_Row_Versus_Column is
         Value : constant Long_Float :=
           Row.Mahalanobis_Distance (Column, Identity);
      begin
         pragma Unreferenced (Value);
      end Check_Row_Versus_Column;

      procedure Check_Depth is
         Value : constant Long_Float :=
           Row.Mahalanobis_Distance (Float64_Row, Identity);
      begin
         pragma Unreferenced (Value);
      end Check_Depth;

      procedure Check_UInt8 is
         Value : constant Long_Float :=
           UInt8_Row.Mahalanobis_Distance (UInt8_Row, Identity);
      begin
         pragma Unreferenced (Value);
      end Check_UInt8;

      procedure Check_Int32 is
         Value : constant Long_Float :=
           Int32_Row.Mahalanobis_Distance (Int32_Row, Identity);
      begin
         pragma Unreferenced (Value);
      end Check_Int32;

      procedure Check_Float16 is
         Value : constant Long_Float :=
           Float16_Row.Mahalanobis_Distance (Float16_Row, Identity);
      begin
         pragma Unreferenced (Value);
      end Check_Float16;

      procedure Check_Channels is
         Value : constant Long_Float :=
           Multi_Row.Mahalanobis_Distance (Multi_Row, Identity);
      begin
         pragma Unreferenced (Value);
      end Check_Channels;

      procedure Check_Matrix_As_Vector is
         Value : constant Long_Float :=
           Matrix.Mahalanobis_Distance (Matrix, Identity);
      begin
         pragma Unreferenced (Value);
      end Check_Matrix_As_Vector;

      procedure Check_Empty_Icovar is
         Value : constant Long_Float :=
           Row.Mahalanobis_Distance (Other_Row, Empty_Icovar);
      begin
         pragma Unreferenced (Value);
      end Check_Empty_Icovar;

      procedure Check_Default_Icovar is
         Value : constant Long_Float :=
           Row.Mahalanobis_Distance (Other_Row, Default_Empty);
      begin
         pragma Unreferenced (Value);
      end Check_Default_Icovar;

      procedure Check_Icovar_Depth is
         Value : constant Long_Float :=
           Row.Mahalanobis_Distance (Other_Row, Identity64);
      begin
         pragma Unreferenced (Value);
      end Check_Icovar_Depth;

      procedure Check_Icovar_Channels is
         Value : constant Long_Float :=
           Row.Mahalanobis_Distance (Other_Row, Multi_Icovar);
      begin
         pragma Unreferenced (Value);
      end Check_Icovar_Channels;

      procedure Check_Icovar_Shape is
         Value : constant Long_Float :=
           Row.Mahalanobis_Distance (Other_Row, Wide_Icovar);
      begin
         pragma Unreferenced (Value);
      end Check_Icovar_Shape;

      procedure Check_Icovar_Dimension is
         Value : constant Long_Float :=
           Row.Mahalanobis_Distance (Other_Row, Large_Icovar);
      begin
         pragma Unreferenced (Value);
      end Check_Icovar_Dimension;
   begin
      Fill_1x2 (Row, 1.0, 2.0);
      Fill_1x2 (Other_Row, 4.0, 6.0);

      Assert_Raises_OpenCV_Error
        (Check_Default_Self'Access,
         "Mahalanobis_Distance must reject a default empty Self");
      Assert_Raises_OpenCV_Error
        (Check_Default_Other'Access,
         "Mahalanobis_Distance must reject a default empty Other");
      Assert_Raises_OpenCV_Error
        (Check_Empty_Vector'Access,
         "Mahalanobis_Distance must reject a typed empty vector");
      Assert_Raises_OpenCV_Error
        (Check_Length'Access,
         "Mahalanobis_Distance must reject mismatched vector lengths");
      Assert_Raises_OpenCV_Error
        (Check_Row_Versus_Column'Access,
         "Mahalanobis_Distance must reject a row vector against a column");
      Assert_Raises_OpenCV_Error
        (Check_Depth'Access,
         "Mahalanobis_Distance must reject mixed Float32 and Float64 vectors");
      Assert_Raises_OpenCV_Error
        (Check_UInt8'Access, "Mahalanobis_Distance must reject UInt8 vectors");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access, "Mahalanobis_Distance must reject Int32 vectors");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access,
         "Mahalanobis_Distance must reject Float16 vectors");
      Assert_Raises_OpenCV_Error
        (Check_Channels'Access,
         "Mahalanobis_Distance must reject multi-channel vectors");
      Assert_Raises_OpenCV_Error
        (Check_Matrix_As_Vector'Access,
         "Mahalanobis_Distance must reject an arbitrary 2x2 matrix as a"
         & " vector");
      Assert_Raises_OpenCV_Error
        (Check_Empty_Icovar'Access,
         "Mahalanobis_Distance must reject an empty Inverse_Covariance");
      Assert_Raises_OpenCV_Error
        (Check_Default_Icovar'Access,
         "Mahalanobis_Distance must reject a default empty"
         & " Inverse_Covariance");
      Assert_Raises_OpenCV_Error
        (Check_Icovar_Depth'Access,
         "Mahalanobis_Distance must reject Inverse_Covariance of the wrong"
         & " depth");
      Assert_Raises_OpenCV_Error
        (Check_Icovar_Channels'Access,
         "Mahalanobis_Distance must reject a multi-channel"
         & " Inverse_Covariance");
      Assert_Raises_OpenCV_Error
        (Check_Icovar_Shape'Access,
         "Mahalanobis_Distance must reject a non-square Inverse_Covariance");
      Assert_Raises_OpenCV_Error
        (Check_Icovar_Dimension'Access,
         "Mahalanobis_Distance must reject a square Inverse_Covariance of the"
         & " wrong dimension");
   end Mahalanobis_Distance_Rejects_Invalid_Inputs;

   procedure Fill_3x1
     (Image : in out OpenCV.Core.Mat; A, B, C : OpenCV.Core.Float32_Value) is
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, A);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, B);
      OpenCV.Core.Float32_Access.Set (Image, 2, 0, C);
   end Fill_3x1;

   function Unchanged_3x1
     (Image : OpenCV.Core.Mat; A, B, C : OpenCV.Core.Float32_Value)
      return Boolean
   is (OpenCV.Core.Float32_Access.Get (Image, 0, 0) = A
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 0) = B
       and then OpenCV.Core.Float32_Access.Get (Image, 2, 0) = C);

   procedure Fill_1x3
     (Image : in out OpenCV.Core.Mat; A, B, C : OpenCV.Core.Float32_Value) is
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, A);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, B);
      OpenCV.Core.Float32_Access.Set (Image, 0, 2, C);
   end Fill_1x3;

   function Unchanged_1x3
     (Image : OpenCV.Core.Mat; A, B, C : OpenCV.Core.Float32_Value)
      return Boolean
   is (OpenCV.Core.Float32_Access.Get (Image, 0, 0) = A
       and then OpenCV.Core.Float32_Access.Get (Image, 0, 1) = B
       and then OpenCV.Core.Float32_Access.Get (Image, 0, 2) = C);

   procedure Cross_Product_Basic_Float32_3x1 (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Self   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Other  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_3x1 (Self, 1.0, 0.0, 0.0);
      Fill_3x1 (Other, 0.0, 1.0, 0.0);
      Result := Self.Cross_Product (Other);

      AUnit.Assertions.Assert
        (Result.Rows = 3
         and then Result.Columns = 1
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 1
         and then Unchanged_3x1 (Result, 0.0, 0.0, 1.0),
         "Float32 3x1 Cross_Product of (1,0,0) and (0,1,0) must be (0,0,1)");
      AUnit.Assertions.Assert
        (Unchanged_3x1 (Self, 1.0, 0.0, 0.0)
         and then Unchanged_3x1 (Other, 0.0, 1.0, 0.0),
         "Cross_Product must not modify its operands");
   end Cross_Product_Basic_Float32_3x1;

   procedure Cross_Product_Operand_Order (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Self   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Other  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_3x1 (Self, 1.0, 0.0, 0.0);
      Fill_3x1 (Other, 0.0, 1.0, 0.0);
      Result := Other.Cross_Product (Self);

      AUnit.Assertions.Assert
        (Unchanged_3x1 (Result, 0.0, 0.0, -1.0),
         "Reversing Cross_Product operands must negate the result");
   end Cross_Product_Operand_Order;

   procedure Cross_Product_General_Values (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Self   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Other  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_3x1 (Self, 1.0, 2.0, 3.0);
      Fill_3x1 (Other, 4.0, 5.0, 6.0);
      Result := Self.Cross_Product (Other);

      AUnit.Assertions.Assert
        (Unchanged_3x1 (Result, -3.0, 6.0, -3.0),
         "Cross_Product of (1,2,3) and (4,5,6) must be (-3,6,-3)");
   end Cross_Product_General_Values;

   procedure Cross_Product_Float32_1x3 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Self   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Other  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_1x3 (Self, 1.0, 2.0, 3.0);
      Fill_1x3 (Other, 4.0, 5.0, 6.0);
      Result := Self.Cross_Product (Other);

      AUnit.Assertions.Assert
        (Result.Rows = 1
         and then Result.Columns = 3
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 1
         and then Unchanged_1x3 (Result, -3.0, 6.0, -3.0),
         "Float32 1x3 Cross_Product must preserve shape and compute"
         & " (-3,6,-3)");
   end Cross_Product_Float32_1x3;

   procedure Cross_Product_Float32_1x1_C3 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Self   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 3));
      Other  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 3));
      Result : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set (Self, 0, 0, (1.0, 2.0, 3.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Other, 0, 0, (4.0, 5.0, 6.0));
      Result := Self.Cross_Product (Other);

      AUnit.Assertions.Assert
        (Result.Rows = 1
         and then Result.Columns = 1
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 3
         and then OpenCV.Core.Float32_Vec3_Access.Get (Result, 0, 0)
                  = (-3.0, 6.0, -3.0),
         "Float32 1x1 C3 Cross_Product must preserve shape and compute"
         & " (-3,6,-3)");
   end Cross_Product_Float32_1x1_C3;

   procedure Cross_Product_Supports_Float64 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Base_32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Unit_32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Other   : OpenCV.Core.Mat;
      Self    : OpenCV.Core.Mat;
      Result  : OpenCV.Core.Mat;
   begin
      --  2**24 is exact in both Float32 and Float64. 2**24+1 is exact
      --  only in Float64; a Float32-only path would collapse
      --  (2**24+1, 0, 0) x (0, 1, 0) to (0, 0, 2**24).
      Fill_3x1 (Base_32, 16_777_216.0, 0.0, 0.0);
      Fill_3x1 (Unit_32, 1.0, 0.0, 0.0);
      Self :=
        Base_32.Convert_To (OpenCV.Core.Float64).Add
          (Unit_32.Convert_To (OpenCV.Core.Float64));
      Fill_3x1 (Unit_32, 0.0, 1.0, 0.0);
      Other := Unit_32.Convert_To (OpenCV.Core.Float64);
      Result := Self.Cross_Product (Other);

      AUnit.Assertions.Assert
        (Result.Depth = OpenCV.Core.Float64
         and then Result.Rows = 3
         and then Result.Columns = 1
         and then Result.Channels = 1
         and then Result.Sum.Component_0 = 16_777_217.0,
         "Float64 Cross_Product must preserve 2**24+1 versus 2**24");
   end Cross_Product_Supports_Float64;

   procedure Cross_Product_Noncontiguous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent_Self  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Parent_Other : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Result       : OpenCV.Core.Mat;
   begin
      Parent_Self.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Parent_Other.Set_To (OpenCV.Core.Make_Scalar (88.0));

      declare
         Self  : OpenCV.Core.Mat :=
           Parent_Self.Region ((X => 1, Y => 0, Width => 1, Height => 3));
         Other : OpenCV.Core.Mat :=
           Parent_Other.Region ((X => 1, Y => 0, Width => 1, Height => 3));
      begin
         Fill_3x1 (Self, 1.0, 2.0, 3.0);
         Fill_3x1 (Other, 4.0, 5.0, 6.0);
         AUnit.Assertions.Assert
           (not Self.Is_Continuous and then not Other.Is_Continuous,
            "The Regions used for Cross_Product must be non-contiguous");
         Result := Self.Cross_Product (Other);
         AUnit.Assertions.Assert
           (Result.Rows = 3
            and then Result.Columns = 1
            and then Unchanged_3x1 (Result, -3.0, 6.0, -3.0),
            "Cross_Product must honor non-contiguous 3x1 Regions");
         AUnit.Assertions.Assert
           (Unchanged_3x1 (Self, 1.0, 2.0, 3.0)
            and then Unchanged_3x1 (Other, 4.0, 5.0, 6.0)
            and then OpenCV.Core.Float32_Access.Get (Parent_Self, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent_Self, 0, 2) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent_Other, 0, 0) = 88.0
            and then OpenCV.Core.Float32_Access.Get (Parent_Other, 2, 2)
                     = 88.0,
            "Cross_Product must not modify the Regions or their parents");
      end;
   end Cross_Product_Noncontiguous_Region;

   procedure Cross_Product_Result_Owns_Independent_Storage
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Self   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Other  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_3x1 (Self, 1.0, 2.0, 3.0);
      Fill_3x1 (Other, 4.0, 5.0, 6.0);
      Result := Self.Cross_Product (Other);

      OpenCV.Core.Float32_Access.Set (Result, 0, 0, 50.0);
      OpenCV.Core.Float32_Access.Set (Result, 1, 0, 40.0);
      OpenCV.Core.Float32_Access.Set (Result, 2, 0, 30.0);
      AUnit.Assertions.Assert
        (Unchanged_3x1 (Self, 1.0, 2.0, 3.0)
         and then Unchanged_3x1 (Other, 4.0, 5.0, 6.0),
         "Mutating the Cross_Product result must not change either source");
   end Cross_Product_Result_Owns_Independent_Storage;

   procedure Cross_Product_Result_Outlives_Inputs
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Mat;
   begin
      declare
         Self  : OpenCV.Core.Mat :=
           OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
         Other : OpenCV.Core.Mat :=
           OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      begin
         Fill_3x1 (Self, 1.0, 2.0, 3.0);
         Fill_3x1 (Other, 4.0, 5.0, 6.0);
         Result := Self.Cross_Product (Other);
      end;

      AUnit.Assertions.Assert
        (Unchanged_3x1 (Result, -3.0, 6.0, -3.0),
         "Cross_Product result must remain valid after its sources finalize");
   end Cross_Product_Result_Outlives_Inputs;

   procedure Cross_Product_Rejects_Invalid_Inputs
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Valid          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Default_Empty  : OpenCV.Core.Mat;
      Empty32        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Row            : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Float64_Column : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float64, 1));
      C3_Column      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 3));
      UInt8_Image    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.UInt8, 1));
      Int32_Image    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Int32, 1));
      Float16_Image  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float16, 1));
      One_By_Two     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      One_By_Four    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
      Two_By_Two     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      One_By_One     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      One_By_Two_C2  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 2));

      procedure Check_Default_Self is
         Result : constant OpenCV.Core.Mat :=
           Default_Empty.Cross_Product (Valid);
      begin
         pragma Unreferenced (Result);
      end Check_Default_Self;

      procedure Check_Default_Other is
         Result : constant OpenCV.Core.Mat :=
           Valid.Cross_Product (Default_Empty);
      begin
         pragma Unreferenced (Result);
      end Check_Default_Other;

      procedure Check_Empty32 is
         Result : constant OpenCV.Core.Mat := Empty32.Cross_Product (Empty32);
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;

      procedure Check_Shape is
         Result : constant OpenCV.Core.Mat :=
           Valid.Cross_Product
             (OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1)));
      begin
         pragma Unreferenced (Result);
      end Check_Shape;

      procedure Check_Depth is
         Result : constant OpenCV.Core.Mat :=
           Valid.Cross_Product (Float64_Column);
      begin
         pragma Unreferenced (Result);
      end Check_Depth;

      procedure Check_Channels is
         Result : constant OpenCV.Core.Mat := Valid.Cross_Product (C3_Column);
      begin
         pragma Unreferenced (Result);
      end Check_Channels;

      procedure Check_UInt8 is
         Result : constant OpenCV.Core.Mat :=
           UInt8_Image.Cross_Product (UInt8_Image);
      begin
         pragma Unreferenced (Result);
      end Check_UInt8;

      procedure Check_Int32 is
         Result : constant OpenCV.Core.Mat :=
           Int32_Image.Cross_Product (Int32_Image);
      begin
         pragma Unreferenced (Result);
      end Check_Int32;

      procedure Check_Float16 is
         Result : constant OpenCV.Core.Mat :=
           Float16_Image.Cross_Product (Float16_Image);
      begin
         pragma Unreferenced (Result);
      end Check_Float16;

      procedure Check_1x2 is
         Result : constant OpenCV.Core.Mat :=
           One_By_Two.Cross_Product (One_By_Two);
      begin
         pragma Unreferenced (Result);
      end Check_1x2;

      procedure Check_1x4 is
         Result : constant OpenCV.Core.Mat :=
           One_By_Four.Cross_Product (One_By_Four);
      begin
         pragma Unreferenced (Result);
      end Check_1x4;

      procedure Check_2x2 is
         Result : constant OpenCV.Core.Mat :=
           Two_By_Two.Cross_Product (Two_By_Two);
      begin
         pragma Unreferenced (Result);
      end Check_2x2;

      procedure Check_1x1 is
         Result : constant OpenCV.Core.Mat :=
           One_By_One.Cross_Product (One_By_One);
      begin
         pragma Unreferenced (Result);
      end Check_1x1;

      procedure Check_1x2_C2 is
         Result : constant OpenCV.Core.Mat :=
           One_By_Two_C2.Cross_Product (One_By_Two_C2);
      begin
         pragma Unreferenced (Result);
      end Check_1x2_C2;

      procedure Check_3x1_C3 is
         Result : constant OpenCV.Core.Mat :=
           C3_Column.Cross_Product (C3_Column);
      begin
         pragma Unreferenced (Result);
      end Check_3x1_C3;

      procedure Check_Column_Versus_Row is
         Result : constant OpenCV.Core.Mat := Valid.Cross_Product (Row);
      begin
         pragma Unreferenced (Result);
      end Check_Column_Versus_Row;
   begin
      Fill_3x1 (Valid, 1.0, 0.0, 0.0);

      Assert_Raises_OpenCV_Error
        (Check_Default_Self'Access,
         "Cross_Product must reject a default empty Self");
      Assert_Raises_OpenCV_Error
        (Check_Default_Other'Access,
         "Cross_Product must reject a default empty Other");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access,
         "Cross_Product must reject a typed empty Float32 Mat");
      Assert_Raises_OpenCV_Error
        (Check_Shape'Access,
         "Cross_Product must reject mismatched Rows and Columns");
      Assert_Raises_OpenCV_Error
        (Check_Depth'Access,
         "Cross_Product must reject mixed Float32 and Float64 operands");
      Assert_Raises_OpenCV_Error
        (Check_Channels'Access,
         "Cross_Product must reject mixed channel counts");
      Assert_Raises_OpenCV_Error
        (Check_UInt8'Access, "Cross_Product must reject UInt8 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access, "Cross_Product must reject Int32 Mats");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access, "Cross_Product must reject Float16 Mats");
      Assert_Raises_OpenCV_Error
        (Check_1x2'Access, "Cross_Product must reject a 1x2 C1 Mat");
      Assert_Raises_OpenCV_Error
        (Check_1x4'Access, "Cross_Product must reject a 1x4 C1 Mat");
      Assert_Raises_OpenCV_Error
        (Check_2x2'Access, "Cross_Product must reject a 2x2 C1 Mat");
      Assert_Raises_OpenCV_Error
        (Check_1x1'Access, "Cross_Product must reject a 1x1 C1 Mat");
      Assert_Raises_OpenCV_Error
        (Check_1x2_C2'Access, "Cross_Product must reject a 1x2 C2 Mat");
      Assert_Raises_OpenCV_Error
        (Check_3x1_C3'Access, "Cross_Product must reject a 3x1 C3 Mat");
      Assert_Raises_OpenCV_Error
        (Check_Column_Versus_Row'Access,
         "Cross_Product must reject a 3x1 C1 Mat against a 1x3 C1 Mat");
   end Cross_Product_Rejects_Invalid_Inputs;

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
   procedure Transposed_Product_Full_Size_Float32_Delta
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Offset : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Fill_2x3 (Offset, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
      Result :=
        Source.Transposed_Product
          (Offset, Order => OpenCV.Core.Transpose_Times_Self);

      AUnit.Assertions.Assert
        (Product_3x3
           (Result, 9.0, 12.0, 15.0, 12.0, 17.0, 22.0, 15.0, 22.0, 29.0),
         "Full-size Delta must subtract element-by-element before the"
         & " transposed product");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Result, 0, 1)
         = OpenCV.Core.Float32_Access.Get (Result, 1, 0)
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 2)
                  = OpenCV.Core.Float32_Access.Get (Result, 2, 0)
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 2)
                  = OpenCV.Core.Float32_Access.Get (Result, 2, 1),
         "Centered Transposed_Product must produce a symmetric result");
      AUnit.Assertions.Assert
        (Unchanged_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0)
         and then Unchanged_2x3 (Offset, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0),
         "Centered Transposed_Product must not modify Self or Delta");
   end Transposed_Product_Full_Size_Float32_Delta;

   procedure Transposed_Product_Row_Vector_Broadcast
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Offset : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      OpenCV.Core.Float32_Access.Set (Offset, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Offset, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Offset, 0, 2, 3.0);
      Result :=
        Source.Transposed_Product
          (Offset, Order => OpenCV.Core.Transpose_Times_Self);

      AUnit.Assertions.Assert
        (Offset.Rows = 1
         and then Offset.Columns = 3
         and then Product_3x3
                    (Result, 9.0, 9.0, 9.0, 9.0, 9.0, 9.0, 9.0, 9.0, 9.0),
         "A 1xN Delta must broadcast across every source row");
      AUnit.Assertions.Assert
        (Unchanged_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0)
         and then OpenCV.Core.Float32_Access.Get (Offset, 0, 0) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Offset, 0, 1) = 2.0
         and then OpenCV.Core.Float32_Access.Get (Offset, 0, 2) = 3.0,
         "Row-vector Delta broadcasting must leave Self and Delta unchanged");
   end Transposed_Product_Row_Vector_Broadcast;

   procedure Transposed_Product_Column_Vector_Broadcast
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Offset : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      OpenCV.Core.Float32_Access.Set (Offset, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Offset, 1, 0, 4.0);
      Result :=
        Source.Transposed_Product
          (Offset, Order => OpenCV.Core.Transpose_Times_Self);

      AUnit.Assertions.Assert
        (Offset.Rows = 2
         and then Offset.Columns = 1
         and then Product_3x3
                    (Result, 0.0, 0.0, 0.0, 0.0, 2.0, 4.0, 0.0, 4.0, 8.0),
         "An Mx1 Delta must broadcast across every source column");
   end Transposed_Product_Column_Vector_Broadcast;

   procedure Transposed_Product_Scalar_Broadcast
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Offset : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      OpenCV.Core.Float32_Access.Set (Offset, 0, 0, 1.0);
      Result :=
        Source.Transposed_Product
          (Offset, Order => OpenCV.Core.Transpose_Times_Self);

      AUnit.Assertions.Assert
        (Offset.Rows = 1
         and then Offset.Columns = 1
         and then Product_3x3
                    (Result,
                     9.0,
                     12.0,
                     15.0,
                     12.0,
                     17.0,
                     22.0,
                     15.0,
                     22.0,
                     29.0),
         "A 1x1 Delta must broadcast across every source element");
   end Transposed_Product_Scalar_Broadcast;

   procedure Transposed_Product_Self_Times_Transpose_With_Delta
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Offset : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Fill_2x3 (Offset, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
      Result :=
        Source.Transposed_Product
          (Offset, Order => OpenCV.Core.Self_Times_Transpose);

      AUnit.Assertions.Assert
        (Product_2x2 (Result, 5.0, 14.0, 14.0, 50.0),
         "Self_Times_Transpose with Delta must compute Scale *"
         & " (Self - Delta) * (Self - Delta)'T");
   end Transposed_Product_Self_Times_Transpose_With_Delta;

   procedure Transposed_Product_Scale_With_Delta
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Offset : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Half   : OpenCV.Core.Mat;
      Neg    : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Fill_2x3 (Offset, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
      Half :=
        Source.Transposed_Product
          (Offset, Order => OpenCV.Core.Transpose_Times_Self, Scale => 0.5);
      Neg :=
        Source.Transposed_Product
          (Offset, Order => OpenCV.Core.Transpose_Times_Self, Scale => -1.0);

      AUnit.Assertions.Assert
        (Product_3x3 (Half, 4.5, 6.0, 7.5, 6.0, 8.5, 11.0, 7.5, 11.0, 14.5),
         "Centered Transposed_Product must apply a fractional Scale");
      AUnit.Assertions.Assert
        (Product_3x3
           (Neg, -9.0, -12.0, -15.0, -12.0, -17.0, -22.0, -15.0, -22.0, -29.0),
         "Centered Transposed_Product must apply a negative Scale");
   end Transposed_Product_Scale_With_Delta;

   procedure Transposed_Product_UInt8_Self_Float32_Delta
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Offset : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 2, 3);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 0, 4);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 1, 5);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 2, 6);
      Fill_2x3 (Offset, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
      Result :=
        Source.Transposed_Product
          (Offset, Order => OpenCV.Core.Transpose_Times_Self);

      AUnit.Assertions.Assert
        (Source.Depth = OpenCV.Core.UInt8
         and then Offset.Depth = OpenCV.Core.Float32
         and then Product_3x3
                    (Result,
                     9.0,
                     12.0,
                     15.0,
                     12.0,
                     17.0,
                     22.0,
                     15.0,
                     22.0,
                     29.0),
         "UInt8 Self with Float32 Delta must promote automatically to"
         & " Float32 without mutating the inputs");
   end Transposed_Product_UInt8_Self_Float32_Delta;

   procedure Transposed_Product_Automatic_Promotion_From_Float64_Delta
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Delta32   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Offset    : OpenCV.Core.Mat;
      Result    : OpenCV.Core.Mat;
      Converted : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Fill_2x3 (Delta32, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
      Offset := Delta32.Convert_To (OpenCV.Core.Float64);
      Result :=
        Source.Transposed_Product
          (Offset, Order => OpenCV.Core.Transpose_Times_Self);
      Converted := Result.Convert_To (OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (Result.Depth = OpenCV.Core.Float64
         and then Source.Depth = OpenCV.Core.Float32
         and then Offset.Depth = OpenCV.Core.Float64
         and then Product_3x3
                    (Converted,
                     9.0,
                     12.0,
                     15.0,
                     12.0,
                     17.0,
                     22.0,
                     15.0,
                     22.0,
                     29.0),
         "A Float64 Delta must promote the automatic result to Float64");
   end Transposed_Product_Automatic_Promotion_From_Float64_Delta;

   procedure Transposed_Product_Int32_Delta (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Delta32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Offset  : OpenCV.Core.Mat;
      Result  : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 2, 3);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 0, 4);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 1, 5);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 2, 6);
      Fill_2x3 (Delta32, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
      Offset := Delta32.Convert_To (OpenCV.Core.Int32);
      Result :=
        Source.Transposed_Product
          (Offset, Order => OpenCV.Core.Transpose_Times_Self);

      AUnit.Assertions.Assert
        (Source.Depth = OpenCV.Core.UInt8
         and then Offset.Depth = OpenCV.Core.Int32
         and then Product_3x3
                    (Result,
                     9.0,
                     12.0,
                     15.0,
                     12.0,
                     17.0,
                     22.0,
                     15.0,
                     22.0,
                     29.0),
         "An Int32 Delta must be accepted and convert to automatic Float32");
   end Transposed_Product_Int32_Delta;

   procedure Transposed_Product_Explicit_Float64_With_Integer_Delta
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Delta32   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Offset    : OpenCV.Core.Mat;
      Result    : OpenCV.Core.Mat;
      Converted : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      OpenCV.Core.Float32_Access.Set (Delta32, 0, 0, 1.0);
      Offset := Delta32.Convert_To (OpenCV.Core.Int16);
      Result :=
        Source.Transposed_Product
          (Offset,
           Order        => OpenCV.Core.Transpose_Times_Self,
           Output_Depth => OpenCV.Core.Float64);
      Converted := Result.Convert_To (OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (Result.Depth = OpenCV.Core.Float64
         and then Offset.Depth = OpenCV.Core.Int16
         and then Product_3x3
                    (Converted,
                     9.0,
                     12.0,
                     15.0,
                     12.0,
                     17.0,
                     22.0,
                     15.0,
                     22.0,
                     29.0),
         "Explicit Float64 must accept an integer Delta and return Float64");
   end Transposed_Product_Explicit_Float64_With_Integer_Delta;

   procedure Transposed_Product_Explicit_Float32_Rejects_Float64_Delta
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Delta32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Offset  : OpenCV.Core.Mat;

      procedure Check_Float64_Delta is
         Result : constant OpenCV.Core.Mat :=
           Source.Transposed_Product
             (Offset,
              Order        => OpenCV.Core.Transpose_Times_Self,
              Output_Depth => OpenCV.Core.Float32);
      begin
         pragma Unreferenced (Result);
      end Check_Float64_Delta;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      OpenCV.Core.Float32_Access.Set (Delta32, 0, 0, 1.0);
      Offset := Delta32.Convert_To (OpenCV.Core.Float64);
      Assert_Raises_OpenCV_Error
        (Check_Float64_Delta'Access,
         "Explicit Float32 must reject a Float64 Delta");
   end Transposed_Product_Explicit_Float32_Rejects_Float64_Delta;

   procedure Transposed_Product_Rejects_Float16_Delta
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Offset : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float16, 1));

      procedure Check_Float16_Delta is
         Result : constant OpenCV.Core.Mat :=
           Source.Transposed_Product
             (Offset, Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_Float16_Delta;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Assert_Raises_OpenCV_Error
        (Check_Float16_Delta'Access,
         "Centered Transposed_Product must reject Float16 Delta");
   end Transposed_Product_Rejects_Float16_Delta;

   procedure Transposed_Product_Rejects_Multi_Channel_Delta
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Offset : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 2));

      procedure Check_Two_Channel_Delta is
         Result : constant OpenCV.Core.Mat :=
           Source.Transposed_Product
             (Offset, Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_Two_Channel_Delta;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Assert_Raises_OpenCV_Error
        (Check_Two_Channel_Delta'Access,
         "Centered Transposed_Product must reject a multi-channel Delta");
   end Transposed_Product_Rejects_Multi_Channel_Delta;

   procedure Transposed_Product_Rejects_Invalid_Delta_Shapes
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Delta_22 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Delta_33 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Delta_31 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Delta_12 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));

      procedure Check_2x2 is
         Result : constant OpenCV.Core.Mat :=
           Source.Transposed_Product
             (Delta_22, Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_2x2;

      procedure Check_3x3 is
         Result : constant OpenCV.Core.Mat :=
           Source.Transposed_Product
             (Delta_33, Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_3x3;

      procedure Check_3x1 is
         Result : constant OpenCV.Core.Mat :=
           Source.Transposed_Product
             (Delta_31, Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_3x1;

      procedure Check_1x2 is
         Result : constant OpenCV.Core.Mat :=
           Source.Transposed_Product
             (Delta_12, Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_1x2;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Assert_Raises_OpenCV_Error
        (Check_2x2'Access,
         "Centered Transposed_Product must reject a 2x2 Delta for a 2x3"
         & " source");
      Assert_Raises_OpenCV_Error
        (Check_3x3'Access,
         "Centered Transposed_Product must reject a 3x3 Delta for a 2x3"
         & " source");
      Assert_Raises_OpenCV_Error
        (Check_3x1'Access,
         "Centered Transposed_Product must reject a 3x1 Delta for a 2x3"
         & " source");
      Assert_Raises_OpenCV_Error
        (Check_1x2'Access,
         "Centered Transposed_Product must reject a 1x2 Delta for a 2x3"
         & " source");
   end Transposed_Product_Rejects_Invalid_Delta_Shapes;

   procedure Transposed_Product_Rejects_Empty_Delta
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Default_Empty : OpenCV.Core.Mat;
      Empty32       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Empty64       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float64, 1));

      procedure Check_Default is
         Result : constant OpenCV.Core.Mat :=
           Source.Transposed_Product
             (Default_Empty, Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_Default;

      procedure Check_Empty32 is
         Result : constant OpenCV.Core.Mat :=
           Source.Transposed_Product
             (Empty32, Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;

      procedure Check_Empty64 is
         Result : constant OpenCV.Core.Mat :=
           Source.Transposed_Product
             (Empty64, Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_Empty64;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Assert_Raises_OpenCV_Error
        (Check_Default'Access,
         "Centered Transposed_Product must reject a default empty Delta");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access,
         "Centered Transposed_Product must reject a typed 0x0 Float32"
         & " Delta");
      Assert_Raises_OpenCV_Error
        (Check_Empty64'Access,
         "Centered Transposed_Product must reject a typed 0x0 Float64"
         & " Delta");
   end Transposed_Product_Rejects_Empty_Delta;

   procedure Transposed_Product_With_Delta_Rejects_Invalid_Self
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Offset        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Default_Empty : OpenCV.Core.Mat;
      Int8_Image    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int8, 1));
      Two_Channel   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 2));

      procedure Check_Default is
         Result : constant OpenCV.Core.Mat :=
           Default_Empty.Transposed_Product
             (Offset, Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_Default;

      procedure Check_Int8 is
         Result : constant OpenCV.Core.Mat :=
           Int8_Image.Transposed_Product
             (Offset, Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_Int8;

      procedure Check_Two_Channel is
         Result : constant OpenCV.Core.Mat :=
           Two_Channel.Transposed_Product
             (Offset, Order => OpenCV.Core.Transpose_Times_Self);
      begin
         pragma Unreferenced (Result);
      end Check_Two_Channel;
   begin
      OpenCV.Core.Float32_Access.Set (Offset, 0, 0, 1.0);
      Assert_Raises_OpenCV_Error
        (Check_Default'Access,
         "Centered Transposed_Product must still reject a default empty"
         & " Self");
      Assert_Raises_OpenCV_Error
        (Check_Int8'Access,
         "Centered Transposed_Product must still reject an Int8 Self");
      Assert_Raises_OpenCV_Error
        (Check_Two_Channel'Access,
         "Centered Transposed_Product must still reject a multi-channel"
         & " Self");
   end Transposed_Product_With_Delta_Rejects_Invalid_Self;

   procedure Transposed_Product_Noncontiguous_Full_Delta_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source_Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 5, (OpenCV.Core.Float32, 1));
      Delta_Parent  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 6, (OpenCV.Core.Float32, 1));
      Result        : OpenCV.Core.Mat;
   begin
      Source_Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Delta_Parent.Set_To (OpenCV.Core.Make_Scalar (77.0));

      declare
         Source : OpenCV.Core.Mat :=
           Source_Parent.Region ((X => 1, Y => 0, Width => 3, Height => 2));
         Offset : OpenCV.Core.Mat :=
           Delta_Parent.Region ((X => 2, Y => 1, Width => 3, Height => 2));
      begin
         Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
         Fill_2x3 (Offset, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
         AUnit.Assertions.Assert
           (not Source.Is_Continuous and then not Offset.Is_Continuous,
            "Both Regions used for centered Transposed_Product must be"
            & " non-contiguous");
         Result :=
           Source.Transposed_Product
             (Offset, Order => OpenCV.Core.Transpose_Times_Self);
         AUnit.Assertions.Assert
           (Product_3x3
              (Result, 9.0, 12.0, 15.0, 12.0, 17.0, 22.0, 15.0, 22.0, 29.0),
            "Centered Transposed_Product must honor non-contiguous Self and"
            & " Delta Regions");
         AUnit.Assertions.Assert
           (Unchanged_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0)
            and then Unchanged_2x3 (Offset, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
            and then OpenCV.Core.Float32_Access.Get (Source_Parent, 0, 0)
                     = 99.0
            and then OpenCV.Core.Float32_Access.Get (Source_Parent, 0, 4)
                     = 99.0
            and then OpenCV.Core.Float32_Access.Get (Delta_Parent, 0, 0) = 77.0
            and then OpenCV.Core.Float32_Access.Get (Delta_Parent, 1, 1)
                     = 77.0,
            "Centered Transposed_Product must not modify either Region or"
            & " the parent pixels outside those Regions");
      end;
   end Transposed_Product_Noncontiguous_Full_Delta_Region;

   procedure Transposed_Product_With_Delta_Result_Independence
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Offset : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Fill_2x3 (Offset, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
      Result :=
        Source.Transposed_Product
          (Offset, Order => OpenCV.Core.Transpose_Times_Self);

      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 50.0);
      OpenCV.Core.Float32_Access.Set (Offset, 0, 0, 40.0);
      AUnit.Assertions.Assert
        (Product_3x3
           (Result, 9.0, 12.0, 15.0, 12.0, 17.0, 22.0, 15.0, 22.0, 29.0),
         "Mutating Self or Delta must not change the centered result");
      OpenCV.Core.Float32_Access.Set (Result, 0, 0, 8.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Source, 0, 0) = 50.0
         and then OpenCV.Core.Float32_Access.Get (Offset, 0, 0) = 40.0,
         "Mutating the centered result must not change Self or Delta");
   end Transposed_Product_With_Delta_Result_Independence;

   function Covariance_Mean_1x2
     (Image : OpenCV.Core.Mat; A, B : OpenCV.Core.Float32_Value) return Boolean
   is (Image.Rows = 1
       and then Image.Columns = 2
       and then Image.Depth = OpenCV.Core.Float32
       and then Image.Channels = 1
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 0, 0)),
                   Long_Float (A))
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 0, 1)),
                   Long_Float (B)));

   function Covariance_Mean_2x1
     (Image : OpenCV.Core.Mat; A, B : OpenCV.Core.Float32_Value) return Boolean
   is (Image.Rows = 2
       and then Image.Columns = 1
       and then Image.Depth = OpenCV.Core.Float32
       and then Image.Channels = 1
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 0, 0)),
                   Long_Float (A))
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 1, 0)),
                   Long_Float (B)));

   function Covariance_2x2
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

   procedure Fill_Row_Samples (Image : in out OpenCV.Core.Mat) is
   begin
      Fill_3x2 (Image, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
   end Fill_Row_Samples;

   procedure Fill_Column_Samples (Image : in out OpenCV.Core.Mat) is
   begin
      Fill_2x3 (Image, 1.0, 3.0, 5.0, 2.0, 4.0, 6.0);
   end Fill_Column_Samples;

   procedure Covariance_Float32_Samples_As_Rows
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Covariance_Result;
   begin
      Fill_Row_Samples (Source);
      Result := Source.Covariance;

      AUnit.Assertions.Assert
        (Result.Covariance.Depth = OpenCV.Core.Float32
         and then Result.Mean.Depth = OpenCV.Core.Float32
         and then Covariance_2x2
                    (Result.Covariance,
                     8.0 / 3.0,
                     8.0 / 3.0,
                     8.0 / 3.0,
                     8.0 / 3.0)
         and then Covariance_Mean_1x2 (Result.Mean, 3.0, 4.0),
         "Row samples must produce a 2x2 Float32 covariance and 1x2 mean");
      AUnit.Assertions.Assert
        (Unchanged_3x2 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0),
         "Covariance must not modify its source");
   end Covariance_Float32_Samples_As_Rows;

   procedure Covariance_Float32_Samples_As_Columns
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Covariance_Result;
   begin
      Fill_Column_Samples (Source);
      Result :=
        Source.Covariance (Orientation => OpenCV.Core.Samples_Are_Columns);

      AUnit.Assertions.Assert
        (Result.Covariance.Depth = OpenCV.Core.Float32
         and then Result.Mean.Depth = OpenCV.Core.Float32
         and then Covariance_2x2
                    (Result.Covariance,
                     8.0 / 3.0,
                     8.0 / 3.0,
                     8.0 / 3.0,
                     8.0 / 3.0)
         and then Covariance_Mean_2x1 (Result.Mean, 3.0, 4.0),
         "Column samples must produce a 2x2 Float32 covariance and 2x1 mean");
      AUnit.Assertions.Assert
        (Unchanged_2x3 (Source, 1.0, 3.0, 5.0, 2.0, 4.0, 6.0),
         "Column-oriented Covariance must not modify its source");
   end Covariance_Float32_Samples_As_Columns;

   procedure Covariance_Unscaled_Returns_Raw_Accumulation
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Covariance_Result;
   begin
      Fill_Row_Samples (Source);
      Result := Source.Covariance (Scaling => OpenCV.Core.Unscaled);

      AUnit.Assertions.Assert
        (Covariance_2x2 (Result.Covariance, 8.0, 8.0, 8.0, 8.0)
         and then Covariance_Mean_1x2 (Result.Mean, 3.0, 4.0),
         "Unscaled Covariance must return the raw 1/N-free accumulation");
   end Covariance_Unscaled_Returns_Raw_Accumulation;

   procedure Covariance_Preserves_Float64_Depth
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Source     : OpenCV.Core.Mat;
      Result     : OpenCV.Core.Covariance_Result;
      Covariance : OpenCV.Core.Mat;
      Mean       : OpenCV.Core.Mat;
   begin
      Fill_Row_Samples (Source32);
      OpenCV.Core.Float32_Access.Set (Source32, 0, 0, 1.000_000_1);
      Source := Source32.Convert_To (OpenCV.Core.Float64);
      Result := Source.Covariance;
      Covariance := Result.Covariance.Convert_To (OpenCV.Core.Float32);
      Mean := Result.Mean.Convert_To (OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (Source.Depth = OpenCV.Core.Float64
         and then Result.Covariance.Depth = OpenCV.Core.Float64
         and then Result.Mean.Depth = OpenCV.Core.Float64
         and then Result.Covariance.Rows = 2
         and then Result.Covariance.Columns = 2
         and then Result.Mean.Rows = 1
         and then Result.Mean.Columns = 2
         and then Result.Covariance.Channels = 1
         and then Result.Mean.Channels = 1
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (Mean, 0, 1)),
                     4.0),
         "Float64 Covariance must keep Float64 outputs and the sample mean");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Covariance, 0, 0)),
            Long_Float (OpenCV.Core.Float32_Access.Get (Covariance, 1, 1))),
         "Float64 Covariance must remain a symmetric feature matrix");
   end Covariance_Preserves_Float64_Depth;

   procedure Covariance_Supports_Noncontiguous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Covariance_Result;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      declare
         Source : OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 2, Height => 3));
      begin
         Fill_Row_Samples (Source);
         AUnit.Assertions.Assert
           (not Source.Is_Continuous,
            "The Region used for Covariance must be non-contiguous");
         Result := Source.Covariance;
         AUnit.Assertions.Assert
           (Covariance_2x2
              (Result.Covariance, 8.0 / 3.0, 8.0 / 3.0, 8.0 / 3.0, 8.0 / 3.0)
            and then Covariance_Mean_1x2 (Result.Mean, 3.0, 4.0),
            "Covariance must honor a non-contiguous sample Region");
         AUnit.Assertions.Assert
           (Unchanged_3x2 (Source, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0)
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 3) = 99.0,
            "Covariance must not modify the Region or its parent");
      end;
   end Covariance_Supports_Noncontiguous_Region;

   procedure Covariance_Outputs_Are_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Covariance_Result;
   begin
      Fill_Row_Samples (Source);
      Result := Source.Covariance;

      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 50.0);
      AUnit.Assertions.Assert
        (Covariance_2x2
           (Result.Covariance, 8.0 / 3.0, 8.0 / 3.0, 8.0 / 3.0, 8.0 / 3.0)
         and then Covariance_Mean_1x2 (Result.Mean, 3.0, 4.0),
         "Mutating Self must not change Covariance or Mean");
      OpenCV.Core.Float32_Access.Set (Result.Covariance, 0, 0, 7.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Source, 0, 0) = 50.0
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result.Mean, 0, 0)),
                     3.0),
         "Mutating Covariance must not change Self or Mean");
      OpenCV.Core.Float32_Access.Set (Result.Mean, 0, 0, 9.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Result.Covariance, 0, 0) = 7.0
         and then OpenCV.Core.Float32_Access.Get (Source, 1, 1) = 4.0,
         "Mutating Mean must not change Covariance or Self");
   end Covariance_Outputs_Are_Independent;

   procedure Covariance_Outputs_Outlive_Source (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Covariance_Result;
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      begin
         Fill_Row_Samples (Source);
         Result := Source.Covariance;
      end;

      AUnit.Assertions.Assert
        (Covariance_2x2
           (Result.Covariance, 8.0 / 3.0, 8.0 / 3.0, 8.0 / 3.0, 8.0 / 3.0)
         and then Covariance_Mean_1x2 (Result.Mean, 3.0, 4.0),
         "Covariance outputs must remain valid after the source finalizes");
   end Covariance_Outputs_Outlive_Source;

   procedure Covariance_Orientation_Changes_Output_Dimensions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      As_Rows    : OpenCV.Core.Covariance_Result;
      As_Columns : OpenCV.Core.Covariance_Result;
   begin
      Fill_Row_Samples (Source);
      As_Rows :=
        Source.Covariance (Orientation => OpenCV.Core.Samples_Are_Rows);
      As_Columns :=
        Source.Covariance (Orientation => OpenCV.Core.Samples_Are_Columns);

      AUnit.Assertions.Assert
        (As_Rows.Mean.Rows = 1
         and then As_Rows.Mean.Columns = 2
         and then As_Rows.Covariance.Rows = 2
         and then As_Rows.Covariance.Columns = 2,
         "Samples_Are_Rows must treat columns as features");
      AUnit.Assertions.Assert
        (As_Columns.Mean.Rows = 3
         and then As_Columns.Mean.Columns = 1
         and then As_Columns.Covariance.Rows = 3
         and then As_Columns.Covariance.Columns = 3,
         "Samples_Are_Columns must treat rows as features");
   end Covariance_Orientation_Changes_Output_Dimensions;

   procedure Covariance_Rejects_Empty_Multi_Channel_And_Invalid_Depths
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Empty : OpenCV.Core.Mat;
      Empty32       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      No_Samples    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 2, (OpenCV.Core.Float32, 1));
      Two_Channel   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 2));
      Three_Channel : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 3));
      UInt8_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.UInt8, 1));
      Int32_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Int32, 1));
      Float16_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float16, 1));

      procedure Check_Default is
         Result : constant OpenCV.Core.Covariance_Result :=
           Default_Empty.Covariance;
      begin
         pragma Unreferenced (Result);
      end Check_Default;

      procedure Check_Empty32 is
         Result : constant OpenCV.Core.Covariance_Result := Empty32.Covariance;
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;

      procedure Check_No_Samples is
         Result : constant OpenCV.Core.Covariance_Result :=
           No_Samples.Covariance;
      begin
         pragma Unreferenced (Result);
      end Check_No_Samples;

      procedure Check_Two_Channel is
         Result : constant OpenCV.Core.Covariance_Result :=
           Two_Channel.Covariance;
      begin
         pragma Unreferenced (Result);
      end Check_Two_Channel;

      procedure Check_Three_Channel is
         Result : constant OpenCV.Core.Covariance_Result :=
           Three_Channel.Covariance;
      begin
         pragma Unreferenced (Result);
      end Check_Three_Channel;

      procedure Check_UInt8 is
         Result : constant OpenCV.Core.Covariance_Result :=
           UInt8_Image.Covariance;
      begin
         pragma Unreferenced (Result);
      end Check_UInt8;

      procedure Check_Int32 is
         Result : constant OpenCV.Core.Covariance_Result :=
           Int32_Image.Covariance;
      begin
         pragma Unreferenced (Result);
      end Check_Int32;

      procedure Check_Float16 is
         Result : constant OpenCV.Core.Covariance_Result :=
           Float16_Image.Covariance;
      begin
         pragma Unreferenced (Result);
      end Check_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Check_Default'Access, "Covariance must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access, "Covariance must reject a typed empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_No_Samples'Access,
         "Covariance must reject a Mat with no samples");
      Assert_Raises_OpenCV_Error
        (Check_Two_Channel'Access, "Covariance must reject C2 input");
      Assert_Raises_OpenCV_Error
        (Check_Three_Channel'Access, "Covariance must reject C3 input");
      Assert_Raises_OpenCV_Error
        (Check_UInt8'Access, "Covariance must reject UInt8 input");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access, "Covariance must reject Int32 input");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access, "Covariance must reject Float16 input");
   end Covariance_Rejects_Empty_Multi_Channel_And_Invalid_Depths;

   function Eigenvalue_At
     (Values : OpenCV.Core.Mat; Row : Natural) return Long_Float
   is (Long_Float (OpenCV.Core.Float32_Access.Get (Values, Row, 0)));

   function Eigenvector_Component
     (Vectors : OpenCV.Core.Mat; Row, Column : Natural) return Long_Float
   is (Long_Float (OpenCV.Core.Float32_Access.Get (Vectors, Row, Column)));

   function Satisfies_Eigen_Equation
     (Source : OpenCV.Core.Mat;
      Result : OpenCV.Core.Eigen_Decomposition_Result;
      Index  : OpenCV.Core.Size_Coordinate) return Boolean
   is
      Vector : constant OpenCV.Core.Mat :=
        Result.Eigenvectors.Row_View (Index);
      Left   : constant OpenCV.Core.Mat :=
        Source.Matrix_Multiply (Vector.Transpose);
      Zero   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (Source.Rows, 1, (Source.Depth, Source.Channels));
      Right  : OpenCV.Core.Mat;
   begin
      Zero.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Right :=
        Vector.Transpose.Scale_Add
          (Scale => Eigenvalue_At (Result.Eigenvalues, Integer (Index)),
           Right => Zero);
      return
        Approximately_Equal
          (Left.Abs_Diff (Right).Norm (OpenCV.Core.Infinity), 0.0, 0.000_1);
   end Satisfies_Eigen_Equation;

   function Eigenvectors_Are_Orthonormal
     (Result : OpenCV.Core.Eigen_Decomposition_Result) return Boolean
   is
      First  : constant OpenCV.Core.Mat := Result.Eigenvectors.Row_View (0);
      Second : constant OpenCV.Core.Mat := Result.Eigenvectors.Row_View (1);
   begin
      return
        Approximately_Equal (First.Norm, 1.0, 0.000_1)
        and then Approximately_Equal (Second.Norm, 1.0, 0.000_1)
        and then Approximately_Equal
                   (First.Dot_Product (Second), 0.0, 0.000_1);
   end Eigenvectors_Are_Orthonormal;

   function Eigenvalues_Are_Descending
     (Values : OpenCV.Core.Mat) return Boolean
   is (Eigenvalue_At (Values, 0) >= Eigenvalue_At (Values, 1) - 0.000_001);

   procedure Eigen_Decomposition_Diagonal_Float32
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Eigen_Decomposition_Result;
   begin
      Fill_2x2 (Source, 5.0, 0.0, 0.0, 2.0);
      Result := Source.Eigen_Decomposition;

      AUnit.Assertions.Assert
        (Result.Eigenvalues.Rows = 2
         and then Result.Eigenvalues.Columns = 1
         and then Result.Eigenvectors.Rows = 2
         and then Result.Eigenvectors.Columns = 2
         and then Result.Eigenvalues.Depth = OpenCV.Core.Float32
         and then Result.Eigenvectors.Depth = OpenCV.Core.Float32
         and then Result.Eigenvalues.Channels = 1
         and then Result.Eigenvectors.Channels = 1,
         "Diagonal eigen output must be N x 1 and N x N Float32 C1");
      AUnit.Assertions.Assert
        (Approximately_Equal (Eigenvalue_At (Result.Eigenvalues, 0), 5.0)
         and then Approximately_Equal
                    (Eigenvalue_At (Result.Eigenvalues, 1), 2.0)
         and then Eigenvalues_Are_Descending (Result.Eigenvalues),
         "Diagonal eigenvalues must be 5 then 2 in descending order");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (abs Eigenvector_Component (Result.Eigenvectors, 0, 0), 1.0)
         and then Approximately_Equal
                    (Eigenvector_Component (Result.Eigenvectors, 0, 1), 0.0)
         and then Approximately_Equal
                    (Eigenvector_Component (Result.Eigenvectors, 1, 0), 0.0)
         and then Approximately_Equal
                    (abs Eigenvector_Component (Result.Eigenvectors, 1, 1),
                     1.0),
         "Diagonal eigenvectors must be signed coordinate axes");
      AUnit.Assertions.Assert
        (Unchanged_2x2 (Source, 5.0, 0.0, 0.0, 2.0),
         "Eigen_Decomposition must not modify its source");
   end Eigen_Decomposition_Diagonal_Float32;

   procedure Eigen_Decomposition_Satisfies_Equation_And_Orthogonality
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Eigen_Decomposition_Result;
   begin
      Fill_2x2 (Source, 2.0, 1.0, 1.0, 2.0);
      Result := Source.Eigen_Decomposition;

      AUnit.Assertions.Assert
        (Approximately_Equal (Eigenvalue_At (Result.Eigenvalues, 0), 3.0)
         and then Approximately_Equal
                    (Eigenvalue_At (Result.Eigenvalues, 1), 1.0),
         "The nontrivial symmetric matrix must have eigenvalues 3 and 1");
      AUnit.Assertions.Assert
        (Satisfies_Eigen_Equation (Source, Result, 0)
         and then Satisfies_Eigen_Equation (Source, Result, 1),
         "Each returned pair must satisfy A * v = lambda * v");
      AUnit.Assertions.Assert
        (Eigenvectors_Are_Orthonormal (Result),
         "Distinct eigenvectors must be orthonormal");
   end Eigen_Decomposition_Satisfies_Equation_And_Orthogonality;

   procedure Eigen_Decomposition_Preserves_Float64_Depth
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Source   : OpenCV.Core.Mat;
      Result   : OpenCV.Core.Eigen_Decomposition_Result;
      Values   : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Source32, 2.0, 1.0, 1.0, 2.0);
      Source := Source32.Convert_To (OpenCV.Core.Float64);
      Result := Source.Eigen_Decomposition;
      Values := Result.Eigenvalues.Convert_To (OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (Source.Depth = OpenCV.Core.Float64
         and then Result.Eigenvalues.Depth = OpenCV.Core.Float64
         and then Result.Eigenvectors.Depth = OpenCV.Core.Float64
         and then Result.Eigenvalues.Rows = 2
         and then Result.Eigenvalues.Columns = 1
         and then Result.Eigenvectors.Rows = 2
         and then Result.Eigenvectors.Columns = 2
         and then Result.Eigenvalues.Channels = 1
         and then Result.Eigenvectors.Channels = 1
         and then Approximately_Equal (Eigenvalue_At (Values, 0), 3.0)
         and then Approximately_Equal (Eigenvalue_At (Values, 1), 1.0),
         "Float64 Eigen_Decomposition must keep Float64 outputs");
   end Eigen_Decomposition_Preserves_Float64_Depth;

   procedure Eigen_Decomposition_Supports_Noncontiguous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Eigen_Decomposition_Result;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      declare
         Source : OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 1, Width => 2, Height => 2));
      begin
         Fill_2x2 (Source, 2.0, 1.0, 1.0, 2.0);
         AUnit.Assertions.Assert
           (not Source.Is_Continuous,
            "The Region used for Eigen_Decomposition must be non-contiguous");
         Result := Source.Eigen_Decomposition;
         AUnit.Assertions.Assert
           (Approximately_Equal (Eigenvalue_At (Result.Eigenvalues, 0), 3.0)
            and then Approximately_Equal
                       (Eigenvalue_At (Result.Eigenvalues, 1), 1.0)
            and then Satisfies_Eigen_Equation (Source, Result, 0)
            and then Satisfies_Eigen_Equation (Source, Result, 1),
            "Eigen_Decomposition must honor a non-contiguous square Region");
         AUnit.Assertions.Assert
           (Unchanged_2x2 (Source, 2.0, 1.0, 1.0, 2.0)
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 3, 3) = 99.0,
            "Eigen_Decomposition must not modify the Region or its parent");
      end;
   end Eigen_Decomposition_Supports_Noncontiguous_Region;

   procedure Eigen_Decomposition_Outputs_Are_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Eigen_Decomposition_Result;
   begin
      Fill_2x2 (Source, 5.0, 0.0, 0.0, 2.0);
      Result := Source.Eigen_Decomposition;

      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 50.0);
      AUnit.Assertions.Assert
        (Approximately_Equal (Eigenvalue_At (Result.Eigenvalues, 0), 5.0)
         and then Approximately_Equal
                    (abs Eigenvector_Component (Result.Eigenvectors, 0, 0),
                     1.0),
         "Mutating Self must not change eigenvalues or eigenvectors");
      OpenCV.Core.Float32_Access.Set (Result.Eigenvalues, 0, 0, 7.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Source, 0, 0) = 50.0
         and then Approximately_Equal
                    (abs Eigenvector_Component (Result.Eigenvectors, 0, 0),
                     1.0),
         "Mutating eigenvalues must not change Self or eigenvectors");
      OpenCV.Core.Float32_Access.Set (Result.Eigenvectors, 0, 0, 9.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Result.Eigenvalues, 0, 0) = 7.0
         and then OpenCV.Core.Float32_Access.Get (Source, 1, 1) = 2.0,
         "Mutating eigenvectors must not change eigenvalues or Self");
   end Eigen_Decomposition_Outputs_Are_Independent;

   procedure Eigen_Decomposition_Outputs_Outlive_Source
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Eigen_Decomposition_Result;
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      begin
         Fill_2x2 (Source, 5.0, 0.0, 0.0, 2.0);
         Result := Source.Eigen_Decomposition;
      end;

      AUnit.Assertions.Assert
        (Approximately_Equal (Eigenvalue_At (Result.Eigenvalues, 0), 5.0)
         and then Approximately_Equal
                    (Eigenvalue_At (Result.Eigenvalues, 1), 2.0)
         and then Result.Eigenvectors.Rows = 2
         and then Result.Eigenvectors.Columns = 2,
         "Eigen outputs must remain valid after the source finalizes");
   end Eigen_Decomposition_Outputs_Outlive_Source;

   procedure Eigen_Decomposition_Repeated_Eigenvalues_Remain_Valid
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Eigen_Decomposition_Result;
   begin
      Fill_2x2 (Source, 1.0, 0.0, 0.0, 1.0);
      Result := Source.Eigen_Decomposition;

      AUnit.Assertions.Assert
        (Approximately_Equal (Eigenvalue_At (Result.Eigenvalues, 0), 1.0)
         and then Approximately_Equal
                    (Eigenvalue_At (Result.Eigenvalues, 1), 1.0)
         and then Satisfies_Eigen_Equation (Source, Result, 0)
         and then Satisfies_Eigen_Equation (Source, Result, 1)
         and then Eigenvectors_Are_Orthonormal (Result),
         "Repeated eigenvalues must still yield a valid orthonormal basis");
   end Eigen_Decomposition_Repeated_Eigenvalues_Remain_Valid;

   procedure Eigen_Decomposition_Rejects_Invalid_Input
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Empty : OpenCV.Core.Mat;
      Empty32       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Non_Square    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Two_Channel   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 2));
      UInt8_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Int32_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int32, 1));
      Float16_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float16, 1));

      procedure Check_Default is
         Result : constant OpenCV.Core.Eigen_Decomposition_Result :=
           Default_Empty.Eigen_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_Default;

      procedure Check_Empty32 is
         Result : constant OpenCV.Core.Eigen_Decomposition_Result :=
           Empty32.Eigen_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;

      procedure Check_Non_Square is
         Result : constant OpenCV.Core.Eigen_Decomposition_Result :=
           Non_Square.Eigen_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_Non_Square;

      procedure Check_Two_Channel is
         Result : constant OpenCV.Core.Eigen_Decomposition_Result :=
           Two_Channel.Eigen_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_Two_Channel;

      procedure Check_UInt8 is
         Result : constant OpenCV.Core.Eigen_Decomposition_Result :=
           UInt8_Image.Eigen_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_UInt8;

      procedure Check_Int32 is
         Result : constant OpenCV.Core.Eigen_Decomposition_Result :=
           Int32_Image.Eigen_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_Int32;

      procedure Check_Float16 is
         Result : constant OpenCV.Core.Eigen_Decomposition_Result :=
           Float16_Image.Eigen_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Check_Default'Access,
         "Eigen_Decomposition must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access,
         "Eigen_Decomposition must reject a typed empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Non_Square'Access,
         "Eigen_Decomposition must reject a non-square Mat");
      Assert_Raises_OpenCV_Error
        (Check_Two_Channel'Access, "Eigen_Decomposition must reject C2 input");
      Assert_Raises_OpenCV_Error
        (Check_UInt8'Access, "Eigen_Decomposition must reject UInt8 input");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access, "Eigen_Decomposition must reject Int32 input");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access,
         "Eigen_Decomposition must reject Float16 input");
   end Eigen_Decomposition_Rejects_Invalid_Input;

   procedure Non_Symmetric_Eigen_Upper_Triangular_Float32
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Eigen_Decomposition_Result;
   begin
      Fill_2x2 (Source, 2.0, 1.0, 0.0, 3.0);
      Result := Source.Non_Symmetric_Eigen_Decomposition;

      AUnit.Assertions.Assert
        (Result.Eigenvalues.Rows = 2
         and then Result.Eigenvalues.Columns = 1
         and then Result.Eigenvectors.Rows = 2
         and then Result.Eigenvectors.Columns = 2
         and then Result.Eigenvalues.Depth = OpenCV.Core.Float32
         and then Result.Eigenvectors.Depth = OpenCV.Core.Float32
         and then Satisfies_Eigen_Equation (Source, Result, 0)
         and then Satisfies_Eigen_Equation (Source, Result, 1),
         "Non-symmetric Float32 eigenpairs must have N x 1 / N x N layout"
         & " and satisfy A * v = lambda * v");
      AUnit.Assertions.Assert
        (Approximately_Equal (Eigenvalue_At (Result.Eigenvalues, 0), 3.0)
         and then Approximately_Equal
                    (Eigenvalue_At (Result.Eigenvalues, 1), 2.0)
         and then Unchanged_2x2 (Source, 2.0, 1.0, 0.0, 3.0),
         "Non-symmetric eigen decomposition must preserve its source");
   end Non_Symmetric_Eigen_Upper_Triangular_Float32;

   procedure Non_Symmetric_Eigen_Decomposition_Three_By_Three
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Eigen_Decomposition_Result;
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 4.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 2, 2.0);
      OpenCV.Core.Float32_Access.Set (Source, 1, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Source, 1, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Source, 1, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Source, 2, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Source, 2, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Source, 2, 2, 3.0);
      Result := Source.Non_Symmetric_Eigen_Decomposition;

      AUnit.Assertions.Assert
        (Satisfies_Eigen_Equation (Source, Result, 0)
         and then Satisfies_Eigen_Equation (Source, Result, 1)
         and then Satisfies_Eigen_Equation (Source, Result, 2)
         and then Approximately_Equal
                    (Eigenvalue_At (Result.Eigenvalues, 0), 3.0)
         and then Approximately_Equal
                    (Eigenvalue_At (Result.Eigenvalues, 1), 2.0)
         and then Approximately_Equal
                    (Eigenvalue_At (Result.Eigenvalues, 2), 1.0),
         "Every distinct-real 3x3 non-symmetric eigenpair must be correct");
   end Non_Symmetric_Eigen_Decomposition_Three_By_Three;

   procedure Non_Symmetric_Eigen_Float64_And_Compatibility
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Source      : OpenCV.Core.Mat;
      General     : OpenCV.Core.Eigen_Decomposition_Result;
      Symmetric   : OpenCV.Core.Eigen_Decomposition_Result;
      General32   : OpenCV.Core.Eigen_Decomposition_Result;
      Symmetric32 : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Source32, 2.0, 1.0, 1.0, 2.0);
      Source := Source32.Convert_To (OpenCV.Core.Float64);
      General := Source.Non_Symmetric_Eigen_Decomposition;
      Symmetric := Source.Eigen_Decomposition;
      General32.Eigenvalues :=
        General.Eigenvalues.Convert_To (OpenCV.Core.Float32);
      General32.Eigenvectors :=
        General.Eigenvectors.Convert_To (OpenCV.Core.Float32);
      Symmetric32 := Symmetric.Eigenvalues.Convert_To (OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (General.Eigenvalues.Depth = OpenCV.Core.Float64
         and then General.Eigenvectors.Depth = OpenCV.Core.Float64
         and then Satisfies_Eigen_Equation (Source32, General32, 0)
         and then Satisfies_Eigen_Equation (Source32, General32, 1)
         and then Approximately_Equal
                    (General32.Eigenvalues.Abs_Diff (Symmetric32).Norm
                       (OpenCV.Core.Infinity),
                     0.0,
                     0.000_1),
         "Non-symmetric Float64 output must preserve depth and agree with"
         & " Eigen_Decomposition on symmetric input");
   end Non_Symmetric_Eigen_Float64_And_Compatibility;

   procedure Non_Symmetric_Eigen_Decomposition_Region_And_Ownership
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent                 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
      Result                 : OpenCV.Core.Eigen_Decomposition_Result;
      First_Vector_Component : OpenCV.Core.Float32_Value;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      declare
         Source : OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 1, Width => 2, Height => 2));
      begin
         Fill_2x2 (Source, 2.0, 1.0, 0.0, 3.0);
         Result := Source.Non_Symmetric_Eigen_Decomposition;
         AUnit.Assertions.Assert
           (not Source.Is_Continuous
            and then Satisfies_Eigen_Equation (Source, Result, 0)
            and then Satisfies_Eigen_Equation (Source, Result, 1),
            "Non-symmetric eigen decomposition must support non-contiguous"
            & " Regions");
      end;

      First_Vector_Component :=
        OpenCV.Core.Float32_Access.Get (Result.Eigenvectors, 0, 0);
      OpenCV.Core.Float32_Access.Set (Result.Eigenvalues, 0, 0, 7.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Result.Eigenvectors, 0, 0)
         = First_Vector_Component,
         "Mutating eigenvalues must not change eigenvectors");
      OpenCV.Core.Float32_Access.Set (Result.Eigenvectors, 0, 0, 9.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 1, 1) = 2.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 1, 2) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 2, 1) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 2, 2) = 3.0
         and then OpenCV.Core.Float32_Access.Get (Result.Eigenvalues, 0, 0)
                  = 7.0
         and then OpenCV.Core.Float32_Access.Get (Result.Eigenvectors, 0, 0)
                  = 9.0,
         "Non-symmetric result Mats must outlive Self and not share its"
         & " storage");
   end Non_Symmetric_Eigen_Decomposition_Region_And_Ownership;

   procedure Non_Symmetric_Eigen_Decomposition_Rejects_Invalid_Input
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Empty : OpenCV.Core.Mat;
      Empty32       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Non_Square    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Two_Channel   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 2));
      UInt8_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Int32_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int32, 1));
      Float16_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float16, 1));

      procedure Check_Default is
         Result : constant OpenCV.Core.Eigen_Decomposition_Result :=
           Default_Empty.Non_Symmetric_Eigen_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_Default;
      procedure Check_Empty32 is
         Result : constant OpenCV.Core.Eigen_Decomposition_Result :=
           Empty32.Non_Symmetric_Eigen_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;
      procedure Check_Non_Square is
         Result : constant OpenCV.Core.Eigen_Decomposition_Result :=
           Non_Square.Non_Symmetric_Eigen_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_Non_Square;
      procedure Check_Two_Channel is
         Result : constant OpenCV.Core.Eigen_Decomposition_Result :=
           Two_Channel.Non_Symmetric_Eigen_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_Two_Channel;
      procedure Check_UInt8 is
         Result : constant OpenCV.Core.Eigen_Decomposition_Result :=
           UInt8_Image.Non_Symmetric_Eigen_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_UInt8;
      procedure Check_Int32 is
         Result : constant OpenCV.Core.Eigen_Decomposition_Result :=
           Int32_Image.Non_Symmetric_Eigen_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_Int32;
      procedure Check_Float16 is
         Result : constant OpenCV.Core.Eigen_Decomposition_Result :=
           Float16_Image.Non_Symmetric_Eigen_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Check_Default'Access,
         "Non-symmetric eigen must reject default empty");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access, "Non-symmetric eigen must reject typed empty");
      Assert_Raises_OpenCV_Error
        (Check_Non_Square'Access,
         "Non-symmetric eigen must reject rectangular input");
      Assert_Raises_OpenCV_Error
        (Check_Two_Channel'Access,
         "Non-symmetric eigen must reject multi-channel input");
      Assert_Raises_OpenCV_Error
        (Check_UInt8'Access, "Non-symmetric eigen must reject UInt8 input");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access, "Non-symmetric eigen must reject Int32 input");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access,
         "Non-symmetric eigen must reject Float16 input");
   end Non_Symmetric_Eigen_Decomposition_Rejects_Invalid_Input;

   procedure Fill_PCA_Row_Samples (Image : in out OpenCV.Core.Mat) is
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 1, 5.0);
      OpenCV.Core.Float32_Access.Set (Image, 3, 0, 5.0);
      OpenCV.Core.Float32_Access.Set (Image, 3, 1, 4.0);
   end Fill_PCA_Row_Samples;

   function Unchanged_PCA_Row_Samples (Image : OpenCV.Core.Mat) return Boolean
   is (OpenCV.Core.Float32_Access.Get (Image, 0, 0) = 1.0
       and then OpenCV.Core.Float32_Access.Get (Image, 0, 1) = 2.0
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 0) = 2.0
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 1) = 1.0
       and then OpenCV.Core.Float32_Access.Get (Image, 2, 0) = 4.0
       and then OpenCV.Core.Float32_Access.Get (Image, 2, 1) = 5.0
       and then OpenCV.Core.Float32_Access.Get (Image, 3, 0) = 5.0
       and then OpenCV.Core.Float32_Access.Get (Image, 3, 1) = 4.0);

   function PCA_Mean_1x2
     (Image : OpenCV.Core.Mat; A, B : OpenCV.Core.Float32_Value) return Boolean
   is (Image.Rows = 1
       and then Image.Columns = 2
       and then Image.Depth = OpenCV.Core.Float32
       and then Image.Channels = 1
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 0, 0)),
                   Long_Float (A))
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 0, 1)),
                   Long_Float (B)));

   function PCA_Mean_2x1
     (Image : OpenCV.Core.Mat; A, B : OpenCV.Core.Float32_Value) return Boolean
   is (Image.Rows = 2
       and then Image.Columns = 1
       and then Image.Depth = OpenCV.Core.Float32
       and then Image.Channels = 1
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 0, 0)),
                   Long_Float (A))
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 1, 0)),
                   Long_Float (B)));

   function PCA_Direction_Aligns
     (Vectors : OpenCV.Core.Mat; Row : Natural; X, Y : Long_Float)
      return Boolean
   is
      VX   : constant Long_Float :=
        Long_Float (OpenCV.Core.Float32_Access.Get (Vectors, Row, 0));
      VY   : constant Long_Float :=
        Long_Float (OpenCV.Core.Float32_Access.Get (Vectors, Row, 1));
      Norm : constant Long_Float := Sqrt (X * X + Y * Y);
   begin
      return Approximately_Equal (abs (VX * X + VY * Y) / Norm, 1.0, 0.000_1);
   end PCA_Direction_Aligns;

   procedure Principal_Component_Analysis_Float32_Rows_All_Components
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Principal_Component_Analysis_Result;
   begin
      Fill_PCA_Row_Samples (Source);
      Result := Source.Principal_Component_Analysis;

      AUnit.Assertions.Assert
        (Result.Mean.Rows = 1
         and then Result.Mean.Columns = 2
         and then Result.Eigenvalues.Rows = 2
         and then Result.Eigenvalues.Columns = 1
         and then Result.Eigenvectors.Rows = 2
         and then Result.Eigenvectors.Columns = 2
         and then Result.Mean.Depth = OpenCV.Core.Float32
         and then Result.Eigenvalues.Depth = OpenCV.Core.Float32
         and then Result.Eigenvectors.Depth = OpenCV.Core.Float32
         and then Result.Mean.Channels = 1
         and then Result.Eigenvalues.Channels = 1
         and then Result.Eigenvectors.Channels = 1,
         "Row-sample PCA must return Float32 C1 1x2 / 2x1 / 2x2 outputs");
      AUnit.Assertions.Assert
        (PCA_Mean_1x2 (Result.Mean, 3.0, 3.0),
         "Row-sample PCA mean must be [3, 3]");
      AUnit.Assertions.Assert
        (Approximately_Equal (Eigenvalue_At (Result.Eigenvalues, 0), 4.5)
         and then Approximately_Equal
                    (Eigenvalue_At (Result.Eigenvalues, 1), 0.5)
         and then Eigenvalues_Are_Descending (Result.Eigenvalues),
         "Row-sample PCA eigenvalues must be 4.5 then 0.5");
      AUnit.Assertions.Assert
        (PCA_Direction_Aligns (Result.Eigenvectors, 0, 1.0, 1.0)
         and then PCA_Direction_Aligns (Result.Eigenvectors, 1, 1.0, -1.0),
         "Row-sample PCA directions must match [1,1] and [1,-1] up to sign");
      AUnit.Assertions.Assert
        (Unchanged_PCA_Row_Samples (Source), "PCA must not modify its source");
   end Principal_Component_Analysis_Float32_Rows_All_Components;

   procedure Principal_Component_Analysis_Matches_Covariance_Eigen
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      PCA        : OpenCV.Core.Principal_Component_Analysis_Result;
      Covariance : OpenCV.Core.Covariance_Result;
      Eigen      : OpenCV.Core.Eigen_Decomposition_Result;
   begin
      Fill_PCA_Row_Samples (Source);
      PCA := Source.Principal_Component_Analysis;
      Covariance := Source.Covariance;
      Eigen := Covariance.Covariance.Eigen_Decomposition;

      AUnit.Assertions.Assert
        (PCA_Mean_1x2 (PCA.Mean, 3.0, 3.0)
         and then PCA_Mean_1x2 (Covariance.Mean, 3.0, 3.0),
         "PCA mean must agree with Covariance mean");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Eigenvalue_At (PCA.Eigenvalues, 0),
            Eigenvalue_At (Eigen.Eigenvalues, 0),
            0.000_1)
         and then Approximately_Equal
                    (Eigenvalue_At (PCA.Eigenvalues, 1),
                     Eigenvalue_At (Eigen.Eigenvalues, 1),
                     0.000_1),
         "PCA eigenvalues must agree with Covariance eigen values");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (abs (Eigenvector_Component (PCA.Eigenvectors, 0, 0)
                 * Eigenvector_Component (Eigen.Eigenvectors, 0, 0)
                 + Eigenvector_Component (PCA.Eigenvectors, 0, 1)
                   * Eigenvector_Component (Eigen.Eigenvectors, 0, 1)),
            1.0,
            0.000_1)
         and then Approximately_Equal
                    (abs (Eigenvector_Component (PCA.Eigenvectors, 1, 0)
                          * Eigenvector_Component (Eigen.Eigenvectors, 1, 0)
                          + Eigenvector_Component (PCA.Eigenvectors, 1, 1)
                            * Eigenvector_Component
                                (Eigen.Eigenvectors, 1, 1)),
                     1.0,
                     0.000_1),
         "PCA directions must align with Covariance eigen vectors up to sign");
   end Principal_Component_Analysis_Matches_Covariance_Eigen;

   procedure Principal_Component_Analysis_Truncates_To_One_Component
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Principal_Component_Analysis_Result;
   begin
      Fill_PCA_Row_Samples (Source);
      Result := Source.Principal_Component_Analysis (Components => 1);

      AUnit.Assertions.Assert
        (Result.Mean.Rows = 1
         and then Result.Mean.Columns = 2
         and then Result.Eigenvalues.Rows = 1
         and then Result.Eigenvalues.Columns = 1
         and then Result.Eigenvectors.Rows = 1
         and then Result.Eigenvectors.Columns = 2,
         "Components => 1 must keep the full mean and one principal"
         & " direction");
      AUnit.Assertions.Assert
        (PCA_Mean_1x2 (Result.Mean, 3.0, 3.0)
         and then Approximately_Equal
                    (Eigenvalue_At (Result.Eigenvalues, 0), 4.5)
         and then PCA_Direction_Aligns (Result.Eigenvectors, 0, 1.0, 1.0),
         "The retained component must be the leading 4.5 direction");
   end Principal_Component_Analysis_Truncates_To_One_Component;

   procedure Principal_Component_Analysis_Samples_As_Columns
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Principal_Component_Analysis_Result;
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 2, 4.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 3, 5.0);
      OpenCV.Core.Float32_Access.Set (Source, 1, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Source, 1, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 1, 2, 5.0);
      OpenCV.Core.Float32_Access.Set (Source, 1, 3, 4.0);
      Result :=
        Source.Principal_Component_Analysis
          (Orientation => OpenCV.Core.Samples_Are_Columns);

      AUnit.Assertions.Assert
        (Result.Mean.Rows = 2
         and then Result.Mean.Columns = 1
         and then Result.Eigenvalues.Rows = 2
         and then Result.Eigenvalues.Columns = 1
         and then Result.Eigenvectors.Rows = 2
         and then Result.Eigenvectors.Columns = 2,
         "Column-sample PCA must return 2x1 mean and 2x2 feature directions");
      AUnit.Assertions.Assert
        (PCA_Mean_2x1 (Result.Mean, 3.0, 3.0)
         and then Approximately_Equal
                    (Eigenvalue_At (Result.Eigenvalues, 0), 4.5)
         and then Approximately_Equal
                    (Eigenvalue_At (Result.Eigenvalues, 1), 0.5)
         and then PCA_Direction_Aligns (Result.Eigenvectors, 0, 1.0, 1.0)
         and then PCA_Direction_Aligns (Result.Eigenvectors, 1, 1.0, -1.0),
         "Column-sample PCA must match the transposed row-sample basis");
   end Principal_Component_Analysis_Samples_As_Columns;

   procedure Principal_Component_Analysis_Scrambled_Feature_Space
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Principal_Component_Analysis_Result;
      Vector : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source, 1.0, 2.0, 3.0, 3.0, 2.0, 1.0);
      Result := Source.Principal_Component_Analysis (Components => 1);
      Vector := Result.Eigenvectors.Row_View (0);

      AUnit.Assertions.Assert
        (Result.Mean.Rows = 1
         and then Result.Mean.Columns = 3
         and then Result.Eigenvalues.Rows = 1
         and then Result.Eigenvalues.Columns = 1
         and then Result.Eigenvectors.Rows = 1
         and then Result.Eigenvectors.Columns = 3,
         "Scrambled PCA must still return feature-space 1x3 directions");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Result.Mean, 0, 0)),
            2.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result.Mean, 0, 1)),
                     2.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result.Mean, 0, 2)),
                     2.0),
         "Two-sample three-feature PCA mean must be [2, 2, 2]");
      AUnit.Assertions.Assert
        (Approximately_Equal (Vector.Norm, 1.0, 0.000_1)
         and then Approximately_Equal
                    (abs (Long_Float
                            (OpenCV.Core.Float32_Access.Get
                               (Result.Eigenvectors, 0, 0))
                          * (-1.0 / Sqrt (2.0))
                          + Long_Float
                              (OpenCV.Core.Float32_Access.Get
                                 (Result.Eigenvectors, 0, 2))
                            * (1.0 / Sqrt (2.0))),
                     1.0,
                     0.000_1)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Result.Eigenvectors, 0, 1)),
                     0.0,
                     0.000_1),
         "Leading scrambled-path direction must align with [-1, 0, 1]");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Eigenvalue_At (Result.Eigenvalues, 0), 2.0, 0.000_1),
         "Leading scrambled-path eigenvalue must be 2.0 under 1/N scaling");
   end Principal_Component_Analysis_Scrambled_Feature_Space;

   procedure Principal_Component_Analysis_Supports_Noncontiguous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (5, 4, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Principal_Component_Analysis_Result;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      declare
         Source : OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 2, Height => 4));
      begin
         Fill_PCA_Row_Samples (Source);
         AUnit.Assertions.Assert
           (not Source.Is_Continuous,
            "The Region used for PCA must be non-contiguous");
         Result := Source.Principal_Component_Analysis;
         AUnit.Assertions.Assert
           (PCA_Mean_1x2 (Result.Mean, 3.0, 3.0)
            and then Approximately_Equal
                       (Eigenvalue_At (Result.Eigenvalues, 0), 4.5)
            and then Approximately_Equal
                       (Eigenvalue_At (Result.Eigenvalues, 1), 0.5)
            and then PCA_Direction_Aligns (Result.Eigenvectors, 0, 1.0, 1.0),
            "PCA must honor a non-contiguous sample Region");
         AUnit.Assertions.Assert
           (Unchanged_PCA_Row_Samples (Source)
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 3) = 99.0,
            "PCA must not modify the Region or its parent");
      end;
   end Principal_Component_Analysis_Supports_Noncontiguous_Region;

   procedure Principal_Component_Analysis_Preserves_Float64_Depth
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Source   : OpenCV.Core.Mat;
      Result   : OpenCV.Core.Principal_Component_Analysis_Result;
      Values   : OpenCV.Core.Mat;
   begin
      Fill_PCA_Row_Samples (Source32);
      Source := Source32.Convert_To (OpenCV.Core.Float64);
      Result := Source.Principal_Component_Analysis;
      Values := Result.Eigenvalues.Convert_To (OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (Source.Depth = OpenCV.Core.Float64
         and then Result.Mean.Depth = OpenCV.Core.Float64
         and then Result.Eigenvalues.Depth = OpenCV.Core.Float64
         and then Result.Eigenvectors.Depth = OpenCV.Core.Float64
         and then Result.Mean.Rows = 1
         and then Result.Mean.Columns = 2
         and then Result.Eigenvalues.Rows = 2
         and then Result.Eigenvalues.Columns = 1
         and then Result.Eigenvectors.Rows = 2
         and then Result.Eigenvectors.Columns = 2
         and then Approximately_Equal (Eigenvalue_At (Values, 0), 4.5)
         and then Approximately_Equal (Eigenvalue_At (Values, 1), 0.5),
         "Float64 PCA must keep Float64 outputs");
   end Principal_Component_Analysis_Preserves_Float64_Depth;

   procedure Principal_Component_Analysis_Outputs_Are_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Principal_Component_Analysis_Result;
   begin
      Fill_PCA_Row_Samples (Source);
      Result := Source.Principal_Component_Analysis;

      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 50.0);
      AUnit.Assertions.Assert
        (PCA_Mean_1x2 (Result.Mean, 3.0, 3.0)
         and then Approximately_Equal
                    (Eigenvalue_At (Result.Eigenvalues, 0), 4.5)
         and then PCA_Direction_Aligns (Result.Eigenvectors, 0, 1.0, 1.0),
         "Mutating Self must not change PCA outputs");
      OpenCV.Core.Float32_Access.Set (Result.Mean, 0, 0, 9.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Source, 0, 0) = 50.0
         and then Approximately_Equal
                    (Eigenvalue_At (Result.Eigenvalues, 0), 4.5)
         and then PCA_Direction_Aligns (Result.Eigenvectors, 0, 1.0, 1.0),
         "Mutating Mean must not change Self, eigenvalues, or eigenvectors");
      OpenCV.Core.Float32_Access.Set (Result.Eigenvalues, 0, 0, 7.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Result.Mean, 0, 0) = 9.0
         and then OpenCV.Core.Float32_Access.Get (Source, 1, 1) = 1.0
         and then PCA_Direction_Aligns (Result.Eigenvectors, 0, 1.0, 1.0),
         "Mutating eigenvalues must not change Self, Mean, or eigenvectors");
      OpenCV.Core.Float32_Access.Set (Result.Eigenvectors, 0, 0, 0.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Result.Eigenvalues, 0, 0) = 7.0
         and then OpenCV.Core.Float32_Access.Get (Result.Mean, 0, 1) = 3.0
         and then OpenCV.Core.Float32_Access.Get (Source, 2, 0) = 4.0,
         "Mutating eigenvectors must not change Self, Mean, or eigenvalues");
   end Principal_Component_Analysis_Outputs_Are_Independent;

   procedure Principal_Component_Analysis_Outputs_Outlive_Source
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Principal_Component_Analysis_Result;
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      begin
         Fill_PCA_Row_Samples (Source);
         Result := Source.Principal_Component_Analysis;
      end;

      AUnit.Assertions.Assert
        (PCA_Mean_1x2 (Result.Mean, 3.0, 3.0)
         and then Approximately_Equal
                    (Eigenvalue_At (Result.Eigenvalues, 0), 4.5)
         and then Approximately_Equal
                    (Eigenvalue_At (Result.Eigenvalues, 1), 0.5)
         and then Result.Eigenvectors.Rows = 2
         and then Result.Eigenvectors.Columns = 2,
         "PCA outputs must remain valid after the source finalizes");
   end Principal_Component_Analysis_Outputs_Outlive_Source;

   procedure Principal_Component_Analysis_Allows_Rank_Deficiency
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Principal_Component_Analysis_Result;
   begin
      Fill_3x2 (Source, 1.0, 1.0, 2.0, 2.0, 3.0, 3.0);
      Result := Source.Principal_Component_Analysis;

      AUnit.Assertions.Assert
        (Result.Eigenvalues.Rows = 2
         and then Result.Eigenvalues.Columns = 1
         and then Result.Eigenvectors.Rows = 2
         and then Result.Eigenvectors.Columns = 2
         and then Approximately_Equal
                    (Eigenvalue_At (Result.Eigenvalues, 1), 0.0, 0.000_1),
         "Rank-deficient PCA must succeed and allow a near-zero eigenvalue");
   end Principal_Component_Analysis_Allows_Rank_Deficiency;

   procedure Principal_Component_Analysis_Rejects_Invalid_Input
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Empty : OpenCV.Core.Mat;
      Empty32       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Two_Channel   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 2));
      UInt8_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.UInt8, 1));
      Int32_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Int32, 1));
      Float16_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float16, 1));
      Source        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));

      procedure Check_Default is
         Result : constant OpenCV.Core.Principal_Component_Analysis_Result :=
           Default_Empty.Principal_Component_Analysis;
      begin
         pragma Unreferenced (Result);
      end Check_Default;

      procedure Check_Empty32 is
         Result : constant OpenCV.Core.Principal_Component_Analysis_Result :=
           Empty32.Principal_Component_Analysis;
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;

      procedure Check_Two_Channel is
         Result : constant OpenCV.Core.Principal_Component_Analysis_Result :=
           Two_Channel.Principal_Component_Analysis;
      begin
         pragma Unreferenced (Result);
      end Check_Two_Channel;

      procedure Check_UInt8 is
         Result : constant OpenCV.Core.Principal_Component_Analysis_Result :=
           UInt8_Image.Principal_Component_Analysis;
      begin
         pragma Unreferenced (Result);
      end Check_UInt8;

      procedure Check_Int32 is
         Result : constant OpenCV.Core.Principal_Component_Analysis_Result :=
           Int32_Image.Principal_Component_Analysis;
      begin
         pragma Unreferenced (Result);
      end Check_Int32;

      procedure Check_Float16 is
         Result : constant OpenCV.Core.Principal_Component_Analysis_Result :=
           Float16_Image.Principal_Component_Analysis;
      begin
         pragma Unreferenced (Result);
      end Check_Float16;

      procedure Check_Excess is
         Result : constant OpenCV.Core.Principal_Component_Analysis_Result :=
           Source.Principal_Component_Analysis (Components => 3);
      begin
         pragma Unreferenced (Result);
      end Check_Excess;
   begin
      Fill_PCA_Row_Samples (Source);
      Assert_Raises_OpenCV_Error
        (Check_Default'Access,
         "Principal_Component_Analysis must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access,
         "Principal_Component_Analysis must reject a typed empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Two_Channel'Access,
         "Principal_Component_Analysis must reject C2 input");
      Assert_Raises_OpenCV_Error
        (Check_UInt8'Access,
         "Principal_Component_Analysis must reject UInt8 input");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access,
         "Principal_Component_Analysis must reject Int32 input");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access,
         "Principal_Component_Analysis must reject Float16 input");
      Assert_Raises_OpenCV_Error
        (Check_Excess'Access,
         "Principal_Component_Analysis must reject Components above K_all");
   end Principal_Component_Analysis_Rejects_Invalid_Input;

   procedure Fill_PCA_Retained_Variance_Row_Samples
     (Image : in out OpenCV.Core.Mat) is
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 2, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, -3.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 2, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 2, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 3, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 3, 1, -2.0);
      OpenCV.Core.Float32_Access.Set (Image, 3, 2, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 4, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 4, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 4, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 5, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 5, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 5, 2, -1.0);
   end Fill_PCA_Retained_Variance_Row_Samples;

   procedure Fill_PCA_Retained_Variance_Column_Samples
     (Image : in out OpenCV.Core.Mat) is
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, -3.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 2, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 3, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 4, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 5, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 2, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 3, -2.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 4, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 5, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 2, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 3, 0.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 4, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 5, -1.0);
   end Fill_PCA_Retained_Variance_Column_Samples;

   function Unchanged_PCA_Retained_Variance_Row_Samples
     (Image : OpenCV.Core.Mat) return Boolean
   is (OpenCV.Core.Float32_Access.Get (Image, 0, 0) = 3.0
       and then OpenCV.Core.Float32_Access.Get (Image, 0, 1) = 0.0
       and then OpenCV.Core.Float32_Access.Get (Image, 0, 2) = 0.0
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 0) = -3.0
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 1) = 0.0
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 2) = 0.0
       and then OpenCV.Core.Float32_Access.Get (Image, 2, 0) = 0.0
       and then OpenCV.Core.Float32_Access.Get (Image, 2, 1) = 2.0
       and then OpenCV.Core.Float32_Access.Get (Image, 2, 2) = 0.0
       and then OpenCV.Core.Float32_Access.Get (Image, 3, 0) = 0.0
       and then OpenCV.Core.Float32_Access.Get (Image, 3, 1) = -2.0
       and then OpenCV.Core.Float32_Access.Get (Image, 3, 2) = 0.0
       and then OpenCV.Core.Float32_Access.Get (Image, 4, 0) = 0.0
       and then OpenCV.Core.Float32_Access.Get (Image, 4, 1) = 0.0
       and then OpenCV.Core.Float32_Access.Get (Image, 4, 2) = 1.0
       and then OpenCV.Core.Float32_Access.Get (Image, 5, 0) = 0.0
       and then OpenCV.Core.Float32_Access.Get (Image, 5, 1) = 0.0
       and then OpenCV.Core.Float32_Access.Get (Image, 5, 2) = -1.0);

   function PCA_Zero_Mean_1x3 (Image : OpenCV.Core.Mat) return Boolean
   is (Image.Rows = 1
       and then Image.Columns = 3
       and then Image.Channels = 1
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 0, 0)),
                   0.0)
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 0, 1)),
                   0.0)
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 0, 2)),
                   0.0));

   function PCA_Zero_Mean_3x1 (Image : OpenCV.Core.Mat) return Boolean
   is (Image.Rows = 3
       and then Image.Columns = 1
       and then Image.Channels = 1
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 0, 0)),
                   0.0)
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 1, 0)),
                   0.0)
       and then Approximately_Equal
                  (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 2, 0)),
                   0.0));

   function Two_Leading_Retained_Eigenvalues
     (Values : OpenCV.Core.Mat) return Boolean
   is (Approximately_Equal (Eigenvalue_At (Values, 0), 3.0, 0.000_1)
       and then Approximately_Equal
                  (Eigenvalue_At (Values, 1), 4.0 / 3.0, 0.000_1));

   function Mats_Approximately_Equal
     (Left, Right : OpenCV.Core.Mat; Tolerance : Long_Float := 0.000_1)
      return Boolean;

   procedure Principal_Component_Analysis_Retained_Variance_0_80
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (6, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Principal_Component_Analysis_Result;
   begin
      Fill_PCA_Retained_Variance_Row_Samples (Source);
      Result :=
        Source.Principal_Component_Analysis (Retained_Variance => 0.80);

      AUnit.Assertions.Assert
        (Result.Mean.Rows = 1
         and then Result.Mean.Columns = 3
         and then Result.Eigenvalues.Rows = 2
         and then Result.Eigenvalues.Columns = 1
         and then Result.Eigenvectors.Rows = 2
         and then Result.Eigenvectors.Columns = 3
         and then Result.Mean.Depth = OpenCV.Core.Float32
         and then Result.Eigenvalues.Depth = OpenCV.Core.Float32
         and then Result.Eigenvectors.Depth = OpenCV.Core.Float32,
         "Retained_Variance 0.80 must return a 1x3 mean and two components");
      AUnit.Assertions.Assert
        (PCA_Zero_Mean_1x3 (Result.Mean)
         and then Two_Leading_Retained_Eigenvalues (Result.Eigenvalues),
         "Retained_Variance 0.80 must keep eigenvalues 3 and 4/3");
      AUnit.Assertions.Assert
        (Unchanged_PCA_Retained_Variance_Row_Samples (Source),
         "Retained-variance PCA must leave Self unchanged");
   end Principal_Component_Analysis_Retained_Variance_0_80;

   procedure Principal_Component_Analysis_Retained_Variance_0_95_Quirk
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (6, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Principal_Component_Analysis_Result;
   begin
      Fill_PCA_Retained_Variance_Row_Samples (Source);
      Result :=
        Source.Principal_Component_Analysis (Retained_Variance => 0.95);

      AUnit.Assertions.Assert
        (Result.Eigenvalues.Rows = 2
         and then Result.Eigenvectors.Rows = 2
         and then Two_Leading_Retained_Eigenvalues (Result.Eigenvalues),
         "OpenCV 4.10 retained-variance 0.95 must keep only the first two"
         & " components even though they represent about 13/14 < 0.95");
   end Principal_Component_Analysis_Retained_Variance_0_95_Quirk;

   procedure Principal_Component_Analysis_Retained_Variance_1_0
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (6, 3, (OpenCV.Core.Float32, 1));
      Retained : OpenCV.Core.Principal_Component_Analysis_Result;
      Complete : OpenCV.Core.Principal_Component_Analysis_Result;
   begin
      Fill_PCA_Retained_Variance_Row_Samples (Source);
      Retained :=
        Source.Principal_Component_Analysis (Retained_Variance => 1.0);
      Complete := Source.Principal_Component_Analysis;

      AUnit.Assertions.Assert
        (Retained.Eigenvalues.Rows = 3
         and then Retained.Eigenvectors.Rows = 3
         and then Retained.Eigenvectors.Columns = 3
         and then Approximately_Equal
                    (Eigenvalue_At (Retained.Eigenvalues, 0), 3.0, 0.000_1)
         and then Approximately_Equal
                    (Eigenvalue_At (Retained.Eigenvalues, 1),
                     4.0 / 3.0,
                     0.000_1)
         and then Approximately_Equal
                    (Eigenvalue_At (Retained.Eigenvalues, 2),
                     1.0 / 3.0,
                     0.000_1),
         "Retained_Variance 1.0 must keep every available component");
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (Retained.Mean, Complete.Mean)
         and then Mats_Approximately_Equal
                    (Retained.Eigenvalues, Complete.Eigenvalues)
         and then Mats_Approximately_Equal
                    (Retained.Eigenvectors, Complete.Eigenvectors),
         "Retained_Variance 1.0 must match the all-components PCA result");
   end Principal_Component_Analysis_Retained_Variance_1_0;

   procedure Principal_Component_Analysis_Retained_Variance_Keeps_Two
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (6, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Principal_Component_Analysis_Result;
   begin
      Fill_PCA_Retained_Variance_Row_Samples (Source);
      Result :=
        Source.Principal_Component_Analysis (Retained_Variance => 0.50);

      AUnit.Assertions.Assert
        (Result.Eigenvalues.Rows = 2
         and then Result.Eigenvectors.Rows = 2
         and then Two_Leading_Retained_Eigenvalues (Result.Eigenvalues),
         "OpenCV 4.10 retained-variance PCA must keep at least two"
         & " components");
   end Principal_Component_Analysis_Retained_Variance_Keeps_Two;

   procedure Principal_Component_Analysis_Retained_Variance_Columns
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 6, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Principal_Component_Analysis_Result;
   begin
      Fill_PCA_Retained_Variance_Column_Samples (Source);
      Result :=
        Source.Principal_Component_Analysis
          (Retained_Variance => 0.80,
           Orientation       => OpenCV.Core.Samples_Are_Columns);

      AUnit.Assertions.Assert
        (Result.Mean.Rows = 3
         and then Result.Mean.Columns = 1
         and then Result.Eigenvalues.Rows = 2
         and then Result.Eigenvalues.Columns = 1
         and then Result.Eigenvectors.Rows = 2
         and then Result.Eigenvectors.Columns = 3,
         "Column retained-variance PCA must return 3x1 mean and 2x3"
         & " directions");
      AUnit.Assertions.Assert
        (PCA_Zero_Mean_3x1 (Result.Mean)
         and then Two_Leading_Retained_Eigenvalues (Result.Eigenvalues),
         "Column retained-variance 0.80 must keep eigenvalues 3 and 4/3");
   end Principal_Component_Analysis_Retained_Variance_Columns;

   procedure Principal_Component_Analysis_Retained_Variance_Project
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (6, 3, (OpenCV.Core.Float32, 1));
      Basis          : OpenCV.Core.Principal_Component_Analysis_Result;
      Coordinates    : OpenCV.Core.Mat;
      Reconstruction : OpenCV.Core.Mat;
      Expected_Coord : OpenCV.Core.Mat;
      Expected_Back  : OpenCV.Core.Mat;
   begin
      Fill_PCA_Retained_Variance_Row_Samples (Source);
      Basis := Source.Principal_Component_Analysis (Retained_Variance => 0.80);
      Coordinates := Source.PCA_Project (Basis);
      Reconstruction := Coordinates.PCA_Back_Project (Basis);
      Expected_Coord :=
        Source.Subtract (Basis.Mean.Repeat (6, 1)).Matrix_Multiply
          (Basis.Eigenvectors.Transpose);
      Expected_Back :=
        Coordinates.Matrix_Multiply (Basis.Eigenvectors).Add
          (Basis.Mean.Repeat (6, 1));

      AUnit.Assertions.Assert
        (Coordinates.Rows = 6
         and then Coordinates.Columns = 2
         and then Reconstruction.Rows = 6
         and then Reconstruction.Columns = 3,
         "Two-component retained-variance project/back-project must return"
         & " 6x2 then 6x3");
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (Coordinates, Expected_Coord)
         and then Mats_Approximately_Equal (Reconstruction, Expected_Back),
         "Retained-variance PCA must integrate with PCA_Project and"
         & " PCA_Back_Project");
      AUnit.Assertions.Assert
        (not Mats_Approximately_Equal (Reconstruction, Source, 0.1),
         "Dropped-component reconstruction must not equal the original"
         & " Source");
   end Principal_Component_Analysis_Retained_Variance_Project;

   procedure Principal_Component_Analysis_Retained_Variance_Float64
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (6, 3, (OpenCV.Core.Float32, 1));
      Source   : OpenCV.Core.Mat;
      Result   : OpenCV.Core.Principal_Component_Analysis_Result;
      Values   : OpenCV.Core.Mat;
   begin
      Fill_PCA_Retained_Variance_Row_Samples (Source32);
      Source := Source32.Convert_To (OpenCV.Core.Float64);
      Result :=
        Source.Principal_Component_Analysis (Retained_Variance => 0.80);
      Values := Result.Eigenvalues.Convert_To (OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (Result.Mean.Depth = OpenCV.Core.Float64
         and then Result.Eigenvalues.Depth = OpenCV.Core.Float64
         and then Result.Eigenvectors.Depth = OpenCV.Core.Float64
         and then Result.Mean.Rows = 1
         and then Result.Mean.Columns = 3
         and then Result.Eigenvalues.Rows = 2
         and then Result.Eigenvectors.Rows = 2
         and then Result.Eigenvectors.Columns = 3
         and then Two_Leading_Retained_Eigenvalues (Values),
         "Float64 retained-variance PCA must keep Float64 two-component"
         & " outputs");
   end Principal_Component_Analysis_Retained_Variance_Float64;

   procedure Principal_Component_Analysis_Retained_Variance_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (8, 5, (OpenCV.Core.Float32, 1));
      Contiguous : OpenCV.Core.Mat :=
        OpenCV.Core.Create (6, 3, (OpenCV.Core.Float32, 1));
      Expected   : OpenCV.Core.Principal_Component_Analysis_Result;
      Result     : OpenCV.Core.Principal_Component_Analysis_Result;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Fill_PCA_Retained_Variance_Row_Samples (Contiguous);
      Expected :=
        Contiguous.Principal_Component_Analysis (Retained_Variance => 0.80);
      declare
         Source : OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 1, Width => 3, Height => 6));
      begin
         Fill_PCA_Retained_Variance_Row_Samples (Source);
         AUnit.Assertions.Assert
           (not Source.Is_Continuous,
            "The Region used for retained-variance PCA must be"
            & " non-contiguous");
         Result :=
           Source.Principal_Component_Analysis (Retained_Variance => 0.80);
         AUnit.Assertions.Assert
           (Mats_Approximately_Equal (Result.Mean, Expected.Mean)
            and then Mats_Approximately_Equal
                       (Result.Eigenvalues, Expected.Eigenvalues)
            and then Mats_Approximately_Equal
                       (Result.Eigenvectors, Expected.Eigenvectors),
            "Retained-variance PCA must honor a non-contiguous sample"
            & " Region");
         AUnit.Assertions.Assert
           (Unchanged_PCA_Retained_Variance_Row_Samples (Source)
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 1, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 1, 4) = 99.0,
            "Retained-variance PCA must not modify the Region or its parent");
      end;
   end Principal_Component_Analysis_Retained_Variance_Region;

   procedure Principal_Component_Analysis_Retained_Variance_Ownership
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Principal_Component_Analysis_Result;
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create (6, 3, (OpenCV.Core.Float32, 1));
      begin
         Fill_PCA_Retained_Variance_Row_Samples (Source);
         Result :=
           Source.Principal_Component_Analysis (Retained_Variance => 0.80);
         OpenCV.Core.Float32_Access.Set (Source, 0, 0, 50.0);
         AUnit.Assertions.Assert
           (PCA_Zero_Mean_1x3 (Result.Mean)
            and then Two_Leading_Retained_Eigenvalues (Result.Eigenvalues),
            "Mutating Self must not change retained-variance PCA outputs");
      end;

      AUnit.Assertions.Assert
        (PCA_Zero_Mean_1x3 (Result.Mean)
         and then Two_Leading_Retained_Eigenvalues (Result.Eigenvalues)
         and then Result.Eigenvectors.Rows = 2
         and then Result.Eigenvectors.Columns = 3,
         "Retained-variance PCA outputs must remain valid after the source"
         & " finalizes");
      OpenCV.Core.Float32_Access.Set (Result.Mean, 0, 0, 9.0);
      AUnit.Assertions.Assert
        (Two_Leading_Retained_Eigenvalues (Result.Eigenvalues)
         and then Result.Eigenvectors.Columns = 3,
         "Mutating Mean must not change eigenvalues or eigenvectors");
      OpenCV.Core.Float32_Access.Set (Result.Eigenvalues, 0, 0, 7.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Result.Mean, 0, 0) = 9.0
         and then OpenCV.Core.Float32_Access.Get (Result.Mean, 0, 1) = 0.0,
         "Mutating eigenvalues must not change Mean");
      OpenCV.Core.Float32_Access.Set (Result.Eigenvectors, 0, 0, 0.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Result.Eigenvalues, 0, 0) = 7.0
         and then OpenCV.Core.Float32_Access.Get (Result.Mean, 0, 2) = 0.0,
         "Mutating eigenvectors must not change Mean or eigenvalues");
   end Principal_Component_Analysis_Retained_Variance_Ownership;

   procedure Principal_Component_Analysis_Retained_Variance_Rejects_Range
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (6, 3, (OpenCV.Core.Float32, 1));

      procedure Check_Zero is
         Result : constant OpenCV.Core.Principal_Component_Analysis_Result :=
           Source.Principal_Component_Analysis (Retained_Variance => 0.0);
      begin
         pragma Unreferenced (Result);
      end Check_Zero;

      procedure Check_Negative is
         Result : constant OpenCV.Core.Principal_Component_Analysis_Result :=
           Source.Principal_Component_Analysis (Retained_Variance => -0.1);
      begin
         pragma Unreferenced (Result);
      end Check_Negative;

      procedure Check_Above_One is
         Result : constant OpenCV.Core.Principal_Component_Analysis_Result :=
           Source.Principal_Component_Analysis (Retained_Variance => 1.1);
      begin
         pragma Unreferenced (Result);
      end Check_Above_One;
   begin
      Fill_PCA_Retained_Variance_Row_Samples (Source);
      Assert_Raises_OpenCV_Error
        (Check_Zero'Access, "Retained_Variance 0.0 must raise OpenCV_Error");
      Assert_Raises_OpenCV_Error
        (Check_Negative'Access,
         "Negative Retained_Variance must raise OpenCV_Error");
      Assert_Raises_OpenCV_Error
        (Check_Above_One'Access,
         "Retained_Variance above 1.0 must raise OpenCV_Error");
   end Principal_Component_Analysis_Retained_Variance_Rejects_Range;

   procedure Principal_Component_Analysis_Retained_Variance_Needs_Two
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.Float32, 1));
      Complete : OpenCV.Core.Principal_Component_Analysis_Result;

      procedure Check_Retained is
         Result : constant OpenCV.Core.Principal_Component_Analysis_Result :=
           Source.Principal_Component_Analysis (Retained_Variance => 0.80);
      begin
         pragma Unreferenced (Result);
      end Check_Retained;
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 1, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Source, 2, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Source, 3, 0, 4.0);
      Complete := Source.Principal_Component_Analysis;
      AUnit.Assertions.Assert
        (Complete.Eigenvalues.Rows = 1
         and then Complete.Eigenvectors.Rows = 1
         and then Complete.Eigenvectors.Columns = 1,
         "All-components PCA must still support a one-component source");
      Assert_Raises_OpenCV_Error
        (Check_Retained'Access,
         "Retained_Variance PCA must reject Available_Components = 1");
   end Principal_Component_Analysis_Retained_Variance_Needs_Two;

   procedure Principal_Component_Analysis_Retained_Variance_Rejects_Input
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Empty : OpenCV.Core.Mat;
      Empty32       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Two_Channel   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (6, 3, (OpenCV.Core.Float32, 2));
      UInt8_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (6, 3, (OpenCV.Core.UInt8, 1));
      Int32_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (6, 3, (OpenCV.Core.Int32, 1));
      Float16_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (6, 3, (OpenCV.Core.Float16, 1));

      procedure Check_Default is
         Result : constant OpenCV.Core.Principal_Component_Analysis_Result :=
           Default_Empty.Principal_Component_Analysis
             (Retained_Variance => 0.80);
      begin
         pragma Unreferenced (Result);
      end Check_Default;

      procedure Check_Empty32 is
         Result : constant OpenCV.Core.Principal_Component_Analysis_Result :=
           Empty32.Principal_Component_Analysis (Retained_Variance => 0.80);
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;

      procedure Check_Two_Channel is
         Result : constant OpenCV.Core.Principal_Component_Analysis_Result :=
           Two_Channel.Principal_Component_Analysis
             (Retained_Variance => 0.80);
      begin
         pragma Unreferenced (Result);
      end Check_Two_Channel;

      procedure Check_UInt8 is
         Result : constant OpenCV.Core.Principal_Component_Analysis_Result :=
           UInt8_Image.Principal_Component_Analysis
             (Retained_Variance => 0.80);
      begin
         pragma Unreferenced (Result);
      end Check_UInt8;

      procedure Check_Int32 is
         Result : constant OpenCV.Core.Principal_Component_Analysis_Result :=
           Int32_Image.Principal_Component_Analysis
             (Retained_Variance => 0.80);
      begin
         pragma Unreferenced (Result);
      end Check_Int32;

      procedure Check_Float16 is
         Result : constant OpenCV.Core.Principal_Component_Analysis_Result :=
           Float16_Image.Principal_Component_Analysis
             (Retained_Variance => 0.80);
      begin
         pragma Unreferenced (Result);
      end Check_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Check_Default'Access,
         "Retained_Variance PCA must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access,
         "Retained_Variance PCA must reject a typed empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Two_Channel'Access,
         "Retained_Variance PCA must reject C2 input");
      Assert_Raises_OpenCV_Error
        (Check_UInt8'Access, "Retained_Variance PCA must reject UInt8 input");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access, "Retained_Variance PCA must reject Int32 input");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access,
         "Retained_Variance PCA must reject Float16 input");
   end Principal_Component_Analysis_Retained_Variance_Rejects_Input;

   procedure Fill_PCA_Column_Samples (Image : in out OpenCV.Core.Mat) is
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 2, 4.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 3, 5.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 2, 5.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 3, 4.0);
   end Fill_PCA_Column_Samples;

   function Mats_Approximately_Equal
     (Left, Right : OpenCV.Core.Mat; Tolerance : Long_Float := 0.000_1)
      return Boolean is
   begin
      return
        Left.Rows = Right.Rows
        and then Left.Columns = Right.Columns
        and then Left.Depth = Right.Depth
        and then Left.Channels = Right.Channels
        and then Approximately_Equal
                   (Left.Abs_Diff (Right).Norm (OpenCV.Core.Infinity),
                    0.0,
                    Tolerance);
   end Mats_Approximately_Equal;

   procedure PCA_Project_And_Back_Project_Round_Trip_Rows
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Basis          : OpenCV.Core.Principal_Component_Analysis_Result;
      Coordinates    : OpenCV.Core.Mat;
      Reconstruction : OpenCV.Core.Mat;
   begin
      Fill_PCA_Row_Samples (Source);
      Basis := Source.Principal_Component_Analysis;
      Coordinates := Source.PCA_Project (Basis);
      Reconstruction := Coordinates.PCA_Back_Project (Basis);

      AUnit.Assertions.Assert
        (Coordinates.Rows = 4
         and then Coordinates.Columns = 2
         and then Reconstruction.Rows = 4
         and then Reconstruction.Columns = 2
         and then Coordinates.Depth = Basis.Mean.Depth
         and then Reconstruction.Depth = Basis.Mean.Depth
         and then Coordinates.Channels = 1
         and then Reconstruction.Channels = 1,
         "Full-basis row PCA project/back-project must return 4x2"
         & " basis-depth results");
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (Reconstruction, Source),
         "Full-basis row reconstruction must approximately equal Source");
      AUnit.Assertions.Assert
        (Unchanged_PCA_Row_Samples (Source),
         "PCA_Project and PCA_Back_Project must not modify Source");
   end PCA_Project_And_Back_Project_Round_Trip_Rows;

   procedure PCA_Project_Matches_Row_Formula (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Basis     : OpenCV.Core.Principal_Component_Analysis_Result;
      Centered  : OpenCV.Core.Mat;
      Expected  : OpenCV.Core.Mat;
      Projected : OpenCV.Core.Mat;
   begin
      Fill_PCA_Row_Samples (Source);
      Basis := Source.Principal_Component_Analysis;
      Centered := Source.Subtract (Basis.Mean.Repeat (4, 1));
      Expected := Centered.Matrix_Multiply (Basis.Eigenvectors.Transpose);
      Projected := Source.PCA_Project (Basis);

      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (Projected, Expected),
         "PCA_Project must match (Self - Mean) * Eigenvectors^T");
   end PCA_Project_Matches_Row_Formula;

   procedure PCA_Back_Project_Matches_Row_Formula
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Basis          : OpenCV.Core.Principal_Component_Analysis_Result;
      Coordinates    : OpenCV.Core.Mat;
      Expected       : OpenCV.Core.Mat;
      Reconstruction : OpenCV.Core.Mat;
   begin
      Fill_PCA_Row_Samples (Source);
      Basis := Source.Principal_Component_Analysis;
      Coordinates := Source.PCA_Project (Basis);
      Expected :=
        Coordinates.Matrix_Multiply (Basis.Eigenvectors).Add
          (Basis.Mean.Repeat (4, 1));
      Reconstruction := Coordinates.PCA_Back_Project (Basis);

      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (Reconstruction, Expected),
         "PCA_Back_Project must match Coordinates * Eigenvectors + Mean");
   end PCA_Back_Project_Matches_Row_Formula;

   procedure PCA_Truncated_One_Component_Reconstruction
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Expected       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Basis          : OpenCV.Core.Principal_Component_Analysis_Result;
      Coordinates    : OpenCV.Core.Mat;
      Reconstruction : OpenCV.Core.Mat;
   begin
      Fill_PCA_Row_Samples (Source);
      OpenCV.Core.Float32_Access.Set (Expected, 0, 0, 1.5);
      OpenCV.Core.Float32_Access.Set (Expected, 0, 1, 1.5);
      OpenCV.Core.Float32_Access.Set (Expected, 1, 0, 1.5);
      OpenCV.Core.Float32_Access.Set (Expected, 1, 1, 1.5);
      OpenCV.Core.Float32_Access.Set (Expected, 2, 0, 4.5);
      OpenCV.Core.Float32_Access.Set (Expected, 2, 1, 4.5);
      OpenCV.Core.Float32_Access.Set (Expected, 3, 0, 4.5);
      OpenCV.Core.Float32_Access.Set (Expected, 3, 1, 4.5);
      Basis := Source.Principal_Component_Analysis (Components => 1);
      Coordinates := Source.PCA_Project (Basis);
      Reconstruction := Coordinates.PCA_Back_Project (Basis);

      AUnit.Assertions.Assert
        (Coordinates.Rows = 4
         and then Coordinates.Columns = 1
         and then Reconstruction.Rows = 4
         and then Reconstruction.Columns = 2,
         "One-component project/back-project must return 4x1 then 4x2");
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (Reconstruction, Expected, 0.000_1),
         "One-component reconstruction must collapse pairs onto [1,1]");
      AUnit.Assertions.Assert
        (not Mats_Approximately_Equal (Reconstruction, Source, 0.1),
         "One-component reconstruction must not equal the original Source");
   end PCA_Truncated_One_Component_Reconstruction;

   procedure PCA_Project_Mean_Sample_Is_Zero (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Mean_Sample : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Basis       : OpenCV.Core.Principal_Component_Analysis_Result;
      Projected   : OpenCV.Core.Mat;
   begin
      Fill_PCA_Row_Samples (Source);
      OpenCV.Core.Float32_Access.Set (Mean_Sample, 0, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Mean_Sample, 0, 1, 3.0);
      Basis := Source.Principal_Component_Analysis;
      Projected := Mean_Sample.PCA_Project (Basis);

      AUnit.Assertions.Assert
        (Projected.Rows = 1
         and then Projected.Columns = 2
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Projected, 0, 0)),
                     0.0,
                     0.000_1)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Projected, 0, 1)),
                     0.0,
                     0.000_1),
         "Projecting the mean sample must yield approximately zero");
   end PCA_Project_Mean_Sample_Is_Zero;

   procedure PCA_Project_And_Back_Project_Round_Trip_Columns
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Float32, 1));
      Basis          : OpenCV.Core.Principal_Component_Analysis_Result;
      Coordinates    : OpenCV.Core.Mat;
      Reconstruction : OpenCV.Core.Mat;
   begin
      Fill_PCA_Column_Samples (Source);
      Basis :=
        Source.Principal_Component_Analysis
          (Orientation => OpenCV.Core.Samples_Are_Columns);
      Coordinates :=
        Source.PCA_Project
          (Basis => Basis, Orientation => OpenCV.Core.Samples_Are_Columns);
      Reconstruction :=
        Coordinates.PCA_Back_Project
          (Basis => Basis, Orientation => OpenCV.Core.Samples_Are_Columns);

      AUnit.Assertions.Assert
        (Coordinates.Rows = 2
         and then Coordinates.Columns = 4
         and then Reconstruction.Rows = 2
         and then Reconstruction.Columns = 4,
         "Column PCA project/back-project must return 2x4 then 2x4");
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (Reconstruction, Source),
         "Full-basis column reconstruction must approximately equal Source");
   end PCA_Project_And_Back_Project_Round_Trip_Columns;

   procedure PCA_One_Feature_Column_Orientation
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
      Basis          : OpenCV.Core.Principal_Component_Analysis_Result;
      Coordinates    : OpenCV.Core.Mat;
      Reconstruction : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 3, 4.0);
      Basis :=
        Source.Principal_Component_Analysis
          (Orientation => OpenCV.Core.Samples_Are_Columns);
      AUnit.Assertions.Assert
        (Basis.Mean.Rows = 1 and then Basis.Mean.Columns = 1,
         "One-feature column PCA mean must be the ambiguous 1x1 shape");
      Coordinates :=
        Source.PCA_Project
          (Basis => Basis, Orientation => OpenCV.Core.Samples_Are_Columns);
      Reconstruction :=
        Coordinates.PCA_Back_Project
          (Basis => Basis, Orientation => OpenCV.Core.Samples_Are_Columns);

      AUnit.Assertions.Assert
        (Coordinates.Rows = 1
         and then Coordinates.Columns = 4
         and then Reconstruction.Rows = 1
         and then Reconstruction.Columns = 4,
         "One-feature column project/back-project must keep 1x4 layout");
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (Reconstruction, Source),
         "One-feature column reconstruction must approximately equal Source");
   end PCA_One_Feature_Column_Orientation;

   procedure PCA_Project_Preserves_Float64_Depth
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Source         : OpenCV.Core.Mat;
      Basis          : OpenCV.Core.Principal_Component_Analysis_Result;
      Coordinates    : OpenCV.Core.Mat;
      Reconstruction : OpenCV.Core.Mat;
   begin
      Fill_PCA_Row_Samples (Source32);
      Source := Source32.Convert_To (OpenCV.Core.Float64);
      Basis := Source.Principal_Component_Analysis;
      Coordinates := Source.PCA_Project (Basis);
      Reconstruction := Coordinates.PCA_Back_Project (Basis);

      AUnit.Assertions.Assert
        (Coordinates.Depth = OpenCV.Core.Float64
         and then Reconstruction.Depth = OpenCV.Core.Float64
         and then Coordinates.Rows = 4
         and then Reconstruction.Columns = 2
         and then Mats_Approximately_Equal (Reconstruction, Source, 0.000_001),
         "Float64 PCA project/back-project must keep Float64 results");
   end PCA_Project_Preserves_Float64_Depth;

   procedure PCA_Project_Converts_Input_To_Basis_Depth
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Source64 : OpenCV.Core.Mat;
      Basis32  : OpenCV.Core.Principal_Component_Analysis_Result;
      Basis64  : OpenCV.Core.Principal_Component_Analysis_Result;
      From32   : OpenCV.Core.Mat;
      From64   : OpenCV.Core.Mat;
   begin
      Fill_PCA_Row_Samples (Source32);
      Source64 := Source32.Convert_To (OpenCV.Core.Float64);
      Basis32 := Source32.Principal_Component_Analysis;
      Basis64 := Source64.Principal_Component_Analysis;
      From32 := Source32.PCA_Project (Basis64);
      From64 := Source64.PCA_Project (Basis32);

      AUnit.Assertions.Assert
        (From32.Depth = OpenCV.Core.Float64
         and then From64.Depth = OpenCV.Core.Float32,
         "PCA_Project output depth must follow the PCA basis");
   end PCA_Project_Converts_Input_To_Basis_Depth;

   procedure PCA_Project_Supports_Noncontiguous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (5, 4, (OpenCV.Core.Float32, 1));
      Contiguous : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Basis      : OpenCV.Core.Principal_Component_Analysis_Result;
      Expected   : OpenCV.Core.Mat;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Fill_PCA_Row_Samples (Contiguous);
      Basis := Contiguous.Principal_Component_Analysis;
      Expected := Contiguous.PCA_Project (Basis);
      declare
         Source    : OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 2, Height => 4));
         Projected : OpenCV.Core.Mat;
      begin
         Fill_PCA_Row_Samples (Source);
         AUnit.Assertions.Assert
           (not Source.Is_Continuous,
            "The Region used for PCA_Project must be non-contiguous");
         Projected := Source.PCA_Project (Basis);
         AUnit.Assertions.Assert
           (Mats_Approximately_Equal (Projected, Expected),
            "PCA_Project must honor a non-contiguous sample Region");
         AUnit.Assertions.Assert
           (Unchanged_PCA_Row_Samples (Source)
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 3) = 99.0,
            "PCA_Project must not modify the Region or its parent");
      end;
   end PCA_Project_Supports_Noncontiguous_Region;

   procedure PCA_Project_And_Back_Project_Outputs_Are_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Basis          : OpenCV.Core.Principal_Component_Analysis_Result;
      Coordinates    : OpenCV.Core.Mat;
      Reconstruction : OpenCV.Core.Mat;
      Saved_Coords   : OpenCV.Core.Mat;
      Saved_Recon    : OpenCV.Core.Mat;
   begin
      Fill_PCA_Row_Samples (Source);
      Basis := Source.Principal_Component_Analysis;
      Coordinates := Source.PCA_Project (Basis);
      Reconstruction := Coordinates.PCA_Back_Project (Basis);
      Saved_Coords := Coordinates.Clone;
      Saved_Recon := Reconstruction.Clone;

      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 50.0);
      OpenCV.Core.Float32_Access.Set (Basis.Mean, 0, 0, 9.0);
      OpenCV.Core.Float32_Access.Set (Basis.Eigenvectors, 0, 0, 0.0);
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (Coordinates, Saved_Coords),
         "Mutating Source or Basis must not change a prior projection");

      OpenCV.Core.Float32_Access.Set (Coordinates, 0, 0, 12.0);
      OpenCV.Core.Float32_Access.Set (Basis.Mean, 0, 1, 8.0);
      OpenCV.Core.Float32_Access.Set (Basis.Eigenvectors, 1, 1, 0.0);
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (Reconstruction, Saved_Recon),
         "Mutating coordinates or Basis must not change a prior"
         & " reconstruction");
   end PCA_Project_And_Back_Project_Outputs_Are_Independent;

   procedure PCA_Project_Does_Not_Use_Eigenvalues
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Basis       : OpenCV.Core.Principal_Component_Analysis_Result;
      First       : OpenCV.Core.Mat;
      Second      : OpenCV.Core.Mat;
      First_Back  : OpenCV.Core.Mat;
      Second_Back : OpenCV.Core.Mat;
   begin
      Fill_PCA_Row_Samples (Source);
      Basis := Source.Principal_Component_Analysis;
      First := Source.PCA_Project (Basis);
      First_Back := First.PCA_Back_Project (Basis);
      OpenCV.Core.Float32_Access.Set (Basis.Eigenvalues, 0, 0, 99.0);
      OpenCV.Core.Float32_Access.Set (Basis.Eigenvalues, 1, 0, 77.0);
      Second := Source.PCA_Project (Basis);
      Second_Back := First.PCA_Back_Project (Basis);

      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (First, Second)
         and then Mats_Approximately_Equal (First_Back, Second_Back),
         "Mutating Basis.Eigenvalues must not change project or"
         & " back-project");
   end PCA_Project_Does_Not_Use_Eigenvalues;

   procedure PCA_Project_Rejects_Invalid_Self (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Empty : OpenCV.Core.Mat;
      Empty32       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Two_Channel   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 2));
      UInt8_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.UInt8, 1));
      Int32_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Int32, 1));
      Float16_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float16, 1));
      Source        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Wrong_Rows    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 3, (OpenCV.Core.Float32, 1));
      Wrong_Cols    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 1));
      Basis         : OpenCV.Core.Principal_Component_Analysis_Result;
      Column_Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Float32, 1));
      Column_Basis  : OpenCV.Core.Principal_Component_Analysis_Result;

      procedure Check_Default is
         Result : constant OpenCV.Core.Mat :=
           Default_Empty.PCA_Project (Basis);
      begin
         pragma Unreferenced (Result);
      end Check_Default;

      procedure Check_Empty32 is
         Result : constant OpenCV.Core.Mat := Empty32.PCA_Project (Basis);
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;

      procedure Check_Two_Channel is
         Result : constant OpenCV.Core.Mat := Two_Channel.PCA_Project (Basis);
      begin
         pragma Unreferenced (Result);
      end Check_Two_Channel;

      procedure Check_UInt8 is
         Result : constant OpenCV.Core.Mat := UInt8_Image.PCA_Project (Basis);
      begin
         pragma Unreferenced (Result);
      end Check_UInt8;

      procedure Check_Int32 is
         Result : constant OpenCV.Core.Mat := Int32_Image.PCA_Project (Basis);
      begin
         pragma Unreferenced (Result);
      end Check_Int32;

      procedure Check_Float16 is
         Result : constant OpenCV.Core.Mat :=
           Float16_Image.PCA_Project (Basis);
      begin
         pragma Unreferenced (Result);
      end Check_Float16;

      procedure Check_Wrong_Features_Rows is
         Result : constant OpenCV.Core.Mat := Wrong_Rows.PCA_Project (Basis);
      begin
         pragma Unreferenced (Result);
      end Check_Wrong_Features_Rows;

      procedure Check_Wrong_Features_Columns is
         Result : constant OpenCV.Core.Mat :=
           Wrong_Cols.PCA_Project
             (Basis       => Column_Basis,
              Orientation => OpenCV.Core.Samples_Are_Columns);
      begin
         pragma Unreferenced (Result);
      end Check_Wrong_Features_Columns;
   begin
      Fill_PCA_Row_Samples (Source);
      Fill_PCA_Column_Samples (Column_Source);
      Basis := Source.Principal_Component_Analysis;
      Column_Basis :=
        Column_Source.Principal_Component_Analysis
          (Orientation => OpenCV.Core.Samples_Are_Columns);
      Assert_Raises_OpenCV_Error
        (Check_Default'Access, "PCA_Project must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access, "PCA_Project must reject a typed empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Two_Channel'Access, "PCA_Project must reject C2 input");
      Assert_Raises_OpenCV_Error
        (Check_UInt8'Access, "PCA_Project must reject UInt8 input");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access, "PCA_Project must reject Int32 input");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access, "PCA_Project must reject Float16 input");
      Assert_Raises_OpenCV_Error
        (Check_Wrong_Features_Rows'Access,
         "PCA_Project must reject a wrong row-oriented feature count");
      Assert_Raises_OpenCV_Error
        (Check_Wrong_Features_Columns'Access,
         "PCA_Project must reject a wrong column-oriented feature count");
   end PCA_Project_Rejects_Invalid_Self;

   procedure PCA_Project_Rejects_Invalid_Basis (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Basis  : OpenCV.Core.Principal_Component_Analysis_Result;

      procedure Check_Empty_Mean is
         Local  : OpenCV.Core.Principal_Component_Analysis_Result;
         Result : OpenCV.Core.Mat;
      begin
         Local.Eigenvectors := Basis.Eigenvectors;
         Result := Source.PCA_Project (Local);
         pragma Unreferenced (Result);
      end Check_Empty_Mean;

      procedure Check_Empty_Eigenvectors is
         Local  : OpenCV.Core.Principal_Component_Analysis_Result;
         Result : OpenCV.Core.Mat;
      begin
         Local.Mean := Basis.Mean;
         Result := Source.PCA_Project (Local);
         pragma Unreferenced (Result);
      end Check_Empty_Eigenvectors;

      procedure Check_Mean_Depth is
         Local  : OpenCV.Core.Principal_Component_Analysis_Result := Basis;
         Result : OpenCV.Core.Mat;
      begin
         Local.Mean := OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
         Result := Source.PCA_Project (Local);
         pragma Unreferenced (Result);
      end Check_Mean_Depth;

      procedure Check_Eigenvector_Depth is
         Local  : OpenCV.Core.Principal_Component_Analysis_Result := Basis;
         Result : OpenCV.Core.Mat;
      begin
         Local.Eigenvectors :=
           Basis.Eigenvectors.Convert_To (OpenCV.Core.Float64);
         Result := Source.PCA_Project (Local);
         pragma Unreferenced (Result);
      end Check_Eigenvector_Depth;

      procedure Check_Wrong_Mean_Shape is
         Result : constant OpenCV.Core.Mat :=
           Source.PCA_Project
             (Basis => Basis, Orientation => OpenCV.Core.Samples_Are_Columns);
      begin
         pragma Unreferenced (Result);
      end Check_Wrong_Mean_Shape;

      procedure Check_Zero_Row_Eigenvectors is
         Local  : OpenCV.Core.Principal_Component_Analysis_Result := Basis;
         Result : OpenCV.Core.Mat;
      begin
         Local.Eigenvectors :=
           OpenCV.Core.Create (0, 2, (OpenCV.Core.Float32, 1));
         Result := Source.PCA_Project (Local);
         pragma Unreferenced (Result);
      end Check_Zero_Row_Eigenvectors;
   begin
      Fill_PCA_Row_Samples (Source);
      Basis := Source.Principal_Component_Analysis;
      Assert_Raises_OpenCV_Error
        (Check_Empty_Mean'Access, "PCA_Project must reject an empty Mean");
      Assert_Raises_OpenCV_Error
        (Check_Empty_Eigenvectors'Access,
         "PCA_Project must reject empty Eigenvectors");
      Assert_Raises_OpenCV_Error
        (Check_Mean_Depth'Access,
         "PCA_Project must reject a non-floating Mean");
      Assert_Raises_OpenCV_Error
        (Check_Eigenvector_Depth'Access,
         "PCA_Project must reject Eigenvectors whose depth differs from Mean");
      Assert_Raises_OpenCV_Error
        (Check_Wrong_Mean_Shape'Access,
         "PCA_Project must reject a Mean shape that does not match"
         & " Orientation");
      Assert_Raises_OpenCV_Error
        (Check_Zero_Row_Eigenvectors'Access,
         "PCA_Project must reject zero-row Eigenvectors");
   end PCA_Project_Rejects_Invalid_Basis;

   procedure PCA_Back_Project_Rejects_Invalid_Input
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Empty : OpenCV.Core.Mat;
      Empty32       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Two_Channel   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 2));
      UInt8_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.UInt8, 1));
      Int32_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Int32, 1));
      Float16_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float16, 1));
      Source        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Coordinates   : OpenCV.Core.Mat;
      Wrong_K       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.Float32, 1));
      Basis         : OpenCV.Core.Principal_Component_Analysis_Result;
      Column_Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Float32, 1));
      Column_Basis  : OpenCV.Core.Principal_Component_Analysis_Result;
      Wrong_Col_K   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));

      procedure Check_Default is
         Result : constant OpenCV.Core.Mat :=
           Default_Empty.PCA_Back_Project (Basis);
      begin
         pragma Unreferenced (Result);
      end Check_Default;

      procedure Check_Empty32 is
         Result : constant OpenCV.Core.Mat := Empty32.PCA_Back_Project (Basis);
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;

      procedure Check_Two_Channel is
         Result : constant OpenCV.Core.Mat :=
           Two_Channel.PCA_Back_Project (Basis);
      begin
         pragma Unreferenced (Result);
      end Check_Two_Channel;

      procedure Check_UInt8 is
         Result : constant OpenCV.Core.Mat :=
           UInt8_Image.PCA_Back_Project (Basis);
      begin
         pragma Unreferenced (Result);
      end Check_UInt8;

      procedure Check_Int32 is
         Result : constant OpenCV.Core.Mat :=
           Int32_Image.PCA_Back_Project (Basis);
      begin
         pragma Unreferenced (Result);
      end Check_Int32;

      procedure Check_Float16 is
         Result : constant OpenCV.Core.Mat :=
           Float16_Image.PCA_Back_Project (Basis);
      begin
         pragma Unreferenced (Result);
      end Check_Float16;

      procedure Check_Wrong_Components_Rows is
         Result : constant OpenCV.Core.Mat := Wrong_K.PCA_Back_Project (Basis);
      begin
         pragma Unreferenced (Result);
      end Check_Wrong_Components_Rows;

      procedure Check_Wrong_Components_Columns is
         Result : constant OpenCV.Core.Mat :=
           Wrong_Col_K.PCA_Back_Project
             (Basis       => Column_Basis,
              Orientation => OpenCV.Core.Samples_Are_Columns);
      begin
         pragma Unreferenced (Result);
      end Check_Wrong_Components_Columns;

      procedure Check_Empty_Mean is
         Local  : OpenCV.Core.Principal_Component_Analysis_Result;
         Result : OpenCV.Core.Mat;
      begin
         Local.Eigenvectors := Basis.Eigenvectors;
         Result := Coordinates.PCA_Back_Project (Local);
         pragma Unreferenced (Result);
      end Check_Empty_Mean;

      procedure Check_Wrong_Mean_Shape is
         Result : constant OpenCV.Core.Mat :=
           Coordinates.PCA_Back_Project
             (Basis => Basis, Orientation => OpenCV.Core.Samples_Are_Columns);
      begin
         pragma Unreferenced (Result);
      end Check_Wrong_Mean_Shape;
   begin
      Fill_PCA_Row_Samples (Source);
      Fill_PCA_Column_Samples (Column_Source);
      Basis := Source.Principal_Component_Analysis;
      Column_Basis :=
        Column_Source.Principal_Component_Analysis
          (Orientation => OpenCV.Core.Samples_Are_Columns);
      Coordinates := Source.PCA_Project (Basis);
      Assert_Raises_OpenCV_Error
        (Check_Default'Access,
         "PCA_Back_Project must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access,
         "PCA_Back_Project must reject a typed empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Two_Channel'Access, "PCA_Back_Project must reject C2 input");
      Assert_Raises_OpenCV_Error
        (Check_UInt8'Access, "PCA_Back_Project must reject UInt8 input");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access, "PCA_Back_Project must reject Int32 input");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access, "PCA_Back_Project must reject Float16 input");
      Assert_Raises_OpenCV_Error
        (Check_Wrong_Components_Rows'Access,
         "PCA_Back_Project must reject a wrong row-oriented component count");
      Assert_Raises_OpenCV_Error
        (Check_Wrong_Components_Columns'Access,
         "PCA_Back_Project must reject a wrong column-oriented component"
         & " count");
      Assert_Raises_OpenCV_Error
        (Check_Empty_Mean'Access,
         "PCA_Back_Project must reject an empty Mean");
      Assert_Raises_OpenCV_Error
        (Check_Wrong_Mean_Shape'Access,
         "PCA_Back_Project must reject a Mean shape that does not match"
         & " Orientation");
   end PCA_Back_Project_Rejects_Invalid_Input;

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
      Invalid_Mask      : constant OpenCV.Core.Mat :=
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

   procedure Fill_Tall_SVD_Source (Image : in out OpenCV.Core.Mat) is
   begin
      Fill_3x2 (Image, 3.0, 0.0, 0.0, 2.0, 0.0, 0.0);
   end Fill_Tall_SVD_Source;

   procedure Fill_Wide_SVD_Source (Image : in out OpenCV.Core.Mat) is
   begin
      Fill_2x3 (Image, 3.0, 0.0, 0.0, 0.0, 2.0, 0.0);
   end Fill_Wide_SVD_Source;

   function Singular_Value_At
     (Values : OpenCV.Core.Mat; Row : Natural) return Long_Float
   is (Long_Float (OpenCV.Core.Float32_Access.Get (Values, Row, 0)));

   function Compact_Outputs_Have_Shapes
     (Result                      :
        OpenCV.Core.Singular_Value_Decomposition_Result;
      Source_Rows, Source_Columns : Natural;
      Depth                       : OpenCV.Core.Depth_Type) return Boolean
   is
      Rank : constant Natural :=
        (if Source_Rows < Source_Columns then Source_Rows else Source_Columns);
   begin
      return
        Result.Singular_Values.Rows = Rank
        and then Result.Singular_Values.Columns = 1
        and then Result.U.Rows = Source_Rows
        and then Result.U.Columns = Rank
        and then Result.V_Transpose.Rows = Rank
        and then Result.V_Transpose.Columns = Source_Columns
        and then Result.Singular_Values.Depth = Depth
        and then Result.U.Depth = Depth
        and then Result.V_Transpose.Depth = Depth
        and then Result.Singular_Values.Channels = 1
        and then Result.U.Channels = 1
        and then Result.V_Transpose.Channels = 1;
   end Compact_Outputs_Have_Shapes;

   function SVD_Sigma
     (Singular_Values : OpenCV.Core.Mat) return OpenCV.Core.Mat
   is (OpenCV.Core.Diagonal_Matrix (Singular_Values));

   function Reconstructs_Source
     (Source    : OpenCV.Core.Mat;
      Result    : OpenCV.Core.Singular_Value_Decomposition_Result;
      Tolerance : Long_Float) return Boolean
   is
      Reconstructed : constant OpenCV.Core.Mat :=
        Result.U.Matrix_Multiply (SVD_Sigma (Result.Singular_Values))
          .Matrix_Multiply (Result.V_Transpose);
   begin
      return Mats_Approximately_Equal (Reconstructed, Source, Tolerance);
   end Reconstructs_Source;

   function Compact_Vectors_Are_Orthonormal
     (Result    : OpenCV.Core.Singular_Value_Decomposition_Result;
      Tolerance : Long_Float) return Boolean
   is
      Rank     : constant Natural := Result.Singular_Values.Rows;
      Identity : OpenCV.Core.Mat :=
        OpenCV.Core.Create (Rank, Rank, (Result.Singular_Values.Depth, 1));
      U_Gram   : constant OpenCV.Core.Mat :=
        Result.U.Transpose.Matrix_Multiply (Result.U);
      V_Gram   : constant OpenCV.Core.Mat :=
        Result.V_Transpose.Matrix_Multiply (Result.V_Transpose.Transpose);
   begin
      Identity.Set_Identity;
      return
        Mats_Approximately_Equal (U_Gram, Identity, Tolerance)
        and then Mats_Approximately_Equal (V_Gram, Identity, Tolerance);
   end Compact_Vectors_Are_Orthonormal;

   procedure Singular_Value_Decomposition_Tall_Compact_Shapes
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Singular_Value_Decomposition_Result;
   begin
      Fill_Tall_SVD_Source (Source);
      Result := Source.Singular_Value_Decomposition;

      AUnit.Assertions.Assert
        (Compact_Outputs_Have_Shapes (Result, 3, 2, OpenCV.Core.Float32),
         "Tall compact SVD must return 2x1, 3x2, and 2x2 Float32 C1 outputs");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Singular_Value_At (Result.Singular_Values, 0), 3.0)
         and then Approximately_Equal
                    (Singular_Value_At (Result.Singular_Values, 1), 2.0),
         "Tall compact SVD must return singular values 3 and 2");
      AUnit.Assertions.Assert
        (Unchanged_3x2 (Source, 3.0, 0.0, 0.0, 2.0, 0.0, 0.0),
         "Tall SVD must leave the source unchanged");
   end Singular_Value_Decomposition_Tall_Compact_Shapes;

   procedure Singular_Value_Decomposition_Tall_Reconstruction
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Singular_Value_Decomposition_Result;
   begin
      Fill_Tall_SVD_Source (Source);
      Result := Source.Singular_Value_Decomposition;

      AUnit.Assertions.Assert
        (Reconstructs_Source (Source, Result, 0.000_1),
         "U * diag(W) * V^T must reconstruct the tall source");
   end Singular_Value_Decomposition_Tall_Reconstruction;

   procedure Singular_Value_Decomposition_Wide_Compact_Shapes
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Singular_Value_Decomposition_Result;
   begin
      Fill_Wide_SVD_Source (Source);
      Result := Source.Singular_Value_Decomposition;

      AUnit.Assertions.Assert
        (Compact_Outputs_Have_Shapes (Result, 2, 3, OpenCV.Core.Float32),
         "Wide compact SVD must return 2x1, 2x2, and 2x3 Float32 C1 outputs");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Singular_Value_At (Result.Singular_Values, 0), 3.0)
         and then Approximately_Equal
                    (Singular_Value_At (Result.Singular_Values, 1), 2.0),
         "Wide compact SVD must return singular values 3 and 2");
      AUnit.Assertions.Assert
        (Reconstructs_Source (Source, Result, 0.000_1),
         "U * diag(W) * V^T must reconstruct the wide source");
      AUnit.Assertions.Assert
        (Unchanged_2x3 (Source, 3.0, 0.0, 0.0, 0.0, 2.0, 0.0),
         "Wide SVD must leave the source unchanged");
   end Singular_Value_Decomposition_Wide_Compact_Shapes;

   procedure Singular_Value_Decomposition_Orthonormal_Vectors
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Singular_Value_Decomposition_Result;
   begin
      Fill_Tall_SVD_Source (Source);
      Result := Source.Singular_Value_Decomposition;

      AUnit.Assertions.Assert
        (Compact_Vectors_Are_Orthonormal (Result, 0.000_1),
         "Compact U and V_Transpose must be orthonormal to working precision");
   end Singular_Value_Decomposition_Orthonormal_Vectors;

   procedure Singular_Value_Decomposition_Matches_Eigen_Of_Gram
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Singular_Value_Decomposition_Result;
      Gram   : OpenCV.Core.Mat;
      Eigen  : OpenCV.Core.Eigen_Decomposition_Result;
   begin
      Fill_Tall_SVD_Source (Source);
      Result := Source.Singular_Value_Decomposition;
      Gram := Source.Transpose.Matrix_Multiply (Source);
      Eigen := Gram.Eigen_Decomposition;

      AUnit.Assertions.Assert
        (Approximately_Equal
           (Singular_Value_At (Result.Singular_Values, 0)**2,
            Eigenvalue_At (Eigen.Eigenvalues, 0),
            0.000_1)
         and then Approximately_Equal
                    (Singular_Value_At (Result.Singular_Values, 1)**2,
                     Eigenvalue_At (Eigen.Eigenvalues, 1),
                     0.000_1),
         "Squared SVD singular values must match eigenvalues of A^T * A");
   end Singular_Value_Decomposition_Matches_Eigen_Of_Gram;

   procedure Singular_Value_Decomposition_Rank_Deficient
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Singular_Value_Decomposition_Result;
   begin
      Fill_3x2 (Source, 3.0, 0.0, 0.0, 0.0, 0.0, 0.0);
      Result := Source.Singular_Value_Decomposition;

      AUnit.Assertions.Assert
        (Compact_Outputs_Have_Shapes (Result, 3, 2, OpenCV.Core.Float32),
         "Rank-deficient SVD must still return compact 2x1, 3x2, and 2x2");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Singular_Value_At (Result.Singular_Values, 0), 3.0)
         and then Approximately_Equal
                    (Singular_Value_At (Result.Singular_Values, 1), 0.0),
         "Rank-deficient SVD must return singular values 3 and 0");
      AUnit.Assertions.Assert
        (Reconstructs_Source (Source, Result, 0.000_1),
         "Rank-deficient SVD must still reconstruct the source");
   end Singular_Value_Decomposition_Rank_Deficient;

   procedure Singular_Value_Decomposition_Preserves_Float64
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Source   : OpenCV.Core.Mat;
      Result   : OpenCV.Core.Singular_Value_Decomposition_Result;
      Values   : OpenCV.Core.Mat;
   begin
      Fill_Tall_SVD_Source (Source32);
      Source := Source32.Convert_To (OpenCV.Core.Float64);
      Result := Source.Singular_Value_Decomposition;
      Values := Result.Singular_Values.Convert_To (OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (Source.Depth = OpenCV.Core.Float64
         and then Compact_Outputs_Have_Shapes
                    (Result, 3, 2, OpenCV.Core.Float64),
         "Float64 SVD must keep Float64 compact outputs");
      AUnit.Assertions.Assert
        (Approximately_Equal (Singular_Value_At (Values, 0), 3.0)
         and then Approximately_Equal (Singular_Value_At (Values, 1), 2.0),
         "Float64 SVD of the converted tall source must keep singular"
         & " values 3 and 2");
      AUnit.Assertions.Assert
        (Reconstructs_Source (Source, Result, 0.000_000_000_1),
         "Float64 SVD must reconstruct the converted source more tightly");
   end Singular_Value_Decomposition_Preserves_Float64;

   procedure Singular_Value_Decomposition_Noncontiguous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (5, 4, (OpenCV.Core.Float32, 1));
      Contiguous : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Expected   : OpenCV.Core.Singular_Value_Decomposition_Result;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Fill_Tall_SVD_Source (Contiguous);
      Expected := Contiguous.Singular_Value_Decomposition;
      declare
         Source : OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 1, Width => 2, Height => 3));
         Result : OpenCV.Core.Singular_Value_Decomposition_Result;
      begin
         Fill_Tall_SVD_Source (Source);
         AUnit.Assertions.Assert
           (not Source.Is_Continuous,
            "The Region used for SVD must be non-contiguous");
         Result := Source.Singular_Value_Decomposition;
         AUnit.Assertions.Assert
           (Approximately_Equal
              (Singular_Value_At (Result.Singular_Values, 0),
               Singular_Value_At (Expected.Singular_Values, 0))
            and then Approximately_Equal
                       (Singular_Value_At (Result.Singular_Values, 1),
                        Singular_Value_At (Expected.Singular_Values, 1)),
            "Non-contiguous SVD must match contiguous singular values");
         AUnit.Assertions.Assert
           (Reconstructs_Source (Source, Result, 0.000_1)
            and then Reconstructs_Source (Contiguous, Expected, 0.000_1),
            "Both contiguous and Region SVD must reconstruct their sources");
         AUnit.Assertions.Assert
           (Unchanged_3x2 (Source, 3.0, 0.0, 0.0, 2.0, 0.0, 0.0)
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 3) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 4, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 1, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 1, 3) = 99.0,
            "SVD must not modify the Region or surrounding parent storage");
      end;
   end Singular_Value_Decomposition_Noncontiguous_Region;

   procedure Singular_Value_Decomposition_Outputs_Are_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result  : OpenCV.Core.Singular_Value_Decomposition_Result;
      Saved_W : OpenCV.Core.Mat;
      Saved_U : OpenCV.Core.Mat;
      Saved_V : OpenCV.Core.Mat;
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      begin
         Fill_Tall_SVD_Source (Source);
         Result := Source.Singular_Value_Decomposition;
         Saved_W := Result.Singular_Values.Clone;
         Saved_U := Result.U.Clone;
         Saved_V := Result.V_Transpose.Clone;
         OpenCV.Core.Float32_Access.Set (Source, 0, 0, 50.0);
      end;

      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (Result.Singular_Values, Saved_W)
         and then Mats_Approximately_Equal (Result.U, Saved_U)
         and then Mats_Approximately_Equal (Result.V_Transpose, Saved_V),
         "SVD outputs must remain valid after the source finalizes");

      OpenCV.Core.Float32_Access.Set (Result.Singular_Values, 0, 0, 7.0);
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (Result.U, Saved_U)
         and then Mats_Approximately_Equal (Result.V_Transpose, Saved_V),
         "Mutating Singular_Values must not change U or V_Transpose");

      OpenCV.Core.Float32_Access.Set (Result.U, 0, 0, 9.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Result.Singular_Values, 0, 0) = 7.0
         and then Mats_Approximately_Equal (Result.V_Transpose, Saved_V),
         "Mutating U must not change Singular_Values or V_Transpose");

      OpenCV.Core.Float32_Access.Set (Result.V_Transpose, 0, 0, 11.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Result.Singular_Values, 0, 0) = 7.0
         and then OpenCV.Core.Float32_Access.Get (Result.U, 0, 0) = 9.0,
         "Mutating V_Transpose must not change Singular_Values or U");
   end Singular_Value_Decomposition_Outputs_Are_Independent;

   procedure Singular_Value_Decomposition_Rejects_Invalid_Input
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Empty : OpenCV.Core.Mat;
      Empty32       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Two_Channel   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 2));
      UInt8_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.UInt8, 1));
      Int32_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Int32, 1));
      Float16_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float16, 1));

      procedure Check_Default is
         Result : constant OpenCV.Core.Singular_Value_Decomposition_Result :=
           Default_Empty.Singular_Value_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_Default;

      procedure Check_Empty32 is
         Result : constant OpenCV.Core.Singular_Value_Decomposition_Result :=
           Empty32.Singular_Value_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;

      procedure Check_Two_Channel is
         Result : constant OpenCV.Core.Singular_Value_Decomposition_Result :=
           Two_Channel.Singular_Value_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_Two_Channel;

      procedure Check_UInt8 is
         Result : constant OpenCV.Core.Singular_Value_Decomposition_Result :=
           UInt8_Image.Singular_Value_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_UInt8;

      procedure Check_Int32 is
         Result : constant OpenCV.Core.Singular_Value_Decomposition_Result :=
           Int32_Image.Singular_Value_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_Int32;

      procedure Check_Float16 is
         Result : constant OpenCV.Core.Singular_Value_Decomposition_Result :=
           Float16_Image.Singular_Value_Decomposition;
      begin
         pragma Unreferenced (Result);
      end Check_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Check_Default'Access,
         "Singular_Value_Decomposition must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access,
         "Singular_Value_Decomposition must reject a typed empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Two_Channel'Access,
         "Singular_Value_Decomposition must reject C2 input");
      Assert_Raises_OpenCV_Error
        (Check_UInt8'Access,
         "Singular_Value_Decomposition must reject UInt8 input");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access,
         "Singular_Value_Decomposition must reject Int32 input");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access,
         "Singular_Value_Decomposition must reject Float16 input");

   end Singular_Value_Decomposition_Rejects_Invalid_Input;

   procedure SVD_Back_Substitute_Square_Full_Rank
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      RHS    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      Basis  : OpenCV.Core.Singular_Value_Decomposition_Result;
      X      : OpenCV.Core.Mat;
      AX     : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Source, 2.0, 0.0, 0.0, 4.0);
      Fill_2x1 (RHS, 4.0, 8.0);
      Basis := Source.Singular_Value_Decomposition;
      X := OpenCV.Core.SVD_Back_Substitute (Basis, RHS);
      AX := Source.Matrix_Multiply (X);

      AUnit.Assertions.Assert
        (X.Rows = 2
         and then X.Columns = 1
         and then X.Depth = OpenCV.Core.Float32
         and then X.Channels = 1,
         "Square SVD back substitution must return a 2x1 Float32 C1 solution");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (X, 0, 0)), 2.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (X, 1, 0)),
                     2.0),
         "Square full-rank SVD back substitution must return [2, 2]");
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (AX, RHS),
         "Square full-rank SVD back substitution must satisfy A * X ~= B");
   end SVD_Back_Substitute_Square_Full_Rank;

   procedure SVD_Back_Substitute_Overdetermined_Least_Squares
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      RHS      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Basis    : OpenCV.Core.Singular_Value_Decomposition_Result;
      X        : OpenCV.Core.Mat;
      Residual : OpenCV.Core.Mat;
      Normal   : OpenCV.Core.Mat;
      Zero     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
   begin
      Fill_3x2 (Source, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0);
      Fill_3x1 (RHS, 1.0, 2.0, 4.0);
      Zero.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Basis := Source.Singular_Value_Decomposition;
      X := OpenCV.Core.SVD_Back_Substitute (Basis, RHS);
      Residual := Source.Matrix_Multiply (X).Subtract (RHS);
      Normal := Source.Transpose.Matrix_Multiply (Residual);

      AUnit.Assertions.Assert
        (X.Rows = 2 and then X.Columns = 1,
         "Overdetermined SVD back substitution must return a 2x1 solution");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (X, 0, 0)),
            4.0 / 3.0,
            0.000_1)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (X, 1, 0)),
                     7.0 / 3.0,
                     0.000_1),
         "Overdetermined SVD back substitution must return the least-squares"
         & " solution [4/3, 7/3]");
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (Normal, Zero, 0.000_1),
         "Overdetermined SVD residual must be orthogonal to the columns of A");
   end SVD_Back_Substitute_Overdetermined_Least_Squares;

   procedure SVD_Back_Substitute_Underdetermined_Minimum_Norm
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      RHS    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      Basis  : OpenCV.Core.Singular_Value_Decomposition_Result;
      X      : OpenCV.Core.Mat;
      AX     : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0);
      Fill_2x1 (RHS, 1.0, 1.0);
      Basis := Source.Singular_Value_Decomposition;
      X := OpenCV.Core.SVD_Back_Substitute (Basis, RHS);
      AX := Source.Matrix_Multiply (X);

      AUnit.Assertions.Assert
        (X.Rows = 3 and then X.Columns = 1,
         "Underdetermined SVD back substitution must return a 3x1 solution");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (X, 0, 0)),
            1.0 / 3.0,
            0.000_1)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (X, 1, 0)),
                     1.0 / 3.0,
                     0.000_1)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (X, 2, 0)),
                     2.0 / 3.0,
                     0.000_1),
         "Underdetermined SVD back substitution must return the minimum-norm"
         & " solution [1/3, 1/3, 2/3]");
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (AX, RHS, 0.000_1),
         "Underdetermined SVD back substitution must satisfy A * X ~= B");
   end SVD_Back_Substitute_Underdetermined_Minimum_Norm;

   procedure SVD_Back_Substitute_Multiple_Right_Hand_Sides
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      RHS    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Basis  : OpenCV.Core.Singular_Value_Decomposition_Result;
      X      : OpenCV.Core.Mat;
      AX     : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Source, 2.0, 0.0, 0.0, 4.0);
      Fill_2x2 (RHS, 4.0, 2.0, 8.0, 12.0);
      Basis := Source.Singular_Value_Decomposition;
      X := OpenCV.Core.SVD_Back_Substitute (Basis, RHS);
      AX := Source.Matrix_Multiply (X);

      AUnit.Assertions.Assert
        (X.Rows = 2 and then X.Columns = 2,
         "Multiple-RHS SVD back substitution must return a 2x2 solution");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (X, 0, 0)), 2.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (X, 0, 1)),
                     1.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (X, 1, 0)),
                     2.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (X, 1, 1)),
                     3.0),
         "Multiple-RHS SVD back substitution must return [[2, 1], [2, 3]]");
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (AX, RHS),
         "Multiple-RHS SVD back substitution must satisfy A * X ~= B");
   end SVD_Back_Substitute_Multiple_Right_Hand_Sides;

   procedure SVD_Back_Substitute_Rank_Deficient
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      RHS    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Basis  : OpenCV.Core.Singular_Value_Decomposition_Result;
      X      : OpenCV.Core.Mat;
   begin
      Fill_3x2 (Source, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0);
      Fill_3x1 (RHS, 2.0, 3.0, 4.0);
      Basis := Source.Singular_Value_Decomposition;
      X := OpenCV.Core.SVD_Back_Substitute (Basis, RHS);

      AUnit.Assertions.Assert
        (X.Rows = 2 and then X.Columns = 1,
         "Rank-deficient SVD back substitution must return a 2x1 solution");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (X, 0, 0)), 2.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (X, 1, 0)),
                     0.0),
         "Rank-deficient SVD back substitution must return [2, 0]");
   end SVD_Back_Substitute_Rank_Deficient;

   procedure SVD_Back_Substitute_Preserves_Float64
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      RHS32    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      Source   : OpenCV.Core.Mat;
      RHS      : OpenCV.Core.Mat;
      Basis    : OpenCV.Core.Singular_Value_Decomposition_Result;
      X        : OpenCV.Core.Mat;
      AX       : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Source32, 2.0, 0.0, 0.0, 4.0);
      Fill_2x1 (RHS32, 4.0, 8.0);
      Source := Source32.Convert_To (OpenCV.Core.Float64);
      RHS := RHS32.Convert_To (OpenCV.Core.Float64);
      Basis := Source.Singular_Value_Decomposition;
      X := OpenCV.Core.SVD_Back_Substitute (Basis, RHS);
      AX := Source.Matrix_Multiply (X);

      AUnit.Assertions.Assert
        (Basis.Singular_Values.Depth = OpenCV.Core.Float64
         and then Basis.U.Depth = OpenCV.Core.Float64
         and then Basis.V_Transpose.Depth = OpenCV.Core.Float64
         and then X.Depth = OpenCV.Core.Float64,
         "Float64 SVD back substitution must keep Float64 basis and result");
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (AX, RHS, 0.000_000_000_1),
         "Float64 SVD back substitution must satisfy A * X ~= B more tightly");
   end SVD_Back_Substitute_Preserves_Float64;

   procedure SVD_Back_Substitute_Noncontiguous_RHS
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Contiguous : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      Parent     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 3, (OpenCV.Core.Float32, 1));
      Basis      : OpenCV.Core.Singular_Value_Decomposition_Result;
      Expected   : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Source, 2.0, 0.0, 0.0, 4.0);
      Fill_2x1 (Contiguous, 4.0, 8.0);
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Basis := Source.Singular_Value_Decomposition;
      Expected := OpenCV.Core.SVD_Back_Substitute (Basis, Contiguous);
      declare
         RHS    : OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 1, Width => 1, Height => 2));
         Result : OpenCV.Core.Mat;
      begin
         Fill_2x1 (RHS, 4.0, 8.0);
         AUnit.Assertions.Assert
           (not RHS.Is_Continuous,
            "The Region used as SVD RHS must be non-contiguous");
         Result := OpenCV.Core.SVD_Back_Substitute (Basis, RHS);
         AUnit.Assertions.Assert
           (Mats_Approximately_Equal (Result, Expected),
            "Non-contiguous SVD RHS must match the contiguous solution");
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Access.Get (RHS, 0, 0) = 4.0
            and then OpenCV.Core.Float32_Access.Get (RHS, 1, 0) = 8.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 2) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 3, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 1, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 1, 2) = 99.0,
            "SVD back substitution must not modify the RHS Region or parent");
      end;
   end SVD_Back_Substitute_Noncontiguous_RHS;

   procedure SVD_Back_Substitute_Noncontiguous_Basis
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      RHS          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      Original     : OpenCV.Core.Singular_Value_Decomposition_Result;
      Expected     : OpenCV.Core.Mat;
      W_Parent     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 3, (OpenCV.Core.Float32, 1));
      U_Parent     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
      VT_Parent    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
      Region_Basis : OpenCV.Core.Singular_Value_Decomposition_Result;
      Result       : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Source, 2.0, 0.0, 0.0, 4.0);
      Fill_2x1 (RHS, 4.0, 8.0);
      Original := Source.Singular_Value_Decomposition;
      Expected := OpenCV.Core.SVD_Back_Substitute (Original, RHS);

      W_Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      U_Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      VT_Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));

      Region_Basis.Singular_Values :=
        W_Parent.Region ((X => 1, Y => 1, Width => 1, Height => 2));
      Region_Basis.U :=
        U_Parent.Region ((X => 1, Y => 1, Width => 2, Height => 2));
      Region_Basis.V_Transpose :=
        VT_Parent.Region ((X => 1, Y => 1, Width => 2, Height => 2));

      Original.Singular_Values.Copy_To (Region_Basis.Singular_Values);
      Original.U.Copy_To (Region_Basis.U);
      Original.V_Transpose.Copy_To (Region_Basis.V_Transpose);

      AUnit.Assertions.Assert
        (not Region_Basis.U.Is_Continuous
         and then not Region_Basis.V_Transpose.Is_Continuous,
         "The compact U and V_Transpose Regions must be non-contiguous");

      Result := OpenCV.Core.SVD_Back_Substitute (Region_Basis, RHS);

      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (Result, Expected),
         "A non-contiguous compact SVD basis must match the contiguous"
         & " solution");
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal
           (Region_Basis.Singular_Values, Original.Singular_Values)
         and then Mats_Approximately_Equal (Region_Basis.U, Original.U)
         and then Mats_Approximately_Equal
                    (Region_Basis.V_Transpose, Original.V_Transpose)
         and then OpenCV.Core.Float32_Access.Get (W_Parent, 0, 0) = 99.0
         and then OpenCV.Core.Float32_Access.Get (W_Parent, 0, 2) = 99.0
         and then OpenCV.Core.Float32_Access.Get (W_Parent, 3, 0) = 99.0
         and then OpenCV.Core.Float32_Access.Get (U_Parent, 0, 0) = 99.0
         and then OpenCV.Core.Float32_Access.Get (U_Parent, 0, 3) = 99.0
         and then OpenCV.Core.Float32_Access.Get (U_Parent, 3, 0) = 99.0
         and then OpenCV.Core.Float32_Access.Get (VT_Parent, 0, 0) = 99.0
         and then OpenCV.Core.Float32_Access.Get (VT_Parent, 0, 3) = 99.0
         and then OpenCV.Core.Float32_Access.Get (VT_Parent, 3, 0) = 99.0,
         "SVD back substitution must not modify basis parent storage"
         & " outside the Regions");
   end SVD_Back_Substitute_Noncontiguous_Basis;

   procedure SVD_Back_Substitute_Inputs_And_Result_Are_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      RHS     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      Basis   : OpenCV.Core.Singular_Value_Decomposition_Result;
      Result  : OpenCV.Core.Mat;
      Saved_W : OpenCV.Core.Mat;
      Saved_U : OpenCV.Core.Mat;
      Saved_V : OpenCV.Core.Mat;
      Saved_B : OpenCV.Core.Mat;
      Saved_X : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Source, 2.0, 0.0, 0.0, 4.0);
      Fill_2x1 (RHS, 4.0, 8.0);
      Basis := Source.Singular_Value_Decomposition;
      Saved_W := Basis.Singular_Values.Clone;
      Saved_U := Basis.U.Clone;
      Saved_V := Basis.V_Transpose.Clone;
      Saved_B := RHS.Clone;
      Result := OpenCV.Core.SVD_Back_Substitute (Basis, RHS);
      Saved_X := Result.Clone;

      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (Basis.Singular_Values, Saved_W)
         and then Mats_Approximately_Equal (Basis.U, Saved_U)
         and then Mats_Approximately_Equal (Basis.V_Transpose, Saved_V)
         and then Mats_Approximately_Equal (RHS, Saved_B),
         "SVD back substitution must leave the basis and RHS unchanged");

      OpenCV.Core.Float32_Access.Set (RHS, 0, 0, 50.0);
      OpenCV.Core.Float32_Access.Set (Basis.Singular_Values, 0, 0, 7.0);
      OpenCV.Core.Float32_Access.Set (Basis.U, 0, 0, 9.0);
      OpenCV.Core.Float32_Access.Set (Basis.V_Transpose, 0, 0, 11.0);
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (Result, Saved_X),
         "Mutating the basis or RHS must not change the returned solution");
   end SVD_Back_Substitute_Inputs_And_Result_Are_Independent;

   procedure SVD_Back_Substitute_Rejects_Invalid_RHS
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Basis         : OpenCV.Core.Singular_Value_Decomposition_Result;
      Default_Empty : OpenCV.Core.Mat;
      Empty32       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Two_Channel   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 2));
      Float64_RHS   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float64, 1));
      Too_Short     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      Too_Tall      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.Float32, 1));

      procedure Check_Default is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.SVD_Back_Substitute (Basis, Default_Empty);
      begin
         pragma Unreferenced (Result);
      end Check_Default;

      procedure Check_Empty32 is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.SVD_Back_Substitute (Basis, Empty32);
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;

      procedure Check_Two_Channel is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.SVD_Back_Substitute (Basis, Two_Channel);
      begin
         pragma Unreferenced (Result);
      end Check_Two_Channel;

      procedure Check_Depth_Mismatch is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.SVD_Back_Substitute (Basis, Float64_RHS);
      begin
         pragma Unreferenced (Result);
      end Check_Depth_Mismatch;

      procedure Check_Too_Short is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.SVD_Back_Substitute (Basis, Too_Short);
      begin
         pragma Unreferenced (Result);
      end Check_Too_Short;

      procedure Check_Too_Tall is
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.SVD_Back_Substitute (Basis, Too_Tall);
      begin
         pragma Unreferenced (Result);
      end Check_Too_Tall;
   begin
      Fill_3x2 (Source, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0);
      Basis := Source.Singular_Value_Decomposition;
      Assert_Raises_OpenCV_Error
        (Check_Default'Access,
         "SVD_Back_Substitute must reject a default empty RHS");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access,
         "SVD_Back_Substitute must reject a typed empty RHS");
      Assert_Raises_OpenCV_Error
        (Check_Two_Channel'Access, "SVD_Back_Substitute must reject a C2 RHS");
      Assert_Raises_OpenCV_Error
        (Check_Depth_Mismatch'Access,
         "SVD_Back_Substitute must reject a depth-mismatched RHS");
      Assert_Raises_OpenCV_Error
        (Check_Too_Short'Access,
         "SVD_Back_Substitute must reject an RHS with too few rows");
      Assert_Raises_OpenCV_Error
        (Check_Too_Tall'Access,
         "SVD_Back_Substitute must reject an RHS with too many rows");
   end SVD_Back_Substitute_Rejects_Invalid_RHS;

   procedure SVD_Back_Substitute_Rejects_Malformed_Basis
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      RHS    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Basis  : OpenCV.Core.Singular_Value_Decomposition_Result;

      procedure Check_Default_Basis is
         Local  : OpenCV.Core.Singular_Value_Decomposition_Result;
         Result : OpenCV.Core.Mat;
      begin
         Result := OpenCV.Core.SVD_Back_Substitute (Local, RHS);
         pragma Unreferenced (Result);
      end Check_Default_Basis;

      procedure Check_Row_Vector_W is
         Local  : OpenCV.Core.Singular_Value_Decomposition_Result := Basis;
         Result : OpenCV.Core.Mat;
      begin
         Local.Singular_Values :=
           OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
         Result := OpenCV.Core.SVD_Back_Substitute (Local, RHS);
         pragma Unreferenced (Result);
      end Check_Row_Vector_W;

      procedure Check_U_Columns is
         Local  : OpenCV.Core.Singular_Value_Decomposition_Result := Basis;
         Result : OpenCV.Core.Mat;
      begin
         Local.U := OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
         Result := OpenCV.Core.SVD_Back_Substitute (Local, RHS);
         pragma Unreferenced (Result);
      end Check_U_Columns;

      procedure Check_VT_Rows is
         Local  : OpenCV.Core.Singular_Value_Decomposition_Result := Basis;
         Result : OpenCV.Core.Mat;
      begin
         Local.V_Transpose :=
           OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
         Result := OpenCV.Core.SVD_Back_Substitute (Local, RHS);
         pragma Unreferenced (Result);
      end Check_VT_Rows;

      procedure Check_Compact_Rank is
         Local  : OpenCV.Core.Singular_Value_Decomposition_Result := Basis;
         Result : OpenCV.Core.Mat;
      begin
         Local.U := OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
         Result := OpenCV.Core.SVD_Back_Substitute (Local, RHS);
         pragma Unreferenced (Result);
      end Check_Compact_Rank;

      procedure Check_Depth_Mismatch is
         Local  : OpenCV.Core.Singular_Value_Decomposition_Result := Basis;
         Result : OpenCV.Core.Mat;
      begin
         Local.U := Local.U.Convert_To (OpenCV.Core.Float64);
         Result := OpenCV.Core.SVD_Back_Substitute (Local, RHS);
         pragma Unreferenced (Result);
      end Check_Depth_Mismatch;

      procedure Check_Multi_Channel is
         Local  : OpenCV.Core.Singular_Value_Decomposition_Result := Basis;
         Result : OpenCV.Core.Mat;
      begin
         Local.V_Transpose :=
           OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 2));
         Result := OpenCV.Core.SVD_Back_Substitute (Local, RHS);
         pragma Unreferenced (Result);
      end Check_Multi_Channel;
   begin
      Fill_3x2 (Source, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0);
      Fill_3x1 (RHS, 1.0, 2.0, 4.0);
      Basis := Source.Singular_Value_Decomposition;
      Assert_Raises_OpenCV_Error
        (Check_Default_Basis'Access,
         "SVD_Back_Substitute must reject a default empty basis");
      Assert_Raises_OpenCV_Error
        (Check_Row_Vector_W'Access,
         "SVD_Back_Substitute must reject a row-vector Singular_Values");
      Assert_Raises_OpenCV_Error
        (Check_U_Columns'Access,
         "SVD_Back_Substitute must reject U.Columns /= R");
      Assert_Raises_OpenCV_Error
        (Check_VT_Rows'Access,
         "SVD_Back_Substitute must reject V_Transpose.Rows /= R");
      Assert_Raises_OpenCV_Error
        (Check_Compact_Rank'Access,
         "SVD_Back_Substitute must reject R /= min (M, N)");
      Assert_Raises_OpenCV_Error
        (Check_Depth_Mismatch'Access,
         "SVD_Back_Substitute must reject a depth mismatch among W/U/VT");
      Assert_Raises_OpenCV_Error
        (Check_Multi_Channel'Access,
         "SVD_Back_Substitute must reject a multi-channel basis component");
   end SVD_Back_Substitute_Rejects_Malformed_Basis;

   function Pinv_At
     (Image : OpenCV.Core.Mat; Row, Column : Natural) return Long_Float
   is (Long_Float (OpenCV.Core.Float32_Access.Get (Image, Row, Column)));

   function Satisfies_Moore_Penrose
     (Source, Inverse : OpenCV.Core.Mat; Tolerance : Long_Float) return Boolean
   is
      Source_Inverse : constant OpenCV.Core.Mat :=
        Source.Matrix_Multiply (Inverse);
      Inverse_Source : constant OpenCV.Core.Mat :=
        Inverse.Matrix_Multiply (Source);
   begin
      return
        Mats_Approximately_Equal
          (Source_Inverse.Matrix_Multiply (Source), Source, Tolerance)
        and then Mats_Approximately_Equal
                   (Inverse_Source.Matrix_Multiply (Inverse),
                    Inverse,
                    Tolerance)
        and then Mats_Approximately_Equal
                   (Source_Inverse.Transpose, Source_Inverse, Tolerance)
        and then Mats_Approximately_Equal
                   (Inverse_Source.Transpose, Inverse_Source, Tolerance);
   end Satisfies_Moore_Penrose;

   procedure Fill_Tall_Pinv_Source (Image : in out OpenCV.Core.Mat) is
   begin
      Fill_3x2 (Image, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0);
   end Fill_Tall_Pinv_Source;

   procedure Fill_Wide_Pinv_Source (Image : in out OpenCV.Core.Mat) is
   begin
      Fill_2x3 (Image, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0);
   end Fill_Wide_Pinv_Source;

   function Expected_Tall_Pinv (Image : OpenCV.Core.Mat) return Boolean
   is (Image.Rows = 2
       and then Image.Columns = 3
       and then Image.Channels = 1
       and then Approximately_Equal (Pinv_At (Image, 0, 0), 2.0 / 3.0)
       and then Approximately_Equal (Pinv_At (Image, 0, 1), -1.0 / 3.0)
       and then Approximately_Equal (Pinv_At (Image, 0, 2), 1.0 / 3.0)
       and then Approximately_Equal (Pinv_At (Image, 1, 0), -1.0 / 3.0)
       and then Approximately_Equal (Pinv_At (Image, 1, 1), 2.0 / 3.0)
       and then Approximately_Equal (Pinv_At (Image, 1, 2), 1.0 / 3.0));

   function Expected_Wide_Pinv (Image : OpenCV.Core.Mat) return Boolean
   is (Image.Rows = 3
       and then Image.Columns = 2
       and then Image.Channels = 1
       and then Approximately_Equal (Pinv_At (Image, 0, 0), 2.0 / 3.0)
       and then Approximately_Equal (Pinv_At (Image, 0, 1), -1.0 / 3.0)
       and then Approximately_Equal (Pinv_At (Image, 1, 0), -1.0 / 3.0)
       and then Approximately_Equal (Pinv_At (Image, 1, 1), 2.0 / 3.0)
       and then Approximately_Equal (Pinv_At (Image, 2, 0), 1.0 / 3.0)
       and then Approximately_Equal (Pinv_At (Image, 2, 1), 1.0 / 3.0));

   procedure Pseudo_Inverse_Square_Nonsingular (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result   : OpenCV.Core.Mat;
      Ordinary : OpenCV.Core.Inversion_Result;
   begin
      Fill_2x2 (Source, 2.0, 0.0, 0.0, 4.0);
      Result := Source.Pseudo_Inverse;
      Ordinary := Source.Invert;

      AUnit.Assertions.Assert
        (Result.Rows = 2
         and then Result.Columns = 2
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 1
         and then Approximately_Equal (Pinv_At (Result, 0, 0), 0.5)
         and then Approximately_Equal (Pinv_At (Result, 0, 1), 0.0)
         and then Approximately_Equal (Pinv_At (Result, 1, 0), 0.0)
         and then Approximately_Equal (Pinv_At (Result, 1, 1), 0.25),
         "Square nonsingular Pseudo_Inverse must return diag (0.5, 0.25)");
      AUnit.Assertions.Assert
        (Ordinary.Invertible
         and then Mats_Approximately_Equal (Result, Ordinary.Inverse),
         "Square nonsingular Pseudo_Inverse must agree with Invert.Inverse");
      AUnit.Assertions.Assert
        (Unchanged_2x2 (Source, 2.0, 0.0, 0.0, 4.0),
         "Pseudo_Inverse must leave a square source unchanged");
   end Pseudo_Inverse_Square_Nonsingular;

   procedure Pseudo_Inverse_Tall_Full_Column_Rank
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_Tall_Pinv_Source (Source);
      Result := Source.Pseudo_Inverse;

      AUnit.Assertions.Assert
        (Expected_Tall_Pinv (Result)
         and then Result.Depth = OpenCV.Core.Float32,
         "Tall Pseudo_Inverse must return the known 2x3 values");
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal
           (Source.Matrix_Multiply (Result).Matrix_Multiply (Source),
            Source,
            0.000_1),
         "Tall Pseudo_Inverse must satisfy A * A^+ * A ~= A");
      AUnit.Assertions.Assert
        (Unchanged_3x2 (Source, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0),
         "Pseudo_Inverse must leave a tall source unchanged");
   end Pseudo_Inverse_Tall_Full_Column_Rank;

   procedure Pseudo_Inverse_Wide_Full_Row_Rank (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_Wide_Pinv_Source (Source);
      Result := Source.Pseudo_Inverse;

      AUnit.Assertions.Assert
        (Expected_Wide_Pinv (Result)
         and then Result.Depth = OpenCV.Core.Float32,
         "Wide Pseudo_Inverse must return the known 3x2 values");
      AUnit.Assertions.Assert
        (Satisfies_Moore_Penrose (Source, Result, 0.000_1),
         "Wide Pseudo_Inverse must satisfy the Moore-Penrose identities");
      AUnit.Assertions.Assert
        (Unchanged_2x3 (Source, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0),
         "Pseudo_Inverse must leave a wide source unchanged");
   end Pseudo_Inverse_Wide_Full_Row_Rank;

   procedure Pseudo_Inverse_Rank_Deficient (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_3x2 (Source, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0);
      Result := Source.Pseudo_Inverse;

      AUnit.Assertions.Assert
        (Result.Rows = 2
         and then Result.Columns = 3
         and then Approximately_Equal (Pinv_At (Result, 0, 0), 1.0)
         and then Approximately_Equal (Pinv_At (Result, 0, 1), 0.0)
         and then Approximately_Equal (Pinv_At (Result, 0, 2), 0.0)
         and then Approximately_Equal (Pinv_At (Result, 1, 0), 0.0)
         and then Approximately_Equal (Pinv_At (Result, 1, 1), 0.0)
         and then Approximately_Equal (Pinv_At (Result, 1, 2), 0.0),
         "Rank-deficient Pseudo_Inverse must keep the nonzero singular"
         & " direction");
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal
           (Source.Matrix_Multiply (Result).Matrix_Multiply (Source),
            Source,
            0.000_1),
         "Rank-deficient Pseudo_Inverse must satisfy A * A^+ * A ~= A");
   end Pseudo_Inverse_Rank_Deficient;

   procedure Pseudo_Inverse_Zero_Matrix (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Source.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Result := Source.Pseudo_Inverse;

      AUnit.Assertions.Assert
        (Result.Rows = 2
         and then Result.Columns = 3
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 1
         and then Approximately_Equal (Pinv_At (Result, 0, 0), 0.0)
         and then Approximately_Equal (Pinv_At (Result, 0, 1), 0.0)
         and then Approximately_Equal (Pinv_At (Result, 0, 2), 0.0)
         and then Approximately_Equal (Pinv_At (Result, 1, 0), 0.0)
         and then Approximately_Equal (Pinv_At (Result, 1, 1), 0.0)
         and then Approximately_Equal (Pinv_At (Result, 1, 2), 0.0),
         "Zero-matrix Pseudo_Inverse must return a zero 2x3 result");
   end Pseudo_Inverse_Zero_Matrix;

   procedure Pseudo_Inverse_Matches_SVD_Back_Substitute
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      RHS    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
      Via_BS : OpenCV.Core.Mat;
      Via_PI : OpenCV.Core.Mat;
   begin
      Fill_Tall_Pinv_Source (Source);
      Fill_3x1 (RHS, 1.0, 2.0, 4.0);
      Via_BS :=
        OpenCV.Core.SVD_Back_Substitute
          (Source.Singular_Value_Decomposition, RHS);
      Via_PI := Source.Pseudo_Inverse.Matrix_Multiply (RHS);

      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (Via_PI, Via_BS, 0.000_1),
         "P * B must match SVD_Back_Substitute of the same A and B");
   end Pseudo_Inverse_Matches_SVD_Back_Substitute;

   procedure Pseudo_Inverse_Preserves_Float64 (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Source   : OpenCV.Core.Mat;
      Result   : OpenCV.Core.Mat;
      Values   : OpenCV.Core.Mat;
   begin
      Fill_Tall_Pinv_Source (Source32);
      Source := Source32.Convert_To (OpenCV.Core.Float64);
      Result := Source.Pseudo_Inverse;
      Values := Result.Convert_To (OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (Result.Depth = OpenCV.Core.Float64
         and then Result.Rows = 2
         and then Result.Columns = 3
         and then Result.Channels = 1
         and then Expected_Tall_Pinv (Values),
         "Float64 Pseudo_Inverse must keep Float64 depth and the known"
         & " values");
      AUnit.Assertions.Assert
        (Satisfies_Moore_Penrose (Source, Result, 0.000_000_000_1),
         "Float64 Pseudo_Inverse must satisfy Moore-Penrose more tightly");
   end Pseudo_Inverse_Preserves_Float64;

   procedure Pseudo_Inverse_Supports_Noncontiguous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (5, 4, (OpenCV.Core.Float32, 1));
      Contiguous : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Expected   : OpenCV.Core.Mat;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Fill_Tall_Pinv_Source (Contiguous);
      Expected := Contiguous.Pseudo_Inverse;
      declare
         Source : OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 1, Width => 2, Height => 3));
         Result : OpenCV.Core.Mat;
      begin
         Fill_Tall_Pinv_Source (Source);
         AUnit.Assertions.Assert
           (not Source.Is_Continuous,
            "The Region used for Pseudo_Inverse must be non-contiguous");
         Result := Source.Pseudo_Inverse;
         AUnit.Assertions.Assert
           (Mats_Approximately_Equal (Result, Expected, 0.000_1)
            and then Expected_Tall_Pinv (Result),
            "Non-contiguous Pseudo_Inverse must match the contiguous result");
         AUnit.Assertions.Assert
           (Unchanged_3x2 (Source, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0)
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 3) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 4, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 1, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 1, 3) = 99.0,
            "Pseudo_Inverse must not modify the Region or parent storage");
      end;
   end Pseudo_Inverse_Supports_Noncontiguous_Region;

   procedure Pseudo_Inverse_Owns_Independent_Storage
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Mat;
      Saved  : OpenCV.Core.Mat;
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      begin
         Fill_Tall_Pinv_Source (Source);
         Result := Source.Pseudo_Inverse;
         Saved := Result.Clone;
         OpenCV.Core.Float32_Access.Set (Source, 0, 0, 50.0);
         AUnit.Assertions.Assert
           (Mats_Approximately_Equal (Result, Saved),
            "Mutating Self must not change its pseudoinverse");
      end;

      AUnit.Assertions.Assert
        (Expected_Tall_Pinv (Result),
         "A pseudoinverse must remain valid after the source finalizes");
      OpenCV.Core.Float32_Access.Set (Result, 0, 0, 9.0);
      AUnit.Assertions.Assert
        (Approximately_Equal (Pinv_At (Saved, 0, 0), 2.0 / 3.0),
         "Mutating the result must not change an independent clone");
   end Pseudo_Inverse_Owns_Independent_Storage;

   procedure Pseudo_Inverse_Rejects_Invalid_Input
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Empty : OpenCV.Core.Mat;
      Empty32       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Two_Channel   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 2));
      UInt8_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.UInt8, 1));
      Int32_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Int32, 1));
      Float16_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float16, 1));

      procedure Check_Default is
         Result : constant OpenCV.Core.Mat := Default_Empty.Pseudo_Inverse;
      begin
         pragma Unreferenced (Result);
      end Check_Default;

      procedure Check_Empty32 is
         Result : constant OpenCV.Core.Mat := Empty32.Pseudo_Inverse;
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;

      procedure Check_Two_Channel is
         Result : constant OpenCV.Core.Mat := Two_Channel.Pseudo_Inverse;
      begin
         pragma Unreferenced (Result);
      end Check_Two_Channel;

      procedure Check_UInt8 is
         Result : constant OpenCV.Core.Mat := UInt8_Image.Pseudo_Inverse;
      begin
         pragma Unreferenced (Result);
      end Check_UInt8;

      procedure Check_Int32 is
         Result : constant OpenCV.Core.Mat := Int32_Image.Pseudo_Inverse;
      begin
         pragma Unreferenced (Result);
      end Check_Int32;

      procedure Check_Float16 is
         Result : constant OpenCV.Core.Mat := Float16_Image.Pseudo_Inverse;
      begin
         pragma Unreferenced (Result);
      end Check_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Check_Default'Access,
         "Pseudo_Inverse must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access, "Pseudo_Inverse must reject a typed empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Two_Channel'Access, "Pseudo_Inverse must reject C2 input");
      Assert_Raises_OpenCV_Error
        (Check_UInt8'Access, "Pseudo_Inverse must reject UInt8 input");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access, "Pseudo_Inverse must reject Int32 input");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access, "Pseudo_Inverse must reject Float16 input");
   end Pseudo_Inverse_Rejects_Invalid_Input;

   procedure Pseudo_Inverse_Remains_Distinct_From_Invert
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Rectangular : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Singular    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Pinv        : OpenCV.Core.Mat;
      Ordinary    : OpenCV.Core.Inversion_Result;

      procedure Check_Rectangular is
         Result : constant OpenCV.Core.Inversion_Result := Rectangular.Invert;
      begin
         pragma Unreferenced (Result);
      end Check_Rectangular;
   begin
      Fill_Wide_Pinv_Source (Rectangular);
      Fill_2x2 (Singular, 1.0, 0.0, 0.0, 0.0);
      Pinv := Rectangular.Pseudo_Inverse;
      Ordinary := Singular.Invert;

      AUnit.Assertions.Assert
        (Expected_Wide_Pinv (Pinv),
         "A rectangular Mat valid for Pseudo_Inverse must succeed");
      Assert_Raises_OpenCV_Error
        (Check_Rectangular'Access,
         "Ordinary Invert must still reject a rectangular Mat");
      AUnit.Assertions.Assert
        (not Ordinary.Invertible,
         "A singular square Mat remains Invertible False for Invert");
      AUnit.Assertions.Assert
        (Singular.Pseudo_Inverse.Rows = 2
         and then Singular.Pseudo_Inverse.Columns = 2,
         "A singular square Mat remains valid for Pseudo_Inverse");
   end Pseudo_Inverse_Remains_Distinct_From_Invert;

   procedure Reciprocal_Condition_Number_Known_Diagonal
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
   begin
      Fill_2x2 (Source, 4.0, 0.0, 0.0, 2.0);
      AUnit.Assertions.Assert
        (Approximately_Equal (Source.Reciprocal_Condition_Number, 0.5),
         "diag(4, 2) must have reciprocal condition number 0.5");
      AUnit.Assertions.Assert
        (Unchanged_2x2 (Source, 4.0, 0.0, 0.0, 2.0),
         "Reciprocal_Condition_Number must leave the known diagonal"
         & " unchanged");
   end Reciprocal_Condition_Number_Known_Diagonal;

   procedure Reciprocal_Condition_Number_Perfectly_Conditioned
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
   begin
      Fill_2x2 (Source, 7.0, 0.0, 0.0, 7.0);
      AUnit.Assertions.Assert
        (Approximately_Equal (Source.Reciprocal_Condition_Number, 1.0),
         "A scaled identity must have reciprocal condition number 1.0");
   end Reciprocal_Condition_Number_Perfectly_Conditioned;

   procedure Reciprocal_Condition_Number_Is_Scale_Invariant
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Scaled : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
   begin
      Fill_2x2 (Source, 4.0, 0.0, 0.0, 2.0);
      Fill_2x2 (Scaled, 40.0, 0.0, 0.0, 20.0);
      AUnit.Assertions.Assert
        (Approximately_Equal (Source.Reciprocal_Condition_Number, 0.5)
         and then Approximately_Equal
                    (Scaled.Reciprocal_Condition_Number, 0.5),
         "rcond(c * A) must equal rcond(A) for a finite nonzero scale");
   end Reciprocal_Condition_Number_Is_Scale_Invariant;

   procedure Reciprocal_Condition_Number_Small_Scale_Float64
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Source   : OpenCV.Core.Mat;
      Result   : Long_Float;
   begin
      Fill_2x2 (Source32, 4.0, 0.0, 0.0, 2.0);
      Source := Source32.Convert_To (OpenCV.Core.Float64, Scale => 1.0E-20);
      Result := Source.Reciprocal_Condition_Number;
      AUnit.Assertions.Assert
        (Source.Depth = OpenCV.Core.Float64,
         "The small-scale source must remain Float64");
      AUnit.Assertions.Assert
        (Approximately_Equal (Result, 0.5, 0.000_000_000_1),
         "1.0E-20 * diag(4, 2) must still have rcond approximately 0.5");
   end Reciprocal_Condition_Number_Small_Scale_Float64;

   procedure Reciprocal_Condition_Number_Singular_Matrix
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
   begin
      Fill_2x2 (Source, 4.0, 0.0, 0.0, 0.0);
      AUnit.Assertions.Assert
        (Approximately_Equal (Source.Reciprocal_Condition_Number, 0.0),
         "A singular matrix must return rcond approximately 0.0");
   end Reciprocal_Condition_Number_Singular_Matrix;

   procedure Reciprocal_Condition_Number_Zero_Matrix
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
   begin
      Source.Set_To (OpenCV.Core.Make_Scalar (0.0));
      AUnit.Assertions.Assert
        (Source.Reciprocal_Condition_Number = 0.0,
         "A non-empty zero matrix must return rcond 0.0 rather than 0 / 0");
   end Reciprocal_Condition_Number_Zero_Matrix;

   procedure Reciprocal_Condition_Number_Tall_Matrix
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
   begin
      Fill_Tall_SVD_Source (Source);
      AUnit.Assertions.Assert
        (Approximately_Equal (Source.Reciprocal_Condition_Number, 2.0 / 3.0),
         "A tall compact matrix with singular values 3 and 2 must return"
         & " 2/3");
   end Reciprocal_Condition_Number_Tall_Matrix;

   procedure Reciprocal_Condition_Number_Wide_Matrix
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
   begin
      Fill_Wide_SVD_Source (Source);
      AUnit.Assertions.Assert
        (Approximately_Equal (Source.Reciprocal_Condition_Number, 2.0 / 3.0),
         "A wide compact matrix with singular values 3 and 2 must return"
         & " 2/3");
   end Reciprocal_Condition_Number_Wide_Matrix;

   procedure Reciprocal_Condition_Number_Matches_Compact_SVD
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Basis  : OpenCV.Core.Singular_Value_Decomposition_Result;
      Rank   : Natural;
      Ratio  : Long_Float;
   begin
      Fill_2x2 (Source, 4.0, 0.0, 0.0, 2.0);
      Basis := Source.Singular_Value_Decomposition;
      Rank := Basis.Singular_Values.Rows;
      Ratio :=
        Singular_Value_At (Basis.Singular_Values, Rank - 1)
        / Singular_Value_At (Basis.Singular_Values, 0);
      AUnit.Assertions.Assert
        (Approximately_Equal (Source.Reciprocal_Condition_Number, Ratio),
         "NO_UV rcond must match sigma_min / sigma_max from compact SVD");
   end Reciprocal_Condition_Number_Matches_Compact_SVD;

   procedure Reciprocal_Condition_Number_Noncontiguous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (5, 4, (OpenCV.Core.Float32, 1));
      Contiguous : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Expected   : Long_Float;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Fill_2x2 (Contiguous, 4.0, 0.0, 0.0, 2.0);
      Expected := Contiguous.Reciprocal_Condition_Number;
      declare
         Region : OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 1, Width => 2, Height => 2));
         Result : Long_Float;
      begin
         Fill_2x2 (Region, 4.0, 0.0, 0.0, 2.0);
         AUnit.Assertions.Assert
           (not Region.Is_Continuous,
            "The Region used for Reciprocal_Condition_Number must be"
            & " non-contiguous");
         Result := Region.Reciprocal_Condition_Number;
         AUnit.Assertions.Assert
           (Approximately_Equal (Result, Expected)
            and then Approximately_Equal (Result, 0.5),
            "A non-contiguous Region must match the contiguous rcond");
         AUnit.Assertions.Assert
           (Unchanged_2x2 (Region, 4.0, 0.0, 0.0, 2.0)
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 3) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 4, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 1, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 1, 3) = 99.0,
            "Reciprocal_Condition_Number must not modify the Region or"
            & " surrounding parent storage");
      end;
   end Reciprocal_Condition_Number_Noncontiguous_Region;

   procedure Reciprocal_Condition_Number_Rejects_Invalid_Input
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Empty : OpenCV.Core.Mat;
      Empty32       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Two_Channel   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 2));
      UInt8_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Int32_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int32, 1));
      Float16_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float16, 1));

      procedure Check_Default is
         Result : constant Long_Float :=
           Default_Empty.Reciprocal_Condition_Number;
      begin
         pragma Unreferenced (Result);
      end Check_Default;

      procedure Check_Empty32 is
         Result : constant Long_Float := Empty32.Reciprocal_Condition_Number;
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;

      procedure Check_Two_Channel is
         Result : constant Long_Float :=
           Two_Channel.Reciprocal_Condition_Number;
      begin
         pragma Unreferenced (Result);
      end Check_Two_Channel;

      procedure Check_UInt8 is
         Result : constant Long_Float :=
           UInt8_Image.Reciprocal_Condition_Number;
      begin
         pragma Unreferenced (Result);
      end Check_UInt8;

      procedure Check_Int32 is
         Result : constant Long_Float :=
           Int32_Image.Reciprocal_Condition_Number;
      begin
         pragma Unreferenced (Result);
      end Check_Int32;

      procedure Check_Float16 is
         Result : constant Long_Float :=
           Float16_Image.Reciprocal_Condition_Number;
      begin
         pragma Unreferenced (Result);
      end Check_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Check_Default'Access,
         "Reciprocal_Condition_Number must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access,
         "Reciprocal_Condition_Number must reject a typed empty Float32 Mat");
      Assert_Raises_OpenCV_Error
        (Check_Two_Channel'Access,
         "Reciprocal_Condition_Number must reject a two-channel Mat");
      Assert_Raises_OpenCV_Error
        (Check_UInt8'Access,
         "Reciprocal_Condition_Number must reject UInt8 input");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access,
         "Reciprocal_Condition_Number must reject Int32 input");
      Assert_Raises_OpenCV_Error
        (Check_Float16'Access,
         "Reciprocal_Condition_Number must reject Float16 input");
   end Reciprocal_Condition_Number_Rejects_Invalid_Input;

   function Unit_Column_Shape
     (Image         : OpenCV.Core.Mat;
      Expected_Rows : Natural;
      Depth         : OpenCV.Core.Depth_Type) return Boolean
   is (Image.Rows = Expected_Rows
       and then Image.Columns = 1
       and then Image.Depth = Depth
       and then Image.Channels = 1);

   function Approximately_Unit_L2
     (Image : OpenCV.Core.Mat; Tolerance : Long_Float := 0.000_1)
      return Boolean
   is (Approximately_Equal (Image.Norm, 1.0, Tolerance));

   function Residual_Norm
     (Source, Solution : OpenCV.Core.Mat) return Long_Float
   is (Source.Matrix_Multiply (Solution).Norm);

   function Float32_Abs
     (Value : OpenCV.Core.Float32_Value) return OpenCV.Core.Float32_Value
   is (if Value < 0.0 then -Value else Value);

   procedure SVD_Solve_Zero_Wide_Exact_Null_Space
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Result   : OpenCV.Core.Mat;
      Residual : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0);
      Result := Source.SVD_Solve_Zero;
      Residual := Source.Matrix_Multiply (Result);

      AUnit.Assertions.Assert
        (Unit_Column_Shape (Result, 3, OpenCV.Core.Float32),
         "Wide SVD_Solve_Zero must return a 3x1 Float32 C1 vector");
      AUnit.Assertions.Assert
        (Approximately_Unit_L2 (Result),
         "Wide SVD_Solve_Zero must return a unit-length vector");
      AUnit.Assertions.Assert
        (Approximately_Equal (Residual.Norm, 0.0, 0.000_1),
         "Wide full-row-rank SVD_Solve_Zero must return a"
         & " null-space direction");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Result, 0, 0)), 0.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 1, 0)),
                     0.0)
         and then Approximately_Equal
                    (Long_Float
                       (Float32_Abs
                          (OpenCV.Core.Float32_Access.Get (Result, 2, 0))),
                     1.0),
         "Wide 2x3 null space must be sign-insensitive e3");
      AUnit.Assertions.Assert
        (Unchanged_2x3 (Source, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0),
         "Wide SVD_Solve_Zero must leave the source unchanged");
   end SVD_Solve_Zero_Wide_Exact_Null_Space;

   procedure SVD_Solve_Zero_Square_Singular (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Source, 4.0, 0.0, 0.0, 0.0);
      Result := Source.SVD_Solve_Zero;

      AUnit.Assertions.Assert
        (Unit_Column_Shape (Result, 2, OpenCV.Core.Float32),
         "Square SVD_Solve_Zero must return a 2x1 Float32 C1 vector");
      AUnit.Assertions.Assert
        (Approximately_Unit_L2 (Result),
         "Square SVD_Solve_Zero must return a unit-length vector");
      AUnit.Assertions.Assert
        (Approximately_Equal (Residual_Norm (Source, Result), 0.0, 0.000_1),
         "Singular square SVD_Solve_Zero must have approximately"
         & " zero residual");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Result, 0, 0)), 0.0)
         and then Approximately_Equal
                    (Long_Float
                       (Float32_Abs
                          (OpenCV.Core.Float32_Access.Get (Result, 1, 0))),
                     1.0),
         "Singular 2x2 SVD_Solve_Zero must be sign-insensitive e2");
      AUnit.Assertions.Assert
        (Unchanged_2x2 (Source, 4.0, 0.0, 0.0, 0.0),
         "Square SVD_Solve_Zero must leave the source unchanged");
   end SVD_Solve_Zero_Square_Singular;

   procedure SVD_Solve_Zero_Full_Rank_Minimizer
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Fill_2x2 (Source, 3.0, 0.0, 0.0, 1.0);
      Result := Source.SVD_Solve_Zero;

      AUnit.Assertions.Assert
        (Unit_Column_Shape (Result, 2, OpenCV.Core.Float32)
         and then Approximately_Unit_L2 (Result),
         "Full-rank SVD_Solve_Zero must return a unit 2x1 vector");
      AUnit.Assertions.Assert
        (Approximately_Equal (Residual_Norm (Source, Result), 1.0, 0.000_1),
         "Full-rank SVD_Solve_Zero residual must be the smallest"
         & " singular value");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Result, 0, 0)), 0.0)
         and then Approximately_Equal
                    (Long_Float
                       (Float32_Abs
                          (OpenCV.Core.Float32_Access.Get (Result, 1, 0))),
                     1.0),
         "Full-rank 2x2 SVD_Solve_Zero must be the smallest right"
         & " singular vector");
   end SVD_Solve_Zero_Full_Rank_Minimizer;

   procedure SVD_Solve_Zero_Tall_Full_Column_Rank
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Result   : OpenCV.Core.Mat;
      Compact  : OpenCV.Core.Singular_Value_Decomposition_Result;
      Last_Row : OpenCV.Core.Mat;
   begin
      Fill_3x2 (Source, 3.0, 0.0, 0.0, 1.0, 0.0, 0.0);
      Result := Source.SVD_Solve_Zero;
      Compact := Source.Singular_Value_Decomposition;
      Last_Row := Compact.V_Transpose.Row_View (1).Transpose;

      AUnit.Assertions.Assert
        (Unit_Column_Shape (Result, 2, OpenCV.Core.Float32)
         and then Approximately_Unit_L2 (Result),
         "Tall SVD_Solve_Zero must return a unit 2x1 vector");
      AUnit.Assertions.Assert
        (Approximately_Equal (Residual_Norm (Source, Result), 1.0, 0.000_1),
         "Tall full-column-rank residual must be the smallest singular value");
      AUnit.Assertions.Assert
        (Mats_Approximately_Equal (Result, Last_Row, 0.000_1)
         or else Approximately_Equal
                   (Result.Add (Last_Row).Norm, 0.0, 0.000_1),
         "Tall SVD_Solve_Zero must match compact VT last row up to sign");
      AUnit.Assertions.Assert
        (Unchanged_3x2 (Source, 3.0, 0.0, 0.0, 1.0, 0.0, 0.0),
         "Tall SVD_Solve_Zero must leave the source unchanged");
   end SVD_Solve_Zero_Tall_Full_Column_Rank;

   procedure SVD_Solve_Zero_Preserves_Float64 (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Source    : OpenCV.Core.Mat;
      Result    : OpenCV.Core.Mat;
      Residual  : OpenCV.Core.Mat;
      Converted : OpenCV.Core.Mat;
   begin
      Fill_2x3 (Source32, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0);
      Source := Source32.Convert_To (OpenCV.Core.Float64);
      Result := Source.SVD_Solve_Zero;
      Residual := Source.Matrix_Multiply (Result);
      Converted := Result.Convert_To (OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (Unit_Column_Shape (Result, 3, OpenCV.Core.Float64),
         "Float64 SVD_Solve_Zero must keep Float64 C1 3x1 output");
      AUnit.Assertions.Assert
        (Approximately_Unit_L2 (Result, 0.000_000_000_1),
         "Float64 SVD_Solve_Zero must return a unit-length vector");
      AUnit.Assertions.Assert
        (Approximately_Equal (Residual.Norm, 0.0, 0.000_000_000_1),
         "Float64 wide SVD_Solve_Zero residual must be approximately zero");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Converted, 0, 0)), 0.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Converted, 1, 0)),
                     0.0)
         and then Approximately_Equal
                    (Long_Float
                       (Float32_Abs
                          (OpenCV.Core.Float32_Access.Get (Converted, 2, 0))),
                     1.0),
         "Float64 wide null space must be sign-insensitive e3");
   end SVD_Solve_Zero_Preserves_Float64;

   procedure SVD_Solve_Zero_Zero_Matrix (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Source.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Result := Source.SVD_Solve_Zero;

      AUnit.Assertions.Assert
        (Unit_Column_Shape (Result, 2, OpenCV.Core.Float32)
         and then Approximately_Unit_L2 (Result)
         and then Approximately_Equal
                    (Residual_Norm (Source, Result), 0.0, 0.000_1),
         "Zero-matrix SVD_Solve_Zero must return a unit vector with"
         & " zero residual");
   end SVD_Solve_Zero_Zero_Matrix;

   procedure SVD_Solve_Zero_One_By_One (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, -3.5);
      Result := Source.SVD_Solve_Zero;

      AUnit.Assertions.Assert
        (Unit_Column_Shape (Result, 1, OpenCV.Core.Float32),
         "1x1 SVD_Solve_Zero must return a 1x1 Float32 C1 vector");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (Float32_Abs (OpenCV.Core.Float32_Access.Get (Result, 0, 0))),
            1.0),
         "1x1 SVD_Solve_Zero must return plus or minus one");
      AUnit.Assertions.Assert
        (Approximately_Equal (Residual_Norm (Source, Result), 3.5, 0.000_1),
         "1x1 SVD_Solve_Zero residual magnitude must be abs(A)");
   end SVD_Solve_Zero_One_By_One;

   procedure SVD_Solve_Zero_Noncontiguous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (5, 5, (OpenCV.Core.Float32, 1));
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      declare
         Source : OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
         Result : OpenCV.Core.Mat;
      begin
         Fill_2x3 (Source, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0);
         AUnit.Assertions.Assert
           (not Source.Is_Continuous,
            "The Region used for SVD_Solve_Zero must be non-contiguous");
         Result := Source.SVD_Solve_Zero;
         AUnit.Assertions.Assert
           (Unit_Column_Shape (Result, 3, OpenCV.Core.Float32)
            and then Approximately_Unit_L2 (Result)
            and then Approximately_Equal
                       (Residual_Norm (Source, Result), 0.0, 0.000_1),
            "Non-contiguous SVD_Solve_Zero must return the 2x3"
            & " null-space direction");
         AUnit.Assertions.Assert
           (Unchanged_2x3 (Source, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0)
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 4) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 4, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 1, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 1, 4) = 99.0,
            "SVD_Solve_Zero must not modify the Region or surrounding"
            & " parent storage");
      end;
   end SVD_Solve_Zero_Noncontiguous_Region;

   procedure SVD_Solve_Zero_Owns_Independent_Storage
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Mat;
      Saved  : OpenCV.Core.Mat;
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      begin
         Fill_2x3 (Source, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0);
         Result := Source.SVD_Solve_Zero;
         Saved := Result.Clone;
         OpenCV.Core.Float32_Access.Set (Source, 0, 0, 50.0);
         AUnit.Assertions.Assert
           (Mats_Approximately_Equal (Result, Saved),
            "Mutating Self must not change SVD_Solve_Zero");
      end;

      AUnit.Assertions.Assert
        (Unit_Column_Shape (Result, 3, OpenCV.Core.Float32)
         and then Approximately_Unit_L2 (Result),
         "SVD_Solve_Zero must remain valid after the source finalizes");
      OpenCV.Core.Float32_Access.Set (Result, 0, 0, 9.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Saved, 0, 0) /= 9.0,
         "Mutating the result must not change an independent clone");
   end SVD_Solve_Zero_Owns_Independent_Storage;

   procedure SVD_Solve_Zero_Rejects_Invalid_Input
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Empty : OpenCV.Core.Mat;
      Empty32       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Two_Channel   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 2));
      Int32_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Int32, 1));

      procedure Check_Default is
         Result : constant OpenCV.Core.Mat := Default_Empty.SVD_Solve_Zero;
      begin
         pragma Unreferenced (Result);
      end Check_Default;

      procedure Check_Empty32 is
         Result : constant OpenCV.Core.Mat := Empty32.SVD_Solve_Zero;
      begin
         pragma Unreferenced (Result);
      end Check_Empty32;

      procedure Check_Two_Channel is
         Result : constant OpenCV.Core.Mat := Two_Channel.SVD_Solve_Zero;
      begin
         pragma Unreferenced (Result);
      end Check_Two_Channel;

      procedure Check_Int32 is
         Result : constant OpenCV.Core.Mat := Int32_Image.SVD_Solve_Zero;
      begin
         pragma Unreferenced (Result);
      end Check_Int32;
   begin
      Assert_Raises_OpenCV_Error
        (Check_Default'Access,
         "SVD_Solve_Zero must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Empty32'Access, "SVD_Solve_Zero must reject a typed empty Mat");
      Assert_Raises_OpenCV_Error
        (Check_Two_Channel'Access, "SVD_Solve_Zero must reject C2 input");
      Assert_Raises_OpenCV_Error
        (Check_Int32'Access, "SVD_Solve_Zero must reject Int32 input");
   end SVD_Solve_Zero_Rejects_Invalid_Input;

   procedure PSNR_Known_Value_Uses_Default_Peak
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Right    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Expected : constant Long_Float := 20.0 * Log (255.0) / Log (10.0);
   begin
      OpenCV.Core.UInt8_Access.Set (Left, 0, 0, 10);
      OpenCV.Core.UInt8_Access.Set (Right, 0, 0, 11);

      AUnit.Assertions.Assert
        (Approximately_Equal
           (OpenCV.Core.Peak_Signal_To_Noise_Ratio (Left, Right),
            Expected,
            0.000_000_001),
         "PSNR must default R to 255 and match the known one-unit RMSE");
   end PSNR_Known_Value_Uses_Default_Peak;

   procedure PSNR_Uses_Custom_Peak_Value (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Left     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Right    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Expected : constant Long_Float :=
        20.0 * Log (100.0 / Sqrt (2.0)) / Log (10.0);
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Right.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Right, 0, 1, 2);

      AUnit.Assertions.Assert
        (Approximately_Equal
           (OpenCV.Core.Peak_Signal_To_Noise_Ratio
              (Left, Right, Peak_Value => 100.0),
            Expected,
            0.000_000_001),
         "PSNR must pass an explicit custom peak value to OpenCV");
   end PSNR_Uses_Custom_Peak_Value;

   procedure PSNR_Identical_Returns_OpenCV_Finite_Value
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Double_Epsilon : constant Long_Float := 2.220_446_049_250_313E-16;
      Expected       : constant Long_Float :=
        20.0 * Log (255.0 / Double_Epsilon) / Log (10.0);
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (42.0));

      AUnit.Assertions.Assert
        (Approximately_Equal
           (OpenCV.Core.Peak_Signal_To_Noise_Ratio (Image, Image),
            Expected,
            0.000_000_001),
         "Zero MSE must use OpenCV's DBL_EPSILON denominator, not infinity");
   end PSNR_Identical_Returns_OpenCV_Finite_Value;

   procedure PSNR_Supports_Float32_Float64_And_Float16
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left32   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Right32  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Left64   : OpenCV.Core.Mat;
      Right64  : OpenCV.Core.Mat;
      Left16   : OpenCV.Core.Mat;
      Right16  : OpenCV.Core.Mat;
      Expected : constant Long_Float :=
        20.0 * Log (10.0 / Sqrt (2.0)) / Log (10.0);
   begin
      Left32.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Right32.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.Float32_Access.Set (Right32, 0, 1, 2.0);
      Left64 := Left32.Convert_To (OpenCV.Core.Float64);
      Right64 := Right32.Convert_To (OpenCV.Core.Float64);
      Left16 := Left32.Convert_To (OpenCV.Core.Float16);
      Right16 := Right32.Convert_To (OpenCV.Core.Float16);

      AUnit.Assertions.Assert
        (Approximately_Equal
           (OpenCV.Core.Peak_Signal_To_Noise_Ratio (Left32, Right32, 10.0),
            Expected,
            0.000_001)
         and then Approximately_Equal
                    (OpenCV.Core.Peak_Signal_To_Noise_Ratio
                       (Left64, Right64, 10.0),
                     Expected,
                     0.000_000_001)
         and then Approximately_Equal
                    (OpenCV.Core.Peak_Signal_To_Noise_Ratio
                       (Left16, Right16, 10.0),
                     Expected,
                     0.000_001),
         "PSNR must support OpenCV's Float32, Float64, and Float16 norms");
   end PSNR_Supports_Float32_Float64_And_Float16;

   procedure PSNR_Supports_Int32_And_UInt16 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Left8    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Right8   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Left32   : OpenCV.Core.Mat;
      Right32  : OpenCV.Core.Mat;
      Left16U  : OpenCV.Core.Mat;
      Right16U : OpenCV.Core.Mat;
      Expected : constant Long_Float :=
        20.0 * Log (100.0 / Sqrt (2.0)) / Log (10.0);
   begin
      Left8.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Right8.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Right8, 0, 1, 2);
      Left32 := Left8.Convert_To (OpenCV.Core.Int32);
      Right32 := Right8.Convert_To (OpenCV.Core.Int32);
      Left16U := Left8.Convert_To (OpenCV.Core.UInt16);
      Right16U := Right8.Convert_To (OpenCV.Core.UInt16);

      AUnit.Assertions.Assert
        (Left32.Depth = OpenCV.Core.Int32
         and then Right32.Depth = OpenCV.Core.Int32
         and then Left32.Channels = 1
         and then Right32.Channels = 1
         and then Approximately_Equal
                    (OpenCV.Core.Peak_Signal_To_Noise_Ratio
                       (Left32, Right32, 100.0),
                     Expected,
                     0.000_000_001)
         and then Left16U.Depth = OpenCV.Core.UInt16
         and then Right16U.Depth = OpenCV.Core.UInt16
         and then Left16U.Channels = 1
         and then Right16U.Channels = 1
         and then Approximately_Equal
                    (OpenCV.Core.Peak_Signal_To_Noise_Ratio
                       (Left16U, Right16U, 100.0),
                     Expected,
                     0.000_000_001),
         "PSNR must accept matching Int32 and UInt16 complete element types");
   end PSNR_Supports_Int32_And_UInt16;

   procedure PSNR_Supports_Multiple_And_More_Than_Four_Channels
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left3        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Right3       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Five_Channel : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 5));
      Expected     : constant Long_Float :=
        20.0 * Log (255.0 / Sqrt (1.0 / 3.0)) / Log (10.0);
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (Left3, 0, 0, (0, 0, 0));
      OpenCV.Core.UInt8_Vec3_Access.Set (Right3, 0, 0, (1, 0, 0));

      AUnit.Assertions.Assert
        (Approximately_Equal
           (OpenCV.Core.Peak_Signal_To_Noise_Ratio (Left3, Right3),
            Expected,
            0.000_000_001),
         "PSNR MSE must include every channel component");
      AUnit.Assertions.Assert
        (OpenCV.Core.Peak_Signal_To_Noise_Ratio (Five_Channel, Five_Channel)
         > 300.0,
         "PSNR must support channel counts greater than Scalar's four");
   end PSNR_Supports_Multiple_And_More_Than_Four_Channels;

   procedure PSNR_Supports_Noncontiguous_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left_Parent  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.UInt8, 1));
      Right_Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.UInt8, 1));
      Left         : OpenCV.Core.Mat;
      Right        : OpenCV.Core.Mat;
      Expected     : constant Long_Float := 20.0 * Log (255.0) / Log (10.0);
   begin
      Left_Parent.Set_To (OpenCV.Core.Make_Scalar (20.0));
      Right_Parent.Set_To (OpenCV.Core.Make_Scalar (21.0));
      Left := Left_Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      Right := Right_Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));

      AUnit.Assertions.Assert
        (not Left.Is_Continuous
         and then not Right.Is_Continuous
         and then Approximately_Equal
                    (OpenCV.Core.Peak_Signal_To_Noise_Ratio (Left, Right),
                     Expected,
                     0.000_000_001),
         "PSNR must support matching non-contiguous Regions");
   end PSNR_Supports_Noncontiguous_Regions;

   procedure PSNR_Rejects_Empty_And_Incompatible_Mats
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Empty          : OpenCV.Core.Mat;
      Base           : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Wrong_Rows     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Wrong_Depth    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Wrong_Channels : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 3));

      procedure Check_Empty is
         Value : constant Long_Float :=
           OpenCV.Core.Peak_Signal_To_Noise_Ratio (Empty, Empty);
      begin
         pragma Unreferenced (Value);
      end Check_Empty;

      procedure Check_Rows is
         Value : constant Long_Float :=
           OpenCV.Core.Peak_Signal_To_Noise_Ratio (Base, Wrong_Rows);
      begin
         pragma Unreferenced (Value);
      end Check_Rows;

      procedure Check_Depth is
         Value : constant Long_Float :=
           OpenCV.Core.Peak_Signal_To_Noise_Ratio (Base, Wrong_Depth);
      begin
         pragma Unreferenced (Value);
      end Check_Depth;

      procedure Check_Channels is
         Value : constant Long_Float :=
           OpenCV.Core.Peak_Signal_To_Noise_Ratio (Base, Wrong_Channels);
      begin
         pragma Unreferenced (Value);
      end Check_Channels;

      procedure Check_Zero_Peak is
         Value : constant Long_Float :=
           OpenCV.Core.Peak_Signal_To_Noise_Ratio
             (Base, Base, Peak_Value => 0.0);
      begin
         pragma Unreferenced (Value);
      end Check_Zero_Peak;

      procedure Check_Negative_Peak is
         Value : constant Long_Float :=
           OpenCV.Core.Peak_Signal_To_Noise_Ratio
             (Base, Base, Peak_Value => -1.0);
      begin
         pragma Unreferenced (Value);
      end Check_Negative_Peak;
   begin
      Assert_Raises_OpenCV_Error
        (Check_Empty'Access, "PSNR must reject empty Mats");
      Assert_Raises_OpenCV_Error
        (Check_Rows'Access, "PSNR must reject mismatched dimensions");
      Assert_Raises_OpenCV_Error
        (Check_Depth'Access, "PSNR must reject mismatched depths");
      Assert_Raises_OpenCV_Error
        (Check_Channels'Access, "PSNR must reject mismatched channel counts");
      Assert_Raises_OpenCV_Error
        (Check_Zero_Peak'Access, "PSNR must reject a zero peak value");
      Assert_Raises_OpenCV_Error
        (Check_Negative_Peak'Access, "PSNR must reject a negative peak value");
   end PSNR_Rejects_Empty_And_Incompatible_Mats;

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);

   Masked_Min_Max_Loc_In_Range         : constant Caller.Test_Method :=
     Masked_Min_Max_Loc_Excludes_Global_Extrema_And_Uses_In_Range_Mask'Access;
   PCA_Supports_Noncontiguous_Region   : constant Caller.Test_Method :=
     Principal_Component_Analysis_Supports_Noncontiguous_Region'Access;
   PCA_Retained_Variance_Rejects_Range : constant Caller.Test_Method :=
     Principal_Component_Analysis_Retained_Variance_Rejects_Range'Access;
   PCA_Retained_Variance_Rejects_Input : constant Caller.Test_Method :=
     Principal_Component_Analysis_Retained_Variance_Rejects_Input'Access;

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      Masked_Mean_Std_Dev_Views : constant Caller.Test_Method :=
        Masked_Mean_Std_Dev_Non_Continuous_Views_And_All_Zero_Mask'Access;
      Masked_Min_Max_Loc_UInt8  : constant Caller.Test_Method :=
        Masked_Min_Max_Loc_UInt8_Selects_Extrema_And_Column_Row_Points'Access;
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
            Masked_Mean_Std_Dev_Views));
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
           ("Dot_Product basic Float32", Dot_Product_Basic_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Dot_Product supports Float64",
            Dot_Product_Supports_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("Dot_Product supports integer depths",
            Dot_Product_Supports_Integer_Depths'Access));
      Result.Add_Test
        (Caller.Create
           ("Dot_Product rejects Float16",
            Dot_Product_Rejects_Float16'Access));
      Result.Add_Test
        (Caller.Create
           ("Dot_Product C3 sums every channel",
            Dot_Product_C3_Sums_Every_Channel'Access));
      Result.Add_Test
        (Caller.Create
           ("Dot_Product C2 is not complex",
            Dot_Product_C2_Is_Not_Complex'Access));
      Result.Add_Test
        (Caller.Create
           ("Dot_Product supports five channels",
            Dot_Product_Supports_Five_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("Dot_Product sums multiple elements and channels",
            Dot_Product_Sums_Multiple_Elements_And_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("Dot_Product supports non-contiguous Regions",
            Dot_Product_Supports_Noncontiguous_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("Dot_Product rejects mismatched shape and type",
            Dot_Product_Rejects_Mismatched_Shape_And_Type'Access));

      Result.Add_Test
        (Caller.Create
           ("Mahalanobis_Distance basic Float32 identity",
            Mahalanobis_Distance_Basic_Float32_Identity'Access));
      Result.Add_Test
        (Caller.Create
           ("Mahalanobis_Distance non-identity diagonal",
            Mahalanobis_Distance_Nonidentity_Diagonal'Access));
      Result.Add_Test
        (Caller.Create
           ("Mahalanobis_Distance uses off-diagonal terms",
            Mahalanobis_Distance_Uses_Off_Diagonal_Terms'Access));
      Result.Add_Test
        (Caller.Create
           ("Mahalanobis_Distance equal vectors are zero",
            Mahalanobis_Distance_Equal_Vectors_Are_Zero'Access));
      Result.Add_Test
        (Caller.Create
           ("Mahalanobis_Distance supports Float64",
            Mahalanobis_Distance_Supports_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("Mahalanobis_Distance supports column vectors",
            Mahalanobis_Distance_Supports_Column_Vectors'Access));
      Result.Add_Test
        (Caller.Create
           ("Mahalanobis_Distance supports non-contiguous Regions",
            Mahalanobis_Distance_Noncontiguous_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("Mahalanobis_Distance rejects invalid inputs",
            Mahalanobis_Distance_Rejects_Invalid_Inputs'Access));

      Result.Add_Test
        (Caller.Create
           ("Cross_Product basic Float32 3x1",
            Cross_Product_Basic_Float32_3x1'Access));
      Result.Add_Test
        (Caller.Create
           ("Cross_Product operand order",
            Cross_Product_Operand_Order'Access));
      Result.Add_Test
        (Caller.Create
           ("Cross_Product general values",
            Cross_Product_General_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Cross_Product Float32 1x3", Cross_Product_Float32_1x3'Access));
      Result.Add_Test
        (Caller.Create
           ("Cross_Product Float32 1x1 C3",
            Cross_Product_Float32_1x1_C3'Access));
      Result.Add_Test
        (Caller.Create
           ("Cross_Product supports Float64",
            Cross_Product_Supports_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("Cross_Product supports non-contiguous Regions",
            Cross_Product_Noncontiguous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Cross_Product result owns independent storage",
            Cross_Product_Result_Owns_Independent_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Cross_Product result outlives inputs",
            Cross_Product_Result_Outlives_Inputs'Access));
      Result.Add_Test
        (Caller.Create
           ("Cross_Product rejects invalid inputs",
            Cross_Product_Rejects_Invalid_Inputs'Access));

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
           ("Transposed_Product full-size Float32 Delta",
            Transposed_Product_Full_Size_Float32_Delta'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product row-vector Delta broadcast",
            Transposed_Product_Row_Vector_Broadcast'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product column-vector Delta broadcast",
            Transposed_Product_Column_Vector_Broadcast'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product 1x1 Delta broadcast",
            Transposed_Product_Scalar_Broadcast'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product Self_Times_Transpose with Delta",
            Transposed_Product_Self_Times_Transpose_With_Delta'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product Scale with Delta",
            Transposed_Product_Scale_With_Delta'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product UInt8 Self with Float32 Delta",
            Transposed_Product_UInt8_Self_Float32_Delta'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product automatic promotion from Float64 Delta",
            Transposed_Product_Automatic_Promotion_From_Float64_Delta'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product Int32 Delta",
            Transposed_Product_Int32_Delta'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product explicit Float64 with integer Delta",
            Transposed_Product_Explicit_Float64_With_Integer_Delta'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product explicit Float32 rejects Float64 Delta",
            Transposed_Product_Explicit_Float32_Rejects_Float64_Delta'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product rejects Float16 Delta",
            Transposed_Product_Rejects_Float16_Delta'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product rejects multi-channel Delta",
            Transposed_Product_Rejects_Multi_Channel_Delta'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product rejects invalid Delta shapes",
            Transposed_Product_Rejects_Invalid_Delta_Shapes'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product rejects empty Delta",
            Transposed_Product_Rejects_Empty_Delta'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product with Delta rejects invalid Self",
            Transposed_Product_With_Delta_Rejects_Invalid_Self'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product non-contiguous full Delta Region",
            Transposed_Product_Noncontiguous_Full_Delta_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Transposed_Product with Delta result independence",
            Transposed_Product_With_Delta_Result_Independence'Access));

      Result.Add_Test
        (Caller.Create
           ("Covariance Float32 samples as rows",
            Covariance_Float32_Samples_As_Rows'Access));
      Result.Add_Test
        (Caller.Create
           ("Covariance Float32 samples as columns",
            Covariance_Float32_Samples_As_Columns'Access));
      Result.Add_Test
        (Caller.Create
           ("Covariance Unscaled returns the raw accumulation",
            Covariance_Unscaled_Returns_Raw_Accumulation'Access));
      Result.Add_Test
        (Caller.Create
           ("Covariance preserves Float64 depth",
            Covariance_Preserves_Float64_Depth'Access));
      Result.Add_Test
        (Caller.Create
           ("Covariance supports a non-contiguous Region",
            Covariance_Supports_Noncontiguous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Covariance outputs are independent",
            Covariance_Outputs_Are_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Covariance outputs outlive the source",
            Covariance_Outputs_Outlive_Source'Access));
      Result.Add_Test
        (Caller.Create
           ("Covariance orientation changes output dimensions",
            Covariance_Orientation_Changes_Output_Dimensions'Access));
      Result.Add_Test
        (Caller.Create
           ("Covariance rejects empty, multi-channel, and invalid depths",
            Covariance_Rejects_Empty_Multi_Channel_And_Invalid_Depths'Access));
      Result.Add_Test
        (Caller.Create
           ("Eigen_Decomposition diagonal Float32 layout and order",
            Eigen_Decomposition_Diagonal_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Eigen_Decomposition satisfies equation and orthogonality",
            Eigen_Decomposition_Satisfies_Equation_And_Orthogonality'Access));
      Result.Add_Test
        (Caller.Create
           ("Eigen_Decomposition preserves Float64 depth",
            Eigen_Decomposition_Preserves_Float64_Depth'Access));
      Result.Add_Test
        (Caller.Create
           ("Eigen_Decomposition supports a non-contiguous Region",
            Eigen_Decomposition_Supports_Noncontiguous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Eigen_Decomposition outputs are independent",
            Eigen_Decomposition_Outputs_Are_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Eigen_Decomposition outputs outlive the source",
            Eigen_Decomposition_Outputs_Outlive_Source'Access));
      Result.Add_Test
        (Caller.Create
           ("Eigen_Decomposition repeated eigenvalues remain valid",
            Eigen_Decomposition_Repeated_Eigenvalues_Remain_Valid'Access));
      Result.Add_Test
        (Caller.Create
           ("Eigen_Decomposition rejects empty, non-square, and invalid types",
            Eigen_Decomposition_Rejects_Invalid_Input'Access));
      Result.Add_Test
        (Caller.Create
           ("Non_Symmetric_Eigen_Decomposition upper-triangular Float32",
            Non_Symmetric_Eigen_Upper_Triangular_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Non_Symmetric_Eigen_Decomposition distinct-real 3x3",
            Non_Symmetric_Eigen_Decomposition_Three_By_Three'Access));
      Result.Add_Test
        (Caller.Create
           ("Non_Symmetric_Eigen_Decomposition Float64 compatibility",
            Non_Symmetric_Eigen_Float64_And_Compatibility'Access));
      Result.Add_Test
        (Caller.Create
           ("Non_Symmetric_Eigen_Decomposition Region and ownership",
            Non_Symmetric_Eigen_Decomposition_Region_And_Ownership'Access));
      Result.Add_Test
        (Caller.Create
           ("Non_Symmetric_Eigen_Decomposition rejects invalid input",
            Non_Symmetric_Eigen_Decomposition_Rejects_Invalid_Input'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis Float32 rows all components",
            Principal_Component_Analysis_Float32_Rows_All_Components'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis matches Covariance eigen",
            Principal_Component_Analysis_Matches_Covariance_Eigen'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis truncates to one component",
            Principal_Component_Analysis_Truncates_To_One_Component'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis samples as columns",
            Principal_Component_Analysis_Samples_As_Columns'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis scrambled feature space",
            Principal_Component_Analysis_Scrambled_Feature_Space'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis supports a non-contiguous Region",
            PCA_Supports_Noncontiguous_Region));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis preserves Float64 depth",
            Principal_Component_Analysis_Preserves_Float64_Depth'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis outputs are independent",
            Principal_Component_Analysis_Outputs_Are_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis outputs outlive the source",
            Principal_Component_Analysis_Outputs_Outlive_Source'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis allows rank deficiency",
            Principal_Component_Analysis_Allows_Rank_Deficiency'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis rejects empty, C2, and invalid"
            & " types",
            Principal_Component_Analysis_Rejects_Invalid_Input'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis retained variance 0.80 keeps two",
            Principal_Component_Analysis_Retained_Variance_0_80'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis retained variance 0.95 OpenCV"
            & " quirk",
            Principal_Component_Analysis_Retained_Variance_0_95_Quirk'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis retained variance 1.0 keeps all",
            Principal_Component_Analysis_Retained_Variance_1_0'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis retained variance keeps at least"
            & " two",
            Principal_Component_Analysis_Retained_Variance_Keeps_Two'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis retained variance samples as"
            & " columns",
            Principal_Component_Analysis_Retained_Variance_Columns'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis retained variance project"
            & " integration",
            Principal_Component_Analysis_Retained_Variance_Project'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis retained variance preserves"
            & " Float64",
            Principal_Component_Analysis_Retained_Variance_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis retained variance non-contiguous"
            & " Region",
            Principal_Component_Analysis_Retained_Variance_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis retained variance ownership",
            Principal_Component_Analysis_Retained_Variance_Ownership'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis retained variance rejects range",
            PCA_Retained_Variance_Rejects_Range));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis retained variance needs two"
            & " components",
            Principal_Component_Analysis_Retained_Variance_Needs_Two'Access));
      Result.Add_Test
        (Caller.Create
           ("Principal_Component_Analysis retained variance rejects invalid"
            & " input",
            PCA_Retained_Variance_Rejects_Input));

      Result.Add_Test
        (Caller.Create
           ("PCA_Project and PCA_Back_Project full-basis row round trip",
            PCA_Project_And_Back_Project_Round_Trip_Rows'Access));
      Result.Add_Test
        (Caller.Create
           ("PCA_Project matches the row formula",
            PCA_Project_Matches_Row_Formula'Access));
      Result.Add_Test
        (Caller.Create
           ("PCA_Back_Project matches the row formula",
            PCA_Back_Project_Matches_Row_Formula'Access));
      Result.Add_Test
        (Caller.Create
           ("PCA one-component reconstruction is approximate",
            PCA_Truncated_One_Component_Reconstruction'Access));
      Result.Add_Test
        (Caller.Create
           ("PCA_Project of the mean sample is zero",
            PCA_Project_Mean_Sample_Is_Zero'Access));
      Result.Add_Test
        (Caller.Create
           ("PCA_Project and PCA_Back_Project full-basis column round trip",
            PCA_Project_And_Back_Project_Round_Trip_Columns'Access));
      Result.Add_Test
        (Caller.Create
           ("PCA one-feature column orientation is unambiguous",
            PCA_One_Feature_Column_Orientation'Access));
      Result.Add_Test
        (Caller.Create
           ("PCA_Project preserves Float64 depth",
            PCA_Project_Preserves_Float64_Depth'Access));
      Result.Add_Test
        (Caller.Create
           ("PCA_Project output depth follows the basis",
            PCA_Project_Converts_Input_To_Basis_Depth'Access));
      Result.Add_Test
        (Caller.Create
           ("PCA_Project supports a non-contiguous Region",
            PCA_Project_Supports_Noncontiguous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("PCA_Project and PCA_Back_Project outputs are independent",
            PCA_Project_And_Back_Project_Outputs_Are_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("PCA_Project does not use Eigenvalues",
            PCA_Project_Does_Not_Use_Eigenvalues'Access));
      Result.Add_Test
        (Caller.Create
           ("PCA_Project rejects empty, C2, and invalid types",
            PCA_Project_Rejects_Invalid_Self'Access));
      Result.Add_Test
        (Caller.Create
           ("PCA_Project rejects a malformed basis",
            PCA_Project_Rejects_Invalid_Basis'Access));
      Result.Add_Test
        (Caller.Create
           ("PCA_Back_Project rejects empty, C2, and invalid types",
            PCA_Back_Project_Rejects_Invalid_Input'Access));

      Result.Add_Test
        (Caller.Create
           ("Singular_Value_Decomposition tall compact shapes",
            Singular_Value_Decomposition_Tall_Compact_Shapes'Access));
      Result.Add_Test
        (Caller.Create
           ("Singular_Value_Decomposition tall reconstruction",
            Singular_Value_Decomposition_Tall_Reconstruction'Access));
      Result.Add_Test
        (Caller.Create
           ("Singular_Value_Decomposition wide compact shapes",
            Singular_Value_Decomposition_Wide_Compact_Shapes'Access));
      Result.Add_Test
        (Caller.Create
           ("Singular_Value_Decomposition orthonormal compact vectors",
            Singular_Value_Decomposition_Orthonormal_Vectors'Access));
      Result.Add_Test
        (Caller.Create
           ("Singular_Value_Decomposition matches Eigen of the Gram matrix",
            Singular_Value_Decomposition_Matches_Eigen_Of_Gram'Access));
      Result.Add_Test
        (Caller.Create
           ("Singular_Value_Decomposition rank-deficient matrix",
            Singular_Value_Decomposition_Rank_Deficient'Access));
      Result.Add_Test
        (Caller.Create
           ("Singular_Value_Decomposition preserves Float64",
            Singular_Value_Decomposition_Preserves_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("Singular_Value_Decomposition supports a non-contiguous Region",
            Singular_Value_Decomposition_Noncontiguous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Singular_Value_Decomposition outputs are independent",
            Singular_Value_Decomposition_Outputs_Are_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Singular_Value_Decomposition rejects empty, C2, and invalid"
            & " types",
            Singular_Value_Decomposition_Rejects_Invalid_Input'Access));

      Result.Add_Test
        (Caller.Create
           ("SVD_Back_Substitute square full-rank system",
            SVD_Back_Substitute_Square_Full_Rank'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD_Back_Substitute overdetermined least squares",
            SVD_Back_Substitute_Overdetermined_Least_Squares'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD_Back_Substitute underdetermined minimum-norm solution",
            SVD_Back_Substitute_Underdetermined_Minimum_Norm'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD_Back_Substitute multiple right-hand sides",
            SVD_Back_Substitute_Multiple_Right_Hand_Sides'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD_Back_Substitute rank-deficient system",
            SVD_Back_Substitute_Rank_Deficient'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD_Back_Substitute preserves Float64",
            SVD_Back_Substitute_Preserves_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD_Back_Substitute supports a non-contiguous RHS",
            SVD_Back_Substitute_Noncontiguous_RHS'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD_Back_Substitute supports a non-contiguous compact basis",
            SVD_Back_Substitute_Noncontiguous_Basis'Access));

      Result.Add_Test
        (Caller.Create
           ("SVD_Back_Substitute inputs and result are independent",
            SVD_Back_Substitute_Inputs_And_Result_Are_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD_Back_Substitute rejects invalid RHS",
            SVD_Back_Substitute_Rejects_Invalid_RHS'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD_Back_Substitute rejects a malformed basis",
            SVD_Back_Substitute_Rejects_Malformed_Basis'Access));

      Result.Add_Test
        (Caller.Create
           ("Pseudo_Inverse square nonsingular agrees with Invert",
            Pseudo_Inverse_Square_Nonsingular'Access));
      Result.Add_Test
        (Caller.Create
           ("Pseudo_Inverse tall full-column-rank matrix",
            Pseudo_Inverse_Tall_Full_Column_Rank'Access));
      Result.Add_Test
        (Caller.Create
           ("Pseudo_Inverse wide full-row-rank matrix",
            Pseudo_Inverse_Wide_Full_Row_Rank'Access));
      Result.Add_Test
        (Caller.Create
           ("Pseudo_Inverse rank-deficient matrix",
            Pseudo_Inverse_Rank_Deficient'Access));
      Result.Add_Test
        (Caller.Create
           ("Pseudo_Inverse zero matrix", Pseudo_Inverse_Zero_Matrix'Access));
      Result.Add_Test
        (Caller.Create
           ("Pseudo_Inverse matches SVD_Back_Substitute",
            Pseudo_Inverse_Matches_SVD_Back_Substitute'Access));
      Result.Add_Test
        (Caller.Create
           ("Pseudo_Inverse preserves Float64",
            Pseudo_Inverse_Preserves_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("Pseudo_Inverse supports a non-contiguous Region",
            Pseudo_Inverse_Supports_Noncontiguous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Pseudo_Inverse owns independent storage",
            Pseudo_Inverse_Owns_Independent_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Pseudo_Inverse rejects empty, C2, and invalid types",
            Pseudo_Inverse_Rejects_Invalid_Input'Access));
      Result.Add_Test
        (Caller.Create
           ("Pseudo_Inverse remains distinct from Invert",
            Pseudo_Inverse_Remains_Distinct_From_Invert'Access));

      Result.Add_Test
        (Caller.Create
           ("Reciprocal_Condition_Number known diagonal",
            Reciprocal_Condition_Number_Known_Diagonal'Access));
      Result.Add_Test
        (Caller.Create
           ("Reciprocal_Condition_Number perfectly conditioned",
            Reciprocal_Condition_Number_Perfectly_Conditioned'Access));
      Result.Add_Test
        (Caller.Create
           ("Reciprocal_Condition_Number is scale invariant",
            Reciprocal_Condition_Number_Is_Scale_Invariant'Access));
      Result.Add_Test
        (Caller.Create
           ("Reciprocal_Condition_Number small-scale Float64",
            Reciprocal_Condition_Number_Small_Scale_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("Reciprocal_Condition_Number singular matrix",
            Reciprocal_Condition_Number_Singular_Matrix'Access));
      Result.Add_Test
        (Caller.Create
           ("Reciprocal_Condition_Number zero matrix",
            Reciprocal_Condition_Number_Zero_Matrix'Access));
      Result.Add_Test
        (Caller.Create
           ("Reciprocal_Condition_Number tall matrix",
            Reciprocal_Condition_Number_Tall_Matrix'Access));
      Result.Add_Test
        (Caller.Create
           ("Reciprocal_Condition_Number wide matrix",
            Reciprocal_Condition_Number_Wide_Matrix'Access));
      Result.Add_Test
        (Caller.Create
           ("Reciprocal_Condition_Number matches compact SVD",
            Reciprocal_Condition_Number_Matches_Compact_SVD'Access));
      Result.Add_Test
        (Caller.Create
           ("Reciprocal_Condition_Number non-contiguous Region",
            Reciprocal_Condition_Number_Noncontiguous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Reciprocal_Condition_Number rejects empty, C2, and invalid"
            & " types",
            Reciprocal_Condition_Number_Rejects_Invalid_Input'Access));

      Result.Add_Test
        (Caller.Create
           ("SVD_Solve_Zero wide exact null space",
            SVD_Solve_Zero_Wide_Exact_Null_Space'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD_Solve_Zero square singular matrix",
            SVD_Solve_Zero_Square_Singular'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD_Solve_Zero full-rank minimizer is not a null vector",
            SVD_Solve_Zero_Full_Rank_Minimizer'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD_Solve_Zero tall full-column-rank matrix",
            SVD_Solve_Zero_Tall_Full_Column_Rank'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD_Solve_Zero preserves Float64",
            SVD_Solve_Zero_Preserves_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD_Solve_Zero zero matrix", SVD_Solve_Zero_Zero_Matrix'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD_Solve_Zero 1x1 matrix", SVD_Solve_Zero_One_By_One'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD_Solve_Zero supports a non-contiguous Region",
            SVD_Solve_Zero_Noncontiguous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD_Solve_Zero owns independent storage",
            SVD_Solve_Zero_Owns_Independent_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("SVD_Solve_Zero rejects empty, C2, and invalid types",
            SVD_Solve_Zero_Rejects_Invalid_Input'Access));

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
           ("Reduce Sum_Of_Squares promotes integer sources before multiply",
            Reduce_Sum_Of_Squares_Promotes_Integer_Sources_Before_Multiply'
              Access));
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
            Masked_Min_Max_Loc_UInt8));
      Result.Add_Test
        (Caller.Create
           ("Masked Min_Max_Loc excludes global extrema with In_Range mask",
            Masked_Min_Max_Loc_In_Range));
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
           ("PSNR known value uses default peak",
            PSNR_Known_Value_Uses_Default_Peak'Access));
      Result.Add_Test
        (Caller.Create
           ("PSNR uses custom peak value",
            PSNR_Uses_Custom_Peak_Value'Access));
      Result.Add_Test
        (Caller.Create
           ("PSNR identical inputs return OpenCV finite value",
            PSNR_Identical_Returns_OpenCV_Finite_Value'Access));
      Result.Add_Test
        (Caller.Create
           ("PSNR supports Float32 Float64 and Float16",
            PSNR_Supports_Float32_Float64_And_Float16'Access));
      Result.Add_Test
        (Caller.Create
           ("PSNR supports Int32 and UInt16",
            PSNR_Supports_Int32_And_UInt16'Access));
      Result.Add_Test
        (Caller.Create
           ("PSNR supports multiple and more than four channels",
            PSNR_Supports_Multiple_And_More_Than_Four_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("PSNR supports non-contiguous Regions",
            PSNR_Supports_Noncontiguous_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("PSNR rejects empty and incompatible Mats",
            PSNR_Rejects_Empty_And_Incompatible_Mats'Access));
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
