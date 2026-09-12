with AUnit.Assertions;
with AUnit.Test_Caller;
with Ada.Exceptions;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Float16_Access;
with OpenCV.Core.Float16_Row_Access;
with Mat_Test_Support;

package body Float16_Row_Access_Tests is

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

   function Float16_Image
     (Rows, Columns : Natural; Channels : OpenCV.Core.Channel_Count := 1)
      return OpenCV.Core.Mat
   is (OpenCV.Core.Create
         (Rows,
          Columns,
          (Depth => OpenCV.Core.Float16, Channels => Channels)));

   procedure Assert_Bits
     (Value    : OpenCV.Core.Float16_Value;
      Expected : Interfaces.Unsigned_16;
      Message  : String)
   is
      Stored : constant Interfaces.Unsigned_16 := Bits_Of (Value);
   begin
      AUnit.Assertions.Assert
        (Stored = Expected,
         Message
         & " (got"
         & Interfaces.Unsigned_16'Image (Stored)
         & ", expected"
         & Interfaces.Unsigned_16'Image (Expected)
         & ")");
   end Assert_Bits;

   procedure Assert_Stored_Bits
     (Image    : OpenCV.Core.Mat;
      Row      : Integer;
      Column   : Integer;
      Expected : Interfaces.Unsigned_16;
      Message  : String) is
   begin
      Assert_Bits
        (OpenCV.Core.Float16_Access.Get (Image, Row, Column),
         Expected,
         Message);
   end Assert_Stored_Bits;

   procedure Copied_Rows_Preserve_Binary16_Encodings (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat := Float16_Image (3, 11);
      Written  : constant OpenCV.Core.Float16_Row_Access.Row_Array (5 .. 15) :=
        (Value_Of (16#0000#),
         Value_Of (16#8000#),
         Value_Of (16#0001#),
         Value_Of (16#03FF#),
         Value_Of (16#0400#),
         Value_Of (16#3C00#),
         Value_Of (16#BC00#),
         Value_Of (16#7BFF#),
         Value_Of (16#7C00#),
         Value_Of (16#FC00#),
         Value_Of (16#7C01#));
      Readback : OpenCV.Core.Float16_Row_Access.Row_Array (20 .. 30);
      Extra    : constant OpenCV.Core.Float16_Row_Access.Row_Array (0 .. 10) :=
        (Value_Of (16#7E00#),
         Value_Of (16#FC01#),
         Value_Of (16#0000#),
         Value_Of (16#8000#),
         Value_Of (16#0001#),
         Value_Of (16#03FF#),
         Value_Of (16#0400#),
         Value_Of (16#3C00#),
         Value_Of (16#BC00#),
         Value_Of (16#7BFF#),
         Value_Of (16#7C00#));
   begin
      for Row in 0 .. 2 loop
         for Column in 0 .. 10 loop
            OpenCV.Core.Float16_Access.Set
              (Image, Row, Column, Value_Of (16#0000#));
         end loop;
      end loop;

      OpenCV.Core.Float16_Row_Access.Write_Row (Image, 1, Written);
      OpenCV.Core.Float16_Row_Access.Read_Row (Image, 1, Readback);

      Assert_Bits (Readback (20), 16#0000#, "+0 must preserve bits");
      Assert_Bits (Readback (21), 16#8000#, "-0 must remain distinct from +0");
      Assert_Bits
        (Readback (22), 16#0001#, "smallest subnormal must preserve bits");
      Assert_Bits
        (Readback (23), 16#03FF#, "largest subnormal must preserve bits");
      Assert_Bits
        (Readback (24), 16#0400#, "smallest normal must preserve bits");
      Assert_Bits (Readback (25), 16#3C00#, "+1 must preserve bits");
      Assert_Bits (Readback (26), 16#BC00#, "-1 must preserve bits");
      Assert_Bits (Readback (27), 16#7BFF#, "max finite must preserve bits");
      Assert_Bits (Readback (28), 16#7C00#, "+Inf must preserve bits");
      Assert_Bits (Readback (29), 16#FC00#, "-Inf must preserve bits");
      Assert_Bits
        (Readback (30), 16#7C01#, "NaN payload 7C01 must preserve bits");
      Assert_Stored_Bits
        (Image, 1, 0, 16#0000#, "element access must observe +0 row write");
      Assert_Stored_Bits
        (Image, 1, 1, 16#8000#, "element access must observe -0 row write");
      Assert_Stored_Bits
        (Image, 1, 10, 16#7C01#, "element access must observe NaN row write");

      OpenCV.Core.Float16_Row_Access.Write_Row (Image, 0, Extra);
      Assert_Stored_Bits
        (Image, 0, 0, 16#7E00#, "quiet NaN 7E00 must preserve bits");
      Assert_Stored_Bits
        (Image, 0, 1, 16#FC01#, "negative NaN FC01 must preserve bits");
      Assert_Stored_Bits
        (Image,
         2,
         0,
         16#0000#,
         "writing one row must not modify adjacent rows");
   end Copied_Rows_Preserve_Binary16_Encodings;

   procedure Copied_Row_Arbitrary_Bounds_Map_To_Columns (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat := Float16_Image (1, 4);
      Written  :
        constant OpenCV.Core.Float16_Row_Access.Row_Array (41 .. 44) :=
          (Value_Of (16#3C00#),
           Value_Of (16#4000#),
           Value_Of (16#4200#),
           Value_Of (16#4400#));
      Readback : OpenCV.Core.Float16_Row_Access.Row_Array (7 .. 10);
   begin
      OpenCV.Core.Float16_Row_Access.Write_Row (Image, 0, Written);
      OpenCV.Core.Float16_Row_Access.Read_Row (Image, 0, Readback);
      Assert_Bits (Readback (7), 16#3C00#, "iteration order maps to column 0");
      Assert_Bits (Readback (8), 16#4000#, "iteration order maps to column 1");
      Assert_Bits (Readback (9), 16#4200#, "iteration order maps to column 2");
      Assert_Bits
        (Readback (10), 16#4400#, "iteration order maps to column 3");
   end Copied_Row_Arbitrary_Bounds_Map_To_Columns;

   procedure Copied_Region_Writes_Respect_Stride_Aliases_And_Clone
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Parent   : OpenCV.Core.Mat := Float16_Image (4, 6);
      Region   : OpenCV.Core.Mat :=
        Parent.Region ((X => 2, Y => 1, Width => 3, Height => 2));
      Alias    : OpenCV.Core.Mat;
      Copy     : OpenCV.Core.Mat;
      Values   : constant OpenCV.Core.Float16_Row_Access.Row_Array (8 .. 10) :=
        (Value_Of (16#3C00#), Value_Of (16#BC00#), Value_Of (16#7C01#));
      Readback : OpenCV.Core.Float16_Row_Access.Row_Array (0 .. 2);
   begin
      for Row in 0 .. 3 loop
         for Column in 0 .. 5 loop
            OpenCV.Core.Float16_Access.Set
              (Parent, Row, Column, Value_Of (16#0400#));
         end loop;
      end loop;

      Alias := Parent;
      Copy := Parent.Clone;
      AUnit.Assertions.Assert
        (not Region.Is_Continuous,
         "The copied-row Region test must exercise a row-strided Mat");
      OpenCV.Core.Float16_Row_Access.Write_Row (Region, 1, Values);
      OpenCV.Core.Float16_Row_Access.Read_Row (Region, 1, Readback);
      Assert_Bits (Readback (0), 16#3C00#, "Region read must return column 0");
      Assert_Bits (Readback (1), 16#BC00#, "Region read must return column 1");
      Assert_Bits (Readback (2), 16#7C01#, "Region read must return column 2");
      Assert_Stored_Bits
        (Parent, 2, 2, 16#3C00#, "Region writes must mutate parent storage");
      Assert_Stored_Bits
        (Alias, 2, 4, 16#7C01#, "shallow aliases must observe Region writes");
      Assert_Stored_Bits
        (Parent,
         2,
         1,
         16#0400#,
         "bytes left of the Region row must be untouched");
      Assert_Stored_Bits
        (Parent,
         2,
         5,
         16#0400#,
         "bytes right of the Region row must be untouched");
      Assert_Stored_Bits
        (Copy, 2, 2, 16#0400#, "a Clone must remain independent");
   end Copied_Region_Writes_Respect_Stride_Aliases_And_Clone;

   procedure Copied_Row_Validation_Rejects_Invalid_Input
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Valid     : OpenCV.Core.Mat := Float16_Image (1, 2);
      UInt16_M  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt16, 1));
      Int16_M   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Int16, 1));
      Float32_M : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      C2        : constant OpenCV.Core.Mat := Float16_Image (1, 2, 2);
      C3        : constant OpenCV.Core.Mat := Float16_Image (1, 2, 3);
      Empty     : OpenCV.Core.Mat;
      Data      : OpenCV.Core.Float16_Row_Access.Row_Array (0 .. 1);
      Short     : OpenCV.Core.Float16_Row_Access.Row_Array (0 .. 0) :=
        (0 => Value_Of (16#0000#));
      Long      : constant OpenCV.Core.Float16_Row_Access.Row_Array (0 .. 2) :=
        (others => Value_Of (16#0000#));

      procedure Read_UInt16 is
      begin
         OpenCV.Core.Float16_Row_Access.Read_Row (UInt16_M, 0, Data);
      end Read_UInt16;
      procedure Read_Int16 is
      begin
         OpenCV.Core.Float16_Row_Access.Read_Row (Int16_M, 0, Data);
      end Read_Int16;
      procedure Read_Float32 is
      begin
         OpenCV.Core.Float16_Row_Access.Read_Row (Float32_M, 0, Data);
      end Read_Float32;
      procedure Read_C2 is
      begin
         OpenCV.Core.Float16_Row_Access.Read_Row (C2, 0, Data);
      end Read_C2;
      procedure Read_C3 is
      begin
         OpenCV.Core.Float16_Row_Access.Read_Row (C3, 0, Data);
      end Read_C3;
      procedure Read_Past is
      begin
         OpenCV.Core.Float16_Row_Access.Read_Row (Valid, 1, Data);
      end Read_Past;
      procedure Read_Empty is
      begin
         OpenCV.Core.Float16_Row_Access.Read_Row (Empty, 0, Data);
      end Read_Empty;
      procedure Write_Short is
      begin
         OpenCV.Core.Float16_Row_Access.Write_Row (Valid, 0, Short);
      end Write_Short;
      procedure Write_Long is
      begin
         OpenCV.Core.Float16_Row_Access.Write_Row (Valid, 0, Long);
      end Write_Long;
      procedure Read_Wrong_Length is
      begin
         OpenCV.Core.Float16_Row_Access.Read_Row (Valid, 0, Short);
      end Read_Wrong_Length;
   begin
      Assert_Raises_OpenCV_Error
        (Read_UInt16'Access, "Float16 row access must reject UInt16 C1");
      Assert_Raises_OpenCV_Error
        (Read_Int16'Access, "Float16 row access must reject Int16 C1");
      Assert_Raises_OpenCV_Error
        (Read_Float32'Access, "Float16 row access must reject Float32 C1");
      Assert_Raises_OpenCV_Error
        (Read_C2'Access, "Float16 row access must reject Float16 C2");
      Assert_Raises_OpenCV_Error
        (Read_C3'Access, "Float16 row access must reject Float16 C3");
      Assert_Raises_OpenCV_Error
        (Read_Past'Access,
         "Float16 row access must reject a row equal to Rows");
      Assert_Raises_OpenCV_Error
        (Read_Empty'Access, "Float16 row access must reject a default Mat");
      Assert_Raises_OpenCV_Error
        (Write_Short'Access, "Float16 row access must reject a short array");
      Assert_Raises_OpenCV_Error
        (Write_Long'Access, "Float16 row access must reject a long array");
      Assert_Raises_OpenCV_Error
        (Read_Wrong_Length'Access,
         "Float16 row access must reject an output array of the wrong length");
   end Copied_Row_Validation_Rejects_Invalid_Input;

   procedure Borrowed_Row_Read_Preserves_Exact_Bits (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat := Float16_Image (2, 4);
      Values : constant OpenCV.Core.Float16_Row_Access.Row_Array (0 .. 3) :=
        (Value_Of (16#0000#),
         Value_Of (16#8000#),
         Value_Of (16#7C00#),
         Value_Of (16#FC01#));
      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 3 and then Data'Length = 4,
            "A borrowed Float16 row must exactly span zero-based columns");
         Assert_Bits (Data (0), 16#0000#, "borrowed +0");
         Assert_Bits (Data (1), 16#8000#, "borrowed -0");
         Assert_Bits (Data (2), 16#7C00#, "borrowed +Inf");
         Assert_Bits (Data (3), 16#FC01#, "borrowed negative NaN");
      end Inspect;
   begin
      OpenCV.Core.Float16_Row_Access.Write_Row (Image, 1, Values);
      OpenCV.Core.Float16_Row_Access.With_Read_Only_Row
        (Image, 1, Inspect'Access);
   end Borrowed_Row_Read_Preserves_Exact_Bits;

   procedure Borrowed_Writable_Row_Is_Zero_Copy (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat := Float16_Image (2, 3);
      Alias : OpenCV.Core.Mat;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float16_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data'Length = 3,
            "A writable borrowed Float16 row must use zero-based columns");
         Data (0) := Value_Of (16#0001#);
         Data (1) := Value_Of (16#7E00#);
         Data (2) := Value_Of (16#FC00#);
         Assert_Stored_Bits
           (Image,
            1,
            0,
            16#0001#,
            "borrowed write must be immediately visible");
         Assert_Stored_Bits
           (Image,
            1,
            1,
            16#7E00#,
            "quiet NaN write must be immediately visible");
         Assert_Stored_Bits
           (Image, 1, 2, 16#FC00#, "-Inf write must be immediately visible");
         OpenCV.Core.Float16_Access.Set (Alias, 1, 2, Value_Of (16#3C00#));
         Assert_Bits
           (Data (2),
            16#3C00#,
            "alias write must be visible through the borrowed row");
      end Mutate;
   begin
      OpenCV.Core.Float16_Access.Set (Image, 1, 0, Value_Of (16#0400#));
      OpenCV.Core.Float16_Access.Set (Image, 1, 1, Value_Of (16#3C00#));
      OpenCV.Core.Float16_Access.Set (Image, 1, 2, Value_Of (16#BC00#));
      Alias := Image;
      OpenCV.Core.Float16_Row_Access.With_Writable_Row
        (Image, 1, Mutate'Access);
      Assert_Stored_Bits
        (Image, 1, 0, 16#0001#, "writable borrowed mutations must remain");
      Assert_Stored_Bits
        (Image, 1, 1, 16#7E00#, "writable borrowed NaN must remain");
      Assert_Stored_Bits
        (Image, 1, 2, 16#3C00#, "alias write during callback must remain");
   end Borrowed_Writable_Row_Is_Zero_Copy;

   procedure Borrowed_Region_Is_Zero_Copy_Without_Padding
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat := Float16_Image (4, 6);
      View   : OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Alias  : OpenCV.Core.Mat;

      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data'Length = 3,
            "A borrowed Float16 Region row must expose only Region columns");
         Assert_Bits (Data (0), 16#3C00#, "read-only Region column 0");
         Assert_Bits (Data (2), 16#BC00#, "read-only Region column 2");
      end Inspect;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float16_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data'Length = 3,
            "A writable borrowed Float16 Region row must use Region columns");
         Data (0) := Value_Of (16#0001#);
         Data (1) := Value_Of (16#7C01#);
         Data (2) := Value_Of (16#FC00#);
         Assert_Stored_Bits
           (Alias,
            2,
            1,
            16#0001#,
            "Region writes must be visible through aliases");
         Assert_Stored_Bits
           (Alias,
            2,
            3,
            16#FC00#,
            "Region last column must be visible through aliases");
      end Mutate;
   begin
      for Row in 0 .. 3 loop
         for Column in 0 .. 5 loop
            OpenCV.Core.Float16_Access.Set
              (Parent, Row, Column, Value_Of (16#0400#));
         end loop;
      end loop;
      OpenCV.Core.Float16_Access.Set (Parent, 1, 1, Value_Of (16#3C00#));
      OpenCV.Core.Float16_Access.Set (Parent, 1, 3, Value_Of (16#BC00#));
      AUnit.Assertions.Assert
        (not View.Is_Continuous,
         "A partial-width multi-row Float16 Region must be non-continuous");
      OpenCV.Core.Float16_Row_Access.With_Read_Only_Row
        (View, 0, Inspect'Access);
      Alias := Parent;
      OpenCV.Core.Float16_Row_Access.With_Writable_Row
        (View, 1, Mutate'Access);
      Assert_Stored_Bits
        (Parent, 2, 1, 16#0001#, "borrowed Region writes must mutate parent");
      Assert_Stored_Bits
        (Parent,
         2,
         2,
         16#7C01#,
         "borrowed Region middle column must mutate parent");
      Assert_Stored_Bits
        (Parent,
         2,
         3,
         16#FC00#,
         "borrowed Region last column must mutate parent");
      Assert_Stored_Bits
        (Parent,
         2,
         0,
         16#0400#,
         "borrowed Region writes must not mutate left padding");
      Assert_Stored_Bits
        (Parent,
         2,
         4,
         16#0400#,
         "borrowed Region writes must not mutate right padding");
      Assert_Stored_Bits
        (Parent,
         1,
         1,
         16#3C00#,
         "borrowed Region writes must not mutate previous row");
   end Borrowed_Region_Is_Zero_Copy_Without_Padding;

   procedure Borrowed_Row_Validation_Does_Not_Invoke_Callback
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      UInt16_M  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt16, 1));
      Int16_M   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Int16, 1));
      Float32_M : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      C2        : constant OpenCV.Core.Mat := Float16_Image (1, 2, 2);
      C3        : constant OpenCV.Core.Mat := Float16_Image (1, 2, 3);
      Valid     : OpenCV.Core.Mat := Float16_Image (1, 2);
      Empty     : OpenCV.Core.Mat;
      Invoked   : Boolean := False;

      procedure Mark_Read
        (Data : aliased OpenCV.Core.Float16_Row_Access.Row_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_Read;

      procedure Mark_Write
        (Data : aliased in out OpenCV.Core.Float16_Row_Access.Row_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_Write;

      procedure Read_UInt16 is
      begin
         OpenCV.Core.Float16_Row_Access.With_Read_Only_Row
           (UInt16_M, 0, Mark_Read'Access);
      end Read_UInt16;
      procedure Read_Int16 is
      begin
         OpenCV.Core.Float16_Row_Access.With_Read_Only_Row
           (Int16_M, 0, Mark_Read'Access);
      end Read_Int16;
      procedure Read_Float32 is
      begin
         OpenCV.Core.Float16_Row_Access.With_Read_Only_Row
           (Float32_M, 0, Mark_Read'Access);
      end Read_Float32;
      procedure Read_C2 is
      begin
         OpenCV.Core.Float16_Row_Access.With_Read_Only_Row
           (C2, 0, Mark_Read'Access);
      end Read_C2;
      procedure Read_C3 is
      begin
         OpenCV.Core.Float16_Row_Access.With_Read_Only_Row
           (C3, 0, Mark_Read'Access);
      end Read_C3;
      procedure Write_Past is
      begin
         OpenCV.Core.Float16_Row_Access.With_Writable_Row
           (Valid, 1, Mark_Write'Access);
      end Write_Past;
      procedure Read_Empty is
      begin
         OpenCV.Core.Float16_Row_Access.With_Read_Only_Row
           (Empty, 0, Mark_Read'Access);
      end Read_Empty;
   begin
      Assert_Raises_OpenCV_Error
        (Read_UInt16'Access, "borrowed Float16 row must reject UInt16 C1");
      Assert_Raises_OpenCV_Error
        (Read_Int16'Access, "borrowed Float16 row must reject Int16 C1");
      Assert_Raises_OpenCV_Error
        (Read_Float32'Access, "borrowed Float16 row must reject Float32 C1");
      Assert_Raises_OpenCV_Error
        (Read_C2'Access, "borrowed Float16 row must reject Float16 C2");
      Assert_Raises_OpenCV_Error
        (Read_C3'Access, "borrowed Float16 row must reject Float16 C3");
      Assert_Raises_OpenCV_Error
        (Write_Past'Access,
         "borrowed Float16 row must reject a row equal to Rows");
      Assert_Raises_OpenCV_Error
        (Read_Empty'Access, "borrowed Float16 row must reject a default Mat");
      AUnit.Assertions.Assert
        (not Invoked, "Borrowed-row validation must not invoke the callback");
   end Borrowed_Row_Validation_Does_Not_Invoke_Callback;

   procedure Borrowed_Row_Propagates_Callback_Exception (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat := Float16_Image (1, 2);
      Raised  : Boolean := False;
      Message : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float16_Row_Access.Row_Array) is
      begin
         Data (0) := Value_Of (16#7C01#);
         raise Borrowed_Row_Callback_Error;
      end Mutate;
   begin
      OpenCV.Core.Float16_Access.Set (Image, 0, 0, Value_Of (16#3C00#));
      OpenCV.Core.Float16_Access.Set (Image, 0, 1, Value_Of (16#BC00#));
      begin
         OpenCV.Core.Float16_Row_Access.With_Writable_Row
           (Image, 0, Mutate'Access);
      exception
         when Error : Borrowed_Row_Callback_Error =>
            Raised := True;
            Message := Ada.Exceptions.Exception_Identity (Error);
      end;
      AUnit.Assertions.Assert
        (Raised and then Message = Borrowed_Row_Callback_Error'Identity,
         "A callback exception must propagate unchanged");
      Assert_Stored_Bits
        (Image,
         0,
         0,
         16#7C01#,
         "completed writes before the exception remain");
      Assert_Stored_Bits
        (Image, 0, 1, 16#BC00#, "unwritten column must remain unchanged");
      OpenCV.Core.Float16_Access.Set (Image, 0, 1, Value_Of (16#0400#));
      Assert_Stored_Bits
        (Image,
         0,
         1,
         16#0400#,
         "the Mat must remain usable after a callback exception");
   end Borrowed_Row_Propagates_Callback_Exception;

   procedure Borrowed_Row_Lease_Survives_Header_Rebind (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat := Float16_Image (1, 2);
      Alias : OpenCV.Core.Mat;

      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Row_Access.Row_Array)
      is
         Replacement : constant OpenCV.Core.Mat := Float16_Image (1, 1);
         Empty       : OpenCV.Core.Mat;
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Length = 2,
            "The borrowed Float16 row must remain valid at callback entry");
         Assert_Bits (Data (1), 16#FC00#, "entry encoding");
         Image := Replacement;
         Alias := Empty;
         AUnit.Assertions.Assert
           (Alias.Is_Empty,
            "Rebinding the alias header must leave an empty Mat");
         Assert_Bits
           (Data (0),
            16#7C00#,
            "The Float16 row lease must survive rebinding other headers");
         Assert_Bits
           (Data (1),
            16#FC00#,
            "The Float16 row lease must preserve the second encoding"
            & " after rebind");
      end Inspect;
   begin
      OpenCV.Core.Float16_Access.Set (Image, 0, 0, Value_Of (16#7C00#));
      OpenCV.Core.Float16_Access.Set (Image, 0, 1, Value_Of (16#FC00#));
      Alias := Image;
      OpenCV.Core.Float16_Row_Access.With_Read_Only_Row
        (Image, 0, Inspect'Access);
   end Borrowed_Row_Lease_Survives_Header_Rebind;

   procedure All_Binary16_Encodings_Round_Trip (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat := Float16_Image (1, 65_536);
      Written  : OpenCV.Core.Float16_Row_Access.Row_Array (0 .. 65_535);
      Readback : OpenCV.Core.Float16_Row_Access.Row_Array (0 .. 65_535);
      Mismatch : Natural := 0;

      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Length = 65_536,
            "The borrowed exhaustive row must expose every encoding");
         for Index in Data'Range loop
            if Bits_Of (Data (Index)) /= Interfaces.Unsigned_16 (Index) then
               Mismatch := Mismatch + 1;
            end if;
         end loop;
      end Inspect;
   begin
      for Index in Written'Range loop
         Written (Index) := Value_Of (Interfaces.Unsigned_16 (Index));
      end loop;

      OpenCV.Core.Float16_Row_Access.Write_Row (Image, 0, Written);
      OpenCV.Core.Float16_Row_Access.Read_Row (Image, 0, Readback);

      for Index in Readback'Range loop
         if Bits_Of (Readback (Index)) /= Interfaces.Unsigned_16 (Index) then
            Mismatch := Mismatch + 1;
         end if;
      end loop;

      AUnit.Assertions.Assert
        (Mismatch = 0,
         "Copied Write_Row then Read_Row must preserve every binary16"
         & " encoding");

      OpenCV.Core.Float16_Row_Access.With_Read_Only_Row
        (Image, 0, Inspect'Access);
      AUnit.Assertions.Assert
        (Mismatch = 0,
         "A borrowed Float16 row must observe every binary16 encoding");
   end All_Binary16_Encodings_Round_Trip;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Float16 copied rows preserve binary16 encodings",
            Copied_Rows_Preserve_Binary16_Encodings'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 copied row arbitrary bounds map to columns",
            Copied_Row_Arbitrary_Bounds_Map_To_Columns'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 copied Region rows respect stride aliases and Clone",
            Copied_Region_Writes_Respect_Stride_Aliases_And_Clone'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 copied row validation rejects invalid input",
            Copied_Row_Validation_Rejects_Invalid_Input'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 borrowed row read preserves exact bits",
            Borrowed_Row_Read_Preserves_Exact_Bits'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 borrowed writable row is zero-copy",
            Borrowed_Writable_Row_Is_Zero_Copy'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 borrowed Region is zero-copy without padding",
            Borrowed_Region_Is_Zero_Copy_Without_Padding'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 borrowed row validation does not invoke callback",
            Borrowed_Row_Validation_Does_Not_Invoke_Callback'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 borrowed row propagates callback exceptions",
            Borrowed_Row_Propagates_Callback_Exception'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 borrowed row lease survives header rebind",
            Borrowed_Row_Lease_Survives_Header_Rebind'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 row transfer preserves all 65536 binary16 encodings",
            All_Binary16_Encodings_Round_Trip'Access));
      return Result'Access;
   end Suite;

end Float16_Row_Access_Tests;
