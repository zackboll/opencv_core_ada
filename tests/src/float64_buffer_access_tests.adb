with Ada.Exceptions;
with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV.Core;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Float64_Buffer_Access;
with OpenCV.Core.Float64_Row_Access;

package body Float64_Buffer_Access_Tests is

   use type Ada.Exceptions.Exception_Id;
   use type OpenCV.Core.Float32_Value;
   use type OpenCV.Core.Float64_Value;
   use type OpenCV.Core.Float64_Access.Float64_Classification;
   use Mat_Test_Support;

   Borrowed_Buffer_Callback_Error : exception;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Float64_Image
     (Rows, Columns : Natural; Channels : OpenCV.Core.Channel_Count := 1)
      return OpenCV.Core.Mat
   is (OpenCV.Core.Create
         (Rows,
          Columns,
          (Depth => OpenCV.Core.Float64, Channels => Channels)));

   procedure Read_Only_Buffer_Preserves_Extent_Order_And_Precision
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      First    : constant OpenCV.Core.Float64_Value := 1.0;
      Distinct : OpenCV.Core.Float64_Value;
      First_32 : OpenCV.Core.Float32_Value;
      Other_32 : OpenCV.Core.Float32_Value;
      Image    : OpenCV.Core.Mat := Float64_Image (2, 3);

      procedure Inspect
        (Data : aliased OpenCV.Core.Float64_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5 and then Data'Length = 6,
            "A Float64 buffer must exactly span zero-based Image.Total");
         AUnit.Assertions.Assert
           (Data (0) = First
            and then Data (1) = Distinct
            and then Data (2) = 2.5
            and then Data (3) = -3.5
            and then Data (4) = 4.5
            and then Data (5) = 9.25,
            "A Float64 buffer must preserve first, last, and row-major"
            & " values");
         AUnit.Assertions.Assert
           (Data (0) /= Data (1),
            "Direct Float64 borrowing must not round values through Float32");
      end Inspect;
   begin
      Distinct := First + 2.0**(-40);
      First_32 := OpenCV.Core.Float32_Value (First);
      Other_32 := OpenCV.Core.Float32_Value (Distinct);
      AUnit.Assertions.Assert
        (First /= Distinct and then First_32 = Other_32,
         "The precision values must be distinct in binary64 but not binary32");
      OpenCV.Core.Float64_Access.Set (Image, 0, 0, First);
      OpenCV.Core.Float64_Access.Set (Image, 0, 1, Distinct);
      OpenCV.Core.Float64_Access.Set (Image, 0, 2, 2.5);
      OpenCV.Core.Float64_Access.Set (Image, 1, 0, -3.5);
      OpenCV.Core.Float64_Access.Set (Image, 1, 1, 4.5);
      OpenCV.Core.Float64_Access.Set (Image, 1, 2, 9.25);
      OpenCV.Core.Float64_Buffer_Access.With_Read_Only_Buffer
        (Image, Inspect'Access);
   end Read_Only_Buffer_Preserves_Extent_Order_And_Precision;

   procedure Writable_Buffer_Is_Shared_And_Clone_Is_Independent
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat := Float64_Image (2, 3);
      Alias : OpenCV.Core.Mat;
      Copy  : OpenCV.Core.Mat;
      Row   : OpenCV.Core.Float64_Row_Access.Row_Array (0 .. 2);

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float64_Buffer_Access.Buffer_Array)
      is
      begin
         Data (0) := 12.125;
         Data (3) := -7.75;
         Data (5) := 99.5;
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Access.Get (Image, 0, 0) = 12.125
            and then OpenCV.Core.Float64_Access.Get (Alias, 1, 0) = -7.75,
            "Float64 buffer writes must be immediately visible through"
            & " aliases");
      end Mutate;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (1.0));
      Alias := Image;
      Copy := Image.Clone;
      OpenCV.Core.Float64_Buffer_Access.With_Writable_Buffer
        (Image, Mutate'Access);
      OpenCV.Core.Float64_Row_Access.Read_Row (Image, 1, Row);
      AUnit.Assertions.Assert
        (Row (0) = -7.75 and then Row (2) = 99.5,
         "Subsequent Float64 row access must observe whole-buffer writes");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Access.Get (Copy, 0, 0) = 1.0
         and then OpenCV.Core.Float64_Access.Get (Copy, 1, 2) = 1.0,
         "A Clone must remain independent of Float64 buffer writes");
   end Writable_Buffer_Is_Shared_And_Clone_Is_Independent;

   procedure Single_Row_And_Single_Column_Buffers_Have_Exact_Extents
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Single_Row : OpenCV.Core.Mat := Float64_Image (1, 4);
      Single_Col : OpenCV.Core.Mat := Float64_Image (3, 1);

      procedure Inspect_Row
        (Data : aliased OpenCV.Core.Float64_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 3 and then Data (3) = 4.0,
            "A single-row Float64 buffer must expose every column");
      end Inspect_Row;

      procedure Inspect_Column
        (Data : aliased OpenCV.Core.Float64_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data (2) = 30.0,
            "A single-column Float64 buffer must flatten every row");
      end Inspect_Column;
   begin
      for Column in 0 .. 3 loop
         OpenCV.Core.Float64_Access.Set
           (Single_Row, 0, Column, OpenCV.Core.Float64_Value (Column + 1));
      end loop;
      for Row in 0 .. 2 loop
         OpenCV.Core.Float64_Access.Set
           (Single_Col, Row, 0, OpenCV.Core.Float64_Value ((Row + 1) * 10));
      end loop;
      OpenCV.Core.Float64_Buffer_Access.With_Read_Only_Buffer
        (Single_Row, Inspect_Row'Access);
      OpenCV.Core.Float64_Buffer_Access.With_Read_Only_Buffer
        (Single_Col, Inspect_Column'Access);
   end Single_Row_And_Single_Column_Buffers_Have_Exact_Extents;

   procedure Buffer_Preserves_Nonfinite_Binary64_Values (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Numerator   : OpenCV.Core.Mat := Float64_Image (1, 3);
      Denominator : OpenCV.Core.Mat := Float64_Image (1, 3);
      Nonfinite   : OpenCV.Core.Mat;
      Destination : OpenCV.Core.Mat := Float64_Image (1, 3);

      procedure Transfer
        (Data : aliased OpenCV.Core.Float64_Buffer_Access.Buffer_Array)
      is
         procedure Write
           (Output :
              aliased in out OpenCV.Core.Float64_Buffer_Access.Buffer_Array) is
         begin
            Output := Data;
         end Write;
      begin
         OpenCV.Core.Float64_Buffer_Access.With_Writable_Buffer
           (Destination, Write'Access);
      end Transfer;
   begin
      OpenCV.Core.Float64_Access.Set (Numerator, 0, 0, 1.0);
      OpenCV.Core.Float64_Access.Set (Numerator, 0, 1, -1.0);
      OpenCV.Core.Float64_Access.Set (Numerator, 0, 2, 0.0);
      Denominator.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Nonfinite := Numerator.Divide (Denominator);
      OpenCV.Core.Float64_Buffer_Access.With_Read_Only_Buffer
        (Nonfinite, Transfer'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Access.Classify (Destination, 0, 0)
         = OpenCV.Core.Float64_Access.Positive_Infinity
         and then OpenCV.Core.Float64_Access.Classify (Destination, 0, 1)
                  = OpenCV.Core.Float64_Access.Negative_Infinity
         and then OpenCV.Core.Float64_Access.Classify (Destination, 0, 2)
                  = OpenCV.Core.Float64_Access.Not_A_Number,
         "Float64 buffer borrowing must preserve infinities and NaN"
         & " classification");
   end Buffer_Preserves_Nonfinite_Binary64_Values;

   procedure Region_Continuity_Is_Enforced (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Parent     : OpenCV.Core.Mat := Float64_Image (4, 5);
      Continuous : OpenCV.Core.Mat :=
        Parent.Region ((X => 0, Y => 1, Width => 5, Height => 2));
      Strided    : constant OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Invoked    : Boolean := False;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float64_Buffer_Access.Buffer_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 10, "A continuous Region must expose Region.Total");
         Data (0) := 8.5;
         Data (9) := -9.5;
      end Mutate;

      procedure Mark
        (Data : aliased OpenCV.Core.Float64_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark;

      procedure Borrow_Strided is
      begin
         OpenCV.Core.Float64_Buffer_Access.With_Read_Only_Buffer
           (Strided, Mark'Access);
      end Borrow_Strided;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (1.0));
      AUnit.Assertions.Assert
        (Continuous.Is_Continuous and then not Strided.Is_Continuous,
         "Region fixtures must exercise both continuity cases");
      OpenCV.Core.Float64_Buffer_Access.With_Writable_Buffer
        (Continuous, Mutate'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Access.Get (Parent, 1, 0) = 8.5
         and then OpenCV.Core.Float64_Access.Get (Parent, 2, 4) = -9.5,
         "Continuous Region buffer writes must use shared storage");
      Assert_Raises_OpenCV_Error
        (Borrow_Strided'Access,
         "Float64 whole-buffer access must reject a non-continuous Region");
      AUnit.Assertions.Assert
        (not Invoked,
         "Continuity validation must precede callback invocation");
   end Region_Continuity_Is_Enforced;

   procedure Wrong_Depth_And_Channel_Count_Do_Not_Invoke_Callback
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Wrong   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Multi   : constant OpenCV.Core.Mat := Float64_Image (1, 2, 2);
      Invoked : Boolean := False;

      procedure Mark
        (Data : aliased OpenCV.Core.Float64_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark;

      procedure Borrow_Wrong is
      begin
         OpenCV.Core.Float64_Buffer_Access.With_Read_Only_Buffer
           (Wrong, Mark'Access);
      end Borrow_Wrong;

      procedure Borrow_Multi is
      begin
         OpenCV.Core.Float64_Buffer_Access.With_Read_Only_Buffer
           (Multi, Mark'Access);
      end Borrow_Multi;
   begin
      Assert_Raises_OpenCV_Error (Borrow_Wrong'Access, "wrong Float64 depth");
      Assert_Raises_OpenCV_Error (Borrow_Multi'Access, "Float64 C2 Mat");
      AUnit.Assertions.Assert
        (not Invoked, "Type validation must precede callback invocation");
   end Wrong_Depth_And_Channel_Count_Do_Not_Invoke_Callback;

   procedure Callback_Exception_Propagates_And_Preserves_Writes
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat := Float64_Image (2, 2);
      Raised   : Boolean := False;
      Identity : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float64_Buffer_Access.Buffer_Array)
      is
      begin
         Data (2) := 42.25;
         raise Borrowed_Buffer_Callback_Error;
      end Mutate;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (1.0));
      begin
         OpenCV.Core.Float64_Buffer_Access.With_Writable_Buffer
           (Image, Mutate'Access);
      exception
         when Error : Borrowed_Buffer_Callback_Error =>
            Raised := True;
            Identity := Ada.Exceptions.Exception_Identity (Error);
      end;
      AUnit.Assertions.Assert
        (Raised and then Identity = Borrowed_Buffer_Callback_Error'Identity,
         "A Float64 buffer callback exception must propagate unchanged");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Access.Get (Image, 1, 0) = 42.25
         and then OpenCV.Core.Float64_Access.Get (Image, 0, 0) = 1.0,
         "Writes before a callback exception must remain visible");
   end Callback_Exception_Propagates_And_Preserves_Writes;

   procedure Typed_Empty_Mat_Invokes_Callback_With_Empty_Array
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Empty   : constant OpenCV.Core.Mat := Float64_Image (0, 0);
      Invoked : Boolean := False;

      procedure Inspect
        (Data : aliased OpenCV.Core.Float64_Buffer_Access.Buffer_Array) is
      begin
         Invoked := True;
         AUnit.Assertions.Assert
           (Data'Length = 0,
            "A typed empty Float64 Mat must borrow an empty array");
      end Inspect;
   begin
      OpenCV.Core.Float64_Buffer_Access.With_Read_Only_Buffer
        (Empty, Inspect'Access);
      AUnit.Assertions.Assert
        (Invoked, "A typed empty Float64 Mat must invoke its callback");
   end Typed_Empty_Mat_Invokes_Callback_With_Empty_Array;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Float64 buffer preserves extent order and binary64 precision",
            Read_Only_Buffer_Preserves_Extent_Order_And_Precision'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 writable buffer shares aliases and isolates Clone",
            Writable_Buffer_Is_Shared_And_Clone_Is_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 single-row and single-column buffer extents",
            Single_Row_And_Single_Column_Buffers_Have_Exact_Extents'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 buffer preserves nonfinite values",
            Buffer_Preserves_Nonfinite_Binary64_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 buffer continuity and continuous Region",
            Region_Continuity_Is_Enforced'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 buffer rejects wrong depth and channels before callback",
            Wrong_Depth_And_Channel_Count_Do_Not_Invoke_Callback'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 buffer callback exception preserves completed writes",
            Callback_Exception_Propagates_And_Preserves_Writes'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 typed empty buffer invokes callback with empty array",
            Typed_Empty_Mat_Invokes_Callback_With_Empty_Array'Access));
      return Result'Access;
   end Suite;

end Float64_Buffer_Access_Tests;
