with Ada.Exceptions;
with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV.Core;
with OpenCV.Core.Float16_Vec3;
with OpenCV.Core.Float16_Vec3_Access;
with OpenCV.Core.Float16_Vec3_Buffer_Access;

package body Float16_Vec3_Buffer_Access_Tests is

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

   procedure Read_Only_Buffer_Preserves_Row_Major_Mapping
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat := Float16_C3_Image (2, 3);

      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5 and then Data'Length = 6,
            "A Float16 Vec3 buffer must exactly span zero-based Image.Total");
         Assert_Component_Bits
           (Data (0),
            Pixel (16#0000#, 16#8000#, 16#0001#),
            "Data (0) must be (0, 0)");
         Assert_Component_Bits
           (Data (2),
            Pixel (16#03FF#, 16#0400#, 16#3C00#),
            "Data (Columns - 1) must be (0, last)");
         Assert_Component_Bits
           (Data (3),
            Pixel (16#BC00#, 16#7BFF#, 16#FBFF#),
            "Data (Columns) must be (1, 0)");
         Assert_Component_Bits
           (Data (5),
            Pixel (16#7C01#, 16#7E00#, 16#FC01#),
            "Data (Total - 1) must be the last pixel");
      end Inspect;
   begin
      OpenCV.Core.Float16_Vec3_Access.Set
        (Image, 0, 0, Pixel (16#0000#, 16#8000#, 16#0001#));
      OpenCV.Core.Float16_Vec3_Access.Set
        (Image, 0, 1, Pixel (16#3C00#, 16#BC00#, 16#7C00#));
      OpenCV.Core.Float16_Vec3_Access.Set
        (Image, 0, 2, Pixel (16#03FF#, 16#0400#, 16#3C00#));
      OpenCV.Core.Float16_Vec3_Access.Set
        (Image, 1, 0, Pixel (16#BC00#, 16#7BFF#, 16#FBFF#));
      OpenCV.Core.Float16_Vec3_Access.Set
        (Image, 1, 1, Pixel (16#7C00#, 16#FC00#, 16#7E55#));
      OpenCV.Core.Float16_Vec3_Access.Set
        (Image, 1, 2, Pixel (16#7C01#, 16#7E00#, 16#FC01#));
      OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer
        (Image, Inspect'Access);
   end Read_Only_Buffer_Preserves_Row_Major_Mapping;

   procedure Writable_Buffer_Is_Zero_Copy_And_Shared (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image       : OpenCV.Core.Mat := Float16_C3_Image (2, 3);
      Alias       : OpenCV.Core.Mat;
      Copy        : OpenCV.Core.Mat;
      First       : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#7C00#, 16#0000#, 16#8000#);
      Next        : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#FC00#, 16#7C01#, 16#7E00#);
      Last        : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#7C01#, 16#7E00#, 16#FC01#);
      Alias_Write : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#0001#, 16#03FF#, 16#0400#);

      procedure Mutate
        (Data :
           aliased in out OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5 and then Data'Length = 6,
            "A writable Float16 Vec3 buffer must be a flat zero-based array");
         Data (0) := First;
         Data (3) := Next;
         Data (5) := Last;
         Assert_Stored_Pixel
           (Image,
            0,
            0,
            First,
            "buffer writes must be visible through Float16_Vec3_Access");
         Assert_Stored_Pixel
           (Alias,
            1,
            0,
            Next,
            "buffer writes must be immediately visible through aliases");
         OpenCV.Core.Float16_Vec3_Access.Set (Alias, 0, 1, Alias_Write);
         Assert_Component_Bits
           (Data (1),
            Alias_Write,
            "alias writes must be immediately visible through Data");
      end Mutate;
   begin
      Fill_Zero (Image);
      Alias := Image;
      Copy := Image.Clone;
      OpenCV.Core.Float16_Vec3_Buffer_Access.With_Writable_Buffer
        (Image, Mutate'Access);
      Assert_Stored_Pixel
        (Image, 0, 0, First, "first-pixel write remains after callback");
      Assert_Stored_Pixel
        (Image, 1, 0, Next, "row-boundary write remains after callback");
      Assert_Stored_Pixel
        (Image, 1, 2, Last, "last-pixel write remains after callback");
      Assert_Stored_Pixel
        (Image, 0, 1, Alias_Write, "alias mutation during callback remains");
      Assert_Stored_Pixel
        (Copy,
         0,
         0,
         Pixel (16#0000#, 16#0000#, 16#0000#),
         "Clone must remain independent of buffer writes");
      Assert_Stored_Pixel
        (Copy,
         1,
         2,
         Pixel (16#0000#, 16#0000#, 16#0000#),
         "Clone last pixel must remain independent");
   end Writable_Buffer_Is_Zero_Copy_And_Shared;

   procedure Buffer_Preserves_Special_Encodings (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat := Float16_C3_Image (1, 5);

      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 5, "special-encoding fixture must span 5 pixels");
         Assert_Component_Bits
           (Data (0), Pixel (16#0000#, 16#8000#, 16#0001#), "+0 -0 subnormal");
         Assert_Component_Bits
           (Data (1),
            Pixel (16#03FF#, 16#0400#, 16#3C00#),
            "largest subnormal, smallest normal, +1");
         Assert_Component_Bits
           (Data (2),
            Pixel (16#BC00#, 16#7BFF#, 16#FBFF#),
            "-1, max finite, negative max finite");
         Assert_Component_Bits
           (Data (3),
            Pixel (16#7C00#, 16#FC00#, 16#7C01#),
            "+Inf, -Inf, NaN payload");
         Assert_Component_Bits
           (Data (4),
            Pixel (16#7E00#, 16#FC01#, 16#7E55#),
            "quiet NaN, negative NaN, another payload");
      end Inspect;
   begin
      OpenCV.Core.Float16_Vec3_Access.Set
        (Image, 0, 0, Pixel (16#0000#, 16#8000#, 16#0001#));
      OpenCV.Core.Float16_Vec3_Access.Set
        (Image, 0, 1, Pixel (16#03FF#, 16#0400#, 16#3C00#));
      OpenCV.Core.Float16_Vec3_Access.Set
        (Image, 0, 2, Pixel (16#BC00#, 16#7BFF#, 16#FBFF#));
      OpenCV.Core.Float16_Vec3_Access.Set
        (Image, 0, 3, Pixel (16#7C00#, 16#FC00#, 16#7C01#));
      OpenCV.Core.Float16_Vec3_Access.Set
        (Image, 0, 4, Pixel (16#7E00#, 16#FC01#, 16#7E55#));
      OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer
        (Image, Inspect'Access);
   end Buffer_Preserves_Special_Encodings;

   procedure All_Binary16_Encodings_Round_Trip (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat := Float16_C3_Image (2, 10_923);
      Mismatch : Natural := 0;
      Bits     : Interfaces.Unsigned_16 := 0;

      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array)
      is
         Observed : Interfaces.Unsigned_16 := 0;
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Length = 21_846,
            "The borrowed exhaustive buffer must expose every encoding slot");
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
      AUnit.Assertions.Assert
        (Image.Is_Continuous
         and then Image.Rows = 2
         and then Image.Columns = 10_923,
         "The exhaustive fixture must be a continuous two-row Mat");

      for Row in 0 .. Image.Rows - 1 loop
         for Column in 0 .. Image.Columns - 1 loop
            OpenCV.Core.Float16_Vec3_Access.Set
              (Image, Row, Column, Pixel (Bits, Bits + 1, Bits + 2));
            Bits := Bits + 3;
         end loop;
      end loop;

      OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer
        (Image, Inspect'Access);
      AUnit.Assertions.Assert
        (Mismatch = 0,
         "A borrowed Float16 Vec3 buffer must observe every binary16"
         & " encoding");
   end All_Binary16_Encodings_Round_Trip;

   procedure Continuous_Region_Is_Zero_Copy (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Parent     : OpenCV.Core.Mat := Float16_C3_Image (4, 5);
      Continuous : OpenCV.Core.Mat :=
        Parent.Region ((X => 0, Y => 1, Width => 5, Height => 2));
      First      : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#7C00#, 16#0000#, 16#8000#);
      Last       : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#FC00#, 16#7C01#, 16#7E00#);
      Fill       : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#3C00#, 16#3C00#, 16#3C00#);

      procedure Mutate
        (Data :
           aliased in out OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 10, "A continuous Region must expose Region.Total");
         Data (0) := First;
         Data (9) := Last;
      end Mutate;
   begin
      for Row in 0 .. Parent.Rows - 1 loop
         for Column in 0 .. Parent.Columns - 1 loop
            OpenCV.Core.Float16_Vec3_Access.Set (Parent, Row, Column, Fill);
         end loop;
      end loop;
      AUnit.Assertions.Assert
        (Continuous.Is_Continuous and then Continuous.Is_Submatrix,
         "The continuous Region fixture must be a full-width submatrix");
      OpenCV.Core.Float16_Vec3_Buffer_Access.With_Writable_Buffer
        (Continuous, Mutate'Access);
      Assert_Stored_Pixel
        (Parent,
         1,
         0,
         First,
         "Continuous Region buffer writes must mutate parent storage");
      Assert_Stored_Pixel
        (Parent,
         2,
         4,
         Last,
         "Continuous Region last element must mutate parent storage");
      Assert_Stored_Pixel
        (Parent,
         0,
         0,
         Fill,
         "parent elements before the Region must remain unchanged");
      Assert_Stored_Pixel
        (Parent,
         3,
         4,
         Fill,
         "parent elements after the Region must remain unchanged");
   end Continuous_Region_Is_Zero_Copy;

   procedure Noncontinuous_Region_Is_Rejected_Before_Callback
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Parent  : constant OpenCV.Core.Mat := Float16_C3_Image (4, 6);
      Strided : constant OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Invoked : Boolean := False;

      procedure Mark_Read
        (Data : aliased OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_Read;

      procedure Mark_Write
        (Data :
           aliased in out OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_Write;

      procedure Read_Strided is
      begin
         OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer
           (Strided, Mark_Read'Access);
      end Read_Strided;

      procedure Write_Strided is
         Mutable : OpenCV.Core.Mat := Strided;
      begin
         OpenCV.Core.Float16_Vec3_Buffer_Access.With_Writable_Buffer
           (Mutable, Mark_Write'Access);
      end Write_Strided;
   begin
      AUnit.Assertions.Assert
        (not Strided.Is_Continuous,
         "A partial-width multi-row Region must be non-continuous");
      Assert_Raises_OpenCV_Error
        (Read_Strided'Access,
         "Float16 Vec3 whole-buffer access must reject a non-continuous"
         & " Region");
      Assert_Raises_OpenCV_Error
        (Write_Strided'Access,
         "writable Float16 Vec3 buffer access must reject a non-continuous"
         & " Region");
      AUnit.Assertions.Assert
        (not Invoked,
         "Continuity validation must precede callback invocation");
   end Noncontinuous_Region_Is_Rejected_Before_Callback;

   procedure Wrong_Layout_Does_Not_Invoke_Callback (Test : in out Fixture) is
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
      Empty     : OpenCV.Core.Mat;
      Invoked   : Boolean := False;

      procedure Mark
        (Data : aliased OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark;

      procedure Borrow_UInt16 is
      begin
         OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer
           (UInt16_M, Mark'Access);
      end Borrow_UInt16;

      procedure Borrow_Float32 is
      begin
         OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer
           (Float32_M, Mark'Access);
      end Borrow_Float32;

      procedure Borrow_C1 is
      begin
         OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer
           (C1, Mark'Access);
      end Borrow_C1;

      procedure Borrow_C2 is
      begin
         OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer
           (C2, Mark'Access);
      end Borrow_C2;

      procedure Borrow_C4 is
      begin
         OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer
           (C4, Mark'Access);
      end Borrow_C4;

      procedure Borrow_Empty is
      begin
         OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer
           (Empty, Mark'Access);
      end Borrow_Empty;
   begin
      Assert_Raises_OpenCV_Error
        (Borrow_UInt16'Access, "Float16 Vec3 buffer must reject UInt16 C3");
      Assert_Raises_OpenCV_Error
        (Borrow_Float32'Access, "Float16 Vec3 buffer must reject Float32 C3");
      Assert_Raises_OpenCV_Error
        (Borrow_C1'Access, "Float16 Vec3 buffer must reject Float16 C1");
      Assert_Raises_OpenCV_Error
        (Borrow_C2'Access, "Float16 Vec3 buffer must reject Float16 C2");
      Assert_Raises_OpenCV_Error
        (Borrow_C4'Access, "Float16 Vec3 buffer must reject Float16 C4");
      Assert_Raises_OpenCV_Error
        (Borrow_Empty'Access,
         "Float16 Vec3 buffer must reject a default invalid Mat");
      AUnit.Assertions.Assert
        (not Invoked, "Type validation must precede callback invocation");
   end Wrong_Layout_Does_Not_Invoke_Callback;

   procedure Three_Dimensional_Mat_Is_Rejected_Before_Callback
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float16, 3));
      Invoked : Boolean := False;

      procedure Mark
        (Data : aliased OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark;

      procedure Borrow is
      begin
         OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer
           (Image, Mark'Access);
      end Borrow;
   begin
      AUnit.Assertions.Assert
        (Image.Is_Continuous and then Image.Dimension_Count = 3,
         "The dimensional fixture must be a continuous genuine 3-D Mat");
      Assert_Raises_OpenCV_Error
        (Borrow'Access,
         "Float16 Vec3 whole-buffer access must match the established 2-D"
         & " contract");
      AUnit.Assertions.Assert
        (not Invoked,
         "Dimensional validation must precede callback invocation");
   end Three_Dimensional_Mat_Is_Rejected_Before_Callback;

   procedure Typed_Empty_Mat_Invokes_Callback_With_Empty_Array
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Empty   : constant OpenCV.Core.Mat := Float16_C3_Image (0, 0);
      Invoked : Boolean := False;

      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array) is
      begin
         Invoked := True;
         AUnit.Assertions.Assert
           (Data'Length = 0,
            "A typed empty Float16 Vec3 Mat must borrow an empty array");
      end Inspect;
   begin
      OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer
        (Empty, Inspect'Access);
      AUnit.Assertions.Assert
        (Invoked, "A typed empty Float16 Vec3 Mat must invoke its callback");
   end Typed_Empty_Mat_Invokes_Callback_With_Empty_Array;

   procedure Callback_Exception_Propagates_And_Preserves_Writes
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat := Float16_C3_Image (2, 2);
      Raised   : Boolean := False;
      Identity : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;
      Written  : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#7C01#, 16#7E00#, 16#FC01#);
      Kept     : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#BC00#, 16#0400#, 16#3C00#);

      procedure Mutate
        (Data :
           aliased in out OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array)
      is
      begin
         Data (2) := Written;
         raise Borrowed_Buffer_Callback_Error;
      end Mutate;
   begin
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 0, 0, Kept);
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 1, 0, Kept);
      begin
         OpenCV.Core.Float16_Vec3_Buffer_Access.With_Writable_Buffer
           (Image, Mutate'Access);
      exception
         when Error : Borrowed_Buffer_Callback_Error =>
            Raised := True;
            Identity := Ada.Exceptions.Exception_Identity (Error);
      end;
      AUnit.Assertions.Assert
        (Raised and then Identity = Borrowed_Buffer_Callback_Error'Identity,
         "A Float16 Vec3 buffer callback exception must propagate unchanged");
      Assert_Stored_Pixel
        (Image, 1, 0, Written, "Writes before a callback exception remain");
      Assert_Stored_Pixel
        (Image, 0, 0, Kept, "Unwritten pixels must remain unchanged");
      OpenCV.Core.Float16_Vec3_Access.Set
        (Image, 0, 1, Pixel (16#0400#, 16#0001#, 16#03FF#));
      Assert_Stored_Pixel
        (Image,
         0,
         1,
         Pixel (16#0400#, 16#0001#, 16#03FF#),
         "the Mat must remain usable afterward");
   end Callback_Exception_Propagates_And_Preserves_Writes;

   procedure Borrowed_Buffer_Lease_Survives_Header_Rebind
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image  : OpenCV.Core.Mat := Float16_C3_Image (1, 2);
      Alias  : OpenCV.Core.Mat;
      First  : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#7C00#, 16#0000#, 16#8000#);
      Second : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#FC00#, 16#7C01#, 16#7E00#);

      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array)
      is
         Replacement : constant OpenCV.Core.Mat := Float16_C3_Image (1, 1);
         Empty       : OpenCV.Core.Mat;
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Length = 2,
            "The borrowed Float16 Vec3 buffer must remain valid at callback"
            & " entry");
         Assert_Component_Bits (Data (1), Second, "entry encoding");
         Image := Replacement;
         Alias := Empty;
         AUnit.Assertions.Assert
           (Alias.Is_Empty,
            "Rebinding the alias header must leave an empty Mat");
         Assert_Component_Bits
           (Data (0),
            First,
            "The Float16 Vec3 buffer lease must survive rebinding other"
            & " headers");
         Assert_Component_Bits
           (Data (1),
            Second,
            "The Float16 Vec3 buffer lease must preserve the second encoding");
      end Inspect;
   begin
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 0, 0, First);
      OpenCV.Core.Float16_Vec3_Access.Set (Image, 0, 1, Second);
      Alias := Image;
      OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer
        (Image, Inspect'Access);
   end Borrowed_Buffer_Lease_Survives_Header_Rebind;
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
      Buffer_Comp    : constant Natural :=
        Observed_Size
          (OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array'Component_Size);
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
        & " Buffer_Component_Size="
        & Natural'Image (Buffer_Comp);
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
        (Buffer_Comp = 48,
         "Float16 Vec3 Buffer_Array Component_Size must be 48: "
         & Description);
      AUnit.Assertions.Assert
        (Alignment <= 2,
         "Float16 Vec3 alignment must not exceed 2: " & Description);
   end Reports_Enforced_Vec3_Representation;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 buffer preserves row-major mapping and exact bits",
            Read_Only_Buffer_Preserves_Row_Major_Mapping'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 writable buffer is zero-copy and shared",
            Writable_Buffer_Is_Zero_Copy_And_Shared'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 buffer preserves special binary16 encodings",
            Buffer_Preserves_Special_Encodings'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 buffer transfer preserves all 65536 encodings",
            All_Binary16_Encodings_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 buffer continuity and continuous Region",
            Continuous_Region_Is_Zero_Copy'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 buffer rejects non-continuous Region before"
            & " callback",
            Noncontinuous_Region_Is_Rejected_Before_Callback'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 buffer rejects wrong depth and channels before"
            & " callback",
            Wrong_Layout_Does_Not_Invoke_Callback'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 buffer callback exception preserves completed"
            & " writes",
            Callback_Exception_Propagates_And_Preserves_Writes'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 buffer lease survives header rebind",
            Borrowed_Buffer_Lease_Survives_Header_Rebind'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 typed empty buffer invokes callback with empty"
            & " array",
            Typed_Empty_Mat_Invokes_Callback_With_Empty_Array'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 buffer matches established 2-D dimensional contract",
            Three_Dimensional_Mat_Is_Rejected_Before_Callback'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 buffer reports enforced representation",
            Reports_Enforced_Vec3_Representation'Access));
      return Result'Access;
   end Suite;

end Float16_Vec3_Buffer_Access_Tests;
