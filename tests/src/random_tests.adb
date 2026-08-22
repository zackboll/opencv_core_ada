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
   use type OpenCV.Core.Mat_Size;

   use Mat_Test_Support;

   function Float_Mats_Equal (Left, Right : OpenCV.Core.Mat) return Boolean is
   begin
      if Left.Rows /= Right.Rows or else Left.Columns /= Right.Columns then
         return False;
      end if;
      for Row in 0 .. Left.Rows - 1 loop
         for Column in 0 .. Left.Columns - 1 loop
            if OpenCV.Core.Float32_Access.Get (Left, Row, Column)
              /= OpenCV.Core.Float32_Access.Get (Right, Row, Column)
            then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Float_Mats_Equal;

   function UInt8_Mats_Equal (Left, Right : OpenCV.Core.Mat) return Boolean is
   begin
      if Left.Rows /= Right.Rows or else Left.Columns /= Right.Columns then
         return False;
      end if;
      for Row in 0 .. Left.Rows - 1 loop
         for Column in 0 .. Left.Columns - 1 loop
            if OpenCV.Core.UInt8_Access.Get (Left, Row, Column)
              /= OpenCV.Core.UInt8_Access.Get (Right, Row, Column)
            then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end UInt8_Mats_Equal;

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
      A, B, Replay   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (8, 8, (OpenCV.Core.Float32, 1));
      Same_Replay    : Boolean := True;
      Any_Difference : Boolean := False;
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
            Any_Difference :=
              Any_Difference
              or else OpenCV.Core.Float32_Access.Get (A, Row, Column)
                      /= OpenCV.Core.Float32_Access.Get (B, Row, Column);
         end loop;
      end loop;
      AUnit.Assertions.Assert
        (Same_Replay and then Any_Difference,
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

   procedure Shuffle_Deterministic_Reseeding (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      A, B  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 32, (OpenCV.Core.UInt8, 1));
      Equal : Boolean := True;
   begin
      for Column in 0 .. 31 loop
         OpenCV.Core.UInt8_Access.Set
           (A, 0, Column, Interfaces.Unsigned_8 (Column));
         OpenCV.Core.UInt8_Access.Set
           (B, 0, Column, Interfaces.Unsigned_8 (Column));
      end loop;
      OpenCV.Core.Set_Random_Seed (1_234);
      A.Shuffle;
      OpenCV.Core.Set_Random_Seed (1_234);
      B.Shuffle;
      for Column in 0 .. 31 loop
         Equal :=
           Equal
           and then OpenCV.Core.UInt8_Access.Get (A, 0, Column)
                    = OpenCV.Core.UInt8_Access.Get (B, 0, Column);
      end loop;
      AUnit.Assertions.Assert
        (Equal, "Shuffle must replay after reseeding the default RNG");
   end Shuffle_Deterministic_Reseeding;

   procedure Shuffle_Advances_Random_Sequence (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      A, B          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 32, (OpenCV.Core.UInt8, 1));
      Any_Different : Boolean := False;
   begin
      for Column in 0 .. 31 loop
         OpenCV.Core.UInt8_Access.Set
           (A, 0, Column, Interfaces.Unsigned_8 (Column));
         OpenCV.Core.UInt8_Access.Set
           (B, 0, Column, Interfaces.Unsigned_8 (Column));
      end loop;
      OpenCV.Core.Set_Random_Seed (5_678);
      A.Shuffle;
      B.Shuffle;
      for Column in 0 .. 31 loop
         Any_Different :=
           Any_Different
           or else OpenCV.Core.UInt8_Access.Get (A, 0, Column)
                   /= OpenCV.Core.UInt8_Access.Get (B, 0, Column);
      end loop;
      AUnit.Assertions.Assert
        (Any_Different,
         "Shuffle calls with a fixed seed must advance the default RNG");
   end Shuffle_Advances_Random_Sequence;

   procedure Shuffle_Row_Vector_Preserves_Permutation
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Vector : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 8, (OpenCV.Core.UInt8, 1));
      Seen   : array (1 .. 8) of Boolean := (others => False);
      Valid  : Boolean := True;
   begin
      for Column in 0 .. 7 loop
         OpenCV.Core.UInt8_Access.Set
           (Vector, 0, Column, Interfaces.Unsigned_8 (Column + 1));
      end loop;
      OpenCV.Core.Set_Random_Seed (99);
      Vector.Shuffle;
      for Column in 0 .. 7 loop
         declare
            Value : constant Natural :=
              Natural (OpenCV.Core.UInt8_Access.Get (Vector, 0, Column));
         begin
            Valid :=
              Valid and then Value in Seen'Range and then not Seen (Value);
            if Value in Seen'Range then
               Seen (Value) := True;
            end if;
         end;
      end loop;
      for Value in Seen'Range loop
         Valid := Valid and then Seen (Value);
      end loop;
      AUnit.Assertions.Assert
        (Valid
         and then Vector.Rows = 1
         and then Vector.Columns = 8
         and then Vector.Depth = OpenCV.Core.UInt8
         and then Vector.Channels = 1,
         "Shuffle must preserve a row vector's complete-value permutation and"
         & " metadata");
   end Shuffle_Row_Vector_Preserves_Permutation;

   procedure Shuffle_Column_Vector (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Vector : OpenCV.Core.Mat :=
        OpenCV.Core.Create (8, 1, (OpenCV.Core.UInt8, 1));
      Seen   : array (1 .. 8) of Boolean := (others => False);
      Valid  : Boolean := True;
   begin
      for Row in 0 .. 7 loop
         OpenCV.Core.UInt8_Access.Set
           (Vector, Row, 0, Interfaces.Unsigned_8 (Row + 1));
      end loop;
      OpenCV.Core.Set_Random_Seed (100);
      Vector.Shuffle;
      for Row in 0 .. 7 loop
         declare
            Value : constant Natural :=
              Natural (OpenCV.Core.UInt8_Access.Get (Vector, Row, 0));
         begin
            Valid :=
              Valid and then Value in Seen'Range and then not Seen (Value);
            if Value in Seen'Range then
               Seen (Value) := True;
            end if;
         end;
      end loop;
      AUnit.Assertions.Assert
        (Valid and then Vector.Rows = 8 and then Vector.Columns = 1,
         "Shuffle must accept and permute a column vector");
   end Shuffle_Column_Vector;

   procedure Shuffle_Non_Continuous_Column_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (8, 2, (OpenCV.Core.UInt8, 1));
      Region : OpenCV.Core.Mat := Parent.Column_View (0);
      Seen   : array (1 .. 8) of Boolean := (others => False);
      Valid  : Boolean := True;
   begin
      for Row in 0 .. 7 loop
         OpenCV.Core.UInt8_Access.Set
           (Parent, Row, 0, Interfaces.Unsigned_8 (Row + 1));
         OpenCV.Core.UInt8_Access.Set (Parent, Row, 1, 200);
      end loop;
      OpenCV.Core.Set_Random_Seed (101);
      Region.Shuffle;
      for Row in 0 .. 7 loop
         declare
            Value : constant Natural :=
              Natural (OpenCV.Core.UInt8_Access.Get (Region, Row, 0));
         begin
            Valid :=
              Valid
              and then Value in Seen'Range
              and then not Seen (Value)
              and then OpenCV.Core.UInt8_Access.Get (Parent, Row, 0)
                       = Interfaces.Unsigned_8 (Value)
              and then OpenCV.Core.UInt8_Access.Get (Parent, Row, 1) = 200;
            if Value in Seen'Range then
               Seen (Value) := True;
            end if;
         end;
      end loop;
      AUnit.Assertions.Assert
        (Valid
         and then not Region.Is_Continuous
         and then Region.Rows = 8
         and then Region.Columns = 1
         and then Region.Is_Submatrix,
         "Shuffle must update only a non-continuous column Region in parent"
         & " storage");
   end Shuffle_Non_Continuous_Column_Region;

   procedure Shuffle_Preserves_Multi_Channel_Elements
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Vector : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 8, (OpenCV.Core.Float32, 3));
      Seen   : array (1 .. 8) of Boolean := (others => False);
      Valid  : Boolean := True;
   begin
      for Column in 0 .. 7 loop
         OpenCV.Core.Float32_Vec3_Access.Set
           (Vector,
            0,
            Column,
            (Interfaces.IEEE_Float_32 (Column + 1),
             Interfaces.IEEE_Float_32 (Column + 101),
             Interfaces.IEEE_Float_32 (Column + 201)));
      end loop;
      OpenCV.Core.Set_Random_Seed (102);
      Vector.Shuffle;
      for Column in 0 .. 7 loop
         declare
            Value : constant OpenCV.Core.Float32_Vec3.Vector :=
              OpenCV.Core.Float32_Vec3_Access.Get (Vector, 0, Column);
            Index : constant Natural := Natural (Integer (Value (0)));
         begin
            Valid :=
              Valid
              and then Index in Seen'Range
              and then not Seen (Index)
              and then Value (1) = Interfaces.IEEE_Float_32 (Index + 100)
              and then Value (2) = Interfaces.IEEE_Float_32 (Index + 200);
            if Index in Seen'Range then
               Seen (Index) := True;
            end if;
         end;
      end loop;
      AUnit.Assertions.Assert
        (Valid, "Shuffle must move all channels of each element together");
   end Shuffle_Preserves_Multi_Channel_Elements;

   procedure Shuffle_Supports_Float16 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Vector : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 8, (OpenCV.Core.Float16, 1));
   begin
      Vector.Set_To (OpenCV.Core.Make_Scalar (2.0));
      Vector.Shuffle;
      AUnit.Assertions.Assert
        (Vector.Rows = 1
         and then Vector.Columns = 8
         and then Vector.Depth = OpenCV.Core.Float16
         and then Vector.Channels = 1,
         "Shuffle must support Float16 elements with size two");
   end Shuffle_Supports_Float16;

   procedure Shuffle_Representative_Dispatch_Sizes
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      One_Byte          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Two_Bytes         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt16, 1));
      Three_Bytes       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 3));
      Four_Bytes        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Eight_Bytes       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float64, 1));
      Twelve_Bytes      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 3));
      Sixteen_Bytes     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float64, 2));
      Twenty_Four_Bytes : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float64, 3));
      Thirty_Two_Bytes  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float64, 4));
   begin
      One_Byte.Shuffle;
      Two_Bytes.Shuffle;
      Three_Bytes.Shuffle;
      Four_Bytes.Shuffle;
      Eight_Bytes.Shuffle;
      Twelve_Bytes.Shuffle;
      Sixteen_Bytes.Shuffle;
      Twenty_Four_Bytes.Shuffle;
      Thirty_Two_Bytes.Shuffle;
      AUnit.Assertions.Assert
        (One_Byte.Element_Size = 1
         and then Two_Bytes.Element_Size = 2
         and then Three_Bytes.Element_Size = 3
         and then Four_Bytes.Element_Size = 4
         and then Eight_Bytes.Element_Size = 8
         and then Twelve_Bytes.Element_Size = 12
         and then Sixteen_Bytes.Element_Size = 16
         and then Twenty_Four_Bytes.Element_Size = 24
         and then Thirty_Two_Bytes.Element_Size = 32,
         "Shuffle must support representative OpenCV dispatcher element"
         & " sizes");
   end Shuffle_Representative_Dispatch_Sizes;

   procedure Shuffle_Rejects_Unsupported_Element_Sizes
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Five_Bytes  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 5));
      Forty_Bytes : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float64, 5));
      procedure Shuffle_Five_Bytes is
      begin
         Five_Bytes.Shuffle;
      end Shuffle_Five_Bytes;
      procedure Shuffle_Forty_Bytes is
      begin
         Forty_Bytes.Shuffle;
      end Shuffle_Forty_Bytes;
   begin
      Assert_Raises_OpenCV_Error
        (Shuffle_Five_Bytes'Access,
         "Shuffle must reject unsupported complete element size five");
      Assert_Raises_OpenCV_Error
        (Shuffle_Forty_Bytes'Access,
         "Shuffle must reject complete element sizes over 32");
   end Shuffle_Rejects_Unsupported_Element_Sizes;

   procedure Shuffle_Rejects_Empty_Mats (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Empty, Typed_Empty : OpenCV.Core.Mat;
      procedure Shuffle_Empty is
      begin
         Empty.Shuffle;
      end Shuffle_Empty;
      procedure Shuffle_Typed_Empty is
      begin
         Typed_Empty.Shuffle;
      end Shuffle_Typed_Empty;
   begin
      Typed_Empty := OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Assert_Raises_OpenCV_Error
        (Shuffle_Empty'Access, "Shuffle must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Shuffle_Typed_Empty'Access, "Shuffle must reject a typed empty Mat");
   end Shuffle_Rejects_Empty_Mats;

   procedure Shuffle_Rejects_Non_Vector_Mat (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Matrix : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      procedure Shuffle_Matrix is
      begin
         Matrix.Shuffle;
      end Shuffle_Matrix;
   begin
      Assert_Raises_OpenCV_Error
        (Shuffle_Matrix'Access,
         "Shuffle must reject a non-vector two-dimensional Mat");
   end Shuffle_Rejects_Non_Vector_Mat;

   procedure Shuffle_Accepts_Single_Element_Vector
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Vector : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Vector, 0, 0, 42);
      Vector.Shuffle;
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Vector, 0, 0) = 42,
         "Shuffle must accept a single-element vector without changing it");
   end Shuffle_Accepts_Single_Element_Vector;

   procedure Explicit_Generator_Construction_And_Reseeding
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_A, Default_B, Zero, Replay_A, Replay_B : OpenCV.Core.Mat :=
        OpenCV.Core.Create (8, 8, (OpenCV.Core.Float32, 1));
      Advance                                        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Default_Generator_A, Default_Generator_B       :
        OpenCV.Core.Random_Number_Generator;
      Zero_Generator                                 :
        OpenCV.Core.Random_Number_Generator :=
          OpenCV.Core.Make_Random_Number_Generator (0);
      Generator                                      :
        OpenCV.Core.Random_Number_Generator :=
          OpenCV.Core.Make_Random_Number_Generator (12_345);
   begin
      Default_A.Fill_Uniform
        (Default_Generator_A,
         OpenCV.Core.Make_Scalar (-1.0),
         OpenCV.Core.Make_Scalar (1.0));
      Default_B.Fill_Uniform
        (Default_Generator_B,
         OpenCV.Core.Make_Scalar (-1.0),
         OpenCV.Core.Make_Scalar (1.0));
      Zero.Fill_Uniform
        (Zero_Generator,
         OpenCV.Core.Make_Scalar (-1.0),
         OpenCV.Core.Make_Scalar (1.0));
      Replay_A.Fill_Uniform
        (Generator,
         OpenCV.Core.Make_Scalar (-1.0),
         OpenCV.Core.Make_Scalar (1.0));
      Advance.Fill_Normal
        (Generator,
         OpenCV.Core.Make_Scalar (0.0),
         OpenCV.Core.Make_Scalar (1.0));
      OpenCV.Core.Reseed (Generator, 12_345);
      Replay_B.Fill_Uniform
        (Generator,
         OpenCV.Core.Make_Scalar (-1.0),
         OpenCV.Core.Make_Scalar (1.0));
      AUnit.Assertions.Assert
        (Float_Mats_Equal (Default_A, Default_B)
         and then Float_Mats_Equal (Default_A, Zero)
         and then Float_Mats_Equal (Replay_A, Replay_B),
         "default and zero seeds must match cv::RNG and reseeding"
         & " must replay");
   end Explicit_Generator_Construction_And_Reseeding;

   procedure Explicit_Generator_Value_Copy_And_Continuous_Sequence
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Initial, First_A, First_B, Second_A, Second_B : OpenCV.Core.Mat :=
        OpenCV.Core.Create (8, 8, (OpenCV.Core.Float32, 1));
      G1                                            :
        OpenCV.Core.Random_Number_Generator :=
          OpenCV.Core.Make_Random_Number_Generator (22_222);
      G2                                            :
        OpenCV.Core.Random_Number_Generator;
   begin
      Initial.Fill_Uniform
        (G1, OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      G2 := G1;
      First_A.Fill_Uniform
        (G1, OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      First_B.Fill_Uniform
        (G2, OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      Second_A.Fill_Uniform
        (G1, OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      Second_B.Fill_Uniform
        (G2, OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      AUnit.Assertions.Assert
        (Float_Mats_Equal (First_A, First_B)
         and then Float_Mats_Equal (Second_A, Second_B),
         "generator assignment must copy its sequence position and advancing"
         & " one copy must not advance the other");
   end Explicit_Generator_Value_Copy_And_Continuous_Sequence;

   procedure Explicit_Fills_Match_Default_And_Do_Not_Advance_It
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Uniform_Default,
      Uniform_Explicit,
      Normal_Default,
      Normal_Explicit,
      Default_Reference,
      Default_Observed,
      Scratch           : OpenCV.Core.Mat :=
        OpenCV.Core.Create (8, 8, (OpenCV.Core.Float32, 1));
      Uniform_Generator : OpenCV.Core.Random_Number_Generator :=
        OpenCV.Core.Make_Random_Number_Generator (1_234);
      Normal_Generator  : OpenCV.Core.Random_Number_Generator :=
        OpenCV.Core.Make_Random_Number_Generator (1_234);
   begin
      OpenCV.Core.Set_Random_Seed (1_234);
      Uniform_Default.Fill_Uniform
        (OpenCV.Core.Make_Scalar (-2.0), OpenCV.Core.Make_Scalar (3.0));
      Uniform_Explicit.Fill_Uniform
        (Uniform_Generator,
         OpenCV.Core.Make_Scalar (-2.0),
         OpenCV.Core.Make_Scalar (3.0));
      OpenCV.Core.Set_Random_Seed (1_234);
      Normal_Default.Fill_Normal
        (OpenCV.Core.Make_Scalar (1.0), OpenCV.Core.Make_Scalar (2.0));
      Normal_Explicit.Fill_Normal
        (Normal_Generator,
         OpenCV.Core.Make_Scalar (1.0),
         OpenCV.Core.Make_Scalar (2.0));
      OpenCV.Core.Set_Random_Seed (77);
      Default_Reference.Fill_Uniform
        (OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      OpenCV.Core.Set_Random_Seed (77);
      Scratch.Fill_Uniform
        (Uniform_Generator,
         OpenCV.Core.Make_Scalar (0.0),
         OpenCV.Core.Make_Scalar (1.0));
      Default_Observed.Fill_Uniform
        (OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      AUnit.Assertions.Assert
        (Float_Mats_Equal (Uniform_Default, Uniform_Explicit)
         and then Float_Mats_Equal (Normal_Default, Normal_Explicit)
         and then Float_Mats_Equal (Default_Reference, Default_Observed),
         "explicit fills must match seeded defaults without advancing theRNG");
   end Explicit_Fills_Match_Default_And_Do_Not_Advance_It;

   procedure Explicit_Shuffle_And_Invalid_Input_Preserve_State
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Vector, Explicit_A, Explicit_B : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 32, (OpenCV.Core.UInt8, 1));
      Invalid                                : OpenCV.Core.Mat;
      G1                                     :
        OpenCV.Core.Random_Number_Generator :=
          OpenCV.Core.Make_Random_Number_Generator (1_234);
      G2                                     :
        OpenCV.Core.Random_Number_Generator := G1;
      A, B                                   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
      procedure Invalid_Fill is
      begin
         Invalid.Fill_Uniform
           (G1, OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      end Invalid_Fill;
   begin
      for Column in 0 .. 31 loop
         OpenCV.Core.UInt8_Access.Set
           (Default_Vector, 0, Column, Interfaces.Unsigned_8 (Column));
         OpenCV.Core.UInt8_Access.Set
           (Explicit_A, 0, Column, Interfaces.Unsigned_8 (Column));
         OpenCV.Core.UInt8_Access.Set
           (Explicit_B, 0, Column, Interfaces.Unsigned_8 (Column));
      end loop;
      OpenCV.Core.Set_Random_Seed (1_234);
      Default_Vector.Shuffle;
      Explicit_A.Shuffle (G1);
      Explicit_B.Shuffle (G2);
      Assert_Raises_OpenCV_Error
        (Invalid_Fill'Access,
         "invalid explicit fills must raise OpenCV_Error");
      A.Fill_Uniform
        (G1, OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      B.Fill_Uniform
        (G2, OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      AUnit.Assertions.Assert
        (UInt8_Mats_Equal (Default_Vector, Explicit_A)
         and then UInt8_Mats_Equal (Explicit_A, Explicit_B)
         and then Float_Mats_Equal (A, B),
         "explicit shuffle must match default and invalid input must preserve"
         & " state");
   end Explicit_Shuffle_And_Invalid_Input_Preserve_State;

   procedure Explicit_Generator_Different_Seeds_And_Mixed_Replay
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Different_A, Different_B, First_A, First_B, Second_A, Second_B :
        OpenCV.Core.Mat := OpenCV.Core.Create (8, 8, (OpenCV.Core.Float32, 1));
      Vector_A, Vector_B                                             :
        OpenCV.Core.Mat := OpenCV.Core.Create (1, 16, (OpenCV.Core.UInt8, 1));
      G1                                                             :
        OpenCV.Core.Random_Number_Generator :=
          OpenCV.Core.Make_Random_Number_Generator (10);
      G2                                                             :
        OpenCV.Core.Random_Number_Generator :=
          OpenCV.Core.Make_Random_Number_Generator (11);
      Replay_A                                                       :
        OpenCV.Core.Random_Number_Generator :=
          OpenCV.Core.Make_Random_Number_Generator (987);
      Replay_B                                                       :
        OpenCV.Core.Random_Number_Generator :=
          OpenCV.Core.Make_Random_Number_Generator (987);
   begin
      Different_A.Fill_Uniform
        (G1, OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      Different_B.Fill_Uniform
        (G2, OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      for Column in 0 .. 15 loop
         OpenCV.Core.UInt8_Access.Set
           (Vector_A, 0, Column, Interfaces.Unsigned_8 (Column));
         OpenCV.Core.UInt8_Access.Set
           (Vector_B, 0, Column, Interfaces.Unsigned_8 (Column));
      end loop;
      First_A.Fill_Uniform
        (Replay_A,
         OpenCV.Core.Make_Scalar (-1.0),
         OpenCV.Core.Make_Scalar (1.0));
      Vector_A.Shuffle (Replay_A);
      Second_A.Fill_Normal
        (Replay_A,
         OpenCV.Core.Make_Scalar (0.0),
         OpenCV.Core.Make_Scalar (1.0));
      First_B.Fill_Uniform
        (Replay_B,
         OpenCV.Core.Make_Scalar (-1.0),
         OpenCV.Core.Make_Scalar (1.0));
      Vector_B.Shuffle (Replay_B);
      Second_B.Fill_Normal
        (Replay_B,
         OpenCV.Core.Make_Scalar (0.0),
         OpenCV.Core.Make_Scalar (1.0));
      AUnit.Assertions.Assert
        (not Float_Mats_Equal (Different_A, Different_B)
         and then Float_Mats_Equal (First_A, First_B)
         and then Float_Mats_Equal (Second_A, Second_B)
         and then UInt8_Mats_Equal (Vector_A, Vector_B),
         "different seeds must differ and mixed explicit operations"
         & " must replay");
   end Explicit_Generator_Different_Seeds_And_Mixed_Replay;

   procedure Explicit_Generator_Supports_Non_Continuous_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Uniform_Parent, Normal_Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 5, (OpenCV.Core.Float32, 1));
      Uniform_Region                : OpenCV.Core.Mat :=
        Uniform_Parent.Region ((1, 1, 3, 2));
      Normal_Region                 : OpenCV.Core.Mat :=
        Normal_Parent.Region ((1, 1, 3, 2));
      Shuffle_Parent                : OpenCV.Core.Mat :=
        OpenCV.Core.Create (8, 2, (OpenCV.Core.UInt8, 1));
      Shuffle_Region                : OpenCV.Core.Mat :=
        Shuffle_Parent.Column_View (0);
      Generator                     : OpenCV.Core.Random_Number_Generator :=
        OpenCV.Core.Make_Random_Number_Generator (456);
      Outside_Intact                : Boolean := True;
   begin
      Uniform_Parent.Set_To (OpenCV.Core.Make_Scalar (-99.0));
      Normal_Parent.Set_To (OpenCV.Core.Make_Scalar (-99.0));
      Uniform_Region.Fill_Uniform
        (Generator,
         OpenCV.Core.Make_Scalar (1.0),
         OpenCV.Core.Make_Scalar (2.0));
      Normal_Region.Fill_Normal
        (Generator,
         OpenCV.Core.Make_Scalar (0.0),
         OpenCV.Core.Make_Scalar (1.0));
      for Row in 0 .. 7 loop
         OpenCV.Core.UInt8_Access.Set
           (Shuffle_Parent, Row, 0, Interfaces.Unsigned_8 (Row + 1));
         OpenCV.Core.UInt8_Access.Set (Shuffle_Parent, Row, 1, 200);
      end loop;
      Shuffle_Region.Shuffle (Generator);
      for Row in 0 .. 3 loop
         for Column in 0 .. 4 loop
            if not (Row in 1 .. 2 and then Column in 1 .. 3) then
               Outside_Intact :=
                 Outside_Intact
                 and then OpenCV.Core.Float32_Access.Get
                            (Uniform_Parent, Row, Column)
                          = -99.0
                 and then OpenCV.Core.Float32_Access.Get
                            (Normal_Parent, Row, Column)
                          = -99.0;
            end if;
         end loop;
      end loop;
      for Row in 0 .. 7 loop
         Outside_Intact :=
           Outside_Intact
           and then OpenCV.Core.UInt8_Access.Get (Shuffle_Parent, Row, 1)
                    = 200;
      end loop;
      AUnit.Assertions.Assert
        (not Uniform_Region.Is_Continuous
         and then not Normal_Region.Is_Continuous
         and then not Shuffle_Region.Is_Continuous
         and then Outside_Intact,
         "explicit fills and shuffle must preserve non-continuous"
         & " Region views");
   end Explicit_Generator_Supports_Non_Continuous_Regions;

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
      Result.Add_Test
        (Caller.Create
           ("Shuffle deterministic reseeding",
            Shuffle_Deterministic_Reseeding'Access));
      Result.Add_Test
        (Caller.Create
           ("Shuffle advances random sequence",
            Shuffle_Advances_Random_Sequence'Access));
      Result.Add_Test
        (Caller.Create
           ("Shuffle row vector preserves permutation",
            Shuffle_Row_Vector_Preserves_Permutation'Access));
      Result.Add_Test
        (Caller.Create
           ("Shuffle column vector", Shuffle_Column_Vector'Access));
      Result.Add_Test
        (Caller.Create
           ("Shuffle non-continuous column Region",
            Shuffle_Non_Continuous_Column_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Shuffle preserves multi-channel elements",
            Shuffle_Preserves_Multi_Channel_Elements'Access));
      Result.Add_Test
        (Caller.Create
           ("Shuffle Float16 support", Shuffle_Supports_Float16'Access));
      Result.Add_Test
        (Caller.Create
           ("Shuffle representative dispatcher sizes",
            Shuffle_Representative_Dispatch_Sizes'Access));
      Result.Add_Test
        (Caller.Create
           ("Shuffle rejects unsupported element sizes",
            Shuffle_Rejects_Unsupported_Element_Sizes'Access));
      Result.Add_Test
        (Caller.Create
           ("Shuffle rejects empty Mats", Shuffle_Rejects_Empty_Mats'Access));
      Result.Add_Test
        (Caller.Create
           ("Shuffle rejects non-vector Mat",
            Shuffle_Rejects_Non_Vector_Mat'Access));
      Result.Add_Test
        (Caller.Create
           ("Shuffle accepts single element",
            Shuffle_Accepts_Single_Element_Vector'Access));
      Result.Add_Test
        (Caller.Create
           ("Explicit generator construction and reseeding",
            Explicit_Generator_Construction_And_Reseeding'Access));
      Result.Add_Test
        (Caller.Create
           ("Explicit generator value copy and continuous sequence",
            Explicit_Generator_Value_Copy_And_Continuous_Sequence'Access));
      Result.Add_Test
        (Caller.Create
           ("Explicit fills match default and preserve default RNG",
            Explicit_Fills_Match_Default_And_Do_Not_Advance_It'Access));
      Result.Add_Test
        (Caller.Create
           ("Explicit shuffle and invalid input preserve state",
            Explicit_Shuffle_And_Invalid_Input_Preserve_State'Access));
      Result.Add_Test
        (Caller.Create
           ("Explicit generator different seeds and mixed replay",
            Explicit_Generator_Different_Seeds_And_Mixed_Replay'Access));
      Result.Add_Test
        (Caller.Create
           ("Explicit generator supports non-continuous Regions",
            Explicit_Generator_Supports_Non_Continuous_Regions'Access));
      return Result'Access;
   end Suite;

end Random_Tests;
