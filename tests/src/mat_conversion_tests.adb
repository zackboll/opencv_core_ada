with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float32_Matx3x3;
with OpenCV.Core.Float32_Matx3x3_Conversions;
with OpenCV.Core.Float32_Vec3_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;
with Mat_Test_Support;

package body Mat_Conversion_Tests is

   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_8;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.UInt8_Vec3.Vector;

   use Mat_Test_Support;

   procedure Convert_To_UInt8_To_Float32_Preserves_Metadata_And_Source
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Converted : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set
        (Source, Row => 0, Column => 0, Value => 10);
      OpenCV.Core.UInt8_Access.Set
        (Source, Row => 0, Column => 1, Value => 20);
      Converted := Source.Convert_To (Depth => OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (Converted.Rows = 1 and then Converted.Columns = 2,
         "Convert_To should preserve source dimensions");
      AUnit.Assertions.Assert
        (Converted.Channels = 1 and then Converted.Depth = OpenCV.Core.Float32,
         "Convert_To should preserve channels and use the requested depth");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get
                 (Converted, Row => 0, Column => 0)),
            10.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Converted, Row => 0, Column => 1)),
                     20.0),
         "Convert_To should preserve UInt8 values in Float32 output");
      AUnit.Assertions.Assert
        (Source.Depth = OpenCV.Core.UInt8
         and then OpenCV.Core.UInt8_Access.Get (Source, Row => 0, Column => 0)
                  = 10
         and then OpenCV.Core.UInt8_Access.Get (Source, Row => 0, Column => 1)
                  = 20,
         "Convert_To must leave its UInt8 source unchanged");

      OpenCV.Core.UInt8_Access.Set
        (Source, Row => 0, Column => 0, Value => 99);
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get
                 (Converted, Row => 0, Column => 0)),
            10.0),
         "Convert_To output must not share source storage");
   end Convert_To_UInt8_To_Float32_Preserves_Metadata_And_Source;

   procedure Convert_To_Applies_Scale_And_Offset
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Converted : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set
        (Source, Row => 0, Column => 0, Value => 10);
      Converted :=
        Source.Convert_To
          (Depth => OpenCV.Core.Float32, Scale => 2.0, Offset => 5.0);
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get
                 (Converted, Row => 0, Column => 0)),
            25.0),
         "Convert_To should calculate source * Scale + Offset");
   end Convert_To_Applies_Scale_And_Offset;

   procedure Convert_To_Float32_To_UInt8_Saturates
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Converted : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set
        (Source, Row => 0, Column => 0, Value => -1.2);
      OpenCV.Core.Float32_Access.Set
        (Source, Row => 0, Column => 1, Value => 12.6);
      OpenCV.Core.Float32_Access.Set
        (Source, Row => 0, Column => 2, Value => 300.0);
      Converted := Source.Convert_To (Depth => OpenCV.Core.UInt8);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Converted, Row => 0, Column => 0) = 0
         and then OpenCV.Core.UInt8_Access.Get
                    (Converted, Row => 0, Column => 1)
                  = 13
         and then OpenCV.Core.UInt8_Access.Get
                    (Converted, Row => 0, Column => 2)
                  = 255,
         "Float32-to-UInt8 conversion must round then saturate to 0 .. 255");
   end Convert_To_Float32_To_UInt8_Saturates;

   procedure Convert_To_Preserves_Vec3_Channels
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      Converted : OpenCV.Core.Mat;
      Pixel     : OpenCV.Core.UInt8_Vec3.Vector;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set
        (Source, Row => 0, Column => 0, Value => (1.4, 127.6, 260.0));
      Converted := Source.Convert_To (Depth => OpenCV.Core.UInt8);
      Pixel :=
        OpenCV.Core.UInt8_Vec3_Access.Get (Converted, Row => 0, Column => 0);

      AUnit.Assertions.Assert
        (Converted.Channels = 3 and then Converted.Depth = OpenCV.Core.UInt8,
         "Convert_To must preserve Vec3 channel count");
      AUnit.Assertions.Assert
        (Pixel (0) = 1 and then Pixel (1) = 128 and then Pixel (2) = 255,
         "Convert_To must apply conversion independently to Vec3 components");
   end Convert_To_Preserves_Vec3_Channels;

   procedure Convert_To_Empty_Mat_Remains_Empty
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : OpenCV.Core.Mat;
      Converted : constant OpenCV.Core.Mat :=
        Source.Convert_To (Depth => OpenCV.Core.Float32);
   begin
      AUnit.Assertions.Assert
        (Converted.Is_Empty,
         "Converting a default Mat should produce an empty Mat");
   end Convert_To_Empty_Mat_Remains_Empty;

   procedure Convert_Scale_Abs_UInt8_Identity_And_Float32_Mapping
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Identity_Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Identity_Result : OpenCV.Core.Mat;
      Source          : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Converted       : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Identity_Source, 0, 0, 0);
      OpenCV.Core.UInt8_Access.Set (Identity_Source, 0, 1, 255);
      Identity_Result := Identity_Source.Convert_Scale_Abs;
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, -2.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 1, 0, 3.5);
      OpenCV.Core.Float32_Access.Set (Source, 1, 1, -4.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 2, 1.6);
      OpenCV.Core.Float32_Access.Set (Source, 1, 2, 200.0);
      Converted := Source.Convert_Scale_Abs (Scale => 2.0, Offset => 1.0);

      AUnit.Assertions.Assert
        (Identity_Result.Rows = 1
         and then Identity_Result.Columns = 2
         and then Identity_Result.Depth = OpenCV.Core.UInt8
         and then Identity_Result.Channels = 1
         and then OpenCV.Core.UInt8_Access.Get (Identity_Result, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Identity_Result, 0, 1) = 255
         and then Converted.Rows = 2
         and then Converted.Columns = 3
         and then Converted.Depth = OpenCV.Core.UInt8
         and then Converted.Channels = 1
         and then OpenCV.Core.UInt8_Access.Get (Converted, 0, 0) = 3
         and then OpenCV.Core.UInt8_Access.Get (Converted, 0, 1) = 3
         and then OpenCV.Core.UInt8_Access.Get (Converted, 1, 0) = 8
         and then OpenCV.Core.UInt8_Access.Get (Converted, 1, 1) = 7
         and then OpenCV.Core.UInt8_Access.Get (Converted, 0, 2) = 4
         and then OpenCV.Core.UInt8_Access.Get (Converted, 1, 2) = 255,
         "Convert_Scale_Abs must apply scale, offset, absolute value,"
         & " rounding,"
         & " and UInt8 saturation");
   end Convert_Scale_Abs_UInt8_Identity_And_Float32_Mapping;

   procedure Convert_Scale_Abs_Preserves_Vec3_Regions_And_Ownership
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Converted : OpenCV.Core.Mat;
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 3,
              Columns      => 3,
              Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
         View   : constant OpenCV.Core.Mat :=
           Source.Region ((X => 1, Y => 0, Width => 2, Height => 3));
      begin
         Source.Set_To (OpenCV.Core.Make_Scalar (-2.0, 1.0, 3.5));
         AUnit.Assertions.Assert
           (not View.Is_Continuous,
            "Convert_Scale_Abs test Region must be non-continuous");
         OpenCV.Core.Float32_Vec3_Access.Set
           (Source, 0, 1, (2.0, -4.0, 200.0));
         Converted := View.Convert_Scale_Abs (Scale => 2.0, Offset => 1.0);
         OpenCV.Core.Float32_Vec3_Access.Set
           (Source, 0, 1, (99.0, 99.0, 99.0));
      end;

      AUnit.Assertions.Assert
        (not Converted.Is_Empty
         and then Converted.Is_Continuous
         and then Converted.Rows = 3
         and then Converted.Columns = 2
         and then Converted.Depth = OpenCV.Core.UInt8
         and then Converted.Channels = 3
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Converted, 0, 0)
                  = (5, 7, 255)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Converted, 0, 1)
                  = (3, 3, 8),
         "Convert_Scale_Abs must process non-continuous Vec3 Regions"
         & " per channel"
         & " and retain independent result storage after source finalization");
   end Convert_Scale_Abs_Preserves_Vec3_Regions_And_Ownership;

   procedure Convert_Scale_Abs_Empty_Mat_Remains_Empty
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Empty_Source : OpenCV.Core.Mat;
      Empty_Result : constant OpenCV.Core.Mat :=
        Empty_Source.Convert_Scale_Abs;
   begin
      AUnit.Assertions.Assert
        (Empty_Result.Is_Empty,
         "Convert_Scale_Abs must leave an empty Mat empty");
   end Convert_Scale_Abs_Empty_Mat_Remains_Empty;

   procedure Float32_Matx3x3_Has_Value_And_Zero_Based_Index_Semantics
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Float32_Matx3x3.Matrix :=
        ((1.25, -2.5, 3.75), (4.5, 5.25, -6.75), (7.0, 8.125, 9.875));
      Copy   : OpenCV.Core.Float32_Matx3x3.Matrix := Source;
   begin
      AUnit.Assertions.Assert
        (Approximately_Equal (Long_Float (Source (0, 0)), 1.25)
         and then Approximately_Equal (Long_Float (Source (1, 2)), -6.75)
         and then Approximately_Equal (Long_Float (Source (2, 1)), 8.125),
         "Float32 Matx3x3 must preserve zero-based row and column indexing");

      Copy (1, 2) := 42.0;

      AUnit.Assertions.Assert
        (Approximately_Equal (Long_Float (Copy (1, 2)), 42.0)
         and then Approximately_Equal (Long_Float (Source (1, 2)), -6.75),
         "Float32 Matx3x3 assignment must use independent Ada value"
         & " semantics");
   end Float32_Matx3x3_Has_Value_And_Zero_Based_Index_Semantics;

   procedure Float32_Matx3x3_To_Mat_Copies_Metadata_Values_And_Storage
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Fixed : OpenCV.Core.Float32_Matx3x3.Matrix :=
        ((1.25, -2.5, 3.75), (4.5, 5.25, -6.75), (7.0, 8.125, 9.875));
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Float32_Matx3x3_Conversions.To_Mat (Fixed);
   begin
      AUnit.Assertions.Assert
        (Image.Rows = 3
         and then Image.Columns = 3
         and then Image.Depth = OpenCV.Core.Float32
         and then Image.Channels = 1,
         "Matx3x3 To_Mat must create a 3x3 Float32 single-channel Mat");

      for Row in Fixed'Range (1) loop
         for Column in Fixed'Range (2) loop
            AUnit.Assertions.Assert
              (Approximately_Equal
                 (Long_Float
                    (OpenCV.Core.Float32_Access.Get (Image, Row, Column)),
                  Long_Float (Fixed (Row, Column))),
               "Matx3x3 To_Mat must copy every element in row-major order");
         end loop;
      end loop;

      Fixed (0, 0) := 42.0;

      AUnit.Assertions.Assert
        (Approximately_Equal (Long_Float (Fixed (0, 0)), 42.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (Image, 0, 0)),
                     1.25),
         "Matx3x3 To_Mat output must not share storage with the Ada value");
   end Float32_Matx3x3_To_Mat_Copies_Metadata_Values_And_Storage;

   procedure Mat_To_Float32_Matx3x3_Copies_Values_And_Storage
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Fixed : OpenCV.Core.Float32_Matx3x3.Matrix;
   begin
      for Row in OpenCV.Core.Float32_Matx3x3.Row_Index loop
         for Column in OpenCV.Core.Float32_Matx3x3.Column_Index loop
            OpenCV.Core.Float32_Access.Set
              (Image,
               Row,
               Column,
               OpenCV.Core.Float32_Value (Row * 3 + Column) + 0.25);
         end loop;
      end loop;

      Fixed := OpenCV.Core.Float32_Matx3x3_Conversions.To_Matx3x3 (Image);

      for Row in Fixed'Range (1) loop
         for Column in Fixed'Range (2) loop
            AUnit.Assertions.Assert
              (Approximately_Equal
                 (Long_Float (Fixed (Row, Column)),
                  Long_Float (Row * 3 + Column) + 0.25),
               "Mat To_Matx3x3 must copy every Float32 element");
         end loop;
      end loop;

      OpenCV.Core.Float32_Access.Set (Image, 2, 2, 99.0);

      AUnit.Assertions.Assert
        (Approximately_Equal (Long_Float (Fixed (2, 2)), 8.25),
         "Mat To_Matx3x3 output must not share storage with the Mat");
   end Mat_To_Float32_Matx3x3_Copies_Values_And_Storage;

   procedure Float32_Matx3x3_Converts_Non_Continuous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 5,
           Columns      => 5,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      View   : constant OpenCV.Core.Mat :=
        Source.Region ((X => 1, Y => 1, Width => 3, Height => 3));
      Fixed  : OpenCV.Core.Float32_Matx3x3.Matrix;
   begin
      for Row in 0 .. 4 loop
         for Column in 0 .. 4 loop
            OpenCV.Core.Float32_Access.Set
              (Source,
               Row,
               Column,
               OpenCV.Core.Float32_Value (Row * 10 + Column));
         end loop;
      end loop;

      Fixed := OpenCV.Core.Float32_Matx3x3_Conversions.To_Matx3x3 (View);

      AUnit.Assertions.Assert
        (not View.Is_Continuous
         and then Approximately_Equal (Long_Float (Fixed (0, 0)), 11.0)
         and then Approximately_Equal (Long_Float (Fixed (1, 2)), 23.0)
         and then Approximately_Equal (Long_Float (Fixed (2, 1)), 32.0),
         "Matx3x3 conversion must copy values from a non-continuous Region");
   end Float32_Matx3x3_Converts_Non_Continuous_Region;

   procedure Float32_Matx3x3_Rejects_Incompatible_Mat_Layouts
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Wrong_Rows     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Wrong_Columns  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Wrong_Depth    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Wrong_Channels : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));

      procedure Convert_Wrong_Rows is
         Ignored : constant OpenCV.Core.Float32_Matx3x3.Matrix :=
           OpenCV.Core.Float32_Matx3x3_Conversions.To_Matx3x3 (Wrong_Rows);
      begin
         pragma Unreferenced (Ignored);
      end Convert_Wrong_Rows;

      procedure Convert_Wrong_Columns is
         Ignored : constant OpenCV.Core.Float32_Matx3x3.Matrix :=
           OpenCV.Core.Float32_Matx3x3_Conversions.To_Matx3x3 (Wrong_Columns);
      begin
         pragma Unreferenced (Ignored);
      end Convert_Wrong_Columns;

      procedure Convert_Wrong_Depth is
         Ignored : constant OpenCV.Core.Float32_Matx3x3.Matrix :=
           OpenCV.Core.Float32_Matx3x3_Conversions.To_Matx3x3 (Wrong_Depth);
      begin
         pragma Unreferenced (Ignored);
      end Convert_Wrong_Depth;

      procedure Convert_Wrong_Channels is
         Ignored : constant OpenCV.Core.Float32_Matx3x3.Matrix :=
           OpenCV.Core.Float32_Matx3x3_Conversions.To_Matx3x3 (Wrong_Channels);
      begin
         pragma Unreferenced (Ignored);
      end Convert_Wrong_Channels;
   begin
      Assert_Raises_OpenCV_Error
        (Convert_Wrong_Rows'Access,
         "Matx3x3 conversion must reject a Mat with wrong rows");
      Assert_Raises_OpenCV_Error
        (Convert_Wrong_Columns'Access,
         "Matx3x3 conversion must reject a Mat with wrong columns");
      Assert_Raises_OpenCV_Error
        (Convert_Wrong_Depth'Access,
         "Matx3x3 conversion must reject a Mat with wrong depth");
      Assert_Raises_OpenCV_Error
        (Convert_Wrong_Channels'Access,
         "Matx3x3 conversion must reject a Mat with wrong channel count");
   end Float32_Matx3x3_Rejects_Incompatible_Mat_Layouts;

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Convert_To UInt8 to Float32 preserves metadata and source",
            Convert_To_UInt8_To_Float32_Preserves_Metadata_And_Source'Access));
      Result.Add_Test
        (Caller.Create
           ("Convert_To applies scale and offset",
            Convert_To_Applies_Scale_And_Offset'Access));
      Result.Add_Test
        (Caller.Create
           ("Convert_To Float32 to UInt8 saturates",
            Convert_To_Float32_To_UInt8_Saturates'Access));
      Result.Add_Test
        (Caller.Create
           ("Convert_To preserves Vec3 channels",
            Convert_To_Preserves_Vec3_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("Convert_To empty Mat remains empty",
            Convert_To_Empty_Mat_Remains_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("Convert_Scale_Abs UInt8 identity and Float32 mapping",
            Convert_Scale_Abs_UInt8_Identity_And_Float32_Mapping'Access));
      Result.Add_Test
        (Caller.Create
           ("Convert_Scale_Abs preserves Vec3 Regions and ownership",
            Convert_Scale_Abs_Preserves_Vec3_Regions_And_Ownership'Access));
      Result.Add_Test
        (Caller.Create
           ("Convert_Scale_Abs empty Mat remains empty",
            Convert_Scale_Abs_Empty_Mat_Remains_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Matx3x3 has value and zero-based index semantics",
            Float32_Matx3x3_Has_Value_And_Zero_Based_Index_Semantics'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Matx3x3 To_Mat copies metadata, values, and storage",
            Float32_Matx3x3_To_Mat_Copies_Metadata_Values_And_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat To_Float32_Matx3x3 copies values and storage",
            Mat_To_Float32_Matx3x3_Copies_Values_And_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Matx3x3 converts non-continuous Region",
            Float32_Matx3x3_Converts_Non_Continuous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Matx3x3 rejects incompatible Mat layouts",
            Float32_Matx3x3_Rejects_Incompatible_Mat_Layouts'Access));
      return Result'Access;
   end Suite;

end Mat_Conversion_Tests;
