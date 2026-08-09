with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with AUnit.Test_Fixtures;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
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

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);

   Result : aliased AUnit.Test_Suites.Test_Suite;

   procedure Size_And_Point_Are_Ordinary_Value_Types
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Dimensions : constant OpenCV.Core.Size :=
        (Width  => 5, Height => 3);
      Empty_Size : constant OpenCV.Core.Size :=
        (Width  => 0, Height => 0);
      Positive   : constant OpenCV.Core.Point :=
        (X => 7, Y => 11);
      Negative   : constant OpenCV.Core.Point :=
        (X => -7, Y => -11);
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
      UInt8_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 5,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Float_Vec3_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 6,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      View : constant OpenCV.Core.Mat :=
        UInt8_Image.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Reshaped : constant OpenCV.Core.Mat :=
        Float_Vec3_Image.Reshape (Channels => 1, Rows => 6);
      Converted : constant OpenCV.Core.Mat :=
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
        (Converted.Dimensions.Width =
           OpenCV.Core.Size_Coordinate (UInt8_Image.Columns)
         and then Converted.Dimensions.Height =
                    OpenCV.Core.Size_Coordinate (UInt8_Image.Rows),
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

   procedure Empty_Mat_Has_Zero_Dimensions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat;
   begin
      AUnit.Assertions.Assert
        (Image.Dimensions.Width = 0 and then Image.Dimensions.Height = 0,
         "A default empty Mat must have zero width and height");
      AUnit.Assertions.Assert
        (Image.Dimensions.Width = OpenCV.Core.Size_Coordinate (Image.Columns)
         and then Image.Dimensions.Height =
                    OpenCV.Core.Size_Coordinate (Image.Rows),
         "Mat dimensions must remain consistent with columns and rows");
   end Empty_Mat_Has_Zero_Dimensions;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
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
      return Result'Access;
   end Suite;

end Mat_Tests;
