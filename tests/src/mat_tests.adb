with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with AUnit.Test_Fixtures;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float32_Matx3x3;
with OpenCV.Core.Float32_Matx3x3_Conversions;
with OpenCV.Core.Float32_Row_Access;
with OpenCV.Core.Float32_Vec3;
with OpenCV.Core.Float32_Vec3_Access;
with OpenCV.Core.Float32_Vec3_Row_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Row_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;
with OpenCV.Core.UInt8_Vec3_Row_Access;

package body Mat_Tests is

   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_8;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Mat_Size;
   use type OpenCV.Core.Point_Coordinate;
   use type OpenCV.Core.Size_Coordinate;
   use type OpenCV.Core.Float32_Access.Float32_Classification;
   use type OpenCV.Core.UInt8_Row_Access.Row_Array;
   use type OpenCV.Core.UInt8_Vec3.Vector;
   use type OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array;

   type Mat_Test_Fixture is new AUnit.Test_Fixtures.Test_Fixture
   with null record;

   procedure Default_Mat_Is_Empty (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat;
   begin
      AUnit.Assertions.Assert
        (OpenCV.Core.Is_Empty (Image),
         "A default Mat should be empty using ordinary notation");
      AUnit.Assertions.Assert
        (Image.Is_Empty,
         "A default Mat should be empty using prefixed notation");
   end Default_Mat_Is_Empty;

   procedure Assigned_Mat_Is_Empty (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat;
      Copy   : constant OpenCV.Core.Mat := Source;
   begin
      AUnit.Assertions.Assert
        (Source.Is_Empty,
         "The source default Mat should remain valid and empty");
      AUnit.Assertions.Assert
        (Copy.Is_Empty, "An assigned default Mat should be valid and empty");
   end Assigned_Mat_Is_Empty;

   procedure UInt8_Single_Channel_Mat_Has_Requested_Metadata
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
   begin
      AUnit.Assertions.Assert
        (not Image.Is_Empty, "A dimensioned Mat should not be empty");
      AUnit.Assertions.Assert
        (Image.Rows = 2, "Rows should report the requested row count");
      AUnit.Assertions.Assert
        (Image.Columns = 3,
         "Columns should report the requested column count");
      AUnit.Assertions.Assert
        (Image.Channels = 1, "Channels should report one channel");
      AUnit.Assertions.Assert
        (Image.Depth = OpenCV.Core.UInt8, "Depth should report UInt8");
   end UInt8_Single_Channel_Mat_Has_Requested_Metadata;

   procedure Float32_Three_Channel_Mat_Has_Requested_Metadata
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 5,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
   begin
      AUnit.Assertions.Assert
        (not Image.Is_Empty,
         "A Float32 three-channel Mat should not be empty");
      AUnit.Assertions.Assert
        (Image.Rows = 4, "Rows should preserve the Float32 Mat shape");
      AUnit.Assertions.Assert
        (Image.Columns = 5, "Columns should preserve the Float32 Mat shape");
      AUnit.Assertions.Assert
        (Image.Channels = 3,
         "Channels should preserve the three-channel type");
      AUnit.Assertions.Assert
        (Image.Depth = OpenCV.Core.Float32, "Depth should preserve Float32");
   end Float32_Three_Channel_Mat_Has_Requested_Metadata;

   procedure Constructed_Mat_Copy_Preserves_Metadata
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 6,
           Columns      => 7,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
   begin
      declare
         Copy : constant OpenCV.Core.Mat := Source;
      begin
         AUnit.Assertions.Assert
           (Source.Rows = Copy.Rows, "A copy should preserve rows");
         AUnit.Assertions.Assert
           (Source.Columns = Copy.Columns, "A copy should preserve columns");
         AUnit.Assertions.Assert
           (Source.Channels = Copy.Channels,
            "A copy should preserve channels");
         AUnit.Assertions.Assert
           (Source.Depth = Copy.Depth, "A copy should preserve depth");
      end;

      AUnit.Assertions.Assert
        (Source.Rows = 6,
         "The source should remain valid after the copy is finalized");
      AUnit.Assertions.Assert
        (Source.Columns = 7,
         "The source columns should survive copy finalization");
      AUnit.Assertions.Assert
        (Source.Channels = 3,
         "The source channels should survive copy finalization");
      AUnit.Assertions.Assert
        (Source.Depth = OpenCV.Core.Float32,
         "The source depth should survive copy finalization");
   end Constructed_Mat_Copy_Preserves_Metadata;

   function Approximately_Equal
     (Left, Right : Long_Float; Tolerance : Long_Float := 0.000_001)
      return Boolean
   is (abs (Left - Right) <= Tolerance);

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

   procedure Assignment_Shares_Set_To_Data (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Copy   : OpenCV.Core.Mat;
      Total  : OpenCV.Core.Scalar;
   begin
      Copy := Source;
      Source.Set_To (OpenCV.Core.Make_Scalar (10.0));
      Total := Copy.Sum;

      AUnit.Assertions.Assert
        (Total.Component_0 = 60.0,
         "A normal Mat assignment should share Set_To-modified data");
   end Assignment_Shares_Set_To_Data;

   procedure Original_Survives_Copy_Finalization
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat;
   begin
      declare
         Copy : constant OpenCV.Core.Mat := Source;
      begin
         AUnit.Assertions.Assert
           (Copy.Is_Empty, "The inner-scope copy should be valid and empty");
      end;

      AUnit.Assertions.Assert
        (Source.Is_Empty,
         "The source should remain valid after its copy is finalized");
   end Original_Survives_Copy_Finalization;

   procedure Clone_Copies_Metadata_And_Data (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Copy   : OpenCV.Core.Mat;
      Total  : OpenCV.Core.Scalar;
   begin
      Source.Set_To (OpenCV.Core.Make_Scalar (1.0, 2.0, 3.0));
      Copy := Source.Clone;

      AUnit.Assertions.Assert
        (Copy.Rows = Source.Rows, "A clone should preserve rows");
      AUnit.Assertions.Assert
        (Copy.Columns = Source.Columns, "A clone should preserve columns");
      AUnit.Assertions.Assert
        (Copy.Channels = Source.Channels, "A clone should preserve channels");
      AUnit.Assertions.Assert
        (Copy.Depth = Source.Depth, "A clone should preserve depth");

      Total := Copy.Sum;
      AUnit.Assertions.Assert
        (Total.Component_0 = 6.0
         and then Total.Component_1 = 12.0
         and then Total.Component_2 = 18.0
         and then Total.Component_3 = 0.0,
         "A clone should initially preserve all channel sums");

      Source.Set_To (OpenCV.Core.Make_Scalar (4.0, 5.0, 6.0));
      Total := Source.Sum;
      AUnit.Assertions.Assert
        (Total.Component_0 = 24.0
         and then Total.Component_1 = 30.0
         and then Total.Component_2 = 36.0,
         "The source should contain its replacement value");

      Total := Copy.Sum;
      AUnit.Assertions.Assert
        (Total.Component_0 = 6.0
         and then Total.Component_1 = 12.0
         and then Total.Component_2 = 18.0
         and then Total.Component_3 = 0.0,
         "A clone should not share Set_To-modified matrix data");
   end Clone_Copies_Metadata_And_Data;

   procedure Assignment_Shares_But_Clone_Is_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Shallow_Copy : OpenCV.Core.Mat;
      Deep_Copy    : OpenCV.Core.Mat;
      Total        : OpenCV.Core.Scalar;
   begin
      Source.Set_To (OpenCV.Core.Make_Scalar (2.0));
      Shallow_Copy := Source;
      Deep_Copy := Source.Clone;

      Source.Set_To (OpenCV.Core.Make_Scalar (5.0));

      Total := Shallow_Copy.Sum;
      AUnit.Assertions.Assert
        (Total.Component_0 = 20.0,
         "Ordinary Mat assignment should share modified matrix data");

      Total := Deep_Copy.Sum;
      AUnit.Assertions.Assert
        (Total.Component_0 = 8.0,
         "Clone should retain data from before the source was modified");
   end Assignment_Shares_But_Clone_Is_Independent;

   procedure Assert_Raises_OpenCV_Error
     (Attempt : not null access procedure; Message : String)
   is
      Raised : Boolean := False;
   begin
      begin
         Attempt.all;
      exception
         when OpenCV.OpenCV_Error =>
            Raised := True;
      end;

      AUnit.Assertions.Assert (Raised, Message);
   end Assert_Raises_OpenCV_Error;

   procedure UInt8_Typed_Element_Access (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Total : OpenCV.Core.Scalar;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 0, Value => 5);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 2, Value => 17);
      OpenCV.Core.UInt8_Access.Set
        (Image, Row => 1, Column => 1, Value => 200);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Image, Row => 0, Column => 0) = 5,
         "UInt8 Get should return the value written at row zero, column zero");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Image, Row => 0, Column => 2) = 17,
         "UInt8 Get should return the value written at row zero, column two");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Image, Row => 1, Column => 1) = 200,
         "UInt8 Get should return the value written at row one, column one");

      Total := Image.Sum;
      AUnit.Assertions.Assert
        (Total.Component_0 = 222.0,
         "Sum should include precisely the UInt8 values written individually");
   end UInt8_Typed_Element_Access;

   procedure Float32_Typed_Element_Access (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
   begin
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 0, Value => 1.25);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 1, Value => -2.5);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 1, Column => 0, Value => 3.75);

      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get (Image, Row => 0, Column => 0)),
            1.25),
         "Float32 Get should preserve the first fractional value");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get (Image, Row => 0, Column => 1)),
            -2.5),
         "Float32 Get should preserve the negative fractional value");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get (Image, Row => 1, Column => 0)),
            3.75),
         "Float32 Get should preserve the third fractional value");
   end Float32_Typed_Element_Access;

   procedure Typed_Access_Rejects_Incompatible_Depth
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Float_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));

      procedure Read_UInt8_From_Float is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Float_Image, Row => 0, Column => 0)
            = 0,
            "An incompatible UInt8 read unexpectedly succeeded");
      end Read_UInt8_From_Float;

      procedure Read_Float32_From_UInt8 is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Access.Get (UInt8_Image, Row => 0, Column => 0)
            = 0.0,
            "An incompatible Float32 read unexpectedly succeeded");
      end Read_Float32_From_UInt8;
   begin
      Assert_Raises_OpenCV_Error
        (Read_UInt8_From_Float'Access,
         "UInt8 access must reject a Float32 Mat");
      Assert_Raises_OpenCV_Error
        (Read_Float32_From_UInt8'Access,
         "Float32 access must reject a UInt8 Mat");
   end Typed_Access_Rejects_Incompatible_Depth;

   procedure Typed_Access_Rejects_Multi_Channel_Mat
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));

      procedure Read_Multi_Channel is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Image, Row => 0, Column => 0) = 0,
            "A multi-channel typed read unexpectedly succeeded");
      end Read_Multi_Channel;
   begin
      Assert_Raises_OpenCV_Error
        (Read_Multi_Channel'Access,
         "Typed access must reject a multi-channel Mat");
   end Typed_Access_Rejects_Multi_Channel_Mat;

   procedure Typed_Access_Rejects_Out_Of_Bounds_Indices
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));

      procedure Read_Negative_Row is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Image, Row => -1, Column => 0) = 0,
            "A negative row read unexpectedly succeeded");
      end Read_Negative_Row;

      procedure Read_Row_After_Last is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Image, Row => 2, Column => 0) = 0,
            "A past-the-end row read unexpectedly succeeded");
      end Read_Row_After_Last;

      procedure Read_Negative_Column is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Image, Row => 0, Column => -1) = 0,
            "A negative column read unexpectedly succeeded");
      end Read_Negative_Column;

      procedure Read_Column_After_Last is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Image, Row => 0, Column => 2) = 0,
            "A past-the-end column read unexpectedly succeeded");
      end Read_Column_After_Last;
   begin
      Assert_Raises_OpenCV_Error
        (Read_Negative_Row'Access,
         "Typed access must reject a row before the first row");
      Assert_Raises_OpenCV_Error
        (Read_Row_After_Last'Access,
         "Typed access must reject a row after the last row");
      Assert_Raises_OpenCV_Error
        (Read_Negative_Column'Access,
         "Typed access must reject a column before the first column");
      Assert_Raises_OpenCV_Error
        (Read_Column_After_Last'Access,
         "Typed access must reject a column after the last column");
   end Typed_Access_Rejects_Out_Of_Bounds_Indices;

   procedure Clone_Isolates_Typed_Element_Writes
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Copy   : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set
        (Source, Row => 0, Column => 0, Value => 10);
      OpenCV.Core.UInt8_Access.Set
        (Source, Row => 0, Column => 1, Value => 20);
      Copy := Source.Clone;

      OpenCV.Core.UInt8_Access.Set
        (Source, Row => 0, Column => 0, Value => 99);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Source, Row => 0, Column => 0) = 99,
         "The source should reflect its typed element write");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Copy, Row => 0, Column => 0) = 10,
         "A clone must retain the original typed element value");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Copy, Row => 0, Column => 1) = 20,
         "A clone must retain unaffected typed element values");
   end Clone_Isolates_Typed_Element_Writes;

   procedure Empty_Mat_Clone_Is_Empty_And_Finalizes_Safely
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat;
   begin
      declare
         Copy : constant OpenCV.Core.Mat := Source.Clone;
      begin
         AUnit.Assertions.Assert
           (Copy.Is_Empty, "A clone of a default Mat should be empty");
      end;

      AUnit.Assertions.Assert
        (Source.Is_Empty,
         "The source should remain valid after its clone is finalized");
   end Empty_Mat_Clone_Is_Empty_And_Finalizes_Safely;

   procedure UInt8_Vec3_Typed_Element_Access (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      First  : constant OpenCV.Core.UInt8_Vec3.Vector := (1, 2, 3);
      Second : constant OpenCV.Core.UInt8_Vec3.Vector := (10, 20, 30);
      Pixel  : OpenCV.Core.UInt8_Vec3.Vector;
      Total  : OpenCV.Core.Scalar;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 1, Value => First);
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 1, Column => 2, Value => Second);

      Pixel :=
        OpenCV.Core.UInt8_Vec3_Access.Get (Image, Row => 0, Column => 1);
      AUnit.Assertions.Assert
        (Pixel (0) = 1 and then Pixel (1) = 2 and then Pixel (2) = 3,
         "UInt8 Vec3 Get should preserve all first pixel components");

      Pixel :=
        OpenCV.Core.UInt8_Vec3_Access.Get (Image, Row => 1, Column => 2);
      AUnit.Assertions.Assert
        (Pixel (0) = 10 and then Pixel (1) = 20 and then Pixel (2) = 30,
         "UInt8 Vec3 Get should preserve all second pixel components");

      Total := Image.Sum;
      AUnit.Assertions.Assert
        (Total.Component_0 = 11.0
         and then Total.Component_1 = 22.0
         and then Total.Component_2 = 33.0
         and then Total.Component_3 = 0.0,
         "Sum should independently include written UInt8 Vec3 components");
   end UInt8_Vec3_Typed_Element_Access;

   procedure Float32_Vec3_Typed_Element_Access (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      First  : constant OpenCV.Core.Float32_Vec3.Vector := (1.25, -2.5, 3.75);
      Second : constant OpenCV.Core.Float32_Vec3.Vector :=
        (-0.5, 0.125, 9.875);
      Pixel  : OpenCV.Core.Float32_Vec3.Vector;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 0, Value => First);
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 1, Column => 1, Value => Second);

      Pixel :=
        OpenCV.Core.Float32_Vec3_Access.Get (Image, Row => 0, Column => 0);
      AUnit.Assertions.Assert
        (Approximately_Equal (Long_Float (Pixel (0)), 1.25)
         and then Approximately_Equal (Long_Float (Pixel (1)), -2.5)
         and then Approximately_Equal (Long_Float (Pixel (2)), 3.75),
         "Float32 Vec3 Get should preserve fractional first pixel components");

      Pixel :=
        OpenCV.Core.Float32_Vec3_Access.Get (Image, Row => 1, Column => 1);
      AUnit.Assertions.Assert
        (Approximately_Equal (Long_Float (Pixel (0)), -0.5)
         and then Approximately_Equal (Long_Float (Pixel (1)), 0.125)
         and then Approximately_Equal (Long_Float (Pixel (2)), 9.875),
         "Float32 Vec3 Get should preserve fractional second pixel"
         & " components");
   end Float32_Vec3_Typed_Element_Access;

   procedure Vec3_Typed_Access_Rejects_Invalid_Mats_And_Indices
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Vec3_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Float32_Vec3_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      UInt8_Scalar_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      UInt8_Vec2_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 2));

      procedure Read_UInt8_From_Float32 is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec3_Access.Get
              (Float32_Vec3_Image, Row => 0, Column => 0) (0)
            = 255,
            "An incompatible UInt8 Vec3 read unexpectedly succeeded");
      end Read_UInt8_From_Float32;

      procedure Read_Float32_From_UInt8 is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Vec3_Access.Get
              (UInt8_Vec3_Image, Row => 0, Column => 0) (0)
            = 1.0,
            "An incompatible Float32 Vec3 read unexpectedly succeeded");
      end Read_Float32_From_UInt8;

      procedure Read_Single_Channel is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec3_Access.Get
              (UInt8_Scalar_Image, Row => 0, Column => 0) (0)
            = 255,
            "A single-channel Vec3 read unexpectedly succeeded");
      end Read_Single_Channel;

      procedure Read_Two_Channel is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec3_Access.Get
              (UInt8_Vec2_Image, Row => 0, Column => 0) (0)
            = 255,
            "A two-channel Vec3 read unexpectedly succeeded");
      end Read_Two_Channel;

      procedure Read_Negative_Row is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec3_Access.Get
              (UInt8_Vec3_Image, Row => -1, Column => 0) (0)
            = 255,
            "A negative Vec3 row read unexpectedly succeeded");
      end Read_Negative_Row;

      procedure Read_Row_After_Last is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec3_Access.Get
              (UInt8_Vec3_Image, Row => 2, Column => 0) (0)
            = 255,
            "A past-the-end Vec3 row read unexpectedly succeeded");
      end Read_Row_After_Last;

      procedure Read_Negative_Column is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec3_Access.Get
              (UInt8_Vec3_Image, Row => 0, Column => -1) (0)
            = 255,
            "A negative Vec3 column read unexpectedly succeeded");
      end Read_Negative_Column;

      procedure Read_Column_After_Last is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec3_Access.Get
              (UInt8_Vec3_Image, Row => 0, Column => 2) (0)
            = 255,
            "A past-the-end Vec3 column read unexpectedly succeeded");
      end Read_Column_After_Last;
   begin
      Assert_Raises_OpenCV_Error
        (Read_UInt8_From_Float32'Access,
         "UInt8 Vec3 access must reject a Float32 Mat");
      Assert_Raises_OpenCV_Error
        (Read_Float32_From_UInt8'Access,
         "Float32 Vec3 access must reject a UInt8 Mat");
      Assert_Raises_OpenCV_Error
        (Read_Single_Channel'Access,
         "Vec3 access must reject a single-channel Mat");
      Assert_Raises_OpenCV_Error
        (Read_Two_Channel'Access,
         "Vec3 access must reject a Mat without three channels");
      Assert_Raises_OpenCV_Error
        (Read_Negative_Row'Access, "Vec3 access must reject a negative row");
      Assert_Raises_OpenCV_Error
        (Read_Row_After_Last'Access,
         "Vec3 access must reject a row after the last row");
      Assert_Raises_OpenCV_Error
        (Read_Negative_Column'Access,
         "Vec3 access must reject a negative column");
      Assert_Raises_OpenCV_Error
        (Read_Column_After_Last'Access,
         "Vec3 access must reject a column after the last column");
   end Vec3_Typed_Access_Rejects_Invalid_Mats_And_Indices;

   procedure Vec3_Access_Proves_Assignment_And_Clone_Semantics
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Shallow_Copy : OpenCV.Core.Mat;
      Deep_Copy    : OpenCV.Core.Mat;
      Original     : constant OpenCV.Core.UInt8_Vec3.Vector := (1, 2, 3);
      Replacement  : constant OpenCV.Core.UInt8_Vec3.Vector := (10, 20, 30);
      Pixel        : OpenCV.Core.UInt8_Vec3.Vector;
   begin
      Shallow_Copy := Source;
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Source, Row => 0, Column => 0, Value => Original);

      Pixel :=
        OpenCV.Core.UInt8_Vec3_Access.Get
          (Shallow_Copy, Row => 0, Column => 0);
      AUnit.Assertions.Assert
        (Pixel (0) = Original (0)
         and then Pixel (1) = Original (1)
         and then Pixel (2) = Original (2),
         "An assigned Mat must share Vec3 element writes");

      Deep_Copy := Source.Clone;
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Source, Row => 0, Column => 0, Value => Replacement);

      Pixel :=
        OpenCV.Core.UInt8_Vec3_Access.Get (Deep_Copy, Row => 0, Column => 0);
      AUnit.Assertions.Assert
        (Pixel (0) = Original (0)
         and then Pixel (1) = Original (1)
         and then Pixel (2) = Original (2),
         "A cloned Mat must retain its original Vec3 element value");
   end Vec3_Access_Proves_Assignment_And_Clone_Semantics;

   procedure Region_Has_Metadata_And_Shares_Data
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 5,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      View   : OpenCV.Core.Mat :=
        Source.Region ((X => 1, Y => 1, Width => 3, Height => 2));
   begin
      AUnit.Assertions.Assert
        (View.Rows = 2, "A region should have the requested height");
      AUnit.Assertions.Assert
        (View.Columns = 3, "A region should have the requested width");
      AUnit.Assertions.Assert
        (View.Depth = Source.Depth, "A region should preserve source depth");
      AUnit.Assertions.Assert
        (View.Channels = Source.Channels,
         "A region should preserve source channels");
      AUnit.Assertions.Assert
        (not View.Is_Empty, "A non-empty region should not be empty");

      OpenCV.Core.UInt8_Access.Set (View, Row => 0, Column => 1, Value => 45);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Source, Row => 1, Column => 2) = 45,
         "A write through a region must change its source");

      OpenCV.Core.UInt8_Access.Set
        (Source, Row => 2, Column => 3, Value => 99);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (View, Row => 1, Column => 2) = 99,
         "A write through a source must be visible through its region");
   end Region_Has_Metadata_And_Shares_Data;

   procedure Region_Preserves_UInt8_Vec3_Access
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      View   : OpenCV.Core.Mat :=
        Source.Region ((X => 1, Y => 1, Width => 2, Height => 1));
      Value  : constant OpenCV.Core.UInt8_Vec3.Vector := (10, 20, 30);
      Pixel  : OpenCV.Core.UInt8_Vec3.Vector;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set
        (View, Row => 0, Column => 1, Value => Value);
      Pixel :=
        OpenCV.Core.UInt8_Vec3_Access.Get (Source, Row => 1, Column => 2);
      AUnit.Assertions.Assert
        (Pixel (0) = Value (0)
         and then Pixel (1) = Value (1)
         and then Pixel (2) = Value (2),
         "A Vec3 write through a region must preserve all source components");
   end Region_Preserves_UInt8_Vec3_Access;

   procedure Region_Survives_Source_And_Temporary_Finalization
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Source, Row => 0, Column => 0, Value => 7);
      declare
         Temporary : constant OpenCV.Core.Mat :=
           Source.Region ((X => 1, Y => 1, Width => 1, Height => 1));
      begin
         AUnit.Assertions.Assert
           (not Temporary.Is_Empty, "A temporary region should be valid");
      end;
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Source, Row => 0, Column => 0) = 7,
         "A source must remain valid after a temporary region finalizes");

      declare
         Retained_View : OpenCV.Core.Mat;
      begin
         declare
            Short_Lived_Source : OpenCV.Core.Mat :=
              OpenCV.Core.Create
                (Rows         => 1,
                 Columns      => 1,
                 Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
         begin
            Retained_View :=
              Short_Lived_Source.Region
                ((X => 0, Y => 0, Width => 1, Height => 1));
            OpenCV.Core.UInt8_Access.Set
              (Short_Lived_Source, Row => 0, Column => 0, Value => 12);
         end;

         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Retained_View, Row => 0, Column => 0)
            = 12,
            "A region must remain readable after its source finalizes");
         OpenCV.Core.UInt8_Access.Set
           (Retained_View, Row => 0, Column => 0, Value => 34);
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Retained_View, Row => 0, Column => 0)
            = 34,
            "A region must remain writable after its source finalizes");
      end;
   end Region_Survives_Source_And_Temporary_Finalization;

   procedure Region_Clone_Is_Independent (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      View   : constant OpenCV.Core.Mat :=
        Source.Region ((X => 0, Y => 0, Width => 1, Height => 1));
      Copy   : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Source, Row => 0, Column => 0, Value => 5);
      Copy := View.Clone;
      OpenCV.Core.UInt8_Access.Set
        (Source, Row => 0, Column => 0, Value => 88);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (View, Row => 0, Column => 0) = 88,
         "A region must observe source changes before clone comparison");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Copy, Row => 0, Column => 0) = 5,
         "A clone of a region must not share region storage");
   end Region_Clone_Is_Independent;

   procedure Region_Rejects_Invalid_Areas (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));

      procedure X_Beyond_Source is
         Ignored : constant OpenCV.Core.Mat :=
           Source.Region ((X => 3, Y => 0, Width => 1, Height => 1));
      begin
         pragma Unreferenced (Ignored);
      end X_Beyond_Source;

      procedure Y_Beyond_Source is
         Ignored : constant OpenCV.Core.Mat :=
           Source.Region ((X => 0, Y => 2, Width => 1, Height => 1));
      begin
         pragma Unreferenced (Ignored);
      end Y_Beyond_Source;

      procedure Width_Past_Right_Edge is
         Ignored : constant OpenCV.Core.Mat :=
           Source.Region ((X => 2, Y => 0, Width => 2, Height => 1));
      begin
         pragma Unreferenced (Ignored);
      end Width_Past_Right_Edge;

      procedure Height_Past_Bottom_Edge is
         Ignored : constant OpenCV.Core.Mat :=
           Source.Region ((X => 0, Y => 1, Width => 1, Height => 2));
      begin
         pragma Unreferenced (Ignored);
      end Height_Past_Bottom_Edge;

      procedure Zero_Width is
         Ignored : constant OpenCV.Core.Mat :=
           Source.Region ((X => 0, Y => 0, Width => 0, Height => 1));
      begin
         pragma Unreferenced (Ignored);
      end Zero_Width;

      procedure Zero_Height is
         Ignored : constant OpenCV.Core.Mat :=
           Source.Region ((X => 0, Y => 0, Width => 1, Height => 0));
      begin
         pragma Unreferenced (Ignored);
      end Zero_Height;
   begin
      Assert_Raises_OpenCV_Error
        (X_Beyond_Source'Access, "Region must reject an X outside source");
      Assert_Raises_OpenCV_Error
        (Y_Beyond_Source'Access, "Region must reject a Y outside source");
      Assert_Raises_OpenCV_Error
        (Width_Past_Right_Edge'Access,
         "Region must reject a width beyond the right edge");
      Assert_Raises_OpenCV_Error
        (Height_Past_Bottom_Edge'Access,
         "Region must reject a height beyond the bottom edge");
      Assert_Raises_OpenCV_Error
        (Zero_Width'Access, "Region must reject zero width");
      Assert_Raises_OpenCV_Error
        (Zero_Height'Access, "Region must reject zero height");
   end Region_Rejects_Invalid_Areas;

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

   procedure Mat_Storage_Metadata_For_Basic_And_Multi_Channel_Mats
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Basic : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      RGB   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
   begin
      AUnit.Assertions.Assert
        (Basic.Total = 6, "A 2x3 Mat total should count six logical elements");
      AUnit.Assertions.Assert
        (Basic.Element_Size = 1,
         "A single-channel UInt8 element should occupy one byte");
      AUnit.Assertions.Assert
        (Basic.Channel_Size = 1, "A UInt8 channel should occupy one byte");
      AUnit.Assertions.Assert
        (Basic.Is_Continuous,
         "A newly allocated two-dimensional Mat should be continuous");
      AUnit.Assertions.Assert
        (not Basic.Is_Submatrix,
         "A newly allocated Mat should not be a submatrix");

      AUnit.Assertions.Assert
        (RGB.Total = 6,
         "A three-channel Mat total should count pixels, not channels");
      AUnit.Assertions.Assert
        (RGB.Element_Size = 3,
         "A three-channel UInt8 element should occupy three bytes");
      AUnit.Assertions.Assert
        (RGB.Channel_Size = 1,
         "A three-channel UInt8 Mat should retain one-byte channels");
   end Mat_Storage_Metadata_For_Basic_And_Multi_Channel_Mats;

   procedure Mat_Storage_Metadata_For_Float32_Mats
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Scalar_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Vec3_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
   begin
      AUnit.Assertions.Assert
        (Scalar_Image.Element_Size = 4 and then Scalar_Image.Channel_Size = 4,
         "A Float32 scalar element and channel should each occupy four bytes");
      AUnit.Assertions.Assert
        (Vec3_Image.Total = 2,
         "A Float32 Vec3 Mat total should count logical pixels");
      AUnit.Assertions.Assert
        (Vec3_Image.Element_Size = 12 and then Vec3_Image.Channel_Size = 4,
         "A Float32 Vec3 element should occupy twelve bytes with four-byte"
         & " channels");
   end Mat_Storage_Metadata_For_Float32_Mats;

   procedure Region_Reports_Authoritative_Storage_Layout
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 5,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Partial_Width : constant OpenCV.Core.Mat :=
        Source.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Full_Width    : constant OpenCV.Core.Mat :=
        Source.Region ((X => 0, Y => 1, Width => 5, Height => 2));
   begin
      AUnit.Assertions.Assert
        (Partial_Width.Is_Submatrix,
         "A Region should report that it is a submatrix");
      AUnit.Assertions.Assert
        (Partial_Width.Total = 6,
         "A Region total should reflect only its dimensions");
      AUnit.Assertions.Assert
        (Partial_Width.Element_Size = Source.Element_Size
         and then Partial_Width.Channel_Size = Source.Channel_Size,
         "A Region should preserve source element and channel sizes");
      AUnit.Assertions.Assert
        (not Partial_Width.Is_Continuous,
         "A partial-width multi-row Region should retain non-contiguous"
         & " source row layout");
      AUnit.Assertions.Assert
        (Full_Width.Is_Submatrix and then Full_Width.Is_Continuous,
         "A full-width Region should remain continuous while reporting"
         & " submatrix status");
   end Region_Reports_Authoritative_Storage_Layout;

   procedure Clone_And_Convert_To_Report_Storage_Metadata
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      View   : constant OpenCV.Core.Mat :=
        Source.Region ((X => 1, Y => 1, Width => 2, Height => 2));
      Copy   : constant OpenCV.Core.Mat := View.Clone;
      Result : constant OpenCV.Core.Mat :=
        Source.Convert_To (Depth => OpenCV.Core.Float32);
   begin
      AUnit.Assertions.Assert
        (not Copy.Is_Submatrix,
         "Clone should produce an independent non-submatrix Mat");
      AUnit.Assertions.Assert
        (Copy.Is_Continuous,
         "Clone should allocate continuous storage for a Region copy");
      AUnit.Assertions.Assert
        (Copy.Total = View.Total
         and then Copy.Element_Size = View.Element_Size
         and then Copy.Channel_Size = View.Channel_Size,
         "Clone should preserve its Region's logical count and element type");

      AUnit.Assertions.Assert
        (Result.Total = Source.Total,
         "Convert_To should preserve the logical element count");
      AUnit.Assertions.Assert
        (Result.Element_Size = 12 and then Result.Channel_Size = 4,
         "Float32 Vec3 Convert_To output should report twelve-byte elements"
         & " and four-byte channels");
      AUnit.Assertions.Assert
        (not Result.Is_Submatrix and then Result.Is_Continuous,
         "Convert_To should produce a continuous independent Mat");
   end Clone_And_Convert_To_Report_Storage_Metadata;

   procedure Empty_Mat_Reports_Authoritative_Storage_Metadata
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat;
   begin
      AUnit.Assertions.Assert
        (Image.Total = 0, "A default Mat should have zero logical elements");
      AUnit.Assertions.Assert
        (Image.Element_Size = 0,
         "The installed OpenCV default Mat reports zero element bytes");
      AUnit.Assertions.Assert
        (Image.Channel_Size = 1,
         "The installed OpenCV default Mat reports a one-byte channel size");
      AUnit.Assertions.Assert
        (not Image.Is_Continuous,
         "The installed OpenCV default Mat should not be continuous");
      AUnit.Assertions.Assert
        (not Image.Is_Submatrix,
         "The installed OpenCV default Mat should not be a submatrix");
   end Empty_Mat_Reports_Authoritative_Storage_Metadata;

   procedure UInt8_Row_Access_Reads_Writes_And_Preserves_Array_Order
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Written  : constant OpenCV.Core.UInt8_Row_Access.Row_Array (5 .. 8) :=
        (10, 20, 30, 40);
      Readback : OpenCV.Core.UInt8_Row_Access.Row_Array (5 .. 8);
      From_Set : OpenCV.Core.UInt8_Row_Access.Row_Array (10 .. 13);
   begin
      OpenCV.Core.UInt8_Row_Access.Write_Row
        (Image, Row => 1, Data => Written);
      OpenCV.Core.UInt8_Row_Access.Read_Row
        (Image, Row => 1, Data => Readback);

      AUnit.Assertions.Assert
        (Readback = Written,
         "UInt8 row access must preserve ordered values and nonzero bounds");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Image, Row => 1, Column => 0) = 10
         and then OpenCV.Core.UInt8_Access.Get (Image, Row => 1, Column => 1)
                  = 20
         and then OpenCV.Core.UInt8_Access.Get (Image, Row => 1, Column => 2)
                  = 30
         and then OpenCV.Core.UInt8_Access.Get (Image, Row => 1, Column => 3)
                  = 40,
         "UInt8 element access must observe a bulk row write");

      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 0, Value => 4);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 1, Value => 3);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 2, Value => 2);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 3, Value => 1);
      OpenCV.Core.UInt8_Row_Access.Read_Row
        (Image, Row => 0, Data => From_Set);

      AUnit.Assertions.Assert
        (From_Set = (4, 3, 2, 1),
         "UInt8 bulk row reads must observe per-element writes");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Image, Row => 2, Column => 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Image, Row => 2, Column => 3)
                  = 0,
         "Writing one UInt8 row must not modify adjacent rows");
   end UInt8_Row_Access_Reads_Writes_And_Preserves_Array_Order;

   procedure Float32_Row_Access_Reads_Writes_And_Preserves_Array_Order
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Written  : constant OpenCV.Core.Float32_Row_Access.Row_Array (3 .. 5) :=
        (1.25, -2.5, 3.75);
      Readback : OpenCV.Core.Float32_Row_Access.Row_Array (3 .. 5);
      From_Set : OpenCV.Core.Float32_Row_Access.Row_Array (8 .. 10);
   begin
      OpenCV.Core.Float32_Row_Access.Write_Row
        (Image, Row => 1, Data => Written);
      OpenCV.Core.Float32_Row_Access.Read_Row
        (Image, Row => 1, Data => Readback);

      AUnit.Assertions.Assert
        (Approximately_Equal (Long_Float (Readback (3)), 1.25)
         and then Approximately_Equal (Long_Float (Readback (4)), -2.5)
         and then Approximately_Equal (Long_Float (Readback (5)), 3.75),
         "Float32 row access must preserve fractional ordered values");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get (Image, Row => 1, Column => 0)),
            1.25)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Image, Row => 1, Column => 2)),
                     3.75),
         "Float32 element access must observe a bulk row write");

      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 0, Value => -0.5);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 1, Value => 0.125);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 2, Value => 9.875);
      OpenCV.Core.Float32_Row_Access.Read_Row
        (Image, Row => 0, Data => From_Set);

      AUnit.Assertions.Assert
        (Approximately_Equal (Long_Float (From_Set (8)), -0.5)
         and then Approximately_Equal (Long_Float (From_Set (9)), 0.125)
         and then Approximately_Equal (Long_Float (From_Set (10)), 9.875),
         "Float32 bulk row reads must observe per-element writes");
   end Float32_Row_Access_Reads_Writes_And_Preserves_Array_Order;

   procedure Row_Access_Handles_Non_Continuous_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 6,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      View     : OpenCV.Core.Mat :=
        Source.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      First    : constant OpenCV.Core.UInt8_Row_Access.Row_Array (0 .. 2) :=
        (11, 12, 13);
      Second   : constant OpenCV.Core.UInt8_Row_Access.Row_Array (4 .. 6) :=
        (21, 22, 23);
      Readback : OpenCV.Core.UInt8_Row_Access.Row_Array (8 .. 10);
   begin
      AUnit.Assertions.Assert
        (not View.Is_Continuous,
         "A partial-width multi-row Region must be non-continuous");

      OpenCV.Core.UInt8_Row_Access.Write_Row (View, Row => 0, Data => First);
      OpenCV.Core.UInt8_Row_Access.Write_Row (View, Row => 1, Data => Second);
      OpenCV.Core.UInt8_Row_Access.Read_Row (View, Row => 1, Data => Readback);

      AUnit.Assertions.Assert
        (Readback = (21, 22, 23),
         "A non-continuous Region row must be readable as a complete row");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Source, Row => 1, Column => 1) = 11
         and then OpenCV.Core.UInt8_Access.Get (Source, Row => 1, Column => 3)
                  = 13
         and then OpenCV.Core.UInt8_Access.Get (Source, Row => 2, Column => 1)
                  = 21
         and then OpenCV.Core.UInt8_Access.Get (Source, Row => 2, Column => 3)
                  = 23,
         "Bulk Region row writes must respect ROI row stride and share"
         & " source data");
   end Row_Access_Handles_Non_Continuous_Regions;

   procedure Row_Access_Respects_Assignment_And_Clone_Semantics
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Shallow_Copy : OpenCV.Core.Mat;
      Deep_Copy    : OpenCV.Core.Mat;
      Initial      :
        constant OpenCV.Core.UInt8_Row_Access.Row_Array (0 .. 1) := (5, 6);
      Replacement  :
        constant OpenCV.Core.UInt8_Row_Access.Row_Array (0 .. 1) := (9, 10);
      Readback     : OpenCV.Core.UInt8_Row_Access.Row_Array (0 .. 1);
   begin
      OpenCV.Core.UInt8_Row_Access.Write_Row
        (Source, Row => 0, Data => Initial);
      Shallow_Copy := Source;
      Deep_Copy := Source.Clone;
      OpenCV.Core.UInt8_Row_Access.Write_Row
        (Shallow_Copy, Row => 0, Data => Replacement);
      OpenCV.Core.UInt8_Row_Access.Read_Row
        (Deep_Copy, Row => 0, Data => Readback);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Source, Row => 0, Column => 0) = 9
         and then OpenCV.Core.UInt8_Access.Get (Source, Row => 0, Column => 1)
                  = 10,
         "Row writes through an assigned Mat must share source storage");
      AUnit.Assertions.Assert
        (Readback = Initial,
         "Row writes after Clone must not affect the deep copy");
   end Row_Access_Respects_Assignment_And_Clone_Semantics;

   procedure Row_Access_Rejects_Invalid_Mats_Indices_And_Lengths
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Float_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      RGB_Image     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Correct_UInt8 : OpenCV.Core.UInt8_Row_Access.Row_Array (0 .. 2) :=
        (others => 0);
      Short_UInt8   : OpenCV.Core.UInt8_Row_Access.Row_Array (0 .. 1) :=
        (others => 0);
      Long_UInt8    :
        constant OpenCV.Core.UInt8_Row_Access.Row_Array (0 .. 3) :=
          (others => 0);

      procedure Read_Wrong_Depth is
      begin
         OpenCV.Core.UInt8_Row_Access.Read_Row
           (Float_Image, Row => 0, Data => Correct_UInt8);
      end Read_Wrong_Depth;

      procedure Read_Multi_Channel is
      begin
         OpenCV.Core.UInt8_Row_Access.Read_Row
           (RGB_Image, Row => 0, Data => Correct_UInt8);
      end Read_Multi_Channel;

      procedure Read_Row_After_Last is
      begin
         OpenCV.Core.UInt8_Row_Access.Read_Row
           (UInt8_Image, Row => 1, Data => Correct_UInt8);
      end Read_Row_After_Last;

      procedure Write_Too_Short is
      begin
         OpenCV.Core.UInt8_Row_Access.Write_Row
           (UInt8_Image, Row => 0, Data => Short_UInt8);
      end Write_Too_Short;

      procedure Write_Too_Long is
      begin
         OpenCV.Core.UInt8_Row_Access.Write_Row
           (UInt8_Image, Row => 0, Data => Long_UInt8);
      end Write_Too_Long;

      procedure Read_Wrong_Length is
      begin
         OpenCV.Core.UInt8_Row_Access.Read_Row
           (UInt8_Image, Row => 0, Data => Short_UInt8);
      end Read_Wrong_Length;
   begin
      Assert_Raises_OpenCV_Error
        (Read_Wrong_Depth'Access, "Row access must reject a wrong Mat depth");
      Assert_Raises_OpenCV_Error
        (Read_Multi_Channel'Access,
         "Row access must reject a multi-channel Mat");
      Assert_Raises_OpenCV_Error
        (Read_Row_After_Last'Access,
         "Row access must reject a row beyond the final row");
      Assert_Raises_OpenCV_Error
        (Write_Too_Short'Access,
         "Row access must reject an input array that is too short");
      Assert_Raises_OpenCV_Error
        (Write_Too_Long'Access,
         "Row access must reject an input array that is too long");
      Assert_Raises_OpenCV_Error
        (Read_Wrong_Length'Access,
         "Row access must reject an output array of the wrong length");
   end Row_Access_Rejects_Invalid_Mats_Indices_And_Lengths;

   procedure UInt8_Vec3_Row_Access_Reads_Writes_And_Interoperates
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Written  :
        constant OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array (5 .. 7) :=
          ((1, 2, 3), (10, 20, 30), (100, 150, 200));
      Readback : OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array (5 .. 7);
      From_Set : OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array (10 .. 12);
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (0.0, 0.0, 0.0));
      OpenCV.Core.UInt8_Vec3_Row_Access.Write_Row
        (Image, Row => 1, Data => Written);
      OpenCV.Core.UInt8_Vec3_Row_Access.Read_Row
        (Image, Row => 1, Data => Readback);

      AUnit.Assertions.Assert
        (Readback = Written,
         "UInt8 Vec3 row access must preserve components and nonzero bounds");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Image, Row => 1, Column => 0)
         = Written (5)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Image, Row => 1, Column => 2)
                  = Written (7),
         "UInt8 Vec3 element access must observe a bulk row write");

      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 0, Value => (9, 8, 7));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 1, Value => (6, 5, 4));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 2, Value => (3, 2, 1));
      OpenCV.Core.UInt8_Vec3_Row_Access.Read_Row
        (Image, Row => 0, Data => From_Set);

      AUnit.Assertions.Assert
        (From_Set = ((9, 8, 7), (6, 5, 4), (3, 2, 1)),
         "UInt8 Vec3 bulk row reads must observe element writes");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Image, Row => 2, Column => 0)
         = (0, 0, 0)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Image, Row => 2, Column => 2)
                  = (0, 0, 0),
         "Writing one UInt8 Vec3 row must not modify adjacent rows");
   end UInt8_Vec3_Row_Access_Reads_Writes_And_Interoperates;

   procedure Float32_Vec3_Row_Access_Reads_Writes_And_Interoperates
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      Written  :
        constant OpenCV.Core.Float32_Vec3_Row_Access.Row_Array (3 .. 5) :=
          ((1.25, -2.5, 3.75), (-0.5, 0.125, 9.875), (4.5, 5.25, -6.75));
      Readback : OpenCV.Core.Float32_Vec3_Row_Access.Row_Array (3 .. 5);
      From_Set : OpenCV.Core.Float32_Vec3_Row_Access.Row_Array (8 .. 10);
   begin
      OpenCV.Core.Float32_Vec3_Row_Access.Write_Row
        (Image, Row => 1, Data => Written);
      OpenCV.Core.Float32_Vec3_Row_Access.Read_Row
        (Image, Row => 1, Data => Readback);

      for Index in Written'Range loop
         for Component in 0 .. 2 loop
            AUnit.Assertions.Assert
              (Approximately_Equal
                 (Long_Float (Readback (Index) (Component)),
                  Long_Float (Written (Index) (Component))),
               "Float32 Vec3 row access must preserve fractional components");
         end loop;
      end loop;

      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Vec3_Access.Get
                 (Image, Row => 1, Column => 0) (1)),
            -2.5)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Vec3_Access.Get
                          (Image, Row => 1, Column => 2) (2)),
                     -6.75),
         "Float32 Vec3 element access must observe a bulk row write");

      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 0, Value => (-1.5, 2.25, 3.5));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 1, Value => (4.75, -5.125, 6.0));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 2, Value => (7.25, 8.5, -9.75));
      OpenCV.Core.Float32_Vec3_Row_Access.Read_Row
        (Image, Row => 0, Data => From_Set);

      AUnit.Assertions.Assert
        (Approximately_Equal (Long_Float (From_Set (8) (0)), -1.5)
         and then Approximately_Equal (Long_Float (From_Set (9) (1)), -5.125)
         and then Approximately_Equal (Long_Float (From_Set (10) (2)), -9.75),
         "Float32 Vec3 bulk row reads must observe element writes");
   end Float32_Vec3_Row_Access_Reads_Writes_And_Interoperates;

   procedure UInt8_Vec3_Row_Access_Handles_Non_Continuous_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 6,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      View     : OpenCV.Core.Mat :=
        Source.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      First    :
        constant OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array (0 .. 2) :=
          ((11, 12, 13), (21, 22, 23), (31, 32, 33));
      Second   :
        constant OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array (4 .. 6) :=
          ((41, 42, 43), (51, 52, 53), (61, 62, 63));
      Readback : OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array (8 .. 10);
   begin
      AUnit.Assertions.Assert
        (not View.Is_Continuous,
         "A partial-width multi-row Vec3 Region must be non-continuous");

      OpenCV.Core.UInt8_Vec3_Row_Access.Write_Row
        (View, Row => 0, Data => First);
      OpenCV.Core.UInt8_Vec3_Row_Access.Write_Row
        (View, Row => 1, Data => Second);
      OpenCV.Core.UInt8_Vec3_Row_Access.Read_Row
        (View, Row => 1, Data => Readback);

      AUnit.Assertions.Assert
        (Readback = Second,
         "A non-continuous Vec3 Region row must be readable completely");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Source, Row => 1, Column => 1)
         = First (0)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Source, Row => 1, Column => 3)
                  = First (2)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Source, Row => 2, Column => 1)
                  = Second (4)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Source, Row => 2, Column => 3)
                  = Second (6),
         "Vec3 Region row writes must respect ROI row stride and share data");
   end UInt8_Vec3_Row_Access_Handles_Non_Continuous_Regions;

   procedure UInt8_Vec3_Row_Access_Respects_Assignment_And_Clone
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Shallow_Copy : OpenCV.Core.Mat;
      Deep_Copy    : OpenCV.Core.Mat;
      Initial      :
        constant OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array (0 .. 1) :=
          ((1, 2, 3), (4, 5, 6));
      Replacement  :
        constant OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array (0 .. 1) :=
          ((10, 20, 30), (40, 50, 60));
      Readback     : OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array (0 .. 1);
   begin
      OpenCV.Core.UInt8_Vec3_Row_Access.Write_Row
        (Source, Row => 0, Data => Initial);
      Shallow_Copy := Source;
      Deep_Copy := Source.Clone;
      OpenCV.Core.UInt8_Vec3_Row_Access.Write_Row
        (Shallow_Copy, Row => 0, Data => Replacement);
      OpenCV.Core.UInt8_Vec3_Row_Access.Read_Row
        (Deep_Copy, Row => 0, Data => Readback);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Source, Row => 0, Column => 0)
         = Replacement (0)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Source, Row => 0, Column => 1)
                  = Replacement (1),
         "Vec3 row writes through an assigned Mat must share source storage");
      AUnit.Assertions.Assert
        (Readback = Initial,
         "Vec3 row writes after Clone must not affect the deep copy");
   end UInt8_Vec3_Row_Access_Respects_Assignment_And_Clone;

   procedure Vec3_Row_Access_Rejects_Invalid_Mats_Indices_And_Lengths
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Image     : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Float32_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      Scalar_Image    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Vec2_Image      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 2));
      Correct_UInt8   : OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array (0 .. 2) :=
        (others => (0, 0, 0));
      Short_UInt8     : OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array (0 .. 1) :=
        (others => (0, 0, 0));
      Long_UInt8      :
        constant OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array (0 .. 3) :=
          (others => (0, 0, 0));
      Correct_Float32 :
        OpenCV.Core.Float32_Vec3_Row_Access.Row_Array (0 .. 2) :=
          (others => (0.0, 0.0, 0.0));

      procedure Read_UInt8_From_Float32 is
      begin
         OpenCV.Core.UInt8_Vec3_Row_Access.Read_Row
           (Float32_Image, Row => 0, Data => Correct_UInt8);
      end Read_UInt8_From_Float32;

      procedure Read_Float32_From_UInt8 is
      begin
         OpenCV.Core.Float32_Vec3_Row_Access.Read_Row
           (UInt8_Image, Row => 0, Data => Correct_Float32);
      end Read_Float32_From_UInt8;

      procedure Read_Single_Channel is
      begin
         OpenCV.Core.UInt8_Vec3_Row_Access.Read_Row
           (Scalar_Image, Row => 0, Data => Correct_UInt8);
      end Read_Single_Channel;

      procedure Read_Two_Channel is
      begin
         OpenCV.Core.UInt8_Vec3_Row_Access.Read_Row
           (Vec2_Image, Row => 0, Data => Correct_UInt8);
      end Read_Two_Channel;

      procedure Read_Row_After_Last is
      begin
         OpenCV.Core.UInt8_Vec3_Row_Access.Read_Row
           (UInt8_Image, Row => 1, Data => Correct_UInt8);
      end Read_Row_After_Last;

      procedure Write_Too_Short is
      begin
         OpenCV.Core.UInt8_Vec3_Row_Access.Write_Row
           (UInt8_Image, Row => 0, Data => Short_UInt8);
      end Write_Too_Short;

      procedure Write_Too_Long is
      begin
         OpenCV.Core.UInt8_Vec3_Row_Access.Write_Row
           (UInt8_Image, Row => 0, Data => Long_UInt8);
      end Write_Too_Long;

      procedure Read_Wrong_Length is
      begin
         OpenCV.Core.UInt8_Vec3_Row_Access.Read_Row
           (UInt8_Image, Row => 0, Data => Short_UInt8);
      end Read_Wrong_Length;
   begin
      Assert_Raises_OpenCV_Error
        (Read_UInt8_From_Float32'Access,
         "UInt8 Vec3 row access must reject a Float32 Mat");
      Assert_Raises_OpenCV_Error
        (Read_Float32_From_UInt8'Access,
         "Float32 Vec3 row access must reject a UInt8 Mat");
      Assert_Raises_OpenCV_Error
        (Read_Single_Channel'Access,
         "Vec3 row access must reject a single-channel Mat");
      Assert_Raises_OpenCV_Error
        (Read_Two_Channel'Access,
         "Vec3 row access must reject a Mat without three channels");
      Assert_Raises_OpenCV_Error
        (Read_Row_After_Last'Access,
         "Vec3 row access must reject a row beyond the final row");
      Assert_Raises_OpenCV_Error
        (Write_Too_Short'Access,
         "Vec3 row access must reject an input array that is too short");
      Assert_Raises_OpenCV_Error
        (Write_Too_Long'Access,
         "Vec3 row access must reject an input array that is too long");
      Assert_Raises_OpenCV_Error
        (Read_Wrong_Length'Access,
         "Vec3 row access must reject an output array of the wrong length");
   end Vec3_Row_Access_Rejects_Invalid_Mats_Indices_And_Lengths;

   procedure Reshape_Changes_Channels_And_Preserves_Scalar_Order
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 6,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      View   : OpenCV.Core.Mat;
      Pixel  : OpenCV.Core.UInt8_Vec3.Vector;
   begin
      for Row in 0 .. 1 loop
         for Column in 0 .. 5 loop
            OpenCV.Core.UInt8_Access.Set
              (Source,
               Row    => Row,
               Column => Column,
               Value  => Interfaces.Unsigned_8 (Row * 6 + Column));
         end loop;
      end loop;

      View := Source.Reshape (Channels => 3);

      AUnit.Assertions.Assert
        (View.Depth = OpenCV.Core.UInt8 and then View.Channels = 3,
         "Channel reshape must preserve UInt8 depth and use three channels");
      AUnit.Assertions.Assert
        (View.Rows = 2 and then View.Columns = 2,
         "Channel reshape must preserve rows and derive columns");
      AUnit.Assertions.Assert
        (View.Total * OpenCV.Core.Mat_Size (View.Channels)
         = Source.Total * OpenCV.Core.Mat_Size (Source.Channels),
         "Channel reshape must preserve the total scalar element count");

      Pixel := OpenCV.Core.UInt8_Vec3_Access.Get (View, Row => 0, Column => 0);
      AUnit.Assertions.Assert
        (Pixel = (0, 1, 2),
         "Channel reshape must group the first three scalar values as Vec3");
      Pixel := OpenCV.Core.UInt8_Vec3_Access.Get (View, Row => 1, Column => 1);
      AUnit.Assertions.Assert
        (Pixel = (9, 10, 11),
         "Channel reshape must preserve scalar ordering across rows");
   end Reshape_Changes_Channels_And_Preserves_Scalar_Order;

   procedure Reshape_To_One_Channel_Preserves_Scalar_Order
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      View   : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Source, Row => 0, Column => 0, Value => (0, 1, 2));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Source, Row => 0, Column => 1, Value => (3, 4, 5));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Source, Row => 1, Column => 0, Value => (6, 7, 8));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Source, Row => 1, Column => 1, Value => (9, 10, 11));

      View := Source.Reshape (Channels => 1);

      AUnit.Assertions.Assert
        (View.Rows = 2 and then View.Columns = 6 and then View.Channels = 1,
         "Reshape to one channel must derive six scalar columns");
      for Row in 0 .. 1 loop
         for Column in 0 .. 5 loop
            AUnit.Assertions.Assert
              (OpenCV.Core.UInt8_Access.Get (View, Row, Column)
               = Interfaces.Unsigned_8 (Row * 6 + Column),
               "Reshape to one channel must retain scalar ordering");
         end loop;
      end loop;
   end Reshape_To_One_Channel_Preserves_Scalar_Order;

   procedure Reshape_Shares_Data_But_Clone_Is_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 6,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      View   : OpenCV.Core.Mat;
      Copy   : OpenCV.Core.Mat;
   begin
      View := Source.Reshape (Channels => 3);
      OpenCV.Core.UInt8_Vec3_Access.Set
        (View, Row => 0, Column => 1, Value => (10, 20, 30));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Source, Row => 0, Column => 3) = 10
         and then OpenCV.Core.UInt8_Access.Get (Source, Row => 0, Column => 5)
                  = 30,
         "Writes through a reshape view must be visible through its source");

      OpenCV.Core.UInt8_Access.Set (Source, Row => 0, Column => 1, Value => 7);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (View, Row => 0, Column => 0)
         = (0, 7, 0),
         "Writes through a source must be visible through its reshape view");

      Copy := View.Clone;
      OpenCV.Core.UInt8_Access.Set
        (Source, Row => 0, Column => 0, Value => 99);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (View, Row => 0, Column => 0) (0)
         = 99,
         "A reshape view must continue sharing source storage after Clone");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Copy, Row => 0, Column => 0)
         = (0, 7, 0),
         "A Clone of a reshape view must not share its storage");
   end Reshape_Shares_Data_But_Clone_Is_Independent;

   procedure Reshape_Changes_Rows_And_Preserves_Scalar_Order
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 6,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      View   : OpenCV.Core.Mat;
   begin
      for Row in 0 .. 1 loop
         for Column in 0 .. 5 loop
            OpenCV.Core.UInt8_Access.Set
              (Source,
               Row    => Row,
               Column => Column,
               Value  => Interfaces.Unsigned_8 (Row * 6 + Column));
         end loop;
      end loop;

      View := Source.Reshape (Channels => 1, Rows => 3);

      AUnit.Assertions.Assert
        (View.Rows = 3 and then View.Columns = 4,
         "Row reshape must derive columns from the scalar element count");
      for Row in 0 .. 2 loop
         for Column in 0 .. 3 loop
            AUnit.Assertions.Assert
              (OpenCV.Core.UInt8_Access.Get (View, Row, Column)
               = Interfaces.Unsigned_8 (Row * 4 + Column),
               "Row reshape must preserve scalar ordering");
         end loop;
      end loop;
   end Reshape_Changes_Rows_And_Preserves_Scalar_Order;

   procedure Reshape_Rejects_Invalid_Shapes (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));

      procedure Invalid_Channel_Shape is
         Ignored : constant OpenCV.Core.Mat := Source.Reshape (Channels => 2);
      begin
         pragma Unreferenced (Ignored);
      end Invalid_Channel_Shape;

      procedure Invalid_Row_Shape is
         Ignored : constant OpenCV.Core.Mat :=
           Source.Reshape (Channels => 1, Rows => 4);
      begin
         pragma Unreferenced (Ignored);
      end Invalid_Row_Shape;
   begin
      Assert_Raises_OpenCV_Error
        (Invalid_Channel_Shape'Access,
         "Reshape must reject a channel count that cannot preserve scalars");
      Assert_Raises_OpenCV_Error
        (Invalid_Row_Shape'Access,
         "Reshape must reject a row count that cannot preserve scalars");
   end Reshape_Rejects_Invalid_Shapes;

   procedure Reshape_Region_Respects_Continuity_Requirements
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 5,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      View   : constant OpenCV.Core.Mat :=
        Source.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Packed : OpenCV.Core.Mat;

      procedure Change_Region_Rows is
         Ignored : constant OpenCV.Core.Mat :=
           View.Reshape (Channels => 1, Rows => 1);
      begin
         pragma Unreferenced (Ignored);
      end Change_Region_Rows;
   begin
      AUnit.Assertions.Assert
        (not View.Is_Continuous,
         "The reshape continuity test requires a non-continuous Region");

      Packed := View.Reshape (Channels => 3);
      AUnit.Assertions.Assert
        (Packed.Rows = 2
         and then Packed.Columns = 1
         and then Packed.Channels = 3,
         "A non-continuous Region may change channels while preserving rows");
      Assert_Raises_OpenCV_Error
        (Change_Region_Rows'Access,
         "Changing rows of a non-continuous Region must raise OpenCV_Error");
   end Reshape_Region_Respects_Continuity_Requirements;

   procedure Empty_Mat_Reshape_Remains_Empty (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat;
      View   : constant OpenCV.Core.Mat := Source.Reshape (Channels => 3);
   begin
      AUnit.Assertions.Assert
        (View.Is_Empty,
         "Reshaping an empty Mat with a new channel count should remain"
         & " empty");
      AUnit.Assertions.Assert
        (View.Channels = 3,
         "Reshaping an empty Mat should apply the requested channel count");
   end Empty_Mat_Reshape_Remains_Empty;

   procedure Float32_Reshape_Preserves_Values (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      View   : OpenCV.Core.Mat;
      Pixel  : OpenCV.Core.Float32_Vec3.Vector;
   begin
      OpenCV.Core.Float32_Access.Set
        (Source, Row => 0, Column => 0, Value => 1.25);
      OpenCV.Core.Float32_Access.Set
        (Source, Row => 0, Column => 1, Value => -2.5);
      OpenCV.Core.Float32_Access.Set
        (Source, Row => 0, Column => 2, Value => 3.75);
      View := Source.Reshape (Channels => 3);
      Pixel :=
        OpenCV.Core.Float32_Vec3_Access.Get (View, Row => 0, Column => 0);

      AUnit.Assertions.Assert
        (View.Depth = OpenCV.Core.Float32 and then View.Columns = 1,
         "Float32 reshape must preserve depth and derive its column count");
      AUnit.Assertions.Assert
        (Approximately_Equal (Long_Float (Pixel (0)), 1.25)
         and then Approximately_Equal (Long_Float (Pixel (1)), -2.5)
         and then Approximately_Equal (Long_Float (Pixel (2)), 3.75),
         "Float32 reshape must preserve scalar values independently of size");
   end Float32_Reshape_Preserves_Values;

   procedure Row_View_Has_Metadata_And_Shares_Data
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      View   : OpenCV.Core.Mat := Source.Row_View (1);
   begin
      AUnit.Assertions.Assert
        (View.Rows = 1 and then View.Columns = 4,
         "A row view must have one row and all source columns");
      AUnit.Assertions.Assert
        (View.Depth = Source.Depth and then View.Channels = Source.Channels,
         "A row view must preserve source element type");
      AUnit.Assertions.Assert
        (View.Is_Submatrix,
         "A row view of a proper source row must be a submatrix");
      AUnit.Assertions.Assert
        (View.Is_Continuous,
         "A complete row view of a continuous source must be continuous");
      AUnit.Assertions.Assert
        (View.Total = 4
         and then View.Dimensions.Width = 4
         and then View.Dimensions.Height = 1,
         "A row view must report its scalar total and dimensions");

      OpenCV.Core.UInt8_Access.Set (View, Row => 0, Column => 2, Value => 45);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Source, Row => 1, Column => 2) = 45,
         "A write through a row view must modify its source");
   end Row_View_Has_Metadata_And_Shares_Data;

   procedure Column_View_Has_Metadata_And_Shares_Data
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      View   : OpenCV.Core.Mat := Source.Column_View (2);
   begin
      AUnit.Assertions.Assert
        (View.Rows = 3 and then View.Columns = 1,
         "A column view must have all source rows and one column");
      AUnit.Assertions.Assert
        (View.Depth = Source.Depth and then View.Channels = Source.Channels,
         "A column view must preserve source element type");
      AUnit.Assertions.Assert
        (View.Is_Submatrix, "A column view must be a submatrix");
      AUnit.Assertions.Assert
        (not View.Is_Continuous,
         "A column view of a multi-column source must be non-continuous");
      AUnit.Assertions.Assert
        (View.Total = 3
         and then View.Dimensions.Width = 1
         and then View.Dimensions.Height = 3,
         "A column view must report its scalar total and dimensions");

      OpenCV.Core.UInt8_Access.Set (View, Row => 2, Column => 0, Value => 87);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Source, Row => 2, Column => 2) = 87,
         "A write through a column view must modify its source");
   end Column_View_Has_Metadata_And_Shares_Data;

   procedure Range_Views_Have_Metadata_And_Share_Data
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source            : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 5,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Row_Range_View    : OpenCV.Core.Mat :=
        Source.Row_View ((Start => 1, Stop => 3));
      Column_Range_View : OpenCV.Core.Mat :=
        Source.Column_View ((Start => 1, Stop => 4));
   begin
      AUnit.Assertions.Assert
        (Row_Range_View.Rows = 2
         and then Row_Range_View.Columns = 5
         and then Row_Range_View.Total = 10
         and then Row_Range_View.Is_Submatrix
         and then Row_Range_View.Is_Continuous,
         "A row range view must preserve full-row continuity and metadata");
      OpenCV.Core.UInt8_Access.Set
        (Row_Range_View, Row => 1, Column => 4, Value => 10);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Source, Row => 2, Column => 4) = 10,
         "A row range view must share its source data");

      AUnit.Assertions.Assert
        (Column_Range_View.Rows = 4
         and then Column_Range_View.Columns = 3
         and then Column_Range_View.Total = 12
         and then Column_Range_View.Is_Submatrix
         and then not Column_Range_View.Is_Continuous,
         "A proper column range must report OpenCV's non-contiguous layout");
      OpenCV.Core.UInt8_Access.Set
        (Column_Range_View, Row => 3, Column => 2, Value => 20);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Source, Row => 3, Column => 3) = 20,
         "A column range view must share its source data");
   end Range_Views_Have_Metadata_And_Share_Data;

   procedure Range_View_Preserves_UInt8_Vec3_Access
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      View   : OpenCV.Core.Mat := Source.Column_View ((Start => 1, Stop => 3));
      Value  : constant OpenCV.Core.UInt8_Vec3.Vector := (10, 20, 30);
      Pixel  : OpenCV.Core.UInt8_Vec3.Vector;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set
        (View, Row => 1, Column => 1, Value => Value);
      Pixel :=
        OpenCV.Core.UInt8_Vec3_Access.Get (Source, Row => 1, Column => 2);
      AUnit.Assertions.Assert
        (Pixel (0) = Value (0)
         and then Pixel (1) = Value (1)
         and then Pixel (2) = Value (2),
         "A Vec3 write through a range view must preserve all components");
   end Range_View_Preserves_UInt8_Vec3_Access;

   procedure Range_View_Survives_Source_Finalization_And_Clone
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Retained_View : OpenCV.Core.Mat;
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 2,
              Columns      => 3,
              Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      begin
         Retained_View := Source.Row_View ((Start => 1, Stop => 2));
         OpenCV.Core.UInt8_Access.Set
           (Source, Row => 1, Column => 0, Value => 5);
      end;

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Retained_View, Row => 0, Column => 0)
         = 5,
         "A range view must remain readable after its source finalizes");
      OpenCV.Core.UInt8_Access.Set
        (Retained_View, Row => 0, Column => 1, Value => 8);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Retained_View, Row => 0, Column => 1)
         = 8,
         "A range view must remain writable after its source finalizes");

      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Rows         => 2,
              Columns      => 2,
              Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
         View   : constant OpenCV.Core.Mat := Source.Column_View (0);
         Copy   : OpenCV.Core.Mat;
      begin
         OpenCV.Core.UInt8_Access.Set
           (Source, Row => 0, Column => 0, Value => 11);
         Copy := View.Clone;
         OpenCV.Core.UInt8_Access.Set
           (Source, Row => 0, Column => 0, Value => 99);
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (View, Row => 0, Column => 0) = 99,
            "A view must observe later source changes");
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Copy, Row => 0, Column => 0) = 11,
            "A clone of a range view must not share source storage");
      end;
   end Range_View_Survives_Source_Finalization_And_Clone;

   procedure View_Operations_Reject_Invalid_Ranges_And_Accept_Empty
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));

      procedure Row_After_Last is
         Ignored : constant OpenCV.Core.Mat := Source.Row_View (2);
      begin
         pragma Unreferenced (Ignored);
      end Row_After_Last;

      procedure Column_After_Last is
         Ignored : constant OpenCV.Core.Mat := Source.Column_View (3);
      begin
         pragma Unreferenced (Ignored);
      end Column_After_Last;

      procedure Reversed_Row_Range is
         Ignored : constant OpenCV.Core.Mat :=
           Source.Row_View ((Start => 2, Stop => 1));
      begin
         pragma Unreferenced (Ignored);
      end Reversed_Row_Range;

      procedure Column_Range_Past_End is
         Ignored : constant OpenCV.Core.Mat :=
           Source.Column_View ((Start => 1, Stop => 4));
      begin
         pragma Unreferenced (Ignored);
      end Column_Range_Past_End;

      Empty_Row_View    : constant OpenCV.Core.Mat :=
        Source.Row_View ((Start => 2, Stop => 2));
      Empty_Column_View : constant OpenCV.Core.Mat :=
        Source.Column_View ((Start => 3, Stop => 3));
   begin
      Assert_Raises_OpenCV_Error
        (Row_After_Last'Access,
         "Row_View must reject an index after the last row");
      Assert_Raises_OpenCV_Error
        (Column_After_Last'Access,
         "Column_View must reject an index after the last column");
      Assert_Raises_OpenCV_Error
        (Reversed_Row_Range'Access,
         "Row_View must reject a range whose start exceeds its stop");
      Assert_Raises_OpenCV_Error
        (Column_Range_Past_End'Access,
         "Column_View must reject a range whose stop exceeds source columns");
      AUnit.Assertions.Assert
        (Empty_Row_View.Is_Empty and then Empty_Column_View.Is_Empty,
         "Equal range endpoints at the dimension boundary must yield"
         & " empty Mats");
   end View_Operations_Reject_Invalid_Ranges_And_Accept_Empty;

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

   procedure Mat_Add_And_Subtract_Work_For_Float32
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left            : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Right           : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Sum, Difference : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Left, 0, 0, 1.5);
      OpenCV.Core.Float32_Access.Set (Left, 0, 1, -2.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 0, 2.5);
      OpenCV.Core.Float32_Access.Set (Right, 0, 1, 3.0);
      Sum := Left.Add (Right);
      Difference := Left.Subtract (Right);
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Sum, 0, 0)), 4.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Difference, 0, 1)),
                     -5.0),
         "Float32 addition and subtraction must preserve arithmetic results");
      AUnit.Assertions.Assert
        (Sum.Rows = Left.Rows
         and then Sum.Columns = Left.Columns
         and then Sum.Depth = Left.Depth
         and then Sum.Channels = Left.Channels,
         "Mat addition must preserve compatible operand metadata");
   end Mat_Add_And_Subtract_Work_For_Float32;

   procedure Mat_Arithmetic_Saturates_And_Supports_Vec3
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left            : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Right           : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Sum, Difference : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (Left, 0, 0, (250, 5, 10));
      OpenCV.Core.UInt8_Vec3_Access.Set (Right, 0, 0, (20, 20, 30));
      Sum := Left.Add (Right);
      Difference := Left.Subtract (Right);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Sum, 0, 0) = (255, 25, 40)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Difference, 0, 0)
                  = (230, 0, 0),
         "UInt8 Vec3 arithmetic must process components independently with"
         & " saturation");
   end Mat_Arithmetic_Saturates_And_Supports_Vec3;

   procedure Mat_Arithmetic_Supports_Int16 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Left       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 1));
      Right      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 1));
      Sum        : OpenCV.Core.Mat;
      Difference : OpenCV.Core.Mat;
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (1_000.0));
      Right.Set_To (OpenCV.Core.Make_Scalar (-250.0));
      Sum := Left.Add (Right);
      Difference := Left.Subtract (Right);

      AUnit.Assertions.Assert
        (Sum.Sum.Component_0 = 750.0
         and then Difference.Sum.Component_0 = 1_250.0,
         "Mat arithmetic must support preserved-depth Int16 operands");
   end Mat_Arithmetic_Supports_Int16;

   procedure Mat_Arithmetic_Is_Independent_And_Handles_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (1.0));
      Right.Set_To (OpenCV.Core.Make_Scalar (2.0));
      Result := Left.Region ((1, 0, 2, 3)).Add (Right.Region ((1, 0, 2, 3)));
      OpenCV.Core.Float32_Access.Set (Left, 0, 1, 9.0);
      OpenCV.Core.Float32_Access.Set (Result, 0, 1, 7.0);
      AUnit.Assertions.Assert
        (Result.Is_Continuous
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 0)),
                     3.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (Left, 0, 2)),
                     1.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (Right, 0, 2)),
                     2.0),
         "Arithmetic Regions must produce independent continuous results");
   end Mat_Arithmetic_Is_Independent_And_Handles_Regions;

   procedure Mat_Arithmetic_Compatibility_And_Empty
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Empty_Left, Empty_Right, Empty_Result : OpenCV.Core.Mat;
      One_By_One                            : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Two_By_One                            : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 1));
      One_By_Two                            : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Depth                                 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Channels                              : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      procedure Bad_Rows is
         X : constant OpenCV.Core.Mat := One_By_One.Add (Two_By_One);
      begin
         pragma Unreferenced (X);
      end Bad_Rows;
      procedure Bad_Columns is
         X : constant OpenCV.Core.Mat := One_By_One.Add (One_By_Two);
      begin
         pragma Unreferenced (X);
      end Bad_Columns;
      procedure Bad_Depth is
         X : constant OpenCV.Core.Mat := One_By_One.Add (Depth);
      begin
         pragma Unreferenced (X);
      end Bad_Depth;
      procedure Bad_Channels is
         X : constant OpenCV.Core.Mat := One_By_One.Subtract (Channels);
      begin
         pragma Unreferenced (X);
      end Bad_Channels;
   begin
      Empty_Result := Empty_Left.Add (Empty_Right);
      AUnit.Assertions.Assert
        (Empty_Result.Is_Empty,
         "Adding two empty Mats must produce an empty Mat");
      Assert_Raises_OpenCV_Error
        (Bad_Rows'Access, "Add must reject mismatched rows");
      Assert_Raises_OpenCV_Error
        (Bad_Columns'Access, "Add must reject mismatched columns");
      Assert_Raises_OpenCV_Error
        (Bad_Depth'Access, "Add must reject mismatched depths");
      Assert_Raises_OpenCV_Error
        (Bad_Channels'Access,
         "Subtract must reject mismatched channel counts");
   end Mat_Arithmetic_Compatibility_And_Empty;

   procedure Mat_Multiply_And_Divide_Work_For_Float32
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left              : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Right             : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Product, Quotient : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Left, 0, 0, 6.0);
      OpenCV.Core.Float32_Access.Set (Left, 0, 1, -9.0);
      OpenCV.Core.Float32_Access.Set (Left, 0, 2, 5.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 1, 3.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 2, 2.0);
      Product := Left.Multiply (Right);
      Quotient := Left.Divide (Right);

      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Product, 0, 0)), 12.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Product, 0, 1)),
                     -27.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Quotient, 0, 0)),
                     3.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Quotient, 0, 1)),
                     -3.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Quotient, 0, 2)),
                     2.5),
         "Float32 multiplication and division must preserve arithmetic"
         & " results");
      AUnit.Assertions.Assert
        (Product.Rows = Left.Rows
         and then Product.Columns = Left.Columns
         and then Product.Depth = Left.Depth
         and then Product.Channels = Left.Channels,
         "Mat multiplication must preserve compatible operand metadata");
   end Mat_Multiply_And_Divide_Work_For_Float32;

   procedure Mat_Multiply_And_Divide_Handle_UInt8_And_Vec3
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left              : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Right             : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Product, Quotient : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (Left, 0, 0, (20, 7, 5));
      OpenCV.Core.UInt8_Vec3_Access.Set (Right, 0, 0, (20, 2, 0));
      Product := Left.Multiply (Right);
      Quotient := Left.Divide (Right);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Product, 0, 0) = (255, 14, 0)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Quotient, 0, 0)
                  = (1, 4, 0),
         "UInt8 Vec3 multiplication and division must use OpenCV saturation"
         & " and preserved-depth rounding");
   end Mat_Multiply_And_Divide_Handle_UInt8_And_Vec3;

   procedure Mat_Divide_By_Zero_Preserves_OpenCV_Semantics
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Integer_Numerator   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Integer_Denominator : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Float_Numerator     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Float_Denominator   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Integer_Result      : OpenCV.Core.Mat;
      Float_Result        : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Integer_Numerator, 0, 0, 20);
      Integer_Result := Integer_Numerator.Divide (Integer_Denominator);
      OpenCV.Core.Float32_Access.Set (Float_Numerator, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Float_Numerator, 0, 1, -1.0);
      Float_Denominator.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Float_Result := Float_Numerator.Divide (Float_Denominator);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Integer_Result, 0, 0) = 0,
         "OpenCV integer division by zero must produce zero");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Classify (Float_Result, 0, 0)
         = OpenCV.Core.Float32_Access.Positive_Infinity
         and then OpenCV.Core.Float32_Access.Classify (Float_Result, 0, 1)
                  = OpenCV.Core.Float32_Access.Negative_Infinity
         and then OpenCV.Core.Float32_Access.Classify (Float_Result, 0, 2)
                  = OpenCV.Core.Float32_Access.Not_A_Number,
         "OpenCV Float32 division by zero must preserve IEEE Inf and NaN");
   end Mat_Divide_By_Zero_Preserves_OpenCV_Semantics;

   procedure Float32_Classification_Identifies_Stored_Values
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Numerator    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
      Denominator  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
      Finite_Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Result       : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 2, -1.0);
      OpenCV.Core.Float32_Access.Set (Finite_Image, 0, 0, 2.0);
      Denominator.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Result := Numerator.Divide (Denominator);

      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Classify (Finite_Image, 0, 0)
         = OpenCV.Core.Float32_Access.Finite
         and then OpenCV.Core.Float32_Access.Classify (Result, 0, 0)
                  = OpenCV.Core.Float32_Access.Positive_Infinity
         and then OpenCV.Core.Float32_Access.Classify (Result, 0, 1)
                  = OpenCV.Core.Float32_Access.Positive_Infinity
         and then OpenCV.Core.Float32_Access.Classify (Result, 0, 2)
                  = OpenCV.Core.Float32_Access.Negative_Infinity
         and then OpenCV.Core.Float32_Access.Classify (Result, 0, 3)
                  = OpenCV.Core.Float32_Access.Not_A_Number,
         "Float32 classification must identify finite, infinite, and NaN"
         & " values");
   end Float32_Classification_Identifies_Stored_Values;

   procedure Mat_Multiply_And_Divide_Handle_Regions_And_Independence
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Right    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Product  : OpenCV.Core.Mat;
      Quotient : OpenCV.Core.Mat;
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (6.0));
      Right.Set_To (OpenCV.Core.Make_Scalar (2.0));
      Product :=
        Left.Region ((1, 0, 2, 3)).Multiply (Right.Region ((1, 0, 2, 3)));
      Quotient :=
        Left.Region ((1, 0, 2, 3)).Divide (Right.Region ((1, 0, 2, 3)));
      OpenCV.Core.Float32_Access.Set (Left, 0, 1, 10.0);
      OpenCV.Core.Float32_Access.Set (Product, 0, 1, 9.0);

      AUnit.Assertions.Assert
        (Product.Is_Continuous
         and then Quotient.Is_Continuous
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Product, 0, 0)),
                     12.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Quotient, 1, 1)),
                     3.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (Left, 0, 2)),
                     6.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (Right, 0, 2)),
                     2.0),
         "Arithmetic Regions must produce independent continuous results");
   end Mat_Multiply_And_Divide_Handle_Regions_And_Independence;

   procedure Mat_Multiply_Divide_Int16_Empty_Compatibility
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Int16_Left                                             :
        OpenCV.Core.Mat := OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 1));
      Int16_Right                                            :
        OpenCV.Core.Mat := OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 1));
      Empty_Left, Empty_Right, Empty_Product, Empty_Quotient : OpenCV.Core.Mat;
      Different_Rows                                         :
        constant OpenCV.Core.Mat :=
          OpenCV.Core.Create (2, 1, (OpenCV.Core.Int16, 1));
      Different_Columns                                      :
        constant OpenCV.Core.Mat :=
          OpenCV.Core.Create (1, 2, (OpenCV.Core.Int16, 1));
      Different_Depth                                        :
        constant OpenCV.Core.Mat :=
          OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Different_Channels                                     :
        constant OpenCV.Core.Mat :=
          OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 3));
      Product, Quotient                                      : OpenCV.Core.Mat;
      procedure Multiply_Mismatched_Rows is
         Ignored : constant OpenCV.Core.Mat :=
           Int16_Left.Multiply (Different_Rows);
      begin
         pragma Unreferenced (Ignored);
      end Multiply_Mismatched_Rows;
      procedure Divide_Mismatched_Columns is
         Ignored : constant OpenCV.Core.Mat :=
           Int16_Left.Divide (Different_Columns);
      begin
         pragma Unreferenced (Ignored);
      end Divide_Mismatched_Columns;
      procedure Divide_Mismatched_Depth is
         Ignored : constant OpenCV.Core.Mat :=
           Int16_Left.Divide (Different_Depth);
      begin
         pragma Unreferenced (Ignored);
      end Divide_Mismatched_Depth;
      procedure Multiply_Mismatched_Channels is
         Ignored : constant OpenCV.Core.Mat :=
           Int16_Left.Multiply (Different_Channels);
      begin
         pragma Unreferenced (Ignored);
      end Multiply_Mismatched_Channels;
   begin
      Int16_Left.Set_To (OpenCV.Core.Make_Scalar (-12.0));
      Int16_Right.Set_To (OpenCV.Core.Make_Scalar (3.0));
      Product := Int16_Left.Multiply (Int16_Right);
      Quotient := Int16_Left.Divide (Int16_Right);
      Empty_Product := Empty_Left.Multiply (Empty_Right);
      Empty_Quotient := Empty_Left.Divide (Empty_Right);

      AUnit.Assertions.Assert
        (Product.Sum.Component_0 = -36.0
         and then Quotient.Sum.Component_0 = -4.0
         and then Empty_Product.Is_Empty
         and then Empty_Quotient.Is_Empty,
         "Multiply and Divide must support Int16 and preserve empty Mat"
         & " results");
      Assert_Raises_OpenCV_Error
        (Multiply_Mismatched_Rows'Access,
         "Multiply must reject mismatched rows");
      Assert_Raises_OpenCV_Error
        (Divide_Mismatched_Columns'Access,
         "Divide must reject mismatched columns");
      Assert_Raises_OpenCV_Error
        (Divide_Mismatched_Depth'Access,
         "Divide must reject mismatched depths");
      Assert_Raises_OpenCV_Error
        (Multiply_Mismatched_Channels'Access,
         "Multiply must reject mismatched channel counts");
   end Mat_Multiply_Divide_Int16_Empty_Compatibility;

   procedure Mat_Abs_Diff_Handles_Float32_And_Metadata
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left, Right : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Result      : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Left, 0, 0, -3.0);
      OpenCV.Core.Float32_Access.Set (Left, 0, 1, 5.5);
      OpenCV.Core.Float32_Access.Set (Right, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 1, -1.5);
      Result := Left.Abs_Diff (Right);

      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Result, 0, 0)), 5.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 1)),
                     7.0)
         and then Result.Rows = Left.Rows
         and then Result.Columns = Left.Columns
         and then Result.Depth = Left.Depth
         and then Result.Channels = Left.Channels,
         "Float32 absolute difference must preserve values and metadata");
   end Mat_Abs_Diff_Handles_Float32_And_Metadata;

   procedure Mat_Abs_Diff_Handles_UInt8_Vec3_And_Int16
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Left, UInt8_Right    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Int16_Left, Int16_Right    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 1));
      UInt8_Result, Int16_Result : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (UInt8_Left, 0, 0, (10, 250, 50));
      OpenCV.Core.UInt8_Vec3_Access.Set (UInt8_Right, 0, 0, (200, 20, 80));
      UInt8_Result := UInt8_Left.Abs_Diff (UInt8_Right);
      Int16_Left.Set_To (OpenCV.Core.Make_Scalar (-32_768.0));
      Int16_Right.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Int16_Result := Int16_Left.Abs_Diff (Int16_Right);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (UInt8_Result, 0, 0)
         = (190, 230, 30)
         and then Int16_Result.Sum.Component_0 = 32_767.0,
         "Abs_Diff must process Vec3 channels and saturate Int16 minimum");
   end Mat_Abs_Diff_Handles_UInt8_Vec3_And_Int16;

   procedure Mat_Abs_Diff_Handles_Regions_Nonfinite_And_Independence
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left, Right                           : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Result                                : OpenCV.Core.Mat;
      Zeros                                 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Numerator                             : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Nonfinite                             : OpenCV.Core.Mat;
      Empty_Left, Empty_Right, Empty_Result : OpenCV.Core.Mat;
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (8.0));
      Right.Set_To (OpenCV.Core.Make_Scalar (3.0));
      Result :=
        Left.Region ((1, 0, 2, 3)).Abs_Diff (Right.Region ((1, 0, 2, 3)));
      OpenCV.Core.Float32_Access.Set (Left, 0, 1, 99.0);
      OpenCV.Core.Float32_Access.Set (Result, 0, 1, 9.0);
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 0, 1.0);
      Zeros.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Nonfinite := Numerator.Divide (Zeros);
      Empty_Result := Empty_Left.Abs_Diff (Empty_Right);

      AUnit.Assertions.Assert
        (Result.Is_Continuous
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 0)),
                     5.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (Left, 0, 2)),
                     8.0)
         and then OpenCV.Core.Float32_Access.Classify (Nonfinite, 0, 0)
                  = OpenCV.Core.Float32_Access.Positive_Infinity
         and then OpenCV.Core.Float32_Access.Classify (Nonfinite, 0, 1)
                  = OpenCV.Core.Float32_Access.Not_A_Number
         and then OpenCV.Core.Float32_Access.Classify
                    (Nonfinite.Abs_Diff (Nonfinite), 0, 0)
                  = OpenCV.Core.Float32_Access.Not_A_Number
         and then Empty_Result.Is_Empty,
         "Abs_Diff must support Regions, independent output, empty, and IEEE"
         & " Float32 semantics");
   end Mat_Abs_Diff_Handles_Regions_Nonfinite_And_Independence;

   procedure Mat_Abs_Diff_Rejects_Incompatible_Operands
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Base     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Rows     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 1));
      Columns  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Depth    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Channels : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      procedure Bad_Rows is
         X : constant OpenCV.Core.Mat := Base.Abs_Diff (Rows);
      begin
         pragma Unreferenced (X);
      end Bad_Rows;
      procedure Bad_Columns is
         X : constant OpenCV.Core.Mat := Base.Abs_Diff (Columns);
      begin
         pragma Unreferenced (X);
      end Bad_Columns;
      procedure Bad_Depth is
         X : constant OpenCV.Core.Mat := Base.Abs_Diff (Depth);
      begin
         pragma Unreferenced (X);
      end Bad_Depth;
      procedure Bad_Channels is
         X : constant OpenCV.Core.Mat := Base.Abs_Diff (Channels);
      begin
         pragma Unreferenced (X);
      end Bad_Channels;
   begin
      Assert_Raises_OpenCV_Error
        (Bad_Rows'Access, "Abs_Diff must reject mismatched rows");
      Assert_Raises_OpenCV_Error
        (Bad_Columns'Access, "Abs_Diff must reject mismatched columns");
      Assert_Raises_OpenCV_Error
        (Bad_Depth'Access, "Abs_Diff must reject mismatched depths");
      Assert_Raises_OpenCV_Error
        (Bad_Channels'Access, "Abs_Diff must reject mismatched channels");
   end Mat_Abs_Diff_Rejects_Incompatible_Operands;

   procedure Mat_Add_Weighted_Handles_Float32_And_Metadata
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left, Right : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Result      : OpenCV.Core.Mat;
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (10.0));
      Right.Set_To (OpenCV.Core.Make_Scalar (20.0));
      Result :=
        Left.Add_Weighted
          (Alpha => 0.25, Right => Right, Beta => 0.75, Gamma => 2.0);

      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Result, 0, 0)), 19.5)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 1)),
                     19.5)
         and then Result.Rows = Left.Rows
         and then Result.Columns = Left.Columns
         and then Result.Depth = Left.Depth
         and then Result.Channels = Left.Channels,
         "Add_Weighted must apply Alpha, Beta, Gamma, and preserve metadata");
   end Mat_Add_Weighted_Handles_Float32_And_Metadata;

   procedure Mat_Add_Weighted_Handles_UInt8_Vec3_And_Int16
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Left, UInt8_Right               : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Int16_Left, Int16_Right               : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 1));
      UInt8_Result, Saturated, Int16_Result : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (UInt8_Left, 0, 0, (1, 10, 200));
      OpenCV.Core.UInt8_Vec3_Access.Set (UInt8_Right, 0, 0, (2, 20, 100));
      UInt8_Result :=
        UInt8_Left.Add_Weighted
          (Alpha => 0.5, Right => UInt8_Right, Beta => 0.5, Gamma => 0.5);
      Saturated :=
        UInt8_Left.Add_Weighted
          (Alpha => 2.0, Right => UInt8_Right, Beta => 2.0, Gamma => 100.0);
      Int16_Left.Set_To (OpenCV.Core.Make_Scalar (-10.0));
      Int16_Right.Set_To (OpenCV.Core.Make_Scalar (20.0));
      Int16_Result :=
        Int16_Left.Add_Weighted
          (Alpha => 0.5, Right => Int16_Right, Beta => 0.5);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (UInt8_Result, 0, 0) = (2, 16, 150)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Saturated, 0, 0)
                  = (106, 160, 255)
         and then Int16_Result.Sum.Component_0 = 5.0,
         "Add_Weighted must use OpenCV rounded saturation per channel");
   end Mat_Add_Weighted_Handles_UInt8_Vec3_And_Int16;

   procedure Mat_Add_Weighted_Handles_Regions_Empty_And_Independence
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left, Right                           : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Result                                : OpenCV.Core.Mat;
      Empty_Left, Empty_Right, Empty_Result : OpenCV.Core.Mat;
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (4.0));
      Right.Set_To (OpenCV.Core.Make_Scalar (12.0));
      Result :=
        Left.Region ((1, 0, 2, 3)).Add_Weighted
          (Alpha => 0.25,
           Right => Right.Region ((1, 0, 2, 3)),
           Beta  => 0.75,
           Gamma => 1.0);
      OpenCV.Core.Float32_Access.Set (Left, 0, 1, 99.0);
      OpenCV.Core.Float32_Access.Set (Result, 0, 1, 9.0);
      Empty_Result :=
        Empty_Left.Add_Weighted
          (Alpha => 1.0, Right => Empty_Right, Beta => 1.0);

      AUnit.Assertions.Assert
        (Result.Is_Continuous
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 0)),
                     11.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (Left, 0, 2)),
                     4.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (Right, 0, 2)),
                     12.0)
         and then Empty_Result.Is_Empty,
         "Add_Weighted must support Regions, independent output, and empty"
         & " Mats");
   end Mat_Add_Weighted_Handles_Regions_Empty_And_Independence;

   procedure Mat_Add_Weighted_Rejects_Incompatible_Operands
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Base     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Rows     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 1));
      Columns  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Depth    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Channels : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      procedure Bad_Rows is
         X : constant OpenCV.Core.Mat := Base.Add_Weighted (1.0, Rows, 1.0);
      begin
         pragma Unreferenced (X);
      end Bad_Rows;
      procedure Bad_Columns is
         X : constant OpenCV.Core.Mat := Base.Add_Weighted (1.0, Columns, 1.0);
      begin
         pragma Unreferenced (X);
      end Bad_Columns;
      procedure Bad_Depth is
         X : constant OpenCV.Core.Mat := Base.Add_Weighted (1.0, Depth, 1.0);
      begin
         pragma Unreferenced (X);
      end Bad_Depth;
      procedure Bad_Channels is
         X : constant OpenCV.Core.Mat :=
           Base.Add_Weighted (1.0, Channels, 1.0);
      begin
         pragma Unreferenced (X);
      end Bad_Channels;
   begin
      Assert_Raises_OpenCV_Error
        (Bad_Rows'Access, "Add_Weighted must reject mismatched rows");
      Assert_Raises_OpenCV_Error
        (Bad_Columns'Access, "Add_Weighted must reject mismatched columns");
      Assert_Raises_OpenCV_Error
        (Bad_Depth'Access, "Add_Weighted must reject mismatched depths");
      Assert_Raises_OpenCV_Error
        (Bad_Channels'Access, "Add_Weighted must reject mismatched channels");
   end Mat_Add_Weighted_Rejects_Incompatible_Operands;

   procedure Mat_Bitwise_Operations_Handle_UInt8_And_Vec3
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left, Right                                               :
        OpenCV.Core.Mat := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Vec_Left, Vec_Right                                       :
        OpenCV.Core.Mat := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      And_Result, Or_Result, Xor_Result, Not_Result, Vec_Result :
        OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Left, 0, 0, 16#AA#);
      OpenCV.Core.UInt8_Access.Set (Right, 0, 0, 16#0F#);
      And_Result := Left.Bitwise_And (Right);
      Or_Result := Left.Bitwise_Or (Right);
      Xor_Result := Left.Bitwise_Xor (Right);
      Not_Result := Left.Bitwise_Not;
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Vec_Left, 0, 0, (16#F0#, 16#0F#, 16#AA#));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Vec_Right, 0, 0, (16#0F#, 16#F0#, 16#55#));
      Vec_Result := Vec_Left.Bitwise_Xor (Vec_Right);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (And_Result, 0, 0) = 16#0A#
         and then OpenCV.Core.UInt8_Access.Get (Or_Result, 0, 0) = 16#AF#
         and then OpenCV.Core.UInt8_Access.Get (Xor_Result, 0, 0) = 16#A5#
         and then OpenCV.Core.UInt8_Access.Get (Not_Result, 0, 0) = 16#55#
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 0, 0)
                  = (16#FF#, 16#FF#, 16#FF#),
         "Bitwise operations must preserve UInt8 and Vec3 bit patterns");
   end Mat_Bitwise_Operations_Handle_UInt8_And_Vec3;

   procedure Mat_Bitwise_Operations_Handle_Int16_And_Float32
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Int16_Left, Int16_Right                      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 1));
      Int16_And, Int16_Not                         : OpenCV.Core.Mat;
      Numerator, Zeroes                            : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Infinity, And_Result, Xor_Result, Not_Result : OpenCV.Core.Mat;
   begin
      Int16_Left.Set_To (OpenCV.Core.Make_Scalar (-1.0));
      Int16_Right.Set_To (OpenCV.Core.Make_Scalar (255.0));
      Int16_And := Int16_Left.Bitwise_And (Int16_Right);
      Int16_Not := Int16_Right.Bitwise_Not;
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 0, 1.0);
      Zeroes.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Infinity := Numerator.Divide (Zeroes);
      And_Result := Infinity.Bitwise_And (Infinity);
      Xor_Result := Infinity.Bitwise_Xor (Infinity);
      Not_Result := Infinity.Bitwise_Not;

      AUnit.Assertions.Assert
        (Int16_And.Sum.Component_0 = 255.0
         and then Int16_Not.Sum.Component_0 = -256.0
         and then OpenCV.Core.Float32_Access.Classify (And_Result, 0, 0)
                  = OpenCV.Core.Float32_Access.Positive_Infinity
         and then OpenCV.Core.Float32_Access.Classify (Xor_Result, 0, 0)
                  = OpenCV.Core.Float32_Access.Finite
         and then OpenCV.Core.Float32_Access.Classify (Not_Result, 0, 0)
                  = OpenCV.Core.Float32_Access.Finite,
         "Bitwise operations must use signed and Float32 stored bit patterns");
   end Mat_Bitwise_Operations_Handle_Int16_And_Float32;

   procedure Mat_Bitwise_Operations_Handle_Regions_And_Independence
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left, Right                                        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.UInt8, 1));
      Result                                             : OpenCV.Core.Mat;
      Empty_Left, Empty_Right, Empty_Binary, Empty_Unary : OpenCV.Core.Mat;
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (240.0));
      Right.Set_To (OpenCV.Core.Make_Scalar (15.0));
      Result :=
        Left.Region ((1, 0, 2, 3)).Bitwise_Or (Right.Region ((1, 0, 2, 3)));
      OpenCV.Core.UInt8_Access.Set (Left, 0, 1, 0);
      OpenCV.Core.UInt8_Access.Set (Result, 0, 1, 16#33#);
      Empty_Binary := Empty_Left.Bitwise_And (Empty_Right);
      Empty_Unary := Empty_Left.Bitwise_Not;

      AUnit.Assertions.Assert
        (Result.Is_Continuous
         and then OpenCV.Core.UInt8_Access.Get (Result, 0, 0) = 16#FF#
         and then OpenCV.Core.UInt8_Access.Get (Left, 0, 2) = 16#F0#
         and then OpenCV.Core.UInt8_Access.Get (Right, 0, 2) = 16#0F#
         and then Empty_Binary.Is_Empty
         and then Empty_Unary.Is_Empty,
         "Bitwise operations must support Regions, independence, and empty"
         & " Mats");
   end Mat_Bitwise_Operations_Handle_Regions_And_Independence;

   procedure Mat_Bitwise_Compatibility_Failures
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Base     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Rows     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 1));
      Columns  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Depth    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Channels : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      procedure Bad_Rows is
         X : constant OpenCV.Core.Mat := Base.Bitwise_And (Rows);
      begin
         pragma Unreferenced (X);
      end Bad_Rows;
      procedure Bad_Columns is
         X : constant OpenCV.Core.Mat := Base.Bitwise_Or (Columns);
      begin
         pragma Unreferenced (X);
      end Bad_Columns;
      procedure Bad_Depth is
         X : constant OpenCV.Core.Mat := Base.Bitwise_Xor (Depth);
      begin
         pragma Unreferenced (X);
      end Bad_Depth;
      procedure Bad_Channels is
         X : constant OpenCV.Core.Mat := Base.Bitwise_And (Channels);
      begin
         pragma Unreferenced (X);
      end Bad_Channels;
   begin
      Assert_Raises_OpenCV_Error
        (Bad_Rows'Access, "Bitwise_And must reject mismatched rows");
      Assert_Raises_OpenCV_Error
        (Bad_Columns'Access, "Bitwise_Or must reject mismatched columns");
      Assert_Raises_OpenCV_Error
        (Bad_Depth'Access, "Bitwise_Xor must reject mismatched depths");
      Assert_Raises_OpenCV_Error
        (Bad_Channels'Access, "Bitwise_And must reject mismatched channels");
   end Mat_Bitwise_Compatibility_Failures;

   procedure Masked_Bitwise_Operations_Select_Nonzero_Values
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left, Right, Mask                             : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      And_Result, Or_Result, Xor_Result, Not_Result : OpenCV.Core.Mat;
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (170.0));
      Right.Set_To (OpenCV.Core.Make_Scalar (15.0));
      OpenCV.Core.UInt8_Access.Set (Mask, 0, 0, 0);
      OpenCV.Core.UInt8_Access.Set (Mask, 0, 1, 1);
      OpenCV.Core.UInt8_Access.Set (Mask, 1, 0, 255);
      OpenCV.Core.UInt8_Access.Set (Mask, 1, 1, 0);
      And_Result := Left.Bitwise_And (Right, Mask);
      Or_Result := Left.Bitwise_Or (Right, Mask);
      Xor_Result := Left.Bitwise_Xor (Right, Mask);
      Not_Result := Left.Bitwise_Not (Mask);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (And_Result, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (And_Result, 0, 1) = 16#0A#
         and then OpenCV.Core.UInt8_Access.Get (And_Result, 1, 0) = 16#0A#
         and then OpenCV.Core.UInt8_Access.Get (Or_Result, 0, 1) = 16#AF#
         and then OpenCV.Core.UInt8_Access.Get (Xor_Result, 1, 0) = 16#A5#
         and then OpenCV.Core.UInt8_Access.Get (Not_Result, 0, 1) = 16#55#
         and then OpenCV.Core.UInt8_Access.Get (Not_Result, 1, 1) = 0,
         "Masked bitwise operations must select any nonzero UInt8 mask value"
         & " and zero unselected new output");
   end Masked_Bitwise_Operations_Select_Nonzero_Values;

   procedure Masked_Bitwise_Vec3_Regions_Independence
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Vec_Left, Vec_Right        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 3));
      Vec_Mask                   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Source, Other, Mask_Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Vec_Result, Region_Result  : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Vec_Left, 0, 0, (16#F0#, 16#0F#, 16#AA#));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Vec_Right, 0, 0, (16#0F#, 16#F0#, 16#55#));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vec_Left, 0, 1, (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vec_Right, 0, 1, (4, 5, 6));
      Vec_Mask.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Vec_Mask, 0, 0, 1);
      Vec_Result := Vec_Left.Bitwise_Xor (Vec_Right, Vec_Mask);
      Source.Set_To (OpenCV.Core.Make_Scalar (240.0));
      Other.Set_To (OpenCV.Core.Make_Scalar (15.0));
      Mask_Parent.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Mask_Parent, 0, 1, 255);
      OpenCV.Core.UInt8_Access.Set (Mask_Parent, 1, 2, 1);
      Region_Result :=
        Source.Region ((1, 0, 2, 2)).Bitwise_Or
          (Other.Region ((1, 0, 2, 2)), Mask_Parent.Region ((1, 0, 2, 2)));
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 0);
      OpenCV.Core.UInt8_Access.Set (Mask_Parent, 0, 1, 0);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 0, 0)
         = (16#FF#, 16#FF#, 16#FF#)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 0, 1)
                  = (0, 0, 0)
         and then not Mask_Parent.Region ((1, 0, 2, 2)).Is_Continuous
         and then Region_Result.Is_Continuous
         and then OpenCV.Core.UInt8_Access.Get (Region_Result, 0, 0) = 16#FF#
         and then OpenCV.Core.UInt8_Access.Get (Region_Result, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Region_Result, 1, 1) = 16#FF#,
         "Masked bitwise operations must support Vec3 and non-continuous masks"
         & " with independent output");
   end Masked_Bitwise_Vec3_Regions_Independence;

   procedure Masked_Bitwise_Invalid_Masks_And_Empty
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source, Other                          : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Float_Mask                             : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Multi_Mask                             : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Rows_Mask                              : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 1));
      Columns_Mask                           : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Empty_Source, Empty_Mask, Empty_Result : OpenCV.Core.Mat;
      procedure Float_Depth is
         X : constant OpenCV.Core.Mat :=
           Source.Bitwise_And (Other, Float_Mask);
      begin
         pragma Unreferenced (X);
      end Float_Depth;
      procedure Multi_Channel is
         X : constant OpenCV.Core.Mat := Source.Bitwise_Or (Other, Multi_Mask);
      begin
         pragma Unreferenced (X);
      end Multi_Channel;
      procedure Wrong_Rows is
         X : constant OpenCV.Core.Mat := Source.Bitwise_Xor (Other, Rows_Mask);
      begin
         pragma Unreferenced (X);
      end Wrong_Rows;
      procedure Wrong_Columns is
         X : constant OpenCV.Core.Mat := Source.Bitwise_Not (Columns_Mask);
      begin
         pragma Unreferenced (X);
      end Wrong_Columns;
   begin
      Empty_Result := Empty_Source.Bitwise_Not (Empty_Mask);
      AUnit.Assertions.Assert
        (Empty_Result.Is_Empty,
         "Masked empty Mat operation must remain empty");
      Assert_Raises_OpenCV_Error
        (Float_Depth'Access, "Mask must reject Float32 depth");
      Assert_Raises_OpenCV_Error
        (Multi_Channel'Access, "Mask must reject multiple channels");
      Assert_Raises_OpenCV_Error
        (Wrong_Rows'Access, "Mask must reject wrong rows");
      Assert_Raises_OpenCV_Error
        (Wrong_Columns'Access, "Mask must reject wrong columns");
   end Masked_Bitwise_Invalid_Masks_And_Empty;

   procedure In_Range_Uses_Inclusive_UInt8_Bounds_And_Mask_Contract
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source              : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 5, (OpenCV.Core.UInt8, 1));
      Range_Mask, Applied : OpenCV.Core.Mat;
      Other               : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 5, (OpenCV.Core.UInt8, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 9);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 10);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 2, 15);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 3, 20);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 4, 21);
      Other.Set_To (OpenCV.Core.Make_Scalar (255.0));
      Range_Mask :=
        Source.In_Range
          (Lower => OpenCV.Core.Make_Scalar (10.0),
           Upper => OpenCV.Core.Make_Scalar (20.0));
      Applied := Source.Bitwise_And (Other, Range_Mask);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 2, 0);

      AUnit.Assertions.Assert
        (Range_Mask.Rows = Source.Rows
         and then Range_Mask.Columns = Source.Columns
         and then Range_Mask.Depth = OpenCV.Core.UInt8
         and then Range_Mask.Channels = 1
         and then OpenCV.Core.UInt8_Access.Get (Range_Mask, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Range_Mask, 0, 1) = 255
         and then OpenCV.Core.UInt8_Access.Get (Range_Mask, 0, 2) = 255
         and then OpenCV.Core.UInt8_Access.Get (Range_Mask, 0, 3) = 255
         and then OpenCV.Core.UInt8_Access.Get (Range_Mask, 0, 4) = 0
         and then OpenCV.Core.UInt8_Access.Get (Applied, 0, 2) = 15,
         "In_Range must be inclusive and produce a directly usable mask");
   end In_Range_Uses_Inclusive_UInt8_Bounds_And_Mask_Contract;

   procedure In_Range_Handles_Float32_Vec3_And_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Float_Image                       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
      Vec_Image                         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 5, (OpenCV.Core.Float32, 3));
      Region_Source                     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Float_Mask, Vec_Mask, Region_Mask : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Float_Image, 0, 0, -1.5);
      OpenCV.Core.Float32_Access.Set (Float_Image, 0, 1, -1.0);
      OpenCV.Core.Float32_Access.Set (Float_Image, 0, 2, 0.5);
      OpenCV.Core.Float32_Access.Set (Float_Image, 0, 3, 1.25);
      Float_Mask :=
        Float_Image.In_Range
          (OpenCV.Core.Make_Scalar (-1.0), OpenCV.Core.Make_Scalar (1.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Vec_Image, 0, 0, (1.0, 2.0, 3.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Vec_Image, 0, 1, (0.0, 2.0, 3.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Vec_Image, 0, 2, (1.0, 4.0, 3.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Vec_Image, 0, 3, (1.0, 2.0, 4.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Vec_Image, 0, 4, (1.0, 2.0, 3.0));
      Vec_Mask :=
        Vec_Image.In_Range
          (OpenCV.Core.Make_Scalar (1.0, 2.0, 3.0),
           OpenCV.Core.Make_Scalar (1.0, 2.0, 3.0));
      Region_Source.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Region_Source, 0, 1, 10);
      OpenCV.Core.UInt8_Access.Set (Region_Source, 0, 2, 20);
      OpenCV.Core.UInt8_Access.Set (Region_Source, 1, 1, 15);
      OpenCV.Core.UInt8_Access.Set (Region_Source, 1, 2, 25);
      Region_Mask :=
        Region_Source.Region ((1, 0, 2, 2)).In_Range
          (OpenCV.Core.Make_Scalar (10.0), OpenCV.Core.Make_Scalar (20.0));

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Float_Mask, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Float_Mask, 0, 1) = 255
         and then OpenCV.Core.UInt8_Access.Get (Float_Mask, 0, 2) = 255
         and then OpenCV.Core.UInt8_Access.Get (Float_Mask, 0, 3) = 0
         and then OpenCV.Core.UInt8_Access.Get (Vec_Mask, 0, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Vec_Mask, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Vec_Mask, 0, 2) = 0
         and then OpenCV.Core.UInt8_Access.Get (Vec_Mask, 0, 3) = 0
         and then OpenCV.Core.UInt8_Access.Get (Vec_Mask, 0, 4) = 255
         and then Region_Mask.Is_Continuous
         and then OpenCV.Core.UInt8_Access.Get (Region_Mask, 0, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Region_Mask, 0, 1) = 255
         and then OpenCV.Core.UInt8_Access.Get (Region_Mask, 1, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Region_Mask, 1, 1) = 0,
         "In_Range must use fractional bounds, all Vec3 channels, and"
         & " Regions");
   end In_Range_Handles_Float32_Vec3_And_Regions;

   procedure In_Range_Handles_Nonfinite_Empty_And_Channel_Failures
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Numerator, Zeroes : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Nonfinite, Mask   : OpenCV.Core.Mat;
      Empty             : OpenCV.Core.Mat;
      Five_Channel      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 5));
      procedure Empty_Source is
         X : constant OpenCV.Core.Mat :=
           Empty.In_Range
             (OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      begin
         pragma Unreferenced (X);
      end Empty_Source;
      procedure Too_Many_Channels is
         X : constant OpenCV.Core.Mat :=
           Five_Channel.In_Range
             (OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (255.0));
      begin
         pragma Unreferenced (X);
      end Too_Many_Channels;
   begin
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 2, -1.0);
      Zeroes.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Nonfinite := Numerator.Divide (Zeroes);
      Mask :=
        Nonfinite.In_Range
          (OpenCV.Core.Make_Scalar (-1.0), OpenCV.Core.Make_Scalar (1.0));

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Mask, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Mask, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Mask, 0, 2) = 0,
         "In_Range must reject NaN and infinite values against finite bounds");
      Assert_Raises_OpenCV_Error
        (Empty_Source'Access, "In_Range must reject an empty source");
      Assert_Raises_OpenCV_Error
        (Too_Many_Channels'Access,
         "In_Range must reject more than four channels");
   end In_Range_Handles_Nonfinite_Empty_And_Channel_Failures;

   procedure Compare_UInt8_All_Modes_And_Mask_Contract
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left                   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.UInt8, 1));
      Right                  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.UInt8, 1));
      Eq, Ne, Lt, Le, Gt, Ge : OpenCV.Core.Mat;
      Other, Applied         : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Left, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Left, 0, 1, 5);
      OpenCV.Core.UInt8_Access.Set (Left, 0, 2, 10);
      OpenCV.Core.UInt8_Access.Set (Left, 0, 3, 20);
      OpenCV.Core.UInt8_Access.Set (Right, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Right, 0, 1, 4);
      OpenCV.Core.UInt8_Access.Set (Right, 0, 2, 10);
      OpenCV.Core.UInt8_Access.Set (Right, 0, 3, 30);

      Eq := Left.Compare (Right, OpenCV.Core.Equal);
      Ne := Left.Compare (Right, OpenCV.Core.Not_Equal);
      Lt := Left.Compare (Right, OpenCV.Core.Less_Than);
      Le := Left.Compare (Right, OpenCV.Core.Less_Or_Equal);
      Gt := Left.Compare (Right, OpenCV.Core.Greater_Than);
      Ge := Left.Compare (Right, OpenCV.Core.Greater_Or_Equal);

      Other := OpenCV.Core.Create (1, 4, (OpenCV.Core.UInt8, 1));
      Other.Set_To (OpenCV.Core.Make_Scalar (255.0));
      Applied := Left.Bitwise_And (Other, Ge);
      OpenCV.Core.UInt8_Access.Set (Left, 0, 1, 0);

      AUnit.Assertions.Assert
        (Eq.Rows = 1
         and then Eq.Columns = 4
         and then Eq.Depth = OpenCV.Core.UInt8
         and then Eq.Channels = 1
         and then OpenCV.Core.UInt8_Access.Get (Eq, 0, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Eq, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Eq, 0, 2) = 255
         and then OpenCV.Core.UInt8_Access.Get (Eq, 0, 3) = 0
         and then OpenCV.Core.UInt8_Access.Get (Ne, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Ne, 0, 1) = 255
         and then OpenCV.Core.UInt8_Access.Get (Ne, 0, 2) = 0
         and then OpenCV.Core.UInt8_Access.Get (Ne, 0, 3) = 255
         and then OpenCV.Core.UInt8_Access.Get (Lt, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Lt, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Lt, 0, 2) = 0
         and then OpenCV.Core.UInt8_Access.Get (Lt, 0, 3) = 255
         and then OpenCV.Core.UInt8_Access.Get (Le, 0, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Le, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Le, 0, 2) = 255
         and then OpenCV.Core.UInt8_Access.Get (Le, 0, 3) = 255
         and then OpenCV.Core.UInt8_Access.Get (Gt, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Gt, 0, 1) = 255
         and then OpenCV.Core.UInt8_Access.Get (Gt, 0, 2) = 0
         and then OpenCV.Core.UInt8_Access.Get (Gt, 0, 3) = 0
         and then OpenCV.Core.UInt8_Access.Get (Ge, 0, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Ge, 0, 1) = 255
         and then OpenCV.Core.UInt8_Access.Get (Ge, 0, 2) = 255
         and then OpenCV.Core.UInt8_Access.Get (Ge, 0, 3) = 0
         and then OpenCV.Core.UInt8_Access.Get (Applied, 0, 1) = 5,
         "Compare must cover all UInt8 modes and produce a usable mask");
   end Compare_UInt8_All_Modes_And_Mask_Contract;

   procedure Compare_Float32_NaN_And_Regions (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left                         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
      Right                        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
      Eq, Ne                       : OpenCV.Core.Mat;
      Region_Left                  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Region_Right                 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Region_Mask                  : OpenCV.Core.Mat;
      Numerator, Zeroes, Nonfinite : OpenCV.Core.Mat;
      Finite                       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Nan_Eq                       : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Left, 0, 0, -1.5);
      OpenCV.Core.Float32_Access.Set (Left, 0, 1, 0.5);
      OpenCV.Core.Float32_Access.Set (Left, 0, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Left, 0, 3, 2.25);
      OpenCV.Core.Float32_Access.Set (Right, 0, 0, -1.5);
      OpenCV.Core.Float32_Access.Set (Right, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 3, 0.0);
      Eq := Left.Compare (Right, OpenCV.Core.Equal);
      Ne := Left.Compare (Right, OpenCV.Core.Not_Equal);

      Region_Left.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Region_Right.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Region_Left, 0, 1, 10);
      OpenCV.Core.UInt8_Access.Set (Region_Left, 0, 2, 20);
      OpenCV.Core.UInt8_Access.Set (Region_Left, 1, 1, 30);
      OpenCV.Core.UInt8_Access.Set (Region_Left, 1, 2, 5);
      OpenCV.Core.UInt8_Access.Set (Region_Right, 0, 1, 10);
      OpenCV.Core.UInt8_Access.Set (Region_Right, 0, 2, 15);
      OpenCV.Core.UInt8_Access.Set (Region_Right, 1, 1, 25);
      OpenCV.Core.UInt8_Access.Set (Region_Right, 1, 2, 5);
      Region_Mask :=
        Region_Left.Region ((1, 0, 2, 2)).Compare
          (Region_Right.Region ((1, 0, 2, 2)), OpenCV.Core.Greater_Than);

      Numerator := OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Zeroes := OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 2, -1.0);
      Zeroes.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Nonfinite := Numerator.Divide (Zeroes);
      Finite.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Nan_Eq := Nonfinite.Compare (Finite, OpenCV.Core.Equal);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Eq, 0, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Eq, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Eq, 0, 2) = 255
         and then OpenCV.Core.UInt8_Access.Get (Eq, 0, 3) = 0
         and then OpenCV.Core.UInt8_Access.Get (Ne, 0, 1) = 255
         and then OpenCV.Core.UInt8_Access.Get (Ne, 0, 3) = 255
         and then Region_Mask.Is_Continuous
         and then Region_Mask.Rows = 2
         and then Region_Mask.Columns = 2
         and then OpenCV.Core.UInt8_Access.Get (Region_Mask, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Region_Mask, 0, 1) = 255
         and then OpenCV.Core.UInt8_Access.Get (Region_Mask, 1, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Region_Mask, 1, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Nan_Eq, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Nan_Eq, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Nan_Eq, 0, 2) = 0,
         "Compare must handle Float32, NaN, and non-contiguous Regions");
   end Compare_Float32_NaN_And_Regions;

   procedure Compare_Rejects_Incompatible_Operands
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Base  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Rows  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.UInt8, 1));
      Cols  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.UInt8, 1));
      Depth : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Multi : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 3));
      procedure Bad_Rows is
         X : constant OpenCV.Core.Mat :=
           Base.Compare (Rows, OpenCV.Core.Equal);
      begin
         pragma Unreferenced (X);
      end Bad_Rows;
      procedure Bad_Columns is
         X : constant OpenCV.Core.Mat :=
           Base.Compare (Cols, OpenCV.Core.Equal);
      begin
         pragma Unreferenced (X);
      end Bad_Columns;
      procedure Bad_Depth is
         X : constant OpenCV.Core.Mat :=
           Base.Compare (Depth, OpenCV.Core.Equal);
      begin
         pragma Unreferenced (X);
      end Bad_Depth;
      procedure Bad_Channels is
         X : constant OpenCV.Core.Mat :=
           Base.Compare (Multi, OpenCV.Core.Equal);
      begin
         pragma Unreferenced (X);
      end Bad_Channels;
      procedure Multi_Left is
         X : constant OpenCV.Core.Mat :=
           Multi.Compare (Base, OpenCV.Core.Equal);
      begin
         pragma Unreferenced (X);
      end Multi_Left;
   begin
      Assert_Raises_OpenCV_Error
        (Bad_Rows'Access, "Compare must reject mismatched rows");
      Assert_Raises_OpenCV_Error
        (Bad_Columns'Access, "Compare must reject mismatched columns");
      Assert_Raises_OpenCV_Error
        (Bad_Depth'Access, "Compare must reject mismatched depths");
      Assert_Raises_OpenCV_Error
        (Bad_Channels'Access, "Compare must reject multi-channel right");
      Assert_Raises_OpenCV_Error
        (Multi_Left'Access, "Compare must reject multi-channel left");
   end Compare_Rejects_Incompatible_Operands;

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);

   Result : aliased AUnit.Test_Suites.Test_Suite;

   procedure Size_And_Point_Are_Ordinary_Value_Types
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Dimensions : constant OpenCV.Core.Size := (Width => 5, Height => 3);
      Empty_Size : constant OpenCV.Core.Size := (Width => 0, Height => 0);
      Positive   : constant OpenCV.Core.Point := (X => 7, Y => 11);
      Negative   : constant OpenCV.Core.Point := (X => -7, Y => -11);
   begin
      AUnit.Assertions.Assert
        (Dimensions.Width = 5 and then Dimensions.Height = 3,
         "Size must preserve its width and height");
      AUnit.Assertions.Assert
        (Empty_Size.Width = 0 and then Empty_Size.Height = 0,
         "Size must permit zero width and height");
      AUnit.Assertions.Assert
        (Positive.X = 7 and then Positive.Y = 11,
         "Point must preserve positive X and Y coordinates");
      AUnit.Assertions.Assert
        (Negative.X = -7 and then Negative.Y = -11,
         "Point must preserve negative X and Y coordinates");
   end Size_And_Point_Are_Ordinary_Value_Types;

   procedure Mat_Dimensions_Reflect_Mat_And_View_Shapes
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Image      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 5,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Float_Vec3_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 6,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      View             : constant OpenCV.Core.Mat :=
        UInt8_Image.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Reshaped         : constant OpenCV.Core.Mat :=
        Float_Vec3_Image.Reshape (Channels => 1, Rows => 6);
      Converted        : constant OpenCV.Core.Mat :=
        UInt8_Image.Convert_To (Depth => OpenCV.Core.Float32);
   begin
      AUnit.Assertions.Assert
        (UInt8_Image.Dimensions.Width = 5
         and then UInt8_Image.Dimensions.Height = 3,
         "A UInt8 Mat dimensions must map columns to width and rows"
         & " to height");
      AUnit.Assertions.Assert
        (Float_Vec3_Image.Dimensions.Width = 6
         and then Float_Vec3_Image.Dimensions.Height = 4,
         "A Float32 Vec3 Mat dimensions must preserve its shape");
      AUnit.Assertions.Assert
        (View.Dimensions.Width = 3 and then View.Dimensions.Height = 2,
         "A Region dimensions must report its ROI width and height");
      AUnit.Assertions.Assert
        (Reshaped.Dimensions.Width = 12
         and then Reshaped.Dimensions.Height = 6,
         "A reshape result dimensions must report its derived shape");
      AUnit.Assertions.Assert
        (Converted.Dimensions.Width
         = OpenCV.Core.Size_Coordinate (UInt8_Image.Columns)
         and then Converted.Dimensions.Height
                  = OpenCV.Core.Size_Coordinate (UInt8_Image.Rows),
         "A Convert_To result dimensions must preserve its source shape");
   end Mat_Dimensions_Reflect_Mat_And_View_Shapes;

   procedure Create_With_Size_Integrates_With_Typed_Access
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Dimensions   => (Width => 5, Height => 3),
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
   begin
      AUnit.Assertions.Assert
        (Image.Rows = 3 and then Image.Columns = 5,
         "Create with Size must map height to rows and width to columns");
      AUnit.Assertions.Assert
        (Image.Dimensions.Width = 5 and then Image.Dimensions.Height = 3,
         "Create with Size must preserve dimensions");
      AUnit.Assertions.Assert
        (Image.Depth = OpenCV.Core.UInt8 and then Image.Channels = 1,
         "Create with Size must preserve the requested element type");
      OpenCV.Core.UInt8_Access.Set
        (Image, Row => 2, Column => 4, Value => 123);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Image, Row => 2, Column => 4) = 123,
         "Create with Size must interoperate with typed element access");
   end Create_With_Size_Integrates_With_Typed_Access;

   procedure Empty_Mat_Has_Zero_Dimensions (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat;
   begin
      AUnit.Assertions.Assert
        (Image.Dimensions.Width = 0 and then Image.Dimensions.Height = 0,
         "A default empty Mat must have zero width and height");
      AUnit.Assertions.Assert
        (Image.Dimensions.Width = OpenCV.Core.Size_Coordinate (Image.Columns)
         and then Image.Dimensions.Height
                  = OpenCV.Core.Size_Coordinate (Image.Rows),
         "Mat dimensions must remain consistent with columns and rows");
   end Empty_Mat_Has_Zero_Dimensions;

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
           ("Mat Add and Subtract work for Float32",
            Mat_Add_And_Subtract_Work_For_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat arithmetic saturates and supports Vec3",
            Mat_Arithmetic_Saturates_And_Supports_Vec3'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat arithmetic supports Int16",
            Mat_Arithmetic_Supports_Int16'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat arithmetic is independent and handles Regions",
            Mat_Arithmetic_Is_Independent_And_Handles_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat arithmetic rejects incompatible operands and handles empty",
            Mat_Arithmetic_Compatibility_And_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Multiply and Divide work for Float32",
            Mat_Multiply_And_Divide_Work_For_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Multiply and Divide handle UInt8 and Vec3",
            Mat_Multiply_And_Divide_Handle_UInt8_And_Vec3'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Divide by zero preserves OpenCV semantics",
            Mat_Divide_By_Zero_Preserves_OpenCV_Semantics'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 classification identifies stored values",
            Float32_Classification_Identifies_Stored_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Multiply and Divide handle Regions and independence",
            Mat_Multiply_And_Divide_Handle_Regions_And_Independence'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Multiply and Divide handle Int16, empty, and compatibility",
            Mat_Multiply_Divide_Int16_Empty_Compatibility'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Abs_Diff handles Float32 and metadata",
            Mat_Abs_Diff_Handles_Float32_And_Metadata'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Abs_Diff handles UInt8, Vec3, and Int16",
            Mat_Abs_Diff_Handles_UInt8_Vec3_And_Int16'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Abs_Diff handles Regions, nonfinite, and independence",
            Mat_Abs_Diff_Handles_Regions_Nonfinite_And_Independence'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Abs_Diff rejects incompatible operands",
            Mat_Abs_Diff_Rejects_Incompatible_Operands'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Add_Weighted handles Float32 and metadata",
            Mat_Add_Weighted_Handles_Float32_And_Metadata'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Add_Weighted handles UInt8, Vec3, and Int16",
            Mat_Add_Weighted_Handles_UInt8_Vec3_And_Int16'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Add_Weighted handles Regions, empty, and independence",
            Mat_Add_Weighted_Handles_Regions_Empty_And_Independence'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Add_Weighted rejects incompatible operands",
            Mat_Add_Weighted_Rejects_Incompatible_Operands'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat bitwise operations handle UInt8 and Vec3",
            Mat_Bitwise_Operations_Handle_UInt8_And_Vec3'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat bitwise operations handle Int16 and Float32",
            Mat_Bitwise_Operations_Handle_Int16_And_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat bitwise operations handle Regions and independence",
            Mat_Bitwise_Operations_Handle_Regions_And_Independence'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat bitwise binary operations reject incompatible operands",
            Mat_Bitwise_Compatibility_Failures'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked bitwise operations select nonzero values",
            Masked_Bitwise_Operations_Select_Nonzero_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked bitwise operations handle Vec3, Regions, and independence",
            Masked_Bitwise_Vec3_Regions_Independence'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked bitwise operations reject invalid masks and handle empty",
            Masked_Bitwise_Invalid_Masks_And_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("In_Range uses inclusive UInt8 bounds and mask contract",
            In_Range_Uses_Inclusive_UInt8_Bounds_And_Mask_Contract'Access));
      Result.Add_Test
        (Caller.Create
           ("In_Range handles Float32, Vec3, and Regions",
            In_Range_Handles_Float32_Vec3_And_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("In_Range handles nonfinite, empty, and channel failures",
            In_Range_Handles_Nonfinite_Empty_And_Channel_Failures'Access));
      Result.Add_Test
        (Caller.Create
           ("Compare covers UInt8 modes and mask contract",
            Compare_UInt8_All_Modes_And_Mask_Contract'Access));
      Result.Add_Test
        (Caller.Create
           ("Compare handles Float32, NaN, and Regions",
            Compare_Float32_NaN_And_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("Compare rejects incompatible operands",
            Compare_Rejects_Incompatible_Operands'Access));
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
           ("Size and Point are ordinary value types",
            Size_And_Point_Are_Ordinary_Value_Types'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat dimensions reflect Mat and view shapes",
            Mat_Dimensions_Reflect_Mat_And_View_Shapes'Access));
      Result.Add_Test
        (Caller.Create
           ("Create with Size integrates with typed access",
            Create_With_Size_Integrates_With_Typed_Access'Access));
      Result.Add_Test
        (Caller.Create
           ("Empty Mat has zero dimensions",
            Empty_Mat_Has_Zero_Dimensions'Access));
      Result.Add_Test
        (Caller.Create
           ("Row view has metadata and shares data",
            Row_View_Has_Metadata_And_Shares_Data'Access));
      Result.Add_Test
        (Caller.Create
           ("Column view has metadata and shares data",
            Column_View_Has_Metadata_And_Shares_Data'Access));
      Result.Add_Test
        (Caller.Create
           ("Range views have metadata and share data",
            Range_Views_Have_Metadata_And_Share_Data'Access));
      Result.Add_Test
        (Caller.Create
           ("Range view preserves UInt8 Vec3 access",
            Range_View_Preserves_UInt8_Vec3_Access'Access));
      Result.Add_Test
        (Caller.Create
           ("Range view survives source finalization and Clone",
            Range_View_Survives_Source_Finalization_And_Clone'Access));
      Result.Add_Test
        (Caller.Create
           ("View operations reject invalid ranges and accept empty",
            View_Operations_Reject_Invalid_Ranges_And_Accept_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("Default Mat reports empty", Default_Mat_Is_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("Assigned default Mat reports empty",
            Assigned_Mat_Is_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 single-channel Mat metadata",
            UInt8_Single_Channel_Mat_Has_Requested_Metadata'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 three-channel Mat metadata",
            Float32_Three_Channel_Mat_Has_Requested_Metadata'Access));
      Result.Add_Test
        (Caller.Create
           ("Constructed Mat copy preserves metadata",
            Constructed_Mat_Copy_Preserves_Metadata'Access));
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
      Result.Add_Test
        (Caller.Create
           ("Assignment shares Set_To data",
            Assignment_Shares_Set_To_Data'Access));
      Result.Add_Test
        (Caller.Create
           ("Original survives copy finalization",
            Original_Survives_Copy_Finalization'Access));
      Result.Add_Test
        (Caller.Create
           ("Clone copies Mat metadata and data",
            Clone_Copies_Metadata_And_Data'Access));
      Result.Add_Test
        (Caller.Create
           ("Assignment shares data while Clone isolates data",
            Assignment_Shares_But_Clone_Is_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 typed element access", UInt8_Typed_Element_Access'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 typed element access",
            Float32_Typed_Element_Access'Access));
      Result.Add_Test
        (Caller.Create
           ("Typed access rejects incompatible depth",
            Typed_Access_Rejects_Incompatible_Depth'Access));
      Result.Add_Test
        (Caller.Create
           ("Typed access rejects multi-channel Mat",
            Typed_Access_Rejects_Multi_Channel_Mat'Access));
      Result.Add_Test
        (Caller.Create
           ("Typed access rejects out-of-bounds indices",
            Typed_Access_Rejects_Out_Of_Bounds_Indices'Access));
      Result.Add_Test
        (Caller.Create
           ("Clone isolates typed element writes",
            Clone_Isolates_Typed_Element_Writes'Access));
      Result.Add_Test
        (Caller.Create
           ("Empty Mat clone finalizes safely",
            Empty_Mat_Clone_Is_Empty_And_Finalizes_Safely'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 typed element access",
            UInt8_Vec3_Typed_Element_Access'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec3 typed element access",
            Float32_Vec3_Typed_Element_Access'Access));
      Result.Add_Test
        (Caller.Create
           ("Vec3 typed access rejects invalid Mats and indices",
            Vec3_Typed_Access_Rejects_Invalid_Mats_And_Indices'Access));
      Result.Add_Test
        (Caller.Create
           ("Vec3 access proves assignment and Clone semantics",
            Vec3_Access_Proves_Assignment_And_Clone_Semantics'Access));
      Result.Add_Test
        (Caller.Create
           ("Region has metadata and shares data",
            Region_Has_Metadata_And_Shares_Data'Access));
      Result.Add_Test
        (Caller.Create
           ("Region preserves UInt8 Vec3 access",
            Region_Preserves_UInt8_Vec3_Access'Access));
      Result.Add_Test
        (Caller.Create
           ("Region survives source and temporary finalization",
            Region_Survives_Source_And_Temporary_Finalization'Access));
      Result.Add_Test
        (Caller.Create
           ("Region Clone is independent",
            Region_Clone_Is_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Region rejects invalid areas",
            Region_Rejects_Invalid_Areas'Access));
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
           ("Mat storage metadata for basic and multi-channel Mats",
            Mat_Storage_Metadata_For_Basic_And_Multi_Channel_Mats'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat storage metadata for Float32 Mats",
            Mat_Storage_Metadata_For_Float32_Mats'Access));
      Result.Add_Test
        (Caller.Create
           ("Region reports authoritative storage layout",
            Region_Reports_Authoritative_Storage_Layout'Access));
      Result.Add_Test
        (Caller.Create
           ("Clone and Convert_To report storage metadata",
            Clone_And_Convert_To_Report_Storage_Metadata'Access));
      Result.Add_Test
        (Caller.Create
           ("Empty Mat reports authoritative storage metadata",
            Empty_Mat_Reports_Authoritative_Storage_Metadata'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 row access reads, writes, and preserves array order",
            UInt8_Row_Access_Reads_Writes_And_Preserves_Array_Order'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 row access reads, writes, and preserves array order",
            Float32_Row_Access_Reads_Writes_And_Preserves_Array_Order'Access));
      Result.Add_Test
        (Caller.Create
           ("Row access handles non-continuous Regions",
            Row_Access_Handles_Non_Continuous_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("Row access respects assignment and Clone semantics",
            Row_Access_Respects_Assignment_And_Clone_Semantics'Access));
      Result.Add_Test
        (Caller.Create
           ("Row access rejects invalid Mats, indices, and lengths",
            Row_Access_Rejects_Invalid_Mats_Indices_And_Lengths'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 row access reads, writes, and interoperates",
            UInt8_Vec3_Row_Access_Reads_Writes_And_Interoperates'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec3 row access reads, writes, and interoperates",
            Float32_Vec3_Row_Access_Reads_Writes_And_Interoperates'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 row access handles non-continuous Regions",
            UInt8_Vec3_Row_Access_Handles_Non_Continuous_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 row access respects assignment and Clone",
            UInt8_Vec3_Row_Access_Respects_Assignment_And_Clone'Access));
      Result.Add_Test
        (Caller.Create
           ("Vec3 row access rejects invalid Mats, indices, and lengths",
            Vec3_Row_Access_Rejects_Invalid_Mats_Indices_And_Lengths'Access));
      Result.Add_Test
        (Caller.Create
           ("Reshape changes channels and preserves scalar order",
            Reshape_Changes_Channels_And_Preserves_Scalar_Order'Access));
      Result.Add_Test
        (Caller.Create
           ("Reshape to one channel preserves scalar order",
            Reshape_To_One_Channel_Preserves_Scalar_Order'Access));
      Result.Add_Test
        (Caller.Create
           ("Reshape shares data while Clone is independent",
            Reshape_Shares_Data_But_Clone_Is_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Reshape changes rows and preserves scalar order",
            Reshape_Changes_Rows_And_Preserves_Scalar_Order'Access));
      Result.Add_Test
        (Caller.Create
           ("Reshape rejects invalid shapes",
            Reshape_Rejects_Invalid_Shapes'Access));
      Result.Add_Test
        (Caller.Create
           ("Reshape Region respects continuity requirements",
            Reshape_Region_Respects_Continuity_Requirements'Access));
      Result.Add_Test
        (Caller.Create
           ("Empty Mat reshape remains empty",
            Empty_Mat_Reshape_Remains_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 reshape preserves values",
            Float32_Reshape_Preserves_Values'Access));
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

end Mat_Tests;
