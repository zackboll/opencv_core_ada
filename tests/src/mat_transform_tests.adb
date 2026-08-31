with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float32_Vec3;
with OpenCV.Core.Float32_Vec3_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;

package body Mat_Transform_Tests is

   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_8;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Border_Kind;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Point_Coordinate;
   use type OpenCV.Core.Size_Coordinate;
   use type OpenCV.Core.UInt8_Vec3.Vector;
   use type OpenCV.Core.Float32_Vec3.Vector;

   use Mat_Test_Support;

   function UInt8_Mats_Are_Equivalent
     (Left, Right : OpenCV.Core.Mat) return Boolean is
   begin
      if Left.Rows /= Right.Rows
        or else Left.Columns /= Right.Columns
        or else Left.Depth /= Right.Depth
        or else Left.Channels /= Right.Channels
      then
         return False;
      end if;

      if Left.Is_Empty then
         return True;
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
   end UInt8_Mats_Are_Equivalent;

   procedure Transpose_Rectangular_UInt8_Maps_All_Elements
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 2, 3);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 0, 4);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 1, 5);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 2, 6);

      declare
         Result : constant OpenCV.Core.Mat := Source.Transpose;
      begin
         AUnit.Assertions.Assert
           (Result.Rows = 3
            and then Result.Columns = 2
            and then Result.Depth = Source.Depth
            and then Result.Channels = Source.Channels
            and then OpenCV.Core.UInt8_Access.Get (Result, 0, 0) = 1
            and then OpenCV.Core.UInt8_Access.Get (Result, 0, 1) = 4
            and then OpenCV.Core.UInt8_Access.Get (Result, 1, 0) = 2
            and then OpenCV.Core.UInt8_Access.Get (Result, 1, 1) = 5
            and then OpenCV.Core.UInt8_Access.Get (Result, 2, 0) = 3
            and then OpenCV.Core.UInt8_Access.Get (Result, 2, 1) = 6,
            "Transpose must map a 2 by 3 Mat to the exact 3 by 2 arrangement");
      end;
   end Transpose_Rectangular_UInt8_Maps_All_Elements;

   procedure Transpose_Square_And_Vector_Shapes
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Square : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Row    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.UInt8, 1));
      Column : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.UInt8, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Square, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Square, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Square, 1, 0, 3);
      OpenCV.Core.UInt8_Access.Set (Square, 1, 1, 4);
      OpenCV.Core.UInt8_Access.Set (Row, 0, 0, 7);
      OpenCV.Core.UInt8_Access.Set (Row, 0, 1, 8);
      OpenCV.Core.UInt8_Access.Set (Row, 0, 2, 9);
      OpenCV.Core.UInt8_Access.Set (Column, 0, 0, 10);
      OpenCV.Core.UInt8_Access.Set (Column, 1, 0, 11);
      OpenCV.Core.UInt8_Access.Set (Column, 2, 0, 12);

      declare
         Square_Result : constant OpenCV.Core.Mat := Square.Transpose;
         Row_Result    : constant OpenCV.Core.Mat := Row.Transpose;
         Column_Result : constant OpenCV.Core.Mat := Column.Transpose;
      begin
         AUnit.Assertions.Assert
           (Square_Result.Rows = 2
            and then Square_Result.Columns = 2
            and then OpenCV.Core.UInt8_Access.Get (Square_Result, 0, 1) = 3
            and then OpenCV.Core.UInt8_Access.Get (Square_Result, 1, 0) = 2
            and then Row_Result.Rows = 3
            and then Row_Result.Columns = 1
            and then OpenCV.Core.UInt8_Access.Get (Row_Result, 2, 0) = 9
            and then Column_Result.Rows = 1
            and then Column_Result.Columns = 3
            and then OpenCV.Core.UInt8_Access.Get (Column_Result, 0, 2) = 12,
            "Transpose must preserve square shape and exchange vector axes");
      end;
   end Transpose_Square_And_Vector_Shapes;

   procedure Transpose_Float32_And_UInt8_Vec3 (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Floats  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 1));
      Vectors : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 3));
   begin
      OpenCV.Core.Float32_Access.Set (Floats, 0, 0, 1.5);
      OpenCV.Core.Float32_Access.Set (Floats, 1, 0, 2.5);
      OpenCV.Core.UInt8_Vec3_Access.Set (Vectors, 0, 0, (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vectors, 0, 1, (4, 5, 6));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vectors, 1, 0, (7, 8, 9));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vectors, 1, 1, (10, 11, 12));

      declare
         Float_Result : constant OpenCV.Core.Mat := Floats.Transpose;
         Vec_Result   : constant OpenCV.Core.Mat := Vectors.Transpose;
      begin
         AUnit.Assertions.Assert
           (Float_Result.Depth = OpenCV.Core.Float32
            and then Float_Result.Channels = 1
            and then Float_Result.Rows = 1
            and then Float_Result.Columns = 2
            and then OpenCV.Core.Float32_Access.Get (Float_Result, 0, 0) = 1.5
            and then OpenCV.Core.Float32_Access.Get (Float_Result, 0, 1) = 2.5
            and then Vec_Result.Depth = OpenCV.Core.UInt8
            and then Vec_Result.Channels = 3
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 0, 1)
                     = (7, 8, 9)
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 1, 0)
                     = (4, 5, 6),
            "Transpose must preserve Float32 and move complete Vec3 elements");
      end;
   end Transpose_Float32_And_UInt8_Vec3;

   procedure Transpose_Non_Continuous_Region (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.UInt8, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Parent, 0, 1, 1);
      OpenCV.Core.UInt8_Access.Set (Parent, 0, 2, 2);
      OpenCV.Core.UInt8_Access.Set (Parent, 1, 1, 3);
      OpenCV.Core.UInt8_Access.Set (Parent, 1, 2, 4);

      declare
         Region : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
         Result : constant OpenCV.Core.Mat := Region.Transpose;
      begin
         AUnit.Assertions.Assert
           (not Region.Is_Continuous
            and then Result.Rows = 2
            and then Result.Columns = 2
            and then OpenCV.Core.UInt8_Access.Get (Result, 0, 0) = 1
            and then OpenCV.Core.UInt8_Access.Get (Result, 0, 1) = 3
            and then OpenCV.Core.UInt8_Access.Get (Result, 1, 0) = 2
            and then OpenCV.Core.UInt8_Access.Get (Result, 1, 1) = 4,
            "Transpose must accept a non-continuous Region");
      end;
   end Transpose_Non_Continuous_Region;

   procedure Transpose_Result_Is_Independent_And_Survives_Source
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Mat;
   begin
      declare
         Source : OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      begin
         OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 20);
         OpenCV.Core.UInt8_Access.Set (Source, 1, 0, 25);
         Result := Source.Transpose;
         OpenCV.Core.UInt8_Access.Set (Result, 1, 0, 30);
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Source, 0, 1) = 20,
            "Modifying a transpose result must not modify its source");
         OpenCV.Core.UInt8_Access.Set (Source, 1, 0, 40);
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Result, 0, 1) = 25,
            "Modifying a transpose source must not modify its result");
      end;

      AUnit.Assertions.Assert
        (Result.Rows = 2
         and then Result.Columns = 2
         and then OpenCV.Core.UInt8_Access.Get (Result, 1, 0) = 30,
         "A transpose result must remain valid after source finalization");
   end Transpose_Result_Is_Independent_And_Survives_Source;

   procedure Transpose_Empty_Mat (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat;
   begin
      declare
         Result : constant OpenCV.Core.Mat := Source.Transpose;
      begin
         AUnit.Assertions.Assert
           (Result.Is_Empty, "Transpose of an empty Mat must be empty");
      end;
   end Transpose_Empty_Mat;

   procedure Flip_Rectangular_UInt8_Maps_All_Elements
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 2, 3);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 0, 4);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 1, 5);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 2, 6);

      declare
         Vertical   : constant OpenCV.Core.Mat :=
           Source.Flip (OpenCV.Core.Vertical);
         Horizontal : constant OpenCV.Core.Mat :=
           Source.Flip (OpenCV.Core.Horizontal);
         Both       : constant OpenCV.Core.Mat :=
           Source.Flip (OpenCV.Core.Both_Axes);
      begin
         AUnit.Assertions.Assert
           (Vertical.Rows = Source.Rows
            and then Vertical.Columns = Source.Columns
            and then Vertical.Depth = Source.Depth
            and then Vertical.Channels = Source.Channels
            and then OpenCV.Core.UInt8_Access.Get (Vertical, 0, 0) = 4
            and then OpenCV.Core.UInt8_Access.Get (Vertical, 0, 1) = 5
            and then OpenCV.Core.UInt8_Access.Get (Vertical, 0, 2) = 6
            and then OpenCV.Core.UInt8_Access.Get (Vertical, 1, 0) = 1
            and then OpenCV.Core.UInt8_Access.Get (Vertical, 1, 1) = 2
            and then OpenCV.Core.UInt8_Access.Get (Vertical, 1, 2) = 3
            and then OpenCV.Core.UInt8_Access.Get (Horizontal, 0, 0) = 3
            and then OpenCV.Core.UInt8_Access.Get (Horizontal, 0, 1) = 2
            and then OpenCV.Core.UInt8_Access.Get (Horizontal, 0, 2) = 1
            and then OpenCV.Core.UInt8_Access.Get (Horizontal, 1, 0) = 6
            and then OpenCV.Core.UInt8_Access.Get (Horizontal, 1, 1) = 5
            and then OpenCV.Core.UInt8_Access.Get (Horizontal, 1, 2) = 4
            and then OpenCV.Core.UInt8_Access.Get (Both, 0, 0) = 6
            and then OpenCV.Core.UInt8_Access.Get (Both, 0, 1) = 5
            and then OpenCV.Core.UInt8_Access.Get (Both, 0, 2) = 4
            and then OpenCV.Core.UInt8_Access.Get (Both, 1, 0) = 3
            and then OpenCV.Core.UInt8_Access.Get (Both, 1, 1) = 2
            and then OpenCV.Core.UInt8_Access.Get (Both, 1, 2) = 1,
            "Flip kinds must have the documented exact 2 by 3 mappings");
      end;
   end Flip_Rectangular_UInt8_Maps_All_Elements;

   procedure Flip_Shape_And_Involution (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Square : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Row    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.UInt8, 1));
      Column : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.UInt8, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Square, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Square, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Square, 1, 0, 3);
      OpenCV.Core.UInt8_Access.Set (Square, 1, 1, 4);
      OpenCV.Core.UInt8_Access.Set (Row, 0, 0, 7);
      OpenCV.Core.UInt8_Access.Set (Row, 0, 1, 8);
      OpenCV.Core.UInt8_Access.Set (Row, 0, 2, 9);
      OpenCV.Core.UInt8_Access.Set (Column, 0, 0, 10);
      OpenCV.Core.UInt8_Access.Set (Column, 1, 0, 11);
      OpenCV.Core.UInt8_Access.Set (Column, 2, 0, 12);

      declare
         Square_Result : constant OpenCV.Core.Mat :=
           Square.Flip (OpenCV.Core.Vertical);
         Row_Result    : constant OpenCV.Core.Mat :=
           Row.Flip (OpenCV.Core.Horizontal);
         Column_Result : constant OpenCV.Core.Mat :=
           Column.Flip (OpenCV.Core.Vertical);
         Vertical      : constant OpenCV.Core.Mat :=
           Square.Flip (OpenCV.Core.Vertical).Flip (OpenCV.Core.Vertical);
         Horizontal    : constant OpenCV.Core.Mat :=
           Square.Flip (OpenCV.Core.Horizontal).Flip (OpenCV.Core.Horizontal);
         Both          : constant OpenCV.Core.Mat :=
           Square.Flip (OpenCV.Core.Both_Axes).Flip (OpenCV.Core.Both_Axes);
      begin
         AUnit.Assertions.Assert
           (Square_Result.Rows = 2
            and then Square_Result.Columns = 2
            and then OpenCV.Core.UInt8_Access.Get (Square_Result, 0, 0) = 3
            and then Row_Result.Rows = 1
            and then Row_Result.Columns = 3
            and then OpenCV.Core.UInt8_Access.Get (Row_Result, 0, 0) = 9
            and then Column_Result.Rows = 3
            and then Column_Result.Columns = 1
            and then OpenCV.Core.UInt8_Access.Get (Column_Result, 0, 0) = 12
            and then OpenCV.Core.UInt8_Access.Get (Vertical, 1, 1) = 4
            and then OpenCV.Core.UInt8_Access.Get (Horizontal, 0, 1) = 2
            and then OpenCV.Core.UInt8_Access.Get (Both, 1, 0) = 3,
            "Flip must preserve shapes and each kind must be an involution");
      end;
   end Flip_Shape_And_Involution;

   procedure Flip_Float32_And_UInt8_Vec3 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Floats  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Vectors : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 3));
   begin
      OpenCV.Core.Float32_Access.Set (Floats, 0, 0, 1.5);
      OpenCV.Core.Float32_Access.Set (Floats, 1, 1, 2.5);
      OpenCV.Core.UInt8_Vec3_Access.Set (Vectors, 0, 0, (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vectors, 0, 1, (4, 5, 6));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vectors, 1, 0, (7, 8, 9));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vectors, 1, 1, (10, 11, 12));
      declare
         Float_Result : constant OpenCV.Core.Mat :=
           Floats.Flip (OpenCV.Core.Both_Axes);
         Vec_Result   : constant OpenCV.Core.Mat :=
           Vectors.Flip (OpenCV.Core.Horizontal);
      begin
         AUnit.Assertions.Assert
           (Float_Result.Depth = OpenCV.Core.Float32
            and then Float_Result.Channels = 1
            and then OpenCV.Core.Float32_Access.Get (Float_Result, 0, 0) = 2.5
            and then Vec_Result.Depth = OpenCV.Core.UInt8
            and then Vec_Result.Channels = 3
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 0, 0)
                     = (4, 5, 6)
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 1, 0)
                     = (10, 11, 12),
            "Flip must preserve Float32 and move complete UInt8 Vec3"
            & " elements");
      end;
   end Flip_Float32_And_UInt8_Vec3;

   procedure Flip_Region_Independence_And_Lifetime
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Mat;
   begin
      declare
         Parent : OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 4, (OpenCV.Core.UInt8, 1));
      begin
         OpenCV.Core.UInt8_Access.Set (Parent, 0, 1, 1);
         OpenCV.Core.UInt8_Access.Set (Parent, 0, 2, 2);
         OpenCV.Core.UInt8_Access.Set (Parent, 1, 1, 3);
         OpenCV.Core.UInt8_Access.Set (Parent, 1, 2, 4);
         declare
            Region : constant OpenCV.Core.Mat :=
              Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
         begin
            Result := Region.Flip (OpenCV.Core.Horizontal);
            OpenCV.Core.UInt8_Access.Set (Result, 0, 0, 20);
            AUnit.Assertions.Assert
              (not Region.Is_Continuous
               and then OpenCV.Core.UInt8_Access.Get (Region, 0, 1) = 2,
               "Flip must accept non-continuous Regions and use independent"
               & " storage");
         end;
      end;
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Result, 0, 0) = 20,
         "A flip result must survive source finalization");
   end Flip_Region_Independence_And_Lifetime;

   procedure Flip_Empty_Mat (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat;
   begin
      declare
         Result : constant OpenCV.Core.Mat :=
           Source.Flip (OpenCV.Core.Vertical);
      begin
         AUnit.Assertions.Assert
           (Result.Is_Empty, "Flip of an empty Mat must be empty");
      end;
   end Flip_Empty_Mat;

   procedure Rotate_Rectangular_UInt8_Maps_All_Elements
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 2, 3);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 0, 4);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 1, 5);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 2, 6);

      declare
         Clockwise        : constant OpenCV.Core.Mat :=
           Source.Rotate (OpenCV.Core.Clockwise_90);
         Half             : constant OpenCV.Core.Mat :=
           Source.Rotate (OpenCV.Core.Half_Turn);
         Counterclockwise : constant OpenCV.Core.Mat :=
           Source.Rotate (OpenCV.Core.Counterclockwise_90);
      begin
         AUnit.Assertions.Assert
           (Clockwise.Rows = 3
            and then Clockwise.Columns = 2
            and then Clockwise.Depth = OpenCV.Core.UInt8
            and then Clockwise.Channels = 1
            and then OpenCV.Core.UInt8_Access.Get (Clockwise, 0, 0) = 4
            and then OpenCV.Core.UInt8_Access.Get (Clockwise, 0, 1) = 1
            and then OpenCV.Core.UInt8_Access.Get (Clockwise, 1, 0) = 5
            and then OpenCV.Core.UInt8_Access.Get (Clockwise, 1, 1) = 2
            and then OpenCV.Core.UInt8_Access.Get (Clockwise, 2, 0) = 6
            and then OpenCV.Core.UInt8_Access.Get (Clockwise, 2, 1) = 3
            and then Half.Rows = 2
            and then Half.Columns = 3
            and then OpenCV.Core.UInt8_Access.Get (Half, 0, 0) = 6
            and then OpenCV.Core.UInt8_Access.Get (Half, 0, 1) = 5
            and then OpenCV.Core.UInt8_Access.Get (Half, 0, 2) = 4
            and then OpenCV.Core.UInt8_Access.Get (Half, 1, 0) = 3
            and then OpenCV.Core.UInt8_Access.Get (Half, 1, 1) = 2
            and then OpenCV.Core.UInt8_Access.Get (Half, 1, 2) = 1
            and then Counterclockwise.Rows = 3
            and then Counterclockwise.Columns = 2
            and then OpenCV.Core.UInt8_Access.Get (Counterclockwise, 0, 0) = 3
            and then OpenCV.Core.UInt8_Access.Get (Counterclockwise, 0, 1) = 6
            and then OpenCV.Core.UInt8_Access.Get (Counterclockwise, 1, 0) = 2
            and then OpenCV.Core.UInt8_Access.Get (Counterclockwise, 1, 1) = 5
            and then OpenCV.Core.UInt8_Access.Get (Counterclockwise, 2, 0) = 1
            and then OpenCV.Core.UInt8_Access.Get (Counterclockwise, 2, 1) = 4,
            "Rotate kinds must have the documented exact 2 by 3 mappings");
      end;
   end Rotate_Rectangular_UInt8_Maps_All_Elements;

   procedure Rotate_Shapes_And_Element_Types (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Square  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Row     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.UInt8, 1));
      Column  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.UInt8, 1));
      Floats  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Vectors : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 3));
   begin
      OpenCV.Core.UInt8_Access.Set (Square, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Square, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Square, 1, 0, 3);
      OpenCV.Core.UInt8_Access.Set (Row, 0, 0, 7);
      OpenCV.Core.UInt8_Access.Set (Row, 0, 1, 8);
      OpenCV.Core.UInt8_Access.Set (Row, 0, 2, 9);
      OpenCV.Core.UInt8_Access.Set (Column, 0, 0, 10);
      OpenCV.Core.UInt8_Access.Set (Column, 1, 0, 11);
      OpenCV.Core.UInt8_Access.Set (Column, 2, 0, 12);
      OpenCV.Core.Float32_Access.Set (Floats, 0, 0, 1.5);
      OpenCV.Core.Float32_Access.Set (Floats, 1, 1, 2.5);
      OpenCV.Core.UInt8_Vec3_Access.Set (Vectors, 0, 0, (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vectors, 0, 1, (4, 5, 6));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vectors, 1, 0, (7, 8, 9));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vectors, 1, 1, (10, 11, 12));

      declare
         Square_Result : constant OpenCV.Core.Mat :=
           Square.Rotate (OpenCV.Core.Clockwise_90);
         Row_Result    : constant OpenCV.Core.Mat :=
           Row.Rotate (OpenCV.Core.Counterclockwise_90);
         Column_Result : constant OpenCV.Core.Mat :=
           Column.Rotate (OpenCV.Core.Clockwise_90);
         Float_Result  : constant OpenCV.Core.Mat :=
           Floats.Rotate (OpenCV.Core.Half_Turn);
         Vec_Result    : constant OpenCV.Core.Mat :=
           Vectors.Rotate (OpenCV.Core.Clockwise_90);
      begin
         AUnit.Assertions.Assert
           (Square_Result.Rows = 2
            and then Square_Result.Columns = 2
            and then OpenCV.Core.UInt8_Access.Get (Square_Result, 0, 0) = 3
            and then Row_Result.Rows = 3
            and then Row_Result.Columns = 1
            and then OpenCV.Core.UInt8_Access.Get (Row_Result, 0, 0) = 9
            and then Column_Result.Rows = 1
            and then Column_Result.Columns = 3
            and then OpenCV.Core.UInt8_Access.Get (Column_Result, 0, 2) = 10
            and then Float_Result.Depth = OpenCV.Core.Float32
            and then Float_Result.Channels = 1
            and then OpenCV.Core.Float32_Access.Get (Float_Result, 1, 1) = 1.5
            and then Vec_Result.Depth = OpenCV.Core.UInt8
            and then Vec_Result.Channels = 3
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 0, 0)
                     = (7, 8, 9)
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 1, 0)
                     = (10, 11, 12)
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 0, 1)
                     = (1, 2, 3),
            "Rotate must support square and vector shapes and preserve "
            & "complete element types");
      end;
   end Rotate_Shapes_And_Element_Types;

   procedure Rotate_Region_Independence_Lifetime_And_Empty
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Mat;
      Empty  : OpenCV.Core.Mat;
   begin
      declare
         Parent : OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 4, (OpenCV.Core.UInt8, 1));
      begin
         OpenCV.Core.UInt8_Access.Set (Parent, 0, 1, 1);
         OpenCV.Core.UInt8_Access.Set (Parent, 0, 2, 2);
         OpenCV.Core.UInt8_Access.Set (Parent, 1, 1, 3);
         OpenCV.Core.UInt8_Access.Set (Parent, 1, 2, 4);
         declare
            Region : constant OpenCV.Core.Mat :=
              Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
         begin
            Result := Region.Rotate (OpenCV.Core.Clockwise_90);
            OpenCV.Core.UInt8_Access.Set (Result, 0, 0, 20);
            AUnit.Assertions.Assert
              (not Region.Is_Continuous
               and then OpenCV.Core.UInt8_Access.Get (Region, 1, 0) = 3,
               "Rotate must accept non-continuous Regions and use "
               & "independent storage");
         end;
      end;
      declare
         Empty_Result : constant OpenCV.Core.Mat :=
           Empty.Rotate (OpenCV.Core.Half_Turn);
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Result, 0, 0) = 20
            and then Empty_Result.Is_Empty,
            "A rotate result must survive source finalization and empty "
            & "rotation must be empty");
      end;
   end Rotate_Region_Independence_Lifetime_And_Empty;

   procedure Rotate_Algebraic_Cross_Checks_And_Cycles
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
   begin
      for Row in 0 .. 1 loop
         for Column in 0 .. 2 loop
            OpenCV.Core.UInt8_Access.Set
              (Source,
               Row,
               Column,
               Interfaces.Unsigned_8 (Row * 3 + Column + 1));
         end loop;
      end loop;
      declare
         Clockwise              : constant OpenCV.Core.Mat :=
           Source.Rotate (OpenCV.Core.Clockwise_90);
         Counterclockwise       : constant OpenCV.Core.Mat :=
           Source.Rotate (OpenCV.Core.Counterclockwise_90);
         Half                   : constant OpenCV.Core.Mat :=
           Source.Rotate (OpenCV.Core.Half_Turn);
         Clockwise_Check        : constant OpenCV.Core.Mat :=
           Source.Transpose.Flip (OpenCV.Core.Horizontal);
         Counterclockwise_Check : constant OpenCV.Core.Mat :=
           Source.Transpose.Flip (OpenCV.Core.Vertical);
         Half_Check             : constant OpenCV.Core.Mat :=
           Source.Flip (OpenCV.Core.Both_Axes);
         Four_Clockwise         : constant OpenCV.Core.Mat :=
           Source.Rotate (OpenCV.Core.Clockwise_90).Rotate
             (OpenCV.Core.Clockwise_90)
             .Rotate (OpenCV.Core.Clockwise_90)
             .Rotate (OpenCV.Core.Clockwise_90);
         Two_Half_Turns         : constant OpenCV.Core.Mat :=
           Source.Rotate (OpenCV.Core.Half_Turn).Rotate
             (OpenCV.Core.Half_Turn);
      begin
         AUnit.Assertions.Assert
           (UInt8_Mats_Are_Equivalent (Clockwise, Clockwise_Check)
            and then UInt8_Mats_Are_Equivalent
                       (Counterclockwise, Counterclockwise_Check)
            and then UInt8_Mats_Are_Equivalent (Half, Half_Check)
            and then UInt8_Mats_Are_Equivalent (Four_Clockwise, Source)
            and then UInt8_Mats_Are_Equivalent (Two_Half_Turns, Source),
            "Rotate must agree with Transpose/Flip identities and "
            & "rotation cycles");
      end;
   end Rotate_Algebraic_Cross_Checks_And_Cycles;

   procedure Repeat_Rectangular_UInt8_Maps_All_Elements
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 0, 3);
      OpenCV.Core.UInt8_Access.Set (Source, 1, 1, 4);

      declare
         Result : constant OpenCV.Core.Mat :=
           Source.Repeat (Row_Repetitions => 2, Column_Repetitions => 3);
      begin
         AUnit.Assertions.Assert
           (Result.Rows = 4
            and then Result.Columns = 6
            and then Result.Depth = OpenCV.Core.UInt8
            and then Result.Channels = 1
            and then OpenCV.Core.UInt8_Access.Get (Result, 0, 0) = 1
            and then OpenCV.Core.UInt8_Access.Get (Result, 0, 1) = 2
            and then OpenCV.Core.UInt8_Access.Get (Result, 0, 2) = 1
            and then OpenCV.Core.UInt8_Access.Get (Result, 0, 3) = 2
            and then OpenCV.Core.UInt8_Access.Get (Result, 0, 4) = 1
            and then OpenCV.Core.UInt8_Access.Get (Result, 0, 5) = 2
            and then OpenCV.Core.UInt8_Access.Get (Result, 1, 0) = 3
            and then OpenCV.Core.UInt8_Access.Get (Result, 1, 1) = 4
            and then OpenCV.Core.UInt8_Access.Get (Result, 1, 2) = 3
            and then OpenCV.Core.UInt8_Access.Get (Result, 1, 3) = 4
            and then OpenCV.Core.UInt8_Access.Get (Result, 1, 4) = 3
            and then OpenCV.Core.UInt8_Access.Get (Result, 1, 5) = 4
            and then OpenCV.Core.UInt8_Access.Get (Result, 2, 0) = 1
            and then OpenCV.Core.UInt8_Access.Get (Result, 2, 1) = 2
            and then OpenCV.Core.UInt8_Access.Get (Result, 2, 2) = 1
            and then OpenCV.Core.UInt8_Access.Get (Result, 2, 3) = 2
            and then OpenCV.Core.UInt8_Access.Get (Result, 2, 4) = 1
            and then OpenCV.Core.UInt8_Access.Get (Result, 2, 5) = 2
            and then OpenCV.Core.UInt8_Access.Get (Result, 3, 0) = 3
            and then OpenCV.Core.UInt8_Access.Get (Result, 3, 1) = 4
            and then OpenCV.Core.UInt8_Access.Get (Result, 3, 2) = 3
            and then OpenCV.Core.UInt8_Access.Get (Result, 3, 3) = 4
            and then OpenCV.Core.UInt8_Access.Get (Result, 3, 4) = 3
            and then OpenCV.Core.UInt8_Access.Get (Result, 3, 5) = 4,
            "Repeat must produce the exact vertical and horizontal tile"
            & " order");
      end;
   end Repeat_Rectangular_UInt8_Maps_All_Elements;

   procedure Repeat_Identity_And_Vector_Shapes (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Row    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Column : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 1));
      Square : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
   begin
      for Index in 0 .. 2 loop
         OpenCV.Core.UInt8_Access.Set
           (Source, 0, Index, Interfaces.Unsigned_8 (Index + 1));
         OpenCV.Core.UInt8_Access.Set
           (Source, 1, Index, Interfaces.Unsigned_8 (Index + 4));
      end loop;
      OpenCV.Core.UInt8_Access.Set (Row, 0, 0, 7);
      OpenCV.Core.UInt8_Access.Set (Row, 0, 1, 8);
      OpenCV.Core.UInt8_Access.Set (Column, 0, 0, 9);
      OpenCV.Core.UInt8_Access.Set (Column, 1, 0, 10);
      OpenCV.Core.UInt8_Access.Set (Square, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Square, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Square, 1, 0, 3);
      OpenCV.Core.UInt8_Access.Set (Square, 1, 1, 4);

      declare
         Identity      : OpenCV.Core.Mat :=
           Source.Repeat (Row_Repetitions => 1, Column_Repetitions => 1);
         Vertical      : constant OpenCV.Core.Mat :=
           Source.Repeat (Row_Repetitions => 2, Column_Repetitions => 1);
         Horizontal    : constant OpenCV.Core.Mat :=
           Source.Repeat (Row_Repetitions => 1, Column_Repetitions => 2);
         Row_Result    : constant OpenCV.Core.Mat :=
           Row.Repeat (Row_Repetitions => 3, Column_Repetitions => 2);
         Column_Result : constant OpenCV.Core.Mat :=
           Column.Repeat (Row_Repetitions => 2, Column_Repetitions => 3);
         Square_Result : constant OpenCV.Core.Mat :=
           Square.Repeat (Row_Repetitions => 2, Column_Repetitions => 2);
      begin
         AUnit.Assertions.Assert
           (UInt8_Mats_Are_Equivalent (Identity, Source),
            "Repeat identity must preserve every source value");
         OpenCV.Core.UInt8_Access.Set (Identity, 0, 0, 20);
         AUnit.Assertions.Assert
           (Source.Rows = 2
            and then Source.Columns = 3
            and then OpenCV.Core.UInt8_Access.Get (Source, 0, 0) = 1
            and then Vertical.Rows = 4
            and then Vertical.Columns = 3
            and then OpenCV.Core.UInt8_Access.Get (Vertical, 3, 2) = 6
            and then Horizontal.Rows = 2
            and then Horizontal.Columns = 6
            and then OpenCV.Core.UInt8_Access.Get (Horizontal, 1, 5) = 6
            and then Row_Result.Rows = 3
            and then Row_Result.Columns = 4
            and then OpenCV.Core.UInt8_Access.Get (Row_Result, 2, 3) = 8
            and then Column_Result.Rows = 4
            and then Column_Result.Columns = 3
            and then OpenCV.Core.UInt8_Access.Get (Column_Result, 3, 2) = 10
            and then Square_Result.Rows = 4
            and then Square_Result.Columns = 4
            and then OpenCV.Core.UInt8_Access.Get (Square_Result, 2, 2) = 1,
            "Repeat identity must be independent and support vector and"
            & " square shapes");
      end;
   end Repeat_Identity_And_Vector_Shapes;

   procedure Repeat_Float32_And_UInt8_Vec3 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Floats  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Vectors : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 3));
   begin
      OpenCV.Core.Float32_Access.Set (Floats, 0, 0, 1.5);
      OpenCV.Core.Float32_Access.Set (Floats, 0, 1, 2.5);
      OpenCV.Core.UInt8_Vec3_Access.Set (Vectors, 0, 0, (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vectors, 0, 1, (4, 5, 6));

      declare
         Float_Result : constant OpenCV.Core.Mat :=
           Floats.Repeat (Row_Repetitions => 2, Column_Repetitions => 2);
         Vec_Result   : constant OpenCV.Core.Mat :=
           Vectors.Repeat (Row_Repetitions => 2, Column_Repetitions => 3);
      begin
         AUnit.Assertions.Assert
           (Float_Result.Rows = 2
            and then Float_Result.Columns = 4
            and then Float_Result.Depth = OpenCV.Core.Float32
            and then Float_Result.Channels = 1
            and then OpenCV.Core.Float32_Access.Get (Float_Result, 1, 2) = 1.5
            and then Vec_Result.Rows = 2
            and then Vec_Result.Columns = 6
            and then Vec_Result.Depth = OpenCV.Core.UInt8
            and then Vec_Result.Channels = 3
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 0, 0)
                     = (1, 2, 3)
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 0, 3)
                     = (4, 5, 6)
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 1, 4)
                     = (1, 2, 3),
            "Repeat must preserve metadata and complete Float32 and Vec3"
            & " values");
      end;
   end Repeat_Float32_And_UInt8_Vec3;

   procedure Repeat_Region_Lifetime_Empty_And_Size_Validation
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Mat;
      Empty  : OpenCV.Core.Mat;

      procedure Repeat_Too_Many_Rows is
         Source  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 1));
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored :=
           Source.Repeat
             (Row_Repetitions => Positive'Last, Column_Repetitions => 1);
      end Repeat_Too_Many_Rows;
   begin
      declare
         Parent : OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 4, (OpenCV.Core.UInt8, 1));
      begin
         OpenCV.Core.UInt8_Access.Set (Parent, 0, 1, 1);
         OpenCV.Core.UInt8_Access.Set (Parent, 0, 2, 2);
         OpenCV.Core.UInt8_Access.Set (Parent, 1, 1, 3);
         OpenCV.Core.UInt8_Access.Set (Parent, 1, 2, 4);
         declare
            Region : constant OpenCV.Core.Mat :=
              Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
         begin
            Result :=
              Region.Repeat (Row_Repetitions => 2, Column_Repetitions => 2);
            OpenCV.Core.UInt8_Access.Set (Result, 0, 0, 20);
            AUnit.Assertions.Assert
              (not Region.Is_Continuous
               and then OpenCV.Core.UInt8_Access.Get (Region, 0, 0) = 1,
               "Repeat must accept non-continuous Regions with independent"
               & " storage");
         end;
      end;

      declare
         Empty_Result : constant OpenCV.Core.Mat :=
           Empty.Repeat (Row_Repetitions => 2, Column_Repetitions => 3);
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Result, 0, 0) = 20
            and then Empty_Result.Is_Empty,
            "A repeat result must survive source finalization and empty input"
            & " must remain empty");
      end;

      Assert_Raises_OpenCV_Error
        (Repeat_Too_Many_Rows'Access,
         "Repeat must reject output dimensions beyond the supported range");
   end Repeat_Region_Lifetime_Empty_And_Size_Validation;

   procedure Copy_Make_Border_UInt8_Modes_And_Constant_Value
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.UInt8, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 2, 3);

      declare
         Constant_Result    : constant OpenCV.Core.Mat :=
           Source.Copy_Make_Border
             (Top    => 0,
              Bottom => 0,
              Left   => 2,
              Right  => 2,
              Kind   => OpenCV.Core.Constant_Border,
              Value  => OpenCV.Core.Make_Scalar (9.0));
         Replicate_Result   : constant OpenCV.Core.Mat :=
           Source.Copy_Make_Border (0, 0, 2, 2, OpenCV.Core.Replicate);
         Reflect_Result     : constant OpenCV.Core.Mat :=
           Source.Copy_Make_Border (0, 0, 2, 2, OpenCV.Core.Reflect);
         Reflect_101_Result : constant OpenCV.Core.Mat :=
           Source.Copy_Make_Border (0, 0, 2, 2, OpenCV.Core.Reflect_101);
         Wrap_Result        : constant OpenCV.Core.Mat :=
           Source.Copy_Make_Border (0, 0, 2, 2, OpenCV.Core.Wrap);
      begin
         AUnit.Assertions.Assert
           (Constant_Result.Rows = 1
            and then Constant_Result.Columns = 7
            and then Constant_Result.Depth = OpenCV.Core.UInt8
            and then Constant_Result.Channels = 1
            and then OpenCV.Core.UInt8_Access.Get (Constant_Result, 0, 0) = 9
            and then OpenCV.Core.UInt8_Access.Get (Constant_Result, 0, 6) = 9
            and then OpenCV.Core.UInt8_Access.Get (Replicate_Result, 0, 0) = 1
            and then OpenCV.Core.UInt8_Access.Get (Replicate_Result, 0, 1) = 1
            and then OpenCV.Core.UInt8_Access.Get (Replicate_Result, 0, 5) = 3
            and then OpenCV.Core.UInt8_Access.Get (Replicate_Result, 0, 6) = 3
            and then OpenCV.Core.UInt8_Access.Get (Reflect_Result, 0, 0) = 2
            and then OpenCV.Core.UInt8_Access.Get (Reflect_Result, 0, 1) = 1
            and then OpenCV.Core.UInt8_Access.Get (Reflect_Result, 0, 5) = 3
            and then OpenCV.Core.UInt8_Access.Get (Reflect_Result, 0, 6) = 2
            and then OpenCV.Core.UInt8_Access.Get (Reflect_101_Result, 0, 0)
                     = 3
            and then OpenCV.Core.UInt8_Access.Get (Reflect_101_Result, 0, 1)
                     = 2
            and then OpenCV.Core.UInt8_Access.Get (Reflect_101_Result, 0, 5)
                     = 2
            and then OpenCV.Core.UInt8_Access.Get (Reflect_101_Result, 0, 6)
                     = 1
            and then OpenCV.Core.UInt8_Access.Get (Wrap_Result, 0, 0) = 2
            and then OpenCV.Core.UInt8_Access.Get (Wrap_Result, 0, 1) = 3
            and then OpenCV.Core.UInt8_Access.Get (Wrap_Result, 0, 5) = 1
            and then OpenCV.Core.UInt8_Access.Get (Wrap_Result, 0, 6) = 2,
            "Copy_Make_Border must map every supported border kind exactly");
      end;
   end Copy_Make_Border_UInt8_Modes_And_Constant_Value;

   procedure Copy_Make_Border_Constant_Preserves_Complete_Element_Type
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (Source, 0, 0, (1, 2, 3));

      declare
         Result : constant OpenCV.Core.Mat :=
           Source.Copy_Make_Border
             (Top    => 1,
              Bottom => 1,
              Left   => 1,
              Right  => 1,
              Kind   => OpenCV.Core.Constant_Border,
              Value  => OpenCV.Core.Make_Scalar (10.0, 20.0, 30.0));
      begin
         AUnit.Assertions.Assert
           (Result.Rows = 3
            and then Result.Columns = 3
            and then Result.Depth = OpenCV.Core.UInt8
            and then Result.Channels = 3
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Result, 0, 0)
                     = (10, 20, 30)
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Result, 1, 1)
                     = (1, 2, 3)
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Result, 2, 2)
                     = (10, 20, 30),
            "Constant borders must preserve type and apply every Scalar"
            & " component");
      end;
   end Copy_Make_Border_Constant_Preserves_Complete_Element_Type;

   procedure Copy_Make_Border_Region_Isolation_Lifetime_Empty_And_Validation
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Mat;
      Empty  : OpenCV.Core.Mat;

      procedure Border_Too_Large is
         Source  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored :=
           Source.Copy_Make_Border
             (Top    => Natural'Last,
              Bottom => 0,
              Left   => 0,
              Right  => 0,
              Kind   => OpenCV.Core.Replicate);
      end Border_Too_Large;
   begin
      declare
         Parent : OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 5, (OpenCV.Core.UInt8, 1));
      begin
         for Column in 0 .. 4 loop
            OpenCV.Core.UInt8_Access.Set
              (Parent, 0, Column, Interfaces.Unsigned_8 ((Column + 1) * 10));
         end loop;

         declare
            Region          : constant OpenCV.Core.Mat :=
              Parent.Region ((X => 1, Y => 0, Width => 3, Height => 1));
            Default_Result  : constant OpenCV.Core.Mat :=
              Region.Copy_Make_Border
                (Top    => 0,
                 Bottom => 0,
                 Left   => 1,
                 Right  => 1,
                 Kind   => OpenCV.Core.Replicate);
            Isolated_Result : constant OpenCV.Core.Mat :=
              Region.Copy_Make_Border
                (Top      => 0,
                 Bottom   => 0,
                 Left     => 1,
                 Right    => 1,
                 Kind     => OpenCV.Core.Replicate,
                 Isolated => True);
         begin
            Result := Isolated_Result;
            AUnit.Assertions.Assert
              (OpenCV.Core.UInt8_Access.Get (Default_Result, 0, 0) = 10
               and then OpenCV.Core.UInt8_Access.Get (Default_Result, 0, 4)
                        = 50
               and then OpenCV.Core.UInt8_Access.Get (Isolated_Result, 0, 0)
                        = 20
               and then OpenCV.Core.UInt8_Access.Get (Isolated_Result, 0, 4)
                        = 40
               and then OpenCV.Core.UInt8_Access.Get (Region, 0, 0) = 20,
               "Isolated must independently restrict Replicate borders"
               & " to Region boundaries while the default may use parent"
               & " pixels");
            OpenCV.Core.UInt8_Access.Set (Result, 0, 0, 99);
         end;
      end;

      declare
         Empty_Result : constant OpenCV.Core.Mat :=
           Empty.Copy_Make_Border (0, 0, 0, 0, OpenCV.Core.Constant_Border);
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Result, 0, 0) = 99
            and then Empty_Result.Is_Empty,
            "Border results must survive source finalization and preserve"
            & " empty input with zero borders");
      end;

      Assert_Raises_OpenCV_Error
        (Border_Too_Large'Access,
         "Copy_Make_Border must reject border sizes beyond the supported"
         & " range");
   end Copy_Make_Border_Region_Isolation_Lifetime_Empty_And_Validation;

   procedure Border_Interpolate_In_Range_Coordinates
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Kinds     :
        constant array (Positive range <>) of OpenCV.Core.Border_Kind :=
          (OpenCV.Core.Constant_Border,
           OpenCV.Core.Replicate,
           OpenCV.Core.Reflect,
           OpenCV.Core.Reflect_101,
           OpenCV.Core.Wrap);
      Positions :
        constant array (Positive range <>) of OpenCV.Core.Point_Coordinate :=
          (0, 3, 7);
   begin
      for Kind of Kinds loop
         for Position of Positions loop
            declare
               Interpolation :
                 constant OpenCV.Core.Border_Interpolation_Result :=
                   OpenCV.Core.Border_Interpolate (Position, 8, Kind);
            begin
               AUnit.Assertions.Assert
                 (not Interpolation.Uses_Constant
                  and then Interpolation.Index
                           = OpenCV.Core.Size_Coordinate (Position)
                  and then Interpolation.Index < 8,
                  "In-range border interpolation must return its"
                  & " source coordinate");
            end;
         end loop;
      end loop;
   end Border_Interpolate_In_Range_Coordinates;

   procedure Border_Interpolate_Extrapolation_Mappings
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);

      procedure Assert_Index
        (Position : OpenCV.Core.Point_Coordinate;
         Kind     : OpenCV.Core.Border_Kind;
         Expected : OpenCV.Core.Size_Coordinate)
      is
         Interpolation : constant OpenCV.Core.Border_Interpolation_Result :=
           OpenCV.Core.Border_Interpolate (Position, 8, Kind);
      begin
         AUnit.Assertions.Assert
           (not Interpolation.Uses_Constant
            and then Interpolation.Index = Expected
            and then Interpolation.Index < 8,
            "Border interpolation must return the expected"
            & " valid donor index");
      end Assert_Index;
   begin
      Assert_Index (-1, OpenCV.Core.Replicate, 0);
      Assert_Index (-100, OpenCV.Core.Replicate, 0);
      Assert_Index (8, OpenCV.Core.Replicate, 7);
      Assert_Index (100, OpenCV.Core.Replicate, 7);

      Assert_Index (-1, OpenCV.Core.Reflect, 0);
      Assert_Index (-2, OpenCV.Core.Reflect, 1);
      Assert_Index (8, OpenCV.Core.Reflect, 7);
      Assert_Index (9, OpenCV.Core.Reflect, 6);
      Assert_Index (-18, OpenCV.Core.Reflect, 1);
      Assert_Index (25, OpenCV.Core.Reflect, 6);

      Assert_Index (-1, OpenCV.Core.Reflect_101, 1);
      Assert_Index (-2, OpenCV.Core.Reflect_101, 2);
      Assert_Index (8, OpenCV.Core.Reflect_101, 6);
      Assert_Index (9, OpenCV.Core.Reflect_101, 5);
      Assert_Index (-18, OpenCV.Core.Reflect_101, 4);
      Assert_Index (25, OpenCV.Core.Reflect_101, 3);

      Assert_Index (-1, OpenCV.Core.Wrap, 7);
      Assert_Index (-8, OpenCV.Core.Wrap, 0);
      Assert_Index (-9, OpenCV.Core.Wrap, 7);
      Assert_Index (8, OpenCV.Core.Wrap, 0);
      Assert_Index (9, OpenCV.Core.Wrap, 1);
      Assert_Index (-25, OpenCV.Core.Wrap, 7);
      Assert_Index (25, OpenCV.Core.Wrap, 1);
   end Border_Interpolate_Extrapolation_Mappings;

   procedure Border_Interpolate_Constant_And_Length_One
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Kinds     :
        constant array (Positive range <>) of OpenCV.Core.Border_Kind :=
          (OpenCV.Core.Replicate,
           OpenCV.Core.Reflect,
           OpenCV.Core.Reflect_101,
           OpenCV.Core.Wrap);
      Positions :
        constant array (Positive range <>) of OpenCV.Core.Point_Coordinate :=
          (-7, 0, 7);
   begin
      for Position of Positions loop
         for Kind of Kinds loop
            declare
               Interpolation :
                 constant OpenCV.Core.Border_Interpolation_Result :=
                   OpenCV.Core.Border_Interpolate (Position, 1, Kind);
            begin
               AUnit.Assertions.Assert
                 (not Interpolation.Uses_Constant
                  and then Interpolation.Index = 0,
                  "Every non-constant length-one border must select"
                  & " index zero");
            end;
         end loop;
      end loop;

      declare
         In_Range : constant OpenCV.Core.Border_Interpolation_Result :=
           OpenCV.Core.Border_Interpolate (0, 8, OpenCV.Core.Constant_Border);
         At_End   : constant OpenCV.Core.Border_Interpolation_Result :=
           OpenCV.Core.Border_Interpolate (7, 8, OpenCV.Core.Constant_Border);
         Before   : constant OpenCV.Core.Border_Interpolation_Result :=
           OpenCV.Core.Border_Interpolate (-1, 8, OpenCV.Core.Constant_Border);
         After    : constant OpenCV.Core.Border_Interpolation_Result :=
           OpenCV.Core.Border_Interpolate (8, 8, OpenCV.Core.Constant_Border);
         One      : constant OpenCV.Core.Border_Interpolation_Result :=
           OpenCV.Core.Border_Interpolate (0, 1, OpenCV.Core.Constant_Border);
         Outside  : constant OpenCV.Core.Border_Interpolation_Result :=
           OpenCV.Core.Border_Interpolate (-7, 1, OpenCV.Core.Constant_Border);
      begin
         AUnit.Assertions.Assert
           (not In_Range.Uses_Constant
            and then In_Range.Index = 0
            and then not At_End.Uses_Constant
            and then At_End.Index = 7
            and then Before.Uses_Constant
            and then After.Uses_Constant
            and then not One.Uses_Constant
            and then One.Index = 0
            and then Outside.Uses_Constant,
            "Constant border must expose a donor only for"
            & " in-range coordinates");
      end;
   end Border_Interpolate_Constant_And_Length_One;

   procedure Border_Interpolate_Overflow_Boundaries
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Maximum_Length : constant Positive :=
        Positive (Interfaces.Integer_32'Last);

      procedure Reflect_First is
         Ignored : constant OpenCV.Core.Border_Interpolation_Result :=
           OpenCV.Core.Border_Interpolate
             (OpenCV.Core.Point_Coordinate'First, 8, OpenCV.Core.Reflect);
      begin
         null;
      end Reflect_First;

      procedure Reflect_101_First is
         Ignored : constant OpenCV.Core.Border_Interpolation_Result :=
           OpenCV.Core.Border_Interpolate
             (OpenCV.Core.Point_Coordinate'First, 8, OpenCV.Core.Reflect_101);
      begin
         null;
      end Reflect_101_First;

      procedure Unsafe_Wrap is
         Ignored : constant OpenCV.Core.Border_Interpolation_Result :=
           OpenCV.Core.Border_Interpolate
             (OpenCV.Core.Point_Coordinate'First, 8, OpenCV.Core.Wrap);
      begin
         null;
      end Unsafe_Wrap;

      procedure Length_One_Minimum_Wrap is
         Ignored : constant OpenCV.Core.Border_Interpolation_Result :=
           OpenCV.Core.Border_Interpolate
             (OpenCV.Core.Point_Coordinate'First, 1, OpenCV.Core.Wrap);
      begin
         null;
      end Length_One_Minimum_Wrap;

   begin
      Assert_Raises_OpenCV_Error
        (Reflect_First'Access,
         "Reflect must reject INT32_MIN before OpenCV negates it");
      Assert_Raises_OpenCV_Error
        (Reflect_101_First'Access,
         "Reflect_101 must reject INT32_MIN before OpenCV negates it");
      Assert_Raises_OpenCV_Error
        (Unsafe_Wrap'Access,
         "Wrap must reject coordinates where OpenCV's p - length"
         & " overflows");
      Assert_Raises_OpenCV_Error
        (Length_One_Minimum_Wrap'Access,
         "Length-one Wrap must reject INT32_MIN because p - 1" & " overflows");
      declare
         Reflect_Safe : constant OpenCV.Core.Border_Interpolation_Result :=
           OpenCV.Core.Border_Interpolate
             (OpenCV.Core.Point_Coordinate'First + 1,
              Maximum_Length,
              OpenCV.Core.Reflect);
         Wrap_Safe    : constant OpenCV.Core.Border_Interpolation_Result :=
           OpenCV.Core.Border_Interpolate
             (OpenCV.Core.Point_Coordinate'First + 8, 8, OpenCV.Core.Wrap);
      begin
         AUnit.Assertions.Assert
           (not Reflect_Safe.Uses_Constant
            and then Reflect_Safe.Index = OpenCV.Core.Size_Coordinate'Last - 1
            and then not Wrap_Safe.Uses_Constant
            and then Wrap_Safe.Index = 0,
            "Coordinates nearest the Reflect and Wrap overflow boundaries"
            & " must remain accepted");
      end;
   end Border_Interpolate_Overflow_Boundaries;

   procedure Border_Interpolate_Int32_Maximum (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Kinds : constant array (Positive range <>) of OpenCV.Core.Border_Kind :=
        (OpenCV.Core.Constant_Border,
         OpenCV.Core.Replicate,
         OpenCV.Core.Reflect,
         OpenCV.Core.Reflect_101,
         OpenCV.Core.Wrap);
   begin
      for Kind of Kinds loop
         declare
            Interpolation : constant OpenCV.Core.Border_Interpolation_Result :=
              OpenCV.Core.Border_Interpolate
                (OpenCV.Core.Point_Coordinate'Last, 8, Kind);
         begin
            AUnit.Assertions.Assert
              ((if Kind = OpenCV.Core.Constant_Border
                then Interpolation.Uses_Constant
                else
                  not Interpolation.Uses_Constant
                  and then Interpolation.Index < 8),
               "INT32_MAX must safely produce its documented border result");
         end;
      end loop;
   end Border_Interpolate_Int32_Maximum;

   procedure HConcat_UInt8_Mapping_And_Array_Order
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Center  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Right   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 1));
      Sources : OpenCV.Core.Mat_Array (5 .. 7) :=
        (5 => Left, 6 => Center, 7 => Right);
   begin
      OpenCV.Core.UInt8_Access.Set (Left, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Left, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Left, 1, 0, 3);
      OpenCV.Core.UInt8_Access.Set (Left, 1, 1, 4);
      OpenCV.Core.UInt8_Access.Set (Center, 0, 0, 5);
      OpenCV.Core.UInt8_Access.Set (Center, 0, 1, 6);
      OpenCV.Core.UInt8_Access.Set (Center, 0, 2, 7);
      OpenCV.Core.UInt8_Access.Set (Center, 1, 0, 8);
      OpenCV.Core.UInt8_Access.Set (Center, 1, 1, 9);
      OpenCV.Core.UInt8_Access.Set (Center, 1, 2, 10);
      OpenCV.Core.UInt8_Access.Set (Right, 0, 0, 11);
      OpenCV.Core.UInt8_Access.Set (Right, 1, 0, 12);

      Sources := (5 => Left, 6 => Center, 7 => Right);
      declare
         Result : constant OpenCV.Core.Mat := OpenCV.Core.HConcat (Sources);
      begin
         AUnit.Assertions.Assert
           (Result.Rows = 2
            and then Result.Columns = 6
            and then Result.Depth = OpenCV.Core.UInt8
            and then Result.Channels = 1
            and then OpenCV.Core.UInt8_Access.Get (Result, 0, 0) = 1
            and then OpenCV.Core.UInt8_Access.Get (Result, 0, 1) = 2
            and then OpenCV.Core.UInt8_Access.Get (Result, 0, 2) = 5
            and then OpenCV.Core.UInt8_Access.Get (Result, 0, 3) = 6
            and then OpenCV.Core.UInt8_Access.Get (Result, 0, 4) = 7
            and then OpenCV.Core.UInt8_Access.Get (Result, 0, 5) = 11
            and then OpenCV.Core.UInt8_Access.Get (Result, 1, 0) = 3
            and then OpenCV.Core.UInt8_Access.Get (Result, 1, 1) = 4
            and then OpenCV.Core.UInt8_Access.Get (Result, 1, 2) = 8
            and then OpenCV.Core.UInt8_Access.Get (Result, 1, 3) = 9
            and then OpenCV.Core.UInt8_Access.Get (Result, 1, 4) = 10
            and then OpenCV.Core.UInt8_Access.Get (Result, 1, 5) = 12,
            "HConcat must preserve left-to-right values for arbitrary bounds");
      end;
   end HConcat_UInt8_Mapping_And_Array_Order;

   procedure HConcat_Float32_And_UInt8_Vec3 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Float_Left  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Float_Right : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Vec_Left    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Vec_Right   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 3));
   begin
      OpenCV.Core.Float32_Access.Set (Float_Left, 0, 0, 1.5);
      OpenCV.Core.Float32_Access.Set (Float_Right, 0, 0, 2.5);
      OpenCV.Core.Float32_Access.Set (Float_Right, 0, 1, 3.5);
      OpenCV.Core.UInt8_Vec3_Access.Set (Vec_Left, 0, 0, (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vec_Right, 0, 0, (4, 5, 6));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vec_Right, 0, 1, (7, 8, 9));

      declare
         Float_Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.HConcat ((0 => Float_Left, 1 => Float_Right));
         Vec_Result   : constant OpenCV.Core.Mat :=
           OpenCV.Core.HConcat ((0 => Vec_Left, 1 => Vec_Right));
      begin
         AUnit.Assertions.Assert
           (Float_Result.Rows = 1
            and then Float_Result.Columns = 3
            and then Float_Result.Depth = OpenCV.Core.Float32
            and then Float_Result.Channels = 1
            and then OpenCV.Core.Float32_Access.Get (Float_Result, 0, 2) = 3.5
            and then Vec_Result.Rows = 1
            and then Vec_Result.Columns = 3
            and then Vec_Result.Depth = OpenCV.Core.UInt8
            and then Vec_Result.Channels = 3
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 0, 0)
                     = (1, 2, 3)
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 0, 1)
                     = (4, 5, 6)
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 0, 2)
                     = (7, 8, 9),
            "HConcat must preserve Float32 values and complete Vec3 tuples");
      end;
   end HConcat_Float32_And_UInt8_Vec3;

   procedure HConcat_Region_Lifetime_Empty_And_Validation
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result        : OpenCV.Core.Mat;
      Empty_Sources : OpenCV.Core.Mat_Array (1 .. 0);
      Empty_Inputs  : OpenCV.Core.Mat_Array (2 .. 3);

      procedure Mismatched_Rows is
         Left    : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Right   : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 1));
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := OpenCV.Core.HConcat ((0 => Left, 1 => Right));
      end Mismatched_Rows;

      procedure Mismatched_Depth is
         UInt8_Source : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Float_Source : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
         Ignored      : OpenCV.Core.Mat;
      begin
         Ignored :=
           OpenCV.Core.HConcat ((0 => UInt8_Source, 1 => Float_Source));
      end Mismatched_Depth;

      procedure Mismatched_Channels is
         UInt8_Source : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Vec_Source   : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
         Ignored      : OpenCV.Core.Mat;
      begin
         Ignored := OpenCV.Core.HConcat ((0 => UInt8_Source, 1 => Vec_Source));
      end Mismatched_Channels;
   begin
      declare
         Parent : OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 6, (OpenCV.Core.UInt8, 1));
      begin
         for Row in 0 .. 1 loop
            for Column in 0 .. 5 loop
               OpenCV.Core.UInt8_Access.Set
                 (Parent,
                  Row,
                  Column,
                  Interfaces.Unsigned_8 (Row * 6 + Column + 1));
            end loop;
         end loop;
         declare
            Left  : constant OpenCV.Core.Mat :=
              Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
            Right : constant OpenCV.Core.Mat :=
              Parent.Region ((X => 3, Y => 0, Width => 2, Height => 2));
         begin
            Result := OpenCV.Core.HConcat ((0 => Left, 1 => Right));
            OpenCV.Core.UInt8_Access.Set (Result, 0, 0, 20);
            AUnit.Assertions.Assert
              (not Left.Is_Continuous
               and then OpenCV.Core.UInt8_Access.Get (Left, 0, 0) = 2,
               "HConcat must accept non-continuous Regions with independent"
               & " storage");
         end;
      end;

      declare
         Single : OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      begin
         OpenCV.Core.UInt8_Access.Set (Single, 0, 0, 7);
         declare
            Single_Result : OpenCV.Core.Mat :=
              OpenCV.Core.HConcat ((0 => Single));
         begin
            OpenCV.Core.UInt8_Access.Set (Single_Result, 0, 0, 9);
            AUnit.Assertions.Assert
              (OpenCV.Core.UInt8_Access.Get (Single, 0, 0) = 7,
               "A one-element HConcat result must have independent storage");
         end;
      end;

      declare
         Empty_Result        : constant OpenCV.Core.Mat :=
           OpenCV.Core.HConcat (Empty_Sources);
         Empty_Inputs_Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.HConcat (Empty_Inputs);
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Result, 0, 0) = 20
            and then Empty_Result.Is_Empty
            and then Empty_Inputs_Result.Is_Empty,
            "HConcat must survive source finalization and accept empty"
            & " inputs");
      end;

      Assert_Raises_OpenCV_Error
        (Mismatched_Rows'Access,
         "HConcat must reject inputs with mismatched row counts");
      Assert_Raises_OpenCV_Error
        (Mismatched_Depth'Access,
         "HConcat must reject inputs with mismatched depths");
      Assert_Raises_OpenCV_Error
        (Mismatched_Channels'Access,
         "HConcat must reject inputs with mismatched channel counts");
   end HConcat_Region_Lifetime_Empty_And_Validation;

   procedure VConcat_UInt8_Mapping_Array_Order_And_Cross_Check
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      A       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      B       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.UInt8, 1));
      Bottom  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Sources : OpenCV.Core.Mat_Array (5 .. 7) :=
        (5 => A, 6 => B, 7 => Bottom);
   begin
      for Row in 0 .. 1 loop
         for Column in 0 .. 1 loop
            OpenCV.Core.UInt8_Access.Set
              (A, Row, Column, Interfaces.Unsigned_8 (Row * 2 + Column + 1));
         end loop;
      end loop;
      for Row in 0 .. 2 loop
         for Column in 0 .. 1 loop
            OpenCV.Core.UInt8_Access.Set
              (B, Row, Column, Interfaces.Unsigned_8 (Row * 2 + Column + 5));
         end loop;
      end loop;
      OpenCV.Core.UInt8_Access.Set (Bottom, 0, 0, 11);
      OpenCV.Core.UInt8_Access.Set (Bottom, 0, 1, 12);
      Sources := (5 => A, 6 => B, 7 => Bottom);

      declare
         Two_Result  : constant OpenCV.Core.Mat :=
           OpenCV.Core.VConcat ((0 => A, 1 => B));
         Result      : constant OpenCV.Core.Mat :=
           OpenCV.Core.VConcat (Sources);
         Cross_Check : constant OpenCV.Core.Mat :=
           OpenCV.Core.HConcat
             ((0 => A.Transpose, 1 => B.Transpose, 2 => Bottom.Transpose))
             .Transpose;
      begin
         AUnit.Assertions.Assert
           (Two_Result.Rows = 5
            and then Two_Result.Columns = 2
            and then OpenCV.Core.UInt8_Access.Get (Two_Result, 0, 0) = 1
            and then OpenCV.Core.UInt8_Access.Get (Two_Result, 0, 1) = 2
            and then OpenCV.Core.UInt8_Access.Get (Two_Result, 1, 0) = 3
            and then OpenCV.Core.UInt8_Access.Get (Two_Result, 1, 1) = 4
            and then OpenCV.Core.UInt8_Access.Get (Two_Result, 2, 0) = 5
            and then OpenCV.Core.UInt8_Access.Get (Two_Result, 2, 1) = 6
            and then OpenCV.Core.UInt8_Access.Get (Two_Result, 3, 0) = 7
            and then OpenCV.Core.UInt8_Access.Get (Two_Result, 3, 1) = 8
            and then OpenCV.Core.UInt8_Access.Get (Two_Result, 4, 0) = 9
            and then OpenCV.Core.UInt8_Access.Get (Two_Result, 4, 1) = 10,
            "VConcat must place two inputs in exact top-to-bottom order");
         AUnit.Assertions.Assert
           (Result.Rows = 6
            and then Result.Columns = 2
            and then Result.Depth = OpenCV.Core.UInt8
            and then Result.Channels = 1
            and then OpenCV.Core.UInt8_Access.Get (Result, 5, 0) = 11
            and then OpenCV.Core.UInt8_Access.Get (Result, 5, 1) = 12
            and then UInt8_Mats_Are_Equivalent (Result, Cross_Check),
            "VConcat must preserve arbitrary Mat_Array order and agree with"
            & " the transpose/HConcat test oracle");
      end;
   end VConcat_UInt8_Mapping_Array_Order_And_Cross_Check;

   procedure VConcat_Float32_And_UInt8_Vec3 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Float_Top    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Float_Bottom : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Vec_Top      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Vec_Bottom   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 3));
   begin
      OpenCV.Core.Float32_Access.Set (Float_Top, 0, 0, 1.5);
      OpenCV.Core.Float32_Access.Set (Float_Top, 0, 1, 2.5);
      OpenCV.Core.Float32_Access.Set (Float_Bottom, 0, 0, 3.5);
      OpenCV.Core.Float32_Access.Set (Float_Bottom, 0, 1, 4.5);
      OpenCV.Core.Float32_Access.Set (Float_Bottom, 1, 0, 5.5);
      OpenCV.Core.Float32_Access.Set (Float_Bottom, 1, 1, 6.5);
      OpenCV.Core.UInt8_Vec3_Access.Set (Vec_Top, 0, 0, (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vec_Bottom, 0, 0, (4, 5, 6));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vec_Bottom, 1, 0, (7, 8, 9));

      declare
         Float_Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.VConcat ((0 => Float_Top, 1 => Float_Bottom));
         Vec_Result   : constant OpenCV.Core.Mat :=
           OpenCV.Core.VConcat ((0 => Vec_Top, 1 => Vec_Bottom));
      begin
         AUnit.Assertions.Assert
           (Float_Result.Rows = 3
            and then Float_Result.Columns = 2
            and then Float_Result.Depth = OpenCV.Core.Float32
            and then Float_Result.Channels = 1
            and then OpenCV.Core.Float32_Access.Get (Float_Result, 2, 1) = 6.5,
            "VConcat must preserve Float32 values and element type");
         AUnit.Assertions.Assert
           (Vec_Result.Rows = 3
            and then Vec_Result.Columns = 1
            and then Vec_Result.Depth = OpenCV.Core.UInt8
            and then Vec_Result.Channels = 3
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 0, 0)
                     = (1, 2, 3)
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 1, 0)
                     = (4, 5, 6)
            and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 2, 0)
                     = (7, 8, 9),
            "VConcat must preserve complete UInt8 Vec3 tuples");
      end;
   end VConcat_Float32_And_UInt8_Vec3;

   procedure VConcat_Region_Lifetime_Empty_And_Validation
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result        : OpenCV.Core.Mat;
      Empty         : OpenCV.Core.Mat;
      Empty_Sources : OpenCV.Core.Mat_Array (1 .. 0);
      Empty_Inputs  : constant OpenCV.Core.Mat_Array (0 .. 1) :=
        (others => Empty);

      procedure Mismatched_Columns is
         Left    : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Right   : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := OpenCV.Core.VConcat ((0 => Left, 1 => Right));
      end Mismatched_Columns;

      procedure Mismatched_Depth is
         UInt8_Source : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Float_Source : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
         Ignored      : OpenCV.Core.Mat;
      begin
         Ignored :=
           OpenCV.Core.VConcat ((0 => UInt8_Source, 1 => Float_Source));
      end Mismatched_Depth;

      procedure Mismatched_Channels is
         UInt8_Source : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Vec_Source   : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
         Ignored      : OpenCV.Core.Mat;
      begin
         Ignored := OpenCV.Core.VConcat ((0 => UInt8_Source, 1 => Vec_Source));
      end Mismatched_Channels;
   begin
      declare
         Parent : OpenCV.Core.Mat :=
           OpenCV.Core.Create (4, 4, (OpenCV.Core.UInt8, 1));
      begin
         for Row in 0 .. 3 loop
            for Column in 0 .. 3 loop
               OpenCV.Core.UInt8_Access.Set
                 (Parent,
                  Row,
                  Column,
                  Interfaces.Unsigned_8 (Row * 4 + Column + 1));
            end loop;
         end loop;
         declare
            Top    : constant OpenCV.Core.Mat :=
              Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
            Bottom : constant OpenCV.Core.Mat :=
              Parent.Region ((X => 1, Y => 2, Width => 2, Height => 2));
         begin
            Result := OpenCV.Core.VConcat ((0 => Top, 1 => Bottom));
            OpenCV.Core.UInt8_Access.Set (Result, 0, 0, 20);
            AUnit.Assertions.Assert
              (not Top.Is_Continuous
               and then Result.Rows = 4
               and then Result.Columns = 2
               and then OpenCV.Core.UInt8_Access.Get (Top, 0, 0) = 2,
               "VConcat must accept non-continuous Regions with independent"
               & " storage");
         end;
      end;

      declare
         Single : OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      begin
         OpenCV.Core.UInt8_Access.Set (Single, 0, 0, 7);
         declare
            Single_Result : OpenCV.Core.Mat :=
              OpenCV.Core.VConcat ((0 => Single));
         begin
            OpenCV.Core.UInt8_Access.Set (Single_Result, 0, 0, 9);
            AUnit.Assertions.Assert
              (OpenCV.Core.UInt8_Access.Get (Single, 0, 0) = 7,
               "A one-element VConcat result must have independent storage");
         end;
      end;

      declare
         Empty_Result        : constant OpenCV.Core.Mat :=
           OpenCV.Core.VConcat (Empty_Sources);
         Empty_Inputs_Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.VConcat (Empty_Inputs);
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Result, 0, 0) = 20
            and then Empty_Result.Is_Empty
            and then Empty_Inputs_Result.Is_Empty,
            "VConcat must survive source finalization and accept empty"
            & " inputs");
      end;

      Assert_Raises_OpenCV_Error
        (Mismatched_Columns'Access,
         "VConcat must reject inputs with mismatched column counts");
      Assert_Raises_OpenCV_Error
        (Mismatched_Depth'Access,
         "VConcat must reject inputs with mismatched depths");
      Assert_Raises_OpenCV_Error
        (Mismatched_Channels'Access,
         "VConcat must reject inputs with mismatched channel counts");
   end VConcat_Region_Lifetime_Empty_And_Validation;

   function Sample_Float32_Source return OpenCV.Core.Mat is
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 2, 2.0);
      OpenCV.Core.Float32_Access.Set (Source, 1, 0, -1.0);
      OpenCV.Core.Float32_Access.Set (Source, 1, 1, 5.0);
      OpenCV.Core.Float32_Access.Set (Source, 1, 2, 0.0);
      return Source;
   end Sample_Float32_Source;

   procedure Sort_Every_Row_Ascending (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat := Sample_Float32_Source;
      Result : constant OpenCV.Core.Mat :=
        Source.Sort
          (Axis => OpenCV.Core.Each_Row, Order => OpenCV.Core.Ascending);
   begin
      AUnit.Assertions.Assert
        (Result.Rows = 2
         and then Result.Columns = 3
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 1
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 0) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 1) = 2.0
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 2) = 3.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 0) = -1.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 1) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 2) = 5.0,
         "Each_Row ascending must sort values across the columns of each row");
   end Sort_Every_Row_Ascending;

   procedure Sort_Every_Row_Descending (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat := Sample_Float32_Source;
      Result : constant OpenCV.Core.Mat :=
        Source.Sort
          (Axis => OpenCV.Core.Each_Row, Order => OpenCV.Core.Descending);
   begin
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Result, 0, 0) = 3.0
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 1) = 2.0
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 2) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 0) = 5.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 1) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 2) = -1.0,
         "Each_Row descending must reverse the values of each row");
   end Sort_Every_Row_Descending;

   procedure Sort_Every_Column_Ascending (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat := Sample_Float32_Source;
      Result : constant OpenCV.Core.Mat :=
        Source.Sort
          (Axis => OpenCV.Core.Each_Column, Order => OpenCV.Core.Ascending);
   begin
      AUnit.Assertions.Assert
        (Result.Rows = 2
         and then Result.Columns = 3
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 0) = -1.0
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 1) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 2) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 0) = 3.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 1) = 5.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 2) = 2.0,
         "Each_Column ascending must sort values down each column");
   end Sort_Every_Column_Ascending;

   procedure Sort_Every_Column_Descending (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat := Sample_Float32_Source;
      Result : constant OpenCV.Core.Mat :=
        Source.Sort
          (Axis => OpenCV.Core.Each_Column, Order => OpenCV.Core.Descending);
   begin
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Result, 0, 0) = 3.0
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 1) = 5.0
         and then OpenCV.Core.Float32_Access.Get (Result, 0, 2) = 2.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 0) = -1.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 1) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 2) = 0.0,
         "Each_Column descending must reverse the values of each column");
   end Sort_Every_Column_Descending;

   procedure Sort_Defaults_Are_Each_Row_Ascending
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source  : constant OpenCV.Core.Mat := Sample_Float32_Source;
      Default : constant OpenCV.Core.Mat := Source.Sort;
   begin
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Default, 0, 0) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Default, 0, 1) = 2.0
         and then OpenCV.Core.Float32_Access.Get (Default, 0, 2) = 3.0
         and then OpenCV.Core.Float32_Access.Get (Default, 1, 0) = -1.0
         and then OpenCV.Core.Float32_Access.Get (Default, 1, 1) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Default, 1, 2) = 5.0,
         "Source.Sort must mean Each_Row ascending");
   end Sort_Defaults_Are_Each_Row_Ascending;

   procedure Sort_Integer_Depths (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      UInt8_Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.UInt8, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (UInt8_Source, 0, 0, 30);
      OpenCV.Core.UInt8_Access.Set (UInt8_Source, 0, 1, 10);
      OpenCV.Core.UInt8_Access.Set (UInt8_Source, 0, 2, 40);
      OpenCV.Core.UInt8_Access.Set (UInt8_Source, 0, 3, 20);

      declare
         UInt8_Result    : constant OpenCV.Core.Mat := UInt8_Source.Sort;
         Int8_Result     : constant OpenCV.Core.Mat :=
           UInt8_Source.Convert_To (OpenCV.Core.Int8).Sort;
         UInt16_Result   : constant OpenCV.Core.Mat :=
           UInt8_Source.Convert_To (OpenCV.Core.UInt16).Sort;
         Int16_Result    : constant OpenCV.Core.Mat :=
           UInt8_Source.Convert_To (OpenCV.Core.Int16).Sort;
         Int32_Result    : constant OpenCV.Core.Mat :=
           UInt8_Source.Convert_To (OpenCV.Core.Int32).Sort;
         Int8_As_UInt8   : constant OpenCV.Core.Mat :=
           Int8_Result.Convert_To (OpenCV.Core.UInt8);
         UInt16_As_UInt8 : constant OpenCV.Core.Mat :=
           UInt16_Result.Convert_To (OpenCV.Core.UInt8);
         Int16_As_UInt8  : constant OpenCV.Core.Mat :=
           Int16_Result.Convert_To (OpenCV.Core.UInt8);
         Int32_As_UInt8  : constant OpenCV.Core.Mat :=
           Int32_Result.Convert_To (OpenCV.Core.UInt8);
      begin
         AUnit.Assertions.Assert
           (UInt8_Result.Depth = OpenCV.Core.UInt8
            and then OpenCV.Core.UInt8_Access.Get (UInt8_Result, 0, 0) = 10
            and then OpenCV.Core.UInt8_Access.Get (UInt8_Result, 0, 1) = 20
            and then OpenCV.Core.UInt8_Access.Get (UInt8_Result, 0, 2) = 30
            and then OpenCV.Core.UInt8_Access.Get (UInt8_Result, 0, 3) = 40,
            "Sort must accept UInt8 and order known values");
         AUnit.Assertions.Assert
           (Int8_Result.Depth = OpenCV.Core.Int8
            and then UInt16_Result.Depth = OpenCV.Core.UInt16
            and then Int16_Result.Depth = OpenCV.Core.Int16
            and then Int32_Result.Depth = OpenCV.Core.Int32
            and then OpenCV.Core.UInt8_Access.Get (Int8_As_UInt8, 0, 0) = 10
            and then OpenCV.Core.UInt8_Access.Get (Int8_As_UInt8, 0, 3) = 40
            and then OpenCV.Core.UInt8_Access.Get (UInt16_As_UInt8, 0, 0) = 10
            and then OpenCV.Core.UInt8_Access.Get (UInt16_As_UInt8, 0, 3) = 40
            and then OpenCV.Core.UInt8_Access.Get (Int16_As_UInt8, 0, 0) = 10
            and then OpenCV.Core.UInt8_Access.Get (Int16_As_UInt8, 0, 3) = 40
            and then OpenCV.Core.UInt8_Access.Get (Int32_As_UInt8, 0, 0) = 10
            and then OpenCV.Core.UInt8_Access.Get (Int32_As_UInt8, 0, 3) = 40,
            "Sort must accept Int8, UInt16, Int16, and Int32");
      end;
   end Sort_Integer_Depths;

   procedure Sort_Float64_Preserves_Metadata (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        Sample_Float32_Source.Convert_To (OpenCV.Core.Float64);
      Result : constant OpenCV.Core.Mat := Source.Sort;
   begin
      AUnit.Assertions.Assert
        (Result.Rows = Source.Rows
         and then Result.Columns = Source.Columns
         and then Result.Channels = 1
         and then Result.Depth = OpenCV.Core.Float64
         and then not Result.Is_Empty,
         "Sort must succeed for Float64 and preserve metadata");
   end Sort_Float64_Preserves_Metadata;

   procedure Sort_Single_Row_And_Column (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Row    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
      Column : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Row, 0, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Row, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Row, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Row, 0, 3, 2.0);
      OpenCV.Core.Float32_Access.Set (Column, 0, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Column, 1, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Column, 2, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Column, 3, 0, 2.0);

      declare
         Row_Result        : constant OpenCV.Core.Mat :=
           Row.Sort (Axis => OpenCV.Core.Each_Row);
         Row_Column_Result : constant OpenCV.Core.Mat :=
           Row.Sort (Axis => OpenCV.Core.Each_Column);
         Column_Result     : constant OpenCV.Core.Mat :=
           Column.Sort (Axis => OpenCV.Core.Each_Column);
      begin
         AUnit.Assertions.Assert
           (Row_Result.Rows = 1
            and then Row_Result.Columns = 4
            and then OpenCV.Core.Float32_Access.Get (Row_Result, 0, 0) = 1.0
            and then OpenCV.Core.Float32_Access.Get (Row_Result, 0, 1) = 2.0
            and then OpenCV.Core.Float32_Access.Get (Row_Result, 0, 2) = 3.0
            and then OpenCV.Core.Float32_Access.Get (Row_Result, 0, 3) = 4.0,
            "A 1xN Mat must sort correctly with Each_Row");
         AUnit.Assertions.Assert
           (Row_Column_Result.Rows = 1
            and then Row_Column_Result.Columns = 4
            and then OpenCV.Core.Float32_Access.Get (Row_Column_Result, 0, 0)
                     = 4.0
            and then OpenCV.Core.Float32_Access.Get (Row_Column_Result, 0, 1)
                     = 1.0
            and then OpenCV.Core.Float32_Access.Get (Row_Column_Result, 0, 2)
                     = 3.0
            and then OpenCV.Core.Float32_Access.Get (Row_Column_Result, 0, 3)
                     = 2.0,
            "Each_Column on a 1xN Mat must leave single-element columns");
         AUnit.Assertions.Assert
           (Column_Result.Rows = 4
            and then Column_Result.Columns = 1
            and then OpenCV.Core.Float32_Access.Get (Column_Result, 0, 0) = 1.0
            and then OpenCV.Core.Float32_Access.Get (Column_Result, 1, 0) = 2.0
            and then OpenCV.Core.Float32_Access.Get (Column_Result, 2, 0) = 3.0
            and then OpenCV.Core.Float32_Access.Get (Column_Result, 3, 0)
                     = 4.0,
            "An Nx1 Mat must sort correctly with Each_Column");
      end;
   end Sort_Single_Row_And_Column;

   procedure Sort_Duplicate_Values (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 5, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 2, 2.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 3, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 4, 2.0);

      declare
         Result : constant OpenCV.Core.Mat := Source.Sort;
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Access.Get (Result, 0, 0) = 1.0
            and then OpenCV.Core.Float32_Access.Get (Result, 0, 1) = 1.0
            and then OpenCV.Core.Float32_Access.Get (Result, 0, 2) = 2.0
            and then OpenCV.Core.Float32_Access.Get (Result, 0, 3) = 2.0
            and then OpenCV.Core.Float32_Access.Get (Result, 0, 4) = 2.0,
            "Sort must order repeated finite values without promising"
            & " stability");
      end;
   end Sort_Duplicate_Values;

   procedure Sort_Noncontiguous_Region_Is_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Mat;
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Parent, 0, 0, 9.0);
      OpenCV.Core.Float32_Access.Set (Parent, 0, 1, 3.0);
      OpenCV.Core.Float32_Access.Set (Parent, 0, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Parent, 0, 3, 8.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 0, 7.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 1, -1.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 2, 5.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 3, 0.0);

      declare
         Region : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      begin
         AUnit.Assertions.Assert
           (not Region.Is_Continuous,
            "The Region test must exercise a non-contiguous view");
         Result := Region.Sort (Axis => OpenCV.Core.Each_Row);
         OpenCV.Core.Float32_Access.Set (Result, 0, 0, 99.0);
         AUnit.Assertions.Assert
           (Result.Rows = 2
            and then Result.Columns = 2
            and then OpenCV.Core.Float32_Access.Get (Result, 0, 1) = 3.0
            and then OpenCV.Core.Float32_Access.Get (Result, 1, 0) = -1.0
            and then OpenCV.Core.Float32_Access.Get (Result, 1, 1) = 5.0
            and then OpenCV.Core.Float32_Access.Get (Region, 0, 0) = 3.0
            and then OpenCV.Core.Float32_Access.Get (Region, 0, 1) = 1.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 1) = 3.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 2) = 1.0,
            "Sort must accept a non-contiguous Region without mutating it");
      end;

      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Result, 0, 1) = 3.0
         and then OpenCV.Core.Float32_Access.Get (Result, 1, 1) = 5.0,
         "A Sort result must remain valid after source Region finalization");
   end Sort_Noncontiguous_Region_Is_Independent;

   procedure Sort_Result_Is_Independent (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat := Sample_Float32_Source;
      Result : OpenCV.Core.Mat := Source.Sort;
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 99.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Result, 0, 0) = 1.0,
         "Mutating Source after Sort must not change Result");
      OpenCV.Core.Float32_Access.Set (Result, 0, 2, -7.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Source, 0, 2) = 2.0,
         "Mutating Result after Sort must not change Source");
   end Sort_Result_Is_Independent;

   procedure Sort_Rejects_Multi_Channel (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));

      procedure Sort_Vec3 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Sort;
      end Sort_Vec3;
   begin
      Assert_Raises_OpenCV_Error
        (Sort_Vec3'Access, "Sort must reject a multi-channel Mat");
   end Sort_Rejects_Multi_Channel;

   procedure Sort_Rejects_Float16 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float16, 1));

      procedure Sort_Float16 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Sort;
      end Sort_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Sort_Float16'Access, "Sort must reject Float16 Mats");
   end Sort_Rejects_Float16;

   procedure Sort_Empty_Mats (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Default     : OpenCV.Core.Mat;
      Empty8      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.UInt8, 1));
      Empty32     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Empty64     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float64, 1));
      Empty16     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float16, 1));
      Default_Out : constant OpenCV.Core.Mat := Default.Sort;
      Out8        : constant OpenCV.Core.Mat := Empty8.Sort;
      Out32       : constant OpenCV.Core.Mat := Empty32.Sort;
      Out64       : constant OpenCV.Core.Mat := Empty64.Sort;

      procedure Sort_Empty_Float16 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Empty16.Sort;
      end Sort_Empty_Float16;
   begin
      AUnit.Assertions.Assert
        (Default_Out.Is_Empty
         and then Default_Out.Rows = 0
         and then Default_Out.Columns = 0
         and then Default_Out.Depth = Default.Depth
         and then Default_Out.Channels = Default.Channels,
         "Sort of a default empty Mat must stay empty and preserve metadata");
      AUnit.Assertions.Assert
        (Out8.Is_Empty
         and then Out8.Depth = OpenCV.Core.UInt8
         and then Out8.Channels = 1
         and then Out32.Is_Empty
         and then Out32.Depth = OpenCV.Core.Float32
         and then Out64.Is_Empty
         and then Out64.Depth = OpenCV.Core.Float64,
         "Typed 0x0 supported-depth Mats must sort to empty same-type"
         & " results");
      Assert_Raises_OpenCV_Error
        (Sort_Empty_Float16'Access,
         "Sort must reject a typed empty Float16 Mat");
   end Sort_Empty_Mats;
   function Inspect_Sort_Indices
     (Indices : OpenCV.Core.Mat) return OpenCV.Core.Mat is
   begin
      AUnit.Assertions.Assert
        (Indices.Depth = OpenCV.Core.Int32 and then Indices.Channels = 1,
         "Sort_Indices must return Int32 single-channel metadata");
      return Indices.Convert_To (OpenCV.Core.UInt8);
   end Inspect_Sort_Indices;

   function Index_At
     (Inspected : OpenCV.Core.Mat; Row, Column : Integer)
      return Interfaces.Unsigned_8
   is (OpenCV.Core.UInt8_Access.Get (Inspected, Row, Column));

   procedure Sort_Indices_Every_Row_Ascending (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : constant OpenCV.Core.Mat := Sample_Float32_Source;
      Indices   : constant OpenCV.Core.Mat :=
        Source.Sort_Indices
          (Axis => OpenCV.Core.Each_Row, Order => OpenCV.Core.Ascending);
      Inspected : constant OpenCV.Core.Mat := Inspect_Sort_Indices (Indices);
   begin
      AUnit.Assertions.Assert
        (Indices.Rows = 2
         and then Indices.Columns = 3
         and then Indices.Depth = OpenCV.Core.Int32
         and then Indices.Channels = 1
         and then Index_At (Inspected, 0, 0) = 1
         and then Index_At (Inspected, 0, 1) = 2
         and then Index_At (Inspected, 0, 2) = 0
         and then Index_At (Inspected, 1, 0) = 0
         and then Index_At (Inspected, 1, 1) = 2
         and then Index_At (Inspected, 1, 2) = 1,
         "Each_Row ascending must return original column indices");
   end Sort_Indices_Every_Row_Ascending;

   procedure Sort_Indices_Every_Row_Descending (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : constant OpenCV.Core.Mat := Sample_Float32_Source;
      Indices   : constant OpenCV.Core.Mat :=
        Source.Sort_Indices
          (Axis => OpenCV.Core.Each_Row, Order => OpenCV.Core.Descending);
      Inspected : constant OpenCV.Core.Mat := Inspect_Sort_Indices (Indices);
   begin
      AUnit.Assertions.Assert
        (Index_At (Inspected, 0, 0) = 0
         and then Index_At (Inspected, 0, 1) = 2
         and then Index_At (Inspected, 0, 2) = 1
         and then Index_At (Inspected, 1, 0) = 1
         and then Index_At (Inspected, 1, 1) = 2
         and then Index_At (Inspected, 1, 2) = 0,
         "Each_Row descending must reverse the original column indices");
   end Sort_Indices_Every_Row_Descending;

   procedure Sort_Indices_Every_Column_Ascending
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : constant OpenCV.Core.Mat := Sample_Float32_Source;
      Indices   : constant OpenCV.Core.Mat :=
        Source.Sort_Indices
          (Axis => OpenCV.Core.Each_Column, Order => OpenCV.Core.Ascending);
      Inspected : constant OpenCV.Core.Mat := Inspect_Sort_Indices (Indices);
   begin
      AUnit.Assertions.Assert
        (Indices.Rows = 2
         and then Indices.Columns = 3
         and then Index_At (Inspected, 0, 0) = 1
         and then Index_At (Inspected, 0, 1) = 0
         and then Index_At (Inspected, 0, 2) = 1
         and then Index_At (Inspected, 1, 0) = 0
         and then Index_At (Inspected, 1, 1) = 1
         and then Index_At (Inspected, 1, 2) = 0,
         "Each_Column ascending must return original row indices");
   end Sort_Indices_Every_Column_Ascending;

   procedure Sort_Indices_Every_Column_Descending
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : constant OpenCV.Core.Mat := Sample_Float32_Source;
      Indices   : constant OpenCV.Core.Mat :=
        Source.Sort_Indices
          (Axis => OpenCV.Core.Each_Column, Order => OpenCV.Core.Descending);
      Inspected : constant OpenCV.Core.Mat := Inspect_Sort_Indices (Indices);
   begin
      AUnit.Assertions.Assert
        (Index_At (Inspected, 0, 0) = 0
         and then Index_At (Inspected, 0, 1) = 1
         and then Index_At (Inspected, 0, 2) = 0
         and then Index_At (Inspected, 1, 0) = 1
         and then Index_At (Inspected, 1, 1) = 0
         and then Index_At (Inspected, 1, 2) = 1,
         "Each_Column descending must reverse the original row indices");
   end Sort_Indices_Every_Column_Descending;

   procedure Sort_Indices_Defaults_Are_Each_Row_Ascending
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : constant OpenCV.Core.Mat := Sample_Float32_Source;
      Default   : constant OpenCV.Core.Mat := Source.Sort_Indices;
      Inspected : constant OpenCV.Core.Mat := Inspect_Sort_Indices (Default);
   begin
      AUnit.Assertions.Assert
        (Index_At (Inspected, 0, 0) = 1
         and then Index_At (Inspected, 0, 1) = 2
         and then Index_At (Inspected, 0, 2) = 0
         and then Index_At (Inspected, 1, 0) = 0
         and then Index_At (Inspected, 1, 1) = 2
         and then Index_At (Inspected, 1, 2) = 1,
         "Source.Sort_Indices must mean Each_Row ascending");
   end Sort_Indices_Defaults_Are_Each_Row_Ascending;

   procedure Sort_Indices_Cross_Check_Against_Sort
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : constant OpenCV.Core.Mat := Sample_Float32_Source;
      Sorted    : constant OpenCV.Core.Mat :=
        Source.Sort
          (Axis => OpenCV.Core.Each_Row, Order => OpenCV.Core.Ascending);
      Indices   : constant OpenCV.Core.Mat :=
        Source.Sort_Indices
          (Axis => OpenCV.Core.Each_Row, Order => OpenCV.Core.Ascending);
      Inspected : constant OpenCV.Core.Mat := Inspect_Sort_Indices (Indices);
   begin
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get
           (Source, 0, Integer (Index_At (Inspected, 0, 0)))
         = OpenCV.Core.Float32_Access.Get (Sorted, 0, 0)
         and then OpenCV.Core.Float32_Access.Get
                    (Source, 0, Integer (Index_At (Inspected, 0, 1)))
                  = OpenCV.Core.Float32_Access.Get (Sorted, 0, 1)
         and then OpenCV.Core.Float32_Access.Get
                    (Source, 0, Integer (Index_At (Inspected, 0, 2)))
                  = OpenCV.Core.Float32_Access.Get (Sorted, 0, 2)
         and then OpenCV.Core.Float32_Access.Get
                    (Source, 1, Integer (Index_At (Inspected, 1, 0)))
                  = OpenCV.Core.Float32_Access.Get (Sorted, 1, 0)
         and then OpenCV.Core.Float32_Access.Get
                    (Source, 1, Integer (Index_At (Inspected, 1, 1)))
                  = OpenCV.Core.Float32_Access.Get (Sorted, 1, 1)
         and then OpenCV.Core.Float32_Access.Get
                    (Source, 1, Integer (Index_At (Inspected, 1, 2)))
                  = OpenCV.Core.Float32_Access.Get (Sorted, 1, 2),
         "Sort_Indices must recover Source.Sort values for unique elements");
   end Sort_Indices_Cross_Check_Against_Sort;

   procedure Sort_Indices_Supported_Depths (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      UInt8_Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.UInt8, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (UInt8_Source, 0, 0, 30);
      OpenCV.Core.UInt8_Access.Set (UInt8_Source, 0, 1, 10);
      OpenCV.Core.UInt8_Access.Set (UInt8_Source, 0, 2, 40);
      OpenCV.Core.UInt8_Access.Set (UInt8_Source, 0, 3, 20);

      declare
         UInt8_Indices    : constant OpenCV.Core.Mat :=
           UInt8_Source.Sort_Indices;
         Int8_Indices     : constant OpenCV.Core.Mat :=
           UInt8_Source.Convert_To (OpenCV.Core.Int8).Sort_Indices;
         UInt16_Indices   : constant OpenCV.Core.Mat :=
           UInt8_Source.Convert_To (OpenCV.Core.UInt16).Sort_Indices;
         Int16_Indices    : constant OpenCV.Core.Mat :=
           UInt8_Source.Convert_To (OpenCV.Core.Int16).Sort_Indices;
         Int32_Indices    : constant OpenCV.Core.Mat :=
           UInt8_Source.Convert_To (OpenCV.Core.Int32).Sort_Indices;
         Float32_Indices  : constant OpenCV.Core.Mat :=
           UInt8_Source.Convert_To (OpenCV.Core.Float32).Sort_Indices;
         Float64_Indices  : constant OpenCV.Core.Mat :=
           UInt8_Source.Convert_To (OpenCV.Core.Float64).Sort_Indices;
         UInt8_Inspected  : constant OpenCV.Core.Mat :=
           Inspect_Sort_Indices (UInt8_Indices);
         Int8_Inspected   : constant OpenCV.Core.Mat :=
           Inspect_Sort_Indices (Int8_Indices);
         UInt16_Inspected : constant OpenCV.Core.Mat :=
           Inspect_Sort_Indices (UInt16_Indices);
         Int16_Inspected  : constant OpenCV.Core.Mat :=
           Inspect_Sort_Indices (Int16_Indices);
         Int32_Inspected  : constant OpenCV.Core.Mat :=
           Inspect_Sort_Indices (Int32_Indices);
      begin
         AUnit.Assertions.Assert
           (UInt8_Indices.Depth = OpenCV.Core.Int32
            and then Int8_Indices.Depth = OpenCV.Core.Int32
            and then UInt16_Indices.Depth = OpenCV.Core.Int32
            and then Int16_Indices.Depth = OpenCV.Core.Int32
            and then Int32_Indices.Depth = OpenCV.Core.Int32
            and then Float32_Indices.Depth = OpenCV.Core.Int32
            and then Float64_Indices.Depth = OpenCV.Core.Int32
            and then UInt8_Indices.Channels = 1
            and then Float32_Indices.Channels = 1
            and then Float64_Indices.Channels = 1,
            "Sort_Indices must succeed for all seven supported depths");
         AUnit.Assertions.Assert
           (Index_At (UInt8_Inspected, 0, 0) = 1
            and then Index_At (UInt8_Inspected, 0, 1) = 3
            and then Index_At (UInt8_Inspected, 0, 2) = 0
            and then Index_At (UInt8_Inspected, 0, 3) = 2
            and then Index_At (Int8_Inspected, 0, 0) = 1
            and then Index_At (Int8_Inspected, 0, 3) = 2
            and then Index_At (UInt16_Inspected, 0, 0) = 1
            and then Index_At (UInt16_Inspected, 0, 3) = 2
            and then Index_At (Int16_Inspected, 0, 0) = 1
            and then Index_At (Int16_Inspected, 0, 3) = 2
            and then Index_At (Int32_Inspected, 0, 0) = 1
            and then Index_At (Int32_Inspected, 0, 3) = 2,
            "Sort_Indices must return the same unique-value order for"
            & " representative integer depths");
      end;
   end Sort_Indices_Supported_Depths;

   procedure Sort_Indices_Duplicate_Values (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 5, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 2, 2.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 3, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 4, 2.0);

      declare
         Indices   : constant OpenCV.Core.Mat := Source.Sort_Indices;
         Inspected : constant OpenCV.Core.Mat :=
           Inspect_Sort_Indices (Indices);
         Seen      : array (0 .. 4) of Boolean := (others => False);
         Previous  : Interfaces.IEEE_Float_32;
         Current   : Interfaces.IEEE_Float_32;
         Index     : Integer;
      begin
         for Column in 0 .. 4 loop
            Index := Integer (Index_At (Inspected, 0, Column));
            AUnit.Assertions.Assert
              (Index in 0 .. 4 and then not Seen (Index),
               "Sort_Indices must return a permutation of original columns");
            Seen (Index) := True;
         end loop;

         Previous :=
           OpenCV.Core.Float32_Access.Get
             (Source, 0, Integer (Index_At (Inspected, 0, 0)));
         for Column in 1 .. 4 loop
            Current :=
              OpenCV.Core.Float32_Access.Get
                (Source, 0, Integer (Index_At (Inspected, 0, Column)));
            AUnit.Assertions.Assert
              (Previous <= Current,
               "Dereferencing Sort_Indices must put duplicate values in"
               & " sorted order");
            Previous := Current;
         end loop;
      end;
   end Sort_Indices_Duplicate_Values;

   procedure Sort_Indices_Single_Row_And_Column
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Row    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
      Column : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Row, 0, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Row, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Row, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Row, 0, 3, 2.0);
      OpenCV.Core.Float32_Access.Set (Column, 0, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Column, 1, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Column, 2, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Column, 3, 0, 2.0);

      declare
         Row_Result           : constant OpenCV.Core.Mat :=
           Row.Sort_Indices (Axis => OpenCV.Core.Each_Row);
         Row_Column_Result    : constant OpenCV.Core.Mat :=
           Row.Sort_Indices (Axis => OpenCV.Core.Each_Column);
         Column_Result        : constant OpenCV.Core.Mat :=
           Column.Sort_Indices (Axis => OpenCV.Core.Each_Column);
         Column_Row_Result    : constant OpenCV.Core.Mat :=
           Column.Sort_Indices (Axis => OpenCV.Core.Each_Row);
         Row_Inspected        : constant OpenCV.Core.Mat :=
           Inspect_Sort_Indices (Row_Result);
         Row_Column_Inspected : constant OpenCV.Core.Mat :=
           Inspect_Sort_Indices (Row_Column_Result);
         Column_Inspected     : constant OpenCV.Core.Mat :=
           Inspect_Sort_Indices (Column_Result);
         Column_Row_Inspected : constant OpenCV.Core.Mat :=
           Inspect_Sort_Indices (Column_Row_Result);
      begin
         AUnit.Assertions.Assert
           (Row_Result.Rows = 1
            and then Row_Result.Columns = 4
            and then Index_At (Row_Inspected, 0, 0) = 1
            and then Index_At (Row_Inspected, 0, 1) = 3
            and then Index_At (Row_Inspected, 0, 2) = 2
            and then Index_At (Row_Inspected, 0, 3) = 0,
            "A 1xN Mat must return sorted column indices with Each_Row");
         AUnit.Assertions.Assert
           (Index_At (Row_Column_Inspected, 0, 0) = 0
            and then Index_At (Row_Column_Inspected, 0, 1) = 0
            and then Index_At (Row_Column_Inspected, 0, 2) = 0
            and then Index_At (Row_Column_Inspected, 0, 3) = 0,
            "Each_Column on a 1xN Mat must contain only row index 0");
         AUnit.Assertions.Assert
           (Column_Result.Rows = 4
            and then Column_Result.Columns = 1
            and then Index_At (Column_Inspected, 0, 0) = 1
            and then Index_At (Column_Inspected, 1, 0) = 3
            and then Index_At (Column_Inspected, 2, 0) = 2
            and then Index_At (Column_Inspected, 3, 0) = 0,
            "An Nx1 Mat must return sorted row indices with Each_Column");
         AUnit.Assertions.Assert
           (Index_At (Column_Row_Inspected, 0, 0) = 0
            and then Index_At (Column_Row_Inspected, 1, 0) = 0
            and then Index_At (Column_Row_Inspected, 2, 0) = 0
            and then Index_At (Column_Row_Inspected, 3, 0) = 0,
            "Each_Row on an Nx1 Mat must contain only column index 0");
      end;
   end Sort_Indices_Single_Row_And_Column;

   procedure Sort_Indices_Noncontiguous_Region_Is_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Mat;
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Parent, 0, 0, 9.0);
      OpenCV.Core.Float32_Access.Set (Parent, 0, 1, 3.0);
      OpenCV.Core.Float32_Access.Set (Parent, 0, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Parent, 0, 3, 8.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 0, 7.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 1, -1.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 2, 5.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 3, 0.0);

      declare
         Region : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      begin
         AUnit.Assertions.Assert
           (not Region.Is_Continuous,
            "The Region test must exercise a non-contiguous view");
         Result := Region.Sort_Indices (Axis => OpenCV.Core.Each_Row);
         declare
            Inspected : constant OpenCV.Core.Mat :=
              Inspect_Sort_Indices (Result);
         begin
            AUnit.Assertions.Assert
              (Result.Rows = 2
               and then Result.Columns = 2
               and then Result.Depth = OpenCV.Core.Int32
               and then Index_At (Inspected, 0, 0) = 1
               and then Index_At (Inspected, 0, 1) = 0
               and then Index_At (Inspected, 1, 0) = 0
               and then Index_At (Inspected, 1, 1) = 1
               and then OpenCV.Core.Float32_Access.Get (Region, 0, 0) = 3.0
               and then OpenCV.Core.Float32_Access.Get (Region, 0, 1) = 1.0
               and then OpenCV.Core.Float32_Access.Get (Parent, 0, 1) = 3.0
               and then OpenCV.Core.Float32_Access.Get (Parent, 0, 2) = 1.0,
               "Sort_Indices must use Region-local indices and leave the"
               & " source unchanged");
         end;
      end;

      declare
         Surviving : constant OpenCV.Core.Mat := Inspect_Sort_Indices (Result);
      begin
         AUnit.Assertions.Assert
           (Index_At (Surviving, 0, 0) = 1
            and then Index_At (Surviving, 0, 1) = 0
            and then Index_At (Surviving, 1, 1) = 1,
            "A Sort_Indices result must remain valid after Region"
            & " finalization");
      end;
   end Sort_Indices_Noncontiguous_Region_Is_Independent;

   procedure Sort_Indices_Result_Is_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : OpenCV.Core.Mat := Sample_Float32_Source;
      Indices   : OpenCV.Core.Mat := Source.Sort_Indices;
      Inspected : constant OpenCV.Core.Mat := Inspect_Sort_Indices (Indices);
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 99.0);
      AUnit.Assertions.Assert
        (Index_At (Inspected, 0, 0) = 1
         and then Index_At (Inspect_Sort_Indices (Indices), 0, 0) = 1,
         "Mutating Source after Sort_Indices must not change the result");
      Indices.Set_To (OpenCV.Core.Make_Scalar (9.0));
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Source, 0, 1) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Source, 0, 2) = 2.0,
         "Mutating Indices after Sort_Indices must not change Source");

   end Sort_Indices_Result_Is_Independent;

   procedure Sort_Indices_Rejects_Multi_Channel
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));

      procedure Sort_Indices_Vec3 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Sort_Indices;
      end Sort_Indices_Vec3;
   begin
      Assert_Raises_OpenCV_Error
        (Sort_Indices_Vec3'Access,
         "Sort_Indices must reject a multi-channel Mat");
   end Sort_Indices_Rejects_Multi_Channel;

   procedure Sort_Indices_Rejects_Float16 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float16, 1));

      procedure Sort_Indices_Float16 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Sort_Indices;
      end Sort_Indices_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Sort_Indices_Float16'Access, "Sort_Indices must reject Float16 Mats");
   end Sort_Indices_Rejects_Float16;

   procedure Sort_Indices_Empty_Mats (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Default : OpenCV.Core.Mat;
      Empty8  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.UInt8, 1));
      Empty32 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Empty64 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float64, 1));
      Empty16 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float16, 1));

      procedure Sort_Indices_Default is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Default.Sort_Indices;
      end Sort_Indices_Default;

      procedure Sort_Indices_Empty8 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Empty8.Sort_Indices;
      end Sort_Indices_Empty8;

      procedure Sort_Indices_Empty32 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Empty32.Sort_Indices;
      end Sort_Indices_Empty32;

      procedure Sort_Indices_Empty64 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Empty64.Sort_Indices;
      end Sort_Indices_Empty64;

      procedure Sort_Indices_Empty16 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Empty16.Sort_Indices;
      end Sort_Indices_Empty16;
   begin
      Assert_Raises_OpenCV_Error
        (Sort_Indices_Default'Access,
         "Sort_Indices must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Sort_Indices_Empty8'Access,
         "Sort_Indices must reject a typed empty UInt8 Mat");
      Assert_Raises_OpenCV_Error
        (Sort_Indices_Empty32'Access,
         "Sort_Indices must reject a typed empty Float32 Mat");
      Assert_Raises_OpenCV_Error
        (Sort_Indices_Empty64'Access,
         "Sort_Indices must reject a typed empty Float64 Mat");
      Assert_Raises_OpenCV_Error
        (Sort_Indices_Empty16'Access,
         "Sort_Indices must reject a typed empty Float16 Mat");
   end Sort_Indices_Empty_Mats;

   function Asymmetric_3x3 return OpenCV.Core.Mat is
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 5.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 2, 6.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 0, 7.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 1, 8.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 2, 9.0);
      return Image;
   end Asymmetric_3x3;

   function Matches_3x3
     (Image                     : OpenCV.Core.Mat;
      A, B, C, D, E, F, G, H, I : Interfaces.IEEE_Float_32) return Boolean
   is (Image.Rows = 3
       and then Image.Columns = 3
       and then Image.Depth = OpenCV.Core.Float32
       and then Image.Channels = 1
       and then OpenCV.Core.Float32_Access.Get (Image, 0, 0) = A
       and then OpenCV.Core.Float32_Access.Get (Image, 0, 1) = B
       and then OpenCV.Core.Float32_Access.Get (Image, 0, 2) = C
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 0) = D
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 1) = E
       and then OpenCV.Core.Float32_Access.Get (Image, 1, 2) = F
       and then OpenCV.Core.Float32_Access.Get (Image, 2, 0) = G
       and then OpenCV.Core.Float32_Access.Get (Image, 2, 1) = H
       and then OpenCV.Core.Float32_Access.Get (Image, 2, 2) = I);

   procedure Complete_Symmetry_Default_Copies_Upper_To_Lower
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat := Asymmetric_3x3;
   begin
      Image.Complete_Symmetry;

      AUnit.Assertions.Assert
        (Matches_3x3 (Image, 1.0, 2.0, 3.0, 2.0, 5.0, 6.0, 3.0, 6.0, 9.0),
         "Default Complete_Symmetry must copy the upper triangle onto the"
         & " lower triangle and leave the diagonal unchanged");
   end Complete_Symmetry_Default_Copies_Upper_To_Lower;

   procedure Complete_Symmetry_Explicit_Upper_Triangle
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat := Asymmetric_3x3;
   begin
      Image.Complete_Symmetry (OpenCV.Core.Upper_Triangle);

      AUnit.Assertions.Assert
        (Matches_3x3 (Image, 1.0, 2.0, 3.0, 2.0, 5.0, 6.0, 3.0, 6.0, 9.0),
         "Explicit Upper_Triangle must match the default upper-to-lower"
         & " copy");
   end Complete_Symmetry_Explicit_Upper_Triangle;

   procedure Complete_Symmetry_Lower_Triangle (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat := Asymmetric_3x3;
   begin
      Image.Complete_Symmetry (OpenCV.Core.Lower_Triangle);

      AUnit.Assertions.Assert
        (Matches_3x3 (Image, 1.0, 4.0, 7.0, 4.0, 5.0, 8.0, 7.0, 8.0, 9.0),
         "Lower_Triangle must copy the lower triangle onto the upper"
         & " triangle and leave the diagonal unchanged");
   end Complete_Symmetry_Lower_Triangle;

   procedure Complete_Symmetry_Already_Symmetric
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Upper : OpenCV.Core.Mat := Asymmetric_3x3;
      Lower : OpenCV.Core.Mat := Asymmetric_3x3;
   begin
      Upper.Complete_Symmetry (OpenCV.Core.Upper_Triangle);
      Lower.Complete_Symmetry (OpenCV.Core.Lower_Triangle);
      Upper.Complete_Symmetry (OpenCV.Core.Upper_Triangle);
      Lower.Complete_Symmetry (OpenCV.Core.Lower_Triangle);

      AUnit.Assertions.Assert
        (Matches_3x3 (Upper, 1.0, 2.0, 3.0, 2.0, 5.0, 6.0, 3.0, 6.0, 9.0),
         "Completing an already upper-symmetric Mat must leave it unchanged");
      AUnit.Assertions.Assert
        (Matches_3x3 (Lower, 1.0, 4.0, 7.0, 4.0, 5.0, 8.0, 7.0, 8.0, 9.0),
         "Completing an already lower-symmetric Mat must leave it unchanged");
   end Complete_Symmetry_Already_Symmetric;

   procedure Complete_Symmetry_One_By_One (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Upper : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Lower : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Upper, 0, 0, 7.0);
      OpenCV.Core.Float32_Access.Set (Lower, 0, 0, 7.0);
      Upper.Complete_Symmetry (OpenCV.Core.Upper_Triangle);
      Lower.Complete_Symmetry (OpenCV.Core.Lower_Triangle);

      AUnit.Assertions.Assert
        (Upper.Rows = 1
         and then Upper.Columns = 1
         and then OpenCV.Core.Float32_Access.Get (Upper, 0, 0) = 7.0
         and then OpenCV.Core.Float32_Access.Get (Lower, 0, 0) = 7.0,
         "1x1 Complete_Symmetry must leave the single diagonal value"
         & " unchanged from either triangle");
   end Complete_Symmetry_One_By_One;

   procedure Complete_Symmetry_Supports_Float64
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image     : OpenCV.Core.Mat :=
        Asymmetric_3x3.Convert_To (OpenCV.Core.Float64);
      Inspected : OpenCV.Core.Mat;
   begin
      Image.Complete_Symmetry;

      AUnit.Assertions.Assert
        (Image.Rows = 3
         and then Image.Columns = 3
         and then Image.Depth = OpenCV.Core.Float64
         and then Image.Channels = 1,
         "Complete_Symmetry must preserve Float64 depth and 3x3 shape");

      Inspected := Image.Clone.Convert_To (OpenCV.Core.Float32);
      AUnit.Assertions.Assert
        (Matches_3x3 (Inspected, 1.0, 2.0, 3.0, 2.0, 5.0, 6.0, 3.0, 6.0, 9.0)
         and then Image.Depth = OpenCV.Core.Float64,
         "A Float64 Complete_Symmetry result must copy the upper triangle"
         & " without changing Self's public depth");
   end Complete_Symmetry_Supports_Float64;

   procedure Complete_Symmetry_Copies_Entire_Vec3
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 3));
      Upper : OpenCV.Core.Float32_Vec3.Vector;
      Lower : OpenCV.Core.Float32_Vec3.Vector;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set (Image, 0, 0, (0.0, 0.0, 0.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Image, 0, 1, (1.0, 10.0, 100.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Image, 1, 0, (9.0, 90.0, 190.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Image, 1, 1, (5.0, 50.0, 150.0));
      Image.Complete_Symmetry (OpenCV.Core.Upper_Triangle);
      Upper := OpenCV.Core.Float32_Vec3_Access.Get (Image, 0, 1);
      Lower := OpenCV.Core.Float32_Vec3_Access.Get (Image, 1, 0);

      AUnit.Assertions.Assert
        (Upper = (1.0, 10.0, 100.0) and then Lower = (1.0, 10.0, 100.0),
         "Complete_Symmetry must copy the entire Vec3 element, not only"
         & " channel 0");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Vec3_Access.Get (Image, 0, 0) = (0.0, 0.0, 0.0)
         and then OpenCV.Core.Float32_Vec3_Access.Get (Image, 1, 1)
                  = (5.0, 50.0, 150.0),
         "Multi-channel Complete_Symmetry must leave the diagonal vectors"
         & " unchanged");
   end Complete_Symmetry_Copies_Entire_Vec3;

   procedure Complete_Symmetry_Noncontiguous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 5, (OpenCV.Core.Float32, 1));
      Region : OpenCV.Core.Mat;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Region := Parent.Region ((X => 1, Y => 1, Width => 3, Height => 3));
      OpenCV.Core.Float32_Access.Set (Region, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Region, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Region, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Region, 1, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Region, 1, 1, 5.0);
      OpenCV.Core.Float32_Access.Set (Region, 1, 2, 6.0);
      OpenCV.Core.Float32_Access.Set (Region, 2, 0, 7.0);
      OpenCV.Core.Float32_Access.Set (Region, 2, 1, 8.0);
      OpenCV.Core.Float32_Access.Set (Region, 2, 2, 9.0);

      AUnit.Assertions.Assert
        (not Region.Is_Continuous and then Region.Is_Submatrix,
         "The Region used for Complete_Symmetry must be non-contiguous");

      Region.Complete_Symmetry;

      AUnit.Assertions.Assert
        (Matches_3x3 (Region, 1.0, 2.0, 3.0, 2.0, 5.0, 6.0, 3.0, 6.0, 9.0),
         "Complete_Symmetry must reflect around the Region's own diagonal");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Parent, 1, 2) = 2.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 2, 1) = 2.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 1, 3) = 3.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 3, 1) = 3.0,
         "Region Complete_Symmetry must mutate the corresponding parent"
         & " pixels");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 0, 4) = 99.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 3, 4) = 99.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 1, 0) = 99.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 1, 4) = 99.0,
         "Pixels outside the Region must remain unchanged");
      AUnit.Assertions.Assert
        (Region.Is_Submatrix and then not Region.Is_Continuous,
         "Complete_Symmetry must not detach a Region into an independent"
         & " copy");
   end Complete_Symmetry_Noncontiguous_Region;

   procedure Complete_Symmetry_Shallow_Alias (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Original : constant OpenCV.Core.Mat := Asymmetric_3x3;
      Alias    : OpenCV.Core.Mat := Original;
   begin
      Alias.Complete_Symmetry;

      AUnit.Assertions.Assert
        (Matches_3x3 (Original, 1.0, 2.0, 3.0, 2.0, 5.0, 6.0, 3.0, 6.0, 9.0)
         and then Matches_3x3
                    (Alias, 1.0, 2.0, 3.0, 2.0, 5.0, 6.0, 3.0, 6.0, 9.0),
         "A shallow Mat alias must observe Complete_Symmetry mutation");
   end Complete_Symmetry_Shallow_Alias;

   procedure Complete_Symmetry_Clone_Remains_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Original : constant OpenCV.Core.Mat := Asymmetric_3x3;
      Copy     : OpenCV.Core.Mat := Original.Clone;
   begin
      Copy.Complete_Symmetry;

      AUnit.Assertions.Assert
        (Matches_3x3 (Copy, 1.0, 2.0, 3.0, 2.0, 5.0, 6.0, 3.0, 6.0, 9.0),
         "Clone.Complete_Symmetry must modify the independent copy");
      AUnit.Assertions.Assert
        (Matches_3x3 (Original, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0),
         "Complete_Symmetry on a Clone must leave the original unchanged");
   end Complete_Symmetry_Clone_Remains_Independent;

   procedure Complete_Symmetry_Empty_Behavior (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Image : OpenCV.Core.Mat;
      Empty32       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 3));
      Empty64       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float64, 1));
      Empty8        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.UInt8, 1));

      procedure Complete_Default is
      begin
         Default_Image.Complete_Symmetry;
      end Complete_Default;

      procedure Complete_Empty8 is
      begin
         Empty8.Complete_Symmetry;
      end Complete_Empty8;
   begin
      Empty32.Complete_Symmetry;
      Empty64.Complete_Symmetry;

      AUnit.Assertions.Assert
        (Empty32.Is_Empty
         and then Empty32.Depth = OpenCV.Core.Float32
         and then Empty32.Channels = 3,
         "A typed 0x0 Float32 Mat must remain empty Float32");
      AUnit.Assertions.Assert
        (Empty64.Is_Empty
         and then Empty64.Depth = OpenCV.Core.Float64
         and then Empty64.Channels = 1,
         "A typed 0x0 Float64 Mat must remain empty Float64");
      AUnit.Assertions.Assert
        (Default_Image.Is_Empty
         and then Default_Image.Depth /= OpenCV.Core.Float32
         and then Default_Image.Depth /= OpenCV.Core.Float64,
         "A default empty Mat must not be Float32 or Float64");
      Assert_Raises_OpenCV_Error
        (Complete_Default'Access,
         "Complete_Symmetry must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Complete_Empty8'Access,
         "Complete_Symmetry must reject a typed 0x0 unsupported depth");
   end Complete_Symmetry_Empty_Behavior;

   procedure Complete_Symmetry_Rejects_Rectangular
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));

      procedure Complete_Rectangular is
      begin
         Image.Complete_Symmetry;
      end Complete_Rectangular;
   begin
      Assert_Raises_OpenCV_Error
        (Complete_Rectangular'Access,
         "Complete_Symmetry must reject a non-square Mat");
   end Complete_Symmetry_Rejects_Rectangular;

   procedure Complete_Symmetry_Rejects_Unsupported_Depths
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Int32_Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int32, 1));
      Float16_Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float16, 1));

      procedure Complete_UInt8 is
      begin
         UInt8_Image.Complete_Symmetry;
      end Complete_UInt8;

      procedure Complete_Int32 is
      begin
         Int32_Image.Complete_Symmetry;
      end Complete_Int32;

      procedure Complete_Float16 is
      begin
         Float16_Image.Complete_Symmetry;
      end Complete_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Complete_UInt8'Access, "Complete_Symmetry must reject UInt8 Mats");
      Assert_Raises_OpenCV_Error
        (Complete_Int32'Access, "Complete_Symmetry must reject Int32 Mats");
      Assert_Raises_OpenCV_Error
        (Complete_Float16'Access,
         "Complete_Symmetry must reject Float16 Mats");
   end Complete_Symmetry_Rejects_Unsupported_Depths;

   function Nonzero_3x3 return OpenCV.Core.Mat is
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 9.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 8.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 2, 7.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, 6.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 5.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 2, 4.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 2, 2, 1.0);
      return Image;
   end Nonzero_3x3;

   procedure Set_Identity_Default_Square_Float32
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat := Nonzero_3x3;
   begin
      Image.Set_Identity;

      AUnit.Assertions.Assert
        (Image.Rows = 3
         and then Image.Columns = 3
         and then Image.Depth = OpenCV.Core.Float32
         and then Image.Channels = 1,
         "Set_Identity must preserve 3x3 Float32 single-channel metadata");
      AUnit.Assertions.Assert
        (Matches_3x3 (Image, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0),
         "Default Set_Identity must overwrite a nonzero square Mat with"
         & " the unit identity");
   end Set_Identity_Default_Square_Float32;

   procedure Set_Identity_Scaled_Float32 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat := Nonzero_3x3;
   begin
      Image.Set_Identity (OpenCV.Core.Make_Scalar (2.5));

      AUnit.Assertions.Assert
        (Matches_3x3 (Image, 2.5, 0.0, 0.0, 0.0, 2.5, 0.0, 0.0, 0.0, 2.5),
         "Set_Identity must scale the diagonal from Make_Scalar (2.5)");
   end Set_Identity_Scaled_Float32;

   procedure Set_Identity_Wide_Rectangular (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Float32, 1));
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (9.0));
      Image.Set_Identity;

      AUnit.Assertions.Assert
        (Image.Rows = 2
         and then Image.Columns = 4
         and then Image.Depth = OpenCV.Core.Float32
         and then OpenCV.Core.Float32_Access.Get (Image, 0, 0) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Image, 0, 1) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Image, 0, 2) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Image, 0, 3) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Image, 1, 0) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Image, 1, 1) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Image, 1, 2) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Image, 1, 3) = 0.0,
         "Set_Identity must accept a wide rectangular Mat and zero every"
         & " off-diagonal element");
   end Set_Identity_Wide_Rectangular;

   procedure Set_Identity_Tall_Rectangular (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 2, (OpenCV.Core.Float32, 1));
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (9.0));
      Image.Set_Identity;

      AUnit.Assertions.Assert
        (Image.Rows = 4
         and then Image.Columns = 2
         and then OpenCV.Core.Float32_Access.Get (Image, 0, 0) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Image, 0, 1) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Image, 1, 0) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Image, 1, 1) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Image, 2, 0) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Image, 2, 1) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Image, 3, 0) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Image, 3, 1) = 0.0,
         "Set_Identity on a tall Mat must use a diagonal of min (rows,"
         & " columns)");
   end Set_Identity_Tall_Rectangular;

   procedure Set_Identity_One_Row_And_One_Column
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Row : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Col : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
   begin
      Row.Set_To (OpenCV.Core.Make_Scalar (9.0));
      Col.Set_To (OpenCV.Core.Make_Scalar (9.0));
      Row.Set_Identity;
      Col.Set_Identity;

      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Row, 0, 0) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Row, 0, 1) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Row, 0, 2) = 0.0,
         "A 1x3 Set_Identity must become [1 0 0]");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Col, 0, 0) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Col, 1, 0) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Col, 2, 0) = 0.0,
         "A 3x1 Set_Identity must become a column [1 0 0]");
   end Set_Identity_One_Row_And_One_Column;

   procedure Set_Identity_Default_Multi_Channel
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 3));
      Zero  : constant OpenCV.Core.Float32_Vec3.Vector := (0.0, 0.0, 0.0);
   begin
      OpenCV.Core.Float32_Vec3_Access.Set (Image, 0, 0, (9.0, 8.0, 7.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Image, 0, 1, (6.0, 5.0, 4.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Image, 1, 0, (3.0, 2.0, 1.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Image, 1, 1, (4.0, 5.0, 6.0));
      Image.Set_Identity;

      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Vec3_Access.Get (Image, 0, 0) = (1.0, 0.0, 0.0)
         and then OpenCV.Core.Float32_Vec3_Access.Get (Image, 1, 1)
                  = (1.0, 0.0, 0.0)
         and then OpenCV.Core.Float32_Vec3_Access.Get (Image, 0, 1) = Zero
         and then OpenCV.Core.Float32_Vec3_Access.Get (Image, 1, 0) = Zero,
         "Default Set_Identity must use Scalar (1, 0, 0), not (1, 1, 1)");
   end Set_Identity_Default_Multi_Channel;

   procedure Set_Identity_Explicit_Multi_Channel
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 3));
      Diagonal : constant OpenCV.Core.Float32_Vec3.Vector := (2.0, 3.0, 4.0);
      Zero     : constant OpenCV.Core.Float32_Vec3.Vector := (0.0, 0.0, 0.0);
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (9.0, 8.0, 7.0));
      Image.Set_Identity
        (OpenCV.Core.Make_Scalar
           (Component_0 => 2.0, Component_1 => 3.0, Component_2 => 4.0));

      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Vec3_Access.Get (Image, 0, 0) = Diagonal
         and then OpenCV.Core.Float32_Vec3_Access.Get (Image, 1, 1) = Diagonal
         and then OpenCV.Core.Float32_Vec3_Access.Get (Image, 0, 1) = Zero
         and then OpenCV.Core.Float32_Vec3_Access.Get (Image, 1, 0) = Zero,
         "An explicit three-component Scalar must appear on every diagonal"
         & " Vec3");
   end Set_Identity_Explicit_Multi_Channel;

   procedure Set_Identity_Four_Channels (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 4));
      Ch0   : OpenCV.Core.Mat;
      Ch1   : OpenCV.Core.Mat;
      Ch2   : OpenCV.Core.Mat;
      Ch3   : OpenCV.Core.Mat;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (9.0, 8.0, 7.0, 6.0));
      Image.Set_Identity (OpenCV.Core.Make_Scalar (2.0, 3.0, 4.0, 5.0));

      AUnit.Assertions.Assert
        (Image.Channels = 4 and then Image.Depth = OpenCV.Core.Float32,
         "Set_Identity must accept a four-channel Mat");

      Ch0 := Image.Extract_Channel (0);
      Ch1 := Image.Extract_Channel (1);
      Ch2 := Image.Extract_Channel (2);
      Ch3 := Image.Extract_Channel (3);

      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Ch0, 0, 0) = 2.0
         and then OpenCV.Core.Float32_Access.Get (Ch1, 0, 0) = 3.0
         and then OpenCV.Core.Float32_Access.Get (Ch2, 0, 0) = 4.0
         and then OpenCV.Core.Float32_Access.Get (Ch3, 0, 0) = 5.0
         and then OpenCV.Core.Float32_Access.Get (Ch0, 1, 1) = 2.0
         and then OpenCV.Core.Float32_Access.Get (Ch0, 0, 1) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Ch3, 1, 0) = 0.0,
         "A four-component Scalar must map onto the four destination"
         & " channels");
   end Set_Identity_Four_Channels;

   procedure Set_Identity_Rejects_Five_Channels
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 5));
      Empty : OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.UInt8, 5));

      procedure Set_Five_Channels is
      begin
         Image.Set_Identity;
      end Set_Five_Channels;

      procedure Set_Empty_Five_Channels is
      begin
         Empty.Set_Identity;
      end Set_Empty_Five_Channels;
   begin
      Assert_Raises_OpenCV_Error
        (Set_Five_Channels'Access,
         "Set_Identity must reject a Mat with more than four channels");
      Assert_Raises_OpenCV_Error
        (Set_Empty_Five_Channels'Access,
         "Set_Identity must reject a typed empty Mat with more than"
         & " four channels");
   end Set_Identity_Rejects_Five_Channels;

   procedure Set_Identity_UInt8 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (9.0));
      Image.Set_Identity (OpenCV.Core.Make_Scalar (7.0));

      AUnit.Assertions.Assert
        (Image.Depth = OpenCV.Core.UInt8
         and then Image.Rows = 2
         and then Image.Columns = 2
         and then OpenCV.Core.UInt8_Access.Get (Image, 0, 0) = 7
         and then OpenCV.Core.UInt8_Access.Get (Image, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Image, 1, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Image, 1, 1) = 7,
         "Set_Identity must support UInt8 and is not floating-point-only");
   end Set_Identity_UInt8;

   procedure Set_Identity_UInt8_Uses_OpenCV_Conversion
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (9.0));
      Image.Set_Identity (OpenCV.Core.Make_Scalar (7.6));

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Image, 0, 0) = 8
         and then OpenCV.Core.UInt8_Access.Get (Image, 1, 1) = 8
         and then OpenCV.Core.UInt8_Access.Get (Image, 0, 1) = 0,
         "Set_Identity must use OpenCV Scalar conversion (7.6 -> 8)");
   end Set_Identity_UInt8_Uses_OpenCV_Conversion;

   procedure Set_Identity_Int32 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int32, 1));
      Inspected : OpenCV.Core.Mat;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Image.Set_Identity (OpenCV.Core.Make_Scalar (7.0));

      AUnit.Assertions.Assert
        (Image.Depth = OpenCV.Core.Int32
         and then Image.Rows = 2
         and then Image.Columns = 2,
         "Set_Identity must preserve Int32 depth and 2x2 shape");

      Inspected := Image.Clone.Convert_To (OpenCV.Core.Float32);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Inspected, 0, 0) = 7.0
         and then OpenCV.Core.Float32_Access.Get (Inspected, 0, 1) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Inspected, 1, 0) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Inspected, 1, 1) = 7.0
         and then Image.Depth = OpenCV.Core.Int32,
         "An Int32 Set_Identity result must keep Int32 storage");
   end Set_Identity_Int32;

   procedure Set_Identity_Float64 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float64, 1));
      Inspected : OpenCV.Core.Mat;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (9.0));
      Image.Set_Identity (OpenCV.Core.Make_Scalar (2.5));

      AUnit.Assertions.Assert
        (Image.Depth = OpenCV.Core.Float64
         and then Image.Rows = 2
         and then Image.Columns = 2,
         "Set_Identity must preserve Float64 depth");

      Inspected := Image.Clone.Convert_To (OpenCV.Core.Float32);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Inspected, 0, 0) = 2.5
         and then OpenCV.Core.Float32_Access.Get (Inspected, 1, 1) = 2.5
         and then OpenCV.Core.Float32_Access.Get (Inspected, 0, 1) = 0.0
         and then Image.Depth = OpenCV.Core.Float64,
         "A Float64 Set_Identity result must keep Float64 storage");
   end Set_Identity_Float64;

   procedure Set_Identity_Float16 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Image     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float16, 1));
      Inspected : OpenCV.Core.Mat;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (9.0));
      Image.Set_Identity (OpenCV.Core.Make_Scalar (2.0));

      AUnit.Assertions.Assert
        (Image.Depth = OpenCV.Core.Float16
         and then Image.Rows = 2
         and then Image.Columns = 2,
         "Set_Identity must accept Float16 and preserve its depth");

      Inspected := Image.Clone.Convert_To (OpenCV.Core.Float32);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Inspected, 0, 0) = 2.0
         and then OpenCV.Core.Float32_Access.Get (Inspected, 1, 1) = 2.0
         and then OpenCV.Core.Float32_Access.Get (Inspected, 0, 1) = 0.0
         and then Image.Depth = OpenCV.Core.Float16,
         "A Float16 Set_Identity result must keep Float16 storage");
   end Set_Identity_Float16;

   procedure Set_Identity_Noncontiguous_Region (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 5, (OpenCV.Core.Float32, 1));
      Region : OpenCV.Core.Mat;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Region := Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));

      AUnit.Assertions.Assert
        (not Region.Is_Continuous and then Region.Is_Submatrix,
         "The Region used for Set_Identity must be non-contiguous");

      Region.Set_Identity;

      AUnit.Assertions.Assert
        (Region.Rows = 2
         and then Region.Columns = 3
         and then OpenCV.Core.Float32_Access.Get (Region, 0, 0) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Region, 0, 1) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Region, 0, 2) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Region, 1, 0) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Region, 1, 1) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Region, 1, 2) = 0.0,
         "Set_Identity must use the Region-local diagonal");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Parent, 1, 1) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 2, 2) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 1, 2) = 0.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 2, 1) = 0.0,
         "Region Set_Identity must mutate the corresponding parent pixels");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 0, 4) = 99.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 3, 4) = 99.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 1, 0) = 99.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 1, 4) = 99.0
         and then OpenCV.Core.Float32_Access.Get (Parent, 3, 1) = 99.0,
         "Pixels outside the Region must remain unchanged");
      AUnit.Assertions.Assert
        (Region.Is_Submatrix and then not Region.Is_Continuous,
         "Set_Identity must not detach a Region into an independent copy");
   end Set_Identity_Noncontiguous_Region;

   procedure Set_Identity_Shallow_Alias (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Original : constant OpenCV.Core.Mat := Nonzero_3x3;
      Alias    : OpenCV.Core.Mat := Original;
   begin
      Alias.Set_Identity;

      AUnit.Assertions.Assert
        (Matches_3x3 (Original, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0)
         and then Matches_3x3
                    (Alias, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0),
         "A shallow Mat alias must observe Set_Identity mutation");
   end Set_Identity_Shallow_Alias;

   procedure Set_Identity_Clone_Remains_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Original : constant OpenCV.Core.Mat := Nonzero_3x3;
      Copy     : OpenCV.Core.Mat := Original.Clone;
   begin
      Copy.Set_Identity;

      AUnit.Assertions.Assert
        (Matches_3x3 (Copy, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0),
         "Clone.Set_Identity must modify the independent copy");
      AUnit.Assertions.Assert
        (Matches_3x3 (Original, 9.0, 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0),
         "Set_Identity on a Clone must leave the original unchanged");
   end Set_Identity_Clone_Remains_Independent;

   procedure Set_Identity_Empty_Behavior (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Default_Image : OpenCV.Core.Mat;
      Empty8        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.UInt8, 1));
      Empty32       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Empty64       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float64, 1));
      Empty16       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float16, 1));
      Empty_Vec3    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 3));
   begin
      Default_Image.Set_Identity;
      Empty8.Set_Identity;
      Empty32.Set_Identity;
      Empty64.Set_Identity;
      Empty16.Set_Identity;
      Empty_Vec3.Set_Identity;

      AUnit.Assertions.Assert
        (Default_Image.Is_Empty
         and then Default_Image.Depth = OpenCV.Core.UInt8
         and then Default_Image.Channels = 1,
         "A default empty Mat must remain an empty UInt8 no-op");
      AUnit.Assertions.Assert
        (Empty8.Is_Empty
         and then Empty8.Depth = OpenCV.Core.UInt8
         and then Empty8.Channels = 1,
         "A typed 0x0 UInt8 Mat must remain empty UInt8");
      AUnit.Assertions.Assert
        (Empty32.Is_Empty
         and then Empty32.Depth = OpenCV.Core.Float32
         and then Empty32.Channels = 1,
         "A typed 0x0 Float32 Mat must remain empty Float32");
      AUnit.Assertions.Assert
        (Empty64.Is_Empty
         and then Empty64.Depth = OpenCV.Core.Float64
         and then Empty64.Channels = 1,
         "A typed 0x0 Float64 Mat must remain empty Float64");
      AUnit.Assertions.Assert
        (Empty16.Is_Empty
         and then Empty16.Depth = OpenCV.Core.Float16
         and then Empty16.Channels = 1,
         "A typed 0x0 Float16 Mat must remain empty Float16");
      AUnit.Assertions.Assert
        (Empty_Vec3.Is_Empty
         and then Empty_Vec3.Depth = OpenCV.Core.Float32
         and then Empty_Vec3.Channels = 3,
         "A typed 0x0 three-channel Mat must remain empty Float32 Vec3");
   end Set_Identity_Empty_Behavior;

   function Linear_C3_Coefficients return OpenCV.Core.Mat is
      Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 2, 3.0);
      return Coefficients;
   end Linear_C3_Coefficients;

   procedure Transform_Float32_C3_To_C1_Linear (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 3));
      Coefficients : constant OpenCV.Core.Mat := Linear_C3_Coefficients;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set (Source, 0, 0, (1.0, 2.0, 3.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Source, 0, 1, (4.0, 5.0, 6.0));

      declare
         Result : constant OpenCV.Core.Mat := Source.Transform (Coefficients);
      begin
         AUnit.Assertions.Assert
           (Result.Rows = 1
            and then Result.Columns = 2
            and then Result.Depth = OpenCV.Core.Float32
            and then Result.Channels = 1
            and then OpenCV.Core.Float32_Access.Get (Result, 0, 0) = 14.0
            and then OpenCV.Core.Float32_Access.Get (Result, 0, 1) = 32.0,
            "Transform must map Float32 C3 to C1 with a 1x3 linear matrix");
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Vec3_Access.Get (Source, 0, 0)
            = (1.0, 2.0, 3.0)
            and then OpenCV.Core.Float32_Vec3_Access.Get (Source, 0, 1)
                     = (4.0, 5.0, 6.0),
            "Transform must leave the C3 source unchanged");
      end;
   end Transform_Float32_C3_To_C1_Linear;

   procedure Transform_Float32_C3_To_C2_Affine (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 3));
      Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Vec3_Access.Set (Source, 0, 0, (1.0, 2.0, 3.0));
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 2, 0.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 3, 10.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 1, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 1, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 1, 2, 0.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 1, 3, 20.0);

      declare
         Result   : constant OpenCV.Core.Mat :=
           Source.Transform (Coefficients);
         Channels : constant OpenCV.Core.Mat_Array := Result.Split;
      begin
         AUnit.Assertions.Assert
           (Result.Rows = 1
            and then Result.Columns = 1
            and then Result.Depth = OpenCV.Core.Float32
            and then Result.Channels = 2
            and then Channels'Length = 2
            and then OpenCV.Core.Float32_Access.Get (Channels (0), 0, 0) = 11.0
            and then OpenCV.Core.Float32_Access.Get (Channels (1), 0, 0)
                     = 22.0,
            "Transform must apply a C3 to C2 affine matrix including bias");
      end;
   end Transform_Float32_C3_To_C2_Affine;

   procedure Transform_C3_Channel_Permutation (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 3));
      Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Vec3_Access.Set (Source, 0, 0, (1.0, 2.0, 3.0));
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 1, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 1, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 1, 2, 0.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 2, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 2, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 2, 2, 0.0);

      declare
         Result : constant OpenCV.Core.Mat := Source.Transform (Coefficients);
      begin
         AUnit.Assertions.Assert
           (Result.Channels = 3
            and then OpenCV.Core.Float32_Vec3_Access.Get (Result, 0, 0)
                     = (3.0, 2.0, 1.0),
            "Transform must permute C3 channels with a 3x3 linear matrix");
      end;
   end Transform_C3_Channel_Permutation;

   procedure Transform_Single_Channel_Affine_Fast_Path
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 1, 3.0);

      declare
         Result : constant OpenCV.Core.Mat := Source.Transform (Coefficients);
      begin
         AUnit.Assertions.Assert
           (Result.Rows = 1
            and then Result.Columns = 3
            and then Result.Channels = 1
            and then OpenCV.Core.Float32_Access.Get (Result, 0, 0) = 5.0
            and then OpenCV.Core.Float32_Access.Get (Result, 0, 1) = 7.0
            and then OpenCV.Core.Float32_Access.Get (Result, 0, 2) = 9.0,
            "Transform must apply a C1 affine scale-and-bias convertTo path");
      end;
   end Transform_Single_Channel_Affine_Fast_Path;

   procedure Transform_UInt8_Saturates (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      High              : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Low               : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      High_Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Low_Coefficients  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (High, 0, 0, 200);
      OpenCV.Core.UInt8_Access.Set (Low, 0, 0, 10);
      OpenCV.Core.Float32_Access.Set (High_Coefficients, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (High_Coefficients, 0, 1, 100.0);
      OpenCV.Core.Float32_Access.Set (Low_Coefficients, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Low_Coefficients, 0, 1, -20.0);

      declare
         High_Result : constant OpenCV.Core.Mat :=
           High.Transform (High_Coefficients);
         Low_Result  : constant OpenCV.Core.Mat :=
           Low.Transform (Low_Coefficients);
      begin
         AUnit.Assertions.Assert
           (High_Result.Depth = OpenCV.Core.UInt8
            and then OpenCV.Core.UInt8_Access.Get (High_Result, 0, 0) = 255
            and then OpenCV.Core.UInt8_Access.Get (Low_Result, 0, 0) = 0,
            "Transform must use OpenCV UInt8 saturation rather than wrapping");
      end;
   end Transform_UInt8_Saturates;

   procedure Transform_Int32_Uses_Float64_Coefficient_Path
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 6);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 1, 1.0);

      declare
         Int32_Source : constant OpenCV.Core.Mat :=
           Source.Convert_To (OpenCV.Core.Int32);
         Result       : constant OpenCV.Core.Mat :=
           Int32_Source.Transform (Coefficients);
         As_UInt8     : constant OpenCV.Core.Mat :=
           Result.Convert_To (OpenCV.Core.UInt8);
      begin
         AUnit.Assertions.Assert
           (Result.Depth = OpenCV.Core.Int32
            and then Result.Channels = 1
            and then OpenCV.Core.UInt8_Access.Get (As_UInt8, 0, 0) = 13,
            "Transform of Int32 must keep Int32 and apply Float32"
            & " coefficients");
      end;
   end Transform_Int32_Uses_Float64_Coefficient_Path;

   procedure Transform_Float64_Preserves_Depth (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source               : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Float32_Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Float32_Coefficients, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Float32_Coefficients, 0, 1, 3.0);

      declare
         Float64_Source : constant OpenCV.Core.Mat :=
           Source.Convert_To (OpenCV.Core.Float64);
         Result         : constant OpenCV.Core.Mat :=
           Float64_Source.Transform (Float32_Coefficients);
         Inspection     : constant OpenCV.Core.Mat :=
           Result.Convert_To (OpenCV.Core.Float32);
      begin
         AUnit.Assertions.Assert
           (Result.Depth = OpenCV.Core.Float64
            and then Result.Channels = 1
            and then Result.Rows = 1
            and then Result.Columns = 2
            and then OpenCV.Core.Float32_Access.Get (Inspection, 0, 0) = 5.0
            and then OpenCV.Core.Float32_Access.Get (Inspection, 0, 1) = 7.0,
            "Transform of Float64 must keep Float64 and apply affine bias");
      end;
   end Transform_Float64_Preserves_Depth;

   procedure Transform_Remaining_Supported_Depths
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));

      function Affine_Result (Depth : OpenCV.Core.Depth_Type) return Boolean is
         Converted : constant OpenCV.Core.Mat := Source.Convert_To (Depth);
         Result    : constant OpenCV.Core.Mat :=
           Converted.Transform (Coefficients);
         As_UInt8  : constant OpenCV.Core.Mat :=
           Result.Convert_To (OpenCV.Core.UInt8);
      begin
         return
           Result.Depth = Depth
           and then Result.Channels = 1
           and then OpenCV.Core.UInt8_Access.Get (As_UInt8, 0, 0) = 7;
      end Affine_Result;
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 2);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 1, 3.0);

      AUnit.Assertions.Assert
        (Affine_Result (OpenCV.Core.Int8)
         and then Affine_Result (OpenCV.Core.UInt16)
         and then Affine_Result (OpenCV.Core.Int16),
         "Transform must reach the Int8, UInt16, and Int16 OpenCV kernels");
   end Transform_Remaining_Supported_Depths;

   procedure Transform_Rejects_Float16 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float16, 1));
      Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));

      procedure Transform_Float16 is
         Ignored : OpenCV.Core.Mat;
      begin
         OpenCV.Core.Float32_Access.Set (Coefficients, 0, 0, 1.0);
         Ignored := Source.Transform (Coefficients);
      end Transform_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Transform_Float16'Access, "Transform must reject Float16 source");
   end Transform_Rejects_Float16;

   procedure Transform_Float64_Coefficients_With_Float32_Self
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 0, 2.0);

      declare
         Float64_Coefficients : constant OpenCV.Core.Mat :=
           Coefficients.Convert_To (OpenCV.Core.Float64);
         Result               : constant OpenCV.Core.Mat :=
           Source.Transform (Float64_Coefficients);
      begin
         AUnit.Assertions.Assert
           (Float64_Coefficients.Depth = OpenCV.Core.Float64
            and then Result.Depth = OpenCV.Core.Float32
            and then Result.Channels = 1
            and then OpenCV.Core.Float32_Access.Get (Result, 0, 0) = 8.0,
            "Float64 coefficients with Float32 Self must stay Float64 and"
            & " yield a Float32 result");
      end;
   end Transform_Float64_Coefficients_With_Float32_Self;

   procedure Transform_Noncontiguous_Source_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Float32, 3));
      Coefficients : constant OpenCV.Core.Mat := Linear_C3_Coefficients;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set (Parent, 0, 0, (9.0, 9.0, 9.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Parent, 0, 1, (1.0, 2.0, 3.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Parent, 0, 2, (4.0, 5.0, 6.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Parent, 0, 3, (8.0, 8.0, 8.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Parent, 1, 0, (7.0, 7.0, 7.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Parent, 1, 1, (1.0, 0.0, 0.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Parent, 1, 2, (0.0, 1.0, 0.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Parent, 1, 3, (6.0, 6.0, 6.0));

      declare
         Region : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
         Result : constant OpenCV.Core.Mat := Region.Transform (Coefficients);
      begin
         AUnit.Assertions.Assert
           (not Region.Is_Continuous
            and then Result.Rows = 2
            and then Result.Columns = 2
            and then Result.Channels = 1
            and then OpenCV.Core.Float32_Access.Get (Result, 0, 0) = 14.0
            and then OpenCV.Core.Float32_Access.Get (Result, 0, 1) = 32.0
            and then OpenCV.Core.Float32_Access.Get (Result, 1, 0) = 1.0
            and then OpenCV.Core.Float32_Access.Get (Result, 1, 1) = 2.0,
            "Transform must accept a non-contiguous C3 Region");
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Vec3_Access.Get (Parent, 0, 0)
            = (9.0, 9.0, 9.0)
            and then OpenCV.Core.Float32_Vec3_Access.Get (Parent, 0, 3)
                     = (8.0, 8.0, 8.0)
            and then OpenCV.Core.Float32_Vec3_Access.Get (Region, 0, 0)
                     = (1.0, 2.0, 3.0),
            "Transform must leave the Region and parent pixels unchanged");
      end;
   end Transform_Noncontiguous_Source_Region;

   procedure Transform_Noncontiguous_Coefficients_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 3));
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 6, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Vec3_Access.Set (Source, 0, 0, (1.0, 2.0, 3.0));
      Parent.Set_To (OpenCV.Core.Make_Scalar (9.0));
      OpenCV.Core.Float32_Access.Set (Parent, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Parent, 0, 2, 0.0);
      OpenCV.Core.Float32_Access.Set (Parent, 0, 3, 0.0);
      OpenCV.Core.Float32_Access.Set (Parent, 0, 4, 10.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 3, 0.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 4, 20.0);

      declare
         Coefficients : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 4, Height => 2));
         Result       : constant OpenCV.Core.Mat :=
           Source.Transform (Coefficients);
         Channels     : constant OpenCV.Core.Mat_Array := Result.Split;
      begin
         AUnit.Assertions.Assert
           (not Coefficients.Is_Continuous
            and then Coefficients.Rows = 2
            and then Coefficients.Columns = 4
            and then Result.Channels = 2
            and then OpenCV.Core.Float32_Access.Get (Channels (0), 0, 0) = 11.0
            and then OpenCV.Core.Float32_Access.Get (Channels (1), 0, 0)
                     = 22.0,
            "Transform must accept a non-contiguous coefficient Region");
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 9.0
            and then OpenCV.Core.Float32_Access.Get (Coefficients, 0, 0) = 1.0
            and then OpenCV.Core.Float32_Access.Get (Coefficients, 1, 3)
                     = 20.0,
            "Transform must leave the coefficient Region and parent"
            & " unchanged");
      end;
   end Transform_Noncontiguous_Coefficients_Region;

   procedure Transform_Result_Is_Independent (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 3));
      Coefficients : OpenCV.Core.Mat := Linear_C3_Coefficients;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set (Source, 0, 0, (1.0, 2.0, 3.0));

      declare
         Result : OpenCV.Core.Mat := Source.Transform (Coefficients);
      begin
         OpenCV.Core.Float32_Vec3_Access.Set (Source, 0, 0, (9.0, 9.0, 9.0));
         OpenCV.Core.Float32_Access.Set (Coefficients, 0, 0, 0.0);
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Access.Get (Result, 0, 0) = 14.0,
            "Mutating Self or Coefficients must not change Result");

         OpenCV.Core.Float32_Access.Set (Result, 0, 0, -1.0);
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Vec3_Access.Get (Source, 0, 0)
            = (9.0, 9.0, 9.0)
            and then OpenCV.Core.Float32_Access.Get (Coefficients, 0, 1) = 2.0,
            "Mutating Result must not change Self or Coefficients");
      end;
   end Transform_Result_Is_Independent;

   procedure Transform_Linear_Matches_Zero_Bias_Affine
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 3));
      Linear : constant OpenCV.Core.Mat := Linear_C3_Coefficients;
      Affine : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Vec3_Access.Set (Source, 0, 0, (1.0, 2.0, 3.0));
      OpenCV.Core.Float32_Access.Set (Affine, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Affine, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Affine, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Affine, 0, 3, 0.0);

      declare
         Linear_Result : constant OpenCV.Core.Mat := Source.Transform (Linear);
         Affine_Result : constant OpenCV.Core.Mat := Source.Transform (Affine);
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Access.Get (Linear_Result, 0, 0) = 14.0
            and then OpenCV.Core.Float32_Access.Get (Affine_Result, 0, 0)
                     = 14.0,
            "Linear coefficients must match affine coefficients with"
            & " zero bias");
      end;
   end Transform_Linear_Matches_Zero_Bias_Affine;

   procedure Transform_More_Than_Four_Output_Channels
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (5, 1, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 1, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 2, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 3, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Coefficients, 4, 0, 5.0);

      declare
         Result   : constant OpenCV.Core.Mat :=
           Source.Transform (Coefficients);
         Channels : constant OpenCV.Core.Mat_Array := Result.Split;
      begin
         AUnit.Assertions.Assert
           (Result.Channels = 5
            and then Channels'Length = 5
            and then OpenCV.Core.Float32_Access.Get (Channels (0), 0, 0) = 2.0
            and then OpenCV.Core.Float32_Access.Get (Channels (1), 0, 0) = 4.0
            and then OpenCV.Core.Float32_Access.Get (Channels (2), 0, 0) = 6.0
            and then OpenCV.Core.Float32_Access.Get (Channels (3), 0, 0) = 8.0
            and then OpenCV.Core.Float32_Access.Get (Channels (4), 0, 0)
                     = 10.0,
            "Transform output channels must follow Coefficients.Rows past 4");
      end;
   end Transform_More_Than_Four_Output_Channels;

   procedure Transform_Rejects_Five_Source_Channels
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 5));
      Coefficients : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 5, (OpenCV.Core.Float32, 1));

      procedure Transform_C5 is
         Ignored : OpenCV.Core.Mat;
      begin
         OpenCV.Core.Float32_Access.Set (Coefficients, 0, 0, 1.0);
         Ignored := Source.Transform (Coefficients);
      end Transform_C5;
   begin
      Assert_Raises_OpenCV_Error
        (Transform_C5'Access, "Transform must reject a five-channel source");
   end Transform_Rejects_Five_Source_Channels;

   procedure Transform_Rejects_Invalid_Coefficient_Columns
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 3));
      Too_Few  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Too_Many : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 5, (OpenCV.Core.Float32, 1));

      procedure Transform_Two_Columns is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Transform (Too_Few);
      end Transform_Two_Columns;

      procedure Transform_Five_Columns is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Transform (Too_Many);
      end Transform_Five_Columns;
   begin
      Assert_Raises_OpenCV_Error
        (Transform_Two_Columns'Access,
         "Transform must reject C3 coefficients with 2 columns");
      Assert_Raises_OpenCV_Error
        (Transform_Five_Columns'Access,
         "Transform must reject C3 coefficients with 5 columns");
   end Transform_Rejects_Invalid_Coefficient_Columns;

   procedure Transform_Rejects_Multi_Channel_Coefficients
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Coefficients : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 2));

      procedure Transform_C2_Coefficients is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Transform (Coefficients);
      end Transform_C2_Coefficients;
   begin
      Assert_Raises_OpenCV_Error
        (Transform_C2_Coefficients'Access,
         "Transform must reject multi-channel coefficients");
   end Transform_Rejects_Multi_Channel_Coefficients;

   procedure Transform_Rejects_Integer_Coefficients
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Coefficients : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int32, 1));

      procedure Transform_Int32_Coefficients is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Transform (Coefficients);
      end Transform_Int32_Coefficients;
   begin
      Assert_Raises_OpenCV_Error
        (Transform_Int32_Coefficients'Access,
         "Transform must reject Int32 coefficients");
   end Transform_Rejects_Integer_Coefficients;

   procedure Transform_Rejects_Excess_Output_Channels
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Coefficients : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (513, 1, (OpenCV.Core.Float32, 1));

      procedure Transform_513_Rows is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Transform (Coefficients);
      end Transform_513_Rows;
   begin
      Assert_Raises_OpenCV_Error
        (Transform_513_Rows'Access,
         "Transform must reject more than 512 coefficient rows");
   end Transform_Rejects_Excess_Output_Channels;

   procedure Transform_Rejects_Empty_Inputs (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Default_Source       : OpenCV.Core.Mat;
      Empty_Source         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Valid_Source         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Default_Coefficients : OpenCV.Core.Mat;
      Empty_Coefficients   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Valid_Coefficients   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));

      procedure Transform_Default_Source is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Default_Source.Transform (Valid_Coefficients);
      end Transform_Default_Source;

      procedure Transform_Empty_Source is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Empty_Source.Transform (Valid_Coefficients);
      end Transform_Empty_Source;

      procedure Transform_Default_Coefficients is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Valid_Source.Transform (Default_Coefficients);
      end Transform_Default_Coefficients;

      procedure Transform_Empty_Coefficients is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Valid_Source.Transform (Empty_Coefficients);
      end Transform_Empty_Coefficients;
   begin
      OpenCV.Core.Float32_Access.Set (Valid_Coefficients, 0, 0, 1.0);
      Assert_Raises_OpenCV_Error
        (Transform_Default_Source'Access,
         "Transform must reject a default empty source");
      Assert_Raises_OpenCV_Error
        (Transform_Empty_Source'Access,
         "Transform must reject a typed 0x0 Float32 source");
      Assert_Raises_OpenCV_Error
        (Transform_Default_Coefficients'Access,
         "Transform must reject default empty coefficients");
      Assert_Raises_OpenCV_Error
        (Transform_Empty_Coefficients'Access,
         "Transform must reject typed 0x0 Float32 coefficients");
   end Transform_Rejects_Empty_Inputs;

   function Merge_Float32_C2 (Xs, Ys : OpenCV.Core.Mat) return OpenCV.Core.Mat
   is (OpenCV.Core.Merge ((0 => Xs, 1 => Ys)));

   function C2_Component
     (Image : OpenCV.Core.Mat; Channel, Row, Column : Natural)
      return Interfaces.IEEE_Float_32
   is
      Channels : constant OpenCV.Core.Mat_Array := Image.Split;
   begin
      return OpenCV.Core.Float32_Access.Get (Channels (Channel), Row, Column);
   end C2_Component;

   function Genuine_C2_Matrix return OpenCV.Core.Mat is
      Matrix : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Matrix, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Matrix, 0, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Matrix, 0, 2, 10.0);
      OpenCV.Core.Float32_Access.Set (Matrix, 1, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Matrix, 1, 1, 3.0);
      OpenCV.Core.Float32_Access.Set (Matrix, 1, 2, 20.0);
      OpenCV.Core.Float32_Access.Set (Matrix, 2, 0, 0.5);
      OpenCV.Core.Float32_Access.Set (Matrix, 2, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Matrix, 2, 2, 1.0);
      return Matrix;
   end Genuine_C2_Matrix;

   function Identity_3x3 return OpenCV.Core.Mat is
      Matrix : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
   begin
      Matrix.Set_Identity;
      return Matrix;
   end Identity_3x3;

   function Two_Point_C2_Source return OpenCV.Core.Mat is
      Xs : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Ys : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Xs, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Ys, 0, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Xs, 0, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Ys, 0, 1, 0.0);
      return Merge_Float32_C2 (Xs, Ys);
   end Two_Point_C2_Source;

   procedure Perspective_Transform_Float32_C2_Genuine
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat := Two_Point_C2_Source;
      Matrix : constant OpenCV.Core.Mat := Genuine_C2_Matrix;
   begin
      declare
         Result   : constant OpenCV.Core.Mat :=
           Source.Perspective_Transform (Matrix);
         Channels : constant OpenCV.Core.Mat_Array := Result.Split;
      begin
         AUnit.Assertions.Assert
           (Source.Depth = OpenCV.Core.Float32
            and then Source.Channels = 2
            and then Result.Rows = Source.Rows
            and then Result.Columns = Source.Columns
            and then Result.Depth = OpenCV.Core.Float32
            and then Result.Channels = 2
            and then OpenCV.Core.Float32_Access.Get (Channels (0), 0, 0) = 7.0
            and then OpenCV.Core.Float32_Access.Get (Channels (1), 0, 0) = 16.0
            and then OpenCV.Core.Float32_Access.Get (Channels (0), 0, 1) = 10.0
            and then OpenCV.Core.Float32_Access.Get (Channels (1), 0, 1)
                     = 20.0,
            "Perspective_Transform must apply a genuine Float32 C2 3x3"
            & " perspective mapping");
         AUnit.Assertions.Assert
           (C2_Component (Source, 0, 0, 0) = 2.0
            and then C2_Component (Source, 1, 0, 0) = 4.0
            and then C2_Component (Source, 0, 0, 1) = 0.0
            and then C2_Component (Source, 1, 0, 1) = 0.0
            and then OpenCV.Core.Float32_Access.Get (Matrix, 0, 0) = 2.0
            and then OpenCV.Core.Float32_Access.Get (Matrix, 2, 2) = 1.0,
            "Perspective_Transform must leave the C2 source and 3x3 matrix"
            & " unchanged");
      end;
   end Perspective_Transform_Float32_C2_Genuine;

   procedure Perspective_Transform_C2_Identity (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat := Two_Point_C2_Source;
      Matrix : constant OpenCV.Core.Mat := Identity_3x3;
      Result : constant OpenCV.Core.Mat :=
        Source.Perspective_Transform (Matrix);
   begin
      AUnit.Assertions.Assert
        (Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 2
         and then C2_Component (Result, 0, 0, 0) = 2.0
         and then C2_Component (Result, 1, 0, 0) = 4.0
         and then C2_Component (Result, 0, 0, 1) = 0.0
         and then C2_Component (Result, 1, 0, 1) = 0.0,
         "A 3x3 identity matrix must leave representative C2 points"
         & " unchanged");
   end Perspective_Transform_C2_Identity;

   procedure Perspective_Transform_Float32_C3_4x4
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 3));
      Matrix : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Vec3_Access.Set (Source, 0, 0, (2.0, 4.0, 1.0));
      Matrix.Set_Identity;
      OpenCV.Core.Float32_Access.Set (Matrix, 3, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Matrix, 3, 3, 1.0);

      declare
         Result : constant OpenCV.Core.Mat :=
           Source.Perspective_Transform (Matrix);
      begin
         AUnit.Assertions.Assert
           (Result.Rows = 1
            and then Result.Columns = 1
            and then Result.Depth = OpenCV.Core.Float32
            and then Result.Channels = 3
            and then OpenCV.Core.Float32_Vec3_Access.Get (Result, 0, 0)
                     = (1.0, 2.0, 0.5),
            "Perspective_Transform must apply a Float32 C3 4x4 perspective"
            & " division");
      end;
   end Perspective_Transform_Float32_C3_4x4;

   procedure Perspective_Transform_Float64_Source
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source     : constant OpenCV.Core.Mat :=
        Two_Point_C2_Source.Convert_To (OpenCV.Core.Float64);
      Matrix     : constant OpenCV.Core.Mat := Genuine_C2_Matrix;
      Result     : constant OpenCV.Core.Mat :=
        Source.Perspective_Transform (Matrix);
      Inspection : constant OpenCV.Core.Mat :=
        Result.Convert_To (OpenCV.Core.Float32);
   begin
      AUnit.Assertions.Assert
        (Source.Depth = OpenCV.Core.Float64
         and then Result.Depth = OpenCV.Core.Float64
         and then Result.Channels = 2
         and then Result.Rows = Source.Rows
         and then Result.Columns = Source.Columns
         and then C2_Component (Inspection, 0, 0, 0) = 7.0
         and then C2_Component (Inspection, 1, 0, 0) = 16.0
         and then C2_Component (Inspection, 0, 0, 1) = 10.0
         and then C2_Component (Inspection, 1, 0, 1) = 20.0,
         "Perspective_Transform of Float64 C2 must keep Float64 and the"
         & " expected values");
   end Perspective_Transform_Float64_Source;

   procedure Perspective_Transform_Float32_Matrix_With_Float64_Source
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source     : constant OpenCV.Core.Mat :=
        Two_Point_C2_Source.Convert_To (OpenCV.Core.Float64);
      Matrix     : constant OpenCV.Core.Mat := Genuine_C2_Matrix;
      Result     : constant OpenCV.Core.Mat :=
        Source.Perspective_Transform (Matrix);
      Inspection : constant OpenCV.Core.Mat :=
        Result.Convert_To (OpenCV.Core.Float32);
   begin
      AUnit.Assertions.Assert
        (Matrix.Depth = OpenCV.Core.Float32
         and then Result.Depth = OpenCV.Core.Float64
         and then C2_Component (Inspection, 0, 0, 0) = 7.0
         and then C2_Component (Inspection, 1, 0, 0) = 16.0,
         "A Float32 matrix with Float64 Self must stay Float32 and yield"
         & " a Float64 result");
   end Perspective_Transform_Float32_Matrix_With_Float64_Source;

   procedure Perspective_Transform_Float64_Matrix_With_Float32_Source
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat := Two_Point_C2_Source;
      Matrix : constant OpenCV.Core.Mat :=
        Genuine_C2_Matrix.Convert_To (OpenCV.Core.Float64);
      Result : constant OpenCV.Core.Mat :=
        Source.Perspective_Transform (Matrix);
   begin
      AUnit.Assertions.Assert
        (Matrix.Depth = OpenCV.Core.Float64
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 2
         and then C2_Component (Result, 0, 0, 0) = 7.0
         and then C2_Component (Result, 1, 0, 0) = 16.0
         and then C2_Component (Result, 0, 0, 1) = 10.0
         and then C2_Component (Result, 1, 0, 1) = 20.0,
         "A Float64 matrix with Float32 Self must stay Float64 and yield"
         & " a Float32 result");
   end Perspective_Transform_Float64_Matrix_With_Float32_Source;

   procedure Perspective_Transform_Zero_Denominator
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat := Two_Point_C2_Source;
      Matrix : OpenCV.Core.Mat := Identity_3x3;
   begin
      OpenCV.Core.Float32_Access.Set (Matrix, 2, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Matrix, 2, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Matrix, 2, 2, 0.0);

      declare
         Result : constant OpenCV.Core.Mat :=
           Source.Perspective_Transform (Matrix);
      begin
         AUnit.Assertions.Assert
           (C2_Component (Result, 0, 0, 0) = 0.0
            and then C2_Component (Result, 1, 0, 0) = 0.0
            and then C2_Component (Result, 0, 0, 1) = 0.0
            and then C2_Component (Result, 1, 0, 1) = 0.0,
            "A zero homogeneous denominator must write a zero C2 vector,"
            & " not Inf or NaN");
      end;
   end Perspective_Transform_Zero_Denominator;

   procedure Perspective_Transform_Near_Zero_Denominator
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Xs     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Ys     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Matrix : OpenCV.Core.Mat := Identity_3x3;
   begin
      OpenCV.Core.Float32_Access.Set (Xs, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Ys, 0, 0, 0.0);
      OpenCV.Core.Float32_Access.Set
        (Matrix, 2, 0, Interfaces.IEEE_Float_32'Model_Epsilon);
      OpenCV.Core.Float32_Access.Set (Matrix, 2, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Matrix, 2, 2, 0.0);

      declare
         Source     : constant OpenCV.Core.Mat :=
           Merge_Float32_C2 (Xs, Ys).Convert_To (OpenCV.Core.Float64);
         Result     : constant OpenCV.Core.Mat :=
           Source.Perspective_Transform (Matrix);
         Inspection : constant OpenCV.Core.Mat :=
           Result.Convert_To (OpenCV.Core.Float32);
      begin
         AUnit.Assertions.Assert
           (Source.Depth = OpenCV.Core.Float64
            and then Result.Depth = OpenCV.Core.Float64
            and then C2_Component (Inspection, 0, 0, 0) = 0.0
            and then C2_Component (Inspection, 1, 0, 0) = 0.0,
            "abs(w) = FLT_EPSILON must write a zero vector even for a"
            & " Float64 source");
      end;
   end Perspective_Transform_Near_Zero_Denominator;

   procedure Perspective_Transform_Negative_Denominator
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Xs     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Ys     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Matrix : OpenCV.Core.Mat := Identity_3x3;
   begin
      OpenCV.Core.Float32_Access.Set (Xs, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Ys, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Matrix, 2, 0, -1.0);
      OpenCV.Core.Float32_Access.Set (Matrix, 2, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Matrix, 2, 2, 0.0);

      declare
         Result : constant OpenCV.Core.Mat :=
           Merge_Float32_C2 (Xs, Ys).Perspective_Transform (Matrix);
      begin
         AUnit.Assertions.Assert
           (C2_Component (Result, 0, 0, 0) = -1.0
            and then C2_Component (Result, 1, 0, 0) = -2.0,
            "A negative homogeneous denominator above FLT_EPSILON must"
            & " still divide and keep the sign");
      end;
   end Perspective_Transform_Negative_Denominator;

   procedure Perspective_Transform_Noncontiguous_Source_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Xs     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Float32, 1));
      Ys     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Float32, 1));
      Matrix : constant OpenCV.Core.Mat := Genuine_C2_Matrix;
   begin
      Xs.Set_To (OpenCV.Core.Make_Scalar (9.0));
      Ys.Set_To (OpenCV.Core.Make_Scalar (8.0));
      OpenCV.Core.Float32_Access.Set (Xs, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Ys, 0, 1, 4.0);
      OpenCV.Core.Float32_Access.Set (Xs, 0, 2, 0.0);
      OpenCV.Core.Float32_Access.Set (Ys, 0, 2, 0.0);
      OpenCV.Core.Float32_Access.Set (Xs, 1, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Ys, 1, 1, 4.0);
      OpenCV.Core.Float32_Access.Set (Xs, 1, 2, 0.0);
      OpenCV.Core.Float32_Access.Set (Ys, 1, 2, 0.0);

      declare
         Parent : constant OpenCV.Core.Mat := Merge_Float32_C2 (Xs, Ys);
         Region : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
         Result : constant OpenCV.Core.Mat :=
           Region.Perspective_Transform (Matrix);
      begin
         AUnit.Assertions.Assert
           (not Region.Is_Continuous
            and then Result.Rows = 2
            and then Result.Columns = 2
            and then Result.Channels = 2
            and then C2_Component (Result, 0, 0, 0) = 7.0
            and then C2_Component (Result, 1, 0, 0) = 16.0
            and then C2_Component (Result, 0, 0, 1) = 10.0
            and then C2_Component (Result, 1, 0, 1) = 20.0
            and then C2_Component (Result, 0, 1, 0) = 7.0
            and then C2_Component (Result, 1, 1, 0) = 16.0,
            "Perspective_Transform must accept a non-contiguous C2 Region");
         AUnit.Assertions.Assert
           (C2_Component (Parent, 0, 0, 0) = 9.0
            and then C2_Component (Parent, 1, 0, 0) = 8.0
            and then C2_Component (Parent, 0, 0, 3) = 9.0
            and then C2_Component (Region, 0, 0, 0) = 2.0
            and then C2_Component (Region, 1, 0, 0) = 4.0,
            "Perspective_Transform must leave the Region and parent pixels"
            & " unchanged");
      end;
   end Perspective_Transform_Noncontiguous_Source_Region;

   procedure Perspective_Transform_Noncontiguous_Matrix_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat := Two_Point_C2_Source;
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 5, (OpenCV.Core.Float32, 1));
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (9.0));
      OpenCV.Core.Float32_Access.Set (Parent, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Parent, 0, 2, 0.0);
      OpenCV.Core.Float32_Access.Set (Parent, 0, 3, 10.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 3, 20.0);
      OpenCV.Core.Float32_Access.Set (Parent, 2, 1, 0.5);
      OpenCV.Core.Float32_Access.Set (Parent, 2, 2, 0.0);
      OpenCV.Core.Float32_Access.Set (Parent, 2, 3, 1.0);

      declare
         Matrix : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 3, Height => 3));
         Result : constant OpenCV.Core.Mat :=
           Source.Perspective_Transform (Matrix);
      begin
         AUnit.Assertions.Assert
           (not Matrix.Is_Continuous
            and then Matrix.Rows = 3
            and then Matrix.Columns = 3
            and then C2_Component (Result, 0, 0, 0) = 7.0
            and then C2_Component (Result, 1, 0, 0) = 16.0
            and then C2_Component (Result, 0, 0, 1) = 10.0
            and then C2_Component (Result, 1, 0, 1) = 20.0,
            "Perspective_Transform must accept a non-contiguous 3x3 matrix"
            & " Region");
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 9.0
            and then OpenCV.Core.Float32_Access.Get (Matrix, 0, 0) = 2.0
            and then OpenCV.Core.Float32_Access.Get (Matrix, 2, 2) = 1.0,
            "Perspective_Transform must leave the matrix Region and parent"
            & " unchanged");
      end;
   end Perspective_Transform_Noncontiguous_Matrix_Region;

   procedure Perspective_Transform_Result_Is_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat := Two_Point_C2_Source;
      Matrix : OpenCV.Core.Mat := Genuine_C2_Matrix;
      Result : OpenCV.Core.Mat := Source.Perspective_Transform (Matrix);
   begin
      Source.Set_To (OpenCV.Core.Make_Scalar (9.0, 8.0));
      OpenCV.Core.Float32_Access.Set (Matrix, 0, 0, 0.0);
      AUnit.Assertions.Assert
        (C2_Component (Result, 0, 0, 0) = 7.0
         and then C2_Component (Result, 1, 0, 0) = 16.0
         and then C2_Component (Result, 0, 0, 1) = 10.0,
         "Mutating Self or Transform_Matrix must not change Result");

      Result.Set_To (OpenCV.Core.Make_Scalar (-1.0, -2.0));
      AUnit.Assertions.Assert
        (C2_Component (Source, 0, 0, 0) = 9.0
         and then C2_Component (Source, 1, 0, 0) = 8.0
         and then OpenCV.Core.Float32_Access.Get (Matrix, 0, 2) = 10.0,
         "Mutating Result must not change Self or Transform_Matrix");
   end Perspective_Transform_Result_Is_Independent;

   procedure Perspective_Transform_Rejects_Invalid_Source_Depth
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Matrix : constant OpenCV.Core.Mat := Identity_3x3;

      procedure Transform_UInt8 is
         Source  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 2));
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Perspective_Transform (Matrix);
      end Transform_UInt8;

      procedure Transform_Int32 is
         Source  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.Int32, 2));
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Perspective_Transform (Matrix);
      end Transform_Int32;

      procedure Transform_Float16 is
         Source  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.Float16, 2));
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Perspective_Transform (Matrix);
      end Transform_Float16;
   begin
      Assert_Raises_OpenCV_Error
        (Transform_UInt8'Access,
         "Perspective_Transform must reject a UInt8 source");
      Assert_Raises_OpenCV_Error
        (Transform_Int32'Access,
         "Perspective_Transform must reject an Int32 source");
      Assert_Raises_OpenCV_Error
        (Transform_Float16'Access,
         "Perspective_Transform must reject a Float16 source");
   end Perspective_Transform_Rejects_Invalid_Source_Depth;

   procedure Perspective_Transform_Rejects_Invalid_Source_Channels
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Matrix : constant OpenCV.Core.Mat := Identity_3x3;

      procedure Transform_C1 is
         Source  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Perspective_Transform (Matrix);
      end Transform_C1;

      procedure Transform_C4 is
         Source  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 4));
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Perspective_Transform (Matrix);
      end Transform_C4;
   begin
      Assert_Raises_OpenCV_Error
        (Transform_C1'Access,
         "Perspective_Transform must reject a Float32 C1 source");
      Assert_Raises_OpenCV_Error
        (Transform_C4'Access,
         "Perspective_Transform must reject a Float32 C4 source");
   end Perspective_Transform_Rejects_Invalid_Source_Channels;

   procedure Perspective_Transform_Rejects_Invalid_Matrix_Depth
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat := Two_Point_C2_Source;
      Matrix : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Int32, 1));

      procedure Transform_Int32_Matrix is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Perspective_Transform (Matrix);
      end Transform_Int32_Matrix;
   begin
      Assert_Raises_OpenCV_Error
        (Transform_Int32_Matrix'Access,
         "Perspective_Transform must reject an Int32 matrix");
   end Perspective_Transform_Rejects_Invalid_Matrix_Depth;

   procedure Perspective_Transform_Rejects_Invalid_Matrix_Channels
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat := Two_Point_C2_Source;
      Matrix : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 2));

      procedure Transform_C2_Matrix is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Perspective_Transform (Matrix);
      end Transform_C2_Matrix;
   begin
      Assert_Raises_OpenCV_Error
        (Transform_C2_Matrix'Access,
         "Perspective_Transform must reject a multi-channel matrix");
   end Perspective_Transform_Rejects_Invalid_Matrix_Channels;

   procedure Perspective_Transform_Rejects_Wrong_C2_Matrix_Dimensions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat := Two_Point_C2_Source;

      procedure Transform_With (Rows, Columns : Natural) is
         Matrix  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (Rows, Columns, (OpenCV.Core.Float32, 1));
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Perspective_Transform (Matrix);
      end Transform_With;

      procedure Transform_2x3 is
      begin
         Transform_With (2, 3);
      end Transform_2x3;

      procedure Transform_3x2 is
      begin
         Transform_With (3, 2);
      end Transform_3x2;

      procedure Transform_4x4 is
      begin
         Transform_With (4, 4);
      end Transform_4x4;
   begin
      Assert_Raises_OpenCV_Error
        (Transform_2x3'Access,
         "Perspective_Transform of C2 must reject a 2x3 matrix");
      Assert_Raises_OpenCV_Error
        (Transform_3x2'Access,
         "Perspective_Transform of C2 must reject a 3x2 matrix");
      Assert_Raises_OpenCV_Error
        (Transform_4x4'Access,
         "Perspective_Transform of C2 must reject a 4x4 matrix");
   end Perspective_Transform_Rejects_Wrong_C2_Matrix_Dimensions;

   procedure Perspective_Transform_Rejects_Wrong_C3_Matrix_Dimensions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 3));

      procedure Transform_With (Rows, Columns : Natural) is
         Matrix  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (Rows, Columns, (OpenCV.Core.Float32, 1));
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Perspective_Transform (Matrix);
      end Transform_With;

      procedure Transform_3x3 is
      begin
         Transform_With (3, 3);
      end Transform_3x3;

      procedure Transform_3x4 is
      begin
         Transform_With (3, 4);
      end Transform_3x4;

      procedure Transform_4x3 is
      begin
         Transform_With (4, 3);
      end Transform_4x3;
   begin
      Assert_Raises_OpenCV_Error
        (Transform_3x3'Access,
         "Perspective_Transform of C3 must reject a 3x3 matrix");
      Assert_Raises_OpenCV_Error
        (Transform_3x4'Access,
         "Perspective_Transform of C3 must reject a 3x4 matrix");
      Assert_Raises_OpenCV_Error
        (Transform_4x3'Access,
         "Perspective_Transform of C3 must reject a 4x3 matrix");
   end Perspective_Transform_Rejects_Wrong_C3_Matrix_Dimensions;

   procedure Perspective_Transform_Rejects_Empty_Inputs
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Source : OpenCV.Core.Mat;
      Empty_Source   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 2));
      Valid_Source   : constant OpenCV.Core.Mat := Two_Point_C2_Source;
      Default_Matrix : OpenCV.Core.Mat;
      Empty_Matrix   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Valid_Matrix   : constant OpenCV.Core.Mat := Identity_3x3;

      procedure Transform_Default_Source is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Default_Source.Perspective_Transform (Valid_Matrix);
      end Transform_Default_Source;

      procedure Transform_Empty_Source is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Empty_Source.Perspective_Transform (Valid_Matrix);
      end Transform_Empty_Source;

      procedure Transform_Default_Matrix is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Valid_Source.Perspective_Transform (Default_Matrix);
      end Transform_Default_Matrix;

      procedure Transform_Empty_Matrix is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Valid_Source.Perspective_Transform (Empty_Matrix);
      end Transform_Empty_Matrix;
   begin
      Assert_Raises_OpenCV_Error
        (Transform_Default_Source'Access,
         "Perspective_Transform must reject a default empty source");
      Assert_Raises_OpenCV_Error
        (Transform_Empty_Source'Access,
         "Perspective_Transform must reject a typed 0x0 Float32 C2 source");
      Assert_Raises_OpenCV_Error
        (Transform_Default_Matrix'Access,
         "Perspective_Transform must reject a default empty matrix");
      Assert_Raises_OpenCV_Error
        (Transform_Empty_Matrix'Access,
         "Perspective_Transform must reject a typed 0x0 Float32 matrix");
   end Perspective_Transform_Rejects_Empty_Inputs;

   function DFT_Sample_Real_Float32 return OpenCV.Core.Mat is
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 5.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 2, 6.0);
      return Image;
   end DFT_Sample_Real_Float32;

   function DFT_Sample_Complex_Float32 return OpenCV.Core.Mat is
      Real_Part      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Imaginary_Part : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Real_Part, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Real_Part, 0, 1, 0.5);
      OpenCV.Core.Float32_Access.Set (Real_Part, 1, 0, -1.0);
      OpenCV.Core.Float32_Access.Set (Real_Part, 1, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Imaginary_Part, 0, 0, 0.25);
      OpenCV.Core.Float32_Access.Set (Imaginary_Part, 0, 1, -0.5);
      OpenCV.Core.Float32_Access.Set (Imaginary_Part, 1, 0, 1.5);
      OpenCV.Core.Float32_Access.Set (Imaginary_Part, 1, 1, 0.0);
      return OpenCV.Core.Merge ((0 => Real_Part, 1 => Imaginary_Part));
   end DFT_Sample_Complex_Float32;

   function DFT_Float32_C1_Close
     (Left, Right : OpenCV.Core.Mat; Tolerance : Long_Float) return Boolean is
   begin
      if Left.Rows /= Right.Rows
        or else Left.Columns /= Right.Columns
        or else Left.Depth /= Right.Depth
        or else Left.Channels /= Right.Channels
      then
         return False;
      end if;

      for Row in 0 .. Left.Rows - 1 loop
         for Column in 0 .. Left.Columns - 1 loop
            if not Approximately_Equal
                     (Long_Float
                        (OpenCV.Core.Float32_Access.Get (Left, Row, Column)),
                      Long_Float
                        (OpenCV.Core.Float32_Access.Get (Right, Row, Column)),
                      Tolerance)
            then
               return False;
            end if;
         end loop;
      end loop;

      return True;
   end DFT_Float32_C1_Close;

   function DFT_Float32_C2_Close
     (Left, Right : OpenCV.Core.Mat; Tolerance : Long_Float) return Boolean
   is
      Left_Channels  : constant OpenCV.Core.Mat_Array := Left.Split;
      Right_Channels : constant OpenCV.Core.Mat_Array := Right.Split;
   begin
      return
        Left.Channels = 2
        and then Right.Channels = 2
        and then DFT_Float32_C1_Close
                   (Left_Channels (0), Right_Channels (0), Tolerance)
        and then DFT_Float32_C1_Close
                   (Left_Channels (1), Right_Channels (1), Tolerance);
   end DFT_Float32_C2_Close;

   procedure Discrete_Fourier_Transform_Real_Forward_Output_Type
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32 : constant OpenCV.Core.Mat := DFT_Sample_Real_Float32;
      Source64 : constant OpenCV.Core.Mat :=
        Source32.Convert_To (OpenCV.Core.Float64);
   begin
      declare
         Spectrum32 : constant OpenCV.Core.Mat :=
           Source32.Discrete_Fourier_Transform;
         Spectrum64 : constant OpenCV.Core.Mat :=
           Source64.Discrete_Fourier_Transform;
      begin
         AUnit.Assertions.Assert
           (Spectrum32.Rows = Source32.Rows
            and then Spectrum32.Columns = Source32.Columns
            and then Spectrum32.Depth = OpenCV.Core.Float32
            and then Spectrum32.Channels = 2,
            "A real Float32 DFT must return a same-shape Float32 C2 spectrum");
         AUnit.Assertions.Assert
           (Spectrum64.Rows = Source64.Rows
            and then Spectrum64.Columns = Source64.Columns
            and then Spectrum64.Depth = OpenCV.Core.Float64
            and then Spectrum64.Channels = 2,
            "A real Float64 DFT must preserve depth and return C2");
      end;
   end Discrete_Fourier_Transform_Real_Forward_Output_Type;

   procedure Discrete_Fourier_Transform_Real_Round_Trip
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32 : constant OpenCV.Core.Mat := DFT_Sample_Real_Float32;
      Source64 : constant OpenCV.Core.Mat :=
        Source32.Convert_To (OpenCV.Core.Float64);
   begin
      declare
         Spectrum32 : constant OpenCV.Core.Mat :=
           Source32.Discrete_Fourier_Transform;
         Restored32 : constant OpenCV.Core.Mat :=
           Spectrum32.Inverse_Real_Discrete_Fourier_Transform;
         Spectrum64 : constant OpenCV.Core.Mat :=
           Source64.Discrete_Fourier_Transform;
         Restored64 : constant OpenCV.Core.Mat :=
           Spectrum64.Inverse_Real_Discrete_Fourier_Transform;
      begin
         AUnit.Assertions.Assert
           (Restored32.Rows = Source32.Rows
            and then Restored32.Columns = Source32.Columns
            and then Restored32.Depth = OpenCV.Core.Float32
            and then Restored32.Channels = 1
            and then DFT_Float32_C1_Close (Restored32, Source32, 0.000_1),
            "A real Float32 DFT plus scaled inverse-real must round-trip");
         AUnit.Assertions.Assert
           (Restored64.Rows = Source64.Rows
            and then Restored64.Columns = Source64.Columns
            and then Restored64.Depth = OpenCV.Core.Float64
            and then Restored64.Channels = 1
            and then Restored64.Abs_Diff (Source64).Norm < 1.0E-12,
            "A real Float64 DFT plus scaled inverse-real must round-trip"
            & " more tightly than Float32");
         AUnit.Assertions.Assert
           (Restored32.Abs_Diff (Source32).Norm < 0.01
            and then Restored64.Abs_Diff (Source64).Norm < 1.0E-10,
            "Ada inverse DFT must use DFT_SCALE rather than returning"
            & " Source * Rows * Columns");
      end;
   end Discrete_Fourier_Transform_Real_Round_Trip;

   procedure Discrete_Fourier_Transform_Complex_Round_Trip
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat := DFT_Sample_Complex_Float32;
   begin
      declare
         Spectrum : constant OpenCV.Core.Mat :=
           Source.Discrete_Fourier_Transform;
         Restored : constant OpenCV.Core.Mat :=
           Spectrum.Inverse_Discrete_Fourier_Transform;
      begin
         AUnit.Assertions.Assert
           (Spectrum.Rows = Source.Rows
            and then Spectrum.Columns = Source.Columns
            and then Spectrum.Depth = OpenCV.Core.Float32
            and then Spectrum.Channels = 2
            and then Restored.Channels = 2
            and then DFT_Float32_C2_Close (Restored, Source, 0.000_1),
            "A complex C2 DFT plus scaled inverse must reproduce both"
            & " real and imaginary components");
         AUnit.Assertions.Assert
           (Restored.Abs_Diff (Source).Norm < 0.01,
            "Complex inverse DFT must be DFT_SCALE-normalized rather than"
            & " returning Source * Rows * Columns");
      end;
   end Discrete_Fourier_Transform_Complex_Round_Trip;

   procedure Discrete_Fourier_Transform_Impulse_Spectrum
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
   begin
      Source.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 1.0);

      declare
         Spectrum : constant OpenCV.Core.Mat :=
           Source.Discrete_Fourier_Transform;
         Channels : constant OpenCV.Core.Mat_Array := Spectrum.Split;
      begin
         AUnit.Assertions.Assert
           (Spectrum.Rows = 4
            and then Spectrum.Columns = 4
            and then Spectrum.Channels = 2,
            "An origin impulse DFT must remain 4x4 C2");
         for Row in 0 .. 3 loop
            for Column in 0 .. 3 loop
               AUnit.Assertions.Assert
                 (Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Channels (0), Row, Column)),
                     1.0,
                     0.000_1)
                  and then Approximately_Equal
                             (Long_Float
                                (OpenCV.Core.Float32_Access.Get
                                   (Channels (1), Row, Column)),
                              0.0,
                              0.000_1),
                  "An origin impulse must have real component 1 and"
                  & " imaginary component 0 everywhere");
            end loop;
         end loop;
      end;
   end Discrete_Fourier_Transform_Impulse_Spectrum;

   procedure Discrete_Fourier_Transform_Constant_DC
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Constant_Value : constant Long_Float := 3.0;
      Rows           : constant Natural := 2;
      Columns        : constant Natural := 3;
      Source         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (Rows, Columns, (OpenCV.Core.Float32, 1));
      Expected_DC    : constant Long_Float :=
        Constant_Value * Long_Float (Rows) * Long_Float (Columns);
   begin
      Source.Set_To (OpenCV.Core.Make_Scalar (Constant_Value));

      declare
         Spectrum : constant OpenCV.Core.Mat :=
           Source.Discrete_Fourier_Transform;
         Channels : constant OpenCV.Core.Mat_Array := Spectrum.Split;
      begin
         AUnit.Assertions.Assert
           (Approximately_Equal
              (Long_Float
                 (OpenCV.Core.Float32_Access.Get (Channels (0), 0, 0)),
               Expected_DC,
               0.000_1)
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get
                             (Channels (1), 0, 0)),
                        0.0,
                        0.000_1),
            "Unscaled forward DFT of a constant C must have DC real"
            & " equal to C * Rows * Columns");
         for Row in 0 .. Rows - 1 loop
            for Column in 0 .. Columns - 1 loop
               if Row /= 0 or else Column /= 0 then
                  AUnit.Assertions.Assert
                    (Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get
                             (Channels (0), Row, Column)),
                        0.0,
                        0.000_1)
                     and then Approximately_Equal
                                (Long_Float
                                   (OpenCV.Core.Float32_Access.Get
                                      (Channels (1), Row, Column)),
                                 0.0,
                                 0.000_1),
                     "Non-DC bins of a constant matrix must be approximately"
                     & " zero");
               end if;
            end loop;
         end loop;
      end;
   end Discrete_Fourier_Transform_Constant_DC;

   procedure Discrete_Fourier_Transform_Row_Vector
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 3, 4.0);

      declare
         Spectrum : constant OpenCV.Core.Mat :=
           Source.Discrete_Fourier_Transform;
         Restored : constant OpenCV.Core.Mat :=
           Spectrum.Inverse_Real_Discrete_Fourier_Transform;
      begin
         AUnit.Assertions.Assert
           (Spectrum.Rows = 1
            and then Spectrum.Columns = 4
            and then Spectrum.Channels = 2
            and then Restored.Rows = 1
            and then Restored.Columns = 4
            and then Restored.Channels = 1
            and then DFT_Float32_C1_Close (Restored, Source, 0.000_1),
            "A 1xN real DFT must remain 1xN and round-trip through"
            & " inverse-real");
      end;
   end Discrete_Fourier_Transform_Row_Vector;

   procedure Discrete_Fourier_Transform_Column_Vector
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 1, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Source, 2, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Source, 3, 0, 4.0);

      declare
         Spectrum : constant OpenCV.Core.Mat :=
           Source.Discrete_Fourier_Transform;
         Restored : constant OpenCV.Core.Mat :=
           Spectrum.Inverse_Real_Discrete_Fourier_Transform;
      begin
         AUnit.Assertions.Assert
           (Spectrum.Rows = 4
            and then Spectrum.Columns = 1
            and then Spectrum.Channels = 2
            and then Restored.Rows = 4
            and then Restored.Columns = 1
            and then Restored.Channels = 1
            and then DFT_Float32_C1_Close (Restored, Source, 0.000_1),
            "An Nx1 real DFT must remain Nx1 and round-trip through"
            & " inverse-real");
      end;
   end Discrete_Fourier_Transform_Column_Vector;

   procedure Discrete_Fourier_Transform_Noncontiguous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 1));
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      OpenCV.Core.Float32_Access.Set (Parent, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Parent, 0, 2, 2.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 1, 3.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 2, 4.0);

      declare
         Region   : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
         Expected : OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
         Spectrum : OpenCV.Core.Mat;
         Restored : OpenCV.Core.Mat;
      begin
         OpenCV.Core.Float32_Access.Set (Expected, 0, 0, 1.0);
         OpenCV.Core.Float32_Access.Set (Expected, 0, 1, 2.0);
         OpenCV.Core.Float32_Access.Set (Expected, 1, 0, 3.0);
         OpenCV.Core.Float32_Access.Set (Expected, 1, 1, 4.0);
         AUnit.Assertions.Assert
           (not Region.Is_Continuous,
            "DFT Region fixture must be non-contiguous");
         Spectrum := Region.Discrete_Fourier_Transform;
         Restored := Spectrum.Inverse_Real_Discrete_Fourier_Transform;
         AUnit.Assertions.Assert
           (Spectrum.Rows = 2
            and then Spectrum.Columns = 2
            and then Restored.Rows = 2
            and then Restored.Columns = 2
            and then DFT_Float32_C1_Close (Restored, Expected, 0.000_1),
            "A non-contiguous Region DFT must transform only Region values");
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Access.Get (Region, 0, 0) = 1.0
            and then OpenCV.Core.Float32_Access.Get (Region, 0, 1) = 2.0
            and then OpenCV.Core.Float32_Access.Get (Region, 1, 0) = 3.0
            and then OpenCV.Core.Float32_Access.Get (Region, 1, 1) = 4.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 2, 3) = 99.0,
            "DFT of a Region must leave the Region and parent unchanged");
         OpenCV.Core.Float32_Access.Set (Restored, 0, 0, 50.0);
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Access.Get (Region, 0, 0) = 1.0,
            "Mutating a Region DFT result must not mutate the Region");
      end;
   end Discrete_Fourier_Transform_Noncontiguous_Region;

   procedure Discrete_Fourier_Transform_Result_Is_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source   : constant OpenCV.Core.Mat := DFT_Sample_Real_Float32;
      Spectrum : OpenCV.Core.Mat := Source.Discrete_Fourier_Transform;
      Restored : OpenCV.Core.Mat :=
        Spectrum.Inverse_Real_Discrete_Fourier_Transform;
      Before   : constant OpenCV.Core.Mat_Array := Spectrum.Split;
   begin
      Spectrum.Set_To (OpenCV.Core.Make_Scalar (123.0, 456.0));
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Source, 0, 0) = 1.0
         and then OpenCV.Core.Float32_Access.Get (Source, 1, 2) = 6.0,
         "Mutating a DFT spectrum must not change the source");
      OpenCV.Core.Float32_Access.Set (Restored, 0, 0, 77.0);
      declare
         Recheck : constant OpenCV.Core.Mat_Array := Spectrum.Split;
      begin
         AUnit.Assertions.Assert
           (Approximately_Equal
              (Long_Float (OpenCV.Core.Float32_Access.Get (Recheck (0), 0, 0)),
               123.0,
               0.000_1)
            and then not Approximately_Equal
                           (Long_Float
                              (OpenCV.Core.Float32_Access.Get
                                 (Before (0), 0, 0)),
                            123.0,
                            0.1),
            "Mutating an inverse-real result must not change the spectrum");
      end;
   end Discrete_Fourier_Transform_Result_Is_Independent;

   procedure Discrete_Fourier_Transform_Rejects_Empty
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Source : OpenCV.Core.Mat;
      Empty_Source   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Empty_Complex  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 2));

      procedure Forward_Default is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Default_Source.Discrete_Fourier_Transform;
      end Forward_Default;

      procedure Forward_Empty is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Empty_Source.Discrete_Fourier_Transform;
      end Forward_Empty;

      procedure Inverse_Empty is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Empty_Complex.Inverse_Discrete_Fourier_Transform;
      end Inverse_Empty;

      procedure Inverse_Real_Empty is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Empty_Complex.Inverse_Real_Discrete_Fourier_Transform;
      end Inverse_Real_Empty;
   begin
      Assert_Raises_OpenCV_Error
        (Forward_Default'Access,
         "Discrete_Fourier_Transform must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Forward_Empty'Access,
         "Discrete_Fourier_Transform must reject a typed 0x0 Mat");
      Assert_Raises_OpenCV_Error
        (Inverse_Empty'Access,
         "Inverse_Discrete_Fourier_Transform must reject empty input");
      Assert_Raises_OpenCV_Error
        (Inverse_Real_Empty'Access,
         "Inverse_Real_Discrete_Fourier_Transform must reject empty input");
   end Discrete_Fourier_Transform_Rejects_Empty;

   procedure Discrete_Fourier_Transform_Rejects_Unsupported_Depth
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Int32_Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int32, 1));

      procedure Forward_UInt8 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := UInt8_Source.Discrete_Fourier_Transform;
      end Forward_UInt8;

      procedure Forward_Int32 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Int32_Source.Discrete_Fourier_Transform;
      end Forward_Int32;
   begin
      Assert_Raises_OpenCV_Error
        (Forward_UInt8'Access, "Discrete_Fourier_Transform must reject UInt8");
      Assert_Raises_OpenCV_Error
        (Forward_Int32'Access, "Discrete_Fourier_Transform must reject Int32");
   end Discrete_Fourier_Transform_Rejects_Unsupported_Depth;

   procedure Discrete_Fourier_Transform_Rejects_Invalid_Channels
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      C3 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 3));
      C1 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));

      procedure Forward_C3 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := C3.Discrete_Fourier_Transform;
      end Forward_C3;

      procedure Inverse_C1 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := C1.Inverse_Discrete_Fourier_Transform;
      end Inverse_C1;

      procedure Inverse_C3 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := C3.Inverse_Discrete_Fourier_Transform;
      end Inverse_C3;

      procedure Inverse_Real_C1 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := C1.Inverse_Real_Discrete_Fourier_Transform;
      end Inverse_Real_C1;

      procedure Inverse_Real_C3 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := C3.Inverse_Real_Discrete_Fourier_Transform;
      end Inverse_Real_C3;
   begin
      Assert_Raises_OpenCV_Error
        (Forward_C3'Access, "Forward DFT must reject C3");
      Assert_Raises_OpenCV_Error
        (Inverse_C1'Access, "Inverse complex DFT must reject C1");
      Assert_Raises_OpenCV_Error
        (Inverse_C3'Access, "Inverse complex DFT must reject C3");
      Assert_Raises_OpenCV_Error
        (Inverse_Real_C1'Access, "Inverse-real DFT must reject C1");
      Assert_Raises_OpenCV_Error
        (Inverse_Real_C3'Access, "Inverse-real DFT must reject C3");
   end Discrete_Fourier_Transform_Rejects_Invalid_Channels;

   procedure Packed_DFT_Float32_Forward_And_Oracle_Round_Trip
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source          : constant OpenCV.Core.Mat := DFT_Sample_Real_Float32;
      Packed          : constant OpenCV.Core.Mat :=
        Source.Packed_Discrete_Fourier_Transform;
      Packed_Restored : constant OpenCV.Core.Mat :=
        Packed.Inverse_Packed_Discrete_Fourier_Transform;
      Full_Restored   : constant OpenCV.Core.Mat :=
        Source
          .Discrete_Fourier_Transform
          .Inverse_Real_Discrete_Fourier_Transform;
   begin
      AUnit.Assertions.Assert
        (Packed.Rows = Source.Rows
         and then Packed.Columns = Source.Columns
         and then Packed.Depth = OpenCV.Core.Float32
         and then Packed.Channels = 1,
         "Packed Float32 DFT must preserve odd shape and remain C1");
      AUnit.Assertions.Assert
        (DFT_Float32_C1_Close (Packed_Restored, Source, 0.000_1)
         and then DFT_Float32_C1_Close
                    (Packed_Restored, Full_Restored, 0.000_1),
         "Packed Float32 inverse must agree with source and full-complex"
         & " oracle");
   end Packed_DFT_Float32_Forward_And_Oracle_Round_Trip;

   procedure Packed_DFT_Float64_Forward_And_Oracle_Round_Trip
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source          : constant OpenCV.Core.Mat :=
        DFT_Sample_Real_Float32.Convert_To (OpenCV.Core.Float64);
      Packed          : constant OpenCV.Core.Mat :=
        Source.Packed_Discrete_Fourier_Transform;
      Packed_Restored : constant OpenCV.Core.Mat :=
        Packed.Inverse_Packed_Discrete_Fourier_Transform;
      Full_Restored   : constant OpenCV.Core.Mat :=
        Source
          .Discrete_Fourier_Transform
          .Inverse_Real_Discrete_Fourier_Transform;
   begin
      AUnit.Assertions.Assert
        (Packed.Rows = Source.Rows
         and then Packed.Columns = Source.Columns
         and then Packed.Depth = OpenCV.Core.Float64
         and then Packed.Channels = 1,
         "Packed Float64 DFT must preserve shape, depth, and one channel");
      AUnit.Assertions.Assert
        (Packed_Restored.Abs_Diff (Source).Norm < 1.0E-12
         and then Packed_Restored.Abs_Diff (Full_Restored).Norm < 1.0E-12,
         "Packed Float64 inverse must satisfy the tighter Float64 oracle");
   end Packed_DFT_Float64_Forward_And_Oracle_Round_Trip;

   procedure Packed_DFT_Row_And_Column_Vectors (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Row_Source    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 5, (OpenCV.Core.Float32, 1));
      Column_Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (5, 1, (OpenCV.Core.Float32, 1));
   begin
      for Index in 0 .. 4 loop
         OpenCV.Core.Float32_Access.Set
           (Row_Source, 0, Index, Interfaces.IEEE_Float_32 (Index + 1));
         OpenCV.Core.Float32_Access.Set
           (Column_Source, Index, 0, Interfaces.IEEE_Float_32 (Index + 1));
      end loop;

      declare
         Row_Packed      : constant OpenCV.Core.Mat :=
           Row_Source.Packed_Discrete_Fourier_Transform;
         Column_Packed   : constant OpenCV.Core.Mat :=
           Column_Source.Packed_Discrete_Fourier_Transform;
         Row_Restored    : constant OpenCV.Core.Mat :=
           Row_Packed.Inverse_Packed_Discrete_Fourier_Transform;
         Column_Restored : constant OpenCV.Core.Mat :=
           Column_Packed.Inverse_Packed_Discrete_Fourier_Transform;
      begin
         AUnit.Assertions.Assert
           (Row_Packed.Rows = 1
            and then Row_Packed.Columns = 5
            and then Row_Packed.Channels = 1
            and then DFT_Float32_C1_Close (Row_Restored, Row_Source, 0.000_1),
            "Odd 1xN input must round-trip through packed CCS");
         AUnit.Assertions.Assert
           (Column_Packed.Rows = 5
            and then Column_Packed.Columns = 1
            and then Column_Packed.Channels = 1
            and then DFT_Float32_C1_Close
                       (Column_Restored, Column_Source, 0.000_1),
            "Odd Nx1 input must round-trip through packed CCS");
      end;
   end Packed_DFT_Row_And_Column_Vectors;

   procedure Packed_DFT_Noncontiguous_Region_And_Independence
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 5, (OpenCV.Core.Float32, 1));
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      for Row in 0 .. 2 loop
         for Column in 0 .. 2 loop
            OpenCV.Core.Float32_Access.Set
              (Parent,
               Row,
               Column + 1,
               Interfaces.IEEE_Float_32 (Row * 3 + Column + 1));
         end loop;
      end loop;

      declare
         Source   : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 3, Height => 3));
         Original : constant OpenCV.Core.Mat := Source.Clone;
         Packed   : OpenCV.Core.Mat :=
           Source.Packed_Discrete_Fourier_Transform;
         Restored : OpenCV.Core.Mat :=
           Packed.Inverse_Packed_Discrete_Fourier_Transform;
      begin
         AUnit.Assertions.Assert
           (not Source.Is_Continuous
            and then DFT_Float32_C1_Close (Restored, Original, 0.000_1)
            and then DFT_Float32_C1_Close (Source, Original, 0.0),
            "Packed DFT must accept a Region and leave its source unchanged");
         Packed.Set_To (OpenCV.Core.Make_Scalar (-7.0));
         AUnit.Assertions.Assert
           (DFT_Float32_C1_Close (Restored, Original, 0.000_1)
            and then DFT_Float32_C1_Close (Source, Original, 0.0),
            "Packed and inverse results must own storage independently");
         Restored.Set_To (OpenCV.Core.Make_Scalar (-9.0));
         AUnit.Assertions.Assert
           (DFT_Float32_C1_Close (Source, Original, 0.0),
            "Mutating inverse output must not alter source storage");
      end;
   end Packed_DFT_Noncontiguous_Region_And_Independence;

   procedure Packed_DFT_Rejects_Invalid_Inputs (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Source : OpenCV.Core.Mat;
      Empty_Source   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Integer_Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Int32, 1));
      Complex_Source : constant OpenCV.Core.Mat :=
        DFT_Sample_Real_Float32.Discrete_Fourier_Transform;

      procedure Forward_Default is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Default_Source.Packed_Discrete_Fourier_Transform;
      end Forward_Default;

      procedure Inverse_Empty is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Empty_Source.Inverse_Packed_Discrete_Fourier_Transform;
      end Inverse_Empty;

      procedure Forward_Integer is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Integer_Source.Packed_Discrete_Fourier_Transform;
      end Forward_Integer;

      procedure Forward_Complex is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Complex_Source.Packed_Discrete_Fourier_Transform;
      end Forward_Complex;
   begin
      Assert_Raises_OpenCV_Error
        (Forward_Default'Access, "Packed DFT must reject a default Mat");
      Assert_Raises_OpenCV_Error
        (Inverse_Empty'Access, "Packed inverse must reject a typed empty Mat");
      Assert_Raises_OpenCV_Error
        (Forward_Integer'Access, "Packed DFT must reject integer depth");
      Assert_Raises_OpenCV_Error
        (Forward_Complex'Access, "Packed DFT must reject C2 input");
   end Packed_DFT_Rejects_Invalid_Inputs;

   procedure DFT_Rows_Forward_Matches_Independent_Rows
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32       : constant OpenCV.Core.Mat := DFT_Sample_Real_Float32;
      Source64       : constant OpenCV.Core.Mat :=
        Source32.Convert_To (OpenCV.Core.Float64);
      Rows32         : constant OpenCV.Core.Mat :=
        Source32.Discrete_Fourier_Transform_Rows;
      Rows64         : constant OpenCV.Core.Mat :=
        Source64.Discrete_Fourier_Transform_Rows;
      Full32         : constant OpenCV.Core.Mat :=
        Source32.Discrete_Fourier_Transform;
      All_Rows_Match : Boolean := True;
   begin
      AUnit.Assertions.Assert
        (Rows32.Rows = Source32.Rows
         and then Rows32.Columns = Source32.Columns
         and then Rows32.Depth = OpenCV.Core.Float32
         and then Rows32.Channels = 2,
         "Row-wise Float32 C1 DFT must preserve shape and return Float32 C2");
      AUnit.Assertions.Assert
        (Rows64.Rows = Source64.Rows
         and then Rows64.Columns = Source64.Columns
         and then Rows64.Depth = OpenCV.Core.Float64
         and then Rows64.Channels = 2,
         "Row-wise Float64 C1 DFT must preserve shape and return Float64 C2");

      for Row in 0 .. Source32.Rows - 1 loop
         declare
            Expected32 : constant OpenCV.Core.Mat :=
              Source32.Row_View (OpenCV.Core.Size_Coordinate (Row))
                .Discrete_Fourier_Transform;
            Actual32   : constant OpenCV.Core.Mat :=
              Rows32.Row_View (OpenCV.Core.Size_Coordinate (Row));
            Expected64 : constant OpenCV.Core.Mat :=
              Source64.Row_View (OpenCV.Core.Size_Coordinate (Row))
                .Discrete_Fourier_Transform;
            Actual64   : constant OpenCV.Core.Mat :=
              Rows64.Row_View (OpenCV.Core.Size_Coordinate (Row));
         begin
            All_Rows_Match :=
              All_Rows_Match
              and then DFT_Float32_C2_Close (Actual32, Expected32, 0.000_1)
              and then Actual64.Abs_Diff (Expected64).Norm < 1.0E-12;
         end;
      end loop;

      AUnit.Assertions.Assert
        (All_Rows_Match,
         "Every DFT_ROWS output row must equal an ordinary DFT of that row"
         & " for Float32 and Float64 signals");
      AUnit.Assertions.Assert
        (Rows32.Abs_Diff (Full32).Norm > 0.1,
         "Independent row transforms must differ from a 2-D DFT for the"
         & " deliberately different row signals");
   end DFT_Rows_Forward_Matches_Independent_Rows;

   procedure DFT_Rows_One_Row_Matches_Ordinary_DFT
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source   : constant OpenCV.Core.Mat :=
        DFT_Sample_Real_Float32.Row_View (0);
      Row_Wise : constant OpenCV.Core.Mat :=
        Source.Discrete_Fourier_Transform_Rows;
      Ordinary : constant OpenCV.Core.Mat := Source.Discrete_Fourier_Transform;
   begin
      AUnit.Assertions.Assert
        (DFT_Float32_C2_Close (Row_Wise, Ordinary, 0.000_1),
         "A one-row DFT_ROWS transform must agree with the ordinary DFT");
   end DFT_Rows_One_Row_Matches_Ordinary_DFT;

   procedure DFT_Rows_Real_Round_Trips (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source32   : constant OpenCV.Core.Mat := DFT_Sample_Real_Float32;
      Source64   : constant OpenCV.Core.Mat :=
        Source32.Convert_To (OpenCV.Core.Float64);
      Spectrum32 : constant OpenCV.Core.Mat :=
        Source32.Discrete_Fourier_Transform_Rows;
      Spectrum64 : constant OpenCV.Core.Mat :=
        Source64.Discrete_Fourier_Transform_Rows;
      Restored32 : constant OpenCV.Core.Mat :=
        Spectrum32.Inverse_Real_Discrete_Fourier_Transform_Rows;
      Restored64 : constant OpenCV.Core.Mat :=
        Spectrum64.Inverse_Real_Discrete_Fourier_Transform_Rows;
   begin
      AUnit.Assertions.Assert
        (Restored32.Channels = 1
         and then DFT_Float32_C1_Close (Restored32, Source32, 0.000_1),
         "Float32 row-wise forward plus scaled inverse-real must round-trip");
      AUnit.Assertions.Assert
        (Restored64.Channels = 1
         and then Restored64.Abs_Diff (Source64).Norm < 1.0E-12,
         "Float64 row-wise forward plus scaled inverse-real must round-trip"
         & " with tighter tolerance");
   end DFT_Rows_Real_Round_Trips;

   procedure DFT_Rows_Complex_Round_Trip_And_Independence
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source   : constant OpenCV.Core.Mat := DFT_Sample_Complex_Float32;
      Spectrum : OpenCV.Core.Mat := Source.Discrete_Fourier_Transform_Rows;
      Restored : OpenCV.Core.Mat :=
        Spectrum.Inverse_Discrete_Fourier_Transform_Rows;
   begin
      AUnit.Assertions.Assert
        (Spectrum.Channels = 2
         and then Restored.Channels = 2
         and then DFT_Float32_C2_Close (Restored, Source, 0.000_1),
         "C2 DFT_ROWS plus scaled complex inverse must round-trip both"
         & " components");
      Spectrum.Set_To (OpenCV.Core.Make_Scalar (99.0, -99.0));
      AUnit.Assertions.Assert
        (DFT_Float32_C2_Close (Restored, Source, 0.000_1),
         "Mutating a row-wise spectrum must not alter its returned inverse");
      Restored.Set_To (OpenCV.Core.Make_Scalar (0.0, 0.0));
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Get (Source.Split (0), 0, 0) = 1.0,
         "Returned row-wise Mats must own storage independently"
         & " of the source");
   end DFT_Rows_Complex_Round_Trip_And_Independence;

   procedure DFT_Rows_Noncontiguous_Region (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 5, (OpenCV.Core.Float32, 1));
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (50.0));
      for Row in 0 .. 2 loop
         for Column in 0 .. 2 loop
            OpenCV.Core.Float32_Access.Set
              (Parent,
               Row,
               Column + 1,
               Interfaces.IEEE_Float_32 (Row * 10 + Column + 1));
         end loop;
      end loop;
      declare
         Source   : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 3, Height => 3));
         Spectrum : constant OpenCV.Core.Mat :=
           Source.Discrete_Fourier_Transform_Rows;
         Restored : constant OpenCV.Core.Mat :=
           Spectrum.Inverse_Real_Discrete_Fourier_Transform_Rows;
      begin
         AUnit.Assertions.Assert
           (not Source.Is_Continuous
            and then DFT_Float32_C1_Close (Restored, Source, 0.000_1),
            "DFT_ROWS must support and round-trip a non-contiguous Region");
      end;
   end DFT_Rows_Noncontiguous_Region;

   procedure DFT_Rows_Rejects_Invalid_Inputs (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Source : OpenCV.Core.Mat;
      Empty_Source   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Int_Source     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Int32, 1));
      C3_Source      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 3));
      C1_Source      : constant OpenCV.Core.Mat := DFT_Sample_Real_Float32;

      procedure Forward_Default is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Default_Source.Discrete_Fourier_Transform_Rows;
      end Forward_Default;
      procedure Forward_Empty is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Empty_Source.Discrete_Fourier_Transform_Rows;
      end Forward_Empty;
      procedure Forward_Int is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Int_Source.Discrete_Fourier_Transform_Rows;
      end Forward_Int;
      procedure Forward_C3 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := C3_Source.Discrete_Fourier_Transform_Rows;
      end Forward_C3;
      procedure Inverse_C1 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := C1_Source.Inverse_Discrete_Fourier_Transform_Rows;
      end Inverse_C1;
      procedure Inverse_Real_C1 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := C1_Source.Inverse_Real_Discrete_Fourier_Transform_Rows;
      end Inverse_Real_C1;
   begin
      Assert_Raises_OpenCV_Error
        (Forward_Default'Access, "DFT_ROWS must reject a default Mat");
      Assert_Raises_OpenCV_Error
        (Forward_Empty'Access, "DFT_ROWS must reject a typed empty Mat");
      Assert_Raises_OpenCV_Error
        (Forward_Int'Access, "DFT_ROWS must reject integer depth");
      Assert_Raises_OpenCV_Error
        (Forward_C3'Access, "DFT_ROWS must reject C3 input");
      Assert_Raises_OpenCV_Error
        (Inverse_C1'Access, "Complex inverse DFT_ROWS must reject C1 input");
      Assert_Raises_OpenCV_Error
        (Inverse_Real_C1'Access, "Real inverse DFT_ROWS must reject C1 input");
   end DFT_Rows_Rejects_Invalid_Inputs;

   function Remainder_After_Factors_Two_Three_Five
     (Value : Positive) return Positive
   is
      Remaining : Positive := Value;
   begin
      while Remaining mod 2 = 0 loop
         Remaining := Remaining / 2;
      end loop;
      while Remaining mod 3 = 0 loop
         Remaining := Remaining / 3;
      end loop;
      while Remaining mod 5 = 0 loop
         Remaining := Remaining / 5;
      end loop;
      return Remaining;
   end Remainder_After_Factors_Two_Three_Five;

   procedure Optimal_DFT_Size_Already_Optimal (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
   begin
      AUnit.Assertions.Assert
        (OpenCV.Core.Optimal_DFT_Size (1) = 1
         and then OpenCV.Core.Optimal_DFT_Size (2) = 2
         and then OpenCV.Core.Optimal_DFT_Size (3) = 3
         and then OpenCV.Core.Optimal_DFT_Size (4) = 4
         and then OpenCV.Core.Optimal_DFT_Size (5) = 5
         and then OpenCV.Core.Optimal_DFT_Size (6) = 6
         and then OpenCV.Core.Optimal_DFT_Size (10) = 10
         and then OpenCV.Core.Optimal_DFT_Size (300) = 300,
         "Already-efficient DFT sizes must return themselves");
   end Optimal_DFT_Size_Already_Optimal;

   procedure Optimal_DFT_Size_Rounds_Up (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
   begin
      AUnit.Assertions.Assert
        (OpenCV.Core.Optimal_DFT_Size (7) = 8
         and then OpenCV.Core.Optimal_DFT_Size (11) = 12
         and then OpenCV.Core.Optimal_DFT_Size (17) = 18
         and then OpenCV.Core.Optimal_DFT_Size (301) = 320
         and then OpenCV.Core.Optimal_DFT_Size (7) >= 7
         and then OpenCV.Core.Optimal_DFT_Size (11) >= 11
         and then OpenCV.Core.Optimal_DFT_Size (17) >= 17
         and then OpenCV.Core.Optimal_DFT_Size (301) >= 301,
         "Non-optimal sizes must round up to the next efficient length");
   end Optimal_DFT_Size_Rounds_Up;

   procedure Optimal_DFT_Size_Factors_Are_Two_Three_Five
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Samples : constant array (Positive range <>) of Positive :=
        (1, 7, 11, 17, 64, 301, 1_024, 4_097);
   begin
      for Sample of Samples loop
         declare
            Optimal : constant Positive :=
              OpenCV.Core.Optimal_DFT_Size (Sample);
         begin
            AUnit.Assertions.Assert
              (Optimal >= Sample
               and then Remainder_After_Factors_Two_Three_Five (Optimal) = 1,
               "Optimal_DFT_Size must return a 2/3/5 factorization");
         end;
      end loop;
   end Optimal_DFT_Size_Factors_Are_Two_Three_Five;

   procedure Optimal_DFT_Size_Upper_Bound (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);

      procedure Too_Large is
         Ignored : Positive;
      begin
         Ignored := OpenCV.Core.Optimal_DFT_Size (2_125_764_000);
      end Too_Large;
   begin
      AUnit.Assertions.Assert
        (OpenCV.Core.Optimal_DFT_Size (2_125_763_999) = 2_125_764_000,
         "The last successful OpenCV 4.10 optimal size must be"
         & " 2125764000");
      Assert_Raises_OpenCV_Error
        (Too_Large'Access,
         "Optimal_DFT_Size must raise OpenCV_Error for the final table"
         & " entry");
   end Optimal_DFT_Size_Upper_Bound;

   procedure Optimal_DFT_Size_Pads_For_DFT_Integration
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Minimum : constant Positive := 17;
      Optimal : constant Positive := OpenCV.Core.Optimal_DFT_Size (Minimum);
      Source  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 17, (OpenCV.Core.Float32, 1));
   begin
      AUnit.Assertions.Assert
        (Optimal = 18, "Optimal_DFT_Size (17) must be 18");

      for Column in 0 .. 16 loop
         OpenCV.Core.Float32_Access.Set
           (Source, 0, Column, Interfaces.IEEE_Float_32 (Column + 1));
      end loop;

      declare
         Padded   : constant OpenCV.Core.Mat :=
           Source.Copy_Make_Border
             (Top    => 0,
              Bottom => 0,
              Left   => 0,
              Right  => Optimal - Minimum,
              Kind   => OpenCV.Core.Constant_Border,
              Value  => OpenCV.Core.Make_Scalar (0.0));
         Spectrum : constant OpenCV.Core.Mat :=
           Padded.Discrete_Fourier_Transform;
      begin
         AUnit.Assertions.Assert
           (Padded.Rows = 1
            and then Padded.Columns = Optimal
            and then Spectrum.Rows = 1
            and then Spectrum.Columns = Optimal
            and then Spectrum.Channels = 2
            and then Spectrum.Depth = OpenCV.Core.Float32,
            "Zero-padding to Optimal_DFT_Size must produce a DFT of"
            & " that length");
      end;
   end Optimal_DFT_Size_Pads_For_DFT_Integration;

   function Complex_Spectrum_From_Reals
     (Real_Part, Imaginary_Part : OpenCV.Core.Mat) return OpenCV.Core.Mat is
   begin
      return OpenCV.Core.Merge ((0 => Real_Part, 1 => Imaginary_Part));
   end Complex_Spectrum_From_Reals;

   function Unit_Complex_Spectrum
     (Rows, Columns : Natural; Depth : OpenCV.Core.Depth_Type)
      return OpenCV.Core.Mat
   is
      Real_Part      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (Rows, Columns, (Depth, 1));
      Imaginary_Part : OpenCV.Core.Mat :=
        OpenCV.Core.Create (Rows, Columns, (Depth, 1));
   begin
      Real_Part.Set_To (OpenCV.Core.Make_Scalar (1.0));
      Imaginary_Part.Set_To (OpenCV.Core.Make_Scalar (0.0));
      return Complex_Spectrum_From_Reals (Real_Part, Imaginary_Part);
   end Unit_Complex_Spectrum;

   function Sample_Complex_Pair return OpenCV.Core.Mat is
      Real_Part      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Imaginary_Part : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Real_Part, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Imaginary_Part, 0, 0, 3.0);
      return Complex_Spectrum_From_Reals (Real_Part, Imaginary_Part);
   end Sample_Complex_Pair;

   function Sample_Complex_Right return OpenCV.Core.Mat is
      Real_Part      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Imaginary_Part : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Real_Part, 0, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Imaginary_Part, 0, 0, 5.0);
      return Complex_Spectrum_From_Reals (Real_Part, Imaginary_Part);
   end Sample_Complex_Right;

   function Complex_Channels_Close
     (Image       : OpenCV.Core.Mat;
      Row, Column : Natural;
      Real, Imag  : Long_Float;
      Tolerance   : Long_Float) return Boolean
   is
      Channels : constant OpenCV.Core.Mat_Array := Image.Split;
   begin
      return
        Image.Channels = 2
        and then Approximately_Equal
                   (Long_Float
                      (OpenCV.Core.Float32_Access.Get
                         (Channels (0), Row, Column)),
                    Real,
                    Tolerance)
        and then Approximately_Equal
                   (Long_Float
                      (OpenCV.Core.Float32_Access.Get
                         (Channels (1), Row, Column)),
                    Imag,
                    Tolerance);
   end Complex_Channels_Close;

   procedure Multiply_Spectra_Ordinary_Float32_Product
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : constant OpenCV.Core.Mat := Sample_Complex_Pair;
      Right  : constant OpenCV.Core.Mat := Sample_Complex_Right;
      Result : constant OpenCV.Core.Mat :=
        OpenCV.Core.Multiply_Spectra (Left, Right);
   begin
      AUnit.Assertions.Assert
        (Result.Rows = 1
         and then Result.Columns = 1
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = 2
         and then Complex_Channels_Close (Result, 0, 0, -7.0, 22.0, 0.000_1),
         "Ordinary Float32 C2 product of (2+3i)*(4+5i) must be -7+22i");
   end Multiply_Spectra_Ordinary_Float32_Product;

   procedure Multiply_Spectra_Conjugate_Right_Float32_Product
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : constant OpenCV.Core.Mat := Sample_Complex_Pair;
      Right  : constant OpenCV.Core.Mat := Sample_Complex_Right;
      Result : constant OpenCV.Core.Mat :=
        OpenCV.Core.Multiply_Spectra
          (Left, Right, OpenCV.Core.Conjugate_Right_Spectrum_Product);
   begin
      AUnit.Assertions.Assert
        (Complex_Channels_Close (Result, 0, 0, 23.0, 2.0, 0.000_1),
         "Conjugate-right Float32 product of (2+3i)*conj(4+5i) must be 23+2i");
   end Multiply_Spectra_Conjugate_Right_Float32_Product;

   procedure Multiply_Spectra_Float64_Product (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : constant OpenCV.Core.Mat :=
        Sample_Complex_Pair.Convert_To (OpenCV.Core.Float64);
      Right  : constant OpenCV.Core.Mat :=
        Sample_Complex_Right.Convert_To (OpenCV.Core.Float64);
      Result : constant OpenCV.Core.Mat :=
        OpenCV.Core.Multiply_Spectra (Left, Right);
      Value  : constant OpenCV.Core.Scalar := Result.Mean;
   begin
      AUnit.Assertions.Assert
        (Result.Rows = 1
         and then Result.Columns = 1
         and then Result.Depth = OpenCV.Core.Float64
         and then Result.Channels = 2
         and then Approximately_Equal (Value.Component_0, -7.0, 0.000_1)
         and then Approximately_Equal (Value.Component_1, 22.0, 0.000_1),
         "Ordinary Float64 C2 product of (2+3i)*(4+5i) must be -7+22i");
   end Multiply_Spectra_Float64_Product;

   procedure Multiply_Spectra_Is_Elementwise_Complex
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left_Real  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Left_Imag  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Right_Real : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Right_Imag : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Left_Real, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Left_Imag, 0, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Left_Real, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Left_Imag, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Left_Real, 1, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Left_Imag, 1, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Left_Real, 1, 1, 3.0);
      OpenCV.Core.Float32_Access.Set (Left_Imag, 1, 1, 4.0);
      OpenCV.Core.Float32_Access.Set (Right_Real, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Right_Imag, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Right_Real, 0, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Right_Imag, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Right_Real, 1, 0, 5.0);
      OpenCV.Core.Float32_Access.Set (Right_Imag, 1, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Right_Real, 1, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Right_Imag, 1, 1, 0.0);

      declare
         Left   : constant OpenCV.Core.Mat :=
           Complex_Spectrum_From_Reals (Left_Real, Left_Imag);
         Right  : constant OpenCV.Core.Mat :=
           Complex_Spectrum_From_Reals (Right_Real, Right_Imag);
         Result : constant OpenCV.Core.Mat :=
           OpenCV.Core.Multiply_Spectra (Left, Right);
      begin
         AUnit.Assertions.Assert
           (Complex_Channels_Close (Result, 0, 0, 1.0, 1.0, 0.000_1)
            and then Complex_Channels_Close (Result, 0, 1, -2.0, 4.0, 0.000_1)
            and then Complex_Channels_Close (Result, 1, 0, 0.0, 5.0, 0.000_1)
            and then Complex_Channels_Close (Result, 1, 1, 3.0, 4.0, 0.000_1),
            "Multiply_Spectra must multiply each C2 element as a complex"
            & " value, not as a matrix or independent channels");
      end;
   end Multiply_Spectra_Is_Elementwise_Complex;

   procedure Multiply_Spectra_Identity_Spectrum
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source   : constant OpenCV.Core.Mat := DFT_Sample_Complex_Float32;
      Identity : constant OpenCV.Core.Mat :=
        Unit_Complex_Spectrum (Source.Rows, Source.Columns, Source.Depth);
      Result   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Multiply_Spectra (Source, Identity);
   begin
      AUnit.Assertions.Assert
        (DFT_Float32_C2_Close (Result, Source, 0.000_1),
         "Multiplying by 1+0i must reproduce the original spectrum");
   end Multiply_Spectra_Identity_Spectrum;

   procedure Multiply_Spectra_DFT_Convolution_Integration
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      A : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      B : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (A, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (A, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (A, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (B, 0, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (B, 0, 1, 5.0);

      declare
         Required : constant Positive := 4;
         Length   : constant Positive :=
           OpenCV.Core.Optimal_DFT_Size (Required);
         Padded_A : constant OpenCV.Core.Mat :=
           A.Copy_Make_Border
             (Top    => 0,
              Bottom => 0,
              Left   => 0,
              Right  => Length - A.Columns,
              Kind   => OpenCV.Core.Constant_Border,
              Value  => OpenCV.Core.Make_Scalar (0.0));
         Padded_B : constant OpenCV.Core.Mat :=
           B.Copy_Make_Border
             (Top    => 0,
              Bottom => 0,
              Left   => 0,
              Right  => Length - B.Columns,
              Kind   => OpenCV.Core.Constant_Border,
              Value  => OpenCV.Core.Make_Scalar (0.0));
         Product  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Multiply_Spectra
             (Padded_A.Discrete_Fourier_Transform,
              Padded_B.Discrete_Fourier_Transform);
         Result   : constant OpenCV.Core.Mat :=
           Product.Inverse_Real_Discrete_Fourier_Transform;
      begin
         AUnit.Assertions.Assert
           (Result.Rows = 1
            and then Result.Columns = Length
            and then Result.Channels = 1
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get (Result, 0, 0)),
                        4.0,
                        0.001)
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get (Result, 0, 1)),
                        13.0,
                        0.001)
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get (Result, 0, 2)),
                        22.0,
                        0.001)
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get (Result, 0, 3)),
                        15.0,
                        0.001),
            "Ordinary spectrum product of padded DFTs must recover the"
            & " linear convolution [4, 13, 22, 15]");
      end;
   end Multiply_Spectra_DFT_Convolution_Integration;

   procedure Multiply_Spectra_Noncontiguous_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left_Parent_Real  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 1));
      Left_Parent_Imag  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 1));
      Right_Parent_Real : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 1));
      Right_Parent_Imag : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 1));
   begin
      Left_Parent_Real.Set_To (OpenCV.Core.Make_Scalar (99.0));
      Left_Parent_Imag.Set_To (OpenCV.Core.Make_Scalar (88.0));
      Right_Parent_Real.Set_To (OpenCV.Core.Make_Scalar (77.0));
      Right_Parent_Imag.Set_To (OpenCV.Core.Make_Scalar (66.0));
      OpenCV.Core.Float32_Access.Set (Left_Parent_Real, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Left_Parent_Imag, 0, 1, 3.0);
      OpenCV.Core.Float32_Access.Set (Left_Parent_Real, 0, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Left_Parent_Imag, 0, 2, 0.0);
      OpenCV.Core.Float32_Access.Set (Left_Parent_Real, 1, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Left_Parent_Imag, 1, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Left_Parent_Real, 1, 2, 4.0);
      OpenCV.Core.Float32_Access.Set (Left_Parent_Imag, 1, 2, 5.0);
      OpenCV.Core.Float32_Access.Set (Right_Parent_Real, 0, 1, 4.0);
      OpenCV.Core.Float32_Access.Set (Right_Parent_Imag, 0, 1, 5.0);
      OpenCV.Core.Float32_Access.Set (Right_Parent_Real, 0, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Right_Parent_Imag, 0, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Right_Parent_Real, 1, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Right_Parent_Imag, 1, 1, 0.0);
      OpenCV.Core.Float32_Access.Set (Right_Parent_Real, 1, 2, 0.0);
      OpenCV.Core.Float32_Access.Set (Right_Parent_Imag, 1, 2, 1.0);

      declare
         Left_Parent  : constant OpenCV.Core.Mat :=
           Complex_Spectrum_From_Reals (Left_Parent_Real, Left_Parent_Imag);
         Right_Parent : constant OpenCV.Core.Mat :=
           Complex_Spectrum_From_Reals (Right_Parent_Real, Right_Parent_Imag);
         Left         : constant OpenCV.Core.Mat :=
           Left_Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
         Right        : constant OpenCV.Core.Mat :=
           Right_Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
         Result       : OpenCV.Core.Mat;
      begin
         AUnit.Assertions.Assert
           (not Left.Is_Continuous and then not Right.Is_Continuous,
            "Spectrum Region fixtures must be non-contiguous");
         Result := OpenCV.Core.Multiply_Spectra (Left, Right);
         AUnit.Assertions.Assert
           (Result.Rows = 2
            and then Result.Columns = 2
            and then Result.Channels = 2
            and then Complex_Channels_Close (Result, 0, 0, -7.0, 22.0, 0.000_1)
            and then Complex_Channels_Close (Result, 0, 1, 1.0, 1.0, 0.000_1)
            and then Complex_Channels_Close (Result, 1, 0, 0.0, 2.0, 0.000_1)
            and then Complex_Channels_Close (Result, 1, 1, -5.0, 4.0, 0.000_1),
            "Non-contiguous C2 Regions must multiply as independent"
            & " complex spectra");
         AUnit.Assertions.Assert
           (Complex_Channels_Close (Left, 0, 0, 2.0, 3.0, 0.000_1)
            and then Complex_Channels_Close (Right, 0, 0, 4.0, 5.0, 0.000_1)
            and then Complex_Channels_Close
                       (Left_Parent, 0, 0, 99.0, 88.0, 0.000_1)
            and then Complex_Channels_Close
                       (Right_Parent, 2, 3, 77.0, 66.0, 0.000_1),
            "Multiply_Spectra must leave Regions and parents unchanged");
         Result.Set_To (OpenCV.Core.Make_Scalar (12.0, 34.0));
         AUnit.Assertions.Assert
           (Complex_Channels_Close (Left, 0, 0, 2.0, 3.0, 0.000_1)
            and then Complex_Channels_Close (Right, 0, 0, 4.0, 5.0, 0.000_1),
            "Mutating a Region product must not mutate the source Regions");
      end;
   end Multiply_Spectra_Noncontiguous_Regions;

   procedure Multiply_Spectra_Result_Is_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : constant OpenCV.Core.Mat := Sample_Complex_Pair;
      Right  : constant OpenCV.Core.Mat := Sample_Complex_Right;
      Result : OpenCV.Core.Mat := OpenCV.Core.Multiply_Spectra (Left, Right);
   begin
      Result.Set_To (OpenCV.Core.Make_Scalar (50.0, 60.0));
      AUnit.Assertions.Assert
        (Complex_Channels_Close (Left, 0, 0, 2.0, 3.0, 0.000_1)
         and then Complex_Channels_Close (Right, 0, 0, 4.0, 5.0, 0.000_1),
         "Mutating the spectrum product must not change Left or Right");
   end Multiply_Spectra_Result_Is_Independent;

   procedure Multiply_Spectra_Rejects_Empty (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Empty_Left  : OpenCV.Core.Mat;
      Empty_Right : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 2));
      Valid       : constant OpenCV.Core.Mat := Sample_Complex_Pair;

      procedure Empty_Left_Operand is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := OpenCV.Core.Multiply_Spectra (Empty_Left, Valid);
      end Empty_Left_Operand;

      procedure Empty_Right_Operand is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := OpenCV.Core.Multiply_Spectra (Valid, Empty_Right);
      end Empty_Right_Operand;
   begin
      Assert_Raises_OpenCV_Error
        (Empty_Left_Operand'Access,
         "Multiply_Spectra must reject an empty Left Mat");
      Assert_Raises_OpenCV_Error
        (Empty_Right_Operand'Access,
         "Multiply_Spectra must reject an empty Right Mat");
   end Multiply_Spectra_Rejects_Empty;

   procedure Multiply_Spectra_Rejects_Shape_Mismatch
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 2));
      Right : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.Float32, 2));

      procedure Mismatched_Shape is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := OpenCV.Core.Multiply_Spectra (Left, Right);
      end Mismatched_Shape;
   begin
      Assert_Raises_OpenCV_Error
        (Mismatched_Shape'Access,
         "Multiply_Spectra must reject mismatched rows or columns");
   end Multiply_Spectra_Rejects_Shape_Mismatch;

   procedure Multiply_Spectra_Rejects_Depth_Mismatch_And_Integer
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Float32_C2 : constant OpenCV.Core.Mat := Sample_Complex_Pair;
      Float64_C2 : constant OpenCV.Core.Mat :=
        Float32_C2.Convert_To (OpenCV.Core.Float64);
      Int32_C2   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int32, 2));

      procedure Depth_Mismatch is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := OpenCV.Core.Multiply_Spectra (Float32_C2, Float64_C2);
      end Depth_Mismatch;

      procedure Integer_Depth is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := OpenCV.Core.Multiply_Spectra (Int32_C2, Int32_C2);
      end Integer_Depth;
   begin
      Assert_Raises_OpenCV_Error
        (Depth_Mismatch'Access,
         "Multiply_Spectra must reject Float32 C2 versus Float64 C2");
      Assert_Raises_OpenCV_Error
        (Integer_Depth'Access,
         "Multiply_Spectra must reject integer C2 spectra");
   end Multiply_Spectra_Rejects_Depth_Mismatch_And_Integer;

   procedure Multiply_Spectra_Rejects_Packed_And_Extra_Channels
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      C1 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      C3 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 3));

      procedure Packed_C1 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := OpenCV.Core.Multiply_Spectra (C1, C1);
      end Packed_C1;

      procedure Extra_C3 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := OpenCV.Core.Multiply_Spectra (C3, C3);
      end Extra_C3;
   begin
      Assert_Raises_OpenCV_Error
        (Packed_C1'Access,
         "Multiply_Spectra must reject packed C1 CCS spectra; the public"
         & " API accepts only explicit full-complex C2");
      Assert_Raises_OpenCV_Error
        (Extra_C3'Access,
         "Multiply_Spectra must reject C3 input; only explicit C2 spectra"
         & " are supported");
   end Multiply_Spectra_Rejects_Packed_And_Extra_Channels;

   function Packed_Product_Oracle_Matches
     (Left, Right : OpenCV.Core.Mat;
      Kind        : OpenCV.Core.Spectrum_Multiplication_Kind;
      Tolerance   : Long_Float) return Boolean
   is
      Packed_Product : constant OpenCV.Core.Mat :=
        OpenCV.Core.Multiply_Packed_Spectra
          (Left.Packed_Discrete_Fourier_Transform,
           Right.Packed_Discrete_Fourier_Transform,
           Kind);
      Packed_Result  : constant OpenCV.Core.Mat :=
        Packed_Product.Inverse_Packed_Discrete_Fourier_Transform;
      Complex_Result : constant OpenCV.Core.Mat :=
        OpenCV.Core.Multiply_Spectra
          (Left.Discrete_Fourier_Transform,
           Right.Discrete_Fourier_Transform,
           Kind)
          .Inverse_Real_Discrete_Fourier_Transform;
   begin
      return
        Packed_Product.Rows = Left.Rows
        and then Packed_Product.Columns = Left.Columns
        and then Packed_Product.Depth = Left.Depth
        and then Packed_Product.Channels = 1
        and then Packed_Result.Abs_Diff (Complex_Result).Norm < Tolerance;
   end Packed_Product_Oracle_Matches;

   procedure Multiply_Packed_Spectra_Float32_Products
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left  : constant OpenCV.Core.Mat := DFT_Sample_Real_Float32;
      Right : constant OpenCV.Core.Mat := Left.Clone;
   begin
      AUnit.Assertions.Assert
        (Packed_Product_Oracle_Matches
           (Left, Right, OpenCV.Core.Ordinary_Spectrum_Product, 0.001),
         "Float32 ordinary packed multiplication must match full-complex");
      AUnit.Assertions.Assert
        (Packed_Product_Oracle_Matches
           (Left, Right, OpenCV.Core.Conjugate_Right_Spectrum_Product, 0.001),
         "Float32 conjugate-right packed multiplication must match"
         & " full-complex");
   end Multiply_Packed_Spectra_Float32_Products;

   procedure Multiply_Packed_Spectra_Float64_Products
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left  : constant OpenCV.Core.Mat :=
        DFT_Sample_Real_Float32.Convert_To (OpenCV.Core.Float64);
      Right : constant OpenCV.Core.Mat := Left.Clone;
   begin
      AUnit.Assertions.Assert
        (Packed_Product_Oracle_Matches
           (Left, Right, OpenCV.Core.Ordinary_Spectrum_Product, 1.0E-10),
         "Float64 ordinary packed multiplication must match full-complex");
      AUnit.Assertions.Assert
        (Packed_Product_Oracle_Matches
           (Left,
            Right,
            OpenCV.Core.Conjugate_Right_Spectrum_Product,
            1.0E-10),
         "Float64 conjugate-right packed multiplication must match"
         & " full-complex");
   end Multiply_Packed_Spectra_Float64_Products;

   procedure Multiply_Packed_Spectra_Odd_Vectors_And_One_By_One
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Row    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 5, (OpenCV.Core.Float32, 1));
      Column : OpenCV.Core.Mat :=
        OpenCV.Core.Create (5, 1, (OpenCV.Core.Float32, 1));
      Unit   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
   begin
      for Index in 0 .. 4 loop
         OpenCV.Core.Float32_Access.Set
           (Row, 0, Index, Interfaces.IEEE_Float_32 (Index + 1));
         OpenCV.Core.Float32_Access.Set
           (Column, Index, 0, Interfaces.IEEE_Float_32 (Index + 2));
      end loop;
      OpenCV.Core.Float32_Access.Set (Unit, 0, 0, 3.0);

      AUnit.Assertions.Assert
        (Packed_Product_Oracle_Matches
           (Row, Row, OpenCV.Core.Ordinary_Spectrum_Product, 0.001)
         and then Packed_Product_Oracle_Matches
                    (Column,
                     Column,
                     OpenCV.Core.Conjugate_Right_Spectrum_Product,
                     0.001)
         and then Packed_Product_Oracle_Matches
                    (Unit, Unit, OpenCV.Core.Ordinary_Spectrum_Product, 0.001),
         "Packed multiplication must support odd row and column vectors"
         & " and 1x1");
   end Multiply_Packed_Spectra_Odd_Vectors_And_One_By_One;

   procedure Multiply_Packed_Spectra_Regions_And_Independence
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left_Parent  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 7, (OpenCV.Core.Float32, 1));
      Right_Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 7, (OpenCV.Core.Float32, 1));
   begin
      for Row in 0 .. 2 loop
         for Column in 0 .. 6 loop
            OpenCV.Core.Float32_Access.Set
              (Left_Parent,
               Row,
               Column,
               Interfaces.IEEE_Float_32 (Row * 7 + Column + 1));
            OpenCV.Core.Float32_Access.Set
              (Right_Parent,
               Row,
               Column,
               Interfaces.IEEE_Float_32 (Row * 7 + Column + 2));
         end loop;
      end loop;

      declare
         Left_Source         : constant OpenCV.Core.Mat :=
           Left_Parent.Region ((X => 1, Y => 0, Width => 5, Height => 3));
         Right_Source        : constant OpenCV.Core.Mat :=
           Right_Parent.Region ((X => 1, Y => 0, Width => 5, Height => 3));
         Left_Packed_Parent  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (3, 7, (OpenCV.Core.Float32, 1));
         Right_Packed_Parent : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (3, 7, (OpenCV.Core.Float32, 1));
         Left_Packed         : OpenCV.Core.Mat :=
           Left_Packed_Parent.Region
             ((X => 1, Y => 0, Width => 5, Height => 3));
         Right_Packed        : OpenCV.Core.Mat :=
           Right_Packed_Parent.Region
             ((X => 1, Y => 0, Width => 5, Height => 3));
      begin
         Left_Source.Packed_Discrete_Fourier_Transform.Copy_To (Left_Packed);
         Right_Source.Packed_Discrete_Fourier_Transform.Copy_To (Right_Packed);
         declare
            Left_Before    : constant OpenCV.Core.Mat := Left_Packed.Clone;
            Right_Before   : constant OpenCV.Core.Mat := Right_Packed.Clone;
            Product        : OpenCV.Core.Mat :=
              OpenCV.Core.Multiply_Packed_Spectra
                (Left_Packed,
                 Right_Packed,
                 OpenCV.Core.Conjugate_Right_Spectrum_Product);
            Packed_Result  : constant OpenCV.Core.Mat :=
              Product.Inverse_Packed_Discrete_Fourier_Transform;
            Complex_Result : constant OpenCV.Core.Mat :=
              OpenCV.Core.Multiply_Spectra
                (Left_Source.Discrete_Fourier_Transform,
                 Right_Source.Discrete_Fourier_Transform,
                 OpenCV.Core.Conjugate_Right_Spectrum_Product)
                .Inverse_Real_Discrete_Fourier_Transform;
         begin
            AUnit.Assertions.Assert
              (not Left_Packed.Is_Continuous
               and then not Right_Packed.Is_Continuous
               and then Packed_Result.Abs_Diff (Complex_Result).Norm < 0.001
               and then Left_Packed.Abs_Diff (Left_Before).Norm = 0.0
               and then Right_Packed.Abs_Diff (Right_Before).Norm = 0.0,
               "Non-contiguous packed Regions must match the full-complex"
               & " oracle and remain unchanged");
            Product.Set_To (OpenCV.Core.Make_Scalar (-17.0));
            AUnit.Assertions.Assert
              (Left_Packed.Abs_Diff (Left_Before).Norm = 0.0
               and then Right_Packed.Abs_Diff (Right_Before).Norm = 0.0,
               "Packed product storage must be independent of both operands");
         end;
      end;
   end Multiply_Packed_Spectra_Regions_And_Independence;

   procedure Multiply_Packed_Spectra_Rejects_Invalid_Inputs
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Mat : OpenCV.Core.Mat;
      Empty       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Float32_C1  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Float64_C1  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float64, 1));
      Wrong_Shape : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float32, 1));
      Float32_C2  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 2));
      Int32_C1    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Int32, 1));
      Float32_ND  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (OpenCV.Core.Dimension_Array'(1 => 2, 2 => 3, 3 => 1),
           (OpenCV.Core.Float32, 1));

      procedure Default_Left is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored :=
           OpenCV.Core.Multiply_Packed_Spectra (Default_Mat, Float32_C1);
      end Default_Left;
      procedure Empty_Right is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := OpenCV.Core.Multiply_Packed_Spectra (Float32_C1, Empty);
      end Empty_Right;
      procedure Mixed_Depth is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored :=
           OpenCV.Core.Multiply_Packed_Spectra (Float32_C1, Float64_C1);
      end Mixed_Depth;
      procedure Shape_Mismatch is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored :=
           OpenCV.Core.Multiply_Packed_Spectra (Float32_C1, Wrong_Shape);
      end Shape_Mismatch;
      procedure Full_Complex is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored :=
           OpenCV.Core.Multiply_Packed_Spectra (Float32_C2, Float32_C2);
      end Full_Complex;
      procedure Integer_Depth is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := OpenCV.Core.Multiply_Packed_Spectra (Int32_C1, Int32_C1);
      end Integer_Depth;
      procedure Not_Two_Dimensional is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored :=
           OpenCV.Core.Multiply_Packed_Spectra (Float32_ND, Float32_ND);
      end Not_Two_Dimensional;
   begin
      Assert_Raises_OpenCV_Error
        (Default_Left'Access, "Packed product rejects default Left");
      Assert_Raises_OpenCV_Error
        (Empty_Right'Access, "Packed product rejects empty Right");
      Assert_Raises_OpenCV_Error
        (Mixed_Depth'Access, "Packed product rejects mixed depth");
      Assert_Raises_OpenCV_Error
        (Shape_Mismatch'Access, "Packed product rejects shape mismatch");
      Assert_Raises_OpenCV_Error
        (Full_Complex'Access, "Packed product rejects C2 input");
      Assert_Raises_OpenCV_Error
        (Integer_Depth'Access, "Packed product rejects integer depth");
      Assert_Raises_OpenCV_Error
        (Not_Two_Dimensional'Access, "Packed product rejects non-2-D input");
   end Multiply_Packed_Spectra_Rejects_Invalid_Inputs;

   function DCT_Float32_C1_Close
     (Left, Right : OpenCV.Core.Mat; Tolerance : Long_Float) return Boolean is
   begin
      return DFT_Float32_C1_Close (Left, Right, Tolerance);
   end DCT_Float32_C1_Close;

   procedure Discrete_Cosine_Transform_Float32_Known_Forward
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 3, 1.0);

      declare
         Spectrum : constant OpenCV.Core.Mat :=
           Source.Discrete_Cosine_Transform;
         Inverse  : OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
      begin
         OpenCV.Core.Float32_Access.Set (Inverse, 0, 0, 2.0);
         OpenCV.Core.Float32_Access.Set (Inverse, 0, 1, 0.0);
         OpenCV.Core.Float32_Access.Set (Inverse, 0, 2, 0.0);
         OpenCV.Core.Float32_Access.Set (Inverse, 0, 3, 0.0);
         AUnit.Assertions.Assert
           (Spectrum.Rows = 1
            and then Spectrum.Columns = 4
            and then Spectrum.Depth = OpenCV.Core.Float32
            and then Spectrum.Channels = 1
            and then DCT_Float32_C1_Close (Spectrum, Inverse, 0.000_1),
            "OpenCV 4.10 DCT of [1,1,1,1] must be approximately [2,0,0,0]");
         declare
            Restored : constant OpenCV.Core.Mat :=
              Inverse.Inverse_Discrete_Cosine_Transform;
         begin
            AUnit.Assertions.Assert
              (DCT_Float32_C1_Close (Restored, Source, 0.000_1),
               "OpenCV 4.10 IDCT of [2,0,0,0] must recover [1,1,1,1]");
         end;
      end;
   end Discrete_Cosine_Transform_Float32_Known_Forward;

   procedure Discrete_Cosine_Transform_Float32_Round_Trip
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 3, 4.0);

      declare
         Spectrum : constant OpenCV.Core.Mat :=
           Source.Discrete_Cosine_Transform;
         Restored : constant OpenCV.Core.Mat :=
           Spectrum.Inverse_Discrete_Cosine_Transform;
      begin
         AUnit.Assertions.Assert
           (Spectrum.Rows = 1
            and then Spectrum.Columns = 4
            and then Spectrum.Depth = OpenCV.Core.Float32
            and then Spectrum.Channels = 1
            and then Restored.Rows = 1
            and then Restored.Columns = 4
            and then Restored.Depth = OpenCV.Core.Float32
            and then Restored.Channels = 1
            and then DCT_Float32_C1_Close (Restored, Source, 0.000_1),
            "Float32 DCT followed by IDCT must recover a nontrivial 1x4");
      end;
   end Discrete_Cosine_Transform_Float32_Round_Trip;

   procedure Discrete_Cosine_Transform_Float64_Round_Trip
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Source32, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Source32, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Source32, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Source32, 0, 3, 4.0);

      declare
         Source     : constant OpenCV.Core.Mat :=
           Source32.Convert_To (OpenCV.Core.Float64);
         Spectrum   : constant OpenCV.Core.Mat :=
           Source.Discrete_Cosine_Transform;
         Restored   : constant OpenCV.Core.Mat :=
           Spectrum.Inverse_Discrete_Cosine_Transform;
         Difference : constant OpenCV.Core.Scalar :=
           Restored.Abs_Diff (Source).Mean;
      begin
         AUnit.Assertions.Assert
           (Spectrum.Rows = 1
            and then Spectrum.Columns = 4
            and then Spectrum.Depth = OpenCV.Core.Float64
            and then Spectrum.Channels = 1
            and then Restored.Depth = OpenCV.Core.Float64
            and then Restored.Channels = 1
            and then Approximately_Equal
                       (Difference.Component_0, 0.0, 1.0E-12),
            "Float64 DCT followed by IDCT must preserve depth and recover"
            & " the signed source values");
      end;
   end Discrete_Cosine_Transform_Float64_Round_Trip;

   procedure Discrete_Cosine_Transform_Column_Vector
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 1, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 1, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Source, 2, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Source, 3, 0, 4.0);

      declare
         Spectrum : constant OpenCV.Core.Mat :=
           Source.Discrete_Cosine_Transform;
         Restored : constant OpenCV.Core.Mat :=
           Spectrum.Inverse_Discrete_Cosine_Transform;
      begin
         AUnit.Assertions.Assert
           (Spectrum.Rows = 4
            and then Spectrum.Columns = 1
            and then Spectrum.Channels = 1
            and then Restored.Rows = 4
            and then Restored.Columns = 1
            and then DCT_Float32_C1_Close (Restored, Source, 0.000_1),
            "A 4x1 DCT must remain a 1-D column transform and round-trip");
      end;
   end Discrete_Cosine_Transform_Column_Vector;

   procedure Discrete_Cosine_Transform_2D (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
   begin
      Source.Set_To (OpenCV.Core.Make_Scalar (1.0));

      declare
         Spectrum : constant OpenCV.Core.Mat :=
           Source.Discrete_Cosine_Transform;
         Restored : constant OpenCV.Core.Mat :=
           Spectrum.Inverse_Discrete_Cosine_Transform;
      begin
         AUnit.Assertions.Assert
           (Spectrum.Rows = 2
            and then Spectrum.Columns = 2
            and then Spectrum.Depth = OpenCV.Core.Float32
            and then Spectrum.Channels = 1
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get (Spectrum, 0, 0)),
                        2.0,
                        0.000_1)
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get (Spectrum, 0, 1)),
                        0.0,
                        0.000_1)
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get (Spectrum, 1, 0)),
                        0.0,
                        0.000_1)
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get (Spectrum, 1, 1)),
                        0.0,
                        0.000_1),
            "A constant 2x2 DCT must be a true 2-D DC-only spectrum");
         AUnit.Assertions.Assert
           (DCT_Float32_C1_Close (Restored, Source, 0.000_1),
            "A 2x2 DCT followed by IDCT must recover the source");
      end;
   end Discrete_Cosine_Transform_2D;

   procedure Discrete_Cosine_Transform_Noncontiguous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 1));
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      OpenCV.Core.Float32_Access.Set (Parent, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Parent, 0, 2, 2.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 1, 3.0);
      OpenCV.Core.Float32_Access.Set (Parent, 1, 2, 4.0);

      declare
         Region   : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
         Expected : OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
         Spectrum : OpenCV.Core.Mat;
         Restored : OpenCV.Core.Mat;
      begin
         OpenCV.Core.Float32_Access.Set (Expected, 0, 0, 1.0);
         OpenCV.Core.Float32_Access.Set (Expected, 0, 1, 2.0);
         OpenCV.Core.Float32_Access.Set (Expected, 1, 0, 3.0);
         OpenCV.Core.Float32_Access.Set (Expected, 1, 1, 4.0);
         AUnit.Assertions.Assert
           (not Region.Is_Continuous,
            "DCT Region fixture must be non-contiguous");
         Spectrum := Region.Discrete_Cosine_Transform;
         Restored := Spectrum.Inverse_Discrete_Cosine_Transform;
         AUnit.Assertions.Assert
           (Spectrum.Rows = 2
            and then Spectrum.Columns = 2
            and then Restored.Rows = 2
            and then Restored.Columns = 2
            and then DCT_Float32_C1_Close (Restored, Expected, 0.000_1),
            "A non-contiguous Region DCT must transform only Region values");
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Access.Get (Region, 0, 0) = 1.0
            and then OpenCV.Core.Float32_Access.Get (Region, 0, 1) = 2.0
            and then OpenCV.Core.Float32_Access.Get (Region, 1, 0) = 3.0
            and then OpenCV.Core.Float32_Access.Get (Region, 1, 1) = 4.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0
            and then OpenCV.Core.Float32_Access.Get (Parent, 2, 3) = 99.0,
            "DCT of a Region must leave the Region and parent unchanged");
         OpenCV.Core.Float32_Access.Set (Restored, 0, 0, 50.0);
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Access.Get (Region, 0, 0) = 1.0,
            "Mutating a Region DCT result must not mutate the Region");
      end;
   end Discrete_Cosine_Transform_Noncontiguous_Region;

   procedure Discrete_Cosine_Transform_Result_Is_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 1, 2.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 2, 3.0);
      OpenCV.Core.Float32_Access.Set (Source, 0, 3, 4.0);

      declare
         Spectrum : OpenCV.Core.Mat := Source.Discrete_Cosine_Transform;
         Restored : OpenCV.Core.Mat :=
           Spectrum.Inverse_Discrete_Cosine_Transform;
      begin
         OpenCV.Core.Float32_Access.Set (Spectrum, 0, 0, 123.0);
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Access.Get (Source, 0, 0) = 1.0
            and then OpenCV.Core.Float32_Access.Get (Source, 0, 3) = 4.0,
            "Mutating a DCT result must not change the source");
         OpenCV.Core.Float32_Access.Set (Restored, 0, 0, 77.0);
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Access.Get (Source, 0, 0) = 1.0
            and then OpenCV.Core.Float32_Access.Get (Spectrum, 0, 0) = 123.0,
            "Mutating an IDCT result must not change the source or spectrum");
      end;
   end Discrete_Cosine_Transform_Result_Is_Independent;

   procedure Discrete_Cosine_Transform_Rejects_Empty
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Source : OpenCV.Core.Mat;
      Empty_Source   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));

      procedure Forward_Default is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Default_Source.Discrete_Cosine_Transform;
      end Forward_Default;

      procedure Forward_Empty is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Empty_Source.Discrete_Cosine_Transform;
      end Forward_Empty;

      procedure Inverse_Empty is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Empty_Source.Inverse_Discrete_Cosine_Transform;
      end Inverse_Empty;
   begin
      Assert_Raises_OpenCV_Error
        (Forward_Default'Access,
         "Discrete_Cosine_Transform must reject a default empty Mat");
      Assert_Raises_OpenCV_Error
        (Forward_Empty'Access,
         "Discrete_Cosine_Transform must reject a typed 0x0 Mat");
      Assert_Raises_OpenCV_Error
        (Inverse_Empty'Access,
         "Inverse_Discrete_Cosine_Transform must reject empty input");
   end Discrete_Cosine_Transform_Rejects_Empty;

   procedure Discrete_Cosine_Transform_Rejects_Unsupported_Depth
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Int32_Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int32, 1));

      procedure Forward_UInt8 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := UInt8_Source.Discrete_Cosine_Transform;
      end Forward_UInt8;

      procedure Forward_Int32 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Int32_Source.Discrete_Cosine_Transform;
      end Forward_Int32;
   begin
      Assert_Raises_OpenCV_Error
        (Forward_UInt8'Access, "Discrete_Cosine_Transform must reject UInt8");
      Assert_Raises_OpenCV_Error
        (Forward_Int32'Access, "Discrete_Cosine_Transform must reject Int32");
   end Discrete_Cosine_Transform_Rejects_Unsupported_Depth;

   procedure Discrete_Cosine_Transform_Rejects_Invalid_Channels
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      C2 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 2));

      procedure Forward_C2 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := C2.Discrete_Cosine_Transform;
      end Forward_C2;
   begin
      Assert_Raises_OpenCV_Error
        (Forward_C2'Access,
         "Discrete_Cosine_Transform must reject C2; DCT is C1 only");
   end Discrete_Cosine_Transform_Rejects_Invalid_Channels;

   procedure Discrete_Cosine_Transform_Rejects_Odd_Vectors
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Row : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Col : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));

      procedure Forward_Row is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Row.Discrete_Cosine_Transform;
      end Forward_Row;

      procedure Forward_Col is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Col.Discrete_Cosine_Transform;
      end Forward_Col;
   begin
      Assert_Raises_OpenCV_Error
        (Forward_Row'Access,
         "Discrete_Cosine_Transform must reject a 1x3 odd-length vector");
      Assert_Raises_OpenCV_Error
        (Forward_Col'Access,
         "Discrete_Cosine_Transform must reject a 3x1 odd-length vector");
   end Discrete_Cosine_Transform_Rejects_Odd_Vectors;

   procedure Discrete_Cosine_Transform_Rejects_Odd_2D
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));

      procedure Forward is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Source.Discrete_Cosine_Transform;
      end Forward;
   begin
      Assert_Raises_OpenCV_Error
        (Forward'Access,
         "Discrete_Cosine_Transform must reject a 2x3 odd 2-D dimension");
   end Discrete_Cosine_Transform_Rejects_Odd_2D;

   procedure Discrete_Cosine_Transform_1x1_Is_Identity
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Source, 0, 0, -3.5);

      declare
         Forward        : constant OpenCV.Core.Mat :=
           Source.Discrete_Cosine_Transform;
         Restored       : constant OpenCV.Core.Mat :=
           Forward.Inverse_Discrete_Cosine_Transform;
         Direct_Inverse : constant OpenCV.Core.Mat :=
           Source.Inverse_Discrete_Cosine_Transform;
      begin
         AUnit.Assertions.Assert
           (Forward.Rows = 1
            and then Forward.Columns = 1
            and then Forward.Depth = OpenCV.Core.Float32
            and then Forward.Channels = 1
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get (Forward, 0, 0)),
                        -3.5,
                        0.000_1),
            "OpenCV 4.10 DCT of a 1x1 Mat must copy the signed value");
         AUnit.Assertions.Assert
           (Restored.Rows = 1
            and then Restored.Columns = 1
            and then Restored.Depth = OpenCV.Core.Float32
            and then Restored.Channels = 1
            and then DCT_Float32_C1_Close (Restored, Source, 0.000_1),
            "IDCT of a 1x1 DCT result must recover the signed source");
         AUnit.Assertions.Assert
           (Direct_Inverse.Rows = 1
            and then Direct_Inverse.Columns = 1
            and then Direct_Inverse.Depth = OpenCV.Core.Float32
            and then Direct_Inverse.Channels = 1
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get
                             (Direct_Inverse, 0, 0)),
                        -3.5,
                        0.000_1),
            "OpenCV 4.10 IDCT of a 1x1 Mat must copy the signed value");
      end;
   end Discrete_Cosine_Transform_1x1_Is_Identity;

   procedure Optimal_DCT_Size_Documented_Values
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
   begin
      AUnit.Assertions.Assert
        (OpenCV.Core.Optimal_DCT_Size (1) = 2
         and then OpenCV.Core.Optimal_DCT_Size (2) = 2
         and then OpenCV.Core.Optimal_DCT_Size (3) = 4
         and then OpenCV.Core.Optimal_DCT_Size (4) = 4
         and then OpenCV.Core.Optimal_DCT_Size (5) = 6
         and then OpenCV.Core.Optimal_DCT_Size (6) = 6
         and then OpenCV.Core.Optimal_DCT_Size (7) = 8
         and then OpenCV.Core.Optimal_DCT_Size (8) = 8
         and then OpenCV.Core.Optimal_DCT_Size (11) = 12
         and then OpenCV.Core.Optimal_DCT_Size (13) = 16
         and then OpenCV.Core.Optimal_DCT_Size (17) = 18
         and then OpenCV.Core.Optimal_DCT_Size (300) = 300
         and then OpenCV.Core.Optimal_DCT_Size (301) = 320,
         "Optimal_DCT_Size must follow OpenCV 4.10's documented"
         & " 2 * Optimal_DFT_Size(ceil(N / 2)) formula");
   end Optimal_DCT_Size_Documented_Values;

   procedure Optimal_DCT_Size_Factors_Are_Two_Three_Five
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Samples : constant array (Positive range <>) of Positive :=
        (1, 3, 5, 7, 11, 13, 17, 64, 301, 1_024, 4_097);
   begin
      for Sample of Samples loop
         declare
            Optimal : constant Positive :=
              OpenCV.Core.Optimal_DCT_Size (Sample);
         begin
            AUnit.Assertions.Assert
              (Optimal >= Sample
               and then Optimal mod 2 = 0
               and then Remainder_After_Factors_Two_Three_Five (Optimal / 2)
                        = 1,
               "Optimal_DCT_Size must return an even length whose"
               & " half is a 2/3/5 factorization");
         end;
      end loop;
   end Optimal_DCT_Size_Factors_Are_Two_Three_Five;

   procedure Optimal_DCT_Size_Upper_Bound (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);

      procedure Too_Large is
         Ignored : Positive;
      begin
         Ignored := OpenCV.Core.Optimal_DCT_Size (2_125_764_001);
      end Too_Large;
   begin
      AUnit.Assertions.Assert
        (OpenCV.Core.Optimal_DCT_Size (2_125_764_000) = 2_125_764_000,
         "The last successful OpenCV 4.10 optimal DCT size must be"
         & " 2125764000");
      Assert_Raises_OpenCV_Error
        (Too_Large'Access,
         "Optimal_DCT_Size must raise OpenCV_Error when doubling"
         & " exceeds signed 32-bit");
   end Optimal_DCT_Size_Upper_Bound;

   procedure Optimal_DCT_Size_Pads_For_DCT_Integration
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Minimum : constant Positive := 13;
      Optimal : constant Positive := OpenCV.Core.Optimal_DCT_Size (Minimum);
      Source  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 13, (OpenCV.Core.Float32, 1));
   begin
      AUnit.Assertions.Assert
        (Optimal = 16, "Optimal_DCT_Size (13) must be 16");

      for Column in 0 .. 12 loop
         OpenCV.Core.Float32_Access.Set
           (Source, 0, Column, Interfaces.IEEE_Float_32 (Column + 1));
      end loop;

      declare
         Padded   : constant OpenCV.Core.Mat :=
           Source.Copy_Make_Border
             (Top    => 0,
              Bottom => 0,
              Left   => 0,
              Right  => Optimal - Minimum,
              Kind   => OpenCV.Core.Constant_Border,
              Value  => OpenCV.Core.Make_Scalar (0.0));
         Spectrum : constant OpenCV.Core.Mat :=
           Padded.Discrete_Cosine_Transform;
         Restored : constant OpenCV.Core.Mat :=
           Spectrum.Inverse_Discrete_Cosine_Transform;
      begin
         AUnit.Assertions.Assert
           (Padded.Rows = 1
            and then Padded.Columns = Optimal
            and then Spectrum.Rows = 1
            and then Spectrum.Columns = Optimal
            and then Spectrum.Channels = 1
            and then Spectrum.Depth = OpenCV.Core.Float32
            and then Restored.Rows = 1
            and then Restored.Columns = Optimal
            and then Restored.Channels = 1
            and then Restored.Depth = OpenCV.Core.Float32
            and then DCT_Float32_C1_Close (Restored, Padded, 0.000_1),
            "Zero-padding to Optimal_DCT_Size must produce a DCT of"
            & " that length that round-trips");
      end;
   end Optimal_DCT_Size_Pads_For_DCT_Integration;

   function DCT_Rows_Sample return OpenCV.Core.Mat is
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 1));
   begin
      for Row in 0 .. 2 loop
         for Column in 0 .. 3 loop
            OpenCV.Core.Float32_Access.Set
              (Source,
               Row,
               Column,
               Interfaces.IEEE_Float_32
                 ((Row + 1) * (Column + 1) + Row * Row - Column));
         end loop;
      end loop;
      return Source;
   end DCT_Rows_Sample;

   procedure DCT_Rows_Forward_Matches_Independent_Rows
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32       : constant OpenCV.Core.Mat := DCT_Rows_Sample;
      Source64       : constant OpenCV.Core.Mat :=
        Source32.Convert_To (OpenCV.Core.Float64);
      Rows32         : constant OpenCV.Core.Mat :=
        Source32.Discrete_Cosine_Transform_Rows;
      Rows64         : constant OpenCV.Core.Mat :=
        Source64.Discrete_Cosine_Transform_Rows;
      All_Rows_Match : Boolean := True;
   begin
      AUnit.Assertions.Assert
        (Rows32.Rows = 3
         and then Rows32.Columns = 4
         and then Rows32.Depth = OpenCV.Core.Float32
         and then Rows32.Channels = 1,
         "DCT_ROWS must accept the 3x4 odd-row regression geometry");
      AUnit.Assertions.Assert
        (Rows64.Rows = 3
         and then Rows64.Columns = 4
         and then Rows64.Depth = OpenCV.Core.Float64
         and then Rows64.Channels = 1,
         "DCT_ROWS must preserve Float64 shape and type");

      for Row in 0 .. Source32.Rows - 1 loop
         declare
            Expected32 : constant OpenCV.Core.Mat :=
              Source32.Row_View (OpenCV.Core.Size_Coordinate (Row))
                .Discrete_Cosine_Transform;
            Actual32   : constant OpenCV.Core.Mat :=
              Rows32.Row_View (OpenCV.Core.Size_Coordinate (Row));
            Expected64 : constant OpenCV.Core.Mat :=
              Source64.Row_View (OpenCV.Core.Size_Coordinate (Row))
                .Discrete_Cosine_Transform;
            Actual64   : constant OpenCV.Core.Mat :=
              Rows64.Row_View (OpenCV.Core.Size_Coordinate (Row));
         begin
            All_Rows_Match :=
              All_Rows_Match
              and then DCT_Float32_C1_Close (Actual32, Expected32, 0.000_1)
              and then Actual64.Abs_Diff (Expected64).Norm < 1.0E-12;
         end;
      end loop;

      AUnit.Assertions.Assert
        (All_Rows_Match,
         "Each Float32 and Float64 DCT_ROWS row must match its ordinary DCT");
      declare
         Source_4x4 : OpenCV.Core.Mat :=
           OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
      begin
         for Row in 0 .. 3 loop
            for Column in 0 .. 3 loop
               OpenCV.Core.Float32_Access.Set
                 (Source_4x4,
                  Row,
                  Column,
                  Interfaces.IEEE_Float_32
                    ((Row + 1) * (Column + 2) + Row * Row - 2 * Column));
            end loop;
         end loop;
         AUnit.Assertions.Assert
           (Source_4x4.Discrete_Cosine_Transform_Rows.Abs_Diff
              (Source_4x4.Discrete_Cosine_Transform)
              .Norm
            > 0.1,
            "DCT_ROWS must differ from a true 2-D DCT for distinct"
            & " row signals");
      end;
   end DCT_Rows_Forward_Matches_Independent_Rows;

   procedure DCT_Rows_Round_Trip_One_Row_And_Unit_Length
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source32   : constant OpenCV.Core.Mat := DCT_Rows_Sample;
      Source64   : constant OpenCV.Core.Mat :=
        Source32.Convert_To (OpenCV.Core.Float64);
      Restored32 : constant OpenCV.Core.Mat :=
        Source32
          .Discrete_Cosine_Transform_Rows
          .Inverse_Discrete_Cosine_Transform_Rows;
      Restored64 : constant OpenCV.Core.Mat :=
        Source64
          .Discrete_Cosine_Transform_Rows
          .Inverse_Discrete_Cosine_Transform_Rows;
      One_Row    : constant OpenCV.Core.Mat := Source32.Row_View (1);
      Unit       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 1, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Float32_Access.Set (Unit, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Unit, 1, 0, -2.0);
      OpenCV.Core.Float32_Access.Set (Unit, 2, 0, 3.5);
      AUnit.Assertions.Assert
        (DCT_Float32_C1_Close (Restored32, Source32, 0.000_1),
         "Float32 row-wise DCT forward and inverse must round-trip");
      AUnit.Assertions.Assert
        (Restored64.Abs_Diff (Source64).Norm < 1.0E-12,
         "Float64 row-wise DCT forward and inverse must round-trip");
      AUnit.Assertions.Assert
        (One_Row.Discrete_Cosine_Transform_Rows.Abs_Diff
           (One_Row.Discrete_Cosine_Transform)
           .Norm
         < 0.000_1,
         "A one-row DCT_ROWS transform must equal ordinary DCT");
      AUnit.Assertions.Assert
        (DCT_Float32_C1_Close
           (Unit.Discrete_Cosine_Transform_Rows, Unit, 0.000_1),
         "OpenCV-supported row length one must transform each row"
         & " as identity");
   end DCT_Rows_Round_Trip_One_Row_And_Unit_Length;

   procedure DCT_Rows_Noncontiguous_And_Independent
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 6, (OpenCV.Core.Float32, 1));
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (99.0));
      for Row in 0 .. 2 loop
         for Column in 0 .. 3 loop
            OpenCV.Core.Float32_Access.Set
              (Parent,
               Row,
               Column + 1,
               Interfaces.IEEE_Float_32 (Row * 10 + Column + 1));
         end loop;
      end loop;
      declare
         Source   : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 4, Height => 3));
         Original : constant OpenCV.Core.Mat := Source.Clone;
         Spectrum : OpenCV.Core.Mat := Source.Discrete_Cosine_Transform_Rows;
         Restored : constant OpenCV.Core.Mat :=
           Spectrum.Inverse_Discrete_Cosine_Transform_Rows;
      begin
         AUnit.Assertions.Assert
           (not Source.Is_Continuous
            and then DCT_Float32_C1_Close (Restored, Original, 0.000_1),
            "DCT_ROWS must round-trip a non-contiguous Region");
         Spectrum.Set_To (OpenCV.Core.Make_Scalar (-50.0));
         AUnit.Assertions.Assert
           (DCT_Float32_C1_Close (Source, Original, 0.000_1)
            and then DCT_Float32_C1_Close (Restored, Original, 0.000_1)
            and then OpenCV.Core.Float32_Access.Get (Parent, 0, 0) = 99.0,
            "Row-wise results must own storage and leave source/parent"
            & " unchanged");
      end;
   end DCT_Rows_Noncontiguous_And_Independent;

   procedure DCT_Rows_Rejects_Invalid_Inputs (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Source : OpenCV.Core.Mat;
      Empty_Source   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Float32, 1));
      Odd_Length     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Integer_Source : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Int32, 1));
      C2_Source      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Float32, 2));

      procedure Forward_Default is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Default_Source.Discrete_Cosine_Transform_Rows;
      end Forward_Default;
      procedure Inverse_Empty is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Empty_Source.Inverse_Discrete_Cosine_Transform_Rows;
      end Inverse_Empty;
      procedure Forward_Odd is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Odd_Length.Discrete_Cosine_Transform_Rows;
      end Forward_Odd;
      procedure Forward_Integer is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := Integer_Source.Discrete_Cosine_Transform_Rows;
      end Forward_Integer;
      procedure Forward_C2 is
         Ignored : OpenCV.Core.Mat;
      begin
         Ignored := C2_Source.Discrete_Cosine_Transform_Rows;
      end Forward_C2;
   begin
      Assert_Raises_OpenCV_Error
        (Forward_Default'Access, "DCT_ROWS must reject a default Mat");
      Assert_Raises_OpenCV_Error
        (Inverse_Empty'Access,
         "Inverse DCT_ROWS must reject typed empty input");
      Assert_Raises_OpenCV_Error
        (Forward_Odd'Access, "DCT_ROWS must reject odd row lengths above one");
      Assert_Raises_OpenCV_Error
        (Forward_Integer'Access, "DCT_ROWS must reject integer depth");
      Assert_Raises_OpenCV_Error
        (Forward_C2'Access,
         "DCT_ROWS must reject channel counts other than one");
   end DCT_Rows_Rejects_Invalid_Inputs;

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      Copy_Make_Border_Region : constant Caller.Test_Method :=
        Copy_Make_Border_Region_Isolation_Lifetime_Empty_And_Validation'Access;
   begin
      Result.Add_Test
        (Caller.Create
           ("Border_Interpolate in-range coordinates",
            Border_Interpolate_In_Range_Coordinates'Access));
      Result.Add_Test
        (Caller.Create
           ("Border_Interpolate extrapolation mappings",
            Border_Interpolate_Extrapolation_Mappings'Access));
      Result.Add_Test
        (Caller.Create
           ("Border_Interpolate constant and length one",
            Border_Interpolate_Constant_And_Length_One'Access));
      Result.Add_Test
        (Caller.Create
           ("Border_Interpolate overflow boundaries",
            Border_Interpolate_Overflow_Boundaries'Access));
      Result.Add_Test
        (Caller.Create
           ("Border_Interpolate INT32_MAX",
            Border_Interpolate_Int32_Maximum'Access));
      Result.Add_Test
        (Caller.Create
           ("Transpose rectangular UInt8 exact mapping",
            Transpose_Rectangular_UInt8_Maps_All_Elements'Access));
      Result.Add_Test
        (Caller.Create
           ("Transpose square and vector shapes",
            Transpose_Square_And_Vector_Shapes'Access));
      Result.Add_Test
        (Caller.Create
           ("Transpose Float32 and UInt8 Vec3",
            Transpose_Float32_And_UInt8_Vec3'Access));
      Result.Add_Test
        (Caller.Create
           ("Transpose non-continuous Region",
            Transpose_Non_Continuous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Transpose storage independence and source lifetime",
            Transpose_Result_Is_Independent_And_Survives_Source'Access));
      Result.Add_Test
        (Caller.Create ("Transpose empty Mat", Transpose_Empty_Mat'Access));
      Result.Add_Test
        (Caller.Create
           ("Flip rectangular UInt8 exact mappings",
            Flip_Rectangular_UInt8_Maps_All_Elements'Access));
      Result.Add_Test
        (Caller.Create
           ("Flip shapes and involution", Flip_Shape_And_Involution'Access));
      Result.Add_Test
        (Caller.Create
           ("Flip Float32 and UInt8 Vec3",
            Flip_Float32_And_UInt8_Vec3'Access));
      Result.Add_Test
        (Caller.Create
           ("Flip non-continuous Region, independence, and lifetime",
            Flip_Region_Independence_And_Lifetime'Access));
      Result.Add_Test
        (Caller.Create ("Flip empty Mat", Flip_Empty_Mat'Access));
      Result.Add_Test
        (Caller.Create
           ("Rotate rectangular UInt8 exact mappings",
            Rotate_Rectangular_UInt8_Maps_All_Elements'Access));
      Result.Add_Test
        (Caller.Create
           ("Rotate shapes and element types",
            Rotate_Shapes_And_Element_Types'Access));
      Result.Add_Test
        (Caller.Create
           ("Rotate Region, independence, lifetime, and empty Mat",
            Rotate_Region_Independence_Lifetime_And_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("Rotate algebraic cross-checks and cycles",
            Rotate_Algebraic_Cross_Checks_And_Cycles'Access));
      Result.Add_Test
        (Caller.Create
           ("Repeat rectangular UInt8 exact mapping",
            Repeat_Rectangular_UInt8_Maps_All_Elements'Access));
      Result.Add_Test
        (Caller.Create
           ("Repeat identity and vector shapes",
            Repeat_Identity_And_Vector_Shapes'Access));
      Result.Add_Test
        (Caller.Create
           ("Repeat Float32 and UInt8 Vec3",
            Repeat_Float32_And_UInt8_Vec3'Access));
      Result.Add_Test
        (Caller.Create
           ("Repeat Region, lifetime, empty Mat, and size validation",
            Repeat_Region_Lifetime_Empty_And_Size_Validation'Access));
      Result.Add_Test
        (Caller.Create
           ("Copy_Make_Border UInt8 modes and constant value",
            Copy_Make_Border_UInt8_Modes_And_Constant_Value'Access));
      Result.Add_Test
        (Caller.Create
           ("Copy_Make_Border constant complete element type",
            Copy_Make_Border_Constant_Preserves_Complete_Element_Type'Access));
      Result.Add_Test
        (Caller.Create
           ("Copy_Make_Border Region isolation, lifetime, empty Mat,"
            & " and validation",
            Copy_Make_Border_Region));
      Result.Add_Test
        (Caller.Create
           ("HConcat UInt8 mapping and arbitrary array order",
            HConcat_UInt8_Mapping_And_Array_Order'Access));
      Result.Add_Test
        (Caller.Create
           ("HConcat Float32 and UInt8 Vec3",
            HConcat_Float32_And_UInt8_Vec3'Access));
      Result.Add_Test
        (Caller.Create
           ("HConcat Region, lifetime, empty input, and validation",
            HConcat_Region_Lifetime_Empty_And_Validation'Access));
      Result.Add_Test
        (Caller.Create
           ("VConcat UInt8 mapping, array order, and cross-check",
            VConcat_UInt8_Mapping_Array_Order_And_Cross_Check'Access));
      Result.Add_Test
        (Caller.Create
           ("VConcat Float32 and UInt8 Vec3",
            VConcat_Float32_And_UInt8_Vec3'Access));
      Result.Add_Test
        (Caller.Create
           ("VConcat Region, lifetime, empty input, and validation",
            VConcat_Region_Lifetime_Empty_And_Validation'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort every row ascending", Sort_Every_Row_Ascending'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort every row descending", Sort_Every_Row_Descending'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort every column ascending",
            Sort_Every_Column_Ascending'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort every column descending",
            Sort_Every_Column_Descending'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort defaults are Each_Row ascending",
            Sort_Defaults_Are_Each_Row_Ascending'Access));
      Result.Add_Test
        (Caller.Create ("Sort integer depths", Sort_Integer_Depths'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort Float64 preserves metadata",
            Sort_Float64_Preserves_Metadata'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort single row and column", Sort_Single_Row_And_Column'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort duplicate values", Sort_Duplicate_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort non-contiguous Region independence",
            Sort_Noncontiguous_Region_Is_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort result is independent of source",
            Sort_Result_Is_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort rejects multi-channel", Sort_Rejects_Multi_Channel'Access));
      Result.Add_Test
        (Caller.Create ("Sort rejects Float16", Sort_Rejects_Float16'Access));
      Result.Add_Test
        (Caller.Create ("Sort empty Mats", Sort_Empty_Mats'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort_Indices every row ascending",
            Sort_Indices_Every_Row_Ascending'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort_Indices every row descending",
            Sort_Indices_Every_Row_Descending'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort_Indices every column ascending",
            Sort_Indices_Every_Column_Ascending'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort_Indices every column descending",
            Sort_Indices_Every_Column_Descending'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort_Indices defaults are Each_Row ascending",
            Sort_Indices_Defaults_Are_Each_Row_Ascending'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort_Indices cross-check against Sort",
            Sort_Indices_Cross_Check_Against_Sort'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort_Indices supported depths",
            Sort_Indices_Supported_Depths'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort_Indices duplicate values",
            Sort_Indices_Duplicate_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort_Indices single row and column",
            Sort_Indices_Single_Row_And_Column'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort_Indices non-contiguous Region independence",
            Sort_Indices_Noncontiguous_Region_Is_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort_Indices result is independent of source",
            Sort_Indices_Result_Is_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort_Indices rejects multi-channel",
            Sort_Indices_Rejects_Multi_Channel'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort_Indices rejects Float16",
            Sort_Indices_Rejects_Float16'Access));
      Result.Add_Test
        (Caller.Create
           ("Sort_Indices empty Mats", Sort_Indices_Empty_Mats'Access));
      Result.Add_Test
        (Caller.Create
           ("Complete_Symmetry default copies upper to lower",
            Complete_Symmetry_Default_Copies_Upper_To_Lower'Access));
      Result.Add_Test
        (Caller.Create
           ("Complete_Symmetry explicit Upper_Triangle",
            Complete_Symmetry_Explicit_Upper_Triangle'Access));
      Result.Add_Test
        (Caller.Create
           ("Complete_Symmetry Lower_Triangle",
            Complete_Symmetry_Lower_Triangle'Access));
      Result.Add_Test
        (Caller.Create
           ("Complete_Symmetry already symmetric matrix",
            Complete_Symmetry_Already_Symmetric'Access));
      Result.Add_Test
        (Caller.Create
           ("Complete_Symmetry 1x1", Complete_Symmetry_One_By_One'Access));
      Result.Add_Test
        (Caller.Create
           ("Complete_Symmetry supports Float64",
            Complete_Symmetry_Supports_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("Complete_Symmetry copies entire Vec3",
            Complete_Symmetry_Copies_Entire_Vec3'Access));
      Result.Add_Test
        (Caller.Create
           ("Complete_Symmetry non-contiguous Region",
            Complete_Symmetry_Noncontiguous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Complete_Symmetry shallow alias observes mutation",
            Complete_Symmetry_Shallow_Alias'Access));
      Result.Add_Test
        (Caller.Create
           ("Complete_Symmetry leaves a Clone independent",
            Complete_Symmetry_Clone_Remains_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Complete_Symmetry empty behavior",
            Complete_Symmetry_Empty_Behavior'Access));
      Result.Add_Test
        (Caller.Create
           ("Complete_Symmetry rejects rectangular Mat",
            Complete_Symmetry_Rejects_Rectangular'Access));
      Result.Add_Test
        (Caller.Create
           ("Complete_Symmetry rejects unsupported depths",
            Complete_Symmetry_Rejects_Unsupported_Depths'Access));
      Result.Add_Test
        (Caller.Create
           ("Set_Identity default square Float32",
            Set_Identity_Default_Square_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Set_Identity scaled Float32",
            Set_Identity_Scaled_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Set_Identity wide rectangular Mat",
            Set_Identity_Wide_Rectangular'Access));
      Result.Add_Test
        (Caller.Create
           ("Set_Identity tall rectangular Mat",
            Set_Identity_Tall_Rectangular'Access));
      Result.Add_Test
        (Caller.Create
           ("Set_Identity one-row and one-column",
            Set_Identity_One_Row_And_One_Column'Access));
      Result.Add_Test
        (Caller.Create
           ("Set_Identity default multi-channel Scalar",
            Set_Identity_Default_Multi_Channel'Access));
      Result.Add_Test
        (Caller.Create
           ("Set_Identity explicit multi-channel Scalar",
            Set_Identity_Explicit_Multi_Channel'Access));
      Result.Add_Test
        (Caller.Create
           ("Set_Identity four channels", Set_Identity_Four_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("Set_Identity rejects more than four channels",
            Set_Identity_Rejects_Five_Channels'Access));
      Result.Add_Test
        (Caller.Create ("Set_Identity UInt8", Set_Identity_UInt8'Access));
      Result.Add_Test
        (Caller.Create
           ("Set_Identity UInt8 uses OpenCV conversion",
            Set_Identity_UInt8_Uses_OpenCV_Conversion'Access));
      Result.Add_Test
        (Caller.Create ("Set_Identity Int32", Set_Identity_Int32'Access));
      Result.Add_Test
        (Caller.Create ("Set_Identity Float64", Set_Identity_Float64'Access));
      Result.Add_Test
        (Caller.Create ("Set_Identity Float16", Set_Identity_Float16'Access));
      Result.Add_Test
        (Caller.Create
           ("Set_Identity non-contiguous Region",
            Set_Identity_Noncontiguous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Set_Identity shallow alias observes mutation",
            Set_Identity_Shallow_Alias'Access));
      Result.Add_Test
        (Caller.Create
           ("Set_Identity leaves a Clone independent",
            Set_Identity_Clone_Remains_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Set_Identity empty behavior",
            Set_Identity_Empty_Behavior'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform Float32 C3 to C1 linear",
            Transform_Float32_C3_To_C1_Linear'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform Float32 C3 to C2 affine",
            Transform_Float32_C3_To_C2_Affine'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform C3 channel permutation",
            Transform_C3_Channel_Permutation'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform single-channel affine fast path",
            Transform_Single_Channel_Affine_Fast_Path'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform UInt8 saturation", Transform_UInt8_Saturates'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform Int32 source",
            Transform_Int32_Uses_Float64_Coefficient_Path'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform Float64 source",
            Transform_Float64_Preserves_Depth'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform remaining supported depths",
            Transform_Remaining_Supported_Depths'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform rejects Float16", Transform_Rejects_Float16'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform Float64 coefficients with Float32 Self",
            Transform_Float64_Coefficients_With_Float32_Self'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform non-contiguous source Region",
            Transform_Noncontiguous_Source_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform non-contiguous Coefficients Region",
            Transform_Noncontiguous_Coefficients_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform result is independent",
            Transform_Result_Is_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform linear matches zero-bias affine",
            Transform_Linear_Matches_Zero_Bias_Affine'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform more than four output channels",
            Transform_More_Than_Four_Output_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform rejects five source channels",
            Transform_Rejects_Five_Source_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform rejects invalid coefficient columns",
            Transform_Rejects_Invalid_Coefficient_Columns'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform rejects multi-channel coefficients",
            Transform_Rejects_Multi_Channel_Coefficients'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform rejects integer coefficients",
            Transform_Rejects_Integer_Coefficients'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform rejects excess output channels",
            Transform_Rejects_Excess_Output_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("Transform rejects empty inputs",
            Transform_Rejects_Empty_Inputs'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform Float32 C2 genuine mapping",
            Perspective_Transform_Float32_C2_Genuine'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform C2 identity",
            Perspective_Transform_C2_Identity'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform Float32 C3 4x4",
            Perspective_Transform_Float32_C3_4x4'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform Float64 source",
            Perspective_Transform_Float64_Source'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform Float32 matrix with Float64 source",
            Perspective_Transform_Float32_Matrix_With_Float64_Source'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform Float64 matrix with Float32 source",
            Perspective_Transform_Float64_Matrix_With_Float32_Source'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform zero denominator",
            Perspective_Transform_Zero_Denominator'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform near-zero denominator",
            Perspective_Transform_Near_Zero_Denominator'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform negative denominator",
            Perspective_Transform_Negative_Denominator'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform non-contiguous source Region",
            Perspective_Transform_Noncontiguous_Source_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform non-contiguous matrix Region",
            Perspective_Transform_Noncontiguous_Matrix_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform result is independent",
            Perspective_Transform_Result_Is_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform rejects invalid source depth",
            Perspective_Transform_Rejects_Invalid_Source_Depth'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform rejects invalid source channels",
            Perspective_Transform_Rejects_Invalid_Source_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform rejects invalid matrix depth",
            Perspective_Transform_Rejects_Invalid_Matrix_Depth'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform rejects invalid matrix channels",
            Perspective_Transform_Rejects_Invalid_Matrix_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform rejects wrong C2 matrix dimensions",
            Perspective_Transform_Rejects_Wrong_C2_Matrix_Dimensions'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform rejects wrong C3 matrix dimensions",
            Perspective_Transform_Rejects_Wrong_C3_Matrix_Dimensions'Access));
      Result.Add_Test
        (Caller.Create
           ("Perspective_Transform rejects empty inputs",
            Perspective_Transform_Rejects_Empty_Inputs'Access));
      Result.Add_Test
        (Caller.Create
           ("DFT real forward output type",
            Discrete_Fourier_Transform_Real_Forward_Output_Type'Access));
      Result.Add_Test
        (Caller.Create
           ("DFT real round trip uses DFT_SCALE",
            Discrete_Fourier_Transform_Real_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("DFT complex round trip uses DFT_SCALE",
            Discrete_Fourier_Transform_Complex_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("DFT origin impulse has real 1 and imaginary 0",
            Discrete_Fourier_Transform_Impulse_Spectrum'Access));
      Result.Add_Test
        (Caller.Create
           ("DFT constant input has expected unscaled DC",
            Discrete_Fourier_Transform_Constant_DC'Access));
      Result.Add_Test
        (Caller.Create
           ("DFT row vector round trip",
            Discrete_Fourier_Transform_Row_Vector'Access));
      Result.Add_Test
        (Caller.Create
           ("DFT column vector round trip",
            Discrete_Fourier_Transform_Column_Vector'Access));
      Result.Add_Test
        (Caller.Create
           ("DFT non-contiguous Region round trip",
            Discrete_Fourier_Transform_Noncontiguous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("DFT result is independent of source",
            Discrete_Fourier_Transform_Result_Is_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("DFT rejects empty input",
            Discrete_Fourier_Transform_Rejects_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("DFT rejects unsupported depth",
            Discrete_Fourier_Transform_Rejects_Unsupported_Depth'Access));
      Result.Add_Test
        (Caller.Create
           ("DFT rejects invalid channel counts",
            Discrete_Fourier_Transform_Rejects_Invalid_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("Packed DFT Float32 forward and full-complex oracle round trip",
            Packed_DFT_Float32_Forward_And_Oracle_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("Packed DFT Float64 forward and full-complex oracle round trip",
            Packed_DFT_Float64_Forward_And_Oracle_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("Packed DFT odd row and column vectors",
            Packed_DFT_Row_And_Column_Vectors'Access));
      Result.Add_Test
        (Caller.Create
           ("Packed DFT non-contiguous Region and independent storage",
            Packed_DFT_Noncontiguous_Region_And_Independence'Access));
      Result.Add_Test
        (Caller.Create
           ("Packed DFT rejects empty, integer, and C2 inputs",
            Packed_DFT_Rejects_Invalid_Inputs'Access));
      Result.Add_Test
        (Caller.Create
           ("DFT_ROWS forward matches independent row DFTs",
            DFT_Rows_Forward_Matches_Independent_Rows'Access));
      Result.Add_Test
        (Caller.Create
           ("DFT_ROWS one row matches ordinary DFT",
            DFT_Rows_One_Row_Matches_Ordinary_DFT'Access));
      Result.Add_Test
        (Caller.Create
           ("DFT_ROWS real Float32 and Float64 round trips",
            DFT_Rows_Real_Round_Trips'Access));
      Result.Add_Test
        (Caller.Create
           ("DFT_ROWS complex round trip and ownership independence",
            DFT_Rows_Complex_Round_Trip_And_Independence'Access));
      Result.Add_Test
        (Caller.Create
           ("DFT_ROWS non-contiguous Region",
            DFT_Rows_Noncontiguous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("DFT_ROWS rejects invalid inputs",
            DFT_Rows_Rejects_Invalid_Inputs'Access));
      Result.Add_Test
        (Caller.Create
           ("Optimal_DFT_Size already-efficient values",
            Optimal_DFT_Size_Already_Optimal'Access));
      Result.Add_Test
        (Caller.Create
           ("Optimal_DFT_Size rounds up", Optimal_DFT_Size_Rounds_Up'Access));
      Result.Add_Test
        (Caller.Create
           ("Optimal_DFT_Size results factor as 2, 3, and 5",
            Optimal_DFT_Size_Factors_Are_Two_Three_Five'Access));
      Result.Add_Test
        (Caller.Create
           ("Optimal_DFT_Size OpenCV 4.10 upper bound",
            Optimal_DFT_Size_Upper_Bound'Access));
      Result.Add_Test
        (Caller.Create
           ("Optimal_DFT_Size pads a small DFT",
            Optimal_DFT_Size_Pads_For_DFT_Integration'Access));
      Result.Add_Test
        (Caller.Create
           ("Multiply_Spectra ordinary Float32 complex product",
            Multiply_Spectra_Ordinary_Float32_Product'Access));
      Result.Add_Test
        (Caller.Create
           ("Multiply_Spectra conjugate-right Float32 product",
            Multiply_Spectra_Conjugate_Right_Float32_Product'Access));
      Result.Add_Test
        (Caller.Create
           ("Multiply_Spectra Float64 complex product",
            Multiply_Spectra_Float64_Product'Access));
      Result.Add_Test
        (Caller.Create
           ("Multiply_Spectra is element-wise complex multiplication",
            Multiply_Spectra_Is_Elementwise_Complex'Access));
      Result.Add_Test
        (Caller.Create
           ("Multiply_Spectra identity spectrum",
            Multiply_Spectra_Identity_Spectrum'Access));
      Result.Add_Test
        (Caller.Create
           ("Multiply_Spectra DFT convolution integration",
            Multiply_Spectra_DFT_Convolution_Integration'Access));
      Result.Add_Test
        (Caller.Create
           ("Multiply_Spectra non-contiguous Regions",
            Multiply_Spectra_Noncontiguous_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("Multiply_Spectra result is independent",
            Multiply_Spectra_Result_Is_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Multiply_Spectra rejects empty inputs",
            Multiply_Spectra_Rejects_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("Multiply_Spectra rejects shape mismatch",
            Multiply_Spectra_Rejects_Shape_Mismatch'Access));
      Result.Add_Test
        (Caller.Create
           ("Multiply_Spectra rejects depth mismatch and integer depth",
            Multiply_Spectra_Rejects_Depth_Mismatch_And_Integer'Access));
      Result.Add_Test
        (Caller.Create
           ("Multiply_Spectra rejects packed C1 and C3",
            Multiply_Spectra_Rejects_Packed_And_Extra_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("Multiply_Packed_Spectra Float32 ordinary and conjugate products",
            Multiply_Packed_Spectra_Float32_Products'Access));
      Result.Add_Test
        (Caller.Create
           ("Multiply_Packed_Spectra Float64 ordinary and conjugate products",
            Multiply_Packed_Spectra_Float64_Products'Access));
      Result.Add_Test
        (Caller.Create
           ("Multiply_Packed_Spectra odd vectors and 1x1",
            Multiply_Packed_Spectra_Odd_Vectors_And_One_By_One'Access));
      Result.Add_Test
        (Caller.Create
           ("Multiply_Packed_Spectra Regions and independent storage",
            Multiply_Packed_Spectra_Regions_And_Independence'Access));
      Result.Add_Test
        (Caller.Create
           ("Multiply_Packed_Spectra rejects invalid inputs",
            Multiply_Packed_Spectra_Rejects_Invalid_Inputs'Access));
      Result.Add_Test
        (Caller.Create
           ("DCT Float32 known 1-D forward coefficients",
            Discrete_Cosine_Transform_Float32_Known_Forward'Access));
      Result.Add_Test
        (Caller.Create
           ("DCT Float32 1-D round trip",
            Discrete_Cosine_Transform_Float32_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("DCT Float64 1-D round trip",
            Discrete_Cosine_Transform_Float64_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("DCT column vector 1-D round trip",
            Discrete_Cosine_Transform_Column_Vector'Access));
      Result.Add_Test
        (Caller.Create
           ("DCT 2-D constant DC-only and round trip",
            Discrete_Cosine_Transform_2D'Access));
      Result.Add_Test
        (Caller.Create
           ("DCT non-contiguous Region",
            Discrete_Cosine_Transform_Noncontiguous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("DCT result is independent",
            Discrete_Cosine_Transform_Result_Is_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("DCT rejects empty input",
            Discrete_Cosine_Transform_Rejects_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("DCT rejects unsupported depth",
            Discrete_Cosine_Transform_Rejects_Unsupported_Depth'Access));
      Result.Add_Test
        (Caller.Create
           ("DCT rejects C2",
            Discrete_Cosine_Transform_Rejects_Invalid_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("DCT rejects odd 1-D vectors",
            Discrete_Cosine_Transform_Rejects_Odd_Vectors'Access));
      Result.Add_Test
        (Caller.Create
           ("DCT rejects odd 2-D dimensions",
            Discrete_Cosine_Transform_Rejects_Odd_2D'Access));
      Result.Add_Test
        (Caller.Create
           ("DCT 1x1 is identity",
            Discrete_Cosine_Transform_1x1_Is_Identity'Access));
      Result.Add_Test
        (Caller.Create
           ("DCT_ROWS forward matches independent row DCTs",
            DCT_Rows_Forward_Matches_Independent_Rows'Access));
      Result.Add_Test
        (Caller.Create
           ("DCT_ROWS round trips, one row, and row length one",
            DCT_Rows_Round_Trip_One_Row_And_Unit_Length'Access));
      Result.Add_Test
        (Caller.Create
           ("DCT_ROWS non-contiguous Region and independent storage",
            DCT_Rows_Noncontiguous_And_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("DCT_ROWS rejects invalid inputs",
            DCT_Rows_Rejects_Invalid_Inputs'Access));
      Result.Add_Test
        (Caller.Create
           ("Optimal_DCT_Size documented values",
            Optimal_DCT_Size_Documented_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Optimal_DCT_Size results factor as 2, 3, and 5",
            Optimal_DCT_Size_Factors_Are_Two_Three_Five'Access));
      Result.Add_Test
        (Caller.Create
           ("Optimal_DCT_Size OpenCV 4.10 upper bound",
            Optimal_DCT_Size_Upper_Bound'Access));
      Result.Add_Test
        (Caller.Create
           ("Optimal_DCT_Size pads a small DCT",
            Optimal_DCT_Size_Pads_For_DCT_Integration'Access));

      return Result'Access;

   end Suite;

end Mat_Transform_Tests;
