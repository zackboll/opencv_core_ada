with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV.Core;
with OpenCV.Core.Float16_Access;
with OpenCV.Core.Float16_Vec3;
with OpenCV.Core.Float16_Vec3_Access;
with OpenCV.Core.Float32_Vec3;
with OpenCV.Core.Float32_Vec3_Access;

package body Float16_Vec3_Access_Tests is

   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_16;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use Mat_Test_Support;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Value_Of
     (Bits : Interfaces.Unsigned_16) return OpenCV.Core.Float16_Value
   is (OpenCV.Core.Float16_From_Bits (Bits));

   function Bits_Of
     (Value : OpenCV.Core.Float16_Value) return Interfaces.Unsigned_16
   is (OpenCV.Core.Float16_Bits (Value));

   function Pixel
     (C0, C1, C2 : Interfaces.Unsigned_16)
      return OpenCV.Core.Float16_Vec3.Vector
   is ((0 => Value_Of (C0), 1 => Value_Of (C1), 2 => Value_Of (C2)));

   procedure Assert_Component_Bits
     (Value    : OpenCV.Core.Float16_Vec3.Vector;
      Expected : OpenCV.Core.Float16_Vec3.Vector;
      Message  : String) is
   begin
      for Component in OpenCV.Core.Float16_Vec3.Component_Index loop
         declare
            Stored   : constant Interfaces.Unsigned_16 :=
              Bits_Of (Value (Component));
            Wanted   : constant Interfaces.Unsigned_16 :=
              Bits_Of (Expected (Component));
            Position : constant String := Integer'Image (Component);
         begin
            AUnit.Assertions.Assert
              (Stored = Wanted,
               Message
               & " component"
               & Position
               & " (got"
               & Interfaces.Unsigned_16'Image (Stored)
               & ", expected"
               & Interfaces.Unsigned_16'Image (Wanted)
               & ")");
         end;
      end loop;
   end Assert_Component_Bits;

   procedure Assert_Stored_Pixel
     (Image    : OpenCV.Core.Mat;
      Row      : Integer;
      Column   : Integer;
      Expected : OpenCV.Core.Float16_Vec3.Vector;
      Message  : String) is
   begin
      Assert_Component_Bits
        (OpenCV.Core.Float16_Vec3_Access.Get (Image, Row, Column),
         Expected,
         Message);
   end Assert_Stored_Pixel;

   procedure Typed_C3_Pixel_Access_Preserves_Special_Encodings
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float16, Channels => 3));
      A     : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#0000#, 16#8000#, 16#0001#);
      B     : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#03FF#, 16#0400#, 16#3C00#);
      C     : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#BC00#, 16#7BFF#, 16#FBFF#);
      D     : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#7C00#, 16#FC00#, 16#7C01#);
      E     : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#7E00#, 16#FC01#, 16#7E55#);
      Zero  : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#0000#, 16#0000#, 16#0000#);
   begin
      for Row in 0 .. 2 loop
         for Column in 0 .. 2 loop
            OpenCV.Core.Float16_Vec3_Access.Set (Image, Row, Column, Zero);
         end loop;
      end loop;

      OpenCV.Core.Float16_Vec3_Access.Set (Image, 0, 0, A);
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 0, 2, B);
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 1, 1, C);
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 2, 0, D);
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 2, 2, E);

      Assert_Stored_Pixel
        (Image, 0, 0, A, "+0, -0, and smallest subnormal must preserve bits");
      Assert_Stored_Pixel
        (Image,
         0,
         2,
         B,
         "largest subnormal, smallest normal, and +1 must preserve bits");
      Assert_Stored_Pixel
        (Image,
         1,
         1,
         C,
         "-1, max finite, and negative max finite must preserve bits");
      Assert_Stored_Pixel
        (Image, 2, 0, D, "+Inf, -Inf, and a NaN payload must preserve bits");
      Assert_Stored_Pixel
        (Image,
         2,
         2,
         E,
         "quiet NaN, negative NaN, and another payload must preserve bits");
      Assert_Stored_Pixel
        (Image, 0, 1, Zero, "an unwritten neighbor must remain +0");
      Assert_Stored_Pixel
        (Image, 1, 0, Zero, "an unwritten left pixel must remain +0");
      Assert_Stored_Pixel
        (Image, 2, 1, Zero, "an unwritten last-row neighbor must remain +0");
   end Typed_C3_Pixel_Access_Preserves_Special_Encodings;

   procedure Component_Order_Is_Channel_Order (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.Float16, Channels => 3));
      Written  : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#1234#, 16#55AA#, 16#ABCD#);
      Readback : OpenCV.Core.Float16_Vec3.Vector;
   begin
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 0, 0, Written);
      Readback := OpenCV.Core.Float16_Vec3_Access.Get (Image, 0, 0);

      AUnit.Assertions.Assert
        (Bits_Of (Readback (0)) = 16#1234#
         and then Bits_Of (Readback (1)) = 16#55AA#
         and then Bits_Of (Readback (2)) = 16#ABCD#,
         "Float16 Vec3 components must keep OpenCV channel 0/1/2 order");
   end Component_Order_Is_Channel_Order;

   procedure Neighboring_Pixels_Are_Isolated (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image     : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float16, Channels => 3));
      Previous  : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#1111#, 16#2222#, 16#3333#);
      Middle    : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#4444#, 16#5555#, 16#6666#);
      Following : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#7777#, 16#8888#, 16#9999#);
      Other_Row : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#AAAA#, 16#BBBB#, 16#CCCC#);
      Updated   : OpenCV.Core.Float16_Vec3.Vector;
   begin
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 0, 0, Previous);
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 0, 1, Middle);
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 0, 2, Following);
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 1, 1, Other_Row);

      Updated := OpenCV.Core.Float16_Vec3_Access.Get (Image, 0, 1);
      Updated (1) := Value_Of (16#DEAD#);
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 0, 1, Updated);

      Assert_Stored_Pixel
        (Image, 0, 0, Previous, "the previous pixel must remain unchanged");
      Assert_Stored_Pixel
        (Image, 0, 2, Following, "the following pixel must remain unchanged");
      Assert_Stored_Pixel
        (Image, 1, 1, Other_Row, "the other row must remain unchanged");
      Assert_Stored_Pixel
        (Image,
         0,
         1,
         Pixel (16#4444#, 16#DEAD#, 16#6666#),
         "only the selected pixel's rewritten component may change");
   end Neighboring_Pixels_Are_Isolated;

   procedure Region_And_Assignment_Share_C3_Writes (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Parent      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 6,
           Element_Type => (Depth => OpenCV.Core.Float16, Channels => 3));
      View        : OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Shallow     : OpenCV.Core.Mat;
      Written     : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#8000#, 16#7E00#, 16#0001#);
      Replacement : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#3C00#, 16#BC00#, 16#7C00#);
   begin
      Shallow := Parent;
      OpenCV.Core.Float16_Vec3_Access.Set (View, 0, 1, Written);

      Assert_Stored_Pixel
        (Parent,
         1,
         2,
         Written,
         "a Region write must modify the corresponding parent pixel");
      Assert_Stored_Pixel
        (Shallow,
         1,
         2,
         Written,
         "a shallow assignment must observe the same C3 pixel write");

      OpenCV.Core.Float16_Vec3_Access.Set (Shallow, 1, 2, Replacement);
      Assert_Stored_Pixel
        (View,
         0,
         1,
         Replacement,
         "a shallow write must be visible through the Region");
   end Region_And_Assignment_Share_C3_Writes;

   procedure Clone_Isolates_C3_Pixel_Writes (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image       : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float16, Channels => 3));
      Original    : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#8000#, 16#7E00#, 16#FC01#);
      Neighbor    : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#0001#, 16#3C00#, 16#7C00#);
      Replacement : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#3C00#, 16#BC00#, 16#7C01#);
      Clone_Write : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#0400#, 16#FBFF#, 16#7E55#);
      Copy        : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 0, 0, Original);
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 0, 1, Neighbor);
      Copy := Image.Clone;

      Assert_Stored_Pixel
        (Copy, 0, 0, Original, "Clone must copy signed zero and NaN payload");
      Assert_Stored_Pixel
        (Copy, 0, 1, Neighbor, "Clone must copy every C3 pixel");

      OpenCV.Core.Float16_Vec3_Access.Set (Image, 0, 0, Replacement);
      Assert_Stored_Pixel
        (Copy, 0, 0, Original, "mutating the original must not change Clone");

      OpenCV.Core.Float16_Vec3_Access.Set (Copy, 0, 1, Clone_Write);
      Assert_Stored_Pixel
        (Image, 0, 1, Neighbor, "mutating Clone must not change the original");
   end Clone_Isolates_C3_Pixel_Writes;

   procedure Typed_Access_Rejects_Invalid_Mats_And_Indices
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float16, Channels => 3));
      UInt16_C3     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.UInt16, Channels => 3));
      Int16_C3      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.Int16, Channels => 3));
      Float32_C3    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      Float16_C1    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.Float16, Channels => 1));
      Float16_C2    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.Float16, Channels => 2));
      Float16_C4    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 1,
           Element_Type => (Depth => OpenCV.Core.Float16, Channels => 4));
      Default_Empty : OpenCV.Core.Mat;

      procedure Read_UInt16_C3 is
      begin
         AUnit.Assertions.Assert
           (Bits_Of (OpenCV.Core.Float16_Vec3_Access.Get (UInt16_C3, 0, 0) (0))
            = 0,
            "A UInt16 C3 Float16 Vec3 read unexpectedly succeeded");
      end Read_UInt16_C3;

      procedure Read_Int16_C3 is
      begin
         AUnit.Assertions.Assert
           (Bits_Of (OpenCV.Core.Float16_Vec3_Access.Get (Int16_C3, 0, 0) (0))
            = 0,
            "An Int16 C3 Float16 Vec3 read unexpectedly succeeded");
      end Read_Int16_C3;

      procedure Read_Float32_C3 is
      begin
         AUnit.Assertions.Assert
           (Bits_Of
              (OpenCV.Core.Float16_Vec3_Access.Get (Float32_C3, 0, 0) (0))
            = 0,
            "A Float32 C3 Float16 Vec3 read unexpectedly succeeded");
      end Read_Float32_C3;

      procedure Read_Float16_C1 is
      begin
         AUnit.Assertions.Assert
           (Bits_Of
              (OpenCV.Core.Float16_Vec3_Access.Get (Float16_C1, 0, 0) (0))
            = 0,
            "A Float16 C1 Vec3 read unexpectedly succeeded");
      end Read_Float16_C1;

      procedure Read_Float16_C2 is
      begin
         AUnit.Assertions.Assert
           (Bits_Of
              (OpenCV.Core.Float16_Vec3_Access.Get (Float16_C2, 0, 0) (0))
            = 0,
            "A Float16 C2 Vec3 read unexpectedly succeeded");
      end Read_Float16_C2;

      procedure Read_Float16_C4 is
      begin
         AUnit.Assertions.Assert
           (Bits_Of
              (OpenCV.Core.Float16_Vec3_Access.Get (Float16_C4, 0, 0) (0))
            = 0,
            "A Float16 C4 Vec3 read unexpectedly succeeded");
      end Read_Float16_C4;

      procedure Read_Negative_Row is
      begin
         AUnit.Assertions.Assert
           (Bits_Of (OpenCV.Core.Float16_Vec3_Access.Get (Image, -1, 0) (0))
            = 0,
            "A negative row Float16 Vec3 read unexpectedly succeeded");
      end Read_Negative_Row;

      procedure Read_Negative_Column is
      begin
         AUnit.Assertions.Assert
           (Bits_Of (OpenCV.Core.Float16_Vec3_Access.Get (Image, 0, -1) (0))
            = 0,
            "A negative column Float16 Vec3 read unexpectedly succeeded");
      end Read_Negative_Column;

      procedure Read_Row_After_Last is
      begin
         AUnit.Assertions.Assert
           (Bits_Of (OpenCV.Core.Float16_Vec3_Access.Get (Image, 2, 0) (0))
            = 0,
            "A past-the-end row Float16 Vec3 read unexpectedly succeeded");
      end Read_Row_After_Last;

      procedure Read_Column_After_Last is
      begin
         AUnit.Assertions.Assert
           (Bits_Of (OpenCV.Core.Float16_Vec3_Access.Get (Image, 0, 2) (0))
            = 0,
            "A past-the-end column Float16 Vec3 read unexpectedly succeeded");
      end Read_Column_After_Last;

      procedure Read_Default is
      begin
         AUnit.Assertions.Assert
           (Bits_Of
              (OpenCV.Core.Float16_Vec3_Access.Get (Default_Empty, 0, 0) (0))
            = 0,
            "A default Mat Float16 Vec3 read unexpectedly succeeded");
      end Read_Default;
   begin
      Assert_Raises_OpenCV_Error
        (Read_UInt16_C3'Access,
         "Float16 Vec3 access must reject a UInt16 C3 Mat");
      Assert_Raises_OpenCV_Error
        (Read_Int16_C3'Access,
         "Float16 Vec3 access must reject an Int16 C3 Mat");
      Assert_Raises_OpenCV_Error
        (Read_Float32_C3'Access,
         "Float16 Vec3 access must reject a Float32 C3 Mat");
      Assert_Raises_OpenCV_Error
        (Read_Float16_C1'Access,
         "Float16 Vec3 access must reject a Float16 C1 Mat");
      Assert_Raises_OpenCV_Error
        (Read_Float16_C2'Access,
         "Float16 Vec3 access must reject a Float16 C2 Mat");
      Assert_Raises_OpenCV_Error
        (Read_Float16_C4'Access,
         "Float16 Vec3 access must reject a Float16 C4 Mat");
      Assert_Raises_OpenCV_Error
        (Read_Negative_Row'Access,
         "Float16 Vec3 access must reject a negative row");
      Assert_Raises_OpenCV_Error
        (Read_Negative_Column'Access,
         "Float16 Vec3 access must reject a negative column");
      Assert_Raises_OpenCV_Error
        (Read_Row_After_Last'Access,
         "Float16 Vec3 access must reject a row after the last row");
      Assert_Raises_OpenCV_Error
        (Read_Column_After_Last'Access,
         "Float16 Vec3 access must reject a column after the last column");
      Assert_Raises_OpenCV_Error
        (Read_Default'Access,
         "Float16 Vec3 Get on a default Mat must raise OpenCV_Error");
   end Typed_Access_Rejects_Invalid_Mats_And_Indices;

   procedure Convert_To_Round_Trips_Exactly_Representable_Float32
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Source     : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      First      : constant OpenCV.Core.Float32_Vec3.Vector :=
        (0.5, 1.0, -2.0);
      Second     : constant OpenCV.Core.Float32_Vec3.Vector :=
        (65_504.0, 5.960_464_48E-08, -0.0);
      As_Float16 : OpenCV.Core.Mat;
      Back       : OpenCV.Core.Mat;
      Pixel_0    : OpenCV.Core.Float16_Vec3.Vector;
      Pixel_1    : OpenCV.Core.Float16_Vec3.Vector;
      Back_0     : OpenCV.Core.Float32_Vec3.Vector;
      Back_1     : OpenCV.Core.Float32_Vec3.Vector;
   begin
      OpenCV.Core.Float32_Vec3_Access.Set (Source, 0, 0, First);
      OpenCV.Core.Float32_Vec3_Access.Set (Source, 0, 1, Second);

      As_Float16 := Source.Convert_To (Depth => OpenCV.Core.Float16);
      AUnit.Assertions.Assert
        (As_Float16.Depth = OpenCV.Core.Float16
         and then As_Float16.Channels = 3
         and then As_Float16.Rows = 1
         and then As_Float16.Columns = 2,
         "Convert_To Float16 must preserve C3 shape");

      Pixel_0 := OpenCV.Core.Float16_Vec3_Access.Get (As_Float16, 0, 0);
      Pixel_1 := OpenCV.Core.Float16_Vec3_Access.Get (As_Float16, 0, 1);
      AUnit.Assertions.Assert
        (Bits_Of (Pixel_0 (0)) = 16#3800#
         and then Bits_Of (Pixel_0 (1)) = 16#3C00#
         and then Bits_Of (Pixel_0 (2)) = 16#C000#,
         "0.5, 1.0, and -2.0 must convert to exact binary16 encodings");
      AUnit.Assertions.Assert
        (Bits_Of (Pixel_1 (0)) = 16#7BFF#
         and then Bits_Of (Pixel_1 (1)) = 16#0001#
         and then Bits_Of (Pixel_1 (2)) = 16#8000#,
         "65504, 2^-24, and -0.0 must convert to exact binary16 encodings");

      Back := As_Float16.Convert_To (Depth => OpenCV.Core.Float32);
      Back_0 := OpenCV.Core.Float32_Vec3_Access.Get (Back, 0, 0);
      Back_1 := OpenCV.Core.Float32_Vec3_Access.Get (Back, 0, 1);
      AUnit.Assertions.Assert
        (Back_0 (0) = 0.5
         and then Back_0 (1) = 1.0
         and then Back_0 (2) = -2.0
         and then Back_1 (0) = 65_504.0
         and then Back_1 (1) = 5.960_464_48E-08
         and then Back_1 (2) = -0.0,
         "converting back to Float32 must restore the original values");
   end Convert_To_Round_Trips_Exactly_Representable_Float32;

   procedure Split_And_Merge_Preserve_Exact_Component_Bits
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.Float16, Channels => 3));
      First  : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#8000#, 16#7E00#, 16#0001#);
      Second : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#3C00#, 16#BC00#, 16#7C01#);
   begin
      OpenCV.Core.Float16_Vec3_Access.Set (Source, 0, 0, First);
      OpenCV.Core.Float16_Vec3_Access.Set (Source, 1, 1, Second);

      declare
         Channels : constant OpenCV.Core.Mat_Array := Source.Split;
         Merged   : constant OpenCV.Core.Mat := OpenCV.Core.Merge (Channels);
      begin
         AUnit.Assertions.Assert
           (Channels'Length = 3
            and then Channels (Channels'First).Depth = OpenCV.Core.Float16
            and then Channels (Channels'First).Channels = 1,
            "Split must return three Float16 C1 Mats");
         AUnit.Assertions.Assert
           (Bits_Of
              (OpenCV.Core.Float16_Access.Get
                 (Channels (Channels'First), 0, 0))
            = 16#8000#
            and then Bits_Of
                       (OpenCV.Core.Float16_Access.Get
                          (Channels (Channels'First + 1), 0, 0))
                     = 16#7E00#
            and then Bits_Of
                       (OpenCV.Core.Float16_Access.Get
                          (Channels (Channels'First + 2), 0, 0))
                     = 16#0001#
            and then Bits_Of
                       (OpenCV.Core.Float16_Access.Get
                          (Channels (Channels'First), 1, 1))
                     = 16#3C00#
            and then Bits_Of
                       (OpenCV.Core.Float16_Access.Get
                          (Channels (Channels'First + 1), 1, 1))
                     = 16#BC00#
            and then Bits_Of
                       (OpenCV.Core.Float16_Access.Get
                          (Channels (Channels'First + 2), 1, 1))
                     = 16#7C01#,
            "Split C1 channels must preserve exact Float16 Vec3 bits");

         Assert_Stored_Pixel
           (Merged, 0, 0, First, "Merge must restore the first C3 pixel bits");
         Assert_Stored_Pixel
           (Merged,
            1,
            1,
            Second,
            "Merge must restore the second C3 pixel bits");
      end;
   end Split_And_Merge_Preserve_Exact_Component_Bits;

   procedure Reports_Ada_Vec3_Representation (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Size           : constant Natural :=
        OpenCV.Core.Float16_Vec3.Vector'Size;
      Object_Size    : constant Natural :=
        OpenCV.Core.Float16_Vec3.Vector'Object_Size;
      Component_Size : constant Natural :=
        OpenCV.Core.Float16_Vec3.Vector'Component_Size;
      Alignment      : constant Natural :=
        OpenCV.Core.Float16_Vec3.Vector'Alignment;
      Description    : constant String :=
        "Float16_Vec3'Size="
        & Natural'Image (Size)
        & " Object_Size="
        & Natural'Image (Object_Size)
        & " Component_Size="
        & Natural'Image (Component_Size)
        & " Alignment="
        & Natural'Image (Alignment);
   begin
      AUnit.Assertions.Assert (Description'Length > 0, Description);
   end Reports_Ada_Vec3_Representation;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 typed C3 pixel access preserves special encodings",
            Typed_C3_Pixel_Access_Preserves_Special_Encodings'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 component order is channel order",
            Component_Order_Is_Channel_Order'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 neighboring pixels are isolated",
            Neighboring_Pixels_Are_Isolated'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 Region and assignment share C3 writes",
            Region_And_Assignment_Share_C3_Writes'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 Clone isolates C3 pixel writes",
            Clone_Isolates_C3_Pixel_Writes'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 typed access rejects invalid Mats and indices",
            Typed_Access_Rejects_Invalid_Mats_And_Indices'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 Convert_To round-trips exact Float32 C3 values",
            Convert_To_Round_Trips_Exactly_Representable_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 Split and Merge preserve exact component bits",
            Split_And_Merge_Preserve_Exact_Component_Bits'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 reports Ada representation attributes",
            Reports_Ada_Vec3_Representation'Access));
      return Result'Access;
   end Suite;

end Float16_Vec3_Access_Tests;
