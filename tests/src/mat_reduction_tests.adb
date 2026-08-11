with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float32_Vec3_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Vec3_Access;
with Mat_Test_Support;

package body Mat_Reduction_Tests is

   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_8;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Point_Coordinate;

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
