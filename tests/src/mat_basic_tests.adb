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

   procedure Default_And_Typed_Empty_Mats_Report_Distinct_Element_Sizes
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Empty : OpenCV.Core.Mat;
      Empty_UInt8   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.UInt8, 1));
      Empty_Float32 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Empty_Vec3    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 3));
   begin
      AUnit.Assertions.Assert
        (Default_Empty.Is_Empty
         and then Default_Empty.Rows = 0
         and then Default_Empty.Columns = 0
         and then Default_Empty.Element_Size = 0,
         "A genuine default Mat should report zero element bytes");
      AUnit.Assertions.Assert
        (Empty_UInt8.Is_Empty and then Empty_UInt8.Element_Size = 1,
         "A typed empty UInt8 C1 Mat should report a one-byte element");
      AUnit.Assertions.Assert
        (Empty_Float32.Is_Empty and then Empty_Float32.Element_Size = 4,
         "A typed empty Float32 C1 Mat should report a four-byte element");
      AUnit.Assertions.Assert
        (Empty_Vec3.Is_Empty and then Empty_Vec3.Element_Size = 12,
         "A typed empty Float32 C3 Mat should report a twelve-byte element");
   end Default_And_Typed_Empty_Mats_Report_Distinct_Element_Sizes;

   procedure Three_Dimensional_Float32_Mat_Has_Requested_Shape
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4),
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
   begin
      AUnit.Assertions.Assert
        (not Image.Is_Empty, "A 3-D Mat should not be empty");
      AUnit.Assertions.Assert
        (Image.Dimension_Count = 3,
         "A 2 x 3 x 4 Mat should have 3 dimensions");
      AUnit.Assertions.Assert
        (Image.Extent (1) = 2, "Extent 1 should be the first Ada dimension");
      AUnit.Assertions.Assert
        (Image.Extent (2) = 3, "Extent 2 should be the second Ada dimension");
      AUnit.Assertions.Assert
        (Image.Extent (3) = 4, "Extent 3 should be the third Ada dimension");
      AUnit.Assertions.Assert
        (Image.Total = 24, "A 2 x 3 x 4 Mat should contain 24 elements");
      AUnit.Assertions.Assert
        (Image.Depth = OpenCV.Core.Float32, "Depth should remain Float32");
      AUnit.Assertions.Assert
        (Image.Channels = 1, "A C1 3-D Mat should report one channel");
      AUnit.Assertions.Assert
        (Image.Element_Size = 4, "Float32 C1 elements should be 4 bytes");
      AUnit.Assertions.Assert
        (Image.Channel_Size = 4, "Float32 channels should be 4 bytes");
      AUnit.Assertions.Assert
        (Image.Is_Continuous, "A newly created 3-D Mat should be continuous");
   end Three_Dimensional_Float32_Mat_Has_Requested_Shape;

   procedure Four_Dimensional_UInt8_Mat_Has_Requested_Shape
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4, 5),
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
   begin
      AUnit.Assertions.Assert
        (Image.Dimension_Count = 4, "A 4-D Mat should report 4 dimensions");
      AUnit.Assertions.Assert (Image.Extent (1) = 2, "Extent 1 should be 2");
      AUnit.Assertions.Assert (Image.Extent (2) = 3, "Extent 2 should be 3");
      AUnit.Assertions.Assert (Image.Extent (3) = 4, "Extent 3 should be 4");
      AUnit.Assertions.Assert (Image.Extent (4) = 5, "Extent 4 should be 5");
      AUnit.Assertions.Assert
        (Image.Total = 120, "A 2 x 3 x 4 x 5 Mat should contain 120 elements");
      AUnit.Assertions.Assert
        (Image.Channels = 3, "A C3 4-D Mat should report three channels");
      AUnit.Assertions.Assert
        (Image.Element_Size = 3, "UInt8 C3 elements should be 3 bytes");
      AUnit.Assertions.Assert
        (Image.Channel_Size = 1, "UInt8 channels should be 1 byte");
   end Four_Dimensional_UInt8_Mat_Has_Requested_Shape;

   procedure Dimension_Array_Uses_Iteration_Order_Not_Index_Origin
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Shape : constant OpenCV.Core.Dimension_Array (3 .. 5) := (2, 3, 4);
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape, (Depth => OpenCV.Core.UInt8, Channels => 1));
   begin
      AUnit.Assertions.Assert
        (Image.Dimension_Count = 3,
         "A non-1 lower bound must not change dimension count");
      AUnit.Assertions.Assert
        (Image.Extent (1) = 2,
         "The first iterated extent must become OpenCV dimension 0");
      AUnit.Assertions.Assert
        (Image.Extent (2) = 3,
         "The second iterated extent must become OpenCV dimension 1");
      AUnit.Assertions.Assert
        (Image.Extent (3) = 4,
         "The third iterated extent must become OpenCV dimension 2");
   end Dimension_Array_Uses_Iteration_Order_Not_Index_Origin;

   procedure Two_Dimensional_Create_Reports_Matching_Extents
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 7,
           Columns      => 11,
           Element_Type => (Depth => OpenCV.Core.Int16, Channels => 2));
   begin
      AUnit.Assertions.Assert
        (Image.Dimension_Count = 2, "A 2-D Create result should have 2 dims");
      AUnit.Assertions.Assert
        (Image.Extent (1) = OpenCV.Core.Size_Coordinate (Image.Rows),
         "Extent 1 must match Rows for a 2-D Mat");
      AUnit.Assertions.Assert
        (Image.Extent (2) = OpenCV.Core.Size_Coordinate (Image.Columns),
         "Extent 2 must match Columns for a 2-D Mat");
   end Two_Dimensional_Create_Reports_Matching_Extents;

   procedure Extent_Rejects_Axis_Past_Dimension_Count
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4),
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));

      procedure Query_Past_Last is
         Unused : OpenCV.Core.Size_Coordinate;
      begin
         Unused := Image.Extent (4);
      end Query_Past_Last;
   begin
      Assert_Raises_OpenCV_Error
        (Query_Past_Last'Access,
         "Extent must raise OpenCV_Error for an axis past Dimension_Count");
   end Extent_Rejects_Axis_Past_Dimension_Count;

   procedure Clone_Preserves_N_Dimensional_Shape_And_Independent_Storage
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4),
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Copy   : OpenCV.Core.Mat;
      Total  : OpenCV.Core.Scalar;
   begin
      Source.Set_To (OpenCV.Core.Make_Scalar (2.0));
      Copy := Source.Clone;

      AUnit.Assertions.Assert
        (Copy.Dimension_Count = Source.Dimension_Count,
         "A clone should preserve dimension count");
      AUnit.Assertions.Assert
        (Copy.Extent (1) = Source.Extent (1)
         and then Copy.Extent (2) = Source.Extent (2)
         and then Copy.Extent (3) = Source.Extent (3),
         "A clone should preserve N-D extents");
      AUnit.Assertions.Assert
        (Copy.Total = Source.Total
         and then Copy.Depth = Source.Depth
         and then Copy.Channels = Source.Channels
         and then Copy.Element_Size = Source.Element_Size,
         "A clone should preserve N-D metadata");

      Total := Copy.Sum;
      AUnit.Assertions.Assert
        (Total.Component_0 = 48.0, "The clone should copy the source values");

      Source.Set_To (OpenCV.Core.Make_Scalar (5.0));
      Total := Copy.Sum;
      AUnit.Assertions.Assert
        (Total.Component_0 = 48.0,
         "A clone should own independent OpenCV storage");
   end Clone_Preserves_N_Dimensional_Shape_And_Independent_Storage;

   procedure Default_Empty_Mat_Has_Zero_Dimension_Count
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Empty : OpenCV.Core.Mat;
      Typed_Empty   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.UInt8, 1));

      procedure Query_Default_Extent is
         Unused : OpenCV.Core.Size_Coordinate;
      begin
         Unused := Default_Empty.Extent (1);
      end Query_Default_Extent;
   begin
      AUnit.Assertions.Assert
        (Default_Empty.Is_Empty and then Default_Empty.Dimension_Count = 0,
         "A genuine default Mat must keep OpenCV's dims == 0 empty header");
      AUnit.Assertions.Assert
        (Typed_Empty.Is_Empty and then Typed_Empty.Dimension_Count = 2,
         "A typed 0x0 Mat must remain a 2-D empty Mat");
      AUnit.Assertions.Assert
        (Typed_Empty.Extent (1) = 0 and then Typed_Empty.Extent (2) = 0,
         "A typed 0x0 Mat should report zero row and column extents");
      Assert_Raises_OpenCV_Error
        (Query_Default_Extent'Access,
         "Extent on a default empty Mat must raise OpenCV_Error");
   end Default_Empty_Mat_Has_Zero_Dimension_Count;

   procedure N_Dimensional_Create_Rejects_Unsafe_Shapes
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);

      procedure Create_One_Dimension is
         Unused : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Shape        => (1 => 4),
              Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      begin
         null;
      end Create_One_Dimension;

      procedure Create_Zero_Extent is
         Unused : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Shape        => (2, 0, 4),
              Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      begin
         null;
      end Create_Zero_Extent;

      procedure Create_Too_Many_Dimensions is
         Shape  : constant OpenCV.Core.Dimension_Array (1 .. 33) :=
           (others => 1);
         Unused : OpenCV.Core.Mat;
      begin
         Unused :=
           OpenCV.Core.Create
             (Shape, (Depth => OpenCV.Core.UInt8, Channels => 1));
      end Create_Too_Many_Dimensions;
   begin
      Assert_Raises_OpenCV_Error
        (Create_One_Dimension'Access,
         "N-D Create must reject a 1-D shape that OpenCV would promote");
      Assert_Raises_OpenCV_Error
        (Create_Zero_Extent'Access, "N-D Create must reject a zero extent");
      Assert_Raises_OpenCV_Error
        (Create_Too_Many_Dimensions'Access,
         "N-D Create must reject more than 32 dimensions");
   end N_Dimensional_Create_Rejects_Unsafe_Shapes;

   procedure Rows_And_Columns_Reject_N_Dimensional_Mats
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4),
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));

      procedure Query_Rows is
         Unused : Natural;
      begin
         Unused := Image.Rows;
      end Query_Rows;

      procedure Query_Columns is
         Unused : Natural;
      begin
         Unused := Image.Columns;
      end Query_Columns;
   begin
      Assert_Raises_OpenCV_Error
        (Query_Rows'Access,
         "Rows must raise OpenCV_Error for an N-D Mat instead of converting"
         & " OpenCV's -1 sentinel");
      Assert_Raises_OpenCV_Error
        (Query_Columns'Access,
         "Columns must raise OpenCV_Error for an N-D Mat instead of converting"
         & " OpenCV's -1 sentinel");
   end Rows_And_Columns_Reject_N_Dimensional_Mats;

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      Typed_Empty_Sizes : constant Caller.Test_Method :=
        Default_And_Typed_Empty_Mats_Report_Distinct_Element_Sizes'Access;

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
      Result.Add_Test
        (Caller.Create
           ("Default and typed empty Mats report distinct element sizes",
            Typed_Empty_Sizes));
      Result.Add_Test
        (Caller.Create
           ("3-D Float32 Mat has requested shape",
            Three_Dimensional_Float32_Mat_Has_Requested_Shape'Access));
      Result.Add_Test
        (Caller.Create
           ("4-D UInt8 Mat has requested shape",
            Four_Dimensional_UInt8_Mat_Has_Requested_Shape'Access));
      Result.Add_Test
        (Caller.Create
           ("Dimension_Array uses iteration order not index origin",
            Dimension_Array_Uses_Iteration_Order_Not_Index_Origin'Access));
      Result.Add_Test
        (Caller.Create
           ("2-D Create reports matching extents",
            Two_Dimensional_Create_Reports_Matching_Extents'Access));
      Result.Add_Test
        (Caller.Create
           ("Extent rejects axis past Dimension_Count",
            Extent_Rejects_Axis_Past_Dimension_Count'Access));
      Result.Add_Test
        (Caller.Create
           ("Clone preserves N-D shape and independent storage",
            Clone_Preserves_N_Dimensional_Shape_And_Independent_Storage'
              Access));
      Result.Add_Test
        (Caller.Create
           ("Default empty Mat has zero dimension count",
            Default_Empty_Mat_Has_Zero_Dimension_Count'Access));
      Result.Add_Test
        (Caller.Create
           ("N-D Create rejects unsafe shapes",
            N_Dimensional_Create_Rejects_Unsafe_Shapes'Access));
      Result.Add_Test
        (Caller.Create
           ("Rows and Columns reject N-D Mats",
            Rows_And_Columns_Reject_N_Dimensional_Mats'Access));

      return Result'Access;
   end Suite;

end Mat_Basic_Tests;
