with Ada.Exceptions;
with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Int8_Access;
with OpenCV.Core.Int8_Buffer_Access;

package body Int8_Buffer_Access_Tests is

   use type Ada.Exceptions.Exception_Id;
   use type OpenCV.Int8_Value;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Int8_Buffer_Access.Buffer_Array;
   use Mat_Test_Support;

   Callback_Error : exception;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   procedure Signed_Round_Trip_And_Zero_Based_Extent (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Int8, 1));
      Read_OK : Boolean := False;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Int8_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 7,
            "Nonempty Int8 buffer must be zero-based row-major");
         Data := (-128, -127, -1, 0, 1, 126, 127, 9);
      end Mutate;
      procedure Inspect
        (Data : aliased OpenCV.Core.Int8_Buffer_Access.Buffer_Array) is
      begin
         Read_OK :=
           Data'First = 0 and then Data = (-128, -127, -1, 0, 1, 126, 127, 9);
      end Inspect;
   begin
      OpenCV.Core.Int8_Buffer_Access.With_Writable_Buffer
        (Image, Mutate'Access);
      OpenCV.Core.Int8_Buffer_Access.With_Read_Only_Buffer
        (Image, Inspect'Access);
      AUnit.Assertions.Assert
        (Read_OK
         and then OpenCV.Core.Int8_Access.Get (Image, 0, 0) = -128
         and then OpenCV.Core.Int8_Access.Get (Image, 1, 2) = 127,
         "Int8 buffer callbacks must round-trip signed endpoints");
   end Signed_Round_Trip_And_Zero_Based_Extent;

   procedure Regions_Empties_And_Invalid_Types (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Parent      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 5, (OpenCV.Core.Int8, 1));
      Continuous  : OpenCV.Core.Mat :=
        Parent.Region ((X => 0, Y => 1, Width => 5, Height => 2));
      Strided     : constant OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Empty       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Int8, 1));
      Wrong       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Multi       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Int8, 2));
      Volume      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 2, 2), Element_Type => (OpenCV.Core.Int8, 1));
      Empty_Count : Natural := 0;
      Invoked     : Boolean := False;

      procedure Write_Continuous
        (Data : aliased in out OpenCV.Core.Int8_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Continuous.Is_Continuous and then Data'Length = 10,
            "Continuous Int8 Region must be borrowed");
         Data (0) := -128;
      end Write_Continuous;
      procedure Mark
        (Data : aliased OpenCV.Core.Int8_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark;
      procedure Empty_Read
        (Data : aliased OpenCV.Core.Int8_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 1 and then Data'Last = 0,
            "Empty Int8 read-only buffer uses 1 .. 0");
         Empty_Count := Empty_Count + 1;
      end Empty_Read;
      procedure Empty_Write
        (Data : aliased in out OpenCV.Core.Int8_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 1 and then Data'Last = 0,
            "Empty Int8 writable buffer uses 1 .. 0");
         Empty_Count := Empty_Count + 1;
      end Empty_Write;
      procedure Borrow_Strided is
      begin
         OpenCV.Core.Int8_Buffer_Access.With_Read_Only_Buffer
           (Strided, Mark'Access);
      end Borrow_Strided;
      procedure Borrow_Wrong is
      begin
         OpenCV.Core.Int8_Buffer_Access.With_Read_Only_Buffer
           (Wrong, Mark'Access);
      end Borrow_Wrong;
      procedure Borrow_Multi is
      begin
         OpenCV.Core.Int8_Buffer_Access.With_Read_Only_Buffer
           (Multi, Mark'Access);
      end Borrow_Multi;
      procedure Borrow_Volume is
      begin
         OpenCV.Core.Int8_Buffer_Access.With_Read_Only_Buffer
           (Volume, Mark'Access);
      end Borrow_Volume;
   begin
      OpenCV.Core.Int8_Buffer_Access.With_Writable_Buffer
        (Continuous, Write_Continuous'Access);
      OpenCV.Core.Int8_Buffer_Access.With_Read_Only_Buffer
        (Empty, Empty_Read'Access);
      OpenCV.Core.Int8_Buffer_Access.With_Writable_Buffer
        (Empty, Empty_Write'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int8_Access.Get (Parent, 1, 0) = -128
         and then Empty_Count = 2,
         "Int8 continuous Region writes and empty callbacks must succeed");
      Assert_Raises_OpenCV_Error
        (Borrow_Strided'Access, "Int8 strided Region");
      Assert_Raises_OpenCV_Error (Borrow_Wrong'Access, "Int8 wrong depth");
      Assert_Raises_OpenCV_Error (Borrow_Multi'Access, "Int8 wrong channels");
      Assert_Raises_OpenCV_Error
        (Borrow_Volume'Access, "Int8 wrong dimensions");
      AUnit.Assertions.Assert
        (not Invoked, "Rejected Int8 buffers must suppress callbacks");
   end Regions_Empties_And_Invalid_Types;

   procedure Callback_Failure_And_Alias_Rebind (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Int8, 1));
      Alias    : OpenCV.Core.Mat := Image;
      Raised   : Boolean := False;
      Identity : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;
      Later    : Boolean := False;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Int8_Buffer_Access.Buffer_Array) is
      begin
         Alias := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (0) := -128;
         raise Callback_Error;
      end Mutate;
      procedure Inspect
        (Data : aliased OpenCV.Core.Int8_Buffer_Access.Buffer_Array) is
      begin
         Later := Data (0) = -128;
      end Inspect;
   begin
      begin
         OpenCV.Core.Int8_Buffer_Access.With_Writable_Buffer
           (Image, Mutate'Access);
      exception
         when Error : Callback_Error =>
            Raised := True;
            Identity := Ada.Exceptions.Exception_Identity (Error);
      end;
      OpenCV.Core.Int8_Buffer_Access.With_Read_Only_Buffer
        (Image, Inspect'Access);
      OpenCV.Core.Int8_Access.Set (Image, 0, 1, 7);
      AUnit.Assertions.Assert
        (Raised
         and then Identity = Callback_Error'Identity
         and then Later
         and then OpenCV.Core.Int8_Access.Get (Image, 0, 1) = 7
         and then Alias.Depth = OpenCV.Core.UInt8,
         "Int8 buffer failure must preserve writes and leave Mat usable");
   end Callback_Failure_And_Alias_Rebind;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Int8 buffers preserve signed values and zero-based extents",
            Signed_Round_Trip_And_Zero_Based_Extent'Access));
      Result.Add_Test
        (Caller.Create
           ("Int8 buffers accept continuous Regions and reject invalid Mats",
            Regions_Empties_And_Invalid_Types'Access));
      Result.Add_Test
        (Caller.Create
           ("Int8 buffer failure preserves writes and alias rebinding",
            Callback_Failure_And_Alias_Rebind'Access));
      return Result'Access;
   end Suite;

end Int8_Buffer_Access_Tests;
