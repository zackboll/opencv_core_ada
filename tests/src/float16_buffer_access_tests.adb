with Ada.Exceptions;
with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV.Core;
with OpenCV.Core.Float16_Access;
with OpenCV.Core.Float16_Buffer_Access;
with OpenCV.Core.Float16_Row_Access;

package body Float16_Buffer_Access_Tests is

   use type Ada.Exceptions.Exception_Id;
   use type Interfaces.Unsigned_16;
   use Mat_Test_Support;

   Borrowed_Buffer_Callback_Error : exception;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

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

   procedure Fill_Bits
     (Image : in out OpenCV.Core.Mat; Bits : Interfaces.Unsigned_16) is
   begin
      for Row in 0 .. Image.Rows - 1 loop
         for Column in 0 .. Image.Columns - 1 loop
            OpenCV.Core.Float16_Access.Set
              (Image, Row, Column, Value_Of (Bits));
         end loop;
      end loop;
   end Fill_Bits;

   procedure Read_Only_Buffer_Preserves_Extent_Order_And_Bits
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat := Float16_Image (2, 3);

      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5 and then Data'Length = 6,
            "A Float16 buffer must exactly span zero-based Image.Total");
         Assert_Bits (Data (0), 16#0000#, "Data (0) must be (0, 0)");
         Assert_Bits
           (Data (2), 16#03FF#, "Data (Columns - 1) must be (0, last)");
         Assert_Bits (Data (3), 16#0400#, "Data (Columns) must be (1, 0)");
         Assert_Bits
           (Data (5), 16#BC00#, "Data (Total - 1) must be the last element");
      end Inspect;
   begin
      OpenCV.Core.Float16_Access.Set (Image, 0, 0, Value_Of (16#0000#));
      OpenCV.Core.Float16_Access.Set (Image, 0, 1, Value_Of (16#8000#));
      OpenCV.Core.Float16_Access.Set (Image, 0, 2, Value_Of (16#03FF#));
      OpenCV.Core.Float16_Access.Set (Image, 1, 0, Value_Of (16#0400#));
      OpenCV.Core.Float16_Access.Set (Image, 1, 1, Value_Of (16#3C00#));
      OpenCV.Core.Float16_Access.Set (Image, 1, 2, Value_Of (16#BC00#));
      OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
        (Image, Inspect'Access);
   end Read_Only_Buffer_Preserves_Extent_Order_And_Bits;

   procedure Writable_Buffer_Is_Zero_Copy_And_Shared (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat := Float16_Image (2, 3);
      Alias : OpenCV.Core.Mat;
      Copy  : OpenCV.Core.Mat;
      Row   : OpenCV.Core.Float16_Row_Access.Row_Array (0 .. 2);

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float16_Buffer_Access.Buffer_Array)
      is
      begin
         Data (0) := Value_Of (16#7C00#);
         Data (3) := Value_Of (16#FC00#);
         Data (5) := Value_Of (16#7C01#);
         Assert_Stored_Bits
           (Image,
            0,
            0,
            16#7C00#,
            "buffer writes must be visible through Float16_Access");
         Assert_Stored_Bits
           (Alias,
            1,
            0,
            16#FC00#,
            "buffer writes must be immediately visible through aliases");
         OpenCV.Core.Float16_Access.Set (Alias, 0, 1, Value_Of (16#0001#));
         Assert_Bits
           (Data (1),
            16#0001#,
            "alias writes must be immediately visible through Data");
      end Mutate;
   begin
      Fill_Bits (Image, 16#3C00#);
      Alias := Image;
      Copy := Image.Clone;
      OpenCV.Core.Float16_Buffer_Access.With_Writable_Buffer
        (Image, Mutate'Access);
      OpenCV.Core.Float16_Row_Access.Read_Row (Image, 1, Row);
      Assert_Bits
        (Row (0), 16#FC00#, "row access must observe whole-buffer writes");
      Assert_Bits
        (Row (2),
         16#7C01#,
         "last-column row access must observe buffer writes");
      Assert_Stored_Bits
        (Image, 0, 1, 16#0001#, "alias mutation during the callback remains");
      Assert_Stored_Bits
        (Copy,
         0,
         0,
         16#3C00#,
         "Clone must remain independent of buffer writes");
      Assert_Stored_Bits
        (Copy, 1, 2, 16#3C00#, "Clone last element must remain independent");
   end Writable_Buffer_Is_Zero_Copy_And_Shared;

   procedure Buffer_Preserves_Special_Encodings (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat := Float16_Image (2, 7);

      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 14, "special-encoding fixture must span 14 values");
         Assert_Bits (Data (0), 16#0000#, "+0");
         Assert_Bits (Data (1), 16#8000#, "-0");
         Assert_Bits (Data (2), 16#0001#, "smallest subnormal");
         Assert_Bits (Data (3), 16#03FF#, "largest subnormal");
         Assert_Bits (Data (4), 16#0400#, "smallest normal");
         Assert_Bits (Data (5), 16#3C00#, "+1");
         Assert_Bits (Data (6), 16#BC00#, "-1");
         Assert_Bits (Data (7), 16#7BFF#, "max finite");
         Assert_Bits (Data (8), 16#FBFF#, "max-magnitude negative finite");
         Assert_Bits (Data (9), 16#7C00#, "+Inf");
         Assert_Bits (Data (10), 16#FC00#, "-Inf");
         Assert_Bits (Data (11), 16#7C01#, "NaN payload");
         Assert_Bits (Data (12), 16#7E00#, "quiet NaN");
         Assert_Bits (Data (13), 16#FC01#, "negative NaN payload");
      end Inspect;
   begin
      OpenCV.Core.Float16_Access.Set (Image, 0, 0, Value_Of (16#0000#));
      OpenCV.Core.Float16_Access.Set (Image, 0, 1, Value_Of (16#8000#));
      OpenCV.Core.Float16_Access.Set (Image, 0, 2, Value_Of (16#0001#));
      OpenCV.Core.Float16_Access.Set (Image, 0, 3, Value_Of (16#03FF#));
      OpenCV.Core.Float16_Access.Set (Image, 0, 4, Value_Of (16#0400#));
      OpenCV.Core.Float16_Access.Set (Image, 0, 5, Value_Of (16#3C00#));
      OpenCV.Core.Float16_Access.Set (Image, 0, 6, Value_Of (16#BC00#));
      OpenCV.Core.Float16_Access.Set (Image, 1, 0, Value_Of (16#7BFF#));
      OpenCV.Core.Float16_Access.Set (Image, 1, 1, Value_Of (16#FBFF#));
      OpenCV.Core.Float16_Access.Set (Image, 1, 2, Value_Of (16#7C00#));
      OpenCV.Core.Float16_Access.Set (Image, 1, 3, Value_Of (16#FC00#));
      OpenCV.Core.Float16_Access.Set (Image, 1, 4, Value_Of (16#7C01#));
      OpenCV.Core.Float16_Access.Set (Image, 1, 5, Value_Of (16#7E00#));
      OpenCV.Core.Float16_Access.Set (Image, 1, 6, Value_Of (16#FC01#));
      OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
        (Image, Inspect'Access);
   end Buffer_Preserves_Special_Encodings;

   procedure All_Binary16_Encodings_Round_Trip (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat := Float16_Image (256, 256);
      Written  : OpenCV.Core.Float16_Row_Access.Row_Array (0 .. 255);
      Readback : OpenCV.Core.Float16_Row_Access.Row_Array (0 .. 255);
      Mismatch : Natural := 0;

      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Length = 65_536,
            "The borrowed exhaustive buffer must expose every encoding");
         for Index in Data'Range loop
            if Bits_Of (Data (Index)) /= Interfaces.Unsigned_16 (Index) then
               Mismatch := Mismatch + 1;
            end if;
         end loop;
      end Inspect;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float16_Buffer_Access.Buffer_Array)
      is
      begin
         for Index in Data'Range loop
            Data (Index) := Value_Of (Interfaces.Unsigned_16 (65_535 - Index));
         end loop;
      end Mutate;
   begin
      for Row in 0 .. 255 loop
         for Column in Written'Range loop
            Written (Column) :=
              Value_Of (Interfaces.Unsigned_16 (Row * 256 + Column));
         end loop;
         OpenCV.Core.Float16_Row_Access.Write_Row (Image, Row, Written);
      end loop;

      OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
        (Image, Inspect'Access);
      AUnit.Assertions.Assert
        (Mismatch = 0,
         "A borrowed Float16 buffer must observe every binary16 encoding");

      OpenCV.Core.Float16_Buffer_Access.With_Writable_Buffer
        (Image, Mutate'Access);

      for Row in 0 .. 255 loop
         OpenCV.Core.Float16_Row_Access.Read_Row (Image, Row, Readback);
         for Column in Readback'Range loop
            if Bits_Of (Readback (Column))
              /= Interfaces.Unsigned_16 (65_535 - (Row * 256 + Column))
            then
               Mismatch := Mismatch + 1;
            end if;
         end loop;
      end loop;

      AUnit.Assertions.Assert
        (Mismatch = 0,
         "Writable Float16 buffer population must preserve every encoding");
   end All_Binary16_Encodings_Round_Trip;

   procedure Multi_Row_Writes_Are_Observed_Through_Access
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat := Float16_Image (3, 4);
      Row   : OpenCV.Core.Float16_Row_Access.Row_Array (0 .. 3);

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float16_Buffer_Access.Buffer_Array)
      is
      begin
         Data (0) := Value_Of (16#0001#);
         Data (3) := Value_Of (16#03FF#);
         Data (4) := Value_Of (16#0400#);
         Data (11) := Value_Of (16#7BFF#);
      end Mutate;
   begin
      Fill_Bits (Image, 16#3C00#);
      OpenCV.Core.Float16_Buffer_Access.With_Writable_Buffer
        (Image, Mutate'Access);
      Assert_Stored_Bits
        (Image, 0, 0, 16#0001#, "element access must observe first write");
      Assert_Stored_Bits
        (Image, 0, 3, 16#03FF#, "element access must observe first-row last");
      Assert_Stored_Bits
        (Image, 1, 0, 16#0400#, "element access must observe the next row");
      Assert_Stored_Bits
        (Image,
         2,
         3,
         16#7BFF#,
         "element access must observe the last element");
      OpenCV.Core.Float16_Row_Access.Read_Row (Image, 1, Row);
      Assert_Bits (Row (0), 16#0400#, "row access must observe the row start");
      Assert_Bits
        (Row (3), 16#3C00#, "unwritten columns in the middle row remain");
      OpenCV.Core.Float16_Row_Access.Read_Row (Image, 2, Row);
      Assert_Bits
        (Row (3), 16#7BFF#, "row access must observe the last write");
   end Multi_Row_Writes_Are_Observed_Through_Access;

   procedure Region_Continuity_Is_Enforced (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Parent     : OpenCV.Core.Mat := Float16_Image (4, 5);
      Continuous : OpenCV.Core.Mat :=
        Parent.Region ((X => 0, Y => 1, Width => 5, Height => 2));
      Strided    : constant OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Invoked    : Boolean := False;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float16_Buffer_Access.Buffer_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 10, "A continuous Region must expose Region.Total");
         Data (0) := Value_Of (16#7C00#);
         Data (9) := Value_Of (16#FC00#);
      end Mutate;

      procedure Mark
        (Data : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark;

      procedure Borrow_Strided is
      begin
         OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
           (Strided, Mark'Access);
      end Borrow_Strided;
   begin
      Fill_Bits (Parent, 16#3C00#);
      AUnit.Assertions.Assert
        (Continuous.Is_Continuous and then not Strided.Is_Continuous,
         "Region fixtures must exercise both continuity cases");
      OpenCV.Core.Float16_Buffer_Access.With_Writable_Buffer
        (Continuous, Mutate'Access);
      Assert_Stored_Bits
        (Parent,
         1,
         0,
         16#7C00#,
         "Continuous Region buffer writes must mutate parent storage");
      Assert_Stored_Bits
        (Parent,
         2,
         4,
         16#FC00#,
         "Continuous Region last element must mutate parent storage");
      Assert_Stored_Bits
        (Parent,
         0,
         0,
         16#3C00#,
         "parent elements before the Region must remain unchanged");
      Assert_Stored_Bits
        (Parent,
         3,
         4,
         16#3C00#,
         "parent elements after the Region must remain unchanged");
      Assert_Raises_OpenCV_Error
        (Borrow_Strided'Access,
         "Float16 whole-buffer access must reject a non-continuous Region");
      AUnit.Assertions.Assert
        (not Invoked,
         "Continuity validation must precede callback invocation");
   end Region_Continuity_Is_Enforced;

   procedure Wrong_Layout_Does_Not_Invoke_Callback (Test : in out Fixture) is
      pragma Unreferenced (Test);
      UInt16_M  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt16, 1));
      Int16_M   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Int16, 1));
      Float32_M : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      C2        : constant OpenCV.Core.Mat := Float16_Image (1, 2, 2);
      C3        : constant OpenCV.Core.Mat := Float16_Image (1, 2, 3);
      Invoked   : Boolean := False;

      procedure Mark
        (Data : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark;

      procedure Borrow_UInt16 is
      begin
         OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
           (UInt16_M, Mark'Access);
      end Borrow_UInt16;

      procedure Borrow_Int16 is
      begin
         OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
           (Int16_M, Mark'Access);
      end Borrow_Int16;

      procedure Borrow_Float32 is
      begin
         OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
           (Float32_M, Mark'Access);
      end Borrow_Float32;

      procedure Borrow_C2 is
      begin
         OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
           (C2, Mark'Access);
      end Borrow_C2;

      procedure Borrow_C3 is
      begin
         OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
           (C3, Mark'Access);
      end Borrow_C3;
   begin
      Assert_Raises_OpenCV_Error
        (Borrow_UInt16'Access, "Float16 buffer must reject UInt16 C1");
      Assert_Raises_OpenCV_Error
        (Borrow_Int16'Access, "Float16 buffer must reject Int16 C1");
      Assert_Raises_OpenCV_Error
        (Borrow_Float32'Access, "Float16 buffer must reject Float32 C1");
      Assert_Raises_OpenCV_Error
        (Borrow_C2'Access, "Float16 buffer must reject Float16 C2");
      Assert_Raises_OpenCV_Error
        (Borrow_C3'Access, "Float16 buffer must reject Float16 C3");
      AUnit.Assertions.Assert
        (not Invoked, "Type validation must precede callback invocation");
   end Wrong_Layout_Does_Not_Invoke_Callback;

   procedure Callback_Exception_Propagates_And_Preserves_Writes
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat := Float16_Image (2, 2);
      Raised   : Boolean := False;
      Identity : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float16_Buffer_Access.Buffer_Array)
      is
      begin
         Data (2) := Value_Of (16#7C01#);
         raise Borrowed_Buffer_Callback_Error;
      end Mutate;
   begin
      Fill_Bits (Image, 16#3C00#);
      begin
         OpenCV.Core.Float16_Buffer_Access.With_Writable_Buffer
           (Image, Mutate'Access);
      exception
         when Error : Borrowed_Buffer_Callback_Error =>
            Raised := True;
            Identity := Ada.Exceptions.Exception_Identity (Error);
      end;
      AUnit.Assertions.Assert
        (Raised and then Identity = Borrowed_Buffer_Callback_Error'Identity,
         "A Float16 buffer callback exception must propagate unchanged");
      Assert_Stored_Bits
        (Image, 1, 0, 16#7C01#, "Writes before a callback exception remain");
      Assert_Stored_Bits
        (Image, 0, 0, 16#3C00#, "Unwritten elements must remain unchanged");
      OpenCV.Core.Float16_Access.Set (Image, 0, 1, Value_Of (16#0400#));
      Assert_Stored_Bits
        (Image, 0, 1, 16#0400#, "the Mat must remain usable afterward");
   end Callback_Exception_Propagates_And_Preserves_Writes;

   procedure Borrowed_Buffer_Lease_Survives_Header_Rebind
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat := Float16_Image (1, 2);
      Alias : OpenCV.Core.Mat;

      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array)
      is
         Replacement : constant OpenCV.Core.Mat := Float16_Image (1, 1);
         Empty       : OpenCV.Core.Mat;
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Length = 2,
            "The borrowed Float16 buffer must remain valid at callback entry");
         Assert_Bits (Data (1), 16#FC00#, "entry encoding");
         Image := Replacement;
         Alias := Empty;
         AUnit.Assertions.Assert
           (Alias.Is_Empty,
            "Rebinding the alias header must leave an empty Mat");
         Assert_Bits
           (Data (0),
            16#7C00#,
            "The Float16 buffer lease must survive rebinding other headers");
         Assert_Bits
           (Data (1),
            16#FC00#,
            "The Float16 buffer lease must preserve the second encoding");
      end Inspect;
   begin
      OpenCV.Core.Float16_Access.Set (Image, 0, 0, Value_Of (16#7C00#));
      OpenCV.Core.Float16_Access.Set (Image, 0, 1, Value_Of (16#FC00#));
      Alias := Image;
      OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
        (Image, Inspect'Access);
   end Borrowed_Buffer_Lease_Survives_Header_Rebind;

   procedure Typed_Empty_Mat_Invokes_Callback_With_Empty_Array
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Empty   : constant OpenCV.Core.Mat := Float16_Image (0, 0);
      Invoked : Boolean := False;

      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array) is
      begin
         Invoked := True;
         AUnit.Assertions.Assert
           (Data'Length = 0,
            "A typed empty Float16 Mat must borrow an empty array");
      end Inspect;
   begin
      OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
        (Empty, Inspect'Access);
      AUnit.Assertions.Assert
        (Invoked, "A typed empty Float16 Mat must invoke its callback");
   end Typed_Empty_Mat_Invokes_Callback_With_Empty_Array;

   procedure Three_Dimensional_Mat_Is_Rejected_Before_Callback
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float16, 1));
      Invoked : Boolean := False;

      procedure Mark
        (Data : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark;

      procedure Borrow is
      begin
         OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
           (Image, Mark'Access);
      end Borrow;
   begin
      AUnit.Assertions.Assert
        (Image.Is_Continuous and then Image.Dimension_Count = 3,
         "The dimensional fixture must be a continuous genuine 3-D Mat");
      Assert_Raises_OpenCV_Error
        (Borrow'Access,
         "Float16 whole-buffer access must match the established 2-D"
         & " contract");
      AUnit.Assertions.Assert
        (not Invoked,
         "Dimensional validation must precede callback invocation");
   end Three_Dimensional_Mat_Is_Rejected_Before_Callback;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Float16 buffer preserves extent order and exact bits",
            Read_Only_Buffer_Preserves_Extent_Order_And_Bits'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 writable buffer is zero-copy and shared",
            Writable_Buffer_Is_Zero_Copy_And_Shared'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 buffer preserves special binary16 encodings",
            Buffer_Preserves_Special_Encodings'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 buffer transfer preserves all 65536 binary16 encodings",
            All_Binary16_Encodings_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 buffer writes are observed across row boundaries",
            Multi_Row_Writes_Are_Observed_Through_Access'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 buffer continuity and continuous Region",
            Region_Continuity_Is_Enforced'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 buffer rejects wrong depth and channels before callback",
            Wrong_Layout_Does_Not_Invoke_Callback'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 buffer callback exception preserves completed writes",
            Callback_Exception_Propagates_And_Preserves_Writes'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 buffer lease survives header rebind",
            Borrowed_Buffer_Lease_Survives_Header_Rebind'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 typed empty buffer invokes callback with empty array",
            Typed_Empty_Mat_Invokes_Callback_With_Empty_Array'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 buffer matches established 2-D dimensional contract",
            Three_Dimensional_Mat_Is_Rejected_Before_Callback'Access));
      return Result'Access;
   end Suite;

end Float16_Buffer_Access_Tests;
