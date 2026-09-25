with Ada.Exceptions;
with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Int8_Access;
with OpenCV.Core.Int8_Row_Access;

package body Int8_Row_Access_Tests is

   use type Ada.Exceptions.Exception_Id;
   use type OpenCV.Int8_Value;
   use type OpenCV.Core.Int8_Row_Access.Row_Array;
   use Mat_Test_Support;

   Callback_Error : exception;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Int8_Image
     (Rows, Columns : Natural; Channels : OpenCV.Core.Channel_Count := 1)
      return OpenCV.Core.Mat
   is (OpenCV.Core.Create
         (Rows, Columns, (Depth => OpenCV.Core.Int8, Channels => Channels)));

   procedure Copied_Rows_Preserve_Endpoints_And_Bounds (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat := Int8_Image (3, 7);
      Written  : constant OpenCV.Core.Int8_Row_Access.Row_Array (4 .. 10) :=
        (-128, -127, -1, 0, 1, 126, 127);
      Readback : OpenCV.Core.Int8_Row_Access.Row_Array (20 .. 26);
      Last     : constant OpenCV.Core.Int8_Row_Access.Row_Array (1 .. 7) :=
        (91, 92, 93, 94, 95, 96, 97);
   begin
      Image.Set_To (OpenCV.Make_Scalar (5.0));
      OpenCV.Core.Int8_Row_Access.Write_Row (Image, 0, Written);
      OpenCV.Core.Int8_Row_Access.Write_Row (Image, 2, Last);
      OpenCV.Core.Int8_Row_Access.Read_Row (Image, 0, Readback);
      AUnit.Assertions.Assert
        (Readback = Written
         and then OpenCV.Core.Int8_Access.Get (Image, 1, 0) = 5
         and then OpenCV.Core.Int8_Access.Get (Image, 2, 0) = 91
         and then OpenCV.Core.Int8_Access.Get (Image, 2, 6) = 97,
         "Int8 copied rows must preserve endpoints and neighboring rows");
      OpenCV.Core.Int8_Access.Set (Image, 0, 1, 77);
      AUnit.Assertions.Assert
        (Readback (21) = -127,
         "Int8 Read_Row must return an independent copy");
   end Copied_Rows_Preserve_Endpoints_And_Bounds;

   procedure Borrowed_Region_Rows_Are_Zero_Based_And_Immediate
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat := Int8_Image (4, 6);
      Region : OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Alias  : OpenCV.Core.Mat := Parent;
      Values : constant OpenCV.Core.Int8_Row_Access.Row_Array (9 .. 11) :=
        (-128, -1, 127);

      procedure Inspect (Data : aliased OpenCV.Core.Int8_Row_Access.Row_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data = Values,
            "Borrowed Int8 Region rows must be zero-based and exact");
      end Inspect;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Int8_Row_Access.Row_Array) is
      begin
         Data (0) := -127;
         OpenCV.Core.Int8_Access.Set (Alias, 2, 3, 42);
         AUnit.Assertions.Assert
           (Data (2) = 42,
            "Borrowed Int8 rows must immediately observe alias writes");
      end Mutate;
   begin
      Parent.Set_To (OpenCV.Make_Scalar (1.0));
      AUnit.Assertions.Assert
        (not Region.Is_Continuous,
         "Int8 Region fixture must be non-contiguous");
      OpenCV.Core.Int8_Row_Access.Write_Row (Region, 1, Values);
      OpenCV.Core.Int8_Row_Access.With_Read_Only_Row
        (Region, 1, Inspect'Access);
      OpenCV.Core.Int8_Row_Access.With_Writable_Row (Region, 1, Mutate'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int8_Access.Get (Parent, 2, 1) = -127
         and then OpenCV.Core.Int8_Access.Get (Parent, 2, 2) = -1
         and then OpenCV.Core.Int8_Access.Get (Parent, 2, 3) = 42
         and then OpenCV.Core.Int8_Access.Get (Parent, 2, 0) = 1
         and then OpenCV.Core.Int8_Access.Get (Parent, 2, 4) = 1,
         "Int8 Region rows must respect stride and neighboring columns");
   end Borrowed_Region_Rows_Are_Zero_Based_And_Immediate;

   procedure Validation_Rejects_Invalid_Rows (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Valid   : OpenCV.Core.Mat := Int8_Image (1, 3);
      Wrong   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.UInt8, 1));
      Multi   : constant OpenCV.Core.Mat := Int8_Image (1, 3, 2);
      Data    : OpenCV.Core.Int8_Row_Access.Row_Array (0 .. 2);
      Short   : constant OpenCV.Core.Int8_Row_Access.Row_Array (0 .. 1) :=
        (others => 0);
      Invoked : Boolean := False;

      procedure Mark (Values : aliased OpenCV.Core.Int8_Row_Access.Row_Array)
      is
         pragma Unreferenced (Values);
      begin
         Invoked := True;
      end Mark;
      procedure Read_Wrong is
      begin
         OpenCV.Core.Int8_Row_Access.Read_Row (Wrong, 0, Data);
      end Read_Wrong;
      procedure Read_Multi is
      begin
         OpenCV.Core.Int8_Row_Access.Read_Row (Multi, 0, Data);
      end Read_Multi;
      procedure Read_Past is
      begin
         OpenCV.Core.Int8_Row_Access.Read_Row (Valid, 1, Data);
      end Read_Past;
      procedure Write_Short is
      begin
         OpenCV.Core.Int8_Row_Access.Write_Row (Valid, 0, Short);
      end Write_Short;
      procedure Borrow_Wrong is
      begin
         OpenCV.Core.Int8_Row_Access.With_Read_Only_Row
           (Wrong, 0, Mark'Access);
      end Borrow_Wrong;
   begin
      Assert_Raises_OpenCV_Error (Read_Wrong'Access, "wrong Int8 depth");
      Assert_Raises_OpenCV_Error (Read_Multi'Access, "Int8 C2 row");
      Assert_Raises_OpenCV_Error (Read_Past'Access, "Int8 row past end");
      Assert_Raises_OpenCV_Error (Write_Short'Access, "short Int8 row");
      Assert_Raises_OpenCV_Error (Borrow_Wrong'Access, "borrow wrong depth");
      AUnit.Assertions.Assert
        (not Invoked, "Invalid Int8 row borrowing must suppress callback");
   end Validation_Rejects_Invalid_Rows;

   procedure Callback_Exception_Propagates_And_Later_Borrow_Succeeds
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat := Int8_Image (1, 3);
      Raised   : Boolean := False;
      Identity : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;
      Later    : Boolean := False;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Int8_Row_Access.Row_Array) is
      begin
         Data (1) := -128;
         raise Callback_Error;
      end Mutate;
      procedure Inspect (Data : aliased OpenCV.Core.Int8_Row_Access.Row_Array)
      is
      begin
         Later := Data (1) = -128;
      end Inspect;
   begin
      Image.Set_To (OpenCV.Make_Scalar (3.0));
      begin
         OpenCV.Core.Int8_Row_Access.With_Writable_Row
           (Image, 0, Mutate'Access);
      exception
         when Error : Callback_Error =>
            Raised := True;
            Identity := Ada.Exceptions.Exception_Identity (Error);
      end;
      OpenCV.Core.Int8_Row_Access.With_Read_Only_Row
        (Image, 0, Inspect'Access);
      AUnit.Assertions.Assert
        (Raised
         and then Identity = Callback_Error'Identity
         and then OpenCV.Core.Int8_Access.Get (Image, 0, 1) = -128
         and then Later,
         "Int8 row exception, prior write, and later borrow must succeed");
   end Callback_Exception_Propagates_And_Later_Borrow_Succeeds;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Int8 copied rows preserve signed endpoints and neighbors",
            Copied_Rows_Preserve_Endpoints_And_Bounds'Access));
      Result.Add_Test
        (Caller.Create
           ("Int8 borrowed Region rows are zero-based and immediate",
            Borrowed_Region_Rows_Are_Zero_Based_And_Immediate'Access));
      Result.Add_Test
        (Caller.Create
           ("Int8 row validation rejects invalid rows types and lengths",
            Validation_Rejects_Invalid_Rows'Access));
      Result.Add_Test
        (Caller.Create
           ("Int8 row callback failure preserves writes and later borrow",
            Callback_Exception_Propagates_And_Later_Borrow_Succeeds'Access));
      return Result'Access;
   end Suite;

end Int8_Row_Access_Tests;
