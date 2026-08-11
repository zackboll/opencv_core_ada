with AUnit.Assertions;
with AUnit.Test_Caller;
with OpenCV.Core;
with OpenCV.Core.UInt8_Access;
with Mat_Test_Support;
with Interfaces;

package body Mat_Basic_Tests is

   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Mat_Size;
   use type OpenCV.Core.Point_Coordinate;
   use type OpenCV.Core.Size_Coordinate;

   use Mat_Test_Support;
   use type Interfaces.Unsigned_8;

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

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);

   Result : aliased AUnit.Test_Suites.Test_Suite;

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
           ("Empty Mat clone finalizes safely",
            Empty_Mat_Clone_Is_Empty_And_Finalizes_Safely'Access));
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
           ("Clone and Convert_To report storage metadata",
            Clone_And_Convert_To_Report_Storage_Metadata'Access));
      Result.Add_Test
        (Caller.Create
           ("Empty Mat reports authoritative storage metadata",
            Empty_Mat_Reports_Authoritative_Storage_Metadata'Access));
      return Result'Access;
   end Suite;

end Mat_Basic_Tests;
