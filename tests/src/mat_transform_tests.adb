with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;

package body Mat_Transform_Tests is

   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_8;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.UInt8_Vec3.Vector;

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
      Empty_Inputs  : OpenCV.Core.Mat_Array (0 .. 1) := (others => Empty);

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
            "VConcat must survive source finalization and accept empty inputs");
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

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
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
            Copy_Make_Border_Region_Isolation_Lifetime_Empty_And_Validation'Access));
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
      return Result'Access;

   end Suite;

end Mat_Transform_Tests;
