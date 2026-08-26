with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;
with Mat_Test_Support;
with OpenCV.Core.Float32_Vec3;
with OpenCV.Core.Float32_Vec3_Access;

package body Mat_View_Tests is

   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_8;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Mat_Size;
   use type OpenCV.Core.Point_Coordinate;
   use type OpenCV.Core.UInt8_Vec3.Vector;

   use Mat_Test_Support;
   use type OpenCV.Core.Size_Coordinate;

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
      Source.Set_To (OpenCV.Core.Make_Scalar (0.0));
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

   procedure Diagonal_View_Maps_Offsets_And_Shares_Data
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.UInt8, 1));
      Main   : OpenCV.Core.Mat;
      Above  : OpenCV.Core.Mat;
      Below  : OpenCV.Core.Mat;
   begin
      for Row in 0 .. 2 loop
         for Column in 0 .. 3 loop
            OpenCV.Core.UInt8_Access.Set
              (Source,
               Row,
               Column,
               Interfaces.Unsigned_8 (Row * 4 + Column + 1));
         end loop;
      end loop;

      Main := Source.Diagonal_View;
      Above := Source.Diagonal_View (1);
      Below := Source.Diagonal_View (-1);

      AUnit.Assertions.Assert
        (Main.Rows = 3
         and then Main.Columns = 1
         and then OpenCV.Core.UInt8_Access.Get (Main, 0, 0) = 1
         and then OpenCV.Core.UInt8_Access.Get (Main, 1, 0) = 6
         and then OpenCV.Core.UInt8_Access.Get (Main, 2, 0) = 11
         and then Above.Rows = 3
         and then Above.Columns = 1
         and then OpenCV.Core.UInt8_Access.Get (Above, 0, 0) = 2
         and then OpenCV.Core.UInt8_Access.Get (Above, 1, 0) = 7
         and then OpenCV.Core.UInt8_Access.Get (Above, 2, 0) = 12
         and then Below.Rows = 2
         and then Below.Columns = 1
         and then OpenCV.Core.UInt8_Access.Get (Below, 0, 0) = 5
         and then OpenCV.Core.UInt8_Access.Get (Below, 1, 0) = 10,
         "Diagonal_View must map zero, positive, and negative offsets"
         & " exactly");
      AUnit.Assertions.Assert
        (Main.Depth = OpenCV.Core.UInt8
         and then Main.Channels = 1
         and then Main.Is_Submatrix
         and then not Main.Is_Continuous,
         "A multi-element diagonal must preserve type and report view layout");

      OpenCV.Core.UInt8_Access.Set (Main, 1, 0, 88);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Source, 1, 1) = 88
         and then OpenCV.Core.UInt8_Access.Get (Source, 1, 2) = 7,
         "A diagonal write must update only its corresponding source element");
      OpenCV.Core.UInt8_Access.Set (Source, 2, 2, 99);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Main, 2, 0) = 99,
         "A diagonal view must observe source writes");
   end Diagonal_View_Maps_Offsets_And_Shares_Data;

   procedure Diagonal_View_Supports_Rectangles_Types_And_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Wide   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.UInt8, 1));
      Tall   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
      Vec    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 3));
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 5, (OpenCV.Core.UInt8, 1));
      Region : constant OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      View   : OpenCV.Core.Mat;
   begin
      for Row in 0 .. 1 loop
         for Column in 0 .. 3 loop
            OpenCV.Core.UInt8_Access.Set
              (Wide,
               Row,
               Column,
               Interfaces.Unsigned_8 (Row * 4 + Column + 1));
         end loop;
      end loop;
      View := Wide.Diagonal_View (2);
      AUnit.Assertions.Assert
        (View.Rows = 2
         and then View.Columns = 1
         and then OpenCV.Core.UInt8_Access.Get (View, 0, 0) = 3
         and then OpenCV.Core.UInt8_Access.Get (View, 1, 0) = 8,
         "A wider Mat diagonal must have the authoritative rectangular"
         & " length");

      OpenCV.Core.Float32_Access.Set (Tall, 2, 0, 3.5);
      OpenCV.Core.Float32_Access.Set (Tall, 3, 1, 4.5);
      View := Tall.Diagonal_View (-2);
      AUnit.Assertions.Assert
        (View.Rows = 2
         and then View.Depth = OpenCV.Core.Float32
         and then OpenCV.Core.Float32_Access.Get (View, 1, 0) = 4.5,
         "A taller Float32 Mat diagonal must preserve type and values");

      OpenCV.Core.UInt8_Vec3_Access.Set (Vec, 0, 1, (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vec, 1, 1, (4, 5, 6));
      View := Vec.Diagonal_View (1);
      AUnit.Assertions.Assert
        (View.Channels = 3
         and then OpenCV.Core.UInt8_Vec3_Access.Get (View, 0, 0) = (1, 2, 3),
         "A Vec3 diagonal must preserve complete channel tuples");

      for Row in 0 .. 3 loop
         for Column in 0 .. 4 loop
            OpenCV.Core.UInt8_Access.Set
              (Parent, Row, Column, Interfaces.Unsigned_8 (Row * 10 + Column));
         end loop;
      end loop;
      View := Region.Diagonal_View;
      OpenCV.Core.UInt8_Access.Set (View, 1, 0, 77);
      AUnit.Assertions.Assert
        (not Region.Is_Continuous
         and then OpenCV.Core.UInt8_Access.Get (View, 0, 0) = 11
         and then OpenCV.Core.UInt8_Access.Get (Parent, 2, 2) = 77
         and then OpenCV.Core.UInt8_Access.Get (Parent, 2, 3) = 23,
         "A diagonal of a non-continuous Region must map relative storage");
   end Diagonal_View_Supports_Rectangles_Types_And_Regions;

   procedure Diagonal_View_Validates_Offsets_And_Survives_Source
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Empty         : OpenCV.Core.Mat;
      Retained_View : OpenCV.Core.Mat;

      procedure Positive_After_Last is
         Ignored : constant OpenCV.Core.Mat := Source.Diagonal_View (3);
      begin
         pragma Unreferenced (Ignored);
      end Positive_After_Last;

      procedure Negative_After_Last is
         Ignored : constant OpenCV.Core.Mat := Source.Diagonal_View (-2);
      begin
         pragma Unreferenced (Ignored);
      end Negative_After_Last;

      procedure Empty_Diagonal is
         Ignored : constant OpenCV.Core.Mat := Empty.Diagonal_View;
      begin
         pragma Unreferenced (Ignored);
      end Empty_Diagonal;
   begin
      AUnit.Assertions.Assert
        (Source.Diagonal_View (2).Rows = 1
         and then Source.Diagonal_View (-1).Rows = 1,
         "Offsets selecting the final upper and lower diagonals must be"
         & " valid");
      Assert_Raises_OpenCV_Error
        (Positive_After_Last'Access,
         "A positive offset past the final diagonal must raise OpenCV_Error");
      Assert_Raises_OpenCV_Error
        (Negative_After_Last'Access,
         "A negative offset past the final diagonal must raise OpenCV_Error");
      Assert_Raises_OpenCV_Error
        (Empty_Diagonal'Access,
         "An empty Mat diagonal must raise OpenCV_Error");

      declare
         Short_Lived_Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      begin
         OpenCV.Core.UInt8_Access.Set (Short_Lived_Source, 1, 1, 42);
         Retained_View := Short_Lived_Source.Diagonal_View;
      end;
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Retained_View, 1, 0) = 42,
         "A diagonal view must remain valid after its source header"
         & " finalizes");
   end Diagonal_View_Validates_Offsets_And_Survives_Source;

   procedure Diagonal_Matrix_Creates_Independent_Matrices
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Column : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.UInt8, 1));
      Row    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.UInt8, 1));
      Vector : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 3));
      Matrix : OpenCV.Core.Mat;
   begin
      for Index in 0 .. 3 loop
         OpenCV.Core.UInt8_Access.Set
           (Column, Index, 0, Interfaces.Unsigned_8 (Index + 1));
      end loop;
      Matrix := OpenCV.Core.Diagonal_Matrix (Column);
      AUnit.Assertions.Assert
        (Matrix.Rows = 4
         and then Matrix.Columns = 4
         and then Matrix.Depth = OpenCV.Core.UInt8
         and then Matrix.Channels = 1
         and then Matrix.Is_Continuous
         and then not Matrix.Is_Submatrix
         and then OpenCV.Core.UInt8_Access.Get (Matrix, 0, 0) = 1
         and then OpenCV.Core.UInt8_Access.Get (Matrix, 1, 1) = 2
         and then OpenCV.Core.UInt8_Access.Get (Matrix, 2, 2) = 3
         and then OpenCV.Core.UInt8_Access.Get (Matrix, 3, 3) = 4
         and then OpenCV.Core.UInt8_Access.Get (Matrix, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Matrix, 2, 1) = 0,
         "A UInt8 column vector must create the expected zero-filled diagonal"
         & " matrix");
      OpenCV.Core.UInt8_Access.Set (Column, 1, 0, 88);
      OpenCV.Core.UInt8_Access.Set (Matrix, 2, 2, 77);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Matrix, 1, 1) = 2
         and then OpenCV.Core.UInt8_Access.Get (Column, 2, 0) = 3,
         "A diagonal matrix and its source must have independent storage");

      OpenCV.Core.Float32_Access.Set (Row, 0, 0, 1.5);
      OpenCV.Core.Float32_Access.Set (Row, 0, 1, -2.5);
      Matrix := OpenCV.Core.Diagonal_Matrix (Row);
      AUnit.Assertions.Assert
        (Matrix.Rows = 2
         and then Matrix.Columns = 2
         and then Matrix.Depth = OpenCV.Core.Float32
         and then Matrix.Channels = 1
         and then OpenCV.Core.Float32_Access.Get (Matrix, 0, 0) = 1.5
         and then OpenCV.Core.Float32_Access.Get (Matrix, 1, 1) = -2.5
         and then OpenCV.Core.Float32_Access.Get (Matrix, 1, 0) = 0.0,
         "A Float32 row vector must preserve its type and values");

      for Index in 0 .. 3 loop
         OpenCV.Core.UInt8_Access.Set
           (Parent, Index, 1, Interfaces.Unsigned_8 (Index + 1));
      end loop;
      Matrix := OpenCV.Core.Diagonal_Matrix (Parent.Column_View (1));
      AUnit.Assertions.Assert
        (not Parent.Column_View (1).Is_Continuous
         and then OpenCV.Core.UInt8_Access.Get (Matrix, 3, 3) = 4,
         "A non-continuous vector view must be accepted");

      OpenCV.Core.UInt8_Vec3_Access.Set (Vector, 0, 0, (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vector, 1, 0, (4, 5, 6));
      Matrix := OpenCV.Core.Diagonal_Matrix (Vector);
      AUnit.Assertions.Assert
        (Matrix.Channels = 3
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Matrix, 0, 0) = (1, 2, 3)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Matrix, 1, 1) = (4, 5, 6)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Matrix, 0, 1) = (0, 0, 0),
         "A multi-channel vector must preserve complete diagonal elements");
   end Diagonal_Matrix_Creates_Independent_Matrices;

   procedure Diagonal_Matrix_Handles_Boundaries_And_Lifetime
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      One_Element  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Empty_Vector : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 1, (OpenCV.Core.UInt8, 1));
      Not_A_Vector : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Empty_Matrix : OpenCV.Core.Mat;
      Retained     : OpenCV.Core.Mat;

      procedure Non_Vector_Diagonal is
         Ignored : constant OpenCV.Core.Mat :=
           OpenCV.Core.Diagonal_Matrix (Not_A_Vector);
      begin
         pragma Unreferenced (Ignored);
      end Non_Vector_Diagonal;
   begin
      OpenCV.Core.UInt8_Access.Set (One_Element, 0, 0, 42);
      AUnit.Assertions.Assert
        (OpenCV.Core.Diagonal_Matrix (One_Element).Rows = 1
         and then OpenCV.Core.Diagonal_Matrix (One_Element).Columns = 1
         and then OpenCV.Core.UInt8_Access.Get
                    (OpenCV.Core.Diagonal_Matrix (One_Element), 0, 0)
                  = 42,
         "A one-element vector must produce a one-by-one matrix");

      Empty_Matrix := OpenCV.Core.Diagonal_Matrix (Empty_Vector);
      AUnit.Assertions.Assert
        (Empty_Matrix.Is_Empty
         and then Empty_Matrix.Rows = 0
         and then Empty_Matrix.Columns = 0
         and then Empty_Matrix.Depth = OpenCV.Core.UInt8
         and then Empty_Matrix.Channels = 1,
         "An empty vector must produce an empty matrix with its element type");
      Assert_Raises_OpenCV_Error
        (Non_Vector_Diagonal'Access,
         "A non-vector diagonal input must raise OpenCV_Error");

      declare
         Short_Lived : OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 1));
      begin
         OpenCV.Core.UInt8_Access.Set (Short_Lived, 0, 0, 9);
         OpenCV.Core.UInt8_Access.Set (Short_Lived, 1, 0, 10);
         Retained := OpenCV.Core.Diagonal_Matrix (Short_Lived);
      end;
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Retained, 0, 0) = 9
         and then OpenCV.Core.UInt8_Access.Get (Retained, 1, 1) = 10,
         "A diagonal matrix must remain valid after source finalization");
   end Diagonal_Matrix_Handles_Boundaries_And_Lifetime;

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
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
           ("Region reports authoritative storage layout",
            Region_Reports_Authoritative_Storage_Layout'Access));
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
           ("Diagonal view maps offsets and shares data",
            Diagonal_View_Maps_Offsets_And_Shares_Data'Access));
      Result.Add_Test
        (Caller.Create
           ("Diagonal view supports rectangles types and Regions",
            Diagonal_View_Supports_Rectangles_Types_And_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("Diagonal view validates offsets and survives source",
            Diagonal_View_Validates_Offsets_And_Survives_Source'Access));
      Result.Add_Test
        (Caller.Create
           ("Diagonal matrix creates independent matrices",
            Diagonal_Matrix_Creates_Independent_Matrices'Access));
      Result.Add_Test
        (Caller.Create
           ("Diagonal matrix handles boundaries and lifetime",
            Diagonal_Matrix_Handles_Boundaries_And_Lifetime'Access));
      return Result'Access;
   end Suite;

end Mat_View_Tests;
