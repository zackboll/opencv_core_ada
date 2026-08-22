with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float32_Vec3;
with OpenCV.Core.Float32_Vec3_Access;
with OpenCV.Core.UInt8_Access;
with Mat_Test_Support;

package body Random_Tests is

   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_8;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Float32_Vec3.Vector;

   use Mat_Test_Support;

   procedure Uniform_Float32_Range_And_Metadata
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (20, 30, (OpenCV.Core.Float32, 1));
      In_Range : Boolean := True;
   begin
      OpenCV.Core.Set_Random_Seed (12345);
      Image.Fill_Uniform
        (OpenCV.Core.Make_Scalar (-2.0), OpenCV.Core.Make_Scalar (3.0));
      for Row in 0 .. Image.Rows - 1 loop
         for Column in 0 .. Image.Columns - 1 loop
            declare
               Value : constant Long_Float :=
                 Long_Float
                   (OpenCV.Core.Float32_Access.Get (Image, Row, Column));
            begin
               In_Range :=
                 In_Range and then Value >= -2.0 and then Value < 3.0;
            end;
         end loop;
      end loop;
      AUnit.Assertions.Assert
        (In_Range
         and then Image.Rows = 20
         and then Image.Columns = 30
         and then Image.Depth = OpenCV.Core.Float32
         and then Image.Channels = 1,
         "Uniform fill must stay in range and preserve Mat metadata");
   end Uniform_Float32_Range_And_Metadata;

   procedure Uniform_Reseeding_And_Sequence_Advancement
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      A, B, Replay                : OpenCV.Core.Mat :=
        OpenCV.Core.Create (8, 8, (OpenCV.Core.Float32, 1));
      Same_Replay, Different_Next : Boolean := True;
   begin
      OpenCV.Core.Set_Random_Seed (6789);
      A.Fill_Uniform
        (OpenCV.Core.Make_Scalar (-10.0), OpenCV.Core.Make_Scalar (10.0));
      B.Fill_Uniform
        (OpenCV.Core.Make_Scalar (-10.0), OpenCV.Core.Make_Scalar (10.0));
      OpenCV.Core.Set_Random_Seed (6789);
      Replay.Fill_Uniform
        (OpenCV.Core.Make_Scalar (-10.0), OpenCV.Core.Make_Scalar (10.0));
      for Row in 0 .. A.Rows - 1 loop
         for Column in 0 .. A.Columns - 1 loop
            Same_Replay :=
              Same_Replay
              and then OpenCV.Core.Float32_Access.Get (A, Row, Column)
                       = OpenCV.Core.Float32_Access.Get (Replay, Row, Column);
            Different_Next :=
              Different_Next
              and then OpenCV.Core.Float32_Access.Get (A, Row, Column)
                       /= OpenCV.Core.Float32_Access.Get (B, Row, Column);
         end loop;
      end loop;
      AUnit.Assertions.Assert
        (Same_Replay and then Different_Next,
         "Reseeding must replay uniform output and fills must advance"
         & " the sequence");
   end Uniform_Reseeding_And_Sequence_Advancement;

   procedure Uniform_Per_Channel_And_Integer_Bounds
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Color : OpenCV.Core.Mat :=
        OpenCV.Core.Create (8, 8, (OpenCV.Core.Float32, 3));
      Bytes : OpenCV.Core.Mat :=
        OpenCV.Core.Create (8, 8, (OpenCV.Core.UInt8, 1));
      Valid : Boolean := True;
   begin
      OpenCV.Core.Set_Random_Seed (42);
      Color.Fill_Uniform
        (OpenCV.Core.Make_Scalar (-2.0, 10.0, 100.0),
         OpenCV.Core.Make_Scalar (-1.0, 20.0, 101.0));
      Bytes.Fill_Uniform
        (OpenCV.Core.Make_Scalar (10.0), OpenCV.Core.Make_Scalar (20.0));
      for Row in 0 .. Color.Rows - 1 loop
         for Column in 0 .. Color.Columns - 1 loop
            declare
               Value : constant OpenCV.Core.Float32_Vec3.Vector :=
                 OpenCV.Core.Float32_Vec3_Access.Get (Color, Row, Column);
               Byte  : constant Interfaces.Unsigned_8 :=
                 OpenCV.Core.UInt8_Access.Get (Bytes, Row, Column);
            begin
               Valid :=
                 Valid
                 and then Value (0) >= -2.0
                 and then Value (0) < -1.0
                 and then Value (1) >= 10.0
                 and then Value (1) < 20.0
                 and then Value (2) >= 100.0
                 and then Value (2) < 101.0
                 and then Byte >= 10
                 and then Byte < 20;
            end;
         end loop;
      end loop;
      AUnit.Assertions.Assert
        (Valid,
         "Uniform fill must use independent Scalar bounds and UInt8 bounds");
   end Uniform_Per_Channel_And_Integer_Bounds;

   procedure Uniform_Float16_Is_Supported (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float16, 1));
   begin
      OpenCV.Core.Set_Random_Seed (91);
      Image.Fill_Uniform
        (OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      AUnit.Assertions.Assert
        (Image.Depth = OpenCV.Core.Float16 and then Image.Rows = 2,
         "Uniform fill must support Float16");
   end Uniform_Float16_Is_Supported;

   procedure Normal_Reseeding_Per_Channel_And_Integer_Conversion
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      A, B                                                   :
        OpenCV.Core.Mat := OpenCV.Core.Create (8, 8, (OpenCV.Core.Float32, 1));
      Color                                                  :
        OpenCV.Core.Mat := OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 3));
      Bytes                                                  :
        OpenCV.Core.Mat := OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Same, Parameters_Applied, Integer_Clipped, Normal_Sane : Boolean := True;
   begin
      OpenCV.Core.Set_Random_Seed (222);
      A.Fill_Normal
        (OpenCV.Core.Make_Scalar (10.0), OpenCV.Core.Make_Scalar (2.0));
      OpenCV.Core.Set_Random_Seed (222);
      B.Fill_Normal
        (OpenCV.Core.Make_Scalar (10.0), OpenCV.Core.Make_Scalar (2.0));
      Color.Fill_Normal
        (OpenCV.Core.Make_Scalar (1.0, 2.0, 3.0),
         OpenCV.Core.Make_Scalar (0.0, 0.0, 0.0));
      Bytes.Fill_Normal
        (OpenCV.Core.Make_Scalar (300.0), OpenCV.Core.Make_Scalar (0.0));
      for Row in 0 .. A.Rows - 1 loop
         for Column in 0 .. A.Columns - 1 loop
            Same :=
              Same
              and then OpenCV.Core.Float32_Access.Get (A, Row, Column)
                       = OpenCV.Core.Float32_Access.Get (B, Row, Column);
            Normal_Sane :=
              Normal_Sane
              and then abs Long_Float
                             (OpenCV.Core.Float32_Access.Get (A, Row, Column)
                              - 10.0)
                       < 100.0;
         end loop;
      end loop;
      for Row in 0 .. Color.Rows - 1 loop
         for Column in 0 .. Color.Columns - 1 loop
            declare
               Value : constant OpenCV.Core.Float32_Vec3.Vector :=
                 OpenCV.Core.Float32_Vec3_Access.Get (Color, Row, Column);
            begin
               Parameters_Applied :=
                 Parameters_Applied and then Value = (1.0, 2.0, 3.0);
               Integer_Clipped :=
                 Integer_Clipped
                 and then OpenCV.Core.UInt8_Access.Get (Bytes, Row, Column)
                          = 255;
            end;
         end loop;
      end loop;
      AUnit.Assertions.Assert
        (Same
         and then Normal_Sane
         and then Parameters_Applied
         and then Integer_Clipped,
         "Normal fill must replay, apply per-channel parameters, and"
         & " saturate integers");
   end Normal_Reseeding_Per_Channel_And_Integer_Conversion;

   procedure Random_Fill_Rejects_Invalid_Destinations
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Empty, Typed_Empty, Half, Many : OpenCV.Core.Mat;
      procedure Uniform_Empty is
      begin
         Empty.Fill_Uniform
           (OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      end Uniform_Empty;
      procedure Uniform_Typed_Empty is
      begin
         Typed_Empty.Fill_Uniform
           (OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      end Uniform_Typed_Empty;
      procedure Normal_Half is
      begin
         Half.Fill_Normal
           (OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      end Normal_Half;
      procedure Uniform_Many is
      begin
         Many.Fill_Uniform
           (OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      end Uniform_Many;
   begin
      Typed_Empty := OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Half := OpenCV.Core.Create (1, 1, (OpenCV.Core.Float16, 1));
      Many := OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 5));
      Assert_Raises_OpenCV_Error
        (Uniform_Empty'Access, "Uniform fill must reject default empty Mats");
      Assert_Raises_OpenCV_Error
        (Uniform_Typed_Empty'Access,
         "Uniform fill must reject typed empty Mats");
      Assert_Raises_OpenCV_Error
        (Normal_Half'Access, "Normal fill must reject Float16 Mats");
      Assert_Raises_OpenCV_Error
        (Uniform_Many'Access,
         "Uniform fill must reject Mats with over four channels");
   end Random_Fill_Rejects_Invalid_Destinations;

   procedure Uniform_Fill_Supports_Non_Continuous_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent                            : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 5, (OpenCV.Core.Float32, 1));
      Region                            : OpenCV.Core.Mat :=
        Parent.Region ((1, 1, 3, 2));
      Outside_Unchanged, Inside_Changed : Boolean := True;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (-99.0));
      OpenCV.Core.Set_Random_Seed (777);
      Region.Fill_Uniform
        (OpenCV.Core.Make_Scalar (1.0), OpenCV.Core.Make_Scalar (2.0));
      for Row in 0 .. Parent.Rows - 1 loop
         for Column in 0 .. Parent.Columns - 1 loop
            declare
               Value     : constant Long_Float :=
                 Long_Float
                   (OpenCV.Core.Float32_Access.Get (Parent, Row, Column));
               In_Region : constant Boolean :=
                 Row in 1 .. 2 and then Column in 1 .. 3;
            begin
               if In_Region then
                  Inside_Changed :=
                    Inside_Changed and then Value >= 1.0 and then Value < 2.0;
               else
                  Outside_Unchanged :=
                    Outside_Unchanged and then Value = -99.0;
               end if;
            end;
         end loop;
      end loop;
      AUnit.Assertions.Assert
        (not Region.Is_Continuous
         and then Outside_Unchanged
         and then Inside_Changed,
         "Uniform fill must modify only a non-continuous Region in"
         & " parent storage");
   end Uniform_Fill_Supports_Non_Continuous_Regions;

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Uniform Float32 range and metadata",
            Uniform_Float32_Range_And_Metadata'Access));
      Result.Add_Test
        (Caller.Create
           ("Uniform reseeding and sequence advancement",
            Uniform_Reseeding_And_Sequence_Advancement'Access));
      Result.Add_Test
        (Caller.Create
           ("Uniform per-channel and integer bounds",
            Uniform_Per_Channel_And_Integer_Bounds'Access));
      Result.Add_Test
        (Caller.Create
           ("Uniform Float16 support", Uniform_Float16_Is_Supported'Access));
      Result.Add_Test
        (Caller.Create
           ("Normal reseeding, parameters, and integer conversion",
            Normal_Reseeding_Per_Channel_And_Integer_Conversion'Access));
      Result.Add_Test
        (Caller.Create
           ("Random fills reject invalid destinations",
            Random_Fill_Rejects_Invalid_Destinations'Access));
      Result.Add_Test
        (Caller.Create
           ("Uniform fill supports non-continuous Regions",
            Uniform_Fill_Supports_Non_Continuous_Regions'Access));
      return Result'Access;
   end Suite;

end Random_Tests;
