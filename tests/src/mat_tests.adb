with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with AUnit.Test_Fixtures;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float32_Vec3;
with OpenCV.Core.Float32_Vec3_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;

package body Mat_Tests is

   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_8;
   use type OpenCV.Core.Depth_Type;

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

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
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
      return Result'Access;
   end Suite;

end Mat_Tests;
