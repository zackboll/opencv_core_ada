with AUnit.Assertions;
with AUnit.Test_Caller;
with Ada.Unchecked_Conversion;
with Interfaces;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Module_Interop;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Mat_View;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;
with OpenCV.Internal.C_API;

package body Mat_Shape_Tests is

   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_8;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Dimension_Array;
   use type OpenCV.Core.Mat_Size;
   use type OpenCV.Internal.C_API.Mat_Handle;
   use type OpenCV.Internal.C_API.Status;
   use type OpenCV.Core.UInt8_Vec3.Vector;
   use type OpenCV.Size_Coordinate;
   use type OpenCV.Core.UInt8_Mat_View.Buffer_Array;
   use type OpenCV.Internal.C_API.C_Int32;

   use Mat_Test_Support;

   subtype Fixture is Mat_Test_Fixture;

   function To_Mat_Handle is new
     Ada.Unchecked_Conversion
       (OpenCV.Core.Module_Interop.Input_Mat_Handle,
        OpenCV.Internal.C_API.Mat_Handle);

   function Raw_Handle
     (Handle : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      return OpenCV.Internal.C_API.Mat_Handle
   is (To_Mat_Handle (Handle));

   function Diagnostic return String
   is (OpenCV.Internal.C_API.Last_Error_Message);

   function Contains (Source, Fragment : String) return Boolean
   is (Source'Length >= Fragment'Length
       and then (for some Offset in 0 .. Source'Length - Fragment'Length =>
                   Source
                     (Source'First
                      + Offset
                      .. Source'First + Offset + Fragment'Length - 1)
                   = Fragment));

   procedure Assert_ABI_Rejected
     (Status : OpenCV.Internal.C_API.Status;
      Handle : OpenCV.Internal.C_API.Mat_Handle;
      Reason : String);

   External_Sizes : aliased constant OpenCV.Internal.C_API.C_Int32_Array :=
     (2, 3, 4);

   procedure Probe_Temporary_External (Image : in out OpenCV.Core.Mat) is
      Source_Handle : OpenCV.Internal.C_API.Mat_Handle;
      Handle        : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status        : OpenCV.Internal.C_API.Status;

      procedure Capture (Raw : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
      begin
         Source_Handle := Raw_Handle (Raw);
      end Capture;
   begin
      OpenCV.Core.Module_Interop.With_Input_Handle (Image, Capture'Access);
      Handle := Source_Handle;
      Status :=
        OpenCV.Internal.C_API.Mat_Reshape_ND
          (Source_Handle, 1, 3, External_Sizes (0)'Access, Handle'Access);
      Assert_ABI_Rejected (Status, Handle, "temporary external");
   end Probe_Temporary_External;

   function ND (First, Second, Third : Integer) return OpenCV.Core.Index_Array
   is (OpenCV.Core.Index_Array'
         (OpenCV.Size_Coordinate (First),
          OpenCV.Size_Coordinate (Second),
          OpenCV.Size_Coordinate (Third)));

   procedure Assert_Shape
     (Image : OpenCV.Core.Mat; Expected : OpenCV.Core.Dimension_Array)
   is
      Actual : constant OpenCV.Core.Dimension_Array := Image.Shape;
   begin
      AUnit.Assertions.Assert
        (Actual'First = 1 and then Actual'Last = Expected'Length,
         "Shape must use bounds 1 .. Dimension_Count");
      AUnit.Assertions.Assert
        (Actual = Expected, "Shape must report the requested extents");
      for Axis in Actual'Range loop
         AUnit.Assertions.Assert
           (Actual (Axis) = Image.Extent (Axis),
            "Each Shape entry must agree with Extent");
      end loop;
   end Assert_Shape;

   procedure Shape_Of_Default_Mat_Is_Null (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat;
      Actual : constant OpenCV.Core.Dimension_Array := Image.Shape;
   begin
      AUnit.Assertions.Assert
        (Image.Dimension_Count = 0 and then Actual'Length = 0,
         "A default Mat must report zero dimensions and a null Shape");
   end Shape_Of_Default_Mat_Is_Null;

   procedure Shape_Of_Two_Dimensional_Mat_Matches_Rows_And_Columns
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (7, 11, (OpenCV.Core.Int16, 2));
   begin
      Assert_Shape (Image, (7, 11));
      AUnit.Assertions.Assert
        (Image.Shape (1) = OpenCV.Size_Coordinate (Image.Rows)
         and then Image.Shape (2) = OpenCV.Size_Coordinate (Image.Columns),
         "A 2-D Shape must be Rows followed by Columns");
   end Shape_Of_Two_Dimensional_Mat_Matches_Rows_And_Columns;

   procedure Shape_Of_Typed_Empty_Mat_Has_Two_Zero_Extents
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.UInt8, 1));
   begin
      AUnit.Assertions.Assert
        (Image.Dimension_Count = 2 and then Image.Is_Empty,
         "The typed empty fixture must be a 0 x 0 2-D Mat");
      Assert_Shape (Image, (0, 0));
   end Shape_Of_Typed_Empty_Mat_Has_Two_Zero_Extents;

   procedure Shape_Of_Three_Dimensional_Mat_Reports_Every_Extent
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.UInt8, 1));
   begin
      Assert_Shape (Image, (2, 3, 4));
   end Shape_Of_Three_Dimensional_Mat_Reports_Every_Extent;

   procedure Shape_Of_Four_Dimensional_Mat_Reports_Every_Extent
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4, 5), Element_Type => (OpenCV.Core.UInt8, 3));
   begin
      Assert_Shape (Image, (2, 3, 4, 5));
   end Shape_Of_Four_Dimensional_Mat_Reports_Every_Extent;

   procedure Shape_Uses_Documented_Bounds_For_Shifted_Input
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Requested : constant OpenCV.Core.Dimension_Array (4 .. 6) := (2, 3, 4);
      Image     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (Requested, (OpenCV.Core.UInt8, 1));
   begin
      Assert_Shape (Image, (2, 3, 4));
   end Shape_Uses_Documented_Bounds_For_Shifted_Input;

   procedure Fill_Sequential (Image : in out OpenCV.Core.Mat) is
      Value : Interfaces.Unsigned_8 := 0;
   begin
      for Plane in 0 .. Integer (Image.Extent (1)) - 1 loop
         for Row in 0 .. Integer (Image.Extent (2)) - 1 loop
            for Column in 0 .. Integer (Image.Extent (3)) - 1 loop
               OpenCV.Core.UInt8_Access.Set
                 (Image, ND (Plane, Row, Column), Value);
               Value := Value + 1;
            end loop;
         end loop;
      end loop;
   end Fill_Sequential;

   procedure Reshape_2D_To_3D_Preserves_Order (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 12, (OpenCV.Core.UInt8, 1));
      View   : OpenCV.Core.Mat;
   begin
      for Row in 0 .. 1 loop
         for Column in 0 .. 11 loop
            OpenCV.Core.UInt8_Access.Set
              (Source, Row, Column, Interfaces.Unsigned_8 (Row * 12 + Column));
         end loop;
      end loop;

      View := Source.Reshape (Shape => (2, 3, 4));
      AUnit.Assertions.Assert
        (View.Dimension_Count = 3
         and then View.Depth = OpenCV.Core.UInt8
         and then View.Channels = 1
         and then View.Total = 24,
         "2-D to 3-D reshape must preserve depth, channels, and scalar count");
      Assert_Shape (View, (2, 3, 4));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (View, ND (0, 0, 0)) = 0
         and then OpenCV.Core.UInt8_Access.Get (View, ND (0, 1, 2)) = 6
         and then OpenCV.Core.UInt8_Access.Get (View, ND (1, 2, 3)) = 23,
         "3-D reshape must preserve flattened scalar order");
      OpenCV.Core.UInt8_Access.Set (View, ND (1, 0, 1), 77);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Source, 1, 1) = 77,
         "A write through the reshaped header must update the source");
   end Reshape_2D_To_3D_Preserves_Order;

   procedure Reshape_3D_To_2D_Shares_Storage (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.UInt8, 1));
      View   : OpenCV.Core.Mat;
   begin
      Fill_Sequential (Source);
      View := Source.Reshape (Shape => (4, 6));
      AUnit.Assertions.Assert
        (View.Dimension_Count = 2
         and then View.Rows = 4
         and then View.Columns = 6
         and then View.Channels = 1,
         "N-D to 2-D reshape must report the requested 2-D shape");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (View, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (View, 1, 0) = 6
         and then OpenCV.Core.UInt8_Access.Get (View, 3, 5) = 23,
         "N-D to 2-D reshape must preserve scalar order");
      OpenCV.Core.UInt8_Access.Set (View, 2, 3, 81);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Source, ND (1, 0, 3)) = 81,
         "A 2-D reshape write must be visible through the N-D source");
      OpenCV.Core.UInt8_Access.Set (Source, ND (0, 2, 1), 82);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (View, 1, 3) = 82,
         "An N-D source write must be visible through the 2-D reshape");
   end Reshape_3D_To_2D_Shares_Storage;

   procedure Channel_Changing_Reshape_Groups_Scalars_As_Vec3
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 6), Element_Type => (OpenCV.Core.UInt8, 1));
      View   : OpenCV.Core.Mat;
      Value  : Interfaces.Unsigned_8 := 0;
   begin
      for Plane in 0 .. 1 loop
         for Row in 0 .. 2 loop
            for Column in 0 .. 5 loop
               OpenCV.Core.UInt8_Access.Set
                 (Source, ND (Plane, Row, Column), Value);
               Value := Value + 1;
            end loop;
         end loop;
      end loop;

      View := Source.Reshape (Channels => 3, Shape => (2, 2, 3));
      AUnit.Assertions.Assert
        (View.Depth = OpenCV.Core.UInt8
         and then View.Channels = 3
         and then View.Total = 12,
         "Channel-changing reshape must preserve depth and scalar count");
      Assert_Shape (View, (2, 2, 3));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (View, ND (0, 0, 0)) = (0, 1, 2)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (View, ND (1, 1, 2))
                  = (33, 34, 35),
         "Vec3 components must preserve original C1 scalar order");
      OpenCV.Core.UInt8_Vec3_Access.Set (View, ND (1, 0, 1), (90, 91, 92));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Source, ND (1, 0, 3)) = 90
         and then OpenCV.Core.UInt8_Access.Get (Source, ND (1, 0, 4)) = 91
         and then OpenCV.Core.UInt8_Access.Get (Source, ND (1, 0, 5)) = 92,
         "An N-D Vec3 write must update the original C1 source");
   end Channel_Changing_Reshape_Groups_Scalars_As_Vec3;

   procedure Channel_Changing_Reshape_Expands_Vec3_To_C1
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 2, 3), Element_Type => (OpenCV.Core.UInt8, 3));
      View   : OpenCV.Core.Mat;
      Value  : Interfaces.Unsigned_8 := 0;
   begin
      for Plane in 0 .. 1 loop
         for Row in 0 .. 1 loop
            for Column in 0 .. 2 loop
               OpenCV.Core.UInt8_Vec3_Access.Set
                 (Source,
                  ND (Plane, Row, Column),
                  (Value, Value + 1, Value + 2));
               Value := Value + 3;
            end loop;
         end loop;
      end loop;

      View := Source.Reshape (Channels => 1, Shape => (2, 3, 6));
      AUnit.Assertions.Assert
        (View.Channels = 1
         and then View.Total = 36
         and then View.Depth = OpenCV.Core.UInt8,
         "C3 to C1 reshape must preserve the scalar count and depth");
      Assert_Shape (View, (2, 3, 6));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (View, ND (0, 0, 0)) = 0
         and then OpenCV.Core.UInt8_Access.Get (View, ND (0, 0, 2)) = 2
         and then OpenCV.Core.UInt8_Access.Get (View, ND (1, 2, 5)) = 35,
         "C3 to C1 reshape must expand vectors in scalar order");
   end Channel_Changing_Reshape_Expands_Vec3_To_C1;

   procedure Float32_Reshape_Preserves_Exact_Values (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 2, 3), Element_Type => (OpenCV.Core.Float32, 1));
      View   : OpenCV.Core.Mat;
      Values : constant array (0 .. 11) of Interfaces.IEEE_Float_32 :=
        (1.0, -2.0, 3.5, 4.0, 0.0, -0.5, 8.0, 9.25, -10.0, 11.0, 12.5, -13.0);
      Index  : Natural := 0;
   begin
      for Plane in 0 .. 1 loop
         for Row in 0 .. 1 loop
            for Column in 0 .. 2 loop
               OpenCV.Core.Float32_Access.Set
                 (Source, ND (Plane, Row, Column), Values (Index));
               Index := Index + 1;
            end loop;
         end loop;
      end loop;

      View := Source.Reshape (Shape => (3, 2, 2));
      AUnit.Assertions.Assert
        (View.Depth = OpenCV.Core.Float32
         and then View.Channels = 1
         and then View.Total = 12,
         "Float32 reshape must preserve depth and scalar count");
      Assert_Shape (View, (3, 2, 2));
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (View, ND (0, 0, 0)) = 1.0
         and then OpenCV.Core.Float32_Access.Get (View, ND (1, 0, 1)) = -0.5
         and then OpenCV.Core.Float32_Access.Get (View, ND (2, 1, 1)) = -13.0,
         "Float32 reshape must preserve exact finite values and order");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Source, ND (1, 0, 2)) = -10.0,
         "Float32 reshape must preserve source storage before mutation");
      OpenCV.Core.Float32_Access.Set (View, ND (2, 0, 0), 42.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Source, ND (1, 0, 2)) = 42.0,
         "Float32 reshape must share storage");
   end Float32_Reshape_Preserves_Exact_Values;

   procedure Reshape_Shares_Storage_And_Clone_Is_Independent
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.UInt8, 1));
      View   : OpenCV.Core.Mat;
      Copy   : OpenCV.Core.Mat;
   begin
      Fill_Sequential (Source);
      View := Source.Reshape (Shape => (4, 6));
      OpenCV.Core.UInt8_Access.Set (View, 0, 1, 70);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Source, ND (0, 0, 1)) = 70,
         "A reshape write must be visible through the source");
      OpenCV.Core.UInt8_Access.Set (Source, ND (0, 0, 2), 71);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (View, 0, 2) = 71,
         "A source write must be visible through the reshape");
      Copy := View.Clone;
      OpenCV.Core.UInt8_Access.Set (Source, ND (0, 0, 0), 99);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (View, 0, 0) = 99
         and then OpenCV.Core.UInt8_Access.Get (Copy, 0, 0) = 0,
         "Clone of a reshape view must own independent storage");
   end Reshape_Shares_Storage_And_Clone_Is_Independent;

   procedure Reshape_Survives_Source_Finalization (Test : in out Fixture) is
      pragma Unreferenced (Test);
      View : OpenCV.Core.Mat;
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.UInt8, 1));
      begin
         Fill_Sequential (Source);
         View := Source.Reshape (Shape => (4, 6));
      end;
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (View, 3, 5) = 23
         and then View.Rows = 4
         and then View.Columns = 6,
         "A reshape header must remain valid after its source finalizes");
      OpenCV.Core.UInt8_Access.Set (View, 0, 0, 44);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (View, 0, 0) = 44,
         "A surviving reshape header must remain writable");
   end Reshape_Survives_Source_Finalization;

   procedure Chained_Reshape_Shares_Original_Storage (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 12, (OpenCV.Core.UInt8, 1));
      First  : OpenCV.Core.Mat;
      Second : OpenCV.Core.Mat;
   begin
      for Column in 0 .. 11 loop
         OpenCV.Core.UInt8_Access.Set
           (Source, 0, Column, Interfaces.Unsigned_8 (Column));
         OpenCV.Core.UInt8_Access.Set
           (Source, 1, Column, Interfaces.Unsigned_8 (12 + Column));
      end loop;
      First := Source.Reshape (Shape => (2, 3, 4));
      Second := First.Reshape (Shape => (3, 8));
      OpenCV.Core.UInt8_Access.Set (Second, 2, 1, 55);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Source, 1, 5) = 55
         and then OpenCV.Core.UInt8_Access.Get (First, ND (1, 1, 1)) = 55,
         "A chained reshape must keep sharing the original storage");
   end Chained_Reshape_Shares_Original_Storage;

   procedure Reshape_Rejects_Null_And_Short_Shapes (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 12, (OpenCV.Core.UInt8, 1));

      procedure Null_Shape is
         Ignored : constant OpenCV.Core.Mat :=
           Source.Reshape (Shape => (1 .. 0 => 1));
      begin
         pragma Unreferenced (Ignored);
      end Null_Shape;

      procedure One_Dimension is
         Ignored : constant OpenCV.Core.Mat :=
           Source.Reshape (Shape => (1 => 24));
      begin
         pragma Unreferenced (Ignored);
      end One_Dimension;
   begin
      AUnit.Assertions.Assert
        (Source.Is_Continuous and then not Source.Is_Empty,
         "Shape-count rejection must use a continuous nonempty source");
      Assert_Raises_OpenCV_Error
        (Null_Shape'Access, "A null Shape must be rejected");
      Assert_Raises_OpenCV_Error
        (One_Dimension'Access, "A one-dimensional Shape must be rejected");
   end Reshape_Rejects_Null_And_Short_Shapes;

   procedure Reshape_Rejects_Thirty_Three_Dimensions (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Shape  : constant OpenCV.Core.Dimension_Array (1 .. 33) :=
        (1 | 2 => 2, others => 1);

      procedure Too_Many is
         Ignored : constant OpenCV.Core.Mat := Source.Reshape (Shape);
      begin
         pragma Unreferenced (Ignored);
      end Too_Many;
   begin
      AUnit.Assertions.Assert
        (Source.Is_Continuous and then Source.Total = 4,
         "The 33-dimension fixture must be continuous with four scalars");
      Assert_Raises_OpenCV_Error
        (Too_Many'Access, "33 dimensions must be rejected");
   end Reshape_Rejects_Thirty_Three_Dimensions;

   procedure Reshape_Rejects_Zero_Extent (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 12, (OpenCV.Core.UInt8, 1));

      procedure Zero_Extent is
         Ignored : constant OpenCV.Core.Mat :=
           Source.Reshape (Shape => (2, 0, 4));
      begin
         pragma Unreferenced (Ignored);
      end Zero_Extent;
   begin
      AUnit.Assertions.Assert
        (Source.Is_Continuous,
         "Zero-extent rejection must reach shape validation");
      Assert_Raises_OpenCV_Error
        (Zero_Extent'Access, "A zero extent must be rejected");
   end Reshape_Rejects_Zero_Extent;

   procedure Reshape_Rejects_Scalar_Count_Mismatch (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 12, (OpenCV.Core.UInt8, 1));

      procedure Mismatch is
         Ignored : constant OpenCV.Core.Mat :=
           Source.Reshape (Shape => (2, 3, 5));
      begin
         pragma Unreferenced (Ignored);
      end Mismatch;
   begin
      AUnit.Assertions.Assert
        (Source.Is_Continuous and then Source.Total = 24,
         "Scalar-count rejection must use a continuous 24-scalar source");
      Assert_Raises_OpenCV_Error
        (Mismatch'Access, "A scalar-count mismatch must be rejected");
   end Reshape_Rejects_Scalar_Count_Mismatch;

   procedure Reshape_Rejects_Non_Continuous_Region (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 6, (OpenCV.Core.UInt8, 1));
      Region : constant OpenCV.Core.Mat :=
        Source.Region ((X => 1, Y => 1, Width => 4, Height => 2));

      procedure Reshape_Region is
         Ignored : constant OpenCV.Core.Mat :=
           Region.Reshape (Shape => (2, 4));
      begin
         pragma Unreferenced (Ignored);
      end Reshape_Region;
   begin
      AUnit.Assertions.Assert
        (not Region.Is_Continuous and then Region.Total = 8,
         "The Region fixture must be a non-continuous shape-compatible view");
      Assert_Raises_OpenCV_Error
        (Reshape_Region'Access,
         "A partial-width Region must be rejected by Shape reshape");
   end Reshape_Rejects_Non_Continuous_Region;

   procedure Reshape_Rejects_Non_Continuous_Slice (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (4, 4, 4), Element_Type => (OpenCV.Core.UInt8, 1));
      Slice  : constant OpenCV.Core.Mat :=
        Source.Slice
          (((Start => 0, Stop => 2),
            (Start => 0, Stop => 2),
            (Start => 0, Stop => 2)));

      procedure Reshape_Slice is
         Ignored : constant OpenCV.Core.Mat := Slice.Reshape (Shape => (2, 4));
      begin
         pragma Unreferenced (Ignored);
      end Reshape_Slice;
   begin
      AUnit.Assertions.Assert
        (not Slice.Is_Continuous and then Slice.Total = 8,
         "The Slice fixture must be a non-continuous shape-compatible view");
      Assert_Raises_OpenCV_Error
        (Reshape_Slice'Access, "A non-continuous N-D Slice must be rejected");
   end Reshape_Rejects_Non_Continuous_Slice;

   procedure Reshape_Rejects_Empty_Sources (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Default_Mat : OpenCV.Core.Mat;
      Typed_Empty : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.UInt8, 1));

      procedure Reshape_Default is
         Ignored : constant OpenCV.Core.Mat :=
           Default_Mat.Reshape (Shape => (2, 2));
      begin
         pragma Unreferenced (Ignored);
      end Reshape_Default;

      procedure Reshape_Typed is
         Ignored : constant OpenCV.Core.Mat :=
           Typed_Empty.Reshape (Shape => (2, 2));
      begin
         pragma Unreferenced (Ignored);
      end Reshape_Typed;
   begin
      AUnit.Assertions.Assert
        (Default_Mat.Dimension_Count = 0 and then Typed_Empty.Is_Empty,
         "Empty rejection must use a default Mat and a typed empty Mat");
      Assert_Raises_OpenCV_Error
        (Reshape_Default'Access, "A default Mat must be rejected");
      Assert_Raises_OpenCV_Error
        (Reshape_Typed'Access, "A typed empty Mat must be rejected");
   end Reshape_Rejects_Empty_Sources;

   procedure Rejected_Reshape_Leaves_Source_Unchanged (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 12, (OpenCV.Core.UInt8, 1));

      procedure Mismatch is
         Ignored : constant OpenCV.Core.Mat :=
           Source.Reshape (Shape => (3, 3, 3));
      begin
         pragma Unreferenced (Ignored);
      end Mismatch;
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 1, 4, 19);
      Assert_Raises_OpenCV_Error
        (Mismatch'Access, "The atomicity fixture must reject the reshape");
      AUnit.Assertions.Assert
        (Source.Rows = 2
         and then Source.Columns = 12
         and then Source.Channels = 1
         and then OpenCV.Core.UInt8_Access.Get (Source, 1, 4) = 19,
         "A rejected reshape must leave source metadata and data unchanged");
   end Rejected_Reshape_Leaves_Source_Unchanged;

   procedure External_View_Reshape_Does_Not_Escape (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Data : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (0, 1, 2, 3, 4, 5, 6, 7);

      procedure Process (Image : in out OpenCV.Core.Mat) is
         procedure Attempt is
            Ignored : constant OpenCV.Core.Mat :=
              Image.Reshape (Shape => (2, 2, 2));
         begin
            pragma Unreferenced (Ignored);
         end Attempt;
      begin
         Assert_Raises_OpenCV_Error
           (Attempt'Access,
            "Shape reshape of a temporary external Mat must raise"
            & " OpenCV_Error");
         OpenCV.Core.UInt8_Access.Set (Image, 0, 1, 9);
      end Process;
   begin
      OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View
        (Data, 2, 4, Process'Access);
      AUnit.Assertions.Assert
        (Data = (0, 9, 2, 3, 4, 5, 6, 7),
         "A rejected external reshape must leave caller storage unchanged"
         & " except deliberate writes");
   end External_View_Reshape_Does_Not_Escape;

   procedure Continuous_Full_Width_Region_Can_Reshape (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 6, (OpenCV.Core.UInt8, 1));
      Region : constant OpenCV.Core.Mat :=
        Source.Region ((X => 0, Y => 1, Width => 6, Height => 2));
      View   : OpenCV.Core.Mat;
   begin
      AUnit.Assertions.Assert
        (Region.Is_Continuous and then Region.Total = 12,
         "The full-width Region fixture must be continuous");
      View := Region.Reshape (Shape => (2, 2, 3));
      Assert_Shape (View, (2, 2, 3));
      OpenCV.Core.UInt8_Access.Set (View, ND (1, 1, 2), 63);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Source, 2, 5) = 63,
         "A continuous Region reshape must share source storage");
   end Continuous_Full_Width_Region_Can_Reshape;

   procedure Assert_ABI_Rejected
     (Status : OpenCV.Internal.C_API.Status;
      Handle : OpenCV.Internal.C_API.Mat_Handle;
      Reason : String) is
   begin
      AUnit.Assertions.Assert
        (Status = OpenCV.Internal.C_API.Error_Invalid_Argument
         and then Handle = OpenCV.Internal.C_API.Null_Mat_Handle
         and then Contains (Diagnostic, Reason),
         "C ABI reshape rejection must be invalid-argument, null the output,"
         & " and identify '"
         & Reason
         & "'; diagnostic was '"
         & Diagnostic
         & "'");
   end Assert_ABI_Rejected;

   procedure Raw_ABI_Rejects_Malformed_Reshape (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.UInt8, 1));
      Parent       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 6, (OpenCV.Core.UInt8, 1));
      Region       : constant OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 4, Height => 2));
      Good_Sizes   : aliased OpenCV.Internal.C_API.C_Int32_Array := (4, 6);
      Region_Sizes : aliased OpenCV.Internal.C_API.C_Int32_Array := (2, 2, 2);

      Bad_Sizes : aliased OpenCV.Internal.C_API.C_Int32_Array := (2, 0, 4);
      Negative  : aliased OpenCV.Internal.C_API.C_Int32_Array := (2, -1, 4);
      Mismatch  : aliased OpenCV.Internal.C_API.C_Int32_Array := (2, 3, 5);
      Volume    : aliased OpenCV.Internal.C_API.C_Int32_Array := (2, 3, 4);
      Too_Many  : aliased OpenCV.Internal.C_API.C_Int32_Array (0 .. 32) :=
        (others => 1);
      Handle    : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status    : OpenCV.Internal.C_API.Status;

      procedure Probe (Raw : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Source_Handle : constant OpenCV.Internal.C_API.Mat_Handle :=
           Raw_Handle (Raw);
      begin
         Status :=
           OpenCV.Internal.C_API.Mat_Reshape_ND
             (Source_Handle, 1, 3, Volume (0)'Access, null);
         AUnit.Assertions.Assert
           (Status = OpenCV.Internal.C_API.Error_Invalid_Argument
            and then Contains (Diagnostic, "out_mat must not be null"),
            "A null reshape output pointer must be rejected");
         Handle := Source_Handle;
         Status :=
           OpenCV.Internal.C_API.Mat_Reshape_ND
             (OpenCV.Internal.C_API.Null_Mat_Handle,
              1,
              3,
              Volume (0)'Access,
              Handle'Access);
         Assert_ABI_Rejected
           (Status, Handle, "source Mat handle must not be null");
         Handle := Source_Handle;
         Status :=
           OpenCV.Internal.C_API.Mat_Reshape_ND
             (Source_Handle, 1, 1, Volume (0)'Access, Handle'Access);
         Assert_ABI_Rejected (Status, Handle, "at least two dimensions");
         Handle := Source_Handle;
         Too_Many (0) := 24;
         Status :=
           OpenCV.Internal.C_API.Mat_Reshape_ND
             (Source_Handle, 1, 33, Too_Many (0)'Access, Handle'Access);
         Assert_ABI_Rejected (Status, Handle, "32-dimension limit");
         Handle := Source_Handle;
         Status :=
           OpenCV.Internal.C_API.Mat_Reshape_ND
             (Source_Handle, 1, 3, null, Handle'Access);
         Assert_ABI_Rejected (Status, Handle, "sizes must not be null");
         Handle := Source_Handle;
         Status :=
           OpenCV.Internal.C_API.Mat_Reshape_ND
             (Source_Handle, 1, 3, Bad_Sizes (0)'Access, Handle'Access);
         Assert_ABI_Rejected (Status, Handle, "extents must be positive");
         Handle := Source_Handle;
         Status :=
           OpenCV.Internal.C_API.Mat_Reshape_ND
             (Source_Handle, 1, 3, Negative (0)'Access, Handle'Access);
         Assert_ABI_Rejected (Status, Handle, "extents must be positive");
         Handle := Source_Handle;
         Status :=
           OpenCV.Internal.C_API.Mat_Reshape_ND
             (Source_Handle, 1, 3, Mismatch (0)'Access, Handle'Access);
         Assert_ABI_Rejected (Status, Handle, "scalar count");
         Handle := Source_Handle;
         Status :=
           OpenCV.Internal.C_API.Mat_Reshape_ND
             (Source_Handle, 1, 2, Good_Sizes (0)'Access, Handle'Access);
         AUnit.Assertions.Assert
           (Status = OpenCV.Internal.C_API.Success
            and then Handle /= OpenCV.Internal.C_API.Null_Mat_Handle,
            "A valid 3-D to 2-D reshape must return a non-null handle");
         OpenCV.Internal.C_API.Mat_Destroy (Handle);
      end Probe;

      procedure Probe_Region
        (Raw : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      is
         Source_Handle : constant OpenCV.Internal.C_API.Mat_Handle :=
           Raw_Handle (Raw);
      begin
         Handle := Source_Handle;
         Status :=
           OpenCV.Internal.C_API.Mat_Reshape_ND
             (Source_Handle, 1, 3, Region_Sizes (0)'Access, Handle'Access);
         AUnit.Assertions.Assert
           (Status = OpenCV.Internal.C_API.Error_OpenCV
            and then Handle = OpenCV.Internal.C_API.Null_Mat_Handle
            and then Diagnostic'Length > 0,
            "OpenCV must reject a non-continuous raw reshape");
      end Probe_Region;
   begin
      AUnit.Assertions.Assert
        (not Region.Is_Continuous,
         "The raw continuity fixture must be a non-continuous Region");
      OpenCV.Core.Module_Interop.With_Input_Handle (Source, Probe'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Region, Probe_Region'Access);
      AUnit.Assertions.Assert
        (Source.Dimension_Count = 3 and then Source.Total = 24,
         "Rejected raw reshape calls must leave the source unchanged");
   end Raw_ABI_Rejects_Malformed_Reshape;

   procedure Raw_ABI_Rejects_Temporary_External_View (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Storage : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (0 .. 23 => 1);
   begin
      OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View
        (Storage, 2, 12, Probe_Temporary_External'Access);
      AUnit.Assertions.Assert
        ((for all Value of Storage => Value = 1),
         "A rejected external reshape must not modify caller storage");
   end Raw_ABI_Rejects_Temporary_External_View;

   package Caller is new AUnit.Test_Caller (Fixture);

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Shape of a default Mat is null",
            Shape_Of_Default_Mat_Is_Null'Access));
      Result.Add_Test
        (Caller.Create
           ("Shape of a 2-D Mat matches rows and columns",
            Shape_Of_Two_Dimensional_Mat_Matches_Rows_And_Columns'Access));
      Result.Add_Test
        (Caller.Create
           ("Shape of a typed empty Mat has two zero extents",
            Shape_Of_Typed_Empty_Mat_Has_Two_Zero_Extents'Access));
      Result.Add_Test
        (Caller.Create
           ("Shape of a 3-D Mat reports every extent",
            Shape_Of_Three_Dimensional_Mat_Reports_Every_Extent'Access));
      Result.Add_Test
        (Caller.Create
           ("Shape of a 4-D Mat reports every extent",
            Shape_Of_Four_Dimensional_Mat_Reports_Every_Extent'Access));
      Result.Add_Test
        (Caller.Create
           ("Shape uses documented result bounds",
            Shape_Uses_Documented_Bounds_For_Shifted_Input'Access));
      Result.Add_Test
        (Caller.Create
           ("2-D reshape to 3-D preserves scalar order",
            Reshape_2D_To_3D_Preserves_Order'Access));
      Result.Add_Test
        (Caller.Create
           ("3-D reshape to 2-D shares storage",
            Reshape_3D_To_2D_Shares_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Channel-changing reshape groups scalars as Vec3",
            Channel_Changing_Reshape_Groups_Scalars_As_Vec3'Access));
      Result.Add_Test
        (Caller.Create
           ("Channel-changing reshape expands Vec3 to C1",
            Channel_Changing_Reshape_Expands_Vec3_To_C1'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 reshape preserves exact values",
            Float32_Reshape_Preserves_Exact_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Reshape shares storage and Clone is independent",
            Reshape_Shares_Storage_And_Clone_Is_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Reshape survives source finalization",
            Reshape_Survives_Source_Finalization'Access));
      Result.Add_Test
        (Caller.Create
           ("Chained reshape shares original storage",
            Chained_Reshape_Shares_Original_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Reshape rejects null and one-dimensional shapes",
            Reshape_Rejects_Null_And_Short_Shapes'Access));
      Result.Add_Test
        (Caller.Create
           ("Reshape rejects 33 dimensions",
            Reshape_Rejects_Thirty_Three_Dimensions'Access));
      Result.Add_Test
        (Caller.Create
           ("Reshape rejects a zero extent",
            Reshape_Rejects_Zero_Extent'Access));
      Result.Add_Test
        (Caller.Create
           ("Reshape rejects a scalar-count mismatch",
            Reshape_Rejects_Scalar_Count_Mismatch'Access));
      Result.Add_Test
        (Caller.Create
           ("Reshape rejects a non-continuous Region",
            Reshape_Rejects_Non_Continuous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Reshape rejects a non-continuous Slice",
            Reshape_Rejects_Non_Continuous_Slice'Access));
      Result.Add_Test
        (Caller.Create
           ("Reshape rejects empty sources",
            Reshape_Rejects_Empty_Sources'Access));
      Result.Add_Test
        (Caller.Create
           ("Rejected reshape leaves source data unchanged",
            Rejected_Reshape_Leaves_Source_Unchanged'Access));
      Result.Add_Test
        (Caller.Create
           ("External-view reshape does not escape",
            External_View_Reshape_Does_Not_Escape'Access));
      Result.Add_Test
        (Caller.Create
           ("A continuous full-width Region can reshape",
            Continuous_Full_Width_Region_Can_Reshape'Access));
      Result.Add_Test
        (Caller.Create
           ("Raw N-D reshape ABI rejects malformed calls",
            Raw_ABI_Rejects_Malformed_Reshape'Access));
      Result.Add_Test
        (Caller.Create
           ("Raw N-D reshape ABI rejects a temporary external view",
            Raw_ABI_Rejects_Temporary_External_View'Access));
      return Result'Access;
   end Suite;

end Mat_Shape_Tests;
