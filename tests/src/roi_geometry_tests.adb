with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Transfers;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Mat_View;
with ROI_Geometry_Tests.Raw_ABI;

package body ROI_Geometry_Tests is
   use OpenCV;
   use OpenCV.Core;
   use AUnit.Assertions;
   use Mat_Test_Support;
   use type UInt8_Value;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Mat_Pixel (Image : Mat; Row, Column : Natural) return UInt8_Value
   is (UInt8_Access.Get (Image, Row, Column));

   procedure Mat_Write
     (Image : in out Mat; Row, Column : Natural; Value : UInt8_Value) is
   begin
      UInt8_Access.Set (Image, Row, Column, Value);
   end Mat_Write;

   function UMat_Pixel (Image : UMat; Row, Column : Natural) return UInt8_Value
   is (UInt8_Access.Get (Transfers.To_Mat (Image), Row, Column));

   procedure UMat_Write
     (Image : in out UMat; Row, Column : Natural; Value : UInt8_Value)
   is
      Cell : UMat :=
        Image.Region
          ((Point_Coordinate (Column), Point_Coordinate (Row), 1, 1));
   begin
      Cell.Set_To (Make_Scalar (Long_Float (Value)));
   end UMat_Write;

   --  Identical public geometry/ownership contract, with test-only UMat
   --  transfers confined to UMat_Pixel above for observing stored values.
   generic
      type Image is tagged private;
      with
        function New_Image
          (Rows, Columns : Natural; Element_Type : Mat_Type) return Image;
      with
        function New_ND
          (Shape : Dimension_Array; Element_Type : Mat_Type) return Image;
      with function Region (Self : Image; Area : Rect) return Image is <>;
      with function Clone (Self : Image) return Image is <>;
      with function Locate_Region (Self : Image) return Region_Location is <>;
      with
        procedure Adjust_Region
          (Self : in out Image; Top, Bottom, Left, Right : Region_Adjustment)
        is <>;
      with procedure Set_To (Self : in out Image; Value : Scalar) is <>;
      with function Rows (Self : Image) return Natural is <>;
      with function Columns (Self : Image) return Natural is <>;
      with function Is_Continuous (Self : Image) return Boolean is <>;
      with function Is_Submatrix (Self : Image) return Boolean is <>;
      with function Is_Empty (Self : Image) return Boolean is <>;
      with function Depth (Self : Image) return Depth_Type is <>;
      with function Channels (Self : Image) return Channel_Count is <>;
      with function Element_Size (Self : Image) return Mat_Size is <>;
      with function Channel_Size (Self : Image) return Mat_Size is <>;
      with
        function Pixel
          (Self : Image; Row, Column : Natural) return UInt8_Value;
      with
        procedure Write
          (Self : in out Image; Row, Column : Natural; Value : UInt8_Value);
   package Cases is
      procedure Whole (Test : in out Fixture);
      procedure Nested (Test : in out Fixture);
      procedure Expansion (Test : in out Fixture);
      procedure Contraction (Test : in out Fixture);
      procedure Crossed (Test : in out Fixture);
      procedure Whole_Adjustment (Test : in out Fixture);
      procedure Aliases (Test : in out Fixture);
      procedure Lifetime (Test : in out Fixture);
      procedure Layouts (Test : in out Fixture);
      procedure Rejections (Test : in out Fixture);
      procedure Overflow (Test : in out Fixture);
      procedure Equal_Boundaries (Test : in out Fixture);
   end Cases;

   package body Cases is
      type Channel_Count_Array is array (Positive range <>) of Channel_Count;
      procedure Geometry
        (Self          : Image;
         X, Y          : Point_Coordinate;
         Width, Height : Natural;
         Whole_Width   : Size_Coordinate := 10;
         Whole_Height  : Size_Coordinate := 8) is
      begin
         Assert
           (Locate_Region (Self)
            = (Whole_Size => (Whole_Width, Whole_Height), Offset => (X, Y))
            and then Rows (Self) = Height
            and then Columns (Self) = Width,
            "retained whole allocation, offset and current extents");
      end Geometry;

      procedure Whole (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Parent : constant Image := New_Image (8, 10, (UInt8, 1));
      begin
         Geometry (Parent, 0, 0, 10, 8);
      end Whole;

      procedure Nested (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Parent : constant Image := New_Image (8, 10, (UInt8, 1));
         A      : constant Image := Region (Parent, (2, 1, 6, 5));
         B      : Image := Region (A, (1, 2, 3, 2));
      begin
         Assert (not Is_Continuous (B), "interior Region keeps parent step");
         Geometry (B, 3, 3, 3, 2);
         Adjust_Region (B, 1, 0, 1, 0);
         Geometry (B, 2, 2, 4, 3);
         Geometry (A, 2, 1, 6, 5);
         Geometry (Parent, 0, 0, 10, 8);
      end Nested;

      procedure Expansion (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Parent : constant Image := New_Image (8, 10, (UInt8, 1));
         View   : Image := Region (Parent, (2, 2, 4, 3));
      begin
         Adjust_Region (View, 100, 100, 100, 100);
         Geometry (View, 0, 0, 10, 8);
         Assert (Is_Continuous (View), "full width restores continuity");
         Assert (Is_Submatrix (View), "native Region submatrix flag persists");
         Geometry (Parent, 0, 0, 10, 8);
      end Expansion;

      procedure Contraction (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Parent : Image := New_Image (8, 10, (UInt8, 1));
         View   : Image := Region (Parent, (1, 1, 8, 6));
      begin
         Set_To (Parent, Make_Scalar (0.0));
         Adjust_Region (View, -1, -1, -1, -1);
         Geometry (View, 2, 2, 6, 4);
         Write (View, 0, 0, 77);
         Assert (Pixel (Parent, 2, 2) = 77, "contraction does not copy");
         Geometry (Parent, 0, 0, 10, 8);
      end Contraction;

      procedure Crossed (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Parent : constant Image := New_Image (8, 10, (UInt8, 1));
         View   : Image := Region (Parent, (2, 2, 4, 3));
      begin
         --  Clamped row endpoints 6,1 and column endpoints 7,1 swap.
         Adjust_Region (View, -4, -4, -5, -5);
         Geometry (View, 1, 1, 6, 5);
      end Crossed;

      procedure Whole_Adjustment (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Parent : Image := New_Image (8, 10, (UInt8, 1));
      begin
         Adjust_Region (Parent, 100, 100, 100, 100);
         Geometry (Parent, 0, 0, 10, 8);
         Adjust_Region (Parent, -1, -1, -1, -1);
         Geometry (Parent, 1, 1, 8, 6);
         Assert (not Is_Submatrix (Parent), "whole header flag stays false");
      end Whole_Adjustment;

      procedure Aliases (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Parent : Image := New_Image (8, 10, (UInt8, 1));
         View   : Image := Region (Parent, (2, 2, 4, 3));
         Alias  : Image;
      begin
         Alias := View;
         Set_To (Parent, Make_Scalar (0.0));
         declare
            Deep : constant Image := Clone (View);
         begin
            Adjust_Region (View, 1, 0, 1, 0);
            Geometry (View, 1, 1, 5, 4);
            Geometry (Alias, 2, 2, 4, 3);
            Geometry (Parent, 0, 0, 10, 8);
            Write (View, 1, 1, 91);
            Assert
              (Pixel (Parent, 2, 2) = 91
               and then Pixel (Alias, 0, 0) = 91
               and then Pixel (Alias, 1, 1) = 0
               and then Pixel (Deep, 0, 0) = 0,
               "shared pixel, different logical indices, deep clone");
            Write (View, 0, 0, 53);
            Assert
              (Pixel (Parent, 1, 1) = 53
               and then Pixel (Alias, 0, 0) = 91
               and then Pixel (Deep, 0, 0) = 0,
               "new margin shares parent without changing alias or clone");
         end;
      end Aliases;

      procedure Lifetime (Test : in out Fixture) is
         pragma Unreferenced (Test);
         View : Image;
      begin
         declare
            Parent : Image := New_Image (8, 10, (UInt8, 1));
         begin
            Set_To (Parent, Make_Scalar (42.0));
            View := Region (Parent, (2, 2, 4, 3));
         end;
         Geometry (View, 2, 2, 4, 3);
         Adjust_Region (View, 2, 3, 2, 4);
         Geometry (View, 0, 0, 10, 8);
         Assert
           (Pixel (View, 7, 9) = 42, "storage survives parent finalization");
         Write (View, 7, 9, 99);
         Assert (Pixel (View, 7, 9) = 99, "retained storage remains writable");
      end Lifetime;

      procedure Layouts (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D in Depth_Type loop
            --  OpenCV 5.0 reduces native CV_CN_MAX from 512 to 128.
            for C of Channel_Count_Array'(1, 3, 128) loop
               declare
                  Parent : constant Image := New_Image (8, 10, (D, C));
                  View   : Image := Region (Parent, (2, 1, 4, 3));
                  E      : constant Mat_Size := Element_Size (View);
                  S      : constant Mat_Size := Channel_Size (View);
               begin
                  Geometry (View, 2, 1, 4, 3);
                  Adjust_Region (View, 1, -1, 1, -1);
                  Geometry (View, 1, 0, 4, 3);
                  Assert
                    (Depth (View) = D
                     and then Channels (View) = C
                     and then Element_Size (View) = E
                     and then Channel_Size (View) = S,
                     "header operations preserve all element metadata");
               end;
            end loop;
         end loop;
      end Layouts;

      procedure Rejections (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Default : Image;
         Typed   : Image := New_Image (0, 0, (UInt16, 3));
         Volume  : Image := New_ND ((2, 3, 4), (UInt8, 1));
         procedure Reject (Self : in out Image) is
            procedure Locate is
               Location : constant Region_Location := Locate_Region (Self);
            begin
               Assert (Location.Offset.X < 0, "unreachable locate");
            end Locate;
            procedure Adjust is
            begin
               Adjust_Region (Self, 1, 1, 1, 1);
            end Adjust;
         begin
            Assert_Raises_OpenCV_Error (Locate'Access, "invalid locate");
            Assert_Raises_OpenCV_Error (Adjust'Access, "invalid adjust");
         end Reject;
      begin
         Reject (Default);
         Reject (Typed);
         Reject (Volume);
         Assert
           (Rows (Typed) = 0 and then Columns (Typed) = 0,
            "typed empty unchanged");
      end Rejections;

      procedure Overflow (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Parent : constant Image := New_Image (8, 10, (UInt8, 1));
         View   : Image := Region (Parent, (2, 2, 4, 3));
         procedure Adjust is
         begin
            Adjust_Region (View, Region_Adjustment'First, 0, 0, 0);
         end Adjust;
      begin
         Assert_Raises_OpenCV_Error (Adjust'Access, "native signed overflow");
         Geometry (View, 2, 2, 4, 3);
      end Overflow;

      procedure Equal_Boundaries (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Parent : constant Image := New_Image (8, 10, (UInt8, 1));
         View   : Image := Region (Parent, (2, 2, 4, 4));
         procedure Locate is
            Location : constant Region_Location := Locate_Region (View);
         begin
            Assert (Location.Offset.X < 0, "unreachable empty locate");
         end Locate;
      begin
         Adjust_Region (View, -2, -2, -2, -2);
         Assert (Is_Empty (View), "equal clipped endpoints produce empty");
         Assert_Raises_OpenCV_Error (Locate'Access, "adjusted empty rejects");
         Geometry (Parent, 0, 0, 10, 8);
      end Equal_Boundaries;
   end Cases;

   package Mat_Cases is new
     Cases (Mat, Create, Create, Pixel => Mat_Pixel, Write => Mat_Write);
   package UMat_Cases is new
     Cases
       (UMat,
        Create_UMat,
        Create_UMat,
        Pixel => UMat_Pixel,
        Write => UMat_Write);

   procedure Temporary_Rejected (Image : in out Mat) is
      Before : constant Size := Image.Dimensions;
      procedure Locate is
         Location : constant Region_Location := Image.Locate_Region;
      begin
         Assert (Location.Offset.X < 0, "unreachable temporary locate");
      end Locate;
      procedure Adjust is
      begin
         Image.Adjust_Region (100, 100, 100, 100);
      end Adjust;
   begin
      Assert (Image.Dimension_Count = 2, "temporary test is genuinely 2-D");
      Assert_Raises_OpenCV_Error (Locate'Access, "temporary parent locate");
      Assert_Raises_OpenCV_Error (Adjust'Access, "temporary parent adjust");
      Assert
        (Image.Dimensions = Before, "rejection leaves geometry unchanged");
   end Temporary_Rejected;

   procedure External (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Data   : aliased UInt8_Mat_View.Buffer_Array := (0 .. 19 => 37);
      Before : constant UInt8_Mat_View.Buffer_Array := Data;
      use type UInt8_Mat_View.Buffer_Array;
   begin
      UInt8_Mat_View.With_Writable_Strided_Mat_View
        (Data, 4, 3, 5, Temporary_Rejected'Access);
      Assert (Data = Before, "caller data and row padding untouched");
   end External;

   procedure Selected (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Volume : Mat := Create (Dimension_Array'(2, 3, 4), (UInt8, 1));
      procedure Process (View : in out Mat) is
      begin
         Temporary_Rejected (View);
         Assert
           (UInt8_Access.Get (View, 0, 0) = 29,
            "selected storage remains usable");
      end Process;
   begin
      Volume.Set_To (Make_Scalar (29.0));
      Volume.With_Selected_View
        (((Kind => Fix_Index, Index => 1),
          (Kind => Keep_Range, Bounds => (0, 3)),
          (Kind => Keep_Range, Bounds => (0, 4))),
         Process'Access);
      Assert
        (UInt8_Access.Get (Volume, Index_Array'(1, 0, 0)) = 29,
         "selected rejection leaves source data unchanged");
   end Selected;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create ("ROI Mat whole", Mat_Cases.Whole'Access));
      Result.Add_Test
        (Caller.Create ("ROI Mat nested", Mat_Cases.Nested'Access));
      Result.Add_Test
        (Caller.Create ("ROI Mat expansion", Mat_Cases.Expansion'Access));
      Result.Add_Test
        (Caller.Create ("ROI Mat contraction", Mat_Cases.Contraction'Access));
      Result.Add_Test
        (Caller.Create ("ROI Mat crossed", Mat_Cases.Crossed'Access));
      Result.Add_Test
        (Caller.Create
           ("ROI Mat whole adjustment", Mat_Cases.Whole_Adjustment'Access));
      Result.Add_Test
        (Caller.Create ("ROI Mat aliases", Mat_Cases.Aliases'Access));
      Result.Add_Test
        (Caller.Create ("ROI Mat lifetime", Mat_Cases.Lifetime'Access));
      Result.Add_Test
        (Caller.Create ("ROI Mat layouts", Mat_Cases.Layouts'Access));
      Result.Add_Test
        (Caller.Create ("ROI Mat rejections", Mat_Cases.Rejections'Access));
      Result.Add_Test
        (Caller.Create ("ROI Mat overflow", Mat_Cases.Overflow'Access));
      Result.Add_Test
        (Caller.Create
           ("ROI Mat equal boundaries", Mat_Cases.Equal_Boundaries'Access));
      Result.Add_Test
        (Caller.Create ("ROI UMat whole", UMat_Cases.Whole'Access));
      Result.Add_Test
        (Caller.Create ("ROI UMat nested", UMat_Cases.Nested'Access));
      Result.Add_Test
        (Caller.Create ("ROI UMat expansion", UMat_Cases.Expansion'Access));
      Result.Add_Test
        (Caller.Create
           ("ROI UMat contraction", UMat_Cases.Contraction'Access));
      Result.Add_Test
        (Caller.Create ("ROI UMat crossed", UMat_Cases.Crossed'Access));
      Result.Add_Test
        (Caller.Create
           ("ROI UMat whole adjustment", UMat_Cases.Whole_Adjustment'Access));
      Result.Add_Test
        (Caller.Create ("ROI UMat aliases", UMat_Cases.Aliases'Access));
      Result.Add_Test
        (Caller.Create ("ROI UMat lifetime", UMat_Cases.Lifetime'Access));
      Result.Add_Test
        (Caller.Create ("ROI UMat layouts", UMat_Cases.Layouts'Access));
      Result.Add_Test
        (Caller.Create ("ROI UMat rejections", UMat_Cases.Rejections'Access));
      Result.Add_Test
        (Caller.Create ("ROI UMat overflow", UMat_Cases.Overflow'Access));
      Result.Add_Test
        (Caller.Create
           ("ROI UMat equal boundaries", UMat_Cases.Equal_Boundaries'Access));
      Result.Add_Test
        (Caller.Create ("ROI Mat external rejection", External'Access));
      Result.Add_Test
        (Caller.Create ("ROI Mat selected rejection", Selected'Access));
      Result.Add_Test
        (Caller.Create ("ROI Mat raw ABI", Raw_ABI.Mat_Check'Access));
      Result.Add_Test
        (Caller.Create ("ROI UMat raw ABI", Raw_ABI.UMat_Check'Access));
      return Result'Access;
   end Suite;
end ROI_Geometry_Tests;
