with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Int8_Access;

package body Int8_Access_Tests is

   use type OpenCV.Int8_Value;
   use Mat_Test_Support;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Int8_Image
     (Rows, Columns : Natural; Channels : OpenCV.Core.Channel_Count := 1)
      return OpenCV.Core.Mat
   is (OpenCV.Core.Create
         (Rows, Columns, (Depth => OpenCV.Core.Int8, Channels => Channels)));

   procedure Typed_Element_Access_Preserves_Signed_Endpoints
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat := Int8_Image (3, 3);
   begin
      Image.Set_To (OpenCV.Make_Scalar (42.0));
      OpenCV.Core.Int8_Access.Set (Image, 0, 0, -128);
      OpenCV.Core.Int8_Access.Set (Image, 0, 1, -127);
      OpenCV.Core.Int8_Access.Set (Image, 0, 2, -1);
      OpenCV.Core.Int8_Access.Set (Image, 1, 0, 0);
      OpenCV.Core.Int8_Access.Set (Image, 1, 1, 1);
      OpenCV.Core.Int8_Access.Set (Image, 2, 0, 126);
      OpenCV.Core.Int8_Access.Set (Image, 2, 2, 127);

      AUnit.Assertions.Assert
        (OpenCV.Core.Int8_Access.Get (Image, 0, 0) = -128
         and then OpenCV.Core.Int8_Access.Get (Image, 0, 1) = -127
         and then OpenCV.Core.Int8_Access.Get (Image, 0, 2) = -1
         and then OpenCV.Core.Int8_Access.Get (Image, 1, 0) = 0
         and then OpenCV.Core.Int8_Access.Get (Image, 1, 1) = 1
         and then OpenCV.Core.Int8_Access.Get (Image, 2, 0) = 126
         and then OpenCV.Core.Int8_Access.Get (Image, 2, 2) = 127,
         "Int8 Get must preserve -128, -127, -1, 0, 1, 126, and 127");
      AUnit.Assertions.Assert
        (OpenCV.Core.Int8_Access.Get (Image, 1, 2) = 42
         and then OpenCV.Core.Int8_Access.Get (Image, 2, 1) = 42,
         "Int8 writes must leave neighboring elements unchanged");
   end Typed_Element_Access_Preserves_Signed_Endpoints;

   procedure Region_And_Clone_Share_Or_Isolate_Writes (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat := Int8_Image (4, 6);
      View   : OpenCV.Core.Mat;
      Alias  : OpenCV.Core.Mat;
      Copy   : OpenCV.Core.Mat;
   begin
      Parent.Set_To (OpenCV.Make_Scalar (1.0));
      View := Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Alias := Parent;
      AUnit.Assertions.Assert
        (not View.Is_Continuous,
         "The Region used for Int8 access must be non-contiguous");

      OpenCV.Core.Int8_Access.Set (View, 0, 0, -128);
      OpenCV.Core.Int8_Access.Set (View, 1, 2, 127);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int8_Access.Get (Parent, 1, 1) = -128
         and then OpenCV.Core.Int8_Access.Get (Parent, 2, 3) = 127
         and then OpenCV.Core.Int8_Access.Get (Alias, 1, 1) = -128
         and then OpenCV.Core.Int8_Access.Get (Parent, 1, 0) = 1
         and then OpenCV.Core.Int8_Access.Get (Parent, 1, 4) = 1,
         "Int8 Region writes must be shared and must not touch padding");

      Copy := Parent.Clone;
      OpenCV.Core.Int8_Access.Set (Parent, 1, 1, 7);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int8_Access.Get (Copy, 1, 1) = -128
         and then OpenCV.Core.Int8_Access.Get (View, 0, 0) = 7,
         "An Int8 clone must stay independent of later shared writes");
   end Region_And_Clone_Share_Or_Isolate_Writes;

   procedure Typed_Access_Rejects_Invalid_Mats_And_Indices
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Multi       : constant OpenCV.Core.Mat := Int8_Image (1, 1, 2);
      Image       : constant OpenCV.Core.Mat := Int8_Image (2, 2);

      procedure Read_UInt8 is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Int8_Access.Get (UInt8_Image, 0, 0) = 0,
            "A UInt8 Mat Int8 read unexpectedly succeeded");
      end Read_UInt8;
      procedure Read_Multi is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Int8_Access.Get (Multi, 0, 0) = 0,
            "A multi-channel Int8 read unexpectedly succeeded");
      end Read_Multi;
      procedure Read_Negative_Row is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Int8_Access.Get (Image, -1, 0) = 0,
            "A negative Int8 row read unexpectedly succeeded");
      end Read_Negative_Row;
      procedure Read_Negative_Column is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Int8_Access.Get (Image, 0, -1) = 0,
            "A negative Int8 column read unexpectedly succeeded");
      end Read_Negative_Column;
      procedure Read_Past_Row is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Int8_Access.Get (Image, 2, 0) = 0,
            "A past-the-end Int8 row read unexpectedly succeeded");
      end Read_Past_Row;
      procedure Read_Past_Column is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Int8_Access.Get (Image, 0, 2) = 0,
            "A past-the-end Int8 column read unexpectedly succeeded");
      end Read_Past_Column;
   begin
      Assert_Raises_OpenCV_Error (Read_UInt8'Access, "Int8 rejects UInt8");
      Assert_Raises_OpenCV_Error (Read_Multi'Access, "Int8 rejects C2");
      Assert_Raises_OpenCV_Error
        (Read_Negative_Row'Access, "Int8 rejects a negative row");
      Assert_Raises_OpenCV_Error
        (Read_Negative_Column'Access, "Int8 rejects a negative column");
      Assert_Raises_OpenCV_Error
        (Read_Past_Row'Access, "Int8 rejects a row after the last row");
      Assert_Raises_OpenCV_Error
        (Read_Past_Column'Access, "Int8 rejects a column after the last");
   end Typed_Access_Rejects_Invalid_Mats_And_Indices;

   procedure Two_And_Three_Dimensional_Indexing (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Plane   : OpenCV.Core.Mat := Int8_Image (1, 4);
      Volume  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4),
           Element_Type => (Depth => OpenCV.Core.Int8, Channels => 1));
      Indices : constant OpenCV.Core.Index_Array (8 .. 10) := (1, 2, 3);
      Alias   : OpenCV.Core.Mat;
      Copy    : OpenCV.Core.Mat;

      procedure Read_Short is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Int8_Access.Get (Volume, Indices => (1, 2)) = 0,
            "A short Int8 index list unexpectedly succeeded");
      end Read_Short;
      procedure Read_Past is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Int8_Access.Get (Volume, Indices => (0, 3, 0)) = 0,
            "An out-of-range Int8 axis unexpectedly succeeded");
      end Read_Past;
      procedure Read_Wrong_Depth is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Int8_Access.Get (Plane, Indices => (0, 0)) = 0,
            "A wrong-depth Int8 N-D read unexpectedly succeeded");
      end Read_Wrong_Depth;
   begin
      Plane.Set_To (OpenCV.Make_Scalar (0.0));
      OpenCV.Core.Int8_Access.Set (Plane, Indices => (0, 0), Value => -128);
      OpenCV.Core.Int8_Access.Set (Plane, Indices => (0, 3), Value => 127);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int8_Access.Get (Plane, Indices => (0, 0)) = -128
         and then OpenCV.Core.Int8_Access.Get (Plane, Indices => (0, 3)) = 127
         and then OpenCV.Core.Int8_Access.Get (Plane, Indices => (0, 1)) = 0,
         "2-D Int8 N-D access must preserve endpoints and neighbors");

      Volume.Set_To (OpenCV.Make_Scalar (0.0));
      OpenCV.Core.Int8_Access.Set
        (Volume, Indices => (0, 0, 0), Value => -128);
      OpenCV.Core.Int8_Access.Set (Volume, Indices => Indices, Value => 127);
      Alias := Volume;
      Copy := Volume.Clone;
      OpenCV.Core.Int8_Access.Set (Volume, Indices => (0, 0, 0), Value => -1);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int8_Access.Get (Volume, Indices => (1, 2, 3)) = 127
         and then OpenCV.Core.Int8_Access.Get (Alias, Indices => (0, 0, 0))
                  = -1
         and then OpenCV.Core.Int8_Access.Get (Copy, Indices => (0, 0, 0))
                  = -128
         and then OpenCV.Core.Int8_Access.Get (Volume, Indices => (0, 0, 1))
                  = 0,
         "3-D Int8 access must honor bounds, aliases, and clones");

      Plane := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Volume :=
        OpenCV.Core.Create
          (Shape        => (2, 2, 2),
           Element_Type => (Depth => OpenCV.Core.Int8, Channels => 2));
      Assert_Raises_OpenCV_Error (Read_Short'Access, "Int8 index count");
      Assert_Raises_OpenCV_Error (Read_Past'Access, "Int8 axis range");
      Assert_Raises_OpenCV_Error (Read_Wrong_Depth'Access, "Int8 N-D depth");
   end Two_And_Three_Dimensional_Indexing;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Int8 2-D access preserves signed endpoints and neighbors",
            Typed_Element_Access_Preserves_Signed_Endpoints'Access));
      Result.Add_Test
        (Caller.Create
           ("Int8 Region writes are shared and clones stay independent",
            Region_And_Clone_Share_Or_Isolate_Writes'Access));
      Result.Add_Test
        (Caller.Create
           ("Int8 access rejects wrong type and out-of-range indices",
            Typed_Access_Rejects_Invalid_Mats_And_Indices'Access));
      Result.Add_Test
        (Caller.Create
           ("Int8 2-D and 3-D access preserves bounds aliases and clones",
            Two_And_Three_Dimensional_Indexing'Access));
      return Result'Access;
   end Suite;

end Int8_Access_Tests;
