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
      return Result'Access;
   end Suite;

end Mat_Transform_Tests;
