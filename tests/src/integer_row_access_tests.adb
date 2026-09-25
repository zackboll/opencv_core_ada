with Ada.Exceptions;
with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Int32_Access;
with OpenCV.Core.Int32_Row_Access;

package body Integer_Row_Access_Tests is

   use type Ada.Exceptions.Exception_Id;
   use type OpenCV.Int32_Value;
   use type OpenCV.Core.Int32_Row_Access.Row_Array;
   use Mat_Test_Support;

   Callback_Error : exception;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Int32_Image
     (Rows, Columns : Natural; Channels : OpenCV.Core.Channel_Count := 1)
      return OpenCV.Core.Mat
   is (OpenCV.Core.Create
         (Rows, Columns, (Depth => OpenCV.Core.Int32, Channels => Channels)));

   procedure Copied_Rows_Preserve_Exact_Values_And_Array_Order
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat := Int32_Image (3, 5);
      Written  : constant OpenCV.Core.Int32_Row_Access.Row_Array (7 .. 11) :=
        (OpenCV.Int32_Value'First, -1, 0, 16_777_217, OpenCV.Int32_Value'Last);
      Readback : OpenCV.Core.Int32_Row_Access.Row_Array (20 .. 24);
      Last     : constant OpenCV.Core.Int32_Row_Access.Row_Array (3 .. 7) :=
        (91, 92, 93, 94, 95);
   begin
      Image.Set_To (OpenCV.Make_Scalar (5.0));
      OpenCV.Core.Int32_Row_Access.Write_Row (Image, 0, Written);
      OpenCV.Core.Int32_Row_Access.Write_Row (Image, 2, Last);
      OpenCV.Core.Int32_Row_Access.Read_Row (Image, 0, Readback);

      AUnit.Assertions.Assert
        (Readback = Written,
         "Int32 copied rows must preserve endpoints and 16_777_217 exactly");
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Access.Get (Image, 2, 0) = 91
         and then OpenCV.Core.Int32_Access.Get (Image, 2, 4) = 95,
         "Int32 copied rows must support the last row");

      OpenCV.Core.Int32_Access.Set (Image, 0, 1, 77);
      AUnit.Assertions.Assert
        (Readback (21) = -1, "Read_Row must return an independent copy");
   end Copied_Rows_Preserve_Exact_Values_And_Array_Order;

   procedure Copied_And_Borrowed_Region_Rows_Share_Parent_Storage
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat := Int32_Image (4, 6);
      Region : OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Alias  : OpenCV.Core.Mat := Parent;
      Values : constant OpenCV.Core.Int32_Row_Access.Row_Array (4 .. 6) :=
        (-9, 16_777_217, OpenCV.Int32_Value'Last);

      procedure Inspect (Data : aliased OpenCV.Core.Int32_Row_Access.Row_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data = Values,
            "Borrowed Int32 Region rows must be zero-based and exact");
      end Inspect;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Int32_Row_Access.Row_Array) is
      begin
         Data (0) := OpenCV.Int32_Value'First;
         OpenCV.Core.Int32_Access.Set (Alias, 2, 3, 42);
         AUnit.Assertions.Assert
           (Data (2) = 42,
            "Borrowed Int32 rows must immediately observe alias writes");
      end Mutate;
   begin
      Parent.Set_To (OpenCV.Make_Scalar (1.0));
      AUnit.Assertions.Assert
        (not Region.Is_Continuous,
         "Int32 Region fixture must be non-contiguous");
      OpenCV.Core.Int32_Row_Access.Write_Row (Region, 1, Values);
      OpenCV.Core.Int32_Row_Access.With_Read_Only_Row
        (Region, 1, Inspect'Access);
      OpenCV.Core.Int32_Row_Access.With_Writable_Row
        (Region, 1, Mutate'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Access.Get (Parent, 2, 1) = OpenCV.Int32_Value'First
         and then OpenCV.Core.Int32_Access.Get (Parent, 2, 2) = 16_777_217
         and then OpenCV.Core.Int32_Access.Get (Parent, 2, 3) = 42
         and then OpenCV.Core.Int32_Access.Get (Parent, 2, 0) = 1
         and then OpenCV.Core.Int32_Access.Get (Parent, 2, 4) = 1,
         "Int32 Region row access must respect parent stride and neighbors");
   end Copied_And_Borrowed_Region_Rows_Share_Parent_Storage;

   procedure Validation_Rejects_Invalid_Rows_Types_And_Lengths
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Valid   : OpenCV.Core.Mat := Int32_Image (1, 3);
      Wrong   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Multi   : constant OpenCV.Core.Mat := Int32_Image (1, 3, 2);
      Data    : OpenCV.Core.Int32_Row_Access.Row_Array (0 .. 2);
      Short   : constant OpenCV.Core.Int32_Row_Access.Row_Array (0 .. 1) :=
        (others => 0);
      Invoked : Boolean := False;

      procedure Mark (Values : aliased OpenCV.Core.Int32_Row_Access.Row_Array)
      is
         pragma Unreferenced (Values);
      begin
         Invoked := True;
      end Mark;
      procedure Read_Wrong is
      begin
         OpenCV.Core.Int32_Row_Access.Read_Row (Wrong, 0, Data);
      end Read_Wrong;
      procedure Read_Multi is
      begin
         OpenCV.Core.Int32_Row_Access.Read_Row (Multi, 0, Data);
      end Read_Multi;
      procedure Read_Past is
      begin
         OpenCV.Core.Int32_Row_Access.Read_Row (Valid, 1, Data);
      end Read_Past;
      procedure Write_Short is
      begin
         OpenCV.Core.Int32_Row_Access.Write_Row (Valid, 0, Short);
      end Write_Short;
      procedure Borrow_Wrong is
      begin
         OpenCV.Core.Int32_Row_Access.With_Read_Only_Row
           (Wrong, 0, Mark'Access);
      end Borrow_Wrong;
   begin
      Assert_Raises_OpenCV_Error (Read_Wrong'Access, "wrong Int32 depth");
      Assert_Raises_OpenCV_Error (Read_Multi'Access, "Int32 C2 row");
      Assert_Raises_OpenCV_Error (Read_Past'Access, "Int32 row past end");
      Assert_Raises_OpenCV_Error (Write_Short'Access, "short Int32 row");
      Assert_Raises_OpenCV_Error (Borrow_Wrong'Access, "borrow wrong depth");
      AUnit.Assertions.Assert
        (not Invoked, "Invalid Int32 row borrowing must suppress callback");
   end Validation_Rejects_Invalid_Rows_Types_And_Lengths;

   procedure Callback_Exception_Propagates_And_Mat_Remains_Usable
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat := Int32_Image (1, 3);
      Raised   : Boolean := False;
      Identity : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Int32_Row_Access.Row_Array) is
      begin
         Data (1) := 16_777_217;
         raise Callback_Error;
      end Mutate;
   begin
      Image.Set_To (OpenCV.Make_Scalar (3.0));
      begin
         OpenCV.Core.Int32_Row_Access.With_Writable_Row
           (Image, 0, Mutate'Access);
      exception
         when Error : Callback_Error =>
            Raised := True;
            Identity := Ada.Exceptions.Exception_Identity (Error);
      end;
      AUnit.Assertions.Assert
        (Raised and then Identity = Callback_Error'Identity,
         "Int32 row callback exception must propagate unchanged");
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Access.Get (Image, 0, 1) = 16_777_217,
         "Int32 row writes before callback failure must remain visible");
      OpenCV.Core.Int32_Access.Set (Image, 0, 2, -8);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Access.Get (Image, 0, 2) = -8,
         "Int32 Mat must remain usable after callback failure");
   end Callback_Exception_Propagates_And_Mat_Remains_Usable;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Int32 copied rows preserve exact values and array order",
            Copied_Rows_Preserve_Exact_Values_And_Array_Order'Access));
      Result.Add_Test
        (Caller.Create
           ("Int32 copied and borrowed Region rows share parent storage",
            Copied_And_Borrowed_Region_Rows_Share_Parent_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Int32 row validation rejects invalid rows types and lengths",
            Validation_Rejects_Invalid_Rows_Types_And_Lengths'Access));
      Result.Add_Test
        (Caller.Create
           ("Int32 row callback failure propagates and preserves writes",
            Callback_Exception_Propagates_And_Mat_Remains_Usable'Access));
      return Result'Access;
   end Suite;

end Integer_Row_Access_Tests;
