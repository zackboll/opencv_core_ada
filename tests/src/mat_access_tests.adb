with AUnit.Assertions;
with AUnit.Test_Caller;
with Ada.Exceptions;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float32_Buffer_Access;
with OpenCV.Core.Float32_Mat_View;
with OpenCV.Core.Float32_Row_Access;
with OpenCV.Core.Float32_Vec3;
with OpenCV.Core.Float32_Vec3_Access;
with OpenCV.Core.Float32_Vec3_Buffer_Access;
with OpenCV.Core.Float32_Vec3_Mat_View;
with OpenCV.Core.Float32_Vec3_Row_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Buffer_Access;
with OpenCV.Core.UInt8_Mat_View;
with OpenCV.Core.UInt8_Row_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;
with OpenCV.Core.UInt8_Vec3_Buffer_Access;
with OpenCV.Core.UInt8_Vec3_Mat_View;
with OpenCV.Core.UInt8_Vec3_Row_Access;
with Mat_Test_Support;

package body Mat_Access_Tests is

   use type Ada.Exceptions.Exception_Id;
   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_8;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.UInt8_Row_Access.Row_Array;
   use type OpenCV.Core.UInt8_Vec3.Vector;
   use type OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array;

   use Mat_Test_Support;

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

   Borrowed_Row_Callback_Error : exception;

   procedure Float32_Borrowed_Writable_Row_Is_Zero_Copy
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Alias : OpenCV.Core.Mat;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float32_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data'Length = 3,
            "A writable borrowed Float32 row must use zero-based columns");

         Data (1) := 42.5;
         AUnit.Assertions.Assert
           (Approximately_Equal
              (Long_Float
                 (OpenCV.Core.Float32_Access.Get
                    (Image, Row => 1, Column => 1)),
               42.5),
            "A write through the borrowed row must be immediately visible"
            & " through Get");

         OpenCV.Core.Float32_Access.Set
           (Alias, Row => 1, Column => 2, Value => -7.25);
         AUnit.Assertions.Assert
           (Approximately_Equal (Long_Float (Data (2)), -7.25),
            "A write through a shallow alias must be immediately visible"
            & " through the borrowed row");
      end Mutate;
   begin
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 1, Column => 0, Value => 1.0);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 1, Column => 1, Value => 2.0);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 1, Column => 2, Value => 3.0);
      Alias := Image;

      OpenCV.Core.Float32_Row_Access.With_Writable_Row
        (Image, Row => 1, Process => Mutate'Access);

      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get (Image, Row => 1, Column => 0)),
            1.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Image, Row => 1, Column => 1)),
                     42.5)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Image, Row => 1, Column => 2)),
                     -7.25),
         "Writable borrowed-row mutations must remain after Process returns");
   end Float32_Borrowed_Writable_Row_Is_Zero_Copy;

   procedure Float32_Borrowed_Read_Only_Row_Matches_Mat
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));

      procedure Inspect
        (Data : aliased OpenCV.Core.Float32_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 3 and then Data'Length = 4,
            "A read-only borrowed Float32 row must use zero-based columns");
         AUnit.Assertions.Assert
           (Approximately_Equal (Long_Float (Data (0)), 0.5)
            and then Approximately_Equal (Long_Float (Data (1)), 1.5)
            and then Approximately_Equal (Long_Float (Data (2)), 2.5)
            and then Approximately_Equal (Long_Float (Data (3)), 3.5),
            "A read-only borrowed Float32 row must match the Mat values");
      end Inspect;
   begin
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 0, Value => 0.5);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 1, Value => 1.5);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 2, Value => 2.5);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 3, Value => 3.5);

      OpenCV.Core.Float32_Row_Access.With_Read_Only_Row
        (Image, Row => 0, Process => Inspect'Access);
   end Float32_Borrowed_Read_Only_Row_Matches_Mat;

   procedure Float32_Borrowed_Row_Handles_Non_Continuous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 6,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      View   : OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float32_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data'Length = 3,
            "A borrowed Region row must be indexed relative to the Region");
         Data (0) := 11.0;
         Data (2) := 13.0;
      end Mutate;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (1.0));
      AUnit.Assertions.Assert
        (not View.Is_Continuous,
         "A partial-width multi-row Region must be non-continuous");

      OpenCV.Core.Float32_Row_Access.With_Writable_Row
        (View, Row => 0, Process => Mutate'Access);

      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get (Parent, Row => 1, Column => 1)),
            11.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Parent, Row => 1, Column => 3)),
                     13.0),
         "Borrowed Region writes must mutate the corresponding parent"
         & " elements");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get (Parent, Row => 1, Column => 0)),
            1.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Parent, Row => 1, Column => 4)),
                     1.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Parent, Row => 1, Column => 2)),
                     1.0),
         "Borrowed Region writes must not expose or mutate parent padding");
   end Float32_Borrowed_Row_Handles_Non_Continuous_Region;

   procedure Float32_Borrowed_Row_Rejects_Invalid_Mats_And_Indices
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      RGB_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      Valid_Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Invoked     : Boolean := False;

      procedure Mark_Read
        (Data : aliased OpenCV.Core.Float32_Row_Access.Row_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_Read;

      procedure Mark_Write
        (Data : aliased in out OpenCV.Core.Float32_Row_Access.Row_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_Write;

      procedure Read_UInt8 is
      begin
         OpenCV.Core.Float32_Row_Access.With_Read_Only_Row
           (UInt8_Image, Row => 0, Process => Mark_Read'Access);
      end Read_UInt8;

      procedure Read_Multi_Channel is
      begin
         OpenCV.Core.Float32_Row_Access.With_Read_Only_Row
           (RGB_Image, Row => 0, Process => Mark_Read'Access);
      end Read_Multi_Channel;

      procedure Write_Past_Last is
      begin
         OpenCV.Core.Float32_Row_Access.With_Writable_Row
           (Valid_Image, Row => 1, Process => Mark_Write'Access);
      end Write_Past_Last;
   begin
      Assert_Raises_OpenCV_Error
        (Read_UInt8'Access,
         "Float32 borrowed-row access must reject a UInt8 Mat");
      Assert_Raises_OpenCV_Error
        (Read_Multi_Channel'Access,
         "Float32 borrowed-row access must reject a multi-channel Mat");
      Assert_Raises_OpenCV_Error
        (Write_Past_Last'Access,
         "Float32 borrowed-row access must reject a row equal to Rows");
      AUnit.Assertions.Assert
        (not Invoked, "Borrowed-row validation must not invoke the callback");
   end Float32_Borrowed_Row_Rejects_Invalid_Mats_And_Indices;

   procedure Float32_Borrowed_Row_Propagates_Callback_Exception
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Raised  : Boolean := False;
      Message : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float32_Row_Access.Row_Array) is
      begin
         Data (0) := 9.0;
         raise Borrowed_Row_Callback_Error;
      end Mutate;
   begin
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 0, Value => 1.0);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 1, Value => 2.0);

      begin
         OpenCV.Core.Float32_Row_Access.With_Writable_Row
           (Image, Row => 0, Process => Mutate'Access);
      exception
         when Error : Borrowed_Row_Callback_Error =>
            Raised := True;
            Message := Ada.Exceptions.Exception_Identity (Error);
      end;

      AUnit.Assertions.Assert
        (Raised and then Message = Borrowed_Row_Callback_Error'Identity,
         "A callback exception must propagate unchanged");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get (Image, Row => 0, Column => 0)),
            9.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Image, Row => 0, Column => 1)),
                     2.0),
         "Writes completed before a callback exception must remain visible");

      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 1, Value => 4.0);
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get (Image, Row => 0, Column => 1)),
            4.0),
         "The Mat must remain usable after a borrowed-row callback exception");
   end Float32_Borrowed_Row_Propagates_Callback_Exception;

   procedure UInt8_Borrowed_Writable_Row_Is_Zero_Copy
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Alias : OpenCV.Core.Mat;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.UInt8_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data'Length = 3,
            "A writable borrowed UInt8 row must use zero-based columns");

         Data (1) := 42;
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Image, Row => 1, Column => 1) = 42,
            "A write through the borrowed row must be immediately visible"
            & " through Get");

         OpenCV.Core.UInt8_Access.Set
           (Alias, Row => 1, Column => 2, Value => 200);
         AUnit.Assertions.Assert
           (Data (2) = 200,
            "A write through a shallow alias must be immediately visible"
            & " through the borrowed row");
      end Mutate;
   begin
      OpenCV.Core.UInt8_Access.Set (Image, Row => 1, Column => 0, Value => 1);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 1, Column => 1, Value => 2);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 1, Column => 2, Value => 3);
      Alias := Image;

      OpenCV.Core.UInt8_Row_Access.With_Writable_Row
        (Image, Row => 1, Process => Mutate'Access);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Image, Row => 1, Column => 0) = 1
         and then OpenCV.Core.UInt8_Access.Get (Image, Row => 1, Column => 1)
                  = 42
         and then OpenCV.Core.UInt8_Access.Get (Image, Row => 1, Column => 2)
                  = 200,
         "Writable borrowed-row mutations must remain after Process returns");
   end UInt8_Borrowed_Writable_Row_Is_Zero_Copy;

   procedure UInt8_Borrowed_Read_Only_Row_Matches_Mat
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));

      procedure Inspect (Data : aliased OpenCV.Core.UInt8_Row_Access.Row_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 3 and then Data'Length = 4,
            "A read-only borrowed UInt8 row must use zero-based columns");
         AUnit.Assertions.Assert
           (Data (0) = 5
            and then Data (1) = 15
            and then Data (2) = 25
            and then Data (3) = 35,
            "A read-only borrowed UInt8 row must match the Mat values");
      end Inspect;
   begin
      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 0, Value => 5);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 1, Value => 15);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 2, Value => 25);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 3, Value => 35);

      OpenCV.Core.UInt8_Row_Access.With_Read_Only_Row
        (Image, Row => 0, Process => Inspect'Access);
   end UInt8_Borrowed_Read_Only_Row_Matches_Mat;

   procedure UInt8_Borrowed_Row_Handles_Non_Continuous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 6,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      View   : OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));

      procedure Mutate
        (Data : aliased in out OpenCV.Core.UInt8_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data'Length = 3,
            "A borrowed Region row must be indexed relative to the Region");
         Data (0) := 11;
         Data (2) := 13;
      end Mutate;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (1.0));
      AUnit.Assertions.Assert
        (not View.Is_Continuous,
         "A partial-width multi-row Region must be non-continuous");

      OpenCV.Core.UInt8_Row_Access.With_Writable_Row
        (View, Row => 0, Process => Mutate'Access);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Parent, Row => 1, Column => 1) = 11
         and then OpenCV.Core.UInt8_Access.Get (Parent, Row => 1, Column => 3)
                  = 13,
         "Borrowed Region writes must mutate the corresponding parent"
         & " elements");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Parent, Row => 1, Column => 0) = 1
         and then OpenCV.Core.UInt8_Access.Get (Parent, Row => 1, Column => 4)
                  = 1
         and then OpenCV.Core.UInt8_Access.Get (Parent, Row => 1, Column => 2)
                  = 1,
         "Borrowed Region writes must not expose or mutate parent padding");
   end UInt8_Borrowed_Row_Handles_Non_Continuous_Region;

   procedure UInt8_Borrowed_Row_Rejects_Invalid_Mats_And_Indices
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Float32_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      RGB_Image     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Valid_Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Invoked       : Boolean := False;

      procedure Mark_Read
        (Data : aliased OpenCV.Core.UInt8_Row_Access.Row_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_Read;

      procedure Mark_Write
        (Data : aliased in out OpenCV.Core.UInt8_Row_Access.Row_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_Write;

      procedure Read_Float32 is
      begin
         OpenCV.Core.UInt8_Row_Access.With_Read_Only_Row
           (Float32_Image, Row => 0, Process => Mark_Read'Access);
      end Read_Float32;

      procedure Read_Multi_Channel is
      begin
         OpenCV.Core.UInt8_Row_Access.With_Read_Only_Row
           (RGB_Image, Row => 0, Process => Mark_Read'Access);
      end Read_Multi_Channel;

      procedure Write_Past_Last is
      begin
         OpenCV.Core.UInt8_Row_Access.With_Writable_Row
           (Valid_Image, Row => 1, Process => Mark_Write'Access);
      end Write_Past_Last;
   begin
      Assert_Raises_OpenCV_Error
        (Read_Float32'Access,
         "UInt8 borrowed-row access must reject a Float32 Mat");
      Assert_Raises_OpenCV_Error
        (Read_Multi_Channel'Access,
         "UInt8 borrowed-row access must reject a multi-channel Mat");
      Assert_Raises_OpenCV_Error
        (Write_Past_Last'Access,
         "UInt8 borrowed-row access must reject a row equal to Rows");
      AUnit.Assertions.Assert
        (not Invoked, "Borrowed-row validation must not invoke the callback");
   end UInt8_Borrowed_Row_Rejects_Invalid_Mats_And_Indices;

   procedure UInt8_Borrowed_Row_Propagates_Callback_Exception
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Raised  : Boolean := False;
      Message : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.UInt8_Row_Access.Row_Array) is
      begin
         Data (0) := 9;
         raise Borrowed_Row_Callback_Error;
      end Mutate;
   begin
      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 0, Value => 1);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 1, Value => 2);

      begin
         OpenCV.Core.UInt8_Row_Access.With_Writable_Row
           (Image, Row => 0, Process => Mutate'Access);
      exception
         when Error : Borrowed_Row_Callback_Error =>
            Raised := True;
            Message := Ada.Exceptions.Exception_Identity (Error);
      end;

      AUnit.Assertions.Assert
        (Raised and then Message = Borrowed_Row_Callback_Error'Identity,
         "A callback exception must propagate unchanged");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Image, Row => 0, Column => 0) = 9
         and then OpenCV.Core.UInt8_Access.Get (Image, Row => 0, Column => 1)
                  = 2,
         "Writes completed before a callback exception must remain visible");

      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 1, Value => 4);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Image, Row => 0, Column => 1) = 4,
         "The Mat must remain usable after a borrowed-row callback exception");
   end UInt8_Borrowed_Row_Propagates_Callback_Exception;

   procedure UInt8_Vec3_Borrowed_Writable_Row_Is_Zero_Copy
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Alias : OpenCV.Core.Mat;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data'Length = 3,
            "A writable borrowed UInt8 Vec3 row must use zero-based columns");

         Data (1) := (10, 20, 30);
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec3_Access.Get (Image, Row => 1, Column => 1)
            = (10, 20, 30),
            "A write through the borrowed Vec3 row must be immediately"
            & " visible through Get");

         OpenCV.Core.UInt8_Vec3_Access.Set
           (Alias, Row => 1, Column => 2, Value => (100, 110, 120));
         AUnit.Assertions.Assert
           (Data (2) = (100, 110, 120),
            "A write through a shallow alias must be immediately visible"
            & " through the borrowed Vec3 row");
      end Mutate;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 1, Column => 0, Value => (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 1, Column => 1, Value => (4, 5, 6));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 1, Column => 2, Value => (7, 8, 9));
      Alias := Image;

      OpenCV.Core.UInt8_Vec3_Row_Access.With_Writable_Row
        (Image, Row => 1, Process => Mutate'Access);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Image, Row => 1, Column => 0)
         = (1, 2, 3)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Image, Row => 1, Column => 1)
                  = (10, 20, 30)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Image, Row => 1, Column => 2)
                  = (100, 110, 120),
         "Writable borrowed Vec3 mutations must remain after Process returns");
   end UInt8_Vec3_Borrowed_Writable_Row_Is_Zero_Copy;

   procedure UInt8_Vec3_Borrowed_Read_Only_Row_Matches_Mat
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));

      procedure Inspect
        (Data : aliased OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 3 and then Data'Length = 4,
            "A read-only borrowed UInt8 Vec3 row must use zero-based columns");
         AUnit.Assertions.Assert
           (Data (0) = (5, 6, 7)
            and then Data (1) = (15, 16, 17)
            and then Data (2) = (25, 26, 27)
            and then Data (3) = (35, 36, 37),
            "A read-only borrowed UInt8 Vec3 row must match the Mat values");
      end Inspect;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 0, Value => (5, 6, 7));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 1, Value => (15, 16, 17));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 2, Value => (25, 26, 27));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 3, Value => (35, 36, 37));

      OpenCV.Core.UInt8_Vec3_Row_Access.With_Read_Only_Row
        (Image, Row => 0, Process => Inspect'Access);
   end UInt8_Vec3_Borrowed_Read_Only_Row_Matches_Mat;

   procedure UInt8_Vec3_Borrowed_Row_Handles_Non_Continuous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 6,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      View   : OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));

      procedure Mutate
        (Data : aliased in out OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data'Length = 3,
            "A borrowed Vec3 Region row must be indexed relative to the"
            & " Region");
         Data (0) := (11, 12, 13);
         Data (2) := (31, 32, 33);
      end Mutate;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (1.0, 2.0, 3.0));
      AUnit.Assertions.Assert
        (not View.Is_Continuous,
         "A partial-width multi-row Vec3 Region must be non-continuous");

      OpenCV.Core.UInt8_Vec3_Row_Access.With_Writable_Row
        (View, Row => 0, Process => Mutate'Access);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Parent, Row => 1, Column => 1)
         = (11, 12, 13)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Parent, Row => 1, Column => 3)
                  = (31, 32, 33),
         "Borrowed Vec3 Region writes must mutate the corresponding parent"
         & " pixels");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Parent, Row => 1, Column => 0)
         = (1, 2, 3)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Parent, Row => 1, Column => 4)
                  = (1, 2, 3)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Parent, Row => 1, Column => 2)
                  = (1, 2, 3),
         "Borrowed Vec3 Region writes must not expose or mutate parent"
         & " padding");
   end UInt8_Vec3_Borrowed_Row_Handles_Non_Continuous_Region;

   procedure UInt8_Vec3_Borrowed_Row_Rejects_Invalid_Mats_And_Indices
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Float32_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      C1_Image      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      C2_Image      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 2));
      Valid_Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Invoked       : Boolean := False;

      procedure Mark_Read
        (Data : aliased OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_Read;

      procedure Mark_Write
        (Data : aliased in out OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_Write;

      procedure Read_Float32 is
      begin
         OpenCV.Core.UInt8_Vec3_Row_Access.With_Read_Only_Row
           (Float32_Image, Row => 0, Process => Mark_Read'Access);
      end Read_Float32;

      procedure Read_C1 is
      begin
         OpenCV.Core.UInt8_Vec3_Row_Access.With_Read_Only_Row
           (C1_Image, Row => 0, Process => Mark_Read'Access);
      end Read_C1;

      procedure Read_C2 is
      begin
         OpenCV.Core.UInt8_Vec3_Row_Access.With_Read_Only_Row
           (C2_Image, Row => 0, Process => Mark_Read'Access);
      end Read_C2;

      procedure Write_Past_Last is
      begin
         OpenCV.Core.UInt8_Vec3_Row_Access.With_Writable_Row
           (Valid_Image, Row => 1, Process => Mark_Write'Access);
      end Write_Past_Last;
   begin
      Assert_Raises_OpenCV_Error
        (Read_Float32'Access,
         "UInt8 Vec3 borrowed-row access must reject a Float32 C3 Mat");
      Assert_Raises_OpenCV_Error
        (Read_C1'Access,
         "UInt8 Vec3 borrowed-row access must reject a UInt8 C1 Mat");
      Assert_Raises_OpenCV_Error
        (Read_C2'Access,
         "UInt8 Vec3 borrowed-row access must reject a UInt8 C2 Mat");
      Assert_Raises_OpenCV_Error
        (Write_Past_Last'Access,
         "UInt8 Vec3 borrowed-row access must reject a row equal to Rows");
      AUnit.Assertions.Assert
        (not Invoked, "Borrowed-row validation must not invoke the callback");
   end UInt8_Vec3_Borrowed_Row_Rejects_Invalid_Mats_And_Indices;

   procedure UInt8_Vec3_Borrowed_Row_Propagates_Callback_Exception
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Raised  : Boolean := False;
      Message : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.UInt8_Vec3_Row_Access.Row_Array) is
      begin
         Data (0) := (9, 10, 11);
         raise Borrowed_Row_Callback_Error;
      end Mutate;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 0, Value => (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 1, Value => (4, 5, 6));

      begin
         OpenCV.Core.UInt8_Vec3_Row_Access.With_Writable_Row
           (Image, Row => 0, Process => Mutate'Access);
      exception
         when Error : Borrowed_Row_Callback_Error =>
            Raised := True;
            Message := Ada.Exceptions.Exception_Identity (Error);
      end;

      AUnit.Assertions.Assert
        (Raised and then Message = Borrowed_Row_Callback_Error'Identity,
         "A callback exception must propagate unchanged");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Image, Row => 0, Column => 0)
         = (9, 10, 11)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Image, Row => 0, Column => 1)
                  = (4, 5, 6),
         "Writes completed before a callback exception must remain visible");

      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 1, Value => (40, 50, 60));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Image, Row => 0, Column => 1)
         = (40, 50, 60),
         "The Mat must remain usable after a borrowed-row callback exception");
   end UInt8_Vec3_Borrowed_Row_Propagates_Callback_Exception;

   function Vec3_Approximately_Equal
     (Left  : OpenCV.Core.Float32_Vec3.Vector;
      Right : OpenCV.Core.Float32_Vec3.Vector) return Boolean is
   begin
      return
        Approximately_Equal (Long_Float (Left (0)), Long_Float (Right (0)))
        and then Approximately_Equal
                   (Long_Float (Left (1)), Long_Float (Right (1)))
        and then Approximately_Equal
                   (Long_Float (Left (2)), Long_Float (Right (2)));
   end Vec3_Approximately_Equal;

   procedure Float32_Vec3_Borrowed_Writable_Row_Is_Zero_Copy
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      Alias : OpenCV.Core.Mat;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float32_Vec3_Row_Access.Row_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data'Length = 3,
            "A writable borrowed Float32 Vec3 row must use zero-based"
            & " columns");

         Data (1) := (1.25, -2.5, 3.75);
         AUnit.Assertions.Assert
           (Vec3_Approximately_Equal
              (OpenCV.Core.Float32_Vec3_Access.Get
                 (Image, Row => 1, Column => 1),
               (1.25, -2.5, 3.75)),
            "A write through the borrowed Vec3 row must be immediately"
            & " visible through Get");

         OpenCV.Core.Float32_Vec3_Access.Set
           (Alias, Row => 1, Column => 2, Value => (-4.5, 0.125, 9.875));
         AUnit.Assertions.Assert
           (Vec3_Approximately_Equal (Data (2), (-4.5, 0.125, 9.875)),
            "A write through a shallow alias must be immediately visible"
            & " through the borrowed Vec3 row");
      end Mutate;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 1, Column => 0, Value => (1.0, 2.0, 3.0));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 1, Column => 1, Value => (4.0, 5.0, 6.0));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 1, Column => 2, Value => (7.0, 8.0, 9.0));
      Alias := Image;

      OpenCV.Core.Float32_Vec3_Row_Access.With_Writable_Row
        (Image, Row => 1, Process => Mutate'Access);

      AUnit.Assertions.Assert
        (Vec3_Approximately_Equal
           (OpenCV.Core.Float32_Vec3_Access.Get (Image, Row => 1, Column => 0),
            (1.0, 2.0, 3.0))
         and then Vec3_Approximately_Equal
                    (OpenCV.Core.Float32_Vec3_Access.Get
                       (Image, Row => 1, Column => 1),
                     (1.25, -2.5, 3.75))
         and then Vec3_Approximately_Equal
                    (OpenCV.Core.Float32_Vec3_Access.Get
                       (Image, Row => 1, Column => 2),
                     (-4.5, 0.125, 9.875)),
         "Writable borrowed Vec3 mutations must remain after Process returns");
   end Float32_Vec3_Borrowed_Writable_Row_Is_Zero_Copy;

   procedure Float32_Vec3_Borrowed_Read_Only_Row_Matches_Mat
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));

      procedure Inspect
        (Data : aliased OpenCV.Core.Float32_Vec3_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 3 and then Data'Length = 4,
            "A read-only borrowed Float32 Vec3 row must use zero-based"
            & " columns");
         AUnit.Assertions.Assert
           (Vec3_Approximately_Equal (Data (0), (0.5, -1.5, 2.5))
            and then Vec3_Approximately_Equal (Data (1), (1.25, 0.0, -3.75))
            and then Vec3_Approximately_Equal (Data (2), (-4.5, 5.125, 6.0))
            and then Vec3_Approximately_Equal (Data (3), (7.875, -8.25, 9.5)),
            "A read-only borrowed Float32 Vec3 row must match the Mat values");
      end Inspect;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 0, Value => (0.5, -1.5, 2.5));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 1, Value => (1.25, 0.0, -3.75));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 2, Value => (-4.5, 5.125, 6.0));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 3, Value => (7.875, -8.25, 9.5));

      OpenCV.Core.Float32_Vec3_Row_Access.With_Read_Only_Row
        (Image, Row => 0, Process => Inspect'Access);
   end Float32_Vec3_Borrowed_Read_Only_Row_Matches_Mat;

   procedure Float32_Vec3_Borrowed_Row_Handles_Non_Continuous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 6,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      View   : OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float32_Vec3_Row_Access.Row_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data'Length = 3,
            "A borrowed Vec3 Region row must be indexed relative to the"
            & " Region");
         Data (0) := (11.0, 12.5, -13.25);
         Data (2) := (-31.5, 32.125, 33.75);
      end Mutate;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (1.0, 2.0, 3.0));
      AUnit.Assertions.Assert
        (not View.Is_Continuous,
         "A partial-width multi-row Vec3 Region must be non-continuous");

      OpenCV.Core.Float32_Vec3_Row_Access.With_Writable_Row
        (View, Row => 0, Process => Mutate'Access);

      AUnit.Assertions.Assert
        (Vec3_Approximately_Equal
           (OpenCV.Core.Float32_Vec3_Access.Get
              (Parent, Row => 1, Column => 1),
            (11.0, 12.5, -13.25))
         and then Vec3_Approximately_Equal
                    (OpenCV.Core.Float32_Vec3_Access.Get
                       (Parent, Row => 1, Column => 3),
                     (-31.5, 32.125, 33.75)),
         "Borrowed Vec3 Region writes must mutate the corresponding parent"
         & " pixels");
      AUnit.Assertions.Assert
        (Vec3_Approximately_Equal
           (OpenCV.Core.Float32_Vec3_Access.Get
              (Parent, Row => 1, Column => 0),
            (1.0, 2.0, 3.0))
         and then Vec3_Approximately_Equal
                    (OpenCV.Core.Float32_Vec3_Access.Get
                       (Parent, Row => 1, Column => 4),
                     (1.0, 2.0, 3.0))
         and then Vec3_Approximately_Equal
                    (OpenCV.Core.Float32_Vec3_Access.Get
                       (Parent, Row => 1, Column => 2),
                     (1.0, 2.0, 3.0)),
         "Borrowed Vec3 Region writes must not expose or mutate parent"
         & " padding");
   end Float32_Vec3_Borrowed_Row_Handles_Non_Continuous_Region;

   procedure Float32_Vec3_Borrowed_Row_Rejects_Invalid_Mats_And_Indices
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      C1_Image    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      C2_Image    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 2));
      Valid_Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      Invoked     : Boolean := False;

      procedure Mark_Read
        (Data : aliased OpenCV.Core.Float32_Vec3_Row_Access.Row_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_Read;

      procedure Mark_Write
        (Data : aliased in out OpenCV.Core.Float32_Vec3_Row_Access.Row_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_Write;

      procedure Read_UInt8 is
      begin
         OpenCV.Core.Float32_Vec3_Row_Access.With_Read_Only_Row
           (UInt8_Image, Row => 0, Process => Mark_Read'Access);
      end Read_UInt8;

      procedure Read_C1 is
      begin
         OpenCV.Core.Float32_Vec3_Row_Access.With_Read_Only_Row
           (C1_Image, Row => 0, Process => Mark_Read'Access);
      end Read_C1;

      procedure Read_C2 is
      begin
         OpenCV.Core.Float32_Vec3_Row_Access.With_Read_Only_Row
           (C2_Image, Row => 0, Process => Mark_Read'Access);
      end Read_C2;

      procedure Write_Past_Last is
      begin
         OpenCV.Core.Float32_Vec3_Row_Access.With_Writable_Row
           (Valid_Image, Row => 1, Process => Mark_Write'Access);
      end Write_Past_Last;
   begin
      Assert_Raises_OpenCV_Error
        (Read_UInt8'Access,
         "Float32 Vec3 borrowed-row access must reject a UInt8 C3 Mat");
      Assert_Raises_OpenCV_Error
        (Read_C1'Access,
         "Float32 Vec3 borrowed-row access must reject a Float32 C1 Mat");
      Assert_Raises_OpenCV_Error
        (Read_C2'Access,
         "Float32 Vec3 borrowed-row access must reject a Float32 C2 Mat");
      Assert_Raises_OpenCV_Error
        (Write_Past_Last'Access,
         "Float32 Vec3 borrowed-row access must reject a row equal to Rows");
      AUnit.Assertions.Assert
        (not Invoked, "Borrowed-row validation must not invoke the callback");
   end Float32_Vec3_Borrowed_Row_Rejects_Invalid_Mats_And_Indices;

   procedure Float32_Vec3_Borrowed_Row_Propagates_Callback_Exception
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      Raised  : Boolean := False;
      Message : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float32_Vec3_Row_Access.Row_Array)
      is
      begin
         Data (0) := (9.25, -10.5, 11.125);
         raise Borrowed_Row_Callback_Error;
      end Mutate;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 0, Value => (1.0, 2.0, 3.0));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 1, Value => (4.0, 5.0, 6.0));

      begin
         OpenCV.Core.Float32_Vec3_Row_Access.With_Writable_Row
           (Image, Row => 0, Process => Mutate'Access);
      exception
         when Error : Borrowed_Row_Callback_Error =>
            Raised := True;
            Message := Ada.Exceptions.Exception_Identity (Error);
      end;

      AUnit.Assertions.Assert
        (Raised and then Message = Borrowed_Row_Callback_Error'Identity,
         "A callback exception must propagate unchanged");
      AUnit.Assertions.Assert
        (Vec3_Approximately_Equal
           (OpenCV.Core.Float32_Vec3_Access.Get (Image, Row => 0, Column => 0),
            (9.25, -10.5, 11.125))
         and then Vec3_Approximately_Equal
                    (OpenCV.Core.Float32_Vec3_Access.Get
                       (Image, Row => 0, Column => 1),
                     (4.0, 5.0, 6.0)),
         "Writes completed before a callback exception must remain visible");

      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 1, Value => (40.5, -50.25, 60.125));
      AUnit.Assertions.Assert
        (Vec3_Approximately_Equal
           (OpenCV.Core.Float32_Vec3_Access.Get (Image, Row => 0, Column => 1),
            (40.5, -50.25, 60.125)),
         "The Mat must remain usable after a borrowed-row callback exception");
   end Float32_Vec3_Borrowed_Row_Propagates_Callback_Exception;

   procedure Float32_Borrowed_Writable_Buffer_Is_Zero_Copy
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Alias : OpenCV.Core.Mat;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float32_Buffer_Access.Buffer_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5 and then Data'Length = 6,
            "A writable borrowed Float32 buffer must be a flat zero-based"
            & " array of Total elements");

         Data (2) := 12.5;
         Data (3) := -7.25;
         AUnit.Assertions.Assert
           (Approximately_Equal
              (Long_Float
                 (OpenCV.Core.Float32_Access.Get
                    (Image, Row => 0, Column => 2)),
               12.5)
            and then Approximately_Equal
                       (Long_Float
                          (OpenCV.Core.Float32_Access.Get
                             (Image, Row => 1, Column => 0)),
                        -7.25),
            "Writes across a row boundary must be immediately visible"
            & " through Get");

         OpenCV.Core.Float32_Access.Set
           (Alias, Row => 1, Column => 2, Value => 9.875);
         AUnit.Assertions.Assert
           (Approximately_Equal (Long_Float (Data (5)), 9.875),
            "A write through a shallow alias must be immediately visible"
            & " through the borrowed buffer");
      end Mutate;
   begin
      AUnit.Assertions.Assert
        (Image.Is_Continuous,
         "A newly allocated Float32 Mat must be continuous");
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 0, Value => 1.0);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 1, Value => 2.0);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 2, Value => 3.0);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 1, Column => 0, Value => 4.0);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 1, Column => 1, Value => 5.0);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 1, Column => 2, Value => 6.0);
      Alias := Image;

      OpenCV.Core.Float32_Buffer_Access.With_Writable_Buffer
        (Image, Process => Mutate'Access);

      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get (Image, Row => 0, Column => 2)),
            12.5)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Image, Row => 1, Column => 0)),
                     -7.25)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Image, Row => 1, Column => 2)),
                     9.875),
         "Writable borrowed-buffer mutations must remain after Process"
         & " returns");
   end Float32_Borrowed_Writable_Buffer_Is_Zero_Copy;

   procedure Float32_Borrowed_Read_Only_Buffer_Matches_Mat
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));

      procedure Inspect
        (Data : aliased OpenCV.Core.Float32_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5 and then Data'Length = 6,
            "A read-only borrowed Float32 buffer must be a flat zero-based"
            & " array of Total elements");
         AUnit.Assertions.Assert
           (Approximately_Equal (Long_Float (Data (0)), 0.5)
            and then Approximately_Equal (Long_Float (Data (1)), -1.5)
            and then Approximately_Equal (Long_Float (Data (2)), 2.25)
            and then Approximately_Equal (Long_Float (Data (3)), -3.75)
            and then Approximately_Equal (Long_Float (Data (4)), 4.125)
            and then Approximately_Equal (Long_Float (Data (5)), 5.0),
            "A read-only borrowed Float32 buffer must match row-major Mat"
            & " values");
      end Inspect;
   begin
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 0, Value => 0.5);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 1, Value => -1.5);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 2, Value => 2.25);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 1, Column => 0, Value => -3.75);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 1, Column => 1, Value => 4.125);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 1, Column => 2, Value => 5.0);

      OpenCV.Core.Float32_Buffer_Access.With_Read_Only_Buffer
        (Image, Process => Inspect'Access);
   end Float32_Borrowed_Read_Only_Buffer_Matches_Mat;

   procedure Float32_Borrowed_Buffer_Accepts_Continuous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      View   : OpenCV.Core.Mat :=
        Parent.Region ((X => 0, Y => 1, Width => 3, Height => 2));

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float32_Buffer_Access.Buffer_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5 and then Data'Length = 6,
            "A borrowed continuous Region buffer must expose Region.Total"
            & " elements");
         Data (2) := 21.5;
         Data (3) := -22.25;
      end Mutate;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (1.0));
      AUnit.Assertions.Assert
        (View.Is_Continuous,
         "A full-width multi-row Region of a continuous parent must be"
         & " continuous");
      AUnit.Assertions.Assert
        (View.Is_Submatrix,
         "The continuous Region test must exercise a submatrix");

      OpenCV.Core.Float32_Buffer_Access.With_Writable_Buffer
        (View, Process => Mutate'Access);

      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get (Parent, Row => 1, Column => 2)),
            21.5)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Parent, Row => 2, Column => 0)),
                     -22.25),
         "Borrowed continuous Region writes must mutate corresponding parent"
         & " elements");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get (Parent, Row => 0, Column => 0)),
            1.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Parent, Row => 3, Column => 2)),
                     1.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Parent, Row => 1, Column => 1)),
                     1.0),
         "Borrowed continuous Region writes must not mutate rows outside the"
         & " Region");
   end Float32_Borrowed_Buffer_Accepts_Continuous_Region;

   procedure Float32_Borrowed_Buffer_Rejects_Invalid_Mats
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      C3_Image      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      Parent        : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 6,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Noncontinuous : constant OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Invoked       : Boolean := False;

      procedure Mark_Read
        (Data : aliased OpenCV.Core.Float32_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_Read;

      procedure Read_UInt8 is
      begin
         OpenCV.Core.Float32_Buffer_Access.With_Read_Only_Buffer
           (UInt8_Image, Process => Mark_Read'Access);
      end Read_UInt8;

      procedure Read_C3 is
      begin
         OpenCV.Core.Float32_Buffer_Access.With_Read_Only_Buffer
           (C3_Image, Process => Mark_Read'Access);
      end Read_C3;

      procedure Read_Noncontinuous is
      begin
         OpenCV.Core.Float32_Buffer_Access.With_Read_Only_Buffer
           (Noncontinuous, Process => Mark_Read'Access);
      end Read_Noncontinuous;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (1.0));
      AUnit.Assertions.Assert
        (not Noncontinuous.Is_Continuous,
         "A partial-width multi-row Region must be non-continuous");

      Assert_Raises_OpenCV_Error
        (Read_UInt8'Access,
         "Float32 buffer access must reject a UInt8 C1 Mat");
      Assert_Raises_OpenCV_Error
        (Read_C3'Access, "Float32 buffer access must reject a Float32 C3 Mat");
      Assert_Raises_OpenCV_Error
        (Read_Noncontinuous'Access,
         "Float32 buffer access must reject a non-continuous Mat");
      AUnit.Assertions.Assert
        (not Invoked,
         "Borrowed-buffer validation must not invoke the" & " callback");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get (Parent, Row => 1, Column => 1)),
            1.0),
         "Rejected non-continuous buffer access must not mutate the parent");
   end Float32_Borrowed_Buffer_Rejects_Invalid_Mats;

   procedure Float32_Borrowed_Buffer_Propagates_Callback_Exception
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Raised  : Boolean := False;
      Message : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float32_Buffer_Access.Buffer_Array)
      is
      begin
         Data (2) := 9.25;
         raise Borrowed_Row_Callback_Error;
      end Mutate;
   begin
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 0, Value => 1.0);
      OpenCV.Core.Float32_Access.Set
        (Image, Row => 1, Column => 0, Value => 2.0);

      begin
         OpenCV.Core.Float32_Buffer_Access.With_Writable_Buffer
           (Image, Process => Mutate'Access);
      exception
         when Error : Borrowed_Row_Callback_Error =>
            Raised := True;
            Message := Ada.Exceptions.Exception_Identity (Error);
      end;

      AUnit.Assertions.Assert
        (Raised and then Message = Borrowed_Row_Callback_Error'Identity,
         "A callback exception must propagate unchanged");
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get (Image, Row => 1, Column => 0)),
            9.25)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get
                          (Image, Row => 0, Column => 0)),
                     1.0),
         "Writes completed before a callback exception must remain visible");

      OpenCV.Core.Float32_Access.Set
        (Image, Row => 0, Column => 1, Value => 4.5);
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get (Image, Row => 0, Column => 1)),
            4.5),
         "The Mat must remain usable after a borrowed-buffer callback"
         & " exception");
   end Float32_Borrowed_Buffer_Propagates_Callback_Exception;

   procedure UInt8_Borrowed_Writable_Buffer_Is_Zero_Copy
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Alias : OpenCV.Core.Mat;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.UInt8_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5 and then Data'Length = 6,
            "A writable borrowed UInt8 buffer must be a flat zero-based"
            & " array of Total elements");

         Data (2) := 42;
         Data (3) := 200;
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Image, Row => 0, Column => 2) = 42
            and then OpenCV.Core.UInt8_Access.Get
                       (Image, Row => 1, Column => 0)
                     = 200,
            "Writes across a row boundary must be immediately visible"
            & " through Get");

         OpenCV.Core.UInt8_Access.Set
           (Alias, Row => 1, Column => 2, Value => 99);
         AUnit.Assertions.Assert
           (Data (5) = 99,
            "A write through a shallow alias must be immediately visible"
            & " through the borrowed buffer");
      end Mutate;
   begin
      AUnit.Assertions.Assert
        (Image.Is_Continuous,
         "A newly allocated UInt8 Mat must be continuous");
      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 0, Value => 1);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 1, Value => 2);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 2, Value => 3);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 1, Column => 0, Value => 10);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 1, Column => 1, Value => 20);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 1, Column => 2, Value => 30);
      Alias := Image;

      OpenCV.Core.UInt8_Buffer_Access.With_Writable_Buffer
        (Image, Process => Mutate'Access);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Image, Row => 0, Column => 2) = 42
         and then OpenCV.Core.UInt8_Access.Get (Image, Row => 1, Column => 0)
                  = 200
         and then OpenCV.Core.UInt8_Access.Get (Image, Row => 1, Column => 2)
                  = 99,
         "Writable borrowed-buffer mutations must remain after Process"
         & " returns");
   end UInt8_Borrowed_Writable_Buffer_Is_Zero_Copy;

   procedure UInt8_Borrowed_Read_Only_Buffer_Matches_Mat
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));

      procedure Inspect
        (Data : aliased OpenCV.Core.UInt8_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5 and then Data'Length = 6,
            "A read-only borrowed UInt8 buffer must be a flat zero-based"
            & " array of Total elements");
         AUnit.Assertions.Assert
           (Data (0) = 1
            and then Data (1) = 2
            and then Data (2) = 3
            and then Data (3) = 10
            and then Data (4) = 20
            and then Data (5) = 30,
            "A read-only borrowed UInt8 buffer must match row-major Mat"
            & " values");
      end Inspect;
   begin
      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 0, Value => 1);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 1, Value => 2);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 2, Value => 3);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 1, Column => 0, Value => 10);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 1, Column => 1, Value => 20);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 1, Column => 2, Value => 30);

      OpenCV.Core.UInt8_Buffer_Access.With_Read_Only_Buffer
        (Image, Process => Inspect'Access);
   end UInt8_Borrowed_Read_Only_Buffer_Matches_Mat;

   procedure UInt8_Borrowed_Buffer_Accepts_Continuous_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      View   : OpenCV.Core.Mat :=
        Parent.Region ((X => 0, Y => 1, Width => 3, Height => 2));

      procedure Mutate
        (Data : aliased in out OpenCV.Core.UInt8_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5 and then Data'Length = 6,
            "A borrowed continuous Region buffer must expose Region.Total"
            & " elements");
         Data (2) := 21;
         Data (3) := 22;
      end Mutate;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (1.0));
      AUnit.Assertions.Assert
        (View.Is_Continuous,
         "A full-width multi-row Region of a continuous parent must be"
         & " continuous");
      AUnit.Assertions.Assert
        (View.Is_Submatrix,
         "The continuous Region test must exercise a submatrix");

      OpenCV.Core.UInt8_Buffer_Access.With_Writable_Buffer
        (View, Process => Mutate'Access);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Parent, Row => 1, Column => 2) = 21
         and then OpenCV.Core.UInt8_Access.Get (Parent, Row => 2, Column => 0)
                  = 22,
         "Borrowed continuous Region writes must mutate corresponding parent"
         & " elements");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Parent, Row => 0, Column => 0) = 1
         and then OpenCV.Core.UInt8_Access.Get (Parent, Row => 3, Column => 2)
                  = 1
         and then OpenCV.Core.UInt8_Access.Get (Parent, Row => 1, Column => 1)
                  = 1,
         "Borrowed continuous Region writes must not mutate rows outside the"
         & " Region");
   end UInt8_Borrowed_Buffer_Accepts_Continuous_Region;

   procedure UInt8_Borrowed_Buffer_Rejects_Invalid_Mats
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Float32_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      C3_Image      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Parent        : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 6,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Noncontinuous : constant OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Invoked       : Boolean := False;

      procedure Mark_Read
        (Data : aliased OpenCV.Core.UInt8_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_Read;

      procedure Read_Float32 is
      begin
         OpenCV.Core.UInt8_Buffer_Access.With_Read_Only_Buffer
           (Float32_Image, Process => Mark_Read'Access);
      end Read_Float32;

      procedure Read_C3 is
      begin
         OpenCV.Core.UInt8_Buffer_Access.With_Read_Only_Buffer
           (C3_Image, Process => Mark_Read'Access);
      end Read_C3;

      procedure Read_Noncontinuous is
      begin
         OpenCV.Core.UInt8_Buffer_Access.With_Read_Only_Buffer
           (Noncontinuous, Process => Mark_Read'Access);
      end Read_Noncontinuous;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (1.0));
      AUnit.Assertions.Assert
        (not Noncontinuous.Is_Continuous,
         "A partial-width multi-row Region must be non-continuous");

      Assert_Raises_OpenCV_Error
        (Read_Float32'Access,
         "UInt8 buffer access must reject a Float32 C1 Mat");
      Assert_Raises_OpenCV_Error
        (Read_C3'Access, "UInt8 buffer access must reject a UInt8 C3 Mat");
      Assert_Raises_OpenCV_Error
        (Read_Noncontinuous'Access,
         "UInt8 buffer access must reject a non-continuous Mat");
      AUnit.Assertions.Assert
        (not Invoked,
         "Borrowed-buffer validation must not invoke the" & " callback");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Parent, Row => 1, Column => 1) = 1,
         "Rejected non-continuous buffer access must not mutate the parent");
   end UInt8_Borrowed_Buffer_Rejects_Invalid_Mats;

   procedure UInt8_Borrowed_Buffer_Propagates_Callback_Exception
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Raised  : Boolean := False;
      Message : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.UInt8_Buffer_Access.Buffer_Array) is
      begin
         Data (2) := 77;
         raise Borrowed_Row_Callback_Error;
      end Mutate;
   begin
      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 0, Value => 1);
      OpenCV.Core.UInt8_Access.Set (Image, Row => 1, Column => 0, Value => 2);

      begin
         OpenCV.Core.UInt8_Buffer_Access.With_Writable_Buffer
           (Image, Process => Mutate'Access);
      exception
         when Error : Borrowed_Row_Callback_Error =>
            Raised := True;
            Message := Ada.Exceptions.Exception_Identity (Error);
      end;

      AUnit.Assertions.Assert
        (Raised and then Message = Borrowed_Row_Callback_Error'Identity,
         "A callback exception must propagate unchanged");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Image, Row => 1, Column => 0) = 77
         and then OpenCV.Core.UInt8_Access.Get (Image, Row => 0, Column => 0)
                  = 1,
         "Writes completed before a callback exception must remain visible");

      OpenCV.Core.UInt8_Access.Set (Image, Row => 0, Column => 1, Value => 45);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Image, Row => 0, Column => 1) = 45,
         "The Mat must remain usable after a borrowed-buffer callback"
         & " exception");
   end UInt8_Borrowed_Buffer_Propagates_Callback_Exception;

   procedure UInt8_Vec3_Borrowed_Writable_Buffer_Is_Zero_Copy
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Alias : OpenCV.Core.Mat;

      procedure Mutate
        (Data :
           aliased in out OpenCV.Core.UInt8_Vec3_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5 and then Data'Length = 6,
            "A writable borrowed UInt8 Vec3 buffer must be a flat"
            & " zero-based array of Total pixels");

         Data (2) := (10, 20, 30);
         Data (3) := (40, 50, 60);
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec3_Access.Get (Image, Row => 0, Column => 2)
            = (10, 20, 30)
            and then OpenCV.Core.UInt8_Vec3_Access.Get
                       (Image, Row => 1, Column => 0)
                     = (40, 50, 60),
            "Writes of complete pixels across a row boundary must be"
            & " immediately visible through Get");

         OpenCV.Core.UInt8_Vec3_Access.Set
           (Alias, Row => 1, Column => 2, Value => (100, 110, 120));
         AUnit.Assertions.Assert
           (Data (5) = (100, 110, 120),
            "A write through a shallow alias must be immediately visible"
            & " through the borrowed Vec3 buffer");
      end Mutate;
   begin
      AUnit.Assertions.Assert
        (Image.Is_Continuous,
         "A newly allocated UInt8 C3 Mat must be continuous");
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 0, Value => (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 1, Value => (4, 5, 6));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 2, Value => (7, 8, 9));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 1, Column => 0, Value => (10, 20, 30));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 1, Column => 1, Value => (40, 50, 60));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 1, Column => 2, Value => (70, 80, 90));
      Alias := Image;

      OpenCV.Core.UInt8_Vec3_Buffer_Access.With_Writable_Buffer
        (Image, Process => Mutate'Access);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Image, Row => 0, Column => 2)
         = (10, 20, 30)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Image, Row => 1, Column => 0)
                  = (40, 50, 60)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Image, Row => 1, Column => 2)
                  = (100, 110, 120),
         "Writable borrowed Vec3 buffer mutations must remain after"
         & " Process returns");
   end UInt8_Vec3_Borrowed_Writable_Buffer_Is_Zero_Copy;

   procedure UInt8_Vec3_Borrowed_Read_Only_Buffer_Matches_Mat
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));

      procedure Inspect
        (Data : aliased OpenCV.Core.UInt8_Vec3_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5 and then Data'Length = 6,
            "A read-only borrowed UInt8 Vec3 buffer must be a flat"
            & " zero-based array of Total pixels");
         AUnit.Assertions.Assert
           (Data (0) = (1, 2, 3)
            and then Data (1) = (4, 5, 6)
            and then Data (2) = (7, 8, 9)
            and then Data (3) = (10, 20, 30)
            and then Data (4) = (40, 50, 60)
            and then Data (5) = (70, 80, 90),
            "A read-only borrowed UInt8 Vec3 buffer must match row-major"
            & " Mat pixels");
      end Inspect;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 0, Value => (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 1, Value => (4, 5, 6));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 2, Value => (7, 8, 9));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 1, Column => 0, Value => (10, 20, 30));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 1, Column => 1, Value => (40, 50, 60));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 1, Column => 2, Value => (70, 80, 90));

      OpenCV.Core.UInt8_Vec3_Buffer_Access.With_Read_Only_Buffer
        (Image, Process => Inspect'Access);
   end UInt8_Vec3_Borrowed_Read_Only_Buffer_Matches_Mat;

   procedure UInt8_Vec3_Borrowed_Buffer_Accepts_Continuous_Offset_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 5,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      View   : OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 1));

      procedure Mutate
        (Data :
           aliased in out OpenCV.Core.UInt8_Vec3_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data'Length = 3,
            "A borrowed continuous offset Region buffer must expose"
            & " Region.Total pixels");
         Data (0) := (11, 12, 13);
         Data (2) := (31, 32, 33);
      end Mutate;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (1.0, 2.0, 3.0));
      AUnit.Assertions.Assert
        (View.Is_Submatrix,
         "The continuous offset Region test must exercise a submatrix");
      AUnit.Assertions.Assert
        (View.Is_Continuous,
         "A single-row partial-width Region of a continuous parent must"
         & " be continuous");

      OpenCV.Core.UInt8_Vec3_Buffer_Access.With_Writable_Buffer
        (View, Process => Mutate'Access);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Parent, Row => 1, Column => 1)
         = (11, 12, 13)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Parent, Row => 1, Column => 3)
                  = (31, 32, 33)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Parent, Row => 1, Column => 2)
                  = (1, 2, 3),
         "Borrowed continuous offset Region writes must mutate the"
         & " corresponding parent pixels");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Parent, Row => 1, Column => 0)
         = (1, 2, 3)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Parent, Row => 1, Column => 4)
                  = (1, 2, 3)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Parent, Row => 0, Column => 1)
                  = (1, 2, 3)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Parent, Row => 2, Column => 1)
                  = (1, 2, 3),
         "Borrowed continuous offset Region writes must not mutate pixels"
         & " outside the Region");
   end UInt8_Vec3_Borrowed_Buffer_Accepts_Continuous_Offset_Region;

   procedure UInt8_Vec3_Borrowed_Buffer_Rejects_Invalid_Mats
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Float32_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      C1_Image      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Parent        : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 6,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Noncontinuous : constant OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Invoked       : Boolean := False;

      procedure Mark_Read
        (Data : aliased OpenCV.Core.UInt8_Vec3_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_Read;

      procedure Read_Float32 is
      begin
         OpenCV.Core.UInt8_Vec3_Buffer_Access.With_Read_Only_Buffer
           (Float32_Image, Process => Mark_Read'Access);
      end Read_Float32;

      procedure Read_C1 is
      begin
         OpenCV.Core.UInt8_Vec3_Buffer_Access.With_Read_Only_Buffer
           (C1_Image, Process => Mark_Read'Access);
      end Read_C1;

      procedure Read_Noncontinuous is
      begin
         OpenCV.Core.UInt8_Vec3_Buffer_Access.With_Read_Only_Buffer
           (Noncontinuous, Process => Mark_Read'Access);
      end Read_Noncontinuous;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (1.0, 2.0, 3.0));
      AUnit.Assertions.Assert
        (not Noncontinuous.Is_Continuous,
         "A partial-width multi-row Vec3 Region must be non-continuous");

      Assert_Raises_OpenCV_Error
        (Read_Float32'Access,
         "UInt8 Vec3 buffer access must reject a Float32 C3 Mat");
      Assert_Raises_OpenCV_Error
        (Read_C1'Access,
         "UInt8 Vec3 buffer access must reject a UInt8 C1 Mat");
      Assert_Raises_OpenCV_Error
        (Read_Noncontinuous'Access,
         "UInt8 Vec3 buffer access must reject a non-continuous Mat");
      AUnit.Assertions.Assert
        (not Invoked,
         "Borrowed-buffer validation must not invoke the" & " callback");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Parent, Row => 1, Column => 1)
         = (1, 2, 3),
         "Rejected non-continuous buffer access must not mutate the parent");
   end UInt8_Vec3_Borrowed_Buffer_Rejects_Invalid_Mats;

   procedure UInt8_Vec3_Borrowed_Buffer_Propagates_Callback_Exception
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Raised  : Boolean := False;
      Message : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;

      procedure Mutate
        (Data :
           aliased in out OpenCV.Core.UInt8_Vec3_Buffer_Access.Buffer_Array) is
      begin
         Data (2) := (77, 88, 99);
         raise Borrowed_Row_Callback_Error;
      end Mutate;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 0, Value => (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 1, Column => 0, Value => (4, 5, 6));

      begin
         OpenCV.Core.UInt8_Vec3_Buffer_Access.With_Writable_Buffer
           (Image, Process => Mutate'Access);
      exception
         when Error : Borrowed_Row_Callback_Error =>
            Raised := True;
            Message := Ada.Exceptions.Exception_Identity (Error);
      end;

      AUnit.Assertions.Assert
        (Raised and then Message = Borrowed_Row_Callback_Error'Identity,
         "A callback exception must propagate unchanged");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Image, Row => 1, Column => 0)
         = (77, 88, 99)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Image, Row => 0, Column => 0)
                  = (1, 2, 3),
         "Writes completed before a callback exception must remain visible");

      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Row => 0, Column => 1, Value => (7, 8, 9));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Image, Row => 0, Column => 1)
         = (7, 8, 9),
         "The Mat must remain usable after a borrowed-buffer callback"
         & " exception");
   end UInt8_Vec3_Borrowed_Buffer_Propagates_Callback_Exception;

   procedure Float32_Vec3_Borrowed_Writable_Buffer_Is_Zero_Copy
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      Alias : OpenCV.Core.Mat;

      procedure Mutate
        (Data :
           aliased in out OpenCV.Core.Float32_Vec3_Buffer_Access.Buffer_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5 and then Data'Length = 6,
            "A writable borrowed Float32 Vec3 buffer must be a flat"
            & " zero-based array of Total pixels");

         Data (2) := (1.25, -2.5, 3.75);
         Data (3) := (-4.5, 5.125, 6.75);
         AUnit.Assertions.Assert
           (Vec3_Approximately_Equal
              (OpenCV.Core.Float32_Vec3_Access.Get
                 (Image, Row => 0, Column => 2),
               (1.25, -2.5, 3.75))
            and then Vec3_Approximately_Equal
                       (OpenCV.Core.Float32_Vec3_Access.Get
                          (Image, Row => 1, Column => 0),
                        (-4.5, 5.125, 6.75)),
            "Writes of complete pixels across a row boundary must be"
            & " immediately visible through Get");

         OpenCV.Core.Float32_Vec3_Access.Set
           (Alias, Row => 1, Column => 2, Value => (7.875, -8.25, 9.5));
         AUnit.Assertions.Assert
           (Vec3_Approximately_Equal (Data (5), (7.875, -8.25, 9.5)),
            "A write through a shallow alias must be immediately visible"
            & " through the borrowed Vec3 buffer");
      end Mutate;
   begin
      AUnit.Assertions.Assert
        (Image.Is_Continuous,
         "A newly allocated Float32 C3 Mat must be continuous");
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 0, Value => (0.5, -1.5, 2.5));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 1, Value => (1.25, 0.0, -3.75));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 2, Value => (-4.5, 5.125, 6.0));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 1, Column => 0, Value => (7.875, -8.25, 9.5));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 1, Column => 1, Value => (-10.0, 11.125, 12.25));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 1, Column => 2, Value => (13.5, 14.75, -15.875));
      Alias := Image;

      OpenCV.Core.Float32_Vec3_Buffer_Access.With_Writable_Buffer
        (Image, Process => Mutate'Access);

      AUnit.Assertions.Assert
        (Vec3_Approximately_Equal
           (OpenCV.Core.Float32_Vec3_Access.Get (Image, Row => 0, Column => 2),
            (1.25, -2.5, 3.75))
         and then Vec3_Approximately_Equal
                    (OpenCV.Core.Float32_Vec3_Access.Get
                       (Image, Row => 1, Column => 0),
                     (-4.5, 5.125, 6.75))
         and then Vec3_Approximately_Equal
                    (OpenCV.Core.Float32_Vec3_Access.Get
                       (Image, Row => 1, Column => 2),
                     (7.875, -8.25, 9.5)),
         "Writable borrowed Vec3 buffer mutations must remain after"
         & " Process returns");
   end Float32_Vec3_Borrowed_Writable_Buffer_Is_Zero_Copy;

   procedure Float32_Vec3_Borrowed_Read_Only_Buffer_Matches_Mat
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));

      procedure Inspect
        (Data : aliased OpenCV.Core.Float32_Vec3_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5 and then Data'Length = 6,
            "A read-only borrowed Float32 Vec3 buffer must be a flat"
            & " zero-based array of Total pixels");
         AUnit.Assertions.Assert
           (Vec3_Approximately_Equal (Data (0), (0.5, -1.5, 2.5))
            and then Vec3_Approximately_Equal (Data (1), (1.25, 0.0, -3.75))
            and then Vec3_Approximately_Equal (Data (2), (-4.5, 5.125, 6.0))
            and then Vec3_Approximately_Equal (Data (3), (7.875, -8.25, 9.5))
            and then Vec3_Approximately_Equal
                       (Data (4), (-10.0, 11.125, 12.25))
            and then Vec3_Approximately_Equal
                       (Data (5), (13.5, 14.75, -15.875)),
            "A read-only borrowed Float32 Vec3 buffer must match"
            & " row-major Mat pixels");
      end Inspect;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 0, Value => (0.5, -1.5, 2.5));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 1, Value => (1.25, 0.0, -3.75));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 2, Value => (-4.5, 5.125, 6.0));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 1, Column => 0, Value => (7.875, -8.25, 9.5));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 1, Column => 1, Value => (-10.0, 11.125, 12.25));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 1, Column => 2, Value => (13.5, 14.75, -15.875));

      OpenCV.Core.Float32_Vec3_Buffer_Access.With_Read_Only_Buffer
        (Image, Process => Inspect'Access);
   end Float32_Vec3_Borrowed_Read_Only_Buffer_Matches_Mat;

   procedure Float32_Vec3_Borrowed_Buffer_Accepts_Continuous_Offset_Region
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 5,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      View   : OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 1));

      procedure Mutate
        (Data :
           aliased in out OpenCV.Core.Float32_Vec3_Buffer_Access.Buffer_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data'Length = 3,
            "A borrowed continuous offset Region buffer must expose"
            & " Region.Total pixels");
         Data (0) := (1.25, -2.5, 3.75);
         Data (2) := (-4.5, 5.125, 6.75);
      end Mutate;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (1.0, 2.0, 3.0));
      AUnit.Assertions.Assert
        (View.Is_Submatrix,
         "The continuous offset Region test must exercise a submatrix");
      AUnit.Assertions.Assert
        (View.Is_Continuous,
         "A single-row partial-width Region of a continuous parent must"
         & " be continuous");

      OpenCV.Core.Float32_Vec3_Buffer_Access.With_Writable_Buffer
        (View, Process => Mutate'Access);

      AUnit.Assertions.Assert
        (Vec3_Approximately_Equal
           (OpenCV.Core.Float32_Vec3_Access.Get
              (Parent, Row => 1, Column => 1),
            (1.25, -2.5, 3.75))
         and then Vec3_Approximately_Equal
                    (OpenCV.Core.Float32_Vec3_Access.Get
                       (Parent, Row => 1, Column => 3),
                     (-4.5, 5.125, 6.75))
         and then Vec3_Approximately_Equal
                    (OpenCV.Core.Float32_Vec3_Access.Get
                       (Parent, Row => 1, Column => 2),
                     (1.0, 2.0, 3.0)),
         "Borrowed continuous offset Region writes must mutate the"
         & " corresponding parent pixels");
      AUnit.Assertions.Assert
        (Vec3_Approximately_Equal
           (OpenCV.Core.Float32_Vec3_Access.Get
              (Parent, Row => 1, Column => 0),
            (1.0, 2.0, 3.0))
         and then Vec3_Approximately_Equal
                    (OpenCV.Core.Float32_Vec3_Access.Get
                       (Parent, Row => 1, Column => 4),
                     (1.0, 2.0, 3.0))
         and then Vec3_Approximately_Equal
                    (OpenCV.Core.Float32_Vec3_Access.Get
                       (Parent, Row => 0, Column => 1),
                     (1.0, 2.0, 3.0))
         and then Vec3_Approximately_Equal
                    (OpenCV.Core.Float32_Vec3_Access.Get
                       (Parent, Row => 2, Column => 1),
                     (1.0, 2.0, 3.0)),
         "Borrowed continuous offset Region writes must not mutate pixels"
         & " outside the Region");
   end Float32_Vec3_Borrowed_Buffer_Accepts_Continuous_Offset_Region;

   procedure Float32_Vec3_Borrowed_Buffer_Rejects_Invalid_Mats
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      C1_Image      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Parent        : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 6,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      Noncontinuous : constant OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Invoked       : Boolean := False;

      procedure Mark_Read
        (Data : aliased OpenCV.Core.Float32_Vec3_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_Read;

      procedure Read_UInt8 is
      begin
         OpenCV.Core.Float32_Vec3_Buffer_Access.With_Read_Only_Buffer
           (UInt8_Image, Process => Mark_Read'Access);
      end Read_UInt8;

      procedure Read_C1 is
      begin
         OpenCV.Core.Float32_Vec3_Buffer_Access.With_Read_Only_Buffer
           (C1_Image, Process => Mark_Read'Access);
      end Read_C1;

      procedure Read_Noncontinuous is
      begin
         OpenCV.Core.Float32_Vec3_Buffer_Access.With_Read_Only_Buffer
           (Noncontinuous, Process => Mark_Read'Access);
      end Read_Noncontinuous;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (1.0, 2.0, 3.0));
      AUnit.Assertions.Assert
        (not Noncontinuous.Is_Continuous,
         "A partial-width multi-row Vec3 Region must be non-continuous");

      Assert_Raises_OpenCV_Error
        (Read_UInt8'Access,
         "Float32 Vec3 buffer access must reject a UInt8 C3 Mat");
      Assert_Raises_OpenCV_Error
        (Read_C1'Access,
         "Float32 Vec3 buffer access must reject a Float32 C1 Mat");
      Assert_Raises_OpenCV_Error
        (Read_Noncontinuous'Access,
         "Float32 Vec3 buffer access must reject a non-continuous Mat");
      AUnit.Assertions.Assert
        (not Invoked,
         "Borrowed-buffer validation must not invoke the" & " callback");
      AUnit.Assertions.Assert
        (Vec3_Approximately_Equal
           (OpenCV.Core.Float32_Vec3_Access.Get
              (Parent, Row => 1, Column => 1),
            (1.0, 2.0, 3.0)),
         "Rejected non-continuous buffer access must not mutate the parent");
   end Float32_Vec3_Borrowed_Buffer_Rejects_Invalid_Mats;

   procedure Float32_Vec3_Borrowed_Buffer_Propagates_Callback_Exception
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      Raised  : Boolean := False;
      Message : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;

      procedure Mutate
        (Data :
           aliased in out OpenCV.Core.Float32_Vec3_Buffer_Access.Buffer_Array)
      is
      begin
         Data (2) := (7.75, -8.5, 9.25);
         raise Borrowed_Row_Callback_Error;
      end Mutate;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 0, Value => (1.0, 2.0, 3.0));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 1, Column => 0, Value => (4.0, 5.0, 6.0));

      begin
         OpenCV.Core.Float32_Vec3_Buffer_Access.With_Writable_Buffer
           (Image, Process => Mutate'Access);
      exception
         when Error : Borrowed_Row_Callback_Error =>
            Raised := True;
            Message := Ada.Exceptions.Exception_Identity (Error);
      end;

      AUnit.Assertions.Assert
        (Raised and then Message = Borrowed_Row_Callback_Error'Identity,
         "A callback exception must propagate unchanged");
      AUnit.Assertions.Assert
        (Vec3_Approximately_Equal
           (OpenCV.Core.Float32_Vec3_Access.Get (Image, Row => 1, Column => 0),
            (7.75, -8.5, 9.25))
         and then Vec3_Approximately_Equal
                    (OpenCV.Core.Float32_Vec3_Access.Get
                       (Image, Row => 0, Column => 0),
                     (1.0, 2.0, 3.0)),
         "Writes completed before a callback exception must remain visible");

      OpenCV.Core.Float32_Vec3_Access.Set
        (Image, Row => 0, Column => 1, Value => (7.0, 8.0, 9.0));
      AUnit.Assertions.Assert
        (Vec3_Approximately_Equal
           (OpenCV.Core.Float32_Vec3_Access.Get (Image, Row => 0, Column => 1),
            (7.0, 8.0, 9.0)),
         "The Mat must remain usable after a borrowed-buffer callback"
         & " exception");
   end Float32_Vec3_Borrowed_Buffer_Propagates_Callback_Exception;

   procedure UInt8_Vec3_External_Mat_View_Is_Zero_Copy
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Data : aliased OpenCV.Core.UInt8_Vec3_Mat_View.Buffer_Array :=
        (11 => (1, 2, 3),
         12 => (4, 5, 6),
         13 => (7, 8, 9),
         14 => (10, 20, 30),
         15 => (40, 50, 60),
         16 => (70, 80, 90));

      procedure Process (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (Image.Rows = 2
            and then Image.Columns = 3
            and then Image.Depth = OpenCV.Core.UInt8
            and then Image.Channels = 3
            and then Natural (Image.Total) = 6
            and then Image.Is_Continuous,
            "UInt8 Vec3 external view metadata must describe six pixels");
         Data (13) := (21, 22, 23);
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec3_Access.Get (Image, 0, 2) = (21, 22, 23),
            "UInt8 Vec3 Data-to-Mat aliasing must cross the row boundary");
         OpenCV.Core.UInt8_Vec3_Access.Set (Image, 1, 0, (31, 32, 33));
         AUnit.Assertions.Assert
           (Data (14) = (31, 32, 33),
            "UInt8 Vec3 Mat-to-Data aliasing must cross the row boundary");
         Image.Set_To (OpenCV.Core.Make_Scalar (100.0, 110.0, 120.0));
      end Process;
   begin
      OpenCV.Core.UInt8_Vec3_Mat_View.With_Writable_Mat_View
        (Data, Rows => 2, Columns => 3, Process => Process'Access);
      AUnit.Assertions.Assert
        (Data (11) = (100, 110, 120) and then Data (16) = (100, 110, 120),
         "UInt8 Vec3 Set_To must directly update caller storage");
   end UInt8_Vec3_External_Mat_View_Is_Zero_Copy;

   procedure Float32_Vec3_External_Mat_View_Is_Zero_Copy
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Data : aliased OpenCV.Core.Float32_Vec3_Mat_View.Buffer_Array :=
        (21 => (0.5, -1.5, 2.5),
         22 => (1.25, 0.0, -3.75),
         23 => (-4.5, 5.125, 6.0),
         24 => (7.875, -8.25, 9.5),
         25 => (-10.0, 11.125, 12.25),
         26 => (13.5, 14.75, -15.875));

      procedure Process (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (Image.Rows = 2
            and then Image.Columns = 3
            and then Image.Depth = OpenCV.Core.Float32
            and then Image.Channels = 3
            and then Natural (Image.Total) = 6
            and then Image.Is_Continuous,
            "Float32 Vec3 external view metadata must describe six pixels");
         Data (23) := (1.25, -2.5, 3.75);
         AUnit.Assertions.Assert
           (Vec3_Approximately_Equal
              (OpenCV.Core.Float32_Vec3_Access.Get (Image, 0, 2),
               (1.25, -2.5, 3.75)),
            "Float32 Vec3 Data-to-Mat aliasing must cross the row boundary");
         OpenCV.Core.Float32_Vec3_Access.Set
           (Image, 1, 0, (-4.5, 5.125, 6.75));
         AUnit.Assertions.Assert
           (Vec3_Approximately_Equal (Data (24), (-4.5, 5.125, 6.75)),
            "Float32 Vec3 Mat-to-Data aliasing must cross the row boundary");
         Image.Set_To (OpenCV.Core.Make_Scalar (7.25, -8.5, 9.75));
      end Process;
   begin
      OpenCV.Core.Float32_Vec3_Mat_View.With_Writable_Mat_View
        (Data, Rows => 2, Columns => 3, Process => Process'Access);
      AUnit.Assertions.Assert
        (Vec3_Approximately_Equal (Data (21), (7.25, -8.5, 9.75))
         and then Vec3_Approximately_Equal (Data (26), (7.25, -8.5, 9.75)),
         "Float32 Vec3 Set_To must directly update caller storage");
   end Float32_Vec3_External_Mat_View_Is_Zero_Copy;

   procedure Vec3_External_Mat_Views_Reject_Invalid_Shape
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Data : aliased OpenCV.Core.UInt8_Vec3_Mat_View.Buffer_Array :=
        (1 .. 5 => (1, 2, 3));
      Float_Data : aliased OpenCV.Core.Float32_Vec3_Mat_View.Buffer_Array :=
        (1 .. 7 => (1.0, 2.0, 3.0));
      Invoked    : Boolean := False;
      procedure Process (Image : in out OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Process;
      procedure Bad_UInt8 is
      begin
         OpenCV.Core.UInt8_Vec3_Mat_View.With_Writable_Mat_View
           (UInt8_Data, 2, 3, Process'Access);
      end Bad_UInt8;
      procedure Bad_Float32 is
      begin
         OpenCV.Core.Float32_Vec3_Mat_View.With_Writable_Mat_View
           (Float_Data, 2, 3, Process'Access);
      end Bad_Float32;
   begin
      Assert_Raises_OpenCV_Error (Bad_UInt8'Access, "UInt8 Vec3 shape");
      Assert_Raises_OpenCV_Error (Bad_Float32'Access, "Float32 Vec3 shape");
      AUnit.Assertions.Assert
        (not Invoked
         and then UInt8_Data (1) = (1, 2, 3)
         and then Vec3_Approximately_Equal (Float_Data (1), (1.0, 2.0, 3.0)),
         "Invalid Vec3 view shapes must not invoke or modify caller storage");
   end Vec3_External_Mat_Views_Reject_Invalid_Shape;

   procedure UInt8_Vec3_External_Mat_View_Permits_Independent_Clone
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Data  : aliased OpenCV.Core.UInt8_Vec3_Mat_View.Buffer_Array :=
        (1 => (1, 2, 3), 2 .. 6 => (4, 5, 6));
      Saved : OpenCV.Core.Mat;
      procedure Capture (Image : in out OpenCV.Core.Mat) is
      begin
         Saved := Image.Clone;
      end Capture;
   begin
      OpenCV.Core.UInt8_Vec3_Mat_View.With_Writable_Mat_View
        (Data, 2, 3, Capture'Access);
      Data (1) := (9, 9, 9);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Saved, 0, 0) = (1, 2, 3),
         "UInt8 Vec3 Clone must retain original caller pixel");
      OpenCV.Core.UInt8_Vec3_Access.Set (Saved, 0, 0, (8, 8, 8));
      AUnit.Assertions.Assert
        (Data (1) = (9, 9, 9), "UInt8 Vec3 Clone must be independent");
   end UInt8_Vec3_External_Mat_View_Permits_Independent_Clone;

   procedure Float32_Vec3_External_Mat_View_Permits_Independent_Clone
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Data  : aliased OpenCV.Core.Float32_Vec3_Mat_View.Buffer_Array :=
        (1 => (1.25, -2.5, 3.75), 2 .. 6 => (4.0, 5.0, 6.0));
      Saved : OpenCV.Core.Mat;
      procedure Capture (Image : in out OpenCV.Core.Mat) is
      begin
         Saved := Image.Clone;
      end Capture;
   begin
      OpenCV.Core.Float32_Vec3_Mat_View.With_Writable_Mat_View
        (Data, 2, 3, Capture'Access);
      Data (1) := (9.0, 9.0, 9.0);
      AUnit.Assertions.Assert
        (Vec3_Approximately_Equal
           (OpenCV.Core.Float32_Vec3_Access.Get (Saved, 0, 0),
            (1.25, -2.5, 3.75)),
         "Float32 Vec3 Clone must retain original caller pixel");
      OpenCV.Core.Float32_Vec3_Access.Set (Saved, 0, 0, (8.0, 8.0, 8.0));
      AUnit.Assertions.Assert
        (Vec3_Approximately_Equal (Data (1), (9.0, 9.0, 9.0)),
         "Float32 Vec3 Clone must be independent");
   end Float32_Vec3_External_Mat_View_Permits_Independent_Clone;

   procedure Vec3_External_Mat_Views_Reject_Shallow_Escape
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Data : aliased OpenCV.Core.UInt8_Vec3_Mat_View.Buffer_Array :=
        (1 .. 6 => (1, 2, 3));
      Float_Data : aliased OpenCV.Core.Float32_Vec3_Mat_View.Buffer_Array :=
        (1 .. 6 => (1.0, 2.0, 3.0));
      procedure UInt8_Process (Image : in out OpenCV.Core.Mat) is
         procedure Escape is
         begin
            declare
               Copy : OpenCV.Core.Mat := Image;
               pragma Unreferenced (Copy);
            begin
               null;
            end;
         end Escape;
      begin
         Assert_Raises_OpenCV_Error (Escape'Access, "UInt8 Vec3 assignment");
         OpenCV.Core.UInt8_Vec3_Access.Set (Image, 0, 0, (7, 8, 9));
      end UInt8_Process;
      procedure Float32_Process (Image : in out OpenCV.Core.Mat) is
         procedure Escape is
         begin
            declare
               View : constant OpenCV.Core.Mat :=
                 Image.Region ((X => 0, Y => 0, Width => 1, Height => 1));
               pragma Unreferenced (View);
            begin
               null;
            end;
         end Escape;
      begin
         Assert_Raises_OpenCV_Error (Escape'Access, "Float32 Vec3 Region");
         OpenCV.Core.Float32_Vec3_Access.Set (Image, 0, 0, (7.0, 8.0, 9.0));
      end Float32_Process;
   begin
      OpenCV.Core.UInt8_Vec3_Mat_View.With_Writable_Mat_View
        (UInt8_Data, 2, 3, UInt8_Process'Access);
      OpenCV.Core.Float32_Vec3_Mat_View.With_Writable_Mat_View
        (Float_Data, 2, 3, Float32_Process'Access);
      AUnit.Assertions.Assert
        (UInt8_Data (1) = (7, 8, 9)
         and then Vec3_Approximately_Equal (Float_Data (1), (7.0, 8.0, 9.0)),
         "Temporary Vec3 views must remain usable after rejected escapes");
   end Vec3_External_Mat_Views_Reject_Shallow_Escape;

   procedure Vec3_External_Mat_Views_Propagate_Callback_Exceptions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Data : aliased OpenCV.Core.UInt8_Vec3_Mat_View.Buffer_Array :=
        (1 .. 6 => (1, 2, 3));
      Float_Data : aliased OpenCV.Core.Float32_Vec3_Mat_View.Buffer_Array :=
        (1 .. 6 => (1.0, 2.0, 3.0));
      Raised     : Boolean := False;
      Identity   : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;
      procedure UInt8_Process (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.UInt8_Vec3_Access.Set (Image, 0, 0, (77, 88, 99));
         raise Borrowed_Row_Callback_Error;
      end UInt8_Process;
      procedure Float32_Process (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Float32_Vec3_Access.Set (Image, 0, 0, (7.75, -8.5, 9.25));
         raise Borrowed_Row_Callback_Error;
      end Float32_Process;
   begin
      begin
         OpenCV.Core.UInt8_Vec3_Mat_View.With_Writable_Mat_View
           (UInt8_Data, 2, 3, UInt8_Process'Access);
      exception
         when Error : Borrowed_Row_Callback_Error =>
            Raised := True;
            Identity := Ada.Exceptions.Exception_Identity (Error);
      end;
      AUnit.Assertions.Assert
        (Raised
         and then Identity = Borrowed_Row_Callback_Error'Identity
         and then UInt8_Data (1) = (77, 88, 99),
         "UInt8 Vec3 callback exception and write must be preserved");
      Raised := False;
      Identity := Ada.Exceptions.Null_Id;
      begin
         OpenCV.Core.Float32_Vec3_Mat_View.With_Writable_Mat_View
           (Float_Data, 2, 3, Float32_Process'Access);
      exception
         when Error : Borrowed_Row_Callback_Error =>
            Raised := True;
            Identity := Ada.Exceptions.Exception_Identity (Error);
      end;
      AUnit.Assertions.Assert
        (Raised
         and then Identity = Borrowed_Row_Callback_Error'Identity
         and then Vec3_Approximately_Equal
                    (Float_Data (1), (7.75, -8.5, 9.25)),
         "Float32 Vec3 callback exception and write must be preserved");
   end Vec3_External_Mat_Views_Propagate_Callback_Exceptions;

   procedure Float32_External_Buffer_Mat_View_Is_Zero_Copy
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Data : aliased OpenCV.Core.Float32_Mat_View.Buffer_Array :=
        (5 => 0.5, 6 => -1.5, 7 => 2.25, 8 => -3.75, 9 => 4.125, 10 => 5.0);

      procedure Mutate (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (Image.Rows = 2
            and then Image.Columns = 3
            and then Image.Depth = OpenCV.Core.Float32
            and then Image.Channels = 1
            and then Natural (Image.Total) = 6
            and then Image.Is_Continuous,
            "An external Float32 C1 view must report the requested Mat"
            & " metadata");

         Data (7) := 12.5;
         AUnit.Assertions.Assert
           (Approximately_Equal
              (Long_Float
                 (OpenCV.Core.Float32_Access.Get
                    (Image, Row => 0, Column => 2)),
               12.5),
            "A write through Data must be immediately visible through Get");

         OpenCV.Core.Float32_Access.Set
           (Image, Row => 1, Column => 0, Value => -7.25);
         AUnit.Assertions.Assert
           (Approximately_Equal (Long_Float (Data (8)), -7.25),
            "A write through Set must be immediately visible through Data");

         Image.Set_To (OpenCV.Core.Make_Scalar (3.5));
         AUnit.Assertions.Assert
           (Approximately_Equal (Long_Float (Data (5)), 3.5)
            and then Approximately_Equal (Long_Float (Data (10)), 3.5),
            "An in-place OpenCV write must mutate the caller-owned buffer");
      end Mutate;
   begin
      OpenCV.Core.Float32_Mat_View.With_Writable_Mat_View
        (Data, Rows => 2, Columns => 3, Process => Mutate'Access);

      AUnit.Assertions.Assert
        (Approximately_Equal (Long_Float (Data (5)), 3.5)
         and then Approximately_Equal (Long_Float (Data (8)), 3.5)
         and then Approximately_Equal (Long_Float (Data (10)), 3.5),
         "Mutations through the temporary view must remain in Data after"
         & " Process returns");
   end Float32_External_Buffer_Mat_View_Is_Zero_Copy;

   procedure Float32_External_Buffer_Mat_View_Rejects_Invalid_Shape
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Data    : aliased OpenCV.Core.Float32_Mat_View.Buffer_Array :=
        (1 => 1.0, 2 => 2.0, 3 => 3.0, 4 => 4.0, 5 => 5.0);
      Invoked : Boolean := False;

      procedure Mark (Image : in out OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Mark;

      procedure Attempt is
      begin
         OpenCV.Core.Float32_Mat_View.With_Writable_Mat_View
           (Data, Rows => 2, Columns => 3, Process => Mark'Access);
      end Attempt;
   begin
      Assert_Raises_OpenCV_Error
        (Attempt'Access,
         "Float32 external Mat view must reject a mismatched buffer length");
      AUnit.Assertions.Assert
        (not Invoked, "Invalid-shape validation must not invoke the callback");
      AUnit.Assertions.Assert
        (Approximately_Equal (Long_Float (Data (1)), 1.0)
         and then Approximately_Equal (Long_Float (Data (5)), 5.0),
         "Rejected external Mat view construction must not mutate Data");
   end Float32_External_Buffer_Mat_View_Rejects_Invalid_Shape;

   procedure Float32_External_Buffer_Mat_View_Rejects_Shallow_Escape
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Data  : aliased OpenCV.Core.Float32_Mat_View.Buffer_Array :=
        (1.0, 2.0, 3.0, 4.0, 5.0, 6.0);
      Owned : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));

      procedure Probe (Image : in out OpenCV.Core.Mat) is
         procedure Assign_Copy is
            Copy : OpenCV.Core.Mat;
            pragma Unreferenced (Copy);
         begin
            begin
               Copy := Image;
            exception
               when Program_Error =>
                  raise OpenCV.OpenCV_Error;
            end;
         end Assign_Copy;

         procedure Take_Region is
            View : OpenCV.Core.Mat;
            pragma Unreferenced (View);
         begin
            View := Image.Region ((X => 0, Y => 0, Width => 2, Height => 1));
         end Take_Region;

         procedure Take_Row is
            View : OpenCV.Core.Mat;
            pragma Unreferenced (View);
         begin
            View := Image.Row_View (0);
         end Take_Row;

         procedure Take_Column is
            View : OpenCV.Core.Mat;
            pragma Unreferenced (View);
         begin
            View := Image.Column_View (1);
         end Take_Column;

         procedure Take_Row_Range is
            View : OpenCV.Core.Mat;
            pragma Unreferenced (View);
         begin
            View := Image.Row_View ((Start => 0, Stop => 1));
         end Take_Row_Range;

         procedure Take_Column_Range is
            View : OpenCV.Core.Mat;
            pragma Unreferenced (View);
         begin
            View := Image.Column_View ((Start => 1, Stop => 3));
         end Take_Column_Range;

         procedure Take_Reshape is
            View : OpenCV.Core.Mat;
            pragma Unreferenced (View);
         begin
            View := Image.Reshape (1);
         end Take_Reshape;

         procedure Take_Reshape_Rows is
            View : OpenCV.Core.Mat;
            pragma Unreferenced (View);
         begin
            View := Image.Reshape (1, 3);
         end Take_Reshape_Rows;

         procedure Take_Diagonal is
            View : OpenCV.Core.Mat;
            pragma Unreferenced (View);
         begin
            View := Image.Diagonal_View (0);
         end Take_Diagonal;
      begin
         Assert_Raises_OpenCV_Error
           (Assign_Copy'Access,
            "Temporary external views must reject ordinary Mat assignment");
         Assert_Raises_OpenCV_Error
           (Take_Region'Access, "Temporary external views must reject Region");
         Assert_Raises_OpenCV_Error
           (Take_Row'Access, "Temporary external views must reject Row_View");
         Assert_Raises_OpenCV_Error
           (Take_Column'Access,
            "Temporary external views must reject Column_View");
         Assert_Raises_OpenCV_Error
           (Take_Row_Range'Access,
            "Temporary external views must reject a row-range view");
         Assert_Raises_OpenCV_Error
           (Take_Column_Range'Access,
            "Temporary external views must reject a column-range view");
         Assert_Raises_OpenCV_Error
           (Take_Reshape'Access,
            "Temporary external views must reject Reshape");
         Assert_Raises_OpenCV_Error
           (Take_Reshape_Rows'Access,
            "Temporary external views must reject a row-changing Reshape");
         Assert_Raises_OpenCV_Error
           (Take_Diagonal'Access,
            "Temporary external views must reject Diagonal_View");

         AUnit.Assertions.Assert
           (Approximately_Equal
              (Long_Float
                 (OpenCV.Core.Float32_Access.Get
                    (Image, Row => 0, Column => 0)),
               1.0),
            "Rejected shallow-escape attempts must leave the temporary Mat"
            & " usable");
      end Probe;
   begin
      declare
         Alias : constant OpenCV.Core.Mat := Owned;
      begin
         OpenCV.Core.Float32_Access.Set
           (Owned, Row => 0, Column => 0, Value => 9.0);
         AUnit.Assertions.Assert
           (Approximately_Equal
              (Long_Float
                 (OpenCV.Core.Float32_Access.Get
                    (Alias, Row => 0, Column => 0)),
               9.0),
            "Ordinary OpenCV-owned Mats must retain shallow assignment");
         declare
            View : constant OpenCV.Core.Mat :=
              Owned.Region ((X => 0, Y => 0, Width => 1, Height => 1));
         begin
            AUnit.Assertions.Assert
              (Approximately_Equal
                 (Long_Float
                    (OpenCV.Core.Float32_Access.Get
                       (View, Row => 0, Column => 0)),
                  9.0),
               "Ordinary OpenCV-owned Mats must retain Region views");
         end;
      end;

      OpenCV.Core.Float32_Mat_View.With_Writable_Mat_View
        (Data, Rows => 2, Columns => 3, Process => Probe'Access);
   end Float32_External_Buffer_Mat_View_Rejects_Shallow_Escape;

   procedure Float32_External_Buffer_Mat_View_Permits_Independent_Clone
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Data  : aliased OpenCV.Core.Float32_Mat_View.Buffer_Array :=
        (2 => 1.25, 3 => -2.5, 4 => 3.75, 5 => -4.5, 6 => 5.125, 7 => 6.0);
      Saved : OpenCV.Core.Mat;

      procedure Capture (Image : in out OpenCV.Core.Mat) is
      begin
         Saved := Image.Clone;
         AUnit.Assertions.Assert
           (Saved.Rows = 2
            and then Saved.Columns = 3
            and then Saved.Depth = OpenCV.Core.Float32
            and then Saved.Channels = 1,
            "Clone of an external view must preserve Mat metadata");
      end Capture;
   begin
      OpenCV.Core.Float32_Mat_View.With_Writable_Mat_View
        (Data, Rows => 2, Columns => 3, Process => Capture'Access);

      Data (2) := 99.0;
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float
              (OpenCV.Core.Float32_Access.Get (Saved, Row => 0, Column => 0)),
            1.25),
         "A cloned external view must retain the pre-mutation value");
      AUnit.Assertions.Assert
        (Approximately_Equal (Long_Float (Data (2)), 99.0),
         "Mutating Data after Process must not change the independent clone");
   end Float32_External_Buffer_Mat_View_Permits_Independent_Clone;

   procedure Float32_External_Buffer_Mat_View_Propagates_Callback_Exception
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Data    : aliased OpenCV.Core.Float32_Mat_View.Buffer_Array :=
        (4 => 1.0, 5 => 2.0, 6 => 3.0, 7 => 4.0);
      Raised  : Boolean := False;
      Message : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;

      procedure Mutate (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Float32_Access.Set
           (Image, Row => 1, Column => 0, Value => 9.25);
         raise Borrowed_Row_Callback_Error;
      end Mutate;
   begin
      begin
         OpenCV.Core.Float32_Mat_View.With_Writable_Mat_View
           (Data, Rows => 2, Columns => 2, Process => Mutate'Access);
      exception
         when Error : Borrowed_Row_Callback_Error =>
            Raised := True;
            Message := Ada.Exceptions.Exception_Identity (Error);
      end;

      AUnit.Assertions.Assert
        (Raised and then Message = Borrowed_Row_Callback_Error'Identity,
         "A callback exception must propagate unchanged");
      AUnit.Assertions.Assert
        (Approximately_Equal (Long_Float (Data (6)), 9.25)
         and then Approximately_Equal (Long_Float (Data (4)), 1.0),
         "Writes completed before a callback exception must remain in Data");

      Data (5) := 8.0;
      AUnit.Assertions.Assert
        (Approximately_Equal (Long_Float (Data (5)), 8.0),
         "Data must remain caller-owned after a callback exception");
   end Float32_External_Buffer_Mat_View_Propagates_Callback_Exception;

   procedure UInt8_External_Buffer_Mat_View_Is_Zero_Copy
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Data : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (11 => 1, 12 => 2, 13 => 3, 14 => 10, 15 => 20, 16 => 30);

      procedure Mutate (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (Image.Rows = 2
            and then Image.Columns = 3
            and then Image.Depth = OpenCV.Core.UInt8
            and then Image.Channels = 1
            and then Natural (Image.Total) = 6
            and then Image.Is_Continuous,
            "An external UInt8 C1 view must report the requested Mat"
            & " metadata");

         Data (13) := 42;
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Image, Row => 0, Column => 2) = 42,
            "A write through Data must be immediately visible through Get");

         OpenCV.Core.UInt8_Access.Set
           (Image, Row => 1, Column => 0, Value => 200);
         AUnit.Assertions.Assert
           (Data (14) = 200,
            "A write through Set must be immediately visible through Data");

         Image.Set_To (OpenCV.Core.Make_Scalar (255.0));
         AUnit.Assertions.Assert
           (Data (11) = 255 and then Data (16) = 255,
            "An in-place OpenCV write must mutate the caller-owned buffer");
      end Mutate;
   begin
      OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View
        (Data, Rows => 2, Columns => 3, Process => Mutate'Access);

      AUnit.Assertions.Assert
        (Data (11) = 255 and then Data (14) = 255 and then Data (16) = 255,
         "Mutations through the temporary view must remain in Data after"
         & " Process returns");
   end UInt8_External_Buffer_Mat_View_Is_Zero_Copy;

   procedure UInt8_External_Buffer_Mat_View_Rejects_Invalid_Shape
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Data    : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (7 => 1, 8 => 2, 9 => 3, 10 => 4, 11 => 5);
      Invoked : Boolean := False;

      procedure Mark (Image : in out OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Mark;

      procedure Attempt is
      begin
         OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View
           (Data, Rows => 2, Columns => 3, Process => Mark'Access);
      end Attempt;
   begin
      Assert_Raises_OpenCV_Error
        (Attempt'Access,
         "UInt8 external Mat view must reject a mismatched buffer length");
      AUnit.Assertions.Assert
        (not Invoked, "Invalid-shape validation must not invoke the callback");
      AUnit.Assertions.Assert
        (Data (7) = 1 and then Data (11) = 5,
         "Rejected external Mat view construction must not mutate Data");
   end UInt8_External_Buffer_Mat_View_Rejects_Invalid_Shape;

   procedure UInt8_External_Buffer_Mat_View_Rejects_Shallow_Escape
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Data : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (21 => 1, 22 => 2, 23 => 3, 24 => 4, 25 => 5, 26 => 6);

      procedure Probe (Image : in out OpenCV.Core.Mat) is
         procedure Assign_Copy is
            Copy : OpenCV.Core.Mat;
            pragma Unreferenced (Copy);
         begin
            begin
               Copy := Image;
            exception
               when Program_Error =>
                  raise OpenCV.OpenCV_Error;
            end;
         end Assign_Copy;

         procedure Take_Region is
            View : OpenCV.Core.Mat;
            pragma Unreferenced (View);
         begin
            View := Image.Region ((X => 0, Y => 0, Width => 2, Height => 1));
         end Take_Region;
      begin
         Assert_Raises_OpenCV_Error
           (Assign_Copy'Access,
            "Temporary external UInt8 views must reject Mat assignment");
         Assert_Raises_OpenCV_Error
           (Take_Region'Access,
            "Temporary external UInt8 views must reject Region");
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Image, Row => 0, Column => 0) = 1,
            "Rejected shallow-escape attempts must leave the temporary Mat"
            & " usable");
      end Probe;
   begin
      OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View
        (Data, Rows => 2, Columns => 3, Process => Probe'Access);
   end UInt8_External_Buffer_Mat_View_Rejects_Shallow_Escape;

   procedure UInt8_External_Buffer_Mat_View_Permits_Independent_Clone
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Data  : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (31 => 1, 32 => 2, 33 => 3, 34 => 4, 35 => 5, 36 => 6);
      Saved : OpenCV.Core.Mat;

      procedure Capture (Image : in out OpenCV.Core.Mat) is
      begin
         Saved := Image.Clone;
         AUnit.Assertions.Assert
           (Saved.Rows = 2
            and then Saved.Columns = 3
            and then Saved.Depth = OpenCV.Core.UInt8
            and then Saved.Channels = 1,
            "Clone of an external UInt8 view must preserve Mat metadata");
      end Capture;
   begin
      OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View
        (Data, Rows => 2, Columns => 3, Process => Capture'Access);

      Data (31) := 99;
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Saved, Row => 0, Column => 0) = 1,
         "A cloned external UInt8 view must retain the pre-mutation value");
      OpenCV.Core.UInt8_Access.Set (Saved, Row => 0, Column => 1, Value => 77);
      AUnit.Assertions.Assert
        (Data (32) = 2, "Mutating an independent clone must not change Data");
   end UInt8_External_Buffer_Mat_View_Permits_Independent_Clone;

   procedure UInt8_External_Buffer_Mat_View_Propagates_Callback_Exception
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Data    : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (41 => 1, 42 => 2, 43 => 3, 44 => 4);
      Raised  : Boolean := False;
      Message : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;

      procedure Mutate (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.UInt8_Access.Set
           (Image, Row => 1, Column => 0, Value => 201);
         raise Borrowed_Row_Callback_Error;
      end Mutate;
   begin
      begin
         OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View
           (Data, Rows => 2, Columns => 2, Process => Mutate'Access);
      exception
         when Error : Borrowed_Row_Callback_Error =>
            Raised := True;
            Message := Ada.Exceptions.Exception_Identity (Error);
      end;

      AUnit.Assertions.Assert
        (Raised and then Message = Borrowed_Row_Callback_Error'Identity,
         "A UInt8 callback exception must propagate unchanged");
      AUnit.Assertions.Assert
        (Data (43) = 201 and then Data (41) = 1,
         "Writes completed before a callback exception must remain in Data");

      Data (42) := 8;
      AUnit.Assertions.Assert
        (Data (42) = 8,
         "Data must remain caller-owned after a callback exception");
   end UInt8_External_Buffer_Mat_View_Propagates_Callback_Exception;

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);

   Result : aliased AUnit.Test_Suites.Test_Suite;

   procedure F32_V3_Row_Invalid (Test : in out Mat_Test_Fixture)
   renames Float32_Vec3_Borrowed_Row_Rejects_Invalid_Mats_And_Indices;
   procedure U8_V3_Buffer_Offset (Test : in out Mat_Test_Fixture)
   renames UInt8_Vec3_Borrowed_Buffer_Accepts_Continuous_Offset_Region;
   procedure F32_V3_Buffer_Exception (Test : in out Mat_Test_Fixture)
   renames Float32_Vec3_Borrowed_Buffer_Propagates_Callback_Exception;
   procedure F32_V3_Buffer_Offset (Test : in out Mat_Test_Fixture)
   renames Float32_Vec3_Borrowed_Buffer_Accepts_Continuous_Offset_Region;
   procedure F32_View_Clone (Test : in out Mat_Test_Fixture)
   renames Float32_External_Buffer_Mat_View_Permits_Independent_Clone;
   procedure F32_View_Exception (Test : in out Mat_Test_Fixture)
   renames Float32_External_Buffer_Mat_View_Propagates_Callback_Exception;
   procedure U8_View_Exception (Test : in out Mat_Test_Fixture)
   renames UInt8_External_Buffer_Mat_View_Propagates_Callback_Exception;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
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
           ("Float32 borrowed writable row is zero-copy",
            Float32_Borrowed_Writable_Row_Is_Zero_Copy'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 borrowed read-only row matches Mat",
            Float32_Borrowed_Read_Only_Row_Matches_Mat'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 borrowed row handles non-continuous Regions",
            Float32_Borrowed_Row_Handles_Non_Continuous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 borrowed row rejects invalid Mats and indices",
            Float32_Borrowed_Row_Rejects_Invalid_Mats_And_Indices'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 borrowed row propagates callback exceptions",
            Float32_Borrowed_Row_Propagates_Callback_Exception'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 borrowed writable row is zero-copy",
            UInt8_Borrowed_Writable_Row_Is_Zero_Copy'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 borrowed read-only row matches Mat",
            UInt8_Borrowed_Read_Only_Row_Matches_Mat'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 borrowed row handles non-continuous Regions",
            UInt8_Borrowed_Row_Handles_Non_Continuous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 borrowed row rejects invalid Mats and indices",
            UInt8_Borrowed_Row_Rejects_Invalid_Mats_And_Indices'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 borrowed row propagates callback exceptions",
            UInt8_Borrowed_Row_Propagates_Callback_Exception'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 borrowed writable row is zero-copy",
            UInt8_Vec3_Borrowed_Writable_Row_Is_Zero_Copy'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 borrowed read-only row matches Mat",
            UInt8_Vec3_Borrowed_Read_Only_Row_Matches_Mat'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 borrowed row handles non-continuous Regions",
            UInt8_Vec3_Borrowed_Row_Handles_Non_Continuous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 borrowed row rejects invalid Mats and indices",
            UInt8_Vec3_Borrowed_Row_Rejects_Invalid_Mats_And_Indices'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 borrowed row propagates callback exceptions",
            UInt8_Vec3_Borrowed_Row_Propagates_Callback_Exception'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec3 borrowed writable row is zero-copy",
            Float32_Vec3_Borrowed_Writable_Row_Is_Zero_Copy'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec3 borrowed read-only row matches Mat",
            Float32_Vec3_Borrowed_Read_Only_Row_Matches_Mat'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec3 borrowed row handles non-continuous Regions",
            Float32_Vec3_Borrowed_Row_Handles_Non_Continuous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec3 borrowed row rejects invalid Mats and indices",
            F32_V3_Row_Invalid'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec3 borrowed row propagates callback exceptions",
            Float32_Vec3_Borrowed_Row_Propagates_Callback_Exception'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 borrowed writable buffer is zero-copy",
            Float32_Borrowed_Writable_Buffer_Is_Zero_Copy'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 borrowed read-only buffer matches Mat",
            Float32_Borrowed_Read_Only_Buffer_Matches_Mat'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 borrowed buffer accepts continuous Regions",
            Float32_Borrowed_Buffer_Accepts_Continuous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 borrowed buffer rejects invalid Mats",
            Float32_Borrowed_Buffer_Rejects_Invalid_Mats'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 borrowed buffer propagates callback exceptions",
            Float32_Borrowed_Buffer_Propagates_Callback_Exception'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 borrowed writable buffer is zero-copy",
            UInt8_Borrowed_Writable_Buffer_Is_Zero_Copy'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 borrowed read-only buffer matches Mat",
            UInt8_Borrowed_Read_Only_Buffer_Matches_Mat'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 borrowed buffer accepts continuous Regions",
            UInt8_Borrowed_Buffer_Accepts_Continuous_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 borrowed buffer rejects invalid Mats",
            UInt8_Borrowed_Buffer_Rejects_Invalid_Mats'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 borrowed buffer propagates callback exceptions",
            UInt8_Borrowed_Buffer_Propagates_Callback_Exception'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 borrowed writable buffer is zero-copy",
            UInt8_Vec3_Borrowed_Writable_Buffer_Is_Zero_Copy'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 borrowed read-only buffer matches Mat",
            UInt8_Vec3_Borrowed_Read_Only_Buffer_Matches_Mat'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 borrowed buffer accepts continuous offset Region",
            U8_V3_Buffer_Offset'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 borrowed buffer rejects invalid Mats",
            UInt8_Vec3_Borrowed_Buffer_Rejects_Invalid_Mats'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 borrowed buffer propagates callback exceptions",
            UInt8_Vec3_Borrowed_Buffer_Propagates_Callback_Exception'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec3 borrowed writable buffer is zero-copy",
            Float32_Vec3_Borrowed_Writable_Buffer_Is_Zero_Copy'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec3 borrowed read-only buffer matches Mat",
            Float32_Vec3_Borrowed_Read_Only_Buffer_Matches_Mat'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec3 borrowed buffer accepts continuous offset Region",
            F32_V3_Buffer_Offset'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec3 borrowed buffer rejects invalid Mats",
            Float32_Vec3_Borrowed_Buffer_Rejects_Invalid_Mats'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec3 borrowed buffer propagates callback exceptions",
            F32_V3_Buffer_Exception'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 external buffer Mat view is zero-copy",
            Float32_External_Buffer_Mat_View_Is_Zero_Copy'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 external Mat view is zero-copy",
            UInt8_Vec3_External_Mat_View_Is_Zero_Copy'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec3 external Mat view is zero-copy",
            Float32_Vec3_External_Mat_View_Is_Zero_Copy'Access));
      Result.Add_Test
        (Caller.Create
           ("Vec3 external Mat views reject invalid shape",
            Vec3_External_Mat_Views_Reject_Invalid_Shape'Access));
      Result.Add_Test
        (Caller.Create
           ("Vec3 external Mat views reject shallow escape",
            Vec3_External_Mat_Views_Reject_Shallow_Escape'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 external Mat view permits independent Clone",
            UInt8_Vec3_External_Mat_View_Permits_Independent_Clone'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec3 external Mat view permits independent Clone",
            Float32_Vec3_External_Mat_View_Permits_Independent_Clone'Access));
      Result.Add_Test
        (Caller.Create
           ("Vec3 external Mat views propagate callback exceptions",
            Vec3_External_Mat_Views_Propagate_Callback_Exceptions'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 external buffer Mat view rejects invalid shape",
            Float32_External_Buffer_Mat_View_Rejects_Invalid_Shape'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 external buffer Mat view rejects shallow escape",
            Float32_External_Buffer_Mat_View_Rejects_Shallow_Escape'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 external buffer Mat view permits independent Clone",
            F32_View_Clone'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 external buffer Mat view propagates callback exceptions",
            F32_View_Exception'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 external buffer Mat view is zero-copy",
            UInt8_External_Buffer_Mat_View_Is_Zero_Copy'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 external buffer Mat view rejects invalid shape",
            UInt8_External_Buffer_Mat_View_Rejects_Invalid_Shape'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 external buffer Mat view rejects shallow escape",
            UInt8_External_Buffer_Mat_View_Rejects_Shallow_Escape'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 external buffer Mat view permits independent Clone",
            UInt8_External_Buffer_Mat_View_Permits_Independent_Clone'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 external buffer Mat view propagates callback exceptions",
            U8_View_Exception'Access));
      return Result'Access;
   end Suite;

end Mat_Access_Tests;
