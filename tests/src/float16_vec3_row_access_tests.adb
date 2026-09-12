with AUnit.Assertions;
with AUnit.Test_Caller;
with Ada.Exceptions;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Float16_Vec3;
with OpenCV.Core.Float16_Vec3_Access;
with OpenCV.Core.Float16_Vec3_Row_Access;
with Mat_Test_Support;

package body Float16_Vec3_Row_Access_Tests is

   use type Ada.Exceptions.Exception_Id;
   use type Interfaces.Unsigned_16;
   use type OpenCV.Core.Depth_Type;
   use Mat_Test_Support;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   Borrowed_Row_Callback_Error : exception;

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

   function Float16_C3_Image (Rows, Columns : Natural) return OpenCV.Core.Mat
   is (OpenCV.Core.Create
         (Rows, Columns, (Depth => OpenCV.Core.Float16, Channels => 3)));

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

   procedure Fill_Zero (Image : in out OpenCV.Core.Mat) is
      Zero : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#0000#, 16#0000#, 16#0000#);
   begin
      for Row in 0 .. Image.Rows - 1 loop
         for Column in 0 .. Image.Columns - 1 loop
            OpenCV.Core.Float16_Vec3_Access.Set (Image, Row, Column, Zero);
         end loop;
      end loop;
   end Fill_Zero;

   procedure Copied_Rows_Preserve_Binary16_Encodings (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat := Float16_C3_Image (3, 5);
      Written  :
        constant OpenCV.Core.Float16_Vec3_Row_Access.Row_Array (5 .. 9) :=
          (Pixel (16#0000#, 16#8000#, 16#0001#),
           Pixel (16#03FF#, 16#0400#, 16#3C00#),
           Pixel (16#BC00#, 16#7BFF#, 16#FBFF#),
           Pixel (16#7C00#, 16#FC00#, 16#7C01#),
           Pixel (16#7E00#, 16#FC01#, 16#7E55#));
      Readback : OpenCV.Core.Float16_Vec3_Row_Access.Row_Array (20 .. 24);
      Extra    :
        constant OpenCV.Core.Float16_Vec3_Row_Access.Row_Array (0 .. 4) :=
          (Pixel (16#3C00#, 16#0000#, 16#8000#),
           Pixel (16#0001#, 16#03FF#, 16#0400#),
           Pixel (16#BC00#, 16#7BFF#, 16#7C00#),
           Pixel (16#FC00#, 16#7C01#, 16#7E00#),
           Pixel (16#FC01#, 16#7E55#, 16#FBFF#));
   begin
      Fill_Zero (Image);
      OpenCV.Core.Float16_Vec3_Row_Access.Write_Row (Image, 1, Written);
      OpenCV.Core.Float16_Vec3_Row_Access.Read_Row (Image, 1, Readback);

      Assert_Component_Bits
        (Readback (20), Written (5), "+0, -0, min subnormal");
      Assert_Component_Bits
        (Readback (21), Written (6), "max subnormal, min normal, +1");
      Assert_Component_Bits
        (Readback (22), Written (7), "-1, max finite, negative max finite");
      Assert_Component_Bits
        (Readback (23), Written (8), "+Inf, -Inf, NaN 7C01");
      Assert_Component_Bits
        (Readback (24), Written (9), "quiet NaN, negative NaN, payload");
      Assert_Stored_Pixel
        (Image, 1, 0, Written (5), "element access must observe row write");
      Assert_Stored_Pixel
        (Image, 1, 4, Written (9), "last column must observe row write");

      OpenCV.Core.Float16_Vec3_Row_Access.Write_Row (Image, 0, Extra);
      Assert_Stored_Pixel
        (Image, 0, 0, Extra (0), "writing row 0 must preserve +1 bits");
      Assert_Stored_Pixel
        (Image,
         2,
         0,
         Pixel (16#0000#, 16#0000#, 16#0000#),
         "writing one row must not modify adjacent rows");
   end Copied_Rows_Preserve_Binary16_Encodings;

   procedure Copied_Row_Component_Order_Is_Channel_Order
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat := Float16_C3_Image (1, 1);
      Written  :
        constant OpenCV.Core.Float16_Vec3_Row_Access.Row_Array (3 .. 3) :=
          (3 => Pixel (16#1234#, 16#55AA#, 16#ABCD#));
      Readback : OpenCV.Core.Float16_Vec3_Row_Access.Row_Array (8 .. 8);
   begin
      OpenCV.Core.Float16_Vec3_Row_Access.Write_Row (Image, 0, Written);
      OpenCV.Core.Float16_Vec3_Row_Access.Read_Row (Image, 0, Readback);
      AUnit.Assertions.Assert
        (Bits_Of (Readback (8) (0)) = 16#1234#
         and then Bits_Of (Readback (8) (1)) = 16#55AA#
         and then Bits_Of (Readback (8) (2)) = 16#ABCD#,
         "Vec3 row components must follow OpenCV channel order 0 .. 2");
   end Copied_Row_Component_Order_Is_Channel_Order;

   procedure Copied_Row_Arbitrary_Bounds_Map_To_Columns (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat := Float16_C3_Image (1, 4);
      Written  :
        constant OpenCV.Core.Float16_Vec3_Row_Access.Row_Array (41 .. 44) :=
          (Pixel (16#3C00#, 16#0000#, 16#8000#),
           Pixel (16#4000#, 16#0001#, 16#03FF#),
           Pixel (16#4200#, 16#0400#, 16#BC00#),
           Pixel (16#4400#, 16#7C00#, 16#FC00#));
      Readback : OpenCV.Core.Float16_Vec3_Row_Access.Row_Array (7 .. 10);
   begin
      OpenCV.Core.Float16_Vec3_Row_Access.Write_Row (Image, 0, Written);
      OpenCV.Core.Float16_Vec3_Row_Access.Read_Row (Image, 0, Readback);
      Assert_Component_Bits
        (Readback (7), Written (41), "iteration order maps to column 0");
      Assert_Component_Bits
        (Readback (8), Written (42), "iteration order maps to column 1");
      Assert_Component_Bits
        (Readback (9), Written (43), "iteration order maps to column 2");
      Assert_Component_Bits
        (Readback (10), Written (44), "iteration order maps to column 3");
   end Copied_Row_Arbitrary_Bounds_Map_To_Columns;

   procedure Copied_Region_Writes_Respect_Stride_Aliases_And_Clone
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Parent   : OpenCV.Core.Mat := Float16_C3_Image (4, 6);
      Region   : OpenCV.Core.Mat :=
        Parent.Region ((X => 2, Y => 1, Width => 3, Height => 2));
      Alias    : OpenCV.Core.Mat;
      Copy     : OpenCV.Core.Mat;
      Values   :
        constant OpenCV.Core.Float16_Vec3_Row_Access.Row_Array (8 .. 10) :=
          (Pixel (16#3C00#, 16#8000#, 16#0001#),
           Pixel (16#BC00#, 16#7C00#, 16#FC00#),
           Pixel (16#7C01#, 16#7E00#, 16#FC01#));
      Readback : OpenCV.Core.Float16_Vec3_Row_Access.Row_Array (0 .. 2);
      Fill     : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#0400#, 16#0400#, 16#0400#);
   begin
      for Row in 0 .. 3 loop
         for Column in 0 .. 5 loop
            OpenCV.Core.Float16_Vec3_Access.Set (Parent, Row, Column, Fill);
         end loop;
      end loop;

      Alias := Parent;
      Copy := Parent.Clone;
      AUnit.Assertions.Assert
        (not Region.Is_Continuous,
         "The copied-row Region test must exercise a row-strided Mat");
      OpenCV.Core.Float16_Vec3_Row_Access.Write_Row (Region, 1, Values);
      OpenCV.Core.Float16_Vec3_Row_Access.Read_Row (Region, 1, Readback);
      Assert_Component_Bits
        (Readback (0), Values (8), "Region read must return column 0");
      Assert_Component_Bits
        (Readback (1), Values (9), "Region read must return column 1");
      Assert_Component_Bits
        (Readback (2), Values (10), "Region read must return column 2");
      Assert_Stored_Pixel
        (Parent, 2, 2, Values (8), "Region writes must mutate parent storage");
      Assert_Stored_Pixel
        (Alias,
         2,
         4,
         Values (10),
         "shallow aliases must observe Region writes");
      Assert_Stored_Pixel
        (Parent, 2, 1, Fill, "bytes left of the Region row must be untouched");
      Assert_Stored_Pixel
        (Parent,
         2,
         5,
         Fill,
         "bytes right of the Region row must be untouched");
      Assert_Stored_Pixel
        (Copy, 2, 2, Fill, "a Clone must remain independent");
   end Copied_Region_Writes_Respect_Stride_Aliases_And_Clone;

   procedure Copied_Row_Validation_Rejects_Invalid_Input
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Valid     : OpenCV.Core.Mat := Float16_C3_Image (1, 2);
      UInt16_M  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt16, 3));
      Float32_M : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 3));
      C1        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float16, 1));
      C2        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float16, 2));
      C4        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float16, 4));
      Empty     : OpenCV.Core.Mat;
      Data      : OpenCV.Core.Float16_Vec3_Row_Access.Row_Array (0 .. 1);
      Short     : OpenCV.Core.Float16_Vec3_Row_Access.Row_Array (0 .. 0) :=
        (0 => Pixel (16#0000#, 16#0000#, 16#0000#));
      Long      :
        constant OpenCV.Core.Float16_Vec3_Row_Access.Row_Array (0 .. 2) :=
          (others => Pixel (16#0000#, 16#0000#, 16#0000#));

      procedure Read_UInt16 is
      begin
         OpenCV.Core.Float16_Vec3_Row_Access.Read_Row (UInt16_M, 0, Data);
      end Read_UInt16;
      procedure Read_Float32 is
      begin
         OpenCV.Core.Float16_Vec3_Row_Access.Read_Row (Float32_M, 0, Data);
      end Read_Float32;
      procedure Read_C1 is
      begin
         OpenCV.Core.Float16_Vec3_Row_Access.Read_Row (C1, 0, Data);
      end Read_C1;
      procedure Read_C2 is
      begin
         OpenCV.Core.Float16_Vec3_Row_Access.Read_Row (C2, 0, Data);
      end Read_C2;
      procedure Read_C4 is
      begin
         OpenCV.Core.Float16_Vec3_Row_Access.Read_Row (C4, 0, Data);
      end Read_C4;
      procedure Read_Past is
      begin
         OpenCV.Core.Float16_Vec3_Row_Access.Read_Row (Valid, 1, Data);
      end Read_Past;
      procedure Read_Empty is
      begin
         OpenCV.Core.Float16_Vec3_Row_Access.Read_Row (Empty, 0, Data);
      end Read_Empty;
      procedure Write_Short is
      begin
         OpenCV.Core.Float16_Vec3_Row_Access.Write_Row (Valid, 0, Short);
      end Write_Short;
      procedure Write_Long is
      begin
         OpenCV.Core.Float16_Vec3_Row_Access.Write_Row (Valid, 0, Long);
      end Write_Long;
      procedure Read_Wrong_Length is
      begin
         OpenCV.Core.Float16_Vec3_Row_Access.Read_Row (Valid, 0, Short);
      end Read_Wrong_Length;
   begin
      Assert_Raises_OpenCV_Error
        (Read_UInt16'Access, "Float16 Vec3 row access must reject UInt16 C3");
      Assert_Raises_OpenCV_Error
        (Read_Float32'Access,
         "Float16 Vec3 row access must reject Float32 C3");
      Assert_Raises_OpenCV_Error
        (Read_C1'Access, "Float16 Vec3 row access must reject Float16 C1");
      Assert_Raises_OpenCV_Error
        (Read_C2'Access, "Float16 Vec3 row access must reject Float16 C2");
      Assert_Raises_OpenCV_Error
        (Read_C4'Access, "Float16 Vec3 row access must reject Float16 C4");
      Assert_Raises_OpenCV_Error
        (Read_Past'Access,
         "Float16 Vec3 row access must reject a row equal to Rows");
      Assert_Raises_OpenCV_Error
        (Read_Empty'Access,
         "Float16 Vec3 row access must reject a default Mat");
      Assert_Raises_OpenCV_Error
        (Write_Short'Access,
         "Float16 Vec3 row access must reject a short array");
      Assert_Raises_OpenCV_Error
        (Write_Long'Access,
         "Float16 Vec3 row access must reject a long array");
      Assert_Raises_OpenCV_Error
        (Read_Wrong_Length'Access,
         "Float16 Vec3 row access must reject an output array of the"
         & " wrong length");
   end Copied_Row_Validation_Rejects_Invalid_Input;

   procedure Borrowed_Row_Read_Preserves_Exact_Bits (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat := Float16_C3_Image (2, 4);
      Values :
        constant OpenCV.Core.Float16_Vec3_Row_Access.Row_Array (0 .. 3) :=
          (Pixel (16#0000#, 16#8000#, 16#0001#),
           Pixel (16#7C00#, 16#FC00#, 16#7C01#),
           Pixel (16#7E00#, 16#FC01#, 16#7E55#),
           Pixel (16#3C00#, 16#BC00#, 16#FBFF#));
      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Vec3_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 3 and then Data'Length = 4,
            "A borrowed Float16 Vec3 row must exactly span"
            & " zero-based columns");
         Assert_Component_Bits
           (Data (0), Values (0), "borrowed +0/-0/subnormal");
         Assert_Component_Bits
           (Data (1), Values (1), "borrowed infinities/NaN");
         Assert_Component_Bits (Data (2), Values (2), "borrowed NaN payloads");
         Assert_Component_Bits (Data (3), Values (3), "borrowed +1/-1/max");
      end Inspect;
   begin
      OpenCV.Core.Float16_Vec3_Row_Access.Write_Row (Image, 1, Values);
      OpenCV.Core.Float16_Vec3_Row_Access.With_Read_Only_Row
        (Image, 1, Inspect'Access);
   end Borrowed_Row_Read_Preserves_Exact_Bits;

   procedure Borrowed_Writable_Row_Is_Zero_Copy (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat := Float16_C3_Image (2, 3);
      Alias : OpenCV.Core.Mat;
      First : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#0001#, 16#7E00#, 16#FC00#);
      Mid   : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#7C01#, 16#FC01#, 16#7E55#);
      Last  : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#3C00#, 16#BC00#, 16#0400#);

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float16_Vec3_Row_Access.Row_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data'Length = 3,
            "A writable borrowed Float16 Vec3 row must use"
            & " zero-based columns");
         Data (0) := First;
         Data (1) := Mid;
         Assert_Stored_Pixel
           (Image, 1, 0, First, "borrowed write must be immediately visible");
         Assert_Stored_Pixel
           (Image,
            1,
            1,
            Mid,
            "borrowed NaN write must be immediately visible");
         OpenCV.Core.Float16_Vec3_Access.Set (Alias, 1, 2, Last);
         Assert_Component_Bits
           (Data (2),
            Last,
            "alias write must be visible through the borrowed row");
      end Mutate;
   begin
      OpenCV.Core.Float16_Vec3_Access.Set
        (Image, 1, 0, Pixel (16#0400#, 16#3C00#, 16#BC00#));
      OpenCV.Core.Float16_Vec3_Access.Set
        (Image, 1, 1, Pixel (16#0000#, 16#8000#, 16#7C00#));
      OpenCV.Core.Float16_Vec3_Access.Set
        (Image, 1, 2, Pixel (16#7BFF#, 16#FBFF#, 16#0001#));
      Alias := Image;
      OpenCV.Core.Float16_Vec3_Row_Access.With_Writable_Row
        (Image, 1, Mutate'Access);
      Assert_Stored_Pixel
        (Image, 1, 0, First, "writable borrowed mutations must remain");
      Assert_Stored_Pixel
        (Image, 1, 1, Mid, "writable borrowed NaN must remain");
      Assert_Stored_Pixel
        (Image, 1, 2, Last, "alias write during callback must remain");
   end Borrowed_Writable_Row_Is_Zero_Copy;

   procedure Borrowed_Region_Is_Zero_Copy_Without_Padding
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat := Float16_C3_Image (4, 6);
      View   : OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Alias  : OpenCV.Core.Mat;
      Fill   : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#0400#, 16#0400#, 16#0400#);
      Left   : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#0001#, 16#7C01#, 16#FC00#);
      Mid    : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#7E00#, 16#FC01#, 16#7E55#);
      Right  : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#3C00#, 16#BC00#, 16#FBFF#);

      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Vec3_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data'Length = 3,
            "A borrowed Float16 Vec3 Region row must expose only Region"
            & " columns");
         Assert_Component_Bits
           (Data (0),
            Pixel (16#3C00#, 16#0000#, 16#8000#),
            "read-only Region column 0");
         Assert_Component_Bits
           (Data (2),
            Pixel (16#BC00#, 16#7C00#, 16#FC00#),
            "read-only Region column 2");
      end Inspect;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float16_Vec3_Row_Access.Row_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data'Length = 3,
            "A writable borrowed Float16 Vec3 Region row must use Region"
            & " columns");
         Data (0) := Left;
         Data (1) := Mid;
         Data (2) := Right;
         Assert_Stored_Pixel
           (Alias,
            2,
            1,
            Left,
            "Region writes must be visible through aliases");
         Assert_Stored_Pixel
           (Alias,
            2,
            3,
            Right,
            "Region last column must be visible through aliases");
      end Mutate;
   begin
      for Row in 0 .. 3 loop
         for Column in 0 .. 5 loop
            OpenCV.Core.Float16_Vec3_Access.Set (Parent, Row, Column, Fill);
         end loop;
      end loop;
      OpenCV.Core.Float16_Vec3_Access.Set
        (Parent, 1, 1, Pixel (16#3C00#, 16#0000#, 16#8000#));
      OpenCV.Core.Float16_Vec3_Access.Set
        (Parent, 1, 3, Pixel (16#BC00#, 16#7C00#, 16#FC00#));
      AUnit.Assertions.Assert
        (not View.Is_Continuous,
         "A partial-width multi-row Float16 Vec3 Region must be"
         & " non-continuous");
      OpenCV.Core.Float16_Vec3_Row_Access.With_Read_Only_Row
        (View, 0, Inspect'Access);
      Alias := Parent;
      OpenCV.Core.Float16_Vec3_Row_Access.With_Writable_Row
        (View, 1, Mutate'Access);
      Assert_Stored_Pixel
        (Parent, 2, 1, Left, "borrowed Region writes must mutate parent");
      Assert_Stored_Pixel
        (Parent,
         2,
         2,
         Mid,
         "borrowed Region middle column must mutate parent");
      Assert_Stored_Pixel
        (Parent,
         2,
         3,
         Right,
         "borrowed Region last column must mutate parent");
      Assert_Stored_Pixel
        (Parent,
         2,
         0,
         Fill,
         "borrowed Region writes must not mutate left padding");
      Assert_Stored_Pixel
        (Parent,
         2,
         4,
         Fill,
         "borrowed Region writes must not mutate right padding");
      Assert_Stored_Pixel
        (Parent,
         1,
         1,
         Pixel (16#3C00#, 16#0000#, 16#8000#),
         "borrowed Region writes must not mutate previous row");
   end Borrowed_Region_Is_Zero_Copy_Without_Padding;

   procedure Borrowed_Row_Validation_Does_Not_Invoke_Callback
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      UInt16_M  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt16, 3));
      Float32_M : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 3));
      C1        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float16, 1));
      C2        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float16, 2));
      C4        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float16, 4));
      Valid     : OpenCV.Core.Mat := Float16_C3_Image (1, 2);
      Empty     : OpenCV.Core.Mat;
      Invoked   : Boolean := False;

      procedure Mark_Read
        (Data : aliased OpenCV.Core.Float16_Vec3_Row_Access.Row_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_Read;

      procedure Mark_Write
        (Data : aliased in out OpenCV.Core.Float16_Vec3_Row_Access.Row_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_Write;

      procedure Read_UInt16 is
      begin
         OpenCV.Core.Float16_Vec3_Row_Access.With_Read_Only_Row
           (UInt16_M, 0, Mark_Read'Access);
      end Read_UInt16;
      procedure Read_Float32 is
      begin
         OpenCV.Core.Float16_Vec3_Row_Access.With_Read_Only_Row
           (Float32_M, 0, Mark_Read'Access);
      end Read_Float32;
      procedure Read_C1 is
      begin
         OpenCV.Core.Float16_Vec3_Row_Access.With_Read_Only_Row
           (C1, 0, Mark_Read'Access);
      end Read_C1;
      procedure Read_C2 is
      begin
         OpenCV.Core.Float16_Vec3_Row_Access.With_Read_Only_Row
           (C2, 0, Mark_Read'Access);
      end Read_C2;
      procedure Read_C4 is
      begin
         OpenCV.Core.Float16_Vec3_Row_Access.With_Read_Only_Row
           (C4, 0, Mark_Read'Access);
      end Read_C4;
      procedure Write_Past is
      begin
         OpenCV.Core.Float16_Vec3_Row_Access.With_Writable_Row
           (Valid, 1, Mark_Write'Access);
      end Write_Past;
      procedure Read_Empty is
      begin
         OpenCV.Core.Float16_Vec3_Row_Access.With_Read_Only_Row
           (Empty, 0, Mark_Read'Access);
      end Read_Empty;
   begin
      Assert_Raises_OpenCV_Error
        (Read_UInt16'Access,
         "borrowed Float16 Vec3 row must reject UInt16 C3");
      Assert_Raises_OpenCV_Error
        (Read_Float32'Access,
         "borrowed Float16 Vec3 row must reject Float32 C3");
      Assert_Raises_OpenCV_Error
        (Read_C1'Access, "borrowed Float16 Vec3 row must reject Float16 C1");
      Assert_Raises_OpenCV_Error
        (Read_C2'Access, "borrowed Float16 Vec3 row must reject Float16 C2");
      Assert_Raises_OpenCV_Error
        (Read_C4'Access, "borrowed Float16 Vec3 row must reject Float16 C4");
      Assert_Raises_OpenCV_Error
        (Write_Past'Access,
         "borrowed Float16 Vec3 row must reject a row equal to Rows");
      Assert_Raises_OpenCV_Error
        (Read_Empty'Access,
         "borrowed Float16 Vec3 row must reject a default Mat");
      AUnit.Assertions.Assert
        (not Invoked, "Borrowed-row validation must not invoke the callback");
   end Borrowed_Row_Validation_Does_Not_Invoke_Callback;

   procedure Borrowed_Row_Propagates_Callback_Exception (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat := Float16_C3_Image (1, 2);
      Raised  : Boolean := False;
      Message : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;
      Written : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#7C01#, 16#7E00#, 16#FC01#);
      Kept    : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#BC00#, 16#0400#, 16#3C00#);

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float16_Vec3_Row_Access.Row_Array)
      is
      begin
         Data (0) := Written;
         raise Borrowed_Row_Callback_Error;
      end Mutate;
   begin
      OpenCV.Core.Float16_Vec3_Access.Set
        (Image, 0, 0, Pixel (16#3C00#, 16#0000#, 16#8000#));
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 0, 1, Kept);
      begin
         OpenCV.Core.Float16_Vec3_Row_Access.With_Writable_Row
           (Image, 0, Mutate'Access);
      exception
         when Error : Borrowed_Row_Callback_Error =>
            Raised := True;
            Message := Ada.Exceptions.Exception_Identity (Error);
      end;
      AUnit.Assertions.Assert
        (Raised and then Message = Borrowed_Row_Callback_Error'Identity,
         "A callback exception must propagate unchanged");
      Assert_Stored_Pixel
        (Image, 0, 0, Written, "completed writes before the exception remain");
      Assert_Stored_Pixel
        (Image, 0, 1, Kept, "unwritten column must remain unchanged");
      OpenCV.Core.Float16_Vec3_Access.Set
        (Image, 0, 1, Pixel (16#0400#, 16#0001#, 16#03FF#));
      Assert_Stored_Pixel
        (Image,
         0,
         1,
         Pixel (16#0400#, 16#0001#, 16#03FF#),
         "the Mat must remain usable after a callback exception");
   end Borrowed_Row_Propagates_Callback_Exception;

   procedure Borrowed_Row_Lease_Survives_Header_Rebind (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat := Float16_C3_Image (1, 2);
      Alias  : OpenCV.Core.Mat;
      First  : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#7C00#, 16#0000#, 16#8000#);
      Second : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#FC00#, 16#7C01#, 16#7E00#);

      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Vec3_Row_Access.Row_Array)
      is
         Replacement : constant OpenCV.Core.Mat := Float16_C3_Image (1, 1);
         Empty       : OpenCV.Core.Mat;
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Length = 2,
            "The borrowed Float16 Vec3 row must remain valid"
            & " at callback entry");
         Assert_Component_Bits (Data (1), Second, "entry encoding");
         Image := Replacement;
         Alias := Empty;
         AUnit.Assertions.Assert
           (Alias.Is_Empty,
            "Rebinding the alias header must leave an empty Mat");
         Assert_Component_Bits
           (Data (0),
            First,
            "The Float16 Vec3 row lease must survive rebinding other headers");
         Assert_Component_Bits
           (Data (1),
            Second,
            "The Float16 Vec3 row lease must preserve the second encoding"
            & " after rebind");
      end Inspect;
   begin
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 0, 0, First);
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 0, 1, Second);
      Alias := Image;
      OpenCV.Core.Float16_Vec3_Row_Access.With_Read_Only_Row
        (Image, 0, Inspect'Access);
   end Borrowed_Row_Lease_Survives_Header_Rebind;

   function Observed_Size (Value : Natural) return Natural is
   begin
      return Value;
   end Observed_Size;

   procedure Reports_Enforced_Vec3_Representation (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Size           : constant Natural :=
        Observed_Size (OpenCV.Core.Float16_Vec3.Vector'Size);
      Object_Size    : constant Natural :=
        Observed_Size (OpenCV.Core.Float16_Vec3.Vector'Object_Size);
      Component_Size : constant Natural :=
        Observed_Size (OpenCV.Core.Float16_Vec3.Vector'Component_Size);
      Alignment      : constant Natural :=
        Observed_Size (OpenCV.Core.Float16_Vec3.Vector'Alignment);
      Value_Size     : constant Natural :=
        Observed_Size (OpenCV.Core.Float16_Value'Size);
      Value_Object   : constant Natural :=
        Observed_Size (OpenCV.Core.Float16_Value'Object_Size);
      Row_Component  : constant Natural :=
        Observed_Size
          (OpenCV.Core.Float16_Vec3_Row_Access.Row_Array'Component_Size);
      Description    : constant String :=
        "Float16_Vec3'Size="
        & Natural'Image (Size)
        & " Object_Size="
        & Natural'Image (Object_Size)
        & " Component_Size="
        & Natural'Image (Component_Size)
        & " Alignment="
        & Natural'Image (Alignment)
        & " Value_Size="
        & Natural'Image (Value_Size)
        & " Value_Object_Size="
        & Natural'Image (Value_Object)
        & " Row_Component_Size="
        & Natural'Image (Row_Component);
   begin
      AUnit.Assertions.Assert
        (Value_Size = 16, "Float16_Value'Size must be 16: " & Description);
      AUnit.Assertions.Assert
        (Value_Object = 16,
         "Float16_Value'Object_Size must be 16: " & Description);
      AUnit.Assertions.Assert
        (Component_Size = 16,
         "Float16 Vec3 Component_Size must be 16: " & Description);
      AUnit.Assertions.Assert
        (Size = 48, "Float16 Vec3'Size must be 48: " & Description);
      AUnit.Assertions.Assert
        (Object_Size = 48,
         "Float16 Vec3'Object_Size must be 48: " & Description);
      AUnit.Assertions.Assert
        (Row_Component = 48,
         "Float16 Vec3 Row_Array Component_Size must be 48: " & Description);
      AUnit.Assertions.Assert
        (Alignment <= 2,
         "Float16 Vec3 alignment must not exceed 2: " & Description);
   end Reports_Enforced_Vec3_Representation;

   procedure All_Binary16_Encodings_Round_Trip (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat := Float16_C3_Image (1, 21_846);
      Written  : OpenCV.Core.Float16_Vec3_Row_Access.Row_Array (0 .. 21_845);
      Readback : OpenCV.Core.Float16_Vec3_Row_Access.Row_Array (0 .. 21_845);
      Mismatch : Natural := 0;
      Bits     : Interfaces.Unsigned_16 := 0;

      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Vec3_Row_Access.Row_Array)
      is
         Observed : Interfaces.Unsigned_16 := 0;
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Length = 21_846,
            "The borrowed exhaustive row must expose every encoding slot");
         for Index in Data'Range loop
            for Component in OpenCV.Core.Float16_Vec3.Component_Index loop
               if Bits_Of (Data (Index) (Component)) /= Observed then
                  Mismatch := Mismatch + 1;
               end if;
               Observed := Observed + 1;
            end loop;
         end loop;
      end Inspect;
   begin
      for Index in Written'Range loop
         Written (Index) := Pixel (Bits, Bits + 1, Bits + 2);
         Bits := Bits + 3;
      end loop;

      OpenCV.Core.Float16_Vec3_Row_Access.Write_Row (Image, 0, Written);
      OpenCV.Core.Float16_Vec3_Row_Access.Read_Row (Image, 0, Readback);

      Bits := 0;
      for Index in Readback'Range loop
         for Component in OpenCV.Core.Float16_Vec3.Component_Index loop
            if Bits_Of (Readback (Index) (Component)) /= Bits then
               Mismatch := Mismatch + 1;
            end if;
            Bits := Bits + 1;
         end loop;
      end loop;

      AUnit.Assertions.Assert
        (Mismatch = 0,
         "Copied Write_Row then Read_Row must preserve every binary16"
         & " encoding");

      OpenCV.Core.Float16_Vec3_Row_Access.With_Read_Only_Row
        (Image, 0, Inspect'Access);
      AUnit.Assertions.Assert
        (Mismatch = 0,
         "A borrowed Float16 Vec3 row must observe every binary16 encoding");
   end All_Binary16_Encodings_Round_Trip;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 copied rows preserve binary16 encodings",
            Copied_Rows_Preserve_Binary16_Encodings'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 copied row component order is channel order",
            Copied_Row_Component_Order_Is_Channel_Order'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 copied row arbitrary bounds map to columns",
            Copied_Row_Arbitrary_Bounds_Map_To_Columns'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 copied Region rows respect stride aliases and Clone",
            Copied_Region_Writes_Respect_Stride_Aliases_And_Clone'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 copied row validation rejects invalid input",
            Copied_Row_Validation_Rejects_Invalid_Input'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 borrowed row read preserves exact bits",
            Borrowed_Row_Read_Preserves_Exact_Bits'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 borrowed writable row is zero-copy",
            Borrowed_Writable_Row_Is_Zero_Copy'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 borrowed Region is zero-copy without padding",
            Borrowed_Region_Is_Zero_Copy_Without_Padding'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 borrowed row validation does not invoke callback",
            Borrowed_Row_Validation_Does_Not_Invoke_Callback'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 borrowed row propagates callback exceptions",
            Borrowed_Row_Propagates_Callback_Exception'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 borrowed row lease survives header rebind",
            Borrowed_Row_Lease_Survives_Header_Rebind'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 row reports enforced representation",
            Reports_Enforced_Vec3_Representation'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 row transfer preserves all 65536 binary16 encodings",
            All_Binary16_Encodings_Round_Trip'Access));
      return Result'Access;
   end Suite;

end Float16_Vec3_Row_Access_Tests;
