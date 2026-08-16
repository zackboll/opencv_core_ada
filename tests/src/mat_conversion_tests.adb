with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float32_Matx3x3;
with OpenCV.Core.Float32_Matx3x3_Conversions;
with OpenCV.Core.Float32_Vec3;
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
   use type OpenCV.Core.Mat_Size;
   use type OpenCV.Core.Float32_Access.Float32_Classification;

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

   function Inversion_Table return OpenCV.Core.Mat is
      Table : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 256,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
   begin
      for Index in 0 .. 255 loop
         OpenCV.Core.UInt8_Access.Set
           (Table,
            Row    => 0,
            Column => Index,
            Value  => Interfaces.Unsigned_8 (255 - Index));
      end loop;
      return Table;
   end Inversion_Table;

   procedure Apply_LUT_UInt8_Inversion_Mapping (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Table  : constant OpenCV.Core.Mat := Inversion_Table;
      Result : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 0);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 1);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 2, 127);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 3, 255);
      Result := Source.Apply_LUT (Table);

      AUnit.Assertions.Assert
        (Result.Rows = 1
         and then Result.Columns = 4
         and then Result.Depth = OpenCV.Core.UInt8
         and then Result.Channels = 1
         and then OpenCV.Core.UInt8_Access.Get (Result, 0, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Result, 0, 1) = 254
         and then OpenCV.Core.UInt8_Access.Get (Result, 0, 2) = 128
         and then OpenCV.Core.UInt8_Access.Get (Result, 0, 3) = 0,
         "Apply_LUT must invert UInt8 values through a 256-entry table");
   end Apply_LUT_UInt8_Inversion_Mapping;

   procedure Apply_LUT_Float32_Table_Changes_Output_Depth
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Table  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 256,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Result : OpenCV.Core.Mat;
   begin
      for Index in 0 .. 255 loop
         OpenCV.Core.Float32_Access.Set
           (Table,
            Row    => 0,
            Column => Index,
            Value  => Interfaces.IEEE_Float_32 (Index) * 0.5);
      end loop;
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 0);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 1);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 2, 127);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 3, 255);
      Result := Source.Apply_LUT (Table);

      AUnit.Assertions.Assert
        (Result.Rows = 1
         and then Result.Columns = 4
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 1
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 0)),
                     0.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 1)),
                     0.5)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 2)),
                     63.5)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 3)),
                     127.5),
         "Apply_LUT output depth must follow the table depth");
   end Apply_LUT_Float32_Table_Changes_Output_Depth;

   procedure Apply_LUT_Single_Channel_Table_On_Vec3
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Result : OpenCV.Core.Mat;
      Pixel  : OpenCV.Core.UInt8_Vec3.Vector;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Source, Row => 0, Column => 0, Value => (0, 1, 255));
      Result := Source.Apply_LUT (Inversion_Table);
      Pixel :=
        OpenCV.Core.UInt8_Vec3_Access.Get (Result, Row => 0, Column => 0);

      AUnit.Assertions.Assert
        (Result.Channels = 3
         and then Result.Depth = OpenCV.Core.UInt8
         and then Pixel (0) = 255
         and then Pixel (1) = 254
         and then Pixel (2) = 0,
         "A one-channel LUT must be applied independently to each Vec3"
         & " channel");
   end Apply_LUT_Single_Channel_Table_On_Vec3;

   procedure Apply_LUT_Per_Channel_Table (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Table  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 256,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Result : OpenCV.Core.Mat;
      Pixel  : OpenCV.Core.UInt8_Vec3.Vector;
   begin
      for Index in 0 .. 255 loop
         OpenCV.Core.UInt8_Vec3_Access.Set
           (Table,
            Row    => 0,
            Column => Index,
            Value  =>
              (Interfaces.Unsigned_8 (Index),
               Interfaces.Unsigned_8 (255 - Index),
               Interfaces.Unsigned_8
                 (if Index + 10 > 255 then 255 else Index + 10)));
      end loop;
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Source, Row => 0, Column => 0, Value => (0, 1, 255));
      Result := Source.Apply_LUT (Table);
      Pixel :=
        OpenCV.Core.UInt8_Vec3_Access.Get (Result, Row => 0, Column => 0);

      AUnit.Assertions.Assert
        (Result.Channels = 3
         and then Pixel (0) = 0
         and then Pixel (1) = 254
         and then Pixel (2) = 255,
         "A matching multi-channel LUT must be applied per source channel");
   end Apply_LUT_Per_Channel_Table;

   procedure Apply_LUT_Noncontiguous_Region_And_Independent_Storage
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Mat;
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 3,
              Columns      => 3,
              Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
         View   : constant OpenCV.Core.Mat :=
           Source.Region ((X => 1, Y => 0, Width => 2, Height => 3));
      begin
         Source.Set_To (OpenCV.Core.Make_Scalar (1.0));
         OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 0);
         OpenCV.Core.UInt8_Access.Set (Source, 0, 2, 255);
         AUnit.Assertions.Assert
           (not View.Is_Continuous,
            "Apply_LUT test Region must be non-continuous");
         Result := View.Apply_LUT (Inversion_Table);
         OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 99);
      end;

      AUnit.Assertions.Assert
        (not Result.Is_Empty
         and then Result.Is_Continuous
         and then Result.Rows = 3
         and then Result.Columns = 2
         and then Result.Depth = OpenCV.Core.UInt8
         and then Result.Channels = 1
         and then OpenCV.Core.UInt8_Access.Get (Result, 0, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Result, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Result, 1, 0) = 254
         and then OpenCV.Core.UInt8_Access.Get (Result, 1, 1) = 254,
         "Apply_LUT must accept a non-contiguous Region and keep independent"
         & " result storage after source finalization");
   end Apply_LUT_Noncontiguous_Region_And_Independent_Storage;

   procedure Apply_LUT_Int8_Indexes_Stored_Byte_Pattern
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Float_Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Source       : OpenCV.Core.Mat;
      Result       : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Float_Source, 0, 0, -128.0);
      OpenCV.Core.Float32_Access.Set (Float_Source, 0, 1, -1.0);
      OpenCV.Core.Float32_Access.Set (Float_Source, 0, 2, 0.0);
      OpenCV.Core.Float32_Access.Set (Float_Source, 0, 3, 127.0);
      Source := Float_Source.Convert_To (Depth => OpenCV.Core.Int8);
      Result := Source.Apply_LUT (Inversion_Table);

      AUnit.Assertions.Assert
        (Source.Depth = OpenCV.Core.Int8
         and then Result.Depth = OpenCV.Core.UInt8
         and then OpenCV.Core.UInt8_Access.Get (Result, 0, 0) = 127
         and then OpenCV.Core.UInt8_Access.Get (Result, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Result, 0, 2) = 255
         and then OpenCV.Core.UInt8_Access.Get (Result, 0, 3) = 128,
         "Int8 Apply_LUT must index the table by the stored 8-bit pattern");
   end Apply_LUT_Int8_Indexes_Stored_Byte_Pattern;

   procedure Apply_LUT_Empty_Zero_By_Zero_Remains_Empty
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 0,
           Columns      => 0,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Result : constant OpenCV.Core.Mat := Source.Apply_LUT (Inversion_Table);
   begin
      AUnit.Assertions.Assert
        (Result.Is_Empty
         and then Result.Rows = 0
         and then Result.Columns = 0
         and then Result.Depth = OpenCV.Core.UInt8
         and then Result.Channels = 1,
         "Apply_LUT must preserve a 0x0 UInt8 source as an empty result");
   end Apply_LUT_Empty_Zero_By_Zero_Remains_Empty;

   procedure Apply_LUT_Rejects_Default_Empty_Source
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat;
      Table  : constant OpenCV.Core.Mat := Inversion_Table;

      procedure Apply_Default_Empty is
         Ignored : constant OpenCV.Core.Mat := Source.Apply_LUT (Table);
      begin
         pragma Unreferenced (Ignored);
      end Apply_Default_Empty;
   begin
      Assert_Raises_OpenCV_Error
        (Apply_Default_Empty'Access,
         "Apply_LUT must reject a default empty Mat");
   end Apply_LUT_Rejects_Default_Empty_Source;
   procedure Apply_LUT_Rejects_Invalid_Table_And_Source
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Valid  : constant OpenCV.Core.Mat := Inversion_Table;

      procedure Apply_Wrong_Size is
         Table   : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 1,
              Columns      => 255,
              Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
         Ignored : constant OpenCV.Core.Mat := Source.Apply_LUT (Table);
      begin
         pragma Unreferenced (Ignored);
      end Apply_Wrong_Size;

      procedure Apply_Wrong_Channels is
         Table   : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 1,
              Columns      => 256,
              Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 2));
         Ignored : constant OpenCV.Core.Mat := Source.Apply_LUT (Table);
      begin
         pragma Unreferenced (Ignored);
      end Apply_Wrong_Channels;

      procedure Apply_Unsupported_Source is
         Bad     : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 1,
              Columns      => 1,
              Element_Type => (Depth => OpenCV.Core.UInt16, Channels => 1));
         Ignored : constant OpenCV.Core.Mat := Bad.Apply_LUT (Valid);
      begin
         pragma Unreferenced (Ignored);
      end Apply_Unsupported_Source;

      procedure Apply_Noncontinuous_Table is
         Wide    : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 256,
              Columns      => 2,
              Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
         Table   : constant OpenCV.Core.Mat := Wide.Column_View (0);
         Ignored : OpenCV.Core.Mat;
      begin
         AUnit.Assertions.Assert
           (not Table.Is_Continuous and then Table.Total = 256,
            "Apply_LUT rejection test needs a 256-entry non-continuous table");
         Ignored := Source.Apply_LUT (Table);
         pragma Unreferenced (Ignored);
      end Apply_Noncontinuous_Table;

      procedure Apply_Float16_Table is
         Table   : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 1,
              Columns      => 256,
              Element_Type => (Depth => OpenCV.Core.Float16, Channels => 1));
         Ignored : constant OpenCV.Core.Mat := Source.Apply_LUT (Table);
      begin
         pragma Unreferenced (Ignored);
      end Apply_Float16_Table;
   begin
      Assert_Raises_OpenCV_Error
        (Apply_Wrong_Size'Access,
         "Apply_LUT must reject a lookup table that is not 256 elements");
      Assert_Raises_OpenCV_Error
        (Apply_Wrong_Channels'Access,
         "Apply_LUT must reject a table channel count that matches neither"
         & " one nor the source");
      Assert_Raises_OpenCV_Error
        (Apply_Unsupported_Source'Access,
         "Apply_LUT must reject a non-8-bit source");
      Assert_Raises_OpenCV_Error
        (Apply_Noncontinuous_Table'Access,
         "Apply_LUT must reject a non-continuous lookup table");
      Assert_Raises_OpenCV_Error
        (Apply_Float16_Table'Access,
         "Apply_LUT must reject a Float16 lookup table");
   end Apply_LUT_Rejects_Invalid_Table_And_Source;

   procedure Sqrt_Float32_Perfect_Squares_And_Zero
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Result : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 2, 4.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 3, 9.0);
      Result := Source.Sqrt;

      AUnit.Assertions.Assert
        (Result.Rows = 1
         and then Result.Columns = 4
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 1
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 0)),
                     0.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 1)),
                     1.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 2)),
                     2.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 3)),
                     3.0),
         "Sqrt must map Float32 0, 1, 4, 9 to 0, 1, 2, 3 and keep metadata");
   end Sqrt_Float32_Perfect_Squares_And_Zero;

   procedure Sqrt_Float64_Non_Perfect_Square (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Float32_Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Source         : OpenCV.Core.Mat;
      Result         : OpenCV.Core.Mat;
      Readable       : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Float32_Source, 0, 0, 2.0);
      Source := Float32_Source.Convert_To (Depth => OpenCV.Core.Float64);
      Result := Source.Sqrt;
      Readable := Result.Convert_To (Depth => OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (Result.Rows = 1
         and then Result.Columns = 1
         and then Result.Depth = OpenCV.Core.Float64
         and then Result.Channels = 1
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Readable, 0, 0)),
                     1.414_213_562,
                     Tolerance => 0.000_001),
         "Sqrt must preserve Float64 depth and compute a non-perfect square");
   end Sqrt_Float64_Non_Perfect_Square;

   procedure Sqrt_Negative_And_Nonfinite_Follow_OpenCV
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Negative    : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Numerator   : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Denominator : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Special     : OpenCV.Core.Mat;
      Neg_Result  : OpenCV.Core.Mat;
      Special_Out : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Negative, 0, 0, -4.0);
      Neg_Result := Negative.Sqrt;
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 1, -1.0);
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 2, 0.0);
      Denominator.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Special := Numerator.Divide (Denominator);
      Special_Out := Special.Sqrt;

      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Classify (Neg_Result, 0, 0)
         = OpenCV.Core.Float32_Access.Not_A_Number,
         "OpenCV 4.10 Sqrt of a negative finite value must be NaN");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Classify (Special, 0, 0)
         = OpenCV.Core.Float32_Access.Positive_Infinity
         and then OpenCV.Core.Float32_Access.Classify (Special, 0, 1)
                  = OpenCV.Core.Float32_Access.Negative_Infinity
         and then OpenCV.Core.Float32_Access.Classify (Special, 0, 2)
                  = OpenCV.Core.Float32_Access.Not_A_Number
         and then OpenCV.Core.Float32_Access.Classify (Special_Out, 0, 0)
                  = OpenCV.Core.Float32_Access.Positive_Infinity
         and then OpenCV.Core.Float32_Access.Classify (Special_Out, 0, 1)
                  = OpenCV.Core.Float32_Access.Not_A_Number
         and then OpenCV.Core.Float32_Access.Classify (Special_Out, 0, 2)
                  = OpenCV.Core.Float32_Access.Not_A_Number,
         "OpenCV 4.10 Sqrt must map +Inf to +Inf and -Inf/NaN to NaN");
   end Sqrt_Negative_And_Nonfinite_Follow_OpenCV;

   procedure Sqrt_Multi_Channel_Vec3 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      Result : OpenCV.Core.Mat;
      Pixel  : OpenCV.Core.Float32_Vec3.Vector;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set
        (Source, Row => 0, Column => 0, Value => (4.0, 9.0, 0.0));
      Result := Source.Sqrt;
      Pixel :=
        OpenCV.Core.Float32_Vec3_Access.Get (Result, Row => 0, Column => 0);

      AUnit.Assertions.Assert
        (Result.Channels = 3
         and then Result.Depth = OpenCV.Core.Float32
         and then Approximately_Equal (Long_Float (Pixel (0)), 2.0)
         and then Approximately_Equal (Long_Float (Pixel (1)), 3.0)
         and then Approximately_Equal (Long_Float (Pixel (2)), 0.0),
         "Sqrt must process each Float32 Vec3 channel independently");
   end Sqrt_Multi_Channel_Vec3;

   procedure Sqrt_Noncontiguous_Region_And_Independent_Storage
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Mat;
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 3,
              Columns      => 3,
              Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
         View   : constant OpenCV.Core.Mat :=
           Source.Region ((X => 1, Y => 0, Width => 2, Height => 3));
      begin
         Source.Set_To (OpenCV.Core.Make_Scalar (4.0));
         OpenCV.Core.Float32_Access.Set (Source, 0, 1, 9.0);
         AUnit.Assertions.Assert
           (not View.Is_Continuous, "Sqrt test Region must be non-continuous");
         Result := View.Sqrt;
         OpenCV.Core.Float32_Access.Set (Source, 0, 1, 100.0);
      end;

      AUnit.Assertions.Assert
        (not Result.Is_Empty
         and then Result.Is_Continuous
         and then Result.Rows = 3
         and then Result.Columns = 2
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 1
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 0)),
                     3.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 1)),
                     2.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 1, 0)),
                     2.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 1, 1)),
                     2.0),
         "Sqrt must accept a non-contiguous Region and keep independent"
         & " result storage after source finalization");
   end Sqrt_Noncontiguous_Region_And_Independent_Storage;

   procedure Sqrt_Typed_Empty_And_Default_Empty
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Empty32  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 0,
           Columns      => 0,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Empty64  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 0,
           Columns      => 0,
           Element_Type => (Depth => OpenCV.Core.Float64, Channels => 2));
      Result32 : constant OpenCV.Core.Mat := Empty32.Sqrt;
      Result64 : constant OpenCV.Core.Mat := Empty64.Sqrt;
      Default  : OpenCV.Core.Mat;

      procedure Sqrt_Default_Empty is
         Ignored : constant OpenCV.Core.Mat := Default.Sqrt;
      begin
         pragma Unreferenced (Ignored);
      end Sqrt_Default_Empty;
   begin
      AUnit.Assertions.Assert
        (Result32.Is_Empty
         and then Result32.Rows = 0
         and then Result32.Columns = 0
         and then Result32.Depth = OpenCV.Core.Float32
         and then Result32.Channels = 1,
         "Sqrt must preserve a typed 0x0 Float32 source as an empty result");
      AUnit.Assertions.Assert
        (Result64.Is_Empty
         and then Result64.Rows = 0
         and then Result64.Columns = 0
         and then Result64.Depth = OpenCV.Core.Float64
         and then Result64.Channels = 2,
         "Sqrt must preserve a typed 0x0 Float64 source as an empty result");
      Assert_Raises_OpenCV_Error
        (Sqrt_Default_Empty'Access, "Sqrt must reject a default empty Mat");
   end Sqrt_Typed_Empty_And_Default_Empty;

   procedure Sqrt_Rejects_Unsupported_Depths (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);

      procedure Sqrt_UInt8 is
         Source  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 1,
              Columns      => 1,
              Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
         Ignored : constant OpenCV.Core.Mat := Source.Sqrt;
      begin
         pragma Unreferenced (Ignored);
      end Sqrt_UInt8;

      procedure Sqrt_Int32 is
         Source  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 1,
              Columns      => 1,
              Element_Type => (Depth => OpenCV.Core.Int32, Channels => 1));
         Ignored : constant OpenCV.Core.Mat := Source.Sqrt;
      begin
         pragma Unreferenced (Ignored);
      end Sqrt_Int32;

      procedure Sqrt_Float16 is
         Source  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 1,
              Columns      => 1,
              Element_Type => (Depth => OpenCV.Core.Float16, Channels => 1));
         Ignored : constant OpenCV.Core.Mat := Source.Sqrt;
      begin
         pragma Unreferenced (Ignored);
      end Sqrt_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Sqrt_UInt8'Access, "Sqrt must reject a UInt8 source");
      Assert_Raises_OpenCV_Error
        (Sqrt_Int32'Access, "Sqrt must reject an Int32 source");
      Assert_Raises_OpenCV_Error
        (Sqrt_Float16'Access, "Sqrt must reject a Float16 source");
   end Sqrt_Rejects_Unsupported_Depths;

   procedure Exp_Float32_Zero_One_And_Negative_One
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Result : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 2, -1.0);
      Result := Source.Exp;

      AUnit.Assertions.Assert
        (Result.Rows = 1
         and then Result.Columns = 3
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 1
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 0)),
                     1.0,
                     Tolerance => 0.000_007)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 1)),
                     2.718_281_828,
                     Tolerance => 0.000_020)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 2)),
                     0.367_879_441,
                     Tolerance => 0.000_003),
         "Exp must map Float32 0, 1, -1 to 1, e, 1/e and keep metadata");
   end Exp_Float32_Zero_One_And_Negative_One;

   procedure Exp_Float64_Representative_Finite_Values
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Float32_Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Source         : OpenCV.Core.Mat;
      Result         : OpenCV.Core.Mat;
      Readable       : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Float32_Source, 0, 0, 0.5);
      OpenCV.Core.Float32_Access.Set (Float32_Source, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Float32_Source, 0, 2, -0.5);
      Source := Float32_Source.Convert_To (Depth => OpenCV.Core.Float64);
      Result := Source.Exp;
      Readable := Result.Convert_To (Depth => OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (Result.Rows = 1
         and then Result.Columns = 3
         and then Result.Depth = OpenCV.Core.Float64
         and then Result.Channels = 1
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Readable, 0, 0)),
                     1.648_721_271,
                     Tolerance => 0.000_001)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Readable, 0, 1)),
                     7.389_056_099,
                     Tolerance => 0.000_001)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Readable, 0, 2)),
                     0.606_530_660,
                     Tolerance => 0.000_001),
         "Exp must preserve Float64 depth and compute representative"
         & " finite values");
   end Exp_Float64_Representative_Finite_Values;

   procedure Exp_Multi_Channel_Vec3 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      Result : OpenCV.Core.Mat;
      Pixel  : OpenCV.Core.Float32_Vec3.Vector;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set
        (Source, Row => 0, Column => 0, Value => (0.0, 1.0, -1.0));
      Result := Source.Exp;
      Pixel :=
        OpenCV.Core.Float32_Vec3_Access.Get (Result, Row => 0, Column => 0);

      AUnit.Assertions.Assert
        (Result.Channels = 3
         and then Result.Depth = OpenCV.Core.Float32
         and then Approximately_Equal
                    (Long_Float (Pixel (0)), 1.0, Tolerance => 0.000_007)
         and then Approximately_Equal
                    (Long_Float (Pixel (1)),
                     2.718_281_828,
                     Tolerance => 0.000_020)
         and then Approximately_Equal
                    (Long_Float (Pixel (2)),
                     0.367_879_441,
                     Tolerance => 0.000_003),
         "Exp must process each Float32 Vec3 channel independently");
   end Exp_Multi_Channel_Vec3;

   procedure Exp_Noncontiguous_Region_And_Independent_Storage
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Mat;
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 3,
              Columns      => 3,
              Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
         View   : constant OpenCV.Core.Mat :=
           Source.Region ((X => 1, Y => 0, Width => 2, Height => 3));
      begin
         Source.Set_To (OpenCV.Core.Make_Scalar (0.0));
         OpenCV.Core.Float32_Access.Set (Source, 0, 1, 1.0);
         AUnit.Assertions.Assert
           (not View.Is_Continuous, "Exp test Region must be non-continuous");
         Result := View.Exp;
         OpenCV.Core.Float32_Access.Set (Source, 0, 1, 100.0);
      end;

      AUnit.Assertions.Assert
        (not Result.Is_Empty
         and then Result.Is_Continuous
         and then Result.Rows = 3
         and then Result.Columns = 2
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 1
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 0)),
                     2.718_281_828,
                     Tolerance => 0.000_020)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 1)),
                     1.0,
                     Tolerance => 0.000_007)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 1, 0)),
                     1.0,
                     Tolerance => 0.000_007)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 1, 1)),
                     1.0,
                     Tolerance => 0.000_007),
         "Exp must accept a non-contiguous Region and keep independent"
         & " result storage after source finalization");
   end Exp_Noncontiguous_Region_And_Independent_Storage;

   procedure Exp_Typed_Empty_And_Default_Empty (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Empty32  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 0,
           Columns      => 0,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Empty64  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 0,
           Columns      => 0,
           Element_Type => (Depth => OpenCV.Core.Float64, Channels => 2));
      Result32 : constant OpenCV.Core.Mat := Empty32.Exp;
      Result64 : constant OpenCV.Core.Mat := Empty64.Exp;
      Default  : OpenCV.Core.Mat;

      procedure Exp_Default_Empty is
         Ignored : constant OpenCV.Core.Mat := Default.Exp;
      begin
         pragma Unreferenced (Ignored);
      end Exp_Default_Empty;
   begin
      AUnit.Assertions.Assert
        (Result32.Is_Empty
         and then Result32.Rows = 0
         and then Result32.Columns = 0
         and then Result32.Depth = OpenCV.Core.Float32
         and then Result32.Channels = 1,
         "Exp must preserve a typed 0x0 Float32 source as an empty result");
      AUnit.Assertions.Assert
        (Result64.Is_Empty
         and then Result64.Rows = 0
         and then Result64.Columns = 0
         and then Result64.Depth = OpenCV.Core.Float64
         and then Result64.Channels = 2,
         "Exp must preserve a typed 0x0 Float64 source as an empty result");
      Assert_Raises_OpenCV_Error
        (Exp_Default_Empty'Access, "Exp must reject a default empty Mat");
   end Exp_Typed_Empty_And_Default_Empty;

   procedure Exp_Rejects_Unsupported_Depths (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);

      procedure Exp_UInt8 is
         Source  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 1,
              Columns      => 1,
              Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
         Ignored : constant OpenCV.Core.Mat := Source.Exp;
      begin
         pragma Unreferenced (Ignored);
      end Exp_UInt8;

      procedure Exp_Int32 is
         Source  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 1,
              Columns      => 1,
              Element_Type => (Depth => OpenCV.Core.Int32, Channels => 1));
         Ignored : constant OpenCV.Core.Mat := Source.Exp;
      begin
         pragma Unreferenced (Ignored);
      end Exp_Int32;

      procedure Exp_Float16 is
         Source  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 1,
              Columns      => 1,
              Element_Type => (Depth => OpenCV.Core.Float16, Channels => 1));
         Ignored : constant OpenCV.Core.Mat := Source.Exp;
      begin
         pragma Unreferenced (Ignored);
      end Exp_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Exp_UInt8'Access, "Exp must reject a UInt8 source");
      Assert_Raises_OpenCV_Error
        (Exp_Int32'Access, "Exp must reject an Int32 source");
      Assert_Raises_OpenCV_Error
        (Exp_Float16'Access, "Exp must reject a Float16 source");
   end Exp_Rejects_Unsupported_Depths;

   procedure Log_Float32_Positive_Known_Values (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Result : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 2.718_281_828);
      OpenCV.Core.Float32_Access.Set (Source, 0, 2, 7.389_056_099);
      Result := Source.Log;

      AUnit.Assertions.Assert
        (Result.Rows = 1
         and then Result.Columns = 3
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 1
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 0)),
                     0.0,
                     Tolerance => 0.000_010)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 1)),
                     1.0,
                     Tolerance => 0.000_010)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 2)),
                     2.0,
                     Tolerance => 0.000_020),
         "Log must map Float32 1, e, e^2 to 0, 1, 2 and keep metadata");
   end Log_Float32_Positive_Known_Values;

   procedure Log_Float64_Representative_Finite_Values
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Float32_Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Source         : OpenCV.Core.Mat;
      Result         : OpenCV.Core.Mat;
      Readable       : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Float32_Source, 0, 0, 0.5);
      OpenCV.Core.Float32_Access.Set (Float32_Source, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Float32_Source, 0, 2, 2.718_281_828);
      Source := Float32_Source.Convert_To (Depth => OpenCV.Core.Float64);
      Result := Source.Log;
      Readable := Result.Convert_To (Depth => OpenCV.Core.Float32);

      AUnit.Assertions.Assert
        (Result.Rows = 1
         and then Result.Columns = 3
         and then Result.Depth = OpenCV.Core.Float64
         and then Result.Channels = 1
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Readable, 0, 0)),
                     -0.693_147_181,
                     Tolerance => 0.000_001)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Readable, 0, 1)),
                     0.693_147_181,
                     Tolerance => 0.000_001)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Readable, 0, 2)),
                     1.0,
                     Tolerance => 0.000_001),
         "Log must preserve Float64 depth and compute representative"
         & " finite values");
   end Log_Float64_Representative_Finite_Values;

   procedure Log_Negative_And_Zero_Are_Undefined_But_Accepted
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
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, -1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 0.0);
      Result := Source.Log;

      AUnit.Assertions.Assert
        (Result.Rows = 1
         and then Result.Columns = 2
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 1
         and then not Result.Is_Empty,
         "OpenCV 4.10 Log accepts zero and negative finite inputs; the"
         & " numeric output is undefined");
   end Log_Negative_And_Zero_Are_Undefined_But_Accepted;

   procedure Log_Multi_Channel_Vec3 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      Result : OpenCV.Core.Mat;
      Pixel  : OpenCV.Core.Float32_Vec3.Vector;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set
        (Source, Row => 0, Column => 0, Value => (1.0, 2.718_281_828, 0.5));
      Result := Source.Log;
      Pixel :=
        OpenCV.Core.Float32_Vec3_Access.Get (Result, Row => 0, Column => 0);

      AUnit.Assertions.Assert
        (Result.Channels = 3
         and then Result.Depth = OpenCV.Core.Float32
         and then Approximately_Equal
                    (Long_Float (Pixel (0)), 0.0, Tolerance => 0.000_010)
         and then Approximately_Equal
                    (Long_Float (Pixel (1)), 1.0, Tolerance => 0.000_010)
         and then Approximately_Equal
                    (Long_Float (Pixel (2)),
                     -0.693_147_181,
                     Tolerance => 0.000_010),
         "Log must process each Float32 Vec3 channel independently");
   end Log_Multi_Channel_Vec3;

   procedure Log_Noncontiguous_Region_And_Independent_Storage
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Mat;
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 3,
              Columns      => 3,
              Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
         View   : constant OpenCV.Core.Mat :=
           Source.Region ((X => 1, Y => 0, Width => 2, Height => 3));
      begin
         Source.Set_To (OpenCV.Core.Make_Scalar (1.0));
         OpenCV.Core.Float32_Access.Set (Source, 0, 1, 2.718_281_828);
         AUnit.Assertions.Assert
           (not View.Is_Continuous, "Log test Region must be non-continuous");
         Result := View.Log;
         OpenCV.Core.Float32_Access.Set (Source, 0, 1, 100.0);
      end;

      AUnit.Assertions.Assert
        (not Result.Is_Empty
         and then Result.Is_Continuous
         and then Result.Rows = 3
         and then Result.Columns = 2
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 1
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 0)),
                     1.0,
                     Tolerance => 0.000_010)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 1)),
                     0.0,
                     Tolerance => 0.000_010)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 1, 0)),
                     0.0,
                     Tolerance => 0.000_010)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 1, 1)),
                     0.0,
                     Tolerance => 0.000_010),
         "Log must accept a non-contiguous Region and keep independent"
         & " result storage after source finalization");
   end Log_Noncontiguous_Region_And_Independent_Storage;

   procedure Log_Typed_Empty_And_Default_Empty (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Empty32  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 0,
           Columns      => 0,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Empty64  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 0,
           Columns      => 0,
           Element_Type => (Depth => OpenCV.Core.Float64, Channels => 2));
      Result32 : constant OpenCV.Core.Mat := Empty32.Log;
      Result64 : constant OpenCV.Core.Mat := Empty64.Log;
      Default  : OpenCV.Core.Mat;

      procedure Log_Default_Empty is
         Ignored : constant OpenCV.Core.Mat := Default.Log;
      begin
         pragma Unreferenced (Ignored);
      end Log_Default_Empty;
   begin
      AUnit.Assertions.Assert
        (Result32.Is_Empty
         and then Result32.Rows = 0
         and then Result32.Columns = 0
         and then Result32.Depth = OpenCV.Core.Float32
         and then Result32.Channels = 1,
         "Log must preserve a typed 0x0 Float32 source as an empty result");
      AUnit.Assertions.Assert
        (Result64.Is_Empty
         and then Result64.Rows = 0
         and then Result64.Columns = 0
         and then Result64.Depth = OpenCV.Core.Float64
         and then Result64.Channels = 2,
         "Log must preserve a typed 0x0 Float64 source as an empty result");
      Assert_Raises_OpenCV_Error
        (Log_Default_Empty'Access, "Log must reject a default empty Mat");
   end Log_Typed_Empty_And_Default_Empty;

   procedure Log_Rejects_Unsupported_Depths (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);

      procedure Log_UInt8 is
         Source  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 1,
              Columns      => 1,
              Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
         Ignored : constant OpenCV.Core.Mat := Source.Log;
      begin
         pragma Unreferenced (Ignored);
      end Log_UInt8;

      procedure Log_Int32 is
         Source  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 1,
              Columns      => 1,
              Element_Type => (Depth => OpenCV.Core.Int32, Channels => 1));
         Ignored : constant OpenCV.Core.Mat := Source.Log;
      begin
         pragma Unreferenced (Ignored);
      end Log_Int32;

      procedure Log_Float16 is
         Source  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 1,
              Columns      => 1,
              Element_Type => (Depth => OpenCV.Core.Float16, Channels => 1));
         Ignored : constant OpenCV.Core.Mat := Source.Log;
      begin
         pragma Unreferenced (Ignored);
      end Log_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Log_UInt8'Access, "Log must reject a UInt8 source");
      Assert_Raises_OpenCV_Error
        (Log_Int32'Access, "Log must reject an Int32 source");
      Assert_Raises_OpenCV_Error
        (Log_Float16'Access, "Log must reject a Float16 source");
   end Log_Rejects_Unsupported_Depths;

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
           ("Apply_LUT UInt8 inversion mapping",
            Apply_LUT_UInt8_Inversion_Mapping'Access));
      Result.Add_Test
        (Caller.Create
           ("Apply_LUT Float32 table changes output depth",
            Apply_LUT_Float32_Table_Changes_Output_Depth'Access));
      Result.Add_Test
        (Caller.Create
           ("Apply_LUT single-channel table on Vec3",
            Apply_LUT_Single_Channel_Table_On_Vec3'Access));
      Result.Add_Test
        (Caller.Create
           ("Apply_LUT per-channel table",
            Apply_LUT_Per_Channel_Table'Access));
      Result.Add_Test
        (Caller.Create
           ("Apply_LUT noncontiguous Region and independent storage",
            Apply_LUT_Noncontiguous_Region_And_Independent_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Apply_LUT Int8 indexes stored byte pattern",
            Apply_LUT_Int8_Indexes_Stored_Byte_Pattern'Access));
      Result.Add_Test
        (Caller.Create
           ("Apply_LUT empty 0x0 remains empty",
            Apply_LUT_Empty_Zero_By_Zero_Remains_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("Apply_LUT rejects default empty source",
            Apply_LUT_Rejects_Default_Empty_Source'Access));
      Result.Add_Test
        (Caller.Create
           ("Apply_LUT rejects invalid table and source",
            Apply_LUT_Rejects_Invalid_Table_And_Source'Access));
      Result.Add_Test
        (Caller.Create
           ("Sqrt Float32 perfect squares and zero",
            Sqrt_Float32_Perfect_Squares_And_Zero'Access));
      Result.Add_Test
        (Caller.Create
           ("Sqrt Float64 non-perfect square",
            Sqrt_Float64_Non_Perfect_Square'Access));
      Result.Add_Test
        (Caller.Create
           ("Sqrt negative and nonfinite follow OpenCV",
            Sqrt_Negative_And_Nonfinite_Follow_OpenCV'Access));
      Result.Add_Test
        (Caller.Create
           ("Sqrt multi-channel Vec3", Sqrt_Multi_Channel_Vec3'Access));
      Result.Add_Test
        (Caller.Create
           ("Sqrt noncontiguous Region and independent storage",
            Sqrt_Noncontiguous_Region_And_Independent_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Sqrt typed empty and default empty",
            Sqrt_Typed_Empty_And_Default_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("Sqrt rejects unsupported depths",
            Sqrt_Rejects_Unsupported_Depths'Access));
      Result.Add_Test
        (Caller.Create
           ("Exp Float32 zero one and negative one",
            Exp_Float32_Zero_One_And_Negative_One'Access));
      Result.Add_Test
        (Caller.Create
           ("Exp Float64 representative finite values",
            Exp_Float64_Representative_Finite_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Exp multi-channel Vec3", Exp_Multi_Channel_Vec3'Access));
      Result.Add_Test
        (Caller.Create
           ("Exp noncontiguous Region and independent storage",
            Exp_Noncontiguous_Region_And_Independent_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Exp typed empty and default empty",
            Exp_Typed_Empty_And_Default_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("Exp rejects unsupported depths",
            Exp_Rejects_Unsupported_Depths'Access));
      Result.Add_Test
        (Caller.Create
           ("Log Float32 positive known values",
            Log_Float32_Positive_Known_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Log Float64 representative finite values",
            Log_Float64_Representative_Finite_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Log negative and zero are undefined but accepted",
            Log_Negative_And_Zero_Are_Undefined_But_Accepted'Access));
      Result.Add_Test
        (Caller.Create
           ("Log multi-channel Vec3", Log_Multi_Channel_Vec3'Access));
      Result.Add_Test
        (Caller.Create
           ("Log noncontiguous Region and independent storage",
            Log_Noncontiguous_Region_And_Independent_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Log typed empty and default empty",
            Log_Typed_Empty_And_Default_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("Log rejects unsupported depths",
            Log_Rejects_Unsupported_Depths'Access));
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
